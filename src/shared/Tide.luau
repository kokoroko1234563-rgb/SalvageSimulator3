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

-- Waterline Z at high and low tide. Zone 1 is always partly uncovered; low tide uncovers
-- most of the last zone.
Tide.HighWaterline = cfg.HighWaterline
Tide.LowWaterline = beach.ZoneLength * beach.ActiveZones - cfg.LowWaterlineFromEnd

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
			Waterline = Tide.HighWaterline + (Tide.LowWaterline - Tide.HighWaterline) * smoothstep(p),
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
			Waterline = Tide.LowWaterline - (Tide.LowWaterline - Tide.HighWaterline) * smoothstep(p),
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

function Tide.waterline(now: number?): number
	return rawState(now).Waterline
end

return Tide
