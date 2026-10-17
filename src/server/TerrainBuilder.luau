-- Builds the beach and the seabed as smooth Terrain from Beach.groundAt: the even slope plus
-- each tile's layout (src/shared/Layouts), the channel to the Far Sandbar, the sandbar and the
-- sea floor beyond. Terrain collides and blocks the view, so the lower zones are hidden from
-- the top and slow to cross. Rock shapes are built from rock. When a tile's biome changes,
-- TerrainBuilder.buildTile rebuilds just that tile. Props sit on it by placing themselves
-- with Beach.groundAt.
-- The ground is a crust: it's solid for Crust studs under the surface and empty below that,
-- and each stretch is only written between the lowest and highest the ground there can be,
-- so the long beach is quick to build and rebuilding a tile always replaces all of it.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Looks = require(Shared.Looks)

local WallBarriers = require(script.Parent.WallBarriers)

local TerrainBuilder = {}

local beach = Config.Beach
local shape = beach.Terrain
local VOXEL = shape.Voxel
local SLAB = 32 -- voxels along Z written per call, to keep memory down
local CRUST = 12 -- studs of solid ground under the lowest the surface can be
-- Roblox draws every solid region of smooth terrain half a cell bigger in every direction than
-- the cells' fill says (measured in the engine with tools/range: ground filled to height h
-- shows its surface at h + 2, a roof's underside 2 lower). So the terrain is written shrunk by
-- that much all round: the ground 2 lower, roofs 2 thinner on each face, and the shapes' sides
-- 2 further in (the lowest the shape is within 2 studs), so walls and corridors come out the
-- width the layout means.
local DRAWN_BIGGER = VOXEL / 2

local AROUND = { { DRAWN_BIGGER, 0 }, { -DRAWN_BIGGER, 0 }, { 0, DRAWN_BIGGER }, { 0, -DRAWN_BIGGER } }

-- The layout's shape at (x, z) with the solid shrunk sideways by DRAWN_BIGGER (the lowest it
-- is within that distance: walls get narrower, channels wider), and whether it's rock.
local function shrunkShape(x: number, z: number): (number, boolean, string?)
	local height, rock, material = Beach.shapeAt(x, z)
	for _, offset in AROUND do
		local h = Beach.shapeAt(x + offset[1], z + offset[2])
		if h < height then
			height = h
		end
	end
	return height, rock, material
end

-- The roof over (x, z), shrunk sideways the same way: only where there's roof all round.
local function shrunkRoof(x: number, z: number): (number?, number?, string?)
	local bottom, top, material = Beach.roofAt(x, z)
	if not bottom then
		return nil, nil, nil
	end
	for _, offset in AROUND do
		if not Beach.roofAt(x + offset[1], z + offset[2]) then
			return nil, nil, nil
		end
	end
	return bottom, top, material
end

-- Behind the shoreline the terrain is the shop's dry sand (flat, height 0) and the low dunes
-- behind it: they rise from about DUNE_FOOT to about DUNE_HEIGHT over 8 studs, roll along (the
-- dune grass stands on them, MapEdge), and fall away again by DUNE_BACK. Away from the
-- boardwalk the foot wanders back and the crest rises and dips, so the dunes aren't one
-- straight bank.
local DUNE_FOOT, DUNE_HEIGHT, DUNE_TOP_END, DUNE_BACK = -74, 4, -124, -132
local DUNE_CLEAR = 70 -- the dunes run straight this far either side of the middle (the boardwalk)

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function behindShore(z: number, x: number?): number
	local px = x or 0
	local wander = smoothstep((math.abs(px) - DUNE_CLEAR) / 40)
	local foot = DUNE_FOOT - wander * 10 * (0.5 + 0.5 * math.noise(px / 70, 1.7))
	if z >= foot then
		return 0
	end
	local height = DUNE_HEIGHT + wander * 2.5 * math.noise(px / 45, 4.2) * 2
	local rise = smoothstep((foot - z) / 8)
	local fall = 1 - smoothstep((DUNE_TOP_END - z) / (DUNE_TOP_END - DUNE_BACK))
	return math.max(height, 1.5) * math.min(rise, fall)
end
TerrainBuilder.behindShore = behindShore

-- The area the terrain covers: the shop's ground and the dunes behind it, and the whole beach
-- and seabed, a little past the sides.
function TerrainBuilder.bounds(): (Vector3, Vector3)
	local half = Beach.HalfWidth + 40
	local zEnd = Beach.Depth + beach.SeaExtent
	local low = Beach.groundY(zEnd) - beach.FarSandbar.ChannelDepth - 12
	local high = 4 + math.max(shape.MaxHeight, shape.WallMaxHeight, shape.RoofMaxTop)
	local function snap(v: number, up: boolean): number
		return (if up then math.ceil(v / VOXEL) else math.floor(v / VOXEL)) * VOXEL
	end
	return Vector3.new(snap(-half, false), snap(low, false), snap(DUNE_BACK - 4, false)),
		Vector3.new(snap(half, true), snap(high, true), snap(zEnd, true))
end

-- The voxels for one slab (Z from z0 to z1): materials and occupancy, [x][y][z].
function TerrainBuilder.slab(lo: Vector3, hi: Vector3, z0: number, z1: number)
	local nx = (hi.X - lo.X) / VOXEL
	local ny = (hi.Y - lo.Y) / VOXEL
	local nz = (z1 - z0) / VOXEL
	local materials, occupancy = table.create(nx), table.create(nx)
	local materialAt = Looks.terrainReader()
	for ix = 1, nx do
		local x = lo.X + (ix - 0.5) * VOXEL
		local mx, ox = table.create(ny), table.create(ny)
		for iy = 1, ny do
			mx[iy] = table.create(nz, Enum.Material.Air)
			ox[iy] = table.create(nz, 0)
		end
		for iz = 1, nz do
			local z = z0 + (iz - 0.5) * VOXEL
			local height, rock, shapeMaterial = shrunkShape(x, z)
			if z < 0 then
				height = behindShore(z, x) -- the shop's flat sand and the dunes behind it
			end
			local h = Beach.groundY(z) + height - DRAWN_BIGGER
			local floorMaterial, rockMaterial = materialAt(x, z)
			-- A shape's own material, else a Paint's on the ground, else the zone's (Looks).
			local paint = Beach.paintAt(x, z)
			local material = if shapeMaterial
				then (Enum.Material :: any)[shapeMaterial]
				elseif rock then rockMaterial
				elseif paint then (Enum.Material :: any)[paint]
				else floorMaterial
			local roofBottom, roofTop, roofMaterial = shrunkRoof(x, z)
			local roofRock = if roofMaterial then (Enum.Material :: any)[roofMaterial] else rockMaterial
			for iy = 1, ny do
				local bottom = lo.Y + (iy - 1) * VOXEL
				local fill = math.clamp((h - bottom) / VOXEL, 0, 1)
				if fill > 0 then
					mx[iy][iz] = material
					ox[iy][iz] = fill
				end
				if roofBottom then
					-- The roof: rock between its underside and its top.
					local overlap = math.min((roofTop :: number) - DRAWN_BIGGER, bottom + VOXEL)
						- math.max(roofBottom + DRAWN_BIGGER, bottom)
					local roof = math.clamp(overlap / VOXEL, 0, 1)
					if roof > ox[iy][iz] then
						mx[iy][iz] = roofRock
						ox[iy][iz] = roof
					end
				end
			end
		end
		materials[ix], occupancy[ix] = mx, ox
	end
	return materials, occupancy
end

local function snap(v: number, up: boolean): number
	return (if up then math.ceil(v / VOXEL) else math.floor(v / VOXEL)) * VOXEL
end

-- The heights a stretch of ground (z0 to z1) can lie between, whatever its layout: from the
-- deepest a cut can go (less the crust) to the tallest a shape can stand.
function TerrainBuilder.heightRange(z0: number, z1: number): (number, number)
	local low, high = math.huge, -math.huge
	local z = z0
	while true do
		local y = Beach.groundY(z)
		low = math.min(low, y)
		high = math.max(high, y)
		if z >= z1 then
			break
		end
		z = math.min(z + VOXEL, z1)
	end
	return snap(low - shape.MaxDepth - CRUST, false),
		snap(high + math.max(shape.MaxHeight, shape.WallMaxHeight, shape.RoofMaxTop) + 4, true)
end

-- Writes the terrain between two Z positions (snapped out to whole voxels).
function TerrainBuilder.buildRange(fromZ: number, toZ: number)
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		return -- tools/tests: no Terrain to write to
	end
	local lo, hi = TerrainBuilder.bounds()
	local z0 = math.max(lo.Z, snap(fromZ, false))
	local stop = math.min(hi.Z, snap(toZ, true))
	while z0 < stop do
		local z1 = math.min(z0 + SLAB * VOXEL, stop)
		local yLow, yHigh = TerrainBuilder.heightRange(z0, z1)
		local slabLo = Vector3.new(lo.X, yLow, z0)
		local slabHi = Vector3.new(hi.X, yHigh, z1)
		local materials, occupancy = TerrainBuilder.slab(slabLo, slabHi, z0, z1)
		local region = Region3.new(slabLo, slabHi)
		terrain:WriteVoxels(region, VOXEL, materials, occupancy)
		z0 = z1
	end
end

-- Rebuilds one tile's terrain (after its layout changed).
function TerrainBuilder.buildTile(tile: number)
	local z0, z1 = Beach.tileRange(tile)
	TerrainBuilder.buildRange(z0, z1)
	WallBarriers.build(tile)
end

function TerrainBuilder.build()
	WallBarriers.buildAll()
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		return
	end
	Looks.paint(terrain)
	local lo, hi = TerrainBuilder.bounds()
	TerrainBuilder.buildRange(lo.Z, hi.Z)
end

return TerrainBuilder
