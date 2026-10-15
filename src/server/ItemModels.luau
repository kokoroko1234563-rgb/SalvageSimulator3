-- Beach item models. The catalog gives every item a physics body: its root part, at the
-- catalog size and shape. Grabbing, cargo and the sell pads all measure that body, so it
-- stays as it is. What you see is built on top of it from welded parts that are massless,
-- don't collide and can't be picked, so they move with the item and never get in the way.
-- The root turns invisible.
--
-- Roblox draws cylinders along their X axis, and items spawn lying the way their body does.
-- So every model is built in the root's own frame: a bottle lies on its side, a wheel
-- stands on its edge. Items without a builder keep the plain catalog look.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder
local Wedge = Enum.PartType.Wedge

local Glass = Palette.Material.Glass
local Wood = Palette.Material.Wood
local WoodPlanks = Palette.Material.WoodPlanks
local Metal = Palette.Material.Metal
local Rust = Palette.Material.Rust
local Foil = Palette.Material.Foil
local Neon = Palette.Material.Neon
local Smooth = Palette.Material.Smooth
local Rock = Palette.Material.Rock
local Fabric = Palette.Material.Fabric
local Grass = Palette.Material.Grass

local M = Palette.ItemModel

local ModelParts = require(script.Parent.ModelParts)

local ALONG_Y = ModelParts.ALONG_Y
local ALONG_Z = ModelParts.ALONG_Z
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar
local arc = ModelParts.arc
local along = ModelParts.along

local ItemModels = {}
local builders = {}

-- A bottle lying along X. `half` is half its length, `width` its diameter.
local function bottle(
	root: BasePart,
	color: Color3,
	half: number,
	width: number,
	detail: ((number, number) -> ())?
)
	local bodyStart, bodyEnd = -0.95 * half, 0.3 * half
	local shoulderEnd, neckEnd, corkEnd = 0.6 * half, 0.88 * half, 0.98 * half
	piece(
		root,
		"Body",
		Cylinder,
		Vector3.new(bodyEnd - bodyStart, width, width),
		along(bodyStart, bodyEnd),
		color,
		Glass,
		0.25
	)
	piece(
		root,
		"Shoulder",
		Cylinder,
		Vector3.new(shoulderEnd - bodyEnd, width * 0.62, width * 0.62),
		along(bodyEnd, shoulderEnd),
		color,
		Glass,
		0.25
	)
	piece(
		root,
		"Neck",
		Cylinder,
		Vector3.new(neckEnd - shoulderEnd, width * 0.37, width * 0.37),
		along(shoulderEnd, neckEnd),
		color,
		Glass,
		0.25
	)
	piece(
		root,
		"Cork",
		Cylinder,
		Vector3.new(corkEnd - neckEnd, width * 0.5, width * 0.5),
		along(neckEnd, corkEnd),
		M.Cork,
		Wood
	)
	if detail then
		detail(bodyStart, bodyEnd)
	end
end

-- A wooden crate of `size` studs, with corner posts and two straps across the lid.
local function crate(root: BasePart, size: number, color: Color3)
	local half = size / 2
	local post = shade(color, -0.25)
	piece(
		root,
		"Planks",
		Block,
		Vector3.new(size - 0.12, size - 0.12, size - 0.12),
		CFrame.new(),
		color,
		WoodPlanks
	)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			piece(
				root,
				"Post",
				Block,
				Vector3.new(0.22, size, 0.22),
				CFrame.new(x * (half - 0.11), 0, z * (half - 0.11)),
				post,
				Wood
			)
		end
	end
	local inner = half - 0.25
	bar(root, "StrapA", Vector3.new(-inner, half, -inner), Vector3.new(inner, half, inner), 0.12, post, Wood)
	bar(root, "StrapB", Vector3.new(inner, half, -inner), Vector3.new(-inner, half, inner), 0.12, post, Wood)
end

-- A closed ring of bars lying in the XZ plane of `frame` (which is in the root's frame).
local function loop(
	root: BasePart,
	name: string,
	frame: CFrame,
	radius: number,
	steps: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?
)
	for step = 1, steps do
		local a0 = (step - 1) / steps * 2 * math.pi
		local a1 = step / steps * 2 * math.pi
		local p0 = frame * Vector3.new(radius * math.cos(a0), 0, radius * math.sin(a0))
		local p1 = frame * Vector3.new(radius * math.cos(a1), 0, radius * math.sin(a1))
		-- Run each bar a little past its corners, so the ring has no gaps.
		local overrun = (p1 - p0).Unit * thickness / 2
		bar(root, name, p0 - overrun, p1 + overrun, thickness, color, material)
	end
end

-- A crystal with a diamond cross-section, from `at` out along at's -Z, ending in a point.
local function crystal(
	root: BasePart,
	name: string,
	at: CFrame,
	width: number,
	length: number,
	tip: number,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	local frame = at * CFrame.Angles(0, 0, math.pi / 4)
	piece(
		root,
		name,
		Block,
		Vector3.new(width, width, length),
		frame * CFrame.new(0, 0, -length / 2),
		color,
		material,
		transparency
	)
	-- Two wedges back to back make the point.
	for _, flip in { 0, math.pi } do
		piece(
			root,
			name .. "Tip",
			Wedge,
			Vector3.new(width, width / 2, tip),
			frame
				* CFrame.new(0, 0, -length - tip / 2)
				* CFrame.Angles(0, 0, flip)
				* CFrame.new(0, width / 4, 0),
			color,
			material,
			transparency
		)
	end
end

builders.Seashell = function(root, def)
	local color = def.Color
	-- A scallop lying flat: a fan of ribs spreading from the hinge, two shades alternating,
	-- taller in the middle.
	for index = 0, 6 do
		local degrees = -60 + index * 20
		local height = 0.16 - math.abs(degrees) / 60 * 0.06
		piece(
			root,
			"Rib" .. index,
			Block,
			Vector3.new(0.22, height, 0.7),
			CFrame.new(0, -0.25 + height / 2, 0.45)
				* CFrame.Angles(0, math.rad(degrees), 0)
				* CFrame.new(0, 0, -0.34),
			if index % 2 == 0 then color else shade(color, 0.45)
		)
	end
	piece(root, "Hinge", Ball, Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, -0.14, 0.48), shade(color, -0.2))
end

builders.GlassBottle = function(root, def)
	local width = def.Size.Y
	bottle(root, def.Color, def.Size.X / 2, width, function(from, to)
		-- A paper label on the side that faces the camera.
		piece(
			root,
			"Label",
			Block,
			Vector3.new((to - from) * 0.5, width * 0.5, 0.03),
			along(from, to) * CFrame.new(0, 0, -width / 2),
			M.Label
		)
	end)
end

builders.MessageBottle = function(root, def)
	local width = def.Size.Y
	local half = def.Size.X / 2
	bottle(root, def.Color, half, width, function(from, to)
		-- The rolled message inside, and a red ribbon tied round the neck.
		piece(
			root,
			"Message",
			Cylinder,
			Vector3.new((to - from) * 0.8, width * 0.45, width * 0.45),
			along(from, to),
			M.Paper
		)
		piece(
			root,
			"Ribbon",
			Cylinder,
			Vector3.new(0.1, width * 0.52, width * 0.52),
			CFrame.new(half * 0.74, 0, 0),
			M.Wax,
			Smooth
		)
	end)
end

builders.FlipFlop = function(root, def)
	local color = def.Color
	piece(root, "Sole", Block, Vector3.new(0.8, 0.2, 1.7), CFrame.new(0, -0.025, 0), color)
	-- A pale thong that splits from the toe post to the heel.
	local strap = shade(color, 0.55)
	local post = Vector3.new(0, 0.09, -0.1)
	bar(root, "StrapLeft", post, Vector3.new(-0.28, 0.09, 0.55), 0.1, strap)
	bar(root, "StrapRight", post, Vector3.new(0.28, 0.09, 0.55), 0.1, strap)
	piece(root, "Post", Ball, Vector3.new(0.14, 0.14, 0.14), CFrame.new(post), strap)
end

builders.Sunglasses = function(root, def)
	local color = def.Color
	for _, side in { -1, 1 } do
		local x = side * 0.36
		piece(
			root,
			"Lens",
			Block,
			Vector3.new(0.6, 0.3, 0.06),
			CFrame.new(x, 0, -0.2),
			M.Sunglasses,
			Glass,
			0.15
		)
		bar(
			root,
			"RimTop",
			Vector3.new(x - 0.3, 0.16, -0.2),
			Vector3.new(x + 0.3, 0.16, -0.2),
			0.06,
			color,
			Smooth
		)
		bar(
			root,
			"RimBottom",
			Vector3.new(x - 0.3, -0.16, -0.2),
			Vector3.new(x + 0.3, -0.16, -0.2),
			0.06,
			color,
			Smooth
		)
		bar(
			root,
			"Temple",
			Vector3.new(side * 0.68, 0.1, -0.2),
			Vector3.new(side * 0.68, 0.1, 0.22),
			0.06,
			color,
			Smooth
		)
	end
	bar(root, "Bridge", Vector3.new(-0.06, 0.08, -0.2), Vector3.new(0.06, 0.08, -0.2), 0.06, color, Smooth)
end

builders.Pearl = function(root, def)
	piece(root, "Pearl", Ball, def.Size, CFrame.new(), def.Color)
	-- A small bright glint, so it reads as a pearl and not a ball.
	piece(root, "Glint", Ball, Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.18, 0.22, 0.15), M.Glint, Neon)
end

builders.BeachBall = function(root, def)
	local size = def.Size.X
	piece(root, "Panel", Ball, def.Size, CFrame.new(), def.Color)
	-- Three white rings round the ball, like the seams between its panels.
	local band = Vector3.new(0.2, size + 0.04, size + 0.04)
	piece(root, "SeamX", Cylinder, band, CFrame.new(), M.White)
	piece(root, "SeamY", Cylinder, band, ALONG_Y, M.White)
	piece(root, "SeamZ", Cylinder, band, ALONG_Z, M.White)
	-- A yellow cap on one pole and a blue one on the other.
	local cap = Vector3.new(0.14, size * 0.34, size * 0.34)
	piece(root, "CapTop", Cylinder, cap, CFrame.new(0, size / 2 - 0.05, 0) * ALONG_Y, M.Sun)
	piece(root, "CapBottom", Cylinder, cap, CFrame.new(0, -(size / 2 - 0.05), 0) * ALONG_Y, M.Aqua)
end

builders.GoldenSpade = function(root, def)
	local color = def.Color
	piece(root, "Blade", Block, Vector3.new(0.56, 0.08, 1.0), CFrame.new(0, 0, -0.8), color, Foil)
	-- A rounded front edge on the blade.
	piece(root, "Tip", Cylinder, Vector3.new(0.08, 0.56, 0.56), CFrame.new(0, 0, -1.0) * ALONG_Y, color, Foil)
	piece(root, "Shaft", Block, Vector3.new(0.16, 0.16, 1.7), CFrame.new(0, 0, 0.45), color, Foil)
	piece(root, "Grip", Block, Vector3.new(0.42, 0.2, 0.2), CFrame.new(0, 0, 1.2), color, Foil)
end

builders.CaptainsKey = function(root, def)
	local color = def.Color
	-- The bow is a ring: a disc with a dark eye through it.
	piece(root, "Bow", Cylinder, Vector3.new(0.3, 0.6, 0.6), CFrame.new(0, 0, -0.55) * ALONG_Y, color, Metal)
	piece(root, "Eye", Cylinder, Vector3.new(0.34, 0.32, 0.32), CFrame.new(0, 0, -0.55) * ALONG_Y, M.Hole)
	piece(root, "Shaft", Block, Vector3.new(0.16, 0.18, 1.2), CFrame.new(0, 0, 0.3), color, Metal)
	piece(root, "ToothA", Block, Vector3.new(0.14, 0.2, 0.2), CFrame.new(0.1, 0, 0.6), color, Metal)
	piece(root, "ToothB", Block, Vector3.new(0.14, 0.2, 0.2), CFrame.new(0.1, 0, 0.85), color, Metal)
end

builders.BeaconPearl = function(root, def)
	piece(root, "Core", Ball, def.Size, CFrame.new(), def.Color, Neon)
	-- A soft halo round the glowing core, and a ring of sparks circling it.
	piece(root, "Halo", Ball, def.Size * 1.4, CFrame.new(), M.Glow, Glass, 0.6)
	for step = 0, 7 do
		local angle = step * math.pi / 4
		piece(
			root,
			"Spark",
			Ball,
			Vector3.new(0.13, 0.13, 0.13),
			CFrame.new(math.cos(angle) * 0.78, 0.05, math.sin(angle) * 0.78),
			M.Sun,
			Neon
		)
	end
end

builders.Bucket = function(root, def)
	local color = def.Color
	local width = def.Size.Y
	piece(root, "Body", Cylinder, Vector3.new(1.35, width * 0.94, width * 0.94), along(-0.8, 0.55), color)
	-- A blue band round the middle, and a white plastic rim and handle.
	piece(
		root,
		"Band",
		Cylinder,
		Vector3.new(0.32, width * 0.96, width * 0.96),
		CFrame.new(-0.2, 0, 0),
		M.Aqua
	)
	piece(root, "Rim", Cylinder, Vector3.new(0.1, width, width), CFrame.new(0.6, 0, 0), M.White)
	piece(
		root,
		"Mouth",
		Cylinder,
		Vector3.new(0.03, width * 0.8, width * 0.8),
		CFrame.new(0.66, 0, 0),
		shade(color, -0.45)
	)
	arc(root, "Handle", Vector2.new(-0.1, 0), 0.9, 25, 155, 0.09, M.White, Smooth)
end

builders.SmallCrate = function(root, def)
	crate(root, def.Size.X, def.Color)
end

builders.BigCrate = function(root, def)
	crate(root, def.Size.X, def.Color)
end

builders.Lantern = function(root, def)
	local color = def.Color
	piece(
		root,
		"Base",
		Block,
		Vector3.new(0.9, 0.14, 0.9),
		CFrame.new(0, -0.93, 0),
		shade(color, -0.2),
		Metal
	)
	piece(
		root,
		"Cage",
		Block,
		Vector3.new(0.82, 1.4, 0.82),
		CFrame.new(0, -0.1, 0),
		M.LanternGlass,
		Glass,
		0.45
	)
	for _, x in { -0.4, 0.4 } do
		for _, z in { -0.4, 0.4 } do
			bar(root, "Post", Vector3.new(x, -0.9, z), Vector3.new(x, 0.7, z), 0.08, color, Metal)
		end
	end
	piece(root, "Roof", Block, Vector3.new(1.08, 0.12, 1.08), CFrame.new(0, 0.66, 0), color, Metal)
	piece(root, "Cap", Block, Vector3.new(0.6, 0.22, 0.6), CFrame.new(0, 0.83, 0), color, Metal)
	local flame =
		piece(root, "Flame", Ball, Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, -0.15, 0), M.Flame, Neon)
	arc(root, "Handle", Vector2.new(0, 0.6), 0.5, 15, 165, 0.07, color)
	-- A warm glow, so it's a lantern you can find at dusk.
	local light = Instance.new("PointLight")
	light.Color = M.Flame
	light.Range = 10
	light.Brightness = 1.3
	light.Parent = flame
end

builders.Spyglass = function(root, def)
	local color = def.Color
	local width = def.Size.Y
	local ring = shade(color, -0.3)
	piece(
		root,
		"Eyepiece",
		Cylinder,
		Vector3.new(0.06, width * 0.55, width * 0.55),
		CFrame.new(-1.27, 0, 0),
		M.SpyLens,
		Glass,
		0.25
	)
	piece(root, "Barrel", Cylinder, Vector3.new(0.9, width, width), along(-1.25, -0.35), color, Metal)
	piece(
		root,
		"BandA",
		Cylinder,
		Vector3.new(0.1, width * 1.08, width * 1.08),
		CFrame.new(-0.35, 0, 0),
		ring,
		Metal
	)
	piece(
		root,
		"Middle",
		Cylinder,
		Vector3.new(0.8, width * 0.8, width * 0.8),
		along(-0.3, 0.5),
		color,
		Metal
	)
	piece(
		root,
		"BandB",
		Cylinder,
		Vector3.new(0.08, width * 0.9, width * 0.9),
		CFrame.new(0.5, 0, 0),
		ring,
		Metal
	)
	piece(
		root,
		"Tip",
		Cylinder,
		Vector3.new(0.7, width * 0.63, width * 0.63),
		along(0.55, 1.25),
		color,
		Metal
	)
	piece(
		root,
		"Lens",
		Cylinder,
		Vector3.new(0.06, width * 0.57, width * 0.57),
		CFrame.new(1.27, 0, 0),
		M.SpyLens,
		Glass,
		0.25
	)
end

builders.ShipBell = function(root, def)
	local color = def.Color
	-- Lying with its mouth towards +X: crown, body, flared lip, and the dark mouth.
	piece(
		root,
		"Crown",
		Cylinder,
		Vector3.new(0.3, 1.0, 1.0),
		CFrame.new(-0.8, 0, 0),
		shade(color, 0.1),
		Metal
	)
	piece(root, "Body", Cylinder, Vector3.new(1.2, 1.8, 1.8), CFrame.new(-0.2, 0, 0), color, Metal)
	piece(root, "Lip", Cylinder, Vector3.new(0.3, 2.2, 2.2), CFrame.new(0.65, 0, 0), color, Metal)
	piece(root, "Mouth", Cylinder, Vector3.new(0.04, 1.7, 1.7), CFrame.new(0.79, 0, 0), shade(color, -0.6))
end

builders.Barrel = function(root, def)
	local color = def.Color
	local width = def.Size.Y
	piece(root, "Staves", Cylinder, Vector3.new(2.7, width, width), CFrame.new(), color, Wood)
	for _, x in { -0.9, 0, 0.9 } do
		piece(
			root,
			"Hoop",
			Cylinder,
			Vector3.new(0.14, width * 1.03, width * 1.03),
			CFrame.new(x, 0, 0),
			M.Iron,
			Metal
		)
	end
	for _, x in { -1.4, 1.4 } do
		piece(
			root,
			"End",
			Cylinder,
			Vector3.new(0.1, width * 0.96, width * 0.96),
			CFrame.new(x, 0, 0),
			shade(color, -0.2),
			Wood
		)
	end
	-- The bung, on top.
	piece(
		root,
		"Bung",
		Cylinder,
		Vector3.new(0.2, 0.3, 0.3),
		CFrame.new(0.6, width / 2, 0) * ALONG_Y,
		shade(color, -0.5),
		Wood
	)
end

builders.Anchor = function(root, def)
	local color = def.Color
	bar(root, "Shank", Vector3.new(0, -1.2, 0), Vector3.new(0, 1.4, 0), 0.36, color, Rust)
	bar(root, "Stock", Vector3.new(-1.0, 1.25, 0), Vector3.new(1.0, 1.25, 0), 0.36, color, Rust)
	piece(root, "Eye", Ball, Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 1.5, 0), color, Rust)
	-- Two curved arms, each ending in a flat blade.
	for _, side in { -1, 1 } do
		local previous = Vector3.new(0, -1.25, 0)
		for _, point in { Vector3.new(0.5, -1.4, 0), Vector3.new(0.95, -1.15, 0), Vector3.new(1.15, -0.7, 0) } do
			local target = Vector3.new(point.X * side, point.Y, 0)
			bar(root, "Arm", previous, target, 0.34, color, Rust)
			previous = target
		end
		piece(
			root,
			"Blade",
			Block,
			Vector3.new(0.5, 0.5, 0.3),
			CFrame.new(1.1 * side, -0.62, 0) * CFrame.Angles(0, 0, math.rad(-25 * side)),
			color,
			Rust
		)
	end
end

builders.ShipWheel = function(root, def)
	local color = def.Color
	local width = def.Size.Y
	-- A disc standing on its edge: wooden rim, dark hole, spokes on the front face.
	piece(root, "Rim", Cylinder, Vector3.new(0.4, width, width), CFrame.new(), color, Wood)
	piece(
		root,
		"Hole",
		Cylinder,
		Vector3.new(0.46, width * 0.76, width * 0.76),
		CFrame.new(),
		shade(color, -0.6)
	)
	local face = 0.27
	piece(
		root,
		"Hub",
		Cylinder,
		Vector3.new(0.3, 0.7, 0.7),
		CFrame.new(face, 0, 0),
		shade(color, -0.2),
		Metal
	)
	for step = 0, 7 do
		local angle = step * math.pi / 4
		local tip = Vector3.new(face, math.cos(angle) * 1.45, math.sin(angle) * 1.45)
		bar(root, "Spoke", Vector3.new(face, 0, 0), tip, 0.16, color, Wood)
		piece(root, "Handle", Ball, Vector3.new(0.3, 0.3, 0.3), CFrame.new(tip), color, Wood)
	end
end

builders.CarvedIdol = function(root, def)
	local color = def.Color
	local dark = shade(color, -0.35)
	piece(root, "Base", Block, Vector3.new(0.7, 0.15, 0.7), CFrame.new(0, -0.725, 0), dark, Wood)
	piece(root, "Body", Block, Vector3.new(0.52, 0.95, 0.48), CFrame.new(0, -0.175, 0), color, Wood)
	for _, side in { -1, 1 } do
		piece(root, "Arm", Block, Vector3.new(0.1, 0.55, 0.3), CFrame.new(side * 0.3, -0.05, 0), dark, Wood)
	end
	piece(root, "Head", Block, Vector3.new(0.62, 0.48, 0.56), CFrame.new(0, 0.52, 0), color, Wood)
	piece(root, "Crest", Block, Vector3.new(0.3, 0.06, 0.3), CFrame.new(0, 0.77, 0), dark, Wood)
	-- A carved face on the front (-Z): heavy brow, deep eyes, a wide mouth.
	local front = -0.29
	piece(root, "Brow", Block, Vector3.new(0.5, 0.08, 0.06), CFrame.new(0, 0.64, front), dark, Wood)
	for _, side in { -1, 1 } do
		piece(root, "Eye", Block, Vector3.new(0.12, 0.08, 0.04), CFrame.new(side * 0.14, 0.55, front), M.Hole)
	end
	piece(root, "Nose", Block, Vector3.new(0.08, 0.14, 0.06), CFrame.new(0, 0.46, front), dark, Wood)
	piece(root, "Mouth", Block, Vector3.new(0.3, 0.05, 0.04), CFrame.new(0, 0.35, front), M.Hole)
end

builders.PearlEyedShell = function(root, def)
	local color = def.Color
	local rib = shade(color, -0.15)
	-- A clam, slightly open at the front (-Z), hinged at the back.
	piece(root, "Bottom", Cylinder, Vector3.new(0.12, 1.1, 1.1), CFrame.new(0, -0.22, 0) * ALONG_Y, color)
	local lid = CFrame.new(0, -0.15, 0.55) * CFrame.Angles(math.rad(25), 0, 0)
	piece(root, "Top", Cylinder, Vector3.new(0.1, 1.1, 1.1), lid * CFrame.new(0, 0, -0.55) * ALONG_Y, color)
	for index, degrees in { -40, -20, 0, 20, 40 } do
		piece(
			root,
			"Rib" .. index,
			Block,
			Vector3.new(0.08, 0.06, 0.7),
			lid * CFrame.Angles(0, math.rad(degrees), 0) * CFrame.new(0, 0.06, -0.4),
			rib
		)
	end
	-- The pearl inside, with a dark pupil looking out: the eye.
	piece(root, "Pearl", Ball, Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, -0.05, -0.05), M.White)
	piece(root, "Pupil", Ball, Vector3.new(0.13, 0.13, 0.13), CFrame.new(0, -0.03, -0.19), M.Hole)
	piece(root, "Glint", Ball, Vector3.new(0.06, 0.06, 0.06), CFrame.new(0.07, 0.05, -0.2), M.Glint, Neon)
end

builders.BarnacledLantern = function(root, def)
	local color = def.Color
	piece(root, "Base", Block, Vector3.new(0.8, 0.12, 0.8), CFrame.new(0, -0.64, 0), shade(color, -0.2), Rust)
	piece(
		root,
		"Cage",
		Block,
		Vector3.new(0.7, 1.0, 0.7),
		CFrame.new(0, -0.08, 0),
		shade(M.LanternGlass, -0.3),
		Glass,
		0.5
	)
	for _, x in { -0.34, 0.34 } do
		for _, z in { -0.34, 0.34 } do
			bar(root, "Post", Vector3.new(x, -0.6, z), Vector3.new(x, 0.42, z), 0.07, color, Rust)
		end
	end
	piece(root, "Roof", Block, Vector3.new(0.9, 0.1, 0.9), CFrame.new(0, 0.45, 0), color, Rust)
	piece(root, "Cap", Block, Vector3.new(0.5, 0.15, 0.5), CFrame.new(0, 0.57, 0), color, Rust)
	-- A dim, sea-green glow that never quite went out.
	piece(
		root,
		"Flame",
		Ball,
		Vector3.new(0.22, 0.22, 0.22),
		CFrame.new(0, -0.15, 0),
		shade(color, 0.5),
		Neon
	)
	arc(root, "Handle", Vector2.new(0, 0.57), 0.14, 0, 180, 0.05, color)
	-- Barnacles crusted on the posts and roof.
	for index, at in
		{
			Vector3.new(0.34, -0.3, -0.36),
			Vector3.new(0.38, 0.1, 0.34),
			Vector3.new(-0.36, -0.5, 0.3),
			Vector3.new(-0.3, 0.48, -0.3),
			Vector3.new(0.2, 0.5, 0.35),
			Vector3.new(-0.4, -0.62, -0.25),
		}
	do
		local size = 0.1 + (index % 3) * 0.03
		piece(root, "Barnacle", Ball, Vector3.new(size, size, size), CFrame.new(at), M.Barnacle, Rock)
	end
end

builders.CoralComb = function(root, def)
	local color = def.Color
	piece(root, "Spine", Block, Vector3.new(1.4, 0.2, 0.26), CFrame.new(0, 0, -0.27), color)
	for step = 0, 10 do
		local x = -0.6 + step * 0.12
		piece(
			root,
			"Tooth",
			Block,
			Vector3.new(0.06, 0.12, 0.52),
			CFrame.new(x, -0.02, 0.13),
			shade(color, 0.1)
		)
	end
	-- Little coral knobs along the spine.
	for _, x in { -0.45, -0.1, 0.25, 0.55 } do
		piece(root, "Knob", Ball, Vector3.new(0.16, 0.16, 0.16), CFrame.new(x, 0.05, -0.3), shade(color, 0.3))
	end
end

builders.JellyJar = function(root, def)
	local color = def.Color
	local width = math.min(def.Size.Y, def.Size.Z)
	-- Lying on its side along X, like the bottles: glass jar, a lid at +X.
	piece(
		root,
		"Jar",
		Cylinder,
		Vector3.new(0.68, width * 0.92, width * 0.92),
		along(-0.45, 0.23),
		color,
		Glass,
		0.55
	)
	piece(
		root,
		"Neck",
		Cylinder,
		Vector3.new(0.06, width * 0.75, width * 0.75),
		along(0.23, 0.29),
		color,
		Glass,
		0.4
	)
	piece(
		root,
		"Lid",
		Cylinder,
		Vector3.new(0.15, width * 0.85, width * 0.85),
		along(0.29, 0.44),
		M.Cork,
		Wood
	)
	-- The jellyfish: a glowing bell trailing tentacles.
	piece(root, "Bell", Ball, Vector3.new(0.4, 0.4, 0.4), CFrame.new(0.02, 0, 0), M.Jelly, Neon)
	for _, offset in { Vector3.new(0, 0.1, 0), Vector3.new(0, -0.1, 0.06), Vector3.new(0, 0, -0.1) } do
		bar(
			root,
			"Tentacle",
			offset + Vector3.new(-0.1, 0, 0),
			offset + Vector3.new(-0.38, 0, 0),
			0.04,
			M.Jelly,
			Neon
		)
	end
end

builders.LighthouseKey = function(root, def)
	local color = def.Color
	-- Lying flat along Z. The bow is a ring with a lamp-bright eye.
	piece(root, "Bow", Cylinder, Vector3.new(0.2, 0.5, 0.5), CFrame.new(0, 0, -0.72) * ALONG_Y, color, Metal)
	piece(
		root,
		"Eye",
		Cylinder,
		Vector3.new(0.24, 0.26, 0.26),
		CFrame.new(0, 0, -0.72) * ALONG_Y,
		M.Flame,
		Neon
	)
	piece(root, "Finial", Ball, Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 0, -0.98), M.Gold, Metal)
	piece(root, "Collar", Block, Vector3.new(0.3, 0.22, 0.08), CFrame.new(0, 0, -0.42), M.Gold, Metal)
	piece(root, "Shaft", Block, Vector3.new(0.14, 0.16, 1.3), CFrame.new(0, 0, 0.23), color, Metal)
	piece(root, "BandA", Block, Vector3.new(0.18, 0.2, 0.06), CFrame.new(0, 0, 0.0), M.Gold, Metal)
	-- The bit, with three teeth.
	piece(root, "ToothA", Block, Vector3.new(0.16, 0.16, 0.14), CFrame.new(0.14, 0, 0.6), color, Metal)
	piece(root, "ToothB", Block, Vector3.new(0.1, 0.16, 0.1), CFrame.new(0.12, 0, 0.74), color, Metal)
	piece(root, "ToothC", Block, Vector3.new(0.16, 0.16, 0.12), CFrame.new(0.14, 0, 0.86), color, Metal)
end

builders.WindChime = function(root, def)
	local color = def.Color
	arc(root, "Hook", Vector2.new(0, 0.6), 0.14, 0, 180, 0.05, color)
	piece(
		root,
		"Top",
		Cylinder,
		Vector3.new(0.1, 0.8, 0.8),
		CFrame.new(0, 0.55, 0) * ALONG_Y,
		shade(color, -0.4),
		Wood
	)
	-- Five tubes of different lengths hanging round the ring.
	for index, length in { 0.9, 0.75, 0.62, 0.7, 0.82 } do
		local angle = index * 2 * math.pi / 5
		local x, z = math.cos(angle) * 0.28, math.sin(angle) * 0.28
		bar(root, "String", Vector3.new(x, 0.5, z), Vector3.new(x, 0.32, z), 0.02, M.Paper)
		piece(
			root,
			"Tube",
			Cylinder,
			Vector3.new(length, 0.1, 0.1),
			CFrame.new(x, 0.32 - length / 2, z) * ALONG_Y,
			color,
			Metal
		)
	end
	-- The striker in the middle and the sail that catches the wind.
	bar(root, "Cord", Vector3.new(0, 0.5, 0), Vector3.new(0, -0.45, 0), 0.02, M.Paper)
	piece(
		root,
		"Striker",
		Cylinder,
		Vector3.new(0.06, 0.3, 0.3),
		CFrame.new(0, -0.05, 0) * ALONG_Y,
		shade(color, -0.4),
		Wood
	)
	piece(root, "Sail", Block, Vector3.new(0.3, 0.3, 0.04), CFrame.new(0, -0.6, 0), shade(color, -0.4), Wood)
end

builders.SpiralConch = function(root, def)
	local color = def.Color
	local ridge = shade(color, -0.2)
	-- Whorls shrinking towards the spire at -Z, each twisted a little round the axis.
	for index, whorl in { { 0.95, 0.3 }, { 0.72, -0.15 }, { 0.52, -0.47 }, { 0.36, -0.68 }, { 0.22, -0.8 } } do
		local size, z = whorl[1], whorl[2]
		local angle = index * 2
		local at = CFrame.new(math.sin(angle) * 0.05, (index - 1) * 0.03, z)
		piece(root, "Whorl", Ball, Vector3.new(size, size, size), at, color)
		piece(root, "Ridge", Cylinder, Vector3.new(0.05, size * 1.01, size * 1.01), at * ALONG_Z, ridge)
	end
	-- The canal at the front and the pink lip of the opening.
	bar(root, "Canal", Vector3.new(0, -0.05, 0.5), Vector3.new(0.02, -0.12, 0.86), 0.22, color)
	piece(root, "Lip", Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0.27, -0.08, 0.4), shade(M.Glint, -0.05))
	piece(
		root,
		"Opening",
		Ball,
		Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(0.36, -0.1, 0.4),
		shade(M.Glint, -0.3)
	)
end

builders.SpearstoneShard = function(root, def)
	local color = def.Color
	crystal(root, "Blade", CFrame.new(0, 0, 0.9), 0.4, 1.4, 0.6, color, Rock)
	-- A lighter edge catching the light along the ridge.
	piece(
		root,
		"Edge",
		Block,
		Vector3.new(0.05, 0.05, 1.35),
		CFrame.new(0, 0.28, 0.2),
		shade(color, 0.35),
		Rock
	)
	crystal(
		root,
		"SplinterA",
		CFrame.new(0.08, 0, 0.6) * CFrame.Angles(0, math.rad(-28), 0),
		0.16,
		0.22,
		0.15,
		shade(color, 0.15),
		Rock
	)
	crystal(
		root,
		"SplinterB",
		CFrame.new(-0.08, 0.05, 0.1) * CFrame.Angles(0, math.rad(30), 0),
		0.14,
		0.2,
		0.12,
		shade(color, 0.15),
		Rock
	)
	piece(root, "Butt", Ball, Vector3.new(0.38, 0.38, 0.38), CFrame.new(0, 0, 0.9), shade(color, -0.3), Rock)
end

builders.PrismShard = function(root, def)
	local color = def.Color
	-- A cluster of crystals pointing up out of a rock.
	local up = CFrame.Angles(math.pi / 2, 0, 0)
	piece(root, "Rock", Block, Vector3.new(0.6, 0.16, 0.55), CFrame.new(0, -0.62, 0), M.Rock, Rock)
	crystal(root, "Main", CFrame.new(0, -0.6, 0) * up, 0.34, 0.85, 0.4, color, Glass, 0.2)
	piece(root, "Core", Block, Vector3.new(0.08, 0.8, 0.08), CFrame.new(0, -0.15, 0), shade(color, 0.4), Neon)
	crystal(
		root,
		"Side",
		CFrame.new(0.08, -0.55, 0.05) * CFrame.Angles(0, 0, math.rad(-18)) * up,
		0.2,
		0.4,
		0.2,
		shade(color, 0.2),
		Glass,
		0.2
	)
	crystal(
		root,
		"Side",
		CFrame.new(-0.07, -0.55, -0.06) * CFrame.Angles(math.rad(-12), 0, math.rad(18)) * up,
		0.16,
		0.3,
		0.16,
		shade(color, -0.15),
		Glass,
		0.2
	)
end

builders.FrozenCompass = function(root, def)
	local flat = ALONG_Y
	-- A brass compass lying flat, its needle under glass, all locked in a disc of ice.
	piece(
		root,
		"Case",
		Cylinder,
		Vector3.new(0.22, 0.86, 0.86),
		CFrame.new(0, -0.06, 0) * flat,
		M.Gold,
		Metal
	)
	piece(root, "Face", Cylinder, Vector3.new(0.02, 0.72, 0.72), CFrame.new(0, 0.06, 0) * flat, M.Label)
	piece(root, "North", Block, Vector3.new(0.06, 0.03, 0.3), CFrame.new(0, 0.085, -0.15), M.Needle)
	piece(root, "South", Block, Vector3.new(0.06, 0.03, 0.3), CFrame.new(0, 0.085, 0.15), M.Iron)
	piece(root, "Pivot", Ball, Vector3.new(0.08, 0.08, 0.08), CFrame.new(0, 0.09, 0), M.Gold, Metal)
	piece(
		root,
		"Lid",
		Cylinder,
		Vector3.new(0.04, 0.74, 0.74),
		CFrame.new(0, 0.12, 0) * flat,
		M.SpyLens,
		Glass,
		0.6
	)
	piece(root, "Ice", Cylinder, Vector3.new(0.38, 1.1, 1.1), flat, def.Color, Glass, 0.6)
	for _, chunk in { { 0.4, 0.1, -0.25, 30 }, { -0.35, 0.08, 0.3, -20 }, { -0.1, 0.12, -0.42, 55 } } do
		piece(
			root,
			"Chunk",
			Block,
			Vector3.new(0.22, 0.14, 0.18),
			CFrame.new(chunk[1], chunk[2], chunk[3]) * CFrame.Angles(0, math.rad(chunk[4]), math.rad(15)),
			shade(def.Color, 0.3),
			Glass,
			0.3
		)
	end
end

builders.ObsidianEgg = function(root, def)
	local color = def.Color
	-- An egg: a wide ball with a smaller one on top.
	piece(root, "Lower", Ball, Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, -0.1, 0), color, Glass)
	piece(root, "Upper", Ball, Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 0.22, 0), color, Glass)
	-- Glowing cracks, as bars from point to point just over the shell.
	local function surface(angle: number, y: number): Vector3
		local lower = math.sqrt(math.max(0, 0.45 ^ 2 - (y + 0.1) ^ 2))
		local upper = math.sqrt(math.max(0, 0.35 ^ 2 - (y - 0.22) ^ 2))
		local radius = math.max(lower, upper) + 0.015
		return Vector3.new(radius * math.sin(angle), y, -radius * math.cos(angle))
	end
	for _, start in { 0, 2.1, 4.2 } do
		local points = {
			surface(start, 0.42),
			surface(start + 0.25, 0.22),
			surface(start - 0.1, 0.02),
			surface(start + 0.2, -0.2),
		}
		for index = 1, #points - 1 do
			bar(root, "Crack", points[index], points[index + 1], 0.05, M.Magma, Neon)
		end
	end
end

builders.Rope = function(root, def)
	local color = def.Color
	-- A coil: two rings flat on the bottom, two more on top of them.
	loop(root, "Coil", CFrame.new(0, -0.13, 0), 0.68, 10, 0.22, color, Fabric)
	loop(root, "Coil", CFrame.new(0, -0.13, 0), 0.46, 8, 0.22, shade(color, -0.08), Fabric)
	loop(root, "Coil", CFrame.new(0, 0.11, 0), 0.57, 9, 0.22, shade(color, 0.05), Fabric)
	loop(root, "Coil", CFrame.new(0, 0.11, 0), 0.33, 6, 0.22, shade(color, -0.04), Fabric)
	-- The loose end trailing off the coil.
	bar(root, "End", Vector3.new(0.5, -0.13, -0.3), Vector3.new(0.62, -0.15, -0.68), 0.2, color, Fabric)
end

builders.OldBoot = function(root, def)
	local color = def.Color
	-- Standing up, toe at -Z, heel at +Z.
	piece(root, "Sole", Block, Vector3.new(0.76, 0.12, 1.56), CFrame.new(0, -0.49, 0), shade(color, -0.55))
	piece(root, "Heel", Block, Vector3.new(0.7, 0.1, 0.4), CFrame.new(0, -0.4, 0.55), shade(color, -0.55))
	piece(root, "Foot", Block, Vector3.new(0.7, 0.4, 1.2), CFrame.new(0, -0.23, 0.1), color, Fabric)
	piece(root, "Toe", Cylinder, Vector3.new(0.7, 0.4, 0.4), CFrame.new(0, -0.23, -0.5), color, Fabric)
	piece(root, "Shaft", Block, Vector3.new(0.7, 0.75, 0.7), CFrame.new(0, 0.17, 0.4), color, Fabric)
	piece(
		root,
		"Cuff",
		Block,
		Vector3.new(0.74, 0.1, 0.74),
		CFrame.new(0, 0.5, 0.4),
		shade(color, -0.25),
		Fabric
	)
	piece(root, "Opening", Block, Vector3.new(0.56, 0.02, 0.56), CFrame.new(0, 0.55, 0.4), M.Hole)
	-- Laces criss-crossed up the front of the shaft.
	for index, y in { -0.02, 0.14, 0.3 } do
		local lean = if index % 2 == 0 then 1 else -1
		bar(
			root,
			"Lace",
			Vector3.new(-0.2, y - lean * 0.04, 0.04),
			Vector3.new(0.2, y + lean * 0.04, 0.04),
			0.04,
			M.Paper
		)
	end
	piece(
		root,
		"Patch",
		Block,
		Vector3.new(0.02, 0.2, 0.3),
		CFrame.new(0.36, -0.2, -0.1),
		shade(color, 0.2),
		Fabric
	)
end

builders.Coconut = function(root, def)
	local color = def.Color
	local size = def.Size.X
	piece(root, "Husk", Ball, def.Size, CFrame.new(), color)
	-- Ridges running from end to end.
	for _, degrees in { 0, 60, 120 } do
		piece(
			root,
			"Ridge",
			Cylinder,
			Vector3.new(0.05, size + 0.02, size + 0.02),
			CFrame.Angles(0, math.rad(degrees), 0) * ALONG_Z,
			shade(color, -0.25)
		)
	end
	-- The three dark eyes, in a triangle on one end.
	for _, direction in
		{ Vector3.new(-0.2, 0.62, -0.75), Vector3.new(0.2, 0.62, -0.75), Vector3.new(0, 0.85, -0.5) }
	do
		piece(
			root,
			"Eye",
			Ball,
			Vector3.new(0.15, 0.15, 0.15),
			CFrame.new(direction.Unit * (size / 2 - 0.02)),
			M.Hole
		)
	end
end

builders.Snorkel = function(root, def)
	local color = def.Color
	-- The tube standing up at +X, bending into a mouthpiece at the bottom.
	piece(root, "Tube", Cylinder, Vector3.new(1.45, 0.16, 0.16), CFrame.new(0.18, 0.12, 0) * ALONG_Y, color)
	piece(
		root,
		"Top",
		Cylinder,
		Vector3.new(0.1, 0.24, 0.24),
		CFrame.new(0.18, 0.85, 0) * ALONG_Y,
		shade(color, -0.2)
	)
	bar(root, "Bend", Vector3.new(0.18, -0.6, 0), Vector3.new(0.02, -0.78, 0), 0.16, color)
	piece(root, "Mouthpiece", Block, Vector3.new(0.18, 0.14, 0.24), CFrame.new(-0.04, -0.8, -0.08), M.Rubber)
	-- The mask clipped to the tube: rubber frame, glass lens, strap.
	piece(root, "Mask", Block, Vector3.new(0.36, 0.34, 0.12), CFrame.new(-0.1, 0.35, -0.08), M.Rubber)
	piece(
		root,
		"Lens",
		Block,
		Vector3.new(0.28, 0.24, 0.04),
		CFrame.new(-0.1, 0.36, -0.16),
		M.MaskGlass,
		Glass,
		0.3
	)
	bar(root, "Strap", Vector3.new(-0.28, 0.35, -0.05), Vector3.new(-0.28, 0.35, 0.22), 0.06, M.Rubber)
	piece(root, "Clip", Block, Vector3.new(0.1, 0.1, 0.1), CFrame.new(0.12, 0.35, -0.02), M.Rubber)
end

builders.Starfish = function(root, def)
	local color = def.Color
	local dots = shade(color, 0.35)
	piece(root, "Middle", Cylinder, Vector3.new(0.22, 0.5, 0.5), ALONG_Y, color)
	for arm = 0, 4 do
		local turn = CFrame.Angles(0, arm * 2 * math.pi / 5, 0)
		piece(root, "Arm", Block, Vector3.new(0.3, 0.18, 0.45), turn * CFrame.new(0, -0.01, -0.32), color)
		piece(root, "ArmTip", Block, Vector3.new(0.18, 0.13, 0.3), turn * CFrame.new(0, -0.03, -0.64), color)
		for _, distance in { 0.3, 0.55 } do
			piece(
				root,
				"Dot",
				Ball,
				Vector3.new(0.08, 0.08, 0.08),
				turn * CFrame.new(0, 0.07, -distance),
				dots
			)
		end
	end
end

builders.FishingLure = function(root, def)
	local color = def.Color
	-- A little fish along Z, nose at -Z, with a white stripe and two treble hooks.
	piece(root, "Body", Cylinder, Vector3.new(0.5, 0.28, 0.28), CFrame.new(0, 0, 0) * ALONG_Z, color)
	piece(root, "Nose", Ball, Vector3.new(0.28, 0.28, 0.28), CFrame.new(0, 0, -0.25), color)
	piece(root, "Stripe", Cylinder, Vector3.new(0.08, 0.3, 0.3), CFrame.new(0, 0, -0.05) * ALONG_Z, M.White)
	piece(root, "Tail", Block, Vector3.new(0.03, 0.24, 0.16), CFrame.new(0, 0, 0.32), shade(color, -0.2))
	for _, side in { -1, 1 } do
		piece(root, "Eye", Ball, Vector3.new(0.07, 0.07, 0.07), CFrame.new(side * 0.11, 0.05, -0.3), M.Hole)
	end
	piece(
		root,
		"Bill",
		Block,
		Vector3.new(0.16, 0.02, 0.14),
		CFrame.new(0, -0.08, -0.43) * CFrame.Angles(math.rad(30), 0, 0),
		M.MaskGlass,
		Glass,
		0.4
	)
	for _, z in { -0.05, 0.4 } do
		local y = if z > 0.3 then 0 else -0.14
		local top = Vector3.new(0, y, z)
		local bottom = Vector3.new(0, -0.19, z + 0.04)
		bar(root, "Hook", top, bottom, 0.025, M.Iron, Metal)
		for _, degrees in { 0, 120, 240 } do
			local angle = math.rad(degrees)
			local barb = bottom + Vector3.new(math.sin(angle) * 0.06, 0.04, math.cos(angle) * 0.06)
			bar(root, "Barb", bottom, barb, 0.02, M.Iron, Metal)
		end
	end
end

builders.GlassFloat = function(root, def)
	local color = def.Color
	piece(root, "Glass", Ball, Vector3.new(1.0, 1.0, 1.0), CFrame.new(), color, Glass, 0.3)
	-- The rope net round it: one ring round the middle, two over the top.
	loop(root, "Net", CFrame.new(), 0.51, 10, 0.04, M.Cork, Fabric)
	loop(root, "Net", CFrame.Angles(math.pi / 2, 0, 0), 0.51, 10, 0.04, M.Cork, Fabric)
	loop(root, "Net", CFrame.Angles(math.pi / 2, math.pi / 2, 0), 0.51, 10, 0.04, M.Cork, Fabric)
	piece(root, "Knot", Ball, Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, 0.53, 0), M.Cork, Fabric)
end

builders.Coral = function(root, def)
	local color = def.Color
	local tips = shade(color, 0.3)
	piece(
		root,
		"Rock",
		Cylinder,
		Vector3.new(0.16, 0.7, 0.7),
		CFrame.new(0, -0.62, 0) * ALONG_Y,
		M.Rock,
		Rock
	)
	local fork = Vector3.new(0, -0.1, 0)
	local left = Vector3.new(-0.32, 0.25, 0.1)
	local right = Vector3.new(0.3, 0.3, -0.15)
	local branches = {
		{ Vector3.new(0, -0.55, 0), fork },
		{ fork, left },
		{ fork, right },
		{ fork, Vector3.new(0.05, 0.6, 0.2) },
		{ left, Vector3.new(-0.45, 0.58, 0.0) },
		{ left, Vector3.new(-0.2, 0.5, 0.42) },
		{ right, Vector3.new(0.45, 0.6, -0.05) },
		{ right, Vector3.new(0.2, 0.55, -0.42) },
	}
	for index, branch in branches do
		bar(root, "Branch", branch[1], branch[2], if index == 1 then 0.2 else 0.15, color)
		if index > 3 then
			piece(root, "Tip", Ball, Vector3.new(0.17, 0.17, 0.17), CFrame.new(branch[2]), tips)
		end
	end
end

builders.Plank = function(root, def)
	local color = def.Color
	local grain = shade(color, -0.25)
	piece(root, "Board", Block, Vector3.new(4, 0.3, 0.95), CFrame.new(0, -0.02, 0), color, Wood)
	-- Grain lines along the top, a knot and two rusty nails.
	for _, line in
		{
			{ -1.8, 1.5, -0.3 },
			{ -1.2, 1.9, -0.08 },
			{ -1.9, 0.6, 0.15 },
			{ 0.9, 1.9, 0.18 },
			{ -0.8, 1.4, 0.36 },
		}
	do
		piece(
			root,
			"Grain",
			Block,
			Vector3.new(line[2] - line[1], 0.02, 0.03),
			CFrame.new((line[1] + line[2]) / 2, 0.135, line[3]),
			grain,
			Wood
		)
	end
	piece(
		root,
		"Knot",
		Cylinder,
		Vector3.new(0.02, 0.2, 0.2),
		CFrame.new(0.4, 0.135, 0.05) * ALONG_Y,
		shade(color, -0.45),
		Wood
	)
	for _, x in { -1.8, 1.8 } do
		piece(
			root,
			"Nail",
			Cylinder,
			Vector3.new(0.03, 0.09, 0.09),
			CFrame.new(x, 0.14, 0) * ALONG_Y,
			M.Iron,
			Rust
		)
	end
end

builders.Net = function(root, def)
	local color = def.Color
	local mesh = shade(color, -0.3)
	-- A heap of folded net: a wide flat fold with two smaller lumps on it.
	local fold = CFrame.new(0, -0.2, 0) * CFrame.Angles(0, math.rad(10), 0)
	piece(root, "Fold", Block, Vector3.new(1.6, 0.28, 1.4), fold, color, Fabric)
	for step = -2, 2 do
		local offset = step * 0.3
		piece(
			root,
			"Mesh",
			Block,
			Vector3.new(1.6, 0.03, 0.03),
			fold * CFrame.new(0, 0.145, offset),
			mesh,
			Fabric
		)
		piece(
			root,
			"Mesh",
			Block,
			Vector3.new(0.03, 0.03, 1.4),
			fold * CFrame.new(offset * 1.1, 0.145, 0),
			mesh,
			Fabric
		)
	end
	piece(
		root,
		"Lump",
		Block,
		Vector3.new(1.0, 0.3, 0.8),
		CFrame.new(0.2, 0.05, -0.15) * CFrame.Angles(0.1, 0.5, 0.06),
		shade(color, -0.08),
		Fabric
	)
	piece(
		root,
		"Lump",
		Block,
		Vector3.new(0.7, 0.24, 0.55),
		CFrame.new(-0.4, 0.04, 0.4) * CFrame.Angles(-0.08, -0.4, 0.1),
		shade(color, 0.08),
		Fabric
	)
	for _, at in
		{ Vector3.new(0.8, -0.15, 0.55), Vector3.new(-0.75, -0.12, -0.5), Vector3.new(0.25, 0.25, -0.2) }
	do
		piece(root, "Float", Ball, Vector3.new(0.3, 0.3, 0.3), CFrame.new(at), M.Float)
	end
end

builders.Buoy = function(root, def)
	local color = def.Color
	piece(root, "Body", Ball, Vector3.new(1.45, 1.45, 1.45), CFrame.new(0, -0.15, 0), color)
	piece(root, "Band", Cylinder, Vector3.new(0.4, 1.47, 1.47), CFrame.new(0, -0.15, 0) * ALONG_Y, M.White)
	piece(root, "Neck", Cylinder, Vector3.new(0.25, 0.36, 0.36), CFrame.new(0, 0.62, 0) * ALONG_Y, M.White)
	arc(root, "Ring", Vector2.new(0, 0.78), 0.1, -90, 270, 0.06, M.Iron)
	piece(
		root,
		"Weight",
		Cylinder,
		Vector3.new(0.12, 0.4, 0.4),
		CFrame.new(0, -0.86, 0) * ALONG_Y,
		M.Iron,
		Metal
	)
end

builders.BigShell = function(root, def)
	local color = def.Color
	local rib = shade(color, -0.12)
	-- A scallop lying flat, hinge at +Z: a domed fan of stacked discs with ribs over it.
	piece(root, "Rim", Cylinder, Vector3.new(0.24, 1.75, 1.75), CFrame.new(0, -0.43, -0.1) * ALONG_Y, color)
	piece(root, "Dome", Cylinder, Vector3.new(0.2, 1.3, 1.3), CFrame.new(0, -0.25, -0.1) * ALONG_Y, color)
	piece(root, "Crown", Cylinder, Vector3.new(0.15, 0.7, 0.7), CFrame.new(0, -0.1, -0.1) * ALONG_Y, color)
	local hinge = Vector3.new(0, -0.05, 0.62)
	for step = -4, 4 do
		local angle = math.rad(step * 17.5)
		local mid = Vector3.new(0.35 * math.sin(angle), 0.04, -0.1 - 0.35 * math.cos(angle))
		local edge = Vector3.new(0.86 * math.sin(angle), -0.32, -0.1 - 0.86 * math.cos(angle))
		bar(root, "Rib", hinge, mid, 0.1, rib)
		bar(root, "Rib", mid, edge, 0.1, rib)
	end
	for _, side in { -1, 1 } do
		piece(root, "Ear", Block, Vector3.new(0.45, 0.12, 0.3), CFrame.new(side * 0.25, -0.4, 0.78), rib)
	end
end

builders.FrozenFish = function(root, def)
	local fish = M.Fish
	-- A fish along Z, head at -Z, inside a clear block of ice.
	piece(root, "Head", Ball, Vector3.new(0.38, 0.38, 0.38), CFrame.new(0, 0, -0.6), fish)
	piece(root, "Body", Cylinder, Vector3.new(0.9, 0.4, 0.4), CFrame.new(0, 0, -0.15) * ALONG_Z, fish)
	piece(root, "Belly", Block, Vector3.new(0.2, 0.06, 0.8), CFrame.new(0, -0.17, -0.2), shade(fish, 0.5))
	piece(root, "Taper", Cylinder, Vector3.new(0.35, 0.26, 0.26), CFrame.new(0, 0, 0.45) * ALONG_Z, fish)
	for _, side in { -1, 1 } do
		piece(
			root,
			"Tail",
			Block,
			Vector3.new(0.04, 0.3, 0.26),
			CFrame.new(0, side * 0.1, 0.72) * CFrame.Angles(side * math.rad(35), 0, 0),
			shade(fish, -0.2)
		)
		piece(root, "Eye", Ball, Vector3.new(0.07, 0.07, 0.07), CFrame.new(side * 0.16, 0.05, -0.66), M.Hole)
	end
	piece(root, "Fin", Block, Vector3.new(0.04, 0.14, 0.35), CFrame.new(0, 0.24, -0.1), shade(fish, -0.2))
	piece(root, "Ice", Block, Vector3.new(0.78, 0.58, 2.1), CFrame.new(), def.Color, Glass, 0.6)
	for _, chunk in { { 0.24, 0.17, -0.9 }, { -0.25, -0.16, 0.85 }, { 0.25, 0.16, 0.6 } } do
		piece(
			root,
			"Frost",
			Block,
			Vector3.new(0.16, 0.12, 0.2),
			CFrame.new(chunk[1], chunk[2], chunk[3]) * CFrame.Angles(0.3, 0.6, 0.2),
			shade(def.Color, 0.4),
			Glass,
			0.3
		)
	end
end

builders.TreasureChest = function(root, def)
	local color = def.Color
	local gold = M.Gold
	piece(root, "Box", Block, Vector3.new(2.9, 1.3, 2.1), CFrame.new(0, -0.4, 0), color, WoodPlanks)
	piece(
		root,
		"Lid",
		Block,
		Vector3.new(2.9, 0.5, 2.1),
		CFrame.new(0, 0.5, 0),
		shade(color, 0.05),
		WoodPlanks
	)
	piece(
		root,
		"Hump",
		Cylinder,
		Vector3.new(2.9, 1.4, 1.4),
		CFrame.new(0, 0.4, 0),
		shade(color, 0.05),
		WoodPlanks
	)
	-- Gold trim: corner posts, a band where the lid meets the box, straps over the lid.
	for _, x in { -1.45, 1.45 } do
		for _, z in { -1.05, 1.05 } do
			piece(root, "Corner", Block, Vector3.new(0.14, 1.85, 0.14), CFrame.new(x, -0.15, z), gold, Metal)
		end
	end
	piece(root, "Band", Block, Vector3.new(2.96, 0.12, 2.16), CFrame.new(0, 0.25, 0), gold, Metal)
	for _, x in { -0.95, 0.95 } do
		piece(root, "Strap", Block, Vector3.new(0.16, 0.52, 2.16), CFrame.new(x, 0.5, 0), gold, Metal)
		piece(root, "StrapTop", Cylinder, Vector3.new(0.16, 1.44, 1.44), CFrame.new(x, 0.4, 0), gold, Metal)
	end
	piece(root, "Lock", Block, Vector3.new(0.4, 0.45, 0.1), CFrame.new(0, 0.2, -1.08), gold, Metal)
	piece(root, "Keyhole", Block, Vector3.new(0.07, 0.16, 0.02), CFrame.new(0, 0.17, -1.135), M.Hole)
end

builders.Statue = function(root, def)
	local color = def.Color
	local plinth = shade(color, -0.2)
	piece(root, "Plinth", Block, Vector3.new(1.6, 0.6, 1.6), CFrame.new(0, -1.7, 0), plinth, Rock)
	piece(root, "PlinthCap", Block, Vector3.new(1.4, 0.15, 1.4), CFrame.new(0, -1.325, 0), plinth, Rock)
	piece(root, "Moss", Block, Vector3.new(0.5, 0.04, 0.5), CFrame.new(0.4, -1.23, 0.35), M.Moss, Grass)
	-- A figure with one arm raised.
	for _, side in { -1, 1 } do
		piece(
			root,
			"Leg",
			Block,
			Vector3.new(0.3, 1.15, 0.36),
			CFrame.new(side * 0.2, -0.675, 0),
			color,
			Rock
		)
	end
	piece(root, "Torso", Block, Vector3.new(0.85, 1.1, 0.46), CFrame.new(0, 0.45, 0), color, Rock)
	piece(root, "Arm", Block, Vector3.new(0.24, 1.0, 0.3), CFrame.new(0.55, 0.45, 0), color, Rock)
	bar(root, "RaisedArm", Vector3.new(-0.55, 0.9, 0), Vector3.new(-0.62, 1.75, 0), 0.25, color, Rock)
	piece(root, "Hand", Ball, Vector3.new(0.28, 0.28, 0.28), CFrame.new(-0.62, 1.85, 0), color, Rock)
	piece(
		root,
		"Neck",
		Cylinder,
		Vector3.new(0.15, 0.24, 0.24),
		CFrame.new(0, 1.07, 0) * ALONG_Y,
		color,
		Rock
	)
	piece(root, "Head", Ball, Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 1.4, 0), color, Rock)
	piece(root, "Nose", Block, Vector3.new(0.08, 0.14, 0.08), CFrame.new(0, 1.38, -0.31), color, Rock)
end

-- Whether an item has a model. Items without one keep their plain catalog look.
function ItemModels.has(id: string): boolean
	return builders[id] ~= nil
end

-- Hides the root and builds the item's model on it. Called once, when the item is created.
function ItemModels.build(root: BasePart, def)
	local builder = builders[def.Id]
	if not builder then
		return
	end
	root.Transparency = 1
	builder(root, def)
end

return ItemModels
