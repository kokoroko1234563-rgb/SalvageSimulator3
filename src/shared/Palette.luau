-- Every colour, material and font the game uses, by name. Code refers to these names
-- (Palette.UI.Accent, Palette.Material.Wood) instead of writing Color3s and Enum items
-- inline, so a look is changed in one place, and a wrong Enum name fails here, at startup,
-- in one obvious spot (tools/check_api.py also checks every Enum name against Roblox's API).
-- Item colours stay with the item data; everything shared lives here.

local rgb = Color3.fromRGB

local Palette = {}

Palette.UI = {
	Background = rgb(25, 45, 60), -- panels
	Console = rgb(18, 24, 30), -- admin console
	Card = rgb(34, 58, 76), -- rows and cards
	CardRaised = rgb(40, 70, 90), -- reward choices
	Input = rgb(32, 42, 52),
	Track = rgb(20, 30, 40), -- empty bars
	Tab = rgb(60, 80, 95),

	Text = rgb(255, 255, 255),
	Muted = rgb(170, 195, 210),
	Soft = rgb(190, 210, 225),
	DisabledText = rgb(200, 205, 210),
	Placeholder = rgb(120, 135, 145),
	Hint = rgb(150, 165, 175),
	Banner = rgb(255, 240, 200),
	Debug = rgb(255, 255, 160),

	Accent = rgb(255, 215, 120), -- gold: headings, borders
	Buy = rgb(235, 150, 40),
	Disabled = rgb(70, 80, 90),
	Danger = rgb(200, 80, 70), -- close and drop buttons
	Spawn = rgb(60, 140, 220),
	Equipped = rgb(60, 160, 90),
	ToggleOn = rgb(60, 140, 90),
	Pocket = rgb(150, 100, 200),
	Attune = rgb(40, 190, 170),
	TrueRebirth = rgb(150, 90, 230),
	Robux = rgb(40, 170, 90),

	Bad = rgb(255, 120, 110), -- "too heavy", "too deep"
	Warn = rgb(255, 160, 120),
	Claimed = rgb(180, 180, 180),
	Breath = rgb(120, 210, 255),
	BreathLow = rgb(255, 90, 80),
	Checkpoint = rgb(120, 230, 255),
}

Palette.Rarity = {
	Common = rgb(235, 235, 235),
	Uncommon = rgb(120, 220, 120),
	Rare = rgb(90, 160, 255),
	VeryRare = rgb(200, 110, 255),
	Unlock = rgb(255, 205, 60),
	Exotic = rgb(40, 225, 200),
	Auction = rgb(255, 120, 60),
}

Palette.Coin = {
	Yellow = rgb(255, 215, 40),
	Orange = rgb(255, 140, 40),
	Blue = rgb(60, 140, 255),
	Green = rgb(70, 200, 90),
	Pink = rgb(255, 120, 200),
}

-- Inventory card borders: when an item is lost.
Palette.Reset = {
	Rebirth = rgb(255, 150, 40),
	TrueRebirth = rgb(175, 110, 255),
}

Palette.World = {
	Sand = rgb(250, 222, 150),
	WetSand = rgb(222, 184, 114),
	Rock = rgb(178, 150, 122), -- warm sandstone
	Sea = rgb(24, 196, 214),
	Flood = rgb(40, 120, 170),
	Foam = rgb(255, 255, 255),
	Boardwalk = rgb(190, 135, 85),
	Post = rgb(240, 240, 240),
	Shopkeeper = rgb(255, 170, 90),
	SellPad = rgb(255, 210, 60),
	BankPad = rgb(190, 110, 255),
	Wheel = rgb(40, 40, 40),
	DarkWood = rgb(70, 45, 25),
	Hatch = rgb(40, 30, 20),
	Mast = rgb(80, 55, 35),
	Barrel = rgb(120, 80, 45),
	ChestWood = rgb(120, 75, 35),
	Dirt = rgb(120, 90, 60),
	Skin = rgb(240, 200, 160),
	Hat = rgb(25, 25, 30),
	TraderCoat = rgb(80, 120, 160),

	-- Buildings and people on the shore.
	Stucco = rgb(255, 240, 212),
	SignText = rgb(70, 40, 20),
	RoofTile = rgb(230, 105, 75),
	Awning = rgb(225, 75, 65),
	AwningCream = rgb(248, 242, 225),
	Window = rgb(160, 222, 245),
	Counter = rgb(140, 95, 55),
	Pants = rgb(55, 60, 85),
	Buyer = rgb(90, 160, 110),
	Banker = rgb(60, 90, 150),

	-- Beach dressing.
	Driftwood = rgb(150, 130, 105),
	Palm = rgb(120, 90, 55),
	Frond = rgb(60, 175, 80),
	Lifeguard = rgb(230, 60, 50),
	UmbrellaRed = rgb(230, 90, 80),
	UmbrellaTeal = rgb(60, 170, 190),
	UmbrellaYellow = rgb(245, 200, 70),
	ShellPink = rgb(245, 205, 200),
	ShellCream = rgb(250, 240, 220),
	ShellTan = rgb(215, 180, 140),
	SandDark = rgb(238, 205, 132),
}

-- Props that give each zone its look (see ZoneProps).
Palette.Zone = {
	ChairWhite = rgb(248, 248, 244),
	ChairCoral = rgb(255, 120, 90),
	ChairSky = rgb(90, 180, 225),
	TowelRed = rgb(230, 70, 90),
	TowelBlue = rgb(70, 150, 230),
	TowelYellow = rgb(250, 200, 60),
	HutWall = rgb(238, 224, 192),
	HutTealRoof = rgb(60, 150, 150),
	HutThatch = rgb(190, 150, 80),
	Pier = rgb(150, 110, 70),
	Piling = rgb(95, 72, 50),
	RockGrey = rgb(128, 122, 116),
	RockDark = rgb(82, 80, 78),
	Coral1 = rgb(255, 110, 130),
	Coral2 = rgb(255, 165, 70),
	Coral3 = rgb(190, 115, 235),
	Pool = rgb(70, 205, 225),
	Net = rgb(205, 200, 185),
	Hull = rgb(60, 130, 200),
	HullInside = rgb(250, 248, 240),
	StoneLight = rgb(196, 186, 170),
	StoneDark = rgb(150, 140, 128),
	Bell = rgb(220, 170, 60),
	Ridge = rgb(226, 204, 152),
}

-- Biome looks (see BiomeModels): each biome's own colours.
Palette.Biome = {
	SandcastleSand = rgb(230, 200, 140),
	Moat = rgb(70, 170, 220),
	Rope = rgb(200, 170, 110),
	Bottle = rgb(110, 190, 130),
	Boot = rgb(90, 60, 40),
	Hollow = rgb(60, 40, 25),
	Starfish = rgb(240, 130, 80),
	BuoyRed = rgb(230, 60, 60),
	BuoyWhite = rgb(250, 250, 250),
	Seagrass = rgb(70, 140, 70),
	Float = rgb(120, 220, 140),
	Coconut = rgb(120, 85, 50),
	Snorkel = rgb(245, 245, 245),
	JellyBlue = rgb(140, 230, 255),
	JellyPink = rgb(255, 150, 220),
	Tentacle = rgb(200, 240, 255),
	Lagoon = rgb(60, 210, 220),
	Glow = rgb(120, 255, 240),
	LighthouseWhite = rgb(245, 245, 240),
	LighthouseRed = rgb(200, 50, 50),
	LampGlass = rgb(255, 235, 150),
	Fog = rgb(240, 245, 250),
	Foghorn = rgb(180, 160, 60),
	Hermit = rgb(190, 120, 90),
	Claw = rgb(230, 110, 90),
	Tunnel = rgb(200, 170, 120),
	Spear = rgb(130, 120, 110),
	SpearTip = rgb(170, 160, 150),
	GlassTeal = rgb(120, 230, 220),
	GlassPink = rgb(255, 160, 220),
	GlassWhite = rgb(235, 250, 255),
	GlassViolet = rgb(190, 160, 255),
	IceWhite = rgb(235, 248, 255),
	IceBlue = rgb(160, 215, 240),
	IceDeep = rgb(90, 160, 210),
	IceCave = rgb(60, 120, 170),
	BlackSand = rgb(35, 32, 32),
	VentGrey = rgb(70, 65, 65),
	Lava = rgb(255, 120, 40),
	Steam = rgb(245, 245, 245),
	TubeDark = rgb(40, 30, 30),
	WhirlSand = rgb(215, 190, 140),
}

Palette.Material = {
	Sand = Enum.Material.Sand,
	Wood = Enum.Material.Wood,
	WoodPlanks = Enum.Material.WoodPlanks,
	Rock = Enum.Material.Slate,
	Metal = Enum.Material.Metal,
	Rust = Enum.Material.CorrodedMetal,
	Glass = Enum.Material.Glass,
	Water = Enum.Material.Glass,
	Neon = Enum.Material.Neon,
	Smooth = Enum.Material.SmoothPlastic,
	Foil = Enum.Material.Foil,
	Fabric = Enum.Material.Fabric,
	Dirt = Enum.Material.Ground,
	Grass = Enum.Material.Grass,
}

-- Accents for the beach item models (src/server/ItemModels.luau). Item body colours stay
-- with the item data; these are the extra colours a model needs on top of that.
Palette.ItemModel = {
	White = rgb(255, 255, 255),
	Label = rgb(248, 246, 238),
	Paper = rgb(246, 236, 206),
	Cork = rgb(196, 150, 95),
	Wax = rgb(210, 50, 55),
	Iron = rgb(90, 95, 105),
	Hole = rgb(35, 30, 30), -- openings, interiors, the key's eye
	Sunglasses = rgb(40, 50, 95),
	SpyLens = rgb(90, 150, 210),
	Flame = rgb(255, 200, 110),
	LanternGlass = rgb(255, 230, 160),
	Glow = rgb(255, 232, 160), -- the Beacon Pearl's halo
	Sun = rgb(255, 214, 70), -- yellow accents
	Aqua = rgb(60, 175, 240), -- blue accents
	Glint = rgb(255, 210, 235), -- a pearl's shine
	Gold = rgb(235, 190, 70), -- trims, locks, the compass case
	Needle = rgb(215, 45, 45), -- the compass needle's north end
	Barnacle = rgb(215, 210, 190),
	Jelly = rgb(255, 140, 220), -- the glowing jellyfish in the jar
	Magma = rgb(255, 120, 40), -- the obsidian egg's cracks
	Rubber = rgb(40, 45, 50), -- snorkel mouthpiece and mask
	MaskGlass = rgb(150, 210, 235),
	Fish = rgb(120, 150, 170),
	Float = rgb(240, 140, 50), -- the net's floats
	Rock = rgb(110, 105, 100),
	Moss = rgb(95, 140, 75),
}

-- Colours for the tool models (src/server/ToolModels.luau).
Palette.ToolModel = {
	Pole = rgb(238, 214, 170),
	PoleDark = rgb(176, 122, 72),
	Brass = rgb(240, 190, 70),
	Steel = rgb(196, 210, 228),
	Red = rgb(235, 75, 70),
	Yellow = rgb(255, 205, 60),
	Orange = rgb(255, 150, 50),
	Blue = rgb(60, 150, 240),
	White = rgb(250, 250, 250),
	Rope = rgb(225, 195, 140),
	Teal = rgb(40, 225, 200),
	Green = rgb(90, 255, 150),
	Pink = rgb(255, 140, 200),
	Violet = rgb(175, 130, 255),
	Film = rgb(235, 225, 255),
	Sky = rgb(150, 215, 255),
	Obsidian = rgb(52, 46, 74),
	Lava = rgb(255, 112, 40),
	Ice = rgb(170, 235, 255),
	Frost = rgb(232, 250, 255),
}

-- Paint for the vessels (src/server/VesselTrim.luau).
Palette.VesselTrim = {
	Sunny = rgb(255, 200, 60),
	Coral = rgb(240, 90, 85),
	Pearl = rgb(255, 190, 225),
	Teal = rgb(45, 175, 195),
	Lime = rgb(110, 205, 90),
	LimeDark = rgb(60, 160, 70),
	LimeLight = rgb(165, 225, 105),
	Royal = rgb(60, 115, 225),
	Gold = rgb(255, 214, 70),
	White = rgb(255, 255, 255),
	Aqua = rgb(90, 235, 205),
	Oak = rgb(214, 152, 92),
	Red = rgb(235, 75, 70),
}

-- Cheerful colours for the beach scenery (src/server/BeachCheer.luau).
Palette.Cheer = {
	Mint = rgb(170, 235, 205),
	Peach = rgb(255, 200, 170),
	Butter = rgb(255, 235, 150),
	Sky = rgb(150, 205, 255),
	Coral = rgb(255, 125, 110),
	Lilac = rgb(200, 170, 255),
	Aqua = rgb(70, 215, 220),
	Sun = rgb(255, 205, 70),
	Pink = rgb(255, 150, 195),
	Lime = rgb(140, 215, 90),
	Leaf = rgb(80, 170, 70),
	White = rgb(255, 255, 255),
	Door = rgb(120, 80, 60),
	Pole = rgb(245, 245, 245),
}

Palette.Font = {
	Title = Enum.Font.FredokaOne,
	Body = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Code = Enum.Font.Code,
}

return Palette
