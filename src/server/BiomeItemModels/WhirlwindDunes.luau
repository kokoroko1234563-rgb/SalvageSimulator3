-- Whirlwind Dunes item models (docs/design/biome-items.md). Each builder adds welded,
-- massless parts to the item's root in its own frame; see ItemModels.luau.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local ModelParts = require(script.Parent.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder
local Wedge = Enum.PartType.Wedge

local Glass = Palette.Material.Glass
local Metal = Palette.Material.Metal
local Smooth = Palette.Material.Smooth
local Foil = Palette.Material.Foil
local Rock = Palette.Material.Rock
local Sand = Palette.Material.Sand
local Neon = Palette.Material.Neon

local M = Palette.ItemModel
local ALONG_Y = ModelParts.ALONG_Y
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

-- A thin pane of glass fused by lightning from the sand, with a crust of sand on one edge.
builders.SandGlassShard = function(root, def)
	local color = def.Color
	piece(
		root,
		"Pane",
		Block,
		Vector3.new(0.8, 0.07, 0.55),
		CFrame.new(-0.05, 0, 0) * CFrame.Angles(0, math.rad(12), 0),
		color,
		Glass,
		0.3
	)
	piece(
		root,
		"Layer",
		Block,
		Vector3.new(0.55, 0.06, 0.5),
		CFrame.new(0.2, 0.07, 0.1) * CFrame.Angles(0, math.rad(-25), math.rad(4)),
		shade(color, 0.2),
		Glass,
		0.4
	)
	piece(
		root,
		"Chip",
		Wedge,
		Vector3.new(0.3, 0.07, 0.35),
		CFrame.new(0.36, 0, -0.25) * CFrame.Angles(0, math.rad(190), 0),
		color,
		Glass,
		0.3
	)
	piece(
		root,
		"Point",
		Wedge,
		Vector3.new(0.4, 0.07, 0.3),
		CFrame.new(-0.38, 0.01, 0.2) * CFrame.Angles(0, math.rad(95), 0),
		shade(color, -0.1),
		Glass,
		0.3
	)
	piece(root, "Crust", Block, Vector3.new(0.7, 0.14, 0.14), CFrame.new(-0.1, -0.05, -0.28), M.Cork, Sand)
	for index, x in { -0.3, -0.05, 0.2 } do
		piece(
			root,
			"Grain",
			Ball,
			Vector3.new(0.12, 0.1, 0.12),
			CFrame.new(x, -0.06, -0.3 + index * 0.04),
			shade(M.Cork, 0.2),
			Sand
		)
	end
	-- A bright streak where the lightning ran through.
	bar(root, "Streak", Vector3.new(-0.3, 0.06, 0.2), Vector3.new(0.35, 0.06, -0.1), 0.03, M.White, Glass)
end

-- A branching tube of fused sand, grey and gritty, hollow at the top.
builders.Fulgurite = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.25)
	local points = {
		Vector3.new(0.03, -0.85, 0),
		Vector3.new(-0.04, -0.5, 0.02),
		Vector3.new(0.05, -0.05, -0.03),
		Vector3.new(-0.03, 0.4, 0.03),
		Vector3.new(0.02, 0.85, 0),
	}
	for index, point in points do
		local width = 0.5 - (index - 1) * 0.07
		piece(
			root,
			"Tube",
			Cylinder,
			Vector3.new(0.5, width, width),
			CFrame.new(point) * ALONG_Y,
			if index % 2 == 0 then color else dark,
			Rock
		)
		piece(
			root,
			"Knob",
			Ball,
			Vector3.new(width * 1.05, 0.2, width * 1.05),
			CFrame.new(point + Vector3.new(0, 0.15, 0)),
			color,
			Rock
		)
	end
	piece(
		root,
		"Mouth",
		Cylinder,
		Vector3.new(0.06, 0.2, 0.2),
		CFrame.new(0.02, 1.0, 0) * ALONG_Y,
		M.Hole,
		Smooth
	)
	-- Side branches reaching out and a crust of sand at the foot.
	bar(root, "BranchA", Vector3.new(0.05, -0.1, 0), Vector3.new(0.27, 0.15, 0.1), 0.12, color, Rock)
	bar(root, "BranchB", Vector3.new(-0.03, 0.25, 0), Vector3.new(-0.26, 0.5, -0.08), 0.1, dark, Rock)
	bar(root, "BranchC", Vector3.new(-0.04, -0.55, 0), Vector3.new(-0.25, -0.75, 0.1), 0.1, color, Rock)
	bar(root, "BranchD", Vector3.new(0.05, -0.35, 0.0), Vector3.new(0.1, -0.15, 0.25), 0.1, dark, Rock)
	piece(
		root,
		"SandFoot",
		Cylinder,
		Vector3.new(0.14, 0.58, 0.58),
		CFrame.new(0, -0.92, 0) * ALONG_Y,
		M.Cork,
		Sand
	)
	for _, spot in
		{ Vector3.new(0.12, 0.45, 0.14), Vector3.new(-0.15, -0.3, 0.12), Vector3.new(0.14, 0.7, -0.1) }
	do
		piece(root, "Grit", Ball, Vector3.new(0.12, 0.12, 0.12), CFrame.new(spot), shade(color, 0.25), Rock)
	end
end

-- A desert rose: gypsum plates fanned out from the middle in rings, stuck with sand.
builders.DesertRose = function(root, def)
	local color = def.Color
	local ring = {
		{ 7, 0.34, -0.08, 0.5, 0.42, 20 },
		{ 6, 0.32, 0.08, 0.46, 0.38, 25 },
		{ 5, 0.22, 0.22, 0.38, 0.3, 15 },
	}
	for ringIndex, spec in ring do
		local count, radius, y, long, tall, twist = spec[1], spec[2], spec[3], spec[4], spec[5], spec[6]
		for index = 0, count - 1 do
			local angle = index / count * 2 * math.pi + ringIndex * 0.4
			piece(
				root,
				"Petal",
				Block,
				Vector3.new(long, tall, 0.07),
				CFrame.Angles(0, -angle, 0)
					* CFrame.new(radius, y, 0)
					* CFrame.Angles(
						math.rad(twist * (if index % 2 == 0 then 1 else -1)),
						math.rad(8),
						math.rad(18 - ringIndex * 6)
					),
				if (index + ringIndex) % 2 == 0 then color else shade(color, 0.2),
				Sand
			)
		end
	end
	piece(root, "Heart", Ball, Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 0.1, 0), shade(color, -0.15), Sand)
	piece(
		root,
		"Base",
		Cylinder,
		Vector3.new(0.14, 0.7, 0.7),
		CFrame.new(0, -0.43, 0) * ALONG_Y,
		shade(color, -0.25),
		Sand
	)
	for index = 0, 5 do
		local angle = index * 1.1
		piece(
			root,
			"Grain",
			Ball,
			Vector3.new(0.09, 0.09, 0.09),
			CFrame.new(math.cos(angle) * 0.5, -0.25 + (index % 3) * 0.2, math.sin(angle) * 0.5),
			M.Cork,
			Sand
		)
	end
end

-- A small sandstone idol of a storm spirit, gold flecked, worn smooth by the wind.
-- The idol is drawn 2.8 studs tall and squeezed down to fit its body.
local SQUEEZE = 0.74
local function tall(
	root: BasePart,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	at: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	local p = at.Position
	local squeezed = CFrame.new(p.X, p.Y * SQUEEZE - 0.02, p.Z) * (at - p)
	piece(
		root,
		name,
		shape,
		Vector3.new(size.X, size.Y * SQUEEZE, size.Z),
		squeezed,
		color,
		material,
		transparency
	)
end
local function tallBar(
	root: BasePart,
	name: string,
	from: Vector3,
	to: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material?
)
	bar(
		root,
		name,
		Vector3.new(from.X, from.Y * SQUEEZE, from.Z),
		Vector3.new(to.X, to.Y * SQUEEZE, to.Z),
		thickness,
		color,
		material
	)
end

builders.StormIdol = function(root, def)
	local color = def.Color
	local stone = shade(color, -0.12)
	local dark = shade(color, -0.4)
	-- Plinth, legs and body.
	tall(root, "Plinth", Block, Vector3.new(0.95, 0.3, 0.95), CFrame.new(0, -0.95, 0), dark, Rock)
	tall(root, "Foot", Block, Vector3.new(0.75, 0.12, 0.75), CFrame.new(0, -0.74, 0), stone, Rock)
	tall(root, "Legs", Block, Vector3.new(0.6, 0.55, 0.45), CFrame.new(0, -0.4, 0), stone, Rock)
	tall(root, "Belt", Block, Vector3.new(0.7, 0.14, 0.5), CFrame.new(0, -0.08, 0), M.Gold, Foil)
	tall(root, "Torso", Block, Vector3.new(0.72, 0.7, 0.5), CFrame.new(0, 0.3, 0), color, Rock)
	tall(root, "Chest", Ball, Vector3.new(0.22, 0.22, 0.12), CFrame.new(0, 0.38, 0.27), M.Gold, Foil)
	-- Arms raised: one up, one clutching the chest.
	tall(root, "ShoulderL", Block, Vector3.new(0.22, 0.2, 0.3), CFrame.new(-0.46, 0.55, 0), stone, Rock)
	tall(root, "ShoulderR", Block, Vector3.new(0.22, 0.2, 0.3), CFrame.new(0.46, 0.55, 0), stone, Rock)
	tallBar(root, "ArmL", Vector3.new(-0.46, 0.5, 0), Vector3.new(-0.47, 0.05, 0.12), 0.16, color, Rock)
	tallBar(root, "ArmR", Vector3.new(0.46, 0.5, 0), Vector3.new(0.47, 0.9, 0.0), 0.16, color, Rock)
	tall(root, "Fist", Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0.47, 0.98, 0), stone, Rock)
	-- Head, face and headdress.
	tall(root, "Neck", Block, Vector3.new(0.3, 0.12, 0.3), CFrame.new(0, 0.7, 0), dark, Rock)
	tall(root, "Head", Block, Vector3.new(0.6, 0.5, 0.55), CFrame.new(0, 0.98, 0), color, Rock)
	for _, x in { -0.14, 0.14 } do
		tall(root, "Eye", Block, Vector3.new(0.12, 0.08, 0.05), CFrame.new(x, 1.02, 0.28), M.Sun, Neon)
	end
	tall(root, "Nose", Block, Vector3.new(0.1, 0.18, 0.1), CFrame.new(0, 0.94, 0.3), stone, Rock)
	tall(root, "Mouth", Block, Vector3.new(0.3, 0.05, 0.05), CFrame.new(0, 0.82, 0.28), dark, Rock)
	tall(root, "Crown", Block, Vector3.new(0.66, 0.1, 0.6), CFrame.new(0, 1.26, 0), M.Gold, Foil)
	for index = -2, 2 do
		tall(
			root,
			"Plume",
			Wedge,
			Vector3.new(0.1, 0.34 - math.abs(index) * 0.05, 0.1),
			CFrame.new(index * 0.13, 1.5 - math.abs(index) * 0.03, 0),
			if index % 2 == 0 then M.Gold else color,
			Foil
		)
	end
	-- Sand drifted against the plinth and a crack down the torso.
	tall(
		root,
		"Drift",
		Wedge,
		Vector3.new(0.5, 0.2, 0.4),
		CFrame.new(0.3, -1.05, 0.36) * CFrame.Angles(0, math.rad(180), 0),
		M.Cork,
		Sand
	)
	tallBar(root, "Crack", Vector3.new(-0.1, 0.6, 0.26), Vector3.new(0.05, 0.1, 0.26), 0.03, dark, Smooth)
end

return builders
