-- Shop gear: grabbing tools and vessels. Order matters: a player always uses the best
-- (highest-listed) tool they own.

local Gear = {}

-- Weight classes and water depth bands are numbered so they can be compared.
Gear.WeightClass = { Light = 1, Medium = 2, Heavy = 3, VeryHeavy = 4 }
Gear.Depth = { Dry = 0, Shallow = 1, KneeDeep = 2, Waist = 3, Deep = 4 }

-- Grip is the acceleration (studs/s^2) the tool can hold an item with; gravity is ~196,
-- so a weak grip barely lifts and is easily knocked loose by waves.
-- GripBreak is how far (studs) an item can be pulled from the hold point before it slips.
Gear.Tools = {
	{
		Id = "BareHands",
		Rarity = "Common",
		Name = "Bare Hands",
		Price = 0,
		Reach = 10,
		Lift = Gear.WeightClass.Light,
		Depth = Gear.Depth.Shallow,
		Grip = 235,
		GripBreak = 5,
		Note = "Weak grip",
		Available = true,
	},
	{
		Id = "BeachRake",
		Rarity = "Common",
		Name = "Beach Rake",
		Price = 150,
		Reach = 14,
		Lift = Gear.WeightClass.Light,
		Depth = Gear.Depth.Shallow,
		Grip = 260,
		GripBreak = 6,
		Note = "Pulls items out of the shallows",
		Available = true,
	},
	{
		Id = "FishingNet",
		Rarity = "Common",
		Name = "Fishing Net",
		Price = 600,
		Reach = 14,
		Lift = Gear.WeightClass.Medium,
		Depth = Gear.Depth.Shallow,
		Grip = 330,
		GripBreak = 7,
		Note = "Better grip",
		Available = true,
	},
	{
		Id = "GrabberClaw",
		Rarity = "Uncommon",
		Name = "Grabber Claw",
		Price = 2500,
		Reach = 18,
		Lift = Gear.WeightClass.Medium,
		Depth = Gear.Depth.KneeDeep,
		Grip = 360,
		GripBreak = 7,
		Note = "Grabs from knee-deep water",
		Available = true,
	},
	{
		-- Not in the doc's Milestone 1 list, but enabled so Heavy placeholder items can be tested.
		Id = "BoatHook",
		Rarity = "Rare",
		Name = "Boat Hook",
		Price = 9000,
		Reach = 18,
		Lift = Gear.WeightClass.Heavy,
		Depth = Gear.Depth.Waist,
		Grip = 420,
		GripBreak = 8,
		Note = "Reaches deeper water",
		Available = true,
	},
	{
		Id = "HandWinch",
		Rarity = "Rare",
		Name = "Hand Winch",
		Price = 30000,
		Reach = 24,
		Lift = Gear.WeightClass.Heavy,
		Depth = Gear.Depth.Waist,
		Grip = 520,
		GripBreak = 10,
		Note = "Strong grip against waves",
		Available = false,
	},
	{
		Id = "ElectricWinch",
		Rarity = "VeryRare",
		Name = "Electric Winch",
		Price = 90000,
		Reach = 24,
		Lift = Gear.WeightClass.VeryHeavy,
		Depth = Gear.Depth.Waist,
		Grip = 620,
		GripBreak = 10,
		Note = "Pulls chests out of rough water",
		Available = false,
	},
	{
		-- Exotic (Sunken Hold lootbox): needs attunement to use. Never in the shop.
		Id = "AnchorHook",
		Name = "Anchor Hook",
		Rarity = "Exotic",
		Price = 0,
		Reach = 22,
		Lift = Gear.WeightClass.Heavy,
		Depth = Gear.Depth.Waist,
		Grip = 480,
		GripBreak = 10,
		Note = "Exotic grabber: long reach, holds tight in the surf",
		Available = false,
		Exotic = true,
	},
	{
		-- Magical (rebirth reward): pulls whatever it grabs toward you through the water.
		Id = "TideMagnet",
		Name = "Tide Magnet",
		Rarity = "VeryRare",
		Price = 0,
		Reach = 26,
		Lift = Gear.WeightClass.Heavy,
		Depth = Gear.Depth.Waist,
		Grip = 500,
		GripBreak = 12,
		Note = "Magical grabber: pulls items toward you through the water",
		Available = false,
		Magical = true,
		Magnet = true,
	},
	{
		-- Magical (rebirth reward): floats anything to you in a bubble, slowly; waves can't
		-- knock it loose.
		Id = "BubbleWand",
		Name = "Bubble Wand",
		Rarity = "VeryRare",
		Price = 0,
		Reach = 30,
		Lift = Gear.WeightClass.VeryHeavy,
		Depth = Gear.Depth.Deep,
		Grip = 600,
		GripBreak = math.huge,
		Note = "Magical grabber: floats any item to you in a bubble, slowly. Waves can't knock it loose",
		Available = false,
		Magical = true,
		Bubble = true,
		MaxSpeed = 10,
	},
	-- Exotic grabbers from the rare biomes' lootboxes. Need attunement; never in the shop.
	{
		-- Whirlwind Dunes: a gust reels whatever it holds toward you, in or out of the water.
		Id = "GustGloves",
		Name = "Gust Gloves",
		Rarity = "Exotic",
		Price = 0,
		Reach = 28,
		Lift = Gear.WeightClass.Heavy,
		Depth = Gear.Depth.Waist,
		Grip = 520,
		GripBreak = 12,
		Note = "Exotic grabber: a gust reels items in fast, in or out of the water",
		Available = false,
		Exotic = true,
		Magnet = true,
		PullSpeed = 16,
		PullAnywhere = true,
	},
	{
		-- Hermit Hollows: short, but nothing pulls out of its grip.
		Id = "CrabClaw",
		Name = "Crab Claw",
		Rarity = "Exotic",
		Price = 0,
		Reach = 14,
		Lift = Gear.WeightClass.VeryHeavy,
		Depth = Gear.Depth.Waist,
		Grip = 900,
		GripBreak = 25,
		Note = "Exotic grabber: short reach, lifts anything, almost impossible to knock loose",
		Available = false,
		Exotic = true,
	},
	{
		-- Black Sand Vents: the best all-round grabber.
		Id = "ObsidianGrabber",
		Name = "Obsidian Grabber",
		Rarity = "Exotic",
		Price = 0,
		Reach = 30,
		Lift = Gear.WeightClass.VeryHeavy,
		Depth = Gear.Depth.Deep,
		Grip = 700,
		GripBreak = 14,
		Note = "Exotic grabber: very long reach, lifts anything, reaches into deep water",
		Available = false,
		Exotic = true,
	},
	{
		-- Stranded Iceberg: freezes the waves around you for a few seconds (never the tide).
		Id = "FreezeWand",
		Name = "Freeze Wand",
		Rarity = "Exotic",
		Price = 0,
		Reach = 18,
		Lift = Gear.WeightClass.Medium,
		Depth = Gear.Depth.KneeDeep,
		Grip = 400,
		GripBreak = 8,
		Note = "Exotic grabber: press F to freeze the waves around you for 5 seconds (25s cooldown)",
		Available = false,
		Exotic = true,
		Freeze = { Duration = 5, Cooldown = 25, Radius = 30 },
	},
	{
		-- Temporary, for exploring the dark deep zones: given with the admin console (give
		-- lantern), not sold. Held from the hotbar like a tool, it lights the way but picks
		-- nothing up (carts can still be towed).
		Id = "Lantern",
		Rarity = "Common",
		Name = "Lantern",
		Price = 0,
		Reach = 0,
		Lift = Gear.WeightClass.Light,
		Depth = Gear.Depth.Dry,
		Grip = 0,
		GripBreak = 0,
		NoGrab = true,
		Light = { Color = Color3.fromRGB(255, 214, 140), Range = 40, Brightness = 2.5 },
		Note = "Lights the way; can't pick anything up",
		Available = false,
	},
}

Gear.Vessels = {
	{
		Id = "Wheelbarrow",
		Size = "Small", -- its box against the map (Config.Carts)
		Rarity = "Common",
		Name = "Wheelbarrow",
		Price = 10, -- a first cart for trying the shop: affordable almost at once
		Capacity = 4,
		Note = "Slow, tips easily",
		Available = true,
	},
	{
		Id = "BeachWagon",
		Size = "Medium", -- its box against the map (Config.Carts)
		Rarity = "Common",
		Name = "Beach Wagon",
		Price = 1500,
		Capacity = 6,
		Note = "More stable",
		Available = true,
	},
	{
		Id = "SandCart",
		Size = "Medium", -- its box against the map (Config.Carts)
		Rarity = "Uncommon",
		Name = "Sand Cart",
		Price = 6000,
		Capacity = 10,
		Note = "Fast on soft sand",
		Available = true,
		Speed = 1.3,
		Stability = 1.2,
	},
	{
		Id = "QuadBike",
		Size = "Large", -- its box against the map (Config.Carts)
		Rarity = "Rare",
		Name = "Quad Bike + Trailer",
		Price = 25000,
		Capacity = 16,
		Note = "Fast, bumps can spill items",
		Available = true,
		Speed = 1.5,
		Stability = 0.5,
	},
	{
		Id = "Dinghy",
		Size = "Large", -- its box against the map (Config.Carts)
		Rarity = "Rare",
		Name = "Inflatable Dinghy",
		Price = 60000,
		Capacity = 14,
		Note = "Travels through deep water, lost if flipped",
		Available = true,
		Boat = true, -- survives deep water when towed; tipping over loses it
		Stability = 1.4,
	},
	{
		Id = "PickupTruck",
		Size = "Huge", -- its box against the map (Config.Carts)
		Rarity = "VeryRare",
		Name = "Pickup Truck",
		Price = 150000,
		Capacity = 24,
		Note = "Fastest and most stable",
		Available = true,
		Speed = 1.8,
		Stability = 3,
	},
	{
		-- Magical vessel from a rebirth reward: never sold in the shop, kept through rebirths.
		Id = "FloatingClamshell",
		Size = "Medium", -- its box against the map (Config.Carts)
		Rarity = "VeryRare",
		Name = "Floating Clamshell",
		Price = 0,
		Capacity = 8,
		Note = "Magical: hovers behind you, never tips",
		Available = false,
		Magical = true,
	},
	{
		-- Exotic (Sunken Hold lootbox): needs attunement to spawn. Never in the shop.
		Id = "CaptainsLongboat",
		Size = "Large", -- its box against the map (Config.Carts)
		Name = "Captain's Longboat",
		Rarity = "Exotic",
		Price = 0,
		Capacity = 12,
		Note = "Exotic vessel: long, steady, holds 12",
		Available = false,
		Exotic = true,
	},
	{
		-- Magical (rebirth reward): swims, so deep water doesn't take it.
		Id = "SeaTurtle",
		Size = "Small", -- its box against the map (Config.Carts)
		Name = "Sea Turtle",
		Rarity = "VeryRare",
		Price = 0,
		Capacity = 6,
		Note = "Magical: swims, so it survives being covered. Cargo can wash off. Slow on sand",
		Available = false,
		Magical = true,
		Swims = true,
	},
	{
		-- Exotic (Sunken Bell Tower lootbox).
		Id = "LeviathanRowboat",
		Size = "Huge", -- its box against the map (Config.Carts)
		Name = "Leviathan Rowboat",
		Rarity = "Exotic",
		Price = 0,
		Capacity = 20,
		Note = "Exotic vessel: huge and steady, holds 20",
		Available = false,
		Exotic = true,
	},
	-- Exotic vessels from the rare biomes' lootboxes.
	{
		-- Jellyfish Lagoon: a bouncy raft that follows you and swims.
		Id = "JellyRaft",
		Size = "Medium", -- its box against the map (Config.Carts)
		Name = "Jelly Raft",
		Rarity = "Exotic",
		Price = 0,
		Capacity = 10,
		Note = "Exotic vessel: follows you and swims, so deep water doesn't take it. Holds 10",
		Available = false,
		Exotic = true,
		Follows = true,
		Swims = true,
	},
	{
		-- Whirlwind Dunes: flies behind you, over sand and sea alike.
		Id = "MagicCarpet",
		Size = "Medium", -- its box against the map (Config.Carts)
		Name = "Magic Carpet",
		Rarity = "Exotic",
		Price = 0,
		Capacity = 10,
		Note = "Exotic vessel: flies behind you over sand and sea, fast. Holds 10",
		Available = false,
		Exotic = true,
		Follows = true,
		Flies = true,
		Speed = 1.5,
	},
	{
		-- Hermit Hollows: a giant shell on wheels, very hard to tip.
		Id = "ShellWagon",
		Size = "Large", -- its box against the map (Config.Carts)
		Name = "Shell Wagon",
		Rarity = "Exotic",
		Price = 0,
		Capacity = 14,
		Note = "Exotic vessel: a giant shell on wheels, very hard to tip. Holds 14",
		Available = false,
		Exotic = true,
		Stability = 3,
	},
	{
		-- Sea-Glass Shore: a glass swan that swims behind you.
		Id = "GlassSwan",
		Size = "Medium", -- its box against the map (Config.Carts)
		Name = "Glass Swan",
		Rarity = "Exotic",
		Price = 0,
		Capacity = 12,
		Note = "Exotic vessel: swims behind you, through deep water. Holds 12",
		Available = false,
		Exotic = true,
		Follows = true,
		Swims = true,
	},
	{
		-- Stranded Iceberg: slides fast over sand and ice.
		Id = "FrostSled",
		Size = "Large", -- its box against the map (Config.Carts)
		Name = "Frost Sled",
		Rarity = "Exotic",
		Price = 0,
		Capacity = 12,
		Note = "Exotic vessel: slides very fast over sand. Holds 12",
		Available = false,
		Exotic = true,
		Speed = 1.7,
		Stability = 1.5,
	},
}

-- Worn items. Exotic ones need attunement.
Gear.Accessories = {
	{
		-- Temporary, for exploring the dark deep zones: given with the admin console (give
		-- headlamp), not sold. To be replaced by proper lamp gear.
		Id = "Headlamp",
		Name = "Headlamp",
		Rarity = "Common",
		Light = { Color = Color3.fromRGB(255, 244, 220), Range = 40, Brightness = 2.5 },
		Note = "Lights up the dark around you",
	},
	{
		Id = "DeckhandsSatchel",
		Name = "Deckhand's Satchel",
		Rarity = "Exotic",
		PocketSlots = 3,
		Note = "Exotic accessory: 3 extra pocket slots for Light items",
		Exotic = true,
	},
	{
		-- Exotic (Sunken Bell Tower lootbox).
		Id = "TideCrown",
		Name = "Tide Crown",
		Rarity = "Exotic",
		WaveResist = 0.25,
		Note = "Exotic accessory: waves push you 25% less",
		Exotic = true,
	},
	-- Exotic accessories from the rare biomes' lootboxes.
	{
		-- Jellyfish Lagoon.
		Id = "GlowPearl",
		Name = "Glow Pearl",
		Rarity = "Exotic",
		Light = { Color = Color3.fromRGB(150, 240, 255), Range = 18, Brightness = 1.5 },
		BreathBonus = 0.25,
		Note = "Exotic accessory: glows around you, and your breath lasts 25% longer",
		Exotic = true,
	},
	{
		-- Fog Bank.
		Id = "LanternOfClearSight",
		Name = "Lantern of Clear Sight",
		Rarity = "Exotic",
		Light = { Color = Color3.fromRGB(255, 235, 170), Range = 16, Brightness = 1.2 },
		ClearSight = 2.5,
		Note = "Exotic accessory: you see 2.5x further through the haze",
		Exotic = true,
	},
	{
		-- Fog Bank.
		Id = "Foghorn",
		Name = "Foghorn",
		Rarity = "Exotic",
		WaveWarning = 10,
		Note = "Exotic accessory: warns you of big and rogue waves 10 seconds earlier",
		Exotic = true,
	},
	{
		-- Spearstone Reef.
		Id = "TidewalkerBoots",
		Name = "Tidewalker Boots",
		Rarity = "Exotic",
		WaveResist = 0.3,
		WadeBonus = 0.5,
		Note = "Exotic accessory: waves push you 30% less, and water slows you half as much",
		Exotic = true,
	},
	{
		-- Sea-Glass Shore.
		Id = "PrismLens",
		Name = "Prism Lens",
		Rarity = "Exotic",
		RevealRare = 150,
		Note = "Exotic accessory: rare items and unlock items within 150 studs shine through anything",
		Exotic = true,
	},
	{
		-- Black Sand Vents.
		Id = "EmberLantern",
		Name = "Ember Lantern",
		Rarity = "Exotic",
		Light = { Color = Color3.fromRGB(255, 140, 60), Range = 16, Brightness = 1.5 },
		BreathBonus = 0.5,
		Note = "Exotic accessory: keeps you warm underwater: breath lasts 50% longer",
		Exotic = true,
	},
}

-- Worn for looks only. Each is a hat: a cylinder of Height and Width, with an optional
-- brim of diameter Brim. Auction cosmetics are scarce: Of = how many will ever exist.
Gear.Cosmetics = {
	{
		Id = "TallTopHat",
		Name = "Tall Top Hat",
		Rarity = "VeryRare",
		Note = "From the man on the dirt tower, for completing the lexicon. Wear it with pride",
		Tradeable = false,
		Hat = { Height = 2.4, Width = 1.3, Brim = 2, Color = Color3.fromRGB(25, 25, 30), Material = "Fabric" },
	},
	{
		Id = "CrownOfTides",
		Name = "Crown of Tides",
		Rarity = "Auction",
		Note = "One of a kind. Won at the global auction",
		Tradeable = true,
		Hat = { Height = 0.8, Width = 1.5, Color = Color3.fromRGB(255, 200, 60), Material = "Foil" },
		Auction = { Of = 1, StartingBid = 50000 },
	},
	{
		Id = "CaptainsTricorn",
		Name = "Captain's Tricorn",
		Rarity = "Auction",
		Note = "A numbered tricorn from the global auction",
		Tradeable = true,
		Hat = {
			Height = 0.7,
			Width = 1.6,
			Brim = 2.6,
			Color = Color3.fromRGB(35, 30, 40),
			Material = "Fabric",
		},
		Auction = { Of = 50, StartingBid = 10000 },
	},
	{
		Id = "SeaGlassCirclet",
		Name = "Sea-Glass Circlet",
		Rarity = "Auction",
		Note = "A numbered circlet of sea glass from the global auction",
		Tradeable = true,
		Hat = { Height = 0.35, Width = 1.6, Color = Color3.fromRGB(130, 220, 200), Material = "Glass" },
		Auction = { Of = 25, StartingBid = 20000 },
	},
}

local toolsById = {}
for index, tool in Gear.Tools do
	tool.Order = index
	toolsById[tool.Id] = tool
end

local vesselsById = {}
for index, vessel in Gear.Vessels do
	vessel.Order = index
	vesselsById[vessel.Id] = vessel
end

local accessoriesById = {}
for _, accessory in Gear.Accessories do
	accessoriesById[accessory.Id] = accessory
end

function Gear.getAccessory(id: string?)
	return accessoriesById[id or ""]
end

local cosmeticsById = {}
for _, cosmetic in Gear.Cosmetics do
	cosmeticsById[cosmetic.Id] = cosmetic
end

function Gear.getCosmetic(id: string?)
	return cosmeticsById[id or ""]
end

function Gear.getTool(id: string?)
	return toolsById[id or ""] or Gear.Tools[1]
end

-- Like getTool, but nil for an unknown id instead of falling back to bare hands.
function Gear.findTool(id: any)
	return if type(id) == "string" then toolsById[id] else nil
end

function Gear.getVessel(id: string?)
	return vesselsById[id or ""]
end

-- Picks the best shop tool from a set of owned ids ({ [id] = true }). Exotic tools are only
-- ever used when equipped (and attuned).
function Gear.bestTool(owned: { [string]: boolean })
	local best = Gear.Tools[1]
	for _, tool in Gear.Tools do
		if owned[tool.Id] and not tool.Exotic and not tool.Magical and not tool.NoGrab then
			best = tool
		end
	end
	return best
end

function Gear.canLift(tool, weightClass: number): boolean
	return weightClass <= tool.Lift
end

function Gear.canReachDepth(tool, depthBand: number): boolean
	return depthBand <= tool.Depth
end

return Gear
