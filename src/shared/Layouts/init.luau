-- Hand-built ground layouts: the shape of the beach on top of the even slope.
--
-- The beach is made of tiles, 150 studs deep and the full width, a few to each zone (see
-- Beach.tileAt). Every zone has a base layout (Layouts/Zones/ZoneN) for its tiles that have
-- no biome; a zone without its own file uses the nearest one above it. A biome that rolls on
-- a tile swaps in its own layout (Layouts/Biomes/<BiomeId>), so the ground changes with the
-- biome. A biome's module returns one layout, or a table of them indexed by zone
-- ({ [1] = layout, [2] = ... }) when it differs by zone. Layouts/Biomes/Planned holds layouts
-- for biomes that don't roll yet.
--
-- A layout is { Name = "...", Primitives = { ... } }. Coordinates are X (-360 to 360) and z
-- local to the tile (0 at its landward edge, 150 at its seaward edge); heights are studs
-- above (or below) the base slope. Primitive kinds:
--   Ridge   { Path = {{x, z}, ...}, Height, Width, Rock? }  a bank along a path
--   Mound   { At = {x, z}, Radius, Height, Rock? }          a hump or boulder
--   Channel { Path = {{x, z}, ...}, Depth, Width }          a cut along a path
--   Hollow  { At = {x, z}, Radius, Depth }                  a round dip (a pool)
--   Ramp    { Path = {{x, z}, ...}, Width }                 a cart route: the bare slope
--   Flat    { At = {x, z}, Radius }                         clears the shape to the slope
-- Raised shapes take the highest, cuts the lowest, and the two add. Ramps and Flats apply
-- last and blend into the ground around them over Config.Beach.Terrain.Blend studs. Rock
-- shapes have steeper faces and are built from rock. Beach.feature adds the fades at the
-- tile edges, the cliffs and the rock pools.
--
-- Which layout is active comes from the tile's biome (a Workspace attribute the server
-- sets), so the server and every client agree on the ground. Layouts.setActive overrides
-- that, for tools/tests.

local Biomes = require(script.Parent.Biomes)
local Config = require(script.Parent.Config)

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

Layouts.Kinds = {
	Ridge = { Path = true, Height = true, Width = true, Rock = false },
	Mound = { At = true, Radius = true, Height = true, Rock = false },
	Channel = { Path = true, Depth = true, Width = true },
	Hollow = { At = true, Radius = true, Depth = true },
	Ramp = { Path = true, Width = true },
	Flat = { At = true, Radius = true },
}

local CELL = 16 -- the lookup grid: each cell lists the primitives that reach it

-- Loading -----------------------------------------------------------------------------------

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

local loaded: { base: { [number]: Layout }, biomes: { [string]: any }, planned: { [string]: any } }? = nil

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

-- Whether a module's value is one layout or a table of them indexed by zone.
local function pick(value: any, zone: number): Layout?
	if type(value) ~= "table" then
		return nil
	end
	if value.Primitives then
		return value
	end
	return value[zone]
end

-- The base layout of a zone (nil: flat). A zone without its own uses the nearest above it.
function Layouts.base(zone: number): Layout?
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

-- A biome's layout in a zone (nil: it has none and the base layout stays).
function Layouts.forBiome(biomeId: string, zone: number): Layout?
	return pick(data().biomes[biomeId], zone)
end

-- A planned biome's draft layout in a zone.
function Layouts.forPlanned(biomeId: string, zone: number): Layout?
	return pick(data().planned[biomeId], zone)
end

-- Every layout, for tools/tests: { Source, Zone, Layout } per zone it can appear in.
function Layouts.all(includePlanned: boolean?): { { Source: string, Zone: number, Layout: Layout } }
	local list = {}
	local zones = Config.Beach.ActiveZones
	for zone = 1, zones do
		local base = data().base[zone]
		if base then
			table.insert(list, { Source = "Zones/Zone" .. zone, Zone = zone, Layout = base })
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
				local layout = pick(set[id], zone)
				if layout then
					table.insert(list, { Source = prefix .. id, Zone = zone, Layout = layout })
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

local overrides: { [number]: Layout | false } = {}

-- For tools/tests: force a tile's layout. Pass a layout, a biome id, "Base" for the base
-- layout, false for flat ground, or nil to go back to following the tile's biome. Names are
-- looked up for the tile's own zone, or for `zone` when given (to try any zone's layouts on
-- any tile: they only meet their neighbours at the shared ramp anchors).
function Layouts.setActive(tile: number, layout: Layout | string | boolean | nil, zone: number?)
	local forZone = zone or zoneOfTile(tile)
	if layout == nil then
		overrides[tile] = nil
	elseif layout == false then
		overrides[tile] = false
	elseif layout == "Base" then
		overrides[tile] = Layouts.base(forZone) or false
	elseif type(layout) == "string" then
		overrides[tile] = Layouts.forBiome(layout, forZone)
			or Layouts.forPlanned(layout, forZone)
			or Layouts.base(forZone)
			or false
	else
		overrides[tile] = layout :: Layout
	end
end

-- The layout shaping a tile right now (nil: flat).
function Layouts.active(tile: number): Layout?
	local forced = overrides[tile]
	if forced ~= nil then
		return forced or nil
	end
	local zone = zoneOfTile(tile)
	local biome = Biomes.activeIn(tile)
	return (biome and Layouts.forBiome(biome.Id, zone)) or Layouts.base(zone)
end

-- Compiling -----------------------------------------------------------------------------------

type Compiled = {
	raised: { any },
	cuts: { any },
	masks: { any },
	cells: { [number]: { raised: { any }, cuts: { any }, masks: { any } } },
	count: number,
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
	local c: Compiled = { raised = {}, cuts = {}, masks = {}, cells = {}, count = 0 }
	for _, p in layout.Primitives do
		local entry: any = { kind = p.Kind, rock = p.Rock == true }
		local reach: number
		if p.Path then
			entry.segments = segmentsOf(p.Path)
			entry.half = (p.Width or 0) / 2
		else
			local at = p.At or { 0, 0 }
			entry.segments = { { at[1], at[2], at[1], at[2] } }
			entry.half = p.Radius or 0
		end
		local list
		if p.Kind == "Ridge" or p.Kind == "Mound" then
			entry.amount = p.Height or 0
			reach = entry.half
			list = c.raised
		elseif p.Kind == "Channel" or p.Kind == "Hollow" then
			entry.amount = p.Depth or 0
			reach = entry.half
			list = c.cuts
		else
			reach = entry.half + cfg.Blend
			list = c.masks
		end
		if list and entry.half > 0 then
			table.insert(list, entry)
			local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
			for _, s in entry.segments do
				minX = math.min(minX, s[1], s[3])
				maxX = math.max(maxX, s[1], s[3])
				minZ = math.min(minZ, s[2], s[4])
				maxZ = math.max(maxZ, s[2], s[4])
			end
			local bucket = if list == c.raised then "raised" elseif list == c.cuts then "cuts" else "masks"
			for cx = math.floor((minX - reach) / CELL), math.floor((maxX + reach) / CELL) do
				for cz = math.floor((minZ - reach) / CELL), math.floor((maxZ + reach) / CELL) do
					local key = cellKey(cx, cz)
					local cell = c.cells[key]
					if not cell then
						cell = { raised = {}, cuts = {}, masks = {} }
						c.cells[key] = cell
					end
					table.insert(cell[bucket], entry)
				end
			end
			c.count += 1
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

-- A layout's shape at (x, local z): the height above the slope, and whether it's rock.
function Layouts.evaluate(layout: Layout, x: number, z: number): (number, boolean)
	local c = compile(layout)
	local cell = c.cells[cellKey(math.floor(x / CELL), math.floor(z / CELL))]
	if not cell then
		return 0, false
	end
	local up, rock = 0, false
	for _, p in cell.raised do
		local v = p.amount * profile(distance(p.segments, x, z) / p.half, p.rock)
		if v > up then
			up, rock = v, p.rock
		end
	end
	local down = 0
	for _, p in cell.cuts do
		local v = p.amount * profile(distance(p.segments, x, z) / p.half, false)
		if v > down then
			down = v
		end
	end
	local mask = 1
	for _, p in cell.masks do
		local k = smoothstep((distance(p.segments, x, z) - p.half) / cfg.Blend)
		if k < mask then
			mask = k
		end
	end
	return (up - down) * mask, rock and up * mask > cfg.RockMin
end

-- The active layout's shape on a tile at (x, local z).
function Layouts.shapeAt(tile: number, x: number, z: number): (number, boolean)
	local layout = Layouts.active(tile)
	if not layout then
		return 0, false
	end
	return Layouts.evaluate(layout, x, z)
end

-- Whether a tile has any shape right now.
function Layouts.isShaped(tile: number): boolean
	local layout = Layouts.active(tile)
	return layout ~= nil and compile(layout).count > 0
end

-- Checking ------------------------------------------------------------------------------------

local function isPoint(value: any): boolean
	return type(value) == "table" and type(value[1]) == "number" and type(value[2]) == "number"
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
			elseif type(value) ~= "number" or value <= 0 then
				add(where .. ": " .. key .. " must be a positive number")
			end
		end
		for key, required in fields do
			if required and p[key] == nil then
				add(where .. " (" .. p.Kind .. "): needs " .. key)
			end
		end
		if type(p.Height) == "number" and p.Height > cfg.MaxHeight then
			add(where .. ": Height is over Config.Beach.Terrain.MaxHeight")
		end
		if type(p.Depth) == "number" and p.Depth > cfg.MaxDepth then
			add(where .. ": Depth is over Config.Beach.Terrain.MaxDepth")
		end
	end
	return problems
end

-- For tools/tests.
function Layouts._reset()
	loaded = nil
	overrides = {}
end

return Layouts
