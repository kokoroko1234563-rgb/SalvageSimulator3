-- Checks that the game's data fits together: every reference points at something that
-- exists, and every entry has the fields the code relies on. It runs when the server starts
-- (problems are printed to Output) and in tools/tests, so a missing colour, item id or
-- loot table is reported by name instead of breaking something mid-game.

local Biomes = require(script.Parent.Biomes)
local Catalog = require(script.Parent.Catalog)
local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)
local Items = require(script.Parent.Items)
local Layouts = require(script.Parent.Layouts)
local Palette = require(script.Parent.Palette)
local Rebirth = require(script.Parent.Rebirth)
local Secrets = require(script.Parent.Secrets)
local Traders = require(script.Parent.Traders)

local Validate = {}

local SHAPES = { Ball = true, Block = true, Cylinder = true }
local RESETS = { Rebirth = true, TrueRebirth = true, Never = true }
local CATEGORIES = { Tool = true, Vessel = true, Accessory = true, Cosmetic = true, Unlock = true }

-- Returns a list of problems (empty when everything checks out).
-- `extra` lets server code add checks for things only it knows (vessel builders, entrances).
function Validate.run(extra: { [string]: { [string]: any } }?): { string }
	local problems = {}
	local function check(ok: any, message: string)
		if not ok then
			table.insert(problems, message)
		end
	end
	local function isColor(value: any): boolean
		return typeof(value) == "Color3"
	end

	-- Palette: everything is the right type.
	for groupName, group in Palette do
		for key, value in group do
			local kind = typeof(value)
			check(
				kind == "Color3" or kind == "EnumItem",
				string.format("Palette.%s.%s is a %s", groupName, key, kind)
			)
		end
	end

	-- Items
	for _, item in Items.Catalog do
		local where = "Item " .. tostring(item.Id)
		check(type(item.Id) == "string" and Items.get(item.Id) == item, where .. ": duplicate or missing Id")
		check(type(item.Name) == "string", where .. ": missing Name")
		check(
			item.Class == 1 or item.Class == 2 or item.Class == 3 or item.Class == 4,
			where .. ": Class must be Light, Medium, Heavy or Very heavy"
		)
		check(
			Palette.Rarity[item.Rarity] ~= nil,
			where .. ": rarity '" .. tostring(item.Rarity) .. "' has no colour"
		)
		check(SHAPES[item.Shape], where .. ": unknown Shape " .. tostring(item.Shape))
		check(item.Floats == nil or type(item.Floats) == "boolean", where .. ": Floats must be true or false")
		check(typeof(item.Size) == "Vector3", where .. ": Size must be a Vector3")
		check(isColor(item.Color), where .. ": Color must be a Color3")
		check(type(item.Value) == "number", where .. ": missing Value")
		if item.Unlock then
			check(
				Biomes.List[item.Unlock] ~= nil
					or Secrets.List[item.Unlock] ~= nil
					or (item.Planned and Biomes.Planned[item.Unlock] ~= nil),
				where .. ": unlocks unknown biome or secret " .. tostring(item.Unlock)
			)
			check(Catalog.get(item.Id) ~= nil, where .. ": unlock item missing from the inventory catalog")
		end
	end

	-- Inventory catalog
	for id, entry in Catalog.all() do
		local where = "Catalog " .. id
		check(CATEGORIES[entry.Category], where .. ": unknown Category " .. tostring(entry.Category))
		check(
			Palette.Rarity[entry.Rarity] ~= nil,
			where .. ": rarity '" .. tostring(entry.Rarity) .. "' has no colour"
		)
		check(RESETS[entry.Resets], where .. ": unknown Resets " .. tostring(entry.Resets))
		check(type(entry.Description) == "string", where .. ": missing Description")
	end

	-- Gear
	for _, tool in Gear.Tools do
		local where = "Tool " .. tool.Id
		check(Palette.Rarity[tool.Rarity] ~= nil, where .. ": rarity has no colour")
		check(
			type(tool.Reach) == "number" and type(tool.Grip) == "number",
			where .. ": missing Reach or Grip"
		)
		check(tool.Lift >= 1 and tool.Lift <= 4, where .. ": bad Lift")
		check(tool.Depth >= 0 and tool.Depth <= 4, where .. ": bad Depth")
	end
	for _, vessel in Gear.Vessels do
		local where = "Vessel " .. vessel.Id
		check(Palette.Rarity[vessel.Rarity] ~= nil, where .. ": rarity has no colour")
		check(type(vessel.Capacity) == "number" and vessel.Capacity > 0, where .. ": bad Capacity")
		local usable = vessel.Available or vessel.Magical or vessel.Exotic
		if usable and extra and extra.VesselBuilders then
			check(
				extra.VesselBuilders[vessel.Id] ~= nil,
				where .. ": can be owned but has no builder in VesselService"
			)
		end
	end
	for _, accessory in Gear.Accessories do
		check(
			Palette.Rarity[accessory.Rarity] ~= nil,
			"Accessory " .. accessory.Id .. ": rarity has no colour"
		)
	end

	-- Zones
	check(#Config.Zones >= Config.Beach.ActiveZones, "Config.Zones has fewer zones than Beach.ActiveZones")
	check(
		Config.Beach.ZoneLength == Config.Beach.TileLength * Config.Beach.TilesPerZone,
		"Config.Beach.ZoneLength must be TileLength * TilesPerZone"
	)
	for index = 1, Config.Beach.ActiveZones do
		local zone = Config.Zones[index]
		check(
			zone ~= nil and type(zone.CrossTime) == "number" and zone.CrossTime > 0,
			"Config.Zones[" .. index .. "] needs a CrossTime (seconds to cross it on foot)"
		)
	end
	local sandbar = Config.Beach.FarSandbar
	check(Config.Zones[sandbar.Zone] ~= nil, "Config.Zones has no entry for the Far Sandbar")
	check(
		sandbar.ChannelStart == Config.Beach.ZoneLength * Config.Beach.ActiveZones,
		"the Far Sandbar's channel must start where the last zone ends"
	)
	check(
		Config.Tide.LowWaterline > sandbar.ChannelEnd and Config.Tide.LowWaterline < sandbar.End,
		"low tide must reach past the channel but not past the sandbar"
	)
	-- Tide shape and sections
	for _, name in { "OutShape", "InShape" } do
		local shape = Config.Tide[name]
		check(type(shape) == "table" and #shape >= 2, "Config.Tide." .. name .. " needs at least 2 values")
		if type(shape) == "table" and #shape >= 2 then
			check(
				shape[1] == 0 and shape[#shape] == 1,
				"Config.Tide." .. name .. " must start at 0 and end at 1"
			)
			for _, value in shape do
				check(
					type(value) == "number" and value >= 0 and value <= 1,
					"Config.Tide." .. name .. " values must be between 0 and 1"
				)
			end
		end
	end
	local lastX = -math.huge
	for _, section in Config.Tide.Sections or {} do
		check(
			type(section.X) == "number" and type(section.Lag) == "number",
			"Config.Tide.Sections entries need X and Lag numbers"
		)
		check((section.X or 0) > lastX, "Config.Tide.Sections must be in order of X")
		local shuffle = Config.Tide.Shuffle and Config.Tide.Shuffle.Amplitude or 0
		check(
			math.abs(section.Lag or 0) + shuffle < Config.Tide.HoldTime,
			"a tide section's Lag plus the Shuffle amplitude must be shorter than the low-tide hold, or that part never reaches low tide with the rest"
		)
		lastX = section.X or lastX
	end

	-- Day and music
	check(
		Config.Day.DayShare > 0 and Config.Day.DayShare < 1 and Config.Day.Length > 0,
		"Config.Day: DayShare must be between 0 and 1, and Length positive"
	)
	local PLACES = { Shop = true, Shore = true, Outer = true, Sandbar = true, Secret = true, Showroom = true }
	local TIMES = { Day = true, Twilight = true, Night = true }
	for _, track in Config.Music.Tracks do
		local where = "Music track " .. tostring(track.Title)
		check(type(track.SoundId) == "number", where .. ": SoundId must be a number (0 = not uploaded yet)")
		check(type(track.Artist) == "string", where .. ": needs an Artist (it's shown when the track starts)")
		check(type(track.Places) == "table" and #track.Places > 0, where .. ": needs Places")
		for _, place in track.Places or {} do
			check(PLACES[place] == true, where .. ": unknown place " .. tostring(place))
		end
		for _, time in track.Times or {} do
			check(TIMES[time] == true, where .. ": unknown time " .. tostring(time))
		end
	end

	-- Terrain shape and mist
	local terrain = Config.Beach.Terrain
	for _, key in
		{
			"Voxel",
			"EdgeFade",
			"ZoneFade",
			"Blend",
			"RockMin",
			"CartSlope",
			"FootSlope",
			"MaxHeight",
			"MaxDepth",
			"EyeHeight",
		}
	do
		check(
			type(terrain[key]) == "number" and terrain[key] > 0,
			"Config.Beach.Terrain." .. key .. " must be a positive number"
		)
	end
	check(terrain.CartSlope < terrain.FootSlope, "carts can't climb steeper than players walk")
	for _, entry in Layouts.all(true) do
		for _, problem in Layouts.problems(entry.Layout) do
			check(false, "Layouts/" .. entry.Source .. ": " .. problem)
		end
	end
	check(#Config.Mist.Zones >= #Config.Zones, "Config.Mist.Zones needs a density for every zone")

	-- Wading
	local wading = Config.Beach.Wading
	check(
		type(wading) == "table" and #wading >= 2 and wading[1].Depth == 0,
		"Config.Beach.Wading needs points from depth 0"
	)
	for i, point in wading or {} do
		check(
			type(point.Speed) == "number"
				and point.Speed > 0
				and point.Speed <= 1
				and type(point.Jump) == "number"
				and point.Jump > 0
				and point.Jump <= 1,
			"Config.Beach.Wading: Speed and Jump must be between 0 and 1"
		)
		if i > 1 then
			check(point.Depth > wading[i - 1].Depth, "Config.Beach.Wading must be in order of depth")
		end
	end

	-- Waves and rock pools
	check(#Config.Waves.ZoneScale >= #Config.Zones, "Config.Waves.ZoneScale needs an entry for every zone")
	do
		-- Wading back across the Far Sandbar's channel at knee depth must stay possible.
		local w = Config.Waves
		local knee = Config.Beach.KneeDepth / Config.Beach.WaistDepth
		local zone = 1 + ((w.ZoneScale[sandbar.Zone] or 1) - 1) * w.UndertowZoneScale
		-- The strongest moment: the drawback just before a big (set) wave.
		local pull = (w.Undertow + (w.UndertowDeep - w.Undertow) * knee)
			* zone
			* (w.Slack + w.Drawback * w.SetSize * w.SetSize)
		-- Averaged over a wave it must stay well under walking speed.
		local share = (w.DrawbackRange / w.Speed) / w.Period
		pull = pull * share
			+ (w.Undertow + (w.UndertowDeep - w.Undertow) * knee) * zone * w.Slack * (1 - share)
		-- Walking speed at knee depth, after the water slows you (Config.Beach.Wading).
		local wade = 16
		for _, point in Config.Beach.Wading or {} do
			if point.Depth <= Config.Beach.KneeDepth then
				wade = 16 * point.Speed
			end
		end
		check(
			pull < wade * 0.8,
			string.format(
				"the undertow at knee depth on the Far Sandbar (%.1f studs/s) is too close to wading speed (%.1f)",
				pull,
				wade
			)
		)
	end
	for index, pool in Config.Beach.Pools or {} do
		local where = "Rock pool " .. index
		check(
			type(pool.Radius) == "number"
				and pool.Radius > 2
				and type(pool.Depth) == "number"
				and pool.Depth > 0,
			where .. ": needs a Radius (over 2) and a Depth"
		)
		check(
			math.abs(pool.X) + pool.Radius < Config.Beach.Width / 2 and pool.Z - pool.Radius > 0,
			where .. ": must be on the beach"
		)
		check(
			pool.Z + pool.Radius < sandbar.ChannelStart,
			where .. ": must be in front of the Far Sandbar's channel"
		)
	end

	for index, zone in Config.Zones do
		for rarity in zone.Rarity do
			check(
				#Items.ofRarity(rarity) > 0,
				string.format("Zone %d rolls rarity %s, which has no items", index, rarity)
			)
		end
	end

	-- Biomes
	for id, weight in Config.Biomes.Weights do
		check(id == "None" or Biomes.List[id] ~= nil, "Config.Biomes.Weights names unknown biome " .. id)
		check(type(weight) == "number" and weight >= 0, "Config.Biomes.Weights." .. id .. " must be a number")
	end
	for id, biome in Biomes.List do
		local where = "Biome " .. id
		check(biome.Id == id, where .. ": Id doesn't match its key")
		for _, lootId in biome.Loot do
			check(Items.get(lootId) ~= nil, where .. ": loot item " .. lootId .. " doesn't exist")
		end
		local unlock = Items.get(biome.UnlockItem)
		check(
			unlock ~= nil and unlock.Unlock == id,
			where .. ": UnlockItem must be an unlock item for this biome"
		)
		check(
			Secrets.List[biome.Secret] ~= nil,
			where .. ": secret " .. tostring(biome.Secret) .. " doesn't exist"
		)
		check(isColor(biome.Decor), where .. ": Decor must be a Color3")
		check(#biome.EntranceSpots > 0, where .. ": needs at least one entrance spot")
		if extra and extra.Entrances then
			check(
				extra.Entrances[biome.Entrance] ~= nil,
				where .. ": no entrance builder called " .. tostring(biome.Entrance)
			)
		end
		if biome.Hazard and extra and extra.Hazards then
			check(
				extra.Hazards[biome.Hazard] ~= nil,
				where .. ": no hazard called " .. tostring(biome.Hazard)
			)
		end
	end

	-- Planned biomes: everything they name must exist.
	for id, biome in Biomes.Planned do
		local where = "Planned biome " .. id
		local unlock = Items.get(biome.UnlockItem)
		check(unlock ~= nil and unlock.Unlock == id, where .. ": unlock item must exist and point back at it")
		for _, lootId in biome.Loot or {} do
			check(Items.get(lootId) ~= nil, where .. ": loot " .. lootId .. " isn't an item")
		end
		for _, rewardId in biome.Rewards or {} do
			check(
				Catalog.get(rewardId) ~= nil,
				where .. ": reward " .. rewardId .. " isn't an inventory item"
			)
		end
		check(biome.Coin == nil or Palette.Coin[biome.Coin] ~= nil, where .. ": coin has no colour")
	end

	-- Secrets
	for id, secret in Secrets.List do
		local where = "Secret " .. id
		local unlock = Items.get(secret.Unlock)
		check(unlock ~= nil and unlock.Unlock ~= nil, where .. ": Unlock must be an unlock item")
		check(isColor(secret.Color), where .. ": Color must be a Color3")
		-- Exactly one kind of reward: a colored coin (normal) or a lootbox (exotic).
		check(
			(secret.Coin ~= nil) ~= (secret.Loot ~= nil),
			where .. ": needs either a Coin or a Loot table, not both"
		)
		if secret.Coin then
			check(
				Palette.Coin[secret.Coin] ~= nil,
				where .. ": coin " .. tostring(secret.Coin) .. " has no colour"
			)
		end
		if secret.Loot then
			for _, entry in secret.Loot do
				check(
					Catalog.get(entry.Id) ~= nil,
					where .. ": loot " .. tostring(entry.Id) .. " isn't an inventory item"
				)
				check(
					type(entry.Weight) == "number" and entry.Weight > 0,
					where .. ": loot weights must be positive"
				)
			end
		end
		check(
			(secret.Biome ~= nil) ~= (secret.Location ~= nil),
			where .. ": needs a Biome (door comes with the biome) or a fixed Location, not both"
		)
		if secret.FloodSeconds then
			check(
				type(secret.FloodSeconds) == "number" and secret.FloodSeconds >= Config.Secrets.MinFlood,
				where .. ": FloodSeconds must be at least Config.Secrets.MinFlood"
			)
		end
		local course = secret.Course
		for _, field in
			{
				"Floor",
				"Platforms",
				"Checkpoints",
				"Spawn",
				"Chest",
				"HalfSize",
				"WallHeight",
				"FloodFrom",
				"FloodTo",
			}
		do
			check(course and course[field] ~= nil, where .. ": course is missing " .. field)
		end
		if course and course.Spawn and course.HalfSize then
			check(
				math.abs(course.Spawn.X) <= course.HalfSize and math.abs(course.Spawn.Z) <= course.HalfSize,
				where .. ": spawn is outside the course box"
			)
		end
	end

	-- Paid features
	local seenIds = {}
	for _, pack in Config.Monetization.CoinPacks do
		local where = "Coin pack " .. tostring(pack.Id)
		check(type(pack.Name) == "string", where .. ": needs a Name")
		check(type(pack.Coins) == "number" and pack.Coins > 0, where .. ": Coins must be positive")
		check(type(pack.ProductId) == "number", where .. ": ProductId must be a number (0 = not set up)")
		if pack.ProductId ~= 0 then
			check(not seenIds[pack.ProductId], where .. ": ProductId is used twice")
			seenIds[pack.ProductId] = true
		end
	end
	local passEffects = { SellMultiplier = true, PocketSlots = true }
	for _, pass in Config.Monetization.Gamepasses do
		local where = "Gamepass " .. tostring(pass.Id)
		check(type(pass.Name) == "string" and type(pass.Note) == "string", where .. ": needs a Name and Note")
		check(type(pass.PassId) == "number", where .. ": PassId must be a number (0 = not set up)")
		local effects = 0
		for key in pass do
			if passEffects[key] then
				effects += 1
			end
		end
		check(effects > 0, where .. ": has no effect (SellMultiplier or PocketSlots)")
	end

	-- Cosmetics
	for _, cosmetic in Gear.Cosmetics do
		local where = "Cosmetic " .. cosmetic.Id
		check(Palette.Rarity[cosmetic.Rarity] ~= nil, where .. ": rarity has no colour")
		local hat = cosmetic.Hat
		check(
			hat and type(hat.Height) == "number" and type(hat.Width) == "number",
			where .. ": needs a Hat shape"
		)
		check(hat and isColor(hat.Color), where .. ": Hat.Color must be a Color3")
		check(
			hat and Palette.Material[hat.Material] ~= nil,
			where .. ": Hat.Material must be a Palette material"
		)
		if cosmetic.Auction then
			check(
				type(cosmetic.Auction.Of) == "number" and cosmetic.Auction.Of >= 1,
				where .. ": Auction.Of must be 1 or more"
			)
			check(type(cosmetic.Auction.StartingBid) == "number", where .. ": Auction needs a StartingBid")
		end
	end

	-- Traders: each sells a real upgrade; traders whose biome exists must be payable with
	-- something that exists.
	for id, trader in Traders.List do
		local where = "Trader " .. id
		check(trader.Id == id, where .. ": Id doesn't match its key")
		check(
			Traders.Upgrades[trader.Upgrade] ~= nil,
			where .. ": sells unknown upgrade " .. tostring(trader.Upgrade)
		)
		check(trader.PaidWithItem ~= nil or trader.PaidWithCores ~= nil, where .. ": needs a way to be paid")
		if Biomes.List[trader.Biome] and trader.PaidWithItem then
			check(
				Items.get(trader.PaidWithItem) ~= nil,
				where .. ": wants " .. trader.PaidWithItem .. ", which doesn't exist"
			)
		end
	end
	for _, id in Traders.UpgradeOrder do
		check(Traders.Upgrades[id] ~= nil, "Upgrade " .. id .. " is listed but not defined")
	end

	-- Auction: every lot is an auctionable cosmetic.
	for _, id in Config.Auction.Lots do
		local cosmetic = Gear.getCosmetic(id)
		check(
			cosmetic ~= nil and cosmetic.Auction ~= nil,
			"Auction lot " .. id .. " isn't an auction cosmetic"
		)
	end

	-- Rebirth
	for _, id in Rebirth.Order do
		check(Rebirth.Rewards[id] ~= nil, "Rebirth reward " .. id .. " is listed but not defined")
	end

	return problems
end

return Validate
