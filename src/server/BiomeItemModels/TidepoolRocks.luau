-- Models for the Tidepool Rocks items (docs/design/biome-items.md). Each builder works in
-- the root's own frame, like the ones in ItemModels.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local ModelParts = require(script.Parent.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder

local Smooth = Palette.Material.Smooth
local Rock = Palette.Material.Rock
local Glass = Palette.Material.Glass
local Foil = Palette.Material.Foil
local Neon = Palette.Material.Neon
local M = Palette.ItemModel

local ALONG_Z = ModelParts.ALONG_Z
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

builders.HermitCrabShell = function(root, def)
	local color = def.Color
	local stripe = shade(color, -0.35)
	local crab = Color3.fromRGB(225, 110, 70)
	-- The spiralling shell: a chain of balls that shrink as they climb, with stripes.
	piece(root, "Whorl", Ball, Vector3.new(0.74, 0.64, 0.8), CFrame.new(0, -0.1, -0.2), color, Smooth)
	piece(
		root,
		"Whorl",
		Ball,
		Vector3.new(0.56, 0.5, 0.56),
		CFrame.new(0.02, 0.1, -0.3),
		shade(color, 0.08),
		Smooth
	)
	piece(root, "Whorl", Ball, Vector3.new(0.38, 0.36, 0.38), CFrame.new(0.0, 0.23, -0.34), color, Smooth)
	piece(
		root,
		"Apex",
		Ball,
		Vector3.new(0.2, 0.2, 0.22),
		CFrame.new(-0.02, 0.32, -0.36),
		shade(color, -0.1),
		Smooth
	)
	for i = 0, 5 do
		local t = i / 5
		local a = t * 2.2 * math.pi
		piece(
			root,
			"Stripe",
			Ball,
			Vector3.new(0.1, 0.08, 0.1),
			CFrame.new(
				0.34 * (1 - t * 0.5) * math.cos(a),
				-0.1 + t * 0.4,
				-0.25 - t * 0.1 + 0.3 * (1 - t) * math.sin(a)
			),
			stripe,
			Rock
		)
	end
	-- The shell's mouth, with the crab looking out of it.
	piece(
		root,
		"Mouth",
		Cylinder,
		Vector3.new(0.06, 0.5, 0.5),
		CFrame.new(0, -0.14, 0.18) * ALONG_Z,
		shade(color, -0.55),
		Smooth
	)
	piece(
		root,
		"Lip",
		Cylinder,
		Vector3.new(0.05, 0.56, 0.56),
		CFrame.new(0, -0.14, 0.14) * ALONG_Z,
		shade(color, 0.2),
		Smooth
	)
	piece(root, "Body", Ball, Vector3.new(0.34, 0.26, 0.4), CFrame.new(0, -0.18, 0.34), crab, Smooth)
	for _, x in { -1, 1 } do
		-- A claw each side (the left one bigger), and two walking legs.
		local big = if x < 0 then 1.3 else 1
		bar(
			root,
			"Arm",
			Vector3.new(x * 0.15, -0.2, 0.34),
			Vector3.new(x * 0.28, -0.22, 0.46),
			0.07,
			crab,
			Smooth
		)
		piece(
			root,
			"Claw",
			Ball,
			Vector3.new(0.2 * big, 0.12, 0.22 * big),
			CFrame.new(x * 0.3, -0.22, 0.5),
			crab,
			Smooth
		)
		piece(
			root,
			"Pincer",
			Block,
			Vector3.new(0.05, 0.07, 0.12 * big),
			CFrame.new(x * 0.3, -0.22, 0.59),
			shade(crab, -0.2),
			Smooth
		)
		bar(
			root,
			"Leg",
			Vector3.new(x * 0.15, -0.26, 0.28),
			Vector3.new(x * 0.4, -0.38, 0.3),
			0.05,
			shade(crab, -0.15),
			Smooth
		)
		bar(
			root,
			"Leg",
			Vector3.new(x * 0.14, -0.26, 0.2),
			Vector3.new(x * 0.38, -0.38, 0.12),
			0.05,
			shade(crab, -0.15),
			Smooth
		)
		bar(
			root,
			"Stalk",
			Vector3.new(x * 0.07, -0.1, 0.4),
			Vector3.new(x * 0.08, 0.0, 0.44),
			0.04,
			crab,
			Smooth
		)
		piece(
			root,
			"Eye",
			Ball,
			Vector3.new(0.08, 0.08, 0.08),
			CFrame.new(x * 0.08, 0.02, 0.44),
			M.Hole,
			Glass
		)
	end
end

builders.SeaUrchin = function(root, def)
	local color = def.Color
	local tip = shade(color, 0.3)
	piece(root, "Test", Ball, Vector3.new(0.58, 0.54, 0.58), CFrame.new(), shade(color, -0.2), Smooth)
	-- Spines in every direction (spread over a sphere), long and short, with pale tips.
	local count = 24
	local golden = math.pi * (3 - math.sqrt(5))
	for i = 0, count - 1 do
		local y = 1 - (i + 0.5) / count * 2
		local r = math.sqrt(1 - y * y)
		local a = i * golden
		local dir = Vector3.new(r * math.cos(a), y, r * math.sin(a))
		local long = if i % 3 == 0 then 0.44 else 0.38
		bar(root, "Spine", dir * 0.22, dir * long, 0.045, color, Smooth)
		piece(root, "SpineTip", Ball, Vector3.new(0.05, 0.05, 0.05), CFrame.new(dir * long), tip, Smooth)
	end
	-- The mouth below, and a purple-pink ring of tube feet round it.
	piece(root, "Mouth", Ball, Vector3.new(0.16, 0.08, 0.16), CFrame.new(0, -0.27, 0), M.Rock, Rock)
end

builders.PearlOyster = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	local nacre = Color3.fromRGB(235, 225, 240)
	-- The lower shell: a rough bowl with a pearly inside.
	piece(root, "LowerShell", Ball, Vector3.new(1.1, 0.3, 0.9), CFrame.new(0, -0.17, 0.02), color, Rock)
	piece(root, "LowerRim", Ball, Vector3.new(1.0, 0.1, 0.8), CFrame.new(0, -0.07, 0.02), dark, Rock)
	piece(root, "Nacre", Ball, Vector3.new(0.92, 0.1, 0.72), CFrame.new(0, -0.04, 0.02), nacre, Foil)
	piece(
		root,
		"Flesh",
		Ball,
		Vector3.new(0.6, 0.12, 0.44),
		CFrame.new(0, -0.02, 0.05),
		Color3.fromRGB(235, 200, 190),
		Smooth
	)
	piece(root, "Pearl", Ball, Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, 0.07, 0.05), M.White, Glass)
	piece(
		root,
		"PearlGlint",
		Ball,
		Vector3.new(0.07, 0.07, 0.07),
		CFrame.new(-0.05, 0.14, 0.0),
		M.Glint,
		Neon
	)
	-- The upper shell, propped open on its hinge at the back.
	local hinge = CFrame.new(0, -0.08, -0.42) * CFrame.Angles(-0.25, 0, 0)
	piece(
		root,
		"UpperShell",
		Ball,
		Vector3.new(1.05, 0.28, 0.84),
		hinge * CFrame.new(0, 0.05, 0.42),
		color,
		Rock
	)
	piece(
		root,
		"UpperNacre",
		Ball,
		Vector3.new(0.9, 0.08, 0.7),
		hinge * CFrame.new(0, -0.05, 0.42),
		nacre,
		Foil
	)
	-- Growth ridges across the shells, and barnacles on the upper one.
	for i = -2, 2 do
		piece(
			root,
			"Ridge",
			Block,
			Vector3.new(0.05, 0.05, 0.4),
			CFrame.new(i * 0.2, -0.3, 0.05) * CFrame.Angles(0, i * 0.12, 0),
			dark,
			Rock
		)
		piece(
			root,
			"UpperRidge",
			Block,
			Vector3.new(0.05, 0.05, 0.4),
			hinge * CFrame.new(i * 0.19, 0.18, 0.42) * CFrame.Angles(0, i * 0.12, 0),
			dark,
			Rock
		)
	end
	piece(root, "Hinge", Block, Vector3.new(0.4, 0.1, 0.1), CFrame.new(0, -0.08, -0.43), dark, Rock)
	piece(
		root,
		"Barnacle",
		Ball,
		Vector3.new(0.12, 0.1, 0.12),
		hinge * CFrame.new(0.2, 0.2, 0.3),
		M.Barnacle,
		Rock
	)
	piece(
		root,
		"Barnacle",
		Ball,
		Vector3.new(0.09, 0.08, 0.09),
		hinge * CFrame.new(-0.25, 0.2, 0.55),
		M.Barnacle,
		Rock
	)
end

builders.CoralFan = function(root, def)
	local color = def.Color
	local light = shade(color, 0.25)
	local dark = shade(color, -0.25)
	local base = Vector3.new(0, -0.62, 0)
	-- A rocky foot and the short stalk.
	piece(root, "Foot", Ball, Vector3.new(0.7, 0.3, 0.26), CFrame.new(0, -0.7, 0), M.Rock, Rock)
	piece(
		root,
		"Foot",
		Ball,
		Vector3.new(0.4, 0.2, 0.22),
		CFrame.new(0.28, -0.66, 0),
		shade(M.Rock, 0.15),
		Rock
	)
	bar(root, "Stalk", Vector3.new(0, -0.7, 0), Vector3.new(0, -0.45, 0), 0.13, dark, Smooth)
	local function at(angle: number, s: number): Vector3
		local a = math.rad(angle)
		return base + Vector3.new(s * 0.85 * math.cos(a), 0.15 + s * 1.3 * math.sin(a), 0)
	end
	-- The fan: ribs spreading from the stalk, and cross-links between them.
	local angles = { 25, 47, 69, 91, 113, 135, 157 }
	for _, angle in angles do
		bar(root, "Rib", at(angle, 0.0), at(angle, 1.0), 0.07, color, Smooth)
		piece(root, "Tip", Ball, Vector3.new(0.11, 0.11, 0.11), CFrame.new(at(angle, 1.0)), light, Smooth)
	end
	for _, s in { 0.35, 0.62, 0.86 } do
		for i = 1, #angles - 1 do
			bar(
				root,
				"Web",
				at(angles[i], s),
				at(angles[i + 1], s),
				0.05,
				if i % 2 == 0 then light else color,
				Smooth
			)
		end
	end
	for _, angle in { 36, 80, 102, 146 } do
		bar(root, "Branch", at(angle, 0.5), at(angle, 0.9), 0.05, dark, Smooth)
	end
end

builders.GiantClamPearl = function(root, def)
	local color = def.Color
	local shell = Color3.fromRGB(170, 160, 140)
	local flesh = Color3.fromRGB(70, 150, 170)
	-- The lower shell, ribbed, and the mantle's glowing lip.
	piece(root, "LowerShell", Ball, Vector3.new(1.4, 0.7, 1.1), CFrame.new(0, -0.42, 0.05), shell, Rock)
	for i = -3, 3 do
		piece(
			root,
			"Rib",
			Block,
			Vector3.new(0.09, 0.09, 0.5),
			CFrame.new(i * 0.18, -0.6 + math.abs(i) * 0.04, 0.2) * CFrame.Angles(0.5, i * 0.18, 0),
			shade(shell, 0.2),
			Rock
		)
	end
	piece(root, "Mantle", Ball, Vector3.new(1.15, 0.2, 0.9), CFrame.new(0, -0.3, 0.05), flesh, Glass)
	piece(
		root,
		"MantleFrill",
		Ball,
		Vector3.new(0.9, 0.12, 0.6),
		CFrame.new(0, -0.24, 0.05),
		shade(flesh, 0.3),
		Glass
	)
	for i = 0, 9 do
		local a = i / 10 * 2 * math.pi
		piece(
			root,
			"Frill",
			Ball,
			Vector3.new(0.17, 0.12, 0.17),
			CFrame.new(0.55 * math.cos(a), -0.22, 0.05 + 0.42 * math.sin(a)),
			if i % 2 == 0 then shade(flesh, 0.35) else flesh,
			Glass
		)
	end
	-- The pearl itself, with a halo of shine.
	piece(
		root,
		"PearlGlow",
		Ball,
		Vector3.new(0.84, 0.84, 0.84),
		CFrame.new(0, 0.12, 0.05),
		M.Glint,
		Glass,
		0.55
	)
	piece(root, "Pearl", Ball, Vector3.new(0.76, 0.76, 0.76), CFrame.new(0, 0.12, 0.05), color, Foil)
	piece(root, "Shine", Ball, Vector3.new(0.18, 0.12, 0.14), CFrame.new(-0.2, 0.36, 0.02), M.White, Neon)
	-- The upper shell, swung open and back with a scalloped edge.
	local hinge = CFrame.new(0, -0.25, -0.5) * CFrame.Angles(-1.1, 0, 0)
	piece(root, "UpperShell", Ball, Vector3.new(1.35, 0.4, 1.0), hinge * CFrame.new(0, 0.1, 0.5), shell, Rock)
	piece(
		root,
		"UpperInside",
		Ball,
		Vector3.new(1.15, 0.12, 0.85),
		hinge * CFrame.new(0, -0.08, 0.5),
		Color3.fromRGB(240, 232, 235),
		Foil
	)
	for i = -3, 3 do
		piece(
			root,
			"UpperRib",
			Block,
			Vector3.new(0.1, 0.1, 0.55),
			hinge * CFrame.new(i * 0.18, 0.3, 0.55) * CFrame.Angles(0, i * 0.2, 0),
			shade(shell, 0.2),
			Rock
		)
	end
end

return builders
