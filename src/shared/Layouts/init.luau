-- Hand-built ground layouts: the shape of the beach on top of the even slope.
--
-- The beach is made of tiles, 152 studs deep and the full width, a few to each zone (see
-- Beach.tileAt). Every zone has a base layout (Layouts/Zones/ZoneN) for its tiles that have
-- no biome; a zone without its own file uses the nearest one above it. A biome that rolls on
-- a tile swaps in its own layout (Layouts/Biomes/<BiomeId>), so the ground changes with the
-- biome. A biome's module returns one layout, or a table of them indexed by zone
-- ({ [1] = layout, [2] = ... }) when it differs by zone. Layouts/Biomes/Planned holds layouts
-- for biomes that don't roll yet.
--
-- A layout is { Name = "...", Primitives = { ... } }. Coordinates are X (-360 to 360) and z
-- local to the tile (0 at its landward edge, 150 at its seaward edge: the last 2 of its 152
-- studs are the flat strip where tiles meet); heights are studs
-- above (or below) the base slope. Primitive kinds:
--   Ridge   { Path = {{x, z}, ...}, Height, Width, Rock? }  a bank along a path
--   Wall    { Path = {{x, z}, ...}, Height, Width }         a rock wall: flat top, sides too
--                                                           steep to climb (a maze, a cave)
--   Roof    { Path, Width } or { At, Radius },              a slab of rock overhead: its
--           Clearance, Thickness                            underside Clearance studs over the
--                                                           slope, Thickness thick (a tunnel, a
--                                                           cave). The ground under it is still
--                                                           the floor: water, waves and items
--                                                           go by the floor, so caves flood.
--   Mound   { At = {x, z}, Radius, Height, Rock? }          a hump or boulder
--   Channel { Path = {{x, z}, ...}, Depth, Width }          a cut along a path
--   Hollow  { At = {x, z}, Radius, Depth }                  a round dip (a pool)
--   Ramp    { Path = {{x, z}, ...}, Width }                 a cart route: the bare slope
--   Flat    { At = {x, z}, Radius }                         clears the shape to the slope
--   Paint   { Path + Width | At + Radius | Area, Material } the ground's material only (mud,
--                                                           shingle, weed), no shape
-- Any outline: Wall, Ridge, Roof, Hollow, Flat and Paint can take an Area instead: a polygon,
-- { {x, z}, {x, z}, {x, z}, ... } (a Ridge or Hollow slopes in over Width, default 8 studs).
-- Worn edges: Rough = studs (up to Config.Beach.Terrain.MaxRough) makes a shape's edge wobble
-- in and out, so it looks eroded rather than drawn; its middle stays as it is.
-- Materials: Material = a terrain material from Config.Looks.Materials ("Basalt", "Mud") makes
-- a shape (or a Roof, or a cut's floor) of that instead of the zone's own (see Looks).
-- Raised shapes take the highest, cuts the lowest, and the two add. Ramps and Flats apply
-- last and blend into the ground around them over Config.Beach.Terrain.Blend studs. Rock
-- shapes have steeper faces and are built from rock. Beach.feature adds the fades at the
-- tile edges, the cliffs and the rock pools.
--
-- A layout can also say where things go on its ground (all optional, in tile coordinates):
--   Loot      = { { At = {x, z}, Radius, Weight? }, ... }  spots where finds settle
--   Entrances = { {x, z}, ... }                            where a secret's entrance can stand
--   Hazards   = { { Type = "Patrol", Path = ... }, ... }   where its biome's hazards go, by
--               Type (see Hazards.luau for what each kind takes)
--
-- Which layout is active comes from the tile's biome (a Workspace attribute the server
-- sets), so the server and every client agree on the ground. Layouts.setActive overrides
-- that, for tools/tests.

local Workspace = game:GetService("Workspace")

local Biomes = require(script.Parent.Biomes)
local Config = require(script.Parent.Config)
local Decor = require(script.Parent.Decor)
local Hazards = require(script.Parent.Hazards)

local cfg = Config.Beach.Terrain

local Layouts = {}

export type Point = { number }
export type Primitive = {
	Kind: string,
	Path: { Point }?,
	At: Point?,
	Height: number?,
	Depth: number?,
	Width: number?,
	Radius: number?,
	Rock: boolean?,
}
export type Layout = { Name: string, Primitives: { Primitive } }

-- Each kind's fields: true = required, false = optional. Shapes that can be an Area (a
-- polygon) take it instead of their Path or At (checked in Layouts.problems).
Layouts.Kinds = {
	Ridge = {
		Path = false,
		Area = false,
		Height = true,
		Width = false,
		Rock = false,
		Rough = false,
		Material = false,
	},
	Wall = { Path = false, Area = false, Height = true, Width = false, Rough = false, Material = false },
	Roof = {
		Path = false,
		Width = false,
		At = false,
		Radius = false,
		Area = false,
		Clearance = true,
		Thickness = true,
		Rough = false,
		Material = false,
	},
	Mound = { At = true, Radius = true, Height = true, Rock = false, Rough = false, Material = false },
	Channel = { Path = true, Depth = true, Width = true, Rough = false, Material = false },
	Hollow = { At = false, Radius = false, Area = false, Depth = true, Rough = false, Material = false },
	Ramp = { Path = true, Width = true },
	Flat = { At = false, Radius = false, Area = false, Rough = false },
	Paint = {
		Path = false,
		Width = false,
		At = false,
		Radius = false,
		Area = false,
		Material = true,
		Rough = false,
	},
}

-- Which shapes each kind can take: a Path (with Width), an At (with Radius), or an Area.
local SHAPES = {
	Ridge = { Path = true, Area = true },
	Wall = { Path = true, Area = true },
	Roof = { Path = true, At = true, Area = true },
	Mound = { At = true },
	Channel = { Path = true },
	Hollow = { At = true, Area = true },
	Ramp = { Path = true },
	Flat = { At = true, Area = true },
	Paint = { Path = true, At = true, Area = true },
}
local AREA_EDGE = 8 -- studs over which an Area ridge or hollow slopes in from its edge

local CELL = 16 -- the lookup grid: each cell lists the primitives that reach it

-- Zone definitions: a frame, crossings and room slots ------------------------------------------
--
-- A zone's (or a biome's) module returns a definition: a layout (the frame: its Primitives,
-- Loot, Entrances and Hazards, the part that's always there) with two optional parts that
-- change each tide:
--   Crossings = { layout, ... }   the ways through the zone: one is picked each tide, and its
--                                 shapes and placements are added to the frame's
--   Slots = { { Name, At = {x, z}, Size = {w, d}, Rooms = { layout, ... } }, ... }
--                                 side rooms: each tide every slot picks one of its Rooms. A
--                                 room is drawn in the slot's own coordinates (x from 0 to w,
--                                 z from 0 to d; At is the slot's corner nearest the shop at
--                                 the lowest x) and moved into place.
-- The pick is a Choice: { Crossing = i, Rooms = { j, ... } } (one room index per slot). The
-- server rolls one for every zone each tide and stores it on a Workspace attribute
-- ("TileLayoutN", see Layouts.encode), so the server and every client build the same ground.

export type Choice = { Crossing: number, Rooms: { number } }

local function loadFolder(folder: Instance?): { [string]: any }
	local found = {}
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("ModuleScript") then
				found[child.Name] = (require :: any)(child)
			end
		end
	end
	return found
end

local loaded: { base: { [number]: any }, biomes: { [string]: any }, planned: { [string]: any } }? = nil

local function data()
	if not loaded then
		local zones = loadFolder(script:FindFirstChild("Zones"))
		local base = {}
		for name, layout in zones do
			local index = tonumber(string.match(name, "^Zone(%d+)$"))
			if index then
				base[index] = layout
			end
		end
		local biomeFolder = script:FindFirstChild("Biomes")
		loaded = {
			base = base,
			biomes = loadFolder(biomeFolder),
			planned = loadFolder(biomeFolder and biomeFolder:FindFirstChild("Planned")),
		}
	end
	return loaded :: any
end

-- Whether a module's value is one definition or a table of them indexed by zone.
-- With `fallback`, a zone without its own takes the nearest above it (as the game does).
local function pick(value: any, zone: number, fallback: boolean?): any
	if type(value) ~= "table" then
		return nil
	end
	if value.Primitives or value.Crossings or value.Slots then
		return value
	end
	if fallback then
		for index = zone, 1, -1 do
			if value[index] then
				return value[index]
			end
		end
	end
	return value[zone]
end

-- The base definition of a zone (nil: flat). A zone without its own uses the nearest above it.
function Layouts.base(zone: number): any
	local base = data().base
	for index = zone, 1, -1 do
		if base[index] then
			return base[index]
		end
	end
	return nil
end

-- The zone a tile belongs to.
local function zoneOfTile(tile: number): number
	return math.ceil(tile / Config.Beach.TilesPerZone)
end

-- A biome's definition in a zone (nil: it has none and the base stays).
function Layouts.forBiome(biomeId: string, zone: number): any
	return pick(data().biomes[biomeId], zone, true)
end

-- A planned biome's draft in a zone.
function Layouts.forPlanned(biomeId: string, zone: number): any
	return pick(data().planned[biomeId], zone, true)
end

-- How many crossings a definition has, and how many rooms each of its slots has.
function Layouts.shape(def: any): (number, { number })
	local rooms = {}
	for index, slot in def.Slots or {} do
		rooms[index] = math.max(1, #(slot.Rooms or {}))
	end
	return math.max(1, #(def.Crossings or {})), rooms
end

-- A choice's text form (the Workspace attribute), and back. "2:1,3" is crossing 2, room 1 in
-- the first slot and room 3 in the second.
function Layouts.encode(choice: Choice): string
	local rooms = {}
	for index, room in choice.Rooms do
		rooms[index] = tostring(room)
	end
	return choice.Crossing .. ":" .. table.concat(rooms, ",")
end

-- Reads a choice for a definition: missing or out-of-range picks fall back to the first.
function Layouts.decode(def: any, text: string?): Choice
	local crossings, slots = Layouts.shape(def)
	local choice: Choice = { Crossing = 1, Rooms = {} }
	local crossing, rooms = string.match(text or "", "^(%d+):?(.*)$")
	local n = tonumber(crossing)
	if n and n >= 1 and n <= crossings then
		choice.Crossing = n
	end
	local picks = string.split(rooms or "", ",")
	for index, count in slots do
		local room = tonumber(picks[index])
		choice.Rooms[index] = if room and room >= 1 and room <= count then room else 1
	end
	return choice
end

-- A random choice for a definition.
function Layouts.roll(def: any, rng: Random): Choice
	local crossings, slots = Layouts.shape(def)
	local choice: Choice = { Crossing = rng:NextInteger(1, crossings), Rooms = {} }
	for index, count in slots do
		choice.Rooms[index] = rng:NextInteger(1, count)
	end
	return choice
end

local function moved(value: any, dx: number, dz: number): any
	if type(value) ~= "table" then
		return value
	end
	if #value == 2 and type(value[1]) == "number" and type(value[2]) == "number" then
		return { value[1] + dx, value[2] + dz }
	end
	local copy = {}
	for key, item in value do
		copy[key] = if key == "Size" then item else moved(item, dx, dz)
	end
	return copy
end

local PLACEMENTS = { "Primitives", "Loot", "Entrances", "Hazards", "Decor" }
local composedCache: { [any]: { [string]: Layout } } = setmetatable({}, { __mode = "k" }) :: any

-- The layout a definition makes with a choice: the frame, the chosen crossing and each
-- slot's chosen room, as one layout (the same table each time for the same choice).
function Layouts.compose(def: any, choice: Choice?): Layout
	if not def.Crossings and not def.Slots then
		return def -- a plain layout
	end
	local pickChoice = choice or Layouts.decode(def, nil)
	local key = Layouts.encode(pickChoice)
	local cache = composedCache[def]
	if not cache then
		cache = {}
		composedCache[def] = cache
	end
	if cache[key] then
		return cache[key]
	end
	local layout: any = { Name = def.Name, FadeEvery = def.FadeEvery }
	for _, field in PLACEMENTS do
		layout[field] = {}
	end
	local function add(part: any, dx: number, dz: number)
		for _, field in PLACEMENTS do
			for _, item in part[field] or {} do
				table.insert(layout[field], if dx == 0 and dz == 0 then item else moved(item, dx, dz))
			end
		end
	end
	add(def, 0, 0)
	if def.Crossings and def.Crossings[pickChoice.Crossing] then
		add(def.Crossings[pickChoice.Crossing], 0, 0)
	end
	for index, slot in def.Slots or {} do
		local room = slot.Rooms and slot.Rooms[pickChoice.Rooms[index] or 1]
		if room then
			add(room, slot.At[1], slot.At[2])
		end
	end
	for _, field in { "Loot", "Entrances", "Hazards", "Decor" } do
		if #layout[field] == 0 then
			layout[field] = nil
		end
	end
	cache[key] = layout
	return layout
end

-- Every way a definition can come out that tools/tests should check: each crossing (with
-- every slot's first room), then each other room of each slot (with the first crossing).
-- Every room joins the frame, not a crossing, so checking each on its own covers every mix.
function Layouts.options(def: any): { { Label: string, Choice: Choice } }
	local crossings, slots = Layouts.shape(def)
	local function first(): Choice
		local rooms = {}
		for index in slots do
			rooms[index] = 1
		end
		return { Crossing = 1, Rooms = rooms }
	end
	local list = {}
	for crossing = 1, crossings do
		local choice = first()
		choice.Crossing = crossing
		local name = def.Crossings and def.Crossings[crossing] and def.Crossings[crossing].Name
		table.insert(list, {
			Label = if crossings > 1
				then "crossing " .. crossing .. (if name then " (" .. name .. ")" else "")
				else "",
			Choice = choice,
		})
	end
	for index, count in slots do
		for room = 2, count do
			local choice = first()
			choice.Rooms[index] = room
			local slot = def.Slots[index]
			local name = slot.Rooms[room].Name
			table.insert(list, {
				Label = "slot " .. (slot.Name or index) .. " room " .. room .. (if name
					then " (" .. name .. ")"
					else ""),
				Choice = choice,
			})
		end
	end
	return list
end

-- Every layout, for tools/tests: { Source, Zone, Layout, Def, Choice } for each way each
-- definition can come out (Layouts.options) in each zone it can appear in.
function Layouts.all(
	includePlanned: boolean?
): { { Source: string, Zone: number, Layout: Layout, Def: any, Choice: Choice } }
	local list = {}
	local zones = Config.Beach.ActiveZones
	local function addOptions(source: string, zone: number, def: any)
		for _, option in Layouts.options(def) do
			table.insert(list, {
				Source = source .. (if option.Label ~= "" then " " .. option.Label else ""),
				Zone = zone,
				Layout = Layouts.compose(def, option.Choice),
				Def = def,
				Choice = option.Choice,
			})
		end
	end
	for zone = 1, zones do
		local base = data().base[zone]
		if base then
			addOptions("Zones/Zone" .. zone, zone, base)
		end
	end
	local function addAll(set, prefix)
		local ids = {}
		for id in set do
			table.insert(ids, id)
		end
		table.sort(ids)
		for _, id in ids do
			for zone = 1, zones do
				local def = pick(set[id], zone)
				if def then
					addOptions(prefix .. id, zone, def)
				end
			end
		end
	end
	addAll(data().biomes, "Biomes/")
	if includePlanned then
		addAll(data().planned, "Biomes/Planned/")
	end
	return list
end

-- Which layout is active ------------------------------------------------------------------

local overrides: { [number]: { def: any, choice: Choice? } | false } = {}

Layouts.LabAttribute = "WaterLab"

-- The water lab's test layout (Layouts/Lab).
function Layouts.lab(): any
	return require(script.Lab) :: any
end

-- The zone the lab is in (the attribute), kept here: activeDef is asked at every point of the
-- ground, and asking the engine each time slows the terrain's building badly.
local labTile: number? = Workspace:GetAttribute(Layouts.LabAttribute)
pcall(function() -- (tools/tests' Workspace has no such signal)
	Workspace:GetAttributeChangedSignal(Layouts.LabAttribute):Connect(function()
		labTile = Workspace:GetAttribute(Layouts.LabAttribute)
	end)
end)

-- The Workspace attribute holding a tile's choice.
function Layouts.attributeFor(tile: number): string
	return "TileLayout" .. tile
end

-- The definition shaping a tile right now (nil: flat), from its biome or its zone.
function Layouts.activeDef(tile: number): any
	local forced = overrides[tile]
	if forced ~= nil then
		return forced and forced.def or nil
	end
	-- The water lab's test layout (Layouts/Lab), put in a zone from the review place.
	if labTile == tile then
		return Layouts.lab()
	end
	local zone = zoneOfTile(tile)
	local biome = Biomes.activeIn(tile)
	return (biome and Layouts.forBiome(biome.Id, zone)) or Layouts.base(zone)
end

-- For tools/tests: force a tile's layout. Pass a layout or definition, a biome id, "Base" for
-- the zone's own, false for flat ground, or nil to go back to following the tile's biome and
-- rolled choice. Names are looked up for the tile's own zone, or for `zone` when given (to
-- try any zone's layouts on any tile). `choice` picks the crossing and rooms (default: the
-- first of each).
function Layouts.setActive(tile: number, layout: any, zone: number?, choice: Choice?)
	local forZone = zone or zoneOfTile(tile)
	local def
	if layout == nil then
		overrides[tile] = nil
		return
	elseif layout == false then
		overrides[tile] = false
		return
	elseif layout == "Base" then
		def = Layouts.base(forZone)
	elseif type(layout) == "string" then
		def = Layouts.forBiome(layout, forZone)
			or Layouts.forPlanned(layout, forZone)
			or Layouts.base(forZone)
	else
		def = layout
	end
	overrides[tile] = if def then { def = def, choice = choice } else false
end

-- The choice in force on a tile (its rolled one, or the one forced by setActive).
function Layouts.activeChoice(tile: number): Choice?
	local def = Layouts.activeDef(tile)
	if not def then
		return nil
	end
	local forced = overrides[tile]
	if forced and forced.choice then
		return Layouts.decode(def, Layouts.encode(forced.choice))
	elseif forced then
		return Layouts.decode(def, nil)
	end
	return Layouts.decode(def, Workspace:GetAttribute(Layouts.attributeFor(tile)))
end

-- The layout shaping a tile right now (nil: flat). Asked for at every point of the ground,
-- so it's kept until the tile's definition or its choice changes.
local activeCache: { [number]: { def: any, text: any, forced: any, layout: Layout } } = {}

function Layouts.active(tile: number): Layout?
	local def = Layouts.activeDef(tile)
	if not def then
		return nil
	end
	local forced = overrides[tile]
	local text = if forced then nil else Workspace:GetAttribute(Layouts.attributeFor(tile))
	local cached = activeCache[tile]
	if cached and cached.def == def and cached.text == text and cached.forced == forced then
		return cached.layout
	end
	local layout = Layouts.compose(def, Layouts.activeChoice(tile))
	activeCache[tile] = { def = def, text = text, forced = forced, layout = layout }
	return layout
end

-- Old layouts repeated down a zone fade out at each old tile edge (Layouts/Tiled).
function Layouts.fadeEvery(tile: number): number?
	local layout = Layouts.active(tile)
	return layout and (layout :: any).FadeEvery
end

-- Compiling -----------------------------------------------------------------------------------

type Compiled = {
	raised: { any },
	cuts: { any },
	masks: { any },
	roofs: { any },
	paints: { any },
	cells: { [number]: { raised: { any }, cuts: { any }, masks: { any }, roofs: { any }, paints: { any } } },
	count: number,
	roofCount: number,
	paintCount: number,
}

local compiled: { [Layout]: Compiled } = setmetatable({}, { __mode = "k" }) :: any

local function cellKey(cx: number, cz: number): number
	return cx * 4096 + cz
end

local function segmentsOf(path: { Point }): { { number } }
	local segments = {}
	if #path == 1 then
		table.insert(segments, { path[1][1], path[1][2], path[1][1], path[1][2] })
	end
	for i = 1, #path - 1 do
		local a, b = path[i], path[i + 1]
		table.insert(segments, { a[1], a[2], b[1], b[2] })
	end
	return segments
end

local function compile(layout: Layout): Compiled
	local result = compiled[layout]
	if result then
		return result
	end
	local c: Compiled = {
		raised = {},
		cuts = {},
		masks = {},
		roofs = {},
		paints = {},
		cells = {},
		count = 0,
		roofCount = 0,
		paintCount = 0,
	}
	for _, p in layout.Primitives do
		local entry: any =
			{ kind = p.Kind, rock = p.Rock == true, rough = p.Rough or 0, material = p.Material }
		local reach: number
		if p.Area then
			-- A polygon: its edges as segments; the edge distance is signed (see edgeOf).
			local path = table.clone(p.Area)
			table.insert(path, p.Area[1])
			entry.segments = segmentsOf(path)
			entry.polygon = p.Area
			entry.half = 0
			entry.band = if p.Kind == "Ridge" or p.Kind == "Hollow" then p.Width or AREA_EDGE else 0
		elseif p.Path then
			entry.segments = segmentsOf(p.Path)
			entry.half = (p.Width or 0) / 2
		else
			local at = p.At or { 0, 0 }
			entry.segments = { { at[1], at[2], at[1], at[2] } }
			entry.half = p.Radius or 0
		end
		entry.band = entry.band or entry.half
		local list
		if p.Kind == "Roof" then
			entry.clearance = p.Clearance or 0
			entry.thickness = p.Thickness or 0
			reach = entry.half
			list = c.roofs
		elseif p.Kind == "Wall" then
			-- Rock with a flat top and sides too steep to climb.
			entry.amount = p.Height or 0
			entry.rock = true
			entry.wall = true
			reach = entry.half
			list = c.raised
		elseif p.Kind == "Ridge" or p.Kind == "Mound" then
			entry.amount = p.Height or 0
			reach = entry.half
			list = c.raised
		elseif p.Kind == "Channel" or p.Kind == "Hollow" then
			entry.amount = p.Depth or 0
			reach = entry.half
			list = c.cuts
		elseif p.Kind == "Paint" then
			reach = entry.half
			list = c.paints
		else
			reach = entry.half + cfg.Blend
			list = c.masks
		end
		reach += entry.rough
		if list and (entry.half > 0 or entry.polygon) then
			table.insert(list, entry)
			local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
			for _, s in entry.segments do
				minX = math.min(minX, s[1], s[3])
				maxX = math.max(maxX, s[1], s[3])
				minZ = math.min(minZ, s[2], s[4])
				maxZ = math.max(maxZ, s[2], s[4])
			end
			local bucket = if list == c.raised
				then "raised"
				elseif list == c.cuts then "cuts"
				elseif list == c.roofs then "roofs"
				elseif list == c.paints then "paints"
				else "masks"
			for cx = math.floor((minX - reach) / CELL), math.floor((maxX + reach) / CELL) do
				for cz = math.floor((minZ - reach) / CELL), math.floor((maxZ + reach) / CELL) do
					local key = cellKey(cx, cz)
					local cell = c.cells[key]
					if not cell then
						cell = { raised = {}, cuts = {}, masks = {}, roofs = {}, paints = {} }
						c.cells[key] = cell
					end
					table.insert(cell[bucket], entry)
				end
			end
			if list == c.roofs then
				c.roofCount += 1 -- a roof isn't ground: the floor under it is
			elseif list == c.paints then
				c.paintCount += 1 -- paint only changes what the ground is made of
			else
				c.count += 1
			end
		end
	end
	compiled[layout] = c
	return c
end

-- Evaluating ----------------------------------------------------------------------------------

-- Distance from (x, z) to the nearest of a primitive's segments.
local function distance(segments: { { number } }, x: number, z: number): number
	local best = math.huge
	for _, s in segments do
		local ax, az, bx, bz = s[1], s[2], s[3], s[4]
		local dx, dz = bx - ax, bz - az
		local len2 = dx * dx + dz * dz
		local t = if len2 > 0 then math.clamp(((x - ax) * dx + (z - az) * dz) / len2, 0, 1) else 0
		local px, pz = ax + dx * t - x, az + dz * t - z
		local d = px * px + pz * pz
		if d < best then
			best = d
		end
	end
	return math.sqrt(best)
end

-- A smooth bank: 1 at the centre, 0 at the edge. Rock has a flatter top and steeper faces.
-- A wall's sides go from its foot to its full height over this many studs (the terrain's own
-- cells soften that a little), far steeper than anyone can climb.
-- Whether (x, z) is inside a polygon (even-odd rule).
local function insidePolygon(points: { Point }, x: number, z: number): boolean
	local inside = false
	local j = #points
	for i = 1, #points do
		local a, b = points[i], points[j]
		if (a[2] > z) ~= (b[2] > z) and x < (b[1] - a[1]) * (z - a[2]) / (b[2] - a[2]) + a[1] then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- Smooth noise from -1 to 1 over the ground, the same everywhere the game runs: wobbles a
-- Rough shape's edge so it looks worn rather than drawn.
local ROUGH_SCALE = 9 -- studs between the wobbles' peaks, roughly
local function hash(ix: number, iz: number): number
	local h = math.sin(ix * 127.1 + iz * 311.7) * 43758.5453
	return (h - math.floor(h)) * 2 - 1
end
local function noise(x: number, z: number): number
	local function layer(scale: number): number
		local fx, fz = x / scale, z / scale
		local ix, iz = math.floor(fx), math.floor(fz)
		local tx, tz = fx - ix, fz - iz
		tx, tz = tx * tx * (3 - 2 * tx), tz * tz * (3 - 2 * tz)
		local a = hash(ix, iz) + (hash(ix + 1, iz) - hash(ix, iz)) * tx
		local b = hash(ix, iz + 1) + (hash(ix + 1, iz + 1) - hash(ix, iz + 1)) * tx
		return a + (b - a) * tz
	end
	return layer(ROUGH_SCALE) * 0.7 + layer(ROUGH_SCALE / 2.7) * 0.3
end

-- How far (x, z) is outside a primitive's edge: negative inside it. For a Path or At shape,
-- the distance from its middle less its half width; for an Area, the distance to its
-- outline, negative inside. A Rough shape's edge wobbles in and out by up to Rough studs.
local function edgeOf(p: any, x: number, z: number): number
	local d = distance(p.segments, x, z)
	local e = if p.polygon then (if insidePolygon(p.polygon, x, z) then -d else d) else d - p.half
	if p.rough > 0 then
		e += p.rough * noise(x, z)
	end
	return e
end

local WALL_EDGE = 1.5

local function profile(t: number, rock: boolean): number
	if t >= 1 then
		return 0
	end
	if rock then
		local u = 1 - t * t * t * t
		return u * u
	end
	local u = 1 - t * t
	return u * u
end

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- A layout's shape at (x, local z): the height above the slope, whether it's rock, and the
-- material the shape asks for there (nil: the zone's own, see Looks).
function Layouts.evaluate(layout: Layout, x: number, z: number): (number, boolean, string?)
	local c = compile(layout)
	local cell = c.cells[cellKey(math.floor(x / CELL), math.floor(z / CELL))]
	if not cell then
		return 0, false, nil
	end
	local up, rock, upMaterial = 0, false, nil
	for _, p in cell.raised do
		local e = edgeOf(p, x, z)
		local v = if p.wall
			then p.amount * math.clamp(-e / WALL_EDGE, 0, 1)
			else p.amount * profile((e + p.band) / p.band, p.rock)
		if v > up then
			up, rock, upMaterial = v, p.rock, p.material
		end
	end
	local down, downMaterial = 0, nil
	for _, p in cell.cuts do
		local v = p.amount * profile((edgeOf(p, x, z) + p.band) / p.band, false)
		if v > down then
			down, downMaterial = v, p.material
		end
	end
	local mask = 1
	for _, p in cell.masks do
		local k = smoothstep(edgeOf(p, x, z) / cfg.Blend)
		if k < mask then
			mask = k
		end
	end
	local height = (up - down) * mask
	local material = if up * mask > 0.5 and up >= down
		then upMaterial
		elseif down * mask > 0.5 then downMaterial
		else nil
	return height, rock and up * mask > cfg.RockMin, material
end

-- The ground material a layout paints at (x, local z), or nil: the last Paint covering it.
function Layouts.paintIn(layout: Layout, x: number, z: number): string?
	local c = compile(layout)
	if c.paintCount == 0 then
		return nil
	end
	local cell = c.cells[cellKey(math.floor(x / CELL), math.floor(z / CELL))]
	if not cell then
		return nil
	end
	local material = nil
	for _, p in cell.paints do
		if edgeOf(p, x, z) <= 0 then
			material = p.material
		end
	end
	return material
end

-- The active layout's shape on a tile at (x, local z).
function Layouts.shapeAt(tile: number, x: number, z: number): (number, boolean, string?)
	local layout = Layouts.active(tile)
	if not layout then
		return 0, false, nil
	end
	return Layouts.evaluate(layout, x, z)
end

-- The ground material the active layout paints on a tile at (x, local z), or nil.
function Layouts.paintAt(tile: number, x: number, z: number): string?
	local layout = Layouts.active(tile)
	return layout and Layouts.paintIn(layout, x, z)
end

-- Whether a tile has any shape right now.
function Layouts.isShaped(tile: number): boolean
	local layout = Layouts.active(tile)
	return layout ~= nil and compile(layout).count > 0
end

-- A layout's roof over (x, local z): its underside and top, in studs over the slope, or nil.
function Layouts.roofIn(layout: Layout, x: number, z: number): (number?, number?, string?)
	local c = compile(layout)
	if c.roofCount == 0 then
		return nil, nil, nil
	end
	local cell = c.cells[cellKey(math.floor(x / CELL), math.floor(z / CELL))]
	if not cell then
		return nil, nil, nil
	end
	local bottom, top, material = nil, nil, nil
	for _, p in cell.roofs do
		if edgeOf(p, x, z) <= 0 then
			bottom = if bottom then math.min(bottom, p.clearance) else p.clearance
			top = if top then math.max(top, p.clearance + p.thickness) else p.clearance + p.thickness
			material = material or p.material
		end
	end
	return bottom, top, material
end

-- The active roof on a tile at (x, local z).
function Layouts.roofAt(tile: number, x: number, z: number): (number?, number?, string?)
	local layout = Layouts.active(tile)
	if not layout then
		return nil, nil, nil
	end
	return Layouts.roofIn(layout, x, z)
end

-- What the tile's active layout places on its ground: loot spots and entrance spots in world
-- X and Z (`z0` is the tile's start, from Beach.tileRange), and hazard placements as written.
function Layouts.lootSpots(
	tile: number,
	z0: number
): { { X: number, Z: number, Radius: number, Weight: number } }
	local layout = Layouts.active(tile)
	local spots = {}
	for _, spot in (layout and (layout :: any).Loot) or {} do
		table.insert(
			spots,
			{ X = spot.At[1], Z = z0 + spot.At[2], Radius = spot.Radius, Weight = spot.Weight or 1 }
		)
	end
	return spots
end

function Layouts.entrances(tile: number, z0: number): { Vector2 }
	local layout = Layouts.active(tile)
	local spots = {}
	for _, point in (layout and (layout :: any).Entrances) or {} do
		table.insert(spots, Vector2.new(point[1], z0 + point[2]))
	end
	return spots
end

-- The tile's decor (Decor.luau), in tile coordinates: its active layout's Decor list.
function Layouts.decor(tile: number): { { [string]: any } }
	local layout = Layouts.active(tile)
	return (layout and (layout :: any).Decor) or {}
end

-- The layout's placements for one kind of hazard (tile coordinates), or an empty list.
function Layouts.hazardPlacements(tile: number, hazardType: string): { { [string]: any } }
	local layout = Layouts.active(tile)
	local list = {}
	for _, placement in (layout and (layout :: any).Hazards) or {} do
		if placement.Type == hazardType then
			table.insert(list, placement)
		end
	end
	return list
end

-- Checking ------------------------------------------------------------------------------------

local function isPoint(value: any): boolean
	return type(value) == "table" and type(value[1]) == "number" and type(value[2]) == "number"
end

-- Whether a point (tile coordinates) lies on the tile.
local function onTile(point: { number }): boolean
	return math.abs(point[1]) <= Config.Beach.Width / 2
		and point[2] >= 0
		and point[2] <= Config.Beach.TileLength
end

-- What's wrong with a layout, as a list of messages (empty: nothing).
function Layouts.problems(layout: any): { string }
	local problems = {}
	local function add(message: string)
		table.insert(problems, message)
	end
	if type(layout) ~= "table" or type(layout.Name) ~= "string" or type(layout.Primitives) ~= "table" then
		add("a layout needs a Name and a Primitives list")
		return problems
	end
	for key in layout do
		if
			key ~= "Name"
			and key ~= "Primitives"
			and key ~= "Loot"
			and key ~= "Entrances"
			and key ~= "Hazards"
			and key ~= "Decor"
			and key ~= "FadeEvery"
		then
			add(layout.Name .. ": unknown field " .. tostring(key))
		end
	end
	for index, spot in layout.Loot or {} do
		local where = layout.Name .. " loot spot " .. index
		if
			type(spot) ~= "table"
			or not isPoint(spot.At)
			or type(spot.Radius) ~= "number"
			or spot.Radius <= 0
		then
			add(where .. ": needs At = {x, z} and a Radius")
		elseif spot.Weight ~= nil and (type(spot.Weight) ~= "number" or spot.Weight <= 0) then
			add(where .. ": Weight must be a positive number")
		elseif not onTile(spot.At) then
			add(where .. ": outside the tile")
		end
	end
	for index, point in layout.Entrances or {} do
		if not isPoint(point) then
			add(layout.Name .. " entrance " .. index .. ": must be {x, z}")
		elseif not onTile(point) then
			add(layout.Name .. " entrance " .. index .. ": outside the tile")
		end
	end
	for _, problem in Decor.problems(layout.Decor, layout.Name) do
		add(problem)
	end
	for index, placement in layout.Hazards or {} do
		local where = layout.Name .. " hazard " .. index
		local fields = type(placement) == "table" and Hazards.Placement[placement.Type]
		if not fields then
			add(where .. ": unknown hazard type " .. tostring(type(placement) == "table" and placement.Type))
			continue
		end
		for key, value in placement do
			if key == "Type" then
				continue
			elseif not fields[key] then
				add(where .. " (" .. placement.Type .. "): unknown field " .. tostring(key))
			elseif key == "At" and not isPoint(value) then
				add(where .. ": At is {x, z}")
			elseif key == "Path" and (type(value) ~= "table" or #value < 2 or not isPoint(value[1])) then
				add(where .. ": Path needs at least two {x, z} points")
			elseif key == "Lanes" and (type(value) ~= "table" or #value < 1) then
				add(where .. ": Lanes is a list of X positions")
			elseif
				(key == "Count" or key == "Radius" or key == "Depth")
				and (type(value) ~= "number" or value <= 0)
			then
				add(where .. ": " .. key .. " must be a positive number")
			elseif key == "Covered" and type(value) ~= "boolean" then
				add(where .. ": Covered is true or false")
			end
		end
	end
	for index, p in layout.Primitives do
		local where = layout.Name .. " #" .. index
		local fields = type(p) == "table" and Layouts.Kinds[p.Kind]
		if not fields then
			add(where .. ": unknown kind " .. tostring(type(p) == "table" and p.Kind))
			continue
		end
		for key, value in p do
			if key == "Kind" then
				continue
			elseif fields[key] == nil then
				add(where .. " (" .. p.Kind .. "): unknown field " .. tostring(key))
			elseif key == "Path" then
				if type(value) ~= "table" or #value < 1 then
					add(where .. ": Path needs at least one point")
				else
					for _, point in value do
						if not isPoint(point) then
							add(where .. ": Path points are {x, z}")
							break
						end
					end
				end
			elseif key == "At" then
				if not isPoint(value) then
					add(where .. ": At is {x, z}")
				end
			elseif key == "Rock" then
				if type(value) ~= "boolean" then
					add(where .. ": Rock is true or false")
				end
			elseif key == "Area" then
				local ok = type(value) == "table" and #value >= 3
				for _, point in (if ok then value else {}) do
					ok = ok and isPoint(point)
				end
				if not ok then
					add(where .. ": Area is a list of at least three {x, z} points")
				end
			elseif key == "Material" then
				if type(value) ~= "string" or not Config.Looks.Materials[value] then
					add(where .. ": Material " .. tostring(value) .. " isn't in Config.Looks.Materials")
				end
			elseif key == "Rough" then
				if type(value) ~= "number" or value < 0 or value > cfg.MaxRough then
					add(where .. ": Rough is 0 to Config.Beach.Terrain.MaxRough studs")
				end
			elseif type(value) ~= "number" or value <= 0 then
				add(where .. ": " .. key .. " must be a positive number")
			end
		end
		for key, required in fields do
			if required and p[key] == nil then
				add(where .. " (" .. p.Kind .. "): needs " .. key)
			end
		end
		-- Its shape: exactly one of a Path (with Width, where the kind needs one), an At (with
		-- Radius) or an Area.
		local shapes = SHAPES[p.Kind]
		local given = {}
		for _, shape in { "Path", "At", "Area" } do
			if p[shape] ~= nil then
				table.insert(given, shape)
			end
		end
		if #given ~= 1 or not shapes[given[1]] then
			local allowed = {}
			for _, shape in { "Path", "At", "Area" } do
				if shapes[shape] then
					table.insert(allowed, shape)
				end
			end
			add(where .. " (" .. p.Kind .. "): needs one of " .. table.concat(allowed, ", "))
		elseif given[1] == "Path" and p.Width == nil then
			add(where .. " (" .. p.Kind .. "): a Path needs a Width")
		elseif given[1] == "At" and p.Radius == nil then
			add(where .. " (" .. p.Kind .. "): an At needs a Radius")
		end
		if p.Kind == "Roof" then
			if type(p.Thickness) == "number" and p.Thickness < cfg.RoofMinThickness then
				add(where .. ": a Roof must be at least Config.Beach.Terrain.RoofMinThickness thick")
			end
			if type(p.Clearance) == "number" and p.Clearance < cfg.RoofMinClearance then
				add(where .. ": Clearance is under Config.Beach.Terrain.RoofMinClearance")
			end
			if
				type(p.Clearance) == "number"
				and type(p.Thickness) == "number"
				and p.Clearance + p.Thickness > cfg.RoofMaxTop
			then
				add(where .. ": a Roof's top (Clearance + Thickness) is over Config.Beach.Terrain.RoofMaxTop")
			end
		elseif p.Kind == "Wall" then
			if type(p.Height) == "number" and p.Height > cfg.WallMaxHeight then
				add(where .. ": Height is over Config.Beach.Terrain.WallMaxHeight")
			end
			if type(p.Width) == "number" and p.Width < cfg.WallMinWidth then
				add(where .. ": a Wall must be at least Config.Beach.Terrain.WallMinWidth wide")
			end
		elseif type(p.Height) == "number" and p.Height > cfg.MaxHeight then
			add(where .. ": Height is over Config.Beach.Terrain.MaxHeight")
		end
		if type(p.Depth) == "number" and p.Depth > cfg.MaxDepth then
			add(where .. ": Depth is over Config.Beach.Terrain.MaxDepth")
		end
	end
	return problems
end

-- What's wrong with a zone's definition itself (its crossings and slots), as messages. Each
-- way it can come out is a layout, checked with Layouts.problems.
function Layouts.defProblems(def: any, where: string): { string }
	local problems = {}
	local function add(message: string)
		table.insert(problems, where .. ": " .. message)
	end
	if type(def) ~= "table" or type(def.Name) ~= "string" then
		add("needs a Name")
		return problems
	end
	for key in def do
		if
			not table.find({
				"Name",
				"Primitives",
				"Loot",
				"Entrances",
				"Hazards",
				"Decor",
				"Crossings",
				"Slots",
				"FadeEvery",
				"Paths",
			}, key)
		then
			add("unknown field " .. tostring(key))
		end
	end
	if def.Crossings ~= nil and (type(def.Crossings) ~= "table" or #def.Crossings == 0) then
		add("Crossings must be a list of layouts")
	end
	-- How many distinct paths through it a crossing (or a zone without crossings) has: 1 to
	-- Config.Paths.MaxCount. The path checks (tools/paths.luau) hold it to that.
	local function pathsProblem(where: string, paths: any)
		if
			paths ~= nil
			and (type(paths) ~= "number" or paths % 1 ~= 0 or paths < 1 or paths > Config.Paths.MaxCount)
		then
			add(where .. ": Paths is a whole number from 1 to " .. Config.Paths.MaxCount)
		end
	end
	pathsProblem("the layout", def.Paths)
	for index, crossing in def.Crossings or {} do
		if type(crossing) ~= "table" or type(crossing.Primitives) ~= "table" then
			add("crossing " .. index .. " needs Primitives")
		else
			pathsProblem("crossing " .. index, crossing.Paths)
		end
	end
	for index, slot in def.Slots or {} do
		local name = "slot " .. tostring(slot.Name or index)
		if not isPoint(slot.At) or not isPoint(slot.Size) or slot.Size[1] <= 0 or slot.Size[2] <= 0 then
			add(name .. ": needs At = {x, z} and Size = {w, d}")
			continue
		end
		if type(slot.Rooms) ~= "table" or #slot.Rooms == 0 then
			add(name .. ": needs Rooms")
			continue
		end
		local w, d = slot.Size[1], slot.Size[2]
		for roomIndex, room in slot.Rooms do
			local roomName = name .. " room " .. roomIndex
			if type(room) ~= "table" or type(room.Primitives) ~= "table" then
				add(roomName .. ": needs Primitives")
				continue
			end
			-- Everything in a room stays inside its slot (shapes by their middle lines).
			local function inside(point: any): boolean
				return point[1] >= 0 and point[1] <= w and point[2] >= 0 and point[2] <= d
			end
			for _, field in PLACEMENTS do
				for itemIndex, item in room[field] or {} do
					local points = {}
					if isPoint(item) then
						table.insert(points, item)
					end
					if type(item) == "table" and isPoint(item.At) then
						table.insert(points, item.At)
					end
					for _, list in { "Path", "Area" } do
						if type(item) == "table" and type(item[list]) == "table" then
							for _, point in item[list] do
								table.insert(points, point)
							end
						end
					end
					for _, point in points do
						if isPoint(point) and not inside(point) then
							add(roomName .. " " .. field .. " " .. itemIndex .. ": outside its slot")
							break
						end
					end
				end
			end
		end
	end
	return problems
end

-- For tools/tests.
function Layouts._reset()
	loaded = nil
	overrides = {}
	activeCache = {}
end

return Layouts
