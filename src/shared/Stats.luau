-- Stats that several things change at once: rebirth rewards, trader upgrades and worn
-- accessories. Everything reads a player's numbers from here, so the sources stack the
-- same way everywhere and the caps (waves always push at least 30%) are applied once.
-- Reads only player attributes, so server and client agree.

local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)
local Rebirth = require(script.Parent.Rebirth)
local Traders = require(script.Parent.Traders)

local Stats = {}

local function hasReward(player: Player, id: string): boolean
	return string.find("," .. (player:GetAttribute("Rewards") or "") .. ",", "," .. id .. ",", 1, true) ~= nil
end
Stats.hasReward = hasReward

local function levels(player: Player)
	return Traders.parseLevels(player:GetAttribute("Upgrades"))
end

function Stats.walkSpeed(player: Player): number
	return 16
		* (if hasReward(player, "SwiftFeet") then Rebirth.SwiftFeetSpeed else 1)
		* Traders.walkMultiplier(levels(player))
end

-- How strongly waves push this player (1 = fully). Never below Config.Traders.MinWavePush.
function Stats.wavePush(player: Player): number
	local push = Traders.wavePushMultiplier(levels(player))
	if hasReward(player, "SeaLegs") then
		push *= 0.6
	end
	local accessory = Gear.getAccessory(player:GetAttribute("Accessory"))
	if accessory and accessory.WaveResist then
		push *= 1 - accessory.WaveResist
	end
	return math.max(Config.Traders.MinWavePush, push)
end

-- How many times longer a player's breath lasts.
function Stats.breath(player: Player): number
	return Traders.breathMultiplier(levels(player)) * (if hasReward(player, "SeaLegs") then 2 else 1)
end

-- The heaviest weight class a player can lift with a tool.
function Stats.lift(player: Player, tool): number
	return math.min(
		tool.Lift + (if hasReward(player, "StrongBack") then 1 else 0),
		Gear.WeightClass.VeryHeavy
	)
end

function Stats.grip(player: Player): number
	return Traders.gripMultiplier(levels(player))
end

function Stats.vesselSpeed(player: Player): number
	return Traders.vesselSpeedMultiplier(levels(player))
end

return Stats
