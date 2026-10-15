-- The day/night clock, computed from the shared server clock like the tide, so the server and
-- every client agree without sending anything. The server stores when the day started
-- (Workspace "DayStart"); the admin console can move it with `time <hour>`.

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)

local cfg = Config.Day

local DayCycle = {}

DayCycle.StartAttribute = "DayStart"

-- Fraction of the cycle (0-1) for an hour of the day. Daylight (6 to 18) takes DayShare.
function DayCycle.fractionFor(hour: number): number
	hour %= 24
	local day = hour - 6
	if day < 0 then
		day += 24
	end
	if day < 12 then
		return day / 12 * cfg.DayShare
	end
	return cfg.DayShare + (day - 12) / 12 * (1 - cfg.DayShare)
end

-- The hour of the day (0-24) at a fraction of the cycle.
function DayCycle.hourFor(fraction: number): number
	fraction %= 1
	if fraction < cfg.DayShare then
		return 6 + 12 * fraction / cfg.DayShare
	end
	return (18 + 12 * (fraction - cfg.DayShare) / (1 - cfg.DayShare)) % 24
end

-- The start time that makes it `hour` o'clock at `now`.
function DayCycle.startFor(hour: number, now: number): number
	return now - DayCycle.fractionFor(hour) * cfg.Length
end

-- The hour of the day right now (or at `now`).
function DayCycle.hour(now: number?): number
	local t = now or Workspace:GetServerTimeNow()
	local start = Workspace:GetAttribute(DayCycle.StartAttribute) or DayCycle.startFor(cfg.StartHour, 0)
	return DayCycle.hourFor((t - start) / cfg.Length)
end

-- "Day", "Twilight" (dawn 5-7, dusk 17-19.5) or "Night".
function DayCycle.period(hour: number): string
	if hour >= 7 and hour < 17 then
		return "Day"
	elseif (hour >= 5 and hour < 7) or (hour >= 17 and hour < 19.5) then
		return "Twilight"
	end
	return "Night"
end

-- How much it's night (0 full day, 1 full night), ramping through dawn and dusk.
function DayCycle.nightness(hour: number): number
	if hour >= 7 and hour < 17 then
		return 0
	elseif hour >= 5 and hour < 7 then
		return 1 - (hour - 5) / 2
	elseif hour >= 17 and hour < 19.5 then
		return (hour - 17) / 2.5
	end
	return 1
end

return DayCycle
