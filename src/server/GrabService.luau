-- Server side of grabbing. The client does the actual dragging (it owns the item's physics);
-- the server decides who may grab what, and keeps checking that held items stay plausible.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ItemService = require(script.Parent.ItemService)
local VesselService = require(script.Parent.VesselService)

local cfg = Config.Items

local GrabService = {}

-- What each player holds, oldest first. Most tools hold one item; the Crab Claw holds two
-- (Gear: Holds).
local heldBy: { [Player]: { BasePart } } = {}
-- Anchor Hook: when its next throw is ready, and until when a hooked item may be far from its
-- thrower (it is being reeled in).
local hookReadyAt: { [Player]: number } = {}
local reelUntil: { [BasePart]: number } = setmetatable({}, { __mode = "k" })
local notify: (Player, string) -> () = function(_player: Player, _text: string) end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- The item the player grabbed last (what the client is working with).
function GrabService.getHeld(player: Player): BasePart?
	local list = heldBy[player]
	return if list then list[#list] else nil
end

-- Everything the player holds, oldest first (a copy).
function GrabService.getAllHeld(player: Player): { BasePart }
	return table.clone(heldBy[player] or {})
end

local function isHeldBy(player: Player, item: BasePart): boolean
	return table.find(heldBy[player] or {}, item) ~= nil
end

local function dropFromList(player: Player, item: BasePart)
	local list = heldBy[player]
	local index = if list then table.find(list, item) else nil
	if list and index then
		table.remove(list, index)
		if #list == 0 then
			heldBy[player] = nil
		end
	end
end

local function holdCapacity(tool): number
	return tool.Holds or 1
end

local function releaseItem(player: Player, item: BasePart)
	dropFromList(player, item)
	if ItemService.isItem(item) and ItemService.getState(item) == "Held" then
		ItemService.setLoose(item)
	end
end

-- Drops whatever the player holds where it is.
function GrabService.forceRelease(player: Player)
	for _, item in GrabService.getAllHeld(player) do
		releaseItem(player, item)
	end
	heldBy[player] = nil
end

-- The rules for lifting an item, whoever lifts it (a player or a bot): the item must be free
-- (or already the owner's), the tool must be able to pick things up, the item within its reach
-- of `from`, and from no farther out than `lift` (a zone tier: the tool's, plus one with Strong
-- Back; Stats.lift). Inside a zone the tool works, it lifts everything, and the water's depth
-- doesn't matter. Returns ok, reason.
-- `reachScale` multiplies the tool's reach (the Anchor Hook's throw).
function GrabService.canClaim(
	item: BasePart,
	ownerId: number,
	tool,
	lift: number,
	from: Vector3,
	reachScale: number?
): (boolean, string?)
	local state = ItemService.getState(item)
	if state == "Held" then
		return false, "Someone is already holding that"
	end
	if state ~= "Unclaimed" and ItemService.getOwnerId(item) ~= ownerId then
		return false, "That belongs to someone else"
	end
	if tool.NoGrab then
		return false, "Your " .. tool.Name .. " can't pick things up"
	end
	local position = item.CFrame.Position
	if (position - from).Magnitude > tool.Reach * (reachScale or 1) + cfg.ReachSlack then
		return false, "Too far away"
	end
	if not Gear.canLift(lift, item:GetAttribute("Tier")) then
		return false, "Too far out for your " .. tool.Name
	end
	return true
end

-- Obsidian Grabber: the first grab of an item with it makes the item worth more, once.
local function applyValueBoost(item: BasePart, tool)
	if not tool.ValueBoost or item:GetAttribute("ObsidianBoost") then
		return
	end
	item:SetAttribute("ObsidianBoost", true)
	local value = item:GetAttribute("Value")
	if type(value) == "number" then
		item:SetAttribute("Value", math.floor(value * (1 + tool.ValueBoost) + 0.5))
	end
end

-- Gust Gloves: the vessel an item can be blown into from where the player stands, if any.
function GrabService.gustVessel(player: Player, root: BasePart, tool): Model?
	if not tool.Gust then
		return nil
	end
	local vessel = VesselService.getVessel(player)
	local base = vessel and vessel.PrimaryPart
	if base and (base.Position - root.Position).Magnitude <= tool.Gust.Range then
		return vessel
	end
	return nil
end

-- Grabs an item for a player. `hook` is the Anchor Hook's throw: reach 3x, on a cooldown, and the
-- item is allowed to be far away while it is reeled in. Returns ok, then "gust" when the Gust
-- Gloves blew the item straight into the vessel (it isn't held), or the reason it failed.
function GrabService.grab(player: Player, item: BasePart, root: BasePart, hook: boolean?): (boolean, string?)
	local state = ItemService.getState(item)
	if state == "Held" and isHeldBy(player, item) then
		return true
	end
	local tool = Gear.getTool(player:GetAttribute("Tool"))
	local reachScale = nil
	if hook then
		if not tool.Hook then
			return false, "You need an Anchor Hook to throw"
		end
		if os.clock() < (hookReadyAt[player] or 0) then
			return false, "The hook is still reeling in"
		end
		reachScale = tool.Hook.ReachScale
	end
	local ok, reason =
		GrabService.canClaim(item, player.UserId, tool, Stats.lift(player, tool), root.Position, reachScale)
	if not ok then
		return false, reason
	end

	-- Past the tool's capacity, the oldest hold is let go.
	while #(heldBy[player] or {}) >= holdCapacity(tool) do
		releaseItem(player, (heldBy[player] :: { BasePart })[1])
	end
	ItemService.setHeld(item, player)
	local list = heldBy[player] or {}
	table.insert(list, item)
	heldBy[player] = list
	applyValueBoost(item, tool)
	if hook then
		hookReadyAt[player] = os.clock() + tool.Hook.Cooldown
		reelUntil[item] = os.clock() + tool.Hook.ReelSeconds
	end

	-- Finding something on the beach yourself records it in your lexicon.
	if state == "Unclaimed" then
		local itemId = item:GetAttribute("ItemId")
		if DataService.recordLexicon(player, itemId) then
			local def = Items.get(itemId)
			-- (A biome item is counted on its biome's page.)
			local biome = if def and def.Biome then Biomes.List[def.Biome] else nil
			local found, total = player:GetAttribute("LexiconCount") or 0, #Items.Lexicon
			if biome then
				local page = Items.ofBiome(biome.Id)
				found, total = DataService.lexiconFound(player, page), #page
			end
			notify(
				player,
				string.format(
					"New %slexicon entry: %s! (%d/%d)",
					if biome then biome.Name .. " " else "",
					if def then def.Name else itemId,
					found,
					total
				)
			)
		end
	end

	-- Gust Gloves: with your vessel close, the item is blown straight into it (the same load the
	-- send-to-vessel button uses, so a full vessel refuses). If it can't go, you simply hold it.
	if GrabService.gustVessel(player, root, tool) then
		local loaded, why = VesselService.load(player, item)
		if loaded then
			dropFromList(player, item)
			return true, "gust"
		end
		notify(player, why or "Couldn't load that")
	end
	return true
end

local function onGrabRequest(player: Player, part: any, mode: any): (boolean, string?)
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
	return GrabService.grab(player, part, root, mode == "hook")
end

local function onRelease(player: Player, part: any)
	if typeof(part) ~= "Instance" or not isHeldBy(player, part :: BasePart) then
		return
	end
	local item = part :: BasePart
	dropFromList(player, item)
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
	if typeof(part) ~= "Instance" or not isHeldBy(player, part :: BasePart) then
		return
	end
	local item = part :: BasePart
	if not ItemService.isItem(item) then
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
		dropFromList(player, item)
	else
		notify(player, reason or "Couldn't load that")
	end
end

-- Held items must stay near the holder and move at sane speeds. This is the main
-- protection against exploiters flinging owned items around.
local function leashTick()
	for player, list in heldBy do
		local tool = Gear.getTool(player:GetAttribute("Tool"))
		local root = rootOf(player)
		for _, item in table.clone(list) do
			if
				not ItemService.isItem(item)
				or ItemService.getState(item) ~= "Held"
				or not ItemService.isOwnedBy(item, player)
			then
				dropFromList(player, item)
				continue
			end
			-- A hooked item is far away until it has been reeled in.
			local reach = if (reelUntil[item] or 0) > os.clock() and tool.Hook
				then tool.Reach * tool.Hook.ReachScale
				else tool.Reach
			if
				not root
				or (item.Position - root.Position).Magnitude > reach + cfg.HeldLeash
				or item.AssemblyLinearVelocity.Magnitude > cfg.MaxHeldSpeed
			then
				releaseItem(player, item)
			end
		end
		-- Swapped to a tool that holds fewer: the oldest holds go.
		local remaining = heldBy[player]
		while remaining and #remaining > holdCapacity(tool) do
			releaseItem(player, remaining[1])
			remaining = heldBy[player]
		end
	end
end

function GrabService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn

	Remotes.get("GrabRequest").OnServerInvoke = function(player: Player, part: any, mode: any)
		local ok, granted, reason = pcall(onGrabRequest, player, part, mode)
		if not ok then
			warn("[GrabService] grab request from", player.Name, "errored:", granted)
			return false, "Grab failed (server error)"
		end
		return granted, reason
	end
	Remotes.get("Release").OnServerEvent:Connect(onRelease)
	Remotes.get("SendToVessel").OnServerEvent:Connect(onSendToVessel)

	ItemService.onDestroyed(function(item)
		for player in heldBy do
			dropFromList(player, item)
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
		hookReadyAt[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			leashTick()
		end
	end)
end

return GrabService
