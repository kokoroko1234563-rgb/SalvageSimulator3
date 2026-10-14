-- Beach geometry helpers shared by server and client.
-- Layout: the shoreline runs along X. The shop is at Z < 0 on flat ground; from Z = 0 the
-- sand slopes down toward +Z into the sea, and the zones are bands running out to sea.
-- The tide moves the waterline (where sea meets sand) in and out along Z.

local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)

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

-- Height of the sea surface for a waterline position.
function Beach.waterY(waterline: number): number
	return -waterline * beach.Slope
end

-- How deep the water is over the seabed at a position (0 or less on dry sand).
function Beach.depthAt(position: Vector3, waterline: number): number
	return Beach.waterY(waterline) - Beach.groundY(position.Z)
end

function Beach.depthBand(position: Vector3, waterline: number): number
	local depth = Beach.depthAt(position, waterline)
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
function Beach.isDeep(position: Vector3, waterline: number): boolean
	return Beach.depthAt(position, waterline) >= beach.WaistDepth
end

-- Unclaimed and loose items this deep are lost to the tide.
function Beach.isLost(position: Vector3, waterline: number): boolean
	return Beach.depthAt(position, waterline) >= beach.LostDepth
end

-- Z where the water reaches a given depth.
function Beach.zForDepth(depth: number, waterline: number): number
	return waterline + depth / beach.Slope
end

return Beach
