-- Tidepool Rocks (planned, draft): rock benches with many small pools in them. The pools hold
-- water after the sea leaves, so a player can be caught in the bench as the tide turns.
-- Heights follow the zone's limit. Rock only in zone 4.
local LIMIT = { 2, 4.5, 6.5, 9 }

local function build(zone: number)
	local top, rock = LIMIT[zone], zone == 4
	return {
		Name = "Tidepool Rocks (zone " .. zone .. ", draft)",
		Primitives = {
			{ Kind = "Mound", At = { -220, 60 }, Radius = 14, Height = top * 0.6, Rock = rock },
			{ Kind = "Mound", At = { 40, 80 }, Radius = 16, Height = top * 0.7, Rock = rock },
			{ Kind = "Mound", At = { 230, 70 }, Radius = 14, Height = top * 0.6, Rock = rock },
			{
				Kind = "Ridge",
				Path = { { -360, 100 }, { -120, 104 }, { 120, 100 } },
				Height = top * 0.5,
				Width = 12,
				Rock = rock,
			},
			{ Kind = "Hollow", At = { -240, 50 }, Radius = 5, Depth = 1.5 },
			{ Kind = "Hollow", At = { -200, 72 }, Radius = 4, Depth = 1.2 },
			{ Kind = "Hollow", At = { 30, 60 }, Radius = 5, Depth = 1.5 },
			{ Kind = "Hollow", At = { 60, 96 }, Radius = 4, Depth = 1.2 },
			{ Kind = "Hollow", At = { 250, 56 }, Radius = 5, Depth = 1.5 },
			{ Kind = "Hollow", At = { 210, 90 }, Radius = 4, Depth = 1.2 },
			{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
			{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
		},
	}
end

return { build(1), build(2), build(3), build(4) }
