-- Zone 5, The Shoals: flooded ground between four rock bars, drawn as one whole zone.
--
-- The frame is four bars across the beach (each with five 20-wide doors) and the Grotto, a roofed
-- tunnel in the middle lane. A crossing plugs all the doors but two on each bar: a ford for feet
-- (a cut with a sand sill, too steep for a cart) and the door the cart ramp uses, and adds its own
-- low walls and boulders in the lanes. Seven slots, against the bars between the doors, each roll a
-- walled pocket: a drowned pool, a dead-end cave, a boulder scramble, a weed-choked channel.

local BARS = { 124, 248, 372, 496 }
local DOORS = { -280, -144, 0, 144, 280 }

local function wall(x0, z0, x1, z1, height)
	return { Kind = "Wall", Path = { { x0, z0 }, { x1, z1 } }, Height = height or 14, Width = 12 }
end

local function add(into, list)
	for _, p in list do
		table.insert(into, p)
	end
end

-- A bar across the beach with a door at every x in DOORS.
local function bar(z)
	local out = {}
	local x = -362
	for _, c in DOORS do
		table.insert(out, wall(x, z, c - 14, z))
		x = c + 14
	end
	table.insert(out, wall(x, z, 362, z))
	return out
end

-- Plugs every door of every bar except the xs listed (open[i] for bar i).
local function plugs(open)
	local out = {}
	for i, z in BARS do
		for _, c in DOORS do
			if not table.find(open[i], c) then
				table.insert(out, wall(c - 14, z, c + 14, z))
			end
		end
	end
	return out
end

-- A ford: a cut through a bar's door with a sand sill across it.
local function ford(c, z)
	return {
		{ Kind = "Channel", Path = { { c, z - 22 }, { c, z + 22 } }, Depth = 4, Width = 12 },
		{ Kind = "Ridge", Path = { { c - 4, z }, { c + 4, z } }, Height = 5, Width = 16 },
	}
end

local function mound(x, z, r, h, rock)
	return { Kind = "Mound", At = { x, z }, Radius = r, Height = h, Rock = rock }
end

-- Slots (their corners; each is 100 x 64) and the cart ramp's router -----------------------------

local SLOT_AT = {
	{ -260, 56 },
	{ 160, 128 },
	{ -120, 128 },
	{ 160, 252 },
	{ -260, 376 },
	{ 20, 376 },
	{ -120, 500 },
}

-- What a cart ramp keeps 15 studs clear of: the Grotto and every slot.
local OBSTACLES = { { -62, 62, 282, 338 } }
for _, at in SLOT_AT do
	table.insert(OBSTACLES, { at[1], at[1] + 100, at[2], at[2] + 64 })
end

local function clearOf(a, b)
	local len = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
	for i = 0, math.ceil(len / 6) do
		local t = i / math.max(math.ceil(len / 6), 1)
		local x = a[1] + (b[1] - a[1]) * t
		local z = a[2] + (b[2] - a[2]) * t
		for _, r in OBSTACLES do
			local dx = math.max(r[1] - x, 0, x - r[2])
			local dz = math.max(r[3] - z, 0, z - r[4])
			if dx * dx + dz * dz < 15 * 15 then
				return false
			end
		end
	end
	return true
end

local function length(pts)
	local n = 0
	for i = 2, #pts do
		n += math.sqrt((pts[i][1] - pts[i - 1][1]) ^ 2 + (pts[i][2] - pts[i - 1][2]) ^ 2)
	end
	return n
end

-- The waypoints that carry a ramp from a to b across a lane (z from zlo to zhi) clear of the
-- Grotto and the slots: none if the straight line does, else the shortest one or two bends.
local function leg(a, b, zlo, zhi)
	if clearOf(a, b) then
		return {}
	end
	local best, bestLen = nil, math.huge
	for zm = zlo, zhi, 8 do
		for xm = -340, 340, 10 do
			local w = { xm, zm }
			if clearOf(a, w) and clearOf(w, b) then
				local n = length({ a, w, b })
				if n < bestLen then
					best, bestLen = { w }, n
				end
			end
		end
	end
	if best then
		return best
	end
	for z1 = zlo, zhi, 12 do
		for x1 = -340, 340, 20 do
			local w1 = { x1, z1 }
			if clearOf(a, w1) then
				for z2 = zlo, zhi, 12 do
					for x2 = -340, 340, 20 do
						local w2 = { x2, z2 }
						if clearOf(w1, w2) and clearOf(w2, b) then
							local n = length({ a, w1, w2, b })
							if n < bestLen then
								best, bestLen = { w1, w2 }, n
							end
						end
					end
				end
			end
		end
	end
	assert(best, `no ramp route across a lane: {a[1]},{a[2]} to {b[1]},{b[2]}`)
	return best
end

-- A crossing: the ford door and the ramp door of each bar, and its own lane furniture.
-- A reef across a lane with two gaps: one for feet at g and one wide enough for the cart ramp at r.
local function baffle(z, g, r)
	local gaps = { { g - 14, g + 14 }, { r - 30, r + 30 } }
	table.sort(gaps, function(p, q)
		return p[1] < q[1]
	end)
	local out = {}
	local x = -362
	for _, gap in gaps do
		if gap[1] > x then
			table.insert(out, wall(x, z, gap[1], z))
		end
		x = math.max(x, gap[2])
	end
	table.insert(out, wall(x, z, 362, z))
	return out
end

local function crossing(name, fords, rampXs, gaps, loot)
	local open = {}
	for i = 1, 4 do
		open[i] = { fords[i], rampXs[i] }
	end
	local out = plugs(open)
	for i, z in BARS do
		if fords[i] ~= rampXs[i] then
			add(out, ford(fords[i], z))
		end
	end
	-- The wet approach to each ford: a shallow cut that floods before the open ground.
	for i, z in BARS do
		table.insert(
			out,
			{ Kind = "Channel", Path = { { fords[i], z - 44 }, { fords[i], z + 44 } }, Depth = 2, Width = 16 }
		)
	end
	local path = { { rampXs[1], 0 } }
	for i, z in BARS do
		table.insert(path, { rampXs[i], z - 24 })
		table.insert(path, { rampXs[i], z + 24 })
		if BARS[i + 1] then
			for _, w in
				leg({ rampXs[i], z + 24 }, { rampXs[i + 1], BARS[i + 1] - 24 }, z + 30, BARS[i + 1] - 30)
			do
				table.insert(path, w)
			end
		end
	end
	table.insert(path, { rampXs[4], 608 })
	table.insert(out, { Kind = "Ramp", Path = path, Width = 16 })
	-- A low reef across the top lane and another across the bottom lane, each with a gap off the
	-- ford, so the first and last stretch wind.
	add(out, baffle(36, gaps[1], rampXs[1]))
	add(out, baffle(584, gaps[2], rampXs[4]))
	return { Name = name, Primitives = out, Loot = loot or {} }
end

-- Rooms --------------------------------------------------------------------------------------
-- Slots are 100 x 64. A room is drawn with its bar along the top (z = 2) and its door in the far
-- wall (x 42 to 58); slots that sit above a bar are flipped.

local W, D = 100, 64

local function shell()
	return {
		wall(8, 2, 8, 62),
		wall(92, 2, 92, 62),
		wall(14, 56, 42, 56),
		wall(58, 56, 86, 56),
	}
end

local function room(name, extra, loot)
	local prims = shell()
	add(prims, extra)
	return { Name = name, Primitives = prims, Loot = loot }
end

local function flip(r)
	local function f(p)
		return { p[1], D - p[2] }
	end
	local prims = {}
	for _, p in r.Primitives do
		local q = table.clone(p)
		if q.Path then
			q.Path = table.create(#p.Path)
			for i, pt in p.Path do
				q.Path[i] = f(pt)
			end
		end
		if q.At then
			q.At = f(p.At)
		end
		table.insert(prims, q)
	end
	local loot = {}
	for _, l in r.Loot or {} do
		local q = table.clone(l)
		q.At = f(l.At)
		table.insert(loot, q)
	end
	return { Name = r.Name, Primitives = prims, Loot = loot }
end

local function pool()
	return room("Drowned pool", {
		{ Kind = "Hollow", At = { 50, 26 }, Radius = 18, Depth = 4 },
		mound(22, 12, 8, 4, true),
		mound(78, 12, 8, 4, true),
	}, {
		{ At = { 50, 26 }, Radius = 6, Weight = 3 },
		{ At = { 24, 38 }, Radius = 5, Weight = 1 },
		{ At = { 78, 38 }, Radius = 5, Weight = 1 },
	})
end

local function cave()
	return room("Dead-end cave", {
		wall(14, 28, 62, 28),
		{ Kind = "Roof", Path = { { 14, 42 }, { 86, 42 } }, Width = 28, Clearance = 10, Thickness = 6 },
	}, {
		{ At = { 50, 12 }, Radius = 6, Weight = 4 },
		{ At = { 76, 12 }, Radius = 5, Weight = 3 },
		{ At = { 76, 42 }, Radius = 5, Weight = 1 },
	})
end

local function scramble()
	return room("Boulder scramble", {
		mound(30, 22, 10, 7, true),
		mound(54, 40, 9, 7, true),
		mound(72, 18, 10, 7, true),
		mound(40, 8, 7, 5, true),
	}, {
		{ At = { 52, 14 }, Radius = 5, Weight = 3 },
		{ At = { 22, 42 }, Radius = 5, Weight = 1 },
		{ At = { 78, 44 }, Radius = 5, Weight = 2 },
	})
end

local function weeds()
	return room("Weed-choked channel", {
		{ Kind = "Channel", Path = { { 14, 26 }, { 86, 26 } }, Depth = 3, Width = 16 },
		mound(34, 26, 8, 3, false),
		mound(62, 26, 8, 3, false),
	}, {
		{ At = { 22, 26 }, Radius = 5, Weight = 2 },
		{ At = { 78, 26 }, Radius = 5, Weight = 2 },
		{ At = { 50, 8 }, Radius = 5, Weight = 3 },
	})
end

local function slot(name, x, z, flipped, makers)
	local rooms = {}
	for _, m in makers do
		local r = m()
		table.insert(rooms, if flipped then flip(r) else r)
	end
	return { Name = name, At = { x, z }, Size = { W, D }, Rooms = rooms }
end

-- Frame --------------------------------------------------------------------------------------

local frame = {}
for _, z in BARS do
	add(frame, bar(z))
end
-- The Grotto: a roofed tunnel across the middle lane, 32 wide inside.
add(frame, {
	wall(-62, 288, 62, 288),
	wall(-62, 332, 62, 332),
	{ Kind = "Roof", Path = { { -62, 310 }, { 62, 310 } }, Width = 44, Clearance = 10, Thickness = 6 },
})
-- Boulders in the lanes.
add(frame, {
	mound(-200, 190, 10, 7, true),
	mound(200, 440, 10, 7, true),
	mound(-300, 440, 10, 7, true),
	mound(300, 190, 10, 7, true),
	mound(-200, 550, 9, 6, true),
	mound(200, 70, 9, 6, true),
})

return {
	Name = "The Shoals",
	Primitives = frame,
	Loot = {
		{ At = { 0, 310 }, Radius = 6, Weight = 3 },
		{ At = { -320, 310 }, Radius = 6, Weight = 1 },
		{ At = { 320, 310 }, Radius = 6, Weight = 1 },
		{ At = { -210, 40 }, Radius = 6, Weight = 1 },
	},
	Crossings = {
		crossing("Zigzag fords", { -144, 280, -144, 0 }, { -280, 144, 280, -280 }, { -32, 112 }),
		crossing("West bank", { -280, 280, -280, 0 }, { -144, 144, 280, -280 }, { -168, -112 }),
		crossing("Crossover", { 0, 280, -280, 144 }, { 280, -280, -144, 280 }, { 104, 32 }),
		crossing("East bank", { 280, -280, 280, 0 }, { 144, -144, -280, 280 }, { 168, -112 }),
		crossing("Grotto way", { 0, -280, 280, -144 }, { -280, 280, 144, -280 }, { -104, -32 }),
	},
	Slots = {
		slot("Weed cove", -260, 56, true, { pool, cave, weeds }),
		slot("Eastern shelf", 160, 128, false, { scramble, pool, cave }),
		slot("Reef cave", -120, 128, false, { cave, scramble, pool }),
		slot("Drowned yard", 160, 252, false, { weeds, pool, scramble }),
		slot("Western hollow", -260, 376, false, { pool, weeds, cave }),
		slot("Stack gallery", 20, 376, false, { scramble, cave, weeds }),
		slot("Outer cove", -120, 500, false, { cave, pool, scramble, weeds }),
	},
}
