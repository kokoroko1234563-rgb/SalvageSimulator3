-- Zone 4, Outer Shore / Reef (base layout): three long rock walls across the beach, each with a
-- few gaps. The gaps are staggered by about 100 studs from one wall to the next, so you zig-zag
-- from one to the next. One gap in the middle wall is a short roofed tunnel. Boulders and
-- dead-end pockets between the walls hold the loot, and the low ground at the seaward end of
-- the tile floods first.
return {
	Name = "Outer Shore (base)",
	Primitives = {
		-- First wall (gaps at x -230, -50 and 250).
		{ Kind = "Wall", Path = { { -360, 30 }, { -242, 30 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { -218, 30 }, { -62, 30 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { -38, 30 }, { 238, 30 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { 262, 30 }, { 360, 30 } }, Height = 16, Width = 16 },
		-- Second wall (gaps at x -100, the tunnel at 60, and 120).
		{ Kind = "Wall", Path = { { -360, 94 }, { -112, 94 } }, Height = 15, Width = 16 },
		{ Kind = "Wall", Path = { { -88, 94 }, { 42, 94 } }, Height = 15, Width = 16 },
		{ Kind = "Wall", Path = { { 78, 94 }, { 108, 94 } }, Height = 15, Width = 16 },
		{ Kind = "Wall", Path = { { 132, 94 }, { 360, 94 } }, Height = 15, Width = 16 },
		-- The tunnel through the second wall: two side walls with a roof on top.
		{ Kind = "Wall", Path = { { 42, 76 }, { 42, 112 } }, Height = 15, Width = 16 },
		{ Kind = "Wall", Path = { { 78, 76 }, { 78, 112 } }, Height = 15, Width = 16 },
		{ Kind = "Roof", Path = { { 60, 92 }, { 60, 96 } }, Width = 44, Clearance = 12, Thickness = 6 },
		-- Third wall (gaps at x -230, -50 and 250).
		{ Kind = "Wall", Path = { { -360, 134 }, { -242, 134 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { -218, 134 }, { -62, 134 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { -38, 134 }, { 238, 134 } }, Height = 16, Width = 16 },
		{ Kind = "Wall", Path = { { 262, 134 }, { 360, 134 } }, Height = 16, Width = 16 },
		-- Dead-end pockets: short spurs that close off a corner.
		{ Kind = "Wall", Path = { { -290, 38 }, { -290, 60 } }, Height = 14, Width = 16 },
		{ Kind = "Wall", Path = { { 310, 38 }, { 310, 60 } }, Height = 14, Width = 16 },
		-- Boulders in the lanes.
		{ Kind = "Mound", At = { -60, 62 }, Radius = 9, Height = 5, Rock = true },
		{ Kind = "Mound", At = { 90, 52 }, Radius = 8, Height = 4, Rock = true },
		{ Kind = "Mound", At = { 200, 62 }, Radius = 9, Height = 5, Rock = true },
		{ Kind = "Mound", At = { -300, 14 }, Radius = 8, Height = 5, Rock = true },
		{ Kind = "Mound", At = { 300, 14 }, Radius = 8, Height = 5, Rock = true },
		{ Kind = "Mound", At = { 170, 14 }, Radius = 8, Height = 4, Rock = true },
		-- Hollows that hold water between the walls.
		{ Kind = "Hollow", At = { 130, 56 }, Radius = 12, Depth = 2 },
		{ Kind = "Hollow", At = { -150, 54 }, Radius = 10, Depth = 2 },
		-- The seaward ford: cut in front of the sea, so it floods first.
		{ Kind = "Channel", Path = { { -120, 12 }, { -20, 10 }, { 100, 12 } }, Depth = 3, Width = 12 },
		-- Cart ramps wind through the gaps.
		{
			Kind = "Ramp",
			Path = {
				{ -200, 0 },
				{ -215, 14 },
				{ -230, 22 },
				{ -230, 38 },
				{ -190, 60 },
				{ -110, 78 },
				{ -100, 86 },
				{ -100, 102 },
				{ -120, 110 },
				{ -150, 114 },
				{ -190, 114 },
				{ -228, 114 },
				{ -230, 122 },
				{ -230, 140 },
				{ -205, 146 },
				{ -200, 150 },
			},
			Width = 16,
		},
		{
			Kind = "Ramp",
			Path = {
				{ 180, 0 },
				{ 215, 14 },
				{ 250, 22 },
				{ 250, 38 },
				{ 210, 60 },
				{ 130, 78 },
				{ 120, 86 },
				{ 120, 102 },
				{ 140, 110 },
				{ 170, 114 },
				{ 210, 114 },
				{ 248, 114 },
				{ 250, 122 },
				{ 250, 140 },
				{ 185, 146 },
				{ 180, 150 },
			},
			Width = 16,
		},
	},
	Loot = {
		{ At = { -322, 52 }, Radius = 6, Weight = 3 },
		{ At = { 330, 52 }, Radius = 6, Weight = 3 },
		{ At = { 60, 94 }, Radius = 5, Weight = 2 },
		{ At = { -200, 112 }, Radius = 6, Weight = 2 },
		{ At = { 210, 112 }, Radius = 6, Weight = 2 },
		{ At = { 20, 60 }, Radius = 6, Weight = 1 },
		{ At = { -100, 146 }, Radius = 6, Weight = 1 },
	},
}
