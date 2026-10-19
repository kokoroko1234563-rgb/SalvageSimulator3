-- Invisible barriers inside the layouts' Walls. Smooth terrain rounds a wall's sides off into
-- rough slopes a player can scramble up, so each wall gets a solid, invisible slab down its
-- middle, a little narrower than the wall and well above its top (more than a jump), that
-- nobody gets over. Where a ramp or a flat cuts through a wall, the barrier stops too, so the
-- gap stays open. An Area wall (a block of rock, often with lanes and halls carved out of it)
-- is covered wherever its rock still stands, INSET in from every edge, carved ones included.
-- Rebuilt with the tile's terrain whenever its layout changes.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Layouts = require(Shared.Layouts)

local WallBarriers = {}

local STEP = 2 -- studs between the points along a wall that are checked
local INSET = 2 -- studs narrower than the wall on each side
local ABOVE = 9 -- studs above the wall's top (a jump reaches about 7)
local STANDING = 0.6 -- a stretch of wall counts while it stands this share of its height
local CELL = 4 -- an Area wall's barrier is laid over its standing rock in cells this size
local MERGE = 64 -- the most studs of rows one Area slab covers (the beach slopes under it)

local function folderFor(tile: number): Folder
	local root = Workspace:FindFirstChild("WallBarriers")
	if not root then
		root = Instance.new("Folder")
		root.Name = "WallBarriers"
		root.Parent = Workspace
	end
	local name = "Tile" .. tile
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = root
	return folder
end

-- An Area wall's slabs: rows of CELL-stud cells where its rock stands (and still stands INSET
-- studs further out each way), runs along each row, merged down the rows while they match.
local function areaSlabs(p, tile: number, slabs)
	local z0, z1 = Beach.tileRange(tile)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, point in p.Area do
		minX, maxX = math.min(minX, point[1]), math.max(maxX, point[1])
		minZ, maxZ = math.min(minZ, z0 + point[2]), math.max(maxZ, z0 + point[2])
	end
	local reach = Beach.HalfWidth + Config.Beach.Terrain.CliffReach
	minX, maxX = math.max(minX, -reach), math.min(maxX, reach)
	minZ, maxZ = math.max(minZ, z0), math.min(maxZ, z1)
	local need = p.Height * STANDING
	local edge = CELL / 2 + INSET
	local function stands(x: number, z: number): boolean
		return Beach.feature(x, z) >= need
	end
	local function solid(x: number, z: number): boolean
		return stands(x, z)
			and stands(x - edge, z)
			and stands(x + edge, z)
			and stands(x, z - edge)
			and stands(x, z + edge)
	end
	local open = {} -- "x0,x1" -> { x0, x1, zFrom, zTo }
	local function emit(r)
		local low, high = Beach.groundY(r[3]), Beach.groundY(r[4])
		local bottom = math.min(low, high) - 2
		local top = math.max(low, high) + p.Height + ABOVE
		local width, depth = r[2] - r[1], r[4] - r[3]
		table.insert(slabs, {
			cframe = CFrame.new((r[1] + r[2]) / 2, (bottom + top) / 2, (r[3] + r[4]) / 2),
			size = Vector3.new(width, top - bottom, depth),
		})
	end
	for z = minZ, maxZ - CELL, CELL do
		local runs = {}
		local start = nil
		local x = minX
		while x <= maxX - CELL do
			if solid(x + CELL / 2, z + CELL / 2) then
				start = start or x
			elseif start then
				table.insert(runs, { start, x })
				start = nil
			end
			x += CELL
		end
		if start then
			table.insert(runs, { start, x })
		end
		local still = {}
		for _, run in runs do
			local key = run[1] .. "," .. run[2]
			local r = open[key]
			if r and r[4] - r[3] < MERGE then
				r[4] = z + CELL
			else
				if r then
					emit(r)
				end
				r = { run[1], run[2], z, z + CELL }
			end
			still[key] = r
			open[key] = nil
		end
		for _, r in open do
			emit(r)
		end
		open = still
	end
	for _, r in open do
		emit(r)
	end
end

-- The barrier slabs for a tile's walls: { CFrame, Size } each.
function WallBarriers.slabsFor(tile: number): { { cframe: CFrame, size: Vector3 } }
	local layout = Layouts.active(tile)
	local slabs = {}
	if not layout then
		return slabs
	end
	local z0 = Beach.tileRange(tile)
	for _, p in layout.Primitives do
		if p.Kind ~= "Wall" then
			continue
		end
		if p.Area then
			areaSlabs(p, tile, slabs)
			continue
		end
		-- The lines the slabs run along: a Path wall's middle line.
		local runs = {}
		do
			for i = 1, #p.Path - 1 do
				table.insert(runs, {
					Vector3.new(p.Path[i][1], 0, z0 + p.Path[i][2]),
					Vector3.new(p.Path[i + 1][1], 0, z0 + p.Path[i + 1][2]),
					math.max(p.Width - 2 * INSET, 2),
				})
			end
		end
		for _, run in runs do
			local a, b, thickness = run[1], run[2], run[3]
			-- A wall that reaches the beach's side carries on into the cliff (Beach.shapeAt), and
			-- so does its barrier.
			local reach = Beach.HalfWidth - 0.5
			if math.abs(a.X) >= reach and (a - b).Magnitude > 0.1 then
				a += (a - b).Unit * (Config.Beach.Terrain.CliffReach + 2)
			end
			if math.abs(b.X) >= reach and (b - a).Magnitude > 0.1 then
				b += (b - a).Unit * (Config.Beach.Terrain.CliffReach + 2)
			end
			local length = (b - a).Magnitude
			if length < 0.1 then
				continue
			end
			local count = math.max(1, math.ceil(length / STEP))
			-- Runs of points where the wall stands; each run is one slab.
			local runStart: number? = nil
			local low, high = math.huge, -math.huge
			local function close(lastIndex: number)
				if runStart then
					local from = a:Lerp(b, runStart / count)
					local to = a:Lerp(b, lastIndex / count)
					local span = (to - from).Magnitude + STEP
					local middle = (from + to) / 2
					local bottom = low - 2
					local top = high + ABOVE
					local direction = (b - a).Unit
					table.insert(slabs, {
						cframe = CFrame.lookAt(
							Vector3.new(middle.X, (bottom + top) / 2, middle.Z),
							Vector3.new(middle.X, (bottom + top) / 2, middle.Z) + direction
						),
						size = Vector3.new(thickness, top - bottom, span),
					})
				end
				runStart, low, high = nil, math.huge, -math.huge
			end
			for k = 0, count do
				local point = a:Lerp(b, k / count)
				local standing = Beach.feature(point.X, point.Z) >= p.Height * STANDING
				if standing then
					runStart = runStart or k
					local slope = Beach.groundY(point.Z)
					low = math.min(low, slope)
					high = math.max(high, slope + p.Height)
				else
					close(k - 1)
				end
			end
			close(count)
		end
	end
	return slabs
end

-- (Re)builds the barriers for one tile.
function WallBarriers.build(tile: number)
	local folder = folderFor(tile)
	for index, slab in WallBarriers.slabsFor(tile) do
		local part = Instance.new("Part")
		part.Name = "WallBarrier" .. index
		part.Anchored = true
		part.CanCollide = true
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = slab.size
		part.CFrame = slab.cframe
		part.Parent = folder
	end
end

function WallBarriers.buildAll()
	for tile = 1, Beach.ActiveTiles do
		WallBarriers.build(tile)
	end
end

return WallBarriers
