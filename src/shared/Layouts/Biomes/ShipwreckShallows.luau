-- Shipwreck Shallows (uncommon): a scour channel cut around the wreck, debris mounds and a gully
-- down the middle of the zone for the barrels. Barrels spawn at a random X and roll toward +Z,
-- so the gully only catches the ones that roll down it (see the design note). The ship's hatch
-- is 30 studs into each zone, at the four entrance flats.
local function entrances(z: number)
	return {
		{ Kind = "Flat", At = { -100, z }, Radius = 10 },
		{ Kind = "Flat", At = { -20, z }, Radius = 10 },
		{ Kind = "Flat", At = { 60, z }, Radius = 10 },
		{ Kind = "Flat", At = { 120, z }, Radius = 10 },
	}
end

local function ramps()
	return {
		{ Kind = "Ramp", Path = { { -200, 0 }, { -260, 50 }, { -230, 100 }, { -200, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 210, 60 }, { 160, 110 }, { 180, 150 } }, Width = 16 },
	}
end

local function concat(...)
	local out = {}
	for _, list in { ... } do
		table.move(list, 1, #list, #out + 1, out)
	end
	return out
end

local tileLayout = {
	[1] = {
		Name = "Shipwreck Shallows (zone 1)",
		Primitives = concat(entrances(30), ramps(), {
			{
				Kind = "Ridge",
				Path = { { -360, 140 }, { -200, 146 }, { 0, 140 }, { 200, 146 }, { 360, 140 } },
				Height = 2.2,
				Width = 12,
			},
			{
				Kind = "Channel",
				Path = { { -100, 62 }, { -30, 72 }, { 40, 70 }, { 110, 60 } },
				Depth = 2,
				Width = 12,
			},
			{ Kind = "Channel", Path = { { -60, 0 }, { -60, 150 } }, Depth = 1.5, Width = 10 },
			{ Kind = "Mound", At = { -160, 100 }, Radius = 6, Height = 2.5 },
			{ Kind = "Mound", At = { 160, 95 }, Radius = 5, Height = 2 },
		}),
	},
	[2] = {
		Name = "Shipwreck Shallows (zone 2)",
		Primitives = concat(entrances(30), ramps(), {
			{ Kind = "Flat", At = { 40, 22 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 40 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 58 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 76 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 94 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 112 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 130 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 148 }, Radius = 9 },
			{
				Kind = "Ridge",
				Path = { { -360, 50 }, { -120, 54 }, { 120, 50 }, { 360, 52 } },
				Height = 4.8,
				Width = 18,
			},
			{
				Kind = "Ridge",
				Path = { { -360, 100 }, { -120, 104 }, { 120, 100 }, { 360, 102 } },
				Height = 4,
				Width = 16,
			},
			{ Kind = "Channel", Path = { { -60, 0 }, { -60, 150 } }, Depth = 1.5, Width = 10 },
			{ Kind = "Channel", Path = { { -150, 96 }, { -40, 104 }, { 80, 96 } }, Depth = 2.5, Width = 12 },
			{ Kind = "Mound", At = { -200, 124 }, Radius = 6, Height = 2.5 },
		}),
	},
	[3] = {
		Name = "Shipwreck Shallows (zone 3)",
		Primitives = concat(entrances(30), ramps(), {
			{ Kind = "Flat", At = { 40, 10 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 25 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 40 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 55 }, Radius = 9 },
			{ Kind = "Flat", At = { 40, 70 }, Radius = 9 },
			{
				Kind = "Ridge",
				Path = { { -360, 46 }, { -120, 50 }, { 120, 46 }, { 360, 48 } },
				Height = 4.8,
				Width = 18,
			},
			{
				Kind = "Ridge",
				Path = { { -360, 100 }, { -120, 104 }, { 120, 100 }, { 360, 102 } },
				Height = 4,
				Width = 16,
			},
			{ Kind = "Channel", Path = { { -90, 0 }, { -90, 150 } }, Depth = 1.5, Width = 10 },
			{
				Kind = "Channel",
				Path = { { -300, 110 }, { -120, 118 }, { 60, 104 }, { 240, 116 } },
				Depth = 2.5,
				Width = 12,
			},
			{ Kind = "Mound", At = { 130, 88 }, Radius = 6, Height = 3 },
		}),
	},
	[4] = {
		Name = "Shipwreck Shallows (zone 4)",
		Primitives = concat(entrances(30), ramps(), {
			{
				Kind = "Ridge",
				Path = { { -360, 44 }, { -120, 48 }, { 120, 44 }, { 360, 46 } },
				Height = 4.8,
				Width = 18,
			},
			{
				Kind = "Ridge",
				Path = { { -360, 100 }, { -120, 104 }, { 120, 100 }, { 360, 102 } },
				Height = 4,
				Width = 16,
			},
			{ Kind = "Channel", Path = { { -60, 0 }, { -60, 150 } }, Depth = 1.5, Width = 10 },
			{
				Kind = "Channel",
				Path = { { -300, 128 }, { -100, 122 }, { 100, 130 } },
				Depth = 3,
				Width = 12,
			},
			{ Kind = "Mound", At = { 150, 96 }, Radius = 6, Height = 3 },
		}),
	},
}

-- Drawn for the old 152-stud tiles: repeated down the zone (Layouts/Tiled).
return require(script.Parent.Parent.Tiled)(tileLayout)
