-- The main shopkeeper: buying gear, respawning vessels, and the sell zone.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ItemService = require(script.Parent.ItemService)
local VesselService = require(script.Parent.VesselService)

local ShopService = {}

local notify: (Player, string) -> () = function(_player: Player, _text: string) end
local shopkeeper: BasePart
local sellZone: BasePart

local function nearShop(player: Player): boolean
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
	if not nearShop(player) then
		return false, "Talk to the shopkeeper to buy"
	end

	if category == "Tool" then
		local tool = Gear.getTool(id)
		if tool.Id ~= id or not tool.Available then
			return false, "Not for sale"
		end
		if profile.Tools[id] then
			return false, "You already own that"
		end
		if not DataService.trySpend(player, tool.Price) then
			return false, "Not enough coins"
		end
		DataService.grantTool(player, id)
		notify(player, "Bought " .. tool.Name .. "!")
		return true
	elseif category == "Vessel" then
		local vessel = Gear.getVessel(id)
		if not vessel or not vessel.Available then
			return false, "Not for sale"
		end
		if profile.Vessels[id] then
			return false, "You already own that"
		end
		if not DataService.trySpend(player, vessel.Price) then
			return false, "Not enough coins"
		end
		DataService.grantVessel(player, id)
		VesselService.spawn(player, id)
		notify(player, "Bought " .. vessel.Name .. "! It's waiting on the blue pad.")
		return true
	end
	return false, "Invalid"
end

local function onSpawnVessel(player: Player, id: any): (boolean, string?)
	if type(id) ~= "string" then
		return false, "Invalid"
	end
	local profile = DataService.get(player)
	if not profile or not profile.Vessels[id] then
		return false, "You don't own that"
	end
	if not nearShop(player) then
		return false, "Vessels respawn at the shop"
	end
	return VesselService.spawn(player, id)
end

local function inSellZone(position: Vector3): boolean
	local rel = sellZone.CFrame:PointToObjectSpace(position)
	local half = sellZone.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and rel.Y > -3 and rel.Y < 10
end

local function sellTick()
	local earned: { [Player]: number } = {}
	for item in ItemService.all() do
		local ownerId = ItemService.getOwnerId(item)
		if ownerId ~= 0 and inSellZone(item.Position) then
			local owner = Players:GetPlayerByUserId(ownerId)
			if owner then
				earned[owner] = (earned[owner] or 0) + (item:GetAttribute("Value") or 0)
				ItemService.destroy(item)
			end
		end
	end
	for player, amount in earned do
		DataService.addCoins(player, amount)
		notify(player, "+" .. amount .. " coins")
	end
end

function ShopService.init(map: Instance, notifyFn: (Player, string) -> ())
	notify = notifyFn
	shopkeeper = map:WaitForChild("Shop"):WaitForChild("Shopkeeper") :: BasePart
	sellZone = map.Shop:WaitForChild("SellZone") :: BasePart

	Remotes.get("Buy").OnServerInvoke = onBuy
	Remotes.get("SpawnVessel").OnServerInvoke = onSpawnVessel

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
