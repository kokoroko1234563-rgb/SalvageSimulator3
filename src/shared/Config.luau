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
		Start = 150, -- studs away where the haze starts
		End = 400, -- studs away where it's fully opaque
		Color = Color3.fromRGB(205, 220, 228),
	},

	-- Rock pools: rings of rock that hold water after the sea leaves (a fixed level, Depth
	-- studs above the ground at the ring's seaward edge). X, Z is the centre.
	Pools = {
		{ X = -210, Z = 150, Radius = 9, Depth = 1.4 },
		{ X = 140, Z = 270, Radius = 12, Depth = 1.8 },
		{ X = -60, Z = 430, Radius = 10, Depth = 1.6 },
		{ X = 260, Z = 520, Radius = 8, Depth = 1.4 },
	},

	-- Depth bands, by how deep the water is at a spot.
	ShallowDepth = 1.5,
	KneeDepth = 3,
	WaistDepth = 4.5, -- deeper than this drowns players and swallows vessels
	LostDepth = 7, -- unclaimed and loose items this deep are lost to the tide

	-- The Far Sandbar: a fixed final zone past the others, across a deep channel that's
	-- only shallow enough to cross around low tide (about 5 minutes per cycle).
	FarSandbar = {
		Zone = 5, -- its entry in Config.Zones (x15 values)
		ChannelStart = 600,
		ChannelEnd = 640,
		ChannelDepth = 8, -- extra depth of the channel below the normal slope
		DoorZ = 680, -- the Sunken Bell Tower's door, uncovered for a while around low tide
		End = 760,
	},
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
	LowWaterline = 700, -- waterline Z at low tide: the channel to the Far Sandbar is crossable

	-- How the tide goes out and comes back in. Each list is how far out the tide is (0 = high,
	-- 1 = low) at evenly spaced moments through that phase, joined by a smooth curve. Repeat
	-- a value to make the tide pause, or bunch values to make it rush.
	OutShape = { 0, 0.08, 0.3, 0.55, 0.62, 0.85, 1 }, -- eases out, pauses a little past halfway
	InShape = { 0, 0.12, 0.4, 0.7, 0.9, 1 }, -- comes back in faster at first

	-- Which parts of the beach drain first. Points along the shoreline (X), each with a delay
	-- in seconds (scaled by TimeScale like the phases): that part of the sea follows the tide
	-- this much later. Positive = drains later and floods later; negative = earlier. Between
	-- points the delay blends smoothly, so the waterline curves.
	Sections = {
		{ X = -360, Lag = -30 }, -- the west end drains first
		{ X = -120, Lag = 0 },
		{ X = 80, Lag = 20 },
		{ X = 360, Lag = 45 }, -- the east end holds water longest
	},
}

Config.Waves = {
	Period = 6, -- seconds between waves
	Speed = 26, -- studs/s the wave front travels toward shore
	StartOffset = 90, -- where each wave starts, studs seaward of the waterline
	BandWidth = 6, -- thickness of the pushing band behind the front: a short, sharp shove
	Push = 18, -- studs/s shoreward push at the leading edge

	-- Undertow: the sea always pulls out, between and under the waves, harder the deeper it
	-- is. Over a whole wave it outweighs the shove toward shore, so standing still in the
	-- water drags you out.
	Undertow = 5, -- studs/s seaward at the waterline...
	UndertowDeep = 10, -- ...rising to this at waist depth and beyond
	UndertowZoneScale = 0.5, -- the undertow grows half as much as the waves further out

	-- Run-up: after reaching the waterline each wave keeps running up the exposed sand as a
	-- thin sheet, slowing down, then slides back. While running up it pushes things up the
	-- beach; while sliding back it drags them toward the sea.
	RunUp = 10, -- studs an average wave runs up the sand
	RunUpVariation = 0.35, -- each wave is up to this much bigger or smaller (deterministic)
	RunUpPush = 14, -- studs/s up the beach under the running-up sheet
	BackwashPull = 24, -- studs/s toward the sea under the sliding-back sheet
	BackwashRatio = 1.1, -- sliding back takes this many times as long as running up

	-- Knockdowns: a push this strong (after the player's wave resistance) knocks the player
	-- over. They're thrown with the water, drop what they're holding, and lie helpless for
	-- KnockdownTime while the water keeps carrying them.
	KnockdownPush = 30, -- studs/s: big waves anywhere, most waves on the Far Sandbar
	KnockdownTime = 1.6,
	ThrowFactor = 1.4, -- launch speed, as a multiple of the push
	ThrowLift = 14, -- studs/s upward on the throw
	KnockdownCooldown = 2.5, -- seconds after getting up before the next knockdown
	SetEvery = 6, -- every Nth wave is a big one...
	SetSize = 1.7, -- ...this much bigger
	RogueChance = 0.03, -- and this fraction of waves are rogue waves...
	RogueSize = 3, -- ...this much bigger. The admin console can send one (wave rogue).
	-- Waves get bigger further out: by zone (where the water reaches), 1 = normal.
	ZoneScale = { 1, 1, 1.15, 1.3, 1.7 },

	-- Unclaimed items near the waterline get moved by the swash: after each wave, items it
	-- reached may be dragged a little (mostly seaward, sometimes up the beach).
	DragChance = 0.35, -- chance per item per normal wave (scaled by the wave's size)
	DragDistance = 3, -- studs, for a normal wave (scaled by size)
	DragShallows = 6, -- items this far into the water (past the waterline) count as reached

	WetSeconds = 40, -- sand the tide uncovered this recently still looks wet
	WobbleAmplitude = 5, -- the front is not a perfect line along the beach
	WobbleFrequency = 1 / 45,
	CharacterFactor = 1, -- multiplier on push for characters (displacement)
	ItemFactor = 2.5, -- multiplier on push for physical items (acceleration)
	Buoyancy = 0.55, -- fraction of gravity cancelled for submerged items
	-- Floating items (round ones: balls and cylinders) bob at the surface instead of rolling
	-- down the seabed, and a current carries them out to sea until they're lost.
	FloatSpring = 0.5, -- extra lift per stud below the surface, as a fraction of gravity
	FloatDamping = 8, -- calms the bobbing
	FloatDrag = 1.2, -- water slows their sideways drift
	FloatDrift = 3, -- studs/s current carrying floating items out to sea
	FloatWavePush = 0.4, -- waves push floating items this much, so the current wins over time
	FloatAwayDistance = 120, -- floating items this far out past the waterline are lost
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
	MagnetPull = 8, -- Tide Magnet: studs/second it reels a held item in while it's in the water
	MagnetWaveScale = 0.5, -- and waves push what it holds this much
	BubbleFloat = 3, -- Bubble Wand: held items float this much higher off the ground
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
	SwimWashChance = 0.02, -- per 0.3s in deep water: a swimming vessel loses one item
	SwimSandSpeed = 0.35, -- swimming vessels follow this much slower on dry sand
	SwimFloat = 1, -- how high a swimming vessel's base sits above the water
}

Config.Drowning = {
	BreathTime = 12, -- seconds of breath in deep water
	RegenTime = 3, -- seconds to refill from empty
	DamagePerSecond = 18,
}

Config.Selling = {
	ShopkeeperRange = 22, -- how close to the shopkeeper you must be to buy
	BuyerRange = 14, -- how close to the buyer you must be to sell what's on the sell pad, and your pockets
}

Config.Banking = {
	BankerRange = 14, -- how close to the banker you must be to bank unlock items on the bank floor
}

-- Paid features. Every Robux id is made in the Creator Hub (see README), then pasted here.
-- Anything still at id 0 shows in the shop as "not set up" and can't be bought.
Config.Monetization = {
	-- Developer products: coins for Robux, bought as many times as you like.
	CoinPacks = {
		{ Id = "PouchOfCoins", Name = "Pouch of Coins", Coins = 5000, ProductId = 0 },
		{ Id = "ChestOfCoins", Name = "Chest of Coins", Coins = 30000, ProductId = 0 },
		{ Id = "PiratesHoard", Name = "Pirate's Hoard", Coins = 150000, ProductId = 0 },
	},
	-- Gamepasses: bought once, kept forever. These two are examples of the two kinds of
	-- effect a pass can have (a multiplier and a slot count); add more the same way.
	Gamepasses = {
		{
			Id = "MerchantsScale",
			Name = "Merchant's Scale",
			Note = "Everything you sell is worth 25% more",
			PassId = 0,
			SellMultiplier = 1.25,
		},
		{
			Id = "ExtraPockets",
			Name = "Extra Pockets",
			Note = "+2 pocket slots for Light items",
			PassId = 0,
			PocketSlots = 2,
		},
	},
	ReceiptMemory = 100, -- the newest purchase ids kept on each profile, so none is granted twice
	FullRatePlayers = 20, -- private servers: rare spawns reach normal rates at this many players
}

Config.Data = {
	StoreName = "SalvageSim3_Player_v1",
	AutosaveInterval = 120,
	LockStaleAfter = 600, -- a session lock older than this is assumed to be from a dead server
	LoadAttempts = 5,
}

return Config
