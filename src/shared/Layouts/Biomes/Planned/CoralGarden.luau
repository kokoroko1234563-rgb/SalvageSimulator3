-- Coral Garden (planned, draft): reef spines with arches. Pairs of spines stand close together
-- and leave an arch between them to walk through. Rock only in zone 4, and the spines are kept
-- short enough for the zone's limit elsewhere.
local LIMIT = { 2, 4.5, 6.5, 9 }

local function build(zone: number)
	local top, rock = LIMIT[zone], zone == 4
	return {
		Name = "Coral Garden (zone " .. zone .. ", draft)",
		Primitives = {
			{ Kind = "Ridge", Path = { { -300, 50 }, { -280, 66 } }, Height = top, Width = 10, Rock = rock },
			{ Kind = "Ridge", Path = { { -240, 50 }, { -260, 66 } }, Height = top, Width = 10, Rock = rock },
			{ Kind = "Ridge", Path = { { -40, 56 }, { -20, 74 } }, Height = top, Width = 10, Rock = rock },
			{ Kind = "Ridge", Path = { { 20, 56 }, { 0, 74 } }, Height = top, Width = 10, Rock = rock },
			{ Kind = "Ridge", Path = { { 130, 60 }, { 150, 80 } }, Height = top, Width = 10, Rock = rock },
			{ Kind = "Ridge", Path = { { 190, 60 }, { 170, 80 } }, Height = top, Width = 10, Rock = rock },
			{ Kind = "Hollow", At = { -100, 100 }, Radius = 8, Depth = 1.5 },
			{ Kind = "Hollow", At = { 250, 100 }, Radius = 8, Depth = 1.5 },
			{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
			{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
		},
	}
end

return { build(1), build(2), build(3), build(4) }
