-- Sandcastle Flats (common): wide, open sand with castle mounds. The relief zone: easy to cross,
-- with a dune across the inner-middle of zones 2 to 4 to keep the sightlines short. The secret's
-- sandcastle stands at the four entrance flats, 30 studs into each zone.
local function entrances(z: number)
	return {
		{ Kind = "Flat", At = { -110, z }, Radius = 10 },
		{ Kind = "Flat", At = { -40, z }, Radius = 10 },
		{ Kind = "Flat", At = { 40, z }, Radius = 10 },
		{ Kind = "Flat", At = { 110, z }, Radius = 10 },
	}
end

local function ramps()
	return {
		{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
	}
end

-- The pier's clear path, in zones 2 and 3.
local function pier(zs: { number })
	local out = {}
	for _, z in zs do
		table.insert(out, { Kind = "Flat", At = { 40, z }, Radius = 9 })
	end
	return out
end

local function concat(...)
	local out = {}
	for _, list in { ... } do
		table.move(list, 1, #list, #out + 1, out)
	end
	return out
end

return {
	[1] = {
		Name = "Sandcastle Flats (zone 1)",
		Primitives = concat(entrances(30), ramps(), {
			{
				Kind = "Ridge",
				Path = { { -360, 140 }, { -200, 146 }, { 0, 140 }, { 200, 146 }, { 360, 140 } },
				Height = 2.2,
				Width = 12,
			},
			{ Kind = "Mound", At = { -150, 90 }, Radius = 8, Height = 2 },
			{ Kind = "Mound", At = { 90, 110 }, Radius = 9, Height = 2.5 },
			{ Kind = "Mound", At = { -20, 130 }, Radius = 7, Height = 2 },
		}),
	},
	[2] = {
		Name = "Sandcastle Flats (zone 2)",
		Primitives = concat(entrances(30), ramps(), pier({ 22, 40, 58, 76, 94, 112, 130, 148 }), {
			{
				Kind = "Ridge",
				Path = { { -360, 60 }, { -120, 64 }, { 120, 60 }, { 360, 62 } },
				Height = 4.8,
				Width = 18,
			},
			{
				Kind = "Ridge",
				Path = { { -360, 100 }, { -120, 104 }, { 120, 100 }, { 360, 102 } },
				Height = 4,
				Width = 16,
			},
			{ Kind = "Mound", At = { -200, 110 }, Radius = 9, Height = 4 },
			{ Kind = "Mound", At = { 200, 128 }, Radius = 8, Height = 3 },
		}),
	},
	[3] = {
		Name = "Sandcastle Flats (zone 3)",
		Primitives = concat(entrances(30), ramps(), pier({ 10, 25, 40, 55, 70 }), {
			{
				Kind = "Ridge",
				Path = { { -360, 56 }, { -120, 60 }, { 120, 56 }, { 360, 58 } },
				Height = 4.8,
				Width = 18,
			},
			{
				Kind = "Ridge",
				Path = { { -360, 100 }, { -120, 104 }, { 120, 100 }, { 360, 102 } },
				Height = 4,
				Width = 16,
			},
			{ Kind = "Mound", At = { -150, 125 }, Radius = 9, Height = 4 },
			{ Kind = "Mound", At = { 100, 120 }, Radius = 8, Height = 3 },
		}),
	},
	[4] = {
		Name = "Sandcastle Flats (zone 4)",
		Primitives = concat(entrances(30), ramps(), {
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
			{ Kind = "Mound", At = { -150, 125 }, Radius = 9, Height = 4 },
			{ Kind = "Mound", At = { 120, 115 }, Radius = 8, Height = 3 },
		}),
	},
}
