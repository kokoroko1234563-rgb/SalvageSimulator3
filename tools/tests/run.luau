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
			BiomeService._buildEntrance(folder, biome, 2)
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
	Layouts.setActive(2, false)
	Layouts.setActive(3, false)
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
	Layouts.setActive(2, nil)
	Layouts.setActive(3, nil)
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
	-- Zones join without a seam, and the shape stays inside the beach.
	Layouts.setActive(2, {
		Name = "edge",
		Primitives = { { Kind = "Ridge", Path = { { -360, 0 }, { 360, 0 } }, Height = 5, Width = 40 } },
	})
	assert(Beach.feature(0, z0) == 0, "the shape fades out at the zone's edge")
	assert(Beach.feature(Beach.HalfWidth, z0 + 2) == 0, "and at the sides")
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
	local lo = roblox.Vector3.new(0, -40, 0)
	local hi = roblox.Vector3.new(8, 12, 0)
	local z0, z1 = 440, 448
	local materials, occupancy = TerrainBuilder.slab(lo, hi, z0, z1)
	-- Column (1, 1): x = 2, z = 442. Sum of occupancy * 4 + bottom = the ground height.
	local filled = 0
	for iy = 1, #occupancy[1] do
		filled += occupancy[1][iy][1] * 4
	end
	local h = Beach.groundAt(2, 442)
	assert(
		math.abs((lo.Y + filled) - h) < 0.01,
		"voxels reach the ground height " .. h .. ", got " .. (lo.Y + filled)
	)
	assert(materials[1][1][1] ~= roblox.Enum.Material.Air, "the bottom is solid")
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
local LAYOUT_COLS = 84 -- grid columns either side of X = 0 (336 studs)
local LAYOUT_UNITS = 6 -- zones tested, one tile each (Config.Beach.ActiveZones)
local LAYOUT_END = LAYOUT_UNITS * 150 - 8 -- the seaward end of the last tested tile
local LAYOUT_ROWS = { -1, LAYOUT_UNITS * 150 / LAYOUT_GRID - 1 } -- z = -4 (the shop side) onward
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
			Layouts.setActive(zone, name, zone)
			local heights = {}
			for iz = LAYOUT_ROWS[1], LAYOUT_ROWS[2] do
				if grid.zoneOfRow[iz] == zone then
					for ix = -LAYOUT_COLS, LAYOUT_COLS do
						heights[layoutKey(ix, iz)] = Beach.groundAt(ix * LAYOUT_GRID, iz * LAYOUT_GRID)
					end
				end
			end
			table.insert(grid.options[zone], { name = name, heights = heights })
			Layouts.setActive(zone, nil)
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

test("every layout keeps a ramp on each side, anchored where the zones join", function()
	local Layouts = h.require("Shared/Layouts")
	local function anchored(p, x)
		local first, last = p.Path[1], p.Path[#p.Path]
		return first[1] == x and first[2] == 0 and last[1] == x and last[2] == 150
	end
	for _, entry in Layouts.all(true) do
		local left, right = false, false
		for _, p in entry.Layout.Primitives do
			if p.Kind == "Ramp" then
				assert(p.Width >= 14, entry.Source .. ": a ramp is at least 14 studs wide")
				left = left or anchored(p, -200)
				right = right or anchored(p, 180)
			end
		end
		assert(
			left and right,
			entry.Source .. " (zone " .. entry.Zone .. "): needs ramps from x = -200 and x = 180"
		)
	end
end)

test("ramps stay within the cart slope and are clear of the ground's shape", function()
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
						assert(
							Beach.feature(x, z) == 0,
							entry.Source .. ": a ramp's centre is clear of shapes"
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
	local Beach = h.require("Shared/Beach")
	local Config = h.require("Shared/Config")
	local grid = layoutGrid()
	local carts, feet = 0, 0
	local combos = 0
	eachLayoutChoice(grid, function(choice)
		combos += 1
		local cart = layoutFlood(grid, choice, Config.Beach.Terrain.CartSlope)
		if layoutReaches(cart, 0, LAYOUT_END) then
			carts += 1
		end
		local foot = layoutFlood(grid, choice, Config.Beach.Terrain.FootSlope)
		if layoutReaches(foot, 0, LAYOUT_END) then
			feet += 1
		end
	end)
	assert(combos > 0, "there are combinations to test")
	assert(carts == combos, carts .. " of " .. combos .. " combinations let a cart reach the sea")
	assert(feet == combos, feet .. " of " .. combos .. " combinations let a player on foot reach the sea")
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
			local biome = Biomes.List[option.name]
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

test("zone 1 is readable from the top, and zones 2 to 4 hide their lower half", function()
	local Config = h.require("Shared/Config")
	local Layouts = h.require("Shared/Layouts")
	local grid = layoutGrid()
	local problems = {}
	for zone = 1, Config.Beach.ActiveZones do
		for _, option in grid.options[zone] do
			Layouts.setActive(zone, option.name, zone)
			local hidden = layoutHidden(zone)
			Layouts.setActive(zone, nil)
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
			if p.Kind == "Wall" then
				walls = true
			else
				table.insert(banks.Primitives, p)
			end
		end
		if walls and entry.Zone < 4 then
			table.insert(problems, entry.Source .. " has walls before zone 4")
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
			Layouts.setActive(zone, option.name, zone)
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
			local biome = Biomes.List[option.name]
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
	for zone = 1, Config.Beach.ActiveZones do
		for id in Biomes.Planned do
			if Layouts.forPlanned(id, zone) then
				-- This zone takes the draft; every other zone keeps its base layout.
				Layouts.setActive(zone, id, zone)
				local option = { name = id, heights = {} }
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
				local byZone = { options = {}, zoneOfRow = grid.zoneOfRow, shop = grid.shop }
				local choice = {}
				for other = 1, Config.Beach.ActiveZones do
					byZone.options[other] = if other == zone then { option } else { grid.options[other][1] }
					choice[other] = 1
				end
				if not layoutReaches(layoutFlood(byZone, choice, cfg.CartSlope), 0, LAYOUT_END) then
					table.insert(problems, label .. ": a cart can't reach the sea")
				end
				if not layoutReaches(layoutFlood(byZone, choice, cfg.FootSlope), 0, LAYOUT_END) then
					table.insert(problems, label .. ": a player on foot can't reach the sea")
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
	local tile = 7
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
		assert(weights.None == Config.Biomes.NoneWeight, "none can always roll")
		for id, biome in Biomes.List do
			local expected = biome.Zones[zone]
			assert(weights[id] == expected, id .. " in zone " .. zone)
		end
	end
	assert(BiomeService.weightsFor(1).HermitHollows == nil, "no hermit crabs by the shop")
	assert(BiomeService.weightsFor(Beach.ActiveTiles).HermitHollows, "but out in the Drowned Reach")
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

print(string.format("\n%d passed, %d failed", passed, failures))
process.exit(if failures > 0 then 1 else 0)
