-- Spearstone Reef item models (docs/design/biome-items.md). Each builder adds welded,
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
local Fabric = Palette.Material.Fabric
local Rock = Palette.Material.Rock
local Grass = Palette.Material.Grass

local M = Palette.ItemModel
local ALONG_Y = ModelParts.ALONG_Y
local ALONG_Z = ModelParts.ALONG_Z
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

-- A leaf-shaped stone blade standing along +Y from y = `base`, `length` long and `width` wide,
-- flat in Z. Built of stacked blocks that widen then narrow, with a wedge tip.
local function blade(
	root: BasePart,
	color: Color3,
	base: number,
	length: number,
	width: number,
	thickness: number,
	material: Enum.Material
)
	local rows = { 0.55, 0.85, 1.0, 0.9, 0.62 }
	local rowLength = length * 0.8 / #rows
	for index, fraction in rows do
		piece(
			root,
			"Blade",
			Block,
			Vector3.new(width * fraction, rowLength + 0.01, thickness),
			CFrame.new(0, base + rowLength * (index - 0.5), 0),
			if index % 2 == 0 then color else shade(color, 0.08),
			material
		)
	end
	local tip = length * 0.2
	piece(
		root,
		"TipA",
		Wedge,
		Vector3.new(thickness, tip, width * 0.31),
		CFrame.new(width * 0.155, base + length * 0.8 + tip / 2, 0) * CFrame.Angles(0, math.rad(90), 0),
		color,
		material
	)
	piece(
		root,
		"TipB",
		Wedge,
		Vector3.new(thickness, tip, width * 0.31),
		CFrame.new(-width * 0.155, base + length * 0.8 + tip / 2, 0) * CFrame.Angles(0, math.rad(-90), 0),
		color,
		material
	)
	-- A raised midrib down the middle.
	bar(
		root,
		"Midrib",
		Vector3.new(0, base + length * 0.05, 0),
		Vector3.new(0, base + length * 0.92, 0),
		thickness * 1.5,
		shade(color, -0.15),
		material
	)
end

-- A broken chip of spearstone: a tilted slab of grey rock with a pointed blue-grey crystal edge.
builders.SpearstoneChip = function(root, def)
	local color = def.Color
	piece(
		root,
		"Slab",
		Block,
		Vector3.new(0.45, 0.8, 0.26),
		CFrame.new(0, -0.15, 0) * CFrame.Angles(0, math.rad(15), math.rad(-6)),
		color,
		Rock
	)
	piece(
		root,
		"Base",
		Block,
		Vector3.new(0.48, 0.3, 0.32),
		CFrame.new(0.02, -0.45, 0) * CFrame.Angles(0, math.rad(-10), math.rad(4)),
		shade(color, -0.2),
		Rock
	)
	-- The point: a wedge on each side, so it reads as a sharp tip.
	piece(
		root,
		"PointA",
		Wedge,
		Vector3.new(0.26, 0.5, 0.22),
		CFrame.new(0.12, 0.4, 0) * CFrame.Angles(0, math.rad(90), 0),
		shade(color, 0.12),
		Rock
	)
	piece(
		root,
		"PointB",
		Wedge,
		Vector3.new(0.26, 0.5, 0.22),
		CFrame.new(-0.1, 0.38, 0) * CFrame.Angles(0, math.rad(-90), 0),
		color,
		Rock
	)
	-- Chipped flakes round the break, a vein of crystal and a smear of moss.
	piece(
		root,
		"Flake",
		Wedge,
		Vector3.new(0.14, 0.25, 0.18),
		CFrame.new(-0.22, -0.1, 0.05) * CFrame.Angles(0, math.rad(-90), math.rad(20)),
		shade(color, 0.2),
		Rock
	)
	piece(
		root,
		"Flake2",
		Wedge,
		Vector3.new(0.14, 0.2, 0.18),
		CFrame.new(0.23, -0.35, -0.04) * CFrame.Angles(0, math.rad(90), math.rad(-15)),
		shade(color, -0.1),
		Rock
	)
	bar(root, "Vein", Vector3.new(-0.1, -0.5, 0.14), Vector3.new(0.1, 0.35, 0.14), 0.05, M.SpyLens, Glass)
	piece(root, "Moss", Block, Vector3.new(0.3, 0.08, 0.1), CFrame.new(0.05, -0.58, 0.18), M.Moss, Grass)
	piece(
		root,
		"Barnacle",
		Ball,
		Vector3.new(0.1, 0.1, 0.1),
		CFrame.new(-0.12, -0.25, 0.17),
		M.Barnacle,
		Rock
	)
end

-- A stone spearhead crusted with barnacles and a streamer of weed.
builders.BarnacledSpearhead = function(root, def)
	local color = def.Color
	-- The tang (the part that went in the shaft) at the bottom, and the blade above.
	piece(root, "Tang", Block, Vector3.new(0.2, 0.4, 0.14), CFrame.new(0, -0.8, 0), shade(color, -0.25), Rock)
	piece(
		root,
		"Shoulders",
		Block,
		Vector3.new(0.34, 0.1, 0.18),
		CFrame.new(0, -0.58, 0),
		shade(color, -0.1),
		Rock
	)
	blade(root, color, -0.55, 1.5, 0.5, 0.14, Rock)
	-- Binding of cord round the tang.
	for index = 0, 2 do
		piece(
			root,
			"Cord",
			Block,
			Vector3.new(0.24, 0.05, 0.18),
			CFrame.new(0, -0.9 + index * 0.1, 0),
			M.Cork,
			Fabric
		)
	end
	-- Barnacles stuck all over, small and large.
	for index, spot in
		{
			Vector3.new(0.12, 0.0, 0.1),
			Vector3.new(-0.1, 0.3, 0.1),
			Vector3.new(0.05, 0.55, 0.1),
			Vector3.new(-0.14, -0.3, 0.1),
			Vector3.new(0.14, 0.2, -0.1),
			Vector3.new(-0.05, -0.1, -0.1),
		}
	do
		local size = 0.1 + (index % 3) * 0.04
		piece(
			root,
			"Barnacle",
			Cylinder,
			Vector3.new(0.06, size, size),
			CFrame.new(spot) * ALONG_Z,
			M.Barnacle,
			Rock
		)
	end
	-- Weed trailing down from the shoulder.
	bar(root, "Weed", Vector3.new(0.12, -0.55, 0.1), Vector3.new(0.05, -0.8, 0.12), 0.05, M.Moss, Grass)
	bar(root, "Weed", Vector3.new(0.05, -0.8, 0.12), Vector3.new(0.12, -0.98, 0.1), 0.04, M.Moss, Grass)
end

-- A long stone-tipped spear: wooden-looking shaft bound to a pale stone head, with a tassel.
builders.StoneSpear = function(root, def)
	local color = def.Color
	local shaft = shade(M.Cork, -0.35)
	piece(
		root,
		"Shaft",
		Cylinder,
		Vector3.new(3.1, 0.12, 0.12),
		CFrame.new(0, -0.5, 0) * ALONG_Y,
		shaft,
		Smooth
	)
	piece(
		root,
		"ButtCap",
		Cylinder,
		Vector3.new(0.18, 0.2, 0.2),
		CFrame.new(0, -2.0, 0) * ALONG_Y,
		color,
		Rock
	)
	piece(
		root,
		"ButtPoint",
		Wedge,
		Vector3.new(0.12, 0.2, 0.12),
		CFrame.new(0, -2.0, 0) * CFrame.Angles(math.rad(180), 0, 0),
		color,
		Rock
	)
	-- Grip bindings along the shaft.
	for _, y in { -1.3, -1.2, -1.1, -1.0 } do
		piece(
			root,
			"Grip",
			Cylinder,
			Vector3.new(0.05, 0.17, 0.17),
			CFrame.new(0, y, 0) * ALONG_Y,
			M.Cork,
			Fabric
		)
	end
	-- Socket, then the head.
	piece(
		root,
		"Socket",
		Cylinder,
		Vector3.new(0.3, 0.2, 0.2),
		CFrame.new(0, 1.15, 0) * ALONG_Y,
		shade(color, -0.25),
		Rock
	)
	for index = 0, 2 do
		piece(
			root,
			"Binding",
			Cylinder,
			Vector3.new(0.05, 0.22, 0.22),
			CFrame.new(0, 1.05 + index * 0.1, 0) * ALONG_Y,
			M.Cork,
			Fabric
		)
	end
	blade(root, color, 1.28, 0.72, 0.42, 0.1, Rock)
	-- A tassel of feathers tied below the head, and a notched stone weight halfway down.
	piece(root, "Knot", Ball, Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.1, 0.9, 0), M.Wax, Fabric)
	for index = -1, 1 do
		bar(
			root,
			"Feather",
			Vector3.new(0.1, 0.9, 0),
			Vector3.new(0.17 + index * 0.05, 0.4, index * 0.07),
			0.05,
			if index == 0 then M.Wax else M.Sun,
			Fabric
		)
	end
	piece(
		root,
		"Weight",
		Cylinder,
		Vector3.new(0.25, 0.26, 0.26),
		CFrame.new(0, -0.3, 0) * ALONG_Y,
		color,
		Rock
	)
	piece(root, "Barnacle", Ball, Vector3.new(0.1, 0.1, 0.1), CFrame.new(0.07, 0.2, 0.05), M.Barnacle, Rock)
	piece(
		root,
		"Moss",
		Cylinder,
		Vector3.new(0.3, 0.15, 0.15),
		CFrame.new(0, 0.0, 0) * ALONG_Y,
		M.Moss,
		Grass
	)
end

-- A green-bronze trident from the deep: three barbed prongs, a curved crossbar and an eye-gem.
builders.AncientTrident = function(root, def)
	local color = def.Color
	local bronze = shade(color, -0.25)
	local light = shade(color, 0.2)
	-- Shaft, with raised rings.
	piece(
		root,
		"Shaft",
		Cylinder,
		Vector3.new(3.2, 0.14, 0.14),
		CFrame.new(0, -0.4, 0) * ALONG_Y,
		bronze,
		Metal
	)
	for _, y in { -1.4, -0.4, 0.4 } do
		piece(
			root,
			"Ring",
			Cylinder,
			Vector3.new(0.08, 0.22, 0.22),
			CFrame.new(0, y, 0) * ALONG_Y,
			color,
			Metal
		)
	end
	piece(root, "Butt", Ball, Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, -2.0, 0), color, Metal)
	-- Crown piece where the prongs meet.
	piece(
		root,
		"Collar",
		Cylinder,
		Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(0, 0.75, 0) * ALONG_Y,
		color,
		Metal
	)
	piece(root, "Gem", Ball, Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 0.75, 0.14), M.Aqua, Glass)
	-- The curved crossbar the side prongs rise from.
	ModelParts.arc(root, "Cross", Vector2.new(0, 1.15), 0.55, 205, 335, 0.1, color)
	-- Three prongs, each a long bar ending in a spear tip, with two barbs.
	for _, x in { -0.5, 0, 0.5 } do
		local height = if x == 0 then 1.35 else 1.0
		local bottom = if x == 0 then 0.85 else 0.9
		bar(
			root,
			"Prong",
			Vector3.new(x, bottom, 0),
			Vector3.new(x, bottom + height - 0.2, 0),
			0.1,
			color,
			Metal
		)
		piece(
			root,
			"TipA",
			Wedge,
			Vector3.new(0.1, 0.28, 0.1),
			CFrame.new(x + 0.05, bottom + height - 0.06, 0) * CFrame.Angles(0, math.rad(90), 0),
			light,
			Metal
		)
		piece(
			root,
			"TipB",
			Wedge,
			Vector3.new(0.1, 0.28, 0.1),
			CFrame.new(x - 0.05, bottom + height - 0.06, 0) * CFrame.Angles(0, math.rad(-90), 0),
			light,
			Metal
		)
		if x ~= 0 then
			bar(
				root,
				"Barb",
				Vector3.new(x, bottom + height - 0.5, 0),
				Vector3.new(x + x * 0.3, bottom + height - 0.3, 0),
				0.07,
				light,
				Metal
			)
		end
	end
	-- Verdigris crust and a few barnacles.
	piece(root, "Crust", Block, Vector3.new(0.16, 0.3, 0.16), CFrame.new(0, 0.2, 0), M.Moss, Smooth)
	piece(
		root,
		"Barnacle",
		Ball,
		Vector3.new(0.12, 0.12, 0.12),
		CFrame.new(0.06, -1.0, 0.06),
		M.Barnacle,
		Rock
	)
	piece(
		root,
		"Barnacle2",
		Ball,
		Vector3.new(0.09, 0.09, 0.09),
		CFrame.new(-0.05, -0.7, 0.07),
		M.Barnacle,
		Rock
	)
end

return builders
