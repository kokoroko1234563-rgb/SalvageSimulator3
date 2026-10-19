--[[
	Finds slots in the terrain as TerrainBuilder builds it: a single 4-stud cell of open ground
	between two walls (or the wall and a cliff), which the engine draws as a crack a character can
	squeeze through, though the layout means the walls to meet.

	lune run tools/gaps.luau <zone> [layout] [choice...]

	  layout   Base (default) or a biome id
	  choice   one or more choices (default: every crossing with its first rooms, "1:", "2:", ...)

	Prints each slot: where it is (world X, Z) and which way it runs.
]]

local process = require("@lune/process")

local Harness = require("./tests/harness")
local h = Harness.new(process.cwd)
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3

local Config = h.require("Shared/Config")
local Beach = h.require("Shared/Beach")
local Layouts = h.require("Shared/Layouts")
local TerrainBuilder = h.require("Server/TerrainBuilder")

local zone = tonumber(process.args[1]) or 5
local layoutName = process.args[2] or "Base"
local def = if layoutName == "Base" then Layouts.base(zone) else Layouts.forBiome(layoutName, zone)
assert(def, "no layout " .. layoutName .. " for zone " .. zone)

local choices = {}
for i = 3, #process.args do
	table.insert(choices, process.args[i])
end
if #choices == 0 then
	for c = 1, math.max(1, #(def.Crossings or {})) do
		table.insert(choices, c .. ":")
	end
end

local VOXEL = Config.Beach.Terrain.Voxel
local WALL = 5 -- a cell this far above the slope is wall (or rock) a character can't step onto

local z0, z1 = Beach.tileRange(zone)
local lo, hi = TerrainBuilder.bounds()
local total = 0
for _, text in choices do
	Layouts.setActive(zone, def, zone, Layouts.decode(def, text))
	-- Each cell's top (the highest solid in its column), by X and Z index.
	local tops: { [number]: { [number]: number } } = {}
	local z = z0
	while z < z1 do
		local zEnd = math.min(z + 64, z1)
		local yLow, yHigh = TerrainBuilder.heightRange(z, zEnd)
		local _, occupancy =
			TerrainBuilder.slab(Vector3.new(lo.X, yLow, z), Vector3.new(hi.X, yHigh, zEnd), z, zEnd)
		for ix = 1, #occupancy do
			local column = occupancy[ix]
			for iz = 1, #column[1] do
				-- The floor: the solid run from the bottom up (a roof above it is a separate run).
				local top = yLow
				for iy = 1, #column do
					if column[iy][iz] <= 0 then
						break
					end
					top = yLow + (iy - 1 + column[iy][iz]) * VOXEL
				end
				local gz = (z - z0) / VOXEL + iz
				tops[ix] = tops[ix] or {}
				tops[ix][gz] = top
			end
		end
		z = zEnd
	end
	local function kind(ix: number, iz: number): string?
		local top = tops[ix] and tops[ix][iz]
		if not top then
			return nil
		end
		local x = lo.X + (ix - 0.5) * VOXEL
		local wz = z0 + (iz - 0.5) * VOXEL
		local rise = top + VOXEL / 2 - Beach.groundY(wz)
		return if rise >= WALL then "wall" else "open"
	end
	local found = {}
	local walls = 0
	local function report(ix: number, iz: number, what: string)
		table.insert(
			found,
			string.format("  %s at x %d, z %d", what, lo.X + (ix - 0.5) * VOXEL, z0 + (iz - 0.5) * VOXEL)
		)
	end
	for ix, column in tops do
		for iz in column do
			local here = kind(ix, iz)
			if here == "wall" then
				walls += 1
			elseif here == "open" then
				-- One or two open cells between walls, across X or along Z.
				for width = 1, 2 do
					local across = kind(ix - 1, iz) == "wall" and kind(ix + width, iz) == "wall"
					local along = kind(ix, iz - 1) == "wall" and kind(ix, iz + width) == "wall"
					local inside = true
					for k = 1, width - 1 do
						inside = inside
							and (if across then kind(ix + k, iz) == "open" else kind(ix, iz + k) == "open")
					end
					if (across or along) and inside then
						report(
							ix,
							iz,
							string.format(
								"%d-cell slot %s",
								width,
								if across then "(walls east and west)" else "(walls north and south)"
							)
						)
					end
				end
			end
		end
	end
	print(string.format("  (%d wall cells)", walls))
	table.sort(found)
	print(string.format("zone %d %s %s: %d slot cell(s)", zone, layoutName, text, #found))
	for _, line in found do
		print(line)
	end
	total += #found
end
process.exit(if total > 0 then 1 else 0)
