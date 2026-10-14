-- Custom waves. Roblox water doesn't push anything, so waves are a deterministic force
-- field computed from the shared clock. Whoever simulates a physics assembly (the server
-- for loose items, the owning client for its character, held item and vessel) samples
-- this field and applies the push locally, which keeps everything smooth and in sync.

local Config = require(script.Parent.Config)

local cfg = Config.Waves

local Waves = {}

Waves.ScaleAttribute = "WavePushScale" -- set by the admin console; 1 = normal

local SHORE = Vector3.new(0, 0, -1)

-- Z position of the current wave front at a given X.
function Waves.frontZ(x: number, now: number): number
	local wobble = cfg.WobbleAmplitude * math.sin(x * cfg.WobbleFrequency + now * 0.2)
	local travelled = (now % cfg.Period) * cfg.Speed
	return cfg.StartZ - travelled + wobble
end

-- Returns the push velocity (studs/s) the sea applies at a position. Zero on dry land,
-- under the flooded tide (still deep water), and between waves on the sand.
function Waves.getPush(position: Vector3, now: number, frontX: number): Vector3
	if position.X > frontX then
		return Vector3.zero
	end
	if position.Z < cfg.EndZ then
		return Vector3.zero
	end

	local depthFactor = (0.7 + math.clamp(position.Z, 0, 60) / 60 * 0.6)
		* (workspace:GetAttribute(Waves.ScaleAttribute) or 1)
	local waveZ = Waves.frontZ(position.X, now)
	local behind = position.Z - waveZ

	if waveZ >= cfg.EndZ and behind >= 0 and behind <= cfg.BandWidth then
		local intensity = 1 - behind / cfg.BandWidth
		return SHORE * cfg.Push * intensity * depthFactor
	end

	if position.Z > 0 and behind < 0 then
		-- Water running back out to sea ahead of the next wave.
		return -SHORE * cfg.Backwash * depthFactor
	end

	return Vector3.zero
end

-- Applies one frame of wave push to an unanchored part this machine simulates.
-- `multiplier` lets future stats (Sea Legs, Barnacle Boots) reduce the push, capped below.
function Waves.applyToPart(part: BasePart, dt: number, now: number, frontX: number, multiplier: number?)
	if part.Anchored or part.Massless then
		return
	end
	local push = Waves.getPush(part.Position, now, frontX)
	-- Per-part mass, so a multi-part vessel gets pushed once in total, not once per part.
	local mass = part.Mass
	local impulse = push * cfg.ItemFactor * math.max(multiplier or 1, cfg.MinPushFraction)
	if part.Position.Y < Config.Beach.WaterLevel and part.Position.Z > 0 and part.Position.X <= frontX then
		impulse += Vector3.new(0, workspace.Gravity * cfg.Buoyancy, 0)
	end
	if impulse.Magnitude > 0 then
		part:ApplyImpulse(impulse * mass * dt)
	end
end

return Waves
