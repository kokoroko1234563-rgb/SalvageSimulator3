-- Builds the beach and the seabed as smooth Terrain from Beach.groundAt: the even slope plus
-- the ridges and troughs of Config.Beach.Terrain, the channel to the Far Sandbar, the sandbar
-- and the sea floor beyond. Terrain collides and blocks the view, so the lower zones are hidden
-- from the top and slow to cross. The tallest ridges in the rough zones are rock spines.
-- Props sit on it by placing themselves with Beach.groundAt.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Palette = require(Shared.Palette)

local TerrainBuilder = {}

local beach = Config.Beach
local shape = beach.Terrain
local VOXEL = shape.Voxel
local SLAB = 32 -- voxels along Z written per call, to keep memory down

-- The area the terrain covers: the whole beach and seabed, a little past the sides.
function TerrainBuilder.bounds(): (Vector3, Vector3)
	local half = Beach.HalfWidth + 40
	local zEnd = Beach.Depth + beach.SeaExtent
	local low = Beach.groundY(zEnd) - beach.FarSandbar.ChannelDepth - 12
	local high = 12
	local function snap(v: number, up: boolean): number
		return (if up then math.ceil(v / VOXEL) else math.floor(v / VOXEL)) * VOXEL
	end
	return Vector3.new(snap(-half, false), snap(low, false), 0),
		Vector3.new(snap(half, true), snap(high, true), snap(zEnd, true))
end

-- Material for the ground at (x, z): rock where a ridge stands taller than its zone's Rock.
local function materialAt(x: number, z: number): Enum.Material
	local zone = Beach.zoneAt(z)
	local spec = zone and zone > 0 and shape.Zones[zone]
	if spec and spec.Rock and Beach.feature(x, z) > spec.Rock then
		return Palette.Material.Rock
	end
	return Palette.Material.Sand
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
			local h = Beach.groundAt(x, z)
			local material = materialAt(x, z)
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

function TerrainBuilder.build()
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		return -- tools/tests: no Terrain to write to
	end
	terrain:SetMaterialColor(Palette.Material.Sand, Palette.World.Sand)
	terrain:SetMaterialColor(Palette.Material.Rock, Palette.World.Rock)
	local lo, hi = TerrainBuilder.bounds()
	local z0 = lo.Z
	while z0 < hi.Z do
		local z1 = math.min(z0 + SLAB * VOXEL, hi.Z)
		local materials, occupancy = TerrainBuilder.slab(lo, hi, z0, z1)
		local region = Region3.new(Vector3.new(lo.X, lo.Y, z0), Vector3.new(hi.X, hi.Y, z1))
		terrain:WriteVoxels(region, VOXEL, materials, occupancy)
		z0 = z1
	end
end

return TerrainBuilder
