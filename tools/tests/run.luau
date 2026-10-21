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

local SLOW = 5 -- seconds: a test slower than this says so

-- `lune run tools/tests/run.luau <words>` runs only the tests whose names contain them.
local ONLY = table.concat(require("@lune/process").args, " ")
local function test(name: string, fn: () -> ())
	-- (Loading the services always runs: the tests after it use them.)
	if ONLY ~= "" and name ~= "load server services" and not string.find(name, ONLY, 1, true) then
		return
	end
	local started = os.clock()
	local ok, err = pcall(fn)
	local took = os.clock() - started
	if took > SLOW then
		print(string.format("SLOW  %s (%.0fs)", name, took))
	end
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
		"Hotbar",
		"WaterObstacles",
		"Layouts",
		"Hazards",
		"Traders",
		"Tide",
		"Beach",
		"Waves",
		"Remotes",
		"Validate",
		"Fish",
		"Routes",
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
			"BeachDressing",
			"Buildings",
			"MapParts",
			"ZoneProps",
			"BiomeModels",
			"CosmeticModels",
			"Textures",
			"Cosmetics",
			"MapEdge",
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
			"LexiconService",
			"TraderService",
			"TradeService",
			"AuctionService",
			"SkyBeamService",
			"CosmeticService",
			"FarSandbarService",
			"TerrainBuilder",
			"MonetizationService",
			"ModelParts",
			"ItemModels",
			"ToolModels",
			"VesselTrim",
			"BeachCheer",
			"SurfService",
			"Showroom",
			"ShowroomExhibits",
			"BotEconomy",
			"BotService",
		}
	do
		h.require("Server/" .. name)
	end
end)
test("data validates", function()
	local problems = h.require("Shared/Validate").run({
		VesselBuilders = VesselService._builders,
		Entrances = BiomeService._entranceBuilders,
		Hazards = h.require("Server/HazardService").Builders,
		Scenery = BiomeService._decorBuilders,
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

-- 4b. Every item has a model, and the model is only for looks: the root stays the body,
-- and the visible parts never collide, can't be picked and weigh nothing.
test("every item has a model", function()
	local Items = h.require("Shared/Items")
	local ItemModels = h.require("Server/ItemModels")
	for _, def in Items.Catalog do
		assert(ItemModels.has(def.Id), def.Id .. " has no model")
	end
end)

test("item models are welded on and never block grabs", function()
	local Items = h.require("Shared/Items")
	local ItemService = h.require("Server/ItemService")
	for _, def in Items.Catalog do
		local part = ItemService.spawnAt(def, 1, roblox.Vector3.new(0, 5, 0))
		assert(part.Transparency == 1, def.Id .. ": the body should be hidden")
		local parts = 0
		for _, child in part:GetChildren() do
			if child:IsA("BasePart") then
				parts += 1
				assert(
					not child.CanCollide and not child.CanQuery and not child.CanTouch,
					def.Id .. ": " .. child.Name .. " blocks"
				)
				assert(child.Massless, def.Id .. ": " .. child.Name .. " has mass")
				-- A NaN here (from a lookAt along its up vector) would make the part vanish.
				for _, component in { child.CFrame:GetComponents() } do
					assert(component == component, def.Id .. ": " .. child.Name .. " has a NaN transform")
				end
			end
		end
		assert(parts > 0, def.Id .. " has no visible parts")
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

-- 5b. Every vessel builds with valid geometry, and where it has paint and trim, the trim never
-- collides or weighs anything.
test("vessels are painted and trimmed", function()
	local VesselTrim = h.require("Server/VesselTrim")
	local trimmed = 0
	for id, build in VesselService._builders do
		local model = Harness.wrap(roblox.Instance.new("Model"))
		build(model, roblox.CFrame.new(0, 1, 0))
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				for _, component in { part.CFrame:GetComponents() } do
					assert(component == component, id .. ": " .. part.Name .. " has a NaN transform")
				end
				if part.Name:match("^Rim") or part.Name:match("^Stripe") then
					assert(
						not part.CanCollide and not part.CanQuery and part.Massless,
						id .. ": " .. part.Name .. " is solid"
					)
				end
			end
		end
		if VesselTrim.has(id) then
			trimmed += 1
			-- The trim is welded on to the floor (the vessel's PrimaryPart).
			assert(model.PrimaryPart:FindFirstChild("RimFront"), id .. " has no rim")
		end
	end
	assert(trimmed >= 6, "the base vessels should all be trimmed")
end)

-- 5c. Every tool but Bare Hands has a model that attaches at the hand, and the model is
-- only for looks: no collision, no mass, nothing a pointer can pick, no broken transforms.
test("tools have models that attach at the hand", function()
	local Gear = h.require("Shared/Gear")
	local ToolModels = h.require("Server/ToolModels")
	for _, tool in Gear.Tools do
		if tool.Id == "BareHands" then
			assert(
				not ToolModels.has(tool.Id) and ToolModels.build(tool.Id) == nil,
				"bare hands hold nothing"
			)
		else
			assert(ToolModels.has(tool.Id), tool.Id .. " has no model")
			local accessory = ToolModels.build(tool.Id)
			assert(
				accessory and accessory:IsA("Tool") and not accessory.CanBeDropped,
				tool.Id .. " is held as a tool"
			)
			local handle = accessory and accessory:FindFirstChild("Handle")
			assert(
				handle and handle:FindFirstChild("RightGripAttachment"),
				tool.Id .. " has nowhere to attach"
			)
			local parts = 0
			for _, part in accessory:GetDescendants() do
				if part:IsA("BasePart") then
					parts += 1
					assert(
						not part.CanCollide and not part.CanQuery and not part.CanTouch and part.Massless,
						tool.Id .. ": " .. part.Name .. " is not just for looks"
					)
					for _, component in { part.CFrame:GetComponents() } do
						assert(component == component, tool.Id .. ": " .. part.Name .. " has a NaN transform")
					end
				end
			end
			assert(parts > 2, tool.Id .. " has hardly any parts")
		end
	end
end)

-- 5d. The beach's cheerful scenery never gets in the way of towing, grabbing or the waves.
test("beach cheer is scenery only", function()
	local map = h.require("Server/BeachBuilder").build()
	local cheer = map:FindFirstChild("Cheer")
	assert(cheer and #cheer:GetChildren() > 100, "no beach cheer was built")
	for _, part in cheer:GetDescendants() do
		if part:IsA("BasePart") then
			assert(
				not part.CanCollide and not part.CanQuery and not part.CanTouch,
				part.Name .. " gets in the way"
			)
			for _, component in { part.CFrame:GetComponents() } do
				assert(component == component, part.Name .. " has a NaN transform")
			end
		end
	end
end)

-- 6. Every biome's decor, entrance and hazards build, and its hazards run.
local Biomes = h.require("Shared/Biomes")
for id, biome in Biomes.List do
	test("build biome " .. id, function()
		local HazardService = h.require("Server/HazardService")
		local folder = Harness.wrap(roblox.Instance.new("Folder"))
		folder.Parent = h.game.Workspace
		local decor = biome.Scenery and BiomeService._decorBuilders[biome.Scenery]
			or BiomeService._decorBuilders.Mounds
		decor(folder, biome, 200, 400)
		if biome.Secret then
			-- On the first zone it rolls in, with its layout's entrance spot.
			local Layouts = h.require("Shared/Layouts")
			local zone = 99
			for rolls in biome.Zones do
				zone = math.min(zone, rolls)
			end
			Layouts.setActive(zone, id, zone)
			BiomeService._buildEntrance(folder, biome, zone, true)
			Layouts.setActive(zone, nil)
			assert(folder:FindFirstChild("SecretEntrance"), "no entrance was built")
		end
		HazardService.start(2, biome, folder)
		for step = 1, 20 do
			HazardService._step(step * 0.7, 0.7) -- through every kind's timer
		end
		folder:Destroy()
	end)
end

test("rebirth rewards stack in Stats", function()
	local Stats = h.require("Shared/Stats")
	local Gear = h.require("Shared/Gear")
	local function fake(attributes)
		return {
			GetAttribute = function(_, name)
				return attributes[name]
			end,
		}
	end
	local plain = fake({})
	local rewarded = fake({ Rewards = "SwiftFeet,SeaLegs,StrongBack", Accessory = "TideCrown" })
	assert(Stats.walkSpeed(rewarded) > Stats.walkSpeed(plain), "Swift Feet should be faster")
	assert(Stats.breath(rewarded) == 2 * Stats.breath(plain), "Sea Legs doubles breath")
	assert(Stats.wavePush(rewarded) >= 0.3 and Stats.wavePush(rewarded) < 0.6, "Sea Legs and the crown stack")
	local tool = Gear.getTool("BasicGrabber") or Gear.Tools[1]
	assert(Stats.lift(rewarded, tool) == tool.Lift + 1, "Strong Back lifts one class heavier")
	assert(Stats.lift(rewarded, Gear.getTool("BubbleWand")) == 4, "lift is capped at Very Heavy")
end)

test("private servers scale rare spawns", function()
	local Items = h.require("Shared/Items")
	local weights = { Common = 60, Uncommon = 25, Rare = 10, VeryRare = 5 }
	assert(Items.scaleRare(weights, 1) == weights, "full rate leaves weights alone")
	local half = Items.scaleRare(weights, 0.5)
	assert(
		half.Rare == 5 and half.VeryRare == 2.5 and half.Common == 67.5,
		"rares halve, commons take the rest"
	)
	local sandbar = Items.scaleRare({ Rare = 60, VeryRare = 40 }, 0.25)
	assert(sandbar.Common == 75, "a rares-only zone still scales")
end)

test("round items float", function()
	local Items = h.require("Shared/Items")
	assert(Items.floats(Items.get("BeachBall")), "balls float")
	assert(Items.floats(Items.get("Barrel")), "cylinders float")
	assert(not Items.floats(Items.get("BigCrate")), "blocks don't")
	local ItemService = h.require("Server/ItemService")
	local part = ItemService.spawnAt(Items.get("BeachBall"), 1, roblox.Vector3.new(0, 5, 0))
	assert(part:GetAttribute("Floats") == true, "spawned items carry the Floats attribute")
end)

test("hotbar slots", function()
	local Hotbar = h.require("Shared/Hotbar")
	local bar = Hotbar.empty()
	local owned = { BeachRake = true, TideMagnet = true }
	assert(Hotbar.autoAdd(bar, "TideMagnet", owned) and bar[1] == "TideMagnet", "first free slot")
	assert(not Hotbar.autoAdd(bar, "TideMagnet", owned), "no duplicates")
	Hotbar.place(bar, 4, "TideMagnet")
	assert(bar[1] == "" and bar[4] == "TideMagnet", "placing moves it")
	bar[1] = "BoatHook" -- not owned any more (rebirth): its slot is free for new tools
	assert(Hotbar.autoAdd(bar, "BeachRake", owned) and bar[1] == "BeachRake", "reuses unowned slots")
	local round = Hotbar.decode(Hotbar.encode(bar))
	for i = 1, Hotbar.Slots do
		assert(round[i] == bar[i], "encode/decode round trip")
	end
	local clean = Hotbar.sanitize({ "TideMagnet", "TideMagnet", "NotATool", 5 })
	assert(
		clean[1] == "TideMagnet" and clean[2] == "" and clean[3] == "" and #clean == Hotbar.Slots,
		"sanitize"
	)
end)

test("tide shape, sections and pools", function()
	local Tide = h.require("Shared/Tide")
	local Beach = h.require("Shared/Beach")
	assert(Tide._shaped({ 0, 1 }, 0) == 0 and Tide._shaped({ 0, 1 }, 1) == 1, "shape endpoints")
	assert(math.abs(Tide._shaped({ 0, 0.5, 1 }, 0.5) - 0.5) < 1e-6, "shape passes through its points")
	-- Sections: the east end lags the west end, so mid-tide the waterlines differ.
	local start = Tide.startFor("Out", 0.5, 1000)
	h.game.Workspace:SetAttribute(Tide.StartAttribute, start)
	local sea = Tide.sea(1000)
	local west, east = Tide.waterlineAt(sea, -360), Tide.waterlineAt(sea, 360)
	assert(west > east, string.format("the west end should drain first (%.1f vs %.1f)", west, east))
	-- A rock pool holds water even at high tide... well above the sea.
	local pool = Beach.Pools[1]
	local inside = roblox.Vector3.new(pool.X, 0, pool.Z - pool.Radius * 0.5)
	h.game.Workspace:SetAttribute(Tide.StartAttribute, Tide.startFor("Hold", 0.5, 1000))
	local lowSea = Tide.sea(1000)
	assert(Beach.depthAt(inside, lowSea) > 0, "rock pools keep water at low tide")
	assert(not Beach.isDeep(inside, lowSea), "rock pools never count as deep sea")
	h.game.Workspace:SetAttribute(Tide.StartAttribute, nil)
end)

test("water slows you down", function()
	local Beach = h.require("Shared/Beach")
	local Tide = h.require("Shared/Tide")
	h.game.Workspace:SetAttribute(Tide.StartAttribute, Tide.startFor("Hold", 0.5, 1000))
	local sea = Tide.sea(1000)
	local line = Tide.waterlineAt(sea, 0)
	local dry = Beach.wading(roblox.Vector3.new(0, 0, line - 20), sea)
	local knee = Beach.wading(roblox.Vector3.new(0, 0, line + 3 / 0.06), sea)
	local under = Beach.wading(roblox.Vector3.new(0, 0, line + 8 / 0.06), sea)
	h.game.Workspace:SetAttribute(Tide.StartAttribute, nil)
	assert(dry == 1, "full speed on dry sand")
	assert(knee < 1 and under < knee, "slower the deeper you are, slowest underwater")
end)

test("the sea seed changes the patterns", function()
	local Tide = h.require("Shared/Tide")
	local Waves = h.require("Shared/Waves")
	local ws = h.game.Workspace
	local function shape()
		local out = {}
		for x = -300, 300, 100 do
			table.insert(out, Tide.lagAt(x, 5000))
		end
		return table.concat(out, ","), Waves.sizeAt(77, 120)
	end
	ws:SetAttribute(Tide.SeedAttribute, 1)
	local a, sizeA = shape()
	ws:SetAttribute(Tide.SeedAttribute, 2)
	local b, sizeB = shape()
	ws:SetAttribute(Tide.SeedAttribute, nil)
	assert(a ~= b, "different seeds give different waterline patterns")
	assert(sizeA ~= sizeB, "different seeds give different waves")
	-- The pattern changes over time too.
	assert(Tide.lagAt(0, 0) ~= Tide.lagAt(0, 600), "the waterline pattern changes as time goes on")
end)

test("water stops at solid things, passes under decks, and shelters behind rocks", function()
	local WaterObstacles = h.require("Shared/WaterObstacles")
	local Waves = h.require("Shared/Waves")
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	WaterObstacles._clear()
	-- On open sand: no layout shapes in the way.
	Layouts.setActive(1, false)
	local function part(shape, size, cf, kind)
		local p = Harness.wrap(roblox.Instance.new("Part"))
		p.Shape = roblox.Enum.PartType[shape]
		p.Size = size
		p.CFrame = cf
		WaterObstacles.mark(p, kind)
		return p
	end
	local line = 300
	local ground = Beach.groundY(line - 10)
	-- A low wall 10 studs up the beach, 2 studs above the sand there.
	part("Block", roblox.Vector3.new(20, 4, 2), roblox.CFrame.new(0, ground, line - 10), "Solid")
	-- A pier deck high over the sand at X = 100: the water ignores it.
	part("Block", roblox.Vector3.new(8, 1, 40), roblox.CFrame.new(100, ground + 3, line - 10), "Under")
	local small = Waves.frontAt(0, line, -20) -- climbs 20 * slope = 1.2 studs: stopped
	assert(small > -10 and small <= 0, "a small run-up stops at the wall, got " .. small)
	-- The wall's top is 2.6 studs above the sea (0.6 of slope + its 2 studs).
	local big = Waves.frontAt(0, line, -40) -- climbs 2.4 studs: just under the top
	assert(big > -10, "the wall is taller than this run-up too, got " .. big)
	local huge = Waves.frontAt(0, line, -60) -- 3.6 studs: over the top
	assert(huge == -60, "a big enough run-up overtops it")
	assert(Waves.frontAt(100, line, -20) == -20, "the water runs under a deck")
	assert(Waves.frontAt(50, line, -20) == -20, "open sand elsewhere")
	-- A boulder standing out of the sea shelters the water behind (landward of) it.
	local sea = line + 40
	part("Ball", roblox.Vector3.new(8, 8, 8), roblox.CFrame.new(-100, Beach.waterY(line) + 1, sea), "Solid")
	assert(WaterObstacles.sheltered(-100, sea - 10, Beach.waterY(line)), "behind the boulder is sheltered")
	assert(not WaterObstacles.sheltered(-100, sea + 10, Beach.waterY(line)), "seaward of it is not")
	WaterObstacles._clear()
	Layouts.setActive(1, nil)
end)

test("every layout is well formed", function()
	local Layouts = h.require("Shared/Layouts")
	local all = Layouts.all(true)
	assert(#all > 0, "there are layouts")
	for _, entry in all do
		local problems = Layouts.problems(entry.Layout)
		assert(#problems == 0, entry.Source .. ": " .. table.concat(problems, "; "))
	end
	for zone = 1, h.require("Shared/Config").Beach.ActiveZones do
		assert(Layouts.base(zone), "zone " .. zone .. " has a base layout")
	end
	assert(
		#Layouts.problems({ Name = "x", Primitives = { { Kind = "Ridge", Path = { { 0, 0 } } } } }) > 0,
		"it catches a missing field"
	)
	assert(#Layouts.problems({ Name = "x", Primitives = { { Kind = "Blob" } } }) > 0, "and an unknown kind")
end)

test("layout primitives shape the ground", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local Config = h.require("Shared/Config")
	local z0 = Beach.tileRange(2)
	local layout = {
		Name = "test",
		Primitives = {
			{ Kind = "Ridge", Path = { { -100, 40 }, { 100, 40 } }, Height = 6, Width = 16 },
			{ Kind = "Mound", At = { 200, 100 }, Radius = 10, Height = 8, Rock = true },
			{ Kind = "Channel", Path = { { -100, 100 }, { 100, 100 } }, Depth = 2, Width = 10 },
			{ Kind = "Ramp", Path = { { 0, 0 }, { 0, 150 } }, Width = 16 },
			{ Kind = "Flat", At = { -60, 100 }, Radius = 10 },
		},
	}
	Layouts.setActive(2, layout)
	local function near(a, b)
		return math.abs(a - b) < 0.01
	end
	assert(near(Beach.feature(-50, z0 + 40), 6), "a ridge's crest is its Height")
	assert(Beach.feature(-50, z0 + 47) < 1 and Beach.feature(-50, z0 + 49) == 0, "and it ends at Width / 2")
	assert(near(Beach.feature(50, z0 + 100), -2), "a channel cuts Depth down")
	local height, rock = Beach.shapeAt(200, z0 + 100)
	assert(near(height, 8) and rock, "a rock mound is rock")
	assert(
		Beach.feature(0, z0 + 40) == 0 and Beach.feature(0, z0 + 100) == 0,
		"a ramp clears the ridge and channel"
	)
	assert(Beach.feature(-60, z0 + 100) == 0, "so does a flat")
	local blend = Config.Beach.Terrain.Blend
	assert(near(Beach.feature(-30, z0 + 100), -2), "beyond the flat's blend the channel is untouched")
	assert(Beach.feature(-60 + 10 + blend / 2, z0 + 100) > -2, "inside the blend it eases in")
	assert(near(Beach.groundAt(-50, z0 + 40), Beach.groundY(z0 + 40) + 6), "groundAt adds the shape")
	-- Zones join without a seam.
	Layouts.setActive(2, {
		Name = "edge",
		Primitives = { { Kind = "Ridge", Path = { { -360, 0 }, { 360, 0 } }, Height = 5, Width = 40 } },
	})
	assert(Beach.feature(0, z0) == 0, "the shape fades out at the zone's edge")
	-- At the sides it carries on as it is at the edge out to the cliffs, then fades under them.
	local edge = Beach.feature(Beach.HalfWidth, z0 + 10)
	assert(edge > 0 and near(Beach.feature(Beach.HalfWidth + 10, z0 + 10), edge), "out to the cliffs")
	local cfg = Config.Beach.Terrain
	assert(
		Beach.feature(Beach.HalfWidth + cfg.CliffReach + cfg.EdgeFade, z0 + 10) == 0,
		"and fades under them"
	)
	assert(Beach.isRough(z0 + 10), "a shaped zone is rough")
	Layouts.setActive(2, false)
	assert(Beach.feature(-50, z0 + 40) == 0 and not Beach.isRough(z0 + 10), "false makes it flat")
	Layouts.setActive(2, nil)
	assert(Beach.feature(0, -10) == 0, "the shop stays flat")
	assert(Beach.feature(0, 700) == 0, "and so does the Far Sandbar")
end)

-- A flood fill over a 4-stud grid: can you get from the shop to the bottom of zone 4 without
-- climbing a step steeper than `slope`?
local function reachesSea(Beach, slope: number): boolean
	local STEP = 4
	local _, bottom = Beach.tileRange(Beach.ActiveTiles)
	local seen = {}
	local queue = {}
	local function key(ix, iz)
		return ix * 10000 + iz
	end
	for ix = -84, 84 do
		local k = key(ix, -1)
		seen[k] = true
		table.insert(queue, { ix, -1 })
	end
	local head = 1
	while head <= #queue do
		local cell = queue[head]
		head += 1
		local ix, iz = cell[1], cell[2]
		local y = Beach.groundAt(ix * STEP, iz * STEP)
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, nz = ix + d[1], iz + d[2]
			if math.abs(nx) <= 84 and nz >= -1 and not seen[key(nx, nz)] then
				local ny = Beach.groundAt(nx * STEP, nz * STEP)
				if math.abs(ny - y) <= slope * STEP then
					if nz * STEP >= bottom - 5 then
						return true
					end
					seen[key(nx, nz)] = true
					table.insert(queue, { nx, nz })
				end
			end
		end
	end
	return false
end

test("a cart can get from the shop to the sea on the base layouts", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	for tile = 1, Beach.ActiveTiles do
		Layouts.setActive(tile, "Base")
	end
	assert(reachesSea(Beach, Config.Beach.Terrain.CartSlope), "a cart gets through, all the way down")
	for tile = 1, Beach.ActiveTiles do
		Layouts.setActive(tile, nil)
	end
end)

test("troughs flood before the waterline reaches them", function()
	local Beach = h.require("Shared/Beach")
	local Tide = h.require("Shared/Tide")
	local z0, z1 = Beach.zoneRange(4)
	-- Find the deepest dip in zone 4 near the middle of the beach.
	local troughX, troughZ, deepest = 0, nil, 0
	for x = -200, 200, 10 do
		for z = z0, z1 do
			local f = Beach.feature(x, z)
			if f < deepest then
				troughX, troughZ, deepest = x, z, f
			end
		end
	end
	assert(troughZ, "zone 4 has dips")
	-- With the sea level just above the trough's floor, the waterline (where the plain slope
	-- meets the sea) is still seaward of it, but the trough is already under water.
	local floorY = Beach.groundAt(troughX, troughZ)
	local seaY = floorY + 0.5
	local waterline = -seaY / 0.06
	assert(waterline > troughZ, "the waterline is still further out")
	local ws = h.game.Workspace
	-- Find a moment where the tide's waterline at X = 0 is about there.
	local start = Tide.startFor("In", 0, 10000)
	ws:SetAttribute(Tide.StartAttribute, start)
	local found = false
	for t = 10000, 10000 + 2000, 2 do
		local sea = Tide.sea(t)
		local line = Tide.waterlineAt(sea, troughX)
		if line < waterline and line > troughZ then
			found = Beach.depthAt(roblox.Vector3.new(troughX, 0, troughZ), sea) > 0
			break
		end
	end
	ws:SetAttribute(Tide.StartAttribute, nil)
	assert(found, "the trough floods while the waterline is still seaward of it")
end)

test("the terrain voxels follow the ground", function()
	local TerrainBuilder = h.require("Server/TerrainBuilder")
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	Layouts.setActive(1, false) -- on the plain slope
	local lo = roblox.Vector3.new(0, -40, 0)
	local hi = roblox.Vector3.new(8, 12, 0)
	local z0, z1 = 440, 448
	local materials, occupancy = TerrainBuilder.slab(lo, hi, z0, z1)
	-- Column (1, 1): x = 2, z = 442. Sum of occupancy * 4 + bottom = the ground height, less
	-- the half cell Roblox draws the surface higher by.
	local filled = 0
	for iy = 1, #occupancy[1] do
		filled += occupancy[1][iy][1] * 4
	end
	local h = Beach.groundAt(2, 442) - 2
	assert(
		math.abs((lo.Y + filled) - h) < 0.01,
		"voxels reach the ground height " .. h .. ", got " .. (lo.Y + filled)
	)
	assert(materials[1][1][1] ~= roblox.Enum.Material.Air, "the bottom is solid")
	Layouts.setActive(1, nil)
end)

test("waves run up and slide back", function()
	local Waves = h.require("Shared/Waves")
	local Config = h.require("Shared/Config")
	local Tide = h.require("Shared/Tide")
	local cfg = Config.Waves
	local n = 1001 -- not a set wave
	-- Hold the tide still (low tide) so the waterline doesn't move during the wave.
	h.game.Workspace:SetAttribute(Tide.StartAttribute, Tide.startFor("Hold", 0.5, n * cfg.Period))
	local line = Tide.waterlineAt(Tide.sea(n * cfg.Period), 0)
	local function at(t)
		return Waves.wave(n, 0, Tide.sea(n * cfg.Period + t), line)
	end
	assert(at(0).Phase == "Rolling" and at(0).Front > 0, "starts out at sea")
	-- When it reaches the waterline (its front's shape along the beach is random).
	local arrive = 0
	while at(arrive) and at(arrive).Phase == "Rolling" do
		arrive += 0.05
	end
	local up = at(arrive + 0.3)
	assert(up and up.Phase == "RunUp" and up.Front < 0, "runs up the sand after reaching the waterline")
	local push =
		Waves.getPush(roblox.Vector3.new(0, 0, line + up.Front / 2), Tide.sea(n * cfg.Period + arrive + 0.3))
	h.game.Workspace:SetAttribute(Tide.StartAttribute, nil)
	assert(push.Z < 0, "the run-up pushes up the beach")
	local life = Waves.lifetime(n)
	assert(at(life + 0.5) == nil, "gone after its lifetime")
	assert(Waves.size(cfg.SetEvery * 50) > Waves.size(cfg.SetEvery * 50 + 1) * 1.1, "set waves are bigger")
	assert(Waves.reach(n, 700) > Waves.reach(n, 100), "waves are bigger further out")
end)

test("build the showroom", function()
	local Showroom = h.require("Server/Showroom")
	local catalogue = h.require("Server/ShowroomExhibits")()
	local parent = Harness.wrap(roblox.Instance.new("Folder"))
	local room = Showroom.build(parent, catalogue)
	assert(room:FindFirstChild("Floor"), "the room has a floor")
	-- Every exhibit built (a failed one is replaced by a red BuildFailed block).
	local failed = {}
	for _, d in room:GetDescendants() do
		if d.Name == "BuildFailed" then
			table.insert(failed, d.Parent.Name)
		end
	end
	-- Avatars need Roblox's servers, so the person can't be built here.
	local expected = { Person = true }
	for _, name in failed do
		assert(expected[name], "showroom exhibit failed to build: " .. name)
	end
	-- Nothing ends up on the beach or in the sea: the whole room is on the shop side.
	local _, hi = Showroom._bounds(room)
	assert(hi and hi.Z < 0, "the showroom must stay at Z < 0, away from the tide")
	-- No exhibit may produce broken (NaN) positions.
	for _, d in room:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d.CFrame.Position
			assert(p == p, "NaN position in showroom part " .. d:GetFullName())
		end
	end
end)

test("day cycle", function()
	local DayCycle = h.require("Shared/DayCycle")
	for _, hour in { 0, 5.5, 6, 12, 17.9, 18, 23 } do
		local back = DayCycle.hourFor(DayCycle.fractionFor(hour))
		assert(math.abs(back - hour) < 1e-6, "hour round trip " .. hour .. " -> " .. back)
	end
	assert(
		DayCycle.period(12) == "Day" and DayCycle.period(6) == "Twilight" and DayCycle.period(2) == "Night"
	)
	assert(DayCycle.nightness(12) == 0 and DayCycle.nightness(1) == 1, "night ramps")
	local start = DayCycle.startFor(19.5, 1000)
	h.game.Workspace:SetAttribute(DayCycle.StartAttribute, start)
	local hour = DayCycle.hour(1000)
	h.game.Workspace:SetAttribute(DayCycle.StartAttribute, nil)
	assert(math.abs(hour - 19.5) < 1e-6, "setting the time works")
end)

test("music picks tracks by place and time", function()
	local Music = h.require("Client/MusicController")
	local Config = h.require("Shared/Config")
	assert(Music.place(roblox.Vector3.new(0, 5, -40)) == "Shop", "the shop")
	assert(Music.place(roblox.Vector3.new(0, 0, 100)) == "Shore", "zone 1 is the shore")
	local doorZ = Config.Beach.FarSandbar.DoorZ
	assert(Music.place(roblox.Vector3.new(0, -40, doorZ)) == "Sandbar", "the sandbar")
	assert(Music.place(roblox.Vector3.new(0, -40, 3000)) == "Outer", "the deepest zones are outer")
	-- Every place has something for every time of day.
	for _, place in { "Shop", "Shore", "Outer", "Sandbar", "Secret", "Showroom" } do
		for _, time in { "Day", "Twilight", "Night" } do
			if place ~= "Showroom" or time == "Day" then
				assert(#Music.candidates(place, time) > 0, "no music for " .. place .. " at " .. time)
			end
		end
	end
	for _, track in Music.candidates("Shore", "Night") do
		assert(track.Times == nil or table.find(track.Times, "Night"), "a day track played at night")
	end
	-- Tracks without a SoundId never play.
	local saved = {}
	for i, track in Config.Music.Tracks do
		saved[i] = track.SoundId
		track.SoundId = 0
	end
	local none = Music.candidates("Shore", "Day")
	for i, track in Config.Music.Tracks do
		track.SoundId = saved[i]
	end
	assert(#none == 0, "tracks without a SoundId never play")
end)

test("build the bell tower", function()
	local map = Harness.wrap(roblox.Instance.new("Folder"))
	local door = h.require("Server/FarSandbarService").build(map)
	assert(door:FindFirstChildOfClass("ProximityPrompt"), "the door needs a prompt")
	local Beach = h.require("Shared/Beach")
	local Tide = h.require("Shared/Tide")
	-- The door must be dry at low tide (wherever the sections put it), or it can never be used.
	h.game.Workspace:SetAttribute(Tide.StartAttribute, Tide.startFor("Hold", 0.99, 1000))
	local dry = not Beach.isDeep(door.CFrame.Position, Tide.sea(1000))
	h.game.Workspace:SetAttribute(Tide.StartAttribute, nil)
	assert(dry, "the door is underwater even at low tide")
end)

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
for _, name in
	{
		"HUD",
		"InventoryUI",
		"TideController",
		"WaveController",
		"GrabController",
		"AdminConsole",
		"TradeUI",
		"TraderUI",
		"AuctionUI",
		"SkyBeamController",
		"HotbarUI",
		"SeaController",
		"DayController",
		"MusicController",
		"GearEffects",
		"MistController",
		"FishController",
		"HazardController",
	}
do
	test("load Client/" .. name, function()
		h.require("Client/" .. name)
	end)
end

-- 9. Trading: the swap is all-or-nothing and never duplicates anything.
local function fakePlayer(name: string, userId: number)
	local attributes = {}
	return {
		Name = name,
		DisplayName = name,
		UserId = userId,
		Parent = true,
		SetAttribute = function(_, key, value)
			attributes[key] = value
		end,
		GetAttribute = function(_, key)
			return attributes[key]
		end,
	}
end
local function countItems(profile)
	local count = 0
	for _ in profile.Items do
		count += 1
	end
	return count
end

test("trade swaps items and taxed coins", function()
	local DataService = h.require("Server/DataService")
	local a, b = fakePlayer("A", 1), fakePlayer("B", 2)
	DataService._setProfile(a, {
		Coins = 1000,
		Items = { u1 = { Id = "GoldenSpade" }, u3 = { Id = "BoatHook" } },
	})
	DataService._setProfile(b, { Coins = 0, Items = { u2 = { Id = "AnchorHook", Variant = "Barnacled" } } })
	local ok, reason = DataService.executeTrade(
		a :: any,
		b :: any,
		{ Items = { u1 = true }, Coins = 500 },
		{ Items = { u2 = true }, Coins = 0 },
		0.1
	)
	assert(ok, reason)
	local pa, pb = DataService.get(a :: any), DataService.get(b :: any)
	assert(pa.Items.u2 and pa.Items.u2.Variant == "Barnacled", "A should have B's item, variant kept")
	assert(pb.Items.u1 and not pa.Items.u1, "the spade should have moved, not been copied")
	assert(pa.Coins == 500 and pb.Coins == 450, string.format("coins A=%d B=%d", pa.Coins, pb.Coins))
	assert(countItems(pa) == 2 and countItems(pb) == 1, "item counts changed")

	-- Replaying the same trade fails: A no longer has u1.
	local again = DataService.executeTrade(
		a :: any,
		b :: any,
		{ Items = { u1 = true }, Coins = 0 },
		{ Items = {}, Coins = 0 },
		0.1
	)
	assert(not again, "a replayed trade must fail")
	assert(pb.Items.u1 and not pa.Items.u1, "a failed trade must change nothing")
end)

test("trade rejects shop gear, missing items and too many coins", function()
	local DataService = h.require("Server/DataService")
	local a, b = fakePlayer("C", 3), fakePlayer("D", 4)
	DataService._setProfile(
		a,
		{ Coins = 100, Items = { g = { Id = "BoatHook" }, k = { Id = "CaptainsKey" } } }
	)
	DataService._setProfile(b, { Coins = 0, Items = {} })
	local empty = { Items = {}, Coins = 0 }
	assert(
		not DataService.executeTrade(a :: any, b :: any, { Items = { g = true }, Coins = 0 }, empty, 0.1),
		"shop gear traded"
	)
	assert(
		not DataService.executeTrade(a :: any, b :: any, { Items = { nope = true }, Coins = 0 }, empty, 0.1),
		"missing item traded"
	)
	assert(
		not DataService.executeTrade(a :: any, b :: any, { Items = { k = true }, Coins = 101 }, empty, 0.1),
		"overspent"
	)
	assert(
		not DataService.executeTrade(a :: any, b :: any, { Items = {}, Coins = -5 }, empty, 0.1),
		"negative coins"
	)
	local pa = DataService.get(a :: any)
	assert(pa.Coins == 100 and pa.Items.k and pa.Items.g, "rejected trades must change nothing")
end)

-- 10. Lexicon, tower man, hat and traders.
test("build the tower man", function()
	local LexiconService = h.require("Server/LexiconService")
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	folder.Parent = h.game.Workspace
	local tower = LexiconService.buildTower(folder, roblox.Vector3.new(0, 0, 100))
	assert(tower:FindFirstChild("Man"), "no man on the tower")
	folder:Destroy()
end)

for _, cosmetic in h.require("Shared/Gear").Cosmetics do
	test("build cosmetic " .. cosmetic.Id, function()
		local hat = h.require("Server/CosmeticService").build(cosmetic)
		assert(hat:IsA("Accessory"), "a cosmetic must be an Accessory")
		local handle = hat:FindFirstChild("Handle")
		assert(
			handle and handle:FindFirstChild("HatAttachment"),
			"a cosmetic needs a Handle with a HatAttachment"
		)
	end)
end

local Traders = h.require("Shared/Traders")
for id, trader in Traders.List do
	test("build trader " .. id, function()
		local folder = Harness.wrap(roblox.Instance.new("Folder"))
		folder.Parent = h.game.Workspace
		local model = h.require("Server/TraderService").spawn(trader, 1, folder)
		assert(model:GetAttribute("EncounterId"), "trader needs an encounter id")
		folder:Destroy()
	end)
end

test("upgrade effects and caps", function()
	assert(Traders.walkMultiplier({ ComfySandals = 3 }) == 1.15, "sandals")
	assert(math.abs(Traders.wavePushMultiplier({ BarnacleBoots = 3 }) - 0.7) < 1e-9, "boots")
	assert(Traders.wavePushMultiplier({ BarnacleBoots = 50 }) == 0.3, "waves must keep at least 30%")
	assert(Traders.breathMultiplier({}) == 1, "no upgrades means no change")
	local levels = Traders.parseLevels("ComfySandals:2,DeepLungs:1")
	assert(levels.ComfySandals == 2 and levels.DeepLungs == 1, "parse levels")
	local gull = Traders.cost(Traders.List.MadameGull, 2)
	assert(gull.Cores == 2 and gull.Coins == 0, "Madame Gull takes cores")
	local gary = Traders.cost(Traders.List.Gary, 3)
	assert(gary.Coins == 100000 and gary.Items == 10, "Gary's level 3 cost")
end)

test("lexicon records each item once and knows when it's complete", function()
	local DataService = h.require("Server/DataService")
	local Items = h.require("Shared/Items")
	local p = fakePlayer("E", 5)
	DataService._setProfile(p, {})
	assert(DataService.recordLexicon(p :: any, "Seashell") == true, "first find is new")
	assert(DataService.recordLexicon(p :: any, "Seashell") == false, "second find isn't")
	assert(DataService.recordLexicon(p :: any, "NotAnItem") == false, "unknown items aren't recorded")
	assert(not DataService.lexiconComplete(p :: any), "not complete yet")
	for _, item in Items.Catalog do
		DataService.recordLexicon(p :: any, item.Id)
	end
	assert(DataService.lexiconComplete(p :: any), "should be complete")
end)

-- 11. Global auction: escrow, outbids, resolution, ledgers, rebirth cancel (one-server store).
test("auction: escrow, outbid, win, refunds", function()
	local DataService = h.require("Server/DataService")
	local AuctionService = h.require("Server/AuctionService")
	AuctionService._useStore(AuctionService._localStore())
	local a, b = fakePlayer("Ann", 11), fakePlayer("Bob", 12)
	DataService._setProfile(a, { Coins = 100000 })
	DataService._setProfile(b, { Coins = 100000 })
	local pa, pb = DataService.get(a :: any), DataService.get(b :: any)

	local state = AuctionService._stateFor(a :: any)
	local start = state.StartingBid
	assert(
		not AuctionService._bid(a :: any, state.LotId, start - 1),
		"a bid under the starting bid must fail"
	)
	assert(AuctionService._bid(a :: any, state.LotId, start), "Ann's first bid")
	assert(pa.Coins == 100000 - start, "Ann's coins are held")
	assert(not AuctionService._bid(b :: any, state.LotId, start + 1), "too small an increment must fail")
	local beat = AuctionService.minNextBid(start, start)
	assert(AuctionService._bid(b :: any, state.LotId, beat), "Bob outbids")
	assert(pb.Coins == 100000 - beat, "Bob's coins are held")
	assert(not AuctionService._bid(a :: any, "lot_0", 999999), "bidding on an old lot must fail")

	-- Ann raises: only the difference is taken.
	local raise = AuctionService.minNextBid(beat, start)
	assert(AuctionService._bid(a :: any, state.LotId, raise), "Ann raises")
	assert(pa.Coins == 100000 - raise, "only the difference was taken")

	-- The lot ends: Ann wins, Bob is refunded through the ledger.
	AuctionService._resolve(AuctionService._lotIndex())
	AuctionService._resolve(AuctionService._lotIndex()) -- a second resolve does nothing
	AuctionService._collect(a :: any)
	AuctionService._collect(b :: any)
	assert(pb.Coins == 100000, "Bob gets his whole bid back")
	assert(pa.Coins == 100000 - raise, "Ann's winning bid is destroyed")
	local won
	for _, record in pa.Items do
		won = record
	end
	assert(
		won and won.Id == state.ItemId and won.Serial == 1 and won.Winner == "Ann",
		"Ann gets item #1 with her name"
	)
	AuctionService._collect(a :: any)
	local count = 0
	for _ in pa.Items do
		count += 1
	end
	assert(count == 1, "collecting twice must not give a second item")
end)

test("auction: a rebirth cancels and refunds the bid first", function()
	local DataService = h.require("Server/DataService")
	local AuctionService = h.require("Server/AuctionService")
	AuctionService._useStore(AuctionService._localStore())
	local c = fakePlayer("Cat", 13)
	DataService._setProfile(c, { Coins = 60000 })
	local pc = DataService.get(c :: any)
	local state = AuctionService._stateFor(c :: any)
	assert(AuctionService._bid(c :: any, state.LotId, state.StartingBid), "bid")
	AuctionService.cancelBid(c :: any)
	assert(pc.Coins == 60000, "the bid is refunded")
	AuctionService._resolve(AuctionService._lotIndex())
	AuctionService._collect(c :: any)
	assert(pc.Coins == 60000 and next(pc.Items) == nil, "a cancelled bid can't win or be refunded twice")
end)

-- 11b. Paid features: a coin pack is granted exactly once, however often Roblox retries.
test("coin pack receipts grant once", function()
	local Config = h.require("Shared/Config")
	local DataService = h.require("Server/DataService")
	local Monetization = h.require("Server/MonetizationService")
	local buyer = fakePlayer("Buyer", 77)
	DataService._setProfile(buyer, { Coins = 0, Items = {} })
	local pack = Config.Monetization.CoinPacks[1]
	local oldId, oldLookup = pack.ProductId, Harness.stubs.Players.GetPlayerByUserId
	pack.ProductId = 12345
	Harness.stubs.Players.GetPlayerByUserId = function(_, userId)
		return if userId == 77 then buyer else nil
	end
	local ok, err = pcall(function()
		local receipt = { PlayerId = 77, ProductId = 12345, PurchaseId = "abc" }
		local first = Monetization._processReceipt(receipt)
		local again = Monetization._processReceipt(receipt)
		local profile = DataService.get(buyer)
		assert(first == roblox.Enum.ProductPurchaseDecision.PurchaseGranted, "first try should grant")
		assert(again == roblox.Enum.ProductPurchaseDecision.PurchaseGranted, "a retry is still acknowledged")
		assert(profile.Coins == pack.Coins, "coins granted once, got " .. profile.Coins)
		local gone = Monetization._processReceipt({ PlayerId = 99, ProductId = 12345, PurchaseId = "x" })
		assert(gone == roblox.Enum.ProductPurchaseDecision.NotProcessedYet, "absent buyers wait")
	end)
	pack.ProductId, Harness.stubs.Players.GetPlayerByUserId = oldId, oldLookup
	assert(ok, err)
end)

-- 12. The cosmetic models, textures and fish. Everything cosmetic must be small, and must never
-- collide or be queried, so none of it can become part of the active map.
local CosmeticModels = h.require("Server/CosmeticModels")
local Textures = h.require("Server/Textures")
local Cosmetics = h.require("Server/Cosmetics")
local BiomeModels = h.require("Server/BiomeModels")
local Fish = h.require("Shared/Fish")

local function fakeRandom()
	return {
		NextNumber = function(_, min, max)
			min, max = min or 0, max or 1
			return min + math.random() * (max - min)
		end,
		NextInteger = function(_, min, max)
			return math.random(min, max)
		end,
	}
end

-- Checks that everything under `folder` is cosmetic. Returns how many parts there are and how far
-- up the highest one reaches.
local function checkCosmetic(folder, label: string): (number, number)
	local parts, highest = 0, 0
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") then
			parts += 1
			assert(not part.CanCollide, label .. ": " .. part.Name .. " collides")
			assert(not part.CanQuery, label .. ": " .. part.Name .. " is queryable")
			highest = math.max(
				highest,
				part.CFrame.Position.Y + math.max(part.Size.X, part.Size.Y, part.Size.Z) / 2
			)
		end
	end
	assert(parts > 0, label .. " built no parts")
	return parts, highest
end

test("the cosmetic catalog has about two hundred models", function()
	assert(#CosmeticModels.List >= 200, "only " .. #CosmeticModels.List .. " cosmetic models")
	local seen = {}
	for _, entry in CosmeticModels.List do
		assert(not seen[entry.Id], "duplicate cosmetic id " .. entry.Id)
		seen[entry.Id] = true
		assert(entry.Height <= CosmeticModels.MAX_HEIGHT, entry.Id .. " is taller than a cosmetic may be")
	end
end)

test("every cosmetic model builds and is cosmetic", function()
	local failures = {}
	for _, entry in CosmeticModels.List do
		local folder = Harness.wrap(roblox.Instance.new("Folder"))
		local ok, err = pcall(function()
			entry.Build(folder, roblox.CFrame.new(0, 0, 0), fakeRandom())
			local _, highest = checkCosmetic(folder, entry.Id)
			assert(highest <= CosmeticModels.MAX_HEIGHT + 0.5, entry.Id .. " reaches " .. highest)
		end)
		if not ok then
			table.insert(failures, entry.Id .. ": " .. tostring(err))
		end
	end
	assert(#failures == 0, table.concat(failures, "\n      "))
end)

test("every cosmetic model belongs to a real theme", function()
	local themes = {}
	for _, theme in CosmeticModels.ZoneThemes do
		themes[theme] = true
	end
	for name in BiomeModels.Plots do
		themes[name] = true
	end
	for _, entry in CosmeticModels.List do
		assert(themes[entry.Theme], entry.Id .. " has no such theme: " .. entry.Theme)
	end
end)

test("every texture builds and is cosmetic", function()
	assert(#Textures.List >= 20, "only " .. #Textures.List .. " textures")
	local failures = {}
	for _, kind in Textures.List do
		local folder = Harness.wrap(roblox.Instance.new("Folder"))
		local ok, err = pcall(function()
			kind.Build(folder, roblox.Vector3.new(0, 0, 100), fakeRandom())
			checkCosmetic(folder, kind.Id)
		end)
		if not ok then
			table.insert(failures, kind.Id .. ": " .. tostring(err))
		end
	end
	assert(#failures == 0, table.concat(failures, "\n      "))
end)

for _, species in Fish.Species do
	test("build fish " .. species.Id, function()
		local model = Fish.build(species)
		assert(model.PrimaryPart ~= nil, "fish needs a PrimaryPart")
		checkCosmetic(model, species.Id)
	end)
end

test("cosmetics are placed across the map", function()
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	local placed = Cosmetics.build(folder)
	assert(placed.Models >= 500, "only " .. placed.Models .. " models placed")
	assert(placed.Textures >= 250, "only " .. placed.Textures .. " textures placed")
	local parts = checkCosmetic(folder, "placed cosmetics")
	print(
		string.format(
			"[Cosmetics] %d models and %d textures placed, %d parts",
			placed.Models,
			placed.Textures,
			parts
		)
	)
end)

-- The descent layouts (docs/layouts). Layouts are drawn per tile and only meet their
-- neighbours at the shared ramp anchors, so each zone's layouts are tested on one tile: zone
-- N's on tile N, one after another from the shop. Carts and players on foot walk a 4-stud grid
-- over those tiles: a step is allowed only where the climb is at most the slope they can take.
local LAYOUT_GRID = 4

-- The rock pools that lie on a zone's tiles, in tile coordinates (z from the tile's start).
-- A pool on the line between two tiles counts for both.
local function poolsOnZone(Beach, zone: number)
	local list = {}
	for _, pool in Beach.Pools do
		local seen = {}
		for _, z in { pool.Z, pool.Z - 0.001 } do
			local tile = Beach.tileAt(z)
			if tile and not seen[tile] and Beach.zoneOfTile(tile) == zone then
				seen[tile] = true
				table.insert(list, { X = pool.X, Z = pool.Z - Beach.tileRange(tile), Radius = pool.Radius })
			end
		end
	end
	return list
end
local LAYOUT_COLS = 88 -- grid columns either side of X = 0 (352 studs)
local LAYOUT_UNITS = 6 -- zones tested, one tile each (Config.Beach.ActiveZones)
local LAYOUT_LENGTH = 608 -- Config.Beach.TileLength: a tile is a zone
local LAYOUT_END = LAYOUT_UNITS * LAYOUT_LENGTH - 8 -- the seaward end of the last zone
local LAYOUT_ROWS = { -1, LAYOUT_UNITS * LAYOUT_LENGTH / LAYOUT_GRID - 1 } -- z = -4 (the shop side) onward
local layoutGridCache = nil

local function layoutKey(ix: number, iz: number): number
	return ix * 1000 + iz
end

-- The ground on the grid, for every layout each zone can take. Computed once: a zone's ground
-- only depends on that zone's layout, so every combination of zones can then be walked cheaply.
local function layoutGrid()
	if layoutGridCache then
		return layoutGridCache
	end
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local Biomes = h.require("Shared/Biomes")
	local grid = { zoneOfRow = {}, options = {}, shop = {} }
	for iz = LAYOUT_ROWS[1], LAYOUT_ROWS[2] do
		grid.zoneOfRow[iz] = Beach.tileAt(iz * LAYOUT_GRID) or 0
	end
	for ix = -LAYOUT_COLS, LAYOUT_COLS do
		grid.shop[layoutKey(ix, -1)] = Beach.groundAt(ix * LAYOUT_GRID, -LAYOUT_GRID)
	end
	for zone = 1, Config.Beach.ActiveZones do
		-- Each biome in the zones it can roll in (Biomes.List[id].Zones).
		local names = { "Base" }
		for id, biome in Biomes.List do
			if Layouts.forBiome(id, zone) and biome.Zones and (biome.Zones[zone] or 0) > 0 then
				table.insert(names, id)
			end
		end
		grid.options[zone] = {}
		for _, name in names do
			-- Each way the zone can come out: each crossing, each room of each slot.
			local def = if name == "Base" then Layouts.base(zone) else Layouts.forBiome(name, zone)
			for _, way in Layouts.options(def) do
				Layouts.setActive(zone, name, zone, way.Choice)
				local heights = {}
				for iz = LAYOUT_ROWS[1], LAYOUT_ROWS[2] do
					if grid.zoneOfRow[iz] == zone then
						for ix = -LAYOUT_COLS, LAYOUT_COLS do
							heights[layoutKey(ix, iz)] = Beach.groundAt(ix * LAYOUT_GRID, iz * LAYOUT_GRID)
						end
					end
				end
				table.insert(grid.options[zone], {
					name = name .. (if way.Label ~= "" then " " .. way.Label else ""),
					id = name,
					biome = if name ~= "Base" then name else nil,
					choice = way.Choice,
					heights = heights,
					every = Layouts.fadeEvery(zone),
				})
				Layouts.setActive(zone, nil)
			end
		end
	end
	layoutGridCache = grid
	return grid
end

-- Calls fn(choice) for the base layouts everywhere, then once for each other option of each
-- zone with the base layouts around it: choice[zone] is an index into that zone's options.
-- Tiles meet along a strip of flat ground at every edge (the shapes fade out there), so a
-- route can cross from one tile to the next anywhere along it: every mix of options works if
-- each option can be crossed on its own, and there's no need to try every mix.
local function eachLayoutChoice(grid, fn)
	local Config = h.require("Shared/Config")
	local choice = {}
	for zone = 1, Config.Beach.ActiveZones do
		choice[zone] = 1
	end
	fn(choice)
	for zone = 1, Config.Beach.ActiveZones do
		for index = 2, #grid.options[zone] do
			choice[zone] = index
			fn(choice)
		end
		choice[zone] = 1
	end
	return choice
end

-- Every cell a route can reach from the shop, stepping only where the climb is at most `slope`.
local function layoutFlood(grid, choice, slope: number)
	local function height(ix: number, iz: number): number
		if iz < 0 then
			return grid.shop[layoutKey(ix, -1)]
		end
		local zone = grid.zoneOfRow[iz]
		return grid.options[zone][choice[zone]].heights[layoutKey(ix, iz)]
	end
	local seen = {}
	local queue, head = {}, 1
	for ix = -LAYOUT_COLS, LAYOUT_COLS do
		seen[layoutKey(ix, -1)] = true
		table.insert(queue, { ix, -1 })
	end
	while head <= #queue do
		local ix, iz = queue[head][1], queue[head][2]
		head += 1
		local y = height(ix, iz)
		for _, step in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, nz = ix + step[1], iz + step[2]
			if
				math.abs(nx) <= LAYOUT_COLS
				and nz >= -1
				and nz <= LAYOUT_ROWS[2]
				and not seen[layoutKey(nx, nz)]
				and math.abs(height(nx, nz) - y) <= slope * LAYOUT_GRID
			then
				seen[layoutKey(nx, nz)] = true
				table.insert(queue, { nx, nz })
			end
		end
	end
	return seen
end

-- Whether a route can cross one zone's option from its top row to its bottom row, starting
-- anywhere along the top (the zones meet along a flat strip, so that's enough to join up).
local function layoutCrossesZone(grid, zone: number, option, slope: number): boolean
	local rows = {}
	for iz = LAYOUT_ROWS[1], LAYOUT_ROWS[2] do
		if grid.zoneOfRow[iz] == zone then
			table.insert(rows, iz)
		end
	end
	local top, bottom = rows[1], rows[#rows]
	local seen, queue, head = {}, {}, 1
	for ix = -LAYOUT_COLS, LAYOUT_COLS do
		seen[layoutKey(ix, top)] = true
		table.insert(queue, { ix, top })
	end
	while head <= #queue do
		local ix, iz = queue[head][1], queue[head][2]
		head += 1
		if iz == bottom then
			return true
		end
		local y = option.heights[layoutKey(ix, iz)]
		for _, step in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, nz = ix + step[1], iz + step[2]
			local k = layoutKey(nx, nz)
			if math.abs(nx) <= LAYOUT_COLS and nz >= top and nz <= bottom and not seen[k] then
				local ny = option.heights[k]
				if ny and math.abs(ny - y) <= slope * LAYOUT_GRID then
					seen[k] = true
					table.insert(queue, { nx, nz })
				end
			end
		end
	end
	return false
end

-- Whether a flood reaches a point (x, z) of the beach, within one grid cell.
local function layoutReaches(seen, x: number, z: number): boolean
	local ix, iz = math.floor(x / LAYOUT_GRID + 0.5), math.floor(z / LAYOUT_GRID + 0.5)
	for dx = -1, 1 do
		for dz = -1, 1 do
			if seen[layoutKey(ix + dx, iz + dz)] then
				return true
			end
		end
	end
	return false
end

-- How far a route is (in cells) from one start point on the top of a zone to its bottom, or nil.
local function layoutRoute(grid, zone: number, option, startIx: number, slope: number): number?
	local rows = {}
	for iz = LAYOUT_ROWS[1], LAYOUT_ROWS[2] do
		if grid.zoneOfRow[iz] == zone then
			table.insert(rows, iz)
		end
	end
	local top, bottom = rows[1], rows[#rows]
	if option.every then
		-- A layout drawn for the old 152-stud tiles repeats down the zone: cross one repeat.
		bottom = math.min(bottom, top + math.floor(option.every / LAYOUT_GRID) - 2)
	end
	local dist = { [layoutKey(startIx, top)] = 0 }
	local queue, head = { { startIx, top } }, 1
	while head <= #queue do
		local ix, iz = queue[head][1], queue[head][2]
		head += 1
		if iz == bottom then
			return dist[layoutKey(ix, iz)]
		end
		local y = option.heights[layoutKey(ix, iz)]
		for _, step in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, nz = ix + step[1], iz + step[2]
			local k = layoutKey(nx, nz)
			if math.abs(nx) <= LAYOUT_COLS and nz >= top and nz <= bottom and dist[k] == nil then
				local ny = option.heights[k]
				if ny and math.abs(ny - y) <= slope * LAYOUT_GRID then
					dist[k] = dist[layoutKey(ix, iz)] + 1
					table.insert(queue, { nx, nz })
				end
			end
		end
	end
	return nil
end

-- Share of a zone's lower half that a player at its top edge can't see at eye height. A target
-- counts as hidden only when none of the nine viewpoints along the top edge can see it.
local function layoutHidden(zone: number): number
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local z0, z1 = Beach.tileRange(zone)
	-- A layout drawn for the old 152-stud tiles repeats down the zone: judge one repeat.
	local every = h.require("Shared/Layouts").fadeEvery(zone)
	if every then
		z1 = z0 + every
	end
	local eye = Config.Beach.Terrain.EyeHeight
	local eyes = {}
	for _, x in { -320, -240, -160, -80, 0, 80, 160, 240, 320 } do
		local z = z0 + 1
		table.insert(eyes, { x = x, z = z, y = Beach.groundAt(x, z) + eye })
	end
	local total, hidden = 0, 0
	for z = z0 + (z1 - z0) / 2, z1 - 2, 6 do
		for x = -340, 340, 8 do
			local ty = Beach.groundAt(x, z)
			total += 1
			local seen = false
			for _, e in eyes do
				local blocked = false
				local dz = z - e.z
				for s = 0.04, 0.96, 2 / math.max(dz, 1) do
					if Beach.groundAt(e.x + (x - e.x) * s, e.z + dz * s) > e.y + (ty - e.y) * s + 0.2 then
						blocked = true
						break
					end
				end
				if not blocked then
					seen = true
					break
				end
			end
			if not seen then
				hidden += 1
			end
		end
	end
	return hidden / math.max(total, 1)
end

test("every way through a zone has a cart ramp from its top edge to its bottom edge", function()
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local length = Config.Beach.TileLength
	local function anchored(p, x)
		local first, last = p.Path[1], p.Path[#p.Path]
		return first[1] == x and first[2] == 0 and last[1] == x and last[2] == 150
	end
	for _, entry in Layouts.all(true) do
		local layout: any = entry.Layout
		local top, bottom, left, right = false, false, false, false
		for _, p in layout.Primitives do
			if p.Kind == "Ramp" then
				assert(p.Width >= 14, entry.Source .. ": a ramp is at least 14 studs wide")
				local first, last = p.Path[1], p.Path[#p.Path]
				top = top or first[2] <= 8 or last[2] <= 8
				bottom = bottom or first[2] >= length - 8 or last[2] >= length - 8
				left = left or anchored(p, -200)
				right = right or anchored(p, 180)
			end
		end
		if layout.FadeEvery then
			-- Old 152-stud layouts: ramps on both sides, anchored at each old tile edge.
			assert(left and right, entry.Source .. ": needs ramps from x = -200 and x = 180")
		else
			assert(
				top and bottom,
				entry.Source .. ": needs ramps from the zone's top edge to its bottom edge"
			)
		end
	end
end)

test("ramps stay within the cart slope and nothing is raised on them", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local z0 = nil
	for _, entry in Layouts.all(true) do
		Layouts.setActive(entry.Zone, entry.Layout)
		z0 = Beach.tileRange(entry.Zone)
		for _, p in entry.Layout.Primitives do
			if p.Kind == "Ramp" then
				for i = 1, #p.Path - 1 do
					local a, b = p.Path[i], p.Path[i + 1]
					local len = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
					local last = nil
					for s = 0, len, 2 do
						local t = s / len
						local x = a[1] + (b[1] - a[1]) * t
						local z = z0 + a[2] + (b[2] - a[2]) * t
						-- Nothing raised on a ramp; a dip is allowed (low ground that floods first),
						-- as long as it keeps to the cart slope (below).
						assert(
							Beach.feature(x, z) <= 0,
							entry.Source .. ": a ramp's centre is clear of raised shapes"
						)
						local y = Beach.groundAt(x, z)
						if last then
							assert(
								math.abs(y - last) / 2 <= Config.Beach.Terrain.CartSlope,
								entry.Source .. ": a ramp is cart-passable"
							)
						end
						last = y
					end
				end
			end
		end
		Layouts.setActive(entry.Zone, nil)
	end
end)

test("a cart and a player on foot reach the sea whatever the biomes", function()
	local Config = h.require("Shared/Config")
	local grid = layoutGrid()
	local cfg = Config.Beach.Terrain
	-- All the way from the shop with the first way each zone comes out...
	local choice = {}
	for zone = 1, Config.Beach.ActiveZones do
		choice[zone] = 1
	end
	assert(layoutReaches(layoutFlood(grid, choice, cfg.CartSlope), 0, LAYOUT_END), "a cart reaches the sea")
	assert(layoutReaches(layoutFlood(grid, choice, cfg.FootSlope), 0, LAYOUT_END), "so does a player on foot")
	-- ...and every way each zone can come out crosses it (the zones meet along flat ground,
	-- so a route can enter the next anywhere along the edge).
	local failures = {}
	for zone = 1, Config.Beach.ActiveZones do
		for _, option in grid.options[zone] do
			if not layoutCrossesZone(grid, zone, option, cfg.CartSlope) then
				table.insert(failures, option.name .. " (zone " .. zone .. "): no way across for a cart")
			end
			if not layoutCrossesZone(grid, zone, option, cfg.FootSlope) then
				table.insert(failures, option.name .. " (zone " .. zone .. "): no way across on foot")
			end
		end
	end
	assert(#failures == 0, table.concat(failures, "; "))
end)

test("a player on foot can reach every biome's entrance spot in every zone it rolls in", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Biomes = h.require("Shared/Biomes")
	local grid = layoutGrid()
	local checked, failures = 0, {}
	eachLayoutChoice(grid, function(choice)
		local seen = nil
		for zone = 1, Config.Beach.ActiveZones do
			local option = grid.options[zone][choice[zone]]
			local biome = option.biome and Biomes.List[option.biome]
			if biome then
				seen = seen or layoutFlood(grid, choice, Config.Beach.Terrain.FootSlope)
				local zStart = Beach.tileRange(zone)
				for _, x in biome.EntranceSpots or {} do
					checked += 1
					if not layoutReaches(seen, x, zStart + 30) then
						table.insert(failures, option.name .. " in zone " .. zone .. " at x " .. x)
					end
				end
			end
		end
	end)
	assert(checked > 0, "there are entrance spots to check")
	assert(#failures == 0, "unreachable on foot: " .. table.concat(failures, "; "))
end)

test("every loot spot and entrance can be reached on foot, whichever way the zone comes out", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local grid = layoutGrid()
	local failures = {}
	for zone = 1, Config.Beach.ActiveZones do
		for _, option in grid.options[zone] do
			-- Every cell reachable from the zone's top edge on foot.
			local rows = {}
			for iz = LAYOUT_ROWS[1], LAYOUT_ROWS[2] do
				if grid.zoneOfRow[iz] == zone then
					table.insert(rows, iz)
				end
			end
			local top, bottom = rows[1], rows[#rows]
			local seen, queue, head = {}, {}, 1
			for ix = -LAYOUT_COLS, LAYOUT_COLS do
				seen[layoutKey(ix, top)] = true
				table.insert(queue, { ix, top })
			end
			local slope = Config.Beach.Terrain.FootSlope * LAYOUT_GRID
			while head <= #queue do
				local ix, iz = queue[head][1], queue[head][2]
				head += 1
				local y = option.heights[layoutKey(ix, iz)]
				for _, step in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
					local nx, nz = ix + step[1], iz + step[2]
					local k = layoutKey(nx, nz)
					if math.abs(nx) <= LAYOUT_COLS and nz >= top and nz <= bottom and not seen[k] then
						local ny = option.heights[k]
						-- Up only as steep as players can walk; down any drop.
						if ny and ny - y <= slope then
							seen[k] = true
							table.insert(queue, { nx, nz })
						end
					end
				end
			end
			Layouts.setActive(zone, option.id, zone, option.choice)
			local z0 = Beach.tileRange(zone)
			local spots = {}
			for _, spot in Layouts.lootSpots(zone, z0) do
				table.insert(spots, { spot.X, spot.Z, "loot spot" })
			end
			for _, point in Layouts.entrances(zone, z0) do
				table.insert(spots, { point.X, point.Y, "entrance" })
			end
			Layouts.setActive(zone, nil)
			for _, spot in spots do
				if not layoutReaches(seen, spot[1], spot[2]) then
					table.insert(
						failures,
						string.format(
							"%s (zone %d): %s at (%d, %d)",
							option.name,
							zone,
							spot[3],
							spot[1],
							spot[2] - z0
						)
					)
				end
			end
		end
	end
	assert(#failures == 0, "can't be reached on foot: " .. table.concat(failures, "; "))
end)

test("every zone has at least two shortcuts a player on foot can take faster than a cart", function()
	local Config = h.require("Shared/Config")
	local grid = layoutGrid()
	local starts = { -300, -150, 0, 150, 300 }
	local weak = {}
	for zone = 1, Config.Beach.ActiveZones do
		for _, option in grid.options[zone] do
			local count = 0
			for _, x in starts do
				local startIx = math.floor(x / LAYOUT_GRID)
				local cart = layoutRoute(grid, zone, option, startIx, Config.Beach.Terrain.CartSlope)
				local foot = layoutRoute(grid, zone, option, startIx, Config.Beach.Terrain.FootSlope)
				if foot and (cart == nil or foot < cart) then
					count += 1
				end
			end
			if count < 2 then
				table.insert(weak, option.name .. " (zone " .. zone .. ") has " .. count)
			end
		end
	end
	assert(#weak == 0, "too few shortcuts: " .. table.concat(weak, "; "))
end)

-- layoutHidden from the test grid's heights (4-stud cells) instead of the ground itself: the
-- same measure, cheap enough to run on every way every zone can come out.
local function layoutHiddenGrid(grid, zone: number, option): number
	local Config = h.require("Shared/Config")
	local rows = {}
	for iz = LAYOUT_ROWS[1], LAYOUT_ROWS[2] do
		if grid.zoneOfRow[iz] == zone then
			table.insert(rows, iz)
		end
	end
	local top, bottom = rows[1], rows[#rows]
	if option.every then
		bottom = math.min(bottom, top + math.floor(option.every / LAYOUT_GRID) - 1)
	end
	local function height(ix: number, iz: number): number
		return option.heights[layoutKey(ix, iz)] or -math.huge
	end
	local eye = Config.Beach.Terrain.EyeHeight
	local eyes = {}
	for _, x in { -320, -240, -160, -80, 0, 80, 160, 240, 320 } do
		local ix = math.floor(x / LAYOUT_GRID + 0.5)
		table.insert(eyes, { ix = ix, iz = top, y = height(ix, top) + eye })
	end
	local total, hidden = 0, 0
	for iz = top + math.floor((bottom - top) / 2), bottom - 1, 2 do
		for ix = -84, 84, 2 do
			local ty = height(ix, iz)
			total += 1
			local seen = false
			for _, e in eyes do
				local blocked = false
				local steps = math.max(math.abs(iz - e.iz), math.abs(ix - e.ix))
				for k = 1, steps - 1 do
					local t = k / steps
					local cx = math.floor(e.ix + (ix - e.ix) * t + 0.5)
					local cz = math.floor(e.iz + (iz - e.iz) * t + 0.5)
					if height(cx, cz) > e.y + (ty - e.y) * t + 0.2 then
						blocked = true
						break
					end
				end
				if not blocked then
					seen = true
					break
				end
			end
			if not seen then
				hidden += 1
			end
		end
	end
	return hidden / math.max(total, 1)
end

test("zone 1 is readable from the top, and zones 2 to 4 hide their lower half", function()
	local Config = h.require("Shared/Config")
	local grid = layoutGrid()
	local problems = {}
	for zone = 1, Config.Beach.ActiveZones do
		for _, option in grid.options[zone] do
			local hidden = layoutHiddenGrid(grid, zone, option)
			if zone == 1 and hidden > 0.2 then
				table.insert(problems, option.name .. " (zone 1) hides " .. math.floor(hidden * 100) .. "%")
			elseif zone > 1 and hidden < 0.6 then
				table.insert(
					problems,
					option.name .. " (zone " .. zone .. ") hides only " .. math.floor(hidden * 100) .. "%"
				)
			end
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

test("layouts stay within their zone's height, and rock and walls start at zone 4", function()
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local cfg = Config.Beach.Terrain
	local limit = { 2.5, 5, 7, 10 } -- from the design: how rough each zone may get
	local problems = {}
	for _, entry in Layouts.all(true) do
		local high, low, rock = 0, 0, false
		-- Walls have their own limit (WallMaxHeight, checked with every layout) and belong to
		-- the rock zones; the zone's roughness is the rest of its ground.
		local banks = { Name = entry.Layout.Name, Primitives = {} }
		local walls = false
		for _, p in entry.Layout.Primitives do
			if p.Kind == "Wall" or p.Kind == "Roof" then
				walls = true
			else
				table.insert(banks.Primitives, p)
			end
		end
		if walls and entry.Zone < 4 then
			table.insert(problems, entry.Source .. " has walls or roofs before zone 4")
		end
		for x = -350, 350, 2 do
			for z = 0, 150, 2 do
				local f, r = Layouts.evaluate(banks, x, z)
				high = math.max(high, f)
				low = math.min(low, f)
				rock = rock or r
			end
		end
		local max = limit[entry.Zone] or cfg.MaxHeight
		if high > max + 0.01 then
			table.insert(
				problems,
				entry.Source .. " (zone " .. entry.Zone .. ") rises " .. high .. ", over " .. max
			)
		end
		if -low > cfg.MaxDepth then
			table.insert(problems, entry.Source .. " cuts " .. -low .. " deep")
		end
		if rock and entry.Zone < 4 then
			table.insert(problems, entry.Source .. " has rock before zone 4")
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

test("the pier's path and every entrance spot are clear of shapes", function()
	local Beach = h.require("Shared/Beach")
	local Biomes = h.require("Shared/Biomes")
	local Layouts = h.require("Shared/Layouts")
	local grid = layoutGrid()
	local problems = {}
	for zone = 1, 4 do
		for _, option in grid.options[zone] do
			Layouts.setActive(zone, option.id, zone, option.choice)
			local zStart = Beach.tileRange(zone)
			if zone == 2 then
				-- The pier runs along x = 40 over the first two tiles of zone 2: the whole way
				-- through any tile there.
				for z = zStart, zStart + 150, 2 do
					if Beach.feature(40, z) ~= 0 then
						table.insert(problems, option.name .. ": the pier is blocked at z " .. z)
						break
					end
				end
			end
			local biome = option.biome and Biomes.List[option.biome]
			if biome then
				for _, x in biome.EntranceSpots or {} do
					if Beach.feature(x, zStart + 30) ~= 0 then
						table.insert(problems, option.name .. ": entrance at x " .. x .. " is not flat")
					end
				end
			end
			Layouts.setActive(zone, nil)
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

test("the rock pools keep their ground, so nothing is cut or raised through them", function()
	local Config = h.require("Shared/Config")
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local problems = {}
	-- The distance from a pool's centre (in the zone's own Z) to a primitive's path, or to its centre.
	local function distanceTo(pool, p): number
		local points = p.Path or { p.At }
		if #points == 1 then
			return math.sqrt((points[1][1] - pool.X) ^ 2 + (points[1][2] - pool.Z) ^ 2)
		end
		local best = math.huge
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local len2 = dx * dx + dz * dz
			local t = if len2 > 0
				then math.clamp(((pool.X - a[1]) * dx + (pool.Z - a[2]) * dz) / len2, 0, 1)
				else 0
			best = math.min(best, math.sqrt((a[1] + dx * t - pool.X) ^ 2 + (a[2] + dz * t - pool.Z) ^ 2))
		end
		return best
	end
	for _, entry in Layouts.all(true) do
		for _, pool in poolsOnZone(Beach, entry.Zone) do
			do
				local local_pool = pool
				for _, p in entry.Layout.Primitives do
					if p.Kind == "Ridge" or p.Kind == "Mound" or p.Kind == "Channel" then
						local d = distanceTo(local_pool, p)
						if d < pool.Radius + 6 then
							table.insert(
								problems,
								entry.Source
									.. ": a "
									.. p.Kind
									.. " comes within "
									.. math.floor(d)
									.. " studs of a pool"
							)
						end
					end
				end
			end
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

test("each planned draft reaches the sea, has shortcuts, and keeps the sightline rule", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Biomes = h.require("Shared/Biomes")
	local Layouts = h.require("Shared/Layouts")
	local cfg = Config.Beach.Terrain
	local grid = layoutGrid()
	local problems = {}
	local checkedDrafts = {} -- a zone without its own draft uses the one above: check it once
	for zone = 1, Config.Beach.ActiveZones do
		for id in Biomes.Planned do
			local def = Layouts.forPlanned(id, zone)
			if def and not checkedDrafts[def] then
				checkedDrafts[def] = true
				-- This zone takes the draft; every other zone keeps its base layout.
				Layouts.setActive(zone, id, zone)
				local option = { name = id, heights = {}, every = Layouts.fadeEvery(zone) }
				for iz = LAYOUT_ROWS[1], LAYOUT_ROWS[2] do
					if grid.zoneOfRow[iz] == zone then
						for ix = -LAYOUT_COLS, LAYOUT_COLS do
							option.heights[layoutKey(ix, iz)] =
								Beach.groundAt(ix * LAYOUT_GRID, iz * LAYOUT_GRID)
						end
					end
				end
				local hidden = layoutHidden(zone)
				Layouts.setActive(zone, nil)
				local label = id .. " (zone " .. zone .. ")"
				local byZone = { zoneOfRow = grid.zoneOfRow }
				if not layoutCrossesZone(byZone, zone, option, cfg.CartSlope) then
					table.insert(problems, label .. ": a cart can't cross it")
				end
				if not layoutCrossesZone(byZone, zone, option, cfg.FootSlope) then
					table.insert(problems, label .. ": a player on foot can't cross it")
				end
				local count = 0
				for _, x in { -300, -150, 0, 150, 300 } do
					local startIx = math.floor(x / LAYOUT_GRID)
					local cart = layoutRoute(byZone, zone, option, startIx, cfg.CartSlope)
					local foot = layoutRoute(byZone, zone, option, startIx, cfg.FootSlope)
					if foot and (cart == nil or foot < cart) then
						count += 1
					end
				end
				if count < 2 then
					table.insert(problems, label .. ": only " .. count .. " shortcut starts of 5")
				end
				if zone == 1 and hidden > 0.2 then
					table.insert(
						problems,
						label .. ": hides " .. math.floor(hidden * 100) .. "% from the top"
					)
				elseif zone > 1 and hidden < 0.6 then
					table.insert(
						problems,
						label .. ": hides only " .. math.floor(hidden * 100) .. "% from the top"
					)
				end
			end
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

test("waves break where the sea really meets the sand", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local Waves = h.require("Shared/Waves")
	local z0 = Beach.tileRange(3)
	local line = z0 + 75
	Layouts.setActive(3, false)
	-- (Each check looks at a different X: the shore is cached for a moment.)
	assert(math.abs(Beach.shoreFrom(-6, line) - line) < 0.1, "on the even slope the shore is the waterline")
	-- A bank standing out of the water 12 studs out: the shore is its seaward face.
	Layouts.setActive(3, {
		Name = "bank",
		Primitives = { { Kind = "Ridge", Path = { { -200, 87 }, { 200, 87 } }, Height = 4, Width = 12 } },
	})
	local shore = Beach.shoreFrom(0, line)
	assert(shore > line + 12 and shore < line + 18, "a bank moves the shore out, got " .. (shore - line))
	assert(Waves.frontAt(0, line, -10) >= shore - line - 1, "and stops the run-up at its face")
	-- A channel cut across the waterline: the shore is its landward bank.
	Layouts.setActive(3, {
		Name = "cut",
		Primitives = { { Kind = "Channel", Path = { { -200, 75 }, { 200, 75 } }, Depth = 2, Width = 16 } },
	})
	assert(Beach.shoreFrom(1, line) < line - 3, "a channel moves the shore in")
	Layouts.setActive(3, nil)
end)

test("the water's fallback parts show the step to deep water", function()
	local SeaController = h.require("Client/SeaController")
	local Tide = h.require("Shared/Tide")
	local Config = h.require("Shared/Config")
	local sea = Tide.sea(1000)
	local pieces, columnXs = SeaController._piecesFrame(sea, sea)
	for c, x in columnXs do
		local near, out = pieces.seaNear[c], pieces.seaOut[c]
		local nearEnd = near.CFrame.Position.Z + near.Size.Z / 2
		local outStart = out.CFrame.Position.Z - out.Size.Z / 2
		assert(math.abs(nearEnd - outStart) < 0.6, "the pale and deep parts meet at x " .. x)
		local line = Tide.waterlineAt(sea, x)
		assert(
			outStart >= line + Config.Beach.WaistDepth / Config.Beach.Slope - 0.6,
			"the deep part starts where the sea is deep enough to drown, at x " .. x
		)
	end
end)

test("the water meshes fit Roblox's limits", function()
	local SeaController = h.require("Client/SeaController")
	local total = 0
	for _, entry in SeaController._meshPlan() do
		local sheet = entry.sheet
		local covered = 1
		for _, range in entry.ranges do
			local fromCol, toCol = range[1], range[2]
			assert(fromCol == covered, sheet.name .. ": the meshes join up")
			covered = toCol
			local triangles = (toCol - fromCol) * (sheet.rows - 1) * 2
			total += triangles
			assert(
				triangles <= SeaController._limits.Triangles,
				sheet.name .. ": too many triangles in one mesh"
			)
			local size = roblox.Vector3.new(sheet.colXs[toCol] - sheet.colXs[fromCol] + 2, 0, 0)
				+ roblox.Vector3.new(0, sheet.high.Y - sheet.low.Y, sheet.high.Z - sheet.low.Z)
			assert(
				size.X <= 2048 and size.Y <= 2048 and size.Z <= 2048,
				sheet.name .. ": a mesh is over 2048 studs"
			)
		end
		assert(covered == #sheet.colXs, sheet.name .. ": the meshes cover every column")
	end
	-- Keep the water light: the editable mesh memory budget is small.
	assert(total <= 14000, "the water has " .. total .. " triangles")
end)

test("walls are flat-topped rock too steep to climb", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local cfg = Config.Beach.Terrain
	local tile = 3
	local z0 = Beach.tileRange(tile)
	local wall = { Kind = "Wall", Path = { { -100, 75 }, { 100, 75 } }, Height = 20, Width = 12 }
	Layouts.setActive(tile, { Name = "wall", Primitives = { wall } })
	local height, rock = Beach.shapeAt(0, z0 + 75)
	assert(math.abs(height - 20) < 0.01 and rock, "full height, rock, at its middle")
	assert(math.abs(Beach.feature(0, z0 + 75 + 4) - 20) < 0.01, "and across its flat top")
	-- Its side: steeper than anyone can walk up, and taller than a jump.
	local steepest = 0
	for z = z0 + 75, z0 + 75 + 8, 0.5 do
		steepest = math.max(steepest, Beach.feature(0, z) - Beach.feature(0, z + 0.5))
	end
	assert(steepest / 0.5 > cfg.FootSlope * 3, "its side is a cliff, steepest " .. steepest / 0.5)
	assert(Beach.feature(0, z0 + 75 + 7) == 0, "and it ends at Width / 2")
	Layouts.setActive(tile, nil)
	local tooTall = {
		Name = "x",
		Primitives = { { Kind = "Wall", Path = { { 0, 0 }, { 1, 1 } }, Height = 99, Width = 14 } },
	}
	local tooThin = {
		Name = "x",
		Primitives = { { Kind = "Wall", Path = { { 0, 0 }, { 1, 1 } }, Height = 10, Width = 2 } },
	}
	assert(#Layouts.problems(tooTall) == 1 and #Layouts.problems(tooThin) == 1, "walls have limits")
end)

test("walls get an invisible barrier inside them, open where a ramp cuts through", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local WallBarriers = h.require("Server/WallBarriers")
	local tile = 4
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "walled",
		Primitives = {
			{ Kind = "Wall", Path = { { -150, 75 }, { 150, 75 } }, Height = 18, Width = 14 },
			{ Kind = "Ramp", Path = { { 0, 0 }, { 0, 150 } }, Width = 16 },
		},
	})
	local slabs = WallBarriers.slabsFor(tile)
	assert(#slabs == 2, "one slab each side of the ramp, got " .. #slabs)
	for _, slab in slabs do
		local position = slab.cframe.Position
		assert(math.abs(position.Z - (z0 + 75)) < 0.01, "down the wall's middle")
		assert(math.abs(position.X) > 8, "not across the ramp")
		local top = position.Y + slab.size.Y / 2
		assert(top > Beach.groundY(z0 + 75) + 18 + 7, "higher than a jump off the wall's top")
		assert(slab.size.X < 14, "inside the wall")
	end
	WallBarriers.build(tile)
	assert(#h.game.Workspace.WallBarriers["Tile" .. tile]:GetChildren() == 2, "built as parts")
	Layouts.setActive(tile, false)
	WallBarriers.build(tile)
	assert(#h.game.Workspace.WallBarriers["Tile" .. tile]:GetChildren() == 0, "and gone with the wall")
	Layouts.setActive(tile, nil)
	WallBarriers.build(tile)
end)

test("scenery only stands on level ground, not across walls or under roofs", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local GroundShift = h.require("Server/GroundShift")
	local tile = 4
	local z0 = Beach.tileRange(tile)
	local function prop(x: number, z: number): Part
		local part = Harness.wrap(roblox.Instance.new("Part"))
		part.Size = roblox.Vector3.new(4, 2, 4)
		part.CFrame = roblox.CFrame.new(x, Beach.groundAt(x, z0 + z), z0 + z)
		return part
	end
	Layouts.setActive(tile, false)
	local scenery = Harness.wrap(roblox.Instance.new("Folder"))
	local onEdge, open = prop(-60, 68), prop(-60, 20)
	onEdge.Parent, open.Parent = scenery, scenery
	Layouts.setActive(tile, {
		Name = "walled",
		Primitives = {
			{ Kind = "Wall", Path = { { -150, 75 }, { 150, 75 } }, Height = 18, Width = 24 },
			{ Kind = "Roof", At = { 100, 30 }, Radius = 20, Clearance = 10, Thickness = 6 },
		},
	})
	assert(not GroundShift.fits(onEdge), "a prop across a wall's edge doesn't fit")
	assert(GroundShift.fits(prop(-60, 75)), "one on its flat top does")
	assert(not GroundShift.fits(prop(100, 30)), "nor one under a roof")
	assert(GroundShift.fits(open), "a prop on open sand does")
	assert(GroundShift.tidy(scenery) == 1, "tidy puts away the one across the wall")
	assert(onEdge.Parent ~= scenery and open.Parent == scenery, "and leaves the other")
	assert(GroundShift._away()[onEdge] == scenery, "remembering where it came from")
	GroundShift.clearMisfits(scenery)
	assert(open.Parent == scenery, "clearMisfits keeps what fits")
	Layouts.setActive(tile, nil)
end)

test("the tide leaves finds at the layouts' loot spots, once each tide", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local Tide = h.require("Shared/Tide")
	local ItemService = h.require("Server/ItemService")
	local tile = 4
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "spotted",
		Primitives = { { Kind = "Wall", Path = { { -150, 40 }, { 150, 40 } }, Height = 18, Width = 16 } },
		Loot = { { At = { 0, 100 }, Radius = 6, Weight = 4 } },
	})
	local chance = Config.Items.SpotChance
	Config.Items.SpotChance = 1
	local function near(): { BasePart }
		local found = {}
		for item in ItemService.all() do
			local p = item.CFrame.Position
			if math.abs(p.X) < 8 and math.abs(p.Z - (z0 + 100)) < 8 then
				table.insert(found, item)
			end
		end
		return found
	end
	local highSea, lowSea = Tide.sea(0), Tide.sea(1000)
	assert(Beach.seaDepthAt(roblox.Vector3.new(0, 0, z0 + 100), highSea) > 0, "covered at high tide")
	ItemService.settleSpots(highSea, 1)
	assert(#near() == 0, "nothing settles under the sea")
	ItemService.settleSpots(lowSea, 1)
	assert(#near() == 1, "a find once the tide leaves the spot dry")
	ItemService.settleSpots(lowSea, 1)
	assert(#near() == 1, "only once each tide")
	ItemService.settleSpots(lowSea, 2)
	assert(#near() == 2, "and again the next tide")
	for _, item in near() do
		local _, rock = Beach.shapeAt(item.CFrame.X, item.CFrame.Z)
		assert(not rock, "never on rock")
	end
	for item in ItemService.all() do
		ItemService.destroy(item)
	end
	Config.Items.SpotChance = chance
	Layouts.setActive(tile, nil)
end)

test("each zone looks its own, darker and foggier all the way down, and biomes on top", function()
	local Beach = h.require("Shared/Beach")
	local Biomes = h.require("Shared/Biomes")
	local Config = h.require("Shared/Config")
	local Looks = h.require("Shared/Looks")
	local problems = Looks.problems()
	assert(#problems == 0, table.concat(problems, "; "))
	local zoneLength = Config.Beach.ZoneLength
	local function middle(zone: number): number
		return (zone - 0.5) * zoneLength
	end
	for zone = 2, Config.Beach.ActiveZones do
		assert(Looks.at(middle(zone)).Fog > Looks.at(middle(zone - 1)).Fog, "zone " .. zone .. " is foggier")
	end
	assert(Looks.at(middle(6)).Brightness < Looks.at(middle(1)).Brightness, "the deep zones are darker")
	local deep = Looks.terrainAt(0, middle(6))
	assert(deep ~= Looks.terrainAt(0, middle(1)), "the deep floor is a different ground")

	-- A biome stands out where it rolls, and still gets foggier deeper down.
	local workspace = h.game:GetService("Workspace")
	local shallowTile, deepTile = Beach.tileAt(middle(2)), Beach.tileAt(middle(6))
	local plain = Looks.at(middle(6)).Fog
	workspace:SetAttribute(Biomes.attributeFor(shallowTile :: number), "ShipwreckShallows")
	workspace:SetAttribute(Biomes.attributeFor(deepTile :: number), "ShipwreckShallows")
	local z0, z1 = Beach.tileRange(deepTile :: number)
	local mid = (z0 + z1) / 2
	assert(Looks.at(mid).Fog > plain, "the wreck is foggier than its zone")
	assert(Looks.at(mid).Fog > Looks.at(Beach.tileRange(shallowTile :: number) + 76).Fog, "deeper is foggier")
	assert(Looks.terrainAt(0, mid) == roblox.Enum.Material.Pavement, "the wreck brings its own ground")
	for x = -300, 300, 4 do
		assert(Looks.terrainAt(x, z0 - 2) ~= roblox.Enum.Material.Pavement, "which stops at its tile's edge")
		assert(Looks.terrainAt(x, z1 + 2) ~= roblox.Enum.Material.Pavement, "on both sides")
	end
	workspace:SetAttribute(Biomes.attributeFor(shallowTile :: number), nil)
	workspace:SetAttribute(Biomes.attributeFor(deepTile :: number), nil)
end)

test("a zone is a frame, one of its crossings and a room in each slot, rolled each tide", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local BiomeService = h.require("Server/BiomeService")
	local wall = function(z)
		return { Kind = "Wall", Path = { { -300, z }, { 300, z } }, Height = 16, Width = 12 }
	end
	local def = {
		Name = "test zone",
		Primitives = { wall(100) },
		Loot = { { At = { 0, 50 }, Radius = 6 } },
		Crossings = {
			{ Name = "left", Primitives = { { Kind = "Flat", At = { -200, 100 }, Radius = 12 } } },
			{ Name = "right", Primitives = { { Kind = "Flat", At = { 200, 100 }, Radius = 12 } } },
		},
		Slots = {
			{
				Name = "pocket",
				At = { 100, 300 },
				Size = { 80, 60 },
				Rooms = {
					{ Name = "empty", Primitives = {} },
					{
						Name = "boulder",
						Primitives = {
							{ Kind = "Mound", At = { 40, 30 }, Radius = 10, Height = 6, Rock = true },
						},
						Loot = { { At = { 10, 10 }, Radius = 4, Weight = 3 } },
					},
				},
			},
		},
	}
	assert(#Layouts.defProblems(def, "test") == 0, table.concat(Layouts.defProblems(def, "test"), "; "))
	local crossings, slots = Layouts.shape(def)
	assert(crossings == 2 and #slots == 1 and slots[1] == 2, "two crossings, one slot of two rooms")
	assert(Layouts.encode({ Crossing = 2, Rooms = { 1 } }) == "2:1", "a choice as text")
	local decoded = Layouts.decode(def, "2:2")
	assert(decoded.Crossing == 2 and decoded.Rooms[1] == 2, "and back")
	local clamped = Layouts.decode(def, "9:7")
	assert(clamped.Crossing == 1 and clamped.Rooms[1] == 1, "out of range falls back to the first")

	local composed = Layouts.compose(def, { Crossing = 2, Rooms = { 2 } })
	assert(
		composed == Layouts.compose(def, { Crossing = 2, Rooms = { 2 } }),
		"the same choice, the same layout"
	)
	assert(#composed.Primitives == 3, "frame, crossing and room")
	local mound = composed.Primitives[3]
	assert(mound.At[1] == 140 and mound.At[2] == 330, "the room is moved into its slot")
	assert(#composed.Loot == 2 and composed.Loot[2].At[1] == 110, "with its loot")
	assert(#Layouts.problems(composed) == 0, "a well formed layout")
	assert(#Layouts.options(def) == 3, "two crossings, then the other room")

	local bad = table.clone(def)
	bad.Slots =
		{ { Name = "x", At = { 0, 0 }, Size = { 20, 20 }, Rooms = { { Primitives = { wall(30) } } } } }
	assert(#Layouts.defProblems(bad, "bad") > 0, "a room reaching out of its slot is a problem")

	-- On a tile: following its rolled choice.
	local tile = 4
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, def, nil, { Crossing = 1, Rooms = { 1 } })
	assert(Beach.feature(-200, z0 + 100) == 0 and Beach.feature(200, z0 + 100) > 10, "the left way is open")
	Layouts.setActive(tile, def, nil, { Crossing = 2, Rooms = { 2 } })
	assert(Beach.feature(200, z0 + 100) == 0 and Beach.feature(-200, z0 + 100) > 10, "then the right way")
	assert(Beach.feature(140, z0 + 330) > 5, "and the boulder room")
	Layouts.setActive(tile, nil)

	-- The server rolls a choice with each biome.
	BiomeService.set(tile, nil)
	local text = h.game.Workspace:GetAttribute(Layouts.attributeFor(tile))
	assert(type(text) == "string" and string.match(text, "^%d+:"), "a rolled choice, got " .. tostring(text))
	BiomeService.set(tile, nil, "1:")
	assert(
		h.game.Workspace:GetAttribute(Layouts.attributeFor(tile))
			== Layouts.encode(Layouts.decode(Layouts.activeDef(tile), "1:")),
		"or a given one"
	)
end)

test("the review place says where you are: zone, crossing, slot and room", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local Review = h.require("Shared/Review")
	assert(not Review.enabled(), "only in the review place")
	local def = {
		Name = "review test",
		Primitives = {},
		Crossings = { { Name = "left", Primitives = {} }, { Name = "right", Primitives = {} } },
		Slots = {
			{
				Name = "pocket",
				At = { 100, 300 },
				Size = { 80, 60 },
				Rooms = { { Name = "a", Primitives = {} }, { Name = "b", Primitives = {} } },
			},
		},
	}
	local tile = 4
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, def, nil, { Crossing = 2, Rooms = { 2 } })
	local where = Review.where(roblox.Vector3.new(120, 0, z0 + 310))
	assert(where.Zone == 4 and where.Z == 310, "the zone, and z from its top edge")
	assert(where.CrossingName == "right" and where.Choice == "2:2", "the crossing that rolled")
	assert(where.SlotName == "pocket" and where.RoomName == "b", "the slot and room stood in")
	assert(Review.where(roblox.Vector3.new(0, 0, z0 + 100)).Slot == nil, "outside the slots, none")
	assert(Review.nearestSlot(tile, roblox.Vector3.new(0, 0, z0 + 100)) == 1, "the nearest slot")
	Layouts.setActive(tile, nil)
end)

test("shapes can be any outline, worn at the edges, and made of their own materials", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local WallBarriers = h.require("Server/WallBarriers")
	local tile = 4
	local z0 = Beach.tileRange(tile)
	local layout = {
		Name = "outlines",
		Primitives = {
			-- An L-shaped block of basalt.
			{
				Kind = "Wall",
				Area = {
					{ -200, 100 },
					{ -100, 100 },
					{ -100, 140 },
					{ -160, 140 },
					{ -160, 220 },
					{ -200, 220 },
				},
				Height = 20,
				Material = "Basalt",
			},
			-- A worn wall.
			{ Kind = "Wall", Path = { { 50, 300 }, { 250, 300 } }, Width = 16, Height = 18, Rough = 4 },
			-- A rectangular roof, and a patch of mud.
			{
				Kind = "Roof",
				Area = { { 100, 400 }, { 200, 400 }, { 200, 460 }, { 100, 460 } },
				Clearance = 10,
				Thickness = 6,
				Material = "Slate",
			},
			{ Kind = "Paint", Area = { { -50, 400 }, { 50, 400 }, { 0, 480 } }, Material = "Mud", Rough = 3 },
		},
	}
	local problems = Layouts.problems(layout)
	assert(#problems == 0, table.concat(problems, "; "))
	Layouts.setActive(tile, layout)
	local height, rock, material = Beach.shapeAt(-180, z0 + 200)
	assert(
		math.abs(height - 20) < 0.01 and rock and material == "Basalt",
		"inside the L: full height, basalt"
	)
	assert(Beach.feature(-130, z0 + 200) == 0, "outside the L's corner: open ground")
	-- The worn wall stands full height down its middle, but its edge wanders.
	local edges = {}
	for x = 60, 240, 6 do
		assert(math.abs(Beach.feature(x, z0 + 300) - 18) < 0.01, "full height down the middle")
		for dz = 0, 14, 0.5 do
			if Beach.feature(x, z0 + 300 + dz) < 9 then
				edges[dz] = true
				break
			end
		end
	end
	local count = 0
	for _ in edges do
		count += 1
	end
	assert(count >= 3, "a worn edge isn't a straight line")
	local bottom, top, roofMaterial = Beach.roofAt(150, z0 + 430)
	assert(bottom and top and roofMaterial == "Slate", "a rectangular roof, of slate")
	assert(Beach.roofAt(205, z0 + 430) == nil, "with square sides")
	assert(
		Beach.paintAt(0, z0 + 420) == "Mud" and Beach.feature(0, z0 + 420) == 0,
		"mud painted on flat ground"
	)
	assert(Beach.paintAt(0, z0 + 300) == nil, "and nowhere else")
	assert(#WallBarriers.slabsFor(tile) > 2, "barriers inside the outlined wall too")
	local bad = {
		Name = "bad",
		Primitives = {
			{ Kind = "Paint", At = { 0, 0 }, Radius = 5, Material = "Lava" },
			{ Kind = "Wall", Height = 10, Area = { { 0, 0 }, { 1, 1 } } },
		},
	}
	assert(#Layouts.problems(bad) >= 2, "unknown materials and two-point areas are problems")
	Layouts.setActive(tile, nil)
end)

test("a plain zone's own dangers go where its layout puts them, and they're deadly", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Hazards = h.require("Shared/Hazards")
	local Layouts = h.require("Shared/Layouts")
	local Tide = h.require("Shared/Tide")
	local HazardService = h.require("Server/HazardService")
	local tile = 6
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "dangers",
		Primitives = {
			{
				Kind = "Roof",
				Area = { { -40, 100 }, { 40, 100 }, { 40, 140 }, { -40, 140 } },
				Clearance = 12,
				Thickness = 6,
			},
		},
		Hazards = {
			{ Type = "Sink", At = { 100, 200 }, Radius = 10 },
			{ Type = "Rockfall", At = { 0, 120 } },
			{ Type = "Undertow", Path = { { -200, 300 }, { -200, 400 } }, Width = 12 },
			{ Type = "Gloom", Path = { { 100, 400 }, { 250, 400 } }, Radius = 20 },
			{ Type = "Pit", At = { -150, 200 } },
			{ Type = "Pit", At = { -150, 260 }, Radius = 6, Depth = 10, Covered = true },
		},
	})
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	local zone = Config.Zones[tile]
	HazardService.start(tile, zone, folder)
	local effects = {}
	for _, part in folder:GetChildren() do
		local effect = part:GetAttribute("Effect")
		if effect then
			effects[effect] = (effects[effect] or 0) + 1
		end
	end
	local sinkSettings = Hazards.settings({ Type = "Sink" })
	local count = function(name)
		local n = 0
		for _, part in folder:GetDescendants() do
			if part.Name == name then
				n += 1
			end
		end
		return n
	end
	assert(effects.Sink == 1 + sinkSettings.Lobes, "the sinking sand: a blob of lobes")
	assert(count("RockfallShadow") >= 3 and count("Rubble") >= 5, "the rockfall: rubble, and rocks to fall")
	assert(
		count("SpikePit") == 2 and count("PitCover") == 1 and count("Spike") >= 10,
		"a spike pit open, one covered"
	)
	assert((effects.Current or 0) >= 3, "the undertow")
	assert(effects.Gloom == 1, "and the Gloom")
	local gloom
	for _, part in folder:GetChildren() do
		if part.Name == "GloomShadow" then
			gloom = part
		end
	end
	-- (Where along its path it starts is random, and it may turn back: watch it a while.)
	HazardService._step(0, 0.1)
	local startX, farthest = gloom.CFrame.X, 0
	for t = 2, 40, 2 do
		HazardService._step(t, 0.1)
		farthest = math.max(farthest, math.abs(gloom.CFrame.X - startX))
	end
	assert(farthest > 20, "the Gloom's shadow moves along its path")
	assert(gloom:GetAttribute("Duration") > 0, "it Benights whoever it touches")
	for _, entry in zone.Hazards do
		local settings = Hazards.settings(entry)
		if settings.Damage then
			assert(settings.Damage >= 100, settings.Type .. " kills")
		end
	end
	-- Rocks fall in turn, each warned first (time going on from the Gloom's).
	local seen = {}
	for t = 42, 50, 0.1 do
		HazardService._step(t, 0.1)
		for _, part in folder:GetChildren() do
			if part.Name == "RockfallShadow" then
				seen[part:GetAttribute("Active")] = true
			end
		end
	end
	assert(seen[true] and seen[false], "rock falls, then doesn't")
	-- (Without a placement, nothing is scattered for a plain zone.)
	Layouts.setActive(tile, { Name = "none", Primitives = {} })
	local empty = Harness.wrap(roblox.Instance.new("Folder"))
	HazardService.start(tile, Config.Zones[tile], empty)
	assert(#empty:GetChildren() == 0, "a plain zone's dangers aren't scattered")
	folder:Destroy()
	Layouts.setActive(tile, nil)
end)

test("layouts dress their ground with decor, and the glowing kinds ward off the Gloom", function()
	local Beach = h.require("Shared/Beach")
	local Decor = h.require("Shared/Decor")
	local Layouts = h.require("Shared/Layouts")
	local DecorService = h.require("Server/DecorService")
	local tile = 6
	local layout = {
		Name = "dressed",
		Primitives = { { Kind = "Wall", Path = { { -300, 300 }, { -100, 300 } }, Width = 16, Height = 20 } },
		Decor = {
			{ Kind = "LanternPost", At = { 0, 100 } },
			{ Kind = "Kelp", Area = { { 50, 50 }, { 150, 50 }, { 150, 150 }, { 50, 150 } }, Count = 10 },
			{ Kind = "Pebbles", Path = { { -300, 300 }, { -100, 300 } }, Count = 6 }, -- on the wall: none
			{ Kind = "Barnacles", At = { -200, 300 } }, -- barnacles may stand on rock
		},
	}
	local problems = Layouts.problems(layout)
	assert(#problems == 0, table.concat(problems, "; "))
	for kind in Decor.Kinds do
		assert(DecorService.Builders[kind], "a builder for " .. kind)
	end
	Layouts.setActive(tile, layout)
	local folder = DecorService.build(tile)
	local counts = {}
	for _, model in folder:GetChildren() do
		counts[model.Name] = (counts[model.Name] or 0) + 1
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				assert(not p.CanCollide and not p.CanQuery, model.Name .. " is only for looks")
			end
		end
	end
	assert(counts.LanternPost == 1 and counts.Kelp == 10, "one lantern, ten kelp")
	assert(counts.Pebbles == nil and counts.Barnacles == 1, "nothing on the wall but barnacles")
	local wards = 0
	for _, ward in folder:GetDescendants() do
		if ward.Name == "Ward" and (ward:GetAttribute("WardRadius") or 0) > 0 then
			wards += 1
		end
	end
	assert(wards == 1, "the lantern wards off the Gloom")
	local before = #folder:GetChildren()
	local again = DecorService.build(tile)
	assert(#again:GetChildren() == before, "the same layout, the same decor")
	assert(
		#Layouts.problems({ Name = "x", Primitives = {}, Decor = { { Kind = "Gnome", At = { 0, 0 } } } }) > 0,
		"unknown kinds are problems"
	)
	Layouts.setActive(tile, nil)
	DecorService.build(tile)
end)

test("paths through a zone: counted, timed, and rated for the cart sizes that fit", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local PathCheck = require("../paths")
	local tile = 4
	-- Two lanes straight down the zone between rock: one 20 wide, one 9 wide.
	local function rock(x0, x1)
		return { Kind = "Wall", Area = { { x0, -10 }, { x1, -10 }, { x1, 618 }, { x0, 618 } }, Height = 12 }
	end
	Layouts.setActive(tile, {
		Name = "two lanes",
		Primitives = { rock(-400, -60), rock(-40, 30), rock(39, 400) },
	})
	local report = PathCheck.analyse(Beach, Config, tile)
	assert(#report.paths == 2, "two distinct paths, found " .. #report.paths)
	local bySizes = {}
	for _, path in report.paths do
		bySizes[#path.sizes] = path
	end
	assert(bySizes[4], "the wide lane takes every cart, up to Huge")
	local narrow = nil
	for _, path in report.paths do
		if #path.sizes < 4 then
			narrow = path
		end
	end
	-- (Widths are measured on 2-stud cells: to within a couple of studs.)
	assert(
		narrow and narrow.sizes[1] == "Small" and not table.find(narrow.sizes, "Large"),
		"the narrow lane takes small carts, not a Large one"
	)
	assert(report.carts.Huge, "a Huge cart gets down")
	-- Straight down is far too quick for the rules.
	local problems = PathCheck.problems(Config, report, 2, Config.Zones[tile].CrossTime)
	assert(#problems >= 2, "both paths are under the minimum time")
	assert(#PathCheck.problems(Config, report, 3, 20) >= 1, "three were wanted: too few")
	Layouts.setActive(tile, nil)
end)

test("layouts that say how many paths they have, have them", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local PathCheck = require("../paths")
	local failures = {}
	for _, entry in Layouts.all(true) do
		local def, zone = entry.Def, entry.Zone
		local crossing = def.Crossings and def.Crossings[entry.Choice.Crossing]
		local wanted = (crossing and crossing.Paths) or def.Paths
		if wanted then
			Layouts.setActive(zone, def, nil, entry.Choice)
			local report = PathCheck.analyse(Beach, Config, zone)
			for _, problem in PathCheck.problems(Config, report, wanted, Config.Zones[zone].CrossTime) do
				table.insert(failures, entry.Source .. ": " .. problem)
			end
			Layouts.setActive(zone, nil)
		end
	end
	assert(#failures == 0, table.concat(failures, "\n      "))
end)

test("barrels teeter at the top of their gully first, then roll down it", function()
	local Beach = h.require("Shared/Beach")
	local Hazards = h.require("Shared/Hazards")
	local Layouts = h.require("Shared/Layouts")
	local HazardService = h.require("Server/HazardService")
	-- (Tile 1's top is above even high tide: a barrel whose start is under water doesn't come.)
	local tile = 1
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "gully",
		Primitives = {},
		Hazards = { { Type = "Roller", Path = { { 40, 20 }, { 40, 300 } } } },
	})
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	HazardService.start(tile, { Hazards = { { Type = "Roller" } } }, folder)
	local settings = Hazards.settings({ Type = "Roller" })
	local base = os.clock() + settings.Period + 0.1 -- (the first comes within a Period)
	HazardService._step(base, 0.1)
	local barrel = folder:FindFirstChild("Roller")
	assert(barrel and barrel:GetAttribute("Active") == false, "it teeters first, harmless")
	assert(math.abs(barrel.CFrame.Z - (z0 + 20)) < 1, "at the top of its gully")
	HazardService._step(base + settings.Warning + 0.5, 0.5)
	assert(barrel:GetAttribute("Active") == true, "then it rolls, and bowls you over")
	assert(barrel.CFrame.Z > z0 + 25 and math.abs(barrel.CFrame.X - 40) < 0.5, "down its gully")
	assert(settings.Effect == "Knockdown" and settings.Warning >= 1.5, "tumbling, after a fair warning")
	folder:Destroy()
	Layouts.setActive(tile, nil)
end)

test("the giant crab takes the longest crab route, and is deadly but can be outrun", function()
	local Beach = h.require("Shared/Beach")
	local Hazards = h.require("Shared/Hazards")
	local Layouts = h.require("Shared/Layouts")
	local HazardService = h.require("Server/HazardService")
	local tile = 4
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "lair",
		Primitives = {},
		Hazards = {
			{ Type = "Patrol", Path = { { -100, 100 }, { 100, 100 } } },
			{ Type = "Patrol", Path = { { -50, 300 }, { -40, 300 } } },
		},
	})
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	HazardService.start(tile, { Hazards = { { Type = "Hunter" } } }, folder)
	local hunter = folder:FindFirstChild("Hunter")
	assert(hunter, "a hunter on the longest crab route")
	-- (It starts where its route starts; Lune's models can't be moved, so the hunting itself is
	-- checked in the engine.)
	local body = hunter:FindFirstChild("Body")
	assert(math.abs(body.CFrame.X + 100) < 1 and math.abs(body.CFrame.Z - (z0 + 100)) < 1, "on its route")
	local settings = Hazards.settings({ Type = "Hunter" })
	assert(settings.Damage >= 100 and settings.ChaseSpeed < 20, "deadly, but a running player can outpace it")
	assert(settings.SightAngle < 360, "it can't see behind it")
	-- Its moves are telegraphed: it rears up before a dash, and where it'll come up shakes and
	-- spurts sand for a while before it does; a patrol crab drums before it calls.
	assert(settings.DashWarn >= 0.5 and settings.DashRecover >= 1, "the dash: rear up first, stand after")
	assert(settings.DigTime + settings.UnderTime >= 2, "the dig: its way up shows for 2 s at least")
	assert(Hazards.settings({ Type = "Patrol" }).CallTime >= 1.5, "a call: drumming first")
	local holes = 0
	for _, part in folder:GetChildren() do
		if part.Name == "BurrowHole" then
			holes += 1
		end
	end
	assert(holes == 2, "burrow holes: its tunnels' ends (and junctions), without Burrows of its own")
	-- Its tunnels are a maze it knows: a cross of two runs meeting in the middle, and the way
	-- from one arm to another goes through the junction, turning there.
	local V2 = roblox.Vector2.new
	local maze = HazardService._tunnels({
		{ V2(0, 0), V2(100, 0) },
		{ V2(50, -50), V2(50, 50) },
	})
	assert(#maze.nodes == 5 and #maze.edges == 4, "two runs crossing make a junction and four arms")
	local from = maze.nearest(V2(10, 0))
	local to = maze.nearest(V2(50, 40))
	local endNode, cost = maze.toward(from, to)
	assert((maze.nodes[endNode] - V2(50, 0)).Magnitude < 1e-6, "it heads for the junction")
	assert(math.abs(cost - 80) < 1e-6, "40 to the junction, 40 up the other arm")
	-- It keeps to its route like a rail: an L-shaped route, 100 along X then 50 along Z.
	local V2 = roblox.Vector2.new
	local route = HazardService._rail({ V2(0, 0), V2(100, 0), V2(100, 50) })
	assert(math.abs(route.length - 150) < 1e-6, "the route's length")
	local at, way = route.at(120)
	assert((at - V2(100, 20)).Magnitude < 1e-6 and (way - V2(0, 1)).Magnitude < 1e-6, "a point along it")
	assert(math.abs(route.nearest(V2(40, -30)) - 40) < 1e-6, "someone beside the first leg")
	assert(math.abs(route.nearest(V2(130, 35)) - 135) < 1e-6, "someone beside the second leg")
	assert(math.abs(route.nearest(V2(-50, 5))) < 1e-6, "someone past its start: it waits at the end")
	folder:Destroy()
	Layouts.setActive(tile, nil)
end)

test("roofs make caves: rock overhead, the floor still the ground", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local TerrainBuilder = h.require("Server/TerrainBuilder")
	local tile = 4
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "tunnel",
		Primitives = {
			{ Kind = "Roof", Path = { { -40, 75 }, { 40, 75 } }, Width = 20, Clearance = 10, Thickness = 6 },
		},
	})
	local z = z0 + 75
	local bottom, top = Beach.roofAt(0, z)
	local slope = Beach.groundY(z)
	assert(
		bottom and math.abs(bottom - (slope + 10)) < 0.01 and math.abs((top :: number) - (slope + 16)) < 0.01,
		"underside and top"
	)
	assert(Beach.roofAt(0, z + 20) == nil and Beach.roofAt(80, z) == nil, "open sky beside it")
	assert(Beach.groundAt(0, z) == slope, "the floor is still the ground")
	assert(not Beach.isRough(z) or Beach.feature(0, z) == 0, "a roof isn't ground shape")
	-- A ray from above, looking for the ground under someone in the tunnel, starts under the roof.
	local start = Beach.rayFrom(roblox.Vector3.new(0, slope + 3, z), 30)
	assert(start.Y < (bottom :: number), "under the roof")
	assert(
		Beach.rayFrom(roblox.Vector3.new(0, slope + 20, z), 30).Y > (top :: number),
		"but not for someone on top of it"
	)
	-- The terrain: sand floor, air, then rock.
	local zA = math.floor(z / 4) * 4
	local yLow, yHigh = TerrainBuilder.heightRange(zA, zA + 4)
	local materials, occupancy = TerrainBuilder.slab(
		roblox.Vector3.new(-2, yLow, zA),
		roblox.Vector3.new(2, yHigh, zA + 4),
		zA,
		zA + 4
	)
	-- (Roblox draws solid terrain 2 studs bigger all round, so the 6-stud roof is written 2 thick.)
	local solid, air, rock = 0, 0, 0
	for iy = 1, #occupancy[1] do
		local cellBottom = yLow + (iy - 1) * 4
		if cellBottom > slope + 1 and cellBottom + 4 < slope + 9 then
			air += if occupancy[1][iy][1] == 0 then 1 else 0
		end
		if cellBottom + 4 > slope + 10 and cellBottom < slope + 16 then
			solid += occupancy[1][iy][1] * 4
			rock += if materials[1][iy][1] == roblox.Enum.Material.Slate then 1 else 0
		end
	end
	assert(air >= 1, "room to walk under it")
	assert(math.abs(solid - 2) < 0.01 and rock >= 1, "rock overhead, written 2 thick: " .. solid)
	Layouts.setActive(tile, nil)
	local function problems(roof)
		return #Layouts.problems({ Name = "x", Primitives = { roof } })
	end
	assert(
		problems({ Kind = "Roof", At = { 0, 0 }, Radius = 20, Clearance = 10, Thickness = 6 }) == 0,
		"a chamber"
	)
	assert(
		problems({ Kind = "Roof", At = { 0, 0 }, Width = 20, Clearance = 10, Thickness = 6 }) > 0,
		"needs a shape"
	)
	assert(
		problems({ Kind = "Roof", At = { 0, 0 }, Radius = 20, Clearance = 4, Thickness = 6 }) > 0,
		"too low to walk under"
	)
	assert(
		problems({ Kind = "Roof", At = { 0, 0 }, Radius = 20, Clearance = 30, Thickness = 6 }) > 0,
		"too high"
	)
end)

test("hazards are data: kinds, settings and problems", function()
	local Hazards = h.require("Shared/Hazards")
	local settings = Hazards.settings({ Type = "Patrol", Count = 7 })
	assert(settings.Count == 7 and settings.Speed == Hazards.Types.Patrol.Speed, "entries override defaults")
	assert(#Hazards.problems({ Type = "Patrol", Count = 2 }, "x") == 0, "a good entry")
	assert(#Hazards.problems({ Type = "Volcano" }, "x") > 0, "an unknown kind")
	assert(#Hazards.problems({ Type = "Pulse", Speed = 3 }, "x") > 0, "a setting the kind doesn't have")
	assert(#Hazards.problems({ Type = "Pulse", Period = "soon" }, "x") > 0, "a setting of the wrong type")
	assert(#Hazards.problems({ Type = "Slow", Effect = "Explode" }, "x") > 0, "an unknown effect")
end)

test("patrols walk their route back and forth", function()
	local HazardService = h.require("Server/HazardService")
	local path = { roblox.Vector2.new(0, 0), roblox.Vector2.new(10, 0), roblox.Vector2.new(10, 10) }
	local function near(a, b)
		return (a - b).Magnitude < 1e-6
	end
	local at, heading = HazardService.alongPath(path, 5)
	assert(
		near(at, roblox.Vector2.new(5, 0)) and near(heading, roblox.Vector2.new(1, 0)),
		"out along the first leg"
	)
	at = HazardService.alongPath(path, 15)
	assert(near(at, roblox.Vector2.new(10, 5)), "round the corner")
	at, heading = HazardService.alongPath(path, 25)
	assert(near(at, roblox.Vector2.new(10, 5)) and near(heading, roblox.Vector2.new(0, -1)), "and back again")
	at = HazardService.alongPath(path, 40)
	assert(near(at, roblox.Vector2.new(0, 0)), "home after twice the route")
end)

test("a hazard reaches you within its radius, at about your height", function()
	local HazardController = h.require("Client/HazardController")
	local part = Harness.wrap(roblox.Instance.new("Part"))
	part.Position = roblox.Vector3.new(0, 0, 0)
	part:SetAttribute("HitRadius", 3)
	assert(HazardController.reaches(part, roblox.Vector3.new(4, 2, 0)), "3 + the body's width")
	assert(not HazardController.reaches(part, roblox.Vector3.new(6, 2, 0)), "too far across")
	assert(not HazardController.reaches(part, roblox.Vector3.new(1, 12, 0)), "too far above")
end)

test("layouts place loot, entrances and hazards", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local layout = {
		Name = "placed",
		Primitives = {},
		Loot = { { At = { 10, 40 }, Radius = 8 }, { At = { -50, 90 }, Radius = 6, Weight = 3 } },
		Entrances = { { 100, 30 } },
		Hazards = {
			{ Type = "Patrol", Path = { { 0, 20 }, { 0, 120 } }, Count = 2 },
			{ Type = "Pulse", At = { 60, 75 } },
		},
	}
	assert(#Layouts.problems(layout) == 0, table.concat(Layouts.problems(layout), "; "))
	local tile = 2
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, layout)
	local loot = Layouts.lootSpots(tile, z0)
	assert(#loot == 2 and loot[1].Z == z0 + 40 and loot[2].Weight == 3, "loot spots in world Z")
	assert(Layouts.entrances(tile, z0)[1].Y == z0 + 30, "entrances too")
	assert(#Layouts.hazardPlacements(tile, "Patrol") == 1, "hazards by kind")
	assert(#Layouts.hazardPlacements(tile, "Roller") == 0, "none of a kind it doesn't place")
	Layouts.setActive(tile, nil)
	local bad = {
		Name = "bad",
		Primitives = {},
		Loot = { { At = { 1, 2 } } },
		Hazards = { { Type = "Pulse", Path = { { 0, 0 }, { 1, 1 } } } },
		Extra = true,
	}
	assert(#Layouts.problems(bad) == 3, "catches a radius-less spot, a misplaced field and an unknown field")
end)

test("biomes roll only in their zones", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Biomes = h.require("Shared/Biomes")
	for tile = 1, Beach.ActiveTiles do
		local zone = Beach.zoneOfTile(tile)
		local weights = BiomeService.weightsFor(tile)
		assert(Config.Biomes.Chance[zone] < 1, "a zone can always come up without a biome")
		for id, biome in Biomes.List do
			local expected = biome.Zones[zone]
			assert(weights[id] == expected, id .. " in zone " .. zone)
		end
	end
	assert(BiomeService.weightsFor(1).HermitHollows == nil, "no hermit crabs by the shop")
	assert(BiomeService.weightsFor(Beach.ActiveTiles).HermitHollows, "but out in the Drowned Reach")
	-- A tide: each biome at most once, and usually one or two in all.
	-- (A stand-in for Roblox's Random, which Lune hasn't got.)
	math.randomseed(7)
	local random = {
		NextNumber = function()
			return math.random()
		end,
		NextInteger = function(_, low, high)
			return math.random(low, high)
		end,
	} :: any
	local total, tides = 0, 2000
	for _ = 1, tides do
		local seen = {}
		for _, id in BiomeService.pick(random) do
			assert(not seen[id], "each biome at most once a tide")
			seen[id] = true
			total += 1
		end
	end
	local average = total / tides
	assert(average >= 1 and average <= 2, "about one or two biomes a tide, not " .. average)
end)

test("cart ramps keep clear of the rock pools' rocks", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local problems = {}
	for _, entry in Layouts.all(true) do
		local z0 = 0 -- pools and paths both in tile coordinates
		for _, p in entry.Layout.Primitives do
			if p.Kind == "Ramp" then
				for _, pool in poolsOnZone(Beach, entry.Zone) do
					-- The rocks stand on a ring of pool.Radius, about 2 studs either side of it.
					local clear = pool.Radius + 2 + p.Width / 2
					for i = 1, #p.Path - 1 do
						local a, b = p.Path[i], p.Path[i + 1]
						for t = 0, 1, 0.02 do
							local x = a[1] + (b[1] - a[1]) * t
							local z = z0 + a[2] + (b[2] - a[2]) * t
							if math.sqrt((x - pool.X) ^ 2 + (z - pool.Z) ^ 2) < clear then
								table.insert(
									problems,
									entry.Source
										.. " zone "
										.. entry.Zone
										.. ": a ramp runs into the pool at "
										.. pool.X
										.. ", "
										.. pool.Z
								)
								break
							end
						end
					end
				end
			end
		end
	end
	assert(#problems == 0, table.concat(problems, "\n      "))
end)

test("jellyfish: stranded ones glow as far as they sting, drifting ones follow their path", function()
	local Beach = h.require("Shared/Beach")
	local Hazards = h.require("Shared/Hazards")
	local Layouts = h.require("Shared/Layouts")
	local HazardService = h.require("Server/HazardService")
	local tile = 3
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "lagoon",
		Primitives = {},
		Hazards = {
			{ Type = "Jelly", At = { 50, 100 }, Radius = 5, Damage = 10 },
			{ Type = "Jelly", Path = { { -100, 200 }, { -40, 200 } } },
		},
	})
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	HazardService.start(tile, { Hazards = { { Type = "Jelly" } } }, folder)
	local settings = Hazards.settings({ Type = "Jelly" })
	local glow, bell
	for _, part in folder:GetChildren() do
		if part.Name == "JellyGlow" then
			glow = part
		elseif part.Name == "JellyBell" and part:GetAttribute("Effect") then
			bell = part
		end
	end
	assert(glow and glow:GetAttribute("Effect") == "Sting", "a stranded jelly stings")
	assert(glow:GetAttribute("HitRadius") == 5 and glow.Size.Y == 10, "its glow shows its reach")
	assert(glow:GetAttribute("Damage") == 10, "the placement's Damage")
	assert(math.abs(glow.CFrame.Z - (z0 + 100)) < 1, "on the sand where it was put")
	assert(glow:GetAttribute("Stun") == settings.Stun and settings.Stun > 0, "a stun in the deep")
	assert(settings.StunZone >= 5 and settings.Damage < 100, "not deadly itself, stuns only deep")
	assert(bell and bell:GetAttribute("Damage") == settings.Damage, "a drifting jelly stings too")
	local before = bell.CFrame.X
	HazardService._step(os.clock() + 4, 0.1)
	assert(
		bell.CFrame.X ~= before and bell.CFrame.X >= -101 and bell.CFrame.X <= -39,
		"it drifts along its path"
	)
	assert(bell.Transparency > 0 and bell.Material == roblox.Enum.Material.Neon, "translucent and glowing")
	folder:Destroy()
	Layouts.setActive(tile, nil)
end)

test("spearstone fields glow and crack first, then shoot up, in the pattern they're given", function()
	local Beach = h.require("Shared/Beach")
	local Hazards = h.require("Shared/Hazards")
	local Layouts = h.require("Shared/Layouts")
	local HazardService = h.require("Server/HazardService")
	local tile = 3
	local settings = Hazards.settings({ Type = "Spears" })
	assert(settings.Warning >= 0.8 and settings.Warning + settings.Active < settings.Period, "a fair rhythm")
	-- How many plates are live (spear up) / warned (cracks showing) at a time, for a pattern.
	local function field(pattern: string, damage: number?)
		Layouts.setActive(tile, {
			Name = "reef",
			Primitives = {},
			Hazards = {
				{ Type = "Spears", At = { 0, 200 }, Radius = 12, Pattern = pattern, Damage = damage },
			},
		})
		local folder = Harness.wrap(roblox.Instance.new("Folder"))
		HazardService.start(tile, { Hazards = { { Type = "Spears" } } }, folder)
		local plates = {}
		for _, part in folder:GetChildren() do
			if part.Name == "SpearPlate" then
				table.insert(plates, part)
			end
		end
		Layouts.setActive(tile, nil)
		return folder, plates
	end
	local function live(plates, now: number): number
		HazardService._step(now, 0.1)
		local count = 0
		for _, plate in plates do
			if plate:GetAttribute("Active") == true then
				count += 1
			end
		end
		return count
	end
	local base = 400 -- (a multiple of every Period)
	local folder, plates = field("Wave", 30)
	assert(#plates > 10 and plates[1]:GetAttribute("Effect") == "Harm", "a field of harming plates")
	assert(plates[1]:GetAttribute("Damage") == 30, "the placement's Damage overrides the setting")
	local z0 = Beach.tileRange(tile)
	assert(math.abs(plates[1].CFrame.Z - (z0 + 200)) <= 13, "where the field was put")
	-- Telegraph: before a spot fires it glows and its cracks show; it's harmless till then.
	local warned = false
	HazardService._step(base + settings.Period - settings.Warning + 0.1, 0.1)
	for _, crack in folder:GetChildren() do
		if crack.Name == "SpearCrack" and crack.Transparency < 1 then
			warned = true
			break
		end
	end
	assert(warned, "cracks show before a spear shoots up")
	assert(
		live(plates, base + settings.Period - settings.Warning + 0.1) < #plates,
		"not all at once in a wave"
	)
	local seen, most = 0, 0
	for t = 0, settings.Period, 0.1 do
		local n = live(plates, base + t)
		seen += if n > 0 then 1 else 0
		most = math.max(most, n)
	end
	assert(seen > 0 and most < #plates, "a wave rolls across: a few live at a time")
	folder:Destroy()
	-- Checker: half the squares, then the other half.
	folder, plates = field("Checker")
	local first = live(plates, base)
	local second = live(plates, base + settings.Period / 2)
	assert(first > 0 and second > 0 and first + second == #plates, "alternating squares")
	folder:Destroy()
	-- All: every spot together. Ring: not.
	folder, plates = field("All")
	assert(live(plates, base) == #plates, "all together")
	folder:Destroy()
	folder, plates = field("Ring")
	assert(live(plates, base) > 0 and live(plates, base) < #plates, "rings from the middle out")
	folder:Destroy()
end)

test("a whirlwind circles its loop, a tall column of sand that flings but doesn't harm", function()
	local Beach = h.require("Shared/Beach")
	local Hazards = h.require("Shared/Hazards")
	local Layouts = h.require("Shared/Layouts")
	local HazardService = h.require("Server/HazardService")
	local tile = 3
	local z0 = Beach.tileRange(tile)
	local loop = { { -40, 100 }, { 40, 100 }, { 40, 180 }, { -40, 180 } }
	Layouts.setActive(tile, {
		Name = "dunes",
		Primitives = {},
		Hazards = { { Type = "Whirlwind", Path = loop, Radius = 8 } },
	})
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	HazardService.start(tile, { Hazards = { { Type = "Whirlwind" } } }, folder)
	local settings = Hazards.settings({ Type = "Whirlwind" })
	local foot = folder:FindFirstChild("Whirlwind")
	assert(foot and foot:GetAttribute("Effect") == "Fling", "a whirlwind that flings")
	assert(foot:GetAttribute("HitRadius") == 8, "the placement's radius")
	assert(foot:GetAttribute("Damage") == nil and settings.Push > 0, "flung, not hurt")
	local tops, layers = 0, 0
	for _, part in folder:GetChildren() do
		if part.Name == "WhirlwindSand" then
			layers += 1
			tops = math.max(tops, part.CFrame.Y - foot.CFrame.Y)
		end
	end
	assert(layers >= 4 and tops >= 30, "a column of sand you can see from far off")
	-- It goes round the loop (never off it) and comes back to where it began.
	local perimeter = 80 + 80 + 80 + 80
	local now = os.clock()
	for t = 0, 40, 1 do
		HazardService._step(now + t, 0.1)
		local x, z = foot.CFrame.X, foot.CFrame.Z - z0
		assert(
			math.abs(x) <= 41
				and z >= 99
				and z <= 181
				and (math.abs(math.abs(x) - 40) < 1 or math.abs(z - 140) > 39),
			"on its loop at " .. t
		)
	end
	local startX, startZ = nil, nil
	HazardService._step(now, 0.1)
	startX, startZ = foot.CFrame.X, foot.CFrame.Z
	HazardService._step(now + perimeter / settings.Speed, 0.1)
	assert(
		math.abs(foot.CFrame.X - startX) < 1 and math.abs(foot.CFrame.Z - startZ) < 1,
		"round and round, not back and forth"
	)
	folder:Destroy()
	Layouts.setActive(tile, nil)
end)

test("ice patches are flat, pale and slippery but leave you some grip, and harm nothing", function()
	local Beach = h.require("Shared/Beach")
	local Hazards = h.require("Shared/Hazards")
	local Layouts = h.require("Shared/Layouts")
	local HazardService = h.require("Server/HazardService")
	local tile = 3
	local z0 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "berg",
		Primitives = {},
		Hazards = { { Type = "Ice", At = { 20, 150 }, Radius = 12 }, { Type = "Ice", At = { -60, 250 } } },
	})
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	HazardService.start(tile, { Hazards = { { Type = "Ice" } } }, folder)
	local settings = Hazards.settings({ Type = "Ice" })
	local patches = {}
	for _, part in folder:GetChildren() do
		if part.Name == "IcePatch" then
			table.insert(patches, part)
		end
	end
	assert(#patches == 2, "a patch for each placement")
	local first = patches[1]
	assert(
		first:GetAttribute("Effect") == "Slide" and first:GetAttribute("HitRadius") == 12,
		"slides, as wide as placed"
	)
	assert(
		math.abs(first.CFrame.X - 20) < 1 and math.abs(first.CFrame.Z - (z0 + 150)) < 1,
		"where it was put"
	)
	assert(patches[2]:GetAttribute("HitRadius") == settings.Radius, "the kind's radius otherwise")
	assert(first.Size.X < 0.5, "flat")
	assert(first.Color.B > first.Color.R and first.Color.R > 0.6, "pale blue-white")
	assert(settings.Grip > 0 and settings.Grip < 0.5, "slippery, but not out of control")
	assert(first:GetAttribute("Grip") == settings.Grip, "the client reads its grip")
	assert(
		first:GetAttribute("Damage") == nil and first:GetAttribute("Spill") == nil,
		"no harm, no cart spilling"
	)
	folder:Destroy()
	Layouts.setActive(tile, nil)
end)

test("a foghorn pulses on its Period: the fog is thick, blinks a warning, then lifts for a while", function()
	local Beach = h.require("Shared/Beach")
	local Hazards = h.require("Shared/Hazards")
	local Layouts = h.require("Shared/Layouts")
	local HazardService = h.require("Server/HazardService")
	local tile = 3
	local z0, z1 = Beach.tileRange(tile)
	Layouts.setActive(tile, {
		Name = "fogbank",
		Primitives = {},
		Hazards = { { Type = "Fog", At = { 30, 120 } } },
	})
	local folder = Harness.wrap(roblox.Instance.new("Folder"))
	HazardService.start(tile, { Hazards = { { Type = "Fog" } } }, folder)
	local settings = Hazards.settings({ Type = "Fog" })
	local horn, lamp, ring, tower
	for _, part in folder:GetChildren() do
		if part.Name == "Foghorn" then
			horn = part
		elseif part.Name == "FoghornLamp" then
			lamp = part
		elseif part.Name == "FoghornRing" then
			ring = part
		elseif part.Name == "FoghornTower" then
			tower = part
		end
	end
	assert(horn and horn:GetAttribute("Effect") == "Fog", "a foghorn the client can find")
	assert(
		tower and math.abs(tower.CFrame.X - 30) < 1 and math.abs(tower.CFrame.Z - (z0 + 120)) < 1,
		"where it was put"
	)
	assert(horn:GetAttribute("ZMin") == z0 and horn:GetAttribute("ZMax") == z1, "it covers its tile")
	assert(
		horn:GetAttribute("Sight") == settings.Sight and settings.Sight <= 20,
		"the fog closes in to a few studs"
	)
	assert(
		settings.Clear >= 3 and settings.Clear < settings.Period / 2,
		"a pulse clears it for a while, not for good"
	)
	assert(
		settings.Effect == "Fog" and settings.HitRadius == 0 and not settings.Lantern,
		"it hits no one; no lantern"
	)
	local base = settings.Period * 40 -- (a multiple of the Period: a pulse starts)
	HazardService._step(base + 0.1, 0.1)
	assert(
		horn:GetAttribute("Clearing") == true and ring.Transparency < 1,
		"the pulse: a ring of light, the fog lifting"
	)
	HazardService._step(base + settings.Clear + 0.5, 0.1)
	assert(horn:GetAttribute("Clearing") == false and ring.Transparency == 1, "then the fog closes in again")
	-- The lamp blinks before the next pulse.
	local lit, dark = false, false
	for t = 0, 1.9, 0.05 do
		HazardService._step(base + settings.Period - 1.9 + t, 0.05)
		lit = lit or lamp.Transparency < 0.5
		dark = dark or lamp.Transparency > 0.5
	end
	assert(lit and dark, "the lamp blinks as the horn is about to sound")
	HazardService._step(base + settings.Period + 0.1, 0.1)
	assert(horn:GetAttribute("Clearing") == true, "and the next pulse comes on time")
	folder:Destroy()
	Layouts.setActive(tile, nil)
end)

-- Every biome of the initial build has its own secret: its unlock item drops on the beach, there
-- is an opening in the biome, and using the item there leads into a room with a chest.
local SECRET_BIOMES = {
	"DriftwoodCove",
	"TidepoolRocks",
	"SeagrassShallows",
	"CoralGarden",
	"FogBank",
	"WhirlwindDunes",
	"HermitHollows",
	"SpearstoneReef",
	"JellyfishLagoon",
	"StrandedIceberg",
}

test("secret: every in-build biome has an unlock item, an opening builder and a secret", function()
	local Items = h.require("Shared/Items")
	local Catalog = h.require("Shared/Catalog")
	local Biomes = h.require("Shared/Biomes")
	local Secrets = h.require("Shared/Secrets")
	for id, biome in Biomes.List do
		assert(biome.UnlockItem and Items.get(biome.UnlockItem), id .. " has no unlock item")
		assert(biome.Secret and Secrets.List[biome.Secret], id .. " has no secret")
		assert(Secrets.List[biome.Secret].Unlock == biome.UnlockItem, id .. ": the secret wants another item")
		assert(BiomeService._entranceBuilders[biome.Entrance], id .. " has no entrance builder")
		assert(type(biome.EntranceName) == "string", id .. " has no prompt text")
	end
	for _, id in SECRET_BIOMES do
		local secret = Secrets.List[Biomes.List[id].Secret]
		assert(Secrets.isRoom(secret), id .. "'s secret is a room")
		assert(secret.Coin or secret.Loot, id .. "'s chest holds nothing")
		for _, entry in secret.Loot or {} do
			assert(Catalog.get(entry.Id), id .. ": " .. entry.Id .. " isn't an item")
		end
	end
end)

test("the first zones wash up mostly light things, which bare hands lift", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Gear = h.require("Shared/Gear")
	local ItemService = h.require("Server/ItemService")
	local z = Beach.tileRange(1) + 100
	local zoneIndex = Beach.zoneAt(z) :: number
	assert(Config.Zones[zoneIndex].LightShare > 0.5, "zone 1 favours light things")
	for _ = 1, 50 do
		local def = ItemService._chooseDef(zoneIndex, z, false, 1, true)
		assert(
			def and def.Class == Gear.WeightClass.Light,
			"a light pick is light: " .. tostring(def and def.Id)
		)
	end
end)

test("unlock: every in-build biome's unlock item can wash up in its own tile, and only there", function()
	local Beach = h.require("Shared/Beach")
	local Biomes = h.require("Shared/Biomes")
	local Config = h.require("Shared/Config")
	local ItemService = h.require("Server/ItemService")
	local workspace = h.game.Workspace
	local tile = 2
	local z = Beach.tileRange(tile) + 100
	local zoneIndex = Beach.zoneAt(z) :: number
	local chance, exotic = Config.Unlocks.SpawnChance, Config.Unlocks.ExoticSpawnChance
	local maxOnMap = Config.Unlocks.MaxOnMap
	Config.Unlocks.SpawnChance, Config.Unlocks.ExoticSpawnChance = 1, 1
	-- (Earlier tests may have left one on the map, which would stop another spawning.)
	Config.Unlocks.MaxOnMap = math.huge
	for id, biome in Biomes.List do
		workspace:SetAttribute(Biomes.attributeFor(tile), id)
		local def = ItemService._chooseDef(zoneIndex, z, nil, 1)
		assert(
			def and def.Id == biome.UnlockItem,
			id .. ": its unlock item can't spawn (got " .. tostring(def and def.Id) .. ")"
		)
	end
	workspace:SetAttribute(Biomes.attributeFor(tile), nil)
	Config.Unlocks.MaxOnMap = maxOnMap
	Config.Unlocks.SpawnChance, Config.Unlocks.ExoticSpawnChance = chance, exotic
end)

test("entrance: every way each in-build biome can come out has a door in clear ground", function()
	local Beach = h.require("Shared/Beach")
	local Biomes = h.require("Shared/Biomes")
	local Layouts = h.require("Shared/Layouts")
	local FOOT, STEP, FLAT = 10, 2.5, 3
	local problems = {}
	for _, id in SECRET_BIOMES do
		for zone in Biomes.List[id].Zones do
			local def = Layouts.forBiome(id, zone)
			if not def then
				table.insert(problems, id .. " has no layout in zone " .. zone)
				continue
			end
			local z0 = Beach.tileRange(zone)
			for _, way in Layouts.options(def) do
				local where = id .. " zone " .. zone .. " " .. way.Label
				local spots = Layouts.compose(def, way.Choice).Entrances or {}
				if #spots == 0 then
					table.insert(problems, where .. ": no door")
				end
				Layouts.setActive(zone, id, zone, way.Choice)
				for _, at in spots do
					local low, high = math.huge, -math.huge
					local clear = true
					for ix = -FOOT // STEP, FOOT // STEP do
						for iz = -FOOT // STEP, FOOT // STEP do
							local px, pz = at[1] + ix * STEP, z0 + at[2] + iz * STEP
							local _, rock = Beach.shapeAt(px, pz)
							if rock or Beach.roofAt(px, pz) then
								clear = false
							end
							local y = Beach.groundAt(px, pz)
							low, high = math.min(low, y), math.max(high, y)
						end
					end
					if not clear or high - low > FLAT then
						table.insert(
							problems,
							string.format(
								"%s: the door at (%d, %d) is on rock, under a roof or on uneven ground",
								where,
								at[1],
								at[2]
							)
						)
					end
				end
				Layouts.setActive(zone, nil)
			end
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

test("entrance: a door stands by its tier's chance, and the item spawns either way", function()
	local Biomes = h.require("Shared/Biomes")
	local Config = h.require("Shared/Config")
	for tier, chance in Config.Secrets.DoorChance do
		assert(chance > 0 and chance < 1, tier .. " needs a chance between 0 and 1")
	end
	assert(
		Config.Secrets.DoorChance.Common < Config.Secrets.DoorChance.Uncommon,
		"rarer biomes' doors stand more often"
	)
	assert(
		Config.Secrets.DoorChance.Uncommon < Config.Secrets.DoorChance.Rare,
		"rarer biomes' doors stand more often"
	)
	assert(
		Config.Secrets.DoorChance.Rare < Config.Secrets.DoorChance.VeryRare,
		"rarer biomes' doors stand more often"
	)
	for id, biome in Biomes.List do
		assert(Config.Secrets.DoorChance[biome.Tier], id .. "'s tier has no door chance")
	end
	for _, id in { "DriftwoodCove", "FogBank", "HermitHollows", "StrandedIceberg" } do
		local biome = Biomes.List[id]
		local want = Config.Secrets.DoorChance[biome.Tier]
		local stood, rolls = 0, 4000
		for _ = 1, rolls do
			if BiomeService._doorStands(biome) then
				stood += 1
			end
		end
		assert(
			math.abs(stood / rolls - want) < 0.05,
			string.format("%s: the door stood %.2f of the time, not %.2f", id, stood / rolls, want)
		)
	end
	-- A failed roll builds nothing; a forced build always stands (the roll is the only gate).
	local Layouts = h.require("Shared/Layouts")
	local zone = 1
	local biome = Biomes.List.DriftwoodCove
	Layouts.setActive(zone, "DriftwoodCove", zone)
	local built = 0
	for _ = 1, 200 do
		local folder = Harness.wrap(roblox.Instance.new("Folder"))
		BiomeService._buildEntrance(folder, biome, zone)
		if folder:FindFirstChild("SecretEntrance") then
			built += 1
		end
	end
	Layouts.setActive(zone, nil)
	assert(built > 40 and built < 160, "about half of 200 common biomes got a door, got " .. built)
end)

test("secret: a room run claims its chest, and a claim from away from it is rejected", function()
	local Secrets = h.require("Shared/Secrets")
	local SecretService = h.require("Server/SecretService")
	local Vector3 = roblox.Vector3
	for _, id in SECRET_BIOMES do
		local secret = Secrets.List[id]
		local course = secret.Course
		assert(Secrets.isRoom(secret) and #course.Checkpoints == 0, id .. " isn't a room without checkpoints")
		local after = course.MinRunTime + 1
		-- Standing at the chest, soon enough and in time: it opens.
		assert(
			SecretService.claimOk(course, course.Chest, 1, after, course.Seconds),
			id .. ": the chest won't open"
		)
		assert(
			SecretService.claimOk(course, course.Chest + Vector3.new(2, 0, 2), 1, after, course.Seconds),
			id .. ": next to the chest"
		)
		-- Where the player arrives, across the room: rejected.
		assert(
			not SecretService.claimOk(course, course.Spawn, 1, after, course.Seconds),
			id .. ": claimed from the spawn"
		)
		assert(
			not SecretService.claimOk(course, course.Chest + Vector3.new(0, 0, 20), 1, after, course.Seconds),
			id .. ": claimed from across the room"
		)
		-- Too fast, or after the time is up: rejected.
		assert(
			not SecretService.claimOk(course, course.Chest, 1, 0.5, course.Seconds),
			id .. ": claimed at once"
		)
		assert(
			not SecretService.claimOk(course, course.Chest, 1, course.Seconds + 5, course.Seconds),
			id .. ": claimed late"
		)
		assert(course.Seconds >= 30, id .. ": the time limit is too short")
		-- The room lasts its limit, never a flood (the water stays far below).
		assert(
			Secrets.floodLevel(course, course.Seconds, course.Seconds) < -1000,
			id .. ": a room doesn't flood"
		)
		-- The reward: its coin, or one of its rewards.
		local rng = {
			NextNumber = function()
				return math.random()
			end,
		} :: any
		if secret.Loot then
			local itemId = Secrets.rollLoot(secret, rng)
			assert(itemId, id .. ": its chest rolled nothing")
		end
	end
	-- A course (the Sandcastle Vault) still needs its checkpoints.
	local vault = Secrets.List.SandcastleFlats.Course
	assert(
		not SecretService.claimOk(vault, vault.Chest, 1, 30, 100),
		"the vault's chest needs its checkpoints"
	)
	assert(
		SecretService.claimOk(vault, vault.Chest, #vault.Checkpoints + 1, 30, 100),
		"the vault's chest opens at the top"
	)
end)

-- Bots (src/server/BotService, BotEconomy, src/shared/Routes) -----------------------------------

test("bot routes avoid rock and walls, and go through the gap", function()
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local Routes = h.require("Shared/Routes")
	local tile = 4
	local z0 = Beach.tileRange(tile)
	-- A wall across the whole beach with one 24-wide gap at x = 200.
	local function wall(x0, x1)
		return {
			Kind = "Wall",
			Area = { { x0, 100 }, { x1, 100 }, { x1, 130 }, { x0, 130 } },
			Height = 14,
		}
	end
	Layouts.setActive(tile, { Name = "gapped", Primitives = { wall(-400, 188), wall(212, 400) } })
	local grid = Routes.new()
	local from, to = { x = 0, z = z0 + 20 }, { x = 0, z = z0 + 220 }
	local path, length = grid:find(from, to, { radius = 4 })
	assert(path, "a way round exists")
	assert(length > 300, "it goes round by the gap, not straight over the wall")
	local through = false
	for _, point in path do
		local _, rock = Beach.shapeAt(point.x, point.z)
		assert(not rock, "never on rock")
		if point.z > z0 + 105 and point.z < z0 + 125 then
			through = true
			assert(point.x > 186 and point.x < 214, "crosses the wall only at the gap")
		end
	end
	assert(through, "it crosses the wall")
	for i = 2, #path do
		local a, b = path[i - 1], path[i]
		local rise = math.abs(Beach.groundAt(b.x, b.z) - Beach.groundAt(a.x, a.z))
		local run = math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
		assert(rise <= Config.Beach.Terrain.FootSlope * run + 1e-6, "no step steeper than a player can climb")
	end
	-- Close the gap: no way at all.
	Layouts.setActive(tile, { Name = "closed", Primitives = { wall(-400, 400) } })
	grid:refresh()
	assert(grid:find(from, to, { radius = 4 }) == nil, "a closed wall has no way through")
	-- Water too deep to stand in blocks the route like rock does.
	Layouts.setActive(tile, nil)
	grid:refresh()
	assert(grid:find(from, to, { radius = 4 }), "open ground again")
	local blocked = function(_x, z)
		return z > z0 + 100 and z < z0 + 130
	end
	assert(grid:find(from, to, { radius = 4, blocked = blocked }) == nil, "deep water blocks a route")
	Layouts.setActive(tile, nil)
end)

test("bot route searches are time-sliced: a hopeless one yields and stays within its bound", function()
	local Beach = h.require("Shared/Beach")
	local Layouts = h.require("Shared/Layouts")
	local Routes = h.require("Shared/Routes")
	local tile = 4
	local z0 = Beach.tileRange(tile)
	-- A goal walled in on every side: no way there, so the search has to give up.
	local function wall(x0, z0w, x1, z1w)
		return { Kind = "Wall", Area = { { x0, z0w }, { x1, z0w }, { x1, z1w }, { x0, z1w } }, Height = 14 }
	end
	Layouts.setActive(tile, {
		Name = "pocket",
		Primitives = {
			wall(-60, 200, 60, 220),
			wall(-60, 300, 60, 320),
			wall(-60, 200, -40, 320),
			wall(40, 200, 60, 320),
		},
	})
	local grid = Routes.new()
	local yields = 0
	local path = grid:find({ x = 0, z = z0 + 20 }, { x = 0, z = z0 + 260 }, {
		radius = 4,
		maxNodes = 3000,
		yieldEvery = 100,
		yield = function()
			yields += 1
		end,
	})
	assert(path == nil, "no way into a walled pocket")
	assert(yields >= 5, "a long search yields (" .. yields .. " times)")
	assert(yields <= 3000 / 100, "and never more than one slice per yieldEvery nodes")
	Layouts.setActive(tile, nil)
end)

test("bot buying rule picks the best income per price, and rebirths first", function()
	local Economy = h.require("Server/BotEconomy")
	local Rebirth = h.require("Shared/Rebirth")
	local state = Economy.newState()
	assert(Economy.nextPurchase(state) == nil, "nothing to buy with no coins")
	for _, coins in { 300, 1700, 6500, 30000, 200000 } do
		state = Economy.newState()
		state.Coins = coins
		local base = Economy.income(state)
		local best, bestRatio
		for _, option in Economy.options(state, false) do
			if option.Price <= coins then
				local ratio = option.Gain / option.Price
				if not bestRatio or ratio > bestRatio then
					best, bestRatio = option, ratio
				end
				-- (the gain is what the purchase really adds)
				local trial = Economy.newState()
				trial.Coins = coins
				if option.Category == "Tool" then
					trial.Tools[option.Id] = true
				else
					trial.Vessels[option.Id] = true
				end
				assert(math.abs(Economy.income(trial) - base - option.Gain) < 1e-6, "gain is income added")
			end
		end
		local pick = Economy.nextPurchase(state)
		assert(
			pick and best and pick.Id == best.Id,
			coins .. " coins: the best income per price is " .. tostring(best and best.Id)
		)
		assert(pick.Price <= coins, "affordable")
	end
	-- The wheelbarrow's price can only buy a wheelbarrow, which is the best buy then.
	state = Economy.newState()
	state.Coins = (h.require("Shared/Gear").getVessel("Wheelbarrow") :: any).Price
	assert(Economy.nextPurchase(state).Id == "Wheelbarrow", "the wheelbarrow first")
	assert(Economy.buy(state, Economy.nextPurchase(state)) and state.Coins == 0, "buying spends the price")
	-- Rebirth: as soon as it's affordable, resets coins and shop gear, adds a pick.
	state = Economy.newState()
	state.Coins = Rebirth.cost(0)
	state.Tools.BoatHook = true
	state.Vessels.Wheelbarrow = true
	assert(Economy.canRebirth(state), "can rebirth at the cost")
	local pick = Economy.rebirth(state)
	assert(pick and state.Rewards[pick], "takes a reward")
	assert(state.Rebirths == 1 and state.Coins == 0, "coins reset")
	assert(not state.Tools.BoatHook and not state.Vessels.Wheelbarrow, "shop gear goes")
	-- It takes the pick that gives most income.
	local options = Rebirth.remaining({})
	local bestIncome, bestId = -1, nil
	for _, id in options do
		local trial = Economy.newState()
		trial.Rebirths = 1
		Economy.grant(trial, id)
		if Economy.income(trial) > bestIncome then
			bestIncome, bestId = Economy.income(trial), id
		end
	end
	assert(pick == bestId, "the most useful reward is " .. tostring(bestId) .. ", took " .. tostring(pick))
end)

test("bot can't claim an item another already claimed", function()
	local Items = h.require("Shared/Items")
	local Gear = h.require("Shared/Gear")
	local ItemService = h.require("Server/ItemService")
	local GrabService = h.require("Server/GrabService")
	local item = ItemService.spawnAt(Items.get("Seashell"), 1, roblox.Vector3.new(0, 0, 100))
	local tool = Gear.getTool("BareHands")
	local near = item.CFrame.Position
	assert(GrabService.canClaim(item, -1, tool, 1, near), "free and in reach")
	assert(not GrabService.canClaim(item, -1, tool, 1, near + roblox.Vector3.new(0, 0, 40)), "out of reach")
	assert(ItemService.claimForBot(item, -1), "the first bot claims it")
	assert(not ItemService.claimForBot(item, -2), "the second can't")
	assert(not GrabService.canClaim(item, -2, tool, 1, near), "and the rules say so too")
	assert(ItemService.getOwnerId(item) == -1, "it stays the first bot's")
	assert(ItemService.stats.ClaimedByBots >= 1, "counted")
	ItemService.destroy(item)
	assert(not ItemService.claimForBot(item, -3), "a destroyed item can't be claimed")
	-- Heavy items need a tool that lifts them.
	local anchor = ItemService.spawnAt(Items.get("TreasureChest"), 1, roblox.Vector3.new(0, 0, 100))
	assert(not GrabService.canClaim(anchor, -1, tool, 1, anchor.CFrame.Position), "too heavy for bare hands")
	ItemService.destroy(anchor)
end)

test("bot state never touches DataService", function()
	local fs = require("@lune/fs")
	local DataService = h.require("Server/DataService")
	local Economy = h.require("Server/BotEconomy")
	local BotService = h.require("Server/BotService")
	local calls = 0
	local originals = {}
	for name, value in DataService do
		if type(value) == "function" then
			originals[name] = value
			DataService[name] = function(...)
				calls += 1
				return value(...)
			end
		end
	end
	local state = Economy.newState()
	Economy.sell(state, 500)
	Economy.buy(state, Economy.nextPurchase(state))
	state.Coins = 1e6
	Economy.rebirth(state)
	BotService.report()
	BotService.snapshot()
	for name, value in originals do
		DataService[name] = value
	end
	assert(calls == 0, "DataService was called " .. calls .. " times")
	-- And the source doesn't use it or DataStores at all (comments aside).
	for _, file in { "src/server/BotService.luau", "src/server/BotEconomy.luau", "src/shared/Routes.luau" } do
		local code = {}
		for line in string.gmatch(fs.readFile(file), "[^\n]+") do
			if not string.match(line, "^%s*%-%-") then
				table.insert(code, line)
			end
		end
		local text = table.concat(code, "\n")
		assert(not string.find(text, "DataService", 1, true), file .. " mentions DataService")
		assert(not string.find(text, "DataStore", 1, true), file .. " mentions a DataStore")
	end
end)

print(string.format("\n%d passed, %d failed", passed, failures))
process.exit(if failures > 0 then 1 else 0)
