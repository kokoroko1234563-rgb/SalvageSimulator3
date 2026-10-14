-- Builds the placeholder beach from code so the test build runs from an empty place.
-- Swap this for a hand-built map later; gameplay only depends on the coordinates in
-- Config.Beach: shoreline along X, shop at Z < 0, sand sloping into the sea toward +Z,
-- zones as bands running out to sea. The sea itself is drawn by each client (it moves
-- with the tide), see TideController.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)

local BeachDressing = require(script.Parent.BeachDressing)
local Buildings = require(script.Parent.Buildings)
local MapParts = require(script.Parent.MapParts)

local beach = Config.Beach

local BeachBuilder = {}

local SAND = Palette.World.Sand
local WET_SAND = Palette.World.WetSand
local ROCK = Palette.World.Rock

-- Where the shop buildings stand, on the dry sand behind the shoreline.
local HOUSE_Z = -48
local HOUSE_WIDTH = 36
local HOUSE_DEPTH = 28
local HOUSE_HEIGHT = 14
local SHOP_X = -150
local BANK_X = 150
local SELL_PAD = Vector3.new(85, 1.1, -30)

-- A block whose top face slopes down from (zStart, yStart) to (zEnd, yEnd).
local function slopedBlock(
	name: string,
	x0: number,
	x1: number,
	zStart: number,
	yStart: number,
	zEnd: number,
	yEnd: number,
	color: Color3
)
	local run = zEnd - zStart
	local drop = yStart - yEnd
	local angle = math.atan2(drop, run)
	local length = math.sqrt(run * run + drop * drop)
	local thickness = 6
	local topCenter = Vector3.new((x0 + x1) / 2, (yStart + yEnd) / 2, (zStart + zEnd) / 2)
	local orientation = CFrame.Angles(angle, 0, 0)
	local center = topCenter - orientation.UpVector * thickness / 2
	return MapParts.part({
		Name = name,
		Size = Vector3.new(x1 - x0, thickness, length + 0.2),
		CFrame = CFrame.new(center) * orientation,
		Color = color,
		Material = Palette.Material.Sand,
	})
end

-- The beach is cut into strips along Z. Each strip is a little darker the further out it is
-- (wetter), with some variation, so the sand reads as sand rather than one flat colour.
local function buildBeach(map: Folder)
	local rng = Random.new(11)
	local stripLength = 30
	local z = 0
	while z < Beach.Depth do
		local nextZ = math.min(z + stripLength, Beach.Depth)
		local wetness = (z / Beach.Depth) * 0.6 + rng:NextNumber(0, 0.25)
		local color = SAND:Lerp(WET_SAND, wetness)
		slopedBlock(
			"Beach",
			-Beach.HalfWidth,
			Beach.HalfWidth,
			z,
			Beach.groundY(z),
			nextZ,
			Beach.groundY(nextZ),
			color
		).Parent =
			map
		z = nextZ
	end
end

local function buildSea(map: Folder)
	local seaEnd = Beach.Depth + beach.SeaExtent
	slopedBlock(
		"Seabed",
		-Beach.HalfWidth - 300,
		Beach.HalfWidth + 300,
		Beach.Depth,
		Beach.groundY(Beach.Depth),
		seaEnd,
		Beach.groundY(seaEnd),
		SAND
	).Parent =
		map
end

-- Zone markers: a tall post at each side of the beach where each zone starts.
local function buildZoneMarkers(map: Folder)
	local half = Beach.HalfWidth
	for index = 1, beach.ActiveZones do
		local zone = Config.Zones[index]
		local startZ = Beach.zoneRange(index) + 1
		local groundY = Beach.groundY(startZ)
		local topY = 14
		for side = -1, 1, 2 do
			local post = MapParts.part({
				Name = "ZoneMarker" .. index,
				Size = Vector3.new(1.2, topY - groundY, 1.2),
				CFrame = CFrame.new(side * (half - 8), (topY + groundY) / 2, startZ),
				Color = Palette.World.Post,
				Material = Palette.Material.Wood,
			})
			local flag = MapParts.part({
				Name = "Flag",
				Size = Vector3.new(0.2, 2.5, 4),
				CFrame = CFrame.new(side * (half - 8), topY - 1.5, startZ + 2.2),
				Color = Color3.fromHSV((index - 1) / beach.ActiveZones * 0.6, 0.7, 1),
				CanCollide = false,
			})
			flag.Parent = post
			MapParts.label(
				post,
				string.format("Zone %d · %s · x%d", index, zone.Name, zone.Multiplier),
				Vector3.new(0, post.Size.Y / 2 + 3, 0)
			)
			post.Parent = map
		end
	end
end

-- The shop: the shopkeeper's house, the buyer by the sell pad, and the bank house.
local function buildShop(map: Folder)
	local shop = Instance.new("Folder")
	shop.Name = "Shop"
	shop.Parent = map

	MapParts.part({
		Name = "Boardwalk",
		Size = Vector3.new(120, 1, beach.ShopDepth - 10),
		CFrame = CFrame.new(0, 0.5, -beach.ShopDepth / 2 - 2),
		Color = Palette.World.Boardwalk,
		Material = Palette.Material.WoodPlanks,
	}).Parent =
		shop

	-- Shopkeeper's house: the shopkeeper stands behind the counter, facing the door.
	Buildings.house(
		shop,
		"ShopHouse",
		Vector3.new(SHOP_X, 0, HOUSE_Z),
		HOUSE_WIDTH,
		HOUSE_DEPTH,
		HOUSE_HEIGHT,
		"SHOP"
	)
	Buildings.counter(shop, Vector3.new(SHOP_X, Buildings.FLOOR, HOUSE_Z + 4), 16)
	local shopkeeper = Buildings.person(
		shop,
		"Shopkeeper",
		CFrame.new(SHOP_X, Buildings.FLOOR, HOUSE_Z - 4) * CFrame.Angles(0, math.pi, 0),
		Palette.World.Shopkeeper,
		"Shopkeeper"
	)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Shopkeeper"
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = shopkeeper

	-- The sell pad, and the buyer who sells what's on it when you talk to them.
	local sellZone = MapParts.part({
		Name = "SellZone",
		Size = Vector3.new(30, 0.2, 22),
		CFrame = CFrame.new(SELL_PAD),
		Color = Palette.World.SellPad,
		Material = Palette.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		CanQuery = false,
	})
	MapParts.label(sellZone, "SELL: drop items here, then talk to the buyer", Vector3.new(0, 5, 0))
	sellZone.Parent = shop

	local buyer = Buildings.person(
		shop,
		"Buyer",
		CFrame.new(62, 0, SELL_PAD.Z) * CFrame.Angles(0, -math.pi / 2, 0),
		Palette.World.Buyer,
		"Buyer"
	)
	local buyerPrompt = Instance.new("ProximityPrompt")
	buyerPrompt.Name = "BuyerPrompt"
	buyerPrompt.ActionText = "Sell"
	buyerPrompt.ObjectText = "Buyer"
	buyerPrompt.MaxActivationDistance = Config.Selling.BuyerRange
	buyerPrompt.RequiresLineOfSight = false
	buyerPrompt.Parent = buyer

	-- The bank house: unlock items dropped on the purple floor inside are banked.
	Buildings.house(
		shop,
		"BankHouse",
		Vector3.new(BANK_X, 0, HOUSE_Z),
		HOUSE_WIDTH,
		HOUSE_DEPTH,
		HOUSE_HEIGHT,
		"BANK"
	)
	Buildings.counter(shop, Vector3.new(BANK_X, Buildings.FLOOR, HOUSE_Z - 6), 16)
	Buildings.person(
		shop,
		"Banker",
		CFrame.new(BANK_X, Buildings.FLOOR, HOUSE_Z - 10) * CFrame.Angles(0, math.pi, 0),
		Palette.World.Banker,
		"Banker"
	)

	local bankPad = MapParts.part({
		Name = "BankPad",
		Size = Vector3.new(24, 0.2, 14),
		CFrame = CFrame.new(BANK_X, Buildings.FLOOR + 0.1, HOUSE_Z + 4),
		Color = Palette.World.BankPad,
		Material = Palette.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		CanQuery = false,
	})
	MapParts.label(bankPad, "BANK: drop unlock items here to keep them safe", Vector3.new(0, 4, 0))
	bankPad.Parent = shop

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BeachSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 1.1, -50)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = shop
end

-- Haze over the far part of the map, so you can't see all of it at once.
local function setFog()
	Lighting.FogStart = beach.Fog.Start
	Lighting.FogEnd = beach.Fog.End
	Lighting.FogColor = beach.Fog.Color
end

function BeachBuilder.build(): Folder
	local old = Workspace:FindFirstChild("Baseplate")
	if old then
		old:Destroy()
	end
	for _, child in Workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 150, 130)
	setFog()

	local map = Instance.new("Folder")
	map.Name = "Map"

	local half = Beach.HalfWidth
	local seaEnd = Beach.Depth + beach.SeaExtent

	-- Flat dry ground behind the shoreline (shop area).
	MapParts.part({
		Name = "DrySand",
		Size = Vector3.new(beach.Width, 10, beach.ShopDepth),
		CFrame = CFrame.new(0, -5, -beach.ShopDepth / 2),
		Color = Palette.World.Sand,
		Material = Palette.Material.Sand,
	}).Parent =
		map

	-- Dunes behind the shop.
	MapParts.part({
		Name = "Dunes",
		Size = Vector3.new(beach.Width + 60, 16, 40),
		CFrame = CFrame.new(0, 0, -beach.ShopDepth - 20),
		Color = Palette.World.Sand,
		Material = Palette.Material.Sand,
	}).Parent =
		map

	-- The beach: one long slope from the shoreline out under the sea. The tide uncovers more
	-- or less of it.
	buildBeach(map)
	buildSea(map)

	-- Rocky headlands on both sides make the beach a cove.
	for side = -1, 1, 2 do
		local length = seaEnd + beach.ShopDepth + 40
		MapParts.part({
			Name = "Headland",
			Size = Vector3.new(40, 120, length),
			CFrame = CFrame.new(side * (half + 20), -40, -beach.ShopDepth - 40 + length / 2),
			Color = ROCK,
			Material = Palette.Material.Rock,
		}).Parent =
			map
	end

	buildZoneMarkers(map)
	buildShop(map)

	local dressingRng = Random.new(7)
	BeachDressing.build(map, dressingRng)

	map.Parent = Workspace
	return map
end

return BeachBuilder
