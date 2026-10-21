-- Rolls a biome for every tile of the beach at the start of each tide cycle, and builds what goes with it:
-- the biome's ground (its layout, see src/shared/Layouts: the tile's terrain is rebuilt and
-- props are moved to stay on it), decor so players can tell (rare biomes are never announced, but you can see them), the
-- secret's entrance, and the biome's beach hazard.
-- Admins can set or reroll biomes from the console (see AdminService).

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Layouts = require(Shared.Layouts)
local Looks = require(Shared.Looks)
local Tide = require(Shared.Tide)

local DecorService = require(script.Parent.DecorService)
local GroundShift = require(script.Parent.GroundShift)
local HazardService = require(script.Parent.HazardService)
local TerrainBuilder = require(script.Parent.TerrainBuilder)

local BiomeService = {}

local folder: Folder
local rng = Random.new()
local onEntrance: (Player, string, CFrame) -> () = function(_player: Player, _secret: string, _at: CFrame) end

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Palette.Material.Sand
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

-- Decor ------------------------------------------------------------------------------

local decorBuilders = {}

-- Small sandcastles scattered over the tile.
function decorBuilders.Sandcastle(tileFolder: Folder, biome, startZ: number, endZ: number)
	for _ = 1, 10 do
		local x = rng:NextNumber(-Beach.HalfWidth + 15, Beach.HalfWidth - 15)
		local z = rng:NextNumber(startZ + 10, endZ - 10)
		local size = rng:NextNumber(2, 4)
		local groundY = Beach.groundAt(x, z)
		makePart({
			Name = "Sandcastle",
			Size = Vector3.new(size, size, size),
			CFrame = CFrame.new(x, groundY + size / 2, z),
			Color = biome.Decor,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			tileFolder
		makePart({
			Name = "Tower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(size * 0.8, size * 0.5, size * 0.5),
			CFrame = CFrame.new(x, groundY + size + size * 0.4, z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = biome.Decor,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			tileFolder
	end
end

-- Broken planks and ribs half-buried in the sand.
function decorBuilders.Wreck(tileFolder: Folder, biome, startZ: number, endZ: number)
	for _ = 1, 14 do
		local x = rng:NextNumber(-Beach.HalfWidth + 15, Beach.HalfWidth - 15)
		local z = rng:NextNumber(startZ + 10, endZ - 10)
		local length = rng:NextNumber(4, 9)
		makePart({
			Name = "Plank",
			Size = Vector3.new(length, 0.5, 1.2),
			CFrame = CFrame.new(x, Beach.groundAt(x, z) + 0.2, z)
				* CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), rng:NextNumber() * math.pi, 0),
			Color = biome.Decor,
			Material = Palette.Material.WoodPlanks,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			tileFolder
	end
end

-- Any biome without scenery of its own: low mounds in its Decor colour, so you can tell it's
-- there.
function decorBuilders.Mounds(tileFolder: Folder, biome, startZ: number, endZ: number)
	for _ = 1, 12 do
		local x = rng:NextNumber(-Beach.HalfWidth + 15, Beach.HalfWidth - 15)
		local z = rng:NextNumber(startZ + 10, endZ - 10)
		local size = rng:NextNumber(2, 5)
		makePart({
			Name = "Mound",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size * 0.5, size),
			CFrame = CFrame.new(x, Beach.groundAt(x, z), z),
			Color = biome.Decor,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			tileFolder
	end
end

-- Entrances ---------------------------------------------------------------------------

local entranceBuilders = {}

function entranceBuilders.Sandcastle(castle: Model, biome, x: number, z: number, groundY: number): BasePart
	local keep = makePart({
		Name = "Keep",
		Size = Vector3.new(22, 14, 22),
		CFrame = CFrame.new(x, groundY + 6, z),
		Color = biome.Decor,
	})
	keep.Parent = castle
	for _, corner in
		{ Vector3.new(-11, 0, -11), Vector3.new(11, 0, -11), Vector3.new(-11, 0, 11), Vector3.new(11, 0, 11) }
	do
		makePart({
			Name = "Tower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(22, 7, 7),
			CFrame = CFrame.new(x + corner.X, groundY + 10, z + corner.Z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = biome.Decor,
		}).Parent =
			castle
	end
	castle.PrimaryPart = keep
	return makePart({
		Name = "Door",
		Size = Vector3.new(5, 8, 0.6),
		CFrame = CFrame.new(x, groundY + 4, z - 11.2),
		Color = Color3.fromRGB(70, 45, 25),
		Material = Palette.Material.Wood,
	})
end

-- A ship's hull lying on its side, with a hatch facing the shop.
function entranceBuilders.Wreck(wreck: Model, biome, x: number, z: number, groundY: number): BasePart
	local hull = makePart({
		Name = "Hull",
		Size = Vector3.new(30, 12, 12),
		CFrame = CFrame.new(x, groundY + 4, z) * CFrame.Angles(0, 0, math.rad(18)),
		Color = biome.Decor,
		Material = Palette.Material.WoodPlanks,
	})
	hull.Parent = wreck
	makePart({
		Name = "Mast",
		Size = Vector3.new(1.4, 22, 1.4),
		CFrame = CFrame.new(x + 6, groundY + 10, z + 2) * CFrame.Angles(0, 0, math.rad(-35)),
		Color = Color3.fromRGB(80, 55, 35),
		Material = Palette.Material.Wood,
	}).Parent =
		wreck
	wreck.PrimaryPart = hull
	return makePart({
		Name = "Hatch",
		Size = Vector3.new(4.5, 5, 0.6),
		CFrame = CFrame.new(x, groundY + 3, z - 6.2),
		Color = Color3.fromRGB(40, 30, 20),
		Material = Palette.Material.Wood,
	})
end

-- The ten rooms' openings. Each is a small model on the entrance's spot (its footprint stays
-- within about 10 studs either side, so it fits the flat the layout clears) with a dark door
-- part on its -Z face, where the prompt sits and the player comes back out.
local DOOR_DARK = Color3.fromRGB(35, 28, 24)

-- Adds a part to the model at an offset from the spot, resting on the ground's height there.
local function put(model: Model, props: { [string]: any }, x: number, y: number, z: number, rotation: CFrame?)
	local part = makePart(props)
	part.CFrame = CFrame.new(x, y, z) * (rotation or CFrame.identity)
	part.Parent = model
	return part
end

local function door(
	x: number,
	y: number,
	z: number,
	size: Vector3,
	color: Color3?,
	props: { [string]: any }?
): BasePart
	local all: { [string]: any } = {
		Name = "Door",
		Size = size,
		CFrame = CFrame.new(x, y, z),
		Color = color or DOOR_DARK,
		Material = Palette.Material.Wood,
	}
	for key, value in props or {} do
		all[key] = value
	end
	return makePart(all)
end

local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- a Cylinder's axis, turned to stand

-- Driftwood Cove: a hollow beached tree trunk lying along Z, its cut end open toward the shop.
function entranceBuilders.Trunk(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local bark = Color3.fromRGB(120, 92, 66)
	local trunk = put(model, {
		Name = "Trunk",
		Size = Vector3.new(14, 9, 9),
		Color = bark,
		Material = Palette.Material.Wood,
		Shape = Enum.PartType.Cylinder,
	}, x, groundY + 4.5, z + 1, CFrame.Angles(0, math.pi / 2, 0))
	model.PrimaryPart = trunk
	-- Roots and boughs at the far end.
	for _, side in { -1, 1 } do
		put(model, {
			Name = "Bough",
			Size = Vector3.new(1.4, 1.4, 8),
			Color = biome.Decor,
			Material = Palette.Material.Wood,
		}, x + side * 4, groundY + 7, z + 6, CFrame.Angles(math.rad(-20), side * math.rad(25), 0))
	end
	put(model, {
		Name = "Root",
		Size = Vector3.new(7, 3, 3),
		Color = bark,
		Material = Palette.Material.Wood,
	}, x - 3, groundY + 1, z + 7, CFrame.Angles(0, math.rad(30), 0))
	return door(x, groundY + 3.5, z - 6.3, Vector3.new(5, 6.5, 0.6))
end

-- Tidepool Rocks: a blowhole, a dark hole in the rock ringed by boulders, open toward the shop.
function entranceBuilders.Blowhole(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local rock = biome.Decor
	local ring = {
		{ -5.5, 1, 3.5 },
		{ 5.5, 1, 3.5 },
		{ -4.5, 0, 7.5 },
		{ 4.5, 0, 7.5 },
		{ 0, 0, 9 },
	}
	for index, spot in ring do
		local boulder = put(model, {
			Name = "Rock",
			Size = Vector3.new(5 + (index % 2), 4 + (index % 3), 5),
			Color = rock:Lerp(Color3.new(0, 0, 0), 0.1 * (index % 3)),
			Material = Palette.Material.Rock,
		}, x + spot[1], groundY + 2 + spot[2], z + spot[3] - 3, CFrame.Angles(0, index, 0))
		if index == 1 then
			model.PrimaryPart = boulder
		end
	end
	put(model, {
		Name = "Spray",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		Color = Color3.fromRGB(200, 225, 235),
		Material = Palette.Material.Glass,
		Transparency = 0.5,
		CanCollide = false,
	}, x, groundY + 4.5, z + 2)
	-- The hole itself: a dark disc lying on the ground.
	return door(x, groundY + 0.4, z, Vector3.new(0.8, 5, 5), DOOR_DARK, {
		Shape = Enum.PartType.Cylinder,
		CFrame = CFrame.new(x, groundY + 0.4, z) * UPRIGHT,
		Material = Palette.Material.Rock,
	})
end

-- Seagrass Shallows: a collapsed jetty, its deck fallen with one end up on posts; the way in is
-- under the high end.
function entranceBuilders.Jetty(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local planks = Color3.fromRGB(125, 100, 72)
	local deck = put(model, {
		Name = "Deck",
		Size = Vector3.new(10, 0.8, 14),
		Color = planks,
		Material = Palette.Material.WoodPlanks,
	}, x, groundY + 5, z + 1, CFrame.Angles(math.rad(20), 0, 0))
	model.PrimaryPart = deck
	for _, side in { -1, 1 } do
		put(model, {
			Name = "Post",
			Size = Vector3.new(1.2, 7, 1.2),
			Color = biome.Decor:Lerp(Color3.new(0, 0, 0), 0.5),
			Material = Palette.Material.Wood,
		}, x + side * 4.6, groundY + 3.5, z - 6, CFrame.Angles(0, 0, side * math.rad(4)))
		put(model, {
			Name = "Barnacles",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.6, 1.2, 1.6),
			Color = Palette.ItemModel.Barnacle,
			CanCollide = false,
		}, x + side * 4.6, groundY + 1.2, z - 6.7)
	end
	put(model, {
		Name = "Rail",
		Size = Vector3.new(0.6, 3, 7),
		Color = planks,
		Material = Palette.Material.WoodPlanks,
	}, x + 5, groundY + 2, z + 6, CFrame.Angles(math.rad(10), 0, math.rad(-35)))
	return door(x, groundY + 2.2, z - 4.2, Vector3.new(5, 4.4, 0.6))
end

-- Coral Garden: an arch in the reef, two coral pillars and a lintel with a glowing way through.
function entranceBuilders.ReefArch(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local coral = biome.Decor
	for _, side in { -1, 1 } do
		local pillar = put(model, {
			Name = "Pillar",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(10, 4.5, 4.5),
			Color = coral,
			Material = Palette.Material.Rock,
		}, x + side * 4.5, groundY + 5, z, UPRIGHT)
		if side == -1 then
			model.PrimaryPart = pillar
		end
		put(model, {
			Name = "Coral",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(4, 3.5, 4),
			Color = coral:Lerp(Color3.fromRGB(255, 255, 255), 0.25),
			Material = Palette.Material.Rock,
		}, x + side * 6.5, groundY + 1.6, z - 2)
	end
	put(model, {
		Name = "Lintel",
		Size = Vector3.new(14, 3, 4.5),
		Color = coral:Lerp(Color3.fromRGB(255, 255, 255), 0.15),
		Material = Palette.Material.Rock,
	}, x, groundY + 11.5, z)
	put(model, {
		Name = "Fan",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 4, 3),
		Color = coral:Lerp(Color3.fromRGB(255, 255, 255), 0.4),
		Material = Palette.Material.Rock,
	}, x + 2, groundY + 14, z)
	return door(x, groundY + 4.5, z + 0.2, Vector3.new(4.6, 9, 0.6), Color3.fromRGB(255, 190, 215), {
		Material = Palette.Material.Neon,
		Transparency = 0.35,
	})
end

-- Fog Bank: a lighthouse; its door is the way in.
function entranceBuilders.Lighthouse(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local white = Color3.fromRGB(225, 228, 230)
	local base = put(model, {
		Name = "Tower",
		Size = Vector3.new(10, 16, 10),
		Color = white,
		Material = Palette.Material.Rock,
	}, x, groundY + 8, z + 1)
	model.PrimaryPart = base
	put(model, {
		Name = "Stripe",
		Size = Vector3.new(10.4, 3, 10.4),
		Color = Color3.fromRGB(140, 60, 55),
		Material = Palette.Material.Rock,
	}, x, groundY + 11, z + 1)
	put(model, {
		Name = "Upper",
		Size = Vector3.new(7, 9, 7),
		Color = white,
		Material = Palette.Material.Rock,
	}, x, groundY + 20.5, z + 1)
	put(model, {
		Name = "Gallery",
		Size = Vector3.new(11, 1, 11),
		Color = Color3.fromRGB(70, 75, 82),
		Material = Palette.Material.Metal,
	}, x, groundY + 25.5, z + 1)
	local lamp = put(model, {
		Name = "Lamp",
		Size = Vector3.new(4.5, 4, 4.5),
		Color = Palette.ItemModel.LanternGlass,
		Material = Palette.Material.Neon,
	}, x, groundY + 28, z + 1)
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Color = Palette.ItemModel.LanternGlass
	light.Parent = lamp
	put(model, {
		Name = "Roof",
		Size = Vector3.new(6.5, 2, 6.5),
		Color = Color3.fromRGB(140, 60, 55),
		Material = Palette.Material.Metal,
	}, x, groundY + 31, z + 1)
	return door(x, groundY + 3.2, z - 4.2, Vector3.new(3.6, 6.4, 0.6))
end

-- Whirlwind Dunes: a hollow in a dune, framed by a wind-carved arch of sandstone.
function entranceBuilders.DuneArch(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local sand = biome.Decor
	local dune = put(model, {
		Name = "Dune",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(22, 14, 18),
		Color = sand,
	}, x, groundY + 1, z + 4)
	model.PrimaryPart = dune
	local stone = sand:Lerp(Color3.fromRGB(150, 105, 70), 0.4)
	for _, side in { -1, 1 } do
		put(model, {
			Name = "Pier",
			Size = Vector3.new(3.5, 9, 4),
			Color = stone,
			Material = Palette.Material.Rock,
		}, x + side * 3.8, groundY + 4.5, z - 3.5, CFrame.Angles(0, 0, side * math.rad(-4)))
	end
	put(model, {
		Name = "Lintel",
		Size = Vector3.new(11.5, 2.6, 4),
		Color = stone,
		Material = Palette.Material.Rock,
	}, x, groundY + 10, z - 3.5, CFrame.Angles(0, 0, math.rad(3)))
	return door(x, groundY + 4, z - 1.6, Vector3.new(4.2, 8, 0.6), Color3.fromRGB(110, 78, 50), {
		Material = Palette.Material.Sand,
	})
end

-- Hermit Hollows: a giant empty shell lying in the chamber, its mouth a burrow.
function entranceBuilders.Burrow(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local shell = biome.Decor
	local body = put(model, {
		Name = "Shell",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(14, 11, 14),
		Color = shell,
		Material = Palette.Material.Rock,
	}, x, groundY + 4, z + 1)
	model.PrimaryPart = body
	put(model, {
		Name = "Whorl",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(8, 7, 8),
		Color = shell:Lerp(Color3.fromRGB(200, 120, 100), 0.35),
		Material = Palette.Material.Rock,
	}, x + 3, groundY + 10, z + 3)
	put(model, {
		Name = "Tip",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 4, 4),
		Color = shell:Lerp(Color3.fromRGB(200, 120, 100), 0.6),
		Material = Palette.Material.Rock,
	}, x + 5, groundY + 14, z + 4)
	put(model, {
		Name = "Lip",
		Size = Vector3.new(7.5, 1.2, 2),
		Color = shell:Lerp(Color3.fromRGB(255, 255, 255), 0.3),
		Material = Palette.Material.Rock,
	}, x, groundY + 0.6, z - 6.6)
	return door(x, groundY + 3.2, z - 5.9, Vector3.new(5, 5.6, 0.6))
end

-- Spearstone Reef: a cleft between two leaning slabs, ringed with spearstones.
function entranceBuilders.Cleft(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local stone = biome.Decor
	for _, side in { -1, 1 } do
		local slab = put(model, {
			Name = "Slab",
			Size = Vector3.new(5, 15, 10),
			Color = stone,
			Material = Palette.Material.Rock,
		}, x + side * 4.6, groundY + 7, z, CFrame.Angles(0, 0, side * math.rad(-5)))
		if side == -1 then
			model.PrimaryPart = slab
		end
	end
	put(model, {
		Name = "Back",
		Size = Vector3.new(14, 15, 2),
		Color = stone:Lerp(Color3.new(0, 0, 0), 0.2),
		Material = Palette.Material.Rock,
	}, x, groundY + 7, z + 5.5)
	for index, spot in { { -8, -4 }, { 8, -4 }, { -9, 3 }, { 9, 3 } } do
		put(model, {
			Name = "Spearstone",
			Size = Vector3.new(1.2, 5 + index % 2, 1.2),
			Color = stone:Lerp(Color3.fromRGB(150, 175, 190), 0.4),
			Material = Palette.Material.Rock,
		}, x + spot[1], groundY + 2.5, z + spot[2], CFrame.Angles(math.rad(8), 0, math.rad(index * 6 - 15)))
	end
	return door(x, groundY + 5, z + 3, Vector3.new(4, 10, 0.6))
end

-- Jellyfish Lagoon: a glowing grotto, a mound of rock with a lit hollow and jellies drifting.
function entranceBuilders.Grotto(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local rock = Color3.fromRGB(80, 62, 120)
	local mound = put(model, {
		Name = "Mound",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(20, 14, 16),
		Color = rock,
		Material = Palette.Material.Rock,
	}, x, groundY + 1, z + 3)
	model.PrimaryPart = mound
	for index, spot in { { -7, 8, -3 }, { 6, 10, -2 }, { 1, 12, 0 } } do
		local jelly = put(model, {
			Name = "Jelly",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.2, 2, 2.2),
			Color = biome.Decor:Lerp(Palette.ItemModel.Jelly, 0.4),
			Material = Palette.Material.Neon,
			Transparency = 0.25,
			CanCollide = false,
		}, x + spot[1], groundY + spot[2], z + spot[3])
		jelly.Name = "Jelly" .. index
	end
	local mouth = door(x, groundY + 3.2, z - 4.4, Vector3.new(5, 5.4, 0.6), biome.Decor, {
		Material = Palette.Material.Neon,
		Transparency = 0.3,
	})
	local glow = Instance.new("PointLight")
	glow.Color = biome.Decor
	glow.Range = 24
	glow.Parent = mouth
	return mouth
end

-- Stranded Iceberg: the mouth of an ice cave in a bluff of ice, icicles hanging over it.
function entranceBuilders.IceCave(model: Model, biome, x: number, z: number, groundY: number): BasePart
	local ice = Color3.fromRGB(185, 220, 240)
	local bluff = put(model, {
		Name = "Bluff",
		Size = Vector3.new(18, 11, 11),
		Color = ice,
		Material = Enum.Material.Ice,
	}, x, groundY + 5, z + 2)
	model.PrimaryPart = bluff
	put(model, {
		Name = "Crest",
		Size = Vector3.new(11, 5, 8),
		Color = ice:Lerp(Color3.fromRGB(255, 255, 255), 0.4),
		Material = Enum.Material.Ice,
	}, x - 2, groundY + 12, z + 3, CFrame.Angles(0, math.rad(12), math.rad(4)))
	put(model, {
		Name = "Brow",
		Size = Vector3.new(8, 1.6, 2),
		Color = ice,
		Material = Enum.Material.Ice,
	}, x, groundY + 7.3, z - 3.6)
	for index, dx in { -3, -1, 1, 3 } do
		put(model, {
			Name = "Icicle",
			Size = Vector3.new(0.7, 2.2 + index % 2, 0.7),
			Color = ice:Lerp(Color3.fromRGB(255, 255, 255), 0.5),
			Material = Enum.Material.Ice,
			CanCollide = false,
		}, x + dx, groundY + 5.9, z - 3.6)
	end
	return door(x, groundY + 3, z - 3.7, Vector3.new(5, 6, 0.6), Color3.fromRGB(25, 45, 70))
end

-- Whether a biome's door stands this tide: a chance by its tier (Config.Secrets.DoorChance).
-- The unlock item's spawn doesn't depend on it: a banked item waits for a tide with a door.
local function doorStands(biome): boolean
	return rng:NextNumber() < (Config.Secrets.DoorChance[biome.Tier] or 1)
end

-- `force` skips the roll (tools/tests).
local function buildEntrance(tileFolder: Folder, biome, tile: number, force: boolean?)
	if not force and not doorStands(biome) then
		return
	end
	local startZ = Beach.tileRange(tile)
	-- The layout says where the entrance can stand, or the biome's spots across the tile.
	local spots = Layouts.entrances(tile, startZ)
	local x, z
	if #spots > 0 then
		local spot = spots[rng:NextInteger(1, #spots)]
		x, z = spot.X, spot.Y
	elseif biome.EntranceSpots and #biome.EntranceSpots > 0 then
		x = biome.EntranceSpots[rng:NextInteger(1, #biome.EntranceSpots)]
		z = startZ + 30 -- where the layouts keep the spots flat
	else
		return -- the layout names no spot and the biome has no fallback: no opening here
	end
	local groundY = Beach.groundAt(x, z)
	local model = Instance.new("Model")
	model.Name = "SecretEntrance"
	local door = entranceBuilders[biome.Entrance](model, biome, x, z, groundY)
	door.Parent = model

	local unlock = Items.get(biome.UnlockItem)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Use " .. unlock.Name
	prompt.ObjectText = biome.EntranceName
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = door
	prompt.Triggered:Connect(function(player)
		-- Players come back out in front of the door.
		onEntrance(player, biome.Secret, door.CFrame * CFrame.new(0, 0, -5))
	end)
	model.Parent = tileFolder
end

-- Public -----------------------------------------------------------------------------

local setCallbacks: { (number, any, Folder) -> () } = {}
local rerollCallbacks: { () -> () } = {}

-- Called after a tile gets a biome, with its folder (things built there go when it changes).
function BiomeService.onBiomeSet(callback: (number, any, Folder) -> ())
	table.insert(setCallbacks, callback)
end

-- Called after every tile has been rolled for a new tide cycle.
function BiomeService.onRerolled(callback: () -> ())
	table.insert(rerollCallbacks, callback)
end

function BiomeService.tileFolder(tile: number): Folder?
	return folder and folder:FindFirstChild("Tile" .. tile) :: Folder?
end

function BiomeService.get(tile: number): string?
	return Workspace:GetAttribute(Biomes.attributeFor(tile))
end

-- Sets (or clears, with nil) a tile's biome and rebuilds its decor and entrance. A tile is a
-- whole zone. `choice` picks its layout's crossing and rooms (Layouts.encode's text, or a
-- Choice); without one, they're rolled.
function BiomeService.set(tile: number, biomeId: string?, choice: any?, rebuild: boolean?)
	local biome = biomeId and Biomes.List[biomeId]
	local wasLayout = Layouts.active(tile)
	local wasOwnGround = Looks.hasOwnGround(Biomes.activeIn(tile))
	local settle = GroundShift.capture(tile)
	Workspace:SetAttribute(Biomes.attributeFor(tile), if biome then biome.Id else nil)
	local def = Layouts.activeDef(tile)
	local text = nil
	if def then
		local picked = if type(choice) == "string"
			then Layouts.decode(def, choice)
			elseif type(choice) == "table" then choice
			else Layouts.roll(def, rng)
		text = Layouts.encode(picked)
	end
	Workspace:SetAttribute(Layouts.attributeFor(tile), text)
	if rebuild or Layouts.active(tile) ~= wasLayout or wasOwnGround or Looks.hasOwnGround(biome) then
		-- The biome brings its own ground (its shape or its materials): rebuild the tile's
		-- terrain and keep things on it.
		TerrainBuilder.buildTile(tile)
		settle()
	end
	local old = folder and folder:FindFirstChild("Tile" .. tile)
	if old then
		old:Destroy()
	end
	-- The layout's decor (its props, the Gloom's wards) goes with its ground.
	DecorService.build(tile)
	-- The plain zone has its own hazards (Config.Zones[i].Hazards), where no biome rolled.
	local zone = Config.Zones[Beach.zoneOfTile(tile)]
	local plainHazards = not biome and zone and zone.Hazards and #zone.Hazards > 0
	if biome or plainHazards then
		local tileFolder = Instance.new("Folder")
		tileFolder.Name = "Tile" .. tile
		if biome then
			local startZ, endZ = Beach.tileRange(tile)
			local decor = biome.Scenery and decorBuilders[biome.Scenery] or decorBuilders.Mounds
			decor(tileFolder, biome, startZ, endZ)
			GroundShift.clearMisfits(tileFolder)
			if biome.Secret and biome.Entrance then
				buildEntrance(tileFolder, biome, tile)
			end
		end
		HazardService.start(tile, biome or zone, tileFolder)
		tileFolder.Parent = folder
		if biome then
			for _, callback in setCallbacks do
				task.spawn(callback, tile, biome, tileFolder)
			end
		end
	end
end

-- The roll weights on a tile: each biome that can roll in its zone.
function BiomeService.weightsFor(tile: number): { [string]: number }
	local zone = Beach.zoneOfTile(tile)
	local weights = {}
	for id, biome in Biomes.List do
		local weight = biome.Zones and biome.Zones[zone]
		if weight and weight > 0 then
			weights[id] = weight
		end
	end
	return weights
end

-- One tide's biomes: { [tile] = biome id } (tiles without one left out). Each zone rolls
-- whether it gets one (Config.Biomes.Chance), then which, from those that can turn up there
-- and haven't already this tide: each biome at most once. The zones roll in a random order, so
-- a biome that can turn up in several isn't always taken by the nearest.
function BiomeService.pick(random: Random): { [number]: string }
	local order = {}
	for tile = 1, Beach.ActiveTiles do
		table.insert(order, random:NextInteger(1, #order + 1), tile)
	end
	local picked, used = {}, {}
	for _, tile in order do
		local chance = Config.Biomes.Chance[Beach.zoneOfTile(tile)] or 0
		if random:NextNumber() >= chance then
			continue
		end
		local weights, total = {}, 0
		for id, weight in BiomeService.weightsFor(tile) do
			if not used[id] then
				weights[id] = weight
				total += weight
			end
		end
		local roll = random:NextNumber() * total
		for id, weight in weights do
			roll -= weight
			if roll <= 0 then
				picked[tile], used[id] = id, true
				break
			end
		end
	end
	return picked
end

-- Rolls every tile's biome for the new tide.
function BiomeService.reroll()
	local picked = BiomeService.pick(rng)
	for tile = 1, Beach.ActiveTiles do
		BiomeService.set(tile, picked[tile])
	end
	for _, callback in rerollCallbacks do
		task.spawn(callback)
	end
end

-- For the data validator and tools/tests.
BiomeService._entranceBuilders = entranceBuilders
BiomeService._decorBuilders = decorBuilders
BiomeService._buildEntrance = buildEntrance
BiomeService._doorStands = doorStands

function BiomeService.init(entranceCallback: (Player, string, CFrame) -> (), _notify: (Player, string) -> ())
	onEntrance = entranceCallback
	folder = Instance.new("Folder")
	folder.Name = "Biomes"
	folder.Parent = Workspace

	BiomeService.reroll()
	local lastCycle = Tide.getState().Cycle
	task.spawn(function()
		while true do
			task.wait(1)
			local cycle = Tide.getState().Cycle
			if cycle ~= lastCycle then
				lastCycle = cycle
				BiomeService.reroll()
			end
		end
	end)
end

return BiomeService
