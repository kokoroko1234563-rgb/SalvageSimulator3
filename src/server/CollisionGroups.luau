-- Collision groups.
--   Characters: player bodies.
--   Items: loose and held items. They bump into characters and each other.
--   Vessel1..VesselN: one group per player slot, holding that player's vessel and its
--   contents. Vessels only touch the ground and their own contents, so nobody else can
--   bump them, and items inside can't be knocked out by other players.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local CollisionGroups = {}

CollisionGroups.Characters = "Characters"
CollisionGroups.Items = "Items"

local slotOf: { [Player]: number } = {}

function CollisionGroups.vesselGroup(slot: number): string
	return "Vessel" .. slot
end

local function setPartsGroup(root: Instance, group: string)
	if root:IsA("BasePart") then
		root.CollisionGroup = group
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = group
		end
	end
end
CollisionGroups.setGroup = setPartsGroup

function CollisionGroups.slotFor(player: Player): number?
	return slotOf[player]
end

function CollisionGroups.vesselGroupFor(player: Player): string?
	local slot = slotOf[player]
	return slot and CollisionGroups.vesselGroup(slot)
end

local function assignSlot(player: Player)
	local taken = {}
	for _, slot in slotOf do
		taken[slot] = true
	end
	for slot = 1, Config.MaxPlayers do
		if not taken[slot] then
			slotOf[player] = slot
			return
		end
	end
	warn("[CollisionGroups] no free vessel slot for", player.Name)
end

function CollisionGroups.init()
	PhysicsService:RegisterCollisionGroup(CollisionGroups.Characters)
	PhysicsService:RegisterCollisionGroup(CollisionGroups.Items)

	local vesselGroups = {}
	for slot = 1, Config.MaxPlayers do
		local group = CollisionGroups.vesselGroup(slot)
		PhysicsService:RegisterCollisionGroup(group)
		table.insert(vesselGroups, group)
	end

	for _, group in vesselGroups do
		PhysicsService:CollisionGroupSetCollidable(group, CollisionGroups.Characters, false)
		PhysicsService:CollisionGroupSetCollidable(group, CollisionGroups.Items, false)
		for _, other in vesselGroups do
			if other ~= group then
				PhysicsService:CollisionGroupSetCollidable(group, other, false)
			end
		end
	end

	local function onCharacter(character: Model)
		setPartsGroup(character, CollisionGroups.Characters)
		character.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = CollisionGroups.Characters
			end
		end)
	end

	local function onPlayer(player: Player)
		assignSlot(player)
		if player.Character then
			onCharacter(player.Character)
		end
		player.CharacterAdded:Connect(onCharacter)
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		-- Released after other PlayerRemoving handlers (vessel cleanup) have run.
		task.defer(function()
			slotOf[player] = nil
		end)
	end)
end

return CollisionGroups
