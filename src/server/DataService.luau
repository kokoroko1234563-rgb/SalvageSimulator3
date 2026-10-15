-- Saves each player's progress with DataStoreService.
--   * Every DataStore call is wrapped in pcall and retried.
--   * UpdateAsync with a session lock (JobId + timestamp) stops two servers from holding the
--     same profile at once, which is how items get duplicated.
--   * Saves on autosave, PlayerRemoving and BindToClose.
-- In Studio without "Enable Studio Access to API Services", data loads as a fresh profile
-- and is not saved.
--
-- Inventory items are stored one record per copy, keyed by a unique id, so a copy can
-- later be traded, carry a variant or a serial number, and never be duplicated. Only this
-- module edits them (addItem / removeItem / removeItemsOfType).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Hotbar = require(Shared.Hotbar)
local Items = require(Shared.Items)
local Rebirth = require(Shared.Rebirth)
local Secrets = require(Shared.Secrets)
local Traders = require(Shared.Traders)

local cfg = Config.Data

local DataService = {}

export type ItemRecord = {
	Id: string, -- catalog id
	Acquired: number, -- os.time()
	Source: string?, -- "shop", "beach", "reward", "admin", "migrated"
	Variant: string?, -- cosmetic variant, e.g. "Frosted"
	Serial: number?, -- numbered auction items: #Serial of Of
	Of: number?,
	Winner: string?, -- auction items: who won it
}

export type PocketEntry = { ItemId: string, Zone: number, Value: number }

export type Profile = {
	Version: number,
	Coins: number,
	Rebirths: number,
	TrueRebirths: number,
	Rewards: { [string]: boolean },
	PendingPick: { string }?, -- reward options waiting for the player to choose one
	ColoredCoins: { [string]: boolean },
	Cores: number, -- attunement cores, one per true rebirth
	Attunements: { [string]: boolean }, -- exotic item types the player can use
	Items: { [string]: ItemRecord }, -- inventory, by unique id
	EquippedTool: string?, -- catalog id; nil = best owned
	EquippedAccessory: string?,
	EquippedCosmetic: string?,
	Lexicon: { [string]: number }, -- item id -> when first found (os.time); never reset
	Upgrades: { [string]: number }, -- trader upgrade id -> level
	Pockets: { PocketEntry }, -- Deep Pockets contents
	Settings: { HideShopGear: boolean, ShowResetText: boolean, MuteMusic: boolean },
	Receipts: { string }, -- recent Robux purchase ids, already granted (MonetizationService)
	Hotbar: { string }, -- tool id per hotbar slot, "" = empty (see Hotbar.luau)
}

local function defaultProfile(): Profile
	return {
		Version = 2,
		Coins = 0,
		Rebirths = 0,
		TrueRebirths = 0,
		Rewards = {},
		PendingPick = nil,
		ColoredCoins = {},
		Cores = 0,
		Attunements = {},
		Items = {},
		EquippedTool = nil,
		EquippedAccessory = nil,
		EquippedCosmetic = nil,
		Lexicon = {},
		Upgrades = {},
		Pockets = {},
		Settings = { HideShopGear = false, ShowResetText = false, MuteMusic = false },
		Receipts = {},
		Hotbar = Hotbar.empty(),
	}
end

local profiles: { [Player]: Profile } = {}
local canSave: { [Player]: boolean } = {}
local loadedCallbacks = {}
local changedCallbacks = {}

local store: DataStore? = nil

local function keyFor(player: Player): string
	return "p_" .. player.UserId
end

local function newUid(): string
	return HttpService:GenerateGUID(false)
end

local function newRecord(id: string, source: string): ItemRecord
	return { Id = id, Acquired = os.time(), Source = source }
end

local function reconcile(data: any): Profile
	local profile = defaultProfile()
	if type(data) ~= "table" then
		return profile
	end
	if type(data.Coins) == "number" then
		profile.Coins = math.max(0, math.floor(data.Coins))
	end
	if type(data.Rebirths) == "number" then
		profile.Rebirths = math.max(0, math.floor(data.Rebirths))
	end
	if type(data.Rewards) == "table" then
		for id, owned in data.Rewards do
			if owned == true and Rebirth.Rewards[id] then
				profile.Rewards[id] = true
			end
		end
	end
	if type(data.PendingPick) == "table" then
		local pick = {}
		for _, id in data.PendingPick do
			if Rebirth.Rewards[id] and not profile.Rewards[id] then
				table.insert(pick, id)
			end
		end
		profile.PendingPick = if #pick > 0 then pick else nil
	end
	if type(data.ColoredCoins) == "table" then
		for color, owned in data.ColoredCoins do
			if owned == true and Secrets.CoinColors[color] then
				profile.ColoredCoins[color] = true
			end
		end
	end
	if type(data.Cores) == "number" then
		profile.Cores = math.max(0, math.floor(data.Cores))
	end
	if type(data.TrueRebirths) == "number" then
		profile.TrueRebirths = math.max(0, math.floor(data.TrueRebirths))
	end
	if type(data.Attunements) == "table" then
		for id, attuned in data.Attunements do
			local entry = Catalog.get(id)
			if attuned == true and entry and entry.Exotic then
				profile.Attunements[id] = true
			end
		end
	end
	if type(data.EquippedAccessory) == "string" and Catalog.get(data.EquippedAccessory) then
		profile.EquippedAccessory = data.EquippedAccessory
	end
	if type(data.EquippedCosmetic) == "string" and Catalog.get(data.EquippedCosmetic) then
		profile.EquippedCosmetic = data.EquippedCosmetic
	end
	if type(data.Lexicon) == "table" then
		for id, at in data.Lexicon do
			if Items.get(id) and type(at) == "number" then
				profile.Lexicon[id] = at
			end
		end
	end
	if type(data.Upgrades) == "table" then
		for id, level in data.Upgrades do
			local upgrade = Traders.Upgrades[id]
			if upgrade and type(level) == "number" and level > 0 then
				profile.Upgrades[id] = math.clamp(math.floor(level), 0, upgrade.MaxLevel)
			end
		end
	end

	if type(data.Items) == "table" then
		for uid, record in data.Items do
			if type(uid) == "string" and type(record) == "table" and Catalog.get(record.Id) then
				profile.Items[uid] = {
					Id = record.Id,
					Acquired = if type(record.Acquired) == "number" then record.Acquired else os.time(),
					Source = if type(record.Source) == "string" then record.Source else nil,
					Variant = if type(record.Variant) == "string" then record.Variant else nil,
					Serial = if type(record.Serial) == "number" then record.Serial else nil,
					Of = if type(record.Of) == "number" then record.Of else nil,
					Winner = if type(record.Winner) == "string" then record.Winner else nil,
				}
			end
		end
	else
		-- Version 1 saves: owned-gear flags and unlock-item counts become item records.
		for _, field in { "Tools", "Vessels" } do
			if type(data[field]) == "table" then
				for id, owned in data[field] do
					if owned == true and Catalog.get(id) then
						profile.Items[newUid()] = newRecord(id, "migrated")
					end
				end
			end
		end
		if type(data.UnlockItems) == "table" then
			for id, count in data.UnlockItems do
				if Catalog.get(id) and type(count) == "number" then
					for _ = 1, math.clamp(math.floor(count), 0, 1000) do
						profile.Items[newUid()] = newRecord(id, "migrated")
					end
				end
			end
		end
	end

	if type(data.EquippedTool) == "string" and Catalog.get(data.EquippedTool) then
		profile.EquippedTool = data.EquippedTool
	end
	if type(data.Pockets) == "table" then
		for _, entry in data.Pockets do
			if
				type(entry) == "table"
				and Items.get(entry.ItemId)
				and #profile.Pockets < Config.Pockets.MaxSlots
			then
				table.insert(profile.Pockets, {
					ItemId = entry.ItemId,
					Zone = if type(entry.Zone) == "number" then entry.Zone else 1,
					Value = if type(entry.Value) == "number" then entry.Value else 0,
				})
			end
		end
	end
	if type(data.Settings) == "table" then
		profile.Settings.HideShopGear = data.Settings.HideShopGear == true
		profile.Settings.MuteMusic = data.Settings.MuteMusic == true
		profile.Settings.ShowResetText = data.Settings.ShowResetText == true
	end
	if type(data.Hotbar) == "table" then
		profile.Hotbar = Hotbar.sanitize(data.Hotbar)
	end
	if type(data.Receipts) == "table" then
		for _, id in data.Receipts do
			if type(id) == "string" then
				table.insert(profile.Receipts, id)
			end
		end
	end
	return profile
end

local function serialize(profile: Profile, release: boolean)
	return {
		Version = profile.Version,
		Coins = profile.Coins,
		Rebirths = profile.Rebirths,
		TrueRebirths = profile.TrueRebirths,
		Rewards = profile.Rewards,
		PendingPick = profile.PendingPick,
		ColoredCoins = profile.ColoredCoins,
		Cores = profile.Cores,
		Attunements = profile.Attunements,
		Items = profile.Items,
		EquippedTool = profile.EquippedTool,
		EquippedAccessory = profile.EquippedAccessory,
		EquippedCosmetic = profile.EquippedCosmetic,
		Lexicon = profile.Lexicon,
		Upgrades = profile.Upgrades,
		Pockets = profile.Pockets,
		Settings = profile.Settings,
		Receipts = profile.Receipts,
		Hotbar = profile.Hotbar,
		Lock = if release then nil else { JobId = game.JobId, Time = os.time() },
	}
end

-- Set of catalog ids the profile owns at least one of.
local function ownedTypes(profile: Profile): { [string]: boolean }
	local set = {}
	for _, record in profile.Items do
		set[record.Id] = true
	end
	return set
end

local function csv(set: { [string]: boolean }, list): string
	local ids = {}
	for _, entry in list do
		if set[entry.Id] then
			table.insert(ids, entry.Id)
		end
	end
	return table.concat(ids, ",")
end

local rewardList = {}
for _, id in Rebirth.Order do
	table.insert(rewardList, Rebirth.Rewards[id])
end

-- Whether the player may use this item type: anything not exotic, or exotic once attuned.
local function canUse(profile: Profile, id: string): boolean
	local entry = Catalog.get(id)
	return entry ~= nil and (not entry.Exotic or profile.Attunements[id] == true)
end

-- The tool the player grabs with: the one they equipped if they still own (and may use)
-- it, else their best shop tool.
local function activeTool(profile: Profile)
	local owned = ownedTypes(profile)
	owned.BareHands = true
	local equipped = profile.EquippedTool
	if equipped and owned[equipped] and (equipped == "BareHands" or canUse(profile, equipped)) then
		return Gear.getTool(equipped)
	end
	return Gear.bestTool(owned)
end

-- The worn accessory, if the player still owns it and is attuned to it.
local function activeAccessory(profile: Profile)
	local id = profile.EquippedAccessory
	if id and ownedTypes(profile)[id] and canUse(profile, id) then
		return Gear.getAccessory(id)
	end
	return nil
end

-- Pocket slots: 3 from Deep Pockets, plus whatever a worn accessory adds.
-- Extra pocket slots from outside the profile (gamepasses, see MonetizationService).
local bonusPockets: { [Player]: number } = {}

local function pocketSlots(player: Player, profile: Profile): number
	local slots = (if profile.Rewards.DeepPockets then Config.Pockets.Slots else 0)
		+ (bonusPockets[player] or 0)
	local accessory = activeAccessory(profile)
	if accessory and accessory.PocketSlots then
		slots += accessory.PocketSlots
	end
	return math.min(slots, Config.Pockets.MaxSlots)
end

local function countKeys(set: { [string]: any }): number
	local count = 0
	for _ in set do
		count += 1
	end
	return count
end

-- Mirrors the profile onto player attributes (small values the HUD and checks read) and
-- tells listeners (the inventory sync) that it changed.
local function publish(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local owned = ownedTypes(profile)
	player:SetAttribute("Coins", profile.Coins)
	player:SetAttribute("Tool", activeTool(profile).Id)
	player:SetAttribute(Hotbar.Attribute, Hotbar.encode(profile.Hotbar))
	player:SetAttribute("OwnedTools", csv(owned, Gear.Tools))
	player:SetAttribute("OwnedVessels", csv(owned, Gear.Vessels))
	player:SetAttribute("Rebirths", profile.Rebirths)
	player:SetAttribute("Multiplier", Rebirth.multiplier(profile.Rebirths))
	player:SetAttribute("Rewards", csv(profile.Rewards, rewardList))
	player:SetAttribute("PendingPick", table.concat(profile.PendingPick or {}, ","))
	player:SetAttribute("Pockets", #profile.Pockets)
	player:SetAttribute("PocketSlots", pocketSlots(player, profile))
	local accessory = activeAccessory(profile)
	player:SetAttribute("Accessory", if accessory then accessory.Id else "")
	player:SetAttribute("Cores", profile.Cores)
	player:SetAttribute("ColoredCoinCount", countKeys(profile.ColoredCoins))
	player:SetAttribute("LexiconCount", countKeys(profile.Lexicon))
	local cosmetic = profile.EquippedCosmetic
	player:SetAttribute("Cosmetic", if cosmetic and ownedTypes(profile)[cosmetic] then cosmetic else "")
	local upgrades = {}
	for _, id in Traders.UpgradeOrder do
		if (profile.Upgrades[id] or 0) > 0 then
			table.insert(upgrades, id .. ":" .. profile.Upgrades[id])
		end
	end
	player:SetAttribute("Upgrades", table.concat(upgrades, ","))
	for _, callback in changedCallbacks do
		task.spawn(callback, player, profile)
	end
end

local function load(player: Player): (Profile?, boolean)
	if not store then
		return defaultProfile(), false
	end

	local key = keyFor(player)
	local lockedElsewhere = false
	for attempt = 1, cfg.LoadAttempts do
		lockedElsewhere = false
		local ok, result = pcall(function()
			return (store :: DataStore):UpdateAsync(key, function(old)
				lockedElsewhere = false
				if type(old) == "table" and type(old.Lock) == "table" then
					local lock = old.Lock
					local stale = type(lock.Time) ~= "number" or os.time() - lock.Time > cfg.LockStaleAfter
					if lock.JobId ~= game.JobId and not stale then
						lockedElsewhere = true
						return nil -- cancel the write, someone else has it
					end
				end
				local profile = reconcile(old)
				return serialize(profile, false)
			end)
		end)

		if ok and not lockedElsewhere then
			return reconcile(result), true
		end
		if not player.Parent then
			return nil, false
		end
		if not ok then
			warn(
				string.format(
					"[DataService] load attempt %d for %s failed: %s",
					attempt,
					player.Name,
					tostring(result)
				)
			)
			if RunService:IsStudio() then
				-- Usually "Studio access to API services" is off; don't make testers wait.
				return defaultProfile(), false
			end
		end
		task.wait(if lockedElsewhere then 5 else 2 ^ attempt)
	end

	if lockedElsewhere then
		return nil, false
	end
	-- DataStores are down: let them play, but don't overwrite their real save.
	return defaultProfile(), false
end

local function save(player: Player, release: boolean): boolean
	local profile = profiles[player]
	if not profile or not canSave[player] or not store then
		return false
	end
	local key = keyFor(player)
	for attempt = 1, 4 do
		local lostLock = false
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(key, function(old)
				lostLock = false
				if type(old) == "table" and type(old.Lock) == "table" and old.Lock.JobId ~= game.JobId then
					lostLock = true
					return nil
				end
				return serialize(profile, release)
			end)
		end)
		if ok then
			if lostLock then
				warn("[DataService] session lock for", player.Name, "is held by another server; not saving")
			end
			return not lostLock
		end
		warn(
			string.format(
				"[DataService] save attempt %d for %s failed: %s",
				attempt,
				player.Name,
				tostring(err)
			)
		)
		task.wait(2 ^ attempt)
	end
	return false
end

-- Call after changing a profile directly, so clients see the change.
DataService.changed = publish

function DataService.get(player: Player): Profile?
	return profiles[player]
end

function DataService.onLoaded(callback: (Player, Profile) -> ())
	table.insert(loadedCallbacks, callback)
	for player, profile in profiles do
		task.spawn(callback, player, profile)
	end
end

function DataService.addCoins(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Coins = math.max(0, profile.Coins + math.floor(amount))
	publish(player)
end

function DataService.setCoins(player: Player, amount: number)
	local profile = profiles[player]
	if profile then
		profile.Coins = math.max(0, math.floor(amount))
		publish(player)
	end
end

-- Wipes a player's progress back to a new save (saved on the next autosave or leave).
function DataService.reset(player: Player)
	if profiles[player] then
		profiles[player] = defaultProfile()
		publish(player)
	end
end

function DataService.trySpend(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or profile.Coins < amount then
		return false
	end
	profile.Coins -= amount
	publish(player)
	return true
end

function DataService.grantColoredCoin(player: Player, color: string)
	local profile = profiles[player]
	if profile then
		profile.ColoredCoins[color] = true
		publish(player)
	end
end

-- Lexicon ----------------------------------------------------------------------------

-- Records that the player found an item type on the beach. Returns true the first time.
function DataService.recordLexicon(player: Player, itemId: string): boolean
	local profile = profiles[player]
	if not profile or profile.Lexicon[itemId] or not Items.get(itemId) then
		return false
	end
	profile.Lexicon[itemId] = os.time()
	publish(player)
	return true
end

function DataService.lexiconComplete(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	for _, item in Items.Lexicon do
		if not profile.Lexicon[item.Id] then
			return false
		end
	end
	return true
end

-- Inventory ------------------------------------------------------------------------

function DataService.canUse(player: Player, id: string): boolean
	local profile = profiles[player]
	return profile ~= nil and canUse(profile, id)
end

function DataService.pocketSlots(player: Player): number
	local profile = profiles[player]
	return if profile then pocketSlots(player, profile) else 0
end

function DataService.setBonusPockets(player: Player, slots: number)
	bonusPockets[player] = if slots > 0 then slots else nil
	publish(player)
end

-- Saves now. False if it couldn't (DataStores down, or this server lost the session lock).
function DataService.saveNow(player: Player): boolean
	return save(player, false)
end

-- Whether this player's profile is being saved at all (false in Studio without API access,
-- or when their save couldn't be loaded).
function DataService.isPersistent(player: Player): boolean
	return store ~= nil and canSave[player] == true
end

function DataService.onChanged(callback: (Player, Profile) -> ())
	table.insert(changedCallbacks, callback)
end

function DataService.ownedTypes(player: Player): { [string]: boolean }
	local profile = profiles[player]
	return if profile then ownedTypes(profile) else {}
end

function DataService.countItemType(player: Player, id: string): number
	local profile = profiles[player]
	local count = 0
	if profile then
		for _, record in profile.Items do
			if record.Id == id then
				count += 1
			end
		end
	end
	return count
end

-- Adds one copy of a catalog item and returns its unique id.
function DataService.addItem(player: Player, id: string, source: string, extra: { [string]: any }?): string?
	local profile = profiles[player]
	if not profile or not Catalog.get(id) then
		return nil
	end
	local record = newRecord(id, source)
	if extra then
		for key, value in extra do
			(record :: any)[key] = value
		end
	end
	local uid = newUid()
	profile.Items[uid] = record
	Hotbar.autoAdd(profile.Hotbar, id, ownedTypes(profile))
	print(string.format("[Inventory] %s +%s (%s)", player.Name, id, source))
	publish(player)
	return uid
end

function DataService.removeItem(player: Player, uid: string): boolean
	local profile = profiles[player]
	local record = profile and profile.Items[uid]
	if not profile or not record then
		return false
	end
	profile.Items[uid] = nil
	print(string.format("[Inventory] %s -%s", player.Name, record.Id))
	publish(player)
	return true
end

-- Removes up to `count` copies of a type (oldest first). Returns how many were removed.
function DataService.removeItemsOfType(player: Player, id: string, count: number): number
	local profile = profiles[player]
	if not profile then
		return 0
	end
	local matches = {}
	for uid, record in profile.Items do
		if record.Id == id then
			table.insert(matches, { uid = uid, at = record.Acquired })
		end
	end
	table.sort(matches, function(a, b)
		return a.at < b.at
	end)
	local removed = 0
	for _, match in matches do
		if removed >= count then
			break
		end
		profile.Items[match.uid] = nil
		removed += 1
	end
	if removed > 0 then
		print(string.format("[Inventory] %s -%d %s", player.Name, removed, id))
		publish(player)
	end
	return removed
end

-- Removes every item a reset of this kind takes away ("Rebirth" or "TrueRebirth").
export type TradeOffer = { Items: { [string]: boolean }, Coins: number }

-- Swaps two offers between two loaded players in one step: everything is re-checked first,
-- then items move (keeping their unique ids, variants and serials) and coins move minus
-- the tax. Nothing changes unless all of it is valid. Both saves are written straight away.
function DataService.executeTrade(
	a: Player,
	b: Player,
	offerA: TradeOffer,
	offerB: TradeOffer,
	taxRate: number
): (boolean, string?)
	local pa, pb = profiles[a], profiles[b]
	if not pa or not pb or a == b then
		return false, "Both players must be loaded"
	end
	for _, side in { { pa, offerA, a }, { pb, offerB, b } } do
		local profile, offer, player = side[1], side[2], side[3]
		for uid in offer.Items do
			local record = profile.Items[uid]
			local entry = record and Catalog.get(record.Id)
			if not record or not entry then
				return false, player.Name .. " no longer has an offered item"
			end
			if not entry.Tradeable then
				return false, entry.Name .. " can't be traded"
			end
		end
		if type(offer.Coins) ~= "number" or offer.Coins < 0 or offer.Coins ~= math.floor(offer.Coins) then
			return false, "Invalid coin amount"
		end
		if offer.Coins > profile.Coins then
			return false, player.Name .. " doesn't have that many coins any more"
		end
	end

	local function move(from: Profile, to: Profile, offer: TradeOffer)
		for uid in offer.Items do
			local record = from.Items[uid]
			to.Items[uid] = record
			from.Items[uid] = nil
			Hotbar.autoAdd(to.Hotbar, record.Id, ownedTypes(to))
		end
		from.Coins -= offer.Coins
		to.Coins += math.floor(offer.Coins * (1 - taxRate))
	end
	move(pa, pb, offerA)
	move(pb, pa, offerB)

	print(string.format("[Trade] %s <-> %s completed", a.Name, b.Name))
	publish(a)
	publish(b)
	task.spawn(save, a, false)
	task.spawn(save, b, false)
	return true
end

-- Puts every owned tool that isn't on the hotbar into a free slot, in shop order (saves
-- from before the hotbar existed start with their tools on it).
function DataService.fillHotbar(profile: Profile)
	local owned = ownedTypes(profile)
	for _, tool in Gear.Tools do
		if owned[tool.Id] and not table.find(profile.Hotbar, tool.Id) then
			Hotbar.autoAdd(profile.Hotbar, tool.Id, owned)
		end
	end
end

-- For tools/tests: install a profile for a stand-in player.
function DataService._setProfile(player: any, data: any)
	profiles[player] = reconcile(data)
	canSave[player] = false
end

function DataService.removeItemsLostOn(player: Player, reset: string)
	local profile = profiles[player]
	if not profile then
		return
	end
	for uid, record in profile.Items do
		local entry = Catalog.get(record.Id)
		if entry and Catalog.lostOn(entry, reset) then
			profile.Items[uid] = nil
		end
	end
	publish(player)
end

function DataService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(cfg.StoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStores unavailable, progress will not save:", result)
	end

	local function onPlayer(player: Player)
		local profile, saving = load(player)
		if not player.Parent then
			return
		end
		if not profile then
			player:Kick("Your save is still open on another server. Please rejoin in a minute.")
			return
		end
		if not saving then
			warn("[DataService] using an unsaved profile for", player.Name)
		end
		profiles[player] = profile
		canSave[player] = saving
		DataService.fillHotbar(profile)
		publish(player)
		player:SetAttribute("DataLoaded", true)
		for _, callback in loadedCallbacks do
			task.spawn(callback, player, profile)
		end
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player, true)
		profiles[player] = nil
		canSave[player] = nil
		bonusPockets[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(cfg.AutosaveInterval)
			for player in profiles do
				task.spawn(save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
