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
		push *= 0.5
	end
	local accessory = Gear.getAccessory(player:GetAttribute("Accessory"))
	if accessory and accessory.WaveResist then
		push *= 1 - accessory.WaveResist
	end
	return math.max(Config.Traders.MinWavePush, push)
end

local function accessory(player: Player)
	return Gear.getAccessory(player:GetAttribute("Accessory"))
end

-- How many times longer a player's breath lasts.
function Stats.breath(player: Player): number
	local worn = accessory(player)
	return Traders.breathMultiplier(levels(player))
		* (if hasReward(player, "SeaLegs") then 2 else 1)
		* (1 + (if worn and worn.BreathBonus then worn.BreathBonus else 0))
end

-- How much of the water's slowdown a player shrugs off (0 = none, 1 = all).
function Stats.wadeBonus(player: Player): number
	local worn = accessory(player)
	local kept = 1 - (if worn and worn.WadeBonus then worn.WadeBonus else 0)
	-- Sea Legs: the water slows you half as much.
	if hasReward(player, "SeaLegs") then
		kept *= 0.5
	end
	return 1 - kept
end

-- The tier an exotic grabber tracks: the best shop tool in an owned-tool set ({ [id] = true }),
-- never below `floor` (the exotic's own Tier).
function Stats.trackedTier(owned: { [string]: boolean }, floor: number): number
	return math.max(floor, Gear.bestTool(owned).Tier)
end

local function ownedTools(player: Player): { [string]: boolean }
	local owned = {}
	for id in string.gmatch(player:GetAttribute("OwnedTools") or "", "[^,]+") do
		owned[id] = true
	end
	return owned
end

-- The highest zone tier a player can lift with a tool: the tool's own Tier, one more with Strong
-- Back, never past the last zone. An exotic grabber (Tracks) works up to the best shop tool the
-- player owns instead (`owned`, { [id] = true }; none = just the starting tool), at least its Tier.
function Stats.liftWith(tool, strongBack: boolean, owned: { [string]: boolean }?): number
	local tier = tool.Tier
	if tool.Tracks then
		tier = Stats.trackedTier(owned or {}, tool.Tier)
	end
	return math.min(tier + (if strongBack then 1 else 0), #Config.Zones)
end

function Stats.lift(player: Player, tool): number
	return Stats.liftWith(
		tool,
		hasReward(player, "StrongBack"),
		if tool.Tracks then ownedTools(player) else nil
	)
end

function Stats.grip(player: Player): number
	return Traders.gripMultiplier(levels(player))
end

function Stats.vesselSpeed(player: Player): number
	return Traders.vesselSpeedMultiplier(levels(player))
end

return Stats
