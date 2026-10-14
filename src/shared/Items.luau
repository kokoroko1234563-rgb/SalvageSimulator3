-- Placeholder beach loot for the test build. Value is the base sell price before the
-- zone multiplier. Shapes and colors are stand-ins until real models exist.

local Gear = require(script.Parent.Gear)
local Palette = require(script.Parent.Palette)

local Light = Gear.WeightClass.Light
local Medium = Gear.WeightClass.Medium
local Heavy = Gear.WeightClass.Heavy

local Items = {}

Items.Rarities = { "Common", "Uncommon", "Rare", "VeryRare" }

Items.RarityColors = Palette.Rarity

-- Density (g/cm^3 in Roblox units) gives each class a different feel when dragged.
Items.ClassDensity = {
	[Light] = 0.35,
	[Medium] = 0.8,
	[Heavy] = 1.6,
}

Items.Catalog = {
	-- Light
	{
		Id = "Seashell",
		Name = "Seashell",
		Class = Light,
		Rarity = "Common",
		Value = 4,
		Size = Vector3.new(1, 0.5, 1.2),
		Shape = "Ball",
		Color = Color3.fromRGB(250, 220, 200),
	},
	{
		Id = "GlassBottle",
		Name = "Glass Bottle",
		Class = Light,
		Rarity = "Common",
		Value = 6,
		Size = Vector3.new(1.6, 0.6, 0.6),
		Shape = "Cylinder",
		Color = Color3.fromRGB(110, 190, 140),
		Material = Palette.Material.Glass,
	},
	{
		Id = "FlipFlop",
		Name = "Flip-Flop",
		Class = Light,
		Rarity = "Common",
		Value = 5,
		Size = Vector3.new(0.8, 0.25, 1.8),
		Shape = "Block",
		Color = Color3.fromRGB(255, 120, 160),
	},
	{
		Id = "Sunglasses",
		Name = "Sunglasses",
		Class = Light,
		Rarity = "Uncommon",
		Value = 14,
		Size = Vector3.new(1.4, 0.4, 0.5),
		Shape = "Block",
		Color = Color3.fromRGB(30, 30, 40),
	},
	{
		Id = "MessageBottle",
		Name = "Message in a Bottle",
		Class = Light,
		Rarity = "Rare",
		Value = 40,
		Size = Vector3.new(1.8, 0.7, 0.7),
		Shape = "Cylinder",
		Color = Color3.fromRGB(160, 220, 255),
		Material = Palette.Material.Glass,
	},
	{
		Id = "Pearl",
		Name = "Pearl",
		Class = Light,
		Rarity = "VeryRare",
		Value = 120,
		Size = Vector3.new(0.7, 0.7, 0.7),
		Shape = "Ball",
		Color = Color3.fromRGB(250, 250, 255),
		Material = Palette.Material.Smooth,
	},
	{
		Id = "BeachBall",
		Name = "Beach Ball",
		Class = Light,
		Rarity = "Common",
		Value = 7,
		Size = Vector3.new(1.6, 1.6, 1.6),
		Shape = "Ball",
		Color = Color3.fromRGB(255, 90, 90),
	},
	-- Unlock items: never rolled as normal loot, never sold, banked at the shore.
	{
		Id = "GoldenSpade",
		Name = "Golden Spade",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "SandcastleFlats",
		Value = 0,
		Size = Vector3.new(0.6, 0.4, 2.6),
		Shape = "Block",
		Color = Color3.fromRGB(255, 200, 50),
		Material = Palette.Material.Foil,
	},
	{
		Id = "CaptainsKey",
		Name = "Captain's Key",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "ShipwreckShallows",
		Value = 0,
		Size = Vector3.new(0.5, 0.3, 1.8),
		Shape = "Block",
		Color = Color3.fromRGB(80, 200, 190),
		Material = Palette.Material.Metal,
	},
	{
		-- The rarest unlock item: a beam of light follows it until it's banked.
		Id = "BeaconPearl",
		Name = "Beacon Pearl",
		Class = Light,
		Rarity = "Unlock",
		Unlock = "FarSandbar",
		UnlockNote = "Opens the Sunken Bell Tower on the Far Sandbar, reachable around low tide. A beam of light follows it until it's banked",
		SkyBeam = true,
		Value = 0,
		Size = Vector3.new(1, 1, 1),
		Shape = "Ball",
		Color = Color3.fromRGB(255, 245, 200),
		Material = Palette.Material.Neon,
	},
	-- Medium
	{
		Id = "Bucket",
		Name = "Bucket",
		Class = Medium,
		Rarity = "Common",
		Value = 15,
		Size = Vector3.new(1.6, 1.8, 1.6),
		Shape = "Cylinder",
		Color = Color3.fromRGB(255, 200, 60),
	},
	{
		Id = "SmallCrate",
		Name = "Small Crate",
		Class = Medium,
		Rarity = "Uncommon",
		Value = 35,
		Size = Vector3.new(2, 2, 2),
		Shape = "Block",
		Color = Color3.fromRGB(170, 120, 70),
		Material = Palette.Material.WoodPlanks,
	},
	{
		Id = "Lantern",
		Name = "Lantern",
		Class = Medium,
		Rarity = "Rare",
		Value = 80,
		Size = Vector3.new(1.2, 2, 1.2),
		Shape = "Block",
		Color = Color3.fromRGB(200, 150, 60),
		Material = Palette.Material.Metal,
	},
	{
		Id = "Spyglass",
		Name = "Spyglass",
		Class = Medium,
		Rarity = "VeryRare",
		Value = 200,
		Size = Vector3.new(2.6, 0.7, 0.7),
		Shape = "Cylinder",
		Color = Color3.fromRGB(190, 160, 80),
		Material = Palette.Material.Metal,
	},
	-- Heavy
	{
		Id = "ShipBell",
		Name = "Ship's Bell",
		Class = Heavy,
		Rarity = "Uncommon",
		Value = 110,
		Size = Vector3.new(2, 2.2, 2),
		Shape = "Cylinder",
		Color = Color3.fromRGB(190, 150, 60),
		Material = Palette.Material.Metal,
	},
	{
		Id = "Barrel",
		Name = "Barrel",
		Class = Heavy,
		Rarity = "Common",
		Value = 55,
		Size = Vector3.new(3, 2.4, 2.4),
		Shape = "Cylinder",
		Color = Color3.fromRGB(130, 85, 50),
		Material = Palette.Material.Wood,
	},
	{
		Id = "BigCrate",
		Name = "Big Crate",
		Class = Heavy,
		Rarity = "Uncommon",
		Value = 90,
		Size = Vector3.new(3.2, 3.2, 3.2),
		Shape = "Block",
		Color = Color3.fromRGB(150, 100, 55),
		Material = Palette.Material.WoodPlanks,
	},
	{
		Id = "Anchor",
		Name = "Anchor",
		Class = Heavy,
		Rarity = "Rare",
		Value = 220,
		Size = Vector3.new(2.4, 3, 0.8),
		Shape = "Block",
		Color = Color3.fromRGB(80, 85, 95),
		Material = Palette.Material.Rust,
	},
	{
		Id = "ShipWheel",
		Name = "Ship's Wheel",
		Class = Heavy,
		Rarity = "VeryRare",
		Value = 450,
		Size = Vector3.new(0.6, 3.4, 3.4),
		Shape = "Cylinder",
		Color = Color3.fromRGB(120, 75, 40),
		Material = Palette.Material.Wood,
	},
}

local byId = {}
local byRarity = {}
for _, rarity in Items.Rarities do
	byRarity[rarity] = {}
end
for _, item in Items.Catalog do
	byId[item.Id] = item
	if byRarity[item.Rarity] then
		table.insert(byRarity[item.Rarity], item)
	end
end

function Items.get(id: string)
	return byId[id]
end

function Items.ofRarity(rarity: string)
	return byRarity[rarity] or {}
end

-- Rolls a rarity from a weight table such as { Common = 70, Uncommon = 25, Rare = 5 }.
function Items.rollRarity(weights: { [string]: number }, rng: Random): string
	local total = 0
	for _, rarity in Items.Rarities do
		total += weights[rarity] or 0
	end
	local roll = rng:NextNumber() * total
	for _, rarity in Items.Rarities do
		roll -= weights[rarity] or 0
		if roll <= 0 and (weights[rarity] or 0) > 0 then
			return rarity
		end
	end
	return "Common"
end

return Items
