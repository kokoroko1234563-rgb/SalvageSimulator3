-- Normal rebirth at the shopkeeper: costs coins (rising each time), resets coins, shop
-- tools and shop vessels, and adds a coin multiplier. At each of the first rebirths the
-- player picks one reward from those they don't have yet; all remaining options are shown.
-- Kept: rebirth count, rewards, magical vessels, banked unlock items and colored coins.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Rebirth = require(Shared.Rebirth)
local Remotes = require(Shared.Remotes)
local Secrets = require(Shared.Secrets)
local Traders = require(Shared.Traders)

local DataService = require(script.Parent.DataService)
local VesselService = require(script.Parent.VesselService)

local RebirthService = {}

local notify: (Player, string) -> () = function(_player: Player, _text: string) end
local nearShop: (Player) -> boolean = function(_player: Player)
	return false
end

-- Applies reward effects that live on the character.
function RebirthService.applyEffects(player: Player)
	local profile = DataService.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not profile or not humanoid then
		return
	end
	humanoid.WalkSpeed = 16
		* (if profile.Rewards.SwiftFeet then Rebirth.SwiftFeetSpeed else 1)
		* Traders.walkMultiplier(profile.Upgrades)
end

-- Does the reset. `free` skips the cost (admin console).
function RebirthService.rebirth(player: Player, free: boolean): (boolean, string?)
	local profile = DataService.get(player)
	if not profile then
		return false, "Still loading"
	end
	if profile.PendingPick then
		return false, "Choose your reward from the last rebirth first"
	end
	local cost = Rebirth.cost(profile.Rebirths)
	if not free and profile.Coins < cost then
		return false, "You need " .. cost .. " coins to rebirth"
	end

	profile.Coins = 0
	profile.EquippedTool = nil
	profile.Rebirths += 1
	-- Shop gear goes; magical vessels, unlock items and anything else that survives stays.
	DataService.removeItemsLostOn(player, "Rebirth")
	local active = VesselService.getVessel(player)
	if active and DataService.countItemType(player, active:GetAttribute("Kind")) == 0 then
		VesselService.despawn(player)
	end

	if profile.Rebirths <= Config.Rebirth.MaxPicks then
		local options = Rebirth.remaining(profile.Rewards)
		profile.PendingPick = if #options > 0 then options else nil
	end
	DataService.changed(player)
	notify(
		player,
		string.format(
			"Rebirth %d! Coins now earn x%.1f.",
			profile.Rebirths,
			Rebirth.multiplier(profile.Rebirths)
		)
	)
	return true
end

-- True rebirth: redeem all 5 colored coins under the main shopkeeper. Resets almost
-- everything, including the rebirth count, multiplier, reward picks, magical vessels and
-- secret progress, and gives one attunement core. Unlock items, exotic items, cores and
-- attunements stay.
function RebirthService.trueRebirth(player: Player, free: boolean): (boolean, string?)
	local profile = DataService.get(player)
	if not profile then
		return false, "Still loading"
	end
	if not free then
		for _, color in Secrets.CoinOrder do
			if not profile.ColoredCoins[color] then
				return false, "You need all 5 colored coins. Missing: " .. color:lower()
			end
		end
	end

	profile.Coins = 0
	profile.Rebirths = 0
	profile.Rewards = {}
	profile.PendingPick = nil
	profile.ColoredCoins = {}
	profile.Pockets = {} -- Deep Pockets is gone with the rewards
	-- Trader upgrades go too, except permanent ones (Madame Gull's Tide Reading).
	local keptUpgrades = {}
	for id, level in profile.Upgrades do
		if Traders.Upgrades[id] and Traders.Upgrades[id].Permanent then
			keptUpgrades[id] = level
		end
	end
	profile.Upgrades = keptUpgrades
	profile.TrueRebirths += 1
	profile.Cores += 1
	DataService.removeItemsLostOn(player, "TrueRebirth")
	local active = VesselService.getVessel(player)
	if active and DataService.countItemType(player, active:GetAttribute("Kind")) == 0 then
		VesselService.despawn(player)
	end
	DataService.changed(player)
	RebirthService.applyEffects(player)
	notify(
		player,
		"True rebirth! You received an attunement core. Use it on an exotic item in your inventory."
	)
	return true
end

local function onTrueRebirth(player: Player): (boolean, string?)
	if not nearShop(player) then
		return false, "Redeem your coins with the shopkeeper"
	end
	return RebirthService.trueRebirth(player, false)
end

local function onRebirth(player: Player): (boolean, string?)
	if not nearShop(player) then
		return false, "Talk to the shopkeeper to rebirth"
	end
	return RebirthService.rebirth(player, false)
end

-- Grants a reward (from a pick, or the admin console).
function RebirthService.grantReward(player: Player, id: string)
	local profile = DataService.get(player)
	if not profile or not Rebirth.Rewards[id] then
		return
	end
	profile.Rewards[id] = true
	DataService.changed(player)
	if id == "FloatingClamshell" and DataService.countItemType(player, "FloatingClamshell") == 0 then
		DataService.addItem(player, "FloatingClamshell", "reward")
	end
	RebirthService.applyEffects(player)
end

local function onChoose(player: Player, id: any): (boolean, string?)
	local profile = DataService.get(player)
	if not profile or not profile.PendingPick or type(id) ~= "string" then
		return false, "Nothing to choose"
	end
	if not table.find(profile.PendingPick, id) then
		return false, "That isn't one of your options"
	end
	profile.PendingPick = nil
	RebirthService.grantReward(player, id)
	notify(player, "You chose " .. Rebirth.Rewards[id].Name .. "!")
	if id == "FloatingClamshell" then
		notify(player, "Spawn your Floating Clamshell from the shop.")
	end
	return true
end

function RebirthService.init(notifyFn: (Player, string) -> (), nearShopFn: (Player) -> boolean)
	notify = notifyFn
	nearShop = nearShopFn
	Remotes.handle("Rebirth", onRebirth)
	Remotes.handle("ChooseReward", onChoose)
	Remotes.handle("TrueRebirth", onTrueRebirth)

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid")
			RebirthService.applyEffects(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	DataService.onLoaded(function(player)
		RebirthService.applyEffects(player)
	end)
end

return RebirthService
