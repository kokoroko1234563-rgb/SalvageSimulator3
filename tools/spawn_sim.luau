--[[
	Simulates the item spawner over whole tides with a virtual clock (no players, nobody
	collecting) and prints how many items each zone got per tide and how many free items lay in
	each zone and in the surf on average. The item lifetimes, drowning and the loot spots are the
	real ones (ItemService's own ticks run against the simulated tide).

	Usage (from the repo root): lune run tools/spawn_sim.luau [tides] [crowd]
	  tides  how many tides to simulate after one to warm up (default 3)
	  crowd  the players on the server, bots included (default 1: solo)
]]

local process = require("@lune/process")

local Harness = require("./tests/harness")

local h = Harness.new(process.cwd)
local Beach = h.require("Shared/Beach")
local Config = h.require("Shared/Config")
local Tide = h.require("Shared/Tide")
local ItemService = h.require("Server/ItemService")

local tides = tonumber(process.args[1]) or 3
local crowd = tonumber(process.args[2]) or 1
ItemService.setBotCount(crowd - 1)

local length = Tide.cycleLength()
local clockTime = 0
ItemService._setClock(function()
	return clockTime
end)

local zones = #Config.Zones
local made, spots = {}, 0
for zone = 1, zones do
	made[zone] = 0
end
local counting = false
ItemService.onCreated(function(item)
	if counting then
		local zone = item:GetAttribute("Zone")
		made[zone] += 1
	end
end)

local step = Config.Items.SpawnInterval
local sums, surfSum, samples = {}, 0, 0
for zone = 1, zones do
	sums[zone] = 0
end
local spotsBefore = 0
local total = (tides + 1) * length
local nextMaintain = 0
while clockTime < total do
	clockTime += step
	if not counting and clockTime >= length then
		counting = true
		spotsBefore = ItemService.stats.SpotSpawned
	end
	ItemService._spawnTick()
	if clockTime >= nextMaintain then
		ItemService._maintenanceTick()
		nextMaintain = clockTime + 0.5
	end
	if counting and math.floor(clockTime / 5) ~= math.floor((clockTime - step) / 5) then
		local sea = Tide.sea(clockTime)
		samples += 1
		for item in ItemService.all() do
			local state = ItemService.getState(item)
			if state == "Unclaimed" or state == "Loose" then
				local zone = Beach.zoneAt(item.CFrame.Position.Z)
				if zone and zone >= 1 then
					sums[zone] += 1
				end
				local depth = Beach.depthAt(item.CFrame.Position, sea)
				if depth > -1 and depth < Config.Beach.WaistDepth then
					surfSum += 1
				end
			end
		end
	end
end
spots = ItemService.stats.SpotSpawned - spotsBefore

print(string.format("crowd %d, %d tides of %d s", crowd, tides, length))
print("zone  spawned/tide  avg free items lying in it")
local grand = 0
for zone = 1, zones do
	local perTide = made[zone] / tides
	grand += perTide
	print(string.format("%4d  %12.0f  %6.1f", zone, perTide, sums[zone] / samples))
end
print(
	string.format(
		"total %11.0f  (of which loot spots %.0f); avg in the surf %.1f",
		grand,
		spots / tides,
		surfSum / samples
	)
)
