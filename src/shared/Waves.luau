-- Custom waves. Roblox water doesn't push anything, so waves are a deterministic force
-- field computed from the shared clock. Whoever simulates a physics assembly (the server
-- for loose items, the owning client for its character, held item and vessel) samples
-- this field and applies the push locally, which keeps everything smooth and in sync.
--
-- Wave n starts StartOffset studs out to sea every Period seconds and rolls in toward the
-- local waterline (which differs along the beach, see Tide.waterlineAt). On reaching it, it
-- runs up the exposed sand as a thin sheet, slows to a stop, and slides back. Each wave has
-- a size: a little random, bigger every SetEvery-th wave, now and then a rogue wave, and
-- bigger further out (ZoneScale). Size scales how far it runs up and how hard it pushes.
--
-- Positions along a wave are measured as a distance from the local waterline: positive out
-- to sea, negative up the beach.

local Config = require(script.Parent.Config)
local Beach = require(script.Parent.Beach)
local Tide = require(script.Parent.Tide)
local WaterObstacles = require(script.Parent.WaterObstacles)

type Sea = Tide.Sea

local cfg = Config.Waves

local Waves = {}

Waves.ScaleAttribute = "WavePushScale" -- set by the admin console; 1 = normal
Waves.RogueAttribute = "RogueWave" -- set by the admin console: this wave index is a rogue wave

local SHORE = Vector3.new(0, 0, -1)

-- Deterministic 0-1 hash of a wave index (and the server's sea seed), the same on the server
-- and every client. Reduced first so the multiplication stays exact.
local function hash(n: number, salt: number): number
	local m = (n + Tide.seed() * 7919) % 1000003
	return ((m * salt) % 4294967296) / 4294967296
end

function Waves.indexAt(now: number): number
	return math.floor(now / cfg.Period)
end

-- How big wave n is, before the zone scale (1 = normal).
function Waves.size(n: number): number
	local size = 1 + cfg.RunUpVariation * (hash(n, 2654435761) * 2 - 1)
	if n % cfg.SetEvery == 0 then
		size *= cfg.SetSize
	end
	if hash(n, 2246822519) < cfg.RogueChance or workspace:GetAttribute(Waves.RogueAttribute) == n then
		size *= cfg.RogueSize
	end
	return size
end

function Waves.isRogue(n: number): boolean
	return Waves.size(n) >= cfg.RogueSize
end

-- Waves are bigger further out.
local function zoneScale(z: number): number
	local zone = Beach.zoneAt(z)
	return if zone and zone > 0 then cfg.ZoneScale[zone] or 1 else 1
end

-- Each wave's front has its own shape along the beach.
local function wobble(x: number, n: number): number
	return cfg.WobbleAmplitude * Tide.noise(x * cfg.WobbleFrequency, n * 0.43, 2)
end

-- Each wave is bigger at some spots along the beach and smaller at others.
function Waves.sizeAt(n: number, x: number): number
	return Waves.size(n) * (1 + cfg.AlongVariation * Tide.noise(x / cfg.AlongWavelength, n * 0.61, 3))
end

export type WaveAt = {
	Index: number,
	Size: number, -- including the zone scale
	Front: number, -- distance of the water's leading edge from the waterline (+ sea, - beach)
	Phase: "Rolling" | "RunUp" | "Backwash",
	PhaseProgress: number, -- 0-1 through the run-up or backwash
	RunUp: number, -- how far up the beach this wave reaches, at this X
}

-- Where wave n is at X, or nil once it has finished sliding back.
function Waves.wave(n: number, x: number, sea: Sea, waterline: number?): WaveAt?
	local s = sea.Now - n * cfg.Period
	if s < 0 then
		return nil
	end
	local line = waterline or Tide.waterlineAt(sea, x)
	local size = Waves.sizeAt(n, x) * zoneScale(line)
	local start = cfg.StartOffset + wobble(x, n)
	local arrive = start / cfg.Speed
	if s < arrive then
		return {
			Index = n,
			Size = size,
			Front = start - cfg.Speed * s,
			Phase = "Rolling",
			PhaseProgress = s / arrive,
			RunUp = cfg.RunUp * size,
		}
	end
	local runUp = cfg.RunUp * size
	local upTime = 2 * runUp / cfg.Speed -- slows from full speed to a stop
	local u = s - arrive
	if u < upTime then
		return {
			Index = n,
			Size = size,
			Front = -(cfg.Speed * u - cfg.Speed * u * u / (2 * upTime)),
			Phase = "RunUp",
			PhaseProgress = u / upTime,
			RunUp = runUp,
		}
	end
	local backTime = upTime * cfg.BackwashRatio
	local b = u - upTime
	if b < backTime then
		local t = b / backTime
		return {
			Index = n,
			Size = size,
			Front = -runUp * (1 - t * t * (3 - 2 * t)),
			Phase = "Backwash",
			PhaseProgress = t,
			RunUp = runUp,
		}
	end
	return nil
end

-- The waves alive at X right now, newest first (a wave can still be sliding back when the
-- next one arrives).
function Waves.wavesAt(x: number, sea: Sea, waterline: number?): { WaveAt }
	local line = waterline or Tide.waterlineAt(sea, x)
	local newest = Waves.indexAt(sea.Now)
	local list = {}
	for n = newest, newest - 3, -1 do
		local wave = Waves.wave(n, x, sea, line)
		if wave then
			table.insert(list, wave)
		end
	end
	return list
end

-- How far up the beach wave n runs where the waterline is `waterline`.
function Waves.reach(n: number, waterline: number, x: number?): number
	local size = if x then Waves.sizeAt(n, x) else Waves.size(n)
	return cfg.RunUp * size * zoneScale(waterline)
end

-- How long wave n lasts from its start until it has slid back (the longest anywhere).
function Waves.lifetime(n: number): number
	local size = Waves.size(n) * (1 + cfg.AlongVariation) * (cfg.ZoneScale[#cfg.ZoneScale] or 1)
	local upTime = 2 * cfg.RunUp * size / cfg.Speed
	return (cfg.StartOffset + cfg.WobbleAmplitude) / cfg.Speed + upTime * (1 + cfg.BackwashRatio)
end

-- Returns the push velocity (studs/s) the sea applies at a position: shoreward in the band
-- behind a rolling wave and under a running-up sheet, seaward under a sliding-back sheet
-- and in the water between waves, zero on sand no wave reaches.
-- The undertow at a spot in the water (rel > 0), before the pulses.
local function undertow(rel: number, line: number): number
	local depth = math.clamp(rel * Config.Beach.Slope / Config.Beach.WaistDepth, 0, 1)
	local pull = cfg.Undertow + (cfg.UndertowDeep - cfg.Undertow) * depth
	-- Grows less than the waves further out, so you can always wade back across the channel.
	return pull * (1 + (zoneScale(line) - 1) * cfg.UndertowZoneScale)
end

-- Side-to-side drift in the water, different along the beach and changing over time.
local function sway(x: number, now: number, rel: number): Vector3
	local amount = cfg.Sway * math.clamp(rel / 20, 0, 1)
	return Vector3.new(amount * math.sin(now * 0.45 + x * 0.031) * math.cos(now * 0.17 - x * 0.013), 0, 0)
end

local function pushAt(position: Vector3, sea: Sea, line: number, rel: number, scale: number): Vector3
	local list = Waves.wavesAt(position.X, sea, line)
	if rel > 0 then
		-- In the sea. Each passing wave rocks you in and out (the water circles under it) and
		-- its front surges you toward the shore; ahead of it, the water rushes out to meet it.
		local depthFactor = 0.7 + math.clamp(rel, 0, 60) / 60 * 0.6
		local wavelength = cfg.Period * cfg.Speed
		local push = Vector3.zero
		local rocked = false
		for _, wave in list do
			if wave.Phase ~= "Rolling" then
				continue
			end
			local strength = wave.Size * scale
			local behind = rel - wave.Front -- > 0: the wave has passed this spot
			if behind >= 0 and behind <= cfg.BandWidth then
				push += SHORE * cfg.Push * (1 - behind / cfg.BandWidth) * depthFactor * strength
			elseif behind < 0 and -behind < cfg.DrawbackRange then
				local closeness = 1 + behind / cfg.DrawbackRange
				local pull = undertow(rel, line)
					* (cfg.Slack + cfg.Drawback * closeness * closeness * wave.Size * wave.Size)
				push -= SHORE * pull * scale
			end
			if not rocked then
				-- Rocking follows the nearest wave still out at sea or just past.
				rocked = true
				push += SHORE * cfg.Rock * math.cos(2 * math.pi * behind / wavelength) * depthFactor * strength
			end
		end
		if push == Vector3.zero then
			push = -SHORE * undertow(rel, line) * cfg.Slack * scale
		end
		-- Behind something solid standing out of the water, the waves barely reach you.
		if WaterObstacles.sheltered(position.X, position.Z, Beach.waterY(line)) then
			push *= Config.Water.ShelterFactor
		end
		return push
	end
	-- On the sand: under a running-up sheet or a sliding-back one, unless something solid
	-- stopped the water before it got here.
	for _, wave in list do
		if wave.Phase ~= "Rolling" and rel >= Waves.frontAt(position.X, line, wave.Front) then
			local strength = wave.Size * scale
			if wave.Phase == "RunUp" then
				return SHORE * cfg.RunUpPush * (1 - wave.PhaseProgress) * strength
			end
			-- Sliding back: strongest as it rushes down, easing off at the end.
			return -SHORE
				* cfg.BackwashPull
				* math.sin(math.pi * math.max(wave.PhaseProgress, 0.15))
				* strength
		end
	end
	return Vector3.zero
end

function Waves.getPush(position: Vector3, sea: Sea): Vector3
	local line = Tide.waterlineAt(sea, position.X)
	local rel = position.Z - line
	local scale = workspace:GetAttribute(Waves.ScaleAttribute) or 1
	local push = pushAt(position, sea, line, rel, scale)
	if rel > 0 then
		push += sway(position.X, sea.Now, rel) * scale
	end
	return push
end

-- Where a run-up's front really is at X: on open sand, `front`; with something solid in the
-- way, stopped just short of it unless the water climbs higher than its top.
function Waves.frontAt(x: number, line: number, front: number): number
	if front >= 0 then
		return front
	end
	local reachY = Beach.waterY(line) - front * Config.Beach.Slope
	return WaterObstacles.limitFront(x, line, front, reachY)
end

-- How far up the beach the water reaches at X right now (distance from the waterline, 0 or
-- negative), and whether it's sliding back.
function Waves.edgeAt(x: number, sea: Sea, waterline: number?): (number, boolean)
	local edge, sliding = 0, false
	for _, wave in Waves.wavesAt(x, sea, waterline) do
		local front = if wave.Phase ~= "Rolling"
			then Waves.frontAt(x, waterline or Tide.waterlineAt(sea, x), wave.Front)
			else 0
		if front < edge then
			edge, sliding = front, wave.Phase == "Backwash"
		end
	end
	return edge, sliding
end

-- Keeps a floating part at the water surface and lets the current carry it out. Returns false
-- (and does nothing) when the part isn't in the water.
function Waves.applyFloat(part: BasePart, dt: number, sea: Sea): boolean
	local surface = Beach.surfaceY(part.Position, sea)
	local below = surface - part.Position.Y -- > 0: its centre is under water
	if below < -part.Size.Y / 2 or Beach.depthAt(part.Position, sea) <= 0 then
		return false
	end
	local velocity = part.AssemblyLinearVelocity
	local gravity = workspace.Gravity
	-- A spring around "half under water", damped so it settles instead of bouncing.
	local lift = gravity * (1 + cfg.FloatSpring * math.max(below, 0)) - cfg.FloatDamping * velocity.Y
	if below < 0 then
		lift = gravity * (1 + below / (part.Size.Y / 2)) - cfg.FloatDamping * velocity.Y
	end
	-- Rock pools are still water: no current.
	local inSea = Beach.seaDepthAt(part.Position, sea) > 0
	local drift = Vector3.new(
		-velocity.X * cfg.FloatDrag,
		0,
		((if inSea then cfg.FloatDrift else 0) - velocity.Z) * cfg.FloatDrag
	)
	part:ApplyImpulse((Vector3.new(0, lift, 0) + drift) * part.Mass * dt)
	part.AssemblyAngularVelocity *= 0.95
	return true
end

-- Applies one frame of wave push to an unanchored part this machine simulates.
-- `multiplier` lets stats (Sea Legs, Barnacle Boots) reduce the push, capped below.
function Waves.applyToPart(part: BasePart, dt: number, sea: Sea, multiplier: number?)
	if part.Anchored or part.Massless then
		return
	end
	-- Cargo is welded into its vessel, so it rides with it instead of floating on its own.
	local floats = part:GetAttribute("Floats") and part:GetAttribute("State") ~= "InVessel"
	if floats and Waves.applyFloat(part, dt, sea) then
		-- Floating at the surface: waves still push it, but it doesn't sink.
		local push = Waves.getPush(part.Position, sea)
		local scale = math.max(multiplier or 1, cfg.MinPushFraction)
		part:ApplyImpulse(push * cfg.ItemFactor * cfg.FloatWavePush * scale * part.Mass * dt)
		return
	end
	local push = Waves.getPush(part.Position, sea)
	-- Per-part mass, so a multi-part vessel gets pushed once in total, not once per part.
	local mass = part.Mass
	local impulse = push * cfg.ItemFactor * math.max(multiplier or 1, cfg.MinPushFraction)
	if part.Position.Y < Beach.surfaceY(part.Position, sea) then
		impulse += Vector3.new(0, workspace.Gravity * cfg.Buoyancy, 0)
	end
	if impulse.Magnitude > 0 then
		part:ApplyImpulse(impulse * mass * dt)
	end
end

return Waves
