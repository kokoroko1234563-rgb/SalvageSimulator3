-- Biomes. Each tide cycle every tile of the beach rolls a biome (or none). The server stores
-- the result on Workspace attributes ("TileBiome1", ...) so every client sees the same thing.
-- So far: Sandcastle Flats (common, normal secret) and Shipwreck Shallows (rare, exotic
-- secret). The rest of the doc's biomes slot in here.

local Workspace = game:GetService("Workspace")

local Biomes = {}

-- Each biome in the list rolls on the beach. Its fields:
--   Zones        { [zone] = weight }: the zones it can roll in, and how often (against the
--                other biomes there, once a zone has rolled to get a biome at all:
--                Config.Biomes.Chance). Each biome turns up at most once a tide.
--   Loot, LootShare  the zone's surf spawns: this share comes from Loot.
--   Hazards      a list of hazard entries (see Hazards.luau): { Type = "Patrol", ... }.
--   Secret, UnlockItem, Entrance, EntranceSpots  its secret and the entrance to it. A biome
--                without a Secret has no entrance (its secret isn't built yet).
--   Scenery      which decor builder dresses it (BiomeService); without one, it's scattered
--                with mounds in its Decor colour.
--   Look         how it looks over its zone: its ground, rock, fog and light (see Looks.luau).
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
		-- Bright, warm and clear: a holiday in the sun.
		Look = {
			Floor = "Sand",
			Fog = -0.08,
			Haze = Color3.fromRGB(255, 226, 170),
			Tint = Color3.fromRGB(255, 240, 215),
			Brightness = 0.2,
			Saturation = 0.12,
			Mix = 0.5,
		},
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
			{ Type = "Pit", Scatter = false },
			{ Type = "Undertow", Scatter = false },
		},
		Decor = Color3.fromRGB(105, 75, 50),
		-- Tarry sand under a brown, smoky sepia haze.
		Look = {
			Floor = "Pavement",
			Rock = "Slate",
			Fog = 0.08,
			Haze = Color3.fromRGB(170, 140, 105),
			Decay = Color3.fromRGB(95, 70, 50),
			Tint = Color3.fromRGB(245, 225, 200),
			Saturation = -0.12,
			Contrast = 0.06,
		},
	},
	HermitHollows = {
		Id = "HermitHollows",
		Name = "Hermit Hollows",
		Tier = "Rare", -- never announced
		Zones = { [4] = 8, [5] = 12, [6] = 15 },
		Loot = { "BigShell" },
		LootShare = 0.5,
		UnlockItem = "SpiralConch", -- (its secret isn't built yet, so it has no entrance)
		-- Hermit crabs patrol the maze's corridors: run into one and you're knocked flat. The giant
		-- one hunts down the longest of them.
		Hazards = {
			{
				Type = "Patrol",
				Count = 4,
				Speed = 7,
				Calls = true, -- one that spots you drums for the giant
				Color = Color3.fromRGB(200, 95, 70),
				HitText = "A hermit crab knocked you flat!",
			},
			-- And the giant one: it hunts down its tunnel, sees a light a long way off, and kills.
			{ Type = "Hunter", HitText = "The giant hermit crab got you!" },
		},
		Decor = Color3.fromRGB(225, 205, 180),
		-- Crushed-shell grit and shell-crusted rock in a warm, dim, coral-pink gloom.
		Look = {
			Floor = "Concrete",
			Rock = "Cobblestone",
			Fog = 0.06,
			Haze = Color3.fromRGB(200, 150, 140),
			Decay = Color3.fromRGB(120, 70, 70),
			Ambient = Color3.fromRGB(120, 85, 80),
			Tint = Color3.fromRGB(255, 225, 215),
			Brightness = -0.15,
			Mix = 0.55,
		},
	},
	DriftwoodCove = {
		Id = "DriftwoodCove",
		-- The pools behind the jams slow you where its layout puts them; zones 3 and 4 add open
		-- spike pits and quicksand, off the cart route.
		Hazards = {
			{ Type = "Slow", Scatter = false, Factor = 0.7, Color = Color3.fromRGB(90, 110, 120) },
			{ Type = "Pit", Scatter = false },
			{ Type = "Sink", Scatter = false },
		},
		Zones = { [1] = 30, [2] = 30, [3] = 25, [4] = 20 },
		LootShare = 0.6,
		Decor = Color3.fromRGB(196, 170, 136),
		Name = "Driftwood Cove",
		Tier = "Common",
		Loot = { "Plank", "Rope", "GlassBottle", "OldBoot" },
		UnlockItem = "CarvedIdol",
		Entrance = "Hollow beached tree trunk",
		Coin = "Orange",
		Look = { Haze = Color3.fromRGB(225, 190, 150), Tint = Color3.fromRGB(255, 235, 210), Mix = 0.4 },
	},
	TidepoolRocks = {
		Id = "TidepoolRocks",
		-- The pools slow you where its layout puts them; blowholes in the benches spout on a timer
		-- (a knockback, a warning first).
		Hazards = {
			{ Type = "Slow", Scatter = false, Factor = 0.7, Color = Color3.fromRGB(80, 130, 150) },
			{
				Type = "Pulse",
				Scatter = false,
				Period = 9,
				Warning = 2,
				Active = 1.2,
				Radius = 5,
				Effect = "Knockdown",
				Push = 40,
				HitText = "A blowhole spouted under you!",
				Color = Color3.fromRGB(200, 225, 235),
			},
		},
		Zones = { [1] = 30, [2] = 30, [3] = 25, [4] = 20 },
		LootShare = 0.6,
		Decor = Color3.fromRGB(120, 140, 150),
		Name = "Tidepool Rocks",
		Tier = "Common",
		Loot = { "Seashell", "Starfish", "FishingLure" },
		UnlockItem = "PearlEyedShell",
		Entrance = "Blowhole in the rocks",
		Coin = "Blue",
		Look = { Rock = "Slate", Haze = Color3.fromRGB(160, 205, 230), Saturation = 0.1, Mix = 0.4 },
	},
	SeagrassShallows = {
		Id = "SeagrassShallows",
		Zones = { [1] = 30, [2] = 30, [3] = 25, [4] = 20 },
		LootShare = 0.6,
		Decor = Color3.fromRGB(110, 150, 100),
		-- Tangling seagrass slows you where its layout puts it (gentle: a common biome).
		Hazards = { { Type = "Slow", Scatter = false, Factor = 0.6, Color = Color3.fromRGB(70, 120, 60) } },
		Name = "Seagrass Shallows",
		Tier = "Common",
		Loot = { "Buoy", "Net", "GlassFloat" },
		UnlockItem = "BarnacledLantern",
		Entrance = "Under a collapsed jetty",
		Coin = "Green",
		Look = {
			Floor = "LeafyGrass",
			Haze = Color3.fromRGB(150, 200, 160),
			Tint = Color3.fromRGB(230, 255, 230),
			Saturation = 0.1,
		},
	},
	CoralGarden = {
		Id = "CoralGarden",
		Zones = { [1] = 30, [2] = 30, [3] = 25, [4] = 20 },
		LootShare = 0.6,
		Decor = Color3.fromRGB(235, 170, 180),
		-- Sharp coral slows you where its layout puts it: wide beds right across the lanes, hard to avoid.
		Hazards = { { Type = "Slow", Scatter = false, Factor = 0.6, Color = Color3.fromRGB(240, 150, 160) } },
		Name = "Coral Garden",
		Tier = "Common",
		Loot = { "Coral", "Snorkel", "Coconut" },
		UnlockItem = "CoralComb",
		Entrance = "Arch in the reef",
		Coin = "Pink",
		Look = {
			Haze = Color3.fromRGB(240, 175, 190),
			Tint = Color3.fromRGB(255, 232, 238),
			Saturation = 0.2,
			Fog = -0.05,
		},
	},
	FogBank = {
		Id = "FogBank",
		Zones = { [2] = 12, [3] = 12, [4] = 14, [5] = 14, [6] = 14 },
		Loot = {},
		LootShare = 0,
		Decor = Color3.fromRGB(200, 205, 210),
		-- The fog, cleared now and then by the lighthouse's foghorn; covered pits in the deep zones.
		Hazards = { { Type = "Fog", Scatter = false }, { Type = "Pit", Scatter = false } },
		Name = "Fog Bank",
		Tier = "Uncommon",
		UnlockItem = "LighthouseKey",
		Hazard = "Thick fog, cleared briefly by a foghorn pulse",
		Look = { Fog = 0.3, Haze = Color3.fromRGB(215, 220, 225), Saturation = -0.25, Mix = 0.8 },
		Rewards = { "LanternOfClearSight", "Foghorn" },
	},
	WhirlwindDunes = {
		Id = "WhirlwindDunes",
		Zones = { [4] = 10, [5] = 10, [6] = 10 },
		Loot = {},
		LootShare = 0,
		Decor = Color3.fromRGB(225, 195, 140),
		-- The whirlwind circling its bowl; spike pits in zone 6 where it can throw you.
		Hazards = { { Type = "Whirlwind", Scatter = false }, { Type = "Pit", Scatter = false } },
		Name = "Whirlwind Dunes",
		Tier = "Rare",
		UnlockItem = "WindChime",
		Hazard = "Tornado circling the zone",
		Look = {
			Floor = "Sand",
			Haze = Color3.fromRGB(230, 200, 150),
			Decay = Color3.fromRGB(170, 130, 80),
			Fog = 0.12,
			Contrast = 0.08,
		},
		Rewards = { "MagicCarpet", "GustGloves" },
	},
	StrandedIceberg = {
		Id = "StrandedIceberg",
		Zones = { [5] = 4, [6] = 6 },
		LootShare = 0.5,
		Decor = Color3.fromRGB(200, 230, 245),
		-- Slippery ice across the frozen lake; crevasses (spike pits), covered and open.
		Hazards = { { Type = "Ice", Scatter = false }, { Type = "Pit", Scatter = false } },
		Name = "Stranded Iceberg",
		Tier = "VeryRare",
		Loot = { "FrozenFish" },
		UnlockItem = "FrozenCompass",
		Hazard = "Slippery ice: vessels slide and spill",
		Look = {
			Floor = "Snow",
			Rock = "Glacier",
			Haze = Color3.fromRGB(215, 235, 250),
			Tint = Color3.fromRGB(225, 240, 255),
			Brightness = 0.25,
			Saturation = -0.1,
		},
		Rewards = { "FrostSled", "FreezeWand" },
		Variant = "Frosted",
	},
}

-- The doc's other biomes, written down so their items exist and point somewhere. They don't
-- roll yet: each needs its decor, entrance, secret course and hazard built first. Moving one
-- into Biomes.List (with those) is what turns it on. Coin = the normal secret's colored coin;
-- Rewards = the exotic secret's lootbox (all in Gear); Variant = its rare cosmetic variant.
Biomes.Planned = {
	SpearstoneReef = {
		Id = "SpearstoneReef",
		Zones = { [4] = 10, [5] = 10, [6] = 10 },
		Loot = {},
		LootShare = 0,
		Decor = Color3.fromRGB(70, 80, 90),
		-- Fields of spearstones on a rhythm, room after room: an obstacle course.
		Hazards = { { Type = "Spears", Scatter = false } },
		Name = "Spearstone Reef",
		Tier = "Rare",
		UnlockItem = "SpearstoneShard",
		Hazard = "Spears shooting from the floor on a timer",
		Look = { Rock = "Basalt", Haze = Color3.fromRGB(120, 150, 170), Contrast = 0.12, Mix = 0.5 },
		Rewards = { "TidewalkerBoots" },
	},
	JellyfishLagoon = {
		Name = "Jellyfish Lagoon",
		Tier = "Uncommon",
		UnlockItem = "JellyJar",
		Hazard = "Jellyfish: a sting drops what you hold",
		Look = {
			Haze = Color3.fromRGB(170, 140, 220),
			Decay = Color3.fromRGB(90, 60, 150),
			Tint = Color3.fromRGB(240, 225, 255),
			Brightness = -0.2,
		},
		Rewards = { "JellyRaft", "GlowPearl" },
	},
	SeaGlassShore = {
		Name = "Sea-Glass Shore",
		Tier = "VeryRare",
		UnlockItem = "PrismShard",
		Hazard = "Sharp glass patches that slow you",
		Look = {
			Floor = "Salt",
			Haze = Color3.fromRGB(170, 235, 225),
			Tint = Color3.fromRGB(225, 255, 250),
			Saturation = 0.2,
			Fog = -0.1,
		},
		Rewards = { "PrismLens", "GlassSwan" },
		Variant = "Sea-glass",
	},
	BlackSandVents = {
		Name = "Black Sand Vents",
		Tier = "VeryRare",
		UnlockItem = "ObsidianEgg",
		Hazard = "Steam vents erupting on a timer",
		Look = {
			Floor = "CrackedLava",
			Rock = "Basalt",
			Haze = Color3.fromRGB(150, 110, 95),
			Decay = Color3.fromRGB(110, 50, 30),
			Fog = 0.12,
			Brightness = -0.2,
			Contrast = 0.15,
		},
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
