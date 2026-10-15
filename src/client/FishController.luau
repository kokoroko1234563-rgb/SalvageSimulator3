-- Swims schools of cosmetic fish around the sea. They exist only on your client, they don't
-- collide with anything, and they can't be grabbed: they're there so the water feels alive.
-- Schools stay near you, over water at least MIN_DEPTH deep, so they follow the tide out and in
-- instead of getting stranded on the sand.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Fish = require(Shared.Fish)
local Tide = require(Shared.Tide)

local FishController = {}

local MIN_DEPTH = 4 -- studs of water a school needs under it
local NEAR = 300 -- schools further than this from you are moved close to you
local SPAWN_MIN = 70
local SPAWN_MAX = 260

-- Which schools swim: species and how many fish in each.
local SCHOOLS = {
	{ "Sardine", 9 },
	{ "Sardine", 8 },
	{ "Sardine", 8 },
	{ "Clownfish", 4 },
	{ "Clownfish", 4 },
	{ "Angelfish", 3 },
	{ "Angelfish", 3 },
	{ "Pufferfish", 2 },
	{ "Ray", 1 },
	{ "Ray", 1 },
	{ "Tuna", 4 },
	{ "Tuna", 4 },
	{ "BlueTang", 5 },
	{ "BlueTang", 5 },
	{ "Seahorse", 3 },
	{ "Turtle", 1 },
	{ "Turtle", 1 },
	{ "MoonJelly", 3 },
	{ "MoonJelly", 3 },
}

-- How fast each species swims, in studs per second.
local SPEED = {
	Sardine = 5,
	Clownfish = 2.5,
	Angelfish = 3,
	Pufferfish = 2,
	Ray = 4,
	Tuna = 7,
	BlueTang = 3.5,
	Seahorse = 1,
	Turtle = 2.5,
	MoonJelly = 0.8,
}

type School = {
	Fish: { Model },
	Offsets: { Vector3 },
	Phases: { number },
	X: number,
	Z: number,
	Heading: number, -- radians; the direction on the XZ plane is (cos, sin)
	Speed: number,
	Depth: number, -- how far under the surface the school swims
}

local rng = Random.new()
local schools: { School } = {}

-- Where a school may swim: not across the headlands, and only where the water is deep enough.
local function bounds(waterline: number): (number, number, number)
	local xMax = Beach.HalfWidth - 20
	local zMin = Beach.zForDepth(MIN_DEPTH + 1, waterline)
	local zMax = Beach.Depth + Config.Beach.SeaExtent - 30
	return xMax, zMin, zMax
end

-- Puts a school somewhere in the water near `near`.
local function respawn(school: School, near: Vector3, waterline: number)
	local xMax, zMin, zMax = bounds(waterline)
	local angle = rng:NextNumber() * math.pi * 2
	local distance = rng:NextNumber(SPAWN_MIN, SPAWN_MAX)
	school.X = math.clamp(near.X + math.cos(angle) * distance, -xMax, xMax)
	school.Z = math.clamp(near.Z + math.sin(angle) * distance, zMin, zMax)
	school.Heading = rng:NextNumber() * math.pi * 2
end

local function buildSchool(folder: Folder, speciesId: string, count: number): School
	local species = assert(Fish.get(speciesId))
	local school: School = {
		Fish = {},
		Offsets = {},
		Phases = {},
		X = 0,
		Z = 0,
		Heading = 0,
		Speed = SPEED[speciesId] or 3,
		Depth = rng:NextNumber(2.5, 5),
	}
	for _ = 1, count do
		local model = Fish.build(species)
		model.Parent = folder
		table.insert(school.Fish, model)
		table.insert(
			school.Offsets,
			Vector3.new(rng:NextNumber(-7, 7), rng:NextNumber(-1.2, 1.2), rng:NextNumber(-7, 7))
		)
		table.insert(school.Phases, rng:NextNumber() * math.pi * 2)
	end
	return school
end

local function step(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local focus = camera.CFrame.Position
	local state = Tide.getState()
	local xMax, zMin, zMax = bounds(state.Waterline)
	local now = os.clock()

	for _, school in schools do
		local dx, dz = school.X - focus.X, school.Z - focus.Z
		if dx * dx + dz * dz > NEAR * NEAR then
			respawn(school, focus, state.Waterline)
		end

		-- Drift along the heading, wander a little, and turn back at the edges.
		school.Heading += rng:NextNumber(-0.6, 0.6) * dt
		school.X += math.cos(school.Heading) * school.Speed * dt
		school.Z += math.sin(school.Heading) * school.Speed * dt
		if school.X > xMax or school.X < -xMax then
			school.X = math.clamp(school.X, -xMax, xMax)
			school.Heading = math.pi - school.Heading
		end
		if school.Z < zMin then
			-- The tide came in over them or they swam shoreward: head back out to sea.
			school.Z = zMin
			school.Heading = rng:NextNumber(0.3, math.pi - 0.3)
		elseif school.Z > zMax then
			school.Z = zMax
			school.Heading = -rng:NextNumber(0.3, math.pi - 0.3)
		end

		local direction = Vector3.new(math.cos(school.Heading), 0, math.sin(school.Heading))
		for i, model in school.Fish do
			local phase = school.Phases[i]
			local offset = school.Offsets[i]
			local x = school.X + offset.X + math.sin(now * 0.7 + phase) * 1.2
			local z = school.Z + offset.Z + math.cos(now * 0.6 + phase) * 1.2
			local y = state.WaterY - school.Depth + offset.Y + math.sin(now + phase) * 0.5
			-- Stay off the seabed and under the surface.
			y = math.clamp(y, Beach.groundY(z) + 1, state.WaterY - 1.2)
			local position = Vector3.new(x, y, z)
			local wag = math.sin(now * 9 + phase) * 0.12
			model:PivotTo(CFrame.lookAt(position, position + direction) * CFrame.Angles(0, wag, 0))
		end
	end
end

function FishController.init()
	local folder = Instance.new("Folder")
	folder.Name = "LocalFish"
	folder.Parent = Workspace

	local state = Tide.getState()
	for _, entry in SCHOOLS do
		local school = buildSchool(folder, entry[1], entry[2])
		respawn(school, Vector3.new(0, 0, Beach.Depth / 2), state.Waterline)
		table.insert(schools, school)
	end

	RunService.Heartbeat:Connect(step)
end

return FishController
