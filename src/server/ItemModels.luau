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

local Glass = Palette.Material.Glass
local Wood = Palette.Material.Wood
local WoodPlanks = Palette.Material.WoodPlanks
local Metal = Palette.Material.Metal
local Rust = Palette.Material.Rust
local Foil = Palette.Material.Foil
local Neon = Palette.Material.Neon
local Smooth = Palette.Material.Smooth

local M = Palette.ItemModel

-- Turns a cylinder (which lies along X) to stand along Y or Z.
local ALONG_Y = CFrame.Angles(0, 0, math.pi / 2)
local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0)

local ItemModels = {}
local builders = {}

-- A darker (negative) or lighter (positive) version of a colour.
local function shade(color: Color3, amount: number): Color3
	if amount >= 0 then
		return color:Lerp(M.White, amount)
	end
	return color:Lerp(Color3.new(0, 0, 0), -amount)
end

-- Adds one visible part to the item. `at` is in the root's own frame.
local function piece(
	root: BasePart,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	at: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.CFrame = root.CFrame * at
	p.Color = color
	p.Material = material or Smooth
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Massless = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = root
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = root
	return p
end

-- A square bar from one point to another, in the root's frame.
local function bar(
	root: BasePart,
	name: string,
	from: Vector3,
	to: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material?
)
	piece(
		root,
		name,
		Block,
		Vector3.new(thickness, thickness, (to - from).Magnitude),
		CFrame.lookAt((from + to) / 2, to),
		color,
		material
	)
end

-- A curved metal handle in the root's XY plane, as a chain of bars.
local function arc(
	root: BasePart,
	name: string,
	centre: Vector2,
	radius: number,
	fromDegrees: number,
	toDegrees: number,
	thickness: number,
	color: Color3
)
	local steps = 6
	local previous = nil
	for step = 0, steps do
		local angle = math.rad(fromDegrees + (toDegrees - fromDegrees) * step / steps)
		local point = Vector3.new(centre.X + radius * math.cos(angle), centre.Y + radius * math.sin(angle), 0)
		if previous then
			bar(root, name, previous, point, thickness, color, Metal)
		end
		previous = point
	end
end

-- A part spanning from..to along the root's X axis, centred on the root.
local function along(from: number, to: number): CFrame
	return CFrame.new((from + to) / 2, 0, 0)
end

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
		0.35
	)
	piece(
		root,
		"Shoulder",
		Cylinder,
		Vector3.new(shoulderEnd - bodyEnd, width * 0.62, width * 0.62),
		along(bodyEnd, shoulderEnd),
		color,
		Glass,
		0.35
	)
	piece(
		root,
		"Neck",
		Cylinder,
		Vector3.new(neckEnd - shoulderEnd, width * 0.37, width * 0.37),
		along(shoulderEnd, neckEnd),
		color,
		Glass,
		0.35
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

builders.Seashell = function(root, def)
	local color = def.Color
	-- A fan-shaped shell lying flat, with ribs radiating from the hinge.
	piece(root, "Shell", Cylinder, Vector3.new(0.18, 1.1, 1.1), CFrame.new(0, -0.12, 0) * ALONG_Y, color)
	for index, degrees in { -50, -25, 0, 25, 50 } do
		piece(
			root,
			"Rib" .. index,
			Block,
			Vector3.new(0.1, 0.1, 0.5),
			CFrame.new(0, -0.02, 0) * CFrame.Angles(0, math.rad(degrees), 0) * CFrame.new(0, 0, -0.3),
			shade(color, -0.15)
		)
	end
	piece(root, "Hinge", Ball, Vector3.new(0.25, 0.25, 0.25), CFrame.new(0, -0.1, 0.5), shade(color, -0.15))
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
	bottle(root, def.Color, def.Size.X / 2, width, function(from, to)
		-- The rolled message, and the red ribbon tied round the bottle.
		piece(
			root,
			"Message",
			Cylinder,
			Vector3.new((to - from) * 0.8, width * 0.45, width * 0.45),
			along(from, to),
			M.Paper
		)
		local ringX = from + (to - from) * 0.4
		piece(
			root,
			"Ribbon",
			Cylinder,
			Vector3.new(0.12, width * 1.06, width * 1.06),
			CFrame.new(ringX, 0, 0),
			M.Wax,
			Smooth
		)
	end)
end

builders.FlipFlop = function(root, def)
	local color = def.Color
	piece(root, "Sole", Block, Vector3.new(0.8, 0.2, 1.7), CFrame.new(0, -0.025, 0), color)
	-- A thong that splits from the toe post to the heel.
	local strap = shade(color, -0.2)
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
	-- A soft halo round the glowing core.
	piece(root, "Halo", Ball, def.Size * 1.35, CFrame.new(), M.Glow, Glass, 0.75)
end

builders.Bucket = function(root, def)
	local color = def.Color
	local width = def.Size.Y
	piece(root, "Body", Cylinder, Vector3.new(1.35, width * 0.94, width * 0.94), along(-0.8, 0.55), color)
	piece(
		root,
		"Rim",
		Cylinder,
		Vector3.new(0.1, width, width),
		CFrame.new(0.6, 0, 0),
		shade(color, 0.15),
		Metal
	)
	-- The open top, dark inside.
	piece(
		root,
		"Mouth",
		Cylinder,
		Vector3.new(0.03, width * 0.8, width * 0.8),
		CFrame.new(0.66, 0, 0),
		M.Hole
	)
	arc(root, "Handle", Vector2.new(-0.1, 0), 0.9, 25, 155, 0.08, M.Iron)
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
	piece(root, "Flame", Ball, Vector3.new(0.36, 0.36, 0.36), CFrame.new(0, -0.15, 0), M.Flame, Neon)
	arc(root, "Handle", Vector2.new(0, 0.6), 0.5, 15, 165, 0.07, color)
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
	piece(root, "Mouth", Cylinder, Vector3.new(0.04, 1.7, 1.7), CFrame.new(0.79, 0, 0), M.Hole)
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
	for _, side in { -1, 1 } do
		bar(root, "Fluke", Vector3.new(0, -1.15, 0), Vector3.new(side * 0.75, -1.25, 0), 0.34, color, Rust)
		bar(
			root,
			"Point",
			Vector3.new(side * 0.75, -1.25, 0),
			Vector3.new(side * 1.1, -0.85, 0),
			0.34,
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
	piece(root, "Hole", Cylinder, Vector3.new(0.46, width * 0.76, width * 0.76), CFrame.new(), M.Hole)
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
