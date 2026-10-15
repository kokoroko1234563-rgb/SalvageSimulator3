-- Zone 2, Dunes (base layout). A placeholder until the hand-built layout replaces it: two
-- broken lines of dunes with hollows behind them, and a clear corridor under the pier (x = 40).
return {
	Name = "Dunes (base)",
	Primitives = {
		{
			Kind = "Ridge",
			Path = { { -340, 45 }, { -250, 55 }, { -120, 48 }, { -20, 52 } },
			Height = 4.5,
			Width = 16,
		},
		{ Kind = "Ridge", Path = { { 90, 50 }, { 200, 42 }, { 340, 50 } }, Height = 4.5, Width = 16 },
		{ Kind = "Ridge", Path = { { -300, 105 }, { -180, 112 }, { -60, 104 } }, Height = 5, Width = 16 },
		{ Kind = "Ridge", Path = { { 0, 115 }, { 140, 108 }, { 300, 116 } }, Height = 5, Width = 16 },
		{ Kind = "Hollow", At = { -220, 80 }, Radius = 12, Depth = 1.2 },
		{ Kind = "Hollow", At = { 240, 82 }, Radius = 12, Depth = 1.2 },
		{ Kind = "Ramp", Path = { { 40, 0 }, { 40, 150 } }, Width = 14 },
		{ Kind = "Ramp", Path = { { -160, 0 }, { -170, 75 }, { -160, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 170, 75 }, { 180, 150 } }, Width = 16 },
	},
}
