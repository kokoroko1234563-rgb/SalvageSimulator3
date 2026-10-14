-- Saves coins and owned gear with DataStoreService.
--   * Every DataStore call is wrapped in pcall and retried.
--   * UpdateAsync with a session lock (JobId + timestamp) stops two servers from holding the
--     same profile at once, which is how items get duplicated.
--   * Saves on autosave, PlayerRemoving and BindToClose.
-- In Studio without "Enable Studio Access to API Services", data loads as a fresh profile
-- and is not saved.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Rebirth = require(Shared.Rebirth)
local Secrets = require(Shared.Secrets)

local cfg = Config.Data

local DataService = {}

export type Profile = {
	Version: number,
	Coins: number,
	Tools: { [string]: boolean },
	Vessels: { [string]: boolean },
	Rebirths: number,
	Rewards: { [string]: boolean },
	PendingPick: { string }?, -- reward options waiting for the player to choose one
	UnlockItems: { [string]: number }, -- banked unlock items by item id
	ColoredCoins: { [string]: boolean },
}

local function defaultProfile(): Profile
	return {
		Version = 1,
		Coins = 0,
		Tools = { BareHands = true },
		Vessels = {},
		Rebirths = 0,
		Rewards = {},
		PendingPick = nil,
		UnlockItems = {},
		ColoredCoins = {},
	}
end

local profiles: { [Player]: Profile } = {}
local canSave: { [Player]: boolean } = {}
local loadedCallbacks = {}

local store: DataStore? = nil

local function keyFor(player: Player): string
	return "p_" .. player.UserId
end

local function reconcile(data: any): Profile
	local profile = defaultProfile()
	if type(data) ~= "table" then
		return profile
	end
	if type(data.Coins) == "number" then
		profile.Coins = math.max(0, math.floor(data.Coins))
	end
	if type(data.Tools) == "table" then
		for id, owned in data.Tools do
			if owned == true and Gear.getTool(id).Id == id then
				profile.Tools[id] = true
			end
		end
	end
	if type(data.Vessels) == "table" then
		for id, owned in data.Vessels do
			if owned == true and Gear.getVessel(id) then
				profile.Vessels[id] = true
			end
		end
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
	if type(data.UnlockItems) == "table" then
		for id, count in data.UnlockItems do
			local def = Items.get(id)
			if def and def.Unlock and type(count) == "number" and count > 0 then
				profile.UnlockItems[id] = math.floor(count)
			end
		end
	end
	if type(data.ColoredCoins) == "table" then
		for color, owned in data.ColoredCoins do
			if owned == true and Secrets.CoinColors[color] then
				profile.ColoredCoins[color] = true
			end
		end
	end
	return profile
end

local function serialize(profile: Profile, release: boolean)
	return {
		Version = profile.Version,
		Coins = profile.Coins,
		Tools = profile.Tools,
		Vessels = profile.Vessels,
		Rebirths = profile.Rebirths,
		Rewards = profile.Rewards,
		PendingPick = profile.PendingPick,
		UnlockItems = profile.UnlockItems,
		ColoredCoins = profile.ColoredCoins,
		Lock = if release then nil else { JobId = game.JobId, Time = os.time() },
	}
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

-- Mirrors the profile onto player attributes so clients can show it.
local function publish(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	player:SetAttribute("Coins", profile.Coins)
	player:SetAttribute("Tool", Gear.bestTool(profile.Tools).Id)
	player:SetAttribute("OwnedTools", csv(profile.Tools, Gear.Tools))
	player:SetAttribute("OwnedVessels", csv(profile.Vessels, Gear.Vessels))
	player:SetAttribute("Rebirths", profile.Rebirths)
	player:SetAttribute("Multiplier", Rebirth.multiplier(profile.Rebirths))
	player:SetAttribute("Rewards", csv(profile.Rewards, rewardList))
	player:SetAttribute("PendingPick", table.concat(profile.PendingPick or {}, ","))
	local unlocks = {}
	for id, count in profile.UnlockItems do
		table.insert(unlocks, id .. ":" .. count)
	end
	table.sort(unlocks)
	player:SetAttribute("UnlockItems", table.concat(unlocks, ","))
	local coins = {}
	for _, color in Secrets.CoinOrder do
		if profile.ColoredCoins[color] then
			table.insert(coins, color)
		end
	end
	player:SetAttribute("ColoredCoins", table.concat(coins, ","))
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

function DataService.grantUnlock(player: Player, id: string, count: number)
	local profile = profiles[player]
	if profile then
		profile.UnlockItems[id] = math.max(0, (profile.UnlockItems[id] or 0) + count)
		if profile.UnlockItems[id] == 0 then
			profile.UnlockItems[id] = nil
		end
		publish(player)
	end
end

function DataService.grantColoredCoin(player: Player, color: string)
	local profile = profiles[player]
	if profile then
		profile.ColoredCoins[color] = true
		publish(player)
	end
end

function DataService.grantTool(player: Player, id: string)
	local profile = profiles[player]
	if profile then
		profile.Tools[id] = true
		publish(player)
	end
end

function DataService.grantVessel(player: Player, id: string)
	local profile = profiles[player]
	if profile then
		profile.Vessels[id] = true
		publish(player)
	end
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
