-- Zone 2, Dunes (base layout): a dune line that hides most of the zone's lower half from the top,
-- broken only where the ramps and the pier let the eye through. Heights stay at 5 studs or less.
local tileLayout = {
	Name = "Dunes (base)",
	Primitives = {
		-- The main dune: tall enough that the eye (5 studs up) can't see past it.
		{
			Kind = "Ridge",
			Path = {
				{ -360, 46 },
				{ -240, 40 },
				{ -120, 48 },
				{ 0, 42 },
				{ 120, 48 },
				{ 240, 40 },
				{ 360, 46 },
			},
			Height = 4.5,
			Width = 16,
		},
		-- A second dune further out, between the pool and the sea.
		{ Kind = "Ridge", Path = { { 80, 100 }, { 200, 98 }, { 330, 102 } }, Height = 3.5, Width = 14 },
		{ Kind = "Ridge", Path = { { -320, 100 }, { -200, 104 }, { -60, 98 } }, Height = 3, Width = 14 },
		{ Kind = "Hollow", At = { -60, 80 }, Radius = 10, Depth = 2 },
		{ Kind = "Hollow", At = { 260, 82 }, Radius = 9, Depth = 2 },
		{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
		-- The pier at x = 40 runs out through this zone: keep a clear path under it.
		{ Kind = "Flat", At = { 40, 22 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 40 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 58 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 76 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 94 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 112 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 130 }, Radius = 9 },
		{ Kind = "Flat", At = { 40, 148 }, Radius = 9 },
	},
}

-- Drawn for the old 152-stud tiles: repeated down the zone (Layouts/Tiled).
return require(script.Parent.Parent.Tiled)(tileLayout)
