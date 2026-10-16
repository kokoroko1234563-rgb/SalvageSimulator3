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
local X0, Z0 = -360, 8 -- the first node of the picture, in zone coordinates

local function wall(path)
	return { Kind = "Wall", Path = path, Height = 24, Width = 12 }
end

-- A pile of rubble filling a doorway: a scramble on foot, too steep for a cart.
local function rubble(path)
	return { Kind = "Ridge", Path = path, Height = 4, Width = 20 }
end

-- Rock overhead, resting on the walls either side of a lane.
local function roof(path, width)
	return { Kind = "Roof", Path = path, Width = width or 52, Clearance = 22, Thickness = 8 }
end

-- A pool: low ground that holds the sea from early in the flood.
local function pool(x, z, radius)
	return { Kind = "Hollow", At = { x, z }, Radius = radius or 12, Depth = 3 }
end

-- A sunk lane: floods before the ground round it.
local function lane(path)
	return { Kind = "Channel", Path = path, Depth = 2, Width = 12 }
end

-- Rock over one lane cell of a side room.
local function cellRoof(x, z)
	return { Kind = "Roof", At = { x, z }, Radius = 26, Clearance = 22, Thickness = 8 }
end

-- A boulder.
local function boulder(x, z, radius, height)
	return { Kind = "Mound", At = { x, z }, Radius = radius, Height = height, Rock = true }
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

local FRAME = {
	"+--+--+  +--+--+--+  +--+--+  +--+--+  +--+--+  +--+--+",
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
	"+--+  +--+--+  +--+--+  +--+--+  +--+--+  +--+--+  +--+",
}

local frame = {
	Name = "The Drowned Reach",
	Primitives = merge(maze(FRAME, X0, Z0, true, true), {
		roof({ { -100, 228 }, { -100, 348 }, { 100, 348 }, { 100, 228 } }, 52),
		roof({ { -100, 388 }, { -100, 548 }, { 100, 548 }, { 100, 388 } }, 52),
		pool(-60, 348),
		pool(60, 348),
		pool(-100, 268),
		pool(100, 268),
		pool(-60, 548),
		pool(60, 548),
		pool(-100, 468),
		pool(100, 468),
	}),
	Loot = {
		loot(-340, 28, 1),
		loot(340, 28, 1),
		loot(-220, 188, 2),
		loot(220, 188, 2),
		loot(-340, 348, 2),
		loot(-100, 268, 2),
		loot(100, 268, 2),
		loot(-140, 388, 2),
		loot(140, 388, 2),
		loot(-340, 548, 2),
		loot(340, 548, 2),
		loot(-20, 548, 3),
	},
}

local CROSSING1 = {
	"+  +  +  +  +  +  +--+  +  +--+  +  +--+  +  +--+  +  +",
	"                                          |     |      ",
	"+  +  +  +--+--+  +  +--+  +  +  +  +  +--+  +  +  +  +",
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
	"      |  |  !                                          ",
	"+--+  +  +  +  +--+  +  +  +  +  +  +  +--+--+  +  +  +",
	"      |  |  !  |                          |            ",
	"+  +--+  +  +  +  +--+  +  +  +  +  +--+  +  +  +  +  +",
	"         !  |  |                 |  |     |            ",
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
	"+  +  +  +  +--+  +  +  +  +  +--+  +  +--+  +  +  +  +",
}

local crossing1 = {
	Name = "West stair",
	Primitives = merge(maze(CROSSING1, X0, Z0, true, true), {
		roof({ { -60, 188 }, { 60, 188 } }, 52),
		roof({ { 100, 228 }, { 100, 348 } }, 52),
		roof({ { -60, 28 }, { 60, 28 } }, 52),
		roof({ { -20, 548 }, { 60, 548 } }, 52),
		roof({ { 140, 548 }, { 260, 548 } }, 52),
		roof({ { -100, 348 }, { -20, 348 } }, 52),
		roof({ { 140, 108 }, { 300, 108 } }, 52),
		lane({ { -220, 548 }, { -180, 548 } }),
		lane({ { -100, 228 }, { -100, 268 } }),
		lane({ { 300, 348 }, { 340, 348 } }),
		lane({ { -340, 28 }, { -300, 28 } }),
		lane({ { 180, 148 }, { 220, 148 } }),
		pool(140, 68),
		pool(-260, 308),
		pool(-60, 148),
		pool(-140, 228),
		pool(-340, 28),
		pool(-300, 268),
		pool(-180, 508),
		pool(300, 348),
		{
			Kind = "Ramp",
			Path = {
				{ -260, 0 },
				{ -260, 28 },
				{ -140, 28 },
				{ -140, 148 },
				{ -220, 148 },
				{ -220, 188 },
				{ -300, 188 },
				{ -300, 308 },
				{ -340, 308 },
				{ -340, 348 },
				{ -260, 348 },
				{ -260, 228 },
				{ -220, 228 },
				{ -220, 428 },
				{ -180, 428 },
				{ -180, 388 },
				{ -140, 388 },
				{ -140, 308 },
				{ -100, 308 },
				{ -100, 188 },
				{ 100, 188 },
				{ 100, 388 },
				{ -100, 388 },
				{ -100, 508 },
				{ -180, 508 },
				{ -180, 468 },
				{ -220, 468 },
				{ -220, 508 },
				{ -260, 508 },
				{ -260, 548 },
				{ -300, 548 },
				{ -300, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(340, 548, 5),
		loot(-100, 548, 4),
		loot(100, 428, 3),
		loot(140, 428, 3),
		loot(220, 308, 2),
		loot(340, 348, 2),
	},
}

local CROSSING2 = {
	"+  +  +--+  +  +  +--+  +  +--+  +  +--+  +  +  +  +  +",
	"            |        |                          |      ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +--+  +--+  +  +",
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
	"+  +--+  +  +--+  +  +--+  +  +  +  +  +--+  +  +--+  +",
}

local crossing2 = {
	Name = "Hall gallery",
	Primitives = merge(maze(CROSSING2, X0, Z0, true, true), {
		roof({ { -60, 548 }, { 20, 548 } }, 52),
		roof({ { -60, 188 }, { 60, 188 } }, 52),
		roof({ { -20, 28 }, { 60, 28 } }, 52),
		roof({ { -60, 348 }, { 60, 348 } }, 52),
		roof({ { -100, 388 }, { -100, 508 } }, 52),
		roof({ { 260, 548 }, { 340, 548 } }, 52),
		roof({ { -60, 388 }, { 60, 388 } }, 52),
		roof({ { -340, 28 }, { -260, 28 } }, 52),
		roof({ { 340, 68 }, { 340, 188 } }, 52),
		roof({ { -300, 548 }, { -220, 548 } }, 52),
		roof({ { -140, 388 }, { -140, 468 } }, 52),
		lane({ { 140, 388 }, { 140, 428 } }),
		lane({ { -100, 228 }, { -100, 268 } }),
		lane({ { 220, 188 }, { 260, 188 } }),
		lane({ { 300, 348 }, { 340, 348 } }),
		lane({ { -220, 348 }, { -180, 348 } }),
		pool(-340, 548),
		pool(140, 228),
		pool(260, 28),
		pool(180, 308),
		pool(220, 68),
		pool(220, 28),
		pool(-100, 308),
		pool(-180, 188),
		{
			Kind = "Ramp",
			Path = {
				{ 260, 0 },
				{ 260, 28 },
				{ 140, 28 },
				{ 140, 108 },
				{ 100, 108 },
				{ 100, 28 },
				{ -60, 28 },
				{ -60, 148 },
				{ -100, 148 },
				{ -100, 188 },
				{ 100, 188 },
				{ 100, 228 },
				{ 140, 228 },
				{ 140, 308 },
				{ 220, 308 },
				{ 220, 348 },
				{ 140, 348 },
				{ 140, 468 },
				{ 180, 468 },
				{ 180, 548 },
				{ 100, 548 },
				{ 100, 348 },
				{ -100, 348 },
				{ -100, 548 },
				{ 60, 548 },
				{ 60, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(-220, 428, 5),
		loot(-140, 228, 4),
		loot(-260, 268, 3),
		loot(-140, 548, 3),
		loot(-100, 228, 2),
		loot(-340, 308, 2),
	},
}

local CROSSING3 = {
	"+  +  +--+  +  +  +--+  +  +--+  +  +--+  +  +  +  +  +",
	"                                             |     |   ",
	"+  +  +  +  +--+  +--+  +  +  +  +  +  +--+--+==+  +  +",
	"            |                          |        |  |   ",
	"+  +  +  +  +  +--+--+  +  +  +  +  +  +  +--+  +  +  +",
	"            |        |                 |  |     !  |   ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +==+  +  +",
	"               |                       |  |  |         ",
	"+  +  +  +--+--+  +--+--+  +  +  +--+  +  +  +--+  +  +",
	"                  |                    |  |        |   ",
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
	"+  +--+  +  +--+  +  +--+  +  +--+  +  +--+  +  +  +  +",
}

local crossing3 = {
	Name = "East switchbacks",
	Primitives = merge(maze(CROSSING3, X0, Z0, true, true), {
		roof({ { -100, 428 }, { -100, 508 } }, 52),
		roof({ { -60, 188 }, { 60, 188 } }, 52),
		roof({ { 100, 388 }, { 100, 508 } }, 52),
		roof({ { -60, 548 }, { 60, 548 } }, 52),
		roof({ { 180, 108 }, { 180, 188 } }, 52),
		roof({ { -340, 28 }, { -260, 28 } }, 52),
		roof({ { -20, 28 }, { 60, 28 } }, 52),
		roof({ { -220, 308 }, { -220, 388 } }, 52),
		roof({ { -260, 548 }, { -180, 548 } }, 52),
		roof({ { 340, 28 }, { 340, 108 } }, 52),
		roof({ { -260, 188 }, { -180, 188 } }, 52),
		lane({ { -100, 228 }, { -100, 268 } }),
		lane({ { 300, 348 }, { 340, 348 } }),
		lane({ { -60, 348 }, { -20, 348 } }),
		lane({ { -260, 228 }, { -220, 228 } }),
		lane({ { 100, 268 }, { 100, 308 } }),
		pool(140, 228),
		pool(-340, 348),
		pool(-180, 68),
		pool(-340, 228),
		pool(-340, 308),
		pool(300, 548),
		pool(-180, 388),
		pool(300, 348),
		{
			Kind = "Ramp",
			Path = {
				{ 260, 0 },
				{ 260, 28 },
				{ 300, 28 },
				{ 300, 188 },
				{ 220, 188 },
				{ 220, 108 },
				{ 260, 108 },
				{ 260, 68 },
				{ 180, 68 },
				{ 180, 228 },
				{ 100, 228 },
				{ 100, 188 },
				{ -100, 188 },
				{ -100, 348 },
				{ 20, 348 },
				{ 20, 388 },
				{ -100, 388 },
				{ -100, 548 },
				{ 100, 548 },
				{ 100, 348 },
				{ 140, 348 },
				{ 140, 388 },
				{ 180, 388 },
				{ 180, 428 },
				{ 140, 428 },
				{ 140, 468 },
				{ 220, 468 },
				{ 220, 548 },
				{ 300, 548 },
				{ 300, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(-140, 508, 5),
		loot(-340, 508, 4),
		loot(220, 28, 3),
		loot(140, 188, 3),
		loot(-220, 468, 2),
		loot(100, 148, 2),
	},
}

local CROSSING4 = {
	"+  +  +  +  +  +  +--+  +  +--+  +  +--+  +  +--+  +  +",
	"            |                                |         ",
	"+  +  +  +  +  +--+  +--+  +  +  +  +--+  +  +  +--+  +",
	"            |        |                    |     |  |   ",
	"+  +  +  +  +  +  +--+  +  +  +  +  +  +  +--+--+  +  +",
	"               |                       |  |     |      ",
	"+  +  +  +--+--+  +  +  +  +  +  +--+  +  +  +  +  +--+",
	"               |     |                 |  |  |  |  |   ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"                  |  !                 |  |  |         ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"   |     |                                |            ",
	"+  +--+  +  +--+  +  +  +  +  +  +--+--+--+  +  +  +  +",
	"   |     |  |  |                                       ",
	"+  +  +--+  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +",
	"   |     |  |  |                       |               ",
	"+  +--+  +  +  +  +--+  +  +  +  +  +--+  +  +  +  +  +",
	"         |  !              |           |  |            ",
	"+  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +  +  +  +",
	"            |                 |           |            ",
	"+  +  +  +  +--+==+  +  +  +  +  +  +--+  +  +  +  +  +",
	"                                       |  |            ",
	"+  +  +  +--+--+--+--+  +  +  +  +  +  +  +  +  +  +  +",
	"                                                       ",
	"+  +  +  +  +  +--+  +  +  +  +  +  +--+  +  +  +  +  +",
	"            |  |                       |  |            ",
	"+  +--+--+--+  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"            |                          |  |            ",
	"+  +  +  +  +--+  +  +  +  +  +--+  +  +  +  +  +--+  +",
}

local crossing4 = {
	Name = "Long cross",
	Primitives = merge(maze(CROSSING4, X0, Z0, true, true), {
		roof({ { -60, 28 }, { 60, 28 } }, 52),
		roof({ { -20, 188 }, { 60, 188 } }, 52),
		roof({ { 180, 108 }, { 180, 188 } }, 52),
		roof({ { -340, 228 }, { -340, 308 } }, 52),
		roof({ { -20, 548 }, { 60, 548 } }, 52),
		roof({ { 260, 548 }, { 340, 548 } }, 52),
		lane({ { 140, 148 }, { 140, 188 } }),
		lane({ { 300, 348 }, { 340, 348 } }),
		lane({ { 300, 388 }, { 340, 388 } }),
		lane({ { -60, 388 }, { -20, 388 } }),
		lane({ { -340, 28 }, { -300, 28 } }),
		pool(-100, 108),
		pool(-180, 428),
		pool(20, 388),
		pool(-140, 428),
		pool(100, 68),
		pool(-180, 508),
		pool(-60, 188),
		pool(340, 188),
		{
			Kind = "Ramp",
			Path = {
				{ -260, 0 },
				{ -260, 28 },
				{ -220, 28 },
				{ -220, 108 },
				{ -180, 108 },
				{ -180, 68 },
				{ -100, 68 },
				{ -100, 28 },
				{ 100, 28 },
				{ 100, 108 },
				{ 140, 108 },
				{ 140, 68 },
				{ 180, 68 },
				{ 180, 228 },
				{ 100, 228 },
				{ 100, 188 },
				{ -60, 188 },
				{ -60, 108 },
				{ -100, 108 },
				{ -100, 308 },
				{ -140, 308 },
				{ -140, 228 },
				{ -220, 228 },
				{ -220, 428 },
				{ -100, 428 },
				{ -100, 388 },
				{ 20, 388 },
				{ 20, 348 },
				{ 140, 348 },
				{ 140, 388 },
				{ 180, 388 },
				{ 180, 548 },
				{ 180, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(-220, 548, 5),
		loot(-340, 228, 4),
		loot(220, 188, 3),
		loot(-140, 468, 3),
		loot(340, 148, 2),
		loot(-100, 468, 2),
	},
}

local CROSSING5 = {
	"+  +  +--+  +  +  +--+  +  +--+  +  +--+  +  +  +  +  +",
	"                                             |  |      ",
	"+  +  +  +--+--+  +  +--+  +  +  +  +  +--+--+  +  +  +",
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
	"               !                       |               ",
	"+  +  +  +  +  +  +--+  +  +  +  +  +  +--+  +  +  +  +",
	"            |  !                                       ",
	"+  +  +  +--+  +  +  +  +  +  +  +  +--+--+  +  +  +  +",
	"               |                    |     |            ",
	"+  +  +  +  +--+  +  +  +  +  +  +  +  +--+  +  +  +  +",
	"         |     |  |                    |               ",
	"+  +--+  +  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +",
	"      |     |                 |     |                  ",
	"+  +--+  +  +--+  +  +--+  +  +  +  +  +--+  +  +--+  +",
}

local crossing5 = {
	Name = "Backtrack",
	Primitives = merge(maze(CROSSING5, X0, Z0, true, true), {
		roof({ { 100, 428 }, { 100, 508 } }, 52),
		roof({ { -60, 28 }, { 60, 28 } }, 52),
		roof({ { -60, 388 }, { 60, 388 } }, 52),
		roof({ { -60, 548 }, { 20, 548 } }, 52),
		roof({ { -60, 348 }, { 60, 348 } }, 52),
		roof({ { -340, 188 }, { -260, 188 } }, 52),
		roof({ { 220, 548 }, { 340, 548 } }, 52),
		roof({ { -20, 188 }, { 60, 188 } }, 52),
		roof({ { -340, 28 }, { -180, 28 } }, 52),
		lane({ { -100, 228 }, { -100, 268 } }),
		lane({ { -140, 468 }, { -140, 508 } }),
		lane({ { 300, 388 }, { 340, 388 } }),
		lane({ { -340, 228 }, { -340, 268 } }),
		lane({ { -100, 468 }, { -100, 508 } }),
		pool(-220, 548),
		pool(-60, 188),
		pool(180, 308),
		pool(260, 388),
		pool(-300, 308),
		pool(-180, 508),
		pool(220, 268),
		pool(100, 308),
		{
			Kind = "Ramp",
			Path = {
				{ 260, 0 },
				{ 260, 28 },
				{ 260, 188 },
				{ 220, 188 },
				{ 220, 148 },
				{ 180, 148 },
				{ 180, 108 },
				{ 100, 108 },
				{ 100, 28 },
				{ -100, 28 },
				{ -100, 68 },
				{ -220, 68 },
				{ -220, 188 },
				{ -180, 188 },
				{ -180, 228 },
				{ -300, 228 },
				{ -300, 348 },
				{ -220, 348 },
				{ -220, 388 },
				{ -180, 388 },
				{ -180, 468 },
				{ -220, 468 },
				{ -220, 508 },
				{ -180, 508 },
				{ -180, 548 },
				{ -140, 548 },
				{ -140, 348 },
				{ -180, 348 },
				{ -180, 308 },
				{ -100, 308 },
				{ -100, 388 },
				{ 100, 388 },
				{ 100, 548 },
				{ 60, 548 },
				{ 60, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(140, 148, 5),
		loot(180, 468, 4),
		loot(340, 548, 3),
		loot(180, 348, 3),
		loot(340, 348, 2),
		loot(340, 388, 2),
	},
}

frame.Crossings = { crossing1, crossing2, crossing3, crossing4, crossing5 }

local SLOT1ROOM1 = {
	"+  +  +  +",
	"          ",
	"+  +--+--+",
	"   |      ",
	"+  +  +--+",
	"          ",
	"+  +  +  +",
}

local SLOT1ROOM2 = {
	"+  +  +  +",
	"   |      ",
	"+  +  +  +",
	"   |  |   ",
	"+  +  +--+",
	"          ",
	"+  +  +  +",
}

local SLOT1ROOM3 = {
	"+  +  +  +",
	"          ",
	"+  +  +  +",
	"          ",
	"+  +  +  +",
	"          ",
	"+  +  +  +",
}

local SLOT2ROOM1 = {
	"+  +  +  +",
	"          ",
	"+  +--+  +",
	"   |  |   ",
	"+  +--+  +",
	"          ",
	"+  +  +  +",
}

local SLOT2ROOM2 = {
	"+  +  +  +",
	"          ",
	"+  +  +  +",
	"          ",
	"+  +  +  +",
	"          ",
	"+  +  +  +",
}

local SLOT2ROOM3 = {
	"+  +  +  +",
	"          ",
	"+--+  +  +",
	"   |  |   ",
	"+  +  +  +",
	"      |   ",
	"+  +  +  +",
}

local SLOT3ROOM1 = {
	"+  +  +  +",
	"          ",
	"+  +--+  +",
	"   |      ",
	"+--+  +--+",
	"          ",
	"+  +  +  +",
}

local SLOT3ROOM2 = {
	"+  +  +  +",
	"          ",
	"+--+--+  +",
	"          ",
	"+--+--+  +",
	"          ",
	"+  +  +  +",
}

local SLOT3ROOM3 = {
	"+  +  +  +",
	"          ",
	"+  +--+  +",
	"   |  |   ",
	"+  +--+  +",
	"          ",
	"+  +  +  +",
}

local SLOT4ROOM1 = {
	"+  +  +  +  +",
	"             ",
	"+  +--+--+  +",
	"      |      ",
	"+  +  +  +--+",
	"   |  |      ",
	"+  +  +  +  +",
}

local SLOT4ROOM2 = {
	"+  +  +  +  +",
	"             ",
	"+  +  +  +  +",
	"             ",
	"+  +  +  +  +",
	"             ",
	"+  +  +  +  +",
}

local SLOT4ROOM3 = {
	"+  +  +  +  +",
	"             ",
	"+  +--+--+  +",
	"   |  |  |   ",
	"+  +--+--+  +",
	"             ",
	"+  +  +  +  +",
}

local SLOT4ROOM4 = {
	"+  +  +  +  +",
	"      |      ",
	"+  +  +  +  +",
	"   |     |   ",
	"+  +--+--+  +",
	"      |      ",
	"+  +  +  +  +",
}

local SLOT5ROOM1 = {
	"+  +  +  +",
	"          ",
	"+  +--+  +",
	"   |  |   ",
	"+  +--+  +",
	"          ",
	"+  +  +  +",
}

local SLOT5ROOM2 = {
	"+  +  +  +",
	"   |      ",
	"+  +  +  +",
	"      |   ",
	"+  +--+--+",
	"          ",
	"+  +  +  +",
}

local SLOT5ROOM3 = {
	"+  +  +  +",
	"          ",
	"+  +  +  +",
	"          ",
	"+  +  +  +",
	"          ",
	"+  +  +  +",
}

local SLOT6ROOM1 = {
	"+  +  +  +  +",
	"   |     |   ",
	"+  +  +--+  +",
	"   |         ",
	"+  +--+--+  +",
	"             ",
	"+  +  +  +  +",
}

local SLOT6ROOM2 = {
	"+  +  +  +  +",
	"      |  |   ",
	"+  +  +  +  +",
	"   |     |   ",
	"+  +--+--+  +",
	"             ",
	"+  +  +  +  +",
}

local SLOT6ROOM3 = {
	"+  +  +  +  +",
	"             ",
	"+  +  +  +  +",
	"             ",
	"+  +  +  +  +",
	"             ",
	"+  +  +  +  +",
}

local SLOT6ROOM4 = {
	"+  +  +  +  +",
	"             ",
	"+  +--+--+  +",
	"   |  |  |   ",
	"+  +--+--+  +",
	"             ",
	"+  +  +  +  +",
}

local SLOT7ROOM1 = {
	"+  +  +  +",
	"   |      ",
	"+  +--+  +",
	"      |   ",
	"+  +  +  +",
	"   |      ",
	"+  +  +  +",
}

local SLOT7ROOM2 = {
	"+  +  +  +",
	"   |  |   ",
	"+  +  +  +",
	"   |      ",
	"+  +--+  +",
	"          ",
	"+  +  +  +",
}

local SLOT7ROOM3 = {
	"+  +  +  +",
	"          ",
	"+  +  +  +",
	"          ",
	"+  +  +  +",
	"          ",
	"+  +  +  +",
}

frame.Slots = {
	{
		Name = "West cave",
		At = { -360, 48 },
		Size = { 120, 120 },
		Rooms = {
			{
				Name = "Dead-end cave",
				Primitives = merge(maze(SLOT1ROOM1, 0, 0, true, false), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 60),
					cellRoof(60, 100),
					cellRoof(100, 20),
					cellRoof(100, 100),
				}),
				Loot = {
					loot(100, 20, 6),
					loot(60, 20, 3),
					loot(20, 20, 2),
					loot(20, 100, 1),
				},
			},
			{
				Name = "Drowned pool",
				Primitives = merge(maze(SLOT1ROOM2, 0, 0, true, false), {
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 20),
					pool(60, 60, 13),
					pool(100, 20, 13),
					pool(20, 20, 13),
				}),
				Loot = {
					loot(20, 20, 6),
					loot(60, 60, 3),
				},
			},
			{
				Name = "Boulder scramble",
				Primitives = merge(maze(SLOT1ROOM3, 0, 0, true, false), {
					boulder(24, 63, 11, 10),
				}),
				Loot = {
					loot(20, 20, 6),
					loot(60, 100, 3),
					loot(60, 20, 2),
				},
			},
		},
	},
	{
		Name = "Gatehouse yard",
		At = { -40, 48 },
		Size = { 120, 120 },
		Rooms = {
			{
				Name = "Tunnel loop",
				Primitives = merge(maze(SLOT2ROOM1, 0, 0, false, false), {
					cellRoof(20, 20),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 100),
					cellRoof(100, 20),
					cellRoof(100, 60),
					cellRoof(100, 100),
				}),
				Loot = {
					loot(100, 60, 6),
					loot(100, 100, 3),
					loot(60, 100, 2),
				},
			},
			{
				Name = "Boulder yard",
				Primitives = merge(maze(SLOT2ROOM2, 0, 0, false, false), {
					boulder(65, 22, 12, 9),
					boulder(101, 98, 13, 10),
				}),
				Loot = {
					loot(100, 20, 6),
					loot(100, 60, 3),
					loot(60, 100, 2),
				},
			},
			{
				Name = "Gatehouse cellar",
				Primitives = merge(maze(SLOT2ROOM3, 0, 0, false, false), {
					cellRoof(20, 20),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 60),
					cellRoof(60, 100),
					cellRoof(100, 20),
					cellRoof(100, 60),
					cellRoof(100, 100),
				}),
				Loot = {
					loot(100, 100, 6),
					loot(100, 60, 3),
					loot(20, 20, 2),
					loot(60, 20, 1),
				},
			},
		},
	},
	{
		Name = "East cellar",
		At = { 240, 208 },
		Size = { 120, 120 },
		Rooms = {
			{
				Name = "Dead-end cellar",
				Primitives = merge(maze(SLOT3ROOM1, 0, 0, false, true), {
					cellRoof(20, 20),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 60),
					cellRoof(60, 100),
					cellRoof(100, 20),
					cellRoof(100, 60),
					cellRoof(100, 100),
				}),
				Loot = {
					loot(20, 100, 6),
					loot(100, 100, 3),
					loot(60, 100, 2),
					loot(100, 60, 1),
				},
			},
			{
				Name = "Flooded cellar",
				Primitives = merge(maze(SLOT3ROOM2, 0, 0, false, true), {
					cellRoof(20, 20),
					cellRoof(60, 100),
					cellRoof(100, 20),
					pool(20, 100, 13),
					pool(60, 20, 13),
					pool(100, 100, 13),
				}),
				Loot = {
					loot(20, 100, 6),
					loot(60, 20, 3),
					loot(20, 20, 4),
				},
			},
			{
				Name = "Tunnel loop",
				Primitives = merge(maze(SLOT3ROOM3, 0, 0, false, true), {
					cellRoof(20, 20),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 100),
					cellRoof(100, 20),
					cellRoof(100, 60),
					cellRoof(100, 100),
				}),
				Loot = {
					loot(100, 60, 6),
					loot(100, 100, 3),
					loot(60, 100, 2),
				},
			},
		},
	},
	{
		Name = "Drowned hall",
		At = { -80, 208 },
		Size = { 160, 120 },
		Rooms = {
			{
				Name = "Flooded hall",
				Primitives = merge(maze(SLOT4ROOM1, 0, 0, false, false), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					pool(100, 20, 13),
					pool(140, 60, 13),
					pool(60, 60, 13),
					pool(100, 100, 13),
				}),
				Loot = {
					loot(100, 100, 6),
					loot(140, 60, 3),
					loot(140, 100, 4),
				},
			},
			{
				Name = "Collapsed hall",
				Primitives = merge(maze(SLOT4ROOM2, 0, 0, false, false), {
					boulder(22, 22, 13, 8),
					boulder(57, 22, 13, 10),
					boulder(141, 96, 11, 10),
				}),
				Loot = {
					loot(140, 20, 6),
					loot(100, 20, 3),
					loot(100, 60, 2),
				},
			},
			{
				Name = "Pillar gallery",
				Primitives = merge(maze(SLOT4ROOM3, 0, 0, false, false), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(100, 20),
					cellRoof(100, 100),
					cellRoof(140, 20),
					cellRoof(140, 60),
					cellRoof(140, 100),
				}),
				Loot = {
					loot(100, 20, 6),
					loot(140, 20, 3),
					loot(20, 60, 2),
				},
			},
			{
				Name = "Dead-end vault",
				Primitives = merge(maze(SLOT4ROOM4, 0, 0, false, false), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 60),
					cellRoof(100, 20),
					cellRoof(100, 60),
					cellRoof(100, 100),
					cellRoof(140, 20),
					cellRoof(140, 60),
					cellRoof(140, 100),
				}),
				Loot = {
					loot(100, 100, 6),
					loot(140, 100, 3),
					loot(140, 60, 2),
					loot(100, 20, 1),
				},
			},
		},
	},
	{
		Name = "Low west vault",
		At = { -360, 368 },
		Size = { 120, 120 },
		Rooms = {
			{
				Name = "Tunnel loop",
				Primitives = merge(maze(SLOT5ROOM1, 0, 0, true, false), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 100),
					cellRoof(100, 20),
					cellRoof(100, 100),
				}),
				Loot = {
					loot(20, 60, 6),
					loot(20, 100, 3),
					loot(60, 100, 2),
				},
			},
			{
				Name = "Dead-end cave",
				Primitives = merge(maze(SLOT5ROOM2, 0, 0, true, false), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 60),
					cellRoof(60, 100),
					cellRoof(100, 20),
					cellRoof(100, 100),
				}),
				Loot = {
					loot(100, 100, 6),
					loot(60, 100, 3),
					loot(20, 20, 2),
					loot(20, 60, 1),
				},
			},
			{
				Name = "Boulder scramble",
				Primitives = merge(maze(SLOT5ROOM3, 0, 0, true, false), {
					boulder(24, 23, 11, 9),
					boulder(16, 60, 13, 9),
				}),
				Loot = {
					loot(20, 100, 6),
					loot(60, 20, 3),
					loot(60, 100, 2),
				},
			},
		},
	},
	{
		Name = "Sea vault",
		At = { -80, 408 },
		Size = { 160, 120 },
		Rooms = {
			{
				Name = "Dead-end vault",
				Primitives = merge(maze(SLOT6ROOM1, 0, 0, false, false), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 60),
					cellRoof(60, 100),
					cellRoof(100, 60),
					cellRoof(100, 100),
					cellRoof(140, 20),
					cellRoof(140, 60),
					cellRoof(140, 100),
				}),
				Loot = {
					loot(20, 20, 6),
					loot(20, 60, 3),
					loot(20, 100, 2),
					loot(100, 100, 1),
				},
			},
			{
				Name = "Flooded vault",
				Primitives = merge(maze(SLOT6ROOM2, 0, 0, false, false), {
					cellRoof(20, 60),
					cellRoof(60, 60),
					cellRoof(60, 100),
					pool(140, 20, 13),
					pool(20, 20, 13),
					pool(60, 20, 13),
					pool(20, 100, 13),
				}),
				Loot = {
					loot(140, 20, 6),
					loot(20, 100, 3),
				},
			},
			{
				Name = "Collapsed vault",
				Primitives = merge(maze(SLOT6ROOM3, 0, 0, false, false), {
					boulder(18, 16, 12, 10),
					boulder(15, 64, 12, 10),
					boulder(140, 59, 11, 10),
					boulder(141, 95, 11, 8),
				}),
				Loot = {
					loot(20, 100, 6),
					loot(60, 100, 3),
					loot(60, 60, 2),
				},
			},
			{
				Name = "Tunnel loop",
				Primitives = merge(maze(SLOT6ROOM4, 0, 0, false, false), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 20),
					cellRoof(60, 100),
					cellRoof(100, 100),
					cellRoof(140, 20),
					cellRoof(140, 60),
					cellRoof(140, 100),
				}),
				Loot = {
					loot(60, 100, 6),
					loot(100, 100, 3),
					loot(20, 20, 2),
				},
			},
		},
	},
	{
		Name = "East deeps",
		At = { 240, 408 },
		Size = { 120, 120 },
		Rooms = {
			{
				Name = "Flooded pocket",
				Primitives = merge(maze(SLOT7ROOM1, 0, 0, false, true), {
					cellRoof(20, 20),
					cellRoof(20, 100),
					cellRoof(100, 60),
					pool(20, 60, 13),
					pool(60, 60, 13),
					pool(60, 100, 13),
				}),
				Loot = {
					loot(20, 60, 6),
					loot(60, 60, 3),
					loot(20, 20, 4),
				},
			},
			{
				Name = "Dead-end cave",
				Primitives = merge(maze(SLOT7ROOM2, 0, 0, false, true), {
					cellRoof(20, 20),
					cellRoof(20, 60),
					cellRoof(20, 100),
					cellRoof(60, 60),
					cellRoof(60, 100),
					cellRoof(100, 20),
					cellRoof(100, 60),
					cellRoof(100, 100),
				}),
				Loot = {
					loot(20, 20, 6),
					loot(20, 60, 3),
					loot(20, 100, 2),
					loot(100, 20, 1),
				},
			},
			{
				Name = "Boulder scramble",
				Primitives = merge(maze(SLOT7ROOM3, 0, 0, false, true), {
					boulder(61, 100, 13, 10),
					boulder(104, 95, 13, 9),
				}),
				Loot = {
					loot(20, 100, 6),
					loot(100, 60, 3),
					loot(20, 60, 2),
				},
			},
		},
	},
}

return frame
