-- Hermit Hollows (planned, draft): a tight maze of rock-walled corridors, 12 studs wide, with
-- dead ends and one way through. The maze sits between the two cart ramps, so the ramps still
-- go round the outside. Walls alternate their gap from end to end. Rock only in zone 4.
local LIMIT = { 2, 4.5, 6.5, 9 }

local function build(zone: number)
	local top, rock = LIMIT[zone], zone == 4
	local walls = {}
	for i, z in { 24, 48, 72, 96, 112 } do
		-- Each wall leaves its gap at one end, alternately west and east.
		local ends = if i % 2 == 1 then { -60, 110 } else { -110, 60 }
		table.insert(walls, {
			Kind = "Ridge",
			Path = { { ends[1], z }, { (ends[1] + ends[2]) / 2, z }, { ends[2], z } },
			Height = top * 0.8,
			Width = 12,
			Rock = rock,
		})
	end
	local primitives = {
		{ Kind = "Ramp", Path = { { -200, 0 }, { -250, 40 }, { -225, 90 }, { -200, 150 } }, Width = 16 },
		{ Kind = "Ramp", Path = { { 180, 0 }, { 215, 60 }, { 205, 110 }, { 180, 150 } }, Width = 16 },
	}
	for _, w in walls do
		table.insert(primitives, w)
	end
	-- Dead-end stubs off the corridors.
	table.insert(
		primitives,
		{ Kind = "Ridge", Path = { { -60, 36 }, { -20, 36 } }, Height = top * 0.6, Width = 10, Rock = rock }
	)
	table.insert(
		primitives,
		{ Kind = "Ridge", Path = { { 50, 84 }, { 100, 84 } }, Height = top * 0.6, Width = 10, Rock = rock }
	)
	return { Name = "Hermit Hollows (zone " .. zone .. ", draft)", Primitives = primitives }
end

return { build(1), build(2), build(3), build(4) }
