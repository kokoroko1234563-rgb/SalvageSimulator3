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
local Palette = require(Shared.Palette)
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Layouts = require(Shared.Layouts)
local Tide = require(Shared.Tide)
local Waves = require(Shared.Waves)

local CollisionGroups = require(script.Parent.CollisionGroups)
local ItemModels = require(script.Parent.ItemModels)

local cfg = Config.Items

local ItemService = {}

ItemService.Tag = "SalvageItem"

local folder: Folder
local mapFolder: Instance
local all: { [BasePart]: boolean } = {}
local loose: { [BasePart]: boolean } = {}
local rng = Random.new()
local destroyedCallbacks = {}
local createdCallbacks = {}

-- Server-wide counts for the bots' measurements (BotService reports them, `bots report`).
ItemService.stats = {
	SurfSpawned = 0, -- items washed up in the surf
	SpotSpawned = 0, -- finds left at loot spots
	Claimed = 0, -- free items taken by anyone (a player or a bot)
	ClaimedByBots = 0,
	Despawned = 0, -- items that went unclaimed: timed out, drowned, or lost to the sea
	SpawnTicks = 0, -- spawn attempts...
	SurfFullTicks = 0, -- ...and how many found the surf full (MaxSurfItems)
}

function ItemService.resetStats()
	for key in ItemService.stats do
		ItemService.stats[key] = 0
	end
end

local clock: (() -> number)? -- tools/tests: a stand-in clock (a simulated tide)

local function now(): number
	return if clock then clock() else Tide.now()
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

function ItemService.onCreated(callback: (BasePart) -> ())
	table.insert(createdCallbacks, callback)
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
	params.FilterDescendantsInstances = { mapFolder, Workspace.Terrain }
	local origin = Beach.rayFrom(item.Position, 10)
	local hit = Workspace:Raycast(origin, Vector3.new(0, -80, 0), params)
	local groundY = if hit then hit.Position.Y else Beach.groundAt(item.Position.X, item.Position.Z)
	local _, yaw, _ = item.CFrame:ToOrientation()
	item.CFrame = CFrame.new(item.Position.X, groundY + item.Size.Y / 2, item.Position.Z)
		* CFrame.Angles(0, yaw, 0)
end

-- Items in a vessel are welded into a slot (see VesselService.load); undo that.
local function detachFromVessel(item: BasePart)
	local weld = item:FindFirstChild("VesselWeld")
	if weld then
		weld:Destroy()
	end
	item.Massless = false
	item.CanCollide = true
	item:SetAttribute("Slot", nil)
end

function ItemService.setUnclaimed(item: BasePart, timedOut: boolean)
	loose[item] = nil
	detachFromVessel(item)
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
	if ItemService.getState(item) == "Unclaimed" then
		ItemService.stats.Claimed += 1
	end
	loose[item] = nil
	detachFromVessel(item)
	item.Anchored = false
	item.CollisionGroup = CollisionGroups.Items
	item:SetAttribute("Owner", player.UserId)
	item:SetAttribute("State", "Held")
	item:SetAttribute("VesselId", nil)
	item:SetAttribute("Fresh", false)
	item:SetAttribute("Since", now())
	trySetNetworkOwner(item, player)
end

-- A bot takes a free item (bots are anchored and have no physics, so it stays anchored).
-- `botId` is the bot's owner id: negative, so it never matches a player's UserId. Whoever asks
-- first gets it: false if the item is no longer free.
function ItemService.claimForBot(item: BasePart, botId: number): boolean
	if not all[item] or ItemService.getState(item) ~= "Unclaimed" then
		return false
	end
	ItemService.stats.Claimed += 1
	ItemService.stats.ClaimedByBots += 1
	item:SetAttribute("Owner", botId)
	item:SetAttribute("State", "Held")
	item:SetAttribute("Fresh", false)
	item:SetAttribute("Since", now())
	item.CanCollide = false
	return true
end

-- A bot puts what it holds into its cart.
function ItemService.setInCart(item: BasePart, cartId: string, botId: number)
	item:SetAttribute("Owner", botId)
	item:SetAttribute("State", "InVessel")
	item:SetAttribute("VesselId", cartId)
	item:SetAttribute("Since", now())
end

function ItemService.setLoose(item: BasePart)
	detachFromVessel(item)
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

function ItemService.countOf(itemId: string): number
	local count = 0
	for item in all do
		if item:GetAttribute("ItemId") == itemId then
			count += 1
		end
	end
	return count
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

-- `tier` is the zone tier the tool must reach to lift it: where the item washed up (so a biome's
-- loot takes its zone's tier), else its own Tier. Unlock items have none: always liftable.
local function createItem(def, zoneIndex: number, position: Vector3, tier: number?): BasePart
	local part = Instance.new("Part")
	part.Name = def.Name
	part.Shape = Enum.PartType[def.Shape]
	part.Size = def.Size
	part.Color = def.Color
	part.Material = def.Material or Palette.Material.Smooth
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
	part:SetAttribute("Floats", Items.floats(def))
	part:SetAttribute("Rarity", def.Rarity)
	part:SetAttribute("Zone", zoneIndex)
	if not def.Unlock then
		part:SetAttribute("Tier", tier or def.Tier or zoneIndex)
	end
	part:SetAttribute("Value", math.floor(def.Value * Config.Zones[zoneIndex].Multiplier))
	if def.Unlock then
		-- Unlock items glow so they're findable, and are banked rather than sold.
		part:SetAttribute("Unlock", def.Unlock)
		local light = Instance.new("PointLight")
		light.Color = def.Color
		light.Range = 10
		light.Brightness = 2
		light.Parent = part
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = def.Color
		sparkles.Parent = part
	end
	if def.SkyBeam then
		CollectionService:AddTag(part, "SkyBeam")
	end
	-- The root stays the physics body; its visible model is welded on (see ItemModels).
	ItemModels.build(part, def)
	ItemService.setUnclaimed(part, false)
	CollectionService:AddTag(part, ItemService.Tag)
	part.Parent = folder
	all[part] = true
	for _, callback in createdCallbacks do
		task.spawn(callback, part)
	end
	return part
end

function ItemService.spawnAt(def, zoneIndex: number, position: Vector3, tier: number?): BasePart
	return createItem(def, zoneIndex, position, tier)
end

-- Whether an item can rest at (x, z): not on rock (a wall's top, a boulder), where nobody
-- could reach it.
local function restsAt(x: number, z: number): boolean
	local _, rock = Beach.shapeAt(x, z)
	return not rock
end

-- The rarest of `rolls` rarity rolls.
local function rollRarity(weights: { [string]: number }, rolls: number): string
	local best = 1
	for _ = 1, rolls do
		local rarity = Items.rollRarity(weights, rng)
		best = math.max(best, table.find(Items.Rarities, rarity) or 1)
	end
	return Items.Rarities[best]
end

-- What washes up at a point in a zone: a biome's secret unlock item or own loot sometimes, the
-- sky-beam item on the Far Sandbar, else an item of the zone's own tier (Items.Catalog Tier) at
-- a rarity from the zone's table (the rarest of `rarityRolls` rolls). Biome loot takes the
-- tier of the zone it washes up in, whatever its own Tier (createItem).
local function chooseDef(zoneIndex: number, z: number, rarityRolls: number)
	local biome = Biomes.activeIn(Beach.tileAt(z))
	local def
	-- Private servers scale rare spawns down with the player count (MonetizationService).
	local rareScale = Workspace:GetAttribute("RareSpawnScale") or 1
	local unlockChance = rareScale
		* (
			if biome and biome.Tier == "Common"
				then Config.Unlocks.SpawnChance
				else Config.Unlocks.ExoticSpawnChance
		)
	-- (Only once its secret is built: before that the item would open nothing.)
	if biome and biome.UnlockItem and biome.Secret and rng:NextNumber() < unlockChance then
		if ItemService.countOf(biome.UnlockItem) < Config.Unlocks.MaxOnMap then
			def = Items.get(biome.UnlockItem)
		end
	end
	-- The sky-beam item only ever washes up on the Far Sandbar, and only one at a time.
	if
		not def
		and zoneIndex == Beach.FarSandbarZone
		and rng:NextNumber() < Config.SkyBeam.SpawnChance * rareScale
		and ItemService.countOf("BeaconPearl") == 0
	then
		def = Items.get("BeaconPearl")
	end
	if not def and biome and rng:NextNumber() < biome.LootShare then
		def = Items.get(biome.Loot[rng:NextInteger(1, #biome.Loot)])
	end
	if not def then
		local rarity = rollRarity(Items.scaleRare(Config.Zones[zoneIndex].Rarity, rareScale), rarityRolls)
		local choices = Items.ofTier(zoneIndex, rarity)
		if #choices == 0 then
			-- (A rarity the tier has none of, such as the commons that scaled-down rare spawns
			-- turn the Far Sandbar's rolls into: the nearest rarer one, else the nearest common.)
			local index = table.find(Items.Rarities, rarity) or 1
			for offset = 1, #Items.Rarities do
				for _, step in { offset, -offset } do
					local other = Items.Rarities[index + step]
					if other and #choices == 0 then
						choices = Items.ofTier(zoneIndex, other)
					end
				end
			end
		end
		if #choices == 0 then
			return nil
		end
		def = choices[rng:NextInteger(1, #choices)]
	end
	return def
end

ItemService._chooseDef = chooseDef -- for tools/tests

-- Somewhere to wash an item up: a point at a random depth between `lo` and `hi` of the sea, off
-- the rocks.
local function surfPoint(sea: Tide.Sea, lo: number, hi: number): (number?, number?)
	for _ = 1, 6 do
		local x = rng:NextNumber(-Beach.HalfWidth + 12, Beach.HalfWidth - 12)
		local z = Beach.zForDepth(rng:NextNumber(lo, hi), sea, x)
		if restsAt(x, z) then
			return x, z
		end
	end
	return nil, nil
end

-- Washes one item up somewhere in the surf around the current waterline. The zone (and so
-- the value, rarity and tier) comes from where it lands, so low tide brings richer loot. Heavy
-- things (by Class) are moved out into deeper water, within the same stretch of beach.
function ItemService.spawnInSurf(sea: Tide.Sea): BasePart?
	local beach = Config.Beach
	local x, z = surfPoint(sea, -0.3, beach.WaistDepth - 0.3)
	if not x or not z then
		return nil
	end
	local zoneIndex = Beach.zoneAt(z)
	if not zoneIndex or zoneIndex < 1 then
		return nil
	end
	local def = chooseDef(zoneIndex, z, 1)
	if not def then
		return nil
	end
	if def.Class >= Gear.WeightClass.Heavy and not def.Unlock then
		local deepX, deepZ = surfPoint(sea, beach.ShallowDepth, beach.WaistDepth - 0.3)
		if
			deepX
			and deepZ
			and Beach.zoneAt(deepZ) == zoneIndex
			and Beach.tileAt(deepZ) == Beach.tileAt(z)
		then
			x, z = deepX, deepZ
		end
	end
	local y = Beach.groundAt(x, z) + def.Size.Y / 2
	return createItem(def, zoneIndex, Vector3.new(x, y, z), zoneIndex)
end

-- The layouts' loot spots: once each tide, as the sea goes out and leaves a spot dry, it
-- leaves finds there (dead ends and hidden corners, where the layouts put them). A spot's
-- Weight raises its chance of a find and how rare the find is.
local settled: { [string]: number } = {} -- spot key -> the tide cycle it last settled in

function ItemService.settleSpots(sea: Tide.Sea, cycle: number): number
	local spawned = 0
	for tile = 1, Beach.ActiveTiles do
		local layout = Layouts.active(tile)
		if not layout then
			continue
		end
		local z0 = Beach.tileRange(tile)
		for index, spot in Layouts.lootSpots(tile, z0) do
			local key = tile .. "/" .. layout.Name .. "/" .. index
			if settled[key] == cycle then
				continue
			end
			local middle = Vector3.new(spot.X, Beach.groundAt(spot.X, spot.Z), spot.Z)
			if Beach.seaDepthAt(middle, sea) > 0 then
				continue -- still under the sea
			end
			settled[key] = cycle
			local zoneIndex = Beach.zoneAt(spot.Z)
			if not zoneIndex or zoneIndex < 1 or rng:NextNumber() >= cfg.SpotChance * spot.Weight then
				continue
			end
			local x, z
			for _ = 1, 6 do
				local angle, r = rng:NextNumber() * math.pi * 2, spot.Radius * math.sqrt(rng:NextNumber())
				x, z = spot.X + math.cos(angle) * r, spot.Z + math.sin(angle) * r
				if restsAt(x, z) then
					break
				end
				x = nil
			end
			local rolls = math.clamp(math.round(spot.Weight), 1, cfg.SpotRarityRolls)
			local def = x and chooseDef(zoneIndex, z, rolls)
			if def then
				createItem(
					def,
					zoneIndex,
					Vector3.new(x, Beach.groundAt(x, z) + def.Size.Y / 2, z),
					zoneIndex
				)
				ItemService.stats.SpotSpawned += 1
				spawned += 1
			end
		end
	end
	return spawned
end

-- Crowds (Config.Items.CrowdSpawn): the more players on the server (bots count), the more of the
-- zones' ordinary surf spawns wash up, up to Scale times a solo server's at Players players,
-- linear in between.
local botCount = 0

function ItemService.setBotCount(n: number)
	botCount = n
end

function ItemService.crowdScale(players: number?): number
	local crowd = cfg.CrowdSpawn
	if not crowd or crowd.Scale <= 1 or crowd.Players <= 1 then
		return 1
	end
	local count = players or (#Players:GetPlayers() + botCount)
	return 1 + (crowd.Scale - 1) * math.clamp((count - 1) / (crowd.Players - 1), 0, 1)
end

-- The most items kept in the surf at a crowd scale: MaxSurfItems times the scale.
function ItemService.surfCap(scale: number): number
	return cfg.MaxSurfItems * scale
end

local function spawnTick()
	local sea = Tide.sea(now())
	local scale = ItemService.crowdScale()
	local cap = ItemService.surfCap(scale)
	local total, inSurf = 0, 0
	for item in all do
		total += 1
		if ItemService.getState(item) == "Unclaimed" and item:GetAttribute("Fresh") then
			local depth = Beach.depthAt(item.CFrame.Position, sea)
			if depth > -1 and depth < Config.Beach.WaistDepth then
				inSurf += 1
			end
		end
	end
	ItemService.stats.SpawnTicks += 1
	if inSurf >= cap then
		ItemService.stats.SurfFullTicks += 1
	end
	if total < cfg.MaxTotal and inSurf < cap then
		if ItemService.spawnInSurf(sea) then
			ItemService.stats.SurfSpawned += 1
			inSurf += 1
		end
		-- The extra spawns a crowd brings: one more try per unit of scale above 1 (the last one
		-- only with the chance left over).
		local extra = scale - 1
		while extra > 0 and total < cfg.MaxTotal and inSurf < cap do
			if rng:NextNumber() < extra and ItemService.spawnInSurf(sea) then
				ItemService.stats.SurfSpawned += 1
				inSurf += 1
			end
			extra -= 1
		end
	end
	if total < cfg.MaxTotal then
		ItemService.settleSpots(sea, Tide.getState(now()).Cycle)
	end
end

local function maintenanceTick()
	local t = now()
	local sea = Tide.sea(t)
	for item in all do
		local position = item.CFrame.Position
		local state = ItemService.getState(item)
		local since = item:GetAttribute("Since") or t

		local fellOut = position.Y < Beach.groundY(position.Z) - 30
			or math.abs(position.X) > Beach.HalfWidth + 40
		-- Floating items drift out instead of sinking, and are lost once they're far out.
		local floats = item:GetAttribute("Floats") == true
		local lostAt = if floats
			then position.Z > Tide.waterlineAt(sea, position.X) + Config.Waves.FloatAwayDistance
			else Beach.isLost(position, sea)
		local drowned = lostAt and (state == "Unclaimed" or state == "Loose")
		if fellOut or drowned then
			if state == "Unclaimed" then
				ItemService.stats.Despawned += 1
			end
			ItemService.destroy(item)
		elseif state == "Unclaimed" then
			local lifetime = if item:GetAttribute("Fresh") then cfg.FreshLifetime else cfg.TimedOutLifetime
			if t - since > lifetime then
				ItemService.stats.Despawned += 1
				ItemService.destroy(item)
			end
		elseif state == "Loose" then
			-- Never freeze something bobbing in the water: it'd hang there when the tide moved.
			local afloat = floats and Beach.depthAt(position, sea) > 0
			if t - since > cfg.LooseTimeout and item.AssemblyLinearVelocity.Magnitude < 1 and not afloat then
				ItemService.setUnclaimed(item, true)
			end
		end
	end
end

-- For tools/tests (tools/spawn_sim.luau): run the ticks by hand against a simulated clock.
ItemService._spawnTick = spawnTick
ItemService._maintenanceTick = maintenanceTick
function ItemService._setClock(fn: (() -> number)?)
	clock = fn
end

function ItemService.init(map: Instance)
	mapFolder = map
	folder = Instance.new("Folder")
	folder.Name = "Items"
	folder.Parent = Workspace
	ItemService.Folder = folder

	-- Server simulates loose items, so the server pushes them with the waves.
	RunService.Heartbeat:Connect(function(dt)
		local sea = Tide.sea(now())
		for item in loose do
			Waves.applyToPart(item, dt, sea)
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
			ItemService.setUnclaimed(item, true)
			ItemService.dropToGround(item)
		end
	end)
end

return ItemService
