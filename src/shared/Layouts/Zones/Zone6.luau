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
	return { Kind = "Roof", Path = path, Width = width or 44, Clearance = 22, Thickness = 8 }
end

-- A pool: low ground that holds the sea from early in the flood.
local function pool(x, z, radius)
	return { Kind = "Hollow", At = { x, z }, Radius = radius or 12, Depth = 3 }
end

-- A sunk lane: floods before the ground round it.
local function lane(path)
	return { Kind = "Channel", Path = path, Depth = 2, Width = 12 }
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
-- x = +-360, so a wall must be full height there).
local function maze(art, x0, z0)
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
				local path = { { x0 + PITCH * c + 6, z } }
				for i = c + 1, last do
					table.insert(path, { x0 + PITCH * i, z })
				end
				table.insert(path, { x0 + PITCH * (last + 1) - 6, z })
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
	Primitives = merge(maze(FRAME, X0, Z0), {
		roof({ { -100, 228 }, { -100, 348 }, { 100, 348 }, { 100, 228 } }, 48),
		roof({ { -100, 388 }, { -100, 548 }, { 100, 548 }, { 100, 388 } }, 48),
	}),
}

local CROSSING1 = {
	"+  +  +  +  +  +  +--+  +  +--+  +  +--+  +  +--+  +  +",
	"                                          |            ",
	"+  +  +  +--+  +--+  +--+  +  +  +  +  +  +--+--+  +  +",
	"            |     |                    |        |  |   ",
	"+  +  +  +  +--+  +--+--+  +  +  +  +  +--+--+  +  +  +",
	"            |                             |     |  |   ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +--+  +--+",
	"               |     |                 |  |     |      ",
	"+  +  +  +--+--+  +  +  +  +  +  +--+  +  +--+  +--+  +",
	"               |     !                 |  |            ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"         |  |                       |                  ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +--+  +  +  +  +  +",
	"   |  |     |  |                          |            ",
	"+  +  +--+  +  +--+--+  +  +  +  +  +  +--+  +  +  +  +",
	"   |  |     |  |                       |  |            ",
	"+  +  +--+--+  +  +  +  +  +  +  +  +  +  +  +  +  +  +",
	"   |        |                          |               ",
	"+  +  +  +  +  +--+--+  +  +--+  +--+--+  +  +  +  +  +",
	"            |                             |            ",
	"+  +  +  +  +  +--+  +  +  +  +  +  +  +  +  +  +  +  +",
	"            |     |                    |               ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +  +--+--+  +  +  +",
	"            |  |                    |                  ",
	"+  +  +  +  +  +  +  +  +  +  +  +  +--+--+  +  +  +  +",
	"         |  |  |                                       ",
	"+  +--+--+  +  +--+  +  +  +  +  +  +  +--+--+  +  +  +",
	"            |                    |                     ",
	"+  +  +  +  +--+  +  +--+  +  +--+  +  +--+  +  +--+  +",
}

local crossing1 = {
	Name = "West stair",
	Primitives = merge(maze(CROSSING1, X0, Z0), {
		roof({ { 100, 228 }, { 100, 308 } }, 44),
		roof({ { -220, 388 }, { -220, 508 } }, 44),
		roof({ { -60, 348 }, { 60, 348 } }, 44),
		roof({ { -20, 188 }, { 60, 188 } }, 44),
		roof({ { 100, 428 }, { 100, 508 } }, 44),
		roof({ { 180, 548 }, { 340, 548 } }, 44),
		roof({ { -60, 548 }, { 60, 548 } }, 44),
		roof({ { -60, 388 }, { 60, 388 } }, 44),
		lane({ { -340, 268 }, { -340, 348 } }),
		lane({ { -60, 28 }, { 60, 28 } }),
		pool(-60, 188),
		pool(100, 28),
		pool(-180, 468),
		pool(-340, 228),
		pool(-180, 388),
		pool(-300, 188),
		{
			Kind = "Ramp",
			Path = {
				{ -260, 0 },
				{ -260, 28 },
				{ -180, 28 },
				{ -180, 68 },
				{ -140, 68 },
				{ -140, 188 },
				{ -100, 188 },
				{ -100, 108 },
				{ -60, 108 },
				{ -60, 188 },
				{ 100, 188 },
				{ 100, 348 },
				{ -100, 348 },
				{ -100, 308 },
				{ -140, 308 },
				{ -140, 348 },
				{ -180, 348 },
				{ -180, 188 },
				{ -300, 188 },
				{ -300, 348 },
				{ -220, 348 },
				{ -220, 548 },
				{ -300, 548 },
				{ -300, 604 },
			},
			Width = 14,
		},
	}),
	Loot = {
		loot(-140, 548, 5),
		loot(-140, 388, 5),
		loot(60, 548, 5),
		loot(340, 108, 5),
		loot(340, 548, 5),
		loot(220, 28, 5),
		loot(220, 188, 5),
	},
}

frame.Crossings = { crossing1 }

return frame
