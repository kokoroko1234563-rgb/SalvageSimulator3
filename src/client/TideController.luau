-- Draws the tide locally (it's computed from the shared clock, so no replication is
-- needed), warns when it turns, and shows which zone the player is in.
-- There's deliberately no on-screen tide clock; Studio shows a debug readout only.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local TideController = {}

local RAMP_LENGTH = 40
local RAMP_START_Y = 0.4
local FLOOD_TOP_Y = 6
local THICKNESS = 14

local function waterPart(name: string): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Glass
	part.Color = Color3.fromRGB(50, 140, 190)
	part.Transparency = 0.35
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

function TideController.init()
	local folder = Instance.new("Folder")
	folder.Name = "LocalTide"
	folder.Parent = Workspace

	local beach = Config.Beach
	local zMin = -beach.DryWidth - 40
	local zMax = beach.SeaExtent
	local depthZ = zMax - zMin
	local midZ = (zMin + zMax) / 2

	local ramp = waterPart("TideRamp")
	local rise = FLOOD_TOP_Y - RAMP_START_Y
	local rampAngle = math.atan2(rise, RAMP_LENGTH)
	local rampLength = math.sqrt(RAMP_LENGTH * RAMP_LENGTH + rise * rise)
	ramp.Size = Vector3.new(rampLength, THICKNESS, depthZ)
	ramp.Parent = folder

	local flood = waterPart("TideFlood")
	local floodEnd = Beach.Length + 400
	flood.Parent = folder

	local lastPhase: string? = nil
	local lastZone: number? = -1

	RunService.RenderStepped:Connect(function()
		local state = Tide.getState()
		local frontX = state.FrontX

		local rampOrientation = CFrame.Angles(0, 0, rampAngle)
		local rampTop = Vector3.new(frontX + RAMP_LENGTH / 2, (RAMP_START_Y + FLOOD_TOP_Y) / 2, midZ)
		ramp.CFrame = CFrame.new(rampTop - rampOrientation.UpVector * THICKNESS / 2) * rampOrientation

		local floodStart = frontX + RAMP_LENGTH
		local floodLength = math.max(floodEnd - floodStart, 1)
		flood.Size = Vector3.new(floodLength, THICKNESS, depthZ)
		flood.CFrame = CFrame.new(floodStart + floodLength / 2, FLOOD_TOP_Y - THICKNESS / 2, midZ)

		if lastPhase and state.Phase ~= lastPhase then
			if state.Phase == "In" then
				HUD.banner("The tide is turning. Head back!")
			elseif state.Phase == "Out" then
				HUD.banner("The tide is going out again.")
			end
		end
		lastPhase = state.Phase

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local zone = Beach.zoneAt(root.Position.X)
			if zone ~= lastZone then
				lastZone = zone
				if zone == 0 then
					HUD.setZone("The Shop")
				elseif zone then
					local info = Config.Zones[zone]
					HUD.setZone(string.format("Zone %d · %s · x%d", zone, info.Name, info.Multiplier))
				else
					HUD.setZone("")
				end
			end
		end

		if RunService:IsStudio() then
			HUD.setDebug(
				string.format(
					"[studio] tide %s %.0f%% · %.0fs left · front x=%.0f",
					state.Phase,
					state.PhaseProgress * 100,
					state.PhaseRemaining,
					frontX
				)
			)
		end
	end)
end

return TideController
