-- Sea mist: the haze around you thickens the further out to sea you are (each zone's and
-- biome's Look sets its Fog, Config.Looks), so the lower zones feel closed in and you can't see far ahead or back up the beach. The Lantern of
-- Clear Sight thins it. Works through the Atmosphere's density (Roblox ignores the old fog
-- settings when there's an Atmosphere), and sets the fog distances too in case there isn't one.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Looks = require(Shared.Looks)

local player = Players.LocalPlayer
local cfg = Config.Mist

local MistController = {}

local current: number? = nil

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
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = density
	end
	-- Rough match for places without an Atmosphere: denser mist, nearer fog.
	Lighting.FogEnd = 96 / density
	Lighting.FogStart = Lighting.FogEnd * 0.35
end

function MistController.init()
	RunService.Heartbeat:Connect(update)
end

return MistController
