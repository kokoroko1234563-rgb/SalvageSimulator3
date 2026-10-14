-- Deep Pockets (rebirth reward): store up to 3 Light items in your pockets, safe from bumps
-- and waves. Pockets are sold automatically on the sell pad, can be emptied in front of you,
-- and drop where you die if you drown. Unlock items can't be pocketed. Pocket contents last
-- for the session only.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local GrabService = require(script.Parent.GrabService)
local ItemService = require(script.Parent.ItemService)

local PocketService = {}

type Pocketed = { ItemId: string, Zone: number, Value: number }

local pockets: { [Player]: { Pocketed } } = {}
local notify: (Player, string) -> () = function(_player: Player, _text: string) end

local function publish(player: Player)
	local list = pockets[player] or {}
	local names = {}
	for _, entry in list do
		table.insert(names, Items.get(entry.ItemId).Name)
	end
	player:SetAttribute("Pockets", #list)
	player:SetAttribute("PocketItems", table.concat(names, ", "))
end

local function hasPockets(player: Player): boolean
	local profile = DataService.get(player)
	return profile ~= nil and profile.Rewards.DeepPockets == true
end

-- Puts a pocketed item back into the world as a loose item owned by the player.
local function release(player: Player, entry: Pocketed, position: Vector3)
	local def = Items.get(entry.ItemId)
	local item = ItemService.spawnAt(def, entry.Zone, position)
	item:SetAttribute("Owner", player.UserId)
	ItemService.setLoose(item)
end

-- Removes and returns everything in the player's pockets (for selling).
function PocketService.takeAll(player: Player): { Pocketed }
	local list = pockets[player] or {}
	pockets[player] = {}
	publish(player)
	return list
end

local function store(player: Player, part: any)
	if not hasPockets(player) then
		return
	end
	local item = GrabService.getHeld(player)
	if not item or item ~= part then
		return
	end
	if item:GetAttribute("Unlock") then
		notify(player, "Unlock items can't go in your pockets. Bank them at the shore.")
		return
	end
	if (item:GetAttribute("Class") or 1) ~= Gear.WeightClass.Light then
		notify(player, "Only Light items fit in your pockets.")
		return
	end
	local list = pockets[player] or {}
	if #list >= Config.Pockets.Slots then
		notify(player, "Your pockets are full.")
		return
	end
	table.insert(list, {
		ItemId = item:GetAttribute("ItemId"),
		Zone = item:GetAttribute("Zone") or 1,
		Value = item:GetAttribute("Value") or 0,
	})
	pockets[player] = list
	ItemService.destroy(item)
	publish(player)
end

local function drop(player: Player)
	local list = pockets[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not list or #list == 0 or not root then
		return
	end
	local entry = table.remove(list) :: Pocketed
	release(player, entry, root.Position + root.CFrame.LookVector * 4 + Vector3.new(0, 1, 0))
	publish(player)
end

function PocketService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	Remotes.get("Pocket").OnServerEvent:Connect(function(player, action, part)
		if action == "store" then
			store(player, part)
		elseif action == "drop" then
			drop(player)
		end
	end)

	local function onCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			-- Pocketed items drop where you died.
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local list = pockets[player]
			if root and list then
				for index, entry in list do
					release(player, entry, root.Position + Vector3.new(index - 2, 2, 0))
				end
			end
			pockets[player] = {}
			publish(player)
		end)
	end
	local function onPlayer(player: Player)
		pockets[player] = {}
		publish(player)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		pockets[player] = nil
	end)
end

return PocketService
