-- Special traders. When a biome rolls, its trader sometimes appears at a spot in that zone
-- until the zone changes. Talking to them shows their offer; each appearance sells a player
-- at most one level of the trader's upgrade. Levels cost coins plus the biome's own items,
-- which the player brings: items count if they're near the trader, in the player's vessel,
-- or in their pockets. Madame Gull takes attunement cores instead.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)
local Traders = require(Shared.Traders)

local Buildings = require(script.Parent.Buildings)
local BiomeService = require(script.Parent.BiomeService)
local MapParts = require(script.Parent.MapParts)
local DataService = require(script.Parent.DataService)
local ItemService = require(script.Parent.ItemService)
local RebirthService = require(script.Parent.RebirthService)

local cfg = Config.Traders

local TraderService = {}

local rng = Random.new()
local notify: (Player, string) -> () = function(_player: Player, _text: string) end
local openRemote
local active: { [string]: { trader: any, model: Model, bought: { [number]: boolean } } } = {} -- by encounter id

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- The player's items of a type that count as "brought": near the trader, in their vessel,
-- or held. Returns the item parts.
local function broughtItems(player: Player, itemId: string, near: Vector3): { BasePart }
	local found = {}
	for item in ItemService.all() do
		if item:GetAttribute("ItemId") == itemId and ItemService.isOwnedBy(item, player) then
			local state = ItemService.getState(item)
			if
				state == "InVessel"
				or state == "Held"
				or (item.Position - near).Magnitude <= cfg.BringRadius
			then
				table.insert(found, item)
			end
		end
	end
	return found
end

local function pocketCount(player: Player, itemId: string): number
	local profile = DataService.get(player)
	local count = 0
	for _, entry in (profile and profile.Pockets) or {} do
		if entry.ItemId == itemId then
			count += 1
		end
	end
	return count
end

-- What the trader screen shows this player.
local function offerFor(player: Player, encounterId: string)
	local encounter = active[encounterId]
	local profile = DataService.get(player)
	if not encounter or not profile then
		return nil
	end
	local trader = encounter.trader
	local upgrade = Traders.Upgrades[trader.Upgrade]
	local level = profile.Upgrades[trader.Upgrade] or 0
	local cost = Traders.cost(trader, level + 1)
	local item = trader.PaidWithItem and Items.get(trader.PaidWithItem)
	local have = if item
		then #broughtItems(player, item.Id, encounter.model:GetPivot().Position) + pocketCount(
			player,
			item.Id
		)
		else 0
	return {
		EncounterId = encounterId,
		Name = trader.Name,
		Greeting = trader.Greeting,
		Upgrade = upgrade.Name,
		Effect = upgrade.Effect,
		Level = level,
		MaxLevel = upgrade.MaxLevel,
		Coins = cost.Coins,
		Items = cost.Items,
		Cores = cost.Cores,
		ItemName = if item then item.Name else nil,
		ItemsHere = have,
		BoughtThisVisit = encounter.bought[player.UserId] == true,
		Permanent = upgrade.Permanent == true,
	}
end

local function open(player: Player, encounterId: string)
	local offer = offerFor(player, encounterId)
	if offer then
		openRemote:FireClient(player, offer)
	end
end

local function buy(player: Player, encounterId: any): (boolean, string?)
	local encounter = type(encounterId) == "string" and active[encounterId]
	local profile = DataService.get(player)
	local root = rootOf(player)
	if not encounter or not encounter.model.Parent or not profile or not root then
		return false, "The trader has gone"
	end
	local traderPos = encounter.model:GetPivot().Position
	if (root.Position - traderPos).Magnitude > 25 then
		return false, "Get closer to the trader"
	end
	if encounter.bought[player.UserId] then
		return false, "One level per visit. Come back next time they appear."
	end
	local trader = encounter.trader
	local upgradeId = trader.Upgrade
	local level = profile.Upgrades[upgradeId] or 0
	if level >= Traders.Upgrades[upgradeId].MaxLevel then
		return false, "You've maxed that upgrade"
	end
	local cost = Traders.cost(trader, level + 1)
	if profile.Coins < cost.Coins then
		return false, "Not enough coins"
	end
	if profile.Cores < cost.Cores then
		return false, "Not enough attunement cores"
	end
	local parts, pockets = {}, 0
	if cost.Items > 0 then
		parts = broughtItems(player, trader.PaidWithItem, traderPos)
		pockets = pocketCount(player, trader.PaidWithItem)
		if #parts + pockets < cost.Items then
			return false,
				string.format(
					"Bring %d %s (you have %d here)",
					cost.Items,
					Items.get(trader.PaidWithItem).Name,
					#parts + pockets
				)
		end
	end

	-- Pay: items on the beach first, then pockets, then coins and cores.
	local remaining = cost.Items
	for _, part in parts do
		if remaining == 0 then
			break
		end
		ItemService.destroy(part)
		remaining -= 1
	end
	if remaining > 0 then
		local kept = {}
		for _, entry in profile.Pockets do
			if remaining > 0 and entry.ItemId == trader.PaidWithItem then
				remaining -= 1
			else
				table.insert(kept, entry)
			end
		end
		profile.Pockets = kept
	end
	profile.Coins -= cost.Coins
	profile.Cores -= cost.Cores
	profile.Upgrades[upgradeId] = level + 1
	encounter.bought[player.UserId] = true
	DataService.changed(player)
	RebirthService.applyEffects(player)
	notify(player, string.format("%s is now level %d!", Traders.Upgrades[upgradeId].Name, level + 1))
	open(player, encounterId)
	return true
end

-- Builds a trader standing in a zone. Returns the model.
function TraderService.spawn(trader, zone: number, parent: Instance): Model
	local startZ = Beach.zoneRange(zone)
	local z = startZ + 65
	local x = rng:NextNumber(-Beach.HalfWidth + 30, Beach.HalfWidth - 30)
	local groundY = Beach.groundY(z)
	local model = Instance.new("Model")
	model.Name = "Trader_" .. trader.Id
	local function part(name: string, size: Vector3, offset: Vector3, color: Color3)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = CFrame.new(x, groundY, z) * CFrame.new(offset)
		p.Color = color
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local stall = part("Stall", Vector3.new(6, 2.4, 2.4), Vector3.new(0, 1.2, -3), Palette.World.Boardwalk)
	stall.Material = Palette.Material.WoodPlanks
	-- The trader is a real Roblox character, standing behind the stall.
	local avatar = Buildings.person(model, "Trader", CFrame.new(x, groundY, z), Palette.World.TraderCoat)
	model.PrimaryPart = avatar.PrimaryPart :: BasePart
	-- The name board stands on the stall's counter (2.4 high, centred 3 studs in front).
	MapParts.sign(model, trader.Name, CFrame.new(x, groundY + 2.4 + 0.8, z - 3), 6, 1.6)

	local encounterId = HttpService:GenerateGUID(false)
	model:SetAttribute("EncounterId", encounterId)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = trader.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = avatar.PrimaryPart
	prompt.Triggered:Connect(function(player)
		open(player, encounterId)
	end)

	active[encounterId] = { trader = trader, model = model, bought = {} }
	model.Destroying:Connect(function()
		active[encounterId] = nil
	end)
	model.Parent = parent
	return model
end

-- Madame Gull's Tide Reading: tells the player about rare biomes, by level.
local function readTide(player: Player)
	local profile = DataService.get(player)
	local level = profile and profile.Upgrades.TideReading or 0
	if level == 0 then
		return
	end
	local rare
	for zone = 1, Config.Beach.ActiveZones do
		local biome = Biomes.activeIn(zone)
		if biome and biome.Tier ~= "Common" then
			rare = { biome = biome, zone = zone }
			break
		end
	end
	if not rare then
		notify(player, "Tide Reading: no rare biome this tide.")
	elseif level == 1 then
		notify(player, "Tide Reading: a rare biome is out this tide.")
	elseif level == 2 then
		notify(player, "Tide Reading: an " .. rare.biome.Tier:lower() .. " rare biome is out this tide.")
	else
		notify(
			player,
			string.format(
				"Tide Reading: an %s rare biome is out in zone %d.",
				rare.biome.Tier:lower(),
				rare.zone
			)
		)
	end
end

function TraderService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	openRemote = Remotes.get("TraderOpen")
	Remotes.handle("TraderBuy", buy)

	BiomeService.onBiomeSet(function(zone, biome, zoneFolder)
		for _, trader in Traders.List do
			if trader.Biome == biome.Id then
				local chance = if biome.Tier == "Common" then cfg.CommonChance else cfg.RareChance
				if rng:NextNumber() < chance then
					TraderService.spawn(trader, zone, zoneFolder)
				end
			end
		end
	end)
	BiomeService.onRerolled(function()
		for _, player in Players:GetPlayers() do
			readTide(player)
		end
	end)
	DataService.onLoaded(function(player)
		task.wait(3) -- after the join messages settle
		readTide(player)
	end)
end

return TraderService
