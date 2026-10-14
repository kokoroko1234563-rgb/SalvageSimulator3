-- Custom waves. Roblox water doesn't push anything, so waves are a deterministic force
-- field computed from the shared clock. Whoever simulates a physics assembly (the server
-- for loose items, the owning client for its character, held item and vessel) samples
-- this field and applies the push locally, which keeps everything smooth and in sync.
-- Waves roll in toward the current waterline, so they follow the tide in and out.

local Config = require(script.Parent.Config)
local Beach = require(script.Parent.Beach)

local cfg = Config.Waves

local Waves = {}

Waves.ScaleAttribute = "WavePushScale" -- set by the admin console; 1 = normal

local SHORE = Vector3.new(0, 0, -1)

-- Z position of the current wave front at a given X.
function Waves.frontZ(x: number, now: number, waterline: number): number
	local wobble = cfg.WobbleAmplitude * math.sin(x * cfg.WobbleFrequency + now * 0.2)
	local travelled = (now % cfg.Period) * cfg.Speed
	return waterline + cfg.StartOffset - travelled + wobble
end

-- Returns the push velocity (studs/s) the sea applies at a position: zero on dry sand and
-- between waves on the wash.
function Waves.getPush(position: Vector3, now: number, waterline: number): Vector3
	local rel = position.Z - waterline
	if rel < cfg.EndOffset then
		return Vector3.zero
	end

	local depthFactor = (0.7 + math.clamp(rel, 0, 60) / 60 * 0.6)
		* (workspace:GetAttribute(Waves.ScaleAttribute) or 1)
	local waveZ = Waves.frontZ(position.X, now, waterline)
	local behind = position.Z - waveZ

	if waveZ >= waterline + cfg.EndOffset and behind >= 0 and behind <= cfg.BandWidth then
		local intensity = 1 - behind / cfg.BandWidth
		return SHORE * cfg.Push * intensity * depthFactor
	end

	if rel > 0 and behind < 0 then
		-- Water running back out to sea ahead of the next wave.
		return -SHORE * cfg.Backwash * depthFactor
	end

	return Vector3.zero
end

-- Keeps a floating part at the sea surface and lets the current carry it out. Returns false
-- (and does nothing) when the part isn't in the water.
function Waves.applyFloat(part: BasePart, dt: number, waterline: number): boolean
	local surface = Beach.waterY(waterline)
	local below = surface - part.Position.Y -- > 0: its centre is under water
	if below < -part.Size.Y / 2 or Beach.depthAt(part.Position, waterline) <= 0 then
		return false
	end
	local velocity = part.AssemblyLinearVelocity
	local gravity = workspace.Gravity
	-- A spring around "half under water", damped so it settles instead of bouncing.
	local lift = gravity * (1 + cfg.FloatSpring * math.max(below, 0)) - cfg.FloatDamping * velocity.Y
	if below < 0 then
		lift = gravity * (1 + below / (part.Size.Y / 2)) - cfg.FloatDamping * velocity.Y
	end
	local drift = Vector3.new(-velocity.X * cfg.FloatDrag, 0, (cfg.FloatDrift - velocity.Z) * cfg.FloatDrag)
	part:ApplyImpulse((Vector3.new(0, lift, 0) + drift) * part.Mass * dt)
	part.AssemblyAngularVelocity *= 0.95
	return true
end

-- Applies one frame of wave push to an unanchored part this machine simulates.
-- `multiplier` lets future stats (Sea Legs, Barnacle Boots) reduce the push, capped below.
function Waves.applyToPart(part: BasePart, dt: number, now: number, waterline: number, multiplier: number?)
	if part.Anchored or part.Massless then
		return
	end
	-- Cargo is welded into its vessel, so it rides with it instead of floating on its own.
	local floats = part:GetAttribute("Floats") and part:GetAttribute("State") ~= "InVessel"
	if floats and Waves.applyFloat(part, dt, waterline) then
		-- Floating at the surface: waves still push it, but it doesn't sink.
		local push = Waves.getPush(part.Position, now, waterline)
		local scale = math.max(multiplier or 1, cfg.MinPushFraction)
		part:ApplyImpulse(push * cfg.ItemFactor * cfg.FloatWavePush * scale * part.Mass * dt)
		return
	end
	local push = Waves.getPush(part.Position, now, waterline)
	-- Per-part mass, so a multi-part vessel gets pushed once in total, not once per part.
	local mass = part.Mass
	local impulse = push * cfg.ItemFactor * math.max(multiplier or 1, cfg.MinPushFraction)
	if part.Position.Y < Beach.waterY(waterline) then
		impulse += Vector3.new(0, workspace.Gravity * cfg.Buoyancy, 0)
	end
	if impulse.Magnitude > 0 then
		part:ApplyImpulse(impulse * mass * dt)
	end
end

return Waves
