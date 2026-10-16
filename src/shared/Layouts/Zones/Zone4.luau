-- Zone 4, Outer Shore: one 720 x 608 piece. Three long rock bars run right across the beach
-- (z 146, 294 and 442) with side pockets walled off at x = -246 and 246. Each tide one of five
-- crossings opens its own doors through the bars and builds its own galleries, spurs and
-- boulder lines between them.

local function wallX(z, x1, x2, height, width)
	return { Kind = "Wall", Path = { { x1, z }, { x2, z } }, Height = height, Width = width or 16 }
end

local function wallZ(x, z1, z2, height, width)
	return { Kind = "Wall", Path = { { x, z1 }, { x, z2 } }, Height = height, Width = width or 16 }
end

local function boulder(x, z, radius, height)
	return { Kind = "Mound", At = { x, z }, Radius = radius, Height = height, Rock = true }
end

local function ramp(path)
	return { Kind = "Ramp", Path = path, Width = 16 }
end

-- A low bank the cart can't climb but a player can scramble over.
local function scramble(path)
	return { Kind = "Ridge", Path = path, Height = 5, Width = 20 }
end

local function roofPath(x1, z1, x2, z2, width)
	return {
		Kind = "Roof",
		Path = { { x1, z1 }, { x2, z2 } },
		Width = width,
		Clearance = 12,
		Thickness = 6,
	}
end

local function hollow(x, z, radius, depth)
	return { Kind = "Hollow", At = { x, z }, Radius = radius, Depth = depth }
end

-- The Arch: a roofed passage through the middle bar at x 2. Every crossing but one plugs it.
local function archPlug()
	return wallX(294, -14, 18, 22)
end

local frame = {
	Name = "Outer Shore",
	Primitives = {
		wallX(146, -360, 360, 20),
		wallX(294, -360, -22, 22),
		wallX(294, 26, 360, 22),
		wallX(442, -360, 360, 20),
		-- The Arch.
		wallZ(-22, 262, 326, 22),
		wallZ(26, 262, 326, 22),
		roofPath(2, 272, 2, 316, 56),
		-- Two pools in the last lane, the first to flood.
		hollow(140, 585, 14, 3),
		hollow(-150, 575, 14, 3),
		-- The side walls: the pockets' outer edge, each with a door onto the lane.
		wallZ(-246, 146, 206, 20),
		wallZ(-246, 234, 294, 20),
		wallZ(-246, 294, 354, 20),
		wallZ(-246, 382, 442, 20),
		wallZ(-246, 442, 514, 20),
		wallZ(-246, 542, 606, 20),
		wallZ(246, 146, 206, 20),
		wallZ(246, 234, 294, 20),
		wallZ(246, 294, 354, 20),
		wallZ(246, 382, 442, 20),
		wallZ(246, 442, 514, 20),
		wallZ(246, 542, 606, 20),
	},
	Loot = {
		{ At = { 2, 272 }, Radius = 5, Weight = 2 },
		{ At = { 2, 316 }, Radius = 5, Weight = 2 },
		{ At = { -300, 100 }, Radius = 6, Weight = 1 },
		{ At = { 300, 100 }, Radius = 6, Weight = 1 },
	},
	Entrances = { { 0, 100 } },
}

-- Side rooms ---------------------------------------------------------------------------------
-- Drawn for a west pocket (its door on the east edge, x = w); the east pockets are mirrored.
-- Wall positions sit on the 4-stud grid so they land on 4k+2 in the zone.

local W = 96

local function spot(x, z, weight)
	return { At = { x, z }, Radius = 5, Weight = weight }
end

local function mirror(room)
	local function flip(point)
		return { W - point[1], point[2] }
	end
	local out = { Name = room.Name, Primitives = {}, Loot = {} }
	for _, p in room.Primitives do
		local q = table.clone(p)
		if p.At then
			q.At = flip(p.At)
		end
		if p.Path then
			q.Path = {}
			for _, point in p.Path do
				table.insert(q.Path, flip(point))
			end
		end
		table.insert(out.Primitives, q)
	end
	for _, l in room.Loot do
		local q = table.clone(l)
		q.At = flip(l.At)
		table.insert(out.Loot, q)
	end
	return out
end

-- cz: the door's row (a multiple of 4), d: the pocket's depth.
local function cove(cz, d)
	return {
		Name = "Sheltered cove",
		Primitives = {
			wallX(cz - 28, 24, 72, 16),
			wallX(cz + 28, 24, 72, 16),
			boulder(14, cz - 30, 8, 5),
			boulder(14, cz + 30, 8, 5),
			hollow(14, cz, 10, 2),
		},
		Loot = { spot(12, cz, 4), spot(46, cz - 8, 2), spot(84, 14, 1) },
	}
end

local function scrambleRoom(cz, d)
	return {
		Name = "Boulder scramble",
		Primitives = {
			boulder(30, cz - 26, 10, 6),
			boulder(56, cz - 22, 10, 6),
			boulder(24, cz + 22, 10, 6),
			boulder(54, cz + 26, 10, 6),
			boulder(76, cz, 9, 6),
			boulder(12, cz - 8, 8, 5),
		},
		Loot = { spot(40, cz, 4), spot(12, cz + 8, 3), spot(80, d - 14, 1) },
	}
end

local function seaCave(cz, d)
	return {
		Name = "Sea cave",
		Primitives = {
			wallX(cz - 24, 12, 68, 20),
			wallX(cz + 24, 12, 68, 20),
			wallZ(8, cz - 24, cz + 24, 20),
			roofPath(16, cz, 60, cz, 60),
			hollow(30, cz, 12, 3),
		},
		Loot = { spot(24, cz, 5), spot(50, cz, 3), spot(84, d - 12, 1) },
	}
end

local function floodedPocket(cz, d)
	return {
		Name = "Flooded pocket",
		Primitives = {
			hollow(44, cz, 24, 3),
			boulder(80, cz - 40, 8, 5),
			boulder(80, cz + 40, 8, 5),
			boulder(10, 16, 8, 5),
		},
		Loot = { spot(44, cz, 4), spot(14, cz + 20, 2), spot(14, 14, 1) },
	}
end

local function switchback(cz, d)
	return {
		Name = "Switchback cove",
		Primitives = {
			wallZ(32, 8, d - 40, 18),
			wallZ(64, 40, d - 8, 18),
		},
		Loot = { spot(12, d - 16, 5), spot(48, d - 20, 2), spot(48, 20, 1) },
	}
end

local function slot(name, x, z, d, cz, east, builders)
	local rooms = {}
	for _, build in builders do
		local room = build(cz, d)
		table.insert(rooms, if east then mirror(room) else room)
	end
	return { Name = name, At = { x, z }, Size = { W, d }, Rooms = rooms }
end

local slots = {
	slot("West lagoon", -350, 158, 124, 60, false, { cove, switchback, floodedPocket }),
	slot("East lagoon", 254, 158, 124, 60, true, { scrambleRoom, seaCave, cove }),
	slot("West caves", -350, 306, 124, 60, false, { seaCave, scrambleRoom, switchback }),
	slot("East caves", 254, 306, 124, 60, true, { floodedPocket, cove, switchback }),
	slot("West reef", -350, 458, 140, 68, false, { switchback, seaCave, scrambleRoom, floodedPocket }),
	slot("East reef", 254, 458, 140, 68, true, { seaCave, cove, scrambleRoom }),
}

local crossings = {
	{
		Name = "West gallery",
		Primitives = {
			archPlug(),
			-- Top lane: the cart loops east round the end of a bank the player scrambles over.
			scramble({ { -360, 70 }, { 100, 70 } }),
			-- A roofed gallery along the lane.
			wallX(186, -190, 10, 20),
			wallX(222, -190, 10, 20),
			roofPath(-170, 204, -10, 204, 36),
			-- A chicane: down one side of a spur, back up the other.
			wallZ(-46, 302, 374, 20),
			wallZ(-94, 346, 442, 20),
			ramp({
				{ 130, 0 },
				{ 130, 100 },
				{ -210, 104 },
				{ -210, 150 },
				{ -210, 262 },
				{ 100, 262 },
				{ 100, 294 },
				{ 100, 410 },
				{ -70, 410 },
				{ -70, 318 },
				{ -130, 318 },
				{ -130, 420 },
				{ -150, 442 },
				{ -150, 520 },
				{ -20, 560 },
				{ -20, 608 },
			}),
		},
		Loot = {
			{ At = { -90, 204 }, Radius = 5, Weight = 2 },
			{ At = { -70, 366 }, Radius = 5, Weight = 2 },
		},
	},
	{
		Name = "East boulder run",
		Primitives = {
			archPlug(),
			scramble({ { -100, 60 }, { 200, 60 } }),
			boulder(140, 236, 12, 8),
			boulder(110, 262, 10, 7),
			boulder(130, 172, 9, 7),
			-- A chicane that sends the way back up the corridor between two spurs.
			wallZ(70, 302, 382, 20),
			wallZ(134, 346, 442, 20),
			ramp({
				{ -130, 0 },
				{ -130, 104 },
				{ 200, 108 },
				{ 200, 146 },
				{ 200, 200 },
				{ 60, 200 },
				{ 60, 256 },
				{ -120, 256 },
				{ -120, 294 },
				{ -120, 330 },
				{ -10, 412 },
				{ 102, 412 },
				{ 102, 318 },
				{ 170, 318 },
				{ 170, 442 },
				{ 170, 520 },
				{ 60, 560 },
				{ 60, 608 },
			}),
		},
		Loot = {
			{ At = { 126, 222 }, Radius = 5, Weight = 2 },
			{ At = { 102, 372 }, Radius = 5, Weight = 2 },
		},
	},
	{
		Name = "Spine walk",
		Primitives = {
			archPlug(),
			scramble({ { -360, 40 }, { -120, 40 }, { -60, 90 }, { 100, 90 } }),
			-- Two spurs that make the way wind back up between them.
			wallZ(-166, 154, 250, 22),
			wallZ(-102, 190, 294, 22),
			wallZ(110, 398, 442, 20),
			-- A short roofed corridor in the last lane.
			wallZ(166, 462, 546, 20),
			wallZ(214, 462, 546, 20),
			roofPath(190, 490, 190, 540, 52),
			ramp({
				{ 110, 0 },
				{ 110, 112 },
				{ -205, 112 },
				{ -205, 146 },
				{ -205, 270 },
				{ -134, 270 },
				{ -134, 170 },
				{ -60, 170 },
				{ -60, 294 },
				{ -60, 362 },
				{ 180, 362 },
				{ 190, 420 },
				{ 190, 442 },
				{ 190, 606 },
			}),
		},
		Loot = {
			{ At = { -134, 220 }, Radius = 5, Weight = 2 },
			{ At = { 190, 515 }, Radius = 5, Weight = 3 },
		},
	},
	{
		Name = "Arch road",
		Primitives = {
			scramble({ { -60, 60 }, { 200, 60 } }),
			hollow(110, 220, 16, 3),
			hollow(60, 200, 12, 3),
			boulder(150, 180, 10, 7),
			-- Past the Arch, a chicane westward.
			wallZ(-62, 302, 386, 20),
			wallZ(-126, 338, 442, 20),
			ramp({
				{ -120, 0 },
				{ -120, 104 },
				{ 200, 108 },
				{ 200, 146 },
				{ 200, 200 },
				{ 2, 230 },
				{ 2, 414 },
				{ -94, 414 },
				{ -94, 316 },
				{ -170, 316 },
				{ -170, 420 },
				{ -200, 442 },
				{ -200, 520 },
				{ -100, 560 },
				{ -100, 608 },
			}),
		},
		Loot = {
			{ At = { 100, 214 }, Radius = 5, Weight = 2 },
			{ At = { -94, 366 }, Radius = 5, Weight = 2 },
		},
	},
	{
		Name = "Cave road",
		Primitives = {
			archPlug(),
			scramble({ { -360, 60 }, { 100, 60 } }),
			-- A chicane westward, then a roofed cave chamber.
			wallZ(-46, 154, 250, 22),
			wallZ(-110, 190, 294, 22),
			hollow(-150, 250, 14, 3),
			wallZ(-138, 338, 386, 20),
			wallZ(-62, 338, 386, 20),
			roofPath(-100, 350, -100, 374, 76),
			ramp({
				{ 150, 0 },
				{ 150, 100 },
				{ 0, 104 },
				{ 0, 146 },
				{ 0, 270 },
				{ -78, 270 },
				{ -78, 170 },
				{ -160, 170 },
				{ -200, 294 },
				{ -200, 330 },
				{ -100, 330 },
				{ -100, 400 },
				{ -40, 414 },
				{ 60, 414 },
				{ 60, 442 },
				{ 60, 520 },
				{ 60, 608 },
			}),
		},
		Loot = {
			{ At = { -78, 220 }, Radius = 5, Weight = 2 },
			{ At = { -100, 362 }, Radius = 5, Weight = 3 },
		},
	},
}

return {
	Name = "Outer Shore",
	Primitives = frame.Primitives,
	Loot = frame.Loot,
	Entrances = frame.Entrances,
	Crossings = crossings,
	Slots = slots,
}
