-- Zone 1, Open Shore (base layout): the tutorial. Low ground the eye can read from the top:
-- a few shallow banks, all of them near the seaward edge, so the zone stays open. Two ramps
-- let a cart through, and the banks are the foot shortcuts. See design notes in docs/layouts.
local tileLayout = {
	Name = "Open Shore (base)",
	Primitives = {
		-- A bank across the seaward end: carts take the ramps, players walk over it.
		{
			Kind = "Ridge",
			Path = { { -360, 140 }, { -200, 146 }, { 0, 140 }, { 200, 146 }, { 360, 140 } },
			Height = 2.2,
			Width = 12,
		},
		-- A low bank mid-zone, with a gap at its east end where the sand runs through.
		{ Kind = "Ridge", Path = { { -220, 70 }, { -120, 74 }, { 0, 70 } }, Height = 1.2, Width = 10 },
		{ Kind = "Mound", At = { 120, 90 }, Radius = 7, Height = 1.5 },
		{ Kind = "Hollow", At = { -60, 110 }, Radius = 7, Depth = 1 },
		-- Ramps: the cart route, anchored at x = -200 and x = 180 on both zone edges.
		{ Kind = "Ramp", Path = { { -200, 0 }, { -245, 40 }, { -225, 95 }, { -200, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
	},
}

-- Drawn for the old 152-stud tiles: repeated down the zone (Layouts/Tiled).
return require(script.Parent.Parent.Tiled)(tileLayout)
