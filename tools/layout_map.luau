--[[
	Draws each descent layout as an ASCII map, from the game's own ground data (Beach.groundAt),
	and prints what the layout does: how much of its lower half a player at the top edge can't
	see, whether carts and players on foot can reach the sea, and how tall and deep it is.

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
	local z0, z1 = Beach.zoneRange(zone)
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
	local z0, z1 = Beach.zoneRange(zone)
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
	local z0, z1 = Beach.zoneRange(zone)
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
	local z0, z1 = Beach.zoneRange(zone)
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
	local z0 = Beach.zoneRange(zone)
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

-- The waterline Z at which each cut floods, as the tide comes in: a cut floods once the sea
-- reaches its floor, which is Depth below the slope, so the waterline must fall to Z + Depth / slope.
local function floodOrder(layout, zone: number): { string }
	local z0 = Beach.zoneRange(zone)
	local lines = {}
	for index, p in layout.Primitives do
		if p.Kind == "Channel" or p.Kind == "Hollow" then
			-- A channel floods from its seaward end, so use the point furthest out.
			local point = if p.Path then p.Path[1] else p.At
			for _, q in p.Path or {} do
				if q[2] > point[2] then
					point = q
				end
			end
			local floods = z0 + point[2] + p.Depth / Config.Beach.Slope
			table.insert(lines, {
				floods = floods,
				text = string.format(
					"%s at x %d, z %d floods when the waterline is below Z %d",
					p.Kind,
					point[1],
					point[2],
					floods
				),
			})
		end
	end
	table.sort(lines, function(a, b)
		return a.floods > b.floods
	end)
	local out = {}
	for _, line in lines do
		table.insert(out, line.text)
	end
	return out
end

-- Report --------------------------------------------------------------------------------------

local maps = {}
local floods = {}

local function report(zone: number, source: string, layout): string
	Layouts.setActive(zone, layout)
	local hidden = hiddenShare(zone)
	local high, low = extremes(zone)
	local short = shortcuts(zone)
	Layouts.setActive(zone, nil)
	maps[source .. "@" .. zone] = mapOf(layout, zone)
	floods[source .. "@" .. zone] = table.concat(floodOrder(layout, zone), "\n")
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
	}
	for _, line in floodOrder(layout, zone) do
		table.insert(lines, "  " .. line)
	end
	return table.concat(lines, "\n") .. "\n" .. maps[source .. "@" .. zone]
end

local out = {}
for zone = 1, Config.Beach.ActiveZones do
	table.insert(out, report(zone, "Zones/Zone" .. zone, Layouts.base(zone)))
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
