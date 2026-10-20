-- Runs the light on this client: the look of where you stand (Looks: each zone's and biome's
-- haze, ambient light and colour grading, blended as you walk, and darker under a roof), and
-- the day/night cycle from the shared clock (DayCycle) on top of it: moves the sun and moon
-- (Lighting.ClockTime), dims and cools the light at night, and warms the haze at sunrise and
-- sunset. Away from the beach (secrets, showroom) it keeps the shop's look.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local DayCycle = require(Shared.DayCycle)
local Looks = require(Shared.Looks)

local cfg = Config.Day

local DayController = {}

local NIGHT_FOG = Color3.fromRGB(30, 40, 70)
local GLOOM_HOUR = 19.2 -- the sky the deep zones' gloom holds to: just after sunset

local look: any = nil -- the look being shown, following where you stand
local roofShade = 0 -- 0 under open sky, 1 under a roof

-- The look where the player stands (the shop's off the beach), with the roof's shade.
local function targetLook(): (any, number)
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return Config.Looks.Zones[0], 0
	end
	local position = root.Position
	if position.Y > Config.Secrets.Origin.Y - 100 or position.X > Config.Showroom.Origin.X - 1000 then
		return Config.Looks.Zones[0], 0
	end
	local roofBottom = Beach.roofAt(position.X, position.Z)
	local covered = roofBottom ~= nil and position.Y < roofBottom
	return Looks.at(position.Z), if covered then 1 else 0
end

-- Moves the shown look toward the target, a step of `k` (0-1).
local function follow(target: any, k: number)
	if not look then
		look = table.clone(target)
		return
	end
	for key, value in target do
		local current = look[key]
		if typeof(value) == "Color3" then
			look[key] = current:Lerp(value, k)
		elseif type(value) == "number" then
			look[key] = current + (value - current) * k
		else
			look[key] = value
		end
	end
end

-- How close it is to sunrise or sunset (0-1).
local function glow(hour: number): number
	return math.max(
		math.clamp(1 - math.abs(hour - 6) / 1.5, 0, 1),
		math.clamp(1 - math.abs(hour - 18.2) / 1.5, 0, 1)
	)
end

-- The colour grading BeachBuilder made (a ColorCorrectionEffect in Lighting).
local function correction(): ColorCorrectionEffect?
	return Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
end

-- Benighted by the Gloom (HazardController sets it, 0 or 1): the world goes black, the sky
-- and the fog with it, so only lights show (the player's own lantern lights what's round them).
-- It closes in quickly and lifts slowly.
DayController.blind = 0
local blindNow = 0
local BLIND_IN, BLIND_OUT = 3, 0.6 -- per second
local atmosphereBase: { Glare: number, Haze: number }? = nil

function DayController.apply(hour: number, dt: number?)
	local target, covered = targetLook()
	local k = if dt then math.min(1, dt * Config.Looks.Response) else 1
	follow(target, k)
	roofShade += (covered - roofShade) * k
	local roof = Config.Looks.UnderRoof
	local shade = 1 + (roof.Light - 1) * roofShade

	-- The deep zones' gloom (their look's Gloom, 0-1): the light no brighter than that close to
	-- night, and the sky held in a late dusk, whatever the hour up the beach.
	local gloom = math.clamp(look.Gloom or 0, 0, 1)
	local night = math.max(DayCycle.nightness(hour), gloom)
	local warm = glow(hour) * (1 - gloom)
	local shownHour = if hour >= 6 and hour < GLOOM_HOUR then hour + (GLOOM_HOUR - hour) * gloom else hour
	local wanted = DayController.blind
	local rate = if wanted > blindNow then BLIND_IN else BLIND_OUT
	blindNow += math.clamp(wanted - blindNow, -rate * (dt or 1), rate * (dt or 1))
	local blind = blindNow
	local black = Color3.new()
	Lighting.ClockTime = shownHour
	Lighting.Brightness = (look.Brightness + (cfg.NightBrightness - look.Brightness) * night)
		* shade
		* (1 - blind)
	Lighting.OutdoorAmbient =
		look.Outdoor:Lerp(cfg.NightAmbient, night):Lerp(Color3.new(), 1 - shade):Lerp(black, blind)
	Lighting.Ambient = look.Ambient
		:Lerp(cfg.NightAmbient, night * 0.5)
		:Lerp(Color3.new(), (1 - shade) * 0.5)
		:Lerp(black, blind)
	Lighting.ExposureCompensation = -1.5 * blind
	local haze = look.Haze:Lerp(cfg.DuskColor, warm * 0.5):Lerp(NIGHT_FOG, night * 0.6):Lerp(black, blind)
	Lighting.FogColor = haze
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = haze
		atmosphere.Decay = look.Decay:Lerp(NIGHT_FOG, night * 0.6):Lerp(black, blind)
		-- (Its own glare and haze, remembered the first time, fade with the light.)
		atmosphereBase = atmosphereBase or { Glare = atmosphere.Glare, Haze = atmosphere.Haze }
		atmosphere.Glare = atmosphereBase.Glare * (1 - blind)
		atmosphere.Haze = atmosphereBase.Haze * (1 - blind)
	end
	local grading = correction()
	if grading then
		grading.TintColor = look.Tint
		grading.Saturation = look.Saturation + roof.Saturation * roofShade
		grading.Contrast = look.Contrast
		grading.Brightness = look.Exposure + roof.Exposure * roofShade
	end
end

-- The fog density of the look being shown (MistController thickens the mist to it).
function DayController.fog(): number?
	return look and look.Fog
end

function DayController.init()
	local elapsed = 1
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.1 then
			DayController.apply(DayCycle.hour(), elapsed)
			elapsed = 0
		end
	end)
end

return DayController
