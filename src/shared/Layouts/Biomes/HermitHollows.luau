-- Hermit Hollows (draft; it rolls in zones 4 to 6): a tight maze of rock-walled corridors, about 12 studs wide, with
-- dead ends and one way through. The maze sits between the cart ramps, so the ramps still go round
-- the outside. Walls alternate their gap from end to end. A bank across the zone gives players on
-- foot a shortcut that carts can't take. Heights follow the zone's limit. Rock only in zone 4.
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
	local walls = {}
	-- Walls spaced 24 apart leave corridors 12 wide. Each leaves its gap at one end, alternately.
	for i, z in { 60, 84, 108 } do
		local ends = if i % 2 == 1 then { -120, 70 } else { -70, 120 }
		-- Where it rolls (zone 4 and below), the walls are real rock walls you can't climb.
		table.insert(
			walls,
			if rock
				then {
					Kind = "Wall",
					Path = { { ends[1], z }, { (ends[1] + ends[2]) / 2, z }, { ends[2], z } },
					Height = 20,
					Width = 12,
				}
				else {
					Kind = "Ridge",
					Path = { { ends[1], z }, { (ends[1] + ends[2]) / 2, z }, { ends[2], z } },
					Height = top * 0.8,
					Width = 12,
					Rock = rock,
				}
		)
	end
	return {
		Name = "Hermit Hollows (zone " .. zone .. ", draft)",
		Primitives = concat(bank(zone), ramps(), walls, {
			-- Dead-end stubs off the corridors.
			{
				Kind = "Ridge",
				Path = { { -60, 72 }, { -20, 72 } },
				Height = top * 0.6,
				Width = 10,
				Rock = rock,
			},
			{
				Kind = "Ridge",
				Path = { { 50, 96 }, { 100, 96 } },
				Height = top * 0.6,
				Width = 10,
				Rock = rock,
			},
		}),
	}
end

return { build(1), build(2), build(3), build(4) }
