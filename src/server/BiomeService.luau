-- Rolls a biome for every zone at the start of each tide cycle, and builds what goes with it:
-- some decor so players can tell, and the giant sandcastle whose door opens the secret.
-- Admins can set or reroll biomes from the console (see AdminService).

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)

local BiomeService = {}

local folder: Folder
local rng = Random.new()
local onEntrance: (Player, string, CFrame) -> () = function(_player: Player, _secret: string, _at: CFrame) end

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.Sand
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

-- Small sandcastles scattered over the zone so players can see the biome.
local function buildDecor(zoneFolder: Folder, biome, zone: number)
	local startZ, endZ = Beach.zoneRange(zone)
	for _ = 1, 10 do
		local x = rng:NextNumber(-Beach.HalfWidth + 15, Beach.HalfWidth - 15)
		local z = rng:NextNumber(startZ + 10, endZ - 10)
		local size = rng:NextNumber(2, 4)
		local groundY = Beach.groundY(z)
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

-- The giant sandcastle with the secret's door, on the side facing the shop.
local function buildEntrance(zoneFolder: Folder, biome, zone: number)
	local startZ = Beach.zoneRange(zone)
	local x = biome.EntranceSpots[rng:NextInteger(1, #biome.EntranceSpots)]
	local z = startZ + 30
	local groundY = Beach.groundY(z)
	local castle = Instance.new("Model")
	castle.Name = "SecretEntrance"

	local body = makePart({
		Name = "Keep",
		Size = Vector3.new(22, 14, 22),
		CFrame = CFrame.new(x, groundY + 6, z),
		Color = biome.Decor,
	})
	body.Parent = castle
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

	local door = makePart({
		Name = "Door",
		Size = Vector3.new(5, 8, 0.6),
		CFrame = CFrame.new(x, groundY + 4, z - 11.2),
		Color = Color3.fromRGB(70, 45, 25),
		Material = Enum.Material.Wood,
	})
	door.Parent = castle
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Use Golden Spade"
	prompt.ObjectText = "Sandcastle door"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = door
	prompt.Triggered:Connect(function(player)
		-- Players come back out in front of the door.
		onEntrance(player, biome.Secret, door.CFrame * CFrame.new(0, 0, -5))
	end)

	castle.PrimaryPart = body
	castle.Parent = zoneFolder
end

function BiomeService.get(zone: number): string?
	return Workspace:GetAttribute(Biomes.attributeFor(zone))
end

-- Sets (or clears, with nil) a zone's biome and rebuilds its decor and entrance.
function BiomeService.set(zone: number, biomeId: string?)
	local biome = biomeId and Biomes.List[biomeId]
	Workspace:SetAttribute(Biomes.attributeFor(zone), if biome then biome.Id else nil)
	local old = folder:FindFirstChild("Zone" .. zone)
	if old then
		old:Destroy()
	end
	if biome then
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = "Zone" .. zone
		buildDecor(zoneFolder, biome, zone)
		buildEntrance(zoneFolder, biome, zone)
		zoneFolder.Parent = folder
	end
end

-- Rolls every zone. Test build: each zone independently becomes Sandcastle Flats or nothing.
function BiomeService.reroll()
	for zone = 1, Config.Beach.ActiveZones do
		local id = if rng:NextNumber() < Config.Biomes.RollChance then "SandcastleFlats" else nil
		BiomeService.set(zone, id)
	end
end

function BiomeService.init(entranceCallback: (Player, string, CFrame) -> ())
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
