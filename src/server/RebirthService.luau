-- Normal rebirth at the shopkeeper: costs coins (rising each time), resets coins, shop
-- tools and shop vessels, and adds a coin multiplier. At each of the first rebirths the
-- player picks one reward from those they don't have yet; all remaining options are shown.
-- Kept: rebirth count, rewards, magical vessels, banked unlock items and colored coins.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Rebirth = require(Shared.Rebirth)
local Remotes = require(Shared.Remotes)

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
	humanoid.WalkSpeed = 16 * (if profile.Rewards.SwiftFeet then Rebirth.SwiftFeetSpeed else 1)
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
	profile.Tools = { BareHands = true }
	local keptVessels = {}
	for id in profile.Vessels do
		local def = Gear.getVessel(id)
		if def and def.Magical then
			keptVessels[id] = true
		end
	end
	profile.Vessels = keptVessels
	local active = VesselService.getVessel(player)
	if active and not keptVessels[active:GetAttribute("Kind")] then
		VesselService.despawn(player)
	end

	profile.Rebirths += 1
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
	if id == "FloatingClamshell" then
		profile.Vessels.FloatingClamshell = true
	end
	DataService.changed(player)
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
	Remotes.get("Rebirth").OnServerInvoke = onRebirth
	Remotes.get("ChooseReward").OnServerInvoke = onChoose

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
