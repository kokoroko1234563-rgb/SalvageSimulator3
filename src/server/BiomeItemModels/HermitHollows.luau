-- Hermit Hollows item models (docs/design/biome-items.md). Each builder adds welded,
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
local Wood = Palette.Material.Wood

local M = Palette.ItemModel
local ALONG_Y = ModelParts.ALONG_Y
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

-- A cast-off crab claw lying along X: arm, palm, a fixed finger and a hinged pincer.
builders.MoltedClaw = function(root, def)
	local color = def.Color
	local pale = shade(color, 0.3)
	local dark = shade(color, -0.25)
	-- Arm segments, narrowing toward the broken end at -X.
	piece(root, "Stump", Cylinder, Vector3.new(0.25, 0.3, 0.3), CFrame.new(-0.85, -0.1, 0), pale, Smooth)
	piece(root, "Arm", Cylinder, Vector3.new(0.5, 0.36, 0.36), CFrame.new(-0.55, -0.08, 0), color, Smooth)
	piece(root, "Elbow", Ball, Vector3.new(0.42, 0.42, 0.42), CFrame.new(-0.3, -0.05, 0), dark, Smooth)
	-- The palm (the big part of the claw).
	piece(root, "Palm", Block, Vector3.new(0.6, 0.46, 0.7), CFrame.new(0.05, 0, 0), color, Smooth)
	piece(root, "PalmTop", Block, Vector3.new(0.5, 0.1, 0.6), CFrame.new(0.05, 0.25, 0), pale, Smooth)
	-- Fixed finger and the hinged pincer, each with teeth.
	piece(
		root,
		"Finger",
		Wedge,
		Vector3.new(0.3, 0.3, 0.8),
		CFrame.new(0.6, -0.15, 0.0) * CFrame.Angles(0, math.rad(90), 0),
		color,
		Smooth
	)
	piece(
		root,
		"Pincer",
		Wedge,
		Vector3.new(0.3, 0.3, 0.8),
		CFrame.new(0.6, 0.18, 0.0) * CFrame.Angles(math.rad(180), math.rad(90), 0),
		dark,
		Smooth
	)
	for index = 0, 2 do
		piece(
			root,
			"Tooth",
			Wedge,
			Vector3.new(0.12, 0.12, 0.1),
			CFrame.new(0.55 + index * 0.17, -0.0, 0.0),
			M.Label,
			Smooth
		)
	end
	piece(
		root,
		"Hinge",
		Ball,
		Vector3.new(0.18, 0.18, 0.18),
		CFrame.new(0.34, 0.08, 0.25),
		shade(color, -0.4),
		Metal
	)
	-- Spines along the top and a barnacle or two clinging on.
	for index = 0, 3 do
		piece(
			root,
			"Spine",
			Wedge,
			Vector3.new(0.08, 0.14, 0.12),
			CFrame.new(-0.3 + index * 0.22, 0.31, 0),
			pale,
			Smooth
		)
	end
	for _, spot in { Vector3.new(-0.5, 0.1, 0.17), Vector3.new(0.0, 0.2, -0.33) } do
		piece(root, "Barnacle", Ball, Vector3.new(0.12, 0.12, 0.12), CFrame.new(spot), M.Barnacle, Rock)
	end
end

-- A polished shell bead, a ball banded with a spiral and strung through the middle.
builders.ShellBead = function(root, def)
	local color = def.Color
	local band = shade(color, -0.25)
	piece(root, "Bead", Ball, Vector3.new(0.7, 0.7, 0.7), CFrame.new(), color, Smooth)
	-- Spiral bands: rings of growing then shrinking size round the body, each tilted a little.
	for index, y in { -0.22, -0.08, 0.08, 0.22 } do
		local diameter = math.sqrt(0.7 * 0.7 - (2 * y) ^ 2) + 0.01
		piece(
			root,
			"Band",
			Cylinder,
			Vector3.new(0.045, diameter, diameter),
			CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90 + index * 4)),
			if index % 2 == 0 then band else shade(color, 0.2),
			Smooth
		)
	end
	-- The stringing hole through the bead, with a short loop of twine.
	piece(root, "Hole", Cylinder, Vector3.new(0.7, 0.13, 0.13), CFrame.new(), M.Hole, Smooth)
	piece(root, "Twine", Cylinder, Vector3.new(0.7, 0.07, 0.07), CFrame.new(), M.Cork, Wood)
	piece(
		root,
		"Shine",
		Ball,
		Vector3.new(0.14, 0.14, 0.14),
		CFrame.new(-0.12, 0.2, 0.2),
		M.Label,
		Smooth,
		0.2
	)
	piece(root, "Shine2", Ball, Vector3.new(0.06, 0.06, 0.06), CFrame.new(-0.02, 0.26, 0.2), M.White, Smooth)
end

-- A domed crab carapace seen from above: layered shell, ridges, spines, eye notches and leg stubs.
builders.CrabCarapace = function(root, def)
	local color = def.Color
	local pale = shade(color, 0.3)
	local dark = shade(color, -0.3)
	-- Layers of the dome, each narrower and taller than the one under it.
	local layers = {
		{ 2.55, 0.2, -0.38 },
		{ 2.3, 0.2, -0.2 },
		{ 1.95, 0.2, -0.02 },
		{ 1.5, 0.2, 0.16 },
		{ 1.0, 0.2, 0.34 },
	}
	for index, layer in layers do
		local width, height, y = layer[1], layer[2], layer[3]
		piece(
			root,
			"Dome",
			Cylinder,
			Vector3.new(height, width, width * 0.84),
			CFrame.new(0, y, -0.05) * ALONG_Y,
			if index % 2 == 0 then pale else color,
			Smooth
		)
	end
	piece(root, "Rim", Cylinder, Vector3.new(0.08, 2.6, 2.2), CFrame.new(0, -0.43, 0) * ALONG_Y, dark, Smooth)
	-- Ridges (the grooves of a crab's back).
	for _, x in { -0.45, 0.45 } do
		bar(root, "Ridge", Vector3.new(x, 0.43, -0.4), Vector3.new(x * 1.7, 0.1, 0.35), 0.1, dark, Smooth)
	end
	bar(root, "Spine", Vector3.new(0, 0.44, -0.45), Vector3.new(0, 0.44, 0.4), 0.14, pale, Smooth)
	-- Front spikes and eye sockets along the front edge (+Z).
	for index = -2, 2 do
		piece(
			root,
			"Spike",
			Wedge,
			Vector3.new(0.18, 0.3, 0.3),
			CFrame.new(index * 0.38, -0.25, 1.0 - math.abs(index) * 0.05) * CFrame.Angles(math.rad(90), 0, 0),
			pale,
			Smooth
		)
	end
	for _, x in { -0.35, 0.35 } do
		piece(root, "Socket", Ball, Vector3.new(0.3, 0.3, 0.3), CFrame.new(x, -0.05, 0.9), dark, Smooth)
	end
	-- Stubs of the legs along both sides, and bumps on the back.
	for _, s in { -1, 1 } do
		for index = 0, 2 do
			piece(
				root,
				"LegStub",
				Cylinder,
				Vector3.new(0.3, 0.22, 0.22),
				CFrame.new(s * 1.18, -0.36, -0.5 + index * 0.45) * CFrame.Angles(0, 0, math.rad(15) * s),
				pale,
				Smooth
			)
		end
	end
	for _, spot in { Vector3.new(0.35, 0.42, -0.2), Vector3.new(-0.5, 0.4, 0.2), Vector3.new(0.7, 0.28, 0.2) } do
		piece(root, "Bump", Ball, Vector3.new(0.22, 0.22, 0.22), CFrame.new(spot), pale, Smooth)
	end
	piece(
		root,
		"Barnacle",
		Ball,
		Vector3.new(0.18, 0.18, 0.18),
		CFrame.new(-0.8, 0.12, -0.6),
		M.Barnacle,
		Rock
	)
end

-- A heap of gold in a cracked clam shell, topped with a tiny crab's crown, with jewels and pearls.
builders.CrabKingsHoard = function(root, def)
	local color = def.Color
	local gold = M.Gold
	-- The shell it sits in: two halves, one tipped open behind.
	piece(
		root,
		"ShellBottom",
		Cylinder,
		Vector3.new(0.3, 1.7, 1.2),
		CFrame.new(0, -0.5, 0) * ALONG_Y,
		M.Barnacle,
		Smooth
	)
	piece(
		root,
		"ShellLip",
		Cylinder,
		Vector3.new(0.12, 1.8, 1.3),
		CFrame.new(0, -0.3, 0) * ALONG_Y,
		shade(M.Barnacle, -0.2),
		Smooth
	)
	piece(
		root,
		"ShellBack",
		Cylinder,
		Vector3.new(0.12, 1.5, 0.9),
		CFrame.new(0, 0.1, -0.5) * CFrame.Angles(math.rad(-75), 0, 0) * ALONG_Y,
		shade(M.Barnacle, -0.1),
		Smooth
	)
	-- The pile: stacked coins and nuggets.
	piece(
		root,
		"Mound",
		Cylinder,
		Vector3.new(0.4, 1.3, 1.0),
		CFrame.new(0, -0.15, 0.05) * ALONG_Y,
		color,
		Foil
	)
	piece(root, "Mound2", Cylinder, Vector3.new(0.3, 0.9, 0.7), CFrame.new(0, 0.15, 0) * ALONG_Y, color, Foil)
	for index, spot in
		{
			Vector3.new(-0.6, -0.05, 0.3),
			Vector3.new(0.55, -0.05, 0.25),
			Vector3.new(0.35, 0.05, -0.3),
			Vector3.new(-0.4, 0.05, -0.2),
			Vector3.new(0.0, 0.0, 0.5),
			Vector3.new(0.2, 0.3, 0.1),
			Vector3.new(-0.2, 0.32, -0.1),
		}
	do
		piece(
			root,
			"Coin",
			Cylinder,
			Vector3.new(0.05, 0.32, 0.32),
			CFrame.new(spot)
				* CFrame.Angles(math.rad(index * 23), math.rad(index * 41), math.rad(60 + index * 17)),
			gold,
			Foil
		)
	end
	-- A little crown on top and gems and pearls in the pile.
	piece(
		root,
		"CrownBand",
		Cylinder,
		Vector3.new(0.14, 0.42, 0.42),
		CFrame.new(0, 0.42, 0) * ALONG_Y,
		gold,
		Metal
	)
	for index = 0, 4 do
		local angle = index / 5 * 2 * math.pi
		piece(
			root,
			"CrownPoint",
			Wedge,
			Vector3.new(0.08, 0.2, 0.1),
			CFrame.new(math.cos(angle) * 0.19, 0.58, math.sin(angle) * 0.19) * CFrame.Angles(0, -angle, 0),
			gold,
			Metal
		)
	end
	piece(root, "CrownJewel", Ball, Vector3.new(0.12, 0.12, 0.12), CFrame.new(0, 0.5, 0.21), M.Wax, Glass)
	piece(root, "Ruby", Ball, Vector3.new(0.24, 0.24, 0.24), CFrame.new(-0.55, 0.12, 0.35), M.Wax, Glass)
	piece(root, "Sapphire", Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0.6, 0.1, 0.1), M.Aqua, Glass)
	piece(root, "Emerald", Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0.1, 0.18, 0.45), M.Moss, Glass)
	piece(root, "Pearl", Ball, Vector3.new(0.26, 0.26, 0.26), CFrame.new(-0.2, 0.28, 0.3), M.Glint, Smooth)
	bar(root, "Chain", Vector3.new(0.7, 0.1, -0.4), Vector3.new(0.2, 0.3, 0.3), 0.06, gold, Metal)
	piece(root, "SandCrust", Block, Vector3.new(0.6, 0.06, 0.4), CFrame.new(-0.6, -0.2, -0.45), M.Cork, Sand)
end

return builders
