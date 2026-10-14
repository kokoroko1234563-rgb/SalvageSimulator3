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

-- The tide front never covers zone 1; at full extent it uncovers the far end of the beach.
Tide.MinFrontX = beach.ZoneLength
Tide.MaxFrontX = beach.ZoneLength * beach.ActiveZones

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

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
	FrontX: number,
	Cycle: number,
}

-- Phase "Out": the water is travelling down the beach, uncovering it.
-- Phase "Hold": the far end is reachable.
-- Phase "In": the water is returning toward the shop.
function Tide.getState(now: number?): State
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
			FrontX = Tide.MinFrontX + (Tide.MaxFrontX - Tide.MinFrontX) * smoothstep(p),
			Cycle = cycle,
		}
	elseif t < outTime + holdTime then
		local h = t - outTime
		return {
			Phase = "Hold",
			PhaseProgress = h / holdTime,
			PhaseRemaining = holdTime - h,
			FrontX = Tide.MaxFrontX,
			Cycle = cycle,
		}
	else
		local i = t - outTime - holdTime
		local p = i / inTime
		return {
			Phase = "In",
			PhaseProgress = p,
			PhaseRemaining = inTime - i,
			FrontX = Tide.MaxFrontX - (Tide.MaxFrontX - Tide.MinFrontX) * smoothstep(p),
			Cycle = cycle,
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

function Tide.frontX(now: number?): number
	return Tide.getState(now).FrontX
end

return Tide
