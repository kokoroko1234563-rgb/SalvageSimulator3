-- Hermit Hollows. Zone 4 is drawn as a whole: a giant hermit crab's warren, a lattice of
-- rock-walled corridors 16 studs wide, almost all of it roofed. Zones 5 and 6 are still the old
-- 152-stud layouts, repeated down the zone. See docs/layouts/HermitHollows.md.
--
-- Zone 4's warren is a grid of 24 x 21 cells. A cell is a 16 x 16 floor; the walls between
-- cells are 12 thick, so cells are 28 apart. Node lines (where walls cross) run at
-- x = -336 + 28 i and z = 12 + 28 j, all on the 4-stud grid, so every wall face lands on 4k + 2.
-- Mazes are drawn as text: 2 n + 1 lines of 2 m + 1 characters. Nodes sit at even positions
-- ('+'); between two nodes a wall is '-' (across) or '|' (down), 'r' is a rubble pile in a
-- doorway (a scramble for players on foot, too steep for a cart), and a blank is a door.
-- Cells sit at odd positions: 'c' is a chamber and 'S' a side-room slot (both unroofed), '.' a
-- gap in the roof, and a blank is a roofed corridor.
local Tiled = require(script.Parent.Parent.Tiled)

local PITCH = 28
local WALL_HEIGHT = 22
local ZONE_DEPTH = 608

local function parse(rows)
	local nodeRows = (#rows - 1) // 2
	local nodeCols = (#rows[1] - 1) // 2
	local lattice = { cols = nodeCols, rows = nodeRows, H = {}, V = {}, cell = {} }
	for j = 0, nodeRows do
		local line = rows[2 * j + 1]
		lattice.H[j] = {}
		for c = 0, nodeCols - 1 do
			lattice.H[j][c] = string.sub(line, 2 * c + 2, 2 * c + 2)
		end
	end
	for r = 0, nodeRows - 1 do
		local line = rows[2 * r + 2]
		lattice.V[r] = {}
		lattice.cell[r] = {}
		for i = 0, nodeCols do
			lattice.V[r][i] = string.sub(line, 2 * i + 1, 2 * i + 1)
		end
		for c = 0, nodeCols - 1 do
			lattice.cell[r][c] = string.sub(line, 2 * c + 2, 2 * c + 2)
		end
	end
	return lattice
end

-- The warren's coordinates, or a side room's (origin 0, 0).
local function gridOf(ox, oz)
	return {
		nodeX = function(i)
			return ox + PITCH * i
		end,
		nodeZ = function(j)
			return oz + PITCH * j
		end,
		cellX = function(c)
			return ox + 14 + PITCH * c
		end,
		cellZ = function(r)
			return oz + 14 + PITCH * r
		end,
	}
end

local WARREN = gridOf(-336, 12)

local function wall(path)
	return { Kind = "Wall", Path = path, Height = WALL_HEIGHT, Width = 12 }
end

-- The walls of a maze that the `base` maze doesn't already have. With `inner`, the maze's own
-- border is left to whoever drew it (a room's border is the frame's, with its door).
local function wallsOf(lattice, grid, base, inner)
	local list = {}
	local function has(l, kind, a, b)
		return l ~= nil and l[kind][a][b] == (if kind == "H" then "-" else "|")
	end
	for j = 0, lattice.rows do
		if not (inner and (j == 0 or j == lattice.rows)) then
			for c = 0, lattice.cols do
				local here = c < lattice.cols and has(lattice, "H", j, c) and not has(base, "H", j, c)
				if here then
					table.insert(
						list,
						wall({ { grid.nodeX(c), grid.nodeZ(j) }, { grid.nodeX(c + 1), grid.nodeZ(j) } })
					)
				end
			end
		end
	end
	for i = 0, lattice.cols do
		if not (inner and (i == 0 or i == lattice.cols)) then
			for r = 0, lattice.rows do
				local here = r < lattice.rows and has(lattice, "V", r, i) and not has(base, "V", r, i)
				if here then
					table.insert(
						list,
						wall({ { grid.nodeX(i), grid.nodeZ(r) }, { grid.nodeX(i), grid.nodeZ(r + 1) } })
					)
				end
			end
		end
	end
	return list
end

-- Rubble in the doorways: a pile of sand across each 'r'.
local function rubbleOf(lattice, grid)
	local list = {}
	local function pile(x1, z1, x2, z2)
		table.insert(list, { Kind = "Ridge", Path = { { x1, z1 }, { x2, z2 } }, Height = 4.2, Width = 24 })
	end
	for j = 0, lattice.rows do
		for c = 0, lattice.cols - 1 do
			if lattice.H[j][c] == "r" then
				pile(grid.nodeX(c), grid.nodeZ(j), grid.nodeX(c + 1), grid.nodeZ(j))
			end
		end
	end
	for r = 0, lattice.rows - 1 do
		for i = 0, lattice.cols do
			if lattice.V[r][i] == "r" then
				pile(grid.nodeX(i), grid.nodeZ(r), grid.nodeX(i), grid.nodeZ(r + 1))
			end
		end
	end
	return list
end

-- Roofs over every corridor cell: a slab resting on the walls, row by row. A cell stays open
-- where `lattice` or `frame` marks it (a chamber, a slot, a gap in the roof).
local function roofsOf(lattice, grid, frame)
	local list = {}
	for r = 0, lattice.rows - 1 do
		local start = nil
		for c = 0, lattice.cols do
			local roofed = c < lattice.cols
				and lattice.cell[r][c] == " "
				and (frame == nil or frame.cell[r][c] == " ")
			if roofed and not start then
				start = c
			elseif not roofed and start then
				local z = grid.cellZ(r)
				local path = if start == c - 1
					then { { grid.cellX(start), z } }
					else { { grid.cellX(start), z }, { grid.cellX(c - 1), z } }
				table.insert(list, { Kind = "Roof", Path = path, Width = 32, Clearance = 20, Thickness = 8 })
				start = nil
			end
		end
	end
	return list
end

local function point(grid, cell)
	return { grid.cellX(cell[1]), grid.cellZ(cell[2]) }
end

local function patrolsOf(grid, crabs)
	local list = {}
	for _, cells in crabs do
		local path = {}
		for _, cell in cells do
			table.insert(path, point(grid, cell))
		end
		table.insert(list, { Type = "Patrol", Path = path, Count = 1 })
	end
	return list
end

local function lootOf(grid, spots)
	local list = {}
	for _, spot in spots do
		local at = point(grid, spot)
		table.insert(list, { At = at, Radius = 6, Weight = spot[3] })
	end
	return list
end

local function append(into, from)
	for _, item in from do
		table.insert(into, item)
	end
end

local FRAME = {
	"+-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+ +-+-+-+-+ +-+-+",
	"|                                       |c c c| |",
	"+ + + + + +-+ +-+ + + + + + + + + + + + + + + + +",
	"|         |c c c                         c c c| |",
	"+ + + + + + + + + + + + + + + + + + + + + + + + +",
	"|          c c c|                       |c c c  |",
	"+-+-+-+ + + +-+ + + + + + + + + + + + + + +-+ + +",
	"|S S S|                                         |",
	"+ + + + + + + + + + + + + + + + + + + + + +-+-+-+",
	"|S S S                                    |S S S|",
	"+ + + + + + + + + + + + + + + + + + + + + + + + +",
	"|S S S|                                    S S S|",
	"+-+-+-+ + + + + + + + + + + + + + + + + + + + + +",
	"|                                         |S S S|",
	"+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+",
	"|                                               |",
	"+-+-+-+-+ + + + + + + + + + + + + + + + +-+-+-+-+",
	"|S S S S|                               |S S S S|",
	"+ + + + + + + + + + +-+ +-+ + + + + + + + + + + +",
	"|S S S S            |c c c               S S S S|",
	"+ + + + + + + + + + + + + + + + + + + + + + + + +",
	"|S S S S|            c c c|             |S S S S|",
	"+ + + + + + + + + + + + + + + + + + + + + + + + +",
	"|S S S S|           |c c c              |S S S S|",
	"+-+-+-+-+ + + + + + + +-+ + + + + + + + +-+-+-+-+",
	"|                                               |",
	"+ + + + + + + + + + + + + + + + + + + + + + + + +",
	"|                                               |",
	"+-+-+-+ +-+-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+ +-+-+",
	"|                                               |",
	"+ + + + + + + + + + + +-+ +-+ + + + + + + + + + +",
	"|                     |c c c                    |",
	"+-+-+-+ + +-+ +-+ + + + + + + + + + + + + +-+-+-+",
	"|S S S|   |c c c       c c c|             |S S S|",
	"+ + + + + + + + + + + + +-+ +-+ +-+ + + + + + + +",
	"|S S S     c c c|           |S S S|       |S S S|",
	"+ + + + + + +-+ + + + + + + + + + + + + + + + + +",
	"|S S S|                     |S S S|        S S S|",
	"+ + + + + + + + + + + + + + + + + + + + + + + + +",
	"|S S S|                     |S S S|       |S S S|",
	"+-+-+-+-+ +-+-+ +-+ +-+ +-+ +-+-+-+ +-+ +-+-+-+-+",
}

local CROSSINGS = {
	{
		Name = "Basin run",
		Maze = {
			"+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+",
			"|     |           |   |     |   |       |c c c| |",
			"+-+-+ + +-+-+-+-+-+ + + +-+ + + +-+-+-+ + + + + +",
			"|     |   |c c c    | | |     |   |      c c c| |",
			"+ +-+-+-+ + + + +-+-+ + + + +-+-+ + +-+ + + + + +",
			"|         |c c c|       | |       |   | |c c c  |",
			"+-+-+-+-+ +-+-+ +-+-+-+ + +-+-+-+ + + +-+-+-+-+ +",
			"|S S S|       | |     | | |   |     |   |       |",
			"+ + + + +-+-+ +-+ +-+-+ + +-+ + +-+r+-+ + +-+-+-+",
			"|S S S .  |   |      .| |   |   |     | | |S S S|",
			"+ + + +-+ + +-+-+-+ + + + + + + + +-+ +-+ + + + +",
			"|S S S| | |     |   | | | |   |   |     |  S S S|",
			"+-+-+-+ + +-+-+ + + + + + +-+ +-+-+-+ + +-+ + + +",
			"|   |     |   |   | | | | |   |       |   |S S S|",
			"+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+",
			"|           | |             |   | |   |         |",
			"+-+-+-+-+ +-+ +-+ + +-+ +-+-+-+-+ + +-+ +-+-+-+-+",
			"|S S S S|   |   |   |     |     |       |S S S S|",
			"+ + + + +-+ +-+ +-+ +-+-+-+ + +-+ + +-+-+ + + + +",
			"|S S S S    | |     |c c c|.| |   |      S S S S|",
			"+ + + + + +-+ +-+-+ + + + + +-+-+-+-+-+ + + + + +",
			"|S S S S| |  .|     |c c c|         |   |S S S S|",
			"+ + + + + + + + + + + + + +-+ + +-+ +-+ + + + + +",
			"|S S S S| | |   | | |c c c  | | | |     |S S S S|",
			"+-+-+-+-+ +-+ +-+ +-+-+-+ + +-+ + +-+ +-+-+-+-+-+",
			"|   |     |     |     |   |     |   |     |   | |",
			"+ +-+ +-+-+-+-+-+ +-+ +-+ +-+-+-+ +-+ + +-+ + + +",
			"|             |   |         |         |     |   |",
			"+-+-+-+ +-+-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+",
			"|       |               |   |.|           |   | |",
			"+ + +-+-+ +-+ + + + + +-+ +-+ +-+ + + +-+ + + + +",
			"| |       |   | | | | |c c c  |   | | | |   |   |",
			"+-+-+-+-+ +-+ +-+-+ + + + + + +-+-+-+-+ + +-+-+-+",
			"|S S S| | |c c c    | |c c c|         | | |S S S|",
			"+ + + + + + + + +-+ +-+-+-+ +-+ +-+-+ + + + + + +",
			"|S S S  | |c c c| |   |   | |S S S| | |   |S S S|",
			"+ + + + + +-+-+ + + +-+-+ + + + + + + + +-+ + + +",
			"|S S S| |     | |       |   |S S S| | |    S S S|",
			"+ + + + + + + + +-+-+-+ + +-+ + + + +-+-+ + + + +",
			"|S S S|       | |       |   |S S S|    .  |S S S|",
			"+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+",
		},
		Ramp = {
			{ 21, 0 },
			{ 20, 0 },
			{ 20, 1 },
			{ 17, 1 },
			{ 17, 3 },
			{ 15, 3 },
			{ 15, 5 },
			{ 16, 5 },
			{ 16, 4 },
			{ 18, 4 },
			{ 18, 5 },
			{ 19, 5 },
			{ 19, 8 },
			{ 17, 8 },
			{ 17, 9 },
			{ 19, 9 },
			{ 19, 11 },
			{ 17, 11 },
			{ 17, 10 },
			{ 15, 10 },
			{ 15, 12 },
			{ 13, 12 },
			{ 13, 11 },
			{ 12, 11 },
			{ 12, 13 },
			{ 10, 13 },
			{ 10, 12 },
			{ 8, 12 },
			{ 8, 14 },
			{ 6, 14 },
			{ 6, 17 },
			{ 7, 17 },
			{ 7, 19 },
		},
		Loot = { { 0, 0, 3 }, { 8, 0, 3 }, { 3, 5, 3 }, { 0, 7, 3 }, { 17, 17, 3 }, { 10, 3, 3 } },
		Crabs = {
			{ { 12, 12 }, { 11, 12 } },
			{ { 19, 6 }, { 20, 6 } },
			{ { 8, 13 }, { 7, 13 } },
			{ { 18, 11 }, { 18, 12 }, { 18, 13 } },
			{ { 19, 0 }, { 19, 1 }, { 19, 2 } },
			{ { 17, 2 }, { 18, 2 } },
			{ { 15, 4 }, { 14, 4 } },
			{ { 6, 15 }, { 5, 15 } },
			{ { 17, 9 }, { 18, 9 }, { 19, 9 } },
			{ { 15, 10 }, { 15, 11 }, { 15, 12 } },
		},
	},
	{
		Name = "Antler descent",
		Maze = {
			"+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+",
			"| |     |         |.|   |   | |         |c c c| |",
			"+ + +-+ + +-+ +-+-+ + +-+ + + + +-+ +-+ + + + + +",
			"| | | | | |c c c  |   |     | | |   | |  c c c| |",
			"+ + + + +-+ + + + + + +-+ +-+ + +-+-+ + + + + + +",
			"|   |      c c c|   |     |.|   |   | | |c c c  |",
			"+-+-+-+ + +-+-+-+ +-+-+-+ + +-+ + + + + +-+-+ +-+",
			"|S S S| |   |   |       |         |   | |       |",
			"+ + + + +-+-+-+ + +-+-+ +-+-+-+ + + + + + +-+-+-+",
			"|S S S        |       |   |   | | |.| | | |S S S|",
			"+ + + + + +-+ +-+-+-+ +-+ + +-+-+-+-+ + +-+ + + +",
			"|S S S| | |         | | |           | |    S S S|",
			"+-+-+-+ + +-+-+-+-+-+-+ +-+-+-+ +-+-+ +-+ + + + +",
			"|       |           |.        | |       | |S S S|",
			"+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+",
			"|           |           |   |     |             |",
			"+-+-+-+-+-+ +-+-+-+ +-+-+ + + + + +-+ +-+-+-+-+-+",
			"|S S S S| |       | |     |   | |   |   |S S S S|",
			"+ + + + + +-+-+-+ + +-+ +-+-+-+-+-+-+-+ + + + + +",
			"|S S S S            |c c c  |   |     |  S S S S|",
			"+ + + + + + +-+-+-+-+ + + + + +-+-+ +-+ + + + + +",
			"|S S S S| |          c c c|   |   |   | |S S S S|",
			"+ + + + +-+ +-+-+-+ + + + +-+-+ +-+-+ + + + + + +",
			"|S S S S| | |       |c c c      |     | |S S S S|",
			"+-+-+-+-+ + +-+-+-+-+-+-+-+-+-+-+-+ +-+ +-+-+-+-+",
			"| |   |   |         |         |     | |       | |",
			"+ +-+ + + +-+-+-+-+ + + + +-+ + + +-+ +-+-+-+ + +",
			"|                   |   |   |   |         | |   |",
			"+-+-+-+ +-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+ +-+-+",
			"|       |   |   |     |   |       |     |     | |",
			"+ +-+-+-+ + + + + + +-+-+ +-+ + +-+-+ +-+ + +-+ +",
			"|         |   | |     |c c c  |   |       |.    |",
			"+-+-+-+-+ +-+-+-+r+-+ + + + +-+ + + + + +-+-+-+-+",
			"|S S S| | |c c c       c c c|   |   | | | |S S S|",
			"+ + + + + + + + +-+-+-+-+-+ +-+ +-+-+-+ + + + + +",
			"|S S S    |c c c| |       | |S S S|     | |S S S|",
			"+ + + + + + +-+ + +-+-+-+ + + + + +-+ +-+ + + + +",
			"|S S S| | | |   |       |.  |S S S| |      S S S|",
			"+ + + + +-+ + + + +-+ + +-+-+ + + + +-+ + + + + +",
			"|S S S|     | |     | |     |S S S|     | |S S S|",
			"+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+",
		},
		Ramp = {
			{ 8, 0 },
			{ 6, 0 },
			{ 6, 2 },
			{ 3, 2 },
			{ 3, 4 },
			{ 4, 4 },
			{ 4, 6 },
			{ 6, 6 },
			{ 6, 7 },
			{ 9, 7 },
			{ 9, 9 },
			{ 5, 9 },
			{ 5, 12 },
			{ 9, 12 },
			{ 9, 13 },
			{ 8, 13 },
			{ 8, 15 },
			{ 10, 15 },
			{ 10, 16 },
			{ 7, 16 },
			{ 7, 19 },
			{ 8, 19 },
			{ 8, 18 },
			{ 11, 18 },
			{ 11, 19 },
			{ 13, 19 },
		},
		Loot = { { 23, 12, 3 }, { 20, 4, 3 }, { 23, 0, 3 }, { 23, 7, 3 }, { 17, 7, 3 }, { 17, 18, 3 } },
		Crabs = {
			{ { 9, 15 }, { 9, 14 } },
			{ { 4, 2 }, { 4, 3 } },
			{ { 7, 18 }, { 6, 18 } },
			{ { 8, 9 }, { 8, 8 } },
			{ { 10, 18 }, { 10, 19 } },
			{ { 5, 10 }, { 6, 10 }, { 7, 10 } },
			{ { 4, 6 }, { 5, 6 }, { 6, 6 } },
			{ { 5, 12 }, { 6, 12 }, { 7, 12 }, { 8, 12 } },
			{ { 6, 7 }, { 7, 7 }, { 8, 7 }, { 9, 7 } },
		},
	},
	{
		Name = "Throne road",
		Maze = {
			"+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+",
			"|   |     |             |     | | |     |c c c| |",
			"+-+ + + +-+-+-+-+-+ +-+-+ +-+ + + +-+ + + + + + +",
			"|   | |   |c c c| |       |   | |   | |  c c c| |",
			"+ +-+ +-+ + + + + +-+ +-+-+ +-+ +-+ +-+ + + + + +",
			"|     | |  c c c|   | |.    |     |   | |c c c  |",
			"+-+-+-+ +-+-+-+ + + + +-+-+ + +-+ + + + +-+-+ +-+",
			"|S S S| |       | | |     |   | |   |   |   |   |",
			"+ + + + + + +-+-+ + +-+-+ +-+-+ +-+-+-+ + +-+-+-+",
			"|S S S    |     | |   |           |     | |S S S|",
			"+ + + + +-+-+-+ + + +-+-+r+-+ +-+ + +-+ + + + + +",
			"|S S S| |     |   |   |   | | |   |   |    S S S|",
			"+-+-+-+ +-+ + +-+ +-+ + + + + + +-+ +-+-+ + + + +",
			"|           |   |   |   |     | |     |   |S S S|",
			"+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+",
			"|.  |       |             |     |            .  |",
			"+-+-+-+-+-+ +-+-+ +-+-+-+-+ +-+ + +-+ +-+-+-+-+-+",
			"|S S S S| |     |       |  .| | | |     |S S S S|",
			"+ + + + + + +-+ +-+-+-+ +-+ + + + + +-+-+ + + + +",
			"|S S S S  |  .| |   |c c c| |   | | |    S S S S|",
			"+ + + + + + +-+ + + + + + + +-+-+ +-+-+ + + + + +",
			"|S S S S| |   |   |  c c c|   |   |     |S S S S|",
			"+ + + + + + +-+-+ +-+ + + +-+-+ +-+ + +-+ + + + +",
			"|S S S S|     | |   |c c c      |   |   |S S S S|",
			"+-+-+-+-+ +-+ + +-+-+-+-+ +-+-+-+ +-+-+ +-+-+-+-+",
			"|   |   | | |       |   | |   |   |   |   |     |",
			"+ +-+ + + + +-+-+ + + + + +-+ + +-+ + + + + + + +",
			"|         |       | | |     |     | |   |   |   |",
			"+-+-+-+ +-+-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+ +-+-+",
			"|   | | |   |   | | |           | | |   |   |   |",
			"+ + + + +-+ +-+ + + + +-+ +-+ + + + + + + +-+-+ +",
			"|       |         | | |c c c| | |   | | |       |",
			"+-+-+-+-+ +-+-+-+-+ + + + + +-+ + +-+ + + +-+-+-+",
			"|S S S| | |c c c      |c c c|     |   |   |S S S|",
			"+ + + + + + + + +-+-+ + +-+ +-+ +-+ +-+-+ + + + +",
			"|S S S  | |c c c|   | | | | |S S S|       |S S S|",
			"+ + + + + +-+-+ +-+ + +-+ + + + + +-+-+-+ + + + +",
			"|S S S| |.|   | |   | |   | |S S S|   |    S S S|",
			"+ + + + + +-+ + + +-+ + +-+ + + + + + + +-+ + + +",
			"|S S S|         |     |     |S S S| |     |S S S|",
			"+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+",
		},
		Ramp = {
			{ 16, 0 },
			{ 16, 1 },
			{ 17, 1 },
			{ 17, 3 },
			{ 16, 3 },
			{ 16, 2 },
			{ 14, 2 },
			{ 14, 3 },
			{ 13, 3 },
			{ 13, 1 },
			{ 14, 1 },
			{ 14, 0 },
			{ 12, 0 },
			{ 12, 1 },
			{ 10, 1 },
			{ 10, 3 },
			{ 12, 3 },
			{ 12, 4 },
			{ 14, 4 },
			{ 14, 6 },
			{ 12, 6 },
			{ 12, 5 },
			{ 11, 5 },
			{ 11, 6 },
			{ 10, 6 },
			{ 10, 7 },
			{ 8, 7 },
			{ 8, 8 },
			{ 11, 8 },
			{ 11, 11 },
			{ 12, 11 },
			{ 12, 13 },
			{ 13, 13 },
			{ 13, 14 },
			{ 12, 14 },
			{ 12, 16 },
			{ 13, 16 },
			{ 13, 19 },
			{ 11, 19 },
		},
		Loot = { { 0, 0, 3 }, { 17, 19, 3 }, { 13, 12, 3 }, { 22, 14, 3 }, { 6, 14, 3 }, { 1, 12, 3 } },
		Crabs = {
			{ { 15, 2 }, { 15, 1 }, { 15, 0 } },
			{ { 17, 2 }, { 18, 2 } },
			{ { 13, 6 }, { 13, 5 } },
			{ { 13, 2 }, { 12, 2 }, { 11, 2 } },
			{ { 14, 0 }, { 13, 0 }, { 12, 0 } },
			{ { 8, 8 }, { 9, 8 }, { 10, 8 }, { 11, 8 } },
			{ { 12, 1 }, { 11, 1 }, { 10, 1 } },
		},
	},
	{
		Name = "East flank",
		Maze = {
			"+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+",
			"|   | | |               |   | |   | |   |c c c| |",
			"+-+ + + + +-+-+-+ +-+ + + +-+ + + + + + + + + + +",
			"| |   | | |c c c    |.| |       | |      c c c| |",
			"+ +-+ + +-+ + + + + +-+-+ +-+ + + +-+-+ + + + + +",
			"|       |  c c c| |   |     | | | | |   |c c c  |",
			"+-+-+-+ +-+-+-+ + + +-+ + + +-+-+-+ +-+ +-+-+-+ +",
			"|S S S|       | | |   | | |     |.  |       |   |",
			"+ + + +-+-+ + +-+ +-+ + + +-+-+-+-+ +-+ + +-+-+-+",
			"|S S S      |   |   |   | | |     | |     |S S S|",
			"+ + + +-+-+ + +-+ + +-+-+-+ + +-+-+ + +-+ + + + +",
			"|S S S|     |    .|   |     | | | | | | |  S S S|",
			"+-+-+-+-+-+-+-+-+ + +-+ +-+ + + + + + + + + + + +",
			"|                 |       |   |         | |S S S|",
			"+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+",
			"|   |         | |   |         |     | |         |",
			"+-+-+-+-+-+ + + + + +-+ +-+-+ + +-+ + + +-+-+-+-+",
			"|S S S S|   |     |   |     |     |   | |S S S S|",
			"+ + + + +-+ +-+ +-+ +-+-+-+-+ +-+ +-+ + + + + + +",
			"|S S S S  | |   |   |c c c  |       | |  S S S S|",
			"+ + + + + + + +-+ + + + + + +-+-+-+ +-+ + + + + +",
			"|S S S S|   |   | | |c c c|         | | |S S S S|",
			"+ + + + +-+-+-+ +-+-+ + + +-+ + +-+r+ + + + + + +",
			"|S S S S| |     |   |c c c|   | | |     |S S S S|",
			"+-+-+-+-+ +-+ + + + + +-+ + +-+ + + +-+ +-+-+-+-+",
			"|   |   |   | | | | | |   |         | | |       |",
			"+-+ + + + + +-+ + + + + +-+-+ +-+-+-+ + + + + + +",
			"|     | | |     | | | |  .  |     |     | | | | |",
			"+-+-+-+ +-+-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+ +-+-+",
			"| |             |   |     |       |         |   |",
			"+ +-+ +-+-+-+ + + + + +-+-+-+ +-+-+-+-+-+-+ + + +",
			"|     |   |   |   |   |c c c      |   |       | |",
			"+-+-+-+ + +-+-+-+-+-+ + + + + +-+ + +-+ + +-+-+-+",
			"|S S S| | |c c c| |    c c c| |   |   | | |S S S|",
			"+ + + + + + + + + +-+ +-+-+ +-+ +-+-+ + +-+ + + +",
			"|S S S  |. c c c| |   |     |S S S| | |   |S S S|",
			"+ + + +-+ +-+-+ + + +-+ + +-+ + + + + +-+ + + + +",
			"|S S S| |       | | |   |   |S S S|     |  S S S|",
			"+ + + + + +-+-+ + + + +-+ + + + + +-+-+ + + + + +",
			"|S S S|             |   | |.|S S S|       |S S S|",
			"+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+",
		},
		Ramp = {
			{ 3, 0 },
			{ 3, 3 },
			{ 6, 3 },
			{ 6, 5 },
			{ 8, 5 },
			{ 8, 4 },
			{ 9, 4 },
			{ 9, 6 },
			{ 10, 6 },
			{ 10, 7 },
			{ 14, 7 },
			{ 14, 9 },
			{ 17, 9 },
			{ 17, 10 },
			{ 15, 10 },
			{ 15, 12 },
			{ 17, 12 },
			{ 17, 11 },
			{ 19, 11 },
			{ 19, 13 },
			{ 17, 13 },
			{ 17, 14 },
			{ 21, 14 },
			{ 21, 15 },
			{ 19, 15 },
			{ 19, 17 },
			{ 20, 17 },
			{ 20, 19 },
			{ 19, 19 },
		},
		Loot = { { 0, 12, 3 }, { 3, 17, 3 }, { 9, 13, 3 }, { 11, 19, 3 }, { 16, 2, 3 }, { 23, 0, 3 } },
		Crabs = {
			{ { 16, 9 }, { 16, 8 } },
			{ { 18, 13 }, { 18, 12 } },
			{ { 16, 12 }, { 16, 11 } },
			{ { 18, 11 }, { 18, 10 } },
			{ { 14, 8 }, { 15, 8 }, { 16, 8 } },
			{ { 20, 15 }, { 20, 16 } },
			{ { 5, 3 }, { 5, 4 }, { 5, 5 } },
			{ { 9, 5 }, { 10, 5 } },
			{ { 11, 7 }, { 11, 8 } },
			{ { 6, 5 }, { 7, 5 }, { 8, 5 } },
		},
	},
	{
		Name = "Cellar spiral",
		Maze = {
			"+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+",
			"|     |     |       | |   |            .|c c c| |",
			"+ + +-+ + +-+ +-+-+-+ +-+ +-+-+ +-+-+-+-+ + + + +",
			"|.|     | |c c c  |.|   | |     |        c c c| |",
			"+ +-+-+ +-+ + + + + + +-+ + +-+ + + + + + + + + +",
			"|     | |  c c c|   |         |   | | | |c c c  |",
			"+-+-+-+ + + +-+-+-+-+-+-+ +-+ +-+-+ + +-+-+-+-+ +",
			"|S S S|   |     |     |     |           |     | |",
			"+ + + + +-+-+-+ + +-+ + +-+ +-+ + +-+-+-+ +-+-+-+",
			"|S S S  |       | | | |   | |   |   |     |S S S|",
			"+ + + + + +-+ +-+ + + +-+-+ + + +-+ + +-+-+ + + +",
			"|S S S| | | |     | |         |   |     |  S S S|",
			"+-+-+-+-+ + +-+-+-+ +-+-+-+ +-+ + + +-+-+ + + + +",
			"|          .  |             |   | | |     |S S S|",
			"+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+",
			"|           |       |         | |               |",
			"+-+-+-+-+-+ + +-+-+ +-+-+-+ +-+ +-+ +-+-+-+-+-+-+",
			"|S S S S|   |           |   |       | | |S S S S|",
			"+ + + + + + +-+ +-+ +-+-+-+-+ +-+-+-+ + + + + + +",
			"|S S S S  | | | |   |c c c|   |       |  S S S S|",
			"+ + + + + + + + +-+-+ + + + +-+ +-+-+ + + + + + +",
			"|S S S S| | | | |    c c c|     |   | | |S S S S|",
			"+ + + + +-+ + + + + + + + +-+-+-+ + +-+ + + + + +",
			"|S S S S|   |   | | |c c c|   | | |     |S S S S|",
			"+-+-+-+-+ +-+ +-+ +-+ +-+ + +-+ + +-+-+-+-+-+-+-+",
			"|           |   |   |   | |       |     |   |   |",
			"+ +-+-+-+ + +-+ +-+ +-+ + +-+ +-+-+-+ + + + +-+ +",
			"|     |   |   | |   |   |     |     |     |     |",
			"+-+-+-+ +-+-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+ +-+-+",
			"|     |   |       |       |       |   |   |     |",
			"+-+ + + +-+-+ +-+-+-+-+-+ +-+-+-+ +-+ + + +-+ + +",
			"|   |  .    |         |c c c      |   | |     | |",
			"+-+-+-+-+ +-+-+-+ +-+ + + + + +-+-+ +-+ + +-+-+-+",
			"|S S S|   |c c c    | |c c c|           | |S S S|",
			"+ + + + +-+ + + +-+-+ +-+-+ +-+ +-+-+ + + + + + +",
			"|S S S     c c c|.| | |   | |S S S|     | |S S S|",
			"+ + + + +-+-+-+-+ + + + +-+ + + + + +-+-+ + + + +",
			"|S S S|         | |   |     |S S S| | |    S S S|",
			"+ + + +-+r+-+-+ + +-+-+ +-+-+ + + + + +-+-+ + + +",
			"|S S S|           |         |S S S|       |S S S|",
			"+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+",
		},
		Ramp = {
			{ 12, 0 },
			{ 12, 3 },
			{ 13, 3 },
			{ 13, 5 },
			{ 10, 5 },
			{ 10, 3 },
			{ 8, 3 },
			{ 8, 5 },
			{ 6, 5 },
			{ 6, 4 },
			{ 4, 4 },
			{ 4, 6 },
			{ 1, 6 },
			{ 1, 7 },
			{ 5, 7 },
			{ 5, 11 },
			{ 4, 11 },
			{ 4, 13 },
			{ 3, 13 },
			{ 3, 15 },
			{ 4, 15 },
			{ 4, 16 },
			{ 3, 16 },
			{ 3, 18 },
			{ 7, 18 },
			{ 7, 19 },
			{ 4, 19 },
		},
		Loot = { { 17, 12, 3 }, { 22, 12, 3 }, { 19, 18, 3 }, { 13, 19, 3 }, { 19, 8, 3 }, { 9, 14, 3 } },
		Crabs = {
			{ { 3, 12 }, { 4, 12 }, { 5, 12 } },
			{ { 5, 8 }, { 4, 8 } },
			{ { 3, 14 }, { 4, 14 } },
			{ { 4, 6 }, { 3, 6 }, { 2, 6 }, { 1, 6 } },
			{ { 13, 3 }, { 13, 4 }, { 13, 5 } },
			{ { 10, 5 }, { 10, 4 }, { 10, 3 } },
		},
	},
}

local FRAME_LATTICE = parse(FRAME)

local function mound(x, z, radius, height)
	return { Kind = "Mound", At = { x, z }, Radius = radius, Height = height, Rock = true }
end

local frame = {
	Name = "Hermit Hollows (zone 4)",
	Primitives = {
		-- Beyond the outer wall at x = +-336, two more walls fill the strip out to the cliffs, so
		-- there's no way round the warren.
		wall({ { -348, 12 }, { -348, 600 } }),
		wall({ { -360, 12 }, { -360, 600 } }),
		wall({ { 348, 12 }, { 348, 600 } }),
		wall({ { 360, 12 }, { 360, 600 } }),
		-- (Rock overhead, so they read as the cliffs' own foot.)
		{ Kind = "Roof", Path = { { -348, 12 }, { -348, 600 } }, Width = 36, Clearance = 20, Thickness = 8 },
		{ Kind = "Roof", Path = { { 348, 12 }, { 348, 600 } }, Width = 36, Clearance = 20, Thickness = 8 },
		{ Kind = "Roof", Path = { { -336, 12 }, { 336, 12 } }, Width = 16, Clearance = 20, Thickness = 8 },
		-- The Brood chamber: boulders round the flat where the secret's entrance goes.
		mound(-36, 330, 8, 8),
		mound(8, 282, 8, 8),
		{ Kind = "Flat", At = { -14, 306 }, Radius = 10 },
		-- The Antler hall.
		mound(-170, 54, 8, 9),
		-- The Throne.
		mound(14, 452, 10, 12),
		-- The Pearl court's pool.
		{ Kind = "Hollow", At = { -154, 488 }, Radius = 10, Depth = 3 },
		-- The Tide basin, round the rock pool (260, 70): just a boulder in the corner.
		mound(294, 30, 8, 8),
	},
	Loot = {
		{ At = { 6, 286 }, Radius = 6, Weight = 2 },
		{ At = { -134, 80 }, Radius = 6, Weight = 2 },
		{ At = { 42, 474 }, Radius = 6, Weight = 2 },
		{ At = { -126, 502 }, Radius = 6, Weight = 2 },
		{ At = { 294, 82 }, Radius = 6, Weight = 2 },
	},
	Entrances = { { -14, 306 } },
	Hazards = {
		{ Type = "Patrol", Path = { { -40, 306 }, { 12, 306 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -14, 282 }, { -14, 332 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -176, 78 }, { -128, 78 } }, Count = 1 },
		{ Type = "Patrol", Path = { { 238, 40 }, { 294, 40 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -8, 474 }, { 36, 474 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -182, 502 }, { -126, 502 } }, Count = 1 },
	},
}
append(frame.Primitives, wallsOf(FRAME_LATTICE, WARREN, nil, false))

local function crossingOf(spec)
	local lattice = parse(spec.Maze)
	local primitives = wallsOf(lattice, WARREN, FRAME_LATTICE, false)
	append(primitives, rubbleOf(lattice, WARREN))
	append(primitives, roofsOf(lattice, WARREN, FRAME_LATTICE))
	-- The cart ramp follows the corridors: in at the top door, out at the bottom door.
	local ramp = { { WARREN.cellX(spec.Ramp[1][1]), 0 } }
	for _, cell in spec.Ramp do
		table.insert(ramp, point(WARREN, cell))
	end
	table.insert(ramp, { WARREN.cellX(spec.Ramp[#spec.Ramp][1]), ZONE_DEPTH })
	table.insert(primitives, { Kind = "Ramp", Path = ramp, Width = 14 })
	return {
		Name = spec.Name,
		Primitives = primitives,
		Loot = lootOf(WARREN, spec.Loot),
		Hazards = patrolsOf(WARREN, spec.Crabs),
	}
end

local crossings = {}
for _, spec in CROSSINGS do
	table.insert(crossings, crossingOf(spec))
end

local zone4 = {
	Name = "Hermit Hollows (zone 4)",
	Primitives = frame.Primitives,
	Loot = frame.Loot,
	Entrances = frame.Entrances,
	Hazards = frame.Hazards,
	Crossings = crossings,
}

-- Side rooms ----------------------------------------------------------------------------------
-- Each slot is a block of cells the frame walls off, with one door. A room is drawn in the
-- slot's own coordinates (cell centres at 14 + 28 c, 14 + 28 r) and fills the block.
local function cx(c)
	return 14 + PITCH * c
end
local function cz(r)
	return 14 + PITCH * r
end
local ROOM = gridOf(0, 0)

local function sandMound(x, z, radius, height)
	return { Kind = "Mound", At = { x, z }, Radius = radius, Height = height }
end
local function rockMound(x, z, radius, height)
	return mound(x, z, radius, height)
end
-- A solid block of rock through cell centres, exactly one cell (16) wide.
local function wall16(path)
	return { Kind = "Wall", Path = path, Height = WALL_HEIGHT, Width = 16 }
end

local function roomOf(spec)
	local lattice = parse(spec.Maze)
	local primitives = wallsOf(lattice, ROOM, nil, true)
	append(primitives, rubbleOf(lattice, ROOM))
	append(primitives, roofsOf(lattice, ROOM, nil))
	append(primitives, spec.Extra or {})
	return {
		Name = spec.Name,
		Primitives = primitives,
		Loot = lootOf(ROOM, spec.Loot or {}),
		Hazards = patrolsOf(ROOM, spec.Crabs or {}),
	}
end

local SLOT_ROOMS = {
	{
		Name = "Northwest nest",
		At = { -336, 96 },
		Size = { 84, 84 },
		Rooms = {
			{
				Name = "Crab nest",
				Maze = {
					"+ + + +",
					"       ",
					"+ +-+ +",
					"  |.|  ",
					"+ + +-+",
					"       ",
					"+ + + +",
				},
				Loot = { { 1, 1, 4 }, { 0, 2, 2 } },
				Crabs = {
					{ { 2, 0 }, { 0, 0 } },
				},
			},
			{
				Name = "Shell midden",
				Maze = {
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
				},
				Extra = {
					sandMound(cx(0) + 6, cz(0) + 6, 9, 6),
					sandMound(cx(1) + 0, cz(2) + 0, 9, 6),
					rockMound(cx(0) + 0, cz(2) + -4, 7, 8),
				},
				Loot = { { 0, 0, 3 }, { 0, 2, 2 }, { 1, 0, 1 } },
			},
			{
				Name = "Flooded pocket",
				Maze = {
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
				},
				Extra = {
					{ Kind = "Hollow", At = { cx(1), cz(1) }, Radius = 18, Depth = 3 },
				},
				Loot = { { 0, 0, 3 }, { 0, 2, 2 } },
			},
		},
	},
	{
		Name = "Western midden",
		At = { -336, 236 },
		Size = { 112, 112 },
		Rooms = {
			{
				Name = "Shell midden",
				Maze = {
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
				},
				Extra = {
					sandMound(cx(1) + 0, cz(1) + 0, 10, 7),
					sandMound(cx(2) + 0, cz(2) + 0, 10, 7),
					rockMound(cx(0) + 4, cz(3) + -4, 7, 9),
					rockMound(cx(3) + 0, cz(0) + 0, 7, 9),
				},
				Loot = { { 0, 0, 3 }, { 0, 3, 2 }, { 2, 3, 1 } },
				Crabs = {
					{ { 1, 3 }, { 3, 3 } },
				},
			},
			{
				Name = "Boulder scramble",
				Maze = {
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
				},
				Extra = {
					rockMound(cx(1) + 0, cz(0) + 0, 7, 11),
					rockMound(cx(1) + 0, cz(2) + 0, 7, 11),
					rockMound(cx(2) + -4, cz(1) + 0, 7, 11),
					rockMound(cx(2) + 0, cz(3) + 0, 7, 11),
					rockMound(cx(0) + -2, cz(1) + 0, 7, 10),
				},
				Loot = { { 0, 0, 3 }, { 0, 3, 4 }, { 3, 3, 2 } },
			},
			{
				Name = "Tunnel loop",
				Maze = {
					"+ + + + +",
					"         ",
					"+ +-+-+ +",
					"  | | |  ",
					"+ +-+-+ +",
					"  | | |  ",
					"+ +-+-+ +",
					"         ",
					"+ + + + +",
				},
				Extra = {
					wall16({ { cx(1), cz(1) }, { cx(2), cz(1) } }),
					wall16({ { cx(1), cz(2) }, { cx(2), cz(2) } }),
					wall16({ { cx(1), cz(1) }, { cx(1), cz(2) } }),
					wall16({ { cx(2), cz(1) }, { cx(2), cz(2) } }),
				},
				Loot = { { 0, 2, 4 }, { 3, 3, 2 }, { 0, 0, 1 } },
				Crabs = {
					{ { 0, 0 }, { 3, 0 } },
					{ { 0, 3 }, { 3, 3 } },
				},
			},
		},
	},
	{
		Name = "Southwest collapse",
		At = { -336, 460 },
		Size = { 84, 112 },
		Rooms = {
			{
				Name = "Collapsed chamber",
				Maze = {
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
				},
				Extra = {
					{
						Kind = "Ridge",
						Path = { { cx(0), cz(1) + 6 }, { cx(1), cz(1) + 6 } },
						Height = 4,
						Width = 16,
					},
					rockMound(cx(1) + 0, cz(2) + 0, 7, 9),
					rockMound(cx(0) + 8, cz(3) + 0, 7, 8),
				},
				Loot = { { 0, 3, 4 }, { 2, 3, 2 }, { 0, 0, 1 } },
				Crabs = {
					{ { 0, 0 }, { 0, 1 } },
				},
			},
			{
				Name = "Sea cave",
				Maze = {
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
				},
				Extra = {
					{ Kind = "Hollow", At = { cx(1), cz(2) }, Radius = 16, Depth = 3 },
				},
				Loot = { { 1, 3, 3 }, { 0, 0, 2 } },
			},
			{
				Name = "Dead-end warren",
				Maze = {
					"+ + + +",
					"    |  ",
					"+ + + +",
					"  |    ",
					"+ +-+-+",
					"  |    ",
					"+ + +-+",
					"       ",
					"+ + + +",
				},
				Loot = { { 0, 3, 4 }, { 1, 0, 1 } },
				Crabs = {
					{ { 1, 1 }, { 1, 0 } },
				},
			},
		},
	},
	{
		Name = "Northeast nest",
		At = { 252, 124 },
		Size = { 84, 84 },
		Rooms = {
			{
				Name = "Crab nest",
				Maze = {
					"+ + + +",
					"       ",
					"+ +-+ +",
					"  |.|  ",
					"+ + + +",
					"  |    ",
					"+ + + +",
				},
				Loot = { { 1, 1, 4 }, { 2, 2, 2 } },
				Crabs = {
					{ { 0, 0 }, { 2, 0 } },
				},
			},
			{
				Name = "Shell garden",
				Maze = {
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
				},
				Extra = {
					sandMound(cx(1) + 0, cz(0) + 0, 9, 5),
					sandMound(cx(1) + 0, cz(2) + 0, 9, 5),
					rockMound(cx(2) + 0, cz(1) + 0, 7, 9),
				},
				Loot = { { 2, 0, 3 }, { 2, 2, 2 } },
			},
			{
				Name = "Collapsed corner",
				Maze = {
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
				},
				Extra = {
					{
						Kind = "Ridge",
						Path = { { cx(1) + 4, cz(0) - 10 }, { cx(1) + 4, cz(2) + 10 } },
						Height = 4.2,
						Width = 24,
					},
				},
				Loot = { { 2, 1, 4 }, { 2, 0, 2 } },
			},
		},
	},
	{
		Name = "Eastern midden",
		At = { 224, 236 },
		Size = { 112, 112 },
		Rooms = {
			{
				Name = "Boulder scramble",
				Maze = {
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
					" . . . . ",
					"+ + + + +",
				},
				Extra = {
					rockMound(cx(1) + 0, cz(0) + 0, 7, 11),
					rockMound(cx(1) + 0, cz(2) + 0, 7, 11),
					rockMound(cx(2) + 4, cz(1) + 0, 7, 11),
					rockMound(cx(2) + 0, cz(3) + 0, 7, 11),
					rockMound(cx(3) + 2, cz(1) + 0, 7, 10),
				},
				Loot = { { 3, 0, 3 }, { 3, 3, 4 }, { 0, 3, 2 } },
			},
			{
				Name = "Crab warren",
				Maze = {
					"+ + + + +",
					"    |    ",
					"+-+ + +-+",
					"         ",
					"+-+-+-+ +",
					"         ",
					"+-+ +-+-+",
					"         ",
					"+ + + + +",
				},
				Loot = { { 3, 3, 4 }, { 0, 3, 1 }, { 3, 0, 2 } },
				Crabs = {
					{ { 0, 1 }, { 2, 1 } },
					{ { 3, 2 }, { 1, 2 } },
				},
			},
			{
				Name = "Drowned hall",
				Maze = {
					"+ + + + +",
					"         ",
					"+ + + + +",
					"         ",
					"+ + + + +",
					"         ",
					"+ + + + +",
					"         ",
					"+ + + + +",
				},
				Extra = {
					{
						Kind = "Channel",
						Path = { { cx(0), cz(2) }, { cx(3), cz(2) } },
						Depth = 3,
						Width = 16,
					},
				},
				Loot = { { 3, 3, 3 }, { 3, 0, 2 } },
			},
		},
	},
	{
		Name = "Southeast burrow",
		At = { 252, 460 },
		Size = { 84, 112 },
		Rooms = {
			{
				Name = "Deep tunnel",
				Maze = {
					"+ + + +",
					"  |    ",
					"+ + +-+",
					"  | |  ",
					"+ + + +",
					"       ",
					"+-+-+ +",
					"       ",
					"+ + + +",
				},
				Loot = { { 0, 3, 4 }, { 2, 0, 3 } },
				Crabs = {
					{ { 1, 2 }, { 2, 2 } },
				},
			},
			{
				Name = "Collapsed gallery",
				Maze = {
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
					" . . . ",
					"+ + + +",
				},
				Extra = {
					{ Kind = "Ridge", Path = { { cx(1), cz(1) }, { cx(2), cz(1) } }, Height = 4, Width = 16 },
					rockMound(cx(1) + 0, cz(3) + 0, 7, 9),
					rockMound(cx(2) + 0, cz(0) + 0, 7, 8),
				},
				Loot = { { 2, 3, 3 }, { 2, 0, 2 } },
			},
			{
				Name = "Drowned gallery",
				Maze = {
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
				},
				Extra = {
					{
						Kind = "Channel",
						Path = { { cx(1), cz(0) }, { cx(1), cz(3) } },
						Depth = 3,
						Width = 16,
					},
				},
				Loot = { { 2, 0, 3 }, { 2, 3, 4 } },
			},
		},
	},
	{
		Name = "South cellar",
		At = { 56, 488 },
		Size = { 84, 84 },
		Rooms = {
			{
				Name = "Crab cellar",
				Maze = {
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
				},
				Extra = {
					rockMound(cx(1) + 0, cz(1) + 0, 8, 10),
				},
				Loot = { { 0, 2, 3 }, { 2, 2, 3 } },
				Crabs = {
					{ { 0, 2 }, { 2, 2 } },
				},
			},
			{
				Name = "Shell hoard",
				Maze = {
					"+ + + +",
					"  |    ",
					"+ + +-+",
					"  | |  ",
					"+ + + +",
					"       ",
					"+ + + +",
				},
				Loot = { { 0, 0, 4 }, { 2, 1, 2 } },
			},
			{
				Name = "Flooded cellar",
				Maze = {
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
					"       ",
					"+ + + +",
				},
				Extra = {
					{ Kind = "Hollow", At = { cx(1), cz(1) }, Radius = 18, Depth = 3 },
				},
				Loot = { { 0, 2, 3 }, { 2, 2, 3 } },
			},
		},
	},
}

local slots = {}
for _, slot in SLOT_ROOMS do
	local rooms = {}
	for _, spec in slot.Rooms do
		table.insert(rooms, roomOf(spec))
	end
	table.insert(slots, { Name = slot.Name, At = slot.At, Size = slot.Size, Rooms = rooms })
end
zone4.Slots = slots

-- Zones 5 and 6 share one frame with zone 4: five walls across the tile (z 20, 48, 76, 104
-- and 132, all on the 4-stud grid), lanes 16 wide between them (z 34, 62, 90 and 118), and
-- cells split by walls running down the beach. Each zone is a step deeper than the one above.

-- A wall of the given height, 12 wide.
local function wallOf(height)
	return function(path)
		return { Kind = "Wall", Path = path, Height = height, Width = 12 }
	end
end

-- A roof resting on walls, with its underside at `clearance`.
local function roofOf(clearance, thickness)
	return function(path, width)
		return { Kind = "Roof", Path = path, Width = width, Clearance = clearance, Thickness = thickness }
	end
end

-- A roof over a gap in the wall line at z, centred on x.
local function gapRoof(makeRoof, x, z)
	return makeRoof({ { x, z - 3 }, { x, z + 3 } }, 20)
end

-- Zone 5: the sump. Lower and wetter: lower roofs, and the middle maze's lanes are sunk
-- 4 studs below the slope, so they flood long before the waterline reaches them.
local w5 = wallOf(18)
local r5 = roofOf(14, 8)

local function sunk(path)
	return { Kind = "Channel", Path = path, Depth = 4, Width = 16 }
end

local zone5 = {
	Name = "Hermit Hollows (zone 5)",
	Primitives = {
		-- Cart ramps: each zig-zags 80 studs outward, away from the middle, in every lane.
		{
			Kind = "Ramp",
			Path = {
				{ -200, 0 },
				{ -200, 34 },
				{ -280, 34 },
				{ -280, 62 },
				{ -200, 62 },
				{ -200, 90 },
				{ -280, 90 },
				{ -280, 118 },
				{ -200, 118 },
				{ -200, 150 },
			},
			Width = 14,
		},
		{
			Kind = "Ramp",
			Path = {
				{ 180, 0 },
				{ 180, 34 },
				{ 260, 34 },
				{ 260, 62 },
				{ 180, 62 },
				{ 180, 90 },
				{ 260, 90 },
				{ 260, 118 },
				{ 180, 118 },
				{ 180, 150 },
			},
			Width = 14,
		},
		-- Walls across the tile. The middle maze's way through: gaps at x -120, -40, the
		-- chamber, 50 and -10.
		w5({ { -360, 20 }, { -214, 20 } }),
		w5({ { -186, 20 }, { -134, 20 } }),
		w5({ { -106, 20 }, { 166, 20 } }),
		w5({ { 194, 20 }, { 360, 20 } }),
		w5({ { -360, 48 }, { -354, 48 } }),
		w5({ { -326, 48 }, { -294, 48 } }),
		w5({ { -266, 48 }, { -54, 48 } }),
		w5({ { -26, 48 }, { 246, 48 } }),
		w5({ { 274, 48 }, { 360, 48 } }),
		w5({ { -360, 76 }, { -354, 76 } }),
		w5({ { -326, 76 }, { -214, 76 } }),
		w5({ { -186, 76 }, { -44, 76 } }),
		w5({ { 54, 76 }, { 166, 76 } }),
		w5({ { 194, 76 }, { 326, 76 } }),
		w5({ { 354, 76 }, { 360, 76 } }),
		w5({ { -360, 104 }, { -354, 104 } }),
		w5({ { -326, 104 }, { -294, 104 } }),
		w5({ { -266, 104 }, { 36, 104 } }),
		w5({ { 64, 104 }, { 246, 104 } }),
		w5({ { -360, 132 }, { -214, 132 } }),
		w5({ { -186, 132 }, { -24, 132 } }),
		w5({ { 4, 132 }, { 166, 132 } }),
		w5({ { 194, 132 }, { 360, 132 } }),
		-- Walls down the beach: the ramp cells' sides, with a door into the burrow (west) and
		-- the gallery (east).
		w5({ { -312, 20 }, { -312, 48 } }),
		w5({ { -312, 76 }, { -312, 132 } }),
		w5({ { -176, 20 }, { -176, 132 } }),
		w5({ { 156, 20 }, { 156, 132 } }),
		w5({ { 284, 48 }, { 284, 76 } }),
		w5({ { 284, 104 }, { 284, 132 } }),
		-- The middle maze's sunken lanes, and the cut through its last two gaps toward the sea.
		sunk({ { -160, 34 }, { 140, 34 } }),
		sunk({ { -160, 62 }, { 140, 62 } }),
		sunk({ { -160, 90 }, { 140, 90 } }),
		sunk({ { -160, 118 }, { 140, 118 } }),
		sunk({ { 50, 90 }, { 50, 118 } }),
		sunk({ { -10, 118 }, { -10, 146 } }),
		-- The gallery's pool.
		{ Kind = "Hollow", At = { 326, 106 }, Radius = 14, Depth = 3 },
		-- Roofs: every lane but the chamber and the gallery.
		r5({ { -366, 34 }, { 366, 34 } }, 28),
		r5({ { -366, 62 }, { -52, 62 } }, 28),
		r5({ { 62, 62 }, { 366, 62 } }, 28),
		r5({ { -366, 90 }, { -52, 90 } }, 28),
		r5({ { 62, 90 }, { 276, 90 } }, 28),
		r5({ { -366, 118 }, { 276, 118 } }, 28),
		gapRoof(r5, -200, 20),
		gapRoof(r5, -120, 20),
		gapRoof(r5, 180, 20),
		gapRoof(r5, -340, 48),
		gapRoof(r5, -280, 48),
		gapRoof(r5, -40, 48),
		gapRoof(r5, 260, 48),
		gapRoof(r5, -340, 76),
		gapRoof(r5, -200, 76),
		gapRoof(r5, 180, 76),
		gapRoof(r5, -340, 104),
		gapRoof(r5, -280, 104),
		gapRoof(r5, 50, 104),
		gapRoof(r5, 260, 104),
		gapRoof(r5, -200, 132),
		gapRoof(r5, -10, 132),
		gapRoof(r5, 180, 132),
		-- The chamber: a dry shelf between the sunken lanes, open to the sky.
		{ Kind = "Flat", At = { 5, 76 }, Radius = 12 },
		{ Kind = "Mound", At = { 36, 66 }, Radius = 8, Height = 5, Rock = true },
	},
	Loot = {
		{ At = { -340, 118 }, Radius = 6, Weight = 5 },
		{ At = { -340, 34 }, Radius = 6, Weight = 3 },
		{ At = { 330, 62 }, Radius = 6, Weight = 5 },
		{ At = { 308, 92 }, Radius = 6, Weight = 3 },
		{ At = { 336, 34 }, Radius = 6, Weight = 2 },
		{ At = { 130, 34 }, Radius = 6, Weight = 3 },
		{ At = { -150, 62 }, Radius = 6, Weight = 2 },
		{ At = { 130, 62 }, Radius = 6, Weight = 2 },
		{ At = { -150, 90 }, Radius = 6, Weight = 3 },
		{ At = { 130, 90 }, Radius = 6, Weight = 2 },
		{ At = { 130, 118 }, Radius = 6, Weight = 3 },
		{ At = { -150, 118 }, Radius = 6, Weight = 2 },
	},
	Entrances = { { 5, 76 } },
	Hazards = {
		{ Type = "Patrol", Path = { { -270, 62 }, { -210, 62 } }, Count = 1 },
		{ Type = "Patrol", Path = { { 190, 34 }, { 250, 34 } }, Count = 1 },
		{ Type = "Patrol", Path = { { 190, 90 }, { 250, 90 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -130, 34 }, { -30, 34 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -10, 90 }, { 90, 90 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -30, 118 }, { 90, 118 } }, Count = 1 },
	},
}

-- Zone 6: the labyrinth. Taller walls, roofed all but one chamber, ramps that swing 120
-- studs a lane, and a middle maze of false doors and long dead ends.
local w6 = wallOf(24)
local r6 = roofOf(20, 8)

local zone6 = {
	Name = "Hermit Hollows (zone 6)",
	Primitives = {
		-- Cart ramps: 120-stud switchbacks, outward.
		{
			Kind = "Ramp",
			Path = {
				{ -200, 0 },
				{ -200, 34 },
				{ -320, 34 },
				{ -320, 62 },
				{ -200, 62 },
				{ -200, 90 },
				{ -320, 90 },
				{ -320, 118 },
				{ -200, 118 },
				{ -200, 150 },
			},
			Width = 14,
		},
		{
			Kind = "Ramp",
			Path = {
				{ 180, 0 },
				{ 180, 34 },
				{ 300, 34 },
				{ 300, 62 },
				{ 180, 62 },
				{ 180, 90 },
				{ 300, 90 },
				{ 300, 118 },
				{ 180, 118 },
				{ 180, 150 },
			},
			Width = 14,
		},
		-- Walls across the tile. The middle maze's way through: gaps at x -130, -50, 90, -10
		-- and -100. False doors at 90 (first wall) and 130 (fourth) lead to dead ends.
		w6({ { -360, 20 }, { -214, 20 } }),
		w6({ { -186, 20 }, { -144, 20 } }),
		w6({ { -116, 20 }, { 76, 20 } }),
		w6({ { 104, 20 }, { 166, 20 } }),
		w6({ { 194, 20 }, { 360, 20 } }),
		w6({ { -360, 48 }, { -334, 48 } }),
		w6({ { -306, 48 }, { -64, 48 } }),
		w6({ { -36, 48 }, { 286, 48 } }),
		w6({ { 314, 48 }, { 360, 48 } }),
		w6({ { -360, 76 }, { -214, 76 } }),
		w6({ { -100, 76 }, { 76, 76 } }),
		w6({ { 104, 76 }, { 166, 76 } }),
		w6({ { 194, 76 }, { 360, 76 } }),
		w6({ { -360, 104 }, { -334, 104 } }),
		w6({ { -306, 104 }, { -24, 104 } }),
		w6({ { 4, 104 }, { 116, 104 } }),
		w6({ { 144, 104 }, { 286, 104 } }),
		w6({ { 314, 104 }, { 360, 104 } }),
		w6({ { -360, 132 }, { -214, 132 } }),
		w6({ { -186, 132 }, { -114, 132 } }),
		w6({ { -86, 132 }, { 166, 132 } }),
		w6({ { 194, 132 }, { 360, 132 } }),
		-- Walls down the beach: the ramp cells' sides and the maze's dividers.
		w6({ { -176, 20 }, { -176, 132 } }),
		w6({ { 156, 20 }, { 156, 132 } }),
		w6({ { 24, 20 }, { 24, 48 } }),
		w6({ { -60, 76 }, { -60, 104 } }),
		w6({ { 40, 104 }, { 40, 132 } }),
		-- The rubble in the fourth wall's gap: a scramble on foot, too steep for a cart.
		{ Kind = "Ridge", Path = { { -24, 104 }, { 4, 104 } }, Height = 5, Width = 20 },
		-- Roofs: everything but the chamber.
		r6({ { -366, 34 }, { 366, 34 } }, 28),
		r6({ { -366, 62 }, { -184, 62 } }, 28),
		r6({ { -92, 62 }, { 366, 62 } }, 28),
		r6({ { -366, 90 }, { -184, 90 } }, 28),
		r6({ { -92, 90 }, { 366, 90 } }, 28),
		r6({ { -366, 118 }, { 366, 118 } }, 28),
		gapRoof(r6, -200, 20),
		gapRoof(r6, -130, 20),
		gapRoof(r6, 90, 20),
		gapRoof(r6, 180, 20),
		gapRoof(r6, -320, 48),
		gapRoof(r6, -50, 48),
		gapRoof(r6, 300, 48),
		gapRoof(r6, -200, 76),
		gapRoof(r6, 90, 76),
		gapRoof(r6, 180, 76),
		gapRoof(r6, -320, 104),
		gapRoof(r6, -10, 104),
		gapRoof(r6, 130, 104),
		gapRoof(r6, 300, 104),
		gapRoof(r6, -200, 132),
		gapRoof(r6, -100, 132),
		gapRoof(r6, 180, 132),
		-- The chamber, off the second lane's west end.
		{ Kind = "Flat", At = { -140, 76 }, Radius = 12 },
		{ Kind = "Mound", At = { -112, 62 }, Radius = 7, Height = 5, Rock = true },
	},
	Loot = {
		{ At = { 60, 118 }, Radius = 6, Weight = 5 },
		{ At = { -80, 90 }, Radius = 6, Weight = 4 },
		{ At = { 120, 34 }, Radius = 6, Weight = 2 },
		{ At = { -158, 34 }, Radius = 6, Weight = 1 },
		{ At = { 136, 62 }, Radius = 6, Weight = 2 },
		{ At = { 136, 90 }, Radius = 6, Weight = 3 },
		{ At = { -150, 118 }, Radius = 6, Weight = 2 },
		{ At = { -345, 62 }, Radius = 6, Weight = 3 },
		{ At = { -345, 118 }, Radius = 6, Weight = 4 },
		{ At = { 340, 34 }, Radius = 6, Weight = 3 },
		{ At = { 340, 90 }, Radius = 6, Weight = 4 },
	},
	Entrances = { { -140, 76 } },
	Hazards = {
		{ Type = "Patrol", Path = { { -310, 34 }, { -210, 34 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -310, 90 }, { -210, 90 } }, Count = 1 },
		{ Type = "Patrol", Path = { { 190, 62 }, { 290, 62 } }, Count = 1 },
		{ Type = "Patrol", Path = { { 190, 118 }, { 290, 118 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -150, 34 }, { -60, 34 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -40, 62 }, { 100, 62 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -40, 90 }, { 100, 90 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -110, 118 }, { 30, 118 } }, Count = 1 },
	},
}

return {
	[4] = zone4,
	[5] = Tiled(zone5),
	[6] = Tiled(zone6),
}
