-- Server side of grabbing. The client does the actual dragging (it owns the item's physics);
-- the server decides who may grab what, and keeps checking that held items stay plausible.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)
local Gear = require(Shared.Gear)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)
local Tide = require(Shared.Tide)

local DataService = require(script.Parent.DataService)
local ItemService = require(script.Parent.ItemService)
local VesselService = require(script.Parent.VesselService)

local cfg = Config.Items

local GrabService = {}

local heldBy: { [Player]: BasePart } = {}
local notify: (Player, string) -> () = function(_player: Player, _text: string) end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function GrabService.getHeld(player: Player): BasePart?
	return heldBy[player]
end

-- Drops whatever the player holds where it is.
function GrabService.forceRelease(player: Player)
	local item = heldBy[player]
	heldBy[player] = nil
	if item and ItemService.isItem(item) and ItemService.getState(item) == "Held" then
		ItemService.setLoose(item)
	end
end

local function grabItem(player: Player, item: BasePart, root: BasePart): (boolean, string?)
	local state = ItemService.getState(item)
	if state == "Held" then
		if heldBy[player] == item then
			return true
		end
		return false, "Someone is already holding that"
	end
	if state ~= "Unclaimed" and not ItemService.isOwnedBy(item, player) then
		return false, "That belongs to someone else"
	end

	local tool = Gear.getTool(player:GetAttribute("Tool"))
	if tool.NoGrab then
		return false, "Your " .. tool.Name .. " can't pick things up"
	end
	if (item.Position - root.Position).Magnitude > tool.Reach + cfg.ReachSlack then
		return false, "Too far away"
	end
	if (item:GetAttribute("Class") or 1) > Stats.lift(player, tool) then
		return false, "Too heavy for your " .. tool.Name
	end
	if state ~= "InVessel" and not Gear.canReachDepth(tool, Beach.depthBand(item.Position, Tide.sea())) then
		return false, "Too deep for your " .. tool.Name
	end

	GrabService.forceRelease(player)
	ItemService.setHeld(item, player)
	heldBy[player] = item

	-- Finding something on the beach yourself records it in your lexicon.
	if state == "Unclaimed" then
		local itemId = item:GetAttribute("ItemId")
		if DataService.recordLexicon(player, itemId) then
			local def = Items.get(itemId)
			notify(
				player,
				string.format(
					"New lexicon entry: %s! (%d/%d)",
					if def then def.Name else itemId,
					player:GetAttribute("LexiconCount") or 0,
					#Items.Lexicon
				)
			)
		end
	end
	return true
end

local function onGrabRequest(player: Player, part: any): (boolean, string?)
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return false, "Invalid"
	end
	local root = rootOf(player)
	if not root then
		return false, "You can't grab right now"
	end

	if CollectionService:HasTag(part, VesselService.HandleTag) then
		local vessel = VesselService.getVessel(player)
		if not vessel or part.Parent ~= vessel then
			return false, "That isn't your vessel"
		end
		if (part.Position - root.Position).Magnitude > Config.Grab.VesselHandleReach + cfg.ReachSlack then
			return false, "Too far away"
		end
		GrabService.forceRelease(player)
		return true, "vessel"
	end

	if not ItemService.isItem(part) then
		return false, "You can't grab that"
	end
	return grabItem(player, part, root)
end

local function onRelease(player: Player, part: any)
	local item = heldBy[player]
	if not item or item ~= part then
		return
	end
	heldBy[player] = nil
	if not ItemService.isItem(item) then
		return
	end

	local vessel = VesselService.getVessel(player)
	if vessel and VesselService.isOverCargo(vessel, item.Position) then
		local ok, reason = VesselService.load(player, item)
		if ok then
			return
		end
		notify(player, reason or "Couldn't load that")
	end
	ItemService.setLoose(item)
end

local function onSendToVessel(player: Player, part: any)
	local item = heldBy[player]
	if not item or item ~= part or not ItemService.isItem(item) then
		return
	end
	local root = rootOf(player)
	local vessel = VesselService.getVessel(player)
	if not root or not vessel or not vessel.PrimaryPart then
		notify(player, "You don't have a vessel out")
		return
	end
	if (vessel.PrimaryPart.Position - root.Position).Magnitude > Config.Grab.AssistRange + cfg.ReachSlack then
		notify(player, "Your vessel is too far away")
		return
	end
	local ok, reason = VesselService.load(player, item)
	if ok then
		heldBy[player] = nil
	else
		notify(player, reason or "Couldn't load that")
	end
end

-- Held items must stay near the holder and move at sane speeds. This is the main
-- protection against exploiters flinging owned items around.
local function leashTick()
	for player, item in heldBy do
		if
			not ItemService.isItem(item)
			or ItemService.getState(item) ~= "Held"
			or not ItemService.isOwnedBy(item, player)
		then
			heldBy[player] = nil
			continue
		end
		local root = rootOf(player)
		local tool = Gear.getTool(player:GetAttribute("Tool"))
		if
			not root
			or (item.Position - root.Position).Magnitude > tool.Reach + cfg.HeldLeash
			or item.AssemblyLinearVelocity.Magnitude > cfg.MaxHeldSpeed
		then
			GrabService.forceRelease(player)
		end
	end
end

function GrabService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn

	Remotes.get("GrabRequest").OnServerInvoke = function(player: Player, part: any)
		local ok, granted, reason = pcall(onGrabRequest, player, part)
		if not ok then
			warn("[GrabService] grab request from", player.Name, "errored:", granted)
			return false, "Grab failed (server error)"
		end
		return granted, reason
	end
	Remotes.get("Release").OnServerEvent:Connect(onRelease)
	Remotes.get("SendToVessel").OnServerEvent:Connect(onSendToVessel)

	ItemService.onDestroyed(function(item)
		for player, held in heldBy do
			if held == item then
				heldBy[player] = nil
			end
		end
	end)

	local function onCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			-- What they carried drops and is lost to the tide or the timeout.
			GrabService.forceRelease(player)
		end)
	end
	local function onPlayer(player: Player)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		player.CharacterRemoving:Connect(function()
			GrabService.forceRelease(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		heldBy[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			leashTick()
		end
	end)
end

return GrabService
