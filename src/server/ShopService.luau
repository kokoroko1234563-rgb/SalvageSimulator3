-- The main shopkeeper (buying gear, respawning vessels), the buyer (selling what's on the sell
-- pad, and your pockets) and the banker (unlock items on the bank floor go into the inventory).

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Rebirth = require(Shared.Rebirth)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local ItemService = require(script.Parent.ItemService)
local PocketService = require(script.Parent.PocketService)
local VesselService = require(script.Parent.VesselService)

local ShopService = {}

local notify: (Player, string) -> () = function(_player: Player, _text: string) end
local shopkeeper: Model
local buyer: Model
local banker: Model
local sellZone: BasePart
local bankPad: BasePart

function ShopService.nearShop(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local target = shopkeeper:GetPivot().Position
	return root ~= nil and (root.Position - target).Magnitude <= Config.Selling.ShopkeeperRange
end

-- What the buyer pays for items worth `value` in all (their Value attributes, which already
-- hold the zone's multiplier): times the rebirth multiplier and any pass multiplier. Takes
-- plain numbers, so the bots (which have no Player) are paid the same way.
function ShopService.payout(value: number, rebirths: number, passMultiplier: number?): number
	return math.floor(value * Rebirth.multiplier(rebirths) * (passMultiplier or 1))
end

-- A shop listing: the tool or vessel (category "Tool" or "Vessel") with this id if the shop
-- sells it, else nil. Its Price is what the shop charges.
function ShopService.listing(category: string, id: string)
	if category == "Tool" then
		local tool = Gear.getTool(id)
		return if tool.Id == id and tool.Available then tool else nil
	elseif category == "Vessel" then
		local vessel = Gear.getVessel(id)
		return if vessel and vessel.Available then vessel else nil
	end
	return nil
end

local function onBuy(player: Player, category: any, id: any): (boolean, string?)
	if type(category) ~= "string" or type(id) ~= "string" then
		return false, "Invalid"
	end
	local profile = DataService.get(player)
	if not profile then
		return false, "Still loading"
	end
	if not ShopService.nearShop(player) then
		return false, "Talk to the shopkeeper to buy"
	end

	if category == "Tool" then
		local tool = Gear.getTool(id)
		if tool.Id ~= id or not tool.Available then
			return false, "Not for sale"
		end
		if DataService.countItemType(player, id) > 0 then
			return false, "You already own that"
		end
		if not DataService.trySpend(player, tool.Price) then
			return false, "Not enough coins"
		end
		DataService.addItem(player, id, "shop")
		profile.EquippedTool = id
		DataService.changed(player)
		notify(player, "Bought " .. tool.Name .. "! It's equipped, and in your inventory (I).")
		return true
	elseif category == "Vessel" then
		local vessel = Gear.getVessel(id)
		if not vessel or not vessel.Available then
			return false, "Not for sale"
		end
		if DataService.countItemType(player, id) > 0 then
			return false, "You already own that"
		end
		if not DataService.trySpend(player, vessel.Price) then
			return false, "Not enough coins"
		end
		DataService.addItem(player, id, "shop")
		VesselService.spawn(player, id)
		notify(player, "Bought " .. vessel.Name .. "! Spawn it any time from your inventory (I).")
		return true
	end
	return false, "Invalid"
end

function ShopService.spawnVessel(player: Player, id: any): (boolean, string?)
	if type(id) ~= "string" then
		return false, "Invalid"
	end
	local profile = DataService.get(player)
	if not profile or DataService.countItemType(player, id) == 0 then
		return false, "You don't own that"
	end
	if not DataService.canUse(player, id) then
		return false, "Attune to it first (1 attunement core)"
	end
	return VesselService.spawn(player, id)
end

local function inPad(pad: BasePart, position: Vector3): boolean
	local rel = pad.CFrame:PointToObjectSpace(position)
	local half = pad.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and rel.Y > -3 and rel.Y < 10
end

local function inSellZone(position: Vector3): boolean
	return inPad(sellZone, position)
end

-- Banking happens when you talk to the banker. Banks every unlock item of yours on the bank
-- floor, so items lying there are safe in the inventory from now on.
local function bankFromFloor(player: Player)
	local count = 0
	for item in ItemService.all() do
		if
			ItemService.getOwnerId(item) == player.UserId
			and item:GetAttribute("Unlock")
			and inPad(bankPad, item.Position)
		then
			local itemId = item:GetAttribute("ItemId")
			item:SetAttribute("BankedBy", player.DisplayName)
			ItemService.destroy(item)
			DataService.addItem(player, itemId, "beach")
			notify(player, "Banked a " .. Items.get(itemId).Name .. "!")
			count += 1
		end
	end
	if count == 0 then
		notify(player, "Nothing to bank. Drop unlock items on the purple floor, then talk to the banker.")
	end
end

-- Selling happens only when you talk to the buyer. Sells every item of yours on the sell pad,
-- and everything in your pockets wherever you're standing.
local function sellFromPad(player: Player)
	local earned = 0
	local count = 0
	for item in ItemService.all() do
		if
			ItemService.getOwnerId(item) == player.UserId
			and not item:GetAttribute("Unlock")
			and inSellZone(item.Position)
		then
			earned += item:GetAttribute("Value") or 0
			count += 1
			ItemService.destroy(item)
		end
	end
	for _, entry in PocketService.takeAll(player) do
		earned += entry.Value
		count += 1
	end

	if count == 0 then
		notify(player, "Nothing on the sell pad. Drop items on the yellow pad, then talk to the buyer.")
		return
	end
	local profile = DataService.get(player)
	local total = ShopService.payout(
		earned,
		if profile then profile.Rebirths else 0,
		MonetizationService.sellMultiplier(player)
	)
	DataService.addCoins(player, total)
	local plural = if count == 1 then "" else "s"
	notify(player, string.format("Sold %d item%s for +%d coins", count, plural, total))
end

function ShopService.init(map: Instance, notifyFn: (Player, string) -> ())
	notify = notifyFn
	local shop = map:WaitForChild("Shop")
	shopkeeper = shop:WaitForChild("Shopkeeper") :: Model
	sellZone = shop:WaitForChild("SellZone") :: BasePart
	bankPad = shop:WaitForChild("BankPad") :: BasePart
	buyer = shop:WaitForChild("Buyer") :: Model
	banker = shop:WaitForChild("Banker") :: Model

	Remotes.handle("Buy", onBuy)
	Remotes.handle("SpawnVessel", ShopService.spawnVessel)

	local openShop = Remotes.get("OpenShop")
	local prompt = shopkeeper:WaitForChild("HumanoidRootPart"):WaitForChild("ShopPrompt") :: ProximityPrompt
	prompt.Triggered:Connect(function(player)
		openShop:FireClient(player)
	end)

	local buyerPrompt = buyer:WaitForChild("HumanoidRootPart"):WaitForChild("BuyerPrompt") :: ProximityPrompt
	buyerPrompt.Triggered:Connect(sellFromPad)

	local bankerRoot = banker:WaitForChild("HumanoidRootPart")
	local bankerPrompt = bankerRoot:WaitForChild("BankerPrompt") :: ProximityPrompt
	bankerPrompt.Triggered:Connect(bankFromFloor)
end

return ShopService
