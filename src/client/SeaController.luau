-- Draws the sea locally, from the same shared clock the server uses, so nothing replicates.
-- The beach is cut into strips along the shoreline. Each strip has its own:
--   * sea surface, at that strip's water level (parts of the beach drain at different times,
--     Config.Tide.Sections), so the waterline curves along the beach;
--   * wave crests rolling in toward the waterline, taller for bigger waves;
--   * the swash: the thin sheet of water a wave pushes up the sand, with a foam edge, which
--     slides back afterwards;
--   * wet sand, from the waterline up to where the tide or the last waves reached.
-- It also warns the player when a rogue wave is on its way.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Palette = require(Shared.Palette)
local Tide = require(Shared.Tide)
local Waves = require(Shared.Waves)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local SeaController = {}

local beach = Config.Beach
local waves = Config.Waves

local STRIP = 24 -- studs along the shoreline per strip
local THICKNESS = 4
local SIDE = 700 -- sea beyond the beach on each side, past the headlands
local TILT = CFrame.Angles(math.atan(beach.Slope), 0, 0) -- lies flat on the sloping sand
local FAR = CFrame.new(0, -10000, 0)

local SWASH = Palette.World.Sea:Lerp(Color3.new(1, 1, 1), 0.35)

type Strip = {
	x: number,
	width: number,
	sea: Part,
	swash: Part,
	edge: Part,
	wet: Part,
	crests: { Part },
}

local strips: { Strip } = {}
local zMin, zMax = 0, 0

local function makePart(name: string, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = FAR
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function newStrip(folder: Folder, x: number, width: number, detailed: boolean): Strip
	local strip: Strip = {
		x = x,
		width = width,
		sea = makePart("Sea", {
			Size = Vector3.new(width + 0.05, THICKNESS, zMax - zMin),
			Material = Palette.Material.Glass,
			Color = Palette.World.Sea,
			Transparency = 0.3,
		}),
		swash = nil :: any,
		edge = nil :: any,
		wet = nil :: any,
		crests = {},
	}
	strip.sea.Parent = folder
	if detailed then
		strip.swash = makePart("Swash", {
			Size = Vector3.new(width + 0.05, 0.1, 1),
			Material = Palette.Material.Glass,
			Color = SWASH,
			Transparency = 0.45,
		})
		strip.edge = makePart("Foam", {
			Size = Vector3.new(width + 0.05, 0.14, 1.4),
			Material = Palette.Material.Smooth,
			Color = Palette.World.Foam,
			Transparency = 0.25,
		})
		strip.wet = makePart("WetSand", {
			Size = Vector3.new(width + 0.05, 0.06, 1),
			Material = Palette.Material.Sand,
			Color = Palette.World.WetSand,
			Transparency = 0.45,
		})
		for i = 1, 2 do
			local crest = makePart("Crest" .. i, {
				Size = Vector3.new(width + 0.05, 0.6, 2.5),
				Material = Palette.Material.Smooth,
				Color = Palette.World.Foam,
				Transparency = 0.4,
			})
			crest.Parent = folder
			strip.crests[i] = crest
		end
		strip.swash.Parent = folder
		strip.edge.Parent = folder
		strip.wet.Parent = folder
	end
	return strip
end

-- A thin part lying on the sand from z0 to z1 (z1 < z0: up the beach).
local function onSand(part: Part, x: number, z0: number, z1: number, lift: number): CFrame
	local length = math.abs(z0 - z1)
	if math.abs(part.Size.Z - length) > 0.15 then
		part.Size = Vector3.new(part.Size.X, part.Size.Y, math.max(length, 0.2))
	end
	local z = (z0 + z1) / 2
	return CFrame.new(x, Beach.groundY(z) + lift, z) * TILT
end

local function setTransparency(part: Part, value: number)
	if math.abs(part.Transparency - value) > 0.02 then
		part.Transparency = value
	end
end

local warnedRogue = -1

local function update()
	local sea = Tide.sea()
	local parts, frames = {}, {}
	local function place(part: Part, frame: CFrame)
		table.insert(parts, part)
		table.insert(frames, frame)
	end
	local wetSea = Tide.sea(
		sea.Now - waves.WetSeconds * (Workspace:GetAttribute(Tide.ScaleAttribute) or Config.Tide.TimeScale)
	)

	for _, strip in strips do
		local line = Tide.waterlineAt(sea, strip.x)
		local waterY = Beach.waterY(line)
		place(strip.sea, CFrame.new(strip.x, waterY - THICKNESS / 2, (zMin + zMax) / 2))
		if not strip.swash then
			continue
		end

		local list = Waves.wavesAt(strip.x, sea, line)

		-- Wave crests rolling in, nearest the shore first.
		local crestIndex = 1
		for i = #list, 1, -1 do
			local wave = list[i]
			local crest = strip.crests[crestIndex]
			if wave.Phase == "Rolling" and crest then
				crestIndex += 1
				local height = 0.35 + 0.35 * wave.Size
				if math.abs(crest.Size.Y - height) > 0.05 then
					crest.Size = Vector3.new(crest.Size.X, height, crest.Size.Z)
				end
				-- Fades in out at sea, sharpest as it reaches the shore.
				setTransparency(crest, 0.25 + 0.6 * (1 - wave.PhaseProgress))
				place(crest, CFrame.new(strip.x, waterY + height * 0.3, line + wave.Front + 1.2))
			end
		end
		for i = crestIndex, #strip.crests do
			place(strip.crests[i], FAR)
		end

		-- The swash sheet and its foam edge.
		local edge, sliding = 0, false
		for _, wave in list do
			if wave.Phase ~= "Rolling" and wave.Front < edge then
				edge, sliding = wave.Front, wave.Phase == "Backwash"
			end
		end
		if edge < -0.3 then
			-- Only on the sand: once the water is back at the waterline, it's just the sea.
			place(strip.swash, onSand(strip.swash, strip.x, line, line + edge, 0.07))
			place(strip.edge, CFrame.new(strip.x, Beach.groundY(line + edge) + 0.09, line + edge) * TILT)
			setTransparency(strip.swash, if sliding then 0.6 else 0.45)
			setTransparency(strip.edge, if sliding then 0.55 else 0.2)
		else
			place(strip.swash, FAR)
			place(strip.edge, FAR)
		end

		-- Wet sand: up to where the tide was a little while ago, or the last wave reached.
		local lastReach = Waves.reach(Waves.indexAt(sea.Now) - 1, line, strip.x)
		local wetTo = math.min(Tide.waterlineAt(wetSea, strip.x), line - lastReach, line + edge)
		if wetTo < line - 0.5 then
			place(strip.wet, onSand(strip.wet, strip.x, line, wetTo, 0.04))
		else
			place(strip.wet, FAR)
		end
	end
	Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)

	-- Rogue waves are known in advance (the waves are deterministic): warn a few seconds out.
	-- The Foghorn warns earlier, and about big waves too.
	local worn = Gear.getAccessory(player:GetAttribute("Accessory"))
	local extra = if worn and worn.WaveWarning then worn.WaveWarning else 0
	local lead = 8 + extra
	local first = Waves.indexAt(sea.Now) + 1
	for upcoming = first, first + math.ceil(lead / waves.Period) do
		if upcoming <= warnedRogue then
			continue
		end
		local rogue = Waves.isRogue(upcoming)
		local big = extra > 0 and Waves.size(upcoming) >= waves.SetSize
		if rogue or big then
			local arrives = upcoming * waves.Period + waves.StartOffset / waves.Speed
			if arrives - sea.Now < lead then
				warnedRogue = upcoming
				HUD.banner(
					if rogue
						then "A rogue wave is coming! Get away from the water!"
						else "Your foghorn sounds: a big wave is coming!"
				)
			end
		end
	end
end

function SeaController.init()
	local folder = Instance.new("Folder")
	folder.Name = "LocalSea"
	folder.Parent = Workspace

	zMin = -beach.ShopDepth - 60
	zMax = Beach.Depth + beach.SeaExtent + 200

	local half = Beach.HalfWidth
	local count = math.ceil(beach.Width / STRIP)
	local width = beach.Width / count
	for i = 0, count - 1 do
		table.insert(strips, newStrip(folder, -half + width * (i + 0.5), width, true))
	end
	-- Plain sea beyond the headlands on each side.
	table.insert(strips, newStrip(folder, -half - SIDE / 2, SIDE, false))
	table.insert(strips, newStrip(folder, half + SIDE / 2, SIDE, false))

	RunService.RenderStepped:Connect(update)
end

-- For tools/tests.
SeaController._update = update

return SeaController
