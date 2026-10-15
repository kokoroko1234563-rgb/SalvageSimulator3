-- Applies biome hazards (Hazards.luau) to this client's own character, like the waves: the
-- server builds and moves the hazards and tags the part each one hits with (HazardService);
-- here each frame the character is checked against the ones nearby.
--   Knockdown  knocked over (dropping what you hold) and thrown away from the hazard.
--   Drop       what you hold is knocked out of your hands.
--   Slow       slowed while you're in it.
-- A Pulse hazard only hits while its Active attribute is set.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Hazards = require(Shared.Hazards)

local GrabController = require(script.Parent.GrabController)
local HUD = require(script.Parent.HUD)
local WaveController = require(script.Parent.WaveController)

local player = Players.LocalPlayer

local HazardController = {}

local BODY = 1.5 -- studs of the character's own width counted in a hit
local REACH_Y = 6 -- a hazard this far above or below you can't reach you
local DROP_COOLDOWN = 1.5 -- seconds before the same hazard can knock something out of your hands again

local lastDrop: { [Instance]: number } = {}

-- Whether a hazard part reaches a point, and how far away it is across the ground.
function HazardController.reaches(part: BasePart, position: Vector3): (boolean, number)
	local offset = position - part.Position
	local across = Vector3.new(offset.X, 0, offset.Z).Magnitude
	local radius = (part:GetAttribute("HitRadius") or 0) + BODY
	return across <= radius and math.abs(offset.Y) <= REACH_Y, across
end

local function step()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		WaveController.hazardSlow = 1
		return
	end
	local position = root.Position
	local now = os.clock()
	local slow = 1
	for _, part in CollectionService:GetTagged(Hazards.Tag) do
		if not part:IsA("BasePart") or part:GetAttribute("Active") == false then
			continue
		end
		local hit, across = HazardController.reaches(part, position)
		if not hit then
			continue
		end
		local effect = part:GetAttribute("Effect")
		if effect == "Slow" then
			slow = math.min(slow, part:GetAttribute("Factor") or 1)
		elseif effect == "Knockdown" then
			local away = Vector3.new(position.X - part.Position.X, 0, position.Z - part.Position.Z)
			local direction = if across > 0.1 then away.Unit else root.CFrame.LookVector * -1
			if WaveController.hit(direction * (part:GetAttribute("Push") or 0)) then
				HUD.notify(part:GetAttribute("HitText") or "You got knocked over!")
			end
		elseif effect == "Drop" then
			if GrabController.isHolding() and now - (lastDrop[part] or -math.huge) > DROP_COOLDOWN then
				lastDrop[part] = now
				GrabController.release()
				HUD.notify(part:GetAttribute("HitText") or "It was knocked out of your hands!")
			end
		end
	end
	WaveController.hazardSlow = slow
end

function HazardController.init()
	RunService.Heartbeat:Connect(step)
	CollectionService:GetInstanceRemovedSignal(Hazards.Tag):Connect(function(part)
		lastDrop[part] = nil
	end)
end

return HazardController
