-- Sea mist: the haze around you thickens the further out to sea you are (each zone's and
-- biome's Look sets its Fog, Config.Looks), so the lower zones feel closed in and you can't see far ahead or back up the beach. The Lantern of
-- Clear Sight thins it. Works through the Atmosphere's density (Roblox ignores the old fog
-- settings when there's an Atmosphere), and sets the fog distances too in case there isn't one.
--
-- A Fog hazard (the Fog Bank's foghorn, Hazards.luau) closes the mist in further while you're on
-- its tile: to its Sight studs (the Atmosphere at full density and Offset, the fog distances at
-- Sight), easing in and out. Its foghorn pulse sets the part's Clearing attribute for Clear
-- seconds, and the fog lifts back to the place's own mist meanwhile. A lantern or the Lantern of
-- Clear Sight does nothing for it: it's fog, not darkness.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Hazards = require(Shared.Hazards)
local Looks = require(Shared.Looks)

local player = Players.LocalPlayer
local cfg = Config.Mist

local MistController = {}

local current: number? = nil
local FOG_IN, FOG_OUT = 1.2, 2.2 -- per second: the Fog hazard's fog closing in, and lifting
local fogShare = 0 -- how much of the Fog hazard's fog is on you (0-1)
local atmosphereOffset: number? = nil -- the Atmosphere's own Offset, remembered

-- The Sight of the Fog hazard on the tile at a point along the beach (Z) and whether its foghorn
-- is clearing it right now, or nil where there's none.
function MistController.fogAt(z: number): (number?, boolean)
	for _, part in CollectionService:GetTagged(Hazards.Tag) do
		if
			part:GetAttribute("Effect") == "Fog"
			and z >= (part:GetAttribute("ZMin") or math.huge)
			and z < (part:GetAttribute("ZMax") or -math.huge)
		then
			return part:GetAttribute("Sight"), part:GetAttribute("Clearing") == true
		end
	end
	return nil, false
end

-- The mist's density at a point along the beach (Z): its look's Fog (each zone's, thickening
-- all the way down, and each biome's on top), blended across edges.
function MistController.densityAt(z: number): number
	return Looks.at(z).Fog
end

local function update(dt: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local inSecretOrShowroom = root.Position.Y > Config.Secrets.Origin.Y - 100
		or root.Position.X > Config.Showroom.Origin.X - 1000
	local target = if inSecretOrShowroom then cfg.Shop else MistController.densityAt(root.Position.Z)
	local worn = Gear.getAccessory(player:GetAttribute("Accessory"))
	if worn and worn.ClearSight then
		target /= worn.ClearSight
	end
	current = if current then current + (target - current) * math.min(1, dt * cfg.Response) else target
	local density = current :: number
	-- The Fog hazard: thick to its Sight unless its foghorn is clearing it.
	local sight, clearing = MistController.fogAt(root.Position.Z)
	local wanted = if sight and not clearing and not inSecretOrShowroom then 1 else 0
	fogShare += math.clamp(wanted - fogShare, -FOG_OUT * dt, FOG_IN * dt)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphereOffset = atmosphereOffset or atmosphere.Offset
		atmosphere.Density = density + (1 - density) * fogShare
		atmosphere.Offset = (atmosphereOffset :: number) + (1 - (atmosphereOffset :: number)) * 0.5 * fogShare
	end
	-- Rough match for places without an Atmosphere: denser mist, nearer fog.
	local fogEnd = 96 / density
	Lighting.FogEnd = fogEnd + ((sight or fogEnd) - fogEnd) * fogShare
	Lighting.FogStart = Lighting.FogEnd * 0.35
end

function MistController.init()
	RunService.Heartbeat:Connect(update)
end

return MistController
