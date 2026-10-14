-- The main shopkeeper: buying gear, respawning vessels, and the sell zone.

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

local function sellTick()
	local earned: { [Player]: number } = {}
	for item in ItemService.all() do
		local ownerId = ItemService.getOwnerId(item)
		local owner = ownerId ~= 0 and Players:GetPlayerByUserId(ownerId)
		if not owner then
			continue
		end
		local unlock = item:GetAttribute("Unlock")
		if unlock and inPad(bankPad, item.Position) then
			-- Unlock items are banked, never sold: safe in the inventory from now on.
			local itemId = item:GetAttribute("ItemId")
			ItemService.destroy(item)
			DataService.addItem(owner, itemId, "beach")
			notify(owner, "Banked a " .. Items.get(itemId).Name .. "!")
		elseif not unlock and inSellZone(item.Position) then
			earned[owner] = (earned[owner] or 0) + (item:GetAttribute("Value") or 0)
			ItemService.destroy(item)
		end
	end
	-- Pockets empty themselves when you stand on the sell pad.
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and (player:GetAttribute("Pockets") or 0) > 0 and inSellZone(root.Position) then
			for _, entry in PocketService.takeAll(player) do
				earned[player] = (earned[player] or 0) + entry.Value
			end
		end
	end
	for player, amount in earned do
		local profile = DataService.get(player)
		local total = math.floor(amount * Rebirth.multiplier(if profile then profile.Rebirths else 0))
		DataService.addCoins(player, total)
		notify(player, "+" .. total .. " coins")
	end
end

function ShopService.init(map: Instance, notifyFn: (Player, string) -> ())
	notify = notifyFn
	shopkeeper = map:WaitForChild("Shop"):WaitForChild("Shopkeeper") :: BasePart
	sellZone = map.Shop:WaitForChild("SellZone") :: BasePart
	bankPad = map.Shop:WaitForChild("BankPad") :: BasePart

	Remotes.get("Buy").OnServerInvoke = onBuy
	Remotes.get("SpawnVessel").OnServerInvoke = ShopService.spawnVessel

	local openShop = Remotes.get("OpenShop")
	local prompt = shopkeeper:WaitForChild("ShopPrompt") :: ProximityPrompt
	prompt.Triggered:Connect(function(player)
		openShop:FireClient(player)
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			sellTick()
		end
	end)
end

return ShopService
