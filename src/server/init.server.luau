-- Salvage Simulator 3, Milestone 1 server entry point.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Remotes = require(Shared.Remotes)
local Tide = require(Shared.Tide)

local AdminService = require(script.AdminService)
local BeachBuilder = require(script.BeachBuilder)
local CollisionGroups = require(script.CollisionGroups)
local DataService = require(script.DataService)
local DrowningService = require(script.DrowningService)
local GrabService = require(script.GrabService)
local ItemService = require(script.ItemService)
local ShopService = require(script.ShopService)
local VesselService = require(script.VesselService)

Remotes.init()

local notifyRemote = Remotes.get("Notify")
local function notify(player: Player, text: string)
	notifyRemote:FireClient(player, text)
end

-- Every machine derives the tide from this one shared timestamp.
Workspace:SetAttribute(Tide.StartAttribute, Workspace:GetServerTimeNow())

local map = BeachBuilder.build()

-- Order matters for PlayerRemoving: items are released before vessels are removed.
CollisionGroups.init()
DataService.init()
ItemService.init(map)
VesselService.init(notify)
GrabService.init(notify)
ShopService.init(map, notify)
DrowningService.init()
AdminService.init()
