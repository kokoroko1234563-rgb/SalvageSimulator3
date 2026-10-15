-- Runs the day/night cycle on this client from the shared clock (DayCycle): moves the sun
-- and moon (Lighting.ClockTime), dims and cools the light at night, and warms the haze at
-- sunrise and sunset. The server sets the daytime look once (BeachBuilder); this blends from
-- it, so the look stays tuned in one place.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local DayCycle = require(Shared.DayCycle)

local cfg = Config.Day

local DayController = {}

local NIGHT_FOG = Color3.fromRGB(30, 40, 70)

local base: any = nil

local function capture()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	base = {
		brightness = Lighting.Brightness,
		outdoor = Lighting.OutdoorAmbient,
		ambient = Lighting.Ambient,
		fog = Lighting.FogColor,
		atmosphere = atmosphere,
		atmosphereColor = if atmosphere then atmosphere.Color else nil,
	}
end

-- How close it is to sunrise or sunset (0-1).
local function glow(hour: number): number
	return math.max(
		math.clamp(1 - math.abs(hour - 6) / 1.5, 0, 1),
		math.clamp(1 - math.abs(hour - 18.2) / 1.5, 0, 1)
	)
end

function DayController.apply(hour: number)
	if not base then
		capture()
	end
	local night = DayCycle.nightness(hour)
	local warm = glow(hour)
	Lighting.ClockTime = hour
	Lighting.Brightness = base.brightness + (cfg.NightBrightness - base.brightness) * night
	Lighting.OutdoorAmbient = base.outdoor:Lerp(cfg.NightAmbient, night)
	Lighting.Ambient = base.ambient:Lerp(cfg.NightAmbient, night * 0.5)
	Lighting.FogColor = base.fog:Lerp(cfg.DuskColor, warm * 0.6):Lerp(NIGHT_FOG, night * 0.8)
	if base.atmosphere and base.atmosphereColor then
		base.atmosphere.Color =
			base.atmosphereColor:Lerp(cfg.DuskColor, warm * 0.5):Lerp(NIGHT_FOG, night * 0.6)
	end
end

function DayController.init()
	local elapsed = 1
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			DayController.apply(DayCycle.hour())
		end
	end)
end

return DayController
