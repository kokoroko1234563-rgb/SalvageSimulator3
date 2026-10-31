-- Models for the Driftwood Cove items (docs/design/biome-items.md). Each builder works in
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
local M = Palette.ItemModel

local ALONG_Y = ModelParts.ALONG_Y
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar
local arc = ModelParts.arc

local builders = {}

builders.DriftwoodBranch = function(root, def)
	local color = def.Color
	local grain = shade(color, -0.25)
	local pale = shade(color, 0.2)
	-- The limb: a few bars along X that wander and taper, joined by knuckles.
	local spine = {
		{ -1.45, 0.05, 0.0, 0.26 },
		{ -0.8, -0.05, 0.04, 0.3 },
		{ -0.1, 0.06, -0.03, 0.28 },
		{ 0.6, -0.04, 0.03, 0.24 },
		{ 1.2, 0.04, 0.0, 0.18 },
		{ 1.5, 0.0, -0.02, 0.12 },
	}
	for i = 1, #spine - 1 do
		local a, b = spine[i], spine[i + 1]
		bar(
			root,
			"Limb",
			Vector3.new(a[1], a[2], a[3]),
			Vector3.new(b[1], b[2], b[3]),
			(a[4] + b[4]) / 2,
			color,
			Wood
		)
	end
	for i = 2, #spine - 1 do
		local s = spine[i]
		piece(
			root,
			"Knuckle",
			Ball,
			Vector3.new(s[4] + 0.04, s[4] + 0.04, s[4] + 0.04),
			CFrame.new(s[1], s[2], s[3]),
			color,
			Wood
		)
	end
	-- Weathered grooves along it, and the pale cut end.
	bar(root, "Grain", Vector3.new(-1.2, 0.14, 0.1), Vector3.new(0.3, 0.12, 0.14), 0.04, grain, Wood)
	bar(root, "Grain", Vector3.new(-0.9, -0.12, -0.12), Vector3.new(0.9, -0.1, -0.12), 0.04, grain, Wood)
	piece(root, "CutEnd", Cylinder, Vector3.new(0.06, 0.26, 0.26), CFrame.new(-1.48, 0.05, 0), pale, Wood)
	-- Two side twigs and a knot.
	bar(root, "Twig", Vector3.new(-0.3, 0.02, 0.05), Vector3.new(-0.05, 0.1, 0.3), 0.1, color, Wood)
	bar(root, "TwigTip", Vector3.new(-0.05, 0.1, 0.3), Vector3.new(0.2, 0.18, 0.3), 0.07, color, Wood)
	bar(root, "Twig", Vector3.new(0.7, 0.0, -0.02), Vector3.new(0.9, 0.12, -0.27), 0.08, color, Wood)
	piece(root, "Knot", Ball, Vector3.new(0.2, 0.2, 0.14), CFrame.new(-0.55, 0.0, 0.22), grain, Wood)
	piece(
		root,
		"KnotEye",
		Ball,
		Vector3.new(0.09, 0.09, 0.06),
		CFrame.new(-0.55, 0.0, 0.29),
		shade(grain, -0.4),
		Wood
	)
end

builders.WovenBasket = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.25)
	-- The base, then the walls as rings of weave that flare out, light and dark in turn.
	piece(root, "Base", Cylinder, Vector3.new(0.1, 1.0, 1.0), CFrame.new(0, -0.45, 0) * ALONG_Y, dark, Wood)
	for i = 0, 5 do
		local radius = 0.5 + 0.1 * i / 5
		piece(
			root,
			"Weave",
			Cylinder,
			Vector3.new(0.11, radius * 2, radius * 2),
			CFrame.new(0, -0.4 + i * 0.1, 0) * ALONG_Y,
			if i % 2 == 0 then color else shade(color, 0.15),
			Fabric
		)
	end
	-- The upright ribs that the weave goes over.
	for i = 0, 9 do
		local a = i / 10 * 2 * math.pi
		local r = 0.585
		piece(
			root,
			"Rib",
			Block,
			Vector3.new(0.05, 0.62, 0.09),
			CFrame.new(r * math.cos(a), -0.12, r * math.sin(a)) * CFrame.Angles(0, -a, 0),
			dark,
			Wood
		)
	end
	-- A thick rim round the opening, with the dark inside.
	piece(
		root,
		"Inside",
		Cylinder,
		Vector3.new(0.05, 1.08, 1.08),
		CFrame.new(0, 0.12, 0) * ALONG_Y,
		M.Hole,
		Smooth
	)
	for i = 0, 11 do
		local a = i / 12 * 2 * math.pi
		piece(
			root,
			"Rim",
			Block,
			Vector3.new(0.14, 0.12, 0.34),
			CFrame.new(0.58 * math.cos(a), 0.15, 0.58 * math.sin(a)) * CFrame.Angles(0, -a, 0),
			dark,
			Wood
		)
	end
	-- A bow handle over the top, and the corner of a cloth peeking out.
	arc(root, "Handle", Vector2.new(0, -0.1), 0.58, 0, 180, 0.09, dark, Wood)
	piece(
		root,
		"Cloth",
		Block,
		Vector3.new(0.4, 0.07, 0.35),
		CFrame.new(0.15, 0.17, 0.1) * CFrame.Angles(0.15, 0.4, 0.1),
		M.Wax,
		Fabric
	)
end

builders.CarvedFloat = function(root, def)
	local color = def.Color
	local light = shade(color, 0.25)
	local dark = shade(color, -0.3)
	-- A turned wooden float lying along X, painted in bands, with a rope through its ends.
	piece(root, "Body", Ball, Vector3.new(1.0, 0.62, 0.62), CFrame.new(), color, Wood)
	for _, x in { -0.5, 0.5 } do
		piece(root, "Cap", Cylinder, Vector3.new(0.14, 0.3, 0.3), CFrame.new(x * 0.98, 0, 0), dark, Wood)
	end
	for _, x in { -0.27, 0.27 } do
		piece(root, "Band", Cylinder, Vector3.new(0.1, 0.6, 0.6), CFrame.new(x, 0, 0), M.Wax, Smooth)
		piece(
			root,
			"Pinstripe",
			Cylinder,
			Vector3.new(0.04, 0.61, 0.61),
			CFrame.new(x * 1.45, 0, 0),
			M.White,
			Smooth
		)
	end
	-- Carved waves round the middle.
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi
		piece(
			root,
			"Wave",
			Ball,
			Vector3.new(0.12, 0.06, 0.1),
			CFrame.new(0, 0.3 * math.cos(a), 0.3 * math.sin(a)) * CFrame.Angles(a, 0, 0),
			light,
			Wood
		)
	end
	-- The rope: a loop out of each end and a lashing round the middle.
	piece(root, "Lashing", Cylinder, Vector3.new(0.1, 0.65, 0.65), CFrame.new(0, 0, 0), M.Cork, Fabric)
	arc(root, "Loop", Vector2.new(-0.62, 0), 0.1, -90, 90, 0.05, M.Cork, Fabric)
	arc(root, "Loop", Vector2.new(0.62, 0), 0.1, 90, 270, 0.05, M.Cork, Fabric)
	piece(root, "EndKnot", Ball, Vector3.new(0.1, 0.1, 0.1), CFrame.new(0.5, 0.06, 0.04), M.Cork, Fabric)
end

builders.DriftwoodTotem = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	local light = shade(color, 0.2)
	-- The pole on a foot, with carved bands between the three faces.
	piece(root, "Foot", Block, Vector3.new(0.85, 0.2, 0.85), CFrame.new(0, -1.1, 0), dark, Wood)
	piece(root, "Pole", Cylinder, Vector3.new(2.1, 0.7, 0.7), CFrame.new(0, 0.0, 0) * ALONG_Y, color, Wood)
	for _, y in { -0.45, 0.4 } do
		piece(root, "Band", Cylinder, Vector3.new(0.1, 0.8, 0.8), CFrame.new(0, y, 0) * ALONG_Y, dark, Wood)
	end
	-- Bottom: a bear with round ears, a snout and a red mouth.
	for _, x in { -0.25, 0.25 } do
		piece(root, "BearEar", Ball, Vector3.new(0.2, 0.2, 0.16), CFrame.new(x, -0.55, 0.2), color, Wood)
		piece(
			root,
			"BearEye",
			Ball,
			Vector3.new(0.12, 0.12, 0.08),
			CFrame.new(x * 0.7, -0.78, 0.35),
			M.Hole,
			Smooth
		)
		piece(
			root,
			"BearPaw",
			Ball,
			Vector3.new(0.2, 0.16, 0.18),
			CFrame.new(x * 1.1, -1.0, 0.3),
			light,
			Wood
		)
	end
	piece(root, "Snout", Block, Vector3.new(0.3, 0.2, 0.2), CFrame.new(0, -0.9, 0.4), light, Wood)
	piece(root, "BearNose", Block, Vector3.new(0.14, 0.08, 0.06), CFrame.new(0, -0.82, 0.48), M.Hole, Smooth)
	piece(root, "BearMouth", Block, Vector3.new(0.26, 0.05, 0.04), CFrame.new(0, -0.97, 0.48), M.Wax, Smooth)
	-- Middle: an eagle with a hooked beak and wings folded to the sides.
	for _, x in { -1, 1 } do
		piece(root, "Wing", Block, Vector3.new(0.1, 0.55, 0.4), CFrame.new(x * 0.4, -0.03, 0.0), dark, Wood)
		piece(
			root,
			"WingFeather",
			Block,
			Vector3.new(0.1, 0.18, 0.34),
			CFrame.new(x * 0.42, -0.34, -0.02),
			M.Aqua,
			Wood
		)
		piece(
			root,
			"Eye",
			Ball,
			Vector3.new(0.14, 0.14, 0.08),
			CFrame.new(x * 0.14, 0.1, 0.34),
			M.Sun,
			Smooth
		)
		piece(
			root,
			"Pupil",
			Ball,
			Vector3.new(0.06, 0.06, 0.04),
			CFrame.new(x * 0.14, 0.1, 0.38),
			M.Hole,
			Smooth
		)
	end
	piece(root, "Beak", Block, Vector3.new(0.16, 0.3, 0.2), CFrame.new(0, -0.06, 0.4), M.Sun, Wood)
	piece(
		root,
		"BeakHook",
		Block,
		Vector3.new(0.12, 0.12, 0.14),
		CFrame.new(0, -0.22, 0.38),
		shade(M.Sun, -0.2),
		Wood
	)
	-- Top: a round face with horns, a red mouth, and a cap.
	for _, x in { -1, 1 } do
		piece(
			root,
			"Horn",
			Block,
			Vector3.new(0.12, 0.3, 0.12),
			CFrame.new(x * 0.3, 1.0, 0.0) * CFrame.Angles(0, 0, -x * 0.35),
			light,
			Wood
		)
		piece(
			root,
			"FaceEye",
			Cylinder,
			Vector3.new(0.06, 0.18, 0.18),
			CFrame.new(x * 0.17, 0.78, 0.35) * CFrame.Angles(0, math.pi / 2, 0),
			M.White,
			Smooth
		)
		piece(
			root,
			"FacePupil",
			Ball,
			Vector3.new(0.08, 0.08, 0.05),
			CFrame.new(x * 0.17, 0.78, 0.39),
			M.Hole,
			Smooth
		)
	end
	piece(root, "FaceNose", Block, Vector3.new(0.1, 0.2, 0.1), CFrame.new(0, 0.62, 0.4), light, Wood)
	piece(root, "FaceMouth", Block, Vector3.new(0.34, 0.09, 0.05), CFrame.new(0, 0.44, 0.36), M.Wax, Smooth)
	piece(root, "Cap", Cylinder, Vector3.new(0.14, 0.8, 0.8), CFrame.new(0, 1.12, 0) * ALONG_Y, dark, Wood)
	piece(root, "CapKnob", Ball, Vector3.new(0.24, 0.2, 0.24), CFrame.new(0, 1.2, 0), color, Wood)
end

builders.AncientFigurehead = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	local light = shade(color, 0.2)
	-- The beam it was fixed to, and the mounting plate behind.
	piece(root, "Beam", Block, Vector3.new(0.5, 0.42, 1.6), CFrame.new(0, -1.05, 0), dark, WoodPlanks)
	piece(
		root,
		"Plate",
		Block,
		Vector3.new(0.9, 0.7, 0.26),
		CFrame.new(0, -0.88, -0.7),
		shade(color, -0.45),
		WoodPlanks
	)
	for _, x in { -0.3, 0.3 } do
		piece(root, "Bolt", Ball, Vector3.new(0.12, 0.12, 0.12), CFrame.new(x, -0.7, -0.57), M.Iron, Metal)
	end
	-- Carved waves she rises from.
	for i = -2, 2 do
		piece(
			root,
			"Wave",
			Ball,
			Vector3.new(0.3, 0.25, 0.4),
			CFrame.new(i * 0.2, -0.7, 0.45 + (i % 2) * 0.08),
			light,
			Wood
		)
	end
	-- The body: a tapering skirt, a bust leaning forward, and the neck.
	piece(
		root,
		"Skirt",
		Cylinder,
		Vector3.new(0.5, 0.75, 0.75),
		CFrame.new(0, -0.5, 0.15) * ALONG_Y,
		color,
		Wood
	)
	piece(
		root,
		"Waist",
		Cylinder,
		Vector3.new(0.4, 0.6, 0.6),
		CFrame.new(0, -0.1, 0.2) * ALONG_Y,
		color,
		Wood
	)
	piece(root, "Bust", Ball, Vector3.new(0.88, 0.7, 0.7), CFrame.new(0, 0.28, 0.25), color, Wood)
	for _, x in { -0.17, 0.17 } do
		piece(root, "Chest", Ball, Vector3.new(0.32, 0.32, 0.3), CFrame.new(x, 0.18, 0.55), light, Wood)
	end
	piece(
		root,
		"Neck",
		Cylinder,
		Vector3.new(0.3, 0.26, 0.26),
		CFrame.new(0, 0.62, 0.3) * ALONG_Y,
		color,
		Wood
	)
	piece(root, "Collar", Block, Vector3.new(0.62, 0.08, 0.2), CFrame.new(0, 0.52, 0.55), M.Gold, Metal)
	-- Arms folded across the front, hands meeting at the chest.
	for _, x in { -1, 1 } do
		bar(root, "Arm", Vector3.new(x * 0.5, 0.4, 0.2), Vector3.new(x * 0.4, -0.05, 0.5), 0.17, color, Wood)
		bar(
			root,
			"Forearm",
			Vector3.new(x * 0.4, -0.05, 0.5),
			Vector3.new(x * 0.1, -0.05, 0.68),
			0.15,
			color,
			Wood
		)
	end
	-- The head: face, eyes, nose, lips.
	piece(root, "Head", Ball, Vector3.new(0.55, 0.65, 0.55), CFrame.new(0, 0.95, 0.32), light, Wood)
	for _, x in { -0.11, 0.11 } do
		piece(root, "Eye", Ball, Vector3.new(0.1, 0.07, 0.06), CFrame.new(x, 1.02, 0.58), M.Hole, Smooth)
		piece(root, "Brow", Block, Vector3.new(0.14, 0.03, 0.05), CFrame.new(x, 1.1, 0.58), dark, Wood)
	end
	piece(root, "Nose", Block, Vector3.new(0.08, 0.16, 0.1), CFrame.new(0, 0.93, 0.6), light, Wood)
	piece(root, "Lips", Block, Vector3.new(0.17, 0.05, 0.05), CFrame.new(0, 0.8, 0.58), M.Wax, Smooth)
	-- Long hair streaming back over the shoulders, and a gold crown.
	for _, x in { -1, 1 } do
		bar(root, "Hair", Vector3.new(x * 0.28, 1.1, 0.25), Vector3.new(x * 0.34, 0.5, -0.4), 0.2, dark, Wood)
		bar(
			root,
			"HairLock",
			Vector3.new(x * 0.34, 0.5, -0.4),
			Vector3.new(x * 0.28, -0.25, -0.62),
			0.16,
			dark,
			Wood
		)
	end
	piece(root, "HairTop", Ball, Vector3.new(0.6, 0.32, 0.6), CFrame.new(0, 1.18, 0.15), dark, Wood)
	piece(root, "Crown", Block, Vector3.new(0.5, 0.1, 0.4), CFrame.new(0, 1.26, 0.32), M.Gold, Metal)
	for _, x in { -0.18, 0, 0.18 } do
		piece(
			root,
			"CrownPoint",
			Block,
			Vector3.new(0.07, 0.14, 0.07),
			CFrame.new(x, 1.36, 0.45),
			M.Gold,
			Metal
		)
	end
	piece(root, "Gem", Ball, Vector3.new(0.1, 0.1, 0.08), CFrame.new(0, 1.3, 0.55), M.Aqua, Glass)
	-- Moss and barnacles from the years in the water.
	piece(root, "Moss", Ball, Vector3.new(0.4, 0.2, 0.3), CFrame.new(0.15, -0.35, 0.6), M.Moss, Rock)
	piece(root, "Moss", Ball, Vector3.new(0.3, 0.16, 0.26), CFrame.new(-0.25, 0.7, -0.1), M.Moss, Rock)
	for _, p in
		{ Vector3.new(0.35, -0.95, 0.35), Vector3.new(-0.2, -0.9, 0.62), Vector3.new(0.3, 0.45, 0.45) }
	do
		piece(root, "Barnacle", Ball, Vector3.new(0.14, 0.12, 0.14), CFrame.new(p), M.Barnacle, Rock)
	end
end

return builders
