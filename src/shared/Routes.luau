-- Walkable routes over the whole beach, found at runtime (the bots use it; see BotService).
--
-- It works on the ground as the game has it (Beach.shapeAt, so the active layouts, whatever
-- biomes rolled) on a grid of STEP-stud cells, filled in lazily: a cell's height is only
-- worked out when a search first touches it, and a tile's cells are thrown away when its
-- layout changes (`refresh`). The stepping rules are tools/paths.luau's: eight directions, a
-- step may climb no steeper than FootSlope (CartSlope with a cart), a diagonal also needs the
-- two straight steps beside it (no cutting a wall's corner). On top of that rock is never
-- walked on, a cart keeps clear of the edges it can't cross (its size's PathWidth, as the
-- layouts' path checks rate them), and the caller may block cells that are deep water at the
-- moment the walker would be there (`blocked`), so a route never goes through the sea.
--
-- (tools/paths.luau measures a layout tile by tile with penalties for repeated runs; this is
-- one grid over the beach with one-off searches, so the two only share their rules.)

local Layouts = require(script.Parent.Layouts)
local Config = require(script.Parent.Config)
local Beach = require(script.Parent.Beach)

local Routes = {}

Routes.STEP = 4
local STEP = Routes.STEP
local DIAG = STEP * math.sqrt(2)

local terrain = Config.Beach.Terrain

local function heap()
	local costs, cells, n = {}, {}, 0
	local self = {}
	function self.push(cost: number, cell: number)
		n += 1
		local i = n
		costs[i], cells[i] = cost, cell
		while i > 1 do
			local parent = i // 2
			if costs[parent] <= costs[i] then
				break
			end
			costs[parent], costs[i] = costs[i], costs[parent]
			cells[parent], cells[i] = cells[i], cells[parent]
			i = parent
		end
	end
	function self.pop(): (number?, number?)
		if n == 0 then
			return nil, nil
		end
		local cost, cell = costs[1], cells[1]
		costs[1], cells[1] = costs[n], cells[n]
		costs[n], cells[n] = nil, nil
		n -= 1
		local i = 1
		while true do
			local l, r, smallest = i * 2, i * 2 + 1, i
			if l <= n and costs[l] < costs[smallest] then
				smallest = l
			end
			if r <= n and costs[r] < costs[smallest] then
				smallest = r
			end
			if smallest == i then
				break
			end
			costs[smallest], costs[i] = costs[i], costs[smallest]
			cells[smallest], cells[i] = cells[i], cells[smallest]
			i = smallest
		end
		return cost, cell
	end
	return self
end

local STEPS = {
	{ 1, 0, STEP },
	{ -1, 0, STEP },
	{ 0, 1, STEP },
	{ 0, -1, STEP },
	{ 1, 1, DIAG },
	{ 1, -1, DIAG },
	{ -1, 1, DIAG },
	{ -1, -1, DIAG },
}

export type Point = { x: number, z: number }

export type Options = {
	slope: number?, -- the steepest climb (rise over run); default FootSlope
	cart: string?, -- a cart size (Config.Carts.Order) that must fit along the route
	-- Whether the walker can't stand at a cell when it gets there: (x, z, ground, studs walked).
	blocked: ((number, number, number, number) -> boolean)?,
	radius: number?, -- the search ends this close (studs) to the goal; default one cell
	weight: number?, -- how hard the search leans toward the goal (1 = exact); default 1.15
	maxNodes: number?,
	-- Called every `yieldEvery` node expansions (default 200), so a caller can spread a long search
	-- over frames (it may yield, or raise an error to abandon the search).
	yield: (() -> ())?,
	yieldEvery: number?,
}

export type Grid = {
	cols: number,
	rows: number,
	refresh: (self: Grid) -> (),
	cellOf: (self: Grid, x: number, z: number) -> (number, number),
	centerOf: (self: Grid, col: number, row: number) -> (number, number),
	groundAt: (self: Grid, col: number, row: number) -> number,
	isRock: (self: Grid, col: number, row: number) -> boolean,
	canStep: (self: Grid, col: number, row: number, dc: number, dr: number, options: Options?) -> boolean,
	find: (self: Grid, from: Point, to: Point, options: Options?) -> ({ Point }?, number?),
}

function Routes.new(): Grid
	local half = math.floor((Beach.HalfWidth - 2) / STEP)
	local cols = half * 2 + 1
	local rows = math.floor(Beach.Depth / STEP) + 1
	local tileRows = math.floor(Config.Beach.TileLength / STEP)

	-- The cells of each tile (0: the ground past the tiles), kept until its layout changes.
	local tiles: { [number]: { ground: { [number]: number }, rock: { [number]: boolean }, edge: { [number]: boolean } } } =
		{}
	local layouts: { [number]: any } = {}

	local function fresh()
		return { ground = {}, rock = {}, edge = {} }
	end

	local function tileOfRow(row: number): number
		local tile = row // tileRows + 1
		return if tile <= Beach.ActiveTiles then tile else 0
	end

	local self = {} :: any
	self.cols = cols
	self.rows = rows

	-- Forgets the tiles whose layout has changed (a new biome, a new tide's choice).
	function self:refresh()
		for tile = 1, Beach.ActiveTiles do
			local layout = Layouts.active(tile)
			if tiles[tile] == nil or layouts[tile] ~= layout then
				tiles[tile] = fresh()
				layouts[tile] = layout
			end
		end
		tiles[0] = tiles[0] or fresh()
	end
	self:refresh()

	function self:cellOf(x: number, z: number): (number, number)
		local col = math.clamp(math.floor(x / STEP + 0.5) + half, 0, cols - 1)
		local row = math.clamp(math.floor(z / STEP + 0.5), 0, rows - 1)
		return col, row
	end

	function self:centerOf(col: number, row: number): (number, number)
		return (col - half) * STEP, row * STEP
	end

	local function fill(col: number, row: number)
		local cache = tiles[tileOfRow(row)]
		local key = row * cols + col
		local x, z = (col - half) * STEP, row * STEP
		local height, rock = Beach.shapeAt(x, z)
		cache.ground[key] = Beach.groundY(z) + height
		cache.rock[key] = rock
		return cache
	end

	function self:groundAt(col: number, row: number): number
		local cache = tiles[tileOfRow(row)]
		local key = row * cols + col
		local value = cache.ground[key]
		if value == nil then
			cache = fill(col, row)
			value = cache.ground[key]
		end
		return value
	end

	function self:isRock(col: number, row: number): boolean
		local cache = tiles[tileOfRow(row)]
		local key = row * cols + col
		local value = cache.rock[key]
		if value == nil then
			cache = fill(col, row)
			value = cache.rock[key]
		end
		return value
	end

	-- A cell a cart can't enter: rock, the beach's sides, or a step from it too steep for a
	-- cart (a wall's foot, a bank's flank, the edge of a cut).
	local function isEdge(col: number, row: number): boolean
		local cache = tiles[tileOfRow(row)]
		local key = row * cols + col
		local value = cache.edge[key]
		if value ~= nil then
			return value
		end
		local edge = self:isRock(col, row) or col == 0 or col == cols - 1
		if not edge then
			local here = self:groundAt(col, row)
			for k = 1, 4 do
				local s = STEPS[k]
				local nc, nr = col + s[1], row + s[2]
				if nc >= 0 and nc < cols and nr >= 0 and nr < rows then
					if math.abs(self:groundAt(nc, nr) - here) > terrain.CartSlope * STEP then
						edge = true
						break
					end
				end
			end
		end
		cache.edge[key] = edge
		return edge
	end

	-- Whether a cart of `size` has room at a cell: no edge nearer than its half width (the
	-- layouts' path checks measure it on 2-stud cells; on this grid a cell's worth of slack is
	-- allowed, or the biggest cart finds no way through the last zone).
	local function cartFits(col: number, row: number, size: string): boolean
		local need = Config.Carts.Sizes[size].PathWidth / 2 - STEP
		if isEdge(col, row) then
			return false
		end
		local reach = math.ceil(need / STEP)
		for dc = -reach, reach do
			for dr = -reach, reach do
				if (dc ~= 0 or dr ~= 0) and math.sqrt(dc * dc + dr * dr) * STEP < need then
					local nc, nr = col + dc, row + dr
					if nc >= 0 and nc < cols and nr >= 0 and nr < rows and isEdge(nc, nr) then
						return false
					end
				end
			end
		end
		return true
	end

	function self:canStep(col: number, row: number, dc: number, dr: number, options: Options?): boolean
		local nc, nr = col + dc, row + dr
		if nc < 0 or nc >= cols or nr < 0 or nr >= rows then
			return false
		end
		local slope = (options and options.slope) or terrain.FootSlope
		if self:isRock(nc, nr) then
			return false
		end
		local here = self:groundAt(col, row)
		local length = if dc ~= 0 and dr ~= 0 then DIAG else STEP
		if math.abs(self:groundAt(nc, nr) - here) > slope * length then
			return false
		end
		if dc ~= 0 and dr ~= 0 then
			if
				self:isRock(nc, row)
				or self:isRock(col, nr)
				or math.abs(self:groundAt(nc, row) - here) > slope * STEP
				or math.abs(self:groundAt(col, nr) - here) > slope * STEP
			then
				return false
			end
		end
		return true
	end

	-- The route from one point to another (waypoints at cell centres, the start first), and
	-- its length in studs; nil if there is none.
	function self:find(from: Point, to: Point, options: Options?): ({ Point }?, number?)
		local opts = options or {}
		local blocked = opts.blocked
		local cart = opts.cart
		local weight = opts.weight or 1.15
		local maxNodes = opts.maxNodes or 60000
		local yieldFn = opts.yield
		local yieldEvery = opts.yieldEvery or 200
		local radius = opts.radius or STEP
		local sc, sr = self:cellOf(from.x, from.z)
		local gc, gr = self:cellOf(to.x, to.z)
		local goalCells = math.max(0, math.floor(radius / STEP))
		local start = sr * cols + sc
		local cost: { [number]: number } = { [start] = 0 }
		local came: { [number]: number } = {}
		local closed: { [number]: boolean } = {}
		local queue = heap()
		local function estimate(col: number, row: number): number
			local dx, dz = math.abs(col - gc), math.abs(row - gr)
			return (math.max(dx, dz) * STEP + math.min(dx, dz) * (DIAG - STEP)) * weight
		end
		queue.push(estimate(sc, sr), start)
		local goal: number? = nil
		local nodes = 0
		while true do
			local _, cell = queue.pop()
			if not cell then
				break
			end
			if closed[cell] then
				continue
			end
			closed[cell] = true
			nodes += 1
			if nodes > maxNodes then
				break
			end
			if yieldFn and nodes % yieldEvery == 0 then
				yieldFn()
			end
			local col, row = cell % cols, cell // cols
			if math.max(math.abs(col - gc), math.abs(row - gr)) <= goalCells then
				goal = cell
				break
			end
			local walked = cost[cell]
			for _, s in STEPS do
				local nc, nr = col + s[1], row + s[2]
				if nc < 0 or nc >= cols or nr < 0 or nr >= rows then
					continue
				end
				local other = nr * cols + nc
				if closed[other] or not self:canStep(col, row, s[1], s[2], opts) then
					continue
				end
				if cart and not cartFits(nc, nr, cart) then
					continue
				end
				local total = walked + s[3]
				if blocked and blocked((nc - half) * STEP, nr * STEP, self:groundAt(nc, nr), total) then
					continue
				end
				local known = cost[other]
				if known == nil or total < known then
					cost[other] = total
					came[other] = cell
					queue.push(total + estimate(nc, nr), other)
				end
			end
		end
		if not goal then
			return nil, nil
		end
		local path: { Point } = {}
		local cell: number? = goal
		while cell do
			table.insert(path, 1, { x = ((cell % cols) - half) * STEP, z = (cell // cols) * STEP })
			cell = came[cell]
		end
		return path, cost[goal]
	end

	return self :: Grid
end

return Routes
