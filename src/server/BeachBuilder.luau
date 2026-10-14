-- Builds the placeholder beach from code so the test build runs from an empty place.
-- Swap this for a hand-built map later; gameplay only depends on the coordinates in
-- Config.Beach: shoreline along X, shop at Z < 0, sand sloping into the sea toward +Z,
-- zones as bands running out to sea. The sea itself is drawn by each client (it moves
-- with the tide), see TideController.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)

local beach = Config.Beach

local BeachBuilder = {}

local SAND = Color3.fromRGB(236, 215, 160)
local WET_SAND = Color3.fromRGB(196, 170, 120)
local ROCK = Color3.fromRGB(120, 115, 105)

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function label(parent: BasePart, text: string, offset: Vector3)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 50)
	gui.StudsOffset = offset
	gui.AlwaysOnTop = false
	gui.MaxDistance = 250
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.4
	textLabel.Text = text
	textLabel.Parent = gui
	gui.Parent = parent
end

-- A block whose top face slopes down from (zStart, yStart) to (zEnd, yEnd).
local function slopedBlock(
	name: string,
	x0: number,
	x1: number,
	zStart: number,
	yStart: number,
	zEnd: number,
	yEnd: number
)
	local run = zEnd - zStart
	local drop = yStart - yEnd
	local angle = math.atan2(drop, run)
	local length = math.sqrt(run * run + drop * drop)
	local thickness = 6
	local topCenter = Vector3.new((x0 + x1) / 2, (yStart + yEnd) / 2, (zStart + zEnd) / 2)
	local orientation = CFrame.Angles(angle, 0, 0)
	local center = topCenter - orientation.UpVector * thickness / 2
	return makePart({
		Name = name,
		Size = Vector3.new(x1 - x0, thickness, length + 0.2),
		CFrame = CFrame.new(center) * orientation,
		Color = WET_SAND,
		Material = Enum.Material.Sand,
	})
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

	local map = Instance.new("Folder")
	map.Name = "Map"

	local half = Beach.HalfWidth
	local seaEnd = Beach.Depth + beach.SeaExtent

	-- Flat dry ground behind the shoreline (shop area).
	makePart({
		Name = "DrySand",
		Size = Vector3.new(beach.Width, 10, beach.ShopDepth),
		CFrame = CFrame.new(0, -5, -beach.ShopDepth / 2),
		Color = SAND,
		Material = Enum.Material.Sand,
	}).Parent =
		map

	-- Dunes behind the shop.
	makePart({
		Name = "Dunes",
		Size = Vector3.new(beach.Width + 60, 16, 40),
		CFrame = CFrame.new(0, 0, -beach.ShopDepth - 20),
		Color = SAND,
		Material = Enum.Material.Sand,
	}).Parent =
		map

	-- The beach: one long slope from the shoreline out under the sea. The tide uncovers more
	-- or less of it.
	local sand = slopedBlock("Beach", -half, half, 0, 0, Beach.Depth, Beach.groundY(Beach.Depth))
	sand.Color = SAND
	sand.Parent = map
	slopedBlock(
		"Seabed",
		-half - 300,
		half + 300,
		Beach.Depth,
		Beach.groundY(Beach.Depth),
		seaEnd,
		Beach.groundY(seaEnd)
	).Parent =
		map

	-- Rocky headlands on both sides make the beach a cove.
	for side = -1, 1, 2 do
		local length = seaEnd + beach.ShopDepth + 40
		makePart({
			Name = "Headland",
			Size = Vector3.new(40, 120, length),
			CFrame = CFrame.new(side * (half + 20), -40, -beach.ShopDepth - 40 + length / 2),
			Color = ROCK,
			Material = Enum.Material.Slate,
		}).Parent =
			map
	end

	-- Zone markers: a tall post at each side of the beach where each zone starts.
	for index = 1, beach.ActiveZones do
		local zone = Config.Zones[index]
		local startZ = Beach.zoneRange(index) + 1
		local groundY = Beach.groundY(startZ)
		local topY = 14
		for side = -1, 1, 2 do
			local post = makePart({
				Name = "ZoneMarker" .. index,
				Size = Vector3.new(1.2, topY - groundY, 1.2),
				CFrame = CFrame.new(side * (half - 8), (topY + groundY) / 2, startZ),
				Color = Color3.fromRGB(240, 240, 240),
				Material = Enum.Material.Wood,
			})
			local flag = makePart({
				Name = "Flag",
				Size = Vector3.new(0.2, 2.5, 4),
				CFrame = CFrame.new(side * (half - 8), topY - 1.5, startZ + 2.2),
				Color = Color3.fromHSV((index - 1) / beach.ActiveZones * 0.6, 0.7, 1),
				CanCollide = false,
			})
			flag.Parent = post
			label(
				post,
				string.format("Zone %d · %s · x%d", index, zone.Name, zone.Multiplier),
				Vector3.new(0, post.Size.Y / 2 + 3, 0)
			)
			post.Parent = map
		end
	end

	-- Shop area.
	local shop = Instance.new("Folder")
	shop.Name = "Shop"
	shop.Parent = map

	makePart({
		Name = "Boardwalk",
		Size = Vector3.new(120, 1, beach.ShopDepth - 10),
		CFrame = CFrame.new(0, 0.5, -beach.ShopDepth / 2 - 2),
		Color = Color3.fromRGB(160, 115, 75),
		Material = Enum.Material.WoodPlanks,
	}).Parent =
		shop

	local shopkeeper = makePart({
		Name = "Shopkeeper",
		Size = Vector3.new(3, 6, 2),
		CFrame = CFrame.new(-25, 4, -62) * CFrame.Angles(0, math.pi, 0),
		Color = Color3.fromRGB(255, 170, 90),
	})
	label(shopkeeper, "Shopkeeper", Vector3.new(0, 4.5, 0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Shopkeeper"
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = shopkeeper
	shopkeeper.Parent = shop

	local sellZone = makePart({
		Name = "SellZone",
		Size = Vector3.new(30, 0.2, 22),
		CFrame = CFrame.new(28, 1.1, -24),
		Color = Color3.fromRGB(255, 210, 60),
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		CanQuery = false,
	})
	label(sellZone, "SELL: drop items or park your vessel here", Vector3.new(0, 5, 0))
	sellZone.Parent = shop

	local vesselPad = makePart({
		Name = "VesselPad",
		Size = Vector3.new(16, 0.2, 16),
		CFrame = CFrame.new(-30, 1.1, -22),
		Color = Color3.fromRGB(90, 180, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		CanQuery = false,
	})
	label(vesselPad, "Vessels spawn here", Vector3.new(0, 4, 0))
	vesselPad.Parent = shop

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

	map.Parent = Workspace
	return map
end

return BeachBuilder
