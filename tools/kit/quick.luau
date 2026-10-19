--[[
	The quick check for one zone's layout (tools/kit/quick.py runs it): what's wrong with its
	definition, and for each choice asked for, what's wrong with that way it comes out and its
	paths: how many, how long against the zone's target, which carts get down.

	Usage: lune run tools/kit/quick.luau <zone> <Zones/Zone5 | Biomes/Id | Biomes/Planned/Id> [choice...]
	(choices as Layouts.encode: "2:" for crossing 2 with the first rooms, "2:1,3" for rooms too;
	none: every crossing with its first rooms)
]]

local process = require("@lune/process")

local Harness = require("../tests/harness")
local PathCheck = require("../paths")

local h = Harness.new(process.cwd)
local Beach = h.require("Shared/Beach")
local Config = h.require("Shared/Config")
local Layouts = h.require("Shared/Layouts")

local zone = tonumber(process.args[1]) or error("which zone?")
local source = process.args[2] or ("Zones/Zone" .. zone)
local def
if string.match(source, "^Zones/") then
	def = Layouts.base(zone)
elseif string.match(source, "^Biomes/Planned/") then
	def = Layouts.forPlanned(string.sub(source, #"Biomes/Planned/" + 1), zone)
else
	def = Layouts.forBiome(string.gsub(source, "^Biomes/", ""), zone)
end
assert(def, "no layout " .. source .. " for zone " .. zone)

local bad = 0
for _, problem in Layouts.defProblems(def, source) do
	print("PROBLEM " .. problem)
	bad += 1
end

local choices = {}
local VERBOSE = false
for i = 3, #process.args do
	if process.args[i] == "--routes" then
		VERBOSE = true
	else
		table.insert(choices, process.args[i])
	end
end
-- With none given: every way it can come out (each crossing, then each other room).
local roomsOnly = {}
if #choices == 0 then
	for _, way in Layouts.options(def) do
		local text = Layouts.encode(way.Choice)
		table.insert(choices, text)
		roomsOnly[text] = string.find(way.Label, "slot") ~= nil
	end
end

-- Whether each find and entrance can be walked to from the zone's top edge (a room the
-- frame's lanes never reach, a pocket sealed by a wall), by flood fill on the game's ground.
local STEP = 2
local function unreachable(): { string }
	local z0, z1 = Beach.tileRange(zone)
	local slope = Config.Beach.Terrain.FootSlope * STEP
	local n = math.floor((Beach.HalfWidth - 2) / STEP)
	local rows = math.floor((z1 - z0) / STEP)
	local height, reached = {}, {}
	local function key(col, row)
		return row * (2 * n + 1) + col + n
	end
	local function ground(col, row)
		local k = key(col, row)
		if not height[k] then
			height[k] = Beach.groundAt(col * STEP, z0 + row * STEP)
		end
		return height[k]
	end
	local queue = {}
	for col = -n, n do
		reached[key(col, 0)] = true
		table.insert(queue, { col, 0 })
	end
	local head = 1
	while head <= #queue do
		local col, row = queue[head][1], queue[head][2]
		head += 1
		local here = ground(col, row)
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local c, r = col + d[1], row + d[2]
			if c >= -n and c <= n and r >= 0 and r <= rows and not reached[key(c, r)] then
				if math.abs(ground(c, r) - here) <= slope then
					reached[key(c, r)] = true
					table.insert(queue, { c, r })
				end
			end
		end
	end
	local layout: any = Layouts.active(zone)
	local found = {}
	local function check(what: string, at, radius: number)
		local reach = math.max(radius, 4)
		for col = math.ceil((at[1] - reach) / STEP), math.floor((at[1] + reach) / STEP) do
			for row = math.ceil((at[2] - reach) / STEP), math.floor((at[2] + reach) / STEP) do
				if reached[key(col, row)] then
					return
				end
			end
		end
		table.insert(
			found,
			string.format("%s at (%d, %d) can't be walked to from the top", what, at[1], at[2])
		)
	end
	for _, spot in layout.Loot or {} do
		check("loot", spot.At, spot.Radius or 4)
	end
	for _, at in layout.Entrances or {} do
		check("the entrance", at, 4)
	end
	return found
end

local target = Config.Zones[zone].CrossTime
for _, text in choices do
	local choice = Layouts.decode(def, text)
	local crossing = def.Crossings and def.Crossings[choice.Crossing]
	local label = if crossing and crossing.Name then " (" .. crossing.Name .. ")" else ""
	if roomsOnly[text] then
		for index, room in choice.Rooms do
			if room ~= 1 then
				label = string.format(" (%s: %s)", def.Slots[index].Name, def.Slots[index].Rooms[room].Name)
			end
		end
	end
	print(string.format("%s %s%s", source, text, label))
	Layouts.setActive(zone, def, nil, choice)
	for _, problem in Layouts.problems(Layouts.active(zone)) do
		print("  PROBLEM " .. problem)
		bad += 1
	end
	for _, problem in unreachable() do
		print("  PROBLEM " .. problem)
		bad += 1
	end
	if roomsOnly[text] then
		-- A room is a dead end off the frame: the crossing's paths are as they were.
		Layouts.setActive(zone, nil)
		continue
	end
	local report = PathCheck.analyse(Beach, Config, zone)
	for _, line in PathCheck.describe(report, target) do
		print("  " .. line)
	end
	if VERBOSE then
		for i, path in report.paths do
			local points = {}
			for _, point in path.turns do
				table.insert(points, string.format("(%d, %d)", point[1], point[2]))
			end
			print(string.format("  path %d goes %s", i, table.concat(points, " ")))
		end
	end
	local wanted = (crossing and crossing.Paths) or def.Paths
	if wanted then
		for _, problem in PathCheck.problems(Config, report, wanted, target) do
			print("  PROBLEM " .. problem)
			bad += 1
		end
	end
	Layouts.setActive(zone, nil)
end
print(if bad == 0 then "no problems" else bad .. " problem(s)")
process.exit(if bad == 0 then 0 else 1)
