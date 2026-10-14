-- Applies the wave field to everything this client simulates: its own character, the item
-- it's holding, its vessel and the vessel's contents. (The server pushes loose items.)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)
local Stats = require(Shared.Stats)
local Waves = require(Shared.Waves)

local player = Players.LocalPlayer

local WaveController = {}

function WaveController.init()
	RunService.Stepped:Connect(function(_, dt)
		local now = Tide.now()
		local waterline = Tide.waterline(now)

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and root and humanoid.Health > 0 then
			-- Characters are moved directly: the Humanoid controller would cancel a plain force.
			local resistance = Stats.wavePush(player)
			local push = Waves.getPush(root.Position, now, waterline)
				* Config.Waves.CharacterFactor
				* resistance
			if push.Magnitude > 0 then
				root.CFrame += Vector3.new(push.X, 0, push.Z) * dt
			end
		end

		for _, item in CollectionService:GetTagged("SalvageItem") do
			if item:GetAttribute("Owner") == player.UserId then
				local state = item:GetAttribute("State")
				local scale = item:GetAttribute("WaveScale") -- set by GrabController on magical grabs
				if (state == "Held" or state == "InVessel") and scale ~= 0 then
					Waves.applyToPart(item, dt, now, waterline, scale)
				end
			end
		end

		for _, vessel in CollectionService:GetTagged("Vessel") do
			if vessel:GetAttribute("Owner") == player.UserId then
				for _, part in vessel:GetDescendants() do
					if part:IsA("BasePart") then
						Waves.applyToPart(part, dt, now, waterline)
					end
				end
			end
		end
	end)
end

return WaveController
