-- Every tunable number for the Milestone 1 test build lives here.
-- Values marked in the design doc as "starting values to tune in testing" are grouped so they are easy to find.

local Config = {}

Config.MaxPlayers = 20

-- Who can use the admin console (F2). Add your Roblox UserId to UserIds.
-- The place owner (or rank 254+ in the owning group) is always an admin, and anyone
-- testing in Studio is too.
Config.Admins = {
	UserIds = { 430130259 } :: { number },
	AllowOwner = true,
	OwnerGroupMinRank = 254,
	AllowStudio = true,
}

-- World layout. The shoreline runs along X (the beach is Width studs wide, centred on X = 0).
-- The shop and dunes are at Z < 0. From Z = 0 the sand slopes gently down into the sea toward
-- +Z, and the zones are bands running out to sea: zone 1 nearest the shop, the last zone
-- furthest out, only uncovered at low tide.
Config.Beach = {
	Width = 720, -- studs along the shoreline
	ZoneLength = 200, -- studs each zone runs out to sea
	ActiveZones = 3, -- test build only uses the first 3 zones
	ShopDepth = 80, -- dry ground behind Z = 0 for the shop and boardwalk
	Slope = 0.06, -- studs of drop per stud out to sea
	SeaExtent = 300, -- seabed continues this far past the last zone

	-- Haze over the sea and sand: things further than FogEnd fade into it, so the whole map
	-- can't be seen at once.
	Fog = {
		Start = 220, -- studs away where the haze starts
		End = 520, -- studs away where it's fully opaque
		Color = Color3.fromRGB(205, 220, 228),
	},

	-- Depth bands, by how deep the water is at a spot.
	ShallowDepth = 1.5,
	KneeDepth = 3,
	WaistDepth = 4.5, -- deeper than this drowns players and swallows vessels
	LostDepth = 7, -- unclaimed and loose items this deep are lost to the tide
}

Config.Zones = {
	{ Name = "Shopside Shore", Multiplier = 1, Rarity = { Common = 90, Uncommon = 10 } },
	{ Name = "Sunny Stretch", Multiplier = 2, Rarity = { Common = 70, Uncommon = 25, Rare = 5 } },
	{
		Name = "Middle Banks",
		Multiplier = 4,
		Rarity = { Common = 50, Uncommon = 32, Rare = 15, VeryRare = 3 },
	},
	{
		Name = "Outer Shore",
		Multiplier = 8,
		Rarity = { Common = 30, Uncommon = 35, Rare = 25, VeryRare = 10 },
	},
	{ Name = "The Far Sandbar", Multiplier = 15, Rarity = { Rare = 60, VeryRare = 40 } },
}

-- Tide: the sea level falls (uncovering the outer zones), holds at low tide, then rises
-- again. The waterline is where the sea meets the sand, measured as a Z position.
-- Times are in seconds and multiplied by TimeScale, so the test build can run a shorter
-- cycle than the full 25 minutes.
Config.Tide = {
	OutTime = 600,
	HoldTime = 300,
	InTime = 600,
	TimeScale = 0.4, -- 0.4 => 10 minute cycle for testing. Set to 1 for the real 25 minutes.
	HighWaterline = 60, -- waterline Z at high tide (inside zone 1)
	LowWaterlineFromEnd = 40, -- at low tide the waterline is this far before the end of the last zone
}

Config.Waves = {
	Period = 7, -- seconds between waves
	Speed = 14, -- studs/s the wave front travels toward shore
	StartOffset = 70, -- where each wave starts, studs seaward of the waterline
	EndOffset = -6, -- how far up the dry sand past the waterline a wave washes
	BandWidth = 10, -- thickness of the pushing band behind the front
	Push = 16, -- studs/s shoreward push at the leading edge
	Backwash = 4, -- studs/s seaward pull in the water between waves
	WobbleAmplitude = 5, -- the front is not a perfect line along the beach
	WobbleFrequency = 1 / 45,
	CharacterFactor = 1, -- multiplier on push for characters (displacement)
	ItemFactor = 2.5, -- multiplier on push for physical items (acceleration)
	Buoyancy = 0.55, -- fraction of gravity cancelled for submerged items
	MinPushFraction = 0.3, -- future stat stacking can never reduce waves below this
}

-- Biomes: each tide cycle, every zone rolls whether it becomes a biome (see Biomes.luau).
Config.Biomes = {
	-- Each cycle every zone rolls one of these (relative weights). Rare biomes are never announced.
	Weights = {
		None = 40,
		SandcastleFlats = 45,
		ShipwreckShallows = 15,
	},
}

-- Rare unlock items for secrets.
Config.Unlocks = {
	SpawnChance = 0.02, -- chance that a surf spawn in a common biome zone is its unlock item
	ExoticSpawnChance = 0.008, -- the same for rare biomes (exotic unlock items are much rarer)
	MaxOnMap = 1, -- of each unlock item at once
}

Config.Secrets = {
	Origin = Vector3.new(-6000, 500, -3000), -- courses are built far off the map, one per player slot
	Spacing = 400,
	ReadyTimeout = 5, -- seconds to wait for the client to build the course and arrive in it
	FloodDelay = 3, -- seconds after arriving before the water starts rising
	MinRunTime = 12, -- a chest claimed faster than this is rejected as implausible
	MinFlood = 60, -- the course floods over at least this many seconds...
	MaxFlood = 180, -- ...and at most this many, depending on when in the tide cycle you enter
}

Config.Lexicon = {
	TowerManChance = 0.001, -- per zone, per tide cycle
}

Config.Traders = {
	CommonChance = 0.5, -- a trader appears this often when their common biome rolls
	RareChance = 0.25, -- and this often in rare biomes
	BringRadius = 18, -- payment items count if they're this close to the trader (or in your vessel or pockets)
	LevelCoins = { 5000, 25000, 100000 },
	LevelItems = { 3, 6, 10 },
	MinWavePush = 0.3, -- stacked wave resistance never takes waves below 30%
}

Config.SkyBeam = {
	SpawnChance = 0.0005, -- chance a surf spawn in the outermost zone is the Beacon Pearl
	Height = 600, -- studs of light above it
}

Config.Hazards = {
	BarrelPeriod = 6, -- Shipwreck Shallows: a barrel rolls down the sand this often (learnable timer)
	BarrelSpeed = 16,
}

Config.Trading = {
	Countdown = 5, -- seconds after any change before either player can accept
	CoinTax = 0.10, -- share of traded coins that leaves the game (stops "parking" coins)
	InviteTimeout = 30,
	MaxItemsPerSide = 30,
}

-- The global auction: one lot at a time, the same on every server, on a fixed schedule.
Config.Auction = {
	LotDuration = 600, -- seconds per lot (10 minutes for testing)
	Epoch = 1767225600, -- 2026-01-01: lots are numbered from here
	Lots = { "CaptainsTricorn", "SeaGlassCirclet", "CaptainsTricorn", "CrownOfTides" }, -- the rotation
	MinIncrement = 100, -- a new top bid beats the old one by at least this...
	MinIncrementFraction = 0.05, -- ...or this share of it, whichever is more
	PollInterval = 3, -- seconds between reading the shared lot
	LedgerInterval = 30, -- seconds between collecting refunds and wins from other servers
	Recent = 8, -- results kept for the "recent winners" list
}

Config.Rebirth = {
	BaseCost = 100000,
	CostGrowth = 1.5, -- each rebirth costs this much more than the last
	MultiplierStep = 0.5, -- coin multiplier gained per rebirth
	MaxPicks = 5, -- reward picks at the first 5 rebirths
}

Config.Pockets = {
	Slots = 3, -- from Deep Pockets
	MaxSlots = 6, -- Deep Pockets plus the Deckhand's Satchel
}

Config.Items = {
	SpawnInterval = 1.25, -- seconds between spawn attempts
	MaxSurfItems = 45, -- unclaimed items kept washing around the current waterline
	MaxTotal = 450,
	LooseTimeout = 25, -- a claimed item left alone this long freezes and becomes unclaimed
	TimedOutLifetime = 90, -- a timed-out item despawns if nobody grabs it within this
	FreshLifetime = 360, -- surf spawns are recycled after this long untouched
	ReachSlack = 4, -- extra studs the server allows on top of a tool's reach (latency)
	HeldLeash = 14, -- server force-drops a held item this far past reach
	MaxHeldSpeed = 140,
}

Config.Grab = {
	TapTime = 0.25, -- a press shorter than this (and short movement) is a tap => assist lift
	TapMovePixels = 12,
	AssistRange = 22, -- studs from player to vessel for assist "send to vessel"
	VesselHandleReach = 14,
	TowAcceleration = 260,
	GripBreakTime = 0.35, -- an item pulled this far from your hand for this long is knocked loose
	MinHoldDistance = 4,
	HoldLift = 1.5, -- dragged items are held at least this far above the ground
	DefaultHandleHeight = 2.4, -- towed vessel handles are held this high above the ground
	-- A parked vessel is held in place sideways with this much acceleration. The slope only
	-- pulls with ~12, waves push with up to ~40, so it stays parked but waves can still move it.
	BrakeAcceleration = 30,
	BrakeSlip = 3, -- if waves shove a parked vessel this far, it re-parks where it ended up
	StabilizerTorque = 600, -- per unit of mass, times the vessel's Stability; keeps vessels upright
	HoverHeight = 3.5, -- the Floating Clamshell hovers this high, behind its owner
	HoverAcceleration = 400,
}

Config.Drowning = {
	BreathTime = 12, -- seconds of breath in deep water
	RegenTime = 3, -- seconds to refill from empty
	DamagePerSecond = 18,
}

Config.Selling = {
	ShopkeeperRange = 22, -- how close to the shopkeeper you must be to buy
	BuyerRange = 14, -- how close to the buyer you must be to sell what's on the sell pad
}

Config.Data = {
	StoreName = "SalvageSim3_Player_v1",
	AutosaveInterval = 120,
	LockStaleAfter = 600, -- a session lock older than this is assumed to be from a dead server
	LoadAttempts = 5,
}

return Config
