--[[
	One bot task of the sweep, run inside the real Roblox engine (Open Cloud Luau Execution, in the
	Test Range place; tools/bots/sweep.py puts the job in front of this script as JOB_JSON):

	  { bots = 8, speed = 10, seconds = 200 }                 X bots play for `seconds` real seconds
	  { finalTrip = true, speed = 10, seconds = 250,          one bot, one trip to `zone` and back
	    zone = 6, tool = "HandWinch", vessel = "Wheelbarrow" }

	It brings up what the bots need of the server (the tide, the item system with its real spawn
	rules, collision groups) without building the map's terrain: the bots walk the layouts' ground
	(Beach.groundAt), which doesn't need it. Every tile has its zone's base layout (no biomes).
	It returns the report as JSON: per-bot measures, the server's item counts and the income log.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local JOB = HttpService:JSONDecode(JOB_JSON) -- luacheck: ignore (set by sweep.py)

local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)

local started = os.clock()
Workspace:SetAttribute(Tide.StartAttribute, Workspace:GetServerTimeNow())
Workspace:SetAttribute(Tide.SeedAttribute, Random.new():NextInteger(1, 999999))

require(Server.CollisionGroups).init()
local map = Instance.new("Folder")
map.Name = "Map"
map.Parent = Workspace
local ItemService = require(Server.ItemService)
ItemService.init(map)
local BotService = require(Server.BotService)

-- Config.Items.CrowdSpawn.Scale: 1 turns the crowd spawn scaler off.
if JOB.scale then
	Config.Items.CrowdSpawn = { Players = Config.Items.CrowdSpawn.Players, Scale = JOB.scale }
end
BotService.clearLog()
BotService.setSpeed(JOB.speed or 1)
-- The way-home fields are built before anyone plays, in big slices (a bot would wait for them).
-- A chained task (JOB.state, the previous task's final state) first puts the tide and the beach
-- back, since the fields read the tide, then the bots.
local warm = { {}, { Cart = "Small" }, { Cart = "Medium" } }
if JOB.state then
	BotService.importWorld(JOB.state)
end
if JOB.finalTrip then
	BotService.warmUp({ { Cart = "Small", Loose = true } })
else
	BotService.warmUp(warm)
end
local setup = os.clock() - started
if JOB.finalTrip then
	BotService.startTrip(JOB.zone or 6, JOB.tool or "HandWinch", JOB.vessel or "Wheelbarrow")
elseif JOB.state then
	BotService.importBots(JOB.state)
else
	BotService.setCount(JOB.bots, JOB.gear, JOB.gearBots)
end
local series = { BotService.progress() }

-- The first seconds build models and routes; the frame timings are for the play after.
task.wait(5)
BotService.resetFrameStats()
local deadline = os.clock() + (JOB.seconds or 200)
while os.clock() < deadline do
	task.wait(if JOB.finalTrip then 1 else 5)
	table.insert(series, BotService.progress())
	if JOB.finalTrip then
		local trip = BotService.tripResult()
		if trip and trip.Done then
			break
		end
	end
end

BotService.closeLog()
local snapshot = BotService.snapshot()
local trip = BotService.tripResult()
local logLines = BotService.report()
local result = {
	job = JOB,
	setupSeconds = setup,
	ranSeconds = os.clock() - started - setup,
	snapshot = snapshot,
	log = BotService.incomeLog(),
	trip = if trip
		then {
			zone = trip.Zone,
			tool = trip.Tool,
			vessel = trip.Vessel,
			done = trip.Done == true,
			earned = trip.Earned or 0,
			items = trip.Items or 0,
			diag = trip.Diag,
			first = trip.First,
			gameSeconds = if trip.EndedAt then (trip.EndedAt - trip.StartedAt) * (JOB.speed or 1) else nil,
			baseCost = Config.Rebirth.BaseCost,
		}
		else nil,
	report = logLines,
	series = series,
	moves = BotService.moves(),
	state = if JOB.finalTrip then nil else BotService.exportState(),
}
BotService.stop()
return HttpService:JSONEncode(result)
