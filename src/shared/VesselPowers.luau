-- The exotic vessels' powers, as plain functions of numbers and vessel kinds, so the server,
-- the client and the tests agree (the powers themselves are Gear.Vessels fields):
--   Rides          a boat the owner boards over deep water and drives (Longboat, Leviathan)
--   Scoops         picks up free items within Config.Grab.ScoopRange, one per ScoopInterval (Jelly Raft)
--   Ghost          never collides with the map (Magic Carpet)
--   Unspillable    cargo is never lost: no tipping, spilling, wash-off or sinking (Shell Wagon)
--   SellBonus      items sold from it are worth this much more (Glass Swan)
--   TowWalkBonus   its owner walks this much faster while towing it (Frost Sled)

local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)

local VesselPowers = {}

local function def(kind: string?)
	return Gear.getVessel(kind)
end

function VesselPowers.rides(kind: string?): boolean
	local d = def(kind)
	return d ~= nil and d.Rides == true
end

function VesselPowers.unspillable(kind: string?): boolean
	local d = def(kind)
	return d ~= nil and d.Unspillable == true
end

function VesselPowers.ghost(kind: string?): boolean
	local d = def(kind)
	return d ~= nil and d.Ghost == true
end

-- What items sold from this vessel are worth, as a multiplier (1 for most vessels).
function VesselPowers.sellMultiplier(kind: string?): number
	local d = def(kind)
	return 1 + (if d and d.SellBonus then d.SellBonus else 0)
end

-- The multiplier on a player's walk speed: a sled's bonus only while it is being towed.
function VesselPowers.towWalkMultiplier(kind: string?, towing: boolean): number
	local d = def(kind)
	if not towing or not d or not d.TowWalkBonus then
		return 1
	end
	return 1 + d.TowWalkBonus
end

-- Whether a boat can be boarded: the player near it and the boat over deep water.
function VesselPowers.canBoard(distance: number, boatInDeepWater: boolean): (boolean, string?)
	if distance > Config.Grab.BoardRange then
		return false, "Too far from the boat"
	end
	if not boatInDeepWater then
		return false, "Tow it into deep water to board"
	end
	return true
end

-- A boat's top speed for its owner, studs a second (`speedMultiplier` is Stats.vesselSpeed).
function VesselPowers.boatSpeed(kind: string?, speedMultiplier: number): number
	local d = def(kind)
	return Config.Grab.BoatSpeed * (if d and d.Speed then d.Speed else 1) * speedMultiplier
end

-- Server-side sanity check on a ridden boat: it moved `distance` studs in `dt` seconds.
function VesselPowers.boatSpeedOk(
	kind: string?,
	speedMultiplier: number,
	distance: number,
	dt: number
): boolean
	return distance <= VesselPowers.boatSpeed(kind, speedMultiplier) * Config.Grab.BoatSpeedSlack * dt + 2
end

-- Whether a raft scoops now: a free item within range, room in the hold and the interval over.
function VesselPowers.canScoop(distance: number, held: number, capacity: number, since: number): boolean
	return distance <= Config.Grab.ScoopRange and held < capacity and since >= Config.Grab.ScoopInterval
end

-- Where a leashed vessel (the carpet) should be: where it is, or on the leash if it strayed.
function VesselPowers.leashed(vessel: Vector3, owner: Vector3, leash: number): Vector3
	local offset = vessel - owner
	if offset.Magnitude <= leash then
		return vessel
	end
	return owner + offset.Unit * leash
end

return VesselPowers
