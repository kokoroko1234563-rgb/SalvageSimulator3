--[[
	Runs the game's data and builders outside Roblox with Lune. Every builder creates real
	instances against Roblox's API, so a property, Enum item or value that Studio would
	reject fails here.

	Usage (from the repo root): lune run tools/tests/run.luau
]]

local process = require("@lune/process")

local Harness = require("./harness")

local h = Harness.new(process.cwd)
local roblox = h.roblox
local failures = 0
local passed = 0

local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failures += 1
		print("FAIL  " .. name .. "\n      " .. tostring(err))
	end
end

-- 1. Every shared module loads (bad Enum names in Palette and data fail here).
for _, name in
	{
		"Config",
		"Palette",
		"Gear",
		"Items",
		"Catalog",
		"Biomes",
		"Secrets",
		"Rebirth",
		"Tide",
		"Beach",
		"Waves",
		"Remotes",
		"Validate",
	}
do
	test("load Shared/" .. name, function()
		h.require("Shared/" .. name)
	end)
end

-- 2. The data fits together.
local VesselService, BiomeService
test("load server services", function()
	VesselService = h.require("Server/VesselService")
	BiomeService = h.require("Server/BiomeService")
	for _, name in
		{
			"BeachBuilder",
			"ItemService",
			"GrabService",
			"ShopService",
			"DataService",
			"SecretService",
			"RebirthService",
			"PocketService",
			"InventoryService",
			"AdminService",
			"DrowningService",
		}
	do
		h.require("Server/" .. name)
	end
end)
test("data validates", function()
	local problems = h.require("Shared/Validate").run({
		VesselBuilders = VesselService._builders,
		Entrances = BiomeService._entranceBuilders,
		Hazards = BiomeService._hazards,
	})
	assert(#problems == 0, table.concat(problems, "\n      "))
end)

-- 3. The beach builds.
test("build the beach", function()
	h.require("Server/BeachBuilder").build()
end)

-- 4. Every item can be created.
test("create every item", function()
	local Items = h.require("Shared/Items")
	local ItemService = h.require("Server/ItemService")
	for _, def in Items.Catalog do
		local ok, err = pcall(ItemService.spawnAt, def, 1, roblox.Vector3.new(0, 5, 0))
		assert(ok, def.Id .. ": " .. tostring(err))
	end
end)

-- 5. Every vessel builds.
for id, build in VesselService and VesselService._builders or {} do
	test("build vessel " .. id, function()
		local model = h.game.Workspace:FindFirstChild("Map") and nil
		model = (Harness.wrap(roblox.Instance.new("Model")))
		local handle = build(model, roblox.CFrame.new(0, 1, 0))
		assert(handle and handle:IsA("BasePart"), "builder must return the handle part")
		assert(model.PrimaryPart ~= nil, "builder must set PrimaryPart")
		assert(model:FindFirstChild("Cargo"), "vessel needs a Cargo part")
	end)
end

-- 6. Every biome's decor, entrance and hazard build.
local Biomes = h.require("Shared/Biomes")
for id, biome in Biomes.List do
	test("build biome " .. id, function()
		local folder = Harness.wrap(roblox.Instance.new("Folder"))
		folder.Parent = h.game.Workspace
		BiomeService._decorBuilders[biome.Entrance](folder, biome, 200, 400)
		BiomeService._buildEntrance(folder, biome, 2)
		assert(folder:FindFirstChild("SecretEntrance"), "no entrance was built")
		if biome.Hazard then
			BiomeService._hazards[biome.Hazard](folder, 1)
		end
		folder:Destroy()
	end)
end

-- 7. Every secret course builds on the client.
local Secrets = h.require("Shared/Secrets")
local SecretController = h.require("Client/SecretController")
for id, secret in Secrets.List do
	test("build secret course " .. id, function()
		SecretController._build(secret, roblox.Vector3.new(0, 500, 0))
		local course = h.game.Workspace:FindFirstChild("LocalSecret")
		assert(course and course:FindFirstChild("Chest"), "course has no chest")
		course:Destroy()
	end)
end

-- 8. Client UI modules load.
for _, name in { "HUD", "InventoryUI", "TideController", "WaveController", "GrabController", "AdminConsole" } do
	test("load Client/" .. name, function()
		h.require("Client/" .. name)
	end)
end

print(string.format("\n%d passed, %d failed", passed, failures))
process.exit(if failures > 0 then 1 else 0)
