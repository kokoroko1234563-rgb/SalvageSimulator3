-- Beach loot. Value is the base sell price before the zone multiplier. Size, Shape and
-- Color set the physics body and the colour the item is named by; the visible model is
-- built from them in src/server/ItemModels.luau.
--
-- Tier (1 to 7) is the zone the item washes up in: a zone's surf and loot spots draw only from
-- items of its own tier (the zone's Rarity table still picks the rarity within it), and a tool
-- lifts every item up to its own tier (Gear.Tools). Unlock items have no tier: they are always
-- liftable. Biome items (Biome = "<BiomeId>", docs/design/biome-items.md) are the exception to
-- that: they have no Tier or Value of their own, wash up only in their biome, take the tier of the
-- zone they land in, and are worth a premium over that zone's normal finds (Items.biomeValue).
-- They stay out of the tier pools (Items.ofTier) and the main lexicon (Items.Lexicon); each
-- biome has its own lexicon page (Items.BiomeOrder, Items.ofBiome). Class (Light to Very heavy) is only the physical feel: density when dragged, what
-- fits in pockets, and where in the water it lies.

local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)
local Palette = require(script.Parent.Palette)

local Light = Gear.WeightClass.Light
local Medium = Gear.WeightClass.Medium
local Heavy = Gear.WeightClass.Heavy
local VeryHeavy = Gear.WeightClass.VeryHeavy

local Items = {}

Items.Rarities = { "Common", "Uncommon", "Rare", "VeryRare" }

Items.RarityColors = Palette.Rarity

-- Density (g/cm^3 in Roblox units) gives each class a different feel when dragged.
Items.ClassDensity = {
	[Light] = 0.35,
	[Medium] = 0.8,
	[Heavy] = 1.6,
	[VeryHeavy] = 2.4,
}

Items.Catalog = {
	-- Light
	{
		Id = "Seashell",
		Name = "Seashell",
		Class = Light,
		Rarity = "Common",
		Tier = 1,
		Value = 16,
		Size = Vector3.new(1, 0.5, 1.2),
		Shape = "Ball",
		Color = Color3.fromRGB(255, 165, 190),
	},
	{
		Id = "GlassBottle",
		Name = "Glass Bottle",
		Class = Light,
		Rarity = "Common",
		Tier = 1,
		Value = 24,
		Size = Vector3.new(1.6, 0.6, 0.6),
		Shape = "Cylinder",
		Color = Color3.fromRGB(70, 215, 150),
		Material = Palette.Material.Glass,
	},
	{
		Id = "FlipFlop",
		Name = "Flip-Flop",
		Class = Light,
		Rarity = "Common",
		Tier = 1,
		Value = 20,
		Size = Vector3.new(0.8, 0.25, 1.8),
		Shape = "Block",
		Color = Color3.fromRGB(255, 105, 170),
	},
	{
		Id = "Sunglasses",
		Name = "Sunglasses",
		Class = Light,
		Rarity = "Uncommon",
		Tier = 1,
		Value = 56,
		Size = Vector3.new(1.4, 0.4, 0.5),
		Shape = "Block",
		Color = Color3.fromRGB(250, 248, 240),
	},
	{
		Id = "MessageBottle",
		Name = "Message in a Bottle",
		Class = Light,
		Rarity = "Rare",
		Tier = 2,
		Value = 160,
		Size = Vector3.new(1.8, 0.7, 0.7),
		Shape = "Cylinder",
		Color = Color3.fromRGB(100, 195, 255),
		Material = Palette.Material.Glass,
	},
	{
		Id = "Pearl",
		Name = "Pearl",
		Class = Light,
		Rarity = "VeryRare",
		Tier = 3,
		Value = 480,
		Size = Vector3.new(0.7, 0.7, 0.7),
		Shape = "Ball",
		Color = Color3.fromRGB(252, 240, 250),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "BeachBall",
		Name = "Beach Ball",
		Class = Light,
		Rarity = "Common",
		Tier = 1,
		Value = 28,
		Size = Vector3.new(1.6, 1.6, 1.6),
		Shape = "Ball",
		Color = Color3.fromRGB(255, 80, 90),
	},
	-- Unlock items: never rolled as normal loot, never sold, banked at the bank house.
	{
		Id = "GoldenSpade",
		Name = "Golden Spade",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "SandcastleFlats",
		Value = 0,
		Size = Vector3.new(0.6, 0.4, 2.6),
		Shape = "Block",
		Color = Color3.fromRGB(255, 205, 55),
		Material = Palette.Material.Foil,
	},
	{
		Id = "CaptainsKey",
		Name = "Captain's Key",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "ShipwreckShallows",
		Value = 0,
		Size = Vector3.new(0.5, 0.3, 1.8),
		Shape = "Block",
		Color = Color3.fromRGB(60, 215, 200),
		Material = Palette.Material.Metal,
	},
	{
		-- The rarest unlock item: a beam of light follows it until it's banked.
		Id = "BeaconPearl",
		Name = "Beacon Pearl",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "FarSandbar",
		UnlockNote = "Opens the Sunken Bell Tower on the Far Sandbar, reachable around low tide. A beam of light follows it until it's banked",
		SkyBeam = true,
		Value = 0,
		Size = Vector3.new(1, 1, 1),
		Shape = "Ball",
		Color = Color3.fromRGB(255, 232, 140),
		Material = Palette.Material.Neon,
	},
	-- Unlock items for the doc's other biomes. Their biomes don't roll yet (Biomes.Planned), so
	-- they can't wash up: they're here so they exist (inventory, admin give, the showroom), and
	-- don't count toward the lexicon until their biome is in. The rare biomes' unlock items
	-- aren't named in the doc: these names are placeholders.
	{
		Id = "CarvedIdol",
		Name = "Carved Driftwood Idol",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "DriftwoodCove",
		Planned = true,
		Value = 0,
		Size = Vector3.new(0.7, 1.6, 0.7),
		Shape = "Block",
		Color = Color3.fromRGB(150, 110, 70),
		Material = Palette.Material.Wood,
	},
	{
		Id = "PearlEyedShell",
		Name = "Pearl-Eyed Shell",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "TidepoolRocks",
		Planned = true,
		Value = 0,
		Size = Vector3.new(1.2, 0.6, 1.4),
		Shape = "Ball",
		Color = Color3.fromRGB(240, 200, 220),
	},
	{
		Id = "BarnacledLantern",
		Name = "Barnacled Lantern",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "SeagrassShallows",
		Planned = true,
		Value = 0,
		Size = Vector3.new(0.9, 1.4, 0.9),
		Shape = "Block",
		Color = Color3.fromRGB(90, 130, 110),
		Material = Palette.Material.Rust,
	},
	{
		Id = "CoralComb",
		Name = "Coral Comb",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "CoralGarden",
		Planned = true,
		Value = 0,
		Size = Vector3.new(1.4, 0.25, 0.8),
		Shape = "Block",
		Color = Color3.fromRGB(255, 120, 150),
	},
	{
		Id = "JellyJar",
		Name = "Glowing Jelly Jar",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "JellyfishLagoon",
		Planned = true,
		Value = 0,
		Size = Vector3.new(0.9, 1.1, 0.9),
		Shape = "Cylinder",
		Color = Color3.fromRGB(150, 230, 255),
		Material = Palette.Material.Glass,
	},
	{
		Id = "LighthouseKey",
		Name = "Lighthouse Key",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "FogBank",
		Planned = true,
		Value = 0,
		Size = Vector3.new(0.5, 0.3, 2),
		Shape = "Block",
		Color = Color3.fromRGB(200, 60, 60),
		Material = Palette.Material.Metal,
	},
	{
		Id = "WindChime",
		Name = "Wind Chime",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "WhirlwindDunes",
		Planned = true,
		Value = 0,
		Size = Vector3.new(0.9, 1.6, 0.9),
		Shape = "Block",
		Color = Color3.fromRGB(220, 200, 150),
		Material = Palette.Material.Metal,
	},
	{
		Id = "SpiralConch",
		Name = "Spiral Conch",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "HermitHollows",
		Planned = true,
		Value = 0,
		Size = Vector3.new(1, 1, 1.8),
		Shape = "Block",
		Color = Color3.fromRGB(240, 170, 130),
	},
	{
		Id = "SpearstoneShard",
		Name = "Spearstone Shard",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "SpearstoneReef",
		Planned = true,
		Value = 0,
		Size = Vector3.new(0.6, 0.6, 2.2),
		Shape = "Block",
		Color = Color3.fromRGB(130, 120, 110),
		Material = Palette.Material.Rock,
	},
	{
		Id = "PrismShard",
		Name = "Prism Shard",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "SeaGlassShore",
		Planned = true,
		Value = 0,
		Size = Vector3.new(0.7, 1.4, 0.7),
		Shape = "Block",
		Color = Color3.fromRGB(190, 160, 255),
		Material = Palette.Material.Glass,
	},
	{
		Id = "FrozenCompass",
		Name = "Frozen Compass",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "StrandedIceberg",
		Planned = true,
		Value = 0,
		Size = Vector3.new(1.1, 0.4, 1.1),
		Shape = "Block", -- a flat disc: a cylinder body would lie along X as a thin rod
		Color = Color3.fromRGB(180, 225, 245),
		Material = Palette.Material.Glass,
	},
	{
		Id = "ObsidianEgg",
		Name = "Obsidian Egg",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "BlackSandVents",
		Planned = true,
		Value = 0,
		Size = Vector3.new(0.9, 1.2, 0.9),
		Shape = "Ball",
		Color = Color3.fromRGB(40, 30, 40),
		Material = Palette.Material.Glass,
	},
	-- Beach loot from the doc's biomes. Their biomes don't roll yet, so for now they wash up
	-- anywhere by rarity, like the rest.
	{
		Id = "Rope",
		Name = "Coil of Rope",
		Class = Light,
		Rarity = "Common",
		Tier = 3,
		Value = 24,
		Size = Vector3.new(1.6, 0.5, 1.6),
		Shape = "Block",
		Color = Color3.fromRGB(200, 170, 110),
		Material = Palette.Material.Fabric,
	},
	{
		Id = "OldBoot",
		Name = "Old Boot",
		Class = Light,
		Rarity = "Common",
		Tier = 2,
		Value = 20,
		Size = Vector3.new(0.8, 1.1, 1.6),
		Shape = "Block",
		Color = Color3.fromRGB(90, 60, 40),
		Material = Palette.Material.Fabric,
	},
	{
		Id = "Coconut",
		Name = "Coconut",
		Class = Light,
		Rarity = "Common",
		Tier = 2,
		Value = 24,
		Size = Vector3.new(1.1, 1.1, 1.1),
		Shape = "Ball",
		Color = Color3.fromRGB(120, 85, 50),
	},
	{
		Id = "Snorkel",
		Name = "Snorkel",
		Class = Light,
		Rarity = "Common",
		Tier = 2,
		Value = 36,
		Size = Vector3.new(0.6, 1.8, 0.5),
		Shape = "Block",
		Color = Color3.fromRGB(255, 200, 40),
	},
	{
		Id = "Starfish",
		Name = "Starfish",
		Class = Light,
		Rarity = "Uncommon",
		Tier = 1,
		Value = 64,
		Size = Vector3.new(1.6, 0.3, 1.6),
		Shape = "Block",
		Color = Color3.fromRGB(240, 130, 80),
	},
	{
		Id = "FishingLure",
		Name = "Fishing Lure",
		Class = Light,
		Rarity = "Uncommon",
		Tier = 2,
		Value = 80,
		Size = Vector3.new(0.4, 0.4, 1.1),
		Shape = "Block",
		Color = Color3.fromRGB(255, 90, 60),
	},
	{
		Id = "GlassFloat",
		Name = "Glass Float",
		Class = Light,
		Rarity = "Uncommon",
		Tier = 3,
		Value = 96,
		Size = Vector3.new(1.2, 1.2, 1.2),
		Shape = "Ball",
		Color = Color3.fromRGB(120, 220, 140),
		Material = Palette.Material.Glass,
	},
	{
		Id = "Coral",
		Name = "Coral Branch",
		Class = Light,
		Rarity = "Rare",
		Tier = 3,
		Value = 180,
		Size = Vector3.new(1.2, 1.4, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(255, 110, 130),
	},
	-- Medium
	{
		Id = "Plank",
		Name = "Driftwood Plank",
		Class = Medium,
		Rarity = "Common",
		Tier = 4,
		Value = 56,
		Size = Vector3.new(4, 0.35, 1),
		Shape = "Block",
		Color = Color3.fromRGB(170, 140, 100),
		Material = Palette.Material.Wood,
	},
	{
		-- Old Nell takes these as payment.
		Id = "Net",
		Name = "Tangled Net",
		Class = Medium,
		Rarity = "Common",
		Tier = 3,
		Value = 64,
		Size = Vector3.new(2, 0.7, 2),
		Shape = "Block",
		Color = Color3.fromRGB(205, 200, 185),
		Material = Palette.Material.Fabric,
	},
	{
		Id = "Buoy",
		Name = "Buoy",
		Class = Medium,
		Rarity = "Uncommon",
		Tier = 3,
		Value = 112,
		Size = Vector3.new(1.8, 1.8, 1.8),
		Shape = "Ball",
		Color = Color3.fromRGB(230, 60, 60),
	},
	{
		-- Captain Pebble takes these as payment.
		Id = "BigShell",
		Name = "Big Shell",
		Class = Medium,
		Rarity = "Uncommon",
		Tier = 2,
		Value = 128,
		Size = Vector3.new(1.8, 1.1, 2),
		Shape = "Block",
		Color = Color3.fromRGB(250, 205, 190),
	},
	{
		-- Pip takes these as payment.
		Id = "FrozenFish",
		Name = "Frozen Fish",
		Class = Medium,
		Rarity = "Rare",
		Tier = 4,
		Value = 168,
		Size = Vector3.new(0.8, 0.6, 2.2),
		Shape = "Block",
		Color = Color3.fromRGB(170, 215, 240),
		Material = Palette.Material.Glass,
		Floats = false,
	},
	-- Very heavy: the Electric Winch or better (or Strong Back).
	{
		Id = "TreasureChest",
		Name = "Treasure Chest",
		Class = VeryHeavy,
		Rarity = "VeryRare",
		Tier = 7,
		Value = 1600,
		Size = Vector3.new(3, 2.2, 2.2),
		Shape = "Block",
		Color = Color3.fromRGB(120, 75, 35),
		Material = Palette.Material.Wood,
	},
	{
		Id = "Statue",
		Name = "Old Statue",
		Class = VeryHeavy,
		Rarity = "VeryRare",
		Tier = 7,
		Value = 1440,
		Size = Vector3.new(1.6, 4, 1.6),
		Shape = "Block",
		Color = Color3.fromRGB(196, 186, 170),
		Material = Palette.Material.Rock,
	},
	-- Medium
	{
		Id = "Bucket",
		Name = "Bucket",
		Class = Medium,
		Rarity = "Common",
		Tier = 3,
		Value = 60,
		Size = Vector3.new(1.6, 1.8, 1.6),
		Shape = "Cylinder",
		Color = Color3.fromRGB(255, 190, 50),
	},
	{
		Id = "SmallCrate",
		Name = "Small Crate",
		Class = Medium,
		Rarity = "Uncommon",
		Tier = 4,
		Value = 140,
		Size = Vector3.new(2, 2, 2),
		Shape = "Block",
		Color = Color3.fromRGB(214, 150, 86),
		Material = Palette.Material.WoodPlanks,
	},
	{
		Id = "Lantern",
		Name = "Lantern",
		Class = Medium,
		Rarity = "Rare",
		Tier = 5,
		Value = 320,
		Size = Vector3.new(1.2, 2, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(255, 176, 60),
		Material = Palette.Material.Metal,
	},
	{
		Id = "Spyglass",
		Name = "Spyglass",
		Class = Medium,
		Rarity = "VeryRare",
		Tier = 4,
		Value = 800,
		Size = Vector3.new(2.6, 0.7, 0.7),
		Shape = "Cylinder",
		Color = Color3.fromRGB(225, 185, 80),
		Material = Palette.Material.Metal,
	},
	-- Heavy
	{
		Id = "ShipBell",
		Name = "Ship's Bell",
		Class = Heavy,
		Rarity = "Uncommon",
		Tier = 6,
		Value = 440,
		Size = Vector3.new(2, 2.2, 2),
		Shape = "Cylinder",
		Color = Color3.fromRGB(240, 190, 70),
		Material = Palette.Material.Metal,
	},
	{
		Id = "Barrel",
		Name = "Barrel",
		Class = Heavy,
		Rarity = "Common",
		Tier = 5,
		Value = 220,
		Size = Vector3.new(3, 2.4, 2.4),
		Shape = "Cylinder",
		Color = Color3.fromRGB(190, 120, 62),
		Material = Palette.Material.Wood,
	},
	{
		Id = "BigCrate",
		Name = "Big Crate",
		Class = Heavy,
		Rarity = "Uncommon",
		Tier = 5,
		Value = 360,
		Size = Vector3.new(3.2, 3.2, 3.2),
		Shape = "Block",
		Color = Color3.fromRGB(200, 132, 72),
		Material = Palette.Material.WoodPlanks,
	},
	{
		Id = "Anchor",
		Name = "Anchor",
		Class = Heavy,
		Rarity = "Rare",
		Tier = 6,
		Value = 880,
		Size = Vector3.new(2.4, 3, 0.8),
		Shape = "Block",
		Color = Color3.fromRGB(120, 150, 185),
		Material = Palette.Material.Rust,
	},
	{
		Id = "ShipWheel",
		Name = "Ship's Wheel",
		Class = Heavy,
		Rarity = "VeryRare",
		Tier = 6,
		Value = 1800,
		Size = Vector3.new(0.6, 3.4, 3.4),
		Shape = "Cylinder",
		Color = Color3.fromRGB(176, 112, 60),
		Material = Palette.Material.Wood,
	},
	-- Zone 4 to 7 additions: every zone's tier holds at least one item of each rarity the zone rolls.
	{
		Id = "Oar",
		Name = "Wooden Oar",
		Class = Medium,
		Rarity = "Common",
		Tier = 4,
		Value = 60,
		Size = Vector3.new(3.8, 0.3, 0.7),
		Shape = "Block",
		Color = Color3.fromRGB(190, 140, 85),
		Material = Palette.Material.Wood,
	},
	{
		Id = "LobsterTrap",
		Name = "Lobster Trap",
		Class = Medium,
		Rarity = "Uncommon",
		Tier = 4,
		Value = 136,
		Size = Vector3.new(2.4, 1.3, 1.6),
		Shape = "Block",
		Color = Color3.fromRGB(150, 120, 80),
		Material = Palette.Material.Wood,
	},
	{
		Id = "Cannonball",
		Name = "Cannonball",
		Class = Heavy,
		Rarity = "Common",
		Tier = 5,
		Value = 200,
		Size = Vector3.new(1.2, 1.2, 1.2),
		Shape = "Ball",
		Floats = false,
		Color = Color3.fromRGB(70, 72, 82),
		Material = Palette.Material.Metal,
	},
	{
		Id = "BrassCompass",
		Name = "Brass Compass",
		Class = Light,
		Rarity = "Uncommon",
		Tier = 5,
		Value = 96,
		Size = Vector3.new(1, 0.4, 1.3),
		Shape = "Block",
		Color = Color3.fromRGB(215, 170, 70),
		Material = Palette.Material.Metal,
	},
	{
		Id = "DivingHelmet",
		Name = "Diving Helmet",
		Class = Medium,
		Rarity = "VeryRare",
		Tier = 5,
		Value = 800,
		Size = Vector3.new(1.8, 1.8, 1.8),
		Shape = "Ball",
		Floats = false,
		Color = Color3.fromRGB(190, 145, 65),
		Material = Palette.Material.Metal,
	},
	{
		Id = "IronChain",
		Name = "Iron Chain",
		Class = Heavy,
		Rarity = "Common",
		Tier = 6,
		Value = 200,
		Size = Vector3.new(2.8, 0.5, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(95, 95, 105),
		Material = Palette.Material.Rust,
	},
	{
		Id = "ShipCannon",
		Name = "Ship's Cannon",
		Class = Heavy,
		Rarity = "VeryRare",
		Tier = 6,
		Value = 1700,
		Size = Vector3.new(3.4, 1.3, 1.3),
		Shape = "Cylinder",
		Floats = false,
		Color = Color3.fromRGB(52, 54, 60),
		Material = Palette.Material.Metal,
	},
	{
		Id = "GoldIngots",
		Name = "Gold Ingots",
		Class = Heavy,
		Rarity = "Rare",
		Tier = 7,
		Value = 880,
		Size = Vector3.new(2.2, 1.2, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(240, 195, 60),
		Material = Palette.Material.Foil,
	},
	{
		Id = "JeweledGoblet",
		Name = "Jeweled Goblet",
		Class = Medium,
		Rarity = "Rare",
		Tier = 7,
		Value = 320,
		Size = Vector3.new(1, 1.5, 1),
		Shape = "Block",
		Color = Color3.fromRGB(235, 190, 70),
		Material = Palette.Material.Foil,
	},
	{
		Id = "GoldCrown",
		Name = "Golden Crown",
		Class = Medium,
		Rarity = "VeryRare",
		Tier = 7,
		Value = 800,
		Size = Vector3.new(1.6, 1, 1.6),
		Shape = "Block",
		Color = Color3.fromRGB(245, 200, 60),
		Material = Palette.Material.Foil,
	},
	-- Biome items (docs/design/biome-items.md): they wash up only in their Biome, replace part of
	-- its zone's spawns, take the tier of the zone they land in, and are worth a premium over the
	-- zone's normal finds, set when they spawn (Items.biomeValue): Value here is a placeholder.
	{
		Id = "SandDollar",
		Name = "Sand Dollar",
		Biome = "SandcastleFlats",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.2, 0.15, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(235, 220, 180),
		Material = Palette.Material.Sand,
	},
	{
		Id = "ToySpade",
		Name = "Toy Spade",
		Biome = "SandcastleFlats",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(0.6, 0.3, 2.0),
		Shape = "Block",
		Color = Color3.fromRGB(230, 70, 60),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "CastleFlag",
		Name = "Castle Flag",
		Biome = "SandcastleFlats",
		Class = Light,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(0.3, 2.2, 0.8),
		Shape = "Block",
		Color = Color3.fromRGB(240, 200, 60),
		Material = Palette.Material.Fabric,
	},
	{
		Id = "GildedTurret",
		Name = "Gilded Turret",
		Biome = "SandcastleFlats",
		Class = Medium,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(1.4, 2.0, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(225, 185, 90),
		Material = Palette.Material.Foil,
	},
	{
		Id = "SandKingsCrown",
		Name = "Sand King's Crown",
		Biome = "SandcastleFlats",
		Class = Light,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.6, 0.9, 1.6),
		Shape = "Block",
		Color = Color3.fromRGB(250, 210, 80),
		Material = Palette.Material.Foil,
	},
	{
		Id = "DriftwoodBranch",
		Name = "Driftwood Branch",
		Biome = "DriftwoodCove",
		Class = Medium,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(3.0, 0.5, 0.6),
		Shape = "Block",
		Color = Color3.fromRGB(180, 160, 135),
		Material = Palette.Material.Wood,
	},
	{
		Id = "WovenBasket",
		Name = "Woven Basket",
		Biome = "DriftwoodCove",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.4, 1.0, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(190, 150, 95),
		Material = Palette.Material.Fabric,
	},
	{
		Id = "CarvedFloat",
		Name = "Carved Float",
		Biome = "DriftwoodCove",
		Class = Light,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(1.2, 0.7, 0.7),
		Shape = "Block",
		Color = Color3.fromRGB(160, 110, 70),
		Material = Palette.Material.Wood,
	},
	{
		Id = "DriftwoodTotem",
		Name = "Driftwood Totem",
		Biome = "DriftwoodCove",
		Class = Medium,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(0.9, 2.4, 0.9),
		Shape = "Block",
		Color = Color3.fromRGB(150, 105, 70),
		Material = Palette.Material.Wood,
	},
	{
		Id = "AncientFigurehead",
		Name = "Ancient Figurehead",
		Biome = "DriftwoodCove",
		Class = Heavy,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.2, 2.6, 1.8),
		Shape = "Block",
		Color = Color3.fromRGB(170, 120, 80),
		Material = Palette.Material.Wood,
	},
	{
		Id = "HermitCrabShell",
		Name = "Hermit Crab Shell",
		Biome = "TidepoolRocks",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.0, 0.8, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(220, 170, 140),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "SeaUrchin",
		Name = "Sea Urchin",
		Biome = "TidepoolRocks",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(0.9, 0.9, 0.9),
		Shape = "Ball",
		Color = Color3.fromRGB(90, 50, 120),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "PearlOyster",
		Name = "Pearl Oyster",
		Biome = "TidepoolRocks",
		Class = Light,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(1.2, 0.6, 1.0),
		Shape = "Block",
		Color = Color3.fromRGB(170, 160, 150),
		Material = Palette.Material.Rock,
	},
	{
		Id = "CoralFan",
		Name = "Living Coral Fan",
		Biome = "TidepoolRocks",
		Class = Light,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(1.6, 1.6, 0.3),
		Shape = "Block",
		Color = Color3.fromRGB(240, 110, 150),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "GiantClamPearl",
		Name = "Giant Clam Pearl",
		Biome = "TidepoolRocks",
		Class = Medium,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.4, 1.4, 1.4),
		Shape = "Ball",
		Color = Color3.fromRGB(245, 240, 255),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "KelpBundle",
		Name = "Kelp Bundle",
		Biome = "SeagrassShallows",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.4, 0.5, 0.8),
		Shape = "Block",
		Color = Color3.fromRGB(70, 120, 60),
		Material = Palette.Material.Grass,
	},
	{
		Id = "DriedSeahorse",
		Name = "Dried Seahorse",
		Biome = "SeagrassShallows",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(0.4, 1.2, 0.5),
		Shape = "Block",
		Color = Color3.fromRGB(220, 170, 80),
		Material = Palette.Material.Sand,
	},
	{
		Id = "JettySign",
		Name = "Old Jetty Sign",
		Biome = "SeagrassShallows",
		Class = Medium,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(2.0, 1.2, 0.3),
		Shape = "Block",
		Color = Color3.fromRGB(140, 110, 80),
		Material = Palette.Material.WoodPlanks,
	},
	{
		Id = "MermaidsMirror",
		Name = "Mermaid's Mirror",
		Biome = "SeagrassShallows",
		Class = Light,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(1.0, 1.4, 0.2),
		Shape = "Block",
		Color = Color3.fromRGB(190, 220, 230),
		Material = Palette.Material.Glass,
	},
	{
		Id = "SeaPearlNecklace",
		Name = "Sea Pearl Necklace",
		Biome = "SeagrassShallows",
		Class = Light,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.2, 0.3, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(230, 240, 220),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "BrainCoral",
		Name = "Brain Coral",
		Biome = "CoralGarden",
		Class = Medium,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.4, 1.1, 1.4),
		Shape = "Ball",
		Color = Color3.fromRGB(230, 150, 120),
		Material = Palette.Material.Rock,
	},
	{
		Id = "ParrotfishScale",
		Name = "Parrotfish Scale",
		Biome = "CoralGarden",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(0.8, 0.15, 1.0),
		Shape = "Block",
		Color = Color3.fromRGB(80, 200, 190),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "QueenConch",
		Name = "Queen Conch",
		Biome = "CoralGarden",
		Class = Light,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(1.4, 1.0, 1.0),
		Shape = "Block",
		Color = Color3.fromRGB(245, 180, 160),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "RedCoralBranch",
		Name = "Red Coral Branch",
		Biome = "CoralGarden",
		Class = Light,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(1.2, 1.8, 0.4),
		Shape = "Block",
		Color = Color3.fromRGB(220, 40, 60),
		Material = Palette.Material.Rock,
	},
	{
		Id = "ReefDiadem",
		Name = "Reef Queen's Diadem",
		Biome = "CoralGarden",
		Class = Light,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.5, 0.8, 1.5),
		Shape = "Block",
		Color = Color3.fromRGB(250, 120, 170),
		Material = Palette.Material.Foil,
	},
	{
		Id = "BrassPorthole",
		Name = "Brass Porthole",
		Biome = "ShipwreckShallows",
		Class = Medium,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.4, 1.4, 0.4),
		Shape = "Block",
		Color = Color3.fromRGB(180, 140, 70),
		Material = Palette.Material.Metal,
	},
	{
		Id = "ShipsLogbook",
		Name = "Ship's Logbook",
		Biome = "ShipwreckShallows",
		Class = Light,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(1.0, 0.3, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(120, 80, 50),
		Material = Palette.Material.Fabric,
	},
	{
		Id = "SilverDoubloons",
		Name = "Silver Doubloons",
		Biome = "ShipwreckShallows",
		Class = Light,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(1.0, 0.4, 1.0),
		Shape = "Block",
		Color = Color3.fromRGB(200, 205, 215),
		Material = Palette.Material.Metal,
	},
	{
		Id = "TreasureMap",
		Name = "Captain's Treasure Map",
		Biome = "ShipwreckShallows",
		Class = Light,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.6, 0.1, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(220, 200, 150),
		Material = Palette.Material.Fabric,
	},
	{
		Id = "FogBell",
		Name = "Fog Bell",
		Biome = "FogBank",
		Class = Medium,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.2, 1.4, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(150, 160, 170),
		Material = Palette.Material.Metal,
	},
	{
		Id = "KeepersLogbook",
		Name = "Keeper's Logbook",
		Biome = "FogBank",
		Class = Light,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(1.0, 0.3, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(90, 70, 60),
		Material = Palette.Material.Fabric,
	},
	{
		Id = "LostShipsLamp",
		Name = "Lost Ship's Lamp",
		Biome = "FogBank",
		Class = Medium,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(0.9, 1.6, 0.9),
		Shape = "Block",
		Color = Color3.fromRGB(200, 190, 140),
		Material = Palette.Material.Metal,
	},
	{
		Id = "LighthouseLens",
		Name = "Lighthouse Lens",
		Biome = "FogBank",
		Class = Medium,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.8, 1.8, 1.0),
		Shape = "Block",
		Color = Color3.fromRGB(210, 235, 255),
		Material = Palette.Material.Glass,
	},
	{
		Id = "MoonJelly",
		Name = "Moon Jelly",
		Biome = "JellyfishLagoon",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.2, 0.6, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(200, 210, 255),
		Material = Palette.Material.Glass,
	},
	{
		Id = "GlowShell",
		Name = "Glow Shell",
		Biome = "JellyfishLagoon",
		Class = Light,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(1.0, 0.7, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(120, 240, 220),
		Material = Palette.Material.Neon,
	},
	{
		Id = "BoxJellyLantern",
		Name = "Box Jelly Lantern",
		Biome = "JellyfishLagoon",
		Class = Light,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(0.9, 1.3, 0.9),
		Shape = "Block",
		Color = Color3.fromRGB(170, 140, 255),
		Material = Palette.Material.Glass,
	},
	{
		Id = "CrownJelly",
		Name = "Crown Jelly",
		Biome = "JellyfishLagoon",
		Class = Light,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.6, 1.0, 1.6),
		Shape = "Block",
		Color = Color3.fromRGB(255, 150, 230),
		Material = Palette.Material.Glass,
	},
	{
		Id = "MoltedClaw",
		Name = "Molted Claw",
		Biome = "HermitHollows",
		Class = Medium,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.8, 0.7, 0.9),
		Shape = "Block",
		Color = Color3.fromRGB(210, 90, 60),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "ShellBead",
		Name = "Polished Shell Bead",
		Biome = "HermitHollows",
		Class = Light,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(0.7, 0.7, 0.7),
		Shape = "Ball",
		Color = Color3.fromRGB(240, 200, 170),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "CrabCarapace",
		Name = "Giant Crab Carapace",
		Biome = "HermitHollows",
		Class = Heavy,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(2.6, 1.0, 2.2),
		Shape = "Block",
		Color = Color3.fromRGB(190, 80, 50),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "CrabKingsHoard",
		Name = "Crab King's Hoard",
		Biome = "HermitHollows",
		Class = Heavy,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.8, 1.4, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(230, 190, 90),
		Material = Palette.Material.Foil,
	},
	{
		Id = "SandGlassShard",
		Name = "Sand-Glass Shard",
		Biome = "WhirlwindDunes",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.0, 0.3, 0.8),
		Shape = "Block",
		Color = Color3.fromRGB(230, 220, 180),
		Material = Palette.Material.Glass,
	},
	{
		Id = "Fulgurite",
		Name = "Fulgurite",
		Biome = "WhirlwindDunes",
		Class = Medium,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(0.6, 2.0, 0.6),
		Shape = "Block",
		Color = Color3.fromRGB(120, 110, 100),
		Material = Palette.Material.Rock,
	},
	{
		Id = "DesertRose",
		Name = "Desert Rose",
		Biome = "WhirlwindDunes",
		Class = Medium,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(1.4, 1.1, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(210, 160, 130),
		Material = Palette.Material.Sand,
	},
	{
		Id = "StormIdol",
		Name = "Storm-Tossed Idol",
		Biome = "WhirlwindDunes",
		Class = Heavy,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.0, 2.2, 1.0),
		Shape = "Block",
		Color = Color3.fromRGB(200, 170, 90),
		Material = Palette.Material.Rock,
	},
	{
		Id = "SpearstoneChip",
		Name = "Spearstone Chip",
		Biome = "SpearstoneReef",
		Class = Light,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(0.6, 1.2, 0.4),
		Shape = "Block",
		Color = Color3.fromRGB(110, 120, 140),
		Material = Palette.Material.Rock,
	},
	{
		Id = "BarnacledSpearhead",
		Name = "Barnacled Spearhead",
		Biome = "SpearstoneReef",
		Class = Medium,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(0.6, 2.0, 0.3),
		Shape = "Block",
		Color = Color3.fromRGB(120, 130, 120),
		Material = Palette.Material.Rock,
	},
	{
		Id = "StoneSpear",
		Name = "Stone Spear",
		Biome = "SpearstoneReef",
		Class = Medium,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(0.5, 4.0, 0.5),
		Shape = "Block",
		Color = Color3.fromRGB(140, 150, 160),
		Material = Palette.Material.Rock,
	},
	{
		Id = "AncientTrident",
		Name = "Ancient Trident",
		Biome = "SpearstoneReef",
		Class = Heavy,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(1.2, 4.0, 0.4),
		Shape = "Block",
		Color = Color3.fromRGB(90, 170, 170),
		Material = Palette.Material.Metal,
	},
	{
		Id = "IceChunk",
		Name = "Ice Chunk",
		Biome = "StrandedIceberg",
		Class = Medium,
		Rarity = "Common",
		Value = 0,
		Size = Vector3.new(1.4, 1.2, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(200, 230, 255),
		Material = Palette.Material.Glass,
	},
	{
		Id = "FrozenHerringCrate",
		Name = "Frozen Herring Crate",
		Biome = "StrandedIceberg",
		Class = Medium,
		Rarity = "Uncommon",
		Value = 0,
		Size = Vector3.new(1.6, 1.0, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(170, 200, 220),
		Material = Palette.Material.WoodPlanks,
	},
	{
		Id = "MammothTusk",
		Name = "Mammoth Tusk",
		Biome = "StrandedIceberg",
		Class = Heavy,
		Rarity = "Rare",
		Value = 0,
		Size = Vector3.new(0.7, 0.7, 3.4),
		Shape = "Block",
		Color = Color3.fromRGB(235, 225, 200),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "IceLockedChest",
		Name = "Ice-Locked Chest",
		Biome = "StrandedIceberg",
		Class = Heavy,
		Rarity = "VeryRare",
		Value = 0,
		Size = Vector3.new(2.0, 1.6, 1.4),
		Shape = "Block",
		Color = Color3.fromRGB(150, 200, 240),
		Material = Palette.Material.Glass,
	},
}

-- The highest tier: the Far Sandbar (Config.Zones[7]).
Items.MaxTier = 7

local byId = {}
local byRarity = {}
local byTier = {} -- tier -> rarity -> items
local byBiome = {} -- biome id -> rarity -> items
Items.BiomeOrder = {} -- biome ids that have items, in catalog order (the collection log's pages)
for _, rarity in Items.Rarities do
	byRarity[rarity] = {}
end
for tier = 1, Items.MaxTier do
	byTier[tier] = {}
	for _, rarity in Items.Rarities do
		byTier[tier][rarity] = {}
	end
end
for _, item in Items.Catalog do
	byId[item.Id] = item
	if item.Biome then
		if not byBiome[item.Biome] then
			byBiome[item.Biome] = {}
			for _, rarity in Items.Rarities do
				byBiome[item.Biome][rarity] = {}
			end
			table.insert(Items.BiomeOrder, item.Biome)
		end
		if byBiome[item.Biome][item.Rarity] then
			table.insert(byBiome[item.Biome][item.Rarity], item)
		end
		continue -- (not in the normal pools)
	end
	if byRarity[item.Rarity] then
		table.insert(byRarity[item.Rarity], item)
	end
	if item.Tier and byTier[item.Tier] and byTier[item.Tier][item.Rarity] then
		table.insert(byTier[item.Tier][item.Rarity], item)
	end
end

-- The items the lexicon counts: everything that can wash up now. Planned items (unlock items
-- for biomes that don't roll yet) join it when their biome does. Biome items are not in it: they
-- have a page each (Items.ofBiome), and the tower man's check ignores them.
Items.Lexicon = {}
for _, item in Items.Catalog do
	if not item.Planned and not item.Biome then
		table.insert(Items.Lexicon, item)
	end
end

function Items.get(id: string)
	return byId[id]
end

function Items.ofRarity(rarity: string)
	return byRarity[rarity] or {}
end

-- The items of a zone tier and rarity (what that zone's surf can wash up at that rarity).
function Items.ofTier(tier: number, rarity: string)
	local tierItems = byTier[tier]
	return if tierItems then tierItems[rarity] or {} else {}
end

-- A biome's items of a rarity, or all of its items when no rarity is given.
function Items.ofBiome(biomeId: string, rarity: string?)
	local pools = byBiome[biomeId]
	if not pools then
		return {}
	end
	if rarity then
		return pools[rarity] or {}
	end
	local all = {}
	for _, name in Items.Rarities do
		for _, item in pools[name] do
			table.insert(all, item)
		end
	end
	return all
end

-- The rarity nearest to `rarity` for which `has(rarity)` holds, the rarer one first on a tie
-- (and `rarity` itself when it holds); nil when none does. A spawn of a rarity its pool has no
-- items of takes this one: normal finds (ItemService.chooseDef), biome items likewise.
function Items.nearestRarity(rarity: string, has: (string) -> boolean): string?
	local index = table.find(Items.Rarities, rarity) or 1
	for offset = 0, #Items.Rarities do
		for _, step in { offset, -offset } do
			local other = Items.Rarities[index + step]
			if other and has(other) then
				return other
			end
		end
	end
	return nil
end

-- A zone's average normal find, as its Value attribute shows it (the zone's multiplier
-- included), and its average rarity weight (Config.Biomes.RarityWorth) under the zone's Rarity
-- table. Both follow the zone's table as written: the private-server scale-down of rare spawns
-- (Items.scaleRare) is not part of it, so a biome's premium holds on any server.
local zoneStats: { [number]: { Average: number, Worth: number } } = {}

local function zoneStatsOf(zone: number)
	local cached = zoneStats[zone]
	if cached then
		return cached
	end
	local weights = Config.Zones[zone].Rarity or {}
	local total, value, worth = 0, 0, 0
	for rarity, weight in weights do
		total += weight
		worth += weight * (Config.Biomes.RarityWorth[rarity] or 0)
		local pickRarity = Items.nearestRarity(rarity, function(other)
			return #Items.ofTier(zone, other) > 0
		end)
		local pool = if pickRarity then Items.ofTier(zone, pickRarity) else {}
		local sum = 0
		for _, item in pool do
			sum += item.Value
		end
		if #pool > 0 then
			value += weight * sum / #pool
		end
	end
	cached = {
		Average = if total > 0 then value / total * Config.Zones[zone].Multiplier else 0,
		Worth = if total > 0 then worth / total else 1,
	}
	zoneStats[zone] = cached
	return cached
end

-- The Value attribute of a biome item of `rarity` that washes up in zone `zone` in a biome of
-- biome tier `biomeTier` (Biomes.List[id].Tier): the zone's average normal find x the biome's
-- premium (Config.Biomes.Premium) x the rarity's weight / the zone's average rarity weight. So
-- a biome's average find is its premium over the zone's normal average wherever it rolls.
function Items.biomeValue(zone: number, biomeTier: string, rarity: string): number
	local stats = zoneStatsOf(zone)
	local premium = Config.Biomes.Premium[biomeTier] or 1
	local worth = Config.Biomes.RarityWorth[rarity] or 1
	return math.floor(stats.Average * premium * worth / stats.Worth)
end

-- Rolls a rarity from a weight table such as { Common = 70, Uncommon = 25, Rare = 5 }.
-- Rarity weights with everything rarer than Uncommon multiplied by `scale` (private
-- servers with few players, see MonetizationService). The weight taken away goes to
-- Common, so zones that only roll rares (the Far Sandbar) scale too.
function Items.scaleRare(weights: { [string]: number }, scale: number): { [string]: number }
	if scale >= 1 then
		return weights
	end
	local scaled = {}
	local removed = 0
	for rarity, weight in weights do
		if rarity == "Common" or rarity == "Uncommon" then
			scaled[rarity] = weight
		else
			scaled[rarity] = weight * scale
			removed += weight - weight * scale
		end
	end
	scaled.Common = (scaled.Common or 0) + removed
	return scaled
end

-- Whether an item floats in the sea. Round things (balls and cylinders) roll down the
-- seabed otherwise, so they float unless the item sets Floats = false.
function Items.floats(def): boolean
	if def.Floats ~= nil then
		return def.Floats
	end
	return def.Shape == "Ball" or def.Shape == "Cylinder"
end

function Items.rollRarity(weights: { [string]: number }, rng: Random): string
	local total = 0
	for _, rarity in Items.Rarities do
		total += weights[rarity] or 0
	end
	local roll = rng:NextNumber() * total
	for _, rarity in Items.Rarities do
		roll -= weights[rarity] or 0
		if roll <= 0 and (weights[rarity] or 0) > 0 then
			return rarity
		end
	end
	return "Common"
end

return Items
