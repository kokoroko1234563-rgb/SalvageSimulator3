-- Sends each player their inventory as data (attributes can't hold it) and handles what
-- they do from the inventory screen: equip a tool or accessory, spawn a vessel, attune to an
-- exotic item type, change a setting.
-- The items themselves live on the saved profile; DataService is the only thing that
-- adds or removes them.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Catalog)
local Gear = require(Shared.Gear)
local Hotbar = require(Shared.Hotbar)
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
			Winner = record.Winner,
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
	local attunements = {}
	for id in profile.Attunements do
		table.insert(attunements, id)
	end
	table.sort(attunements)
	return {
		Items = items,
		ColoredCoins = coins,
		Cores = profile.Cores,
		Attunements = attunements,
		TrueRebirths = profile.TrueRebirths,
		EquippedAccessory = player:GetAttribute("Accessory"),
		EquippedCosmetic = player:GetAttribute("Cosmetic"),
		Lexicon = (function()
			local found = {}
			for id in profile.Lexicon do
				table.insert(found, id)
			end
			return found
		end)(),
		Upgrades = profile.Upgrades,
		PocketSlots = player:GetAttribute("PocketSlots"),
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
		if
			not record
			or not entry
			or (entry.Category ~= "Tool" and entry.Category ~= "Accessory" and entry.Category ~= "Cosmetic")
		then
			return false, "You can't equip that"
		end
		if not DataService.canUse(player, record.Id) then
			return false, "Attune to " .. entry.Name .. " first (1 attunement core)"
		end
		if entry.Category == "Tool" then
			profile.EquippedTool = record.Id
		elseif entry.Category == "Cosmetic" then
			profile.EquippedCosmetic = record.Id
		else
			profile.EquippedAccessory = record.Id
		end
		DataService.changed(player)
		return true
	elseif action == "unequip" then
		local record, entry = findRecord(player, arg)
		if record and entry and entry.Category == "Cosmetic" then
			profile.EquippedCosmetic = nil
			DataService.changed(player)
			return true
		end
		if not record or not entry or entry.Category ~= "Accessory" then
			return false, "Nothing to take off"
		end
		local slotsAfter = DataService.pocketSlots(player) - (Gear.getAccessory(record.Id).PocketSlots or 0)
		if #profile.Pockets > slotsAfter then
			return false, "Take some items out of your pockets first"
		end
		profile.EquippedAccessory = nil
		DataService.changed(player)
		return true
	elseif action == "spawn" then
		local record, entry = findRecord(player, arg)
		if not record or not entry or entry.Category ~= "Vessel" then
			return false, "That isn't a vessel"
		end
		return ShopService.spawnVessel(player, record.Id)
	elseif action == "attune" then
		-- Attunement is to the item type, not this copy: trade it away, get another later,
		-- and it still works without a new core.
		local record, entry = findRecord(player, arg)
		if not record or not entry or not entry.Exotic then
			return false, "Only exotic items need attuning"
		end
		if profile.Attunements[record.Id] then
			return false, "You're already attuned to " .. entry.Name
		end
		if profile.Cores < 1 then
			return false, "You need an attunement core. True rebirth gives you one."
		end
		profile.Cores -= 1
		profile.Attunements[record.Id] = true
		DataService.changed(player)
		return true, "Attuned to " .. entry.Name .. "!"
	elseif action == "equipTool" then
		-- From the hotbar: tools are owned per type, so it names the tool, not a copy.
		local tool = Gear.findTool(arg)
		if not tool or not DataService.ownedTypes(player)[tool.Id] then
			return false, "You don't have that tool"
		end
		if not DataService.canUse(player, tool.Id) then
			return false, "Attune to " .. tool.Name .. " first (1 attunement core)"
		end
		profile.EquippedTool = tool.Id
		DataService.changed(player)
		return true
	elseif action == "hotbar" then
		-- Put a tool in a hotbar slot ("" empties it). A tool already on the bar swaps places.
		local slot = tonumber(arg)
		if not slot or slot ~= math.floor(slot) or slot < 1 or slot > Hotbar.Slots then
			return false, "No such hotbar slot"
		end
		if value ~= "" then
			local tool = Gear.findTool(value)
			if not tool or not DataService.ownedTypes(player)[tool.Id] then
				return false, "Only tools you own go on the hotbar"
			end
		end
		Hotbar.place(profile.Hotbar, slot, value)
		DataService.changed(player)
		return true
	elseif action == "setting" then
		if
			(arg == "HideShopGear" or arg == "ShowResetText" or arg == "MuteMusic")
			and type(value) == "boolean"
		then
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
	Remotes.handle("InventoryAction", onAction)

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
