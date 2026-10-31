-- Models for the Coral Garden items (docs/design/biome-items.md). Each builder works in
-- the root's own frame, like the ones in ItemModels.

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
local Foil = Palette.Material.Foil
local Neon = Palette.Material.Neon
local M = Palette.ItemModel

local ALONG_Y = ModelParts.ALONG_Y
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local builders = {}

builders.BrainCoral = function(root, def)
	local color = def.Color
	local groove = shade(color, -0.3)
	local ridge = shade(color, 0.12)
	-- A rock foot, then the dome with its winding ridges and dark grooves.
	piece(
		root,
		"Foot",
		Cylinder,
		Vector3.new(0.25, 0.9, 0.9),
		CFrame.new(0, -0.45, 0) * ALONG_Y,
		M.Rock,
		Rock
	)
	piece(root, "Dome", Ball, Vector3.new(1.3, 1.0, 1.3), CFrame.new(0, -0.05, 0), groove, Smooth)
	local radius = Vector3.new(0.62, 0.5, 0.62)
	local rows = { { 12, 5, 0 }, { 30, 7, 0.4 }, { 50, 6, 0.1 }, { 68, 4, 0.5 }, { 82, 1, 0 } }
	for _, row in rows do
		local lat = math.rad(row[1])
		for i = 0, row[2] - 1 do
			local lon = (i + row[3]) / row[2] * 2 * math.pi
			local dir =
				Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
			local at = Vector3.new(dir.X * radius.X, dir.Y * radius.Y - 0.05, dir.Z * radius.Z)
			local length = 0.46 * math.cos(lat) + 0.2
			piece(
				root,
				"Ridge",
				Ball,
				Vector3.new(length, 0.2, 0.2),
				CFrame.lookAt(at, at * 2, Vector3.yAxis) * CFrame.Angles(0, 0, i * 1.3 + row[1]),
				if i % 2 == 0 then color else ridge,
				Smooth
			)
		end
	end
	-- A few tiny polyps in the grooves.
	for _, spot in { Vector3.new(0.3, 0.3, 0.45), Vector3.new(-0.4, 0.2, 0.4), Vector3.new(0.1, 0.42, -0.4) } do
		piece(
			root,
			"Polyp",
			Ball,
			Vector3.new(0.07, 0.07, 0.07),
			CFrame.new(spot),
			shade(groove, -0.2),
			Smooth
		)
	end
end

builders.ParrotfishScale = function(root, def)
	local color = def.Color
	local light = shade(color, 0.3)
	local dark = shade(color, -0.3)
	-- A big flat scale: a rounded shield of teal with a pink-violet sheen, a lighter inner
	-- plate, growth rings and fan ribs.
	piece(root, "Scale", Ball, Vector3.new(0.78, 0.09, 0.94), CFrame.new(0, 0, 0.03), color, Foil)
	piece(root, "Edge", Ball, Vector3.new(0.7, 0.06, 0.4), CFrame.new(0, 0, 0.3), light, Foil)
	piece(
		root,
		"Sheen",
		Ball,
		Vector3.new(0.5, 0.07, 0.56),
		CFrame.new(0, 0.005, 0.1),
		Color3.fromRGB(200, 120, 200),
		Foil,
		0.35
	)
	piece(root, "Root", Block, Vector3.new(0.34, 0.07, 0.14), CFrame.new(0, 0, -0.44), dark, Smooth)
	for _, spec in { { 0.18, 0.2 }, { 0.3, 0.34 }, { 0.4, 0.44 } } do
		local previous = nil
		for step = 0, 6 do
			local a = math.rad(25 + step * 22)
			local point = Vector3.new(spec[1] * math.cos(a) * 1.0, 0.05, -0.2 + spec[2] * 1.5 * math.sin(a))
			if previous then
				bar(root, "Ring", previous, point, 0.03, dark, Smooth)
			end
			previous = point
		end
	end
	for i = 0, 4 do
		local a = math.rad(35 + i * 27.5)
		bar(
			root,
			"Rib",
			Vector3.new(0, 0.05, -0.32),
			Vector3.new(0.34 * math.cos(a), 0.05, 0.3 + 0.2 * math.sin(a)),
			0.025,
			light,
			Smooth
		)
	end
	for _, x in { -0.14, 0.14 } do
		piece(root, "Glint", Ball, Vector3.new(0.05, 0.03, 0.1), CFrame.new(x, 0.06, 0.2), M.White, Neon, 0.3)
	end
end

builders.QueenConch = function(root, def)
	local inner = def.Color
	local outer = Color3.fromRGB(225, 190, 150)
	local knob = shade(outer, -0.15)
	-- The spire: whorls that shrink away along -X, banded, with a point at the end.
	piece(root, "Body", Ball, Vector3.new(0.82, 0.74, 0.72), CFrame.new(0.1, 0, 0), outer, Smooth)
	piece(
		root,
		"Whorl",
		Ball,
		Vector3.new(0.55, 0.5, 0.5),
		CFrame.new(-0.36, 0.05, -0.02),
		shade(outer, 0.05),
		Smooth
	)
	piece(root, "Whorl", Ball, Vector3.new(0.4, 0.36, 0.36), CFrame.new(-0.54, 0.08, -0.03), outer, Smooth)
	piece(
		root,
		"Whorl",
		Ball,
		Vector3.new(0.28, 0.26, 0.26),
		CFrame.new(-0.65, 0.1, -0.04),
		shade(outer, 0.05),
		Smooth
	)
	piece(root, "Apex", Ball, Vector3.new(0.14, 0.14, 0.14), CFrame.new(-0.72, 0.11, -0.04), knob, Smooth)
	-- The siphonal canal at the front end.
	piece(root, "Canal", Ball, Vector3.new(0.42, 0.22, 0.22), CFrame.new(0.54, -0.08, 0), outer, Smooth)
	piece(root, "CanalTip", Ball, Vector3.new(0.2, 0.12, 0.12), CFrame.new(0.7, -0.1, 0), knob, Smooth)
	-- The knobbly crown round the shoulder.
	for i = 0, 6 do
		local a = i / 7 * 2 * math.pi
		piece(
			root,
			"Knob",
			Ball,
			Vector3.new(0.14, 0.22, 0.14),
			CFrame.new(
				-0.18 + 0.05 * math.cos(a),
				0.28 * math.sin(a) + 0.04,
				0.3 * math.cos(a) + 0.04 * math.sin(a)
			),
			knob,
			Smooth
		)
	end
	-- The glowing pink flared lip on the front, wide and thin, with the dark throat.
	piece(
		root,
		"Lip",
		Ball,
		Vector3.new(0.88, 0.62, 0.14),
		CFrame.new(0.15, -0.02, 0.33),
		shade(inner, -0.1),
		Smooth
	)
	piece(root, "Inside", Ball, Vector3.new(0.7, 0.48, 0.1), CFrame.new(0.15, -0.02, 0.38), inner, Foil)
	piece(
		root,
		"Throat",
		Ball,
		Vector3.new(0.4, 0.26, 0.06),
		CFrame.new(0.05, -0.02, 0.4),
		shade(inner, -0.35),
		Smooth
	)
	piece(
		root,
		"LipEdge",
		Ball,
		Vector3.new(0.9, 0.12, 0.12),
		CFrame.new(0.15, 0.3, 0.34),
		shade(inner, 0.2),
		Smooth
	)
	-- The orange banding on the back.
	for _, x in { -0.05, 0.25 } do
		piece(
			root,
			"Band",
			Ball,
			Vector3.new(0.1, 0.6, 0.12),
			CFrame.new(x, 0.0, -0.3),
			Color3.fromRGB(215, 140, 90),
			Smooth
		)
	end
end

builders.RedCoralBranch = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.3)
	local tip = shade(color, 0.35)
	piece(root, "Base", Ball, Vector3.new(0.7, 0.24, 0.38), CFrame.new(0, -0.9, 0), M.Rock, Rock)
	piece(
		root,
		"Base",
		Ball,
		Vector3.new(0.4, 0.2, 0.3),
		CFrame.new(0.3, -0.86, 0.02),
		shade(M.Rock, 0.2),
		Rock
	)
	-- Each limb is { from, to, thickness }; the trunk forks, and the forks fork again.
	local limbs = {
		{ Vector3.new(0, -0.85, 0), Vector3.new(0.02, -0.4, 0.02), 0.18 },
		{ Vector3.new(0.02, -0.4, 0.02), Vector3.new(-0.05, 0.0, -0.03), 0.15 },
		{ Vector3.new(-0.05, 0.0, -0.03), Vector3.new(0.05, 0.42, 0.04), 0.12 },
		{ Vector3.new(0.05, 0.42, 0.04), Vector3.new(0.0, 0.9, 0.0), 0.09 },
		{ Vector3.new(0.02, -0.4, 0.02), Vector3.new(-0.36, -0.05, 0.08), 0.12 },
		{ Vector3.new(-0.36, -0.05, 0.08), Vector3.new(-0.5, 0.4, 0.04), 0.09 },
		{ Vector3.new(-0.5, 0.4, 0.04), Vector3.new(-0.46, 0.78, 0.1), 0.07 },
		{ Vector3.new(-0.36, -0.05, 0.08), Vector3.new(-0.62, -0.12, 0.12), 0.07 },
		{ Vector3.new(-0.5, 0.4, 0.04), Vector3.new(-0.26, 0.66, -0.04), 0.06 },
		{ Vector3.new(0.02, -0.4, 0.02), Vector3.new(0.4, -0.1, -0.08), 0.12 },
		{ Vector3.new(0.4, -0.1, -0.08), Vector3.new(0.54, 0.34, -0.04), 0.09 },
		{ Vector3.new(0.54, 0.34, -0.04), Vector3.new(0.5, 0.8, -0.1), 0.07 },
		{ Vector3.new(0.4, -0.1, -0.08), Vector3.new(0.6, -0.16, -0.1), 0.07 },
		{ Vector3.new(0.54, 0.34, -0.04), Vector3.new(0.3, 0.6, 0.04), 0.06 },
		{ Vector3.new(0.05, 0.42, 0.04), Vector3.new(0.26, 0.72, 0.1), 0.06 },
		{ Vector3.new(0.02, 0.6, 0.02), Vector3.new(-0.2, 0.8, -0.04), 0.06 },
	}
	local tips = {}
	for index, limb in limbs do
		bar(root, "Limb", limb[1], limb[2], limb[3], if index % 3 == 0 then dark else color, Smooth)
		piece(
			root,
			"Joint",
			Ball,
			Vector3.new(limb[3] * 1.15, limb[3] * 1.15, limb[3] * 1.15),
			CFrame.new(limb[2]),
			color,
			Smooth
		)
		if limb[3] <= 0.07 then
			table.insert(tips, limb[2])
		end
	end
	-- Bright polyp tips.
	for _, at in tips do
		piece(root, "Tip", Ball, Vector3.new(0.11, 0.11, 0.11), CFrame.new(at), tip, Smooth)
	end
end

builders.ReefDiadem = function(root, def)
	local color = def.Color
	local light = shade(color, 0.3)
	local dark = shade(color, -0.25)
	local pearl = M.Label
	local radius = 0.62
	-- The band, with a pearl-studded gold rim.
	for i = 0, 8 do
		local a = i / 9 * 2 * math.pi
		piece(
			root,
			"Band",
			Block,
			Vector3.new(0.12, 0.2, 2 * radius * math.tan(math.pi / 9) * 1.06 + 0.02),
			CFrame.new(radius * math.cos(a), -0.3, radius * math.sin(a)) * CFrame.Angles(0, -a, 0),
			color,
			Metal
		)
	end
	-- Forked coral branches growing from the band, each ending in two bright tips.
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi + math.pi / 6
		local c, s = math.cos(a), math.sin(a)
		local base = Vector3.new(radius * c, -0.2, radius * s)
		local fork = Vector3.new(radius * c, 0.05, radius * s)
		local tangent = Vector3.new(-s, 0, c)
		local out = Vector3.new(c, 0, s)
		bar(root, "Branch", base, fork, 0.1, if i % 2 == 0 then light else color, Metal)
		for _, side in { -1, 1 } do
			local tipAt = fork
				+ tangent * side * 0.12
				+ out * 0.04
				+ Vector3.new(0, 0.2 + (if side > 0 then 0.04 else 0), 0)
			bar(root, "Fork", fork, tipAt, 0.07, if i % 2 == 0 then light else color, Metal)
			piece(
				root,
				"Tip",
				Ball,
				Vector3.new(0.11, 0.11, 0.11),
				CFrame.new(tipAt),
				if i % 2 == 0 then pearl else M.Glint,
				Foil
			)
		end
	end
	-- The scallop-shell fan at the front, with a big pearl, and a starfish at each side.
	for k = -2, 2 do
		piece(
			root,
			"Fan",
			Block,
			Vector3.new(0.09, 0.3 - math.abs(k) * 0.04, 0.05),
			CFrame.new(k * 0.13, -0.05 + 0.04 * (2 - math.abs(k)), radius + 0.1)
				* CFrame.Angles(0, 0, -k * 0.3),
			dark,
			Metal
		)
	end
	piece(
		root,
		"FanPearl",
		Ball,
		Vector3.new(0.2, 0.2, 0.2),
		CFrame.new(0, -0.3, radius + 0.1),
		M.White,
		Foil
	)
	piece(
		root,
		"FanGlint",
		Ball,
		Vector3.new(0.05, 0.05, 0.05),
		CFrame.new(-0.04, -0.25, radius + 0.19),
		M.Glint,
		Neon
	)
	for _, side in { -1, 1 } do
		for k = 0, 2 do
			local a = k / 3 * math.pi
			bar(
				root,
				"Star",
				Vector3.new(side * (radius + 0.06), -0.3, 0)
					+ Vector3.new(0, 0.1 * math.cos(a), 0.1 * math.sin(a)),
				Vector3.new(side * (radius + 0.06), -0.3, 0)
					- Vector3.new(0, 0.1 * math.cos(a), 0.1 * math.sin(a)),
				0.05,
				M.Float,
				Smooth
			)
		end
	end
end

return builders
