-- Seagrass Shallows (planned, draft): low, flood-prone flats. Shallow channels cut across the
-- zone, so the flats flood in stages as the waterline comes in. Heights follow the zone's limit.
-- Rock only in zone 4.
local LIMIT = { 2, 4.5, 6.5, 9 }

local function build(zone: number)
	local top, rock = LIMIT[zone], zone == 4
	local depth = math.min(2, 1 + zone * 0.3)
	return {
		Name = "Seagrass Shallows (zone " .. zone .. ", draft)",
		Primitives = {
			{
				Kind = "Ridge",
				Path = { { -360, 44 }, { -120, 48 }, { 120, 44 }, { 360, 46 } },
				Height = top * 0.6,
				Width = 16,
				Rock = rock,
			},
			{
				Kind = "Channel",
				Path = { { -300, 90 }, { -100, 96 }, { 100, 90 }, { 300, 96 } },
				Depth = depth,
				Width = 12,
			},
			{
				Kind = "Channel",
				Path = { { -160, 100 }, { -60, 104 }, { 40, 100 } },
				Depth = depth + 0.5,
				Width = 10,
			},
			{ Kind = "Hollow", At = { -180, 70 }, Radius = 9, Depth = depth },
			{ Kind = "Hollow", At = { 200, 66 }, Radius = 8, Depth = depth },
			{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
			{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
		},
	}
end

return { build(1), build(2), build(3), build(4) }
