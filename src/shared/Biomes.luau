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
		Look = { Haze = Color3.fromRGB(225, 190, 150), Tint = Color3.fromRGB(255, 235, 210), Mix = 0.4 },
	},
	TidepoolRocks = {
		Name = "Tidepool Rocks",
		Tier = "Common",
		Loot = { "Seashell", "Starfish", "FishingLure" },
		UnlockItem = "PearlEyedShell",
		Entrance = "Blowhole in the rocks",
		Coin = "Blue",
		Look = { Rock = "Slate", Haze = Color3.fromRGB(160, 205, 230), Saturation = 0.1, Mix = 0.4 },
	},
	SeagrassShallows = {
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
	FogBank = {
		Name = "Fog Bank",
		Tier = "Uncommon",
		UnlockItem = "LighthouseKey",
		Hazard = "Thick fog, cleared briefly by a foghorn pulse",
		Look = { Fog = 0.3, Haze = Color3.fromRGB(215, 220, 225), Saturation = -0.25, Mix = 0.8 },
		Rewards = { "LanternOfClearSight", "Foghorn" },
	},
	WhirlwindDunes = {
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
	SpearstoneReef = {
		Name = "Spearstone Reef",
		Tier = "Rare",
		UnlockItem = "SpearstoneShard",
		Hazard = "Spears shooting from the floor on a timer",
		Look = { Rock = "Basalt", Haze = Color3.fromRGB(120, 150, 170), Contrast = 0.12, Mix = 0.5 },
		Rewards = { "TidewalkerBoots" },
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
	StrandedIceberg = {
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
