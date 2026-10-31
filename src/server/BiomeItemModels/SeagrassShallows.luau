-- Models for the Seagrass Shallows items (docs/design/biome-items.md). Each builder works in
-- the root's own frame, like the ones in ItemModels.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local ModelParts = require(script.Parent.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder

local Metal = Palette.Material.Metal
local Smooth = Palette.Material.Smooth
local Wood = Palette.Material.Wood
local WoodPlanks = Palette.Material.WoodPlanks
local Fabric = Palette.Material.Fabric
local Glass = Palette.Material.Glass
local Rock = Palette.Material.Rock
local Foil = Palette.Material.Foil
local Neon = Palette.Material.Neon
local Grass = Palette.Material.Grass
local M = Palette.ItemModel

local ALONG_Y = ModelParts.ALONG_Y
local ALONG_Z = ModelParts.ALONG_Z
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

builders.KelpBundle = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	local light = shade(color, 0.2)
	-- Strands of kelp lying along X, each a wavy chain of bars with a flat frond at the end.
	local strands = {
		{ y = 0.08, z = -0.26, phase = 0.0 },
		{ y = -0.04, z = -0.13, phase = 1.2 },
		{ y = 0.1, z = 0.0, phase = 2.4 },
		{ y = -0.06, z = 0.13, phase = 3.6 },
		{ y = 0.06, z = 0.26, phase = 4.8 },
	}
	for index, strand in strands do
		local points = {}
		for step = 0, 5 do
			local x = -0.55 + step * 0.22
			table.insert(
				points,
				Vector3.new(
					x,
					strand.y + 0.06 * math.sin(strand.phase + step * 1.1),
					strand.z + 0.05 * math.cos(strand.phase + step)
				)
			)
		end
		for step = 1, #points - 1 do
			bar(
				root,
				"Strand",
				points[step],
				points[step + 1],
				0.09,
				if (index + step) % 2 == 0 then color else light,
				Grass
			)
		end
		-- The frond at the far end, a flat ruffled blade.
		piece(
			root,
			"Frond",
			Block,
			Vector3.new(0.24, 0.025, 0.18),
			CFrame.new(points[6] + Vector3.new(0.05, 0, 0)) * CFrame.Angles(0.15, index * 0.3 - 0.9, 0),
			dark,
			Grass
		)
		-- And an air bladder, like a little bead on the stem.
		piece(
			root,
			"Bladder",
			Ball,
			Vector3.new(0.13, 0.12, 0.13),
			CFrame.new(points[3] + Vector3.new(0, 0.04, 0)),
			M.Sun:Lerp(color, 0.55),
			Smooth
		)
	end
	-- A cut stump of roots at the other end.
	for index = 1, 3 do
		bar(
			root,
			"Root",
			Vector3.new(-0.58, 0, (index - 2) * 0.15),
			Vector3.new(-0.76, 0.04 * index - 0.08, (index - 2) * 0.28),
			0.06,
			dark,
			Grass
		)
	end
	-- Twine round the bundle.
	for _, x in { -0.35, 0.2 } do
		piece(root, "Twine", Cylinder, Vector3.new(0.08, 0.38, 0.7), CFrame.new(x, 0, 0), M.Cork, Fabric)
		piece(root, "TwineKnot", Ball, Vector3.new(0.1, 0.08, 0.1), CFrame.new(x, 0.2, 0.05), M.Cork, Fabric)
	end
end

builders.DriedSeahorse = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	local light = shade(color, 0.2)
	-- The body is a chain in the Y-Z plane: head, neck, belly, tail curling forward.
	local spine = {
		{ 0.44, 0.04, 0.1 },
		{ 0.32, 0.0, 0.1 },
		{ 0.14, 0.04, 0.13 },
		{ -0.04, 0.02, 0.11 },
		{ -0.24, -0.04, 0.09 },
		{ -0.44, -0.05, 0.07 },
		{ -0.54, 0.04, 0.06 },
		{ -0.46, 0.14, 0.05 },
		{ -0.36, 0.14, 0.05 },
		{ -0.35, 0.06, 0.04 },
	}
	for i = 1, #spine - 1 do
		local a, b = spine[i], spine[i + 1]
		bar(
			root,
			"Body",
			Vector3.new(0, a[1], a[2]),
			Vector3.new(0, b[1], b[2]),
			(a[3] + b[3]) / 2 * 1.7,
			color,
			Smooth
		)
	end
	for i = 2, #spine - 1 do
		local s = spine[i]
		piece(
			root,
			"Joint",
			Ball,
			Vector3.new(s[3] * 1.8, s[3] * 1.8, s[3] * 1.8),
			CFrame.new(0, s[1], s[2]),
			if i % 2 == 0 then color else light,
			Smooth
		)
		-- The bony rings of the dried body.
		piece(
			root,
			"Ring",
			Block,
			Vector3.new(s[3] * 2.1, 0.03, s[3] * 2.1),
			CFrame.new(0, s[1] - 0.05, s[2]),
			dark,
			Smooth
		)
	end
	-- The belly pouch, the head with its long snout, and the eye.
	piece(root, "Belly", Ball, Vector3.new(0.3, 0.34, 0.26), CFrame.new(0, 0.1, 0.1), light, Smooth)
	piece(root, "Head", Ball, Vector3.new(0.25, 0.26, 0.26), CFrame.new(0, 0.47, 0.05), color, Smooth)
	piece(
		root,
		"Snout",
		Cylinder,
		Vector3.new(0.2, 0.1, 0.1),
		CFrame.new(0, 0.43, 0.14) * ALONG_Z,
		color,
		Smooth
	)
	piece(root, "SnoutTip", Ball, Vector3.new(0.09, 0.09, 0.09), CFrame.new(0, 0.43, 0.24), dark, Smooth)
	piece(root, "Eye", Ball, Vector3.new(0.07, 0.07, 0.04), CFrame.new(0.1, 0.51, 0.11), M.Hole, Smooth)
	piece(root, "Eye", Ball, Vector3.new(0.07, 0.07, 0.04), CFrame.new(-0.1, 0.51, 0.11), M.Hole, Smooth)
	-- A crown of little spines on its head, then a dorsal fin and spikes down the back.
	for i = 0, 2 do
		piece(
			root,
			"Crest",
			Block,
			Vector3.new(0.04, 0.1, 0.04),
			CFrame.new(0, 0.6 - i * 0.02, -0.02 - i * 0.05) * CFrame.Angles(-0.4 - i * 0.2, 0, 0),
			dark,
			Smooth
		)
	end
	piece(
		root,
		"DorsalFin",
		Block,
		Vector3.new(0.025, 0.24, 0.12),
		CFrame.new(0, 0.12, -0.1) * CFrame.Angles(0.2, 0, 0),
		light,
		Foil
	)
	for i = 0, 4 do
		piece(
			root,
			"Spike",
			Ball,
			Vector3.new(0.06, 0.06, 0.06),
			CFrame.new(0, 0.3 - i * 0.16, -0.07 - i * 0.02),
			dark,
			Smooth
		)
	end
	piece(root, "PectoralFin", Block, Vector3.new(0.02, 0.1, 0.08), CFrame.new(0.14, 0.33, 0.0), light, Foil)
end

builders.JettySign = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	local light = shade(color, 0.2)
	local paint = Color3.fromRGB(235, 232, 215)
	-- The post it hung from, with a crossarm and a rusty hook.
	piece(root, "Post", Block, Vector3.new(0.2, 1.15, 0.2), CFrame.new(-0.88, 0, -0.04), dark, Wood)
	piece(root, "PostCap", Block, Vector3.new(0.26, 0.08, 0.24), CFrame.new(-0.88, 0.58, -0.04), color, Wood)
	piece(root, "Arm", Block, Vector3.new(1.7, 0.12, 0.14), CFrame.new(0.0, 0.5, -0.04), dark, Wood)
	piece(
		root,
		"Brace",
		Block,
		Vector3.new(0.12, 0.45, 0.1),
		CFrame.new(-0.6, 0.35, -0.04) * CFrame.Angles(0, 0, 0.9),
		dark,
		Wood
	)
	-- The board, made of weathered planks of slightly different colours.
	for index, y in { 0.28, 0.1, -0.08 } do
		piece(
			root,
			"Plank",
			Block,
			Vector3.new(1.55, 0.17, 0.08),
			CFrame.new(0.1, y, 0.06),
			if index == 2 then light else color,
			WoodPlanks
		)
	end
	-- Painted lettering gone patchy, and an arrow.
	for index, x in { -0.5, -0.3, -0.1, 0.12, 0.32 } do
		piece(
			root,
			"Letter",
			Block,
			Vector3.new(0.1, 0.22 - (index % 2) * 0.05, 0.02),
			CFrame.new(x, 0.1, 0.11),
			paint,
			Smooth
		)
	end
	bar(
		root,
		"ArrowShaft",
		Vector3.new(-0.5, -0.07, 0.11),
		Vector3.new(0.6, -0.07, 0.11),
		0.035,
		paint,
		Smooth
	)
	bar(root, "ArrowHead", Vector3.new(0.45, 0.0, 0.11), Vector3.new(0.62, -0.07, 0.11), 0.035, paint, Smooth)
	bar(
		root,
		"ArrowHead",
		Vector3.new(0.45, -0.14, 0.11),
		Vector3.new(0.62, -0.07, 0.11),
		0.035,
		paint,
		Smooth
	)
	-- Hung from the arm on two chains, with rusty nails and some weed on the corner.
	for _, x in { -0.55, 0.7 } do
		bar(root, "Chain", Vector3.new(x, 0.45, 0.0), Vector3.new(x, 0.37, 0.05), 0.04, M.Iron, Metal)
		piece(root, "Nail", Ball, Vector3.new(0.07, 0.07, 0.05), CFrame.new(x, -0.08, 0.11), M.Iron, Metal)
		piece(root, "Nail", Ball, Vector3.new(0.07, 0.07, 0.05), CFrame.new(x, 0.28, 0.11), M.Iron, Metal)
	end
	piece(root, "Weed", Ball, Vector3.new(0.3, 0.12, 0.1), CFrame.new(0.65, -0.2, 0.1), M.Moss, Grass)
	piece(
		root,
		"Barnacle",
		Ball,
		Vector3.new(0.1, 0.08, 0.08),
		CFrame.new(-0.6, -0.15, 0.1),
		M.Barnacle,
		Rock
	)
end

builders.MermaidsMirror = function(root, def)
	local glass = def.Color
	local frame = Color3.fromRGB(110, 205, 190)
	local pearl = M.Label
	local centre = Vector2.new(0, 0.15)
	-- The glass in a ring of scales, with a back plate.
	piece(
		root,
		"Back",
		Cylinder,
		Vector3.new(0.05, 0.78, 0.78),
		CFrame.new(centre.X, centre.Y, -0.04) * ALONG_Z,
		shade(frame, -0.3),
		Metal
	)
	piece(
		root,
		"Glass",
		Cylinder,
		Vector3.new(0.04, 0.7, 0.7),
		CFrame.new(centre.X, centre.Y, 0.02) * ALONG_Z,
		glass,
		Glass,
		0.1
	)
	piece(
		root,
		"Shine",
		Block,
		Vector3.new(0.07, 0.4, 0.02),
		CFrame.new(centre.X - 0.12, centre.Y + 0.05, 0.05) * CFrame.Angles(0, 0, -0.5),
		M.White,
		Neon,
		0.55
	)
	piece(
		root,
		"Shine",
		Block,
		Vector3.new(0.04, 0.2, 0.02),
		CFrame.new(centre.X - 0.02, centre.Y - 0.08, 0.05) * CFrame.Angles(0, 0, -0.5),
		M.White,
		Neon,
		0.55
	)
	for i = 0, 15 do
		local a = i / 16 * 2 * math.pi
		piece(
			root,
			"Scale",
			Ball,
			Vector3.new(0.17, 0.12, 0.14),
			CFrame.new(centre.X + 0.4 * math.cos(a), centre.Y + 0.4 * math.sin(a), 0.0)
				* CFrame.Angles(0, 0, a),
			if i % 2 == 0 then frame else shade(frame, 0.25),
			Metal
		)
	end
	-- A scallop crest on top with a pearl, and pearls round the frame.
	for i = -2, 2 do
		piece(
			root,
			"Crest",
			Block,
			Vector3.new(0.08, 0.17 - math.abs(i) * 0.03, 0.06),
			CFrame.new(i * 0.14, centre.Y + 0.5 - math.abs(i) * 0.04, 0) * CFrame.Angles(0, 0, -i * 0.28),
			shade(frame, 0.15),
			Metal
		)
	end
	piece(
		root,
		"CrestPearl",
		Ball,
		Vector3.new(0.12, 0.12, 0.12),
		CFrame.new(0, centre.Y + 0.44, 0.05),
		pearl,
		Foil
	)
	for _, side in { -1, 1 } do
		piece(
			root,
			"Pearl",
			Ball,
			Vector3.new(0.1, 0.1, 0.1),
			CFrame.new(side * 0.47, centre.Y, 0.03),
			pearl,
			Foil
		)
	end
	-- The handle: a ringed stem ending in a mermaid's tail fin.
	piece(
		root,
		"Stem",
		Cylinder,
		Vector3.new(0.45, 0.1, 0.1),
		CFrame.new(0, -0.35, 0) * ALONG_Y,
		frame,
		Metal
	)
	for _, y in { -0.12, -0.55 } do
		piece(
			root,
			"StemRing",
			Cylinder,
			Vector3.new(0.05, 0.15, 0.15),
			CFrame.new(0, y, 0) * ALONG_Y,
			M.Gold,
			Metal
		)
	end
	piece(root, "Grip", Ball, Vector3.new(0.14, 0.14, 0.12), CFrame.new(0, -0.62, 0), pearl, Foil)
	for _, side in { -1, 1 } do
		bar(
			root,
			"TailFin",
			Vector3.new(0, -0.62, 0),
			Vector3.new(side * 0.28, -0.72, 0),
			0.07,
			shade(frame, 0.15),
			Metal
		)
		piece(
			root,
			"TailTip",
			Ball,
			Vector3.new(0.14, 0.1, 0.05),
			CFrame.new(side * 0.3, -0.7, 0),
			frame,
			Metal
		)
	end
end

builders.SeaPearlNecklace = function(root, def)
	local pearl = def.Color
	local radius = 0.48
	local count = 22
	local cz = -0.1
	-- Pearls strung in a loop lying flat, with a thread through them, a gold clasp and a
	-- pendant pearl in a gold cap at the front.
	for i = 0, count - 1 do
		local a = i / count * 2 * math.pi
		local skip = math.abs(i - count * 0.25) < 1.5
		if not skip then
			local at = Vector3.new(radius * math.cos(a), 0, radius * math.sin(a) + cz)
			piece(
				root,
				"Pearl",
				Ball,
				Vector3.new(0.17, 0.17, 0.17),
				CFrame.new(at),
				if i % 3 == 0 then M.Label else pearl,
				Foil
			)
			if i % 4 == 0 then
				piece(
					root,
					"Spacer",
					Cylinder,
					Vector3.new(0.04, 0.1, 0.1),
					CFrame.new(at) * CFrame.Angles(0, -a + math.pi / 2, 0),
					M.Gold,
					Metal
				)
			end
		end
	end
	-- The gold clasp at the back.
	piece(root, "Clasp", Block, Vector3.new(0.12, 0.08, 0.2), CFrame.new(0, 0, cz - radius), M.Gold, Metal)
	piece(
		root,
		"ClaspRing",
		Cylinder,
		Vector3.new(0.03, 0.16, 0.16),
		CFrame.new(0.0, 0.0, cz - radius) * ALONG_Y,
		shade(M.Gold, 0.2),
		Metal
	)
	-- The pendant: a bigger pearl in a gold cup, on two short chain bars.
	local front = Vector3.new(0, 0, radius + cz)
	bar(
		root,
		"ChainLeft",
		front + Vector3.new(-0.12, 0, -0.04),
		front + Vector3.new(-0.02, 0, 0.1),
		0.03,
		M.Gold,
		Metal
	)
	bar(
		root,
		"ChainRight",
		front + Vector3.new(0.12, 0, -0.04),
		front + Vector3.new(0.02, 0, 0.1),
		0.03,
		M.Gold,
		Metal
	)
	piece(
		root,
		"PendantCup",
		Cylinder,
		Vector3.new(0.08, 0.24, 0.24),
		CFrame.new(front + Vector3.new(0, 0, 0.06)) * ALONG_Y,
		M.Gold,
		Metal
	)
	piece(
		root,
		"PendantPearl",
		Ball,
		Vector3.new(0.26, 0.26, 0.26),
		CFrame.new(front + Vector3.new(0, 0, 0.15)),
		M.White,
		Foil
	)
	piece(
		root,
		"PendantShine",
		Ball,
		Vector3.new(0.07, 0.05, 0.07),
		CFrame.new(front + Vector3.new(-0.04, 0.1, 0.12)),
		M.Glint,
		Neon
	)
end

return builders
