-- Applies the wave field to everything this client simulates: its own character, the item
-- it's holding, its vessel and the vessel's contents. (The server pushes loose items.)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)
local Stats = require(Shared.Stats)
local Waves = require(Shared.Waves)

local player = Players.LocalPlayer

local WaveController = {}

local cfg = Config.Waves

-- The water's speed the character has picked up: it builds up and fades instead of
-- snapping to the water's speed, so being in the surf has momentum.
local carried = Vector3.zero

-- Knockdown state for this client's character.
local knockedUntil = 0
local readyAt = 0
local thrown = Vector3.zero -- the seaward carry when knocked over

-- Knocks the character over and throws it along with the water. The humanoid stops fighting
-- (PlatformStand), so the water carries it until it gets back up.
local function knockDown(character: Model, humanoid: Humanoid, root: BasePart, push: Vector3)
	local now = os.clock()
	knockedUntil = now + cfg.KnockdownTime
	readyAt = knockedUntil + cfg.KnockdownCooldown
	character:SetAttribute("KnockedDown", true) -- local only; GrabController drops what you hold
	humanoid.PlatformStand = true
	-- Whichever way the wave hit, it tumbles you and the water takes you out to sea.
	thrown = Vector3.new(push.X * 0.3, 0, push.Magnitude) * cfg.ThrowFactor
	root.AssemblyLinearVelocity = thrown + Vector3.new(0, cfg.ThrowLift, 0)
	root.AssemblyAngularVelocity = Vector3.new(math.random() * 6 - 3, 0, math.random() * 6 - 3)
	task.delay(cfg.KnockdownTime, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		if character.Parent then
			character:SetAttribute("KnockedDown", nil)
		end
	end)
end

function WaveController.init()
	RunService.Stepped:Connect(function(_, dt)
		local sea = Tide.sea()

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and root and humanoid.Health > 0 then
			-- Water is sluggish: slower walking and lower jumps the deeper you are.
			local speedScale, jumpScale = Beach.wading(root.Position, sea)
			local base = humanoid:GetAttribute("BaseWalkSpeed") or Stats.walkSpeed(player)
			humanoid.WalkSpeed = base * speedScale
			local jumpBase = humanoid:GetAttribute("BaseJump")
			if not jumpBase then
				jumpBase = if humanoid.UseJumpPower then humanoid.JumpPower else humanoid.JumpHeight
				humanoid:SetAttribute("BaseJump", jumpBase)
			end
			if humanoid.UseJumpPower then
				humanoid.JumpPower = jumpBase * jumpScale
			else
				humanoid.JumpHeight = jumpBase * jumpScale
			end

			-- Characters are moved directly: the Humanoid controller would cancel a plain force.
			local resistance = Stats.wavePush(player)
			local push = Waves.getPush(root.Position, sea) * Config.Waves.CharacterFactor * resistance
			local now = os.clock()
			if now < knockedUntil then
				-- Tumbling: the water carries you out, slowing as the wave spends itself.
				local left = (knockedUntil - now) / cfg.KnockdownTime
				local velocity = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(thrown.X * left, velocity.Y, thrown.Z * left)
				carried = thrown * left
			elseif push.Magnitude >= cfg.KnockdownPush and now >= readyAt then
				knockDown(character :: Model, humanoid, root, push)
			else
				carried = carried:Lerp(Vector3.new(push.X, 0, push.Z), 1 - math.exp(-cfg.Coupling * dt))
				if carried.Magnitude > 0.05 then
					root.CFrame += carried * dt
				end
			end
		end

		for _, item in CollectionService:GetTagged("SalvageItem") do
			if item:GetAttribute("Owner") == player.UserId then
				local state = item:GetAttribute("State")
				local scale = item:GetAttribute("WaveScale") -- set by GrabController on magical grabs
				if (state == "Held" or state == "InVessel") and scale ~= 0 then
					Waves.applyToPart(item, dt, sea, scale)
				end
			end
		end

		for _, vessel in CollectionService:GetTagged("Vessel") do
			if vessel:GetAttribute("Owner") == player.UserId then
				for _, part in vessel:GetDescendants() do
					if part:IsA("BasePart") then
						Waves.applyToPart(part, dt, sea)
					end
				end
			end
		end
	end)
end

return WaveController
