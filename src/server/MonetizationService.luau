-- Robux purchases and private servers.
--   * Coin packs are developer products. ProcessReceipt grants each purchase exactly once:
--     the purchase id is stored on the profile and saved before Roblox is told it's done, so
--     a crash, a retry or a second server can never grant it twice or lose it.
--   * Gamepasses are checked when a player joins and when they buy one in game. Owned passes
--     are published as the "Passes" attribute (comma-separated ids) for the shop UI.
--   * Private servers: rare spawns scale with the player count, reaching normal at
--     Config.Monetization.FullRatePlayers, so solo farming isn't worth it. The scale is the
--     Workspace attribute "RareSpawnScale" (1 everywhere else), which ItemService reads.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)

local DataService = require(script.Parent.DataService)

local cfg = Config.Monetization

local MonetizationService = {}

MonetizationService.ScaleAttribute = "RareSpawnScale"

local notify: (Player, string) -> () = function(_player: Player, _text: string) end
local passes: { [Player]: { [string]: boolean } } = {}
local simulatedPlayers: number? = nil -- admin console: pretend this is a private server

local function passById(id: string)
	for _, pass in cfg.Gamepasses do
		if pass.Id == id then
			return pass
		end
	end
	return nil
end

-- Product ids are numbers in Config, but receipts can't be trusted to match types exactly.
local function sameId(a: any, b: any): boolean
	return tonumber(a) ~= nil and tonumber(a) == tonumber(b)
end

local function packFor(productId: any)
	for _, pack in cfg.CoinPacks do
		if pack.ProductId ~= 0 and sameId(pack.ProductId, productId) then
			return pack
		end
	end
	return nil
end

-- Pass effects ------------------------------------------------------------------------

function MonetizationService.hasPass(player: Player, id: string): boolean
	local owned = passes[player]
	return owned ~= nil and owned[id] == true
end

-- Multiplier on everything this player sells.
function MonetizationService.sellMultiplier(player: Player): number
	local multiplier = 1
	for id in passes[player] or {} do
		local pass = passById(id)
		if pass and pass.SellMultiplier then
			multiplier *= pass.SellMultiplier
		end
	end
	return multiplier
end

local function applyPasses(player: Player)
	local owned = passes[player] or {}
	local ids = {}
	local slots = 0
	for _, pass in cfg.Gamepasses do
		if owned[pass.Id] then
			table.insert(ids, pass.Id)
			slots += pass.PocketSlots or 0
		end
	end
	player:SetAttribute("Passes", table.concat(ids, ","))
	DataService.setBonusPockets(player, slots)
end

-- Gives or takes a pass for this session only (admin console, for testing a pass's effect
-- before it exists on Roblox).
function MonetizationService.setPass(player: Player, id: string, owned: boolean): boolean
	if not passById(id) then
		return false
	end
	passes[player] = passes[player] or {}
	passes[player][id] = if owned then true else nil
	applyPasses(player)
	return true
end

local function checkPasses(player: Player)
	passes[player] = passes[player] or {}
	for _, pass in cfg.Gamepasses do
		if not player.Parent then
			passes[player] = nil -- left while we were asking
			return
		end
		if pass.PassId ~= 0 then
			local ok, owns = pcall(
				MarketplaceService.UserOwnsGamePassAsync,
				MarketplaceService,
				player.UserId,
				pass.PassId
			)
			if ok and owns then
				passes[player][pass.Id] = true
			elseif not ok then
				warn("[Monetization] couldn't check pass", pass.Id, "for", player.Name, owns)
			end
		end
	end
	applyPasses(player)
end

-- Coin packs ---------------------------------------------------------------------------

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		-- They left: Roblox retries the next time they join a server.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = DataService.get(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)
	if table.find(profile.Receipts, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- granted before; the ack got lost
	end
	local pack = packFor(receipt.ProductId)
	if not pack then
		warn("[Monetization] no coin pack has product id", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- A profile that isn't being saved would forget the coins; wait for one that is. Studio
	-- test purchases are free and never retried, so grant those anyway.
	local persistent = DataService.isPersistent(player)
	if not persistent and not RunService:IsStudio() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	table.insert(profile.Receipts, purchaseId)
	while #profile.Receipts > cfg.ReceiptMemory do
		table.remove(profile.Receipts, 1)
	end
	DataService.addCoins(player, pack.Coins)
	if persistent and not DataService.saveNow(player) then
		-- Undo, so the retry grants it cleanly.
		local index = table.find(profile.Receipts, purchaseId)
		if index then
			table.remove(profile.Receipts, index)
		end
		DataService.setCoins(player, math.max(0, profile.Coins - pack.Coins))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	notify(player, string.format("Thanks! +%d coins (%s)", pack.Coins, pack.Name))
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Private servers ----------------------------------------------------------------------

local function isPrivateServer(): boolean
	-- Reserved servers (PrivateServerOwnerId 0) are made by the game itself, not bought.
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

-- How rare spawns are scaled right now (1 = normal).
function MonetizationService.rareScale(): number
	local count = simulatedPlayers
	if not count then
		if not isPrivateServer() then
			return 1
		end
		count = #Players:GetPlayers()
	end
	return math.clamp(count / cfg.FullRatePlayers, 0, 1)
end

local function updateScale()
	Workspace:SetAttribute(MonetizationService.ScaleAttribute, MonetizationService.rareScale())
end

-- Admin console: act as a private server with this many players (nil = back to real).
function MonetizationService.simulatePrivate(players: number?)
	simulatedPlayers = players
	updateScale()
end

function MonetizationService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, pass in cfg.Gamepasses do
			if pass.PassId ~= 0 and sameId(pass.PassId, passId) then
				MonetizationService.setPass(player, pass.Id, true)
				notify(player, "Thanks! " .. pass.Name .. " is active.")
			end
		end
	end)

	local function onPlayer(player: Player)
		task.spawn(checkPasses, player)
		updateScale()
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		passes[player] = nil
		task.defer(updateScale) -- after they've left the player list
	end)
	updateScale()
end

-- For tools/tests.
MonetizationService._processReceipt = processReceipt

return MonetizationService
