-- Pockets: store Light items safe from bumps and waves. 3 slots from Deep Pockets (rebirth
-- reward), 3 more from a worn Deckhand's Satchel (exotic, attuned). Pockets are saved, sold
-- when you talk to the buyer (from anywhere), can be taken out one at a time, and drop where
-- you die if you drown. Unlock items can't be pocketed.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local GrabService = require(script.Parent.GrabService)
local ItemService = require(script.Parent.ItemService)

local PocketService = {}

local notify: (Player, string) -> () = function(_player: Player, _text: string) end

-- Puts a pocketed item back into the world as a loose item owned by the player.
local function release(player: Player, entry: DataService.PocketEntry, position: Vector3)
	local def = Items.get(entry.ItemId)
	local item = ItemService.spawnAt(def, entry.Zone, position)
	item:SetAttribute("Owner", player.UserId)
	ItemService.setLoose(item)
end

-- Removes and returns everything in the player's pockets (for selling).
function PocketService.takeAll(player: Player): { DataService.PocketEntry }
	local profile = DataService.get(player)
	if not profile then
		return {}
	end
	local list = profile.Pockets
	profile.Pockets = {}
	DataService.changed(player)
	return list
end

local function store(player: Player, part: any)
	local profile = DataService.get(player)
	local slots = DataService.pocketSlots(player)
	if not profile or slots == 0 then
		return
	end
	local item = GrabService.getHeld(player)
	if not item or item ~= part then
		return
	end
	if item:GetAttribute("Unlock") then
		notify(player, "Unlock items can't go in your pockets. Bank them at the bank house.")
		return
	end
	if (item:GetAttribute("Class") or 1) ~= Gear.WeightClass.Light then
		notify(player, "Only Light items fit in your pockets.")
		return
	end
	if #profile.Pockets >= slots then
		notify(player, "Your pockets are full.")
		return
	end
	table.insert(profile.Pockets, {
		ItemId = item:GetAttribute("ItemId"),
		Zone = item:GetAttribute("Zone") or 1,
		Value = item:GetAttribute("Value") or 0,
	})
	ItemService.destroy(item)
	DataService.changed(player)
end

-- Takes one item out of a pocket slot (the last one if no slot is given).
function PocketService.drop(player: Player, slot: number?)
	local profile = DataService.get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not profile or #profile.Pockets == 0 or not root then
		return
	end
	local index = if slot and profile.Pockets[slot] then slot else #profile.Pockets
	local entry = table.remove(profile.Pockets, index) :: DataService.PocketEntry
	release(player, entry, root.Position + root.CFrame.LookVector * 4 + Vector3.new(0, 1, 0))
	DataService.changed(player)
end

function PocketService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	Remotes.get("Pocket").OnServerEvent:Connect(function(player, action, arg)
		if action == "store" then
			store(player, arg)
		elseif action == "drop" then
			PocketService.drop(player, if type(arg) == "number" then math.floor(arg) else nil)
		end
	end)

	local function onCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			-- Pocketed items drop where you died.
			local profile = DataService.get(player)
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not profile or not root or #profile.Pockets == 0 then
				return
			end
			for index, entry in profile.Pockets do
				release(player, entry, root.Position + Vector3.new(index - 2, 2, 0))
			end
			profile.Pockets = {}
			DataService.changed(player)
		end)
	end
	local function onPlayer(player: Player)
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
end

return PocketService
