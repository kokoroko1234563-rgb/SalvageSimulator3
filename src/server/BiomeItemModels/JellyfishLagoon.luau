-- Jellyfish Lagoon item models (docs/design/biome-items.md). Each builder adds welded,
-- massless parts to the item's root in its own frame; see ItemModels.luau.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local ModelParts = require(script.Parent.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder

local Glass = Palette.Material.Glass
local Metal = Palette.Material.Metal
local Neon = Palette.Material.Neon
local Smooth = Palette.Material.Smooth
local Foil = Palette.Material.Foil

local M = Palette.ItemModel
local ALONG_Y = ModelParts.ALONG_Y
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

-- A bell dome built as stacked discs under a cap, translucent. Returns nothing.
local function dome(
	root: BasePart,
	color: Color3,
	baseY: number,
	radius: number,
	height: number,
	layers: number
)
	for index = 0, layers - 1 do
		local t = index / layers
		local r = radius * math.sqrt(1 - t * t)
		piece(
			root,
			"Bell",
			Cylinder,
			Vector3.new(height / layers + 0.01, r * 2, r * 2),
			CFrame.new(0, baseY + height * (index + 0.5) / layers, 0) * ALONG_Y,
			color,
			Glass,
			0.35
		)
	end
end

-- A trailing tentacle: a few bars wavering downward.
local function tentacle(
	root: BasePart,
	color: Color3,
	x: number,
	z: number,
	top: number,
	length: number,
	thickness: number
)
	local previous = Vector3.new(x, top, z)
	for step = 1, 3 do
		local sway = if step % 2 == 0 then 0.05 else -0.05
		local nextPoint = Vector3.new(x + sway, top - length * step / 3, z - sway)
		bar(root, "Tentacle", previous, nextPoint, thickness, color, Glass)
		previous = nextPoint
	end
end

-- A flat moon-pale jelly with four pale rings on its dome and short frills.
builders.MoonJelly = function(root, def)
	local color = def.Color
	dome(root, color, -0.08, 0.58, 0.36, 5)
	piece(
		root,
		"Rim",
		Cylinder,
		Vector3.new(0.08, 1.16, 1.16),
		CFrame.new(0, -0.1, 0) * ALONG_Y,
		shade(color, 0.15),
		Glass,
		0.3
	)
	-- The four rings of the moon jelly, seen through the bell.
	for index = 0, 3 do
		local angle = index / 4 * 2 * math.pi
		piece(
			root,
			"Ring",
			Ball,
			Vector3.new(0.2, 0.1, 0.2),
			CFrame.new(math.cos(angle) * 0.17, 0.12, math.sin(angle) * 0.17),
			M.Glint,
			Neon
		)
	end
	piece(root, "Core", Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0.02, 0), M.Glow, Neon, 0.3)
	-- Frills round the rim and oral arms hanging below.
	for index = 0, 7 do
		local angle = index / 8 * 2 * math.pi
		piece(
			root,
			"Frill",
			Ball,
			Vector3.new(0.14, 0.14, 0.14),
			CFrame.new(math.cos(angle) * 0.56, -0.12, math.sin(angle) * 0.56),
			shade(color, 0.3),
			Glass,
			0.2
		)
	end
	for _, x in { -0.14, 0.14 } do
		for _, z in { -0.14, 0.14 } do
			tentacle(root, shade(color, 0.2), x, z, -0.1, 0.2, 0.06)
		end
	end
end

-- A scallop shell lying open, ribbed and softly glowing from inside.
builders.GlowShell = function(root, def)
	local color = def.Color
	local pale = shade(color, 0.45)
	local hinge = Vector3.new(0, 0, -0.5)
	-- The valve: a fan of ribs spreading from the hinge, over a flat disc.
	piece(
		root,
		"Valve",
		Cylinder,
		Vector3.new(0.12, 0.95, 0.95),
		CFrame.new(0, -0.15, 0.02) * ALONG_Y,
		pale,
		Smooth
	)
	piece(
		root,
		"Glow",
		Cylinder,
		Vector3.new(0.06, 0.7, 0.7),
		CFrame.new(0, -0.08, 0.05) * ALONG_Y,
		color,
		Neon,
		0.35
	)
	for index = 0, 6 do
		local angle = math.rad(-30 + index * 10)
		local tip = hinge + Vector3.new(math.sin(angle) * 1.0, 0.1, math.cos(angle) * 1.0)
		local start = hinge + Vector3.new(math.sin(angle) * 0.12, -0.02, math.cos(angle) * 0.12)
		bar(root, "Rib", start, tip, 0.12, if index % 2 == 0 then color else pale, Smooth)
	end
	-- A second, lifted valve behind, hinged and propped open.
	piece(
		root,
		"Lid",
		Cylinder,
		Vector3.new(0.1, 0.9, 0.9),
		CFrame.new(0, 0.08, -0.25) * CFrame.Angles(math.rad(-25), 0, 0) * ALONG_Y,
		pale,
		Smooth
	)
	piece(
		root,
		"Hinge",
		Block,
		Vector3.new(0.4, 0.18, 0.14),
		CFrame.new(0, -0.05, -0.5),
		shade(color, -0.25),
		Smooth
	)
	for _, s in { -1, 1 } do
		piece(
			root,
			"Ear",
			Block,
			Vector3.new(0.22, 0.14, 0.18),
			CFrame.new(s * 0.26, -0.05, -0.44),
			pale,
			Smooth
		)
	end
	-- A glowing pearl in the shell.
	local pearl =
		piece(root, "Pearl", Ball, Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, 0.0, 0.1), M.Glow, Neon)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 7
	light.Brightness = 0.8
	light.Parent = pearl
end

-- A cube-shaped box jelly, hung as a lantern: a frame of four posts, a glowing bell, four tentacle bunches.
builders.BoxJellyLantern = function(root, def)
	local color = def.Color
	piece(root, "Bell", Block, Vector3.new(0.7, 0.62, 0.7), CFrame.new(0, 0.14, 0), color, Glass, 0.45)
	piece(
		root,
		"Crown",
		Block,
		Vector3.new(0.5, 0.12, 0.5),
		CFrame.new(0, 0.5, 0),
		shade(color, 0.2),
		Glass,
		0.3
	)
	local core = piece(root, "Core", Ball, Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 0.14, 0), color, Neon)
	for _, x in { -0.35, 0.35 } do
		for _, z in { -0.35, 0.35 } do
			bar(root, "Post", Vector3.new(x, -0.17, z), Vector3.new(x, 0.45, z), 0.07, M.Iron, Metal)
			-- A bunch of tentacles under each corner.
			tentacle(root, shade(color, 0.15), x * 0.8, z * 0.8, -0.17, 0.45, 0.07)
			tentacle(root, shade(color, 0.3), x * 0.5, z * 0.5, -0.17, 0.35, 0.05)
		end
	end
	piece(root, "Base", Block, Vector3.new(0.82, 0.08, 0.82), CFrame.new(0, -0.18, 0), M.Iron, Metal)
	piece(root, "Cap", Block, Vector3.new(0.82, 0.08, 0.82), CFrame.new(0, 0.46, 0), M.Iron, Metal)
	piece(
		root,
		"Collar",
		Cylinder,
		Vector3.new(0.1, 0.26, 0.26),
		CFrame.new(0, 0.54, 0) * ALONG_Y,
		M.Gold,
		Foil
	)
	ModelParts.arc(root, "Handle", Vector2.new(0, 0.5), 0.2, 20, 160, 0.06, M.Gold)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 9
	light.Brightness = 1
	light.Parent = core
end

-- A big pink jelly wearing a crown of tall points round its bell, with long frilled arms.
builders.CrownJelly = function(root, def)
	local color = def.Color
	dome(root, color, -0.1, 0.62, 0.5, 6)
	piece(
		root,
		"Rim",
		Cylinder,
		Vector3.new(0.1, 1.3, 1.3),
		CFrame.new(0, -0.12, 0) * ALONG_Y,
		shade(color, 0.15),
		Glass,
		0.3
	)
	local core =
		piece(root, "Core", Ball, Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0.1, 0), M.Glint, Neon, 0.2)
	-- The crown: nine spikes, each tipped with a glowing bead.
	for index = 0, 8 do
		local angle = index / 9 * 2 * math.pi
		local c, s = math.cos(angle), math.sin(angle)
		bar(
			root,
			"Spike",
			Vector3.new(c * 0.45, 0.25, s * 0.45),
			Vector3.new(c * 0.58, 0.46, s * 0.58),
			0.1,
			shade(color, 0.25),
			Glass
		)
		piece(
			root,
			"Bead",
			Ball,
			Vector3.new(0.14, 0.14, 0.14),
			CFrame.new(c * 0.6, 0.5, s * 0.6),
			M.Glint,
			Neon
		)
	end
	-- Eight long arms and a ring of short frills.
	for index = 0, 7 do
		local angle = index / 8 * 2 * math.pi
		tentacle(root, shade(color, 0.1), math.cos(angle) * 0.5, math.sin(angle) * 0.5, -0.14, 0.34, 0.09)
	end
	for index = 0, 3 do
		local angle = index / 4 * 2 * math.pi + math.pi / 4
		tentacle(root, shade(color, 0.3), math.cos(angle) * 0.22, math.sin(angle) * 0.22, -0.1, 0.38, 0.12)
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 10
	light.Brightness = 1
	light.Parent = core
end

return builders
