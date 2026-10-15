-- Coral Garden (planned, draft): reef spines with arches. Pairs of spines stand close together and
-- leave an arch between them to walk through. A bank across the zone gives players on foot a shortcut
-- that carts can't take. Heights follow the zone's limit. Rock only in zone 4.
local LIMIT = { 2, 4.5, 6.5, 9 }

-- The bank across the zone: foot-only in zones 1 to 3 (carts take the ramps), rock with a gap in zone 4.
local function bank(zone: number)
	if zone == 1 then
		return {
			{
				Kind = "Ridge",
				Path = { { -360, 138 }, { -200, 144 }, { 0, 138 }, { 200, 144 }, { 360, 138 } },
				Height = 2,
				Width = 12,
			},
		}
	elseif zone == 2 then
		return {
			{
				Kind = "Ridge",
				Path = { { -360, 44 }, { -180, 50 }, { 0, 42 }, { 180, 50 }, { 360, 44 } },
				Height = 4.8,
				Width = 18,
			},
			{
				Kind = "Ridge",
				Path = { { -360, 100 }, { -120, 104 }, { 120, 100 }, { 360, 102 } },
				Height = 4,
				Width = 16,
			},
		}
	elseif zone == 3 then
		return {
			{
				Kind = "Ridge",
				Path = { { -360, 40 }, { -200, 46 }, { 0, 38 }, { 200, 46 }, { 360, 40 } },
				Height = 4.8,
				Width = 18,
			},
			{
				Kind = "Ridge",
				Path = { { -360, 100 }, { -120, 104 }, { 120, 100 }, { 360, 102 } },
				Height = 4,
				Width = 16,
			},
		}
	end
	return {
		{
			Kind = "Ridge",
			Path = { { -360, 40 }, { -200, 36 }, { -100, 42 } },
			Height = 9,
			Width = 12,
			Rock = true,
		},
		{
			Kind = "Ridge",
			Path = { { -20, 42 }, { 120, 36 }, { 360, 40 } },
			Height = 9,
			Width = 12,
			Rock = true,
		},
		{
			Kind = "Ridge",
			Path = { { -300, 96 }, { -120, 90 }, { 20, 98 } },
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
	}
end

local function ramps()
	return {
		{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
	}
end

local function concat(...)
	local out = {}
	for _, list in { ... } do
		table.move(list, 1, #list, #out + 1, out)
	end
	return out
end

local function build(zone: number)
	local top, rock = LIMIT[zone], zone == 4
	return {
		Name = "Coral Garden (zone " .. zone .. ", draft)",
		Primitives = concat(bank(zone), ramps(), {
			-- Pairs of spines, each pair leaving an arch to walk through between them.
			{
				Kind = "Ridge",
				Path = { { -300, 56 }, { -280, 66 } },
				Height = top * 0.8,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { -240, 56 }, { -260, 66 } },
				Height = top * 0.8,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { -40, 60 }, { -20, 74 } },
				Height = top * 0.8,
				Width = 10,
				Rock = rock,
			},
			{ Kind = "Ridge", Path = { { 20, 60 }, { 0, 74 } }, Height = top * 0.8, Width = 10, Rock = rock },
			{
				Kind = "Ridge",
				Path = { { 130, 62 }, { 150, 78 } },
				Height = top * 0.8,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { 190, 62 }, { 170, 78 } },
				Height = top * 0.8,
				Width = 10,
				Rock = rock,
			},
			{ Kind = "Hollow", At = { -100, 100 }, Radius = 8, Depth = 1.5 },
			{ Kind = "Hollow", At = { 250, 100 }, Radius = 8, Depth = 1.5 },
		}),
	}
end

return { build(1), build(2), build(3), build(4) }
