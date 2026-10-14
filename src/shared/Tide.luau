-- Deterministic tide. The server stores the cycle start time on Workspace once; after
-- that, server and every client compute the exact same tide from the shared clock, so
-- nothing needs to be replicated per frame.

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)

local Tide = {}

Tide.StartAttribute = "TideCycleStart"
Tide.ScaleAttribute = "TideTimeScale" -- set by the admin console; overrides Config.Tide.TimeScale

local cfg = Config.Tide
local beach = Config.Beach

-- Waterline Z at high and low tide. Zone 1 is always partly uncovered; only low tide makes
-- the channel to the Far Sandbar shallow enough to cross.
Tide.HighWaterline = cfg.HighWaterline
Tide.LowWaterline = cfg.LowWaterline

-- How far out the tide is (0-1) at `p` (0-1) through a phase, from a list of evenly spaced
-- values joined by a smooth (Catmull-Rom) curve.
local function shaped(points: { number }, p: number): number
	local n = #points - 1
	if n < 1 then
		return math.clamp(p, 0, 1)
	end
	p = math.clamp(p, 0, 1)
	local segment = math.min(math.floor(p * n), n - 1)
	local t = p * n - segment
	local p1 = points[segment + 1]
	local p2 = points[segment + 2]
	local p0 = points[segment] or p1
	local p3 = points[segment + 3] or p2
	local t2, t3 = t * t, t * t * t
	local value = 0.5
		* (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
	return math.clamp(value, 0, 1)
end
Tide._shaped = shaped

function Tide.durations()
	local scale = Workspace:GetAttribute(Tide.ScaleAttribute) or cfg.TimeScale
	return cfg.OutTime * scale, cfg.HoldTime * scale, cfg.InTime * scale
end

function Tide.cycleLength(): number
	local outTime, holdTime, inTime = Tide.durations()
	return outTime + holdTime + inTime
end

function Tide.now(): number
	return Workspace:GetServerTimeNow()
end

function Tide.cycleStart(): number
	return Workspace:GetAttribute(Tide.StartAttribute) or 0
end

export type State = {
	Phase: "Out" | "Hold" | "In",
	PhaseProgress: number,
	PhaseRemaining: number,
	Waterline: number, -- Z where the sea meets the sand
	WaterY: number, -- height of the sea surface
	Cycle: number,
}

-- Phase "Out": the tide is going out, uncovering the outer zones.
-- Phase "Hold": low tide, the far zone is reachable.
-- Phase "In": the tide is coming back in toward the shop.
local function rawState(now: number?): State
	local outTime, holdTime, inTime = Tide.durations()
	local length = outTime + holdTime + inTime
	local elapsed = (now or Tide.now()) - Tide.cycleStart()
	local cycle = math.floor(elapsed / length)
	local t = elapsed - cycle * length

	if t < outTime then
		local p = t / outTime
		return {
			Phase = "Out",
			PhaseProgress = p,
			PhaseRemaining = outTime - t,
			Waterline = Tide.HighWaterline
				+ (Tide.LowWaterline - Tide.HighWaterline) * shaped(cfg.OutShape, p),
			Cycle = cycle,
			WaterY = 0,
		}
	elseif t < outTime + holdTime then
		local h = t - outTime
		return {
			Phase = "Hold",
			PhaseProgress = h / holdTime,
			PhaseRemaining = holdTime - h,
			Waterline = Tide.LowWaterline,
			Cycle = cycle,
			WaterY = 0,
		}
	else
		local i = t - outTime - holdTime
		local p = i / inTime
		return {
			Phase = "In",
			PhaseProgress = p,
			PhaseRemaining = inTime - i,
			Waterline = Tide.LowWaterline - (Tide.LowWaterline - Tide.HighWaterline) * shaped(cfg.InShape, p),
			Cycle = cycle,
			WaterY = 0,
		}
	end
end

-- The cycle start time that puts the tide at `progress` (0-1) through `phase` right now.
function Tide.startFor(phase: string, progress: number, now: number?): number
	local outTime, holdTime, inTime = Tide.durations()
	local offset
	if phase == "Out" then
		offset = outTime * progress
	elseif phase == "Hold" then
		offset = outTime + holdTime * progress
	else
		offset = outTime + holdTime + inTime * progress
	end
	return (now or Tide.now()) - offset
end

function Tide.getState(now: number?): State
	local state = rawState(now)
	-- The beach is a straight slope, so the sea surface is the ground height at the waterline.
	state.WaterY = -state.Waterline * beach.Slope
	return state
end

-- Just the waterline for a moment (no table; called a lot).
local function waterlineFor(now: number): number
	local outTime, holdTime, inTime = Tide.durations()
	local length = outTime + holdTime + inTime
	local elapsed = now - Tide.cycleStart()
	local t = elapsed - math.floor(elapsed / length) * length
	local range = Tide.LowWaterline - Tide.HighWaterline
	if t < outTime then
		return Tide.HighWaterline + range * shaped(cfg.OutShape, t / outTime)
	elseif t < outTime + holdTime then
		return Tide.LowWaterline
	end
	return Tide.LowWaterline - range * shaped(cfg.InShape, (t - outTime - holdTime) / inTime)
end

-- The waterline at X = 0's reference point of the tide (no section delay). Most code wants
-- the waterline where something actually is: use Tide.sea() and Tide.waterlineAt().
function Tide.waterline(now: number?): number
	return rawState(now).Waterline
end

-- Sections: the delay (seconds, already time-scaled) for a point along the shoreline.
function Tide.lagAt(x: number): number
	local sections = cfg.Sections
	if not sections or #sections == 0 then
		return 0
	end
	local scale = Workspace:GetAttribute(Tide.ScaleAttribute) or cfg.TimeScale
	if x <= sections[1].X then
		return sections[1].Lag * scale
	end
	for i = 2, #sections do
		local a, b = sections[i - 1], sections[i]
		if x <= b.X then
			local t = (x - a.X) / (b.X - a.X)
			t = t * t * (3 - 2 * t) -- blend smoothly between points
			return (a.Lag + (b.Lag - a.Lag) * t) * scale
		end
	end
	return sections[#sections].Lag * scale
end

-- A moment of the sea. Pass it to Beach and Waves functions; they work out the waterline at
-- each position from it, since different parts of the beach drain at different times.
export type Sea = { Now: number }

function Tide.sea(now: number?): Sea
	return { Now = now or Tide.now() }
end

-- The waterline (Z) at a point along the shoreline.
function Tide.waterlineAt(sea: Sea, x: number): number
	return waterlineFor(sea.Now - Tide.lagAt(x))
end

return Tide
