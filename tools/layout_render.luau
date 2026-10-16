--[[
	Samples one way a zone comes out, for tools/layout_render.py to draw: the ground every 2
	studs (height over the slope, rock, roof, ramp) and its placements, as JSON.

	Usage: lune run tools/layout_render.luau <zone> <Base | biome id> <choice>
	(choice as Layouts.encode: "2:1,1,3"; "1:" for the first of everything)
]]

local process = require("@lune/process")
local serde = require("@lune/serde")

local Harness = require("./tests/harness")

local h = Harness.new(process.cwd)
local Beach = h.require("Shared/Beach")
local Layouts = h.require("Shared/Layouts")

local zone = tonumber(process.args[1]) or error("which zone?")
local spec = process.args[2] or "Base"
local def = if spec == "Base" then Layouts.base(zone) else Layouts.forBiome(spec, zone)
assert(def, "no layout")
local choice = Layouts.decode(def, process.args[3] or "1:")
Layouts.setActive(zone, def, nil, choice)
local layout: any = Layouts.active(zone)
local z0, z1 = Beach.tileRange(zone)

local STEP = 2
local function inRamp(x: number, z: number): boolean
	for _, p in layout.Primitives do
		if p.Kind == "Ramp" then
			for i = 1, #p.Path - 1 do
				local a, b = p.Path[i], p.Path[i + 1]
				local dx, dz = b[1] - a[1], b[2] - a[2]
				local len2 = dx * dx + dz * dz
				local t = if len2 > 0 then math.clamp(((x - a[1]) * dx + (z - a[2]) * dz) / len2, 0, 1) else 0
				if math.sqrt((a[1] + dx * t - x) ^ 2 + (a[2] + dz * t - z) ^ 2) <= p.Width / 2 then
					return true
				end
			end
		end
	end
	return false
end

local rows = {}
for lz = 0, z1 - z0 - STEP, STEP do
	local row = {}
	for x = -360, 360 - STEP, STEP do
		local height, rock = Beach.shapeAt(x, z0 + lz)
		local roof = Beach.roofAt(x, z0 + lz) ~= nil
		local code = string.format("%.1f", height)
			.. (if rock then "r" else "")
			.. (if roof then "R" else "")
			.. (if inRamp(x, lz) then "=" else "")
		table.insert(row, code)
	end
	table.insert(rows, table.concat(row, " "))
end

local slots = {}
for index, slot in def.Slots or {} do
	local room = slot.Rooms[choice.Rooms[index] or 1]
	table.insert(slots, { name = slot.Name, at = slot.At, size = slot.Size, room = room and room.Name })
end
local crossing = def.Crossings and def.Crossings[choice.Crossing]
print(serde.encode("json", {
	zone = zone,
	name = def.Name,
	crossing = crossing and crossing.Name,
	choice = Layouts.encode(choice),
	step = STEP,
	rows = rows,
	loot = layout.Loot or {},
	entrances = layout.Entrances or {},
	slots = slots,
	hazards = layout.Hazards or {},
}))
