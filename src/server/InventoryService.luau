-- Sends each player their inventory as data (attributes can't hold it) and handles what
-- they do from the inventory screen: equip a tool, spawn a vessel, change a setting.
-- The items themselves live on the saved profile; DataService is the only thing that
-- adds or removes them.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Catalog)
local Rebirth = require(Shared.Rebirth)
local Remotes = require(Shared.Remotes)
local Secrets = require(Shared.Secrets)

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)

local InventoryService = {}

local syncRemote
local pending: { [Player]: boolean } = {}

-- Everything the inventory screen needs, as plain data.
function InventoryService.snapshot(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return nil
	end
	local items = {}
	for uid, record in profile.Items do
		table.insert(items, {
			Uid = uid,
			Id = record.Id,
			Acquired = record.Acquired,
			Variant = record.Variant,
			Serial = record.Serial,
			Of = record.Of,
		})
	end
	table.sort(items, function(a, b)
		local ea, eb = Catalog.get(a.Id), Catalog.get(b.Id)
		if ea and eb and ea.Order ~= eb.Order then
			return ea.Order < eb.Order
		end
		return a.Acquired < b.Acquired
	end)

	local coins = {}
	for _, color in Secrets.CoinOrder do
		if profile.ColoredCoins[color] then
			table.insert(coins, color)
		end
	end
	local rewards = {}
	for _, id in Rebirth.Order do
		if profile.Rewards[id] then
			table.insert(rewards, id)
		end
	end
	return {
		Items = items,
		ColoredCoins = coins,
		Cores = profile.Cores,
		Rewards = rewards,
		Pockets = profile.Pockets,
		Settings = profile.Settings,
		EquippedTool = player:GetAttribute("Tool"),
		ActiveVessel = player:GetAttribute("ActiveVessel"),
	}
end

-- Coalesces several changes in one frame into a single sync.
local function scheduleSync(player: Player)
	if pending[player] then
		return
	end
	pending[player] = true
	task.defer(function()
		pending[player] = nil
		if player.Parent then
			syncRemote:FireClient(player, InventoryService.snapshot(player))
		end
	end)
end

local function findRecord(player: Player, uid: any)
	local profile = DataService.get(player)
	if not profile or type(uid) ~= "string" then
		return nil, nil
	end
	local record = profile.Items[uid]
	return record, record and Catalog.get(record.Id)
end

local function onAction(player: Player, action: any, arg: any, value: any): (boolean, string?)
	local profile = DataService.get(player)
	if not profile then
		return false, "Still loading"
	end

	if action == "equip" then
		local record, entry = findRecord(player, arg)
		if not record or not entry or entry.Category ~= "Tool" then
			return false, "You can't equip that"
		end
		profile.EquippedTool = record.Id
		DataService.changed(player)
		return true
	elseif action == "spawn" then
		local record, entry = findRecord(player, arg)
		if not record or not entry or entry.Category ~= "Vessel" then
			return false, "That isn't a vessel"
		end
		return ShopService.spawnVessel(player, record.Id)
	elseif action == "setting" then
		if (arg == "HideShopGear" or arg == "ShowResetText") and type(value) == "boolean" then
			profile.Settings[arg] = value
			DataService.changed(player)
			return true
		end
		return false, "Unknown setting"
	end
	return false, "Unknown action"
end

function InventoryService.init()
	syncRemote = Remotes.get("InventorySync")
	Remotes.get("GetInventory").OnServerInvoke = function(player)
		return InventoryService.snapshot(player)
	end
	Remotes.get("InventoryAction").OnServerInvoke = onAction

	DataService.onChanged(function(player)
		scheduleSync(player)
	end)
	-- The active vessel and tool live on attributes, so changes to them resync too.
	local function onPlayer(player: Player)
		player:GetAttributeChangedSignal("ActiveVessel"):Connect(function()
			scheduleSync(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
	end)
end

return InventoryService
