-- Trading between two players on the same server.
--   * One player invites another; the invite expires after a while.
--   * Both sides offer items (only tradeable ones) and coins.
--   * Any change clears both accepts and starts a short countdown before anyone can accept,
--     so nobody can swap something out at the last second.
--   * When both accept, DataService.executeTrade re-checks everything and swaps it in one
--     step. Coins are taxed (Config.Trading.CoinTax) so they can't be parked for free.
-- Everything is decided here on the server; clients only send requests and draw the state.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local VesselService = require(script.Parent.VesselService)

local cfg = Config.Trading

local TradeService = {}

type Offer = { Items: { [string]: boolean }, Coins: number }
type Session = {
	players: { Player },
	offers: { [Player]: Offer },
	accepted: { [Player]: boolean },
	unlockAt: number, -- os.clock() when accepting is allowed again
	finished: boolean,
}

local sessions: { [Player]: Session } = {}
local invites: { [Player]: { [Player]: number } } = {} -- target -> sender -> expiry (os.clock())
local notify: (Player, string) -> () = function(_player: Player, _text: string) end
local syncRemote

local function partnerOf(session: Session, player: Player): Player
	return if session.players[1] == player then session.players[2] else session.players[1]
end

local function describeOffer(owner: Player, offer: Offer)
	local profile = DataService.get(owner)
	local items = {}
	for uid in offer.Items do
		local record = profile and profile.Items[uid]
		if record then
			table.insert(items, {
				Uid = uid,
				Id = record.Id,
				Variant = record.Variant,
				Serial = record.Serial,
				Of = record.Of,
			})
		end
	end
	table.sort(items, function(x, y)
		return x.Id < y.Id
	end)
	return { Items = items, Coins = offer.Coins, Receives = math.floor(offer.Coins * (1 - cfg.CoinTax)) }
end

-- Sends a player everything their trade screen shows.
local function sync(player: Player)
	if not player.Parent then
		return
	end
	local incoming = {}
	for sender, expiry in invites[player] or {} do
		if expiry > os.clock() and sender.Parent then
			table.insert(incoming, { UserId = sender.UserId, Name = sender.DisplayName })
		end
	end
	local session = sessions[player]
	local state: any = { Invites = incoming, Tax = cfg.CoinTax }
	if session then
		local partner = partnerOf(session, player)
		state.Trading = true
		state.Partner = partner.DisplayName
		state.Mine = describeOffer(player, session.offers[player])
		state.Theirs = describeOffer(partner, session.offers[partner])
		state.MyAccepted = session.accepted[player] == true
		state.TheirAccepted = session.accepted[partner] == true
		state.CountdownLeft = math.max(0, session.unlockAt - os.clock())
	end
	syncRemote:FireClient(player, state)
end

local function syncSession(session: Session)
	for _, player in session.players do
		sync(player)
	end
end

local function close(session: Session, message: string?)
	session.finished = true
	for _, player in session.players do
		if sessions[player] == session then
			sessions[player] = nil
		end
		if message then
			notify(player, message)
		end
		sync(player)
	end
end

-- Something changed: nobody is accepted any more, and the countdown restarts.
local function changed(session: Session)
	for _, player in session.players do
		session.accepted[player] = false
	end
	session.unlockAt = os.clock() + cfg.Countdown
	syncSession(session)
end

local function startSession(a: Player, b: Player)
	local session: Session = {
		players = { a, b },
		offers = { [a] = { Items = {}, Coins = 0 }, [b] = { Items = {}, Coins = 0 } },
		accepted = {},
		unlockAt = os.clock() + cfg.Countdown,
		finished = false,
	}
	sessions[a] = session
	sessions[b] = session
	invites[a] = nil
	invites[b] = nil
	syncSession(session)
end

local function execute(session: Session)
	local a, b = session.players[1], session.players[2]
	local ok, reason = DataService.executeTrade(a, b, session.offers[a], session.offers[b], cfg.CoinTax)
	if not ok then
		close(session, "Trade cancelled: " .. tostring(reason))
		return
	end
	-- A vessel that changed hands can't stay out for its old owner.
	for _, player in session.players do
		local vessel = VesselService.getVessel(player)
		if vessel and DataService.countItemType(player, vessel:GetAttribute("Kind")) == 0 then
			VesselService.despawn(player)
		end
	end
	close(session, "Trade complete!")
end

local actions = {}

function actions.request(player: Player, userId: any): (boolean, string?)
	local target = type(userId) == "number" and Players:GetPlayerByUserId(userId)
	if not target or target == player then
		return false, "That player isn't here"
	end
	if sessions[player] then
		return false, "Finish your current trade first"
	end
	if sessions[target] then
		return false, target.DisplayName .. " is already trading"
	end
	if not DataService.get(player) or not DataService.get(target) then
		return false, "Still loading"
	end
	-- They already invited you: just start.
	local mine = invites[player]
	if mine and mine[target] and mine[target] > os.clock() then
		startSession(player, target)
		return true
	end
	invites[target] = invites[target] or {}
	invites[target][player] = os.clock() + cfg.InviteTimeout
	notify(target, player.DisplayName .. " wants to trade. Press T to answer.")
	sync(target)
	return true, "Trade request sent to " .. target.DisplayName
end

function actions.respond(player: Player, userId: any, accept: any): (boolean, string?)
	local sender = type(userId) == "number" and Players:GetPlayerByUserId(userId)
	local expiry = sender and invites[player] and invites[player][sender]
	if not sender or not expiry or expiry < os.clock() then
		return false, "That invite has expired"
	end
	invites[player][sender] = nil
	if accept ~= true then
		notify(sender, player.DisplayName .. " declined your trade.")
		sync(player)
		return true
	end
	if sessions[player] or sessions[sender] then
		sync(player)
		return false, "One of you is already trading"
	end
	startSession(sender, player)
	return true
end

function actions.offerItem(player: Player, uid: any, add: any): (boolean, string?)
	local session = sessions[player]
	local profile = DataService.get(player)
	if not session or not profile or type(uid) ~= "string" then
		return false, "You're not trading"
	end
	local offer = session.offers[player]
	if add == true then
		local record = profile.Items[uid]
		local entry = record and Catalog.get(record.Id)
		if not record or not entry then
			return false, "You don't have that"
		end
		if not entry.Tradeable then
			return false, entry.Name .. " can't be traded"
		end
		local count = 0
		for _ in offer.Items do
			count += 1
		end
		if count >= cfg.MaxItemsPerSide then
			return false, "That's the most items one side can offer"
		end
		offer.Items[uid] = true
	else
		offer.Items[uid] = nil
	end
	changed(session)
	return true
end

function actions.offerCoins(player: Player, amount: any): (boolean, string?)
	local session = sessions[player]
	local profile = DataService.get(player)
	if not session or not profile or type(amount) ~= "number" or amount ~= amount then
		return false, "You're not trading"
	end
	session.offers[player].Coins = math.clamp(math.floor(amount), 0, profile.Coins)
	changed(session)
	return true
end

function actions.accept(player: Player, value: any): (boolean, string?)
	local session = sessions[player]
	if not session then
		return false, "You're not trading"
	end
	if value == true and os.clock() < session.unlockAt then
		return false, "Wait for the countdown"
	end
	session.accepted[player] = value == true
	local partner = partnerOf(session, player)
	if session.accepted[player] and session.accepted[partner] then
		execute(session)
	else
		syncSession(session)
	end
	return true
end

function actions.cancel(player: Player): (boolean, string?)
	local session = sessions[player]
	if session then
		close(session, player.DisplayName .. " cancelled the trade.")
	end
	return true
end

function actions.sync(player: Player): (boolean, string?)
	sync(player)
	return true
end

-- For tools/tests.
TradeService._actions = actions
TradeService._sessions = sessions

function TradeService.isTrading(player: Player): boolean
	return sessions[player] ~= nil
end

function TradeService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	syncRemote = Remotes.get("TradeSync")
	Remotes.handle("Trade", function(player: Player, action: any, ...)
		local handler = type(action) == "string" and actions[action]
		if not handler then
			return false, "Unknown trade action"
		end
		return handler(player, ...)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			close(session, player.DisplayName .. " left, so the trade was cancelled.")
		end
		invites[player] = nil
		for _, list in invites do
			list[player] = nil
		end
	end)
end

return TradeService
