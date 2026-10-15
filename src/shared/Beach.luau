-- Beach geometry helpers shared by server and client.
-- Layout: the shoreline runs along X. The shop is at Z < 0 on flat ground; from Z = 0 the
-- sand slopes down toward +Z into the sea, and the zones are bands running out to sea.
-- The tide moves the waterline (where sea meets sand) in and out along Z.

local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)
local Layouts = require(script.Parent.Layouts)
local Tide = require(script.Parent.Tide)

type Sea = Tide.Sea

local beach = Config.Beach

local Beach = {}

local sandbar = beach.FarSandbar

Beach.Depth = sandbar.End -- how far out the playable beach reaches (to the end of the Far Sandbar)
Beach.FarSandbarZone = sandbar.Zone
Beach.HalfWidth = beach.Width / 2

-- Zone index for a Z position: 0 at the shop, nil past the playable zones.
function Beach.zoneAt(z: number): number?
	if z < 0 then
		return 0
	end
	local index = math.floor(z / beach.ZoneLength) + 1
	if index <= beach.ActiveZones then
		return index
	end
	if z < sandbar.End then
		return sandbar.Zone -- the channel and the Far Sandbar
	end
	return nil
end

function Beach.zoneRange(index: number): (number, number)
	if index == sandbar.Zone then
		return sandbar.ChannelStart, sandbar.End
	end
	return (index - 1) * beach.ZoneLength, index * beach.ZoneLength
end

-- Height of the sand/seabed surface at a given Z.
function Beach.groundY(z: number): number
	if z <= 0 then
		return 0
	end
	if z > sandbar.ChannelStart and z < sandbar.ChannelEnd then
		-- A smooth dip with sloping banks, so you can wade in and climb back out.
		local t = (z - sandbar.ChannelStart) / (sandbar.ChannelEnd - sandbar.ChannelStart)
		return -z * beach.Slope - sandbar.ChannelDepth * math.sin(t * math.pi)
	end
	return -z * beach.Slope
end

-- The ground's shape on top of the even slope, from the zone's layout (src/shared/Layouts):
-- its height above the slope at (x, z), and whether it's rock. It fades out at the edges of
-- each zone (so zones join without a seam), at the sides of the beach (the cliffs stand
-- there) and around rock pools.
local shape = beach.Terrain

function Beach.shapeAt(x: number, z: number): (number, boolean)
	local zone = Beach.zoneAt(z)
	if not zone or zone < 1 or zone > beach.ActiveZones then
		return 0, false
	end
	local z0, z1 = Beach.zoneRange(zone)
	local height, rock = Layouts.shapeAt(zone, x, z - z0)
	if height == 0 then
		return 0, false
	end
	local fade = math.clamp((Beach.HalfWidth - math.abs(x)) / shape.EdgeFade, 0, 1)
		* math.clamp(math.min(z - z0, z1 - z) / shape.ZoneFade, 0, 1)
	for _, pool in Beach.Pools or {} do
		local d = math.sqrt((x - pool.X) ^ 2 + (z - pool.Z) ^ 2)
		fade *= math.clamp((d - pool.Radius) / 8, 0, 1)
	end
	fade = fade * fade * (3 - 2 * fade)
	return height * fade, rock and height * fade > shape.RockMin
end

function Beach.feature(x: number, z: number): number
	return (Beach.shapeAt(x, z))
end

-- The real ground height at a point: the slope plus its shape.
function Beach.groundAt(x: number, z: number): number
	return Beach.groundY(z) + Beach.feature(x, z)
end

-- Whether the ground has any shape near this Z (a quick check before scanning it).
function Beach.isRough(z: number): boolean
	local zone = Beach.zoneAt(z)
	return zone ~= nil and zone >= 1 and zone <= beach.ActiveZones and Layouts.isShaped(zone)
end

-- Height of the sea surface for a waterline position.
function Beach.waterY(waterline: number): number
	return -waterline * beach.Slope
end

-- Where the sea really meets the sand at X, for a tide waterline `line`. The waterline is
-- where the even slope meets the sea; with the ground's shape (a bank standing out of the
-- water, a channel cutting in) the real shore can be further out or further in. Coming up the
-- beach from the sea, it's the first place the ground rises out of the water. The waves break
-- and run up from here. Cached briefly (the tide moves slowly).
local SHORE_OUT = 30 -- studs seaward of the waterline the search starts
local SHORE_BACK = 80 -- and how far up the beach it looks
local shoreCache: { [number]: number } = {}
local shoreCount = 0
local shoreClock = 0

function Beach.shoreFrom(x: number, line: number): number
	if not (Beach.isRough(line) or Beach.isRough(line + SHORE_OUT) or Beach.isRough(line - SHORE_BACK)) then
		return line
	end
	local now = os.clock()
	if now - shoreClock > 1 or shoreCount > 20000 then
		shoreCache, shoreCount, shoreClock = {}, 0, now
	end
	local key = math.floor(x + 0.5) * 1e6 + math.floor(line * 10 + 0.5)
	local cached = shoreCache[key]
	if cached then
		return cached
	end
	local waterY = Beach.waterY(line)
	local step = 2
	local z = line + SHORE_OUT
	local shore = line - SHORE_BACK
	while z > line - SHORE_BACK do
		local next = z - step
		if Beach.groundAt(x, next) > waterY then
			-- Between next (dry) and z (wet): find the crossing.
			local lo, hi = next, z
			for _ = 1, 6 do
				local mid = (lo + hi) / 2
				if Beach.groundAt(x, mid) > waterY then
					lo = mid
				else
					hi = mid
				end
			end
			shore = (lo + hi) / 2
			break
		end
		z = next
	end
	shoreCache[key] = shore
	shoreCount += 1
	return shore
end

-- Height of the sea surface at a point along the shoreline (parts of the beach drain at
-- different times, see Config.Tide.Sections).
function Beach.waterYAt(sea: Sea, x: number): number
	return Beach.waterY(Tide.waterlineAt(sea, x))
end

-- Rock pools hold water at a fixed level: Depth above the ground at their seaward edge.
Beach.Pools = {}
for _, pool in beach.Pools or {} do
	table.insert(Beach.Pools, {
		X = pool.X,
		Z = pool.Z,
		Radius = pool.Radius,
		Depth = pool.Depth,
		Level = -(pool.Z + pool.Radius) * beach.Slope + pool.Depth,
	})
end

-- The rock pool a position is in, if any.
function Beach.poolAt(position: Vector3)
	for _, pool in Beach.Pools do
		local dx, dz = position.X - pool.X, position.Z - pool.Z
		if dx * dx + dz * dz < pool.Radius * pool.Radius then
			return pool
		end
	end
	return nil
end

-- Height of the water surface over a position: the sea, or a rock pool's water if higher.
function Beach.surfaceY(position: Vector3, sea: Sea): number
	local y = Beach.waterYAt(sea, position.X)
	local pool = Beach.poolAt(position)
	if pool and pool.Level > y then
		return pool.Level
	end
	return y
end

-- How deep the water is over the ground at a position (0 or less on dry sand).
function Beach.depthAt(position: Vector3, sea: Sea): number
	return Beach.surfaceY(position, sea) - Beach.groundAt(position.X, position.Z)
end

-- How deep the sea alone is (rock pools never drown anyone or swallow anything).
function Beach.seaDepthAt(position: Vector3, sea: Sea): number
	return Beach.waterYAt(sea, position.X) - Beach.groundAt(position.X, position.Z)
end

function Beach.depthBand(position: Vector3, sea: Sea): number
	local depth = Beach.depthAt(position, sea)
	if depth <= 0 then
		return Gear.Depth.Dry
	elseif depth < beach.ShallowDepth then
		return Gear.Depth.Shallow
	elseif depth < beach.KneeDepth then
		return Gear.Depth.KneeDeep
	elseif depth < beach.WaistDepth then
		return Gear.Depth.Waist
	end
	return Gear.Depth.Deep
end

-- Deep water drowns players and swallows vessels.
function Beach.isDeep(position: Vector3, sea: Sea): boolean
	return Beach.seaDepthAt(position, sea) >= beach.WaistDepth
end

-- Unclaimed and loose items this deep are lost to the tide.
function Beach.isLost(position: Vector3, sea: Sea): boolean
	return Beach.seaDepthAt(position, sea) >= beach.LostDepth
end

-- How much the water slows a character standing at a position: walk speed and jump
-- multipliers from Config.Beach.Wading.
function Beach.wading(position: Vector3, sea: Sea): (number, number)
	local depth = Beach.depthAt(position, sea)
	local points = beach.Wading
	if depth <= points[1].Depth then
		return points[1].Speed, points[1].Jump
	end
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		if depth < b.Depth then
			local t = (depth - a.Depth) / (b.Depth - a.Depth)
			return a.Speed + (b.Speed - a.Speed) * t, a.Jump + (b.Jump - a.Jump) * t
		end
	end
	local last = points[#points]
	return last.Speed, last.Jump
end

-- Z where the sea reaches a given depth, at a point along the shoreline.
function Beach.zForDepth(depth: number, sea: Sea, x: number): number
	return Tide.waterlineAt(sea, x) + depth / beach.Slope
end

return Beach
