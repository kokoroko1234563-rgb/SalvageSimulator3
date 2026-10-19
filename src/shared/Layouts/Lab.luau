-- The water lab's layout: every kind of ground the water has to cope with, side by side in
-- lanes running down a whole zone, so wherever the tide is, each lane meets the waterline.
-- Not part of the game: tools/water draws it (python3 tools/water/water.py <zone> Lab 1: <z>),
-- and in the review place the admin command `waterlab <zone>` puts it in a zone
-- (Workspace attribute "WaterLab", read by Layouts.activeDef).
--
-- Lanes, west to east (X):
--   -315  the bare slope, to compare with
--   -235  a wall running down the beach, and breakwater walls across it with lagoons behind
--   -150  sand banks across the beach with hollows behind them (pools cut off from the sea)
--    -65  a channel cut down the beach, deep then shallow
--     20  a tunnel: two walls and a roof, so the sea runs in under rock
--    105  pits from narrow to wide, shallow to deep
--    190  rock domes and banks standing in the water
--    275  worn walls with a gap narrower than the water's grid between them
--    345  the edge of the beach, where the shapes fade into the cliffs

local LANE_STEP = 150 -- studs down the beach between repeats of the lanes' features

local primitives = {}
local function add(p)
	table.insert(primitives, p)
end

-- Lane -235: a wall down the beach, with a breakwater across it every LANE_STEP.
add({ Kind = "Wall", Path = { { -235, 10 }, { -235, 598 } }, Height = 8, Width = 12 })
-- Lane -150 and the breakwaters: the repeats.
for z = 60, 560, LANE_STEP do
	add({ Kind = "Wall", Path = { { -280, z }, { -190, z } }, Height = 6, Width = 12 })
	add({ Kind = "Hollow", At = { -262, z - 22 }, Radius = 12, Depth = 3 })
	add({ Kind = "Ridge", Path = { { -190, z + 30 }, { -110, z + 30 } }, Height = 4, Width = 16 })
	add({ Kind = "Hollow", At = { -150, z + 4 }, Radius = 16, Depth = 4 })
	-- Lane 105: pits, from a narrow deep one to a wide shallow one.
	add({ Kind = "Hollow", At = { 92, z }, Radius = 5, Depth = 4 })
	add({ Kind = "Hollow", At = { 118, z + 40 }, Radius = 10, Depth = 3 })
	add({ Kind = "Hollow", At = { 105, z + 95 }, Radius = 20, Depth = 1.5 })
	-- Lane 190: rock domes and a bank.
	add({ Kind = "Mound", At = { 180, z }, Radius = 9, Height = 6, Rock = true })
	add({ Kind = "Mound", At = { 205, z + 45 }, Radius = 5, Height = 3, Rock = true })
	add({ Kind = "Ridge", Path = { { 165, z + 90 }, { 215, z + 110 } }, Height = 2.5, Width = 14 })
end

-- Lane -65: a channel down the beach, 4 deep for its first half and 1.5 for the rest.
add({ Kind = "Channel", Path = { { -65, 10 }, { -65, 300 } }, Depth = 4, Width = 14 })
add({ Kind = "Channel", Path = { { -65, 300 }, { -65, 598 } }, Depth = 1.5, Width = 14 })

-- Lane 20: a tunnel down the beach, open to the sky every so often.
add({ Kind = "Wall", Path = { { 4, 10 }, { 4, 598 } }, Height = 12, Width = 12 })
add({ Kind = "Wall", Path = { { 36, 10 }, { 36, 598 } }, Height = 12, Width = 12 })
for z = 40, 560, LANE_STEP do
	add({
		Kind = "Roof",
		Area = { { -2, z }, { 42, z }, { 42, z + 90 }, { -2, z + 90 } },
		Clearance = 10,
		Thickness = 6,
	})
end

-- Lane 275: two worn walls down the beach with a 6-stud gap between them.
add({ Kind = "Wall", Path = { { 260, 10 }, { 260, 598 } }, Height = 7, Width = 14, Rough = 1 })
add({ Kind = "Wall", Path = { { 280, 10 }, { 280, 598 } }, Height = 7, Width = 14, Rough = 1 })

-- Lane 345: a bank running out under the cliffs.
add({ Kind = "Ridge", Path = { { 330, 100 }, { 372, 140 } }, Height = 4, Width = 16 })

return {
	Name = "Water lab",
	Primitives = primitives,
}
