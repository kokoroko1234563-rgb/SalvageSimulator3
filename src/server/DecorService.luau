-- Builds the layouts' decor (Decor.luau): the props each zone's layout places on its ground,
-- rebuilt with the zone whenever its biome or crossing and rooms change (BiomeService). Each
-- kind is a small model of plain parts on the real ground, turned to a yaw, sized by Scale;
-- scattered ones are laid out from a seed, so the same layout always comes out the same.
-- Decor never collides with anything (the layouts' routes are worked out without it) and
-- can't be grabbed. The glowing kinds give off light and are wards against the Gloom: an
-- invisible part tagged Hazards.WardTag with a WardRadius (HazardController).

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Decor = require(Shared.Decor)
local Hazards = require(Shared.Hazards)
local Layouts = require(Shared.Layouts)
local Palette = require(Shared.Palette)

local D = Palette.Decor
local M = Palette.Material
local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder
local Wedge = "Wedge"

local DecorService = {}

local root: Folder? = nil

-- One anchored, non-colliding, ungrabbable part. `at` is relative to `base`.
local function part(
	parent: Instance,
	base: CFrame,
	name: string,
	shape: Enum.PartType | string,
	size: Vector3,
	at: CFrame,
	color: Color3,
	material: Enum.Material?
): BasePart
	local p: BasePart
	if shape == Wedge then
		p = Instance.new("WedgePart")
	else
		local block = Instance.new("Part")
		block.Shape = shape :: Enum.PartType
		p = block
	end
	p.Name = name
	p.Size = size
	p.CFrame = base * at
	p.Color = color
	p.Material = material or M.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = size.Magnitude > 2
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A bar from one point to another (relative to `base`).
local function bar(
	parent: Instance,
	base: CFrame,
	name: string,
	from: Vector3,
	to: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material?
): BasePart
	local direction = to - from
	local up = if math.abs(direction.Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return part(
		parent,
		base,
		name,
		Block,
		Vector3.new(thickness, thickness, direction.Magnitude),
		CFrame.lookAt((from + to) / 2, to, up),
		color,
		material
	)
end

-- A cylinder standing up (relative to `base`), from `y0` to `y1` at (x, z).
local function post(
	parent: Instance,
	base: CFrame,
	name: string,
	x: number,
	z: number,
	y0: number,
	y1: number,
	width: number,
	color: Color3,
	material
)
	return part(
		parent,
		base,
		name,
		Cylinder,
		Vector3.new(y1 - y0, width, width),
		CFrame.new(x, (y0 + y1) / 2, z) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material
	)
end

-- A light, and a ward the Gloom can't reach within `radius`.
local function glow(parent: Instance, at: BasePart, color: Color3, radius: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = math.min(radius * 1.4, 60)
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = at
	local ward = Instance.new("Part")
	ward.Name = "Ward"
	ward.Size = Vector3.new(1, 1, 1)
	ward.CFrame = at.CFrame
	ward.Transparency = 1
	ward.Anchored = true
	ward.CanCollide = false
	ward.CanQuery = false
	ward.CanTouch = false
	ward:SetAttribute("WardRadius", radius)
	CollectionService:AddTag(ward, Hazards.WardTag)
	ward.Parent = parent
end

-- The builders: each builds one prop at `base` (on the ground, turned), sized by `s`.
local builders: { [string]: (Instance, CFrame, number, Random) -> () } = {}

function builders.Kelp(model, base, s, rng)
	for i = 1, rng:NextInteger(4, 7) do
		local x, z = rng:NextNumber(-1.2, 1.2) * s, rng:NextNumber(-1.2, 1.2) * s
		local height = rng:NextNumber(5, 10) * s
		local lean = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * s
		local mid = Vector3.new(x, height * 0.55, z) + lean * 0.5
		local top = Vector3.new(x, height, z) + lean * 1.3
		local color = if i % 2 == 0 then D.Kelp else D.KelpLight
		bar(model, base, "Stalk", Vector3.new(x, 0, z), mid, 0.3 * s, color, M.Grass)
		bar(model, base, "Stalk", mid, top, 0.25 * s, color, M.Grass)
		part(
			model,
			base,
			"Blade",
			Block,
			Vector3.new(0.9, 2.2, 0.08) * s,
			CFrame.new(top) * CFrame.Angles(0, rng:NextNumber(0, 6), 0.3),
			color,
			M.Grass
		)
	end
end

function builders.Weed(model, base, s, rng)
	for _ = 1, rng:NextInteger(6, 10) do
		local x, z = rng:NextNumber(-2.5, 2.5) * s, rng:NextNumber(-2.5, 2.5) * s
		part(
			model,
			base,
			"Weed",
			Wedge,
			Vector3.new(0.6, rng:NextNumber(0.6, 1.4), rng:NextNumber(1.2, 2.2)) * s,
			CFrame.new(x, 0.3 * s, z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			D.Weed,
			M.Grass
		)
	end
end

function builders.Timber(model, base, s, rng)
	local length = rng:NextNumber(6, 10) * s
	local tilt = CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.15, 0.15))
	part(
		model,
		base,
		"Timber",
		Block,
		Vector3.new(1.3, 1, length) * s,
		CFrame.new(0, 0.3 * s, 0) * tilt,
		D.Timber,
		M.Wood
	)
	part(
		model,
		base,
		"Split",
		Wedge,
		Vector3.new(1.3, 0.8, 1.6) * s,
		CFrame.new(0, 0.7 * s, length / 2 + 0.6 * s) * tilt,
		D.TimberDark,
		M.Wood
	)
end

function builders.WreckRibs(model, base, s, rng)
	local length = 14 * s
	bar(
		model,
		base,
		"Keel",
		Vector3.new(0, 0.3, -length / 2),
		Vector3.new(0, 0.3, length / 2),
		1.1 * s,
		D.TimberDark,
		M.WoodPlanks
	)
	local ribs = rng:NextInteger(4, 6)
	for i = 0, ribs - 1 do
		local z = -length / 2 + (i + 0.5) * length / ribs
		local height = (6 + rng:NextNumber(-1, 1.5)) * s * (1 - math.abs(i - (ribs - 1) / 2) / ribs * 0.6)
		local broken = rng:NextNumber() < 0.3
		for _, side in { -1, 1 } do
			local points = {
				Vector3.new(0, 0, z),
				Vector3.new(side * 2.6 * s, height * 0.35, z),
				Vector3.new(side * 3.2 * s, height * 0.75, z),
				Vector3.new(side * 2.4 * s, height, z),
			}
			local last = if broken and side == 1 then 2 else #points - 1
			for k = 1, last do
				bar(model, base, "Rib", points[k], points[k + 1], 0.55 * s, D.Timber, M.WoodPlanks)
			end
		end
	end
end

function builders.Anchor(model, base, s, rng)
	-- Lying on its side: the shank along the ground, one arm dug in, one up, and its chain.
	local tilt = CFrame.Angles(0, 0, math.rad(70))
	local frame = CFrame.new(0, 1.6 * s, 0) * tilt
	part(model, base, "Shank", Block, Vector3.new(0.7, 7, 0.7) * s, frame, D.Rust, M.Rust)
	part(
		model,
		base,
		"Stock",
		Block,
		Vector3.new(0.5, 0.5, 4.5) * s,
		frame * CFrame.new(0, 3.2 * s, 0),
		D.RustDark,
		M.Rust
	)
	for _, side in { -1, 1 } do
		part(
			model,
			base,
			"Arm",
			Block,
			Vector3.new(0.6, 3, 0.6) * s,
			frame * CFrame.new(side * 1.1 * s, -3.1 * s, 0) * CFrame.Angles(0, 0, side * math.rad(-50)),
			D.Rust,
			M.Rust
		)
		part(
			model,
			base,
			"Fluke",
			Wedge,
			Vector3.new(0.4, 1.4, 1.6) * s,
			frame
				* CFrame.new(side * 2.2 * s, -2.2 * s, 0)
				* CFrame.Angles(0, math.pi / 2, side * math.rad(40)),
			D.RustDark,
			M.Rust
		)
	end
	part(
		model,
		base,
		"Ring",
		Cylinder,
		Vector3.new(0.3, 1.4, 1.4) * s,
		frame * CFrame.new(0, 3.9 * s, 0),
		D.RustDark,
		M.Rust
	)
	builders.Chain(model, base * CFrame.new(-2.6 * s, 0, 0), s * 0.8, rng)
end

function builders.Chain(model, base, s, rng)
	local heading = 0
	local at = Vector3.zero
	for i = 1, rng:NextInteger(9, 14) do
		heading += rng:NextNumber(-0.35, 0.35)
		local step = Vector3.new(math.sin(heading), 0, math.cos(heading)) * 0.9 * s
		at += step
		part(
			model,
			base,
			"Link",
			Cylinder,
			Vector3.new(0.25, 1.1, 0.7) * s,
			CFrame.lookAt(at + Vector3.new(0, 0.3 * s, 0), at + Vector3.new(0, 0.3 * s, 0) + step)
				* CFrame.Angles(0, if i % 2 == 0 then 0 else math.pi / 2, math.pi / 2),
			D.RustDark,
			M.Rust
		)
	end
end

function builders.Bones(model, base, s, _rng)
	local length = 12 * s
	for i = 0, 6 do
		local z = -length / 2 + i * length / 6
		part(
			model,
			base,
			"Vertebra",
			Cylinder,
			Vector3.new(0.9, 1.1, 1.1) * s,
			CFrame.new(0, 0.4 * s, z) * CFrame.Angles(0, math.pi / 2, 0),
			D.Bone,
			M.Smooth
		)
	end
	for i = 1, 5 do
		local z = -length / 2 + i * length / 6
		local height = (5 - math.abs(i - 3)) * s
		for _, side in { -1, 1 } do
			bar(
				model,
				base,
				"Rib",
				Vector3.new(0, 0.5 * s, z),
				Vector3.new(side * 2.4 * s, height * 0.7, z + 0.4 * s),
				0.35 * s,
				D.Bone
			)
			bar(
				model,
				base,
				"Rib",
				Vector3.new(side * 2.4 * s, height * 0.7, z + 0.4 * s),
				Vector3.new(side * 1.8 * s, height, z + 0.8 * s),
				0.3 * s,
				D.Bone
			)
		end
	end
	part(
		model,
		base,
		"Skull",
		Ball,
		Vector3.new(2.4, 1.8, 3.2) * s,
		CFrame.new(0, 0.8 * s, length / 2 + 1.6 * s),
		D.Bone,
		M.Smooth
	)
end

function builders.DeadCoral(model, base, s, rng)
	local trunkTop = Vector3.new(0, 1.6 * s, 0)
	bar(model, base, "Trunk", Vector3.zero, trunkTop, 0.6 * s, D.DeadCoral, M.Rock)
	for _ = 1, rng:NextInteger(4, 7) do
		local angle = rng:NextNumber(0, 6.28)
		local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local tip = trunkTop
			+ out * rng:NextNumber(1, 2) * s
			+ Vector3.new(0, rng:NextNumber(1.2, 2.6) * s, 0)
		bar(model, base, "Branch", trunkTop, tip, 0.4 * s, D.DeadCoral, M.Rock)
		bar(
			model,
			base,
			"Twig",
			tip,
			tip + out * 0.6 * s + Vector3.new(0, 0.9 * s, 0),
			0.25 * s,
			D.DeadCoral,
			M.Rock
		)
	end
end

function builders.Barnacles(model, base, s, rng)
	for _ = 1, rng:NextInteger(8, 14) do
		local x, z = rng:NextNumber(-1.6, 1.6) * s, rng:NextNumber(-1.6, 1.6) * s
		local size = rng:NextNumber(0.4, 0.8) * s
		part(
			model,
			base,
			"Barnacle",
			Cylinder,
			Vector3.new(size * 0.8, size, size),
			CFrame.new(x, size * 0.4, z) * CFrame.Angles(0, 0, math.pi / 2),
			D.Barnacle,
			M.Rock
		)
		part(
			model,
			base,
			"Mouth",
			Cylinder,
			Vector3.new(0.05, size * 0.4, size * 0.4),
			CFrame.new(x, size * 0.82, z) * CFrame.Angles(0, 0, math.pi / 2),
			D.PebbleDark,
			M.Smooth
		)
	end
end

function builders.Urchins(model, base, s, rng)
	for _ = 1, rng:NextInteger(4, 7) do
		local x, z = rng:NextNumber(-1.5, 1.5) * s, rng:NextNumber(-1.5, 1.5) * s
		local size = rng:NextNumber(0.7, 1.1) * s
		local centre = Vector3.new(x, size * 0.4, z)
		part(
			model,
			base,
			"Urchin",
			Ball,
			Vector3.new(size, size * 0.8, size),
			CFrame.new(centre),
			D.Urchin,
			M.Smooth
		)
		for k = 1, 6 do
			local angle = k / 6 * 6.28 + rng:NextNumber(0, 0.5)
			local out = Vector3.new(math.cos(angle), 0.6, math.sin(angle)).Unit
			bar(model, base, "Spine", centre, centre + out * size * 0.9, 0.08 * s, D.Urchin)
		end
	end
end

function builders.Starfish(model, base, s, _rng)
	part(
		model,
		base,
		"Body",
		Cylinder,
		Vector3.new(0.25, 0.9, 0.9) * s,
		CFrame.new(0, 0.12 * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
		D.Starfish
	)
	for k = 0, 4 do
		local angle = k / 5 * 6.28
		part(
			model,
			base,
			"Arm",
			Wedge,
			Vector3.new(0.5, 0.22, 1.3) * s,
			CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.11 * s, 0.9 * s),
			D.Starfish
		)
	end
end

function builders.Pebbles(model, base, s, rng)
	for _ = 1, rng:NextInteger(10, 18) do
		local x, z = rng:NextNumber(-3, 3) * s, rng:NextNumber(-3, 3) * s
		local size = rng:NextNumber(0.3, 0.9) * s
		part(
			model,
			base,
			"Pebble",
			Ball,
			Vector3.new(size, size * 0.5, size * 0.8),
			CFrame.new(x, size * 0.15, z) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
			if rng:NextNumber() < 0.5 then D.Pebble else D.PebbleDark,
			M.Rock
		)
	end
end

function builders.Crate(model, base, s, rng)
	local size = 3 * s
	part(
		model,
		base,
		"Bottom",
		Block,
		Vector3.new(size, 0.2 * s, size),
		CFrame.new(0, 0.1 * s, 0),
		D.Timber,
		M.WoodPlanks
	)
	part(
		model,
		base,
		"Side",
		Block,
		Vector3.new(size, size * 0.8, 0.2 * s),
		CFrame.new(0, size * 0.4, -size / 2),
		D.Timber,
		M.WoodPlanks
	)
	part(
		model,
		base,
		"Side",
		Block,
		Vector3.new(0.2 * s, size * 0.6, size),
		CFrame.new(-size / 2, size * 0.3, 0) * CFrame.Angles(0, 0, 0.15),
		D.TimberDark,
		M.WoodPlanks
	)
	for _ = 1, 3 do
		part(
			model,
			base,
			"Plank",
			Block,
			Vector3.new(0.6, 0.15, size * 0.9) * s,
			CFrame.new(rng:NextNumber(1, 3) * s, 0.1 * s, rng:NextNumber(-1.5, 1.5) * s)
				* CFrame.Angles(0, rng:NextNumber(0, 3), 0),
			D.Timber,
			M.WoodPlanks
		)
	end
end

function builders.Shells(model, base, s, rng)
	local colors = { D.ShellPink, D.ShellCream, D.ShellBand }
	for _ = 1, rng:NextInteger(6, 11) do
		local x, z = rng:NextNumber(-2.2, 2.2) * s, rng:NextNumber(-2.2, 2.2) * s
		local size = rng:NextNumber(0.35, 0.8) * s
		part(
			model,
			base,
			"Shell",
			Ball,
			Vector3.new(size, size * 0.4, size * 0.85),
			CFrame.new(x, size * 0.12, z) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
			colors[rng:NextInteger(1, #colors)],
			M.Smooth
		)
	end
end

function builders.Rocks(model, base, s, rng)
	for _ = 1, rng:NextInteger(3, 6) do
		local x, z = rng:NextNumber(-3, 3) * s, rng:NextNumber(-3, 3) * s
		local size = rng:NextNumber(1.6, 4.2) * s
		part(
			model,
			base,
			"Rock",
			Ball,
			Vector3.new(size * rng:NextNumber(1, 1.4), size * 0.7, size),
			CFrame.new(x, size * 0.2, z) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
			if rng:NextNumber() < 0.5 then D.RockLight else D.RockMid,
			M.Rock
		)
	end
end

function builders.DuneGrass(model, base, s, rng)
	for _ = 1, rng:NextInteger(3, 5) do
		local cx, cz = rng:NextNumber(-2, 2) * s, rng:NextNumber(-2, 2) * s
		for _ = 1, rng:NextInteger(4, 7) do
			local height = rng:NextNumber(1.2, 2.6) * s
			local tip =
				Vector3.new(cx + rng:NextNumber(-0.7, 0.7) * s, height, cz + rng:NextNumber(-0.7, 0.7) * s)
			bar(
				model,
				base,
				"Blade",
				Vector3.new(cx, 0, cz),
				tip,
				0.12 * s,
				if rng:NextNumber() < 0.6 then D.DuneGrass else D.DuneGrassDry,
				M.Grass
			)
		end
	end
end

function builders.Driftwood(model, base, s, rng)
	local length = rng:NextNumber(4, 7) * s
	local bend = rng:NextNumber(-0.5, 0.5)
	local a = Vector3.new(0, 0.35 * s, -length / 2)
	local m = Vector3.new(bend * 2 * s, 0.4 * s, 0)
	local b = Vector3.new(-bend * s, 0.3 * s, length / 2)
	bar(model, base, "Branch", a, m, 0.6 * s, D.Driftwood, M.Wood)
	bar(model, base, "Branch", m, b, 0.5 * s, D.Driftwood, M.Wood)
	bar(model, base, "Twig", m, m + Vector3.new(1.4 * s, 0.4 * s, 0.8 * s), 0.25 * s, D.Driftwood, M.Wood)
end

function builders.GlowShells(model, base, s, rng)
	local brightest: BasePart? = nil
	for _ = 1, rng:NextInteger(4, 7) do
		local x, z = rng:NextNumber(-1.4, 1.4) * s, rng:NextNumber(-1.4, 1.4) * s
		local size = rng:NextNumber(0.5, 0.9) * s
		local shell = part(
			model,
			base,
			"GlowShell",
			Ball,
			Vector3.new(size, size * 0.45, size * 0.8),
			CFrame.new(x, size * 0.15, z) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
			D.GlowShell,
			M.Neon
		)
		brightest = brightest or shell
	end
	glow(model, brightest :: BasePart, D.GlowShell, Decor.Kinds.GlowShells.Ward * s, 1.2)
end

function builders.GlowWeed(model, base, s, rng)
	local tallest: BasePart? = nil
	for _ = 1, rng:NextInteger(5, 8) do
		local x, z = rng:NextNumber(-1.5, 1.5) * s, rng:NextNumber(-1.5, 1.5) * s
		local height = rng:NextNumber(1.5, 3) * s
		local blade = bar(
			model,
			base,
			"GlowBlade",
			Vector3.new(x, 0, z),
			Vector3.new(x + rng:NextNumber(-0.6, 0.6), height, z + rng:NextNumber(-0.6, 0.6)),
			0.2 * s,
			D.GlowWeed,
			M.Neon
		)
		tallest = tallest or blade
	end
	glow(model, tallest :: BasePart, D.GlowWeed, Decor.Kinds.GlowWeed.Ward * s, 1.5)
end

function builders.LanternPost(model, base, s, _rng)
	post(model, base, "Post", 0, 0, 0, 6 * s, 0.5 * s, D.TimberDark, M.Wood)
	bar(
		model,
		base,
		"Arm",
		Vector3.new(0, 5.6 * s, 0),
		Vector3.new(1.4 * s, 5.6 * s, 0),
		0.3 * s,
		D.TimberDark,
		M.Wood
	)
	bar(
		model,
		base,
		"Hook",
		Vector3.new(1.3 * s, 5.6 * s, 0),
		Vector3.new(1.3 * s, 5.1 * s, 0),
		0.08 * s,
		D.LanternIron,
		M.Metal
	)
	post(model, base, "Cap", 1.3 * s, 0, 4.8 * s, 5.1 * s, 0.7 * s, D.LanternIron, M.Metal)
	local glass = post(model, base, "Glass", 1.3 * s, 0, 4.1 * s, 4.8 * s, 0.55 * s, D.LanternGlass, M.Neon)
	post(model, base, "Base", 1.3 * s, 0, 3.9 * s, 4.1 * s, 0.75 * s, D.LanternIron, M.Metal)
	glow(model, glass, D.LanternGlass, Decor.Kinds.LanternPost.Ward * s, 2)
end

DecorService.Builders = builders

-- A seed for a decor entry, so it comes out the same every time.
local function seedFor(tile: number, index: number, name: string): number
	local h = tile * 7919 + index * 104729
	for i = 1, #name do
		h = (h * 31 + string.byte(name, i)) % 2147483647
	end
	return h
end

local function insidePolygon(points, x: number, z: number): boolean
	local inside = false
	local j = #points
	for i = 1, #points do
		local a, b = points[i], points[j]
		if (a[2] > z) ~= (b[2] > z) and x < (b[1] - a[1]) * (z - a[2]) / (b[2] - a[2]) + a[1] then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- Where an entry's props go, in tile coordinates: its At, Count spots over its Area, or Count
-- spots strung along its Path.
local function spotsOf(entry, rng: Random): { Vector2 }
	if entry.At then
		return { Vector2.new(entry.At[1], entry.At[2]) }
	end
	local spots = {}
	if entry.Area then
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, p in entry.Area do
			minX, maxX = math.min(minX, p[1]), math.max(maxX, p[1])
			minZ, maxZ = math.min(minZ, p[2]), math.max(maxZ, p[2])
		end
		local tries = 0
		while #spots < entry.Count and tries < entry.Count * 30 do
			tries += 1
			local x, z = rng:NextNumber(minX, maxX), rng:NextNumber(minZ, maxZ)
			if insidePolygon(entry.Area, x, z) then
				table.insert(spots, Vector2.new(x, z))
			end
		end
	elseif entry.Path then
		local path = {}
		for _, p in entry.Path do
			table.insert(path, Vector2.new(p[1], p[2]))
		end
		local total = 0
		for i = 1, #path - 1 do
			total += (path[i + 1] - path[i]).Magnitude
		end
		for k = 1, entry.Count do
			local d = (k - 0.5) / entry.Count * total
			for i = 1, #path - 1 do
				local length = (path[i + 1] - path[i]).Magnitude
				if d <= length or i == #path - 1 then
					local at = path[i]:Lerp(path[i + 1], math.clamp(d / math.max(length, 0.01), 0, 1))
					table.insert(spots, at + Vector2.new(rng:NextNumber(-2, 2), rng:NextNumber(-2, 2)))
					break
				end
				d -= length
			end
		end
	end
	return spots
end

-- Builds one tile's decor (rebuilding it), from its active layout.
function DecorService.build(tile: number): Folder?
	if not root then
		local folder = Instance.new("Folder")
		folder.Name = "Decor"
		folder.Parent = Workspace
		root = folder
	end
	local name = "Tile" .. tile
	local old = (root :: Folder):FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local entries = Layouts.decor(tile)
	if #entries == 0 then
		return nil
	end
	local layout = Layouts.active(tile)
	local folder = Instance.new("Folder")
	folder.Name = name
	local z0 = Beach.tileRange(tile)
	for index, entry in entries do
		local kind = Decor.Kinds[entry.Kind]
		local build = builders[entry.Kind]
		if not kind or not build then
			continue
		end
		local rng = Random.new(seedFor(tile, index, layout and layout.Name or ""))
		for _, spot in spotsOf(entry, rng) do
			local x, z = spot.X, z0 + spot.Y
			local _, rock = Beach.shapeAt(x, z)
			if rock and not kind.OnRock then
				continue -- only open ground (a wall's top or side is no place for it)
			end
			local yaw = if entry.Yaw then math.rad(entry.Yaw) else rng:NextNumber(0, math.pi * 2)
			local model = Instance.new("Model")
			model.Name = entry.Kind
			build(
				model,
				CFrame.new(x, Beach.groundAt(x, z), z) * CFrame.Angles(0, yaw, 0),
				entry.Scale or 1,
				rng
			)
			model.Parent = folder
		end
	end
	folder.Parent = root
	return folder
end

return DecorService
