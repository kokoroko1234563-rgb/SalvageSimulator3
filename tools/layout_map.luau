--[[
	Draws each descent layout as an ASCII map, from the game's own ground data (Beach.groundAt),
	and prints what the layout does: how much of its lower half a player at the top edge can't
	see, whether carts and players on foot can reach the sea, how tall and deep it is, and how
	long the fastest way across takes on foot against its zone's CrossTime (Config.Zones).

	It also writes the maps into the layout notes, between the <!-- map ... --> markers, so the
	notes can't drift from the layouts.

	Usage (from the repo root): lune run tools/layout_map.luau [docs/layouts | -] [sources...] [--maps]
	Without a folder (or with -) it only prints the measurements; --maps prints the maps too
	(they're always drawn when writing the notes). Name sources ("Zones/Zone5",
	"Biomes/HermitHollows") to report only those. Every way a zone can come out is reported:
	each crossing, each room of each slot; the maps are keyed Source@zone, with /c2 for
	crossing 2 or /s3r2 for room 2 of slot 3. Each map is 72 columns (10 studs each) by one row
	per 10 studs of the zone, top edge first. Legend: # rock, ^ raised sand, . flat, ~ floods at mid-tide,
	= cart ramp, o entrance flat, R under a roof, ' ' open sand.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local Harness = require("./tests/harness")

-- Arguments: an optional notes folder (or -), then sources; --maps anywhere draws the maps.
local args, drawMaps = {}, false
for _, arg in process.args do
	if arg == "--maps" then
		drawMaps = true
	else
		table.insert(args, arg)
	end
end
local outDir = if args[1] and args[1] ~= "-" then args[1] else nil
drawMaps = drawMaps or outDir ~= nil
local h = Harness.new(process.cwd)
local Beach = h.require("Shared/Beach")
local Config = h.require("Shared/Config")
local Layouts = h.require("Shared/Layouts")
local Biomes = h.require("Shared/Biomes")
local Tide = h.require("Shared/Tide")

local cfg = Config.Beach.Terrain
local STEP = 4
local VIEWS = { -320, -240, -160, -80, 0, 80, 160, 240, 320 }

-- Metrics ------------------------------------------------------------------------------------

-- Hidden share of the zone's lower half, from the top edge at eye height. A target counts as
-- hidden only if no viewpoint on the top edge can see it.
local function hiddenShare(zone: number): number
	local z0, z1 = Beach.tileRange(zone)
	local eyes = {}
	for _, x in VIEWS do
		local z = z0 + 1
		table.insert(eyes, { x = x, z = z, y = Beach.groundAt(x, z) + cfg.EyeHeight })
	end
	local total, hidden = 0, 0
	for z = z0 + (z1 - z0) / 2, z1 - 2, 6 do
		for x = -340, 340, 8 do
			local ty = Beach.groundAt(x, z)
			total += 1
			local seenBy = false
			for _, e in eyes do
				local blocked = false
				local dz = z - e.z
				for s = 0.04, 0.96, 2 / math.max(dz, 1) do
					local px = e.x + (x - e.x) * s
					local pz = e.z + dz * s
					local py = e.y + (ty - e.y) * s
					if Beach.groundAt(px, pz) > py + 0.2 then
						blocked = true
						break
					end
				end
				if not blocked then
					seenBy = true
					break
				end
			end
			if not seenBy then
				hidden += 1
			end
		end
	end
	return hidden / math.max(total, 1)
end

-- Shortest route (in cells) from the zone's top row to its bottom row, with a slope limit.
local function route(zone: number, slope: number): number?
	local z0, z1 = Beach.tileRange(zone)
	local n = math.floor(Beach.HalfWidth / STEP)
	local top = math.floor(z0 / STEP)
	local bottom = math.floor(z1 / STEP)
	local dist = {}
	local queue, head = {}, 1
	local function key(ix, iz)
		return ix * 10000 + iz
	end
	for ix = -n, n do
		local x = ix * STEP
		if math.abs(x) <= Beach.HalfWidth - 4 then
			dist[key(ix, top)] = 0
			table.insert(queue, { ix, top })
		end
	end
	while head <= #queue do
		local c = queue[head]
		head += 1
		local ix, iz = c[1], c[2]
		local d = dist[key(ix, iz)]
		if iz >= bottom then
			return d
		end
		local y = Beach.groundAt(ix * STEP, iz * STEP)
		for _, step in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, nz = ix + step[1], iz + step[2]
			if math.abs(nx) <= n and nz >= top and nz <= bottom and dist[key(nx, nz)] == nil then
				local ny = Beach.groundAt(nx * STEP, nz * STEP)
				if math.abs(ny - y) <= slope * STEP then
					dist[key(nx, nz)] = d + 1
					table.insert(queue, { nx, nz })
				end
			end
		end
	end
	return nil
end

-- Shortest route from one start point on the top edge (cells), or nil.
local function routeFrom(zone: number, startX: number, slope: number): number?
	local z0, z1 = Beach.tileRange(zone)
	local n = math.floor(Beach.HalfWidth / STEP)
	local top = math.floor(z0 / STEP)
	local bottom = math.floor(z1 / STEP)
	local dist = {}
	local queue, head = {}, 1
	local function key(ix, iz)
		return ix * 10000 + iz
	end
	local sx = math.floor(startX / STEP)
	dist[key(sx, top)] = 0
	table.insert(queue, { sx, top })
	while head <= #queue do
		local c = queue[head]
		head += 1
		local ix, iz = c[1], c[2]
		local d = dist[key(ix, iz)]
		if iz >= bottom then
			return d
		end
		local y = Beach.groundAt(ix * STEP, iz * STEP)
		for _, step in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, nz = ix + step[1], iz + step[2]
			if math.abs(nx) <= n and nz >= top and nz <= bottom and dist[key(nx, nz)] == nil then
				local ny = Beach.groundAt(nx * STEP, nz * STEP)
				if math.abs(ny - y) <= slope * STEP then
					dist[key(nx, nz)] = d + 1
					table.insert(queue, { nx, nz })
				end
			end
		end
	end
	return nil
end

-- The fastest way across a tile on foot, in seconds at walking speed (20 studs a second): from
-- anywhere on its top edge to anywhere on its bottom edge, in 4-stud steps along X and Z.
local WALK_SPEED = 20
local function crossSeconds(tile: number): number?
	local z0, z1 = Beach.tileRange(tile)
	local n = math.floor(Beach.HalfWidth / STEP)
	local top = math.floor(z0 / STEP)
	local bottom = math.floor(z1 / STEP)
	local dist = {}
	local queue, head = {}, 1
	local function key(ix, iz)
		return ix * 10000 + iz
	end
	for ix = -n, n do
		dist[key(ix, top)] = 0
		table.insert(queue, { ix, top })
	end
	while head <= #queue do
		local ix, iz = queue[head][1], queue[head][2]
		head += 1
		local d = dist[key(ix, iz)]
		if iz >= bottom then
			return d * STEP / WALK_SPEED
		end
		local y = Beach.groundAt(ix * STEP, iz * STEP)
		for _, step in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, nz = ix + step[1], iz + step[2]
			if math.abs(nx) <= n and nz >= top and nz <= bottom and dist[key(nx, nz)] == nil then
				if math.abs(Beach.groundAt(nx * STEP, nz * STEP) - y) <= cfg.FootSlope * STEP then
					dist[key(nx, nz)] = d + 1
					table.insert(queue, { nx, nz })
				end
			end
		end
	end
	return nil
end

-- How many of a few start points on the top edge are shorter on foot than by cart.
local function shortcuts(zone: number): number
	local count = 0
	for _, x in { -300, -150, 0, 150, 300 } do
		local cart = routeFrom(zone, x, cfg.CartSlope) or math.huge
		local foot = routeFrom(zone, x, cfg.FootSlope) or math.huge
		if foot < cart then
			count += 1
		end
	end
	return count
end

-- Largest height above the slope, and deepest cut, inside a zone.
local function extremes(zone: number): (number, number)
	local z0, z1 = Beach.tileRange(zone)
	local high, low = 0, 0
	for z = z0, z1, 2 do
		for x = -350, 350, 2 do
			local f = Beach.feature(x, z)
			high = math.max(high, f)
			low = math.min(low, f)
		end
	end
	return high, -low
end

-- Maps -------------------------------------------------------------------------------------

local COLS, ROWS = 72, math.floor(Config.Beach.TileLength / 10)

-- The character for one cell of a zone's map, from the layout's own primitives first.
local function cellChar(layout, zone: number, x: number, lz: number, mid: number): string
	local z0 = Beach.tileRange(zone)
	for _, p in layout.Primitives do
		if p.Kind == "Flat" and p.At then
			if math.sqrt((x - p.At[1]) ^ 2 + (lz - p.At[2]) ^ 2) <= p.Radius then
				return "o"
			end
		elseif p.Kind == "Ramp" then
			local d = math.huge
			for i = 1, #p.Path - 1 do
				local a, b = p.Path[i], p.Path[i + 1]
				local dx, dz = b[1] - a[1], b[2] - a[2]
				local t = math.clamp(((x - a[1]) * dx + (lz - a[2]) * dz) / (dx * dx + dz * dz), 0, 1)
				d = math.min(d, math.sqrt((a[1] + dx * t - x) ^ 2 + (a[2] + dz * t - lz) ^ 2))
			end
			if d <= p.Width / 2 then
				return "="
			end
		end
	end
	if Layouts.roofIn(layout, x, lz) then
		return "R"
	end
	local f, rock = Beach.shapeAt(x, z0 + lz)
	if rock and f > cfg.RockMin then
		return "#"
	end
	if Beach.groundAt(x, z0 + lz) < Beach.waterY(mid) then
		return "~"
	end
	if f > 0.5 then
		return "^"
	end
	if math.abs(f) < 0.3 then
		return "."
	end
	return " "
end

local function mapOf(layout, zone: number): string
	local mid = (Tide.HighWaterline + Tide.LowWaterline) / 2
	local rows = {}
	for row = 0, ROWS - 1 do
		local line = {}
		local lz = row * 10 + 5
		for col = 0, COLS - 1 do
			local x = -360 + col * 10 + 5
			table.insert(line, cellChar(layout, zone, x, lz, mid))
		end
		table.insert(rows, table.concat(line))
	end
	return table.concat(rows, "\n")
end

-- Flood order ----------------------------------------------------------------------------

-- The ground on a grid of 2-stud cells over a zone and a little either side, with the zone's
-- layout as it is now (set it first).
local FLOOD_STEP = 2
local FLOOD_X0, FLOOD_COLS = -360, 361 -- X -360..360

-- For every cell of the grid, the lowest sea level at which the sea reaches it, flowing in
-- from the seaward edge through lower ground only (a cut walled off by higher ground stays
-- dry until the sea tops the wall): a priority flood, lowest spill first.
local function spillLevels(zone: number): ({ number }, number, number)
	local z0, z1 = Beach.tileRange(zone)
	local zStart = z0 - 40
	local rows = math.floor((z1 + 40 - zStart) / FLOOD_STEP) + 1
	local ground = {}
	for j = 0, rows - 1 do
		for i = 0, FLOOD_COLS - 1 do
			ground[j * FLOOD_COLS + i + 1] =
				Beach.groundAt(FLOOD_X0 + i * FLOOD_STEP, zStart + j * FLOOD_STEP)
		end
	end
	-- A binary heap of { level, cell }.
	local heap = {}
	local function push(level: number, cell: number)
		table.insert(heap, { level, cell })
		local k = #heap
		while k > 1 do
			local parent = k // 2
			if heap[parent][1] <= heap[k][1] then
				break
			end
			heap[parent], heap[k] = heap[k], heap[parent]
			k = parent
		end
	end
	local function pop(): { number }
		local top = heap[1]
		local last = table.remove(heap)
		if #heap > 0 then
			heap[1] = last
			local k = 1
			while true do
				local a, b, smallest = k * 2, k * 2 + 1, k
				if a <= #heap and heap[a][1] < heap[smallest][1] then
					smallest = a
				end
				if b <= #heap and heap[b][1] < heap[smallest][1] then
					smallest = b
				end
				if smallest == k then
					break
				end
				heap[smallest], heap[k] = heap[k], heap[smallest]
				k = smallest
			end
		end
		return top
	end
	local spill = {}
	for i = 0, FLOOD_COLS - 1 do
		local cell = (rows - 1) * FLOOD_COLS + i + 1
		spill[cell] = ground[cell]
		push(ground[cell], cell)
	end
	while #heap > 0 do
		local entry = pop()
		local level, cell = entry[1], entry[2]
		if level > spill[cell] then
			continue
		end
		local i, j = (cell - 1) % FLOOD_COLS, (cell - 1) // FLOOD_COLS
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local ni, nj = i + d[1], j + d[2]
			if ni >= 0 and ni < FLOOD_COLS and nj >= 0 and nj < rows then
				local n = nj * FLOOD_COLS + ni + 1
				local reach = math.max(level, ground[n])
				if spill[n] == nil or reach < spill[n] then
					spill[n] = reach
					push(reach, n)
				end
			end
		end
	end
	return spill, zStart, rows
end

-- The cuts of a zone's layout, seaward first, with the waterline at which the sea reaches each.
local function floodOrder(layout, zone: number): { string }
	local z0 = Beach.tileRange(zone)
	local spill, zStart = spillLevels(zone)
	local lines = {}
	for _, p in layout.Primitives do
		if p.Kind == "Channel" or p.Kind == "Hollow" then
			-- A channel floods from its seaward end, so test the point furthest out.
			local point = if p.Path then p.Path[1] elseif p.At then p.At else p.Area[1]
			for _, q in p.Area or {} do
				if q[2] > point[2] then
					point = q
				end
			end
			for _, q in p.Path or {} do
				if q[2] > point[2] then
					point = q
				end
			end
			local i = math.floor((point[1] - FLOOD_X0) / FLOOD_STEP + 0.5)
			local j = math.floor((z0 + point[2] - zStart) / FLOOD_STEP + 0.5)
			local level = spill[j * FLOOD_COLS + i + 1]
			-- The sea is above `level` while the waterline is below -level / Slope.
			local line = if level then math.floor(-level / Config.Beach.Slope) else nil
			local text = string.format(
				"%s at x %d, z %d: the sea reaches it when the waterline is below Z %s",
				p.Kind,
				point[1],
				point[2],
				tostring(line or "never")
			)
			table.insert(lines, { line = line or -1, text = text })
		end
	end
	table.sort(lines, function(a, b)
		return a.line > b.line
	end)
	local out = {}
	for _, entry in lines do
		table.insert(out, entry.text)
	end
	return out
end

-- Report --------------------------------------------------------------------------------------

local maps = {}
local floods = {}
local out = {}

-- A short tag for a choice, for map keys: "" for the first of everything, "/c2" for
-- crossing 2, "/s3r2" for room 2 in slot 3.
local function tagOf(choice): string
	local tag = if choice.Crossing ~= 1 then "/c" .. choice.Crossing else ""
	for index, room in choice.Rooms do
		if room ~= 1 then
			tag ..= "/s" .. index .. "r" .. room
		end
	end
	return tag
end

-- Reports one way a zone's definition comes out, on the zone's own tile (a tile is a zone).
local function report(zone: number, source: string, def, way): string
	local tile = zone
	Layouts.setActive(tile, def, nil, way.Choice)
	local layout = Layouts.active(tile)
	local hidden = hiddenShare(tile)
	local high, low = extremes(tile)
	local short = shortcuts(tile)
	local cross = crossSeconds(tile)
	local key = source .. "@" .. zone .. tagOf(way.Choice)
	-- The maps and flood orders only when they're wanted (they're the slow, long part).
	maps[key] = if drawMaps then mapOf(layout, tile) else ""
	local order = if drawMaps then floodOrder(layout, tile) else {}
	Layouts.setActive(tile, nil)
	floods[key] = table.concat(order, "\n")
	local lines = {
		string.format(
			"Zone %d %s%s [%s]: hidden from the top %d%%, highest %.1f, deepest cut %.1f, shortcut starts %d of 5",
			zone,
			source,
			if way.Label ~= "" then " " .. way.Label else "",
			key,
			math.floor(hidden * 100 + 0.5),
			high,
			low,
			short
		),
		string.format(
			"  fastest crossing on foot: about %s s (target %d s)",
			if cross then string.format("%.0f", cross) else "no way across",
			Config.Zones[zone].CrossTime
		),
	}
	for _, line in order do
		table.insert(lines, "  " .. line)
	end
	return table.concat(lines, "\n") .. (if drawMaps then "\n" .. maps[key] else "")
end

local function reportAll(zone: number, source: string, def)
	for _, way in Layouts.options(def) do
		table.insert(out, report(zone, source, def, way))
	end
end

-- Only what's asked for, when names are given: "lune run tools/layout_map.luau - Zones/Zone5".
local only = {}
for index = 2, #args do
	only[args[index]] = true
end
local function wanted(source: string): boolean
	return next(only) == nil or only[source] == true
end

for zone = 1, Config.Beach.ActiveZones do
	-- (Zones without a definition of their own use the one above them: nothing new to report.)
	local base = Layouts.base(zone)
	if base and base ~= Layouts.base(zone - 1) and wanted("Zones/Zone" .. zone) then
		reportAll(zone, "Zones/Zone" .. zone, base)
	end
	for id in Biomes.List do
		local def = Layouts.forBiome(id, zone)
		if def and (zone == 1 or def ~= Layouts.forBiome(id, zone - 1)) and wanted("Biomes/" .. id) then
			reportAll(zone, "Biomes/" .. id, def)
		end
	end
end
for id in Biomes.Planned do
	for zone = 1, Config.Beach.ActiveZones do
		local def = Layouts.forPlanned(id, zone)
		if
			def
			and (zone == 1 or def ~= Layouts.forPlanned(id, zone - 1))
			and wanted("Biomes/Planned/" .. id)
		then
			reportAll(zone, "Biomes/Planned/" .. id, def)
		end
	end
end

print(table.concat(out, "\n\n"))

if outDir then
	-- Write the maps and flood orders into the notes, between their markers.
	for _, name in fs.readDir(outDir) do
		if string.sub(name, -3) == ".md" then
			local path = outDir .. "/" .. name
			local text = fs.readFile(path)
			local updated = string.gsub(text, "<!%-%- map (%S+) %-%->.-<!%-%- /map %-%->", function(key)
				return "<!-- map "
					.. key
					.. " -->\n```text\n"
					.. (maps[key] or "missing")
					.. "\n```\n<!-- /map -->"
			end)
			updated = string.gsub(updated, "<!%-%- floods (%S+) %-%->.-<!%-%- /floods %-%->", function(key)
				return "<!-- floods " .. key .. " -->\n" .. (floods[key] or "no cuts") .. "\n<!-- /floods -->"
			end)
			fs.writeFile(path, updated)
		end
	end
end
