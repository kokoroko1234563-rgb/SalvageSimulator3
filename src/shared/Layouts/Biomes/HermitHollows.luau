-- Hermit Hollows, zones 4 to 6. See docs/layouts/HermitHollows.md.
local function wall(path)
	return { Kind = "Wall", Path = path, Height = 22, Width = 12 }
end

local function roof(path, width)
	return { Kind = "Roof", Path = path, Width = width, Clearance = 20, Thickness = 8 }
end

local layout = {
	Name = "Hermit Hollows (zone 4)",
	Primitives = {
		-- Cart ramps
		{
			Kind = "Ramp",
			Path = {
				{ -200, 0 },
				{ -200, 34 },
				{ -124, 34 },
				{ -124, 62 },
				{ -200, 62 },
				{ -200, 90 },
				{ -124, 90 },
				{ -124, 118 },
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
				{ 104, 34 },
				{ 104, 62 },
				{ 180, 62 },
				{ 180, 90 },
				{ 104, 90 },
				{ 104, 118 },
				{ 180, 118 },
				{ 180, 150 },
			},
			Width = 14,
		},
		-- Row walls and dividers
		wall({ { -360, 20 }, { -214, 20 } }),
		wall({ { -186, 20 }, { 46, 20 } }),
		wall({ { 74, 20 }, { 166, 20 } }),
		wall({ { 194, 20 }, { 280, 20 }, { 360, 20 } }),
		wall({ { -360, 48 }, { -304, 48 } }),
		wall({ { -276, 48 }, { -138, 48 } }),
		wall({ { -110, 48 }, { -34, 48 } }),
		wall({ { -6, 48 }, { 90, 48 } }),
		wall({ { 118, 48 }, { 226, 48 } }),
		wall({ { 306, 48 }, { 360, 48 } }),
		wall({ { -360, 76 }, { -334, 76 } }),
		wall({ { -306, 76 }, { -214, 76 } }),
		wall({ { -186, 76 }, { -66, 76 } }),
		wall({ { 16, 76 }, { 166, 76 } }),
		wall({ { 194, 76 }, { 226, 76 } }),
		wall({ { 306, 76 }, { 360, 76 } }),
		wall({ { -360, 104 }, { -304, 104 } }),
		wall({ { -276, 104 }, { -138, 104 } }),
		wall({ { -110, 104 }, { 22, 104 } }),
		wall({ { 74, 104 }, { 90, 104 } }),
		wall({ { 118, 104 }, { 248, 104 } }),
		wall({ { 276, 104 }, { 360, 104 } }),
		wall({ { -360, 132 }, { -214, 132 } }),
		wall({ { -186, 132 }, { -34, 132 } }),
		wall({ { -6, 132 }, { 166, 132 } }),
		wall({ { 194, 132 }, { 360, 132 } }),
		wall({ { -250, 48 }, { -250, 76 }, { -250, 104 }, { -250, 132 } }),
		wall({ { -70, 20 }, { -70, 48 }, { -70, 76 } }),
		wall({ { -70, 104 }, { -70, 132 } }),
		wall({ { 90, 20 }, { 90, 48 } }),
		wall({ { 90, 76 }, { 90, 104 }, { 90, 132 } }),
		wall({ { 232, 20 }, { 232, 48 }, { 232, 76 } }),
		wall({ { 232, 104 }, { 232, 132 } }),
		wall({ { 300, 20 }, { 300, 48 }, { 300, 76 }, { 300, 104 } }),
		-- Foot scrambles
		{ Kind = "Ridge", Path = { { 28, 104 }, { 64, 104 } }, Height = 5, Width = 20 },
		-- Roofs
		roof({ { -366, 34 }, { 232, 34 } }, 28),
		roof({ { 300, 34 }, { 366, 34 } }, 28),
		roof({ { -366, 62 }, { -60, 62 } }, 28),
		roof({ { 10, 62 }, { 232, 62 } }, 28),
		roof({ { 300, 62 }, { 366, 62 } }, 28),
		roof({ { -366, 90 }, { -60, 90 } }, 28),
		roof({ { 10, 90 }, { 232, 90 } }, 28),
		roof({ { 300, 90 }, { 366, 90 } }, 28),
		roof({ { -366, 118 }, { 366, 118 } }, 28),
		roof({ { -200, 17 }, { -200, 23 } }, 20),
		roof({ { 60, 17 }, { 60, 23 } }, 20),
		roof({ { 180, 17 }, { 180, 23 } }, 20),
		roof({ { -124, 45 }, { -124, 51 } }, 20),
		roof({ { -290, 45 }, { -290, 51 } }, 20),
		roof({ { -20, 45 }, { -20, 51 } }, 20),
		roof({ { 104, 45 }, { 104, 51 } }, 20),
		roof({ { -200, 73 }, { -200, 79 } }, 20),
		roof({ { -320, 73 }, { -320, 79 } }, 20),
		roof({ { 180, 73 }, { 180, 79 } }, 20),
		roof({ { -124, 101 }, { -124, 107 } }, 20),
		roof({ { -290, 101 }, { -290, 107 } }, 20),
		roof({ { 60, 101 }, { 60, 107 } }, 20),
		roof({ { 104, 101 }, { 104, 107 } }, 20),
		roof({ { 262, 101 }, { 262, 107 } }, 20),
		roof({ { -200, 129 }, { -200, 135 } }, 20),
		roof({ { -20, 129 }, { -20, 135 } }, 20),
		roof({ { 180, 129 }, { 180, 135 } }, 20),
		-- Chambers
		{ Kind = "Mound", At = { -52, 92 }, Radius = 8, Height = 6, Rock = true },
		{ Kind = "Mound", At = { 6, 92 }, Radius = 8, Height = 6, Rock = true },
		{ Kind = "Mound", At = { 292, 60 }, Radius = 8, Height = 6, Rock = true },
		{ Kind = "Mound", At = { 276, 34 }, Radius = 8, Height = 5, Rock = true },
		{ Kind = "Flat", At = { -25, 76 }, Radius = 12 },
	},
	Loot = {
		{ At = { -332, 118 }, Radius = 6, Weight = 5 },
		{ At = { -268, 90 }, Radius = 6, Weight = 3 },
		{ At = { -332, 62 }, Radius = 6, Weight = 3 },
		{ At = { -236, 90 }, Radius = 6, Weight = 1 },
		{ At = { -54, 34 }, Radius = 6, Weight = 2 },
		{ At = { 80, 34 }, Radius = 6, Weight = 2 },
		{ At = { 215, 90 }, Radius = 6, Weight = 3 },
		{ At = { 288, 88 }, Radius = 6, Weight = 3 },
		{ At = { 322, 118 }, Radius = 6, Weight = 5 },
		{ At = { 270, 118 }, Radius = 6, Weight = 3 },
	},
	Entrances = { { -25, 76 } },
	Hazards = {
		{ Type = "Patrol", Path = { { -190, 62 }, { -134, 62 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -190, 90 }, { -134, 90 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -190, 118 }, { -134, 118 } }, Count = 1 },
		{ Type = "Patrol", Path = { { 170, 34 }, { 114, 34 } }, Count = 1 },
		{ Type = "Patrol", Path = { { 170, 90 }, { 114, 90 } }, Count = 1 },
		{ Type = "Patrol", Path = { { -60, 62 }, { 40, 62 } }, Count = 1 },
	},
}

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
local function gapRoof(roof, x, z)
	return roof({ { x, z - 3 }, { x, z + 3 } }, 20)
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

return { [4] = layout, [5] = zone5, [6] = zone6 }
