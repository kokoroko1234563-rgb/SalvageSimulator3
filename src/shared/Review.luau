-- The review place (Config.Review): whether this is it, and where a point of the beach is in
-- the layouts' terms (zone, biome, crossing, slot and room), for the review panel and notes.

local Shared = script.Parent
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Layouts = require(Shared.Layouts)

local Review = {}

function Review.enabled(): boolean
	local ok, placeId = pcall(function()
		return game.PlaceId
	end)
	return ok and table.find(Config.Review.PlaceIds, placeId) ~= nil
end

export type Where = {
	Zone: number?,
	ZoneName: string?,
	Biome: string?,
	Layout: string?,
	Choice: string?,
	Crossing: number?,
	Crossings: number?,
	CrossingName: string?,
	Slot: number?,
	SlotName: string?,
	Room: number?,
	Rooms: number?,
	RoomName: string?,
	X: number,
	Z: number, -- from the zone's top edge
}

-- Where a point is: its zone, biome, layout, the crossing that rolled there, and the slot
-- and room it stands in (if any). X and Z are in the zone's own coordinates.
function Review.where(position: Vector3): Where
	local where: Where = { X = position.X, Z = position.Z }
	local zone = Beach.zoneAt(position.Z)
	local tile = Beach.tileAt(position.Z)
	if not zone or not tile then
		return where
	end
	local z0 = Beach.tileRange(tile)
	where.Zone = zone
	where.ZoneName = Config.Zones[zone] and Config.Zones[zone].Name
	where.Z = position.Z - z0
	local biome = Biomes.activeIn(tile)
	where.Biome = biome and biome.Name
	local def = Layouts.activeDef(tile)
	local choice = Layouts.activeChoice(tile)
	if not def or not choice then
		return where
	end
	where.Layout = def.Name
	where.Choice = Layouts.encode(choice)
	local crossings = Layouts.shape(def)
	where.Crossing = choice.Crossing
	where.Crossings = crossings
	where.CrossingName = def.Crossings
		and def.Crossings[choice.Crossing]
		and def.Crossings[choice.Crossing].Name
	for index, slot in def.Slots or {} do
		local x, z = position.X - slot.At[1], where.Z - slot.At[2]
		if x >= 0 and x <= slot.Size[1] and z >= 0 and z <= slot.Size[2] then
			local room = choice.Rooms[index] or 1
			where.Slot = index
			where.SlotName = slot.Name
			where.Room = room
			where.Rooms = #slot.Rooms
			where.RoomName = slot.Rooms[room] and slot.Rooms[room].Name
			break
		end
	end
	return where
end

-- The slot nearest a point in a zone (its index), for stepping through its rooms.
function Review.nearestSlot(tile: number, position: Vector3): number?
	local def = Layouts.activeDef(tile)
	if not def or not def.Slots then
		return nil
	end
	local z0 = Beach.tileRange(tile)
	local best, bestDistance = nil, math.huge
	for index, slot in def.Slots do
		local cx = slot.At[1] + slot.Size[1] / 2
		local cz = z0 + slot.At[2] + slot.Size[2] / 2
		local d = (Vector2.new(cx, cz) - Vector2.new(position.X, position.Z)).Magnitude
		if d < bestDistance then
			best, bestDistance = index, d
		end
	end
	return best
end

return Review
