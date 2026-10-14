-- The global auction: one lot at a time, shared by every server, on a fixed schedule
-- (lot N runs from Epoch + N*LotDuration). Each lot is a scarce cosmetic: one of a kind or
-- numbered ("#3 of 50").
--
--   * Bids are escrowed: your coins leave your save when you bid, and come back if you
--     don't win, even if you're on another server by then (through a refund ledger).
--   * The winning bid is destroyed (the main coin sink). The winner gets the item with its
--     serial number and their name on it, on whichever server they're on (a win ledger).
--   * Rebirthing cancels your bid and refunds it before the reset, so bids can't park coins.
--
-- Shared state: MemoryStoreService holds the live lots, DataStores hold the ledgers, series
-- counters and recent winners, MessagingService carries announcements. When those aren't
-- available (Studio without API access, tests) an in-memory stand-in keeps it working on
-- one server.

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)

local cfg = Config.Auction

local AuctionService = {}

AuctionService.OffsetAttribute = "AuctionOffset" -- admin: shifts the schedule (end a lot early)

local notify: (Player, string) -> () = function(_player: Player, _text: string) end

-- Storage --------------------------------------------------------------------------
-- One interface for both the real services and the single-server stand-in.

type Store = {
	getLot: (key: string) -> any,
	updateLot: (key: string, fn: (any) -> any) -> any, -- fn returns the new value, or nil to cancel
	updateLedger: (userId: number, fn: (any) -> any) -> any,
	updateSeries: (itemId: string, fn: (any) -> any) -> any,
	getSeries: (itemId: string) -> number,
	updateRecent: (fn: (any) -> any) -> any,
	getRecent: () -> any,
	publish: (message: any) -> (),
	subscribe: (handler: (any) -> ()) -> (),
}

local function localStore(): Store
	local lots, ledgers, series, recent = {}, {}, {}, {}
	local handlers = {}
	local function update(tbl, key, fn)
		local result = fn(tbl[key])
		if result ~= nil then
			tbl[key] = result
		end
		return result
	end
	return {
		getLot = function(key)
			return lots[key]
		end,
		updateLot = function(key, fn)
			return update(lots, key, fn)
		end,
		updateLedger = function(userId, fn)
			return update(ledgers, userId, fn)
		end,
		updateSeries = function(itemId, fn)
			return update(series, itemId, fn)
		end,
		getSeries = function(itemId)
			return series[itemId] or 0
		end,
		updateRecent = function(fn)
			local result = fn(recent)
			if result ~= nil then
				recent = result
			end
			return result
		end,
		getRecent = function()
			return recent
		end,
		publish = function(message)
			for _, handler in handlers do
				task.spawn(handler, message)
			end
		end,
		subscribe = function(handler)
			table.insert(handlers, handler)
		end,
	}
end

local function robloxStore(): Store
	local lotsMap = MemoryStoreService:GetSortedMap("Auction_v1")
	local ledger = DataStoreService:GetDataStore("AuctionLedger_v1")
	local seriesStore = DataStoreService:GetDataStore("AuctionSeries_v1")
	local resultsStore = DataStoreService:GetDataStore("AuctionResults_v1")
	local TWO_DAYS = 2 * 24 * 3600
	return {
		getLot = function(key)
			return lotsMap:GetAsync(key)
		end,
		updateLot = function(key, fn)
			return lotsMap:UpdateAsync(key, fn, TWO_DAYS)
		end,
		updateLedger = function(userId, fn)
			return ledger:UpdateAsync("u_" .. userId, fn)
		end,
		updateSeries = function(itemId, fn)
			return seriesStore:UpdateAsync(itemId, fn)
		end,
		getSeries = function(itemId)
			return seriesStore:GetAsync(itemId) or 0
		end,
		updateRecent = function(fn)
			return resultsStore:UpdateAsync("recent", fn)
		end,
		getRecent = function()
			return resultsStore:GetAsync("recent") or {}
		end,
		publish = function(message)
			pcall(MessagingService.PublishAsync, MessagingService, "Auction_v1", message)
		end,
		subscribe = function(handler)
			pcall(MessagingService.SubscribeAsync, MessagingService, "Auction_v1", function(packet)
				handler(packet.Data)
			end)
		end,
	}
end

local store: Store = localStore()

-- Schedule -------------------------------------------------------------------------

local function now(): number
	return os.time() + (Workspace:GetAttribute(AuctionService.OffsetAttribute) or 0)
end

local function lotIndex(at: number): number
	return math.floor((at - cfg.Epoch) / cfg.LotDuration)
end

local function lotKey(index: number): string
	return "lot_" .. index
end

local function lotItem(index: number)
	return Gear.getCosmetic(cfg.Lots[(index % #cfg.Lots) + 1])
end

local function topBid(lot): (number, string?, string?)
	local bestAmount, bestUser, bestName, bestTime = 0, nil, nil, math.huge
	for userId, bid in (lot and lot.Bids) or {} do
		if bid.Amount > bestAmount or (bid.Amount == bestAmount and (bid.Time or 0) < bestTime) then
			bestAmount, bestUser, bestName, bestTime = bid.Amount, userId, bid.Name, bid.Time or 0
		end
	end
	return bestAmount, bestUser, bestName
end

function AuctionService.minNextBid(top: number, startingBid: number): number
	if top <= 0 then
		return startingBid
	end
	return top + math.max(cfg.MinIncrement, math.ceil(top * cfg.MinIncrementFraction))
end

-- Cached view of the current lot (read every PollInterval, shared by all players here).
local cache = { index = -1, lot = nil :: any, issued = 0, recent = {} :: any }

local function refresh()
	local index = lotIndex(now())
	local okLot, lot = pcall(store.getLot, lotKey(index))
	local item = lotItem(index)
	local okSeries, issued = pcall(store.getSeries, item.Id)
	local okRecent, recent = pcall(store.getRecent)
	cache.index = index
	cache.lot = if okLot then lot else cache.lot
	cache.issued = if okSeries then issued else cache.issued
	cache.recent = if okRecent then recent else cache.recent
end

-- Ledgers --------------------------------------------------------------------------

-- Owes a player coins (on whichever server they're on next).
local function addRefund(userId: number, amount: number)
	if amount <= 0 then
		return
	end
	pcall(store.updateLedger, userId, function(old)
		old = old or { Refund = 0, Wins = {} }
		old.Refund = (old.Refund or 0) + amount
		return old
	end)
end

local function addWin(userId: number, win)
	pcall(store.updateLedger, userId, function(old)
		old = old or { Refund = 0, Wins = {} }
		old.Wins = old.Wins or {}
		table.insert(old.Wins, win)
		return old
	end)
end

-- Collects whatever this player is owed: refunds and won items.
local function collect(player: Player)
	if not DataService.get(player) then
		return
	end
	local claimed
	local ok = pcall(store.updateLedger, player.UserId, function(old)
		claimed = old
		if not old or ((old.Refund or 0) == 0 and #(old.Wins or {}) == 0) then
			return nil -- nothing to take
		end
		return { Refund = 0, Wins = {} }
	end)
	if not ok or not claimed then
		return
	end
	if (claimed.Refund or 0) > 0 then
		DataService.addCoins(player, claimed.Refund)
		notify(player, string.format("Auction refund: %d coins returned.", claimed.Refund))
	end
	for _, win in claimed.Wins or {} do
		DataService.addItem(
			player,
			win.ItemId,
			"auction",
			{ Serial = win.Serial, Of = win.Of, Winner = win.Winner }
		)
		local cosmetic = Gear.getCosmetic(win.ItemId)
		notify(
			player,
			string.format(
				"You won %s #%d of %d! It's in your inventory.",
				if cosmetic then cosmetic.Name else win.ItemId,
				win.Serial,
				win.Of
			)
		)
	end
end

-- Resolving ------------------------------------------------------------------------

-- Closes a finished lot. Only one server succeeds in marking it resolved, and that server
-- hands out the item and the refunds.
local function resolve(index: number)
	local mine = false
	local bids
	local ok = pcall(store.updateLot, lotKey(index), function(old)
		mine = false
		if not old or old.Resolved then
			return nil
		end
		mine = true
		bids = old.Bids or {}
		old.Resolved = true
		return old
	end)
	if not ok or not mine then
		return
	end

	local item = lotItem(index)
	local amount, winnerId, winnerName = topBid({ Bids = bids })
	if not winnerId then
		return
	end
	-- Next serial for this item, if any are left.
	local serial
	pcall(store.updateSeries, item.Id, function(old)
		local issued = old or 0
		if issued >= item.Auction.Of then
			serial = nil
			return nil
		end
		serial = issued + 1
		return serial
	end)
	for userId, bid in bids do
		if userId ~= winnerId or not serial then
			addRefund(tonumber(userId) :: number, bid.Amount)
		end
	end
	if not serial then
		return
	end
	addWin(
		tonumber(winnerId) :: number,
		{ ItemId = item.Id, Serial = serial, Of = item.Auction.Of, Winner = winnerName }
	)
	pcall(store.updateRecent, function(old)
		local list = old or {}
		table.insert(
			list,
			1,
			{ ItemId = item.Id, Serial = serial, Of = item.Auction.Of, Winner = winnerName, Amount = amount }
		)
		while #list > cfg.Recent do
			table.remove(list)
		end
		return list
	end)
	store.publish({
		Type = "won",
		Text = string.format(
			"%s won %s #%d of %d for %d coins!",
			tostring(winnerName),
			item.Name,
			serial,
			item.Auction.Of,
			amount
		),
	})
end

-- Bidding --------------------------------------------------------------------------

local function bid(player: Player, lotId: any, amount: any): (boolean, string?)
	local profile = DataService.get(player)
	if not profile then
		return false, "Still loading"
	end
	local index = lotIndex(now())
	if lotId ~= lotKey(index) then
		return false, "That lot has ended"
	end
	if type(amount) ~= "number" or amount ~= math.floor(amount) or amount <= 0 then
		return false, "Bid a whole number of coins"
	end
	local item = lotItem(index)
	if cache.index == index and cache.issued >= item.Auction.Of then
		return false, "Every " .. item.Name .. " has already been won"
	end
	local userKey = tostring(player.UserId)
	-- Read the lot fresh: how much more to take depends on this player's current bid.
	local okLot, freshLot = pcall(store.getLot, lotKey(index))
	if not okLot then
		return false, "The auction couldn't be reached. Try again."
	end
	local current = freshLot and freshLot.Bids and freshLot.Bids[userKey]
	local myEscrow = if current then current.Amount else 0
	local needed = amount - myEscrow
	if needed <= 0 then
		return false, "Bid more than your current bid"
	end
	if profile.Coins < needed then
		return false, "Not enough coins"
	end

	-- Take the coins first; give them back if the bid doesn't go through.
	profile.Coins -= needed
	DataService.changed(player)
	local reason
	local previousTopUser
	local ok, result = pcall(store.updateLot, lotKey(index), function(old)
		reason = nil
		local lot = old or { Bids = {} }
		lot.Bids = lot.Bids or {}
		if lot.Resolved then
			reason = "That lot has ended"
			return nil
		end
		local mineNow = lot.Bids[userKey]
		if (mineNow and mineNow.Amount or 0) ~= myEscrow then
			reason = "Your bid changed elsewhere. Try again."
			return nil
		end
		local top, topUser = topBid(lot)
		if amount < AuctionService.minNextBid(top, item.Auction.StartingBid) then
			reason = "Someone bid higher. The minimum is now "
				.. AuctionService.minNextBid(top, item.Auction.StartingBid)
			return nil
		end
		previousTopUser = topUser
		lot.Bids[userKey] = { Amount = amount, Name = player.DisplayName, Time = os.time() }
		return lot
	end)
	if not ok or result == nil then
		profile.Coins += needed
		DataService.changed(player)
		return false, reason or "The auction couldn't be reached. Your coins were returned."
	end
	cache.index = index
	cache.lot = result
	if previousTopUser and previousTopUser ~= userKey then
		store.publish({
			Type = "outbid",
			UserId = tonumber(previousTopUser),
			Text = player.DisplayName .. " outbid you on " .. item.Name .. "!",
		})
	end
	return true, string.format("You bid %d on %s.", amount, item.Name)
end

-- Cancels the player's bid on the current lot and refunds it (rebirths call this first,
-- so the refund is wiped by the reset like everything else).
function AuctionService.cancelBid(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end
	local userKey = tostring(player.UserId)
	local refund = 0
	pcall(store.updateLot, lotKey(lotIndex(now())), function(old)
		refund = 0
		if not old or old.Resolved or not old.Bids or not old.Bids[userKey] then
			return nil
		end
		refund = old.Bids[userKey].Amount
		old.Bids[userKey] = nil
		return old
	end)
	if refund > 0 then
		profile.Coins += refund
		DataService.changed(player)
		notify(player, string.format("Your auction bid of %d was cancelled by the rebirth.", refund))
	end
end

local function stateFor(player: Player)
	local index = lotIndex(now())
	local item = lotItem(index)
	local lot = if cache.index == index then cache.lot else nil
	local top, _, topName = topBid(lot)
	local mine = lot and lot.Bids and lot.Bids[tostring(player.UserId)]
	return {
		LotId = lotKey(index),
		ItemId = item.Id,
		Name = item.Name,
		Note = item.Note,
		Of = item.Auction.Of,
		Issued = cache.issued,
		Available = cache.issued < item.Auction.Of,
		TimeLeft = (cfg.Epoch + (index + 1) * cfg.LotDuration) - now(),
		StartingBid = item.Auction.StartingBid,
		TopBid = top,
		TopName = topName,
		MyBid = if mine then mine.Amount else 0,
		MinNext = AuctionService.minNextBid(top, item.Auction.StartingBid),
		Recent = cache.recent,
	}
end

-- For tools/tests.
AuctionService._bid = bid
AuctionService._resolve = resolve
AuctionService._collect = collect
AuctionService._stateFor = stateFor
AuctionService._lotIndex = function()
	return lotIndex(now())
end
function AuctionService._useStore(newStore)
	store = newStore
end
AuctionService._localStore = localStore

function AuctionService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	-- Use Roblox's shared services if they work here; otherwise, one-server mode.
	local ok = pcall(function()
		local probe = robloxStore()
		probe.getLot("probe")
		store = probe
	end)
	if not ok then
		warn("[Auction] MemoryStore/DataStore unavailable here: the auction runs on this server only.")
		store = localStore()
	end

	store.subscribe(function(message)
		if type(message) ~= "table" then
			return
		end
		if message.Type == "won" then
			for _, player in Players:GetPlayers() do
				notify(player, message.Text)
			end
		elseif message.Type == "outbid" then
			local player = Players:GetPlayerByUserId(message.UserId or 0)
			if player then
				notify(player, message.Text)
			end
		end
	end)

	Remotes.handle("AuctionBid", bid)
	Remotes.get("AuctionState").OnServerInvoke = function(player)
		local okState, state = pcall(stateFor, player)
		return if okState then state else nil
	end

	DataService.onLoaded(function(player)
		collect(player)
	end)

	task.spawn(function()
		local lastLedger = 0
		while true do
			refresh()
			local index = lotIndex(now())
			-- Close the lots that just finished (and one before, in case no server was up).
			resolve(index - 1)
			resolve(index - 2)
			if os.clock() - lastLedger > cfg.LedgerInterval then
				lastLedger = os.clock()
				for _, player in Players:GetPlayers() do
					task.spawn(collect, player)
				end
			end
			task.wait(cfg.PollInterval)
		end
	end)
end

return AuctionService
