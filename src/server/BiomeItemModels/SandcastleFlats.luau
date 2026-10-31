-- Models for the Sandcastle Flats items (docs/design/biome-items.md). Each builder works in
-- the root's own frame, like the ones in ItemModels.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local ModelParts = require(script.Parent.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder

local Metal = Palette.Material.Metal
local Smooth = Palette.Material.Smooth
local Sand = Palette.Material.Sand
local Fabric = Palette.Material.Fabric
local Wood = Palette.Material.Wood
local Glass = Palette.Material.Glass
local M = Palette.ItemModel

local ALONG_Y = ModelParts.ALONG_Y
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

-- A ring of blocks standing on edge around the Y axis.
local function ring(
	root: BasePart,
	name: string,
	radius: number,
	y: number,
	height: number,
	thickness: number,
	count: number,
	color: Color3,
	material: Enum.Material?
)
	local length = 2 * radius * math.tan(math.pi / count) * 1.06 + 0.02
	for i = 0, count - 1 do
		local a = i / count * 2 * math.pi
		piece(
			root,
			name,
			Block,
			Vector3.new(thickness, height, length),
			CFrame.new(radius * math.cos(a), y, radius * math.sin(a)) * CFrame.Angles(0, -a, 0),
			color,
			material
		)
	end
end

local builders = {}

builders.SandDollar = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.35)
	piece(root, "Disc", Cylinder, Vector3.new(0.15, 1.2, 1.2), ALONG_Y, color, Smooth)
	piece(root, "Rim", Cylinder, Vector3.new(0.1, 1.2, 1.2), ALONG_Y, shade(color, -0.1), Sand)
	-- The five-petal flower on top.
	for i = 0, 4 do
		local a = i / 5 * 2 * math.pi
		local petal = CFrame.new(0.27 * math.cos(a), 0.065, 0.27 * math.sin(a)) * CFrame.Angles(0, -a, 0)
		piece(root, "Petal", Block, Vector3.new(0.4, 0.03, 0.12), petal, dark, Smooth)
		piece(
			root,
			"PetalTip",
			Ball,
			Vector3.new(0.13, 0.03, 0.13),
			petal * CFrame.new(0.2, 0, 0),
			dark,
			Smooth
		)
		-- The slots between the petals.
		local b = a + math.pi / 5
		piece(
			root,
			"Slot",
			Block,
			Vector3.new(0.14, 0.03, 0.05),
			CFrame.new(0.45 * math.cos(b), 0.065, 0.45 * math.sin(b)) * CFrame.Angles(0, -b, 0),
			M.Hole,
			Smooth
		)
	end
	piece(
		root,
		"Centre",
		Ball,
		Vector3.new(0.12, 0.04, 0.12),
		CFrame.new(0, 0.065, 0),
		shade(dark, -0.2),
		Smooth
	)
end

builders.ToySpade = function(root, def)
	local color = def.Color
	local light = shade(color, 0.25)
	local dark = shade(color, -0.25)
	-- The D-shaped grip at the far end.
	bar(root, "GripLeft", Vector3.new(-0.22, 0, -0.98), Vector3.new(-0.22, 0, -0.62), 0.1, color, Smooth)
	bar(root, "GripRight", Vector3.new(0.22, 0, -0.98), Vector3.new(0.22, 0, -0.62), 0.1, color, Smooth)
	bar(root, "GripEnd", Vector3.new(-0.27, 0, -0.98), Vector3.new(0.27, 0, -0.98), 0.1, color, Smooth)
	-- The shaft, with a collar where it meets the blade.
	bar(root, "Shaft", Vector3.new(0, 0, -0.65), Vector3.new(0, 0, 0.25), 0.15, light, Smooth)
	piece(root, "Collar", Block, Vector3.new(0.24, 0.2, 0.14), CFrame.new(0, 0, 0.2), dark, Smooth)
	-- The blade: a flat scoop with a rim along its sides and a round tip.
	piece(root, "Blade", Block, Vector3.new(0.5, 0.05, 0.55), CFrame.new(0, -0.04, 0.55), color, Smooth)
	piece(
		root,
		"Tip",
		Cylinder,
		Vector3.new(0.05, 0.5, 0.5),
		CFrame.new(0, -0.04, 0.82) * ALONG_Y,
		color,
		Smooth
	)
	for _, x in { -0.24, 0.24 } do
		piece(root, "Flange", Block, Vector3.new(0.05, 0.2, 0.55), CFrame.new(x, 0.04, 0.55), light, Smooth)
	end
	piece(root, "Rib", Block, Vector3.new(0.08, 0.1, 0.5), CFrame.new(0, 0.03, 0.55), dark, Smooth)
	-- A little sand still on it.
	piece(
		root,
		"Sand",
		Ball,
		Vector3.new(0.3, 0.12, 0.3),
		CFrame.new(0.05, 0.02, 0.85),
		M.Cork:Lerp(M.Paper, 0.5),
		Sand
	)
end

builders.CastleFlag = function(root, def)
	local color = def.Color
	local poleZ = -0.3
	-- A small mound of sand holds the pole.
	piece(
		root,
		"Mound",
		Ball,
		Vector3.new(0.32, 0.3, 0.7),
		CFrame.new(0, -0.98, 0),
		M.Paper:Lerp(M.Cork, 0.4),
		Sand
	)
	piece(
		root,
		"Pole",
		Cylinder,
		Vector3.new(2.0, 0.07, 0.07),
		CFrame.new(0, 0, poleZ) * ALONG_Y,
		M.Paper,
		Wood
	)
	piece(root, "Finial", Ball, Vector3.new(0.15, 0.15, 0.15), CFrame.new(0, 1.05, poleZ), M.Gold, Metal)
	-- The cloth, swallow-tailed, with a stripe and a round emblem.
	piece(root, "Cloth", Block, Vector3.new(0.03, 0.55, 0.52), CFrame.new(0, 0.6, poleZ + 0.3), color, Fabric)
	piece(
		root,
		"TailTop",
		Block,
		Vector3.new(0.03, 0.17, 0.12),
		CFrame.new(0, 0.79, poleZ + 0.62),
		color,
		Fabric
	)
	piece(
		root,
		"TailBottom",
		Block,
		Vector3.new(0.03, 0.17, 0.12),
		CFrame.new(0, 0.41, poleZ + 0.62),
		color,
		Fabric
	)
	piece(
		root,
		"Stripe",
		Block,
		Vector3.new(0.035, 0.09, 0.52),
		CFrame.new(0, 0.46, poleZ + 0.3),
		M.Wax,
		Fabric
	)
	piece(
		root,
		"Emblem",
		Cylinder,
		Vector3.new(0.04, 0.2, 0.2),
		CFrame.new(0, 0.68, poleZ + 0.25),
		M.Wax,
		Fabric
	)
	piece(
		root,
		"EmblemDot",
		Cylinder,
		Vector3.new(0.045, 0.09, 0.09),
		CFrame.new(0, 0.68, poleZ + 0.25),
		M.White,
		Fabric
	)
	-- The pole's rope ties.
	for _, y in { 0.82, 0.38 } do
		piece(
			root,
			"Tie",
			Cylinder,
			Vector3.new(0.05, 0.1, 0.1),
			CFrame.new(0, y, poleZ) * ALONG_Y,
			M.Cork,
			Fabric
		)
	end
end

builders.GildedTurret = function(root, def)
	local color = def.Color
	local sand = M.Paper:Lerp(M.Cork, 0.35)
	local dark = shade(color, -0.3)
	-- Sand base, then the tower with gold bands.
	piece(root, "Plinth", Block, Vector3.new(1.3, 0.3, 1.3), CFrame.new(0, -0.85, 0), sand, Sand)
	piece(root, "Foot", Block, Vector3.new(1.1, 0.12, 1.1), CFrame.new(0, -0.64, 0), color, Metal)
	piece(
		root,
		"Tower",
		Cylinder,
		Vector3.new(1.1, 0.95, 0.95),
		CFrame.new(0, -0.03, 0) * ALONG_Y,
		sand,
		Sand
	)
	for _, y in { -0.5, 0.2 } do
		piece(root, "Band", Cylinder, Vector3.new(0.1, 1.0, 1.0), CFrame.new(0, y, 0) * ALONG_Y, color, Metal)
	end
	-- Slit windows round the tower, and the arched door in front.
	for i = 0, 3 do
		local a = i / 4 * 2 * math.pi + math.pi / 4
		piece(
			root,
			"Slit",
			Block,
			Vector3.new(0.05, 0.28, 0.08),
			CFrame.new(0.48 * math.cos(a), 0.0, 0.48 * math.sin(a)) * CFrame.Angles(0, -a, 0),
			M.Hole,
			Smooth
		)
	end
	piece(root, "Door", Block, Vector3.new(0.3, 0.3, 0.06), CFrame.new(0, -0.45, 0.48), M.Hole, Smooth)
	piece(
		root,
		"DoorArch",
		Cylinder,
		Vector3.new(0.06, 0.3, 0.3),
		CFrame.new(0, -0.3, 0.48) * CFrame.Angles(0, math.pi / 2, 0),
		M.Hole,
		Smooth
	)
	piece(root, "DoorTrim", Block, Vector3.new(0.4, 0.06, 0.05), CFrame.new(0, -0.14, 0.49), color, Metal)
	-- The gilded battlement: a flared ring, then the merlons.
	piece(
		root,
		"Corbel",
		Cylinder,
		Vector3.new(0.14, 1.25, 1.25),
		CFrame.new(0, 0.5, 0) * ALONG_Y,
		color,
		Metal
	)
	for i = 0, 7 do
		local a = i / 8 * 2 * math.pi
		piece(
			root,
			"Merlon",
			Block,
			Vector3.new(0.2, 0.26, 0.24),
			CFrame.new(0.52 * math.cos(a), 0.7, 0.52 * math.sin(a)) * CFrame.Angles(0, -a, 0),
			color,
			Metal
		)
	end
	-- The little gilded cap in the middle.
	piece(root, "Cap", Cylinder, Vector3.new(0.3, 0.7, 0.7), CFrame.new(0, 0.7, 0) * ALONG_Y, dark, Metal)
	piece(
		root,
		"CapTop",
		Cylinder,
		Vector3.new(0.2, 0.45, 0.45),
		CFrame.new(0, 0.9, 0) * ALONG_Y,
		color,
		Metal
	)
	piece(root, "Tip", Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 1.05, 0), M.Gold, Metal)
end

builders.SandKingsCrown = function(root, def)
	local color = def.Color
	local radius = 0.7
	-- The band, with a rim above and below.
	ring(root, "Band", radius, -0.3, 0.3, 0.12, 10, color, Metal)
	ring(root, "RimTop", radius, -0.14, 0.07, 0.18, 10, shade(color, 0.2), Metal)
	ring(root, "RimBottom", radius, -0.44, 0.07, 0.18, 10, shade(color, 0.2), Metal)
	piece(
		root,
		"Lining",
		Cylinder,
		Vector3.new(0.22, 1.25, 1.25),
		CFrame.new(0, -0.3, 0) * ALONG_Y,
		M.Wax,
		Fabric
	)
	-- Tall and short points around the top, each tipped with a jewel.
	for i = 0, 7 do
		local a = i / 8 * 2 * math.pi
		local tall = i % 2 == 0
		local h = if tall then 0.38 else 0.24
		local at = CFrame.new(radius * math.cos(a), -0.12 + h / 2, radius * math.sin(a))
			* CFrame.Angles(0, -a, 0)
		piece(root, "Point", Block, Vector3.new(0.12, h, 0.26), at, color, Metal)
		piece(
			root,
			"PointTaper",
			Block,
			Vector3.new(0.1, 0.12, 0.14),
			at * CFrame.new(0, h / 2 + 0.05, 0),
			color,
			Metal
		)
		piece(
			root,
			"Jewel",
			Ball,
			Vector3.new(0.17, 0.17, 0.17),
			at * CFrame.new(0, h / 2 + 0.13, 0),
			if tall then M.Wax else M.Aqua,
			Glass
		)
	end
	-- Big stones set in the band, and sand-coloured studs between them.
	for i = 0, 3 do
		local a = i / 4 * 2 * math.pi + math.pi / 8
		piece(
			root,
			"Stone",
			Ball,
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new((radius + 0.06) * math.cos(a), -0.3, (radius + 0.06) * math.sin(a)),
			if i % 2 == 0 then M.Aqua else M.Wax,
			Glass
		)
		local b = a + math.pi / 4
		piece(
			root,
			"Stud",
			Ball,
			Vector3.new(0.1, 0.1, 0.1),
			CFrame.new((radius + 0.06) * math.cos(b), -0.3, (radius + 0.06) * math.sin(b)),
			M.Paper,
			Sand
		)
	end
end

return builders
