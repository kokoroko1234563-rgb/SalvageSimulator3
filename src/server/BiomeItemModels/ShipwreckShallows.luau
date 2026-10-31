-- Models for the Shipwreck Shallows items (docs/design/biome-items.md). Each builder works
-- in the root's own frame, like the ones in ItemModels.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local ModelParts = require(script.Parent.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder

local Metal = Palette.Material.Metal
local Smooth = Palette.Material.Smooth
local Glass = Palette.Material.Glass
local Rock = Palette.Material.Rock
local Fabric = Palette.Material.Fabric
local Foil = Palette.Material.Foil
local Neon = Palette.Material.Neon
local M = Palette.ItemModel

local ALONG_Y = ModelParts.ALONG_Y
local ALONG_Z = ModelParts.ALONG_Z
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

builders.BrassPorthole = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.35)
	local light = shade(color, 0.2)
	local verdigris = Color3.fromRGB(90, 160, 130)
	-- The thick outer flange, made of segments round a hole, and the inner bezel.
	local outer, inner = 0.57, 0.43
	for i = 0, 13 do
		local a = i / 14 * 2 * math.pi
		piece(
			root,
			"Flange",
			Block,
			Vector3.new(0.2, 2 * outer * math.tan(math.pi / 14) * 1.06 + 0.02, 0.3),
			CFrame.new(outer * math.cos(a), outer * math.sin(a), 0.0) * CFrame.Angles(0, 0, a),
			color,
			Metal
		)
	end
	for i = 0, 9 do
		local a = i / 10 * 2 * math.pi
		piece(
			root,
			"Bezel",
			Block,
			Vector3.new(0.1, 2 * inner * math.tan(math.pi / 10) * 1.06 + 0.02, 0.2),
			CFrame.new(inner * math.cos(a), inner * math.sin(a), 0.1) * CFrame.Angles(0, 0, a),
			light,
			Metal
		)
	end
	-- The thick glass set deep in it, over a dark inside, with a shine.
	piece(
		root,
		"Inside",
		Cylinder,
		Vector3.new(0.04, 0.78, 0.78),
		CFrame.new(0, 0, -0.1) * ALONG_Z,
		M.Hole,
		Smooth
	)
	piece(
		root,
		"Glass",
		Cylinder,
		Vector3.new(0.1, 0.8, 0.8),
		CFrame.new(0, 0, 0.0) * ALONG_Z,
		M.MaskGlass,
		Glass,
		0.35
	)
	bar(root, "Shine", Vector3.new(-0.22, 0.2, 0.06), Vector3.new(-0.05, 0.32, 0.06), 0.05, M.White, Neon)
	bar(root, "Shine", Vector3.new(-0.3, 0.05, 0.06), Vector3.new(-0.25, 0.1, 0.06), 0.04, M.White, Neon)
	-- Eight bolts round the flange.
	for i = 0, 7 do
		local a = (i + 0.5) / 8 * 2 * math.pi
		piece(
			root,
			"Bolt",
			Cylinder,
			Vector3.new(0.06, 0.12, 0.12),
			CFrame.new(0.57 * math.cos(a), 0.57 * math.sin(a), 0.15) * ALONG_Z,
			dark,
			Metal
		)
	end
	-- The hinge at the top and the swing-bolt and wing nut on the right.
	piece(root, "Hinge", Block, Vector3.new(0.36, 0.16, 0.2), CFrame.new(0, 0.66, 0.0), dark, Metal)
	piece(root, "HingePin", Cylinder, Vector3.new(0.4, 0.07, 0.07), CFrame.new(0, 0.66, 0.08), light, Metal)
	piece(root, "Clasp", Block, Vector3.new(0.14, 0.34, 0.12), CFrame.new(0.64, 0, 0.1), dark, Metal)
	piece(root, "WingNut", Block, Vector3.new(0.24, 0.07, 0.1), CFrame.new(0.64, 0, 0.17), light, Metal)
	piece(root, "WingNut", Block, Vector3.new(0.07, 0.24, 0.1), CFrame.new(0.64, 0, 0.17), light, Metal)
	-- Verdigris and barnacles from the sea.
	piece(
		root,
		"Verdigris",
		Ball,
		Vector3.new(0.3, 0.2, 0.1),
		CFrame.new(-0.42, -0.42, 0.14),
		verdigris,
		Rock
	)
	piece(root, "Verdigris", Ball, Vector3.new(0.2, 0.26, 0.08), CFrame.new(0.3, 0.45, 0.15), verdigris, Rock)
	piece(
		root,
		"Barnacle",
		Ball,
		Vector3.new(0.12, 0.12, 0.1),
		CFrame.new(0.18, -0.55, 0.14),
		M.Barnacle,
		Rock
	)
	piece(
		root,
		"Barnacle",
		Ball,
		Vector3.new(0.09, 0.09, 0.08),
		CFrame.new(-0.55, 0.2, 0.15),
		M.Barnacle,
		Rock
	)
end

builders.ShipsLogbook = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	local light = shade(color, 0.2)
	-- Leather covers either side of a block of cream pages, and a rounded spine on the left.
	piece(root, "Pages", Block, Vector3.new(0.88, 0.19, 1.3), CFrame.new(0.04, 0, 0), M.Paper, Smooth)
	for _, y in { -0.07, 0, 0.07 } do
		piece(
			root,
			"PageLine",
			Block,
			Vector3.new(0.89, 0.012, 1.31),
			CFrame.new(0.04, y, 0),
			shade(M.Paper, -0.25),
			Smooth
		)
	end
	piece(root, "CoverTop", Block, Vector3.new(0.96, 0.05, 1.4), CFrame.new(0.02, 0.12, 0), color, Fabric)
	piece(root, "CoverBottom", Block, Vector3.new(0.96, 0.05, 1.4), CFrame.new(0.02, -0.12, 0), color, Fabric)
	piece(
		root,
		"Spine",
		Cylinder,
		Vector3.new(1.4, 0.28, 0.28),
		CFrame.new(-0.42, 0, 0) * ALONG_Z,
		dark,
		Fabric
	)
	for _, z in { -0.5, -0.17, 0.17, 0.5 } do
		piece(
			root,
			"Band",
			Cylinder,
			Vector3.new(0.07, 0.3, 0.3),
			CFrame.new(-0.42, 0, z) * ALONG_Z,
			M.Gold,
			Metal
		)
	end
	-- Brass corners, and a strap across with a buckle.
	for _, x in { -0.44, 0.46 } do
		for _, z in { -0.65, 0.65 } do
			piece(root, "Corner", Block, Vector3.new(0.16, 0.08, 0.16), CFrame.new(x, 0.12, z), M.Gold, Metal)
		end
	end
	piece(root, "Strap", Block, Vector3.new(0.9, 0.03, 0.13), CFrame.new(0.0, 0.145, 0.3), dark, Fabric)
	piece(root, "Buckle", Block, Vector3.new(0.14, 0.04, 0.2), CFrame.new(0.3, 0.151, 0.3), M.Gold, Metal)
	piece(root, "BuckleHole", Block, Vector3.new(0.07, 0.02, 0.1), CFrame.new(0.3, 0.161, 0.3), dark, Smooth)
	-- An anchor stamped on the cover, with a water stain.
	piece(
		root,
		"Stain",
		Ball,
		Vector3.new(0.4, 0.02, 0.32),
		CFrame.new(0.15, 0.141, -0.35),
		light,
		Fabric,
		0.3
	)
	local y = 0.147
	bar(root, "AnchorShaft", Vector3.new(0.05, y, -0.65), Vector3.new(0.05, y, -0.25), 0.045, M.Gold, Metal)
	bar(root, "AnchorBar", Vector3.new(-0.08, y, -0.56), Vector3.new(0.18, y, -0.56), 0.04, M.Gold, Metal)
	bar(root, "AnchorFluke", Vector3.new(-0.12, y, -0.36), Vector3.new(0.05, y, -0.25), 0.04, M.Gold, Metal)
	bar(root, "AnchorFluke", Vector3.new(0.22, y, -0.36), Vector3.new(0.05, y, -0.25), 0.04, M.Gold, Metal)
	piece(
		root,
		"AnchorRing",
		Cylinder,
		Vector3.new(0.015, 0.09, 0.09),
		CFrame.new(0.05, y, -0.68) * ALONG_Y,
		M.Gold,
		Metal
	)
end

builders.SilverDoubloons = function(root, def)
	local color = def.Color
	local tarnish = shade(color, -0.3)
	local emboss = shade(color, -0.12)
	local function coin(name: string, at: CFrame, tone: Color3)
		piece(root, name, Cylinder, Vector3.new(0.07, 0.44, 0.44), at * ALONG_Y, tone, Metal)
		piece(
			root,
			name .. "Rim",
			Cylinder,
			Vector3.new(0.075, 0.35, 0.35),
			at * ALONG_Y,
			shade(tone, -0.18),
			Metal
		)
		piece(
			root,
			name .. "Face",
			Cylinder,
			Vector3.new(0.08, 0.26, 0.26),
			at * ALONG_Y,
			shade(tone, 0.06),
			Metal
		)
	end
	-- A tilted stack of four, a shorter stack of two, and loose coins on the ground.
	for i = 0, 3 do
		coin(
			"Stack",
			CFrame.new(-0.08 + (i % 2) * 0.03, -0.165 + i * 0.07, -0.05 + (i % 3) * 0.02)
				* CFrame.Angles(0, i * 0.6, 0),
			if i % 2 == 0 then color else tarnish
		)
	end
	for i = 0, 1 do
		coin(
			"Pair",
			CFrame.new(-0.22, -0.165 + i * 0.07, 0.25 - i * 0.02) * CFrame.Angles(0, i * 0.9, 0),
			if i == 0 then tarnish else color
		)
	end
	coin("Loose", CFrame.new(0.22, -0.165, -0.25) * CFrame.Angles(0, 0.5, 0), color)
	coin("Loose", CFrame.new(0.24, -0.165, 0.25) * CFrame.Angles(0, 1.1, 0), tarnish)
	-- One coin leaning on the stack, face out, with a cross stamped on it.
	local lean = CFrame.new(0.22, -0.01, 0.0) * CFrame.Angles(0, 0, -0.95)
	piece(root, "Leaning", Cylinder, Vector3.new(0.07, 0.44, 0.44), lean * ALONG_Y, color, Metal)
	piece(root, "LeaningRim", Cylinder, Vector3.new(0.075, 0.35, 0.35), lean * ALONG_Y, tarnish, Metal)
	piece(
		root,
		"LeaningCrossA",
		Block,
		Vector3.new(0.09, 0.26, 0.04),
		lean * CFrame.new(0, 0, 0),
		emboss,
		Metal
	)
	piece(
		root,
		"LeaningCrossB",
		Block,
		Vector3.new(0.09, 0.04, 0.26),
		lean * CFrame.new(0, 0, 0),
		emboss,
		Metal
	)
end

builders.TreasureMap = function(root, def)
	local color = def.Color
	local ink = Color3.fromRGB(95, 65, 40)
	local y = 0.027
	-- The parchment with a stained, torn look: a base sheet, darker edges and rough corners.
	piece(root, "Sheet", Block, Vector3.new(1.46, 0.04, 1.08), CFrame.new(0.03, 0, 0), color, Fabric)
	piece(
		root,
		"Stain",
		Ball,
		Vector3.new(0.6, 0.02, 0.45),
		CFrame.new(0.15, 0.02, -0.25),
		shade(color, -0.12),
		Fabric
	)
	piece(
		root,
		"Stain",
		Ball,
		Vector3.new(0.35, 0.02, 0.3),
		CFrame.new(-0.5, 0.02, 0.3),
		shade(color, -0.08),
		Fabric
	)
	piece(
		root,
		"EdgeFar",
		Block,
		Vector3.new(1.46, 0.035, 0.06),
		CFrame.new(0.03, 0, -0.55),
		shade(color, -0.2),
		Fabric
	)
	piece(
		root,
		"EdgeNear",
		Block,
		Vector3.new(1.46, 0.035, 0.06),
		CFrame.new(0.03, 0, 0.55),
		shade(color, -0.2),
		Fabric
	)
	for _, spec in { { 0.76, -0.2, 0.1, 0.18 }, { 0.78, 0.25, 0.08, 0.14 }, { 0.5, -0.56, 0.2, 0.06 } } do
		piece(
			root,
			"Torn",
			Block,
			Vector3.new(spec[3], 0.035, spec[4]),
			CFrame.new(spec[1], 0, spec[2]) * CFrame.Angles(0, 0.3, 0),
			shade(color, -0.1),
			Fabric
		)
	end
	-- The rolled-up left edge, tied.
	piece(
		root,
		"Roll",
		Cylinder,
		Vector3.new(1.0, 0.1, 0.1),
		CFrame.new(-0.75, 0.0, 0) * ALONG_Z,
		shade(color, -0.1),
		Fabric
	)
	piece(
		root,
		"Tie",
		Cylinder,
		Vector3.new(0.05, 0.11, 0.11),
		CFrame.new(-0.75, 0.0, 0.25) * ALONG_Z,
		M.Wax,
		Fabric
	)
	-- The island, with a palm and a hill, and the sea's wave marks.
	piece(
		root,
		"Island",
		Ball,
		Vector3.new(0.5, 0.02, 0.34),
		CFrame.new(-0.3, y, 0.15),
		shade(color, -0.25),
		Fabric
	)
	piece(
		root,
		"Grass",
		Ball,
		Vector3.new(0.3, 0.025, 0.2),
		CFrame.new(-0.28, y + 0.003, 0.13),
		M.Moss,
		Fabric
	)
	bar(root, "Hill", Vector3.new(-0.2, y, 0.05), Vector3.new(-0.12, y, -0.04), 0.03, ink, Smooth)
	bar(root, "Hill", Vector3.new(-0.04, y, 0.05), Vector3.new(-0.12, y, -0.04), 0.03, ink, Smooth)
	for _, spec in { { 0.3, 0.38 }, { -0.1, -0.38 }, { 0.5, -0.42 }, { -0.5, -0.3 } } do
		bar(
			root,
			"Wave",
			Vector3.new(spec[1] - 0.07, y, spec[2]),
			Vector3.new(spec[1], y, spec[2] - 0.03),
			0.02,
			M.Aqua,
			Smooth
		)
		bar(
			root,
			"Wave",
			Vector3.new(spec[1], y, spec[2] - 0.03),
			Vector3.new(spec[1] + 0.07, y, spec[2]),
			0.02,
			M.Aqua,
			Smooth
		)
	end
	-- A dotted path winding off to a big red X.
	local stops = {
		Vector3.new(-0.05, y, 0.22),
		Vector3.new(0.12, y, 0.1),
		Vector3.new(0.05, y, -0.05),
		Vector3.new(0.28, y, -0.12),
		Vector3.new(0.38, y, -0.25),
	}
	for i = 1, #stops - 1 do
		local a, b = stops[i], stops[i + 1]
		bar(root, "Path", a:Lerp(b, 0.1), a:Lerp(b, 0.55), 0.025, M.Wax, Smooth)
		bar(root, "Path", a:Lerp(b, 0.7), a:Lerp(b, 0.95), 0.025, M.Wax, Smooth)
	end
	bar(
		root,
		"MarkA",
		Vector3.new(0.4, y + 0.004, -0.35),
		Vector3.new(0.58, y + 0.004, -0.17),
		0.05,
		M.Wax,
		Smooth
	)
	bar(
		root,
		"MarkB",
		Vector3.new(0.4, y + 0.004, -0.17),
		Vector3.new(0.58, y + 0.004, -0.35),
		0.05,
		M.Wax,
		Smooth
	)
	-- A compass rose in the corner.
	local rose = Vector3.new(0.5, y, 0.3)
	piece(root, "RoseRing", Cylinder, Vector3.new(0.012, 0.26, 0.26), CFrame.new(rose) * ALONG_Y, ink, Smooth)
	piece(
		root,
		"RoseFace",
		Cylinder,
		Vector3.new(0.016, 0.23, 0.23),
		CFrame.new(rose + Vector3.new(0, 0.001, 0)) * ALONG_Y,
		color,
		Fabric
	)
	bar(
		root,
		"RoseNS",
		rose + Vector3.new(0, 0.004, -0.16),
		rose + Vector3.new(0, 0.004, 0.16),
		0.025,
		ink,
		Smooth
	)
	bar(
		root,
		"RoseEW",
		rose + Vector3.new(-0.16, 0.004, 0),
		rose + Vector3.new(0.16, 0.004, 0),
		0.025,
		ink,
		Smooth
	)
	piece(
		root,
		"RoseNorth",
		Block,
		Vector3.new(0.045, 0.01, 0.07),
		CFrame.new(rose + Vector3.new(0, 0.008, -0.12)),
		M.Wax,
		Smooth
	)
end

return builders
