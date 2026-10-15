-- Warns when the tide turns and shows which zone you're in. (SeaController draws the sea.)
-- There's deliberately no on-screen tide clock; Studio shows a debug readout only.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local TideController = {}

function TideController.init()
	local lastPhase: string? = nil
	local lastZone: number? = -2

	RunService.RenderStepped:Connect(function()
		local state = Tide.getState()

		if lastPhase and state.Phase ~= lastPhase then
			if state.Phase == "In" then
				HUD.banner("The tide is turning. Head back to shore!")
			elseif state.Phase == "Out" then
				HUD.banner("The tide is going out again.")
			end
		end
		lastPhase = state.Phase

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			-- Secret courses are built high above everything, far off the map.
			local zone = if root.Position.Y > Config.Secrets.Origin.Y - 100
				then -1
				else Beach.zoneAt(root.Position.Z)
			if zone ~= lastZone then
				lastZone = zone
				if zone == -1 then
					HUD.setZone("A secret")
				elseif zone == 0 then
					HUD.setZone("The Shop")
				elseif zone then
					local info = Config.Zones[zone]
					HUD.setZone(string.format("Zone %d · %s · x%d", zone, info.Name, info.Multiplier))
				else
					HUD.setZone("Open sea")
				end
			end
		end

		if RunService:IsStudio() then
			HUD.setDebug(
				string.format(
					"[studio] tide %s %.0f%% · %.0fs left · waterline z=%.0f",
					state.Phase,
					state.PhaseProgress * 100,
					state.PhaseRemaining,
					state.Waterline
				)
			)
		end
	end)
end

return TideController
