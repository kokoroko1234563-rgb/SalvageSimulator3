-- The boardwalk in front of the shop, dressed as the heart of the beach: dark boards round its
-- edge, a rope railing along the back and the sides (open in the middle of each side, toward
-- the shop and the bank), an arch over the steps down to the sand, lamp posts, benches facing
-- the sea, planters, a salvaged anchor on a plinth and crates and barrels by the buyer. All of it
-- is scenery: it doesn't collide or get queried, so it never gets in the way of towing.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local MapParts = require(script.Parent.MapParts)
local DecorService = require(script.Parent.DecorService)
local BeachDressing = require(script.Parent.BeachDressing)

local Boardwalk = {}

local W = Palette.World

local function piece(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
)
	return MapParts.scenery(parent, {
		Name = name,
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material or Palette.Material.Wood,
	})
end

-- A rope railing from `a` to `b` on the deck: posts every 8 studs and two sagging-free ropes.
local function railing(parent: Instance, a: Vector3, b: Vector3, top: number)
	local run = b - a
	local count = math.max(1, math.round(run.Magnitude / 8))
	for i = 0, count do
		local at = a + run * (i / count)
		piece(
			parent,
			"RailPost",
			Vector3.new(0.8, 4, 0.8),
			CFrame.new(at + Vector3.new(0, top + 2, 0)),
			W.DarkWood
		)
		MapParts.ball(parent, at + Vector3.new(0, top + 4.2, 0), 1, W.DarkWood, Palette.Material.Wood)
	end
	local mid = (a + b) / 2
	for _, h in { 2.2, 3.6 } do
		piece(
			parent,
			"Rope",
			Vector3.new(0.25, 0.25, run.Magnitude),
			CFrame.lookAt(mid + Vector3.new(0, top + h, 0), b + Vector3.new(0, top + h, 0)),
			W.Rope,
			Palette.Material.Fabric
		)
	end
end

-- A lamp post: a dark pole, a cross arm and a lantern with a warm light.
local function lamp(parent: Instance, base: Vector3)
	piece(
		parent,
		"LampPost",
		Vector3.new(0.7, 11, 0.7),
		CFrame.new(base + Vector3.new(0, 5.5, 0)),
		W.LampIron,
		Palette.Material.Metal
	)
	piece(
		parent,
		"LampCap",
		Vector3.new(1.8, 0.4, 1.8),
		CFrame.new(base + Vector3.new(0, 11.6, 0)),
		W.LampIron,
		Palette.Material.Metal
	)
	local glass = piece(
		parent,
		"LampGlass",
		Vector3.new(1.3, 1.6, 1.3),
		CFrame.new(base + Vector3.new(0, 10.6, 0)),
		W.LampGlow,
		Palette.Material.Neon
	)
	local light = Instance.new("PointLight")
	light.Color = W.LampGlow
	light.Range = 18
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = glass
end

-- A bench facing +Z (the sea): seat, back and two legs each side.
local function bench(parent: Instance, base: Vector3)
	piece(
		parent,
		"Seat",
		Vector3.new(8, 0.4, 2),
		CFrame.new(base + Vector3.new(0, 1.8, 0)),
		W.Counter,
		Palette.Material.WoodPlanks
	)
	piece(
		parent,
		"Back",
		Vector3.new(8, 1.6, 0.3),
		CFrame.new(base + Vector3.new(0, 3.2, -1)) * CFrame.Angles(math.rad(-12), 0, 0),
		W.Counter,
		Palette.Material.WoodPlanks
	)
	for side = -1, 1, 2 do
		piece(
			parent,
			"Leg",
			Vector3.new(0.4, 1.7, 1.8),
			CFrame.new(base + Vector3.new(side * 3.4, 0.85, 0)),
			W.LampIron,
			Palette.Material.Metal
		)
	end
end

-- A wooden planter with a little palm or a bush in it.
local function planter(parent: Instance, base: Vector3, palm: boolean, rng: Random)
	piece(
		parent,
		"Planter",
		Vector3.new(5, 2.4, 5),
		CFrame.new(base + Vector3.new(0, 1.2, 0)),
		W.Counter,
		Palette.Material.WoodPlanks
	)
	piece(
		parent,
		"Soil",
		Vector3.new(4.4, 0.2, 4.4),
		CFrame.new(base + Vector3.new(0, 2.35, 0)),
		W.Dirt,
		Palette.Material.Dirt
	)
	if palm then
		BeachDressing.palm(parent, base + Vector3.new(0, 2.4, 0), rng:NextNumber(10, 13), rng)
	else
		for i = 1, 4 do
			local a = i * math.pi / 2 + rng:NextNumber(-0.4, 0.4)
			MapParts.ball(
				parent,
				base + Vector3.new(math.cos(a) * 1.1, 3.4, math.sin(a) * 1.1),
				2.4,
				W.Frond,
				Palette.Material.Grass
			)
		end
		MapParts.ball(parent, base + Vector3.new(0, 4.4, 0), 1.2, W.Bloom)
	end
end

-- Dresses the deck. `center` is the middle of its top face; `size` is its width (X) and depth (Z).
function Boardwalk.build(parent: Instance, center: Vector3, size: Vector2)
	local folder = Instance.new("Folder")
	folder.Name = "Boardwalk"
	folder.Parent = parent
	local rng = Random.new(17)
	local top = center.Y
	local hx, hz = size.X / 2, size.Y / 2
	local x0, x1 = center.X - hx, center.X + hx
	local back, front = center.Z - hz, center.Z + hz

	-- Dark boards round the edge.
	for _, z in { back + 0.6, front - 0.6 } do
		piece(
			folder,
			"EdgeBoard",
			Vector3.new(size.X, 0.2, 1.2),
			CFrame.new(center.X, top + 0.1, z),
			W.DarkWood,
			Palette.Material.WoodPlanks
		)
	end
	for _, x in { x0 + 0.6, x1 - 0.6 } do
		piece(
			folder,
			"EdgeBoard",
			Vector3.new(1.2, 0.2, size.Y),
			CFrame.new(x, top + 0.1, center.Z),
			W.DarkWood,
			Palette.Material.WoodPlanks
		)
	end

	-- Railing along the back, and the sides with an opening in the middle of each.
	railing(folder, Vector3.new(x0 + 1, 0, back + 1), Vector3.new(x1 - 1, 0, back + 1), top)
	local gap = 12
	for _, x in { x0 + 1, x1 - 1 } do
		railing(folder, Vector3.new(x, 0, back + 1), Vector3.new(x, 0, center.Z - gap), top)
		railing(folder, Vector3.new(x, 0, center.Z + gap), Vector3.new(x, 0, front - 4), top)
	end

	-- The arch over the steps down to the sand.
	for side = -1, 1, 2 do
		piece(
			folder,
			"ArchPost",
			Vector3.new(1.4, 15, 1.4),
			CFrame.new(center.X + side * 8, top + 7.5, front - 1.5),
			W.Trim
		)
		MapParts.ball(
			folder,
			Vector3.new(center.X + side * 8, top + 15.4, front - 1.5),
			1.8,
			W.Trim,
			Palette.Material.Wood
		)
	end
	piece(folder, "ArchBeam", Vector3.new(19, 1, 1.4), CFrame.new(center.X, top + 14.2, front - 1.5), W.Trim)
	MapParts.sign(folder, "SALVAGE BAY", CFrame.new(center.X, top + 12, front - 1.1), 14, 2.6)

	-- Lamps at the corners and either side of the arch.
	for _, x in { x0 + 3, x1 - 3 } do
		lamp(folder, Vector3.new(x, top, back + 3))
		lamp(folder, Vector3.new(x, top, front - 3))
	end

	-- Benches along the front, facing the sea, between the bunting poles.
	for _, x in { -40, -28, 28, 40 } do
		bench(folder, Vector3.new(center.X + x, top, front - 6))
	end

	-- Planters: palms at the back corners, bushes by the side openings.
	planter(folder, Vector3.new(x0 + 6, top, back + 6), true, rng)
	planter(folder, Vector3.new(x1 - 6, top, back + 6), true, rng)
	for _, x in { x0 + 4, x1 - 4 } do
		planter(folder, Vector3.new(x, top, center.Z - gap - 3), false, rng)
		planter(folder, Vector3.new(x, top, center.Z + gap + 3), false, rng)
	end

	-- The salvaged anchor on a stone plinth at the back, the first find anyone made here.
	local plinth = Vector3.new(center.X, top, back + 9)
	piece(
		folder,
		"Plinth",
		Vector3.new(12, 1.6, 6),
		CFrame.new(plinth + Vector3.new(0, 0.8, 0)),
		W.Plinth,
		Palette.Material.Rock
	)
	piece(
		folder,
		"PlinthTop",
		Vector3.new(12.6, 0.4, 6.6),
		CFrame.new(plinth + Vector3.new(0, 1.8, 0)),
		W.Trim,
		Palette.Material.Rock
	)
	local anchor = Instance.new("Model")
	anchor.Name = "ShowAnchor"
	anchor.Parent = folder
	DecorService.Builders.Anchor(
		anchor,
		CFrame.new(plinth + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.pi / 2, 0),
		1.3,
		rng
	)

	-- A compass rose inlaid in the deck where people come in.
	local rose = Vector3.new(center.X, top, center.Z - 8)
	for i, ring in { { 17, W.DarkWood }, { 15.4, W.Trim }, { 14.6, W.DarkWood } } do
		piece(
			folder,
			"Rose",
			Vector3.new(0.06, ring[1], ring[1]),
			CFrame.new(rose + Vector3.new(0, 0.02 + i * 0.02, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			ring[2],
			Palette.Material.WoodPlanks
		).Shape =
			Enum.PartType.Cylinder
	end
	for k, turn in { math.pi / 4, 0 } do
		local length = if k == 1 then 9 else 13
		for _, a in { 0, math.pi / 2 } do
			piece(
				folder,
				"RosePoint",
				Vector3.new(length / 7, 0.06, length),
				CFrame.new(rose + Vector3.new(0, 0.1 + k * 0.02, 0)) * CFrame.Angles(0, turn + a, 0),
				if k == 1 then W.Trim else W.Shutter,
				Palette.Material.WoodPlanks
			)
		end
	end
	MapParts.ball(folder, rose + Vector3.new(0, 0.1, 0), 1.6, W.LampGlow, Palette.Material.Metal)

	-- Crates and barrels of salvage stacked on the side toward the buyer.
	local stackAt = Vector3.new(x1 - 18, top, back + 10)
	for _, c in { { 0, 0, 0, 0.1 }, { 4.2, 0, 0.5, -0.2 }, { 2.1, 3.6, 0.2, 0.25 }, { 0.8, 0, 4.4, 0.4 } } do
		local cf = CFrame.new(stackAt + Vector3.new(c[1], c[2] + 1.8, c[3])) * CFrame.Angles(0, c[4], 0)
		piece(folder, "Crate", Vector3.new(3.6, 3.6, 3.6), cf, W.ChestWood, Palette.Material.WoodPlanks)
		for _, y in { -1.3, 1.3 } do
			piece(folder, "CrateBand", Vector3.new(3.8, 0.4, 3.8), cf * CFrame.new(0, y, 0), W.DarkWood)
		end
	end
	for i, at in { Vector3.new(-3, 0, 1), Vector3.new(-3.4, 0, 4.6) } do
		local base = stackAt + at
		MapParts.column(folder, base, 4, 3, W.Barrel, Palette.Material.Wood)
		for _, y in { 0.7, 3.3 } do
			MapParts.column(
				folder,
				base + Vector3.new(0, y - 0.2, 0),
				0.4,
				3.2,
				W.LampIron,
				Palette.Material.Metal
			)
		end
		if i == 1 then
			MapParts.ball(folder, base + Vector3.new(0, 4.3, 0), 1.6, W.Rope, Palette.Material.Fabric)
		end
	end
	return folder
end

return Boardwalk
