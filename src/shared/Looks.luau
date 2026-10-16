-- How each part of the beach looks (Config.Looks): its ground and rock, its fog, its haze and
-- light. Each zone has a look, and a biome rolled on a tile lays its own Look over its zone's,
-- so it stands out wherever it rolls but still gets darker and foggier the deeper it is:
--   Floor, Rock   its own terrain materials (from Config.Looks.Materials)
--   colours       mixed into the zone's by Mix (0 to 1, default 0.6)
--   numbers       added to the zone's (Fog = 0.1: a little foggier than the zone around it)
-- Looks blend over Config.Looks.Blend studs where zones and tiles meet.
--
-- The terrain takes Floor and Rock (Looks.terrainAt); the client blends the rest as you walk
-- (DayController for the light, MistController for the fog).

local Shared = script.Parent
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)

local cfg = Config.Looks

local Looks = {}

export type Look = {
	Floor: string,
	Rock: string,
	Fog: number,
	Haze: Color3,
	Decay: Color3,
	Outdoor: Color3,
	Ambient: Color3,
	Brightness: number,
	Saturation: number,
	Contrast: number,
	Exposure: number,
	Tint: Color3,
}

local NUMBERS = { "Fog", "Brightness", "Saturation", "Contrast", "Exposure" }
local COLORS = { "Haze", "Decay", "Outdoor", "Ambient", "Tint" }

-- The zone's look at a point along the beach (Z): [0] behind the shop, the Far Sandbar's
-- past the last zone.
local function zoneLook(z: number): Look
	local zone = Beach.zoneAt(z)
	if zone == nil or zone > Config.Beach.ActiveZones then
		zone = Beach.FarSandbarZone
	end
	return cfg.Zones[zone] or cfg.Zones[0]
end

-- The look in a zone with a biome (or none) over it.
local function lookWith(look: Look, biome: any): Look
	if biome and biome.Look then
		local over = biome.Look
		local mix = over.Mix or 0.6
		local merged: any = table.clone(look)
		merged.Floor = over.Floor or look.Floor
		merged.Rock = over.Rock or look.Rock
		for _, key in NUMBERS do
			merged[key] = look[key] + (over[key] or 0)
		end
		for _, key in COLORS do
			if over[key] then
				merged[key] = look[key]:Lerp(over[key], mix)
			end
		end
		return merged
	end
	return look
end

-- The look at a point (Z), unblended: the zone's, with the tile's biome laid over it.
function Looks.pointAt(z: number): Look
	return lookWith(zoneLook(z), Biomes.activeIn(Beach.tileAt(z)))
end

-- The look at a point (Z), blended over Blend studs across zone and tile edges.
function Looks.at(z: number): Look
	local samples = 5
	local blended: any = table.clone(Looks.pointAt(z))
	for _, key in NUMBERS do
		blended[key] = 0
	end
	local colors = {}
	for _, key in COLORS do
		colors[key] = Vector3.zero
	end
	for i = 0, samples - 1 do
		local look: any = Looks.pointAt(z + (i / (samples - 1) - 0.5) * cfg.Blend)
		for _, key in NUMBERS do
			blended[key] += look[key] / samples
		end
		for _, key in COLORS do
			local c = look[key]
			colors[key] += Vector3.new(c.R, c.G, c.B) / samples
		end
	end
	for _, key in COLORS do
		local v = colors[key]
		blended[key] = Color3.new(v.X, v.Y, v.Z)
	end
	return blended
end

-- A steady pseudo-random number (0-1) for a terrain cell, so the ground's blend between two
-- looks is a fixed scatter, not a straight line.
local function scatter(x: number, z: number): number
	local h = math.sin(math.floor(x / 4) * 12.9898 + math.floor(z / 4) * 78.233) * 43758.5453
	return h - math.floor(h)
end

-- The terrain materials at a point: its floor and its rock. Across Blend studs where looks
-- meet, cells take one look's or the other's, scattered.
-- A function giving the terrain materials at a point (x, z): its floor and its rock. Across
-- Blend studs where looks meet, cells take one look's or the other's, scattered. A biome's
-- own ground stops at its tile's edges, so a tile's terrain only ever depends on its own
-- biome (rebuilding the tile is enough when its biome changes). The biomes are read once,
-- when it's made: make one for each piece of terrain written.
function Looks.terrainReader(): (x: number, z: number) -> (Enum.Material, Enum.Material)
	local biomes, own = {}, {}
	for tile = 1, Beach.ActiveTiles do
		biomes[tile] = Biomes.activeIn(tile) or false
		own[tile] = Looks.hasOwnGround(biomes[tile] or nil)
	end
	local materials: { [Look]: { Enum.Material } } = {}
	return function(x: number, z: number)
		local at = z + (scatter(x, z) - 0.5) * cfg.Blend
		local tile, other = Beach.tileAt(z), Beach.tileAt(at)
		if tile ~= other and ((tile and own[tile]) or (other and own[other])) then
			at = z
		end
		local atTile = Beach.tileAt(at)
		local look = lookWith(zoneLook(at), atTile and biomes[atTile] or nil)
		local pair = materials[look]
		if not pair then
			pair = { (Enum.Material :: any)[look.Floor], (Enum.Material :: any)[look.Rock] }
			materials[look] = pair
		end
		return pair[1], pair[2]
	end
end

-- The terrain materials at a point (see Looks.terrainReader).
function Looks.terrainAt(x: number, z: number): (Enum.Material, Enum.Material)
	return Looks.terrainReader()(x, z)
end

-- Whether a biome brings its own ground (terrain materials).
function Looks.hasOwnGround(biome: any): boolean
	return biome ~= nil and biome.Look ~= nil and (biome.Look.Floor ~= nil or biome.Look.Rock ~= nil)
end

-- Applies the materials' colours to the terrain.
function Looks.paint(terrain: Terrain)
	for name, color in cfg.Materials do
		terrain:SetMaterialColor((Enum.Material :: any)[name], color)
	end
end

-- What's wrong with the looks (for tools/tests): missing fields, unknown materials.
function Looks.problems(): { string }
	local problems = {}
	local function check(where: string, look: any, partial: boolean)
		for _, key in { "Floor", "Rock" } do
			local value = look[key]
			if value == nil then
				if not partial then
					table.insert(problems, where .. ": no " .. key)
				end
			elseif not cfg.Materials[value] then
				table.insert(
					problems,
					where .. ": " .. key .. " " .. tostring(value) .. " isn't in Looks.Materials"
				)
			end
		end
		for _, key in NUMBERS do
			if look[key] == nil and not partial then
				table.insert(problems, where .. ": no " .. key)
			elseif look[key] ~= nil and type(look[key]) ~= "number" then
				table.insert(problems, where .. ": " .. key .. " must be a number")
			end
		end
		for _, key in COLORS do
			if look[key] == nil and not partial then
				table.insert(problems, where .. ": no " .. key)
			elseif look[key] ~= nil and typeof(look[key]) ~= "Color3" then
				table.insert(problems, where .. ": " .. key .. " must be a Color3")
			end
		end
		for key in look do
			if
				key ~= "Floor"
				and key ~= "Rock"
				and not (partial and key == "Mix")
				and not table.find(NUMBERS, key)
				and not table.find(COLORS, key)
			then
				table.insert(problems, where .. ": unknown field " .. tostring(key))
			end
		end
	end
	for zone = 0, Beach.FarSandbarZone do
		local look = cfg.Zones[zone]
		if not look then
			table.insert(problems, "zone " .. zone .. " has no look")
		else
			check("zone " .. zone, look, false)
		end
	end
	for _, list in { Biomes.List, Biomes.Planned } do
		for id, biome in list do
			if biome.Look then
				check(tostring(biome.Id or id), biome.Look, true)
			end
		end
	end
	for name in cfg.Materials do
		if not pcall(function()
			return (Enum.Material :: any)[name]
		end) then
			table.insert(problems, "unknown terrain material " .. name)
		end
	end
	return problems
end

return Looks
