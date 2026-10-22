-- Beach items: spawning, ownership state, timeouts, despawning and the tide.
--
-- Item states (attribute "State"):
--   Unclaimed  anchored, no physics, anyone can grab it
--   Held       claimed, physics on, network-owned by the holder
--   Loose      claimed but put down outside a vessel; server simulates it, waves push it,
--              and after Config.Items.LooseTimeout it freezes and becomes Unclaimed again
--   InVessel   claimed, sitting in its owner's vessel, network-owned by the owner
--
-- Spawning (docs/design/spawning.md). Every zone, 1 to 7 (the Far Sandbar included), keeps its
-- own supply of free items, whatever the tide is doing:
--   * Target. Each zone has a target number of free items lying in it (Config.Zones Target):
--     items Unclaimed or Loose whose position is in the zone, on sand or in the surf (not in
--     deep water). Held and InVessel items don't count.
--   * Rate. Each spawn tick a zone spawns with an expected number of
--     MaxRate * SpawnInterval * (target - count) / target items: the emptier the zone, the
--     faster it refills, up to MaxRate per second when empty; at or above target it spawns
--     nothing. A zone only ever looks at its own count, so items dropped in one zone can't
--     speed up another.
--   * Rarity. What a spawn is (chooseDef) is rolled exactly as before; emptiness changes only
--     how often a zone spawns, never what.
--   * Where. Zones with SpawnOnSand (1 to 3) put a spawn on their open, walkable sand (not
--     under the sea, not rock, not under a roof, not on a cliff) at any point of the tide, or,
--     when the waterline is in the zone, with chance Config.Items.SurfShare in the surf. The
--     other zones (4 to 6, the Far Sandbar) only spawn in the wet sand and surf around the
--     waterline, so they refill only while the water is in or near them. Open-sand spawns roll
--     ordinary items only: no unlock item and no Beacon Pearl, which come from surf spawns.
--   * Crowds. The crowd scale (players plus bots, Config.Items.CrowdSpawn) multiplies every
--     zone's target and its MaxRate. Config.Items.MaxTotal is a global safety cap.
--   * Loot spots (settleSpots) are separate: once each tide, unchanged, and not counted.

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

local function zoneCounts(): { number }
	return table.create(#Config.Zones, 0)
end

-- Server-wide counts for the bots' measurements (BotService reports them, `bots report`).
ItemService.stats = {
	SurfSpawned = 0, -- items washed up in the surf
	SandSpawned = 0, -- items left on open sand (zones with SpawnOnSand)
	SpotSpawned = 0, -- finds left at loot spots
	ZoneSpawned = zoneCounts(), -- surf, sand and spot items by zone (index 1 to 7)
	Claimed = 0, -- free items taken by anyone (a player or a bot)
	ClaimedByBots = 0,
	Despawned = 0, -- items that went unclaimed: timed out, drowned, or lost to the sea
	SpawnTicks = 0, -- spawn ticks...
	SurfFullTicks = 0, -- ...and how many found every zone at its target
}

function ItemService.resetStats()
	for key, value in ItemService.stats do
		ItemService.stats[key] = if type(value) == "table" then zoneCounts() else 0
	end
end

local function countSpawn(zoneIndex: number)
	local zones = ItemService.stats.ZoneSpawned
	zones[zoneIndex] += 1
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
-- With `ordinary` set (spawns on open sand) there is no unlock item and no sky-beam item: those
-- only come from the surf; the biome's own loot is still allowed.
local function chooseDef(zoneIndex: number, z: number, rarityRolls: number, ordinary: boolean?)
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
	if not ordinary and biome and biome.UnlockItem and biome.Secret and rng:NextNumber() < unlockChance then
		if ItemService.countOf(biome.UnlockItem) < Config.Unlocks.MaxOnMap then
			def = Items.get(biome.UnlockItem)
		end
	end
	-- The sky-beam item only ever washes up on the Far Sandbar, and only one at a time.
	if
		not def
		and not ordinary
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
-- the rocks, and in `zoneIndex` when one is asked for.
local function surfPoint(sea: Tide.Sea, lo: number, hi: number, zoneIndex: number?): (number?, number?)
	for _ = 1, 6 do
		local x = rng:NextNumber(-Beach.HalfWidth + 12, Beach.HalfWidth - 12)
		local z = Beach.zForDepth(rng:NextNumber(lo, hi), sea, x)
		if restsAt(x, z) and (not zoneIndex or Beach.zoneAt(z) == zoneIndex) then
			return x, z
		end
	end
	return nil, nil
end

-- Whether (x, z) is open, walkable sand: not rock, not under a roof, not under the sea (or a
-- rock pool), and not on a slope steeper than a player can walk.
local function openSand(x: number, z: number, sea: Tide.Sea): boolean
	if not restsAt(x, z) or Beach.roofAt(x, z) then
		return false
	end
	local ground = Beach.groundAt(x, z)
	if Beach.depthAt(Vector3.new(x, ground, z), sea) > 0 then
		return false
	end
	local step = 2
	local limit = Config.Beach.Terrain.FootSlope * step
	for _, offset in { { step, 0 }, { -step, 0 }, { 0, step }, { 0, -step } } do
		if math.abs(Beach.groundAt(x + offset[1], z + offset[2]) - ground) > limit then
			return false
		end
	end
	return true
end

-- Somewhere on a zone's open sand, at the current tide.
local function sandPoint(sea: Tide.Sea, zoneIndex: number): (number?, number?)
	local z0, z1 = Beach.zoneRange(zoneIndex)
	for _ = 1, 8 do
		local x = rng:NextNumber(-Beach.HalfWidth + 12, Beach.HalfWidth - 12)
		local z = rng:NextNumber(z0, z1)
		if openSand(x, z, sea) then
			return x, z
		end
	end
	return nil, nil
end

-- Leaves one ordinary item (no unlock item, no Beacon Pearl) somewhere on a zone's open sand.
function ItemService.spawnOnSand(sea: Tide.Sea, zoneIndex: number): BasePart?
	local x, z = sandPoint(sea, zoneIndex)
	if not x or not z then
		return nil
	end
	local def = chooseDef(zoneIndex, z, 1, true)
	if not def then
		return nil
	end
	local y = Beach.groundAt(x, z) + def.Size.Y / 2
	return createItem(def, zoneIndex, Vector3.new(x, y, z), zoneIndex)
end

-- Washes one item up somewhere in the surf around the current waterline, in `zoneIndex` when
-- one is asked for (else wherever the surf point lands). The zone (and so the value, rarity and
-- tier) comes from where it lands. Heavy things (by Class) are moved out into deeper water,
-- within the same stretch of beach.
function ItemService.spawnInSurf(sea: Tide.Sea, zoneIndex: number?): BasePart?
	local beach = Config.Beach
	local x, z = surfPoint(sea, -0.3, beach.WaistDepth - 0.3, zoneIndex)
	if not x or not z then
		return nil
	end
	local zoneHere = Beach.zoneAt(z)
	if not zoneHere or zoneHere < 1 then
		return nil
	end
	local def = chooseDef(zoneHere, z, 1)
	if not def then
		return nil
	end
	if def.Class >= Gear.WeightClass.Heavy and not def.Unlock then
		local deepX, deepZ = surfPoint(sea, beach.ShallowDepth, beach.WaistDepth - 0.3, zoneHere)
		if deepX and deepZ and Beach.tileAt(deepZ) == Beach.tileAt(z) then
			x, z = deepX, deepZ
		end
	end
	local y = Beach.groundAt(x, z) + def.Size.Y / 2
	return createItem(def, zoneHere, Vector3.new(x, y, z), zoneHere)
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
				countSpawn(zoneIndex)
				spawned += 1
			end
		end
	end
	return spawned
end

-- Crowds (Config.Items.CrowdSpawn): the more players on the server (bots count), the more every
-- zone's target and its spawn rate scale up, to Scale times a solo server's at Players players,
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

-- How many free items a zone keeps lying in it at a crowd scale.
function ItemService.zoneTarget(zoneIndex: number, scale: number): number
	return Config.Zones[zoneIndex].Target * scale
end

-- The most a zone spawns per second (when it's empty) at a crowd scale.
function ItemService.zoneMaxRate(zoneIndex: number, scale: number): number
	return Config.Zones[zoneIndex].MaxRate * scale
end

-- The chance-weighted number of items a zone spawns in `dt` seconds with `count` free items
-- lying in it: MaxRate * dt * (target - count) / target, nothing at or above the target.
function ItemService.zoneSpawnRate(zoneIndex: number, count: number, scale: number, dt: number): number
	local target = ItemService.zoneTarget(zoneIndex, scale)
	if target <= 0 or count >= target then
		return 0
	end
	return ItemService.zoneMaxRate(zoneIndex, scale) * dt * (target - count) / target
end

-- The free items lying in each zone: Unclaimed or Loose, on sand or in the surf (not in deep
-- water, where they're about to be lost). Held and InVessel items don't count. Also the total
-- number of items of all kinds.
function ItemService.countFree(sea: Tide.Sea): ({ number }, number)
	local counts = zoneCounts()
	local total = 0
	for item in all do
		total += 1
		local state = ItemService.getState(item)
		if state == "Unclaimed" or state == "Loose" then
			local position = item.CFrame.Position
			local zoneIndex = Beach.zoneAt(position.Z)
			if zoneIndex and zoneIndex >= 1 and Beach.depthAt(position, sea) < Config.Beach.WaistDepth then
				counts[zoneIndex] += 1
			end
		end
	end
	return counts, total
end

-- Makes one spawn in a zone (nil when no point was found). A SpawnOnSand zone puts it on its
-- open sand, or, with chance SurfShare when the waterline is in the zone, in the surf; the other
-- zones only have the surf (no point there when the water is elsewhere).
local function spawnInZone(sea: Tide.Sea, zoneIndex: number): BasePart?
	local item
	if Config.Zones[zoneIndex].SpawnOnSand then
		if rng:NextNumber() < cfg.SurfShare then
			item = ItemService.spawnInSurf(sea, zoneIndex)
			if item then
				ItemService.stats.SurfSpawned += 1
			end
		end
		if not item then
			item = ItemService.spawnOnSand(sea, zoneIndex)
			if item then
				ItemService.stats.SandSpawned += 1
			end
		end
	else
		item = ItemService.spawnInSurf(sea, zoneIndex)
		if item then
			ItemService.stats.SurfSpawned += 1
		end
	end
	if item then
		countSpawn(zoneIndex)
	end
	return item
end

local function spawnTick()
	local t = now()
	local sea = Tide.sea(t)
	local scale = ItemService.crowdScale()
	local counts, total = ItemService.countFree(sea)
	ItemService.stats.SpawnTicks += 1
	local anyWanted = false
	for zoneIndex = 1, #Config.Zones do
		local expected = ItemService.zoneSpawnRate(zoneIndex, counts[zoneIndex], scale, cfg.SpawnInterval)
		if expected <= 0 then
			continue
		end
		anyWanted = true
		-- (More than one a tick only when the rate is high; the fraction is a chance.)
		local made = math.floor(expected)
		if rng:NextNumber() < expected - made then
			made += 1
		end
		for _ = 1, made do
			if total >= cfg.MaxTotal then
				break
			end
			if spawnInZone(sea, zoneIndex) then
				total += 1
				counts[zoneIndex] += 1
			end
		end
	end
	if not anyWanted then
		ItemService.stats.SurfFullTicks += 1
	end
	if total < cfg.MaxTotal then
		ItemService.settleSpots(sea, Tide.getState(t).Cycle)
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
