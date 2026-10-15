-- Biomes. Each tide cycle every tile of the beach rolls a biome (or none). The server stores
-- the result on Workspace attributes ("TileBiome1", ...) so every client sees the same thing.
-- So far: Sandcastle Flats (common, normal secret) and Shipwreck Shallows (rare, exotic
-- secret). The rest of the doc's biomes slot in here.

local Workspace = game:GetService("Workspace")

local Biomes = {}

-- Each biome in the list rolls on the beach. Its fields:
--   Zones        { [zone] = weight }: the zones it can roll in, and how often (against the
--                other biomes there and Config.Biomes.NoneWeight).
--   Loot, LootShare  the zone's surf spawns: this share comes from Loot.
--   Hazards      a list of hazard entries (see Hazards.luau): { Type = "Patrol", ... }.
--   Secret, UnlockItem, Entrance, EntranceSpots  its secret and the entrance to it. A biome
--                without a Secret has no entrance (its secret isn't built yet).
--   Scenery      which decor builder dresses it (BiomeService); without one, it's scattered
--                with mounds in its Decor colour.
-- Its ground comes from its layout (src/shared/Layouts/Biomes/<Id>).
Biomes.List = {
	SandcastleFlats = {
		Id = "SandcastleFlats",
		Name = "Sandcastle Flats",
		Tier = "Common",
		Zones = { [1] = 45, [2] = 45, [3] = 40, [4] = 30 },
		Loot = { "Bucket", "Sunglasses", "BeachBall", "FlipFlop" },
		LootShare = 0.6, -- this share of the zone's surf spawns comes from Loot
		UnlockItem = "GoldenSpade",
		Secret = "SandcastleFlats",
		EntranceSpots = { -110, -40, 40, 110 }, -- X positions the secret's sandcastle can stand at
		Entrance = "Sandcastle",
		Scenery = "Sandcastle",
		Decor = Color3.fromRGB(230, 200, 140),
	},
	ShipwreckShallows = {
		Id = "ShipwreckShallows",
		Name = "Shipwreck Shallows",
		Tier = "Uncommon", -- a rare biome: never announced
		Zones = { [2] = 15, [3] = 15, [4] = 15, [5] = 15, [6] = 12 },
		Loot = { "Barrel", "SmallCrate", "Lantern", "GlassBottle", "ShipBell" },
		LootShare = 0.6,
		UnlockItem = "CaptainsKey",
		Secret = "ShipwreckShallows",
		EntranceSpots = { -100, -20, 60, 120 },
		Entrance = "Wreck",
		Scenery = "Wreck",
		-- Barrels roll down the sand on a fixed timer: getting hit knocks what you hold out of
		-- your hands. Learnable, so a hit feels like a mistake.
		Hazards = {
			{
				Type = "Roller",
				Period = 6,
				Speed = 16,
				HitText = "A barrel knocked it out of your hands!",
			},
		},
		Decor = Color3.fromRGB(105, 75, 50),
	},
	HermitHollows = {
		Id = "HermitHollows",
		Name = "Hermit Hollows",
		Tier = "Rare", -- never announced
		Zones = { [4] = 8, [5] = 12, [6] = 15 },
		Loot = { "BigShell" },
		LootShare = 0.5,
		UnlockItem = "SpiralConch", -- (its secret isn't built yet, so it has no entrance)
		-- Hermit crabs patrol the maze's corridors: run into one and you're knocked flat.
		Hazards = {
			{
				Type = "Patrol",
				Count = 4,
				Speed = 7,
				Color = Color3.fromRGB(200, 95, 70),
				HitText = "A hermit crab knocked you flat!",
			},
		},
		Decor = Color3.fromRGB(225, 205, 180),
	},
}

-- The doc's other biomes, written down so their items exist and point somewhere. They don't
-- roll yet: each needs its decor, entrance, secret course and hazard built first. Moving one
-- into Biomes.List (with those) is what turns it on. Coin = the normal secret's colored coin;
-- Rewards = the exotic secret's lootbox (all in Gear); Variant = its rare cosmetic variant.
Biomes.Planned = {
	DriftwoodCove = {
		Name = "Driftwood Cove",
		Tier = "Common",
		Loot = { "Plank", "Rope", "GlassBottle", "OldBoot" },
		UnlockItem = "CarvedIdol",
		Entrance = "Hollow beached tree trunk",
		Coin = "Orange",
	},
	TidepoolRocks = {
		Name = "Tidepool Rocks",
		Tier = "Common",
		Loot = { "Seashell", "Starfish", "FishingLure" },
		UnlockItem = "PearlEyedShell",
		Entrance = "Blowhole in the rocks",
		Coin = "Blue",
	},
	SeagrassShallows = {
		Name = "Seagrass Shallows",
		Tier = "Common",
		Loot = { "Buoy", "Net", "GlassFloat" },
		UnlockItem = "BarnacledLantern",
		Entrance = "Under a collapsed jetty",
		Coin = "Green",
	},
	CoralGarden = {
		Name = "Coral Garden",
		Tier = "Common",
		Loot = { "Coral", "Snorkel", "Coconut" },
		UnlockItem = "CoralComb",
		Entrance = "Arch in the reef",
		Coin = "Pink",
	},
	JellyfishLagoon = {
		Name = "Jellyfish Lagoon",
		Tier = "Uncommon",
		UnlockItem = "JellyJar",
		Hazard = "Jellyfish: a sting drops what you hold",
		Rewards = { "JellyRaft", "GlowPearl" },
	},
	FogBank = {
		Name = "Fog Bank",
		Tier = "Uncommon",
		UnlockItem = "LighthouseKey",
		Hazard = "Thick fog, cleared briefly by a foghorn pulse",
		Rewards = { "LanternOfClearSight", "Foghorn" },
	},
	WhirlwindDunes = {
		Name = "Whirlwind Dunes",
		Tier = "Rare",
		UnlockItem = "WindChime",
		Hazard = "Tornado circling the zone",
		Rewards = { "MagicCarpet", "GustGloves" },
	},
	SpearstoneReef = {
		Name = "Spearstone Reef",
		Tier = "Rare",
		UnlockItem = "SpearstoneShard",
		Hazard = "Spears shooting from the floor on a timer",
		Rewards = { "TidewalkerBoots" },
	},
	SeaGlassShore = {
		Name = "Sea-Glass Shore",
		Tier = "VeryRare",
		UnlockItem = "PrismShard",
		Hazard = "Sharp glass patches that slow you",
		Rewards = { "PrismLens", "GlassSwan" },
		Variant = "Sea-glass",
	},
	StrandedIceberg = {
		Name = "Stranded Iceberg",
		Tier = "VeryRare",
		Loot = { "FrozenFish" },
		UnlockItem = "FrozenCompass",
		Hazard = "Slippery ice: vessels slide and spill",
		Rewards = { "FrostSled", "FreezeWand" },
		Variant = "Frosted",
	},
	BlackSandVents = {
		Name = "Black Sand Vents",
		Tier = "VeryRare",
		UnlockItem = "ObsidianEgg",
		Hazard = "Steam vents erupting on a timer",
		Rewards = { "EmberLantern", "ObsidianGrabber" },
		Variant = "Ember",
	},
}

-- Each tile of the beach (see Beach.tileAt) rolls its own biome.
function Biomes.attributeFor(tile: number): string
	return "TileBiome" .. tile
end

-- The biome on a tile right now (nil: none).
function Biomes.activeIn(tile: number?): any
	if not tile or tile < 1 then
		return nil
	end
	local id = Workspace:GetAttribute(Biomes.attributeFor(tile))
	return id and Biomes.List[id] or nil
end

-- Finds a biome by id or name, ignoring case, spaces and punctuation ("sandcastle" works).
function Biomes.find(query: string): any
	local key = query:lower():gsub("[%s%-_']", "")
	for id, biome in Biomes.List do
		local idKey = id:lower()
		local nameKey = biome.Name:lower():gsub("[%s%-_']", "")
		if idKey == key or nameKey == key or idKey:sub(1, #key) == key then
			return biome
		end
	end
	return nil
end

return Biomes
