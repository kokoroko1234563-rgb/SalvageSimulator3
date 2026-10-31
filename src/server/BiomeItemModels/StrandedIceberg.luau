-- Stranded Iceberg item models (docs/design/biome-items.md). Each builder adds welded,
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
local Rust = Palette.Material.Rust
local WoodPlanks = Palette.Material.WoodPlanks
local Wood = Palette.Material.Wood

local M = Palette.ItemModel
local ALONG_Y = ModelParts.ALONG_Y
local ALONG_Z = ModelParts.ALONG_Z
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

-- A hanging icicle: a thin wedge pair pointing down.
local function icicle(
	root: BasePart,
	color: Color3,
	x: number,
	top: number,
	z: number,
	length: number,
	width: number
)
	piece(
		root,
		"Icicle",
		Wedge,
		Vector3.new(width, length, width),
		CFrame.new(x, top - length / 2, z) * CFrame.Angles(math.rad(180), 0, 0),
		color,
		Glass,
		0.25
	)
end

-- A lump of glacier ice: tilted translucent blocks round a bright core, with a cap of snow.
builders.IceChunk = function(root, def)
	local color = def.Color
	local deep = shade(color, -0.2)
	piece(
		root,
		"Core",
		Block,
		Vector3.new(0.9, 0.8, 0.8),
		CFrame.new(0, -0.1, 0) * CFrame.Angles(0, math.rad(20), math.rad(4)),
		deep,
		Glass,
		0.3
	)
	piece(
		root,
		"Big",
		Block,
		Vector3.new(1.2, 0.6, 1.0),
		CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(3), math.rad(-12), 0),
		color,
		Glass,
		0.4
	)
	piece(
		root,
		"Crystal",
		Block,
		Vector3.new(0.5, 0.7, 0.5),
		CFrame.new(-0.3, 0.25, 0.1) * CFrame.Angles(math.rad(10), math.rad(35), math.rad(-14)),
		shade(color, 0.15),
		Glass,
		0.35
	)
	piece(
		root,
		"Crystal2",
		Block,
		Vector3.new(0.4, 0.55, 0.4),
		CFrame.new(0.35, 0.15, -0.2) * CFrame.Angles(math.rad(-12), math.rad(-20), math.rad(16)),
		color,
		Glass,
		0.35
	)
	piece(
		root,
		"Spire",
		Wedge,
		Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(-0.3, 0.5, 0.1) * CFrame.Angles(0, math.rad(35), 0),
		M.White,
		Glass,
		0.3
	)
	piece(root, "Snow", Block, Vector3.new(0.7, 0.1, 0.6), CFrame.new(0.2, 0.0, 0.25), M.White, Smooth)
	piece(root, "Snow2", Ball, Vector3.new(0.3, 0.18, 0.3), CFrame.new(-0.45, -0.02, 0.35), M.White, Smooth)
	piece(
		root,
		"Foot",
		Block,
		Vector3.new(1.35, 0.2, 1.1),
		CFrame.new(0, -0.5, 0),
		shade(color, -0.1),
		Glass,
		0.2
	)
	-- Chips round the base and an icicle or two.
	for _, spot in
		{ Vector3.new(0.62, -0.5, 0.5), Vector3.new(-0.6, -0.5, -0.45), Vector3.new(0.5, -0.5, -0.5) }
	do
		piece(
			root,
			"Chip",
			Block,
			Vector3.new(0.22, 0.18, 0.22),
			CFrame.new(spot) * CFrame.Angles(0, math.rad(30), 0),
			color,
			Glass,
			0.3
		)
	end
	icicle(root, color, 0.55, -0.15, 0.3, 0.3, 0.1)
	icicle(root, color, -0.1, -0.2, 0.55, 0.25, 0.08)
	-- A glint where the light catches.
	piece(root, "Glint", Ball, Vector3.new(0.1, 0.1, 0.1), CFrame.new(-0.3, 0.45, 0.35), M.White, Smooth)
end

-- A crate of frozen herring: slatted wood, rimed with frost, and fish packed in on top.
builders.FrozenHerringCrate = function(root, def)
	local color = def.Color
	local wood = shade(M.Cork, -0.2)
	local frost = shade(color, 0.5)
	-- Corner posts and slatted sides.
	for _, x in { -0.74, 0.74 } do
		for _, z in { -0.54, 0.54 } do
			piece(root, "Post", Block, Vector3.new(0.14, 0.92, 0.14), CFrame.new(x, -0.04, z), wood, Wood)
		end
	end
	for _, y in { -0.35, -0.05, 0.25 } do
		for _, z in { -0.55, 0.55 } do
			piece(
				root,
				"SlatFront",
				Block,
				Vector3.new(1.5, 0.22, 0.08),
				CFrame.new(0, y, z),
				wood,
				WoodPlanks
			)
		end
		for _, x in { -0.75, 0.75 } do
			piece(
				root,
				"SlatSide",
				Block,
				Vector3.new(0.08, 0.22, 1.1),
				CFrame.new(x, y, 0),
				wood,
				WoodPlanks
			)
		end
	end
	piece(
		root,
		"Floor",
		Block,
		Vector3.new(1.45, 0.08, 1.05),
		CFrame.new(0, -0.45, 0),
		shade(wood, -0.2),
		WoodPlanks
	)
	piece(root, "Ice", Block, Vector3.new(1.4, 0.2, 1.0), CFrame.new(0, 0.28, 0), frost, Glass, 0.3)
	-- Herring in two rows, lying across the crate, with tails sticking out one side.
	for row = 0, 2 do
		local z = -0.34 + row * 0.34
		piece(
			root,
			"Fish",
			Cylinder,
			Vector3.new(1.2, 0.26, 0.28),
			CFrame.new(-0.05, 0.4, z),
			shade(M.Fish, 0.1 * (row % 2)),
			Foil
		)
		piece(root, "Belly", Cylinder, Vector3.new(1.0, 0.18, 0.2), CFrame.new(-0.05, 0.34, z), M.Label, Foil)
		piece(
			root,
			"Tail",
			Wedge,
			Vector3.new(0.08, 0.3, 0.2),
			CFrame.new(0.66, 0.4, z) * CFrame.Angles(0, 0, math.rad(90)),
			shade(M.Fish, -0.15),
			Smooth
		)
		piece(
			root,
			"Eye",
			Ball,
			Vector3.new(0.07, 0.07, 0.07),
			CFrame.new(-0.58, 0.46, z + 0.05),
			M.Hole,
			Smooth
		)
	end
	-- Frost on the rim and icicles under it.
	piece(root, "Rime", Block, Vector3.new(1.6, 0.06, 0.1), CFrame.new(0, 0.46, -0.55), M.White, Smooth)
	piece(root, "Rime2", Block, Vector3.new(1.6, 0.06, 0.1), CFrame.new(0, 0.46, 0.55), M.White, Smooth)
	for index = 0, 4 do
		icicle(root, frost, -0.6 + index * 0.3, 0.1, 0.6, 0.2 + (index % 2) * 0.12, 0.08)
	end
	-- A stencilled mark on the side.
	piece(root, "Stamp", Block, Vector3.new(0.4, 0.14, 0.02), CFrame.new(-0.2, -0.05, 0.6), M.Wax, Smooth)
end

-- A mammoth's tusk, lying along Z: a long ivory curve, ringed with growth lines, dark at the root.
builders.MammothTusk = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	-- The curve: a spine of points from the root (-Z) to the tip (+Z), rising toward the tip.
	local count = 9
	local points = {}
	local radii = {}
	for index = 0, count do
		local t = index / count
		table.insert(points, Vector3.new(0.06 * math.sin(t * math.pi), -0.03 + 0.3 * t ^ 2.2, -1.6 + 3.2 * t))
		table.insert(radii, 0.62 * (1 - t) ^ 0.85 + 0.04)
	end
	for index = 1, count do
		local from, to = points[index], points[index + 1]
		local width = (radii[index] + radii[index + 1]) / 2
		piece(
			root,
			"Segment",
			Cylinder,
			Vector3.new((to - from).Magnitude + 0.04, width, width),
			CFrame.lookAt((from + to) / 2, to) * ALONG_Z,
			if index <= 2 then shade(color, -0.12) else color,
			Smooth
		)
		piece(
			root,
			"Joint",
			Ball,
			Vector3.new(radii[index + 1], radii[index + 1], radii[index + 1]),
			CFrame.new(to),
			color,
			Smooth
		)
	end
	-- The root end: a darker, cracked cap with a hollow.
	piece(
		root,
		"RootCap",
		Cylinder,
		Vector3.new(0.14, 0.62, 0.62),
		CFrame.new(points[1]) * ALONG_Z,
		dark,
		Wood
	)
	piece(
		root,
		"RootHollow",
		Cylinder,
		Vector3.new(0.05, 0.36, 0.36),
		CFrame.new(points[1] + Vector3.new(0, 0, -0.07)) * ALONG_Z,
		M.Hole,
		Smooth
	)
	-- Growth rings (thin bands) round the shaft.
	for _, index in { 3, 5, 7 } do
		local from, to = points[index], points[index + 1]
		local width = (radii[index] + radii[index + 1]) / 2 + 0.03
		piece(
			root,
			"Ring",
			Cylinder,
			Vector3.new(0.04, width, width),
			CFrame.lookAt(from:Lerp(to, 0.5), to) * ALONG_Z,
			shade(color, -0.2),
			Smooth
		)
	end
	-- Stains, a crack and a dusting of frost.
	bar(
		root,
		"Crack",
		points[2] + Vector3.new(0, 0.2, 0.1),
		points[4] + Vector3.new(0, 0.24, 0),
		0.03,
		dark,
		Smooth
	)
	piece(
		root,
		"Frost",
		Block,
		Vector3.new(0.3, 0.06, 0.5),
		CFrame.new(points[4] + Vector3.new(0, 0.2, 0.25)),
		M.White,
		Smooth,
		0.1
	)
	piece(
		root,
		"Frost2",
		Ball,
		Vector3.new(0.14, 0.1, 0.14),
		CFrame.new(points[6] + Vector3.new(0, 0.1, 0)),
		M.White,
		Smooth,
		0.1
	)
end

-- A sea chest frozen into the ice: iron-banded wood, a gold lock, and ice grown over half of it.
builders.IceLockedChest = function(root, def)
	local color = def.Color
	local wood = shade(M.Cork, -0.4)
	-- The chest itself.
	piece(root, "Body", Block, Vector3.new(1.7, 0.8, 1.1), CFrame.new(0, -0.35, 0), wood, WoodPlanks)
	piece(
		root,
		"Lid",
		Cylinder,
		Vector3.new(1.7, 0.95, 1.0),
		CFrame.new(0, 0.05, 0),
		shade(wood, 0.05),
		WoodPlanks
	)
	for _, x in { -0.65, 0.65 } do
		piece(root, "Band", Block, Vector3.new(0.14, 0.82, 1.14), CFrame.new(x, -0.35, 0), M.Iron, Rust)
		piece(root, "LidBand", Cylinder, Vector3.new(0.14, 1.0, 1.05), CFrame.new(x, 0.05, 0), M.Iron, Rust)
	end
	piece(root, "Lock", Block, Vector3.new(0.3, 0.3, 0.1), CFrame.new(0, -0.05, 0.58), M.Gold, Foil)
	piece(root, "Keyhole", Block, Vector3.new(0.06, 0.12, 0.04), CFrame.new(0, -0.07, 0.64), M.Hole, Smooth)
	piece(root, "Hasp", Block, Vector3.new(0.12, 0.3, 0.06), CFrame.new(0, 0.17, 0.55), M.Iron, Metal)
	-- A chain wrapped round it, frozen stiff.
	for index = 0, 3 do
		piece(
			root,
			"Chain",
			Cylinder,
			Vector3.new(0.08, 0.16, 0.16),
			CFrame.new(-0.3 + index * 0.2, -0.45, 0.58) * CFrame.Angles(0, 0, math.rad(index * 90)),
			M.Iron,
			Metal
		)
	end
	-- The ice: a thick translucent slab over the bottom and one side, spires rising, icicles hanging.
	piece(root, "IceBase", Block, Vector3.new(2.0, 0.45, 1.4), CFrame.new(0, -0.58, 0), color, Glass, 0.45)
	piece(
		root,
		"IceSide",
		Block,
		Vector3.new(0.6, 1.0, 1.3),
		CFrame.new(0.65, -0.1, -0.05) * CFrame.Angles(0, 0, math.rad(-4)),
		shade(color, 0.1),
		Glass,
		0.45
	)
	piece(
		root,
		"IceBack",
		Block,
		Vector3.new(1.4, 0.9, 0.35),
		CFrame.new(-0.2, -0.1, -0.5),
		color,
		Glass,
		0.5
	)
	piece(
		root,
		"Crystal",
		Block,
		Vector3.new(0.4, 0.8, 0.4),
		CFrame.new(0.8, 0.28, 0.1) * CFrame.Angles(math.rad(8), math.rad(25), math.rad(-12)),
		shade(color, 0.2),
		Glass,
		0.4
	)
	piece(
		root,
		"Spire",
		Wedge,
		Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(0.8, 0.66, 0.1) * CFrame.Angles(0, math.rad(25), 0),
		M.White,
		Glass,
		0.35
	)
	piece(root, "Snow", Block, Vector3.new(0.9, 0.08, 0.7), CFrame.new(-0.3, 0.55, -0.1), M.White, Smooth)
	for index = 0, 5 do
		icicle(root, shade(color, 0.3), -0.85 + index * 0.3, -0.12, 0.7, 0.2 + (index % 3) * 0.1, 0.08)
	end
end

return builders
