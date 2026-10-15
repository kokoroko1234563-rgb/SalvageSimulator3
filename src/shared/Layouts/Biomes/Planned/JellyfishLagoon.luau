-- Jellyfish Lagoon (planned, draft): one big lagoon, a hollow ringed by a bank, with narrow
-- causeways across the bank. The lagoon floods from its seaward side first. Heights follow the
-- zone's limit. Rock only in zone 4.
local LIMIT = { 2, 4.5, 6.5, 9 }

local function build(zone: number)
	local top, rock = LIMIT[zone], zone == 4
	local depth = math.min(3, 1.5 + zone * 0.4)
	return {
		Name = "Jellyfish Lagoon (zone " .. zone .. ", draft)",
		Primitives = {
			{ Kind = "Hollow", At = { 0, 90 }, Radius = 22, Depth = depth },
			-- The bank around it, in arcs with a causeway gap on each side.
			{
				Kind = "Ridge",
				Path = { { -40, 90 }, { -30, 66 }, { -10, 62 } },
				Height = top * 0.7,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { 10, 62 }, { 30, 66 }, { 40, 90 } },
				Height = top * 0.7,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { 40, 90 }, { 30, 114 }, { 10, 118 } },
				Height = top * 0.7,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { -10, 118 }, { -30, 114 }, { -40, 90 } },
				Height = top * 0.7,
				Width = 10,
				Rock = rock,
			},
			{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
			{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
		},
	}
end

return { build(1), build(2), build(3), build(4) }
