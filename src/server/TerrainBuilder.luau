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
local function shrunkShape(x: number, z: number): (number, boolean)
	local height, rock = Beach.shapeAt(x, z)
	for _, offset in AROUND do
		local h = Beach.shapeAt(x + offset[1], z + offset[2])
		if h < height then
			height = h
		end
	end
	return height, rock
end

-- The roof over (x, z), shrunk sideways the same way: only where there's roof all round.
local function shrunkRoof(x: number, z: number): (number?, number?)
	local bottom, top = Beach.roofAt(x, z)
	if not bottom then
		return nil, nil
	end
	for _, offset in AROUND do
		if not Beach.roofAt(x + offset[1], z + offset[2]) then
			return nil, nil
		end
	end
	return bottom, top
end

-- The area the terrain covers: the whole beach and seabed, a little past the sides.
function TerrainBuilder.bounds(): (Vector3, Vector3)
	local half = Beach.HalfWidth + 40
	local zEnd = Beach.Depth + beach.SeaExtent
	local low = Beach.groundY(zEnd) - beach.FarSandbar.ChannelDepth - 12
	local high = 4 + math.max(shape.MaxHeight, shape.WallMaxHeight, shape.RoofMaxTop)
	local function snap(v: number, up: boolean): number
		return (if up then math.ceil(v / VOXEL) else math.floor(v / VOXEL)) * VOXEL
	end
	return Vector3.new(snap(-half, false), snap(low, false), 0),
		Vector3.new(snap(half, true), snap(high, true), snap(zEnd, true))
end

-- The voxels for one slab (Z from z0 to z1): materials and occupancy, [x][y][z].
function TerrainBuilder.slab(lo: Vector3, hi: Vector3, z0: number, z1: number)
	local nx = (hi.X - lo.X) / VOXEL
	local ny = (hi.Y - lo.Y) / VOXEL
	local nz = (z1 - z0) / VOXEL
	local materials, occupancy = table.create(nx), table.create(nx)
	for ix = 1, nx do
		local x = lo.X + (ix - 0.5) * VOXEL
		local mx, ox = table.create(ny), table.create(ny)
		for iy = 1, ny do
			mx[iy] = table.create(nz, Enum.Material.Air)
			ox[iy] = table.create(nz, 0)
		end
		for iz = 1, nz do
			local z = z0 + (iz - 0.5) * VOXEL
			local height, rock = shrunkShape(x, z)
			local h = Beach.groundY(z) + height - DRAWN_BIGGER
			local floorMaterial, rockMaterial = Looks.terrainAt(x, z)
			local material = if rock then rockMaterial else floorMaterial
			local roofBottom, roofTop = shrunkRoof(x, z)
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
						mx[iy][iz] = rockMaterial
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
