-- What the showroom shows (see Showroom.luau). Each section is a list of exhibits: a name, an
-- optional note and pedestal height, and a Build function that builds the thing around the
-- point it's given. Builders don't need to know their size or final spot; the showroom
-- measures each one and lays the room out.
--
-- To show something new, add an exhibit to a section here (or a new section). Most models in
-- the game are already a function that takes a parent and a position, so an entry is usually
-- one line: Build = function(p, at) MyModels.thing(p, at.Position) end.

local Shared = game:GetService("ReplicatedStorage").Shared
local Biomes = require(Shared.Biomes)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Palette = require(Shared.Palette)

local BeachDressing = require(script.Parent.BeachDressing)
local BiomeModels = require(script.Parent.BiomeModels)
local BiomeService = require(script.Parent.BiomeService)
local Buildings = require(script.Parent.Buildings)
local CosmeticService = require(script.Parent.CosmeticService)
local FarSandbarService = require(script.Parent.FarSandbarService)
local ItemModels = require(script.Parent.ItemModels)
local MapParts = require(script.Parent.MapParts)
local VesselService = require(script.Parent.VesselService)
local ZoneProps = require(script.Parent.ZoneProps)

local Z = Palette.Zone
local W = Palette.World

local function sortedKeys(t: { [string]: any }): { string }
	local keys = {}
	for key in t do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

-- Materials: the same neutral cube in every material the game uses.
local function materials()
	local list = {}
	for _, name in sortedKeys(Palette.Material) do
		local material = Palette.Material[name]
		table.insert(list, {
			Name = name,
			Note = material.Name,
			Pedestal = 1,
			Build = function(p, at)
				MapParts.part({
					Name = name,
					Size = Vector3.new(4, 4, 4),
					CFrame = at + Vector3.new(0, 2, 0),
					Color = W.Sand,
					Material = material,
				}).Parent =
					p
			end,
		})
	end
	return list
end

-- Colours: a swatch for every colour in a Palette group, in its own material-neutral finish.
local function colours(group: string)
	local list = {}
	for _, name in sortedKeys(Palette[group]) do
		local color = Palette[group][name]
		if typeof(color) ~= "Color3" then
			continue
		end
		table.insert(list, {
			Name = name,
			Note = string.format("%d, %d, %d", color.R * 255 + 0.5, color.G * 255 + 0.5, color.B * 255 + 0.5),
			Build = function(p, at)
				MapParts.part({
					Name = name,
					Size = Vector3.new(3, 1.5, 3),
					CFrame = at + Vector3.new(0, 0.75, 0),
					Color = color,
					Material = Palette.Material.Smooth,
				}).Parent =
					p
			end,
		})
	end
	return list
end

-- Beach items: the catalog body with its model on it, exactly as it washes up.
local function items()
	local list = {}
	for _, def in Items.Catalog do
		table.insert(list, {
			Name = def.Name,
			Note = def.Rarity .. (if ItemModels.has(def.Id) then "" else " · no model yet"),
			Pedestal = 2,
			Build = function(p, at)
				local root = Instance.new("Part")
				root.Name = def.Name
				root.Shape = Enum.PartType[def.Shape]
				root.Size = def.Size
				root.Color = def.Color
				root.Material = def.Material or Palette.Material.Smooth
				root.TopSurface = Enum.SurfaceType.Smooth
				root.BottomSurface = Enum.SurfaceType.Smooth
				root.Anchored = true
				root.CFrame = at + Vector3.new(0, def.Size.Y / 2, 0)
				ItemModels.build(root, def)
				root.Parent = p
			end,
		})
	end
	return list
end

local function vessels()
	local list = {}
	for _, def in Gear.Vessels do
		local build = VesselService._builders[def.Id]
		if build then
			table.insert(list, {
				Name = def.Name,
				Note = "Holds " .. def.Capacity,
				Build = function(p, at)
					local model = Instance.new("Model")
					model.Name = def.Name
					build(model, at)
					model.Parent = p
				end,
			})
		end
	end
	return list
end

-- Hats, standing upright (they're built lying along X, the way they're worn).
local function cosmetics()
	local list = {}
	for _, cosmetic in Gear.Cosmetics do
		table.insert(list, {
			Name = cosmetic.Name,
			Note = cosmetic.Rarity,
			Pedestal = 2,
			Build = function(p, at)
				local accessory = CosmeticService.build(cosmetic)
				local handle = accessory:FindFirstChild("Handle") :: BasePart
				local upright = at
					* CFrame.new(0, cosmetic.Hat.Height / 2, 0)
					* CFrame.Angles(0, 0, math.pi / 2)
				local offset = upright * handle.CFrame:Inverse()
				for _, part in accessory:GetDescendants() do
					if part:IsA("BasePart") then
						part.CFrame = offset * part.CFrame
					end
				end
				accessory.Parent = p
			end,
		})
	end
	return list
end

local function rng(): Random
	return Random.new(42)
end

local function pieces()
	local P = ZoneProps.pieces
	return {
		{
			Name = "Palm",
			Build = function(p, at)
				BeachDressing.palm(p, at.Position, 14, rng())
			end,
		},
		{
			Name = "Umbrella",
			Build = function(p, at)
				BeachDressing.umbrella(p, at.Position, Z.ChairCoral)
			end,
		},
		{
			Name = "Driftwood",
			Build = function(p, at)
				BeachDressing.driftwood(p, at.Position, rng())
			end,
		},
		{
			Name = "Shell",
			Pedestal = 1,
			Build = function(p, at)
				BeachDressing.shell(p, at.Position, rng())
			end,
		},
		{
			Name = "Lifeguard tower",
			Build = function(p, at)
				BeachDressing.lifeguardTower(p, at.Position)
			end,
		},
		{
			Name = "Lounger",
			Build = function(p, at)
				P.lounger(p, at, Z.ChairSky)
			end,
		},
		{
			Name = "Towel",
			Build = function(p, at)
				P.towel(p, at.Position, 0, Z.TowelRed)
			end,
		},
		{
			Name = "Beach hut",
			Build = function(p, at)
				P.hut(p, at.Position, 0, Z.HutWall, Z.HutTealRoof)
			end,
		},
		{
			Name = "Sandbank",
			Build = function(p, at)
				P.sandbank(p, at.X - 15, at.X + 15, at.Z, 2, 8)
			end,
		},
		{
			Name = "Driftwood pile",
			Build = function(p, at)
				P.driftwoodPile(p, at.Position, rng())
			end,
		},
		{
			Name = "Fishing net",
			Build = function(p, at)
				P.net(p, at.Position, 0)
			end,
		},
		{
			Name = "Rowing boat",
			Build = function(p, at)
				P.boat(p, at.Position, 0)
			end,
		},
		{
			Name = "Wreck ribs",
			Build = function(p, at)
				P.wreck(p, at.Position, 0)
			end,
		},
		{
			Name = "Rock cluster",
			Build = function(p, at)
				P.rockCluster(p, at.Position, 6, rng())
			end,
		},
		{
			Name = "Tidepool",
			Build = function(p, at)
				P.tidepool(p, at.Position)
			end,
		},
		{
			Name = "Coral patch",
			Build = function(p, at)
				P.coralPatch(p, at.Position, rng())
			end,
		},
		{
			Name = "Piling row",
			Build = function(p, at)
				P.pilingRow(p, at.X, at.Z - 10, at.Z + 10, 6)
			end,
		},
		{
			Name = "Pier",
			Build = function(p, at)
				P.pier(p, at.X, at.Z - 20, at.Z + 20, 4)
			end,
		},
		{
			Name = "Ruined bell tower",
			Build = function(p, at)
				P.bellTower(p, at.Position)
			end,
		},
		{
			Name = "Ruined column",
			Build = function(p, at)
				P.ruinedColumn(p, at.Position, rng())
			end,
		},
	}
end

local function buildings()
	return {
		{
			Name = "House",
			Note = "Buildings.house",
			Build = function(p, at)
				Buildings.house(p, "House", at.Position, 30, 24, "House")
			end,
		},
		{
			Name = "Counter",
			Note = "Buildings.counter",
			Build = function(p, at)
				Buildings.counter(p, at.Position, 10, "Counter")
			end,
		},
		{
			Name = "Person",
			Note = "Buildings.person",
			Build = function(p, at)
				Buildings.person(p, "Person", at * CFrame.new(0, 3, 0), W.TraderCoat)
			end,
		},
	}
end

-- The secret doors: each biome's entrance, and the Sunken Bell Tower on the Far Sandbar.
local function doors()
	local list = {}
	local builders = BiomeService._entranceBuilders
	local seen = {}
	for _, id in sortedKeys(Biomes.List) do
		local biome = Biomes.List[id]
		local build = biome.Entrance and builders[biome.Entrance]
		if build and not seen[biome.Entrance] then
			seen[biome.Entrance] = true
			table.insert(list, {
				Name = biome.Name .. " door",
				Note = biome.Entrance,
				Build = function(p, at)
					local model = Instance.new("Model")
					local door = build(model, biome, at.X, at.Z, at.Y)
					door.Parent = model
					model.Parent = p
				end,
			})
		end
	end
	table.insert(list, {
		Name = "Sunken Bell Tower",
		Note = "Far Sandbar door",
		Build = function(p, _at)
			FarSandbarService.build(p)
		end,
	})
	return list
end

local function biomes()
	local list = {}
	local size = BiomeModels.PlotSize
	for i, entry in BiomeModels.list do
		local name, ground, build = entry[1], entry[2], entry[3]
		table.insert(list, {
			Name = name,
			Build = function(p, at)
				MapParts.part({
					Name = "Plot",
					Size = Vector3.new(size, 0.4, size),
					CFrame = at + Vector3.new(0, 0.2, 0),
					Color = ground,
					Material = Palette.Material.Sand,
				}).Parent =
					p
				build(p, at.Position, Random.new(300 + i))
			end,
		})
	end
	return list
end

-- The catalogue, in the order the room is laid out (from the entrance back).
return function()
	return {
		{ Name = "Materials", Description = "Every material in Palette.Material", Exhibits = materials() },
		{ Name = "Colours: World", Description = "Palette.World", Exhibits = colours("World") },
		{ Name = "Colours: Zones", Description = "Palette.Zone", Exhibits = colours("Zone") },
		{ Name = "Colours: Biomes", Description = "Palette.Biome", Exhibits = colours("Biome") },
		{ Name = "Colours: Items", Description = "Palette.ItemModel", Exhibits = colours("ItemModel") },
		{
			Name = "Colours: Rarity and coins",
			Description = "Palette.Rarity, Palette.Coin",
			Exhibits = (function()
				local list = colours("Rarity")
				for _, exhibit in colours("Coin") do
					exhibit.Name = "Coin " .. exhibit.Name
					table.insert(list, exhibit)
				end
				return list
			end)(),
		},
		{ Name = "Beach items", Description = "Items.Catalog with ItemModels", Exhibits = items() },
		{ Name = "Vessels", Description = "VesselService builders", Exhibits = vessels() },
		{ Name = "Cosmetics", Description = "Gear.Cosmetics", Exhibits = cosmetics() },
		{ Name = "Beach pieces", Description = "BeachDressing and ZoneProps", Exhibits = pieces() },
		{ Name = "Buildings", Description = "Buildings", Exhibits = buildings() },
		{
			Name = "Secret doors",
			Description = "BiomeService entrances, FarSandbarService",
			Exhibits = doors(),
		},
		{ Name = "Biomes", Description = "BiomeModels: all fourteen", Exhibits = biomes() },
	}
end
