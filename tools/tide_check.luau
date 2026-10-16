--[[
	Checks the tide against the descent: when the sea uncovers each zone going out and covers
	it coming back, and where a regular player walking the zones' CrossTime targets (and the
	Far Sandbar's channel) would be held up by the water, or caught by it on the way back.

	Usage (from the repo root): lune run tools/tide_check.luau [start]
	`start`: seconds after high tide the player sets off from the shop (default 0).
]]

local process = require("@lune/process")

local Harness = require("./tests/harness")

local h = Harness.new(process.cwd)
local Beach = h.require("Shared/Beach")
local Config = h.require("Shared/Config")
local Tide = h.require("Shared/Tide")

local X = -120 -- where the sections' delay is 0
local base = Tide.cycleStart()
local outTime, holdTime, inTime = Tide.durations()

local function line(t: number): number
	return Tide.waterlineAt(Tide.sea(base + t), X)
end

-- The first time (from high tide, in steps of 1 s) the waterline is past z going out, and
-- the first time after low tide that it's back over z.
local function uncovered(z: number): number?
	for t = 0, outTime + holdTime do
		if line(t) >= z then
			return t
		end
	end
	return nil
end
local function covered(z: number): number?
	for t = outTime + holdTime, outTime + holdTime + inTime do
		if line(t) < z then
			return t
		end
	end
	return nil
end

print(
	string.format(
		"Tide: out %d s, low for %d s, back in %d s. High water Z %d, low Z %d.",
		outTime,
		holdTime,
		inTime,
		Config.Tide.HighWaterline,
		Config.Tide.LowWaterline
	)
)
print("\nWhen each zone is uncovered and covered again (at x " .. X .. "):")
print("zone  top uncovered  bottom uncovered   bottom covered  top covered")
for zone = 1, Config.Beach.ActiveZones do
	local z0, z1 = Beach.zoneRange(zone)
	print(
		string.format(
			"%4d  %10s s  %13s s  %13s s  %9s s",
			zone,
			tostring(uncovered(z0)),
			tostring(uncovered(z1)),
			tostring(covered(z1)),
			tostring(covered(z0))
		)
	)
end
local sandbar = Config.Beach.FarSandbar
print(
	string.format(
		"Far Sandbar channel (Z %d to %d): uncovered at %s s, covered at %s s",
		sandbar.ChannelStart,
		sandbar.ChannelEnd,
		tostring(uncovered(sandbar.ChannelEnd)),
		tostring(covered(sandbar.ChannelStart))
	)
)

-- A regular: walks each zone in its CrossTime, but can't go past the waterline.
local start = tonumber(process.args[1]) or 0
print(string.format("\nA regular setting off at %d s, walking each zone in its CrossTime:", start))
local t = start
local waited = 0
for zone = 1, Config.Beach.ActiveZones do
	local z0, z1 = Beach.zoneRange(zone)
	local cross = Config.Zones[zone].CrossTime
	local open = uncovered(z1) or math.huge
	local finish = math.max(t + cross, open)
	local wait = finish - (t + cross)
	waited += wait
	print(
		string.format(
			"  zone %d: in at %3d s, out at %3d s%s",
			zone,
			t,
			finish,
			if wait > 0 then string.format("  (held up %d s by the water)", wait) else ""
		)
	)
	t = finish
end
local channelOpen = uncovered(sandbar.ChannelEnd) or math.huge
local atSandbar = math.max(t + 10, channelOpen)
print(
	string.format(
		"  Far Sandbar reached at %d s (%.1f min), %d s of it waiting for the water",
		atSandbar,
		atSandbar / 60,
		waited + (atSandbar - t - 10)
	)
)

-- And back up, setting off from the sandbar as soon as they arrive (or at the end of low tide).
print("\nComing back up straight away, each zone in its CrossTime:")
local back = atSandbar + 10
local margins = {}
for zone = Config.Beach.ActiveZones, 1, -1 do
	local z0 = Beach.zoneRange(zone)
	back += Config.Zones[zone].CrossTime
	local catch = covered(z0) or math.huge
	table.insert(
		margins,
		string.format(
			"zone %d top at %d s, the sea there at %s s (%s s to spare)",
			zone,
			back,
			tostring(catch),
			tostring(catch - back)
		)
	)
end
for _, m in margins do
	print("  " .. m)
end
-- Latest the sandbar can be left and still make it.
local function survives(leave: number): boolean
	local time = leave + 10
	for zone = Config.Beach.ActiveZones, 1, -1 do
		local z0 = Beach.zoneRange(zone)
		time += Config.Zones[zone].CrossTime
		if time > (covered(z0) or math.huge) then
			return false
		end
	end
	return true
end
local latest = nil
for leave = atSandbar, outTime + holdTime + inTime do
	if survives(leave) then
		latest = leave
	end
end
print(
	string.format(
		"Latest a regular can leave the sandbar and get back dry: %s s (%s s after arriving)",
		tostring(latest),
		tostring(latest and latest - atSandbar)
	)
)
