-- Surface textures for the sand and the sea floor: ripples, foam lace, wet sheen, pebble beds,
-- shell grit, seagrass meadows, light patches under the water, and so on. We don't import image
-- textures (they'd mean outside assets), so each texture is a small "stamp" made of thin,
-- flat parts laid on the ground, in the same sand and sea colours as everything else.
--
-- They're cosmetic: flat, non-colliding, and a few hundredths of a stud thick, so they never
-- change how anything walks, tows or grabs. Cosmetics.luau places them.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Config = require(Shared.Config)

local MapParts = require(script.Parent.MapParts)

local Textures = {}

local C = Palette.Cosmetic
local W = Palette.World
local M = Palette.Material
local add = MapParts.scenery

local TILT = math.atan(Config.Beach.Slope)

export type Kind = {
	Id: string,
	Name: string,
	Theme: string, -- a zone name, or a biome name for the biome textures
	Region: string, -- "band" (anywhere in its zone), "sea" (always under water) or "plot" (in its biome's plot)
	Count: number, -- how many stamps
	Build: (Instance, Vector3, Random) -> (),
	Range: { number }?, -- if set, only place stamps between these two Z values
}

Textures.List = {} :: { Kind }

-- A flat patch lying on the ground at `pos` (a ground point), following the slope of the beach.
local function ground(pos: Vector3, yaw: number?): CFrame
	local base = CFrame.new(pos + Vector3.new(0, 0.04, 0))
	if pos.Z > 0 then
		base = base * CFrame.Angles(TILT, 0, 0)
	end
	return base * CFrame.Angles(0, yaw or 0, 0)
end

local function patch(
	parent: Instance,
	pos: Vector3,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	yaw: number?
)
	return add(parent, {
		Name = "Patch",
		Size = size,
		CFrame = ground(pos, yaw),
		Color = color,
		Material = material or M.Smooth,
		Transparency = transparency or 0,
	})
end

local function round(
	parent: Instance,
	pos: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	return add(parent, {
		Name = "RoundPatch",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.05, diameter, diameter),
		CFrame = ground(pos) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Material = material or M.Smooth,
		Transparency = transparency or 0,
	})
end

local function speck(
	parent: Instance,
	pos: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	return add(parent, {
		Name = "Speck",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter * 0.6, diameter),
		CFrame = CFrame.new(pos + Vector3.new(0, diameter * 0.2, 0)),
		Color = color,
		Material = material or M.Smooth,
		Transparency = transparency or 0,
	})
end

local function texture(
	id: string,
	name: string,
	theme: string,
	region: string,
	count: number,
	build: (Instance, Vector3, Random) -> (),
	range: { number }?
)
	table.insert(Textures.List, {
		Id = id,
		Name = name,
		Theme = theme,
		Region = region,
		Count = count,
		Build = build,
		Range = range,
	})
end

local SHOPSIDE, SUNNY, BANKS, OUTER, FAR =
	"Shopside Shore", "Sunny Stretch", "Middle Banks", "Outer Shore", "The Far Sandbar"
local darkSand = C.Sand:Lerp(C.Ink, 0.12)
local wetSand = W.WetSand

-- Sand ------------------------------------------------------------------------------------------

texture("Ripples", "Sand ripples", SHOPSIDE, "band", 22, function(p, c, rng)
	local yaw = rng:NextNumber(-0.3, 0.3)
	for i = 0, 4 do
		patch(
			p,
			c + Vector3.new(0, 0, i * 0.8 - 1.6),
			Vector3.new(rng:NextNumber(5, 9), 0.05, 0.14),
			darkSand,
			M.Sand,
			0.15,
			yaw
		)
	end
end)

texture("FoamLace", "Foam lace", SHOPSIDE, "band", 16, function(p, c, rng)
	for _ = 1, 4 do
		round(
			p,
			c + Vector3.new(rng:NextNumber(-2.5, 2.5), 0, rng:NextNumber(-1.2, 1.2)),
			rng:NextNumber(1.5, 3),
			W.Foam,
			M.Smooth,
			0.55
		)
	end
end, { 30, 100 }) -- only near the high-tide line

texture("BirdTracks", "Bird tracks", SHOPSIDE, "band", 14, function(p, c, rng)
	local yaw = rng:NextNumber() * math.pi * 2
	for i = 0, 5 do
		local step = Vector3.new(math.sin(yaw) * i * 1.1, 0, math.cos(yaw) * i * 1.1)
		for k = -1, 1 do
			patch(p, c + step, Vector3.new(0.08, 0.05, 0.45), darkSand, M.Sand, 0.1, yaw + k * 0.5)
		end
	end
end)

texture("WetSheen", "Wet sheen", SUNNY, "band", 18, function(p, c, rng)
	patch(
		p,
		c,
		Vector3.new(rng:NextNumber(8, 15), 0.04, rng:NextNumber(3, 6)),
		wetSand,
		M.Sand,
		0.5,
		rng:NextNumber(-0.4, 0.4)
	)
end)

texture("ShellGrit", "Shell grit", SUNNY, "band", 18, function(p, c, rng)
	local colors = { C.Cream, C.Pink, C.Peach, C.White }
	for _ = 1, 14 do
		speck(
			p,
			c + Vector3.new(rng:NextNumber(-2.5, 2.5), 0, rng:NextNumber(-2.5, 2.5)),
			rng:NextNumber(0.15, 0.3),
			colors[rng:NextInteger(1, #colors)]
		)
	end
end)

texture("Gravel", "Gravel", SUNNY, "band", 14, function(p, c, rng)
	local colors = { C.Grey, C.Stone, C.DarkGrey, C.Brown }
	for _ = 1, 20 do
		speck(
			p,
			c + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)),
			rng:NextNumber(0.15, 0.3),
			colors[rng:NextInteger(1, #colors)],
			M.Rock
		)
	end
end)

texture("PebbleBed", "Pebble bed", BANKS, "band", 18, function(p, c, rng)
	local colors = { C.Grey, C.Stone, C.Brown, C.DarkGrey }
	for _ = 1, 12 do
		speck(
			p,
			c + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)),
			rng:NextNumber(0.3, 0.5),
			colors[rng:NextInteger(1, #colors)],
			M.Rock
		)
	end
end)

texture("WrackLine", "Seaweed wrack", BANKS, "band", 18, function(p, c, rng)
	local colors = { C.Olive, C.Moss, C.Brown }
	for i = 0, 5 do
		patch(
			p,
			c + Vector3.new(i * 0.9 - 2.2, 0, rng:NextNumber(-0.4, 0.4)),
			Vector3.new(rng:NextNumber(0.8, 1.4), 0.1, rng:NextNumber(0.3, 0.5)),
			colors[rng:NextInteger(1, #colors)],
			M.Fabric,
			0,
			rng:NextNumber() * math.pi
		)
	end
end)

texture("DampPatch", "Damp patch", BANKS, "band", 18, function(p, c, rng)
	round(p, c, rng:NextNumber(4, 7), wetSand, M.Sand, 0.45)
end)

texture("MudFlat", "Mud flat", BANKS, "band", 14, function(p, c, rng)
	patch(
		p,
		c,
		Vector3.new(rng:NextNumber(6, 10), 0.04, rng:NextNumber(4, 7)),
		C.Brown,
		M.Dirt,
		0.3,
		rng:NextNumber(-0.5, 0.5)
	)
end)

texture("CoralRubble", "Coral rubble", OUTER, "band", 16, function(p, c, rng)
	local colors = { C.Coral, C.Pink, C.Peach, C.White }
	for _ = 1, 8 do
		speck(
			p,
			c + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)),
			rng:NextNumber(0.3, 0.5),
			colors[rng:NextInteger(1, #colors)]
		)
	end
end)

texture("GlitterSand", "Glitter sand", FAR, "band", 16, function(p, c, rng)
	for _ = 1, 10 do
		speck(p, c + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), 0.12, C.Gold, M.Neon, 0.2)
	end
end)

texture("SaltCrust", "Salt crust", FAR, "band", 14, function(p, c, rng)
	for _ = 1, 3 do
		patch(
			p,
			c + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)),
			Vector3.new(rng:NextNumber(2, 4), 0.04, rng:NextNumber(1.5, 3)),
			C.White,
			M.Smooth,
			0.3,
			rng:NextNumber() * math.pi
		)
	end
end)

-- Sea floor ---------------------------------------------------------------------------------------

texture("Caustics", "Light patches", OUTER, "sea", 24, function(p, c, rng)
	for _ = 1, 3 do
		round(
			p,
			c + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)),
			rng:NextNumber(2.5, 4.5),
			C.Aqua,
			M.Neon,
			0.85
		)
	end
end)

texture("Holdfast", "Kelp holdfasts", OUTER, "sea", 16, function(p, c, rng)
	for _ = 1, 3 do
		round(
			p,
			c + Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5)),
			rng:NextNumber(0.8, 1.4),
			C.Moss,
			M.Smooth,
			0.1
		)
	end
end)

texture("SeagrassMeadow", "Seagrass meadow", OUTER, "sea", 18, function(p, c, rng)
	local colors = { C.Moss, C.Green, C.Olive }
	for _ = 1, 20 do
		local h = rng:NextNumber(1, 1.6)
		add(p, {
			Name = "Blade",
			Size = Vector3.new(0.15, h, 0.04),
			CFrame = CFrame.new(c + Vector3.new(rng:NextNumber(-2.5, 2.5), h / 2, rng:NextNumber(-2.5, 2.5)))
				* CFrame.Angles(
					rng:NextNumber(-0.2, 0.2),
					rng:NextNumber() * math.pi,
					rng:NextNumber(-0.2, 0.2)
				),
			Color = colors[rng:NextInteger(1, #colors)],
			Material = M.Smooth,
		})
	end
end)

texture("AlgaeMat", "Algae mat", OUTER, "sea", 16, function(p, c, rng)
	round(p, c, rng:NextNumber(3, 5), C.Moss, M.Smooth, 0.35)
end)

-- Biome textures, laid inside that biome's plot ------------------------------------------------

texture("BlackDust", "Black dust", "Black Sand Vents", "plot", 12, function(p, c, rng)
	round(p, c, rng:NextNumber(3, 5), C.Ink, M.Sand, 0.4)
end)

texture("FrostPatch", "Frost", "Stranded Iceberg", "plot", 12, function(p, c, rng)
	round(p, c, rng:NextNumber(3, 5), C.White, M.Smooth, 0.5)
	round(
		p,
		c + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)),
		rng:NextNumber(1.5, 2.5),
		C.Aqua,
		M.Glass,
		0.6
	)
end)

texture("GlassSparkle", "Glass sparkle", "Sea-Glass Shore", "plot", 12, function(p, c, rng)
	local colors = { C.Aqua, C.Pink, C.White, C.Lavender, C.Mint }
	for _ = 1, 6 do
		add(p, {
			Name = "Sparkle",
			Size = Vector3.new(0.3, 0.12, 0.3),
			CFrame = CFrame.new(c + Vector3.new(rng:NextNumber(-2, 2), 0.08, rng:NextNumber(-2, 2)))
				* CFrame.Angles(0, rng:NextNumber() * math.pi, 0),
			Color = colors[rng:NextInteger(1, #colors)],
			Material = M.Glass,
			Transparency = 0.2,
		})
	end
end)

return Textures
