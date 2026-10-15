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
-- furthest out, only uncovered at low tide. Each zone is a few tiles deep: a tile is the unit
-- of the ground's hand-built layouts and of biomes (each tile rolls its own biome).
-- The descent is meant to take about 7 minutes: the tide takes 10 to go out, so you follow it
-- down, and 10 to come back in, so you race it back with your finds.
Config.Beach = {
	Width = 720, -- studs along the shoreline
	TileLength = 150, -- studs each tile runs out to sea
	TilesPerZone = 4,
	ZoneLength = 600, -- TileLength * TilesPerZone
	ActiveZones = 6, -- zones 1-6, then the Far Sandbar's channel
	ShopDepth = 80, -- dry ground behind Z = 0 for the shop and boardwalk
	Slope = 0.06, -- studs of drop per stud out to sea
	SeaExtent = 300, -- seabed continues this far past the last zone

	-- Haze over the sea and sand: things further than FogEnd fade into it, so the whole map
	-- can't be seen at once.
	Fog = {
		Start = 300, -- studs away where the haze starts
		End = 950, -- studs away where it's fully opaque
		Color = Color3.fromRGB(196, 226, 250), -- the colour of the sky at the horizon
	},

	-- The shape of the ground (built as smooth Terrain, see TerrainBuilder): the even slope,
	-- plus each zone's hand-built layout (src/shared/Layouts), which changes with its biome.
	Terrain = {
		Voxel = 4, -- smooth Terrain resolution
		EdgeFade = 30, -- the shape fades out over this many studs at the sides of the beach
		-- The shape of zones 1-4 comes from hand-built layouts (src/shared/Layouts).
		ZoneFade = 6, -- it fades out over this many studs at each zone's landward and seaward edge
		Blend = 8, -- Ramps and Flats blend into the ground around them over this many studs
		RockMin = 1.5, -- rock shapes lower than this are built from sand
		CartSlope = 0.35, -- the steepest climb a vessel can take (rise over run)
		FootSlope = 0.9, -- the steepest climb a player can walk up (characters' MaxSlopeAngle)
		MaxHeight = 12, -- the tallest a layout shape can be (but a Wall)
		WallMaxHeight = 24, -- the tallest a Wall can be: well over a jump (about 7 studs)
		WallMinWidth = 12, -- the thinnest a Wall can be: thinner ones get rounded off by the terrain's 4-stud cells
		MaxDepth = 4, -- the deepest a layout cut can be
		EyeHeight = 5, -- standing eye height above the ground (for sightlines)
	},

	-- Rock pools: rings of rock that hold water after the sea leaves (a fixed level, Depth
	-- studs above the ground at the ring's seaward edge). X, Z is the centre.
	Pools = {
		{ X = -280, Z = 620, Radius = 9, Depth = 1.4 }, -- just past where zone 1 meets zone 2
		{ X = 140, Z = 720, Radius = 12, Depth = 1.8 },
		{ X = -60, Z = 1330, Radius = 10, Depth = 1.6 },
		{ X = 260, Z = 1870, Radius = 8, Depth = 1.4 },
	},

	-- Wading: walk speed and jump at each water depth (studs over the ground), blended
	-- smoothly in between. A character is about 5 studs tall, so past that you're underwater.
	Wading = {
		{ Depth = 0, Speed = 1, Jump = 1 },
		{ Depth = 1.5, Speed = 0.85, Jump = 0.9 }, -- ankle to shin
		{ Depth = 3, Speed = 0.7, Jump = 0.75 }, -- knee-deep
		{ Depth = 4.5, Speed = 0.55, Jump = 0.6 }, -- waist-deep
		{ Depth = 5.5, Speed = 0.4, Jump = 0.45 }, -- head under: fully underwater
	},

	-- Depth bands, by how deep the water is at a spot.
	ShallowDepth = 1.5,
	KneeDepth = 3,
	WaistDepth = 4.5, -- deeper than this drowns players and swallows vessels
	LostDepth = 7, -- unclaimed and loose items this deep are lost to the tide

	-- The Far Sandbar: a fixed final zone past the others, across a deep channel that's
	-- only shallow enough to cross around low tide (about 5 minutes per cycle).
	FarSandbar = {
		Zone = 7, -- its entry in Config.Zones
		ChannelStart = 3600, -- ZoneLength * ActiveZones
		ChannelEnd = 3640,
		ChannelDepth = 8, -- extra depth of the channel below the normal slope
		DoorZ = 3680, -- the Sunken Bell Tower's door, uncovered for a while around low tide
		End = 3760,
	},
}

-- The zones, from the shop out. CrossTime: about how many seconds the fastest way across the
-- zone should take on foot (tools/layout_map.luau measures it from the layouts). Together
-- they make the walk down about 7 minutes, with wading, waves and wrong turns: the lower
-- zones are slower, more maze-like ground.
Config.Zones = {
	{ Name = "Shopside Shore", Multiplier = 1, CrossTime = 35, Rarity = { Common = 90, Uncommon = 10 } },
	{
		Name = "Sunny Stretch",
		Multiplier = 2,
		CrossTime = 40,
		Rarity = { Common = 70, Uncommon = 25, Rare = 5 },
	},
	{
		Name = "Middle Banks",
		Multiplier = 4,
		CrossTime = 45,
		Rarity = { Common = 50, Uncommon = 32, Rare = 15, VeryRare = 3 },
	},
	{
		Name = "Outer Shore",
		Multiplier = 8,
		CrossTime = 55,
		Rarity = { Common = 30, Uncommon = 35, Rare = 25, VeryRare = 10 },
	},
	{
		Name = "The Shoals",
		Multiplier = 12,
		CrossTime = 65,
		Rarity = { Common = 20, Uncommon = 35, Rare = 30, VeryRare = 15 },
	},
	{
		Name = "The Drowned Reach",
		Multiplier = 18,
		CrossTime = 85,
		Rarity = { Common = 10, Uncommon = 30, Rare = 38, VeryRare = 22 },
	},
	{ Name = "The Far Sandbar", Multiplier = 25, Rarity = { Rare = 60, VeryRare = 40 } },
}

-- Tide: the sea level falls (uncovering the outer zones), holds at low tide, then rises
-- again. The waterline is where the sea meets the sand, measured as a Z position.
-- Times are in seconds and multiplied by TimeScale, so the test build can run a shorter
-- cycle than the full 25 minutes.
Config.Tide = {
	OutTime = 600,
	HoldTime = 300,
	InTime = 600,
	TimeScale = 1, -- 1 = the real 25-minute cycle. Lower it (or use the admin console) to test faster.
	HighWaterline = 60, -- waterline Z at high tide (inside zone 1)
	LowWaterline = 3700, -- waterline Z at low tide: the channel to the Far Sandbar is crossable

	-- How the tide goes out and comes back in. Each list is how far out the tide is (0 = high,
	-- 1 = low) at evenly spaced moments through that phase, joined by a smooth curve. Repeat
	-- a value to make the tide pause, or bunch values to make it rush.
	OutShape = { 0, 0.08, 0.3, 0.55, 0.62, 0.85, 1 }, -- eases out, pauses a little past halfway
	InShape = { 0, 0.12, 0.4, 0.7, 0.9, 1 }, -- comes back in faster at first

	-- Which parts of the beach drain first. Points along the shoreline (X), each with a delay
	-- in seconds (scaled by TimeScale like the phases): that part of the sea follows the tide
	-- this much later. Positive = drains later and floods later; negative = earlier. Between
	-- points the delay blends smoothly, so the waterline curves.
	-- On top of the sections, a random pattern (from the server's sea seed) shifts which
	-- parts drain first, and slowly changes over time, so the highest and lowest stretches of
	-- the waterline move about as the tide goes out. Each server has its own seed.
	Shuffle = {
		Amplitude = 4, -- up to this many seconds earlier or later (scaled by TimeScale)
		Wavelength = 260, -- studs along the shoreline between high and low stretches (roughly)
		Change = 120, -- seconds for the pattern to change into a different one
	},
	Sections = {
		-- (The tide crosses about 6 studs a second, so a few seconds bends the shore a lot.)
		{ X = -360, Lag = -5 }, -- the west end drains first
		{ X = -120, Lag = 0 },
		{ X = 80, Lag = 3.5 },
		{ X = 360, Lag = 7.5 }, -- the east end holds water longest
	},
}

Config.Waves = {
	Period = 6, -- seconds between waves
	Speed = 26, -- studs/s the wave front travels toward shore
	StartOffset = 90, -- where each wave starts, studs seaward of the waterline
	BandWidth = 14, -- the surge behind a wave's front, pushing swimmers toward shore
	Push = 14, -- studs/s shoreward push at the leading edge

	-- The ordinary sea is impartial: it jostles you both ways and doesn't drag you out. As a
	-- wave approaches, the water rushes out to meet it (the drawback), then the wave's front
	-- shoves you back in; for a normal wave the two roughly cancel. The drawback grows with
	-- the wave's size squared, so big waves pull hard and rogue waves pull very hard: they are
	-- the danger, not the water itself.
	Undertow = 4, -- studs/s scale of the drawback at the waterline...
	UndertowDeep = 6, -- ...rising to this at waist depth and beyond
	UndertowZoneScale = 0.5, -- grows half as much as the waves further out
	Slack = 0, -- pull between waves, as a fraction of the undertow (0 = still water)
	Drawback = 1.2, -- drawback strength just before a wave: undertow x this x size squared
	DrawbackRange = 25, -- studs ahead of an incoming wave where the water rushes out to it
	Rock = 3, -- studs/s in and out as each wave passes over you (the water circling under it)
	Sway = 2.5, -- studs/s side-to-side drift in the water, varying along the beach and in time
	Coupling = 4, -- how quickly you pick up (and lose) the water's speed; lower = more momentum

	-- Run-up: after reaching the waterline each wave keeps running up the exposed sand as a
	-- thin sheet, slowing down, then slides back. While running up it pushes things up the
	-- beach; while sliding back it drags them toward the sea.
	RunUp = 10, -- studs an average wave runs up the sand
	RunUpVariation = 0.35, -- each wave is up to this much bigger or smaller (deterministic)
	AlongVariation = 0.35, -- and up to this much bigger or smaller at different spots along the beach
	AlongWavelength = 140, -- studs between the bigger and smaller stretches of a wave
	RunUpPush = 12, -- studs/s up the beach under the running-up sheet
	BackwashPull = 16, -- studs/s toward the sea under the sliding-back sheet
	BackwashRatio = 1.1, -- sliding back takes this many times as long as running up

	-- Knockdowns: a push this strong (after the player's wave resistance) knocks the player
	-- over. Only big waves get there (and most waves on the Far Sandbar). The wave tumbles
	-- them and drags them out to sea: they drop what they're holding and are carried seaward,
	-- slowing over KnockdownTime. A rogue wave can carry you deep enough to drown.
	KnockdownPush = 28, -- studs/s
	KnockdownTime = 1.6,
	ThrowFactor = 1.4, -- seaward carry speed, as a multiple of the push that knocked you over
	ThrowLift = 14, -- studs/s upward on the throw
	KnockdownCooldown = 2.5, -- seconds after getting up before the next knockdown
	SetEvery = 6, -- every Nth wave is a big one...
	SetSize = 1.7, -- ...this much bigger
	RogueChance = 0.03, -- and this fraction of waves are rogue waves...
	RogueSize = 3, -- ...this much bigger. The admin console can send one (wave rogue).
	-- Waves get bigger further out: by zone (where the water reaches), 1 = normal.
	ZoneScale = { 1, 1.1, 1.25, 1.45, 1.7, 2, 2.3 },

	-- Unclaimed items near the waterline get moved by the swash: after each wave, items it
	-- reached may be dragged a little (mostly seaward, sometimes up the beach).
	DragChance = 0.35, -- chance per item per normal wave (scaled by the wave's size)
	DragDistance = 3, -- studs, for a normal wave (scaled by size)
	DragShallows = 6, -- items this far into the water (past the waterline) count as reached

	WetSeconds = 40, -- sand the tide uncovered this recently still looks wet
	WobbleAmplitude = 8, -- the front is not a perfect line along the beach (a different shape each wave)
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

-- Sea mist: the haze thickens the further out you are, so the lower zones feel closed in and
-- you can't see far ahead (or back). Atmosphere density by zone (shop, then zones 1-6 and the
-- Far Sandbar); it
-- blends smoothly across zone edges. The Lantern of Clear Sight divides it.
Config.Mist = {
	Shop = 0.2,
	Zones = { 0.24, 0.3, 0.37, 0.45, 0.54, 0.63, 0.7 },
	Blend = 40, -- studs over which one zone's mist blends into the next
	Response = 0.8, -- how quickly the mist follows you (per second)
}

-- How the water treats objects on the beach (WaterObstacles).
Config.Water = {
	Bucket = 16, -- studs along X per lookup bucket
	Step = 1, -- studs between samples when the run-up looks for something in its way
	ShelterRange = 40, -- solid things up to this far out to sea shelter what's behind them
	ShelterStep = 3, -- studs between samples when looking for shelter
	ShelterHeight = 0.3, -- they shelter only where they stand at least this far out of the water
	ShelterFactor = 0.15, -- waves push this much behind shelter
}

-- Biomes: each tide cycle, every zone rolls whether it becomes a biome (see Biomes.luau).
Config.Biomes = {
	-- Each cycle every tile rolls a biome from those that can turn up in its zone (each biome's
	-- Zones weights, in Biomes.luau), or none, with this weight. Rare biomes are never announced.
	NoneWeight = 40,
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

-- The showroom: a gallery off the map showing every model, material and colour (Showroom,
-- ShowroomExhibits). Admins get there with `tp showroom`. It's on the shop side (Z < 0), far
-- along X, where no tide or wave reaches.
Config.Showroom = {
	Enabled = true,
	Origin = Vector3.new(6000, 0, -300), -- the entrance; the room runs back toward -Z
	RowWidth = 360, -- studs of exhibits per row
	Gap = 6, -- studs between exhibits
	Aisle = 10, -- studs between rows
	SectionGap = 24, -- studs between sections
	WallHeight = 4,
}

-- The day: a 24-hour clock that runs on the shared server clock, separate from the tide.
-- Daytime (6:00 to 18:00) takes DayShare of each cycle, so nights pass quicker.
Config.Day = {
	Length = 1200, -- seconds for a whole day (20 minutes)
	DayShare = 0.7, -- the share of it that's daylight
	StartHour = 9, -- the hour a new server starts at
	NightAmbient = Color3.fromRGB(70, 85, 130), -- outdoor light at night: dim and blue, still playable
	NightBrightness = 0.8,
	DuskColor = Color3.fromRGB(255, 160, 110), -- haze colour around sunrise and sunset
}

-- Music, chosen by place and time of day. These are Roblox's licensed library tracks (APM
-- Music), free to use in any experience, so nothing needs uploading. Find more in the Creator
-- Store's audio section (or with tools that search it) and add them here with their asset id.
-- (Kevin MacLeod's music was tried first: Roblox's moderation rejects it on upload.)
-- Places: Shop, Shore (zones 1-2), Outer (zones 3-4), Sandbar (zone 5), Secret, Showroom.
-- Times: Day, Twilight (dawn and dusk), Night. A track with no Times plays at any time.
-- A track with SoundId 0 is skipped. Each new track shows its title and artist.
Config.Music = {
	Volume = 0.35,
	FadeTime = 3, -- seconds to cross-fade between tracks
	Gap = { 4, 12 }, -- seconds of quiet between tracks
	Tracks = {
		{
			Title = "Prima Bossa Nova",
			Artist = "Anthony Mawer",
			SoundId = 1837070127,
			Places = { "Shop" },
			Times = { "Day", "Twilight" },
		},
		{
			Title = "Bossa Nova Party",
			Artist = "Intersound",
			SoundId = 1845764031,
			Places = { "Shop", "Showroom" },
			Times = { "Day" },
		},
		{
			Title = "A Dream of Bossa Nova",
			Artist = "Intersound",
			SoundId = 9043921564,
			Places = { "Shop", "Showroom" },
		},
		{
			Title = "Seaside Parade",
			Artist = "Themes - Vinyl Series",
			SoundId = 1848368912,
			Places = { "Showroom", "Shop" },
			Times = { "Day" },
		},
		{
			Title = "Hawaiian Calypso",
			Artist = "Jo Wetter",
			SoundId = 1837052375,
			Places = { "Shore" },
			Times = { "Day" },
		},
		{
			Title = "Tropical Breeze",
			Artist = "Charles Michael Brotman",
			SoundId = 9047134387,
			Places = { "Shore", "Shop" },
			Times = { "Day", "Twilight" },
		},
		{
			Title = "Maui Beach",
			Artist = "Selected Sound New Vinyl Series",
			SoundId = 9043828544,
			Places = { "Shore" },
			Times = { "Day" },
		},
		{
			Title = "Beach Party",
			Artist = "Endgame",
			SoundId = 1837779005,
			Places = { "Shore" },
			Times = { "Day" },
		},
		{
			Title = "Jamaica Boy",
			Artist = "Bruce Campbell",
			SoundId = 1836356833,
			Places = { "Shore", "Outer" },
			Times = { "Day" },
		},
		{
			Title = "Carnival in Trinidad",
			Artist = "Lars-Luis Linek",
			SoundId = 1844398749,
			Places = { "Shore", "Outer" },
			Times = { "Day" },
		},
		{
			Title = "Beach Island",
			Artist = "Aymeric Ribot",
			SoundId = 9047876685,
			Places = { "Outer" },
			Times = { "Day", "Twilight" },
		},
		{
			Title = "Pirate King",
			Artist = "2nd Foundation Music",
			SoundId = 1835322563,
			Places = { "Outer", "Sandbar" },
			Times = { "Day", "Twilight" },
		},
		{
			Title = "Atlantis Mystery",
			Artist = "Sonoton Vanguard",
			SoundId = 1847183157,
			Places = { "Sandbar" },
		},
		{
			Title = "Dangerous Deep Sea",
			Artist = "Walt Rockman",
			SoundId = 1846079117,
			Places = { "Sandbar", "Outer" },
			Times = { "Twilight", "Night" },
		},
		{
			Title = "Kona Sunset",
			Artist = "Charles Michael Brotman",
			SoundId = 9047138975,
			Places = { "Shore", "Outer" },
			Times = { "Twilight" },
		},
		{
			Title = "Sunset Chill",
			Artist = "Queens Road",
			SoundId = 9046862941,
			Places = { "Shore", "Shop" },
			Times = { "Twilight" },
		},
		{
			Title = "Night in Jamaica",
			Artist = "Lars-Luis Linek",
			SoundId = 1844398912,
			Places = { "Shop", "Shore" },
			Times = { "Night" },
		},
		{
			Title = "Calypso Ballad",
			Artist = "David Ohana",
			SoundId = 9047782221,
			Places = { "Shore", "Outer", "Sandbar" },
			Times = { "Night" },
		},
		{ Title = "Deep Sea", Artist = "Sonoton Vinyl", SoundId = 9043080550, Places = { "Secret" } },
		{
			Title = "Mysterious Ocean",
			Artist = "Philippe Bestion",
			SoundId = 1839254432,
			Places = { "Secret" },
		},
	},
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
