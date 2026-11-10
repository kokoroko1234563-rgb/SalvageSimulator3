-- Driving a boat you're riding (Captain's Longboat, Leviathan Rowboat). The server seats you at
-- the helm (VesselService.toggleBoard) and sets your "Riding" attribute; this client owns the
-- boat's physics, so it steers it from your movement keys: it floats on the sea surface and
-- moves at the boat's speed (the server checks that speed, VesselPowers.boatSpeedOk). Jumping
-- gets you out. GrabController leaves a ridden boat alone (its parking brake is off).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Stats = require(Shared.Stats)
local Tide = require(Shared.Tide)
local VesselPowers = require(Shared.VesselPowers)

local player = Players.LocalPlayer

local BoatController = {}

local TURN_RATE = 6 -- how quickly the bow swings round to where you steer
local rig: {
	base: BasePart,
	attachment: Attachment,
	velocity: LinearVelocity,
	float: AlignPosition,
	turn: AlignOrientation,
}? =
	nil

local function myBoat(): Model?
	for _, vessel in CollectionService:GetTagged("Vessel") do
		if vessel:GetAttribute("Owner") == player.UserId and vessel:GetAttribute("Ridden") == true then
			return vessel
		end
	end
	return nil
end

local function removeRig()
	if rig then
		rig.velocity:Destroy()
		rig.float:Destroy()
		rig.turn:Destroy()
		rig.attachment:Destroy()
		rig = nil
	end
end

local function buildRig(base: BasePart)
	local attachment = Instance.new("Attachment")
	attachment.Name = "RideAttachment"
	attachment.Parent = base

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "RideVelocity"
	velocity.Attachment0 = attachment
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = base

	local float = Instance.new("AlignPosition")
	float.Name = "RideFloat"
	float.Mode = Enum.PositionAlignmentMode.OneAttachment
	float.Attachment0 = attachment
	float.ApplyAtCenterOfMass = true
	float.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	float.Responsiveness = 12
	float.Position = base.Position
	float.Parent = base

	local turn = Instance.new("AlignOrientation")
	turn.Name = "RideTurn"
	turn.Mode = Enum.OrientationAlignmentMode.OneAttachment
	turn.Attachment0 = attachment
	turn.Responsiveness = TURN_RATE
	turn.CFrame = base.CFrame
	turn.Parent = base

	rig = { base = base, attachment = attachment, velocity = velocity, float = float, turn = turn }
end

local function step()
	local boat = myBoat()
	local base = boat and boat.PrimaryPart
	if rig and (not base or rig.base ~= base) then
		removeRig()
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not boat or not base or not humanoid then
		return
	end
	if not rig then
		buildRig(base)
	end
	local current = rig :: any

	local mass = base.AssemblyMass
	local direction = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	local speed = VesselPowers.boatSpeed(boat:GetAttribute("Kind"), Stats.vesselSpeed(player))
	local push = mass * Config.Grab.HoverAcceleration
	current.velocity.VectorVelocity = direction * speed
	current.velocity.MaxAxesForce = Vector3.new(push, 0, push)

	-- Floats on the sea surface (the sea draws over the seabed it would otherwise rest on).
	local waterY = Beach.waterYAt(Tide.sea(), base.Position.X)
	current.float.Position = Vector3.new(base.Position.X, waterY + Config.Grab.SwimFloat, base.Position.Z)
	current.float.MaxAxesForce = Vector3.new(0, push, 0)

	-- The bow swings toward where you steer, level.
	if direction.Magnitude > 0.1 then
		current.turn.CFrame = CFrame.lookAt(Vector3.zero, direction)
	else
		local _, yaw = base.CFrame:ToOrientation()
		current.turn.CFrame = CFrame.Angles(0, yaw, 0)
	end
	current.turn.MaxTorque = mass * Config.Grab.StabilizerTorque
end

function BoatController.init()
	RunService.RenderStepped:Connect(step)
end

return BoatController
