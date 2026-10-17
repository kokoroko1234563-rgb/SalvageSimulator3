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

local function wall(path)
	return { Kind = "Wall", Path = path, Height = 24, Width = 12 }
end

-- A pile of rubble filling a doorway: a scramble on foot, too steep for a cart.
local function rubble(path)
	return { Kind = "Ridge", Path = path, Height = 4, Width = 20 }
end

-- Rock overhead along a lane: a marker, turned into exact rectangles by `fit` once the walls
-- are known (see below). `path` runs through the centres of the lane cells it covers.
local function roof(path)
	return { Kind = "RoofRun", Path = path }
end

-- A pool: low ground that holds the sea from early in the flood.
local function pool(x, z, radius)
	return { Kind = "Hollow", At = { x, z }, Radius = radius or 12, Depth = 3 }
end

-- A sunk lane: floods before the ground round it.
local function lane(path)
	return { Kind = "Channel", Path = path, Depth = 2, Width = 12 }
end

-- Rock over one lane cell of a side room (a marker, like `roof`).
local function cellRoof(x, z)
	return { Kind = "RoofRun", Path = { { x, z } } }
end

-- A boulder.
local function boulder(x, z, radius, height)
	return { Kind = "Mound", At = { x, z }, Radius = radius, Height = height, Rock = true }
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
-- Walls run between nodes (with a point on each node on the way) and stop 6 studs short of the
-- ends; a round post stands on every node
-- a wall touches, so the walls meet exactly (a wall's face is 6 studs off its line) with no
-- crack where two meet end to end. On the picture's left and right edges the posts also close
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
			table.insert(list, wall({ { x0 + PITCH * i, z0 + PITCH * j } }))
		end
	end
	local function add(char, path)
		table.insert(list, if char == "-" or char == "|" then wall(path) else rubble(path))
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
				local path = { { x0 + PITCH * c + (if c == 0 and edgeL then 0 else 6), z } }
				for i = c + 1, last do
					table.insert(path, { x0 + PITCH * i, z })
				end
				table.insert(
					path,
					{ x0 + PITCH * (last + 1) - (if last + 1 == w and edgeR then 0 else 6), z }
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
				local path = { { x, z0 + PITCH * r + 6 } }
				for j = r + 1, last do
					table.insert(path, { x, z0 + PITCH * j })
				end
				table.insert(path, { x, z0 + PITCH * (last + 1) - 6 })
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
					mud({ { 44, 4 }, { 76, 4 }, { 76, 36 }, { 44, 36 } }),
					mud({ { 44, 84 }, { 76, 84 }, { 76, 116 }, { 44, 116 } }),
				},
				Loot = {
					loot(100, 20, 6),
					loot(100, 100, 5),
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
				},
				Loot = {
					loot(100, 20, 6),
					loot(140, 100, 4),
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
				},
				Loot = {
					loot(20, 100, 6),
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
	return out
end

frame.Primitives = fit(frame.Primitives, { { FRAME, 0, 0 } }, 0, 0)
for index, crossing in frame.Crossings do
	local art = ({ CROSSING1, CROSSING2, CROSSING3, CROSSING4, CROSSING5 })[index]
	crossing.Primitives = fit(crossing.Primitives, { { FRAME, 0, 0 }, { art, 0, 0 } }, 0, 0)
end
for _, slot in frame.Slots do
	local i0, j0 = (slot.At[1] - X0) // PITCH, (slot.At[2] - Z0) // PITCH
	for _, room in slot.Rooms do
		room.Primitives =
			fit(room.Primitives, { { FRAME, 0, 0 }, { room.Art, i0, j0 } }, slot.At[1], slot.At[2])
		room.Art = nil
	end
end

return frame
