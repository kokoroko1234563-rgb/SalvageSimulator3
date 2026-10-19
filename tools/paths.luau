--[[
	The paths through a zone: how many distinct ways down it has, how long each takes on foot,
	how wide each is at its narrowest, and which cart sizes fit along it (Config.Paths,
	Config.Carts). Used by tools/layout_map.luau and tools/tests.

	It works on the ground as the game has it (Beach.groundAt) on a grid of STEP-stud cells over
	the zone, the zone's layout already active. Steps are allowed in eight directions where the
	ground's rise is within a slope limit (FootSlope on foot, CartSlope for carts).

	Distinct paths: the fastest way down, then again with the cells already used made costly to
	walk (so the next one goes its own way where it can), up to MaxCount times. A path counts as
	distinct when no more than MaxShared of its length runs along (or right beside) the paths
	before it: paths may cross and link up, but each needs its own stretches.

	Carts: a cart of a size needs room, PathWidth wide: it keeps to cells at least half that from
	any cell a cart can't enter (a step steeper than CartSlope from it: a wall, a bank's flank,
	the edge of a cut), and climbs no steeper than CartSlope. A size fits a path when it can get
	down keeping within LANE studs of that path (in its lane, not by some other way round). Each
	size's own fastest way down, anywhere, is reported too.
]]

local Paths = {}

local STEP = 2 -- fine enough to tell an 8-wide gap from a 10-wide one
local WALK_SPEED = 20
local PENALTY = 4 -- how much costlier a cell an earlier path used is, when looking for the next
local LANE = 16 -- studs either side of a path a cart may stray and still be on that path
local BESIDE = 20 -- studs, walking (not through a wall), from a path within which another runs along it

export type Path = {
	seconds: number, -- on foot, at walking speed
	shared: number, -- the share of it along earlier paths (0 for the first)
	sizes: { string }, -- the cart sizes that fit along it (none: foot only)
	cells: { number },
	turns: { { number } }, -- where it turns, roughly (x, z in the zone), for reports
}

export type Report = {
	paths: { Path }, -- the distinct paths, fastest first
	tried: number, -- how many were looked for
	carts: { [string]: number? }, -- for each cart size, the fastest way down it can take (seconds), or nil
}

-- A binary heap of (cost, cell).
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

-- Measures the zone on `tile` (its layout set). `Beach` and `Config` are the game's modules.
function Paths.analyse(Beach: any, Config: any, tile: number): Report
	local terrain = Config.Beach.Terrain
	local rules = Config.Paths
	local z0, z1 = Beach.tileRange(tile)
	local n = math.floor((Beach.HalfWidth - 2) / STEP)
	local cols = n * 2 + 1
	local top, bottom = math.ceil(z0 / STEP), math.floor(z1 / STEP)
	local rows = bottom - top + 1
	local count = cols * rows
	-- Cell index: row * cols + col (0-based), row from the top edge.
	local height = table.create(count, 0)
	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			height[row * cols + col + 1] = Beach.groundAt((col - n) * STEP, (top + row) * STEP)
		end
	end
	local function h(cell: number): number
		return height[cell + 1]
	end

	-- The eight steps: column and row change, length.
	local DIAG = STEP * math.sqrt(2)
	local steps = {
		{ 1, 0, STEP },
		{ -1, 0, STEP },
		{ 0, 1, STEP },
		{ 0, -1, STEP },
		{ 1, 1, DIAG },
		{ 1, -1, DIAG },
		{ -1, 1, DIAG },
		{ -1, -1, DIAG },
	}
	-- Whether a step from `cell` (col, row) by `s` keeps within `slope` (and, on a diagonal, so
	-- do the two straight steps beside it: no cutting a wall's corner).
	local function canStep(col: number, row: number, s, slope: number): number?
		local nc, nr = col + s[1], row + s[2]
		if nc < 0 or nc >= cols or nr < 0 or nr >= rows then
			return nil
		end
		local here = h(row * cols + col)
		local there = nr * cols + nc
		if math.abs(h(there) - here) > slope * s[3] then
			return nil
		end
		if s[1] ~= 0 and s[2] ~= 0 then
			if
				math.abs(h(row * cols + nc) - here) > slope * STEP
				or math.abs(h(nr * cols + col) - here) > slope * STEP
			then
				return nil
			end
		end
		return there
	end

	-- Clearance: studs from each cell to the nearest edge a cart can't cross (a step steeper
	-- than CartSlope), measured from the edge itself: a cell beside one is half a cell from it.
	local blocked = table.create(count, false)
	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			for k = 1, 4 do
				local s = steps[k]
				local nc, nr = col + s[1], row + s[2]
				if
					nc >= 0
					and nc < cols
					and nr >= 0
					and nr < rows
					and math.abs(h(nr * cols + nc) - h(row * cols + col)) > terrain.CartSlope * STEP
				then
					blocked[row * cols + col + 1] = true
					break
				end
			end
		end
	end
	local clearance = table.create(count, math.huge)
	do
		local queue = heap()
		for cell = 0, count - 1 do
			if blocked[cell + 1] then
				clearance[cell + 1] = STEP / 2
				queue.push(STEP / 2, cell)
			end
		end
		-- The beach's sides count as walls too.
		for row = 0, rows - 1 do
			for _, col in { 0, cols - 1 } do
				local cell = row * cols + col
				if clearance[cell + 1] > STEP / 2 then
					clearance[cell + 1] = STEP / 2
					queue.push(STEP / 2, cell)
				end
			end
		end
		while true do
			local d, cell = queue.pop()
			if not d then
				break
			end
			if d > clearance[cell + 1] then
				continue
			end
			local col, row = cell % cols, cell // cols
			for _, s in steps do
				local nc, nr = col + s[1], row + s[2]
				if nc >= 0 and nc < cols and nr >= 0 and nr < rows then
					local other = nr * cols + nc
					local nd = d + s[3]
					if nd < clearance[other + 1] then
						clearance[other + 1] = nd
						queue.push(nd, other)
					end
				end
			end
		end
	end

	-- The fastest way from the top row to the bottom row: its cells (top first) and length in
	-- studs, or nil. `extra` makes some cells costlier; `allowed` (if given) limits the cells.
	local function fastest(slope: number, extra: { [number]: boolean }?, allowed: ((number) -> boolean)?)
		local cost = table.create(count, math.huge)
		local from = table.create(count, -1)
		local queue = heap()
		for col = 0, cols - 1 do
			if not allowed or allowed(col) then
				cost[col + 1] = 0
				queue.push(0, col)
			end
		end
		local goal: number? = nil
		while true do
			local c, cell = queue.pop()
			if not c then
				break
			end
			if c > cost[cell + 1] then
				continue
			end
			local col, row = cell % cols, cell // cols
			if row == rows - 1 then
				goal = cell
				break
			end
			for _, s in steps do
				local other = canStep(col, row, s, slope)
				if other and (not allowed or allowed(other)) then
					local weight = s[3] * (if extra and extra[other] then PENALTY else 1)
					local nc = c + weight
					if nc < cost[other + 1] then
						cost[other + 1] = nc
						from[other + 1] = cell
						queue.push(nc, other)
					end
				end
			end
		end
		if not goal then
			return nil
		end
		local cells = {}
		local cell = goal :: number
		while cell >= 0 do
			table.insert(cells, 1, cell)
			cell = from[cell + 1]
		end
		return cells
	end

	local function length(cells: { number }): number
		local total = 0
		for i = 2, #cells do
			local a, b = cells[i - 1], cells[i]
			local dc, dr = math.abs(a % cols - b % cols), math.abs(a // cols - b // cols)
			total += if dc + dr == 2 then DIAG else STEP
		end
		return total
	end

	-- The cells within LANE of a path's.
	local function laneOf(cells: { number }): { [number]: boolean }
		local within: { [number]: boolean } = {}
		local reach = math.ceil(LANE / STEP)
		for _, cell in cells do
			local col, row = cell % cols, cell // cols
			for dc = -reach, reach do
				for dr = -reach, reach do
					local nc, nr = col + dc, row + dr
					if
						nc >= 0
						and nc < cols
						and nr >= 0
						and nr < rows
						and dc * dc + dr * dr <= reach * reach
					then
						within[nr * cols + nc] = true
					end
				end
			end
		end
		return within
	end

	-- Whether a cart of `size` gets down keeping to cells `within`.
	local function cartGets(size: string, within: { [number]: boolean }?): number?
		local half = Config.Carts.Sizes[size].PathWidth / 2
		local cells = fastest(terrain.CartSlope, nil, function(cell: number): boolean
			return clearance[cell + 1] >= half and (not within or within[cell] == true)
		end)
		return if cells then length(cells) / WALK_SPEED else nil
	end

	local function rate(cells: { number }, shared: number): Path
		-- The biggest size that fits, then every smaller one does too.
		local sizes = {}
		local lane = laneOf(cells)
		local order = Config.Carts.Order
		for i = #order, 1, -1 do
			if cartGets(order[i], lane) then
				for k = 1, i do
					table.insert(sizes, order[k])
				end
				break
			end
		end
		-- Its turns (zone coordinates, z from the zone's top): where it changes direction.
		local turns = {}
		local lastDir
		for i, cell in cells do
			local col, row = cell % cols, cell // cols
			local nextCell = cells[i + 1]
			local dir = if nextCell then (nextCell % cols - col) .. "," .. (nextCell // cols - row) else nil
			if i == 1 or i == #cells or dir ~= lastDir then
				local point = { (col - n) * STEP, (top + row) * STEP - z0 }
				local last = turns[#turns]
				if not last or math.abs(last[1] - point[1]) + math.abs(last[2] - point[2]) >= 24 then
					table.insert(turns, point)
				end
			end
			lastDir = dir
		end
		return {
			seconds = length(cells) / WALK_SPEED,
			shared = shared,
			sizes = sizes,
			cells = cells,
			turns = turns,
		}
	end

	-- The distinct paths on foot.
	local report: Report = { paths = {}, tried = 0, carts = {} }
	local used: { [number]: boolean } = {} -- costlier to walk: the earlier paths and beside them
	local near: { [number]: boolean } = {} -- the earlier paths' cells and those beside them
	for _ = 1, rules.MaxCount do
		report.tried += 1
		local cells = fastest(terrain.FootSlope, used)
		if not cells then
			break
		end
		local along = 0
		for _, cell in cells do
			if near[cell] then
				along += 1
			end
		end
		local shared = along / #cells
		if #report.paths > 0 and shared > rules.MaxShared then
			break
		end
		table.insert(report.paths, rate(cells, shared))
		-- Beside it: what's within BESIDE of it on foot, in the same open ground (two sides of
		-- one corridor are the same way; two corridors with a wall between are not).
		local within = table.create(count, math.huge)
		local queue = heap()
		for _, cell in cells do
			within[cell + 1] = 0
			queue.push(0, cell)
		end
		while true do
			local d, cell = queue.pop()
			if not d then
				break
			end
			if d > within[cell + 1] then
				continue
			end
			near[cell] = true
			used[cell] = true
			local col, row = cell % cols, cell // cols
			for _, s in steps do
				local other = canStep(col, row, s, terrain.FootSlope)
				if other then
					local nd = d + s[3]
					if nd <= BESIDE and nd < within[other + 1] then
						within[other + 1] = nd
						queue.push(nd, other)
					end
				end
			end
		end
	end

	-- Each cart size: the fastest way down on cells wide enough for it, within the cart slope.
	for _, size in Config.Carts.Order do
		report.carts[size] = cartGets(size, nil)
	end
	return report
end

-- What's wrong with a zone's paths against the rules (Config.Paths), for a crossing that says
-- it has `wanted` paths and a zone whose CrossTime is `target` seconds.
function Paths.problems(Config: any, report: Report, wanted: number, target: number): { string }
	local rules = Config.Paths
	local problems = {}
	if #report.paths < wanted then
		table.insert(problems, string.format("%d distinct path(s) through, wanted %d", #report.paths, wanted))
	end
	for i, path in report.paths do
		if i > wanted then
			break
		end
		local share = path.seconds / target
		if share < rules.Min then
			table.insert(
				problems,
				string.format(
					"path %d takes %.0f s, under %d%% of %d s",
					i,
					path.seconds,
					rules.Min * 100,
					target
				)
			)
		elseif share > rules.Max then
			table.insert(
				problems,
				string.format(
					"path %d takes %.0f s, over %d%% of %d s",
					i,
					path.seconds,
					rules.Max * 100,
					target
				)
			)
		end
	end
	local big = report.carts[rules.BigCart]
	if not big then
		table.insert(problems, "no way down for a " .. rules.BigCart .. " cart")
	elseif big / target > rules.Max then
		table.insert(
			problems,
			string.format(
				"the %s cart's way takes %.0f s, over %d%% of %d s",
				rules.BigCart,
				big,
				rules.Max * 100,
				target
			)
		)
	end
	return problems
end

-- One line per path, and the carts: for reports.
function Paths.describe(report: Report, target: number): { string }
	local lines = {}
	for i, path in report.paths do
		table.insert(
			lines,
			string.format(
				"path %d: %.0f s (%d%% of %d s), %s%s",
				i,
				path.seconds,
				math.floor(path.seconds / target * 100 + 0.5),
				target,
				if #path.sizes > 0 then "carts: " .. table.concat(path.sizes, ", ") else "foot only",
				if i > 1 then string.format(", %d%% shared", math.floor(path.shared * 100 + 0.5)) else ""
			)
		)
	end
	local carts = {}
	for size, seconds in report.carts do
		table.insert(carts, size .. " " .. string.format("%.0f s", seconds))
	end
	table.sort(carts)
	table.insert(lines, "carts get down: " .. (if #carts > 0 then table.concat(carts, ", ") else "none"))
	return lines
end

return Paths
