-- Zone 5, The Shoals (base layout): three low rock bars across the beach with flooded lanes
-- between them. The quick way down is through the fords, rock gaps whose floor is cut below the
-- slope, zig-zagging through the middle; the dry gaps carry the cart ramps out to the cliffs and
-- back, a much longer way. The seaward ford goes under first, so on the way back up the quick
-- way is cut off one ford at a time. The middle ford runs through the Grotto, a cave either side
-- of the second bar.

-- A low rock bar across the beach, from x0 to x1.
local function bar(z, x0, x1)
	return { Kind = "Wall", Path = { { x0, z }, { x1, z } }, Height = 12, Width = 12 }
end

-- A short wall running down the beach, from z0 to z1.
local function spur(x, z0, z1)
	return { Kind = "Wall", Path = { { x, z0 }, { x, z1 } }, Height = 12, Width = 12 }
end

-- A ford: a cut down through a bar's gap, deep enough to flood early.
local function ford(x, z)
	return { Kind = "Channel", Path = { { x, z - 22 }, { x, z + 22 } }, Depth = 4, Width = 16 }
end

-- A sand sill across a ford's gap: a scramble on foot, too steep for a cart.
local function sill(x, z)
	return { Kind = "Ridge", Path = { { x - 12, z }, { x + 12, z } }, Height = 3.5, Width = 16 }
end

return {
	Name = "The Shoals (base)",
	Primitives = {
		-- First bar (z 28): dry gaps at x -200 and 180 (the ramps), fords at -120 and 120.
		bar(28, -360, -216),
		bar(28, -184, -136),
		bar(28, -104, 104),
		bar(28, 136, 164),
		bar(28, 196, 360),
		-- Second bar (z 76): dry gaps against the cliffs (the ramps), the ford at x 0.
		bar(76, -320, -16),
		bar(76, 16, 320),
		-- Third bar (z 120): gaps like the first.
		bar(120, -360, -216),
		bar(120, -184, -136),
		bar(120, -104, 104),
		bar(120, 136, 164),
		bar(120, 196, 360),

		-- The fords, each with a sand sill across its gap.
		ford(-120, 28),
		ford(120, 28),
		ford(0, 76),
		ford(-120, 120),
		ford(120, 120),
		sill(-120, 28),
		sill(120, 28),
		sill(0, 76),
		sill(-120, 120),
		sill(120, 120),
		-- Shoals: shallow cuts along the middle of both lanes, joining the fords.
		{ Kind = "Channel", Path = { { -170, 52 }, { 170, 52 } }, Depth = 2, Width = 20 },
		{ Kind = "Channel", Path = { { -170, 98 }, { 170, 98 } }, Depth = 2, Width = 20 },

		-- The Grotto: a cave either side of the middle ford.
		{ Kind = "Roof", At = { 0, 52 }, Radius = 28, Clearance = 10, Thickness = 6 },
		{ Kind = "Roof", At = { 0, 98 }, Radius = 22, Clearance = 10, Thickness = 6 },
		-- Low spurs off the second bar that the way to and from the middle ford must go round,
		-- each closing a pocket beside the Grotto.
		spur(-64, 56, 70),
		spur(64, 56, 70),
		spur(-64, 82, 92),
		spur(64, 82, 92),

		-- Cart ramps: through the dry gaps, out to the cliffs at the second bar and back.
		{
			Kind = "Ramp",
			Path = {
				{ -200, 0 },
				{ -200, 40 },
				{ -232, 52 },
				{ -320, 52 },
				{ -344, 64 },
				{ -344, 88 },
				{ -320, 98 },
				{ -232, 98 },
				{ -200, 108 },
				{ -200, 150 },
			},
			Width = 16,
		},
		{
			Kind = "Ramp",
			Path = {
				{ 180, 0 },
				{ 180, 40 },
				{ 212, 52 },
				{ 320, 52 },
				{ 344, 64 },
				{ 344, 88 },
				{ 320, 98 },
				{ 212, 98 },
				{ 180, 108 },
				{ 180, 150 },
			},
			Width = 16,
		},
	},
	Loot = {
		-- The Grotto, and the pockets behind the spurs.
		{ At = { 0, 52 }, Radius = 6, Weight = 3 },
		{ At = { -40, 62 }, Radius = 5, Weight = 2 },
		{ At = { 40, 62 }, Radius = 5, Weight = 2 },
		{ At = { -40, 90 }, Radius = 5, Weight = 2 },
		{ At = { 40, 90 }, Radius = 5, Weight = 2 },
		-- The lanes' far corners, off the quick way.
		{ At = { -160, 52 }, Radius = 6, Weight = 1 },
		{ At = { 150, 52 }, Radius = 6, Weight = 1 },
		{ At = { -160, 98 }, Radius = 6, Weight = 1 },
		{ At = { 150, 98 }, Radius = 6, Weight = 1 },
		-- Out by the cliffs, where only the ramps go.
		{ At = { -330, 108 }, Radius = 6, Weight = 1 },
		{ At = { 330, 40 }, Radius = 6, Weight = 1 },
	},
}
