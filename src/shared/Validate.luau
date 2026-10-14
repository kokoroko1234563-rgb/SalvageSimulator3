-- Checks that the game's data fits together: every reference points at something that
-- exists, and every entry has the fields the code relies on. It runs when the server starts
-- (problems are printed to Output) and in tools/tests, so a missing colour, item id or
-- loot table is reported by name instead of breaking something mid-game.

local Biomes = require(script.Parent.Biomes)
local Catalog = require(script.Parent.Catalog)
local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)
local Items = require(script.Parent.Items)
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
			item.Class == 1 or item.Class == 2 or item.Class == 3,
			where .. ": Class must be Light, Medium or Heavy"
		)
		check(
			Palette.Rarity[item.Rarity] ~= nil,
			where .. ": rarity '" .. tostring(item.Rarity) .. "' has no colour"
		)
		check(SHAPES[item.Shape], where .. ": unknown Shape " .. tostring(item.Shape))
		check(typeof(item.Size) == "Vector3", where .. ": Size must be a Vector3")
		check(isColor(item.Color), where .. ": Color must be a Color3")
		check(type(item.Value) == "number", where .. ": missing Value")
		if item.Unlock then
			check(
				Biomes.List[item.Unlock] ~= nil or Secrets.List[item.Unlock] ~= nil,
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
