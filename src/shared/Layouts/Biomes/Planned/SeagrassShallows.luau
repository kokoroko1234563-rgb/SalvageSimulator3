-- Seagrass Shallows (planned, draft): low, flood-prone flats. Shallow channels cut across the zone, so
-- the flats flood in stages as the waterline comes in. A bank across the zone gives players on foot
-- a shortcut that carts can't take. Rock only in zone 4.

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
			{ Kind = "Ridge", Path = { { -360, 126 }, { -200, 130 } }, Height = 4, Width = 16 },
			{ Kind = "Ridge", Path = { { 200, 128 }, { 360, 128 } }, Height = 4, Width = 16 },
		}
	elseif zone == 3 then
		return {
			{
				Kind = "Ridge",
				Path = { { -360, 40 }, { -200, 46 }, { 0, 38 }, { 200, 46 }, { 360, 40 } },
				Height = 4.8,
				Width = 18,
			},
			{ Kind = "Ridge", Path = { { -360, 126 }, { -200, 130 } }, Height = 4, Width = 16 },
			{ Kind = "Ridge", Path = { { 200, 128 }, { 360, 128 } }, Height = 4, Width = 16 },
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
	local depth = math.min(2, 1 + zone * 0.3)
	return {
		Name = "Seagrass Shallows (zone " .. zone .. ", draft)",
		Primitives = concat(bank(zone), ramps(), {
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
		}),
	}
end

-- Drawn for the old 152-stud tiles: repeated down the zone (Layouts/Tiled).
return require(script.Parent.Parent.Parent.Tiled)({ build(1), build(2), build(3), build(4) })
