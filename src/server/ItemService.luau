-- Beach items: spawning in the surf, ownership state, timeouts, despawning and the tide.
--
-- Item states (attribute "State"):
--   Unclaimed  anchored, no physics, anyone can grab it
--   Held       claimed, physics on, network-owned by the holder
--   Loose      claimed but put down outside a vessel; server simulates it, waves push it,
--              and after Config.Items.LooseTimeout it freezes and becomes Unclaimed again
--   InVessel   claimed, sitting in its owner's vessel, network-owned by the owner

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)
local Items = require(Shared.Items)
local Tide = require(Shared.Tide)
local Waves = require(Shared.Waves)

local CollisionGroups = require(script.Parent.CollisionGroups)

local cfg = Config.Items

local ItemService = {}

ItemService.Tag = "SalvageItem"

local folder: Folder
local mapFolder: Instance
local all: { [BasePart]: boolean } = {}
local loose: { [BasePart]: boolean } = {}
local rng = Random.new()
local destroyedCallbacks = {}

local function now(): number
	return Tide.now()
end

local function trySetNetworkOwner(part: BasePart, player: Player?)
	if part.Anchored or not part:IsDescendantOf(Workspace) then
		return
	end
	pcall(part.SetNetworkOwner, part, player)
end
ItemService.trySetNetworkOwner = trySetNetworkOwner

function ItemService.all(): { [BasePart]: boolean }
	return all
end

function ItemService.isItem(instance: Instance?): boolean
	return instance ~= nil and all[instance :: any] == true
end

function ItemService.getState(item: BasePart): string
	return item:GetAttribute("State") or "Unclaimed"
end

function ItemService.getOwnerId(item: BasePart): number
	return item:GetAttribute("Owner") or 0
end

function ItemService.isOwnedBy(item: BasePart, player: Player): boolean
	return ItemService.getOwnerId(item) == player.UserId
end

function ItemService.onDestroyed(callback: (BasePart) -> ())
	table.insert(destroyedCallbacks, callback)
end

function ItemService.destroy(item: BasePart)
	if not all[item] then
		return
	end
	all[item] = nil
	loose[item] = nil
	for _, callback in destroyedCallbacks do
		callback(item)
	end
	item:Destroy()
end

-- Puts an item down on whatever map surface is under it.
function ItemService.dropToGround(item: BasePart)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { mapFolder }
	local origin = item.Position + Vector3.new(0, 10, 0)
	local hit = Workspace:Raycast(origin, Vector3.new(0, -80, 0), params)
	local groundY = if hit then hit.Position.Y else Beach.groundY(item.Position.Z)
	local _, yaw, _ = item.CFrame:ToOrientation()
	item.CFrame = CFrame.new(item.Position.X, groundY + item.Size.Y / 2, item.Position.Z)
		* CFrame.Angles(0, yaw, 0)
end

function ItemService.setUnclaimed(item: BasePart, timedOut: boolean)
	loose[item] = nil
	item.Anchored = true
	item.AssemblyLinearVelocity = Vector3.zero
	item.AssemblyAngularVelocity = Vector3.zero
	item.CollisionGroup = CollisionGroups.Items
	item:SetAttribute("Owner", 0)
	item:SetAttribute("State", "Unclaimed")
	item:SetAttribute("VesselId", nil)
	item:SetAttribute("Fresh", not timedOut)
	item:SetAttribute("Since", now())
end

function ItemService.setHeld(item: BasePart, player: Player)
	loose[item] = nil
	item.Anchored = false
	item.CollisionGroup = CollisionGroups.Items
	item:SetAttribute("Owner", player.UserId)
	item:SetAttribute("State", "Held")
	item:SetAttribute("VesselId", nil)
	item:SetAttribute("Fresh", false)
	item:SetAttribute("Since", now())
	trySetNetworkOwner(item, player)
end

function ItemService.setLoose(item: BasePart)
	item.Anchored = false
	item.CollisionGroup = CollisionGroups.Items
	item:SetAttribute("State", "Loose")
	item:SetAttribute("VesselId", nil)
	item:SetAttribute("Since", now())
	trySetNetworkOwner(item, nil)
	loose[item] = true
end

function ItemService.setInVessel(item: BasePart, vesselId: string, owner: Player, group: string)
	loose[item] = nil
	item.Anchored = false
	item.CollisionGroup = group
	item:SetAttribute("Owner", owner.UserId)
	item:SetAttribute("State", "InVessel")
	item:SetAttribute("VesselId", vesselId)
	item:SetAttribute("Since", now())
	trySetNetworkOwner(item, owner)
end

function ItemService.itemsOwnedBy(player: Player): { BasePart }
	local result = {}
	for item in all do
		if ItemService.isOwnedBy(item, player) then
			table.insert(result, item)
		end
	end
	return result
end

local function createItem(def, zoneIndex: number, position: Vector3): BasePart
	local part = Instance.new("Part")
	part.Name = def.Name
	part.Shape = Enum.PartType[def.Shape]
	part.Size = def.Size
	part.Color = def.Color
	part.Material = def.Material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CustomPhysicalProperties = PhysicalProperties.new(Items.ClassDensity[def.Class], 0.4, 0.1)
	-- `position` assumes the catalog size; Roblox can resize some shapes (balls are always
	-- round), so rest the real part on the surface instead of sinking it into the sand.
	-- (plus a margin for the beach's slope under the item's corners).
	local slopeMargin = Config.Beach.Slope * math.max(part.Size.X, part.Size.Z) / 2
	local restY = position.Y - def.Size.Y / 2 + part.Size.Y / 2 + slopeMargin + 0.05
	part.CFrame = CFrame.new(position.X, restY, position.Z)
		* CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	part:SetAttribute("ItemId", def.Id)
	part:SetAttribute("Class", def.Class)
	part:SetAttribute("Rarity", def.Rarity)
	part:SetAttribute("Zone", zoneIndex)
	part:SetAttribute("Value", math.floor(def.Value * Config.Zones[zoneIndex].Multiplier))
	ItemService.setUnclaimed(part, false)
	CollectionService:AddTag(part, ItemService.Tag)
	part.Parent = folder
	all[part] = true
	return part
end

function ItemService.spawnAt(def, zoneIndex: number, position: Vector3): BasePart
	return createItem(def, zoneIndex, position)
end

-- Washes one item up somewhere in the surf around the current waterline. The zone (and so
-- the value and rarity) comes from where it lands, so low tide brings richer loot.
function ItemService.spawnInSurf(waterline: number): BasePart?
	local beach = Config.Beach
	-- Heavy things sit out in deeper water; lighter ones anywhere from the wet sand out.
	local heavyRoll = rng:NextNumber()
	local depth = if heavyRoll < 0.3
		then rng:NextNumber(beach.ShallowDepth, beach.WaistDepth - 0.3)
		else rng:NextNumber(-0.3, beach.WaistDepth - 0.3)
	local z = Beach.zForDepth(depth, waterline)
	local zoneIndex = Beach.zoneAt(z)
	if not zoneIndex or zoneIndex < 1 then
		return nil
	end

	local rarity = Items.rollRarity(Config.Zones[zoneIndex].Rarity, rng)
	local choices = {}
	for _, def in Items.ofRarity(rarity) do
		-- Only heavy items in the deeper spots, only lighter ones in the shallows.
		if (def.Class >= 3) == (heavyRoll < 0.3) then
			table.insert(choices, def)
		end
	end
	if #choices == 0 then
		return nil
	end
	local def = choices[rng:NextInteger(1, #choices)]

	local x = rng:NextNumber(-Beach.HalfWidth + 12, Beach.HalfWidth - 12)
	local y = Beach.groundY(z) + def.Size.Y / 2
	return createItem(def, zoneIndex, Vector3.new(x, y, z))
end

local function spawnTick()
	local waterline = Tide.waterline()
	local total, inSurf = 0, 0
	for item in all do
		total += 1
		if ItemService.getState(item) == "Unclaimed" and item:GetAttribute("Fresh") then
			local depth = Beach.depthAt(item.Position, waterline)
			if depth > -1 and depth < Config.Beach.WaistDepth then
				inSurf += 1
			end
		end
	end
	if total < cfg.MaxTotal and inSurf < cfg.MaxSurfItems then
		ItemService.spawnInSurf(waterline)
	end
end

local function maintenanceTick()
	local t = now()
	local waterline = Tide.waterline(t)
	for item in all do
		local position = item.Position
		local state = ItemService.getState(item)
		local since = item:GetAttribute("Since") or t

		local fellOut = position.Y < Beach.groundY(position.Z) - 30
			or math.abs(position.X) > Beach.HalfWidth + 40
		local drowned = Beach.isLost(position, waterline) and (state == "Unclaimed" or state == "Loose")
		if fellOut or drowned then
			ItemService.destroy(item)
		elseif state == "Unclaimed" then
			local lifetime = if item:GetAttribute("Fresh") then cfg.FreshLifetime else cfg.TimedOutLifetime
			if t - since > lifetime then
				ItemService.destroy(item)
			end
		elseif state == "Loose" then
			if t - since > cfg.LooseTimeout and item.AssemblyLinearVelocity.Magnitude < 1 then
				ItemService.setUnclaimed(item, true)
			end
		end
	end
end

function ItemService.init(map: Instance)
	mapFolder = map
	folder = Instance.new("Folder")
	folder.Name = "Items"
	folder.Parent = Workspace
	ItemService.Folder = folder

	-- Server simulates loose items, so the server pushes them with the waves.
	RunService.Heartbeat:Connect(function(dt)
		local t = now()
		local waterline = Tide.waterline(t)
		for item in loose do
			Waves.applyToPart(item, dt, t, waterline)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(cfg.SpawnInterval)
			spawnTick()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			maintenanceTick()
		end
	end)

	-- Items a player leaves on the beach become unclaimed where they lie.
	Players.PlayerRemoving:Connect(function(player)
		for _, item in ItemService.itemsOwnedBy(player) do
			ItemService.dropToGround(item)
			ItemService.setUnclaimed(item, true)
		end
	end)
end

return ItemService
