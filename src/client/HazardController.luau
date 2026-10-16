-- Applies biome hazards (Hazards.luau) to this client's own character, like the waves: the
-- server builds and moves the hazards and tags the part each one hits with (HazardService);
-- here each frame the character is checked against the ones nearby.
--   Knockdown  knocked over (dropping what you hold) and thrown away from the hazard.
--   Drop       what you hold is knocked out of your hands.
--   Slow       slowed while you're in it.
--   Sink       slowed, and sinking while you're in it (fast standing still, slow moving); fully
--              sunk, the server is told (it kills). You climb back out of it outside.
--   Current    dragged along its Direction at Strength (into deep water, where you drown).
--   Harm       the server is told you were hit (it applies the Damage), and you're thrown.
--   Gloom      dread rises while you're in it (slower if you carry a light), and drains out of
--              it or within a ward's light (Hazards.WardTag); full, the server is told (it
--              takes you). The screen darkens with it, and your own light gutters
--              (the LocalPlayer's "Gloom" attribute, read by GearEffects).
-- A hazard with an Active attribute only hits while it's set.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)
local Hazards = require(Shared.Hazards)
local Remotes = require(Shared.Remotes)

local GrabController = require(script.Parent.GrabController)
local HUD = require(script.Parent.HUD)
local WaveController = require(script.Parent.WaveController)

local player = Players.LocalPlayer

local HazardController = {}

local BODY = 1.5 -- studs of the character's own width counted in a hit
local REACH_Y = 6 -- a hazard this far above or below you can't reach you
local DROP_COOLDOWN = 1.5 -- seconds before the same hazard can knock something out of your hands again

local lastDrop: { [Instance]: number } = {}
local lastHarm: { [Instance]: number } = {}
local sunk = 0 -- seconds of sinking so far (standing-still seconds)
local warned = false
local dread = 0 -- the Gloom's hold on you, 0 to 1
local dreadWarned = false
local shade: Frame? = nil -- the screen darkening with the dread

-- Whether this player carries a light (a lamp accessory or a held lantern).
local function carriesLight(): boolean
	local worn = Gear.getAccessory(player:GetAttribute("Accessory"))
	local tool = Gear.findTool(player:GetAttribute("Tool"))
	return (worn ~= nil and worn.Light ~= nil) or (tool ~= nil and tool.Light ~= nil)
end

-- Whether a point is within a ward's light, where the Gloom can't reach.
local function warded(position: Vector3): boolean
	for _, ward in CollectionService:GetTagged(Hazards.WardTag) do
		if ward:IsA("BasePart") then
			local offset = position - ward.Position
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= (ward:GetAttribute("WardRadius") or 0) then
				return true
			end
		end
	end
	return false
end

-- Whether a hazard part reaches a point, and how far away it is across the ground.
function HazardController.reaches(part: BasePart, position: Vector3): (boolean, number)
	local offset = position - part.Position
	local across = Vector3.new(offset.X, 0, offset.Z).Magnitude
	local radius = (part:GetAttribute("HitRadius") or 0) + BODY
	return across <= radius and math.abs(offset.Y) <= REACH_Y, across
end

local function step(dt: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		WaveController.hazardSlow = 1
		WaveController.hazardPush = Vector3.zero
		sunk, warned = 0, false
		return
	end
	local position = root.Position
	local now = os.clock()
	local slow = 1
	local push = Vector3.zero
	local sinking: BasePart? = nil
	local gloom: BasePart? = nil
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
		elseif effect == "Sink" then
			slow = math.min(slow, part:GetAttribute("Factor") or 1)
			sinking = part
		elseif effect == "Gloom" then
			gloom = part
		elseif effect == "Current" then
			local current = (part:GetAttribute("Direction") or Vector3.zero)
				* (part:GetAttribute("Strength") or 0)
			if current.Magnitude > push.Magnitude then
				push = current
			end
		elseif effect == "Harm" then
			if now - (lastHarm[part] or -math.huge) > 1 then
				lastHarm[part] = now
				Remotes.get("HazardHarm"):FireServer(part)
				local away = Vector3.new(position.X - part.Position.X, 0, position.Z - part.Position.Z)
				local direction = if across > 0.1 then away.Unit else root.CFrame.LookVector * -1
				WaveController.hit(direction * (part:GetAttribute("Push") or 0))
				HUD.notify(part:GetAttribute("HitText") or "Ouch!")
			end
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
	WaveController.hazardPush = push

	-- Sinking sand: deeper while you're in it (much slower if you keep moving), back out of
	-- it once you're clear.
	if sinking then
		local velocity = root.AssemblyLinearVelocity
		local moving = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 3
		sunk += dt * (if moving then sinking:GetAttribute("MovingShare") or 0.3 else 1)
		local limit = sinking:GetAttribute("SinkTime") or 3
		if sunk >= limit * 0.4 and not warned then
			warned = true
			HUD.notify("You're sinking! Keep moving and get out!")
		end
		if sunk >= limit then
			sunk, warned = 0, false
			Remotes.get("HazardHarm"):FireServer(sinking)
			HUD.notify(sinking:GetAttribute("HitText") or "The sand swallowed you!")
		end
	else
		sunk = math.max(0, sunk - dt * 2)
		if sunk == 0 then
			warned = false
		end
	end

	-- The Gloom: dread rises inside it (slower with a light), drains outside or in a ward's light.
	if gloom and not warded(position) then
		local fill = if carriesLight()
			then gloom:GetAttribute("LightFill") or 16
			else gloom:GetAttribute("Fill") or 7
		dread = math.min(1, dread + dt / fill)
		if dread >= 0.5 and not dreadWarned then
			dreadWarned = true
			HUD.notify("The Gloom is closing in... find the light!")
		end
		if dread >= 1 then
			dread, dreadWarned = 0, false
			Remotes.get("HazardHarm"):FireServer(gloom)
			HUD.notify(gloom:GetAttribute("HitText") or "The Gloom took you.")
		end
	else
		local drain = if gloom then gloom:GetAttribute("Drain") or 3 else 3
		dread = math.max(0, dread - dt * drain / 7)
		if dread == 0 then
			dreadWarned = false
		end
	end
	player:SetAttribute("Gloom", dread)
	if shade then
		-- Inside it at all, the light dims; the dread darkens it toward black.
		local darkness = (if gloom then 0.25 else 0) + dread * 0.65
		shade.BackgroundTransparency = 1 - darkness
	end
end

function HazardController.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GloomShade"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -5 -- under the HUD
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(4, 3, 10)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	shade = frame
	RunService.Heartbeat:Connect(step)
	CollectionService:GetInstanceRemovedSignal(Hazards.Tag):Connect(function(part)
		lastDrop[part] = nil
		lastHarm[part] = nil
	end)
end

return HazardController
