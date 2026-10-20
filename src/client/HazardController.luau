-- Applies biome hazards (Hazards.luau) to this client's own character, like the waves: the
-- server builds and moves the hazards and tags the part each one hits with (HazardService);
-- here each frame the character is checked against the ones nearby.
--   Knockdown  knocked over (dropping what you hold) and thrown away from the hazard.
--   Drop       what you hold is knocked out of your hands.
--   Slow       slowed while you're in it.
--   Sink       slowed, unable to jump, and visibly sinking while you're in it (fast standing
--              still, slower moving); fully sunk, the server is told (it kills). You climb
--              back out of it outside.
--   Current    dragged along its Direction at Strength (into deep water, where you drown).
--   Harm       the server is told you were hit (it applies the Damage), and you're thrown.
--   Gloom      its shadow makes you Benighted (not within a ward's light, Hazards.WardTag):
--              the world goes black around you (DayController.blind) and only lights show,
--              until you die or leave the deep (zones 5 and 6). The LocalPlayer's "Benighted"
--              attribute says so, shown on screen.
--   Sting      (jellyfish) the server is told (it applies the Damage, checked like Harm), you drop
--              what you hold, are pushed a little, and in StunZone and deeper you're stunned
--              (can't move or jump) for Stun seconds.
--   Fling      (whirlwind) thrown Push studs/s away and up (Push x FLING_LIFT), tumbling for
--              FLING_TIME, dropping what you hold; not deadly itself.
--   Slide      (ice) your velocity follows where you want to go at only Grip x SLIDE_RATE per
--              second: you keep the momentum you came with and turn slowly (the slide is
--              carried as WaveController.hazardPush on top of the Humanoid's own walking).
--   Fog        (foghorn) nothing here: MistController thickens the mist while you're on the
--              hazard's tile (its ZMin/ZMax) and lifts it while its Clearing attribute is set.
-- A hazard with an Active attribute only hits while it's set.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Hazards = require(Shared.Hazards)
local Remotes = require(Shared.Remotes)

local DayController = require(script.Parent.DayController)
local GrabController = require(script.Parent.GrabController)
local HUD = require(script.Parent.HUD)
local WaveController = require(script.Parent.WaveController)

local player = Players.LocalPlayer

local HazardController = {}

local BODY = 1.5 -- studs of the character's own width counted in a hit
local REACH_Y = 6 -- a hazard this far above or below you can't reach you
local DROP_COOLDOWN = 1.5 -- seconds before the same hazard can knock something out of your hands again
local HOLD_DEPTH = 0.6 -- how far down sand that holds (Lethal = false) takes you, as a share of swallowed

local STING_COOLDOWN = 2 -- seconds before the same jelly can sting you again
local stunnedUntil = 0 -- stunned by a sting (can't move) until then
local FLING_TIME = 1.6 -- seconds tumbling after a whirlwind throws you
local FLING_LIFT = 0.6 -- the throw's upward speed, as a share of its Push
local FLING_COOLDOWN = 3.5 -- seconds before a whirlwind can throw you again
local lastFling = -math.huge
local SLIDE_RATE = 8 -- on ice, how fast your velocity follows your wish, per second, times Grip
local FOOTING_RATE = 5 -- off it, how fast you get your footing back, per second
local slideVelocity: Vector3? = nil -- the velocity you're sliding at, from the first step on ice

local lastDrop: { [Instance]: number } = {}
local lastHarm: { [Instance]: number } = {}
local sunk = 0 -- seconds of sinking so far (standing-still seconds)
local warned = false
local benighted = false -- Benighted by the Gloom (until you die or leave the deep)
local benightedLabel: TextLabel? = nil
local baseHip: number? = nil -- the character's own HipHeight, while the sand pulls it down

-- Whether a point along the beach (Z) is in the deep, the zones where the Gloom keeps hold of
-- you (DEEP, by zone).
local DEEP = { 5, 6 }
local function inDeep(z: number): boolean
	local per = Config.Beach.TilesPerZone
	local from = Beach.tileRange((DEEP[1] - 1) * per + 1)
	local _, to = Beach.tileRange(DEEP[#DEEP] * per)
	return z >= from and z < to
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
		WaveController.hazardJump = 1
		WaveController.hazardPush = Vector3.zero
		stunnedUntil, slideVelocity = 0, nil
		sunk, warned, baseHip = 0, false, nil
		benighted = false -- (dying lifts it)
		DayController.blind = 0
		return
	end
	local position = root.Position
	local now = os.clock()
	local slow = 1
	local push = Vector3.zero
	local sinking: BasePart? = nil
	local gloom: BasePart? = nil
	local grip: number? = nil -- the share of control you keep, on ice
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
		elseif effect == "Slide" then
			grip = math.min(grip or 1, part:GetAttribute("Grip") or 1)
		elseif effect == "Sting" then
			-- A sting: the server applies the Damage, what you hold is dropped, a small push, and
			-- from StunZone down you can't move for Stun seconds.
			if now - (lastHarm[part] or -math.huge) > STING_COOLDOWN then
				lastHarm[part] = now
				Remotes.get("HazardHarm"):FireServer(part)
				if GrabController.isHolding() then
					GrabController.release()
				end
				local away = Vector3.new(position.X - part.Position.X, 0, position.Z - part.Position.Z)
				local direction = if across > 0.1 then away.Unit else root.CFrame.LookVector * -1
				local velocity = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = velocity + direction * (part:GetAttribute("Push") or 0)
				if (Beach.zoneAt(position.Z) or 0) >= (part:GetAttribute("StunZone") or math.huge) then
					stunnedUntil = now + (part:GetAttribute("Stun") or 0)
				end
				HUD.notify(part:GetAttribute("HitText") or "Stung!")
			end
		elseif effect == "Fling" then
			-- Caught in a whirlwind: thrown up and away, tumbling, dropping what you hold. Not
			-- deadly itself; the landing is what you make of it.
			if now - lastFling > FLING_COOLDOWN then
				lastFling = now
				if GrabController.isHolding() then
					GrabController.release()
				end
				local away = Vector3.new(position.X - part.Position.X, 0, position.Z - part.Position.Z)
				local direction = if across > 0.1 then away.Unit else root.CFrame.LookVector * -1
				local speed = part:GetAttribute("Push") or 0
				humanoid.PlatformStand = true
				root.AssemblyLinearVelocity = direction * speed + Vector3.new(0, speed * FLING_LIFT, 0)
				root.AssemblyAngularVelocity =
					Vector3.new(math.random() * 12 - 6, math.random() * 12 - 6, math.random() * 12 - 6)
				task.delay(FLING_TIME, function()
					if humanoid.Parent and humanoid.Health > 0 then
						humanoid.PlatformStand = false
						humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end)
				HUD.notify(part:GetAttribute("HitText") or "You were thrown!")
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
	-- Ice: your velocity follows where you want to go only slowly (the less Grip, the slower), so
	-- you keep sliding the way you were going, and turn slowly. The slide is carried as a push
	-- (WaveController moves the character by it) on top of the walking the Humanoid does. Off the
	-- ice you get your footing back within a moment.
	if grip or slideVelocity then
		local walk = humanoid.MoveDirection * humanoid.WalkSpeed
		walk = Vector3.new(walk.X, 0, walk.Z)
		if not slideVelocity then
			local velocity = root.AssemblyLinearVelocity
			slideVelocity = Vector3.new(velocity.X, 0, velocity.Z)
		end
		local rate = if grip then grip * SLIDE_RATE else FOOTING_RATE
		slideVelocity += (walk - slideVelocity) * (1 - math.exp(-rate * dt))
		if not grip and (slideVelocity - walk).Magnitude < 1 then
			slideVelocity = nil
		else
			push += slideVelocity - walk
		end
	end
	local stunned = now < stunnedUntil -- a sting in the deep: rooted to the spot
	WaveController.hazardSlow = if stunned then 0 else slow
	WaveController.hazardJump = if sinking or stunned then 0 else 1 -- no jumping out of sinking sand
	WaveController.hazardPush = push

	-- Sinking sand: deeper while you're in it (slower if you keep moving), back out of it once
	-- you're clear. You see yourself go down: the sand pulls your hips toward the ground.
	local limit = if sinking then sinking:GetAttribute("SinkTime") or 4 else 4
	if sinking then
		local velocity = root.AssemblyLinearVelocity
		local moving = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 3
		local lethal = sinking:GetAttribute("Lethal") ~= false
		sunk += dt * (if moving then sinking:GetAttribute("MovingShare") or 0.6 else 1)
		if not lethal then
			-- Sand that holds rather than swallows: down to the waist, then no further.
			sunk = math.min(sunk, limit * HOLD_DEPTH)
		end
		if sunk >= limit * 0.35 and not warned then
			warned = true
			HUD.notify(
				if lethal
					then "You're sinking! Keep moving and get out!"
					else "The sand has you! Keep wading out before the sea comes in!"
			)
		end
		if lethal and sunk >= limit then
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
	if sunk > 0 then
		baseHip = baseHip or humanoid.HipHeight
		humanoid.HipHeight = (baseHip :: number) * (1 - 0.9 * math.min(1, sunk / limit))
	elseif baseHip then
		humanoid.HipHeight = baseHip
		baseHip = nil
	end

	-- The Gloom: its shadow Benights you (a ward's light keeps it off), and it stays on you until
	-- you die or leave the deep (back up past zone 5, or out onto the Far Sandbar).
	if gloom and not warded(position) then
		if not benighted then
			HUD.notify(gloom:GetAttribute("HitText") or "The Gloom's shadow fell on you: find the light!")
		end
		benighted = true
	elseif benighted and not inDeep(position.Z) then
		benighted = false
		HUD.notify("The Gloom lets go of you.")
	end
	DayController.blind = if benighted then 1 else 0
	player:SetAttribute("Benighted", if benighted then true else nil)
	if benightedLabel then
		benightedLabel.Visible = benighted
	end
end

function HazardController.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GloomShade"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 70)
	label.Size = UDim2.fromOffset(700, 28)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = Color3.fromRGB(200, 190, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = "Benighted: follow the lights, or carry your own (it lifts out of the deep)"
	label.Visible = false
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	benightedLabel = label
	RunService.Heartbeat:Connect(step)
	CollectionService:GetInstanceRemovedSignal(Hazards.Tag):Connect(function(part)
		lastDrop[part] = nil
		lastHarm[part] = nil
	end)
end

return HazardController
