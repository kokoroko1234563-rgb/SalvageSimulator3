-- Rolls a biome for every tile of the beach at the start of each tide cycle, and builds what goes with it:
-- the biome's ground (its layout, see src/shared/Layouts: the tile's terrain is rebuilt and
-- props are moved to stay on it), decor so players can tell (rare biomes are never announced, but you can see them), the
-- secret's entrance, and the biome's beach hazard.
-- Admins can set or reroll biomes from the console (see AdminService).

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Layouts = require(Shared.Layouts)
local Tide = require(Shared.Tide)

local GroundShift = require(script.Parent.GroundShift)
local HazardService = require(script.Parent.HazardService)
local TerrainBuilder = require(script.Parent.TerrainBuilder)

local BiomeService = {}

local folder: Folder
local rng = Random.new()
local onEntrance: (Player, string, CFrame) -> () = function(_player: Player, _secret: string, _at: CFrame) end

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Palette.Material.Sand
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

-- Decor ------------------------------------------------------------------------------

local decorBuilders = {}

-- Small sandcastles scattered over the tile.
function decorBuilders.Sandcastle(tileFolder: Folder, biome, startZ: number, endZ: number)
	for _ = 1, 10 do
		local x = rng:NextNumber(-Beach.HalfWidth + 15, Beach.HalfWidth - 15)
		local z = rng:NextNumber(startZ + 10, endZ - 10)
		local size = rng:NextNumber(2, 4)
		local groundY = Beach.groundAt(x, z)
		makePart({
			Name = "Sandcastle",
			Size = Vector3.new(size, size, size),
			CFrame = CFrame.new(x, groundY + size / 2, z),
			Color = biome.Decor,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			tileFolder
		makePart({
			Name = "Tower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(size * 0.8, size * 0.5, size * 0.5),
			CFrame = CFrame.new(x, groundY + size + size * 0.4, z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = biome.Decor,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			tileFolder
	end
end

-- Broken planks and ribs half-buried in the sand.
function decorBuilders.Wreck(tileFolder: Folder, biome, startZ: number, endZ: number)
	for _ = 1, 14 do
		local x = rng:NextNumber(-Beach.HalfWidth + 15, Beach.HalfWidth - 15)
		local z = rng:NextNumber(startZ + 10, endZ - 10)
		local length = rng:NextNumber(4, 9)
		makePart({
			Name = "Plank",
			Size = Vector3.new(length, 0.5, 1.2),
			CFrame = CFrame.new(x, Beach.groundAt(x, z) + 0.2, z)
				* CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), rng:NextNumber() * math.pi, 0),
			Color = biome.Decor,
			Material = Palette.Material.WoodPlanks,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			tileFolder
	end
end

-- Any biome without scenery of its own: low mounds in its Decor colour, so you can tell it's
-- there.
function decorBuilders.Mounds(tileFolder: Folder, biome, startZ: number, endZ: number)
	for _ = 1, 12 do
		local x = rng:NextNumber(-Beach.HalfWidth + 15, Beach.HalfWidth - 15)
		local z = rng:NextNumber(startZ + 10, endZ - 10)
		local size = rng:NextNumber(2, 5)
		makePart({
			Name = "Mound",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size * 0.5, size),
			CFrame = CFrame.new(x, Beach.groundAt(x, z), z),
			Color = biome.Decor,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			tileFolder
	end
end

-- Entrances ---------------------------------------------------------------------------

local entranceBuilders = {}

function entranceBuilders.Sandcastle(castle: Model, biome, x: number, z: number, groundY: number): BasePart
	local keep = makePart({
		Name = "Keep",
		Size = Vector3.new(22, 14, 22),
		CFrame = CFrame.new(x, groundY + 6, z),
		Color = biome.Decor,
	})
	keep.Parent = castle
	for _, corner in
		{ Vector3.new(-11, 0, -11), Vector3.new(11, 0, -11), Vector3.new(-11, 0, 11), Vector3.new(11, 0, 11) }
	do
		makePart({
			Name = "Tower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(22, 7, 7),
			CFrame = CFrame.new(x + corner.X, groundY + 10, z + corner.Z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = biome.Decor,
		}).Parent =
			castle
	end
	castle.PrimaryPart = keep
	return makePart({
		Name = "Door",
		Size = Vector3.new(5, 8, 0.6),
		CFrame = CFrame.new(x, groundY + 4, z - 11.2),
		Color = Color3.fromRGB(70, 45, 25),
		Material = Palette.Material.Wood,
	})
end

-- A ship's hull lying on its side, with a hatch facing the shop.
function entranceBuilders.Wreck(wreck: Model, biome, x: number, z: number, groundY: number): BasePart
	local hull = makePart({
		Name = "Hull",
		Size = Vector3.new(30, 12, 12),
		CFrame = CFrame.new(x, groundY + 4, z) * CFrame.Angles(0, 0, math.rad(18)),
		Color = biome.Decor,
		Material = Palette.Material.WoodPlanks,
	})
	hull.Parent = wreck
	makePart({
		Name = "Mast",
		Size = Vector3.new(1.4, 22, 1.4),
		CFrame = CFrame.new(x + 6, groundY + 10, z + 2) * CFrame.Angles(0, 0, math.rad(-35)),
		Color = Color3.fromRGB(80, 55, 35),
		Material = Palette.Material.Wood,
	}).Parent =
		wreck
	wreck.PrimaryPart = hull
	return makePart({
		Name = "Hatch",
		Size = Vector3.new(4.5, 5, 0.6),
		CFrame = CFrame.new(x, groundY + 3, z - 6.2),
		Color = Color3.fromRGB(40, 30, 20),
		Material = Palette.Material.Wood,
	})
end

local function buildEntrance(tileFolder: Folder, biome, tile: number)
	local startZ = Beach.tileRange(tile)
	-- The layout says where the entrance can stand, or the biome's spots across the tile.
	local spots = Layouts.entrances(tile, startZ)
	local x, z
	if #spots > 0 then
		local spot = spots[rng:NextInteger(1, #spots)]
		x, z = spot.X, spot.Y
	else
		x = biome.EntranceSpots[rng:NextInteger(1, #biome.EntranceSpots)]
		z = startZ + 30 -- where the layouts keep the spots flat
	end
	local groundY = Beach.groundAt(x, z)
	local model = Instance.new("Model")
	model.Name = "SecretEntrance"
	local door = entranceBuilders[biome.Entrance](model, biome, x, z, groundY)
	door.Parent = model

	local unlock = Items.get(biome.UnlockItem)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Use " .. unlock.Name
	prompt.ObjectText = if biome.Entrance == "Wreck" then "Ship's hatch" else "Sandcastle door"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = door
	prompt.Triggered:Connect(function(player)
		-- Players come back out in front of the door.
		onEntrance(player, biome.Secret, door.CFrame * CFrame.new(0, 0, -5))
	end)
	model.Parent = tileFolder
end

-- Public -----------------------------------------------------------------------------

local setCallbacks: { (number, any, Folder) -> () } = {}
local rerollCallbacks: { () -> () } = {}

-- Called after a tile gets a biome, with its folder (things built there go when it changes).
function BiomeService.onBiomeSet(callback: (number, any, Folder) -> ())
	table.insert(setCallbacks, callback)
end

-- Called after every tile has been rolled for a new tide cycle.
function BiomeService.onRerolled(callback: () -> ())
	table.insert(rerollCallbacks, callback)
end

function BiomeService.tileFolder(tile: number): Folder?
	return folder and folder:FindFirstChild("Tile" .. tile) :: Folder?
end

function BiomeService.get(tile: number): string?
	return Workspace:GetAttribute(Biomes.attributeFor(tile))
end

-- Sets (or clears, with nil) a tile's biome and rebuilds its decor and entrance.
function BiomeService.set(tile: number, biomeId: string?)
	local biome = biomeId and Biomes.List[biomeId]
	local wasLayout = Layouts.active(tile)
	local settle = GroundShift.capture(tile)
	Workspace:SetAttribute(Biomes.attributeFor(tile), if biome then biome.Id else nil)
	if Layouts.active(tile) ~= wasLayout then
		-- The biome brings its own ground: rebuild the tile's terrain and keep things on it.
		TerrainBuilder.buildTile(tile)
		settle()
	end
	local old = folder:FindFirstChild("Tile" .. tile)
	if old then
		old:Destroy()
	end
	if biome then
		local tileFolder = Instance.new("Folder")
		tileFolder.Name = "Tile" .. tile
		local startZ, endZ = Beach.tileRange(tile)
		local decor = biome.Scenery and decorBuilders[biome.Scenery] or decorBuilders.Mounds
		decor(tileFolder, biome, startZ, endZ)
		GroundShift.clearMisfits(tileFolder)
		if biome.Secret and biome.Entrance then
			buildEntrance(tileFolder, biome, tile)
		end
		HazardService.start(tile, biome, tileFolder)
		tileFolder.Parent = folder
		for _, callback in setCallbacks do
			task.spawn(callback, tile, biome, tileFolder)
		end
	end
end

-- The roll weights on a tile: each biome that can roll in its zone, and None.
function BiomeService.weightsFor(tile: number): { [string]: number }
	local zone = Beach.zoneOfTile(tile)
	local weights = { None = Config.Biomes.NoneWeight }
	for id, biome in Biomes.List do
		local weight = biome.Zones and biome.Zones[zone]
		if weight and weight > 0 then
			weights[id] = weight
		end
	end
	return weights
end

-- Rolls every tile from the biomes that can turn up in its zone.
function BiomeService.reroll()
	for tile = 1, Beach.ActiveTiles do
		local weights = BiomeService.weightsFor(tile)
		local total = 0
		for _, weight in weights do
			total += weight
		end
		local roll = rng:NextNumber() * total
		local picked: string? = nil
		for id, weight in weights do
			roll -= weight
			if roll <= 0 then
				picked = id
				break
			end
		end
		BiomeService.set(tile, if picked and Biomes.List[picked] then picked else nil)
	end
	for _, callback in rerollCallbacks do
		task.spawn(callback)
	end
end

-- For the data validator and tools/tests.
BiomeService._entranceBuilders = entranceBuilders
BiomeService._decorBuilders = decorBuilders
BiomeService._buildEntrance = buildEntrance

function BiomeService.init(entranceCallback: (Player, string, CFrame) -> (), _notify: (Player, string) -> ())
	onEntrance = entranceCallback
	folder = Instance.new("Folder")
	folder.Name = "Biomes"
	folder.Parent = Workspace

	BiomeService.reroll()
	local lastCycle = Tide.getState().Cycle
	task.spawn(function()
		while true do
			task.wait(1)
			local cycle = Tide.getState().Cycle
			if cycle ~= lastCycle then
				lastCycle = cycle
				BiomeService.reroll()
			end
		end
	end)
end

return BiomeService
