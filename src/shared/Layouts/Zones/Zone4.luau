-- Zone 4, Outer Shore / Reef (base layout): rock spines with narrow gaps, boulders in the
-- corridors between them, and sea caves made of two tall spines. The seaward fords flood first.
return {
	Name = "Outer Shore (base)",
	Primitives = {
		-- The first spine, with a narrow gap for players on foot.
		{
			Kind = "Ridge",
			Path = { { -360, 40 }, { -200, 36 }, { -100, 42 } },
			Height = 9,
			Width = 12,
			Rock = true,
		},
		{
			Kind = "Ridge",
			Path = { { -40, 40 }, { 80, 36 }, { 200, 44 }, { 360, 40 } },
			Height = 9,
			Width = 12,
			Rock = true,
		},
		-- The second spine, with its gap further east.
		{
			Kind = "Ridge",
			Path = { { -300, 96 }, { -120, 90 }, { 20, 98 } },
			Height = 8,
			Width = 16,
			Rock = true,
		},
		{
			Kind = "Ridge",
			Path = { { 80, 92 }, { 200, 96 }, { 340, 90 } },
			Height = 8,
			Width = 16,
			Rock = true,
		},
		-- Boulders in the corridor, and a rock sea cave: two tall spines close together.
		{ Kind = "Mound", At = { -150, 66 }, Radius = 8, Height = 5, Rock = true },
		{ Kind = "Mound", At = { 40, 66 }, Radius = 7, Height = 4, Rock = true },
		{ Kind = "Ridge", Path = { { 240, 112 }, { 255, 140 } }, Height = 10, Width = 10, Rock = true },
		{ Kind = "Ridge", Path = { { 270, 112 }, { 285, 140 } }, Height = 10, Width = 10, Rock = true },
		-- Hollows that hold water in the corridors.
		{ Kind = "Hollow", At = { -40, 66 }, Radius = 12, Depth = 2 },
		{ Kind = "Hollow", At = { 200, 62 }, Radius = 10, Depth = 2 },
		-- The seaward fords: cut in front of the sea, so they flood first.
		{ Kind = "Channel", Path = { { -300, 130 }, { -100, 124 }, { 100, 132 } }, Depth = 3, Width = 12 },
		{ Kind = "Ramp", Path = { { -200, 0 }, { -180, 75 }, { -200, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 160, 75 }, { 180, 150 } }, Width = 16 },
	},
}
