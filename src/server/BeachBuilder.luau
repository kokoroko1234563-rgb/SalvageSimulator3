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
local BiomeModels = require(script.Parent.BiomeModels)
local ZoneProps = require(script.Parent.ZoneProps)

local beach = Config.Beach

local BeachBuilder = {}

local SAND = Palette.World.Sand
local WET_SAND = Palette.World.WetSand
local ROCK = Palette.World.Rock

-- Where the shop buildings stand, on the dry sand behind the shoreline.
local HOUSE_Z = -50
local HOUSE_WIDTH = 48
local HOUSE_DEPTH = 36
local SHOP_X = -200
local BANK_X = 200
local SELL_PAD = Vector3.new(90, 1.1, -30)
local SELL_PAD_SIZE = Vector3.new(30, 0.2, 22)
local BANK_PAD_SIZE = Vector3.new(32, 0.2, 16)
local BUYER_X = 68

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

-- Flat patches of lighter and darker sand scattered over the beach, so it isn't one colour.
local function buildSandPatches(map: Folder)
	local folder = Instance.new("Folder")
	folder.Name = "SandPatches"
	folder.Parent = map
	local rng = Random.new(23)
	local tilt = math.atan(beach.Slope)
	local bleached = SAND:Lerp(Color3.new(1, 1, 1), 0.35)
	local damp = SAND:Lerp(WET_SAND, 0.45)
	for _ = 1, 420 do
		local x = rng:NextNumber(-Beach.HalfWidth + 4, Beach.HalfWidth - 4)
		local z = rng:NextNumber(2, Beach.Depth + 40)
		local diameter = rng:NextNumber(3, 8)
		local color = if rng:NextNumber() < 0.5 then bleached else damp
		MapParts.part({
			Name = "SandPatch",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.15, diameter, diameter),
			CFrame = CFrame.new(x, Beach.groundY(z) + 0.05, z)
				* CFrame.Angles(tilt, rng:NextNumber() * math.pi * 2, 0)
				* CFrame.Angles(0, 0, math.pi / 2),
			Color = color,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
		}).Parent =
			folder
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

-- Zone markers: a tall post at each side of the beach where each zone starts, with its name
-- on a sign across the post.
local function buildZoneMarkers(map: Folder)
	local half = Beach.HalfWidth
	for index = 1, beach.ActiveZones do
		local zone = Config.Zones[index]
		local startZ = Beach.zoneRange(index) + 1
		local groundY = Beach.groundY(startZ)
		local topY = 14
		for side = -1, 1, 2 do
			local x = side * (half - 8)
			local post = MapParts.part({
				Name = "ZoneMarker" .. index,
				Size = Vector3.new(1.2, topY - groundY, 1.2),
				CFrame = CFrame.new(x, (topY + groundY) / 2, startZ),
				Color = Palette.World.Post,
				Material = Palette.Material.Wood,
			})
			post.Parent = map
			local flag = MapParts.part({
				Name = "Flag",
				Size = Vector3.new(0.2, 2.5, 4),
				CFrame = CFrame.new(x, topY - 1.5, startZ + 2.2),
				Color = Color3.fromHSV((index - 1) / beach.ActiveZones * 0.6, 0.7, 1),
				CanCollide = false,
			})
			flag.Parent = post
			MapParts.sign(
				post,
				string.format("Zone %d · %s · x%d", index, zone.Name, zone.Multiplier),
				CFrame.new(x, 11, startZ),
				16,
				3
			)
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
		Size = Vector3.new(120, 2, beach.ShopDepth - 10),
		CFrame = CFrame.new(0, 0, -beach.ShopDepth / 2 - 2),
		Color = Palette.World.Boardwalk,
		Material = Palette.Material.WoodPlanks,
	}).Parent =
		shop

	-- Shopkeeper's house: the shopkeeper stands behind the counter, facing the door.
	Buildings.house(shop, "ShopHouse", Vector3.new(SHOP_X, 0, HOUSE_Z), HOUSE_WIDTH, HOUSE_DEPTH, "SHOP")
	Buildings.counter(shop, Vector3.new(SHOP_X, Buildings.FLOOR, HOUSE_Z + 4), 22, "SHOPKEEPER")
	local shopkeeper = Buildings.person(
		shop,
		"Shopkeeper",
		CFrame.new(SHOP_X, Buildings.FLOOR, HOUSE_Z - 2) * CFrame.Angles(0, math.pi, 0),
		Palette.World.Shopkeeper
	)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Shopkeeper"
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = shopkeeper.PrimaryPart

	-- The sell pad, its sign, and the buyer who sells what's on it when you talk to them.
	local sellZone = MapParts.part({
		Name = "SellZone",
		Size = SELL_PAD_SIZE,
		CFrame = CFrame.new(SELL_PAD),
		Color = Palette.World.SellPad,
		Material = Palette.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		CanQuery = false,
	})
	sellZone.Parent = shop
	MapParts.sign(
		shop,
		"SELL: drop items on the yellow pad, then talk to the buyer",
		CFrame.new(SELL_PAD.X, 5, SELL_PAD.Z - SELL_PAD_SIZE.Z / 2 - 2),
		26,
		2.6,
		0
	)

	local buyer = Buildings.person(
		shop,
		"Buyer",
		CFrame.new(BUYER_X, 0, SELL_PAD.Z) * CFrame.Angles(0, -math.pi / 2, 0),
		Palette.World.Buyer
	)
	MapParts.sign(
		shop,
		"BUYER",
		CFrame.new(BUYER_X - 4, 5, SELL_PAD.Z - 10),
		12,
		2.4,
		0
	)
	local buyerPrompt = Instance.new("ProximityPrompt")
	buyerPrompt.Name = "BuyerPrompt"
	buyerPrompt.ActionText = "Sell"
	buyerPrompt.ObjectText = "Buyer"
	buyerPrompt.MaxActivationDistance = Config.Selling.BuyerRange
	buyerPrompt.RequiresLineOfSight = false
	buyerPrompt.Parent = buyer.PrimaryPart

	-- The bank house: unlock items dropped on the purple floor inside are banked when you talk to
	-- the banker.
	Buildings.house(shop, "BankHouse", Vector3.new(BANK_X, 0, HOUSE_Z), HOUSE_WIDTH, HOUSE_DEPTH, "BANK")
	Buildings.counter(shop, Vector3.new(BANK_X, Buildings.FLOOR, HOUSE_Z - 8), 22, "BANKER")
	local banker = Buildings.person(
		shop,
		"Banker",
		CFrame.new(BANK_X, Buildings.FLOOR, HOUSE_Z - 12) * CFrame.Angles(0, math.pi, 0),
		Palette.World.Banker
	)
	local bankerPrompt = Instance.new("ProximityPrompt")
	bankerPrompt.Name = "BankerPrompt"
	bankerPrompt.ActionText = "Bank"
	bankerPrompt.ObjectText = "Banker"
	bankerPrompt.MaxActivationDistance = Config.Banking.BankerRange
	bankerPrompt.RequiresLineOfSight = false
	bankerPrompt.Parent = banker.PrimaryPart

	local bankPad = MapParts.part({
		Name = "BankPad",
		Size = BANK_PAD_SIZE,
		CFrame = CFrame.new(BANK_X, Buildings.FLOOR + 0.1, HOUSE_Z + 4),
		Color = Palette.World.BankPad,
		Material = Palette.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		CanQuery = false,
	})
	bankPad.Parent = shop
	MapParts.sign(
		shop,
		"BANK: drop unlock items on the purple floor, then talk to the banker",
		CFrame.new(BANK_X, 12, HOUSE_Z - HOUSE_DEPTH / 2 + 1.6),
		HOUSE_WIDTH * 0.6,
		3
	)

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

-- The look: haze over the far part of the map, and Roblox's own lighting effects for a bright,
-- saturated, sunny feel. These are engine objects, not assets. Each is made once and reused.
local function setLighting()
	Lighting.FogStart = beach.Fog.Start
	Lighting.FogEnd = beach.Fog.End
	Lighting.FogColor = beach.Fog.Color

	local function ensure(className: string): Instance
		local existing = Lighting:FindFirstChildOfClass(className)
		if existing then
			return existing
		end
		local created = Instance.new(className)
		created.Parent = Lighting
		return created
	end

	local atmosphere = ensure("Atmosphere") :: Atmosphere
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(200, 228, 242)
	atmosphere.Decay = Color3.fromRGB(110, 170, 210)
	atmosphere.Glare = 0.25
	atmosphere.Haze = 1.4

	local correction = ensure("ColorCorrectionEffect") :: ColorCorrectionEffect
	correction.Saturation = 0.25
	correction.Contrast = 0.08
	correction.Brightness = 0.02
	correction.TintColor = Color3.fromRGB(255, 246, 230)

	local bloom = ensure("BloomEffect") :: BloomEffect
	bloom.Intensity = 0.35
	bloom.Size = 18
	bloom.Threshold = 0.9

	local sunRays = ensure("SunRaysEffect") :: SunRaysEffect
	sunRays.Intensity = 0.12
	sunRays.Spread = 0.8
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
	setLighting()

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

	-- Low dunes behind the shop, so the cove stays open.
	MapParts.part({
		Name = "Dunes",
		Size = Vector3.new(beach.Width + 60, 8, 40),
		CFrame = CFrame.new(0, 0, -beach.ShopDepth - 20),
		Color = Palette.World.Sand,
		Material = Palette.Material.Sand,
	}).Parent =
		map

	-- The beach: one long slope from the shoreline out under the sea. The tide uncovers more
	-- or less of it.
	buildBeach(map)
	buildSandPatches(map)
	buildSea(map)

	-- Rocky headlands on both sides, pushed out and kept low so the cove reads as open.
	for side = -1, 1, 2 do
		local length = seaEnd + beach.ShopDepth + 40
		MapParts.part({
			Name = "Headland",
			Size = Vector3.new(80, 70, length),
			CFrame = CFrame.new(side * (half + 60), -25, -beach.ShopDepth - 40 + length / 2),
			Color = ROCK,
			Material = Palette.Material.Rock,
		}).Parent =
			map
	end

	buildZoneMarkers(map)
	buildShop(map)
	BeachDressing.build(map, Random.new(7))
	ZoneProps.build(map)
	BiomeModels.showcase(map)

	map.Parent = Workspace
	return map
end

return BeachBuilder
