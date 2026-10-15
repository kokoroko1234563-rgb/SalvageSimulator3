-- Players slowly drown in deep water (out past the waist-deep band, which moves with the tide).
-- Breath is a 0-1 player attribute the HUD shows.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)
local Tide = require(Shared.Tide)
local Stats = require(Shared.Stats)

local cfg = Config.Drowning
local TICK = 0.2

local DrowningService = {}

local function tick()
	local sea = Tide.sea()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoid or not root or humanoid.Health <= 0 then
			player:SetAttribute("Breath", 1)
			continue
		end

		local breath = player:GetAttribute("Breath") or 1
		-- Deep water is measured from your feet, not the beach's ground height under you: on a
		-- rock, a prop or a ridge above the water you can breathe.
		local feet = root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
		local deep = Beach.waterYAt(sea, root.Position.X) - feet >= Config.Beach.WaistDepth
		if deep and not player:GetAttribute("AdminGod") then
			local lungs = Stats.breath(player)
			breath = math.max(0, breath - TICK / (cfg.BreathTime * lungs))
			if breath <= 0 then
				humanoid:TakeDamage(cfg.DamagePerSecond * TICK)
			end
		else
			breath = math.min(1, breath + TICK / cfg.RegenTime)
		end
		player:SetAttribute("Breath", breath)
	end
end

function DrowningService.init()
	task.spawn(function()
		while true do
			task.wait(TICK)
			tick()
		end
	end)
end

return DrowningService
