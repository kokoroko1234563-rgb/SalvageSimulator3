-- The main shopkeeper (buying gear, respawning vessels), the buyer (selling what's on the sell
-- pad) and the bank floor (unlock items go into the inventory).

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Rebirth = require(Shared.Rebirth)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ItemService = require(script.Parent.ItemService)
local PocketService = require(script.Parent.PocketService)
local VesselService = require(script.Parent.VesselService)

local ShopService = {}

local notify: (Player, string) -> () = function(_player: Player, _text: string) end
local shopkeeper: BasePart
local buyer: BasePart
local sellZone: BasePart
local bankPad: BasePart

function ShopService.nearShop(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - shopkeeper.Position).Magnitude <= Config.Selling.ShopkeeperRange
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

-- Banking is automatic: unlock items on the bank floor go into the owner's inventory.
local function bankTick()
	for item in ItemService.all() do
		local ownerId = ItemService.getOwnerId(item)
		local owner = ownerId ~= 0 and Players:GetPlayerByUserId(ownerId)
		if not owner then
			continue
		end
		if item:GetAttribute("Unlock") and inPad(bankPad, item.Position) then
			-- Unlock items are banked, never sold: safe in the inventory from now on.
			local itemId = item:GetAttribute("ItemId")
			item:SetAttribute("BankedBy", owner.DisplayName)
			ItemService.destroy(item)
			DataService.addItem(owner, itemId, "beach")
			notify(owner, "Banked a " .. Items.get(itemId).Name .. "!")
		end
	end
end

-- Selling happens only when you talk to the buyer. Sells every item of yours on the sell pad,
-- and your pockets too if you're standing on it.
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
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and (player:GetAttribute("Pockets") or 0) > 0 and inSellZone(root.Position) then
		for _, entry in PocketService.takeAll(player) do
			earned += entry.Value
			count += 1
		end
	end

	if count == 0 then
		notify(player, "Nothing on the sell pad. Drop items on the yellow pad, then talk to the buyer.")
		return
	end
	local profile = DataService.get(player)
	local total = math.floor(earned * Rebirth.multiplier(if profile then profile.Rebirths else 0))
	DataService.addCoins(player, total)
	local plural = if count == 1 then "" else "s"
	notify(player, string.format("Sold %d item%s for +%d coins", count, plural, total))
end

function ShopService.init(map: Instance, notifyFn: (Player, string) -> ())
	notify = notifyFn
	local shop = map:WaitForChild("Shop")
	shopkeeper = shop:WaitForChild("Shopkeeper") :: BasePart
	sellZone = shop:WaitForChild("SellZone") :: BasePart
	bankPad = shop:WaitForChild("BankPad") :: BasePart
	buyer = shop:WaitForChild("Buyer") :: BasePart

	Remotes.handle("Buy", onBuy)
	Remotes.handle("SpawnVessel", ShopService.spawnVessel)

	local openShop = Remotes.get("OpenShop")
	local prompt = shopkeeper:WaitForChild("ShopPrompt") :: ProximityPrompt
	prompt.Triggered:Connect(function(player)
		openShop:FireClient(player)
	end)

	local buyerPrompt = buyer:WaitForChild("BuyerPrompt") :: ProximityPrompt
	buyerPrompt.Triggered:Connect(sellFromPad)

	task.spawn(function()
		while true do
			task.wait(0.25)
			bankTick()
		end
	end)
end

return ShopService
