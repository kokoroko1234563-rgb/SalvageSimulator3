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
local Palette = require(Shared.Palette)

local WallBarriers = require(script.Parent.WallBarriers)

local TerrainBuilder = {}

local beach = Config.Beach
local shape = beach.Terrain
local VOXEL = shape.Voxel
local SLAB = 32 -- voxels along Z written per call, to keep memory down
local CRUST = 12 -- studs of solid ground under the lowest the surface can be

-- The area the terrain covers: the whole beach and seabed, a little past the sides.
function TerrainBuilder.bounds(): (Vector3, Vector3)
	local half = Beach.HalfWidth + 40
	local zEnd = Beach.Depth + beach.SeaExtent
	local low = Beach.groundY(zEnd) - beach.FarSandbar.ChannelDepth - 12
	local high = 4 + math.max(shape.MaxHeight, shape.WallMaxHeight)
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
			local height, rock = Beach.shapeAt(x, z)
			local h = Beach.groundY(z) + height
			local material = if rock then Palette.Material.Rock else Palette.Material.Sand
			for iy = 1, ny do
				local bottom = lo.Y + (iy - 1) * VOXEL
				local fill = math.clamp((h - bottom) / VOXEL, 0, 1)
				if fill > 0 then
					mx[iy][iz] = material
					ox[iy][iz] = fill
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
		snap(high + math.max(shape.MaxHeight, shape.WallMaxHeight) + 4, true)
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
	terrain:SetMaterialColor(Palette.Material.Sand, Palette.World.Sand)
	terrain:SetMaterialColor(Palette.Material.Rock, Palette.World.Rock)
	local lo, hi = TerrainBuilder.bounds()
	TerrainBuilder.buildRange(lo.Z, hi.Z)
end

return TerrainBuilder
