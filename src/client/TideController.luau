-- Draws the sea locally. The tide is computed from the shared clock, so no replication is
-- needed: a flat sea surface rises and falls over the sloping beach, which moves the
-- waterline in and out. Also warns when the tide turns and shows which zone you're in.
-- There's deliberately no on-screen tide clock; Studio shows a debug readout only.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local TideController = {}

local THICKNESS = 4

local function waterPart(name: string, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

function TideController.init()
	local folder = Instance.new("Folder")
	folder.Name = "LocalSea"
	folder.Parent = Workspace

	local beach = Config.Beach
	local zMin = -beach.ShopDepth - 60
	local zMax = Beach.Depth + beach.SeaExtent + 200
	local width = beach.Width + 800

	local sea = waterPart("SeaSurface", {
		Size = Vector3.new(width, THICKNESS, zMax - zMin),
		Material = Palette.Material.Glass,
		Color = Palette.World.Sea,
		Transparency = 0.3,
	})
	sea.Parent = folder

	local foam = waterPart("Foam", {
		Size = Vector3.new(beach.Width, 0.15, 3),
		Material = Palette.Material.Smooth,
		Color = Palette.World.Foam,
		Transparency = 0.35,
	})
	foam.Parent = folder

	local lastPhase: string? = nil
	local lastZone: number? = -2

	RunService.RenderStepped:Connect(function()
		local state = Tide.getState()

		sea.CFrame = CFrame.new(0, state.WaterY - THICKNESS / 2, (zMin + zMax) / 2)
		foam.CFrame = CFrame.new(0, state.WaterY + 0.05, state.Waterline)

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
