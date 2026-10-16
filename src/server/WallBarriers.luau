-- Invisible barriers inside the layouts' Walls. Smooth terrain rounds a wall's sides off into
-- rough slopes a player can scramble up, so each wall gets a solid, invisible slab down its
-- middle, a little narrower than the wall and well above its top (more than a jump), that
-- nobody gets over. Where a ramp or a flat cuts through a wall, the barrier stops too, so the
-- gap stays open. Rebuilt with the tile's terrain whenever its layout changes.

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
local AREA_IN = 4 -- studs inside an Area wall's edge its slabs run
local AREA_THICKNESS = 4

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
		-- The lines the slabs run along: a Path wall's middle line; an Area wall's edges, moved
		-- in by AREA_IN (a slab down each side, inside the rock).
		local runs = {}
		if p.Area then
			local area = p.Area
			local cx, cz = 0, 0
			for _, point in area do
				cx += point[1] / #area
				cz += point[2] / #area
			end
			for i = 1, #area do
				local a, b = area[i], area[i % #area + 1]
				local along = Vector3.new(b[1] - a[1], 0, b[2] - a[2])
				if along.Magnitude < 0.1 then
					continue
				end
				local normal = Vector3.new(-along.Z, 0, along.X).Unit
				local middle = Vector3.new((a[1] + b[1]) / 2, 0, (a[2] + b[2]) / 2)
				if (Vector3.new(cx, 0, cz) - middle):Dot(normal) < 0 then
					normal = -normal
				end
				local inset = normal * AREA_IN
				table.insert(runs, {
					Vector3.new(a[1], 0, z0 + a[2]) + inset,
					Vector3.new(b[1], 0, z0 + b[2]) + inset,
					AREA_THICKNESS,
				})
			end
		else
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
