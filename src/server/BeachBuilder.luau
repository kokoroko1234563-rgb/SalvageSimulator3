-- Builds the placeholder beach from code so the test build runs from an empty place.
-- Swap this for a hand-built map later; gameplay only depends on the coordinates in
-- Config.Beach (beach along +X, waterline at Z = 0, sea toward +Z).

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)

local beach = Config.Beach

local BeachBuilder = {}

local SAND = Color3.fromRGB(236, 215, 160)
local WET_SAND = Color3.fromRGB(196, 170, 120)
local SEA = Color3.fromRGB(60, 160, 200)

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

	local x0 = -beach.ShopLength
	local x1 = Beach.Length + 200 -- a little beach past the end, under the tide
	local width = x1 - x0
	local midX = (x0 + x1) / 2

	-- Dry sand.
	makePart({
		Name = "DrySand",
		Size = Vector3.new(width, 10, beach.DryWidth),
		CFrame = CFrame.new(midX, -5, -beach.DryWidth / 2),
		Color = SAND,
		Material = Enum.Material.Sand,
	}).Parent =
		map

	-- Dunes behind the beach.
	makePart({
		Name = "Dunes",
		Size = Vector3.new(width, 14, 30),
		CFrame = CFrame.new(midX, 0, -beach.DryWidth - 15),
		Color = SAND,
		Material = Enum.Material.Sand,
	}).Parent =
		map

	-- Seabed: slope, then a flat floor out to sea.
	slopedBlock("SeabedSlope", x0, x1, 0, 0, beach.SlopeRun, -beach.SlopeDrop).Parent = map
	local floorDepth = beach.SeaExtent - beach.SlopeRun
	makePart({
		Name = "SeaFloor",
		Size = Vector3.new(width, 6, floorDepth),
		CFrame = CFrame.new(midX, -beach.SlopeDrop - 3, beach.SlopeRun + floorDepth / 2),
		Color = WET_SAND,
		Material = Enum.Material.Sand,
	}).Parent =
		map

	-- Static sea surface (visual only).
	makePart({
		Name = "SeaSurface",
		Size = Vector3.new(width, 0.4, beach.SeaExtent),
		CFrame = CFrame.new(midX, beach.WaterLevel - 0.2, beach.SeaExtent / 2),
		Color = SEA,
		Material = Enum.Material.Glass,
		Transparency = 0.45,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
	}).Parent =
		map

	-- Zone markers: a flag post at the start of each zone with its name and multiplier.
	for index = 1, beach.ActiveZones do
		local zone = Config.Zones[index]
		local startX = Beach.zoneRange(index)
		local post = makePart({
			Name = "ZoneMarker" .. index,
			Size = Vector3.new(1, 14, 1),
			CFrame = CFrame.new(startX, 7, -8),
			Color = Color3.fromRGB(240, 240, 240),
			Material = Enum.Material.Wood,
		})
		label(
			post,
			string.format("Zone %d · %s · x%d", index, zone.Name, zone.Multiplier),
			Vector3.new(0, 9, 0)
		)
		post.Parent = map
	end

	-- Shop area.
	local shop = Instance.new("Folder")
	shop.Name = "Shop"
	shop.Parent = map

	makePart({
		Name = "Boardwalk",
		Size = Vector3.new(beach.ShopLength - 10, 1, 60),
		CFrame = CFrame.new(-beach.ShopLength / 2, 0.5, -32),
		Color = Color3.fromRGB(160, 115, 75),
		Material = Enum.Material.WoodPlanks,
	}).Parent =
		shop

	local shopkeeper = makePart({
		Name = "Shopkeeper",
		Size = Vector3.new(3, 6, 2),
		CFrame = CFrame.new(-45, 4, -45),
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
		CFrame = CFrame.new(-25, 1.1, -14),
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
		CFrame = CFrame.new(-75, 1.1, -14),
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
	spawn.CFrame = CFrame.new(-60, 1.1, -45)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = shop

	map.Parent = Workspace
	return map
end

return BeachBuilder
