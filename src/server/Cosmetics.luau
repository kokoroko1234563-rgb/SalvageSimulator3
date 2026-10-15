-- Places the cosmetic models and textures. Each zone's themed props (loungers on Shopside Shore,
-- crabs and nets on Middle Banks, reef life on Outer Shore, ruins on the Far Sandbar) go in that
-- zone's band; each biome's props go in that biome's plot (see BiomeModels). Textures are laid
-- over the sand and the sea floor.
--
-- Everything placed here is cosmetic. It's small, flat or low, and never collides, so none of it
-- is part of the active map: no hazards, no obstacles, nothing that blocks the view.
-- Positions come from seeded Randoms, so every server builds the same beach.

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)

local BiomeModels = require(script.Parent.BiomeModels)
local CosmeticModels = require(script.Parent.CosmeticModels)
local Textures = require(script.Parent.Textures)

local Cosmetics = {}

local beach = Config.Beach

-- Which zone each zone theme belongs to, and how many of each model go in it. The outer zones
-- sit under the sea, so they get fewer.
local ZONE_OF_THEME = {
	["Shopside Shore"] = 1,
	["Sunny Stretch"] = 2,
	["Middle Banks"] = 3,
	["Outer Shore"] = 4,
	["The Far Sandbar"] = 5,
}
local COPIES = { 3, 3, 3, 2, 2 }
local BIOME_COPIES = 4

-- The lowest the sea gets, and how far under it things must stay to count as under water.
local LOW_WATER_Y = -Tide.LowWaterline * beach.Slope
local UNDERWATER_CLEARANCE = 1.5

-- A spot in a zone's band, across the width of the beach. Zone 1 keeps clear of the shop, and the
-- last zone stops where the sea floor does.
local function bandSpot(zone: number, rng: Random, minZ: number?): Vector3
	local zMin, zMax = Beach.zoneRange(zone)
	local low = math.max(zMin + 14, minZ or 0)
	local high = zMax - 12
	if zone == #Config.Zones then
		high = Beach.Depth + beach.SeaExtent - 12
	end
	local half = Beach.HalfWidth - 30
	local z = rng:NextNumber(low, math.max(high, low))
	local x = rng:NextNumber(-half, half)
	return Vector3.new(x, Beach.groundAt(x, z), z)
end

-- A spot on the sea floor that's always under water, whatever the tide.
local function seaSpot(rng: Random, height: number): Vector3
	local minZ = (-LOW_WATER_Y + UNDERWATER_CLEARANCE + height) / beach.Slope
	local zMax = Beach.Depth + beach.SeaExtent - 12
	local z = rng:NextNumber(math.max(minZ, Beach.Depth + 20), zMax)
	local half = Beach.HalfWidth - 30
	local x = rng:NextNumber(-half, half)
	return Vector3.new(x, Beach.groundAt(x, z), z)
end

-- A spot inside a biome's plot, away from the middle where its big structures stand.
local function plotSpot(center: Vector3, rng: Random): Vector3
	local angle = rng:NextNumber() * math.pi * 2
	local distance = rng:NextNumber(20, 40)
	return center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

local function placeModel(folder: Instance, entry: CosmeticModels.Entry, position: Vector3, rng: Random)
	local model = Instance.new("Model")
	model.Name = entry.Id
	model.Parent = folder
	entry.Build(
		model,
		CFrame.new(position - Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0),
		rng
	)
end

-- Places every model and texture into `map`. Returns how many of each it placed, for the tests.
function Cosmetics.build(map: Instance): { Models: number, Textures: number }
	local root = Instance.new("Folder")
	root.Name = "Cosmetics"
	root.Parent = map
	local placedModels, placedTextures = 0, 0

	for _, entry in CosmeticModels.List do
		local zone = ZONE_OF_THEME[entry.Theme]
		local plot = BiomeModels.Plots[entry.Theme]
		if not zone and not plot then
			continue
		end
		local themeFolder = root:FindFirstChild(entry.Theme) or Instance.new("Folder")
		themeFolder.Name = entry.Theme
		themeFolder.Parent = root

		local rng = Random.new(900 + placedModels)
		local copies = if zone then COPIES[zone] else BIOME_COPIES
		for _ = 1, copies do
			local position
			if entry.Underwater then
				position = seaSpot(rng, entry.Variant.Height or entry.Height)
			elseif zone then
				position = bandSpot(zone, rng)
			else
				position = plotSpot(plot, rng)
			end
			placeModel(themeFolder, entry, position, rng)
			placedModels += 1
		end
	end

	local texturesFolder = Instance.new("Folder")
	texturesFolder.Name = "Textures"
	texturesFolder.Parent = root
	for _, kind in Textures.List do
		local kindFolder = Instance.new("Folder")
		kindFolder.Name = kind.Id
		kindFolder.Parent = texturesFolder
		local rng = Random.new(1500 + placedTextures)
		local plot = BiomeModels.Plots[kind.Theme]
		for _ = 1, kind.Count do
			local position
			if kind.Region == "sea" then
				position = seaSpot(rng, 0)
			elseif kind.Region == "plot" then
				if not plot then
					break
				end
				position = plotSpot(plot, rng)
			elseif kind.Range then
				local z = rng:NextNumber(kind.Range[1], kind.Range[2])
				local half = Beach.HalfWidth - 30
				local x = rng:NextNumber(-half, half)
				position = Vector3.new(x, Beach.groundAt(x, z), z)
			else
				position = bandSpot(ZONE_OF_THEME[kind.Theme], rng)
			end
			kind.Build(kindFolder, position, rng)
			placedTextures += 1
		end
	end

	return { Models = placedModels, Textures = placedTextures }
end

return Cosmetics
