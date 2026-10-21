-- A bot's purse, gear and buying rule, with no engine objects in it (so Lune can test it). It lives
-- in memory only: nothing here touches DataService or any DataStore.
--
-- Prices are the game's own: what a bot is paid comes from ShopService.payout (item Value, which
-- holds the zone multiplier, times the rebirth multiplier), what it buys comes from the shop's
-- listings (Gear.Tools and Gear.Vessels through ShopService.listing), and a rebirth costs
-- Rebirth.cost and gives Rebirth.multiplier.
--
-- The one buying rule, for every bot: rebirth as soon as it can be afforded (taking the reward
-- that raises income most); otherwise buy the thing that raises income most for its price,
-- among what it can afford. "Income" is `BotEconomy.income`, the bot's own estimate of what a
-- tide's worth of work brings in with some gear: the items of the zones its tool works (every
-- item up to the tool's tier) in the zones the tide leaves it time to work, as many per trip as
-- its vessel carries, against the walk there and back.

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Rebirth = require(Shared.Rebirth)
local Stats = require(Shared.Stats)
local Beach = require(Shared.Beach)
local Tide = require(Shared.Tide)

local ShopService = require(script.Parent.ShopService)

local BotEconomy = {}

export type State = {
	Coins: number,
	Rebirths: number,
	Rewards: { [string]: boolean },
	Tools: { [string]: boolean }, -- shop tools bought and magical grabbers won
	Vessels: { [string]: boolean },
	PendingPick: { string }?,
}

BotEconomy.WalkSpeed = 16 -- studs a second on dry sand: the player's (Stats.walkSpeed)
BotEconomy.MazeFactor = 1.3 -- how much longer a real route is than the straight line
BotEconomy.ItemSeconds = 6 -- walking between items and lifting each one into the cart
BotEconomy.SellSeconds = 10

function BotEconomy.newState(): State
	return {
		Coins = 0,
		Rebirths = 0,
		Rewards = {},
		Tools = { BareHands = true },
		Vessels = {},
		PendingPick = nil,
	}
end

-- Gear -----------------------------------------------------------------------------------

-- The tool a bot uses: the best it owns (the highest tier, then the longest reach).
function BotEconomy.tool(state: State)
	local best = Gear.Tools[1]
	local function rank(tool): number
		return tool.Tier * 1e3 + tool.Reach
	end
	for _, tool in Gear.Tools do
		if state.Tools[tool.Id] and not tool.NoGrab and not tool.Exotic and rank(tool) > rank(best) then
			best = tool
		end
	end
	return best
end

-- The vessel a bot tows: the one that carries most (nil: it carries one thing in its hands).
function BotEconomy.vessel(state: State)
	local best = nil
	for _, vessel in Gear.Vessels do
		if state.Vessels[vessel.Id] and (not best or vessel.Capacity > best.Capacity) then
			best = vessel
		end
	end
	return best
end

-- The highest zone tier it lifts (its tool's, one more with Strong Back).
function BotEconomy.lift(state: State, tool): number
	return Stats.liftWith(tool, state.Rewards.StrongBack == true)
end

function BotEconomy.capacity(state: State): number
	local vessel = BotEconomy.vessel(state)
	return (if vessel then vessel.Capacity else 1)
		+ (if state.Rewards.DeepPockets then Config.Pockets.Slots else 0)
end

function BotEconomy.walkSpeed(state: State): number
	return BotEconomy.WalkSpeed * (if state.Rewards.SwiftFeet then Rebirth.SwiftFeetSpeed else 1)
end

-- Whether a bot's cart can only take the gentler slope (it has a vessel with wheels or runners).
function BotEconomy.cartSize(state: State): string?
	local vessel = BotEconomy.vessel(state)
	return if vessel and not vessel.Flies then vessel.Size else nil
end

-- Estimating income ----------------------------------------------------------------------

-- Share of a tide cycle during which the waterline is where zone `z`'s surf items wash up
-- (the waterline within 70 studs short of the zone, to its far edge).
local zoneWindow: { [number]: number } = {}
do
	local cfg = Config.Tide
	local length = cfg.OutTime + cfg.HoldTime + cfg.InTime
	local samples = 600
	local counts = {}
	for i = 0, samples - 1 do
		local t = (i + 0.5) / samples * length
		local wl
		if t < cfg.OutTime then
			wl = cfg.HighWaterline
				+ (cfg.LowWaterline - cfg.HighWaterline) * Tide._shaped(cfg.OutShape, t / cfg.OutTime)
		elseif t < cfg.OutTime + cfg.HoldTime then
			wl = cfg.LowWaterline
		else
			local p = (t - cfg.OutTime - cfg.HoldTime) / cfg.InTime
			wl = cfg.LowWaterline - (cfg.LowWaterline - cfg.HighWaterline) * Tide._shaped(cfg.InShape, p)
		end
		for z = 1, #Config.Zones do
			local z0, z1 = Beach.zoneRange(z)
			if wl >= z0 - 70 and wl <= z1 + 5 then
				counts[z] = (counts[z] or 0) + 1
			end
		end
	end
	for z = 1, #Config.Zones do
		zoneWindow[z] = (counts[z] or 0) / samples
	end
end
BotEconomy.CycleSeconds = Config.Tide.OutTime + Config.Tide.HoldTime + Config.Tide.InTime

-- The share of the water where heavy things lie (ItemService moves them out into knee- to
-- waist-deep water) that a bot will wade into: it keeps this far short of waist depth.
BotEconomy.WadeMargin = 1.0
local heavyReach = math.clamp(
	(Config.Beach.WaistDepth - BotEconomy.WadeMargin - Config.Beach.ShallowDepth)
		/ (Config.Beach.WaistDepth - 0.3 - Config.Beach.ShallowDepth),
	0,
	1
)

-- What a spawned item in zone `z` is worth to a bot, and how likely it can take it:
-- (expected value over all spawns, chance a spawn can be taken). Zone `z` washes up only items of
-- tier `z`, so a tool that works the zone (its lift tier at least `z`) can take them all, bar the
-- heavy things lying in water deeper than a bot wades; one that doesn't can take none.
local function zoneYield(z: number, lift: number): (number, number)
	if z > lift then
		return 0, 0
	end
	local weights = Config.Zones[z].Rarity or {}
	local total = 0
	for _, w in weights do
		total += w
	end
	local value, chance = 0, 0
	for rarity, w in weights do
		local pool = Items.ofTier(z, rarity)
		for _, def in pool do
			local share = (w / total) / #pool
			local reach = if def.Class >= Gear.WeightClass.Heavy then heavyReach else 1
			value += share * reach * def.Value * Config.Zones[z].Multiplier
			chance += share * reach
		end
	end
	return value, chance
end

-- Estimated coins a tide brings in with this gear (coins as paid, with the rebirth multiplier).
function BotEconomy.income(state: State): number
	local tool = BotEconomy.tool(state)
	local lift = BotEconomy.lift(state, tool)
	local capacity = BotEconomy.capacity(state)
	local speed = BotEconomy.walkSpeed(state)
	local best = 0
	for z = 1, #Config.Zones do
		local window = zoneWindow[z] * BotEconomy.CycleSeconds
		local z0, z1 = Beach.zoneRange(z)
		local travel = (z0 + z1) / 2 / speed * BotEconomy.MazeFactor
		local value, chance = zoneYield(z, lift)
		if value > 0 and chance > 0 then
			local perItem = value / chance
			-- Filling the cart takes a while when few of what washes up can be taken.
			local fill = capacity * BotEconomy.ItemSeconds * (1 + 0.5 / math.max(chance, 0.05))
			local trip = 2 * travel + fill + BotEconomy.SellSeconds
			local trips = math.max(0, (window - travel) / trip)
			best = math.max(best, trips * capacity * perItem)
		end
	end
	return best * Rebirth.multiplier(state.Rebirths)
end

-- Buying --------------------------------------------------------------------------------

local function with(state: State, category: string, id: string): State
	local copy = table.clone(state)
	copy.Tools = table.clone(state.Tools)
	copy.Vessels = table.clone(state.Vessels)
	if category == "Tool" then
		copy.Tools[id] = true
	else
		copy.Vessels[id] = true
	end
	return copy
end

export type Purchase = { Category: string, Id: string, Name: string, Price: number, Gain: number }

-- Everything the shop sells that this state doesn't own, with the income it would add per
-- coin; best first. (Only what's affordable when `affordable` is set.)
function BotEconomy.options(state: State, affordable: boolean?): { Purchase }
	local base = BotEconomy.income(state)
	local list = {}
	for _, entry in { { "Tool", Gear.Tools }, { "Vessel", Gear.Vessels } } do
		local category, defs = entry[1], entry[2]
		for _, def in defs do
			if
				ShopService.listing(category, def.Id)
				and def.Price > 0
				and not (if category == "Tool" then state.Tools[def.Id] else state.Vessels[def.Id])
				and (not affordable or state.Coins >= def.Price)
			then
				local gain = BotEconomy.income(with(state, category, def.Id)) - base
				if gain > 0 then
					table.insert(
						list,
						{ Category = category, Id = def.Id, Name = def.Name, Price = def.Price, Gain = gain }
					)
				end
			end
		end
	end
	table.sort(list, function(a, b)
		local ra, rb = a.Gain / a.Price, b.Gain / b.Price
		if ra ~= rb then
			return ra > rb
		end
		return a.Price < b.Price
	end)
	return list
end

-- What the bot buys next, or nil.
function BotEconomy.nextPurchase(state: State): Purchase?
	return BotEconomy.options(state, true)[1]
end

function BotEconomy.buy(state: State, purchase: Purchase): boolean
	if state.Coins < purchase.Price or not ShopService.listing(purchase.Category, purchase.Id) then
		return false
	end
	state.Coins -= purchase.Price
	if purchase.Category == "Tool" then
		state.Tools[purchase.Id] = true
	else
		state.Vessels[purchase.Id] = true
	end
	return true
end

-- Selling: coins for items worth `value` (their Value attributes added up), as ShopService pays.
function BotEconomy.sell(state: State, value: number): number
	local paid = ShopService.payout(value, state.Rebirths, 1)
	state.Coins += paid
	return paid
end

-- Rebirth --------------------------------------------------------------------------------

function BotEconomy.rebirthCost(state: State): number
	return Rebirth.cost(state.Rebirths)
end

function BotEconomy.canRebirth(state: State): boolean
	return state.PendingPick == nil and state.Coins >= Rebirth.cost(state.Rebirths)
end

-- The reward a bot takes from its options: the one after which its income is highest.
function BotEconomy.bestReward(state: State, options: { string }): string?
	local best, bestIncome = nil, -1
	for _, id in options do
		local trial = table.clone(state)
		trial.Rewards = table.clone(state.Rewards)
		trial.Tools = table.clone(state.Tools)
		trial.Vessels = table.clone(state.Vessels)
		BotEconomy.grant(trial, id)
		local income = BotEconomy.income(trial)
		if income > bestIncome then
			best, bestIncome = id, income
		end
	end
	return best
end

-- A reward: a modifier, or a magical grabber or vessel that stays through rebirths.
function BotEconomy.grant(state: State, id: string)
	local reward = Rebirth.Rewards[id]
	if not reward then
		return
	end
	state.Rewards[id] = true
	if reward.GrantsItem then
		if Gear.findTool(reward.GrantsItem) then
			state.Tools[reward.GrantsItem] = true
		elseif Gear.getVessel(reward.GrantsItem) then
			state.Vessels[reward.GrantsItem] = true
		end
	end
end

-- Rebirths (as RebirthService does, but in memory): coins and shop gear reset, the count goes
-- up, and for the first rewards a pick is taken at once. Returns the reward picked, if any.
function BotEconomy.rebirth(state: State): string?
	assert(BotEconomy.canRebirth(state), "can't afford to rebirth")
	state.Coins = 0
	state.Rebirths += 1
	-- Shop gear goes; magical grabbers and vessels from rewards stay.
	local tools = { BareHands = true }
	for id in state.Tools do
		local reward = Gear.getTool(id)
		if reward.Magical then
			tools[id] = true
		end
	end
	state.Tools = tools
	local vessels = {}
	for id in state.Vessels do
		local vessel = Gear.getVessel(id)
		if vessel and vessel.Magical then
			vessels[id] = true
		end
	end
	state.Vessels = vessels
	if state.Rebirths <= Config.Rebirth.MaxPicks then
		local options = Rebirth.remaining(state.Rewards)
		local pick = BotEconomy.bestReward(state, options)
		if pick then
			BotEconomy.grant(state, pick)
			return pick
		end
	end
	return nil
end

-- A comma list of the gear, for logs.
function BotEconomy.gearOf(
	state: State
): { Tool: string, Vessel: string?, Rebirths: number, Rewards: { string } }
	local tool = BotEconomy.tool(state)
	local vessel = BotEconomy.vessel(state)
	local rewards = {}
	for id in state.Rewards do
		table.insert(rewards, id)
	end
	table.sort(rewards)
	return {
		Tool = tool.Id,
		Vessel = if vessel then vessel.Id else nil,
		Rebirths = state.Rebirths,
		Rewards = rewards,
	}
end

return BotEconomy
