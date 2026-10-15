-- Zone 1, Open Shore (base layout). A placeholder until the hand-built layout replaces it:
-- a few low dunes, easy to read from the top. See src/shared/Layouts/init.luau for the format.
return {
	Name = "Open Shore (base)",
	Primitives = {
		{ Kind = "Ridge", Path = { { -320, 70 }, { -230, 78 }, { -120, 72 } }, Height = 2, Width = 14 },
		{ Kind = "Ridge", Path = { { -40, 95 }, { 60, 88 }, { 150, 96 } }, Height = 2.5, Width = 14 },
		{ Kind = "Ridge", Path = { { 220, 60 }, { 320, 66 } }, Height = 2, Width = 12 },
		{ Kind = "Ramp", Path = { { -160, 0 }, { -160, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 180, 150 } }, Width = 16 },
	},
}
