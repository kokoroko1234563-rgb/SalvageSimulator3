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
	Sand = rgb(236, 215, 160),
	WetSand = rgb(196, 170, 120),
	Rock = rgb(120, 115, 105),
	Sea = rgb(50, 150, 195),
	Flood = rgb(40, 120, 170),
	Foam = rgb(255, 255, 255),
	Boardwalk = rgb(160, 115, 75),
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
}

Palette.Font = {
	Title = Enum.Font.FredokaOne,
	Body = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Code = Enum.Font.Code,
}

return Palette
