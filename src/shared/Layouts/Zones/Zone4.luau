-- Zone 4, Outer Shore / Reef (base layout): three long rock walls across the beach, each with
-- three gaps. Each wall's gaps sit 80 studs along from the last one's, so to go straight down
-- you have to keep sidling in one direction; the pattern repeats every 240 studs. One gap in
-- the middle wall is a short roofed tunnel. U-shaped pockets between the walls hold the best
-- loot, and the low ground floods first.
local tileLayout = {
	Name = "Outer Shore (base)",
	Primitives = {
		-- First wall (gaps at x -300, -60 and 180).
		{ Kind = "Wall", Path = { { -360, 34 }, { -312, 34 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { -288, 34 }, { -72, 34 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { -48, 34 }, { 168, 34 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { 192, 34 }, { 360, 34 } }, Height = 16, Width = 16 },
		-- Second wall (gaps at x -220, the tunnel at 20, and 260).
		{ Kind = "Wall", Path = { { -360, 94 }, { -232, 94 } }, Height = 15, Width = 16 },
		{ Kind = "Wall", Path = { { -208, 94 }, { 8, 94 } }, Height = 15, Width = 16 },
		{ Kind = "Wall", Path = { { 32, 94 }, { 248, 94 } }, Height = 15, Width = 16 },
		{ Kind = "Wall", Path = { { 272, 94 }, { 360, 94 } }, Height = 15, Width = 16 },
		-- The tunnel through the second wall: two side walls with a roof on top.
		{ Kind = "Wall", Path = { { 2, 76 }, { 2, 112 } }, Height = 15, Width = 16 },
		{ Kind = "Wall", Path = { { 38, 76 }, { 38, 112 } }, Height = 15, Width = 16 },
		{ Kind = "Roof", Path = { { 20, 92 }, { 20, 96 } }, Width = 44, Clearance = 12, Thickness = 6 },
		-- Third wall (gaps at x -140, 130 and 336).
		{ Kind = "Wall", Path = { { -360, 134 }, { -152, 134 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { -128, 134 }, { 118, 134 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { 142, 134 }, { 324, 134 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { 348, 134 }, { 360, 134 } }, Height = 16, Width = 16 },

		-- Dead-end pockets: two spurs off the first wall, open to the south.
		{ Kind = "Wall", Path = { { -166, 42 }, { -166, 55 } }, Height = 14, Width = 16 },
		{ Kind = "Wall", Path = { { -126, 42 }, { -126, 55 } }, Height = 14, Width = 16 },
		{ Kind = "Wall", Path = { { 90, 42 }, { 90, 55 } }, Height = 14, Width = 16 },
		{ Kind = "Wall", Path = { { 130, 42 }, { 130, 55 } }, Height = 14, Width = 16 },
		-- Boulders and hollows in the lanes.
		{ Kind = "Mound", At = { -20, 64 }, Radius = 9, Height = 5, Rock = true },
		{ Kind = "Mound", At = { 300, 56 }, Radius = 8, Height = 4, Rock = true },
		{ Kind = "Mound", At = { -250, 162 }, Radius = 8, Height = 5, Rock = true },
		{ Kind = "Mound", At = { 150, 160 }, Radius = 8, Height = 5, Rock = true },
		{ Kind = "Hollow", At = { -250, 64 }, Radius = 10, Depth = 2 },
		{ Kind = "Hollow", At = { 30, 62 }, Radius = 12, Depth = 2 },
		-- The seaward ford: cut in front of the sea, so it floods first.
		{ Kind = "Channel", Path = { { -100, 150 }, { 0, 148 }, { 100, 150 } }, Depth = 3, Width = 12 },
		-- Cart ramps wind through the gaps.
		{
			Kind = "Ramp",
			Path = {
				{ -200, 0 },
				{ -250, 14 },
				{ -300, 24 },
				{ -300, 44 },
				{ -270, 58 },
				{ -235, 72 },
				{ -220, 82 },
				{ -220, 102 },
				{ -190, 112 },
				{ -160, 114 },
				{ -140, 124 },
				{ -140, 144 },
				{ -170, 146 },
				{ -200, 150 },
			},
			Width = 16,
		},
		{
			Kind = "Ramp",
			Path = {
				{ 180, 0 },
				{ 180, 24 },
				{ 180, 44 },
				{ 200, 70 },
				{ 230, 86 },
				{ 260, 92 },
				{ 260, 102 },
				{ 230, 112 },
				{ 180, 114 },
				{ 140, 118 },
				{ 130, 126 },
				{ 130, 144 },
				{ 160, 149 },
				{ 180, 150 },
			},
			Width = 16,
		},
	},
	Loot = {
		{ At = { -150, 50 }, Radius = 6, Weight = 3 },
		{ At = { 110, 50 }, Radius = 6, Weight = 3 },
		{ At = { 20, 94 }, Radius = 5, Weight = 2 },
		{ At = { -330, 100 }, Radius = 6, Weight = 2 },
		{ At = { 320, 8 }, Radius = 6, Weight = 2 },
		{ At = { -60, 112 }, Radius = 6, Weight = 1 },
		{ At = { 0, 10 }, Radius = 6, Weight = 1 },
	},
}

-- Drawn for the old 152-stud tiles: repeated down the zone (Layouts/Tiled).
return require(script.Parent.Parent.Tiled)(tileLayout)
