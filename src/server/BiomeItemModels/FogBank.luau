-- Fog Bank item models (docs/design/biome-items.md). Each builder adds welded, massless
-- parts to the item's root in its own frame; see ItemModels.luau for how they are used.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local ModelParts = require(script.Parent.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder

local Glass = Palette.Material.Glass
local Metal = Palette.Material.Metal
local Rust = Palette.Material.Rust
local Neon = Palette.Material.Neon
local Smooth = Palette.Material.Smooth
local Fabric = Palette.Material.Fabric
local Foil = Palette.Material.Foil

local M = Palette.ItemModel
local ALONG_Y = ModelParts.ALONG_Y
local ALONG_Z = ModelParts.ALONG_Z
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

-- A weathered ship's bell hanging from a bracket in the fog.
builders.FogBell = function(root, def)
	local color = def.Color
	local bronze = shade(color, -0.1)
	-- Bracket: a crossbeam on two posts, with the bell hung from it.
	piece(root, "Beam", Block, Vector3.new(1.1, 0.1, 0.14), CFrame.new(0, 0.65, 0), M.Iron, Rust)
	for _, x in { -0.5, 0.5 } do
		piece(root, "Post", Block, Vector3.new(0.1, 0.2, 0.14), CFrame.new(x, 0.55, 0), M.Iron, Rust)
	end
	piece(root, "Hanger", Block, Vector3.new(0.1, 0.2, 0.1), CFrame.new(0, 0.5, 0), M.Iron, Rust)
	piece(
		root,
		"Crown",
		Cylinder,
		Vector3.new(0.12, 0.3, 0.3),
		CFrame.new(0, 0.38, 0) * ALONG_Y,
		bronze,
		Metal
	)
	-- The bell, as flaring rings from shoulder to lip.
	piece(root, "Shoulder", Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 0.2, 0), bronze, Metal)
	piece(
		root,
		"Upper",
		Cylinder,
		Vector3.new(0.3, 0.55, 0.55),
		CFrame.new(0, 0.1, 0) * ALONG_Y,
		bronze,
		Metal
	)
	piece(
		root,
		"Middle",
		Cylinder,
		Vector3.new(0.3, 0.75, 0.75),
		CFrame.new(0, -0.15, 0) * ALONG_Y,
		color,
		Metal
	)
	piece(
		root,
		"Flare",
		Cylinder,
		Vector3.new(0.25, 0.98, 0.98),
		CFrame.new(0, -0.4, 0) * ALONG_Y,
		bronze,
		Metal
	)
	piece(
		root,
		"Lip",
		Cylinder,
		Vector3.new(0.12, 1.12, 1.12),
		CFrame.new(0, -0.58, 0) * ALONG_Y,
		shade(color, -0.3),
		Metal
	)
	piece(
		root,
		"Band",
		Cylinder,
		Vector3.new(0.06, 0.82, 0.82),
		CFrame.new(0, -0.02, 0) * ALONG_Y,
		M.Gold,
		Foil
	)
	piece(root, "Clapper", Ball, Vector3.new(0.24, 0.24, 0.24), CFrame.new(0, -0.62, 0), M.Iron, Metal)
	bar(root, "ClapperRod", Vector3.new(0, 0.1, 0), Vector3.new(0, -0.6, 0), 0.05, M.Iron, Metal)
	-- A lashing of rope round the hanger, and a patch of verdigris.
	piece(
		root,
		"Rope",
		Cylinder,
		Vector3.new(0.12, 0.16, 0.16),
		CFrame.new(0, 0.53, 0) * ALONG_Y,
		M.Cork,
		Fabric
	)
	piece(root, "Verdigris", Block, Vector3.new(0.3, 0.18, 0.04), CFrame.new(0.2, -0.3, 0.37), M.Moss, Smooth)
end

-- A leather-bound logbook lying flat.
builders.KeepersLogbook = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	piece(root, "Pages", Block, Vector3.new(0.9, 0.2, 1.3), CFrame.new(0.02, 0, 0), M.Paper, Fabric)
	piece(
		root,
		"PageEdge",
		Block,
		Vector3.new(0.9, 0.04, 1.3),
		CFrame.new(0.02, 0.02, 0),
		shade(M.Paper, -0.12),
		Fabric
	)
	piece(root, "BackCover", Block, Vector3.new(1.0, 0.05, 1.4), CFrame.new(0, -0.125, 0), color, Fabric)
	piece(root, "FrontCover", Block, Vector3.new(1.0, 0.05, 1.4), CFrame.new(0, 0.125, 0), color, Fabric)
	piece(root, "Spine", Block, Vector3.new(0.1, 0.3, 1.4), CFrame.new(-0.45, 0, 0), dark, Fabric)
	for _, z in { -0.4, 0, 0.4 } do
		piece(root, "SpineBand", Block, Vector3.new(0.12, 0.31, 0.05), CFrame.new(-0.45, 0, z), M.Gold, Foil)
	end
	for _, x in { -0.45, 0.45 } do
		for _, z in { -0.65, 0.65 } do
			piece(root, "Corner", Block, Vector3.new(0.14, 0.31, 0.14), CFrame.new(x, 0, z), M.Gold, Foil)
		end
	end
	piece(root, "Label", Block, Vector3.new(0.5, 0.02, 0.6), CFrame.new(0.1, 0.15, -0.1), M.Paper, Smooth)
	for index = 0, 2 do
		piece(
			root,
			"Line",
			Block,
			Vector3.new(0.34, 0.02, 0.05),
			CFrame.new(0.1, 0.16, -0.28 + index * 0.18),
			dark,
			Smooth
		)
	end
	piece(root, "Strap", Block, Vector3.new(0.12, 0.31, 0.7), CFrame.new(0.4, 0, 0.3), dark, Fabric)
	piece(root, "Clasp", Block, Vector3.new(0.1, 0.04, 0.12), CFrame.new(0.4, 0.15, 0.3), M.Gold, Foil)
	piece(root, "Ribbon", Block, Vector3.new(0.05, 0.02, 0.4), CFrame.new(0.2, 0, 0.58), M.Wax, Fabric)
end

-- A ship's storm lantern, rusted and still faintly lit.
builders.LostShipsLamp = function(root, def)
	local color = def.Color
	piece(
		root,
		"Base",
		Cylinder,
		Vector3.new(0.16, 0.8, 0.8),
		CFrame.new(0, -0.72, 0) * ALONG_Y,
		M.Iron,
		Rust
	)
	piece(
		root,
		"Collar",
		Cylinder,
		Vector3.new(0.14, 0.66, 0.66),
		CFrame.new(0, -0.6, 0) * ALONG_Y,
		color,
		Metal
	)
	piece(
		root,
		"Globe",
		Cylinder,
		Vector3.new(0.95, 0.6, 0.6),
		CFrame.new(0, -0.05, 0) * ALONG_Y,
		M.LanternGlass,
		Glass,
		0.4
	)
	for index = 0, 3 do
		local angle = index / 4 * 2 * math.pi + math.pi / 4
		local x, z = math.cos(angle) * 0.34, math.sin(angle) * 0.34
		bar(root, "Rib", Vector3.new(x, -0.55, z), Vector3.new(x, 0.45, z), 0.06, M.Iron, Rust)
	end
	piece(root, "Rim", Cylinder, Vector3.new(0.1, 0.72, 0.72), CFrame.new(0, 0.46, 0) * ALONG_Y, color, Metal)
	piece(
		root,
		"Hood",
		Cylinder,
		Vector3.new(0.22, 0.56, 0.56),
		CFrame.new(0, 0.58, 0) * ALONG_Y,
		M.Iron,
		Rust
	)
	piece(
		root,
		"Chimney",
		Cylinder,
		Vector3.new(0.18, 0.24, 0.24),
		CFrame.new(0, 0.74, 0) * ALONG_Y,
		M.Iron,
		Rust
	)
	piece(
		root,
		"Ring",
		Cylinder,
		Vector3.new(0.05, 0.26, 0.26),
		CFrame.new(0, 0.72, 0) * ALONG_Z,
		M.Iron,
		Metal
	)
	piece(root, "Wick", Block, Vector3.new(0.1, 0.12, 0.1), CFrame.new(0, -0.5, 0), M.Rock, Smooth)
	local flame =
		piece(root, "Flame", Ball, Vector3.new(0.3, 0.38, 0.3), CFrame.new(0, -0.3, 0), M.Flame, Neon)
	local light = Instance.new("PointLight")
	light.Color = M.Flame
	light.Range = 9
	light.Brightness = 0.9
	light.Parent = flame
	piece(root, "Handle", Block, Vector3.new(0.05, 0.05, 0.3), CFrame.new(0.38, -0.2, 0), M.Iron, Metal)
end

-- A great Fresnel lens, standing on its edge: glass rings round a bright core, in a brass frame.
builders.LighthouseLens = function(root, def)
	local brass = M.Gold
	-- Frame: four brass bars round the rim.
	for _, s in { -1, 1 } do
		piece(root, "FrameV", Block, Vector3.new(0.1, 1.8, 0.22), CFrame.new(s * 0.85, 0, 0), brass, Metal)
		piece(root, "FrameH", Block, Vector3.new(1.8, 0.1, 0.22), CFrame.new(0, s * 0.85, 0), brass, Metal)
	end
	-- The lens: concentric glass rings, thicker toward the middle.
	for index, diameter in { 1.7, 1.4, 1.1, 0.8, 0.5 } do
		piece(
			root,
			"Ring",
			Cylinder,
			Vector3.new(0.2 + index * 0.14, diameter, diameter),
			CFrame.new(0, 0, 0) * ALONG_Z,
			shade(def.Color, 0.1 * (index % 2)),
			Glass,
			0.35
		)
	end
	for _, diameter in { 1.25, 0.95 } do
		piece(
			root,
			"Groove",
			Cylinder,
			Vector3.new(0.04, diameter, diameter),
			CFrame.new(0, 0, -0.34) * ALONG_Z,
			shade(def.Color, -0.3),
			Metal
		)
	end
	local core = piece(root, "Core", Ball, Vector3.new(0.36, 0.36, 0.36), CFrame.new(0, 0, 0), M.Glow, Neon)
	for _, x in { -0.85, 0.85 } do
		for _, y in { -0.85, 0.85 } do
			piece(
				root,
				"Rivet",
				Ball,
				Vector3.new(0.14, 0.14, 0.14),
				CFrame.new(x, y, 0.11),
				shade(brass, -0.25),
				Metal
			)
		end
	end
	piece(root, "Foot", Block, Vector3.new(1.0, 0.1, 0.5), CFrame.new(0, -0.89, 0), shade(brass, -0.3), Metal)
	local light = Instance.new("PointLight")
	light.Color = M.Glow
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = core
end

return builders
