--[[
	Where each biome's secret door can stand, for every zone it rolls in and every way that zone
	can come out (each crossing, each other room): how many ways have a door, how many have one
	in clear ground (nothing under the model: no rock, no roof, a flat enough footprint) and far
	off the cart route, and what is wrong with the rest.

	Usage: lune run tools/entrances.luau [BiomeId ...]   (none: the ten biomes with rooms)
]]

local process = require("@lune/process")

local Harness = require("./tests/harness")

local h = Harness.new(process.cwd)
local Beach = h.require("Shared/Beach")
local Biomes = h.require("Shared/Biomes")
local Layouts = h.require("Shared/Layouts")
local Secrets = h.require("Shared/Secrets")

local FOOT = 10 -- the model's footprint: this many studs either side of the spot
local STEP = 2.5
local FLAT = 3 -- the most the ground may differ across the footprint
local FAR = 60 -- a door this far from every cart route counts as far off

local ids = {}
for i = 1, #process.args do
	table.insert(ids, process.args[i])
end
if #ids == 0 then
	for id, biome in Biomes.List do
		if biome.Secret and Secrets.isRoom(Secrets.List[biome.Secret]) then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
end

local function distanceToPath(path, x: number, z: number): number
	local best = math.huge
	for i = 1, #path - 1 do
		local a, b = path[i], path[i + 1]
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local len2 = dx * dx + dz * dz
		local t = if len2 == 0 then 0 else math.clamp(((x - a[1]) * dx + (z - a[2]) * dz) / len2, 0, 1)
		best = math.min(best, math.sqrt((x - a[1] - t * dx) ^ 2 + (z - a[2] - t * dz) ^ 2))
	end
	return best
end

-- What is wrong under the model at a tile spot, or nil.
local function footprint(tile: number, x: number, lz: number): string?
	local z0 = Beach.tileRange(tile)
	local low, high = math.huge, -math.huge
	local steps = math.floor(FOOT / STEP)
	for ix = -steps, steps do
		for iz = -steps, steps do
			local px, pz = x + ix * STEP, z0 + lz + iz * STEP
			local _, rock = Beach.shapeAt(px, pz)
			if rock then
				return string.format("rock at (%d, %d)", px, pz - z0)
			end
			if Beach.roofAt(px, pz) then
				return string.format("a roof over (%d, %d)", px, pz - z0)
			end
			local y = Beach.groundAt(px, pz)
			low, high = math.min(low, y), math.max(high, y)
		end
	end
	if high - low > FLAT then
		return string.format("ground varies by %.1f", high - low)
	end
	return nil
end

local totalBad = 0
for _, id in ids do
	local biome = Biomes.List[id]
	local zones = {}
	for zone in biome.Zones do
		table.insert(zones, zone)
	end
	table.sort(zones)
	for _, zone in zones do
		local def = Layouts.forBiome(id, zone)
		if not def then
			continue
		end
		local options = Layouts.options(def)
		local withDoor, farDoor, roomDoor, problems = 0, 0, 0, {}
		for _, way in options do
			local layout: any = Layouts.compose(def, way.Choice)
			local spots = layout.Entrances or {}
			if #spots > 0 then
				withDoor += 1
			end
			local ramps = {}
			for _, p in layout.Primitives or {} do
				if p.Kind == "Ramp" then
					table.insert(ramps, p.Path)
				end
			end
			local far, inRoom = false, false
			Layouts.setActive(zone, id, zone, way.Choice)
			for _, at in spots do
				local bad = footprint(zone, at[1], at[2])
				local near = math.huge
				for _, path in ramps do
					near = math.min(near, distanceToPath(path, at[1], at[2]))
				end
				if bad then
					table.insert(
						problems,
						string.format(
							"  %s: door (%d, %d): %s",
							way.Label ~= "" and way.Label or "base",
							at[1],
							at[2],
							bad
						)
					)
				elseif near >= FAR then
					far = true
					for _, slot in def.Slots or {} do
						if
							at[1] >= slot.At[1]
							and at[1] <= slot.At[1] + slot.Size[1]
							and at[2] >= slot.At[2]
							and at[2] <= slot.At[2] + slot.Size[2]
						then
							inRoom = true
						end
					end
				end
			end
			Layouts.setActive(zone, nil)
			if inRoom then
				roomDoor += 1
			end
			if far then
				farDoor += 1
			end
		end
		print(
			string.format(
				"%-17s zone %d: %d ways, %d with a door, %d with a clear far-off door (%d in a side room)",
				id,
				zone,
				#options,
				withDoor,
				farDoor,
				roomDoor
			)
		)
		for _, line in problems do
			print(line)
			totalBad += 1
		end
	end
end
if totalBad > 0 then
	process.exit(1)
end
