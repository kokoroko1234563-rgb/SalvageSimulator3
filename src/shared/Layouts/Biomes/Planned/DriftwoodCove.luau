-- Driftwood Cove (planned, draft): a log jam. Logs piled across the zone, each stretch with a gap to
-- squeeze through, and a dip behind them where the logs catch the water. A bank across the zone gives
-- players on foot a shortcut that carts can't take. Heights follow the zone's limit: 2, 4.5, 6.5 and 9
-- studs. Rock only in zone 4.
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
		}
	elseif zone == 3 then
		return {
			{
				Kind = "Ridge",
				Path = { { -360, 40 }, { -200, 46 }, { 0, 38 }, { 200, 46 }, { 360, 40 } },
				Height = 4.8,
				Width = 18,
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
		Name = "Driftwood Cove (zone " .. zone .. ", draft)",
		Primitives = concat(bank(zone), ramps(), {
			-- The log jam behind the bank, in stretches with gaps between them.
			{
				Kind = "Ridge",
				Path = { { -320, 80 }, { -200, 86 }, { -120, 80 } },
				Height = top * 0.5,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { -40, 84 }, { 60, 90 }, { 160, 84 } },
				Height = top * 0.5,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { 200, 92 }, { 300, 88 } },
				Height = top * 0.5,
				Width = 10,
				Rock = rock,
			},
			{ Kind = "Hollow", At = { -80, 120 }, Radius = 9, Depth = 1.5 },
		}),
	}
end

-- Drawn for the old 152-stud tiles: repeated down the zone (Layouts/Tiled).
return require(script.Parent.Parent.Parent.Tiled)({ build(1), build(2), build(3), build(4) })
