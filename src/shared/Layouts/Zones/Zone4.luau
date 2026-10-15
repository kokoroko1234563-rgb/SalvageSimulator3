-- Zone 4, Outer Shore (base layout). A placeholder until the hand-built layout replaces it:
-- rock spines with gaps, boulders, and dips between that flood first.
return {
	Name = "Outer Shore (base)",
	Primitives = {
		{
			Kind = "Ridge",
			Path = { { -340, 35 }, { -220, 28 }, { -60, 38 } },
			Height = 9,
			Width = 14,
			Rock = true,
		},
		{
			Kind = "Ridge",
			Path = { { 0, 32 }, { 140, 40 }, { 340, 30 } },
			Height = 9,
			Width = 14,
			Rock = true,
		},
		{
			Kind = "Ridge",
			Path = { { -300, 95 }, { -120, 88 }, { 20, 98 } },
			Height = 8,
			Width = 16,
			Rock = true,
		},
		{
			Kind = "Ridge",
			Path = { { 80, 92 }, { 220, 84 }, { 340, 96 } },
			Height = 8,
			Width = 16,
			Rock = true,
		},
		{ Kind = "Mound", At = { -100, 60 }, Radius = 8, Height = 5, Rock = true },
		{ Kind = "Mound", At = { 60, 64 }, Radius = 7, Height = 4, Rock = true },
		{ Kind = "Mound", At = { 260, 125 }, Radius = 9, Height = 5, Rock = true },
		{ Kind = "Hollow", At = { -40, 65 }, Radius = 14, Depth = 2 },
		{ Kind = "Hollow", At = { 200, 62 }, Radius = 12, Depth = 2 },
		{ Kind = "Channel", Path = { { -300, 128 }, { -100, 122 }, { 100, 130 } }, Depth = 2, Width = 12 },
		{ Kind = "Ramp", Path = { { -160, 0 }, { -180, 75 }, { -160, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 160, 75 }, { 180, 150 } }, Width = 16 },
	},
}
