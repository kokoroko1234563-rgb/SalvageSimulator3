-- Zone 3, Banks (base layout): a bank across the zone with gaps for the fords. The fords are cut
-- below the sand, so they flood as the waterline comes in, the seaward ones first.
return {
	Name = "Banks (base)",
	Primitives = {
		{
			Kind = "Ridge",
			Path = { { -360, 35 }, { -200, 40 }, { -60, 32 }, { 80, 38 }, { 220, 34 }, { 360, 38 } },
			Height = 4.5,
			Width = 16,
		},
		{ Kind = "Ridge", Path = { { -300, 90 }, { -150, 96 }, { -20, 88 } }, Height = 3, Width = 14 },
		{ Kind = "Ridge", Path = { { 90, 84 }, { 230, 92 }, { 340, 86 } }, Height = 3, Width = 14 },
		-- The fords: cut across the zone, two to three studs deep.
		{
			Kind = "Channel",
			Path = { { -300, 110 }, { -120, 118 }, { 60, 104 }, { 240, 116 } },
			Depth = 2.5,
			Width = 12,
		},
		{ Kind = "Hollow", At = { -200, 80 }, Radius = 8, Depth = 3 },
		{ Kind = "Hollow", At = { 120, 60 }, Radius = 9, Depth = 2 },
		{ Kind = "Ramp", Path = { { -200, 0 }, { -260, 50 }, { -230, 100 }, { -200, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 210, 60 }, { 160, 110 }, { 180, 150 } }, Width = 16 },
		-- The pier runs through this zone too.
		{ Kind = "Flat", At = { 40, 10 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 25 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 40 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 55 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 70 }, Radius = 9 },
	},
}
