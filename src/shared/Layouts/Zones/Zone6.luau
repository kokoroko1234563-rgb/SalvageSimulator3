-- Zone 6, The Drowned Reach (base layout): the deepest, slowest ground, a maze of tall rock
-- walls in three cells. Each outer cell holds a cart ramp that winds through three long
-- galleries, out to the cliffs and back. The middle cell is a tight maze of sunken lanes, the
-- quick way on foot, shut to carts by rubble. The ends of the galleries the ramps don't use
-- are dead ends, and the roofed ones by the cliffs hold the best finds. See
-- docs/layouts/Zone6.md.
--
-- The ramps clear and blend the ground 15 studs either side of their centre lines, so the
-- walls beside a ramp keep about that far from it: the galleries' walls are 44 apart.
local function wall(path)
	return { Kind = "Wall", Path = path, Height = 24, Width = 12 }
end

-- Rock overhead, resting on the walls either side.
local function roof(path, width)
	return { Kind = "Roof", Path = path, Width = width, Clearance = 22, Thickness = 8 }
end

-- A pile of rubble filling a gap in a wall: a scramble on foot, too steep for a cart.
local function rubble(path)
	return { Kind = "Ridge", Path = path, Height = 4, Width = 20 }
end

-- A sunken lane floor: low ground that floods early.
local function sunk(path)
	return { Kind = "Channel", Path = path, Depth = 2, Width = 12 }
end

return {
	Name = "The Drowned Reach (base)",
	Primitives = {
		-- The west ramp cell (x -360 to -80): galleries at z 32, 74 and 116. The ramp comes
		-- down at x -200, runs east to -104, back west the whole gallery to -330 by the
		-- cliff, then east again to -200 and out.
		wall({ { -360, 12 }, { -222, 12 } }),
		wall({ { -178, 12 }, { -166, 12 } }),
		wall({ { -138, 12 }, { -80, 12 } }),
		wall({ { -360, 52 }, { -126, 52 } }),
		wall({ { -310, 96 }, { -80, 96 } }),
		wall({ { -360, 136 }, { -222, 136 } }),
		wall({ { -178, 136 }, { -80, 136 } }),
		wall({ { -80, 12 }, { -80, 136 } }),

		-- The east ramp cell (x 60 to 360), the same the other way round: down at x 180, west
		-- to 84, east to 310, west to 180 and out.
		wall({ { 60, 12 }, { 118, 12 } }),
		wall({ { 146, 12 }, { 154, 12 } }),
		wall({ { 202, 12 }, { 360, 12 } }),
		wall({ { 106, 52 }, { 360, 52 } }),
		wall({ { 60, 96 }, { 290, 96 } }),
		wall({ { 60, 136 }, { 158, 136 } }),
		wall({ { 202, 136 }, { 360, 136 } }),
		wall({ { 60, 12 }, { 60, 136 } }),

		-- Rubble in a gap into each ramp cell's first gallery: a short cut on foot.
		rubble({ { -166, 12 }, { -138, 12 } }),
		rubble({ { 118, 12 }, { 146, 12 } }),

		-- The middle cell (x -74 to 54): five walls 28 apart, with gaps that swap sides
		-- (x -60, then 32), so every lane is walked end to end. Its first and fourth gaps are
		-- choked with rubble, so no cart gets in.
		wall({ { -46, 20 }, { 60, 20 } }),
		wall({ { -80, 48 }, { 18, 48 } }),
		wall({ { 46, 48 }, { 60, 48 } }),
		wall({ { -46, 76 }, { 60, 76 } }),
		wall({ { -80, 104 }, { 18, 104 } }),
		wall({ { 46, 104 }, { 60, 104 } }),
		wall({ { -46, 132 }, { 60, 132 } }),
		rubble({ { -74, 20 }, { -46, 20 } }),
		rubble({ { 18, 104 }, { 46, 104 } }),
		-- Its lanes are sunk two studs: the low ground floods first.
		sunk({ { -68, 34 }, { 48, 34 } }),
		sunk({ { -68, 62 }, { 48, 62 } }),
		sunk({ { -68, 90 }, { 48, 90 } }),
		sunk({ { -68, 118 }, { 48, 118 } }),

		-- The drowned pool, in the west cell's dead-end gallery.
		{ Kind = "Hollow", At = { -300, 32 }, Radius = 10, Depth = 3 },

		-- Roofs: the ramp cells' long middle galleries, their dead-end galleries by the cliffs,
		-- and the middle cell's two inner lanes.
		roof({ { -364, 74 }, { -80, 74 } }, 44),
		roof({ { 60, 74 }, { 364, 74 } }, 44),
		roof({ { -364, 32 }, { -224, 32 } }, 40),
		roof({ { 224, 32 }, { 364, 32 } }, 40),
		roof({ { -80, 62 }, { 60, 62 } }, 28),
		roof({ { -80, 90 }, { 60, 90 } }, 28),

		-- Cart ramps.
		{
			Kind = "Ramp",
			Path = {
				{ -200, 0 },
				{ -200, 32 },
				{ -104, 32 },
				{ -104, 74 },
				{ -330, 74 },
				{ -330, 116 },
				{ -200, 116 },
				{ -200, 150 },
			},
			Width = 14,
		},
		{
			Kind = "Ramp",
			Path = {
				{ 180, 0 },
				{ 180, 32 },
				{ 84, 32 },
				{ 84, 74 },
				{ 310, 74 },
				{ 310, 116 },
				{ 180, 116 },
				{ 180, 150 },
			},
			Width = 14,
		},
	},
	Loot = {
		-- The roofed dead-end galleries by the cliffs: the best finds at their far ends.
		{ At = { -342, 32 }, Radius = 6, Weight = 5 },
		{ At = { -300, 32 }, Radius = 8, Weight = 3 },
		{ At = { 342, 32 }, Radius = 6, Weight = 5 },
		{ At = { 270, 32 }, Radius = 6, Weight = 3 },
		-- The open dead-end galleries at the ramp cells' inner sides.
		{ At = { -120, 116 }, Radius = 6, Weight = 2 },
		{ At = { 100, 116 }, Radius = 6, Weight = 2 },
		-- The middle cell's dead-end pockets.
		{ At = { 47, 34 }, Radius = 5, Weight = 1 },
		{ At = { 47, 62 }, Radius = 5, Weight = 2 },
		{ At = { 47, 90 }, Radius = 5, Weight = 2 },
		{ At = { 47, 118 }, Radius = 5, Weight = 1 },
	},
}
