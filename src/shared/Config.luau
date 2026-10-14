-- Every tunable number for the Milestone 1 test build lives here.
-- Values marked in the design doc as "starting values to tune in testing" are grouped so they are easy to find.

local Config = {}

Config.MaxPlayers = 20

-- Who can use the admin console (F2). Add your Roblox UserId to UserIds.
-- The place owner (or rank 254+ in the owning group) is always an admin, and anyone
-- testing in Studio is too.
Config.Admins = {
	UserIds = {} :: { number },
	AllowOwner = true,
	OwnerGroupMinRank = 254,
	AllowStudio = true,
}

-- World layout. The beach runs along +X starting at the shop (X = 0).
-- Dry sand is at Z < 0, the sea is at Z > 0 and gets deeper the further out you go.
Config.Beach = {
	ZoneLength = 400, -- studs per zone (full game: 5 zones over ~2,000-2,500 studs)
	ActiveZones = 3, -- test build only builds and tides over the first 3 zones
	DryWidth = 70, -- dry sand between the dunes and the waterline
	ShopLength = 110, -- shop area at X < 0
	SlopeRun = 60, -- seabed slopes down over this many studs from the waterline...
	SlopeDrop = 5, -- ...dropping this far
	SeaExtent = 260, -- how far the sea floor extends past the waterline
	WaterLevel = 1, -- Y of the sea surface

	-- Depth bands, measured as distance out from the waterline (Z).
	ShallowEnd = 15,
	KneeEnd = 30,
	WaistEnd = 45, -- past this the water is deep: players drown and vessels are lost
	LostZ = 75, -- loose items that drift past this are gone
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

-- Tide: travels down the beach, holds at the far end, then returns. Times are in seconds
-- and multiplied by TimeScale, so the test build can run a shorter cycle than the full 25 minutes.
Config.Tide = {
	OutTime = 600,
	HoldTime = 300,
	InTime = 600,
	TimeScale = 0.4, -- 0.4 => 10 minute cycle for testing. Set to 1 for the real 25 minutes.
	DeepOffset = 10, -- the first studs past the tide front are wadeable; deeper than that drowns you
	FloodOffset = 5, -- items this far past the front are lost to the tide
}

Config.Waves = {
	Period = 7, -- seconds between waves
	Speed = 14, -- studs/s the wave front travels toward shore
	StartZ = 70, -- where each wave starts (out at sea)
	EndZ = -6, -- how far up the dry sand a wave washes
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

Config.Items = {
	SpawnInterval = 1.25, -- seconds between spawn attempts
	MaxUnclaimedPerZone = 28,
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
}

Config.Drowning = {
	BreathTime = 12, -- seconds of breath in deep water
	RegenTime = 3, -- seconds to refill from empty
	DamagePerSecond = 18,
}

Config.Selling = {
	ShopkeeperRange = 22, -- how close to the shopkeeper you must be to buy
}

Config.Data = {
	StoreName = "SalvageSim3_Player_v1",
	AutosaveInterval = 120,
	LockStaleAfter = 600, -- a session lock older than this is assumed to be from a dead server
	LoadAttempts = 5,
}

return Config
