-- Zone 3, Banks (base layout). A placeholder until the hand-built layout replaces it: sandbanks
-- with channels behind them that flood as the tide comes in, and the pier corridor (x = 40).
return {
	Name = "Banks (base)",
	Primitives = {
		{ Kind = "Ridge", Path = { { -340, 40 }, { -200, 30 }, { -90, 42 } }, Height = 6, Width = 18 },
		{ Kind = "Ridge", Path = { { 70, 36 }, { 220, 46 }, { 340, 34 } }, Height = 6, Width = 18 },
		{
			Kind = "Ridge",
			Path = { { -260, 100 }, { -100, 110 }, { 100, 96 }, { 260, 108 } },
			Height = 7,
			Width = 18,
		},
		{
			Kind = "Channel",
			Path = { { -320, 70 }, { -150, 64 }, { 0, 72 }, { 150, 66 }, { 320, 74 } },
			Depth = 2.5,
			Width = 14,
		},
		{
			Kind = "Channel",
			Path = { { -340, 135 }, { -100, 130 }, { 120, 138 }, { 340, 132 } },
			Depth = 2,
			Width = 12,
		},
		{ Kind = "Ramp", Path = { { 40, 0 }, { 40, 60 } }, Width = 14 },
		{ Kind = "Ramp", Path = { { -160, 0 }, { -150, 75 }, { -160, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 190, 75 }, { 180, 150 } }, Width = 16 },
	},
}
