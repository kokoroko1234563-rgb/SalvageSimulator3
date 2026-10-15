--[[
	Draws each descent layout as an ASCII map, from the game's own ground data (Beach.groundAt),
	and prints what the layout does: how much of its lower half a player at the top edge can't
	see, whether carts and players on foot can reach the sea, how tall and deep it is, and how
	long the fastest way across takes on foot against its zone's CrossTime (Config.Zones).

	It also writes the maps into the layout notes, between the <!-- map ... --> markers, so the
	notes can't drift from the layouts.

	Usage (from the repo root): lune run tools/layout_map.luau [docs/layouts]
	Without a folder it only prints. Each map is 72 columns (10 studs each) by 15 rows (10 studs
	each), top edge first. Legend: # rock, ^ raised sand, . flat, ~ floods at mid-tide,
	= cart ramp, o entrance flat, ' ' open sand.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local Harness = require("./tests/harness")

local outDir = process.args[1]
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

local COLS, ROWS = 72, 15

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

-- The ground on a grid of 2-stud cells around a tile (from a little up the beach of it to
-- well out past it, with the tile set to `layout`), so the sea can be flowed through it.
local FLOOD_STEP = 2
local FLOOD_X0, FLOOD_COLS, FLOOD_ROWS = -360, 361, 171 -- X -360..360, Z 340 studs from FLOOD_Z0
local FLOOD_Z0 = 0

local function floodGrid(zone: number?, layout): { number }
	local grid = {}
	if zone then
		Layouts.setActive(zone, layout)
		FLOOD_Z0 = Beach.tileRange(zone) - 40
	end
	for j = 0, FLOOD_ROWS - 1 do
		for i = 0, FLOOD_COLS - 1 do
			grid[j * FLOOD_COLS + i + 1] =
				Beach.groundAt(FLOOD_X0 + i * FLOOD_STEP, FLOOD_Z0 + j * FLOOD_STEP)
		end
	end
	if zone then
		Layouts.setActive(zone, nil)
	end
	return grid
end

-- Whether the sea, at a waterline Z, flows in from the seaward edge to a point (through cells
-- below the sea surface only). A cut that is walled off by higher ground stays dry.
local function reachedBySea(grid: { number }, waterline: number, i: number, j: number): boolean
	local level = Beach.waterY(waterline)
	local seen, queue, head = {}, {}, 1
	local function at(a: number, b: number): number
		return (b * FLOOD_COLS) + a + 1
	end
	for a = 0, FLOOD_COLS - 1 do
		local k = at(a, FLOOD_ROWS - 1)
		if grid[k] < level then
			seen[k] = true
			table.insert(queue, { a, FLOOD_ROWS - 1 })
		end
	end
	local target = at(i, j)
	while head <= #queue do
		local a, b = queue[head][1], queue[head][2]
		head += 1
		if seen[target] then
			return true
		end
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local na, nb = a + d[1], b + d[2]
			if na >= 0 and na < FLOOD_COLS and nb >= 0 and nb < FLOOD_ROWS then
				local k = at(na, nb)
				if not seen[k] and grid[k] < level then
					seen[k] = true
					table.insert(queue, { na, nb })
				end
			end
		end
	end
	return seen[target] == true
end

-- The highest waterline Z at which the sea reaches a cut's floor, by bisection (reaching is
-- monotonic: a lower tide floods more). Nil if the sea never reaches it.
local function floodLine(grid: { number }, x: number, z: number): number?
	local i = math.floor((x - FLOOD_X0) / FLOOD_STEP + 0.5)
	local j = math.floor((z - FLOOD_Z0) / FLOOD_STEP + 0.5)
	local lo, hi = math.floor(FLOOD_Z0 - 300), math.floor(FLOOD_Z0 + 450)
	if not reachedBySea(grid, lo, i, j) then
		return nil
	end
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if reachedBySea(grid, mid, i, j) then
			lo = mid
		else
			hi = mid
		end
	end
	return lo
end

-- The cuts of a zone's layout, seaward first, with the waterline at which the sea reaches each.
local function floodOrder(layout, zone: number): { string }
	local z0 = Beach.tileRange(zone)
	local grid = floodGrid(zone, layout)
	local lines = {}
	for _, p in layout.Primitives do
		if p.Kind == "Channel" or p.Kind == "Hollow" then
			-- A channel floods from its seaward end, so test the point furthest out.
			local point = if p.Path then p.Path[1] else p.At
			for _, q in p.Path or {} do
				if q[2] > point[2] then
					point = q
				end
			end
			local line = floodLine(grid, point[1], z0 + point[2])
			local text = string.format(
				"%s at x %d, z %d: the sea reaches it when the waterline is below Z %s",
				p.Kind,
				point[1],
				point[2],
				tostring(line and math.floor(line) or "never")
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

-- Each zone's layouts are measured on the zone's own first tile, where the tide meets them.
local function report(zone: number, source: string, layout): string
	local tile = (zone - 1) * Config.Beach.TilesPerZone + 1
	Layouts.setActive(tile, layout)
	local hidden = hiddenShare(tile)
	local high, low = extremes(tile)
	local short = shortcuts(tile)
	local cross = crossSeconds(tile)
	Layouts.setActive(tile, nil)
	maps[source .. "@" .. zone] = mapOf(layout, tile)
	local order = floodOrder(layout, tile)
	floods[source .. "@" .. zone] = table.concat(order, "\n")
	local lines = {
		string.format(
			"Zone %d %s: hidden from the top %d%%, highest %.1f, deepest cut %.1f, shortcut starts %d of 5",
			zone,
			source,
			math.floor(hidden * 100 + 0.5),
			high,
			low,
			short
		),
		-- A zone is TilesPerZone tiles of this layout (when no biome rolls there).
		string.format(
			"  fastest crossing on foot: %s s per tile, about %s s for the zone (target %d s)",
			if cross then string.format("%.1f", cross) else "no way across",
			if cross then string.format("%.0f", cross * Config.Beach.TilesPerZone) else "-",
			Config.Zones[zone].CrossTime
		),
	}
	for _, line in order do
		table.insert(lines, "  " .. line)
	end
	return table.concat(lines, "\n") .. "\n" .. maps[source .. "@" .. zone]
end

local out = {}
for zone = 1, Config.Beach.ActiveZones do
	-- (Zones without a layout of their own use the one above them: nothing new to report.)
	local own = Layouts.all()
	local hasOwn = false
	for _, entry in own do
		if entry.Source == "Zones/Zone" .. zone then
			hasOwn = true
		end
	end
	if hasOwn then
		table.insert(out, report(zone, "Zones/Zone" .. zone, Layouts.base(zone)))
	end
	for id in Biomes.List do
		local layout = Layouts.forBiome(id, zone)
		if layout then
			table.insert(out, report(zone, "Biomes/" .. id, layout))
		end
	end
end
for id in Biomes.Planned do
	for zone = 1, Config.Beach.ActiveZones do
		local layout = Layouts.forPlanned(id, zone)
		if layout then
			table.insert(out, report(zone, "Biomes/Planned/" .. id, layout))
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
