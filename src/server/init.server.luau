-- Salvage Simulator 3 server entry point (Milestones 1 and 2).

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Validate = require(Shared.Validate)
local Tide = require(Shared.Tide)
local DayCycle = require(Shared.DayCycle)

local AdminService = require(script.AdminService)
local AccessoryService = require(script.AccessoryService)
local Showroom = require(script.Showroom)
local ShowroomExhibits = require(script.ShowroomExhibits)
local AuctionService = require(script.AuctionService)
local BeachBuilder = require(script.BeachBuilder)
local BiomeService = require(script.BiomeService)
local CollisionGroups = require(script.CollisionGroups)
local CosmeticService = require(script.CosmeticService)
local DataService = require(script.DataService)
local DrowningService = require(script.DrowningService)
local GrabService = require(script.GrabService)
local InventoryService = require(script.InventoryService)
local LexiconService = require(script.LexiconService)
local ItemService = require(script.ItemService)
local PocketService = require(script.PocketService)
local RebirthService = require(script.RebirthService)
local SecretService = require(script.SecretService)
local SurfService = require(script.SurfService)
local FarSandbarService = require(script.FarSandbarService)
local MonetizationService = require(script.MonetizationService)
local ShopService = require(script.ShopService)
local ToolModels = require(script.ToolModels)
local SkyBeamService = require(script.SkyBeamService)
local TradeService = require(script.TradeService)
local TraderService = require(script.TraderService)
local VesselService = require(script.VesselService)

Remotes.init()

-- Check that the game's data fits together before anything uses it.
do
	local problems = Validate.run({
		VesselBuilders = VesselService._builders,
		Entrances = BiomeService._entranceBuilders,
		Hazards = BiomeService._hazards,
	})
	for _, problem in problems do
		warn("[Validate] " .. problem)
	end
	if #problems > 0 then
		task.spawn(error, string.format("[Validate] %d data problem(s), see the warnings above", #problems))
	end
end

local notifyRemote = Remotes.get("Notify")
local function notify(player: Player, text: string)
	notifyRemote:FireClient(player, text)
end

-- Every machine derives the tide from this one shared timestamp.
Workspace:SetAttribute(Tide.StartAttribute, Workspace:GetServerTimeNow())
-- Each server's sea gets its own pattern of waterline and waves.
Workspace:SetAttribute(Tide.SeedAttribute, Random.new():NextInteger(1, 999999))
-- The day/night clock starts at Config.Day.StartHour on a new server.
Workspace:SetAttribute(
	DayCycle.StartAttribute,
	DayCycle.startFor(Config.Day.StartHour, Workspace:GetServerTimeNow())
)

local map = BeachBuilder.build()

-- Order matters for PlayerRemoving: items are released before vessels are removed.
CollisionGroups.init()
DataService.init()
ItemService.init(map)
SurfService.init()
SkyBeamService.init()
VesselService.init(notify)
GrabService.init(notify)
PocketService.init(notify)
ShopService.init(map, notify)
InventoryService.init()
TradeService.init(notify)
DrowningService.init()
SecretService.init(notify)
TraderService.init(notify) -- before biomes roll, so traders can appear in the first tide
BiomeService.init(SecretService.tryEnter, notify)
FarSandbarService.init(map, SecretService.tryEnter)
LexiconService.init(notify)
CosmeticService.init()
ToolModels.init()
AccessoryService.init()
RebirthService.init(notify, ShopService.nearShop)
AuctionService.init(notify)
MonetizationService.init(notify)
AdminService.init()

-- The showroom (admins: tp showroom). Built last, off the startup path: some exhibits load
-- avatars, which waits on Roblox.
if Config.Showroom.Enabled then
	task.spawn(function()
		Showroom.build(Workspace, ShowroomExhibits())
	end)
end
