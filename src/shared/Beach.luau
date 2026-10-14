-- Beach geometry helpers shared by server and client.

local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)
local Tide = require(script.Parent.Tide)

local beach = Config.Beach

local Beach = {}

Beach.Length = beach.ZoneLength * beach.ActiveZones

-- Zone index for an X position: 0 in the shop area, nil past the built beach.
function Beach.zoneAt(x: number): number?
	if x < 0 then
		return 0
	end
	local index = math.floor(x / beach.ZoneLength) + 1
	if index > beach.ActiveZones then
		return nil
	end
	return index
end

function Beach.zoneRange(index: number): (number, number)
	return (index - 1) * beach.ZoneLength, index * beach.ZoneLength
end

-- Height of the sand/seabed surface at a given distance out from the waterline.
function Beach.groundY(z: number): number
	if z <= 0 then
		return 0
	end
	return -math.min(z, beach.SlopeRun) / beach.SlopeRun * beach.SlopeDrop
end

function Beach.depthBand(z: number): number
	if z <= 0 then
		return Gear.Depth.Dry
	elseif z < beach.ShallowEnd then
		return Gear.Depth.Shallow
	elseif z < beach.KneeEnd then
		return Gear.Depth.KneeDeep
	elseif z < beach.WaistEnd then
		return Gear.Depth.Waist
	end
	return Gear.Depth.Deep
end

-- Deep water drowns players and swallows vessels: far out at sea, or under the tide.
function Beach.isDeep(position: Vector3, frontX: number): boolean
	return position.Z >= beach.WaistEnd or position.X > frontX + Config.Tide.DeepOffset
end

function Beach.isFlooded(position: Vector3, frontX: number): boolean
	return position.X > frontX + Config.Tide.FloodOffset
end

function Beach.isInSea(position: Vector3): boolean
	return position.Z > 0
end

-- Convenience for callers that don't already have the front position.
function Beach.isDeepNow(position: Vector3): boolean
	return Beach.isDeep(position, Tide.frontX())
end

return Beach
