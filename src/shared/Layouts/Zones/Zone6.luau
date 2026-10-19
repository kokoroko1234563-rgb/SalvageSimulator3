-- Zone 6, The Drowned Reach: the deepest, slowest ground on the beach, drawn as one 720 x 608
-- piece. A maze of tall rock walls on a 40-stud grid (28-wide lanes between walls 12 wide and
-- 24 high), cut into nine wards by four long walls with gates, and walled across its top and
-- bottom edges. The frame is always there: the long walls and their gate candidates, the shells
-- of seven side rooms, the roofed galleries round the two halls. Each tide one of five
-- crossings is rolled: it shuts the gates it doesn't want, draws every other wall of the maze
-- (a tree, so there is one way through, and dead ends everywhere), roofs some of its straights,
-- digs some low lanes and pools, and winds a cart ramp along the way through. A few doorways
-- are choked with rubble instead of walled: players scramble over them to cut a bend, carts
-- can't. Each side room's pick fills its shell. See docs/layouts/Zone6.md.
--
-- The mazes are drawn as pictures (see `maze`): '+' is a grid node, '--' a wall between two
-- lanes, '==' or '!' rubble, and a blank an opening. Row by row, a line of nodes, then a line
-- of cells.

local PITCH = 40 -- grid: lane centres 40 apart
local X0, Z0 = -360, 12 -- the first node of the picture, in zone coordinates

-- A rock wall; its edges are worn by `rough` studs (the Test Range tolerates 1, and only on the walls that run across: more draws the
-- walls too thin and the terrain strays from the layout). Posts stay square.
local function wall(path, rough)
	return { Kind = "Wall", Path = path, Height = 24, Width = 12, Rough = rough }
end

-- A pile of rubble filling a doorway: a scramble on foot, too steep for a cart.
local function rubble(path)
	return { Kind = "Ridge", Path = path, Height = 4, Width = 20, Rough = 3 }
end

-- Rock overhead along a lane: a marker, turned into exact rectangles by `fit` once the walls
-- are known (see below). `path` runs through the centres of the lane cells it covers.
local function roof(path)
	return { Kind = "RoofRun", Path = path }
end

-- A pool: low ground that holds the sea from early in the flood.
local function pool(x, z, radius)
	return { Kind = "Hollow", At = { x, z }, Radius = radius or 12, Depth = 3, Material = "Mud", Rough = 3 }
end

-- A sunk lane: floods before the ground round it.
local function lane(path)
	return { Kind = "Channel", Path = path, Depth = 2, Width = 12, Material = "Mud" }
end

-- Rock over one lane cell of a side room (a marker, like `roof`).
local function cellRoof(x, z)
	return { Kind = "RoofRun", Path = { { x, z } } }
end

-- A boulder.
local function boulder(x, z, radius, height)
	return { Kind = "Mound", At = { x, z }, Radius = radius, Height = height, Rock = true, Rough = 3 }
end

-- A freestanding column of rock on a grid node.
local function post(x, z)
	return wall({ { x, z } })
end

-- Mud or weed over the ground in an area (the ground's material only).
local function mud(area)
	return { Kind = "Paint", Area = area, Material = "Mud" }
end

local function weed(area)
	return { Kind = "Paint", Area = area, Material = "Rock" }
end

-- One prop, and a rectangle of them.
local function prop(kind, x, z, scale, yaw)
	return { Kind = kind, At = { x, z }, Scale = scale, Yaw = yaw }
end

local function scatter(kind, x0, z0, x1, z1, count, scale)
	return {
		Kind = kind,
		Area = { { x0, z0 }, { x1, z0 }, { x1, z1 }, { x0, z1 } },
		Count = count,
		Scale = scale,
	}
end

local function loot(x, z, weight)
	return { At = { x, z }, Radius = 6, Weight = weight }
end

-- Joins lists of shapes into one.
local function merge(...)
	local all = {}
	for _, list in { ... } do
		for _, item in list do
			table.insert(all, item)
		end
	end
	return all
end

-- Turns a maze picture into walls and rubble. The picture's top left node is at (x0, z0).
-- Walls run between nodes (with a point on each node on the way) and stop 2 studs short of the
-- ends; a post stands on every node a wall touches, 12 across, so the walls run 4 studs into it
-- and no crack opens where two meet end to end, even with their edges worn (Rough). On the picture's left and right edges the posts also close
-- the walls against the cliffs (the ground past the beach's sides carries on as it is at
-- x = +-360, so a wall must be full height there). `edgeL` and `edgeR` say the picture's left
-- or right edge is the beach's side: the walls that reach it run right out to it, which also
-- stretches their invisible barriers on to the cliffs.
local function maze(art, x0, z0, edgeL, edgeR)
	local list = {}
	local h = (#art - 1) // 2
	local _, nodes = string.gsub(art[1], "%+", "")
	local w = nodes - 1
	local posts = {}
	local function post(i, j)
		local key = i * 1000 + j
		if not posts[key] then
			posts[key] = true
			table.insert(list, wall({ { x0 + PITCH * i, z0 + PITCH * j } }, nil))
		end
	end
	local function add(char, path)
		table.insert(
			list,
			if char == "-" or char == "|" then wall(path, if char == "-" then 1 else nil) else rubble(path)
		)
	end
	for j = 0, h do
		local line = art[2 * j + 1]
		local z = z0 + PITCH * j
		local c = 0
		while c < w do
			local char = string.sub(line, 3 * c + 2, 3 * c + 2)
			if char == "-" or char == "=" then
				local last = c
				while last + 1 < w and string.sub(line, 3 * (last + 1) + 2, 3 * (last + 1) + 2) == char do
					last += 1
				end
				local path = { { x0 + PITCH * c + (if c == 0 and edgeL then 0 else 2), z } }
				for i = c + 1, last do
					table.insert(path, { x0 + PITCH * i, z })
				end
				table.insert(
					path,
					{ x0 + PITCH * (last + 1) - (if last + 1 == w and edgeR then 0 else 2), z }
				)
				add(char, path)
				if char == "-" then
					for i = c, last + 1 do
						post(i, j)
					end
				end
				c = last + 1
			else
				c += 1
			end
		end
	end
	for i = 0, w do
		local x = x0 + PITCH * i
		local r = 0
		while r < h do
			local char = string.sub(art[2 * r + 2], 3 * i + 1, 3 * i + 1)
			if char == "|" or char == "!" then
				local last = r
				while last + 1 < h and string.sub(art[2 * (last + 1) + 2], 3 * i + 1, 3 * i + 1) == char do
					last += 1
				end
				local path = { { x, z0 + PITCH * r + 2 } }
				for j = r + 1, last do
					table.insert(path, { x, z0 + PITCH * j })
				end
				table.insert(path, { x, z0 + PITCH * (last + 1) - 2 })
				add(char, path)
				if char == "|" then
					for j = r, last + 1 do
						post(i, j)
					end
				end
				r = last + 1
			else
				r += 1
			end
		end
	end
	return list
end

-- A side room: its picture's walls and its shapes, in slot coordinates.
local function makeRoom(edgeL, edgeR, room)
	room.Primitives = merge(maze(room.Art, 0, 0, edgeL, edgeR), room.Shapes)
	room.Shapes = nil
	return room
end

local FRAME = {
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"                  |                 |                  ",
	"+--+--+--+  +  +  +  +  +--+--+--+  +  +  +  +  +  +  +",
	"         |              |        |  |                  ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"                  |              |                     ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"         |        |     |        |  |                  ",
	"+--+--+--+  +  +  +  +  +--+--+--+  +  +  +  +  +  +  +",
	"                                    |                  ",
	"+--+  +--+--+  +--+  +--+--+--+--+  +--+  +--+--+--+--+",
	"                  |  |           |           |         ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"                  |  |           |  |                  ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"                     |           |  |        |         ",
	"+  +  +  +  +  +  +  +--+  +--+--+  +  +  +  +--+--+--+",
	"                  |                                    ",
	"+--+--+--+  +--+  +  +--+--+  +--+  +  +--+--+  +--+--+",
	"         |        |                 |                  ",
	"+  +  +  +  +  +  +  +--+--+  +--+  +  +  +  +--+  +--+",
	"                     |           |  |        |         ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"         |        |  |           |           |         ",
	"+--+--+--+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"                     |           |  |        |         ",
	"+  +  +  +  +  +  +  +--+--+--+--+  +  +  +  +--+--+--+",
	"                  |                                    ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
}

local frame = {
	Name = "The Drowned Reach",
	Primitives = merge(maze(FRAME, X0, Z0, true, true), {
		roof({ { -100, 232 }, { -100, 352 }, { 100, 352 }, { 100, 232 } }),
		roof({ { -100, 392 }, { -100, 552 }, { 100, 552 }, { 100, 392 } }),
		pool(-60, 352),
		pool(60, 352),
		pool(-100, 272),
		pool(100, 272),
		pool(-60, 552),
		pool(60, 552),
		pool(-100, 472),
		pool(100, 472),
	}),
	Loot = {
		loot(-340, 32, 1),
		loot(-340, 192, 1),
	},
}

local CROSSING1 = {
	"+--+--+  +--+  +--+--+--+  +--+--+--+  +  +--+--+--+--+",
	"            |              |           |  |     |      ",
	"+  +  +  +--+--+  +  +--+  +  +  +  +--+--+  +  +  +  +",
	"               |  |  |                       |     |   ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +--+--+--+--+--+  +",
	"            |  |     |                                 ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +--+--+--+--+--+  +",
	"                                             |         ",
	"+  +  +  +  +--+  +--+--+  +  +  +  +  +--+--+  +--+--+",
	"            |     |                                    ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"   |  |     |                       |  |               ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +--+  +  +  +  +",
	"      !  |  |                                          ",
	"+--+  +  +  +  +--+  +  +  +  +  +  +  +--+--+  +  +  +",
	"      !  |  |  |                          |            ",
	"+  +--+  +  +  +  +--+  +  +  +  +  +--+  +  +  +  +  +",
	"         |  !  |                 |  |     |            ",
	"+  +  +  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +  +",
	"            |                                          ",
	"+  +  +  +  +  +--+  +  +  +  +  +--+--+--+  +  +  +  +",
	"               |  |                    |               ",
	"+  +  +  +--+--+  +  +  +  +  +  +  +  +  +--+  +  +  +",
	"               |                       |               ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +  +",
	"      |     |                                          ",
	"+  +--+  +--+--+  +--+  +  +  +  +  +--+--+--+  +  +  +",
	"         |                                             ",
	"+--+  +--+  +--+--+--+  +--+--+--+--+  +--+--+--+  +--+",
}

local crossing1 = {
	Name = "West stair",
	Primitives = merge(maze(CROSSING1, X0, Z0, true, true), {
		roof({ { -60, 192 }, { 60, 192 } }),
		roof({ { 100, 232 }, { 100, 352 } }),
		roof({ { -60, 32 }, { 60, 32 } }),
		roof({ { -20, 552 }, { 60, 552 } }),
		roof({ { 140, 552 }, { 260, 552 } }),
		roof({ { -100, 352 }, { -20, 352 } }),
		roof({ { 140, 112 }, { 300, 112 } }),
		lane({ { -220, 552 }, { -180, 552 } }),
		lane({ { -100, 232 }, { -100, 272 } }),
		lane({ { 300, 352 }, { 340, 352 } }),
		lane({ { -340, 32 }, { -300, 32 } }),
		lane({ { 180, 152 }, { 220, 152 } }),
		pool(140, 72),
		pool(-260, 312),
		pool(-60, 152),
		pool(-140, 232),
		pool(-340, 32),
		pool(-300, 272),
		pool(-180, 512),
		pool(300, 352),
		{
			Kind = "Ramp",
			Path = {
				{ -260, 0 },
				{ -260, 32 },
				{ -140, 32 },
				{ -140, 152 },
				{ -220, 152 },
				{ -220, 192 },
				{ -300, 192 },
				{ -300, 312 },
				{ -340, 312 },
				{ -340, 352 },
				{ -260, 352 },
				{ -260, 232 },
				{ -220, 232 },
				{ -220, 432 },
				{ -180, 432 },
				{ -180, 392 },
				{ -140, 392 },
				{ -140, 312 },
				{ -100, 312 },
				{ -100, 192 },
				{ 100, 192 },
				{ 100, 392 },
				{ -100, 392 },
				{ -100, 512 },
				{ -180, 512 },
				{ -180, 472 },
				{ -220, 472 },
				{ -220, 512 },
				{ -260, 512 },
				{ -260, 552 },
				{ -300, 552 },
				{ -300, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(340, 552, 5),
		loot(-100, 552, 4),
		loot(100, 432, 3),
		loot(140, 432, 3),
		loot(220, 312, 2),
		loot(340, 352, 2),
	},
}

local CROSSING2 = {
	"+  +  +--+--+--+--+  +--+--+--+--+--+  +  +--+  +--+--+",
	"   |  |     |        |                 |  |     |      ",
	"+  +  +  +  +  +  +--+  +  +  +  +  +  +--+  +--+  +  +",
	"               |                       |  |  |     |   ",
	"+  +  +  +  +--+--+  +  +  +  +  +  +  +  +  +  +--+  +",
	"               |     |                 |     |     |   ",
	"+  +  +  +--+  +  +--+  +  +  +  +--+--+  +--+  +  +  +",
	"            |                          |  |     |  |   ",
	"+  +  +  +  +--+  +  +--+  +  +  +  +  +  +--+--+  +  +",
	"                  |                                |   ",
	"+  +  +  +  +--+  +--+  +  +  +  +  +  +  +  +  +  +  +",
	"      |                                |               ",
	"+  +--+  +  +--+--+  +  +  +  +  +--+  +--+  +  +  +  +",
	"      |  |  |                          |               ",
	"+--+  +--+  +  +  +  +  +  +  +  +  +  +--+--+  +  +  +",
	"   |     |     |                                       ",
	"+  +--+  +--+--+  +--+  +  +  +  +  +--+--+  +  +  +  +",
	"                                    |        |         ",
	"+  +  +  +--+  +  +  +  +  +--+  +  +  +  +  +  +  +  +",
	"               |     |                 |               ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +",
	"            |  |  |                    |               ",
	"+  +  +  +--+  +  +  +  +  +  +  +  +  +--+  +  +  +  +",
	"               |                    !                  ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +--+  +  +  +  +  +",
	"            |     |                    |  |            ",
	"+  +--+--+--+  +--+  +  +  +  +  +  +  +  +  +  +  +  +",
	"                                 |        |            ",
	"+--+--+--+--+--+--+--+  +--+--+  +--+--+--+--+--+--+--+",
}

local crossing2 = {
	Name = "Hall gallery",
	Primitives = merge(maze(CROSSING2, X0, Z0, true, true), {
		roof({ { -60, 552 }, { 20, 552 } }),
		roof({ { -60, 192 }, { 60, 192 } }),
		roof({ { -20, 32 }, { 60, 32 } }),
		roof({ { -60, 352 }, { 60, 352 } }),
		roof({ { -100, 392 }, { -100, 512 } }),
		roof({ { 260, 552 }, { 340, 552 } }),
		roof({ { -60, 392 }, { 60, 392 } }),
		roof({ { -340, 32 }, { -260, 32 } }),
		roof({ { 340, 72 }, { 340, 192 } }),
		roof({ { -300, 552 }, { -220, 552 } }),
		roof({ { -140, 392 }, { -140, 472 } }),
		lane({ { 140, 392 }, { 140, 432 } }),
		lane({ { -100, 232 }, { -100, 272 } }),
		lane({ { 220, 192 }, { 260, 192 } }),
		lane({ { 300, 352 }, { 340, 352 } }),
		lane({ { -220, 352 }, { -180, 352 } }),
		pool(-340, 552),
		pool(140, 232),
		pool(260, 32),
		pool(180, 312),
		pool(220, 72),
		pool(220, 32),
		pool(-100, 312),
		pool(-180, 192),
		{
			Kind = "Ramp",
			Path = {
				{ 260, 0 },
				{ 260, 32 },
				{ 140, 32 },
				{ 140, 112 },
				{ 100, 112 },
				{ 100, 32 },
				{ -60, 32 },
				{ -60, 152 },
				{ -100, 152 },
				{ -100, 192 },
				{ 100, 192 },
				{ 100, 232 },
				{ 140, 232 },
				{ 140, 312 },
				{ 220, 312 },
				{ 220, 352 },
				{ 140, 352 },
				{ 140, 472 },
				{ 180, 472 },
				{ 180, 552 },
				{ 100, 552 },
				{ 100, 352 },
				{ -100, 352 },
				{ -100, 552 },
				{ 60, 552 },
				{ 60, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(-60, 392, 5),
		loot(-140, 232, 4),
		loot(-260, 272, 3),
		loot(-140, 552, 3),
		loot(-100, 232, 2),
		loot(-340, 312, 2),
	},
}

local CROSSING3 = {
	"+  +  +--+--+--+--+  +--+--+  +--+--+  +  +  +  +--+--+",
	"   |  |              |     |           |  |  |     |   ",
	"+  +  +  +  +--+  +--+  +  +  +  +  +--+--+--+==+  +  +",
	"            |                          |        |  |   ",
	"+  +  +  +  +  +--+--+  +  +  +  +  +  +  +--+  +  +  +",
	"            |        |                 |  |     |  |   ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +==+  +  +",
	"               |                       |  |  |         ",
	"+  +  +  +--+--+  +--+--+  +  +  +--+  +  +  +--+  +  +",
	"                  |                    |  !        |   ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"   |                                                   ",
	"+  +  +--+--+  +--+  +  +  +  +  +--+--+--+  +  +  +  +",
	"      |     |                             |            ",
	"+  +--+  +  +--+  +  +  +  +  +  +  +  +--+  +  +  +  +",
	"      |  |  |  |                                       ",
	"+--+  +  +  +  +--+  +  +  +  +  +  +--+  +--+  +  +  +",
	"         |  |                    |     |               ",
	"+  +  +  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +  +",
	"            |                    |        |            ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +--+  +  +  +  +  +",
	"                  |                       |            ",
	"+  +  +  +--+--+  +  +  +  +  +  +  +  +--+--+  +  +  +",
	"            |                       |                  ",
	"+  +  +  +  +  +--+  +  +  +  +  +  +  +--+  +  +  +  +",
	"   |           |  |                    |  |            ",
	"+  +  +--+--+--+  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"                                    |     |            ",
	"+--+--+--+--+  +  +--+--+--+--+--+--+  +--+--+  +  +--+",
}

local crossing3 = {
	Name = "East switchbacks",
	Primitives = merge(maze(CROSSING3, X0, Z0, true, true), {
		roof({ { -100, 432 }, { -100, 512 } }),
		roof({ { -60, 192 }, { 60, 192 } }),
		roof({ { 100, 392 }, { 100, 512 } }),
		roof({ { -60, 552 }, { 60, 552 } }),
		roof({ { -340, 32 }, { -260, 32 } }),
		roof({ { -20, 32 }, { 60, 32 } }),
		roof({ { -220, 312 }, { -220, 392 } }),
		roof({ { -260, 552 }, { -180, 552 } }),
		roof({ { 340, 32 }, { 340, 112 } }),
		roof({ { -260, 192 }, { -180, 192 } }),
		lane({ { -60, 392 }, { -20, 392 } }),
		lane({ { 100, 272 }, { 100, 312 } }),
		lane({ { -100, 232 }, { -100, 272 } }),
		lane({ { -260, 232 }, { -220, 232 } }),
		lane({ { 180, 112 }, { 180, 152 } }),
		pool(-140, 112),
		pool(220, 352),
		pool(300, 392),
		pool(-140, 192),
		pool(-180, 272),
		pool(-100, 552),
		pool(260, 32),
		pool(140, 272),
		{
			Kind = "Ramp",
			Path = {
				{ 260, 0 },
				{ 260, 32 },
				{ 300, 32 },
				{ 300, 192 },
				{ 220, 192 },
				{ 220, 112 },
				{ 260, 112 },
				{ 260, 72 },
				{ 180, 72 },
				{ 180, 232 },
				{ 100, 232 },
				{ 100, 192 },
				{ -100, 192 },
				{ -100, 352 },
				{ 20, 352 },
				{ 20, 392 },
				{ -100, 392 },
				{ -100, 552 },
				{ 100, 552 },
				{ 100, 352 },
				{ 140, 352 },
				{ 140, 392 },
				{ 180, 392 },
				{ 180, 432 },
				{ 140, 432 },
				{ 140, 472 },
				{ 220, 472 },
				{ 220, 552 },
				{ 300, 552 },
				{ 300, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(-140, 512, 5),
		loot(220, 32, 4),
		loot(-340, 512, 3),
		loot(140, 192, 3),
		loot(100, 152, 2),
		loot(-220, 472, 2),
	},
}

local CROSSING4 = {
	"+--+--+  +--+--+  +--+--+--+--+--+--+  +--+--+  +--+--+",
	"            |  |                       |     |         ",
	"+  +  +  +  +  +--+  +--+  +  +  +  +--+  +  +--+--+  +",
	"            |        |                    |     |  |   ",
	"+  +  +  +  +  +  +--+  +  +  +  +  +  +  +--+--+  +  +",
	"               |                       |  |     |      ",
	"+  +  +  +--+--+  +  +  +  +  +  +--+  +  +  +  +  +--+",
	"               |     |                 |  |  |  |  |   ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"                  |  |                 |  |  |         ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"   |     |                                |            ",
	"+  +--+  +  +--+  +  +  +  +  +  +--+--+--+  +  +  +  +",
	"   |     |  |  |                                       ",
	"+  +  +--+  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +",
	"   |     |  |  |                       |               ",
	"+  +--+  +  +  +  +--+  +  +  +  +  +--+  +  +  +  +  +",
	"         |  !              |           |  |            ",
	"+  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +  +  +  +",
	"            !                 |           |            ",
	"+  +  +  +  +--+--+  +  +  +  +  +  +--+  +  +  +  +  +",
	"                                       |  |            ",
	"+  +  +  +--+==+--+--+  +  +  +  +  +  +  +  +  +  +  +",
	"                                                       ",
	"+  +  +  +  +  +--+  +  +  +  +  +  +--+  +  +  +  +  +",
	"            |  |                       |  |            ",
	"+  +--+--+--+--+  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"            |                          |  |            ",
	"+--+  +--+--+  +--+--+  +--+--+  +--+--+  +--+--+--+--+",
}

local crossing4 = {
	Name = "Long cross",
	Primitives = merge(maze(CROSSING4, X0, Z0, true, true), {
		roof({ { 180, 112 }, { 180, 192 } }),
		roof({ { -60, 32 }, { 60, 32 } }),
		roof({ { -20, 192 }, { 60, 192 } }),
		roof({ { -100, 152 }, { -100, 272 } }),
		roof({ { -340, 232 }, { -340, 312 } }),
		roof({ { -20, 552 }, { 60, 552 } }),
		roof({ { 260, 552 }, { 340, 552 } }),
		lane({ { 220, 152 }, { 220, 192 } }),
		lane({ { 300, 352 }, { 340, 352 } }),
		lane({ { -60, 392 }, { -20, 392 } }),
		lane({ { -340, 32 }, { -300, 32 } }),
		lane({ { 300, 392 }, { 340, 392 } }),
		pool(-100, 112),
		pool(-180, 432),
		pool(100, 72),
		pool(-140, 432),
		pool(100, 232),
		pool(-180, 512),
		pool(-20, 352),
		pool(-300, 192),
		{
			Kind = "Ramp",
			Path = {
				{ -260, 0 },
				{ -260, 32 },
				{ -220, 32 },
				{ -220, 112 },
				{ -180, 112 },
				{ -180, 72 },
				{ -100, 72 },
				{ -100, 32 },
				{ 100, 32 },
				{ 100, 112 },
				{ 140, 112 },
				{ 140, 72 },
				{ 180, 72 },
				{ 180, 232 },
				{ 100, 232 },
				{ 100, 192 },
				{ -60, 192 },
				{ -60, 112 },
				{ -100, 112 },
				{ -100, 312 },
				{ -140, 312 },
				{ -140, 232 },
				{ -220, 232 },
				{ -220, 432 },
				{ -100, 432 },
				{ -100, 392 },
				{ 20, 392 },
				{ 20, 352 },
				{ 140, 352 },
				{ 140, 392 },
				{ 180, 392 },
				{ 180, 552 },
				{ 180, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(-220, 552, 5),
		loot(-340, 232, 4),
		loot(220, 192, 3),
		loot(-140, 472, 3),
		loot(340, 152, 2),
		loot(-100, 472, 2),
	},
}

local CROSSING5 = {
	"+  +  +  +  +  +  +--+--+--+--+--+--+  +  +  +  +--+--+",
	"   |  |  |  |  |                       |  |  |  |      ",
	"+  +  +  +--+--+--+  +--+  +  +  +  +--+--+--+  +  +  +",
	"                     |                       |  |  |   ",
	"+  +  +  +  +--+  +--+  +  +  +  +  +--+--+  +  +  +  +",
	"            |  |                          |        |   ",
	"+  +  +  +  +  +  +  +  +  +  +  +--+--+  +--+  +--+  +",
	"            |        |                 |     |  |      ",
	"+  +  +  +  +--+  +--+  +  +  +  +  +  +--+  +  +  +--+",
	"               |                          |     |      ",
	"+  +--+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"   |           |                       |               ",
	"+  +  +--+--+--+  +  +  +  +  +  +--+  +--+  +  +  +  +",
	"   |  |                                   |            ",
	"+  +  +  +  +--+--+--+  +  +  +  +  +--+  +  +  +  +  +",
	"         |  |                             |            ",
	"+  +  +--+--+  +--+  +  +  +  +  +  +  +--+  +  +  +  +",
	"   |        |        !                 |               ",
	"+  +  +  +  +  +  +  +  +  +--+  +--+  +  +  +  +  +  +",
	"               |                       |               ",
	"+  +  +  +  +  +  +--+  +  +  +  +  +  +--+  +  +  +  +",
	"            |  !                                       ",
	"+  +  +  +--+  +  +  +  +  +  +  +  +--+--+  +  +  +  +",
	"               |                    |     |            ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +--+  +  +  +  +",
	"         |     |  |                    |               ",
	"+  +--+  +  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +",
	"      |     |                 |     |                  ",
	"+--+--+--+--+--+--+--+--+--+--+  +  +--+--+--+--+--+--+",
}

local crossing5 = {
	Name = "Backtrack",
	Primitives = merge(maze(CROSSING5, X0, Z0, true, true), {
		roof({ { 100, 432 }, { 100, 512 } }),
		roof({ { -60, 32 }, { 60, 32 } }),
		roof({ { -60, 392 }, { 60, 392 } }),
		roof({ { -60, 552 }, { 20, 552 } }),
		roof({ { -60, 352 }, { 60, 352 } }),
		roof({ { -340, 192 }, { -260, 192 } }),
		roof({ { 220, 552 }, { 340, 552 } }),
		roof({ { -20, 192 }, { 60, 192 } }),
		roof({ { -340, 32 }, { -180, 32 } }),
		lane({ { -100, 232 }, { -100, 272 } }),
		lane({ { -140, 472 }, { -140, 512 } }),
		lane({ { 300, 392 }, { 340, 392 } }),
		lane({ { -340, 232 }, { -340, 272 } }),
		lane({ { -100, 472 }, { -100, 512 } }),
		pool(-220, 552),
		pool(-60, 192),
		pool(180, 312),
		pool(260, 392),
		pool(-300, 312),
		pool(-180, 512),
		pool(220, 272),
		pool(100, 312),
		{
			Kind = "Ramp",
			Path = {
				{ 260, 0 },
				{ 260, 32 },
				{ 260, 192 },
				{ 220, 192 },
				{ 220, 152 },
				{ 180, 152 },
				{ 180, 112 },
				{ 100, 112 },
				{ 100, 32 },
				{ -100, 32 },
				{ -100, 72 },
				{ -220, 72 },
				{ -220, 192 },
				{ -180, 192 },
				{ -180, 232 },
				{ -300, 232 },
				{ -300, 352 },
				{ -220, 352 },
				{ -220, 392 },
				{ -180, 392 },
				{ -180, 472 },
				{ -220, 472 },
				{ -220, 512 },
				{ -180, 512 },
				{ -180, 552 },
				{ -140, 552 },
				{ -140, 352 },
				{ -180, 352 },
				{ -180, 312 },
				{ -100, 312 },
				{ -100, 392 },
				{ 100, 392 },
				{ 100, 552 },
				{ 60, 552 },
				{ 60, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(140, 152, 5),
		loot(180, 472, 4),
		loot(340, 552, 3),
		loot(180, 352, 3),
		loot(340, 352, 2),
		loot(340, 392, 2),
	},
}

frame.Crossings = { crossing1, crossing2, crossing3, crossing4, crossing5 }

-- <<< rooms (written by tools/gen/zone6/rooms.py; edit that, not this)
frame.Slots = {
	{
		Name = "West cave",
		At = { -360, 52 },
		Size = { 120, 120 },
		Rooms = {
			makeRoom(true, false, {
				Name = "Comb of caves",
				Art = {
					"+  +  +  +",
					"          ",
					"+  +--+--+",
					"          ",
					"+  +--+--+",
					"          ",
					"+  +  +  +",
				},
				Shapes = {
					cellRoof(60, 20),
					cellRoof(100, 20),
					cellRoof(60, 100),
					cellRoof(100, 100),
				},
				Loot = {
					loot(100, 20, 6),
					loot(100, 100, 4),
				},
				Decor = {
					{
						Kind = "DeadCoral",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 2,
					},
					{
						Kind = "Pebbles",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 4,
					},
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 8,
					},
					{
						Kind = "DeadCoral",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 3,
					},
					{ Kind = "Timber", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 2 },
					prop("GlowShells", 110, 10),
				},
			}),
			makeRoom(true, false, {
				Name = "Drowned pool",
				Art = {
					"+  +  +  +",
					"   |      ",
					"+  +  +  +",
					"          ",
					"+  +  +  +",
					"   |      ",
					"+  +  +  +",
				},
				Shapes = {
					pool(60, 60, 20),
					mud({ { 24, 36 }, { 96, 36 }, { 96, 84 }, { 24, 84 } }),
				},
				Loot = {
					loot(20, 20, 6),
					loot(20, 100, 4),
				},
				Decor = {
					{ Kind = "Kelp", Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } }, Count = 3 },
					{
						Kind = "Starfish",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 1,
					},
					{ Kind = "Kelp", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 8 },
					{ Kind = "Weed", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 4 },
				},
			}),
			makeRoom(true, false, {
				Name = "Boulder scramble",
				Art = {
					"+  +  +  +",
					"          ",
					"+--+--+  +",
					"          ",
					"+  +  +  +",
					"          ",
					"+  +  +  +",
				},
				Shapes = {
					boulder(60, 70, 13, 10),
					boulder(34, 74, 11, 9),
					boulder(96, 80, 11, 10),
					boulder(100, 34, 11, 10),
				},
				Loot = {
					loot(20, 20, 6),
					loot(20, 100, 3),
				},
				Decor = {
					{
						Kind = "Crate",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 1,
					},
					{
						Kind = "Urchins",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 2,
					},
					{
						Kind = "Pebbles",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 4,
					},
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 10,
					},
					{
						Kind = "Urchins",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 4,
					},
					{
						Kind = "Barnacles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 6,
					},
				},
			}),
		},
	},
	{
		Name = "Gatehouse yard",
		At = { -40, 52 },
		Size = { 120, 120 },
		Rooms = {
			makeRoom(false, false, {
				Name = "Gatehouse ring",
				Art = {
					"+  +  +  +",
					"          ",
					"+  +--+  +",
					"   |      ",
					"+  +--+  +",
					"      |   ",
					"+  +  +  +",
				},
				Shapes = {
					cellRoof(20, 20),
					cellRoof(60, 20),
					cellRoof(100, 20),
					cellRoof(100, 60),
				},
				Loot = {
					loot(60, 60, 6),
					loot(60, 100, 3),
					loot(100, 100, 2),
				},
				Decor = {
					{ Kind = "Anchor", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 1 },
					{ Kind = "Chain", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 1 },
					{ Kind = "Chain", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 3 },
					{ Kind = "Bones", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 1 },
					{
						Kind = "Barnacles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 6,
					},
					prop("GlowShells", 70, 50),
				},
			}),
			makeRoom(false, false, {
				Name = "Pillar court",
				Art = {
					"+  +  +  +",
					"      |   ",
					"+  +  +  +",
					"          ",
					"+  +  +  +",
					"      |   ",
					"+  +  +  +",
				},
				Shapes = {
					post(40, 40),
					post(80, 40),
					post(40, 80),
					post(80, 80),
				},
				Loot = {
					loot(100, 100, 6),
					loot(100, 20, 5),
				},
				Decor = {
					{ Kind = "Timber", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 2 },
					{ Kind = "Chain", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 1 },
					{ Kind = "Timber", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 4 },
					{
						Kind = "Barnacles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 6,
					},
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 4,
					},
				},
			}),
			makeRoom(false, false, {
				Name = "Gatehouse cellar",
				Art = {
					"+  +  +  +",
					"          ",
					"+  +--+  +",
					"   |  |   ",
					"+  +  +  +",
					"   |      ",
					"+  +  +  +",
				},
				Shapes = {
					cellRoof(60, 60),
					cellRoof(60, 100),
					cellRoof(100, 60),
				},
				Loot = {
					loot(60, 60, 6),
					loot(20, 100, 3),
				},
				Decor = {
					{
						Kind = "DeadCoral",
						Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } },
						Count = 2,
					},
					{ Kind = "Pebbles", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 4 },
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 8,
					},
					{
						Kind = "DeadCoral",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 3,
					},
					{ Kind = "Timber", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 2 },
					prop("GlowShells", 70, 50),
				},
			}),
		},
	},
	{
		Name = "East cellar",
		At = { 240, 212 },
		Size = { 120, 120 },
		Rooms = {
			makeRoom(false, true, {
				Name = "Sinking flats",
				Art = {
					"+  +  +  +",
					"      |   ",
					"+  +  +  +",
					"          ",
					"+  +  +  +",
					"      |   ",
					"+  +  +  +",
				},
				Shapes = {
					mud({ { 44, 58 }, { 76, 58 }, { 76, 90 }, { 44, 90 } }),
					mud({ { 84, 30 }, { 116, 30 }, { 116, 62 }, { 84, 62 } }),
				},
				Loot = {
					loot(100, 20, 6),
					loot(100, 100, 5),
				},
				Decor = {
					{ Kind = "Bones", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 1 },
					{ Kind = "Starfish", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 2 },
					{ Kind = "Bones", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 2 },
					{
						Kind = "Starfish",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 3,
					},
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 6,
					},
				},
				Hazards = {
					{ Type = "Sink", At = { 60, 74 }, Radius = 9 },
					{ Type = "Sink", At = { 100, 46 }, Radius = 9 },
				},
			}),
			makeRoom(false, true, {
				Name = "Flooded cellar",
				Art = {
					"+  +  +  +",
					"          ",
					"+  +--+--+",
					"          ",
					"+  +  +  +",
					"      |   ",
					"+  +  +  +",
				},
				Shapes = {
					pool(60, 100, 16),
					cellRoof(60, 20),
					cellRoof(100, 20),
				},
				Loot = {
					loot(100, 20, 6),
					loot(100, 100, 4),
				},
				Decor = {
					{ Kind = "Kelp", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 3 },
					{ Kind = "Starfish", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 1 },
					{ Kind = "Kelp", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 8 },
					{ Kind = "Weed", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 4 },
				},
			}),
			makeRoom(false, true, {
				Name = "Weed hall",
				Art = {
					"+  +  +  +",
					"   |      ",
					"+  +  +--+",
					"          ",
					"+  +  +  +",
					"   |      ",
					"+  +  +  +",
				},
				Shapes = {
					lane({ { 60, 60 }, { 100, 60 } }),
					weed({ { 44, 28 }, { 116, 28 }, { 116, 92 }, { 44, 92 } }),
				},
				Loot = {
					loot(100, 20, 6),
					loot(20, 20, 3),
					loot(20, 100, 3),
				},
				Decor = {
					{ Kind = "Weed", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 4 },
					{ Kind = "Kelp", Area = { { 8, 48 }, { 32, 48 }, { 32, 72 }, { 8, 72 } }, Count = 2 },
					{ Kind = "Weed", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 10 },
					{ Kind = "Kelp", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 6 },
				},
			}),
		},
	},
	{
		Name = "Drowned hall",
		At = { -80, 212 },
		Size = { 160, 120 },
		Rooms = {
			makeRoom(false, false, {
				Name = "Flooded hall",
				Art = {
					"+  +  +  +  +",
					"   |     |   ",
					"+  +  +  +  +",
					"             ",
					"+  +  +  +  +",
					"             ",
					"+  +  +  +  +",
				},
				Shapes = {
					post(40, 40),
					post(120, 40),
					post(40, 80),
					post(120, 80),
					pool(60, 60, 15),
					pool(100, 60, 15),
				},
				Loot = {
					loot(140, 20, 6),
					loot(20, 20, 5),
				},
				Decor = {
					{ Kind = "Kelp", Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } }, Count = 3 },
					{
						Kind = "Starfish",
						Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } },
						Count = 1,
					},
					{ Kind = "Kelp", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 8 },
					{ Kind = "Weed", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 4 },
				},
			}),
			makeRoom(false, false, {
				Name = "Collapsed hall",
				Art = {
					"+  +  +  +  +",
					"         |   ",
					"+  +--+--+  +",
					"             ",
					"+  +  +  +  +",
					"         |   ",
					"+  +  +  +  +",
				},
				Shapes = {
					boulder(40, 76, 11, 9),
					boulder(120, 40, 12, 10),
					boulder(80, 96, 11, 8),
					cellRoof(60, 20),
					cellRoof(100, 20),
				},
				Loot = {
					loot(100, 20, 6),
					loot(140, 100, 4),
				},
				Decor = {
					{
						Kind = "Timber",
						Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } },
						Count = 1,
					},
					{
						Kind = "Crate",
						Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } },
						Count = 1,
					},
					{
						Kind = "Pebbles",
						Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } },
						Count = 5,
					},
					{ Kind = "Timber", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 4 },
					{ Kind = "Crate", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 2 },
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } },
						Count = 12,
					},
				},
				Hazards = {
					{ Type = "Rockfall", At = { 60, 20 } },
				},
			}),
			makeRoom(false, false, {
				Name = "Pillar gallery",
				Art = {
					"+  +  +  +  +",
					"             ",
					"+  +  +  +--+",
					"             ",
					"+  +  +  +  +",
					"   |         ",
					"+  +  +  +  +",
				},
				Shapes = {
					post(40, 40),
					post(80, 40),
					post(120, 40),
					post(80, 80),
					post(120, 80),
				},
				Loot = {
					loot(140, 20, 6),
					loot(20, 100, 3),
				},
				Decor = {
					{
						Kind = "Timber",
						Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } },
						Count = 2,
					},
					{
						Kind = "Chain",
						Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } },
						Count = 1,
					},
					{ Kind = "Timber", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 4 },
					{
						Kind = "Barnacles",
						Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } },
						Count = 6,
					},
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } },
						Count = 4,
					},
					prop("LanternPost", 50, 24),
					prop("GlowWeed", 90, 34),
					prop("GlowShells", 134, 34),
				},
				Hazards = {
					{ Type = "Gloom", At = { 120, 20 }, Radius = 18 },
				},
			}),
			makeRoom(false, false, {
				Name = "Dead-end vault",
				Art = {
					"+  +  +  +  +",
					"             ",
					"+  +--+--+--+",
					"             ",
					"+  +  +  +  +",
					"   |         ",
					"+  +  +  +  +",
				},
				Shapes = {
					cellRoof(60, 20),
					cellRoof(140, 20),
				},
				Loot = {
					loot(140, 20, 6),
					loot(20, 100, 3),
				},
				Decor = {
					{
						Kind = "Bones",
						Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } },
						Count = 1,
					},
					{
						Kind = "DeadCoral",
						Area = { { 48, 88 }, { 72, 88 }, { 72, 112 }, { 48, 112 } },
						Count = 1,
					},
					{ Kind = "Bones", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 2 },
					{
						Kind = "DeadCoral",
						Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } },
						Count = 4,
					},
					{ Kind = "Chain", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 2 },
					prop("GlowShells", 150, 10),
				},
				Hazards = {
					{ Type = "Rockfall", At = { 60, 20 } },
				},
			}),
		},
	},
	{
		Name = "Low west vault",
		At = { -360, 372 },
		Size = { 120, 120 },
		Rooms = {
			makeRoom(true, false, {
				Name = "Tunnel ring",
				Art = {
					"+  +  +  +",
					"          ",
					"+  +--+  +",
					"   |      ",
					"+  +--+  +",
					"          ",
					"+  +  +  +",
				},
				Shapes = {
					cellRoof(20, 20),
					cellRoof(100, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(100, 100),
				},
				Loot = {
					loot(60, 60, 6),
				},
				Decor = {
					{
						Kind = "Anchor",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 1,
					},
					{
						Kind = "Chain",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 1,
					},
					{ Kind = "Chain", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 3 },
					{ Kind = "Bones", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 1 },
					{
						Kind = "Barnacles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 6,
					},
					prop("GlowShells", 70, 50),
				},
			}),
			makeRoom(true, false, {
				Name = "Dead-end cave",
				Art = {
					"+  +  +  +",
					"   |      ",
					"+  +  +  +",
					"          ",
					"+--+--+  +",
					"          ",
					"+  +  +  +",
				},
				Shapes = {
					cellRoof(20, 100),
					cellRoof(60, 100),
					cellRoof(20, 20),
				},
				Loot = {
					loot(20, 100, 6),
					loot(20, 20, 4),
				},
				Decor = {
					{
						Kind = "DeadCoral",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 2,
					},
					{
						Kind = "Pebbles",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 4,
					},
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 8,
					},
					{
						Kind = "DeadCoral",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 3,
					},
					{ Kind = "Timber", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 2 },
					prop("GlowShells", 30, 90),
				},
			}),
			makeRoom(true, false, {
				Name = "Boulder scramble",
				Art = {
					"+  +  +  +",
					"   !      ",
					"+--+  +  +",
					"          ",
					"+  +  +  +",
					"          ",
					"+  +  +  +",
				},
				Shapes = {
					boulder(70, 62, 13, 10),
					boulder(100, 100, 11, 10),
					boulder(30, 100, 11, 9),
				},
				Loot = {
					loot(20, 20, 6),
				},
				Decor = {
					{
						Kind = "Crate",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 1,
					},
					{
						Kind = "Urchins",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 2,
					},
					{
						Kind = "Pebbles",
						Area = { { 88, 48 }, { 112, 48 }, { 112, 72 }, { 88, 72 } },
						Count = 4,
					},
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 10,
					},
					{
						Kind = "Urchins",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 4,
					},
					{
						Kind = "Barnacles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 6,
					},
				},
			}),
		},
	},
	{
		Name = "Sea vault",
		At = { -80, 412 },
		Size = { 160, 120 },
		Rooms = {
			makeRoom(false, false, {
				Name = "Drowned gallery",
				Art = {
					"+  +  +  +  +",
					"             ",
					"+--+--+--+  +",
					"             ",
					"+  +--+--+--+",
					"             ",
					"+  +  +  +  +",
				},
				Shapes = {
					roof({ { 140, 60 }, { 20, 60 }, { 20, 100 }, { 140, 100 } }),
				},
				Loot = {
					loot(140, 100, 6),
					loot(20, 20, 3),
				},
				Decor = {
					{ Kind = "Chain", Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } }, Count = 2 },
					{
						Kind = "WreckRibs",
						Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } },
						Count = 1,
					},
					{ Kind = "Chain", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 4 },
					{
						Kind = "WreckRibs",
						Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } },
						Count = 1,
					},
					{ Kind = "Kelp", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 4 },
				},
			}),
			makeRoom(false, false, {
				Name = "Flooded vault",
				Art = {
					"+  +  +  +  +",
					"             ",
					"+--+--+  +  +",
					"             ",
					"+  +  +  +  +",
					"         |   ",
					"+  +  +  +  +",
				},
				Shapes = {
					post(80, 40),
					post(80, 80),
					pool(80, 80, 18),
					pool(120, 60, 12),
				},
				Loot = {
					loot(20, 20, 6),
					loot(140, 100, 4),
				},
				Decor = {
					{ Kind = "Kelp", Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } }, Count = 3 },
					{
						Kind = "Starfish",
						Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } },
						Count = 1,
					},
					{ Kind = "Kelp", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 8 },
					{ Kind = "Weed", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 4 },
				},
			}),
			makeRoom(false, false, {
				Name = "Collapsed vault",
				Art = {
					"+  +  +  +  +",
					"             ",
					"+  +  +  +  +",
					"      |      ",
					"+--+  +  +  +",
					"      !      ",
					"+  +  +  +  +",
				},
				Shapes = {
					boulder(30, 70, 11, 9),
					boulder(110, 90, 12, 10),
					boulder(140, 60, 11, 9),
					cellRoof(20, 100),
					cellRoof(60, 100),
				},
				Loot = {
					loot(20, 100, 6),
				},
				Decor = {
					{ Kind = "Timber", Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } }, Count = 1 },
					{ Kind = "Crate", Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } }, Count = 1 },
					{
						Kind = "Pebbles",
						Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } },
						Count = 5,
					},
					{ Kind = "Timber", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 4 },
					{ Kind = "Crate", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 2 },
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } },
						Count = 12,
					},
				},
				Hazards = {
					{ Type = "Rockfall", At = { 60, 100 } },
				},
			}),
			makeRoom(false, false, {
				Name = "Ring and vault",
				Art = {
					"+  +  +  +  +",
					"             ",
					"+  +--+--+  +",
					"   |         ",
					"+  +--+--+  +",
					"             ",
					"+  +  +  +  +",
				},
				Shapes = {
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(140, 100),
					cellRoof(60, 100),
				},
				Loot = {
					loot(60, 60, 6),
				},
				Decor = {
					{ Kind = "Anchor", Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } }, Count = 1 },
					{ Kind = "Chain", Area = { { 88, 8 }, { 112, 8 }, { 112, 32 }, { 88, 32 } }, Count = 1 },
					{ Kind = "Chain", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 3 },
					{ Kind = "Bones", Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } }, Count = 1 },
					{
						Kind = "Barnacles",
						Area = { { 8, 8 }, { 152, 8 }, { 152, 112 }, { 8, 112 } },
						Count = 6,
					},
					prop("GlowShells", 70, 50),
				},
			}),
		},
	},
	{
		Name = "East deeps",
		At = { 240, 412 },
		Size = { 120, 120 },
		Rooms = {
			makeRoom(false, true, {
				Name = "Flooded pocket",
				Art = {
					"+  +  +  +",
					"          ",
					"+  +  +  +",
					"      |   ",
					"+  +  +  +",
					"      |   ",
					"+  +  +  +",
				},
				Shapes = {
					pool(40, 80, 20),
				},
				Loot = {
					loot(100, 100, 6),
					loot(20, 100, 3),
				},
				Decor = {
					{ Kind = "Kelp", Area = { { 48, 8 }, { 72, 8 }, { 72, 32 }, { 48, 32 } }, Count = 3 },
					{ Kind = "Starfish", Area = { { 48, 8 }, { 72, 8 }, { 72, 32 }, { 48, 32 } }, Count = 1 },
					{ Kind = "Kelp", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 8 },
					{ Kind = "Weed", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 4 },
				},
			}),
			makeRoom(false, true, {
				Name = "Dead-end cave",
				Art = {
					"+  +  +  +",
					"          ",
					"+--+--+  +",
					"          ",
					"+  +  +--+",
					"          ",
					"+  +  +  +",
				},
				Shapes = {
					cellRoof(60, 60),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 100),
				},
				Loot = {
					loot(100, 100, 6),
					loot(20, 20, 3),
				},
				Decor = {
					{
						Kind = "DeadCoral",
						Area = { { 48, 8 }, { 72, 8 }, { 72, 32 }, { 48, 32 } },
						Count = 2,
					},
					{ Kind = "Pebbles", Area = { { 48, 8 }, { 72, 8 }, { 72, 32 }, { 48, 32 } }, Count = 4 },
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 8,
					},
					{
						Kind = "DeadCoral",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 3,
					},
					{ Kind = "Timber", Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } }, Count = 2 },
					prop("GlowShells", 110, 90),
				},
			}),
			makeRoom(false, true, {
				Name = "Boulder scramble",
				Art = {
					"+  +  +  +",
					"          ",
					"+  +  +  +",
					"          ",
					"+--+  +  +",
					"          ",
					"+  +  +  +",
				},
				Shapes = {
					boulder(70, 62, 13, 10),
					boulder(96, 76, 11, 10),
					boulder(30, 56, 11, 9),
				},
				Loot = {
					loot(20, 100, 6),
					loot(100, 100, 3),
				},
				Decor = {
					{ Kind = "Crate", Area = { { 48, 8 }, { 72, 8 }, { 72, 32 }, { 48, 32 } }, Count = 1 },
					{ Kind = "Urchins", Area = { { 48, 8 }, { 72, 8 }, { 72, 32 }, { 48, 32 } }, Count = 2 },
					{ Kind = "Pebbles", Area = { { 48, 8 }, { 72, 8 }, { 72, 32 }, { 48, 32 } }, Count = 4 },
					{
						Kind = "Pebbles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 10,
					},
					{
						Kind = "Urchins",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 4,
					},
					{
						Kind = "Barnacles",
						Area = { { 8, 8 }, { 112, 8 }, { 112, 112 }, { 8, 112 } },
						Count = 6,
					},
				},
			}),
		},
	},
}
-- >>> rooms

-- Fitting the roofs -----------------------------------------------------------------------------
--
-- A roof is drawn as `roof(path)`: the lane cells along the path. Here each one becomes exact
-- rectangles whose edges lie on the grid lines, on the walls under them: a cell is roofed only
-- if at least two of its sides are walls (a bend, a straight, a dead end: never an open
-- junction), and a long run is broken by light shafts (every third cell stays open to the sky).

-- The walls of some pictures, as sets: h[j * 100 + i] a wall on node row j between node columns i
-- and i + 1; v[i * 100 + j] one on node column i between node rows j and j + 1.
local function wallSets(arts)
	local h, v = {}, {}
	for _, item in arts do
		local art, i0, j0 = item[1], item[2], item[3]
		local rows = (#art - 1) // 2
		local cols = (#art[1] + 2) // 3 - 1
		for j = 0, rows do
			for c = 0, cols - 1 do
				if string.sub(art[2 * j + 1], 3 * c + 2, 3 * c + 2) == "-" then
					h[(j0 + j) * 100 + i0 + c] = true
				end
			end
		end
		for r = 0, rows - 1 do
			for i = 0, cols do
				if string.sub(art[2 * r + 2], 3 * i + 1, 3 * i + 1) == "|" then
					v[(i0 + i) * 100 + j0 + r] = true
				end
			end
		end
	end
	return h, v
end

local COLS, ROWS = 18, 14

-- The rock of the walls changes from ward to ward (the zone's own is Basalt, left as it is).
local WALL_ROCK = {
	{ false, "Slate", false },
	{ "Limestone", false, "Slate" },
	{ "Slate", "Limestone", false },
}
local function rockAt(x, z)
	local col = if x < -120 then 1 elseif x < 120 then 2 else 3
	local row = if z < 212 then 1 elseif z < 412 then 2 else 3
	return WALL_ROCK[row][col]
end

-- Replaces the roof markers in `list` with Area roofs. `arts` are the pictures whose walls hold
-- the roof up ({ picture, node column, node row } each); the list's own coordinates start at
-- (ox, oz) in the zone.
local function fit(list, arts, ox, oz)
	local h, v = wallSets(arts)
	local function supported(c, r)
		local n = 0
		n += if h[r * 100 + c] then 1 else 0
		n += if h[(r + 1) * 100 + c] then 1 else 0
		n += if c == 0 or v[c * 100 + r] then 1 else 0
		n += if c == COLS - 1 or v[(c + 1) * 100 + r] then 1 else 0
		return n >= 2
	end
	local roofed = {}
	local out = {}
	for _, item in list do
		if item.Kind ~= "RoofRun" then
			if item.Kind == "Wall" then
				item.Material = rockAt(ox + item.Path[1][1], oz + item.Path[1][2]) or nil
			end
			table.insert(out, item)
			continue
		end
		local run = {}
		local function cell(x, z)
			local c = math.floor((ox + x - X0) / PITCH)
			local r = math.floor((oz + z - Z0) / PITCH)
			local last = run[#run]
			if not last or last[1] ~= c or last[2] ~= r then
				table.insert(run, { c, r })
			end
		end
		local path = item.Path
		cell(path[1][1], path[1][2])
		for k = 2, #path do
			local a, b = path[k - 1], path[k]
			local steps = math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2])) // PITCH
			for s = 1, steps do
				cell(a[1] + (b[1] - a[1]) * s // steps, a[2] + (b[2] - a[2]) * s // steps)
			end
		end
		for k, c in run do
			local shaft = if #run == 3 then k == 2 else (#run > 3 and k % 3 == 0)
			if
				not shaft
				and c[1] >= 0
				and c[1] < COLS
				and c[2] >= 0
				and c[2] < ROWS
				and supported(c[1], c[2])
			then
				roofed[c[2] * 100 + c[1]] = true
			end
		end
	end
	-- Rows of roofed cells, joined down into rectangles of equal width.
	local open = {}
	for r = 0, ROWS do
		local now = {}
		local c = 0
		while c < COLS do
			if roofed[r * 100 + c] then
				local last = c
				while last + 1 < COLS and roofed[r * 100 + last + 1] do
					last += 1
				end
				now[c * 100 + last] = true
				c = last + 1
			else
				c += 1
			end
		end
		for key, first in open do
			if not now[key] then
				local c0, c1 = key // 100, key % 100
				local x0, x1 = X0 + PITCH * c0 - ox, X0 + PITCH * (c1 + 1) - ox
				local z0, z1 = Z0 + PITCH * first - oz, Z0 + PITCH * r - oz
				table.insert(out, {
					Kind = "Roof",
					Area = { { x0, z0 }, { x1, z0 }, { x1, z1 }, { x0, z1 } },
					Clearance = 22,
					Thickness = 8,
					Material = "Slate",
				})
				open[key] = nil
			end
		end
		for key in now do
			if not open[key] then
				open[key] = r
			end
		end
	end
	return out, roofed
end

local roofedOf = {} -- each crossing's roofed cells (row * 100 + column), for the dangers
frame.Primitives = fit(frame.Primitives, { { FRAME, 0, 0 } }, 0, 0)
for index, crossing in frame.Crossings do
	local art = ({ CROSSING1, CROSSING2, CROSSING3, CROSSING4, CROSSING5 })[index]
	crossing.Primitives, roofedOf[crossing] =
		fit(crossing.Primitives, { { FRAME, 0, 0 }, { art, 0, 0 } }, 0, 0)
end
for _, slot in frame.Slots do
	local i0, j0 = (slot.At[1] - X0) // PITCH, (slot.At[2] - Z0) // PITCH
	for _, room in slot.Rooms do
		room.Primitives =
			fit(room.Primitives, { { FRAME, 0, 0 }, { room.Art, i0, j0 } }, slot.At[1], slot.At[2])
		room.Art = nil
	end
end

-- Dressing: decor, dangers and tells -----------------------------------------------------------

-- Ground: patches of mud and drowned silt over the floor (the same each tide), and each ward
-- its own look. Props stand on open ground only, so walls and roofs clear them away.
local function patches()
	local list = {}
	for c = 0, COLS - 1 do
		for r = 0, ROWS - 1 do
			local h = (c * 7 + r * 13 + c * r * 3) % 11
			local material = if h == 0 or h == 1 then "Mud" elseif h == 2 then "Limestone" else nil
			if material then
				local x, z = X0 + PITCH * c + PITCH // 2, Z0 + PITCH * r + PITCH // 2
				table.insert(list, {
					Kind = "Paint",
					Area = { { x - 16, z - 16 }, { x + 16, z - 16 }, { x + 16, z + 16 }, { x - 16, z + 16 } },
					Material = material,
					Rough = 6,
				})
			end
		end
	end
	return list
end

-- The nine wards (by the long walls): what lies in each, as { kind, count, scale }.
local THEMES = {
	{
		{ { "Kelp", 24 }, { "Weed", 12 }, { "Starfish", 6 } }, -- a kelp forest
		{ { "WreckRibs", 3, 1.2 }, { "Timber", 8 }, { "Chain", 5 }, { "Crate", 3 }, { "Anchor", 1 } }, -- a wreck yard
		{ { "Bones", 4, 1.4 }, { "Pebbles", 12 }, { "DeadCoral", 6 } }, -- a bone field
	},
	{
		{ { "DeadCoral", 16 }, { "Urchins", 8 }, { "Starfish", 5 } }, -- coral gardens
		{ { "WreckRibs", 2, 1.5 }, { "Timber", 6 }, { "Crate", 3 }, { "Pebbles", 10 } }, -- the halls
		{ { "Kelp", 20 }, { "Weed", 10 }, { "Urchins", 4 } }, -- weed beds
	},
	{
		{ { "Anchor", 2 }, { "Chain", 8 }, { "Timber", 6 }, { "Urchins", 5 } }, -- an anchorage
		{ { "Kelp", 16 }, { "DeadCoral", 8 }, { "Bones", 3 } }, -- a sunken grove
		{ { "WreckRibs", 2, 1.3 }, { "Bones", 5, 1.2 }, { "Pebbles", 10 } }, -- a graveyard
	},
}
frame.Decor = {}
for row, wards in THEMES do
	for col, items in wards do
		local x0, x1 = -360 + 240 * (col - 1) + 8, -360 + 240 * col - 8
		local z0 = ({ 12, 212, 412 })[row] + 8
		local z1 = ({ 212, 412, 596 })[row] - 8
		for _, item in items do
			table.insert(frame.Decor, scatter(item[1], x0, z0, x1, z1, item[2], item[3]))
		end
	end
end
-- Barnacles crust the tops of the long walls.
for j = 1, ROWS do
	local z = Z0 + PITCH * j
	table.insert(frame.Decor, {
		Kind = "Barnacles",
		Path = { { -340, z }, { 340, z } },
		Count = 22,
	})
end
for _, item in patches() do
	table.insert(frame.Primitives, item)
end

-- Each crossing's way in (its first stretch from the top edge) has its own landmark, so a
-- regular knows which crossing rolled before committing: 1 an anchor and chain, 2 a hull's
-- ribs, 3 an arch of bones, 4 a pair of lanterns, 5 dead coral and a smashed crate.
crossing1.Decor = {
	prop("Anchor", -244, 30, 1.2, 20),
	prop("Chain", -278, 40, 1.2, 80),
	scatter("Kelp", -282, 14, -238, 50, 3),
}
crossing2.Decor = {
	prop("WreckRibs", 238, 30, 1.3, 90),
	prop("WreckRibs", 282, 36, 1.1, 90),
	prop("Timber", 262, 48, 1, 30),
}
crossing3.Decor = {
	prop("Bones", 260, 22, 1.8, 0),
	prop("Bones", 260, 44, 1.5, 0),
	scatter("Pebbles", 240, 14, 282, 50, 4),
}
crossing4.Decor = {
	prop("LanternPost", -244, 20),
	prop("LanternPost", -276, 20),
	prop("Chain", -260, 44, 1, 90),
}
crossing5.Decor = {
	scatter("DeadCoral", 240, 14, 282, 50, 4, 1.2),
	prop("Crate", 270, 40, 1, 20),
	scatter("Urchins", 240, 14, 282, 50, 2),
}

-- Dangers. Each is where a regular can learn it: the same spot in its crossing (or room), with
-- its tell, and never the only way through without a safe moment.
--   Sink      in the lane that leads to a dead end's loot, on dark mud: cross it moving, don't stop.
--   Rockfall  in the roofed passages along the route, in the middle of the lane (the lane is
--             wider than its reach), on a floor of old rubble; it trickles dust first.
--   Undertow  along every flooding channel, while the sea covers it (foam streams along it).
--   Gloom     drifting back and forth along a straight gallery of the route, with lanterns at
--             its ends and a trail of glowing weed and shells to wait in or follow through.
local function sinks(def, spots)
	def.Hazards = def.Hazards or {}
	def.Decor = def.Decor or {}
	for _, spot in spots do
		local x, z = spot[1], spot[2]
		table.insert(def.Hazards, { Type = "Sink", At = { x, z }, Radius = 12 })
		table.insert(
			def.Primitives,
			mud({ { x - 14, z - 14 }, { x + 14, z - 14 }, { x + 14, z + 14 }, { x - 14, z + 14 } })
		)
		table.insert(def.Decor, prop("Bones", x + 10, z - 10, 0.8, 40))
		table.insert(def.Decor, prop("Starfish", x - 8, z + 9))
	end
end

-- A Gloom along the straight gallery from a to b (lane centre), and its lit trail.
local function gloom(def, a, b)
	def.Hazards = def.Hazards or {}
	def.Decor = def.Decor or {}
	table.insert(def.Hazards, { Type = "Gloom", Path = { a, b } })
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local len = math.sqrt(dx * dx + dz * dz)
	local ux, uz = dx / len, dz / len
	local function at(t, side)
		return a[1] + ux * t - uz * side, a[2] + uz * t + ux * side
	end
	local x, z = at(-6, 9)
	table.insert(def.Decor, prop("LanternPost", x, z))
	x, z = at(len + 6, -9)
	table.insert(def.Decor, prop("LanternPost", x, z))
	local k = 0
	for t = 30, len - 20, 34 do
		k += 1
		x, z = at(t, if k % 2 == 0 then 9 else -9)
		table.insert(def.Decor, prop(if k % 2 == 0 then "GlowShells" else "GlowWeed", x, z))
	end
end

-- A rock falls in the roofed cells along the cart route: every third one, from the second.
local function rockfalls(def, count)
	local roofed = roofedOf[def]
	local ramp
	for _, item in def.Primitives do
		if item.Kind == "Ramp" then
			ramp = item
		end
	end
	local seen, found = {}, {}
	local function visit(x, z)
		local c, r = (x - X0) // PITCH, (z - Z0) // PITCH
		local key = r * 100 + c
		if roofed[key] and not seen[key] then
			seen[key] = true
			table.insert(found, { X0 + PITCH * c + PITCH // 2, Z0 + PITCH * r + PITCH // 2 })
		end
	end
	for k = 1, #ramp.Path - 1 do
		local a, b = ramp.Path[k], ramp.Path[k + 1]
		local steps = math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2])) // PITCH
		for s = 0, steps do
			visit(
				a[1] + (b[1] - a[1]) * s // math.max(steps, 1),
				a[2] + (b[2] - a[2]) * s // math.max(steps, 1)
			)
		end
	end
	def.Hazards = def.Hazards or {}
	def.Decor = def.Decor or {}
	local placed = 0
	for k = 2, #found, 3 do
		if placed >= count then
			break
		end
		placed += 1
		local spot = found[k]
		table.insert(def.Hazards, { Type = "Rockfall", At = spot })
		table.insert(def.Decor, scatter("Pebbles", spot[1] - 12, spot[2] - 12, spot[1] + 12, spot[2] + 12, 5))
		table.insert(def.Decor, prop("Timber", spot[1] + 8, spot[2] - 6, 0.8, 60))
	end
end

-- Undertow along every channel.
local function undertows(def)
	def.Hazards = def.Hazards or {}
	for _, item in def.Primitives do
		if item.Kind == "Channel" then
			table.insert(def.Hazards, { Type = "Undertow", Path = item.Path, Width = item.Width })
		end
	end
end

-- Spike pits: the best find of each crossing lies on a covered pit. Its false floor's cracks
-- are the only tell: a regular learns to look before stepping on the prize.
local function pits(def)
	def.Hazards = def.Hazards or {}
	local best
	for _, find in def.Loot or {} do
		if not best or (find.Weight or 1) > (best.Weight or 1) then
			best = find
		end
	end
	if best then
		table.insert(def.Hazards, { Type = "Pit", At = best.At, Radius = 4, Covered = true })
	end
end

for _, crossing in { crossing1, crossing2, crossing3, crossing4, crossing5 } do
	pits(crossing)
end

sinks(crossing1, { { -60, 552 }, { 100, 472 } })
gloom(crossing1, { -220, 252 }, { -220, 412 })
gloom(crossing1, { 100, 212 }, { 100, 372 })
rockfalls(crossing1, 3)
undertows(crossing1)

sinks(crossing2, { { -180, 232 }, { -260, 232 } })
gloom(crossing2, { -80, 192 }, { 80, 192 })
gloom(crossing2, { -100, 372 }, { -100, 532 })
rockfalls(crossing2, 3)
undertows(crossing2)

sinks(crossing3, { { -340, 552 }, { 140, 152 } })
gloom(crossing3, { 80, 192 }, { -80, 192 })
gloom(crossing3, { -80, 552 }, { 80, 552 })
rockfalls(crossing3, 3)
undertows(crossing3)

sinks(crossing4, { { -340, 272 }, { 220, 152 } })
gloom(crossing4, { -80, 32 }, { 80, 32 })
gloom(crossing4, { -220, 252 }, { -220, 412 })
rockfalls(crossing4, 3)
undertows(crossing4)

sinks(crossing5, { { 140, 472 }, { 300, 352 } })
gloom(crossing5, { 80, 32 }, { -80, 32 })
gloom(crossing5, { -80, 392 }, { 80, 392 })
rockfalls(crossing5, 3)
undertows(crossing5)

return frame
