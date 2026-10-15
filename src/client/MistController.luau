-- Sea mist: the haze around you thickens the further out to sea you are (Config.Mist), so the
-- lower zones feel closed in and you can't see far ahead or back up the beach. The Lantern of
-- Clear Sight thins it. Works through the Atmosphere's density (Roblox ignores the old fog
-- settings when there's an Atmosphere), and sets the fog distances too in case there isn't one.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)

local player = Players.LocalPlayer
local cfg = Config.Mist

local MistController = {}

local current: number? = nil

-- The mist's density at a point along the beach (Z), blended across zone edges.
function MistController.densityAt(z: number): number
	local function zoneDensity(at: number): number
		local zone = Beach.zoneAt(at)
		if not zone or zone > #cfg.Zones then
			return cfg.Zones[#cfg.Zones]
		elseif zone <= 0 then
			return cfg.Shop
		end
		return cfg.Zones[zone]
	end
	-- Average over a window, so crossing a zone edge doesn't jump.
	local samples, total = 5, 0
	for i = 0, samples - 1 do
		total += zoneDensity(z + (i / (samples - 1) - 0.5) * cfg.Blend)
	end
	return total / samples
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
