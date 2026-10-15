-- Rolls a biome for every zone at the start of each tide cycle, and builds what goes with it:
-- the biome's ground (its layout, see src/shared/Layouts: the zone's terrain is rebuilt and
-- props are moved to stay on it), decor so players can tell (rare biomes are never announced, but you can see them), the
-- secret's entrance, and the biome's beach hazard.
-- Admins can set or reroll biomes from the console (see AdminService).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Layouts = require(Shared.Layouts)
local Tide = require(Shared.Tide)

local CollisionGroups = require(script.Parent.CollisionGroups)
local GrabService = require(script.Parent.GrabService)
local GroundShift = require(script.Parent.GroundShift)
local TerrainBuilder = require(script.Parent.TerrainBuilder)

local BiomeService = {}

local folder: Folder
local rng = Random.new()
local onEntrance: (Player, string, CFrame) -> () = function(_player: Player, _secret: string, _at: CFrame) end
local notify: (Player, string) -> () = function(_player: Player, _text: string) end

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

-- Small sandcastles scattered over the zone.
function decorBuilders.Sandcastle(zoneFolder: Folder, biome, startZ: number, endZ: number)
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
			zoneFolder
		makePart({
			Name = "Tower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(size * 0.8, size * 0.5, size * 0.5),
			CFrame = CFrame.new(x, groundY + size + size * 0.4, z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = biome.Decor,
			CanCollide = false,
			CanQuery = false,
		}).Parent =
			zoneFolder
	end
end

-- Broken planks and ribs half-buried in the sand.
function decorBuilders.Wreck(zoneFolder: Folder, biome, startZ: number, endZ: number)
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
			zoneFolder
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

local function buildEntrance(zoneFolder: Folder, biome, zone: number)
	local startZ = Beach.zoneRange(zone)
	local x = biome.EntranceSpots[rng:NextInteger(1, #biome.EntranceSpots)]
	local z = startZ + 30
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
	model.Parent = zoneFolder
end

-- Hazards ----------------------------------------------------------------------------

-- Shipwreck Shallows: barrels roll down the sand on a fixed timer. Getting hit knocks
-- whatever you're holding out of your hands. Learnable, so a hit feels like a mistake.
local function rollBarrel(zoneFolder: Folder, zone: number)
	local startZ = Beach.zoneRange(zone)
	local fromZ = math.max(startZ + 5, 1)
	if Beach.isDeep(Vector3.new(0, 0, fromZ), Tide.sea()) then
		return -- the top of the zone is under water: nothing to roll down
	end
	local barrel = makePart({
		Name = "RollingBarrel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, 2.6, 2.6), -- axis along X so it rolls toward the sea
		CFrame = (function()
			local x = rng:NextNumber(-Beach.HalfWidth + 20, Beach.HalfWidth - 20)
			return CFrame.new(x, Beach.groundAt(x, fromZ) + 1.5, fromZ)
		end)(),
		Color = Color3.fromRGB(120, 80, 45),
		Material = Palette.Material.Wood,
		Anchored = false,
		CustomPhysicalProperties = PhysicalProperties.new(2, 0.3, 0.2),
	})
	barrel.CollisionGroup = CollisionGroups.Items
	barrel.AssemblyLinearVelocity = Vector3.new(0, 0, Config.Hazards.BarrelSpeed)
	barrel.AssemblyAngularVelocity = Vector3.new(Config.Hazards.BarrelSpeed / 1.3, 0, 0)

	local hitRecently: { [Player]: boolean } = {}
	barrel.Touched:Connect(function(other)
		local player = Players:GetPlayerFromCharacter(other.Parent)
		if player and not hitRecently[player] then
			hitRecently[player] = true
			if GrabService.getHeld(player) then
				GrabService.forceRelease(player)
				notify(player, "A barrel knocked it out of your hands!")
			end
		end
	end)
	barrel.Parent = zoneFolder
	pcall(barrel.SetNetworkOwner, barrel, nil)

	task.delay(12, function()
		barrel:Destroy()
	end)
end

-- Public -----------------------------------------------------------------------------

local setCallbacks: { (number, any, Folder) -> () } = {}
local rerollCallbacks: { () -> () } = {}

-- Called after a zone gets a biome, with its folder (things built there go when it changes).
function BiomeService.onBiomeSet(callback: (number, any, Folder) -> ())
	table.insert(setCallbacks, callback)
end

-- Called after every zone has been rolled for a new tide cycle.
function BiomeService.onRerolled(callback: () -> ())
	table.insert(rerollCallbacks, callback)
end

function BiomeService.zoneFolder(zone: number): Folder?
	return folder and folder:FindFirstChild("Zone" .. zone) :: Folder?
end

function BiomeService.get(zone: number): string?
	return Workspace:GetAttribute(Biomes.attributeFor(zone))
end

-- Sets (or clears, with nil) a zone's biome and rebuilds its decor and entrance.
function BiomeService.set(zone: number, biomeId: string?)
	local biome = biomeId and Biomes.List[biomeId]
	local wasLayout = Layouts.active(zone)
	local settle = GroundShift.capture(zone)
	Workspace:SetAttribute(Biomes.attributeFor(zone), if biome then biome.Id else nil)
	if Layouts.active(zone) ~= wasLayout then
		-- The biome brings its own ground: rebuild the zone's terrain and keep things on it.
		TerrainBuilder.buildZone(zone)
		settle()
	end
	local old = folder:FindFirstChild("Zone" .. zone)
	if old then
		old:Destroy()
	end
	if biome then
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = "Zone" .. zone
		local startZ, endZ = Beach.zoneRange(zone)
		decorBuilders[biome.Entrance](zoneFolder, biome, startZ, endZ)
		buildEntrance(zoneFolder, biome, zone)
		zoneFolder.Parent = folder
		for _, callback in setCallbacks do
			task.spawn(callback, zone, biome, zoneFolder)
		end
	end
end

-- Rolls every zone from Config.Biomes.Weights.
function BiomeService.reroll()
	local weights = Config.Biomes.Weights
	local total = 0
	for _, weight in weights do
		total += weight
	end
	for zone = 1, Config.Beach.ActiveZones do
		local roll = rng:NextNumber() * total
		local picked: string? = nil
		for id, weight in weights do
			roll -= weight
			if roll <= 0 then
				picked = id
				break
			end
		end
		BiomeService.set(zone, if picked and Biomes.List[picked] then picked else nil)
	end
	for _, callback in rerollCallbacks do
		task.spawn(callback)
	end
end

-- For the data validator and tools/tests.
BiomeService._entranceBuilders = entranceBuilders
BiomeService._decorBuilders = decorBuilders
BiomeService._hazards = { Barrels = rollBarrel }
BiomeService._buildEntrance = buildEntrance

function BiomeService.init(entranceCallback: (Player, string, CFrame) -> (), notifyFn: (Player, string) -> ())
	onEntrance = entranceCallback
	notify = notifyFn
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

	task.spawn(function()
		while true do
			task.wait(Config.Hazards.BarrelPeriod)
			for zone = 1, Config.Beach.ActiveZones do
				local biome = Biomes.activeIn(zone)
				local zoneFolder = folder:FindFirstChild("Zone" .. zone)
				if biome and biome.Hazard == "Barrels" and zoneFolder then
					rollBarrel(zoneFolder :: Folder, zone)
				end
			end
		end
	end)
end

return BiomeService
