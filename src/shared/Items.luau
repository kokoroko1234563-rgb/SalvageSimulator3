-- Beach loot. Value is the base sell price before the zone multiplier. Size, Shape and
-- Color set the physics body and the colour the item is named by; the visible model is
-- built from them in src/server/ItemModels.luau.
--
-- Tier (1 to 7) is the zone the item washes up in: a zone's surf and loot spots draw only from
-- items of its own tier (the zone's Rarity table still picks the rarity within it), and a tool
-- lifts every item up to its own tier (Gear.Tools). Unlock items have no tier: they are always
-- liftable. Class (Light to Very heavy) is only the physical feel: density when dragged, what
-- fits in pockets, and where in the water it lies.

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
}

-- The highest tier: the Far Sandbar (Config.Zones[7]).
Items.MaxTier = 7

local byId = {}
local byRarity = {}
local byTier = {} -- tier -> rarity -> items
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
	if byRarity[item.Rarity] then
		table.insert(byRarity[item.Rarity], item)
	end
	if item.Tier and byTier[item.Tier] and byTier[item.Tier][item.Rarity] then
		table.insert(byTier[item.Tier][item.Rarity], item)
	end
end

-- The items the lexicon counts: everything that can wash up now. Planned items (unlock items
-- for biomes that don't roll yet) join it when their biome does.
Items.Lexicon = {}
for _, item in Items.Catalog do
	if not item.Planned then
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
