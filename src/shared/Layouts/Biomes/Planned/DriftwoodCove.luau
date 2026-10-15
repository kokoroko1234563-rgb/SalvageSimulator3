-- Driftwood Cove (planned, draft): a log jam. Ridges piled across the zone like driftwood, each
-- with a gap to squeeze through, and a dip behind them where the logs catch the water.
-- Heights follow the zone's limit: 2, 4.5, 6.5 and 9 studs. Rock only in zone 4.
local LIMIT = { 2, 4.5, 6.5, 9 }

local function build(zone: number)
	local top, rock = LIMIT[zone], zone == 4
	return {
		Name = "Driftwood Cove (zone " .. zone .. ", draft)",
		Primitives = {
			{
				Kind = "Ridge",
				Path = { { -320, 52 }, { -200, 58 }, { -120, 52 } },
				Height = top,
				Width = 14,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { -40, 54 }, { 60, 60 }, { 160, 54 } },
				Height = top,
				Width = 14,
				Rock = rock,
			},
			{ Kind = "Ridge", Path = { { 200, 44 }, { 300, 40 } }, Height = top, Width = 14, Rock = rock },
			{ Kind = "Hollow", At = { -80, 90 }, Radius = 9, Depth = 1.5 },
			{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
			{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
		},
	}
end

return { build(1), build(2), build(3), build(4) }
