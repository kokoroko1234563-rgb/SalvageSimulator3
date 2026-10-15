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
		"Traders",
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
			"BeachDressing",
			"Buildings",
			"MapParts",
			"ZoneProps",
			"BiomeModels",
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
			"MonetizationService",
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

-- 10. Paid features: a coin pack is granted exactly once, however often Roblox retries.
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

print(string.format("\n%d passed, %d failed", passed, failures))
process.exit(if failures > 0 then 1 else 0)
