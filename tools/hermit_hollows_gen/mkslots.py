import os
from rooms import Room

here = os.path.dirname(os.path.abspath(__file__))


def R(name, cols, rows, door, seed=1):
    return Room(name, cols, rows, door, seed)


def sand(c, r, rad, h, dx=0, dz=0):
    return 'sandMound(cx(%d) + %d, cz(%d) + %d, %d, %d)' % (c, dx, r, dz, rad, h)


def rock(c, r, rad, h, dx=0, dz=0):
    return 'rockMound(cx(%d) + %d, cz(%d) + %d, %d, %d)' % (c, dx, r, dz, rad, h)


def pond(c, r, rad, depth):
    return '{ Kind = "Hollow", At = { cx(%d), cz(%d) }, Radius = %d, Depth = %d }' % (c, r, rad, depth)


def cut(c0, r0, c1, r1, depth, width=16):
    return '{ Kind = "Channel", Path = { { cx(%d), cz(%d) }, { cx(%d), cz(%d) } }, Depth = %d, Width = %d }' % (c0, r0, c1, r1, depth, width)


slots = []

# ---- S1 Northwest nest 3x3, door (2,1)
rooms = []
r = R("Crab nest", 3, 3, (2, 1), 1)
r.carve((2, 1), (2, 0), (1, 0), (0, 0), (0, 1), (0, 2), (1, 2), (1, 1))
r.unroofed.add((1, 1))
r.loot = [(1, 1, 4), (0, 2, 2)]
r.crabs = [[(2, 0), (0, 0)]]
rooms.append(r)
r = R("Shell midden", 3, 3, (2, 1), 2)
r.whole(False)
r.extra = [sand(0, 0, 9, 6, 6, 6), sand(1, 2, 9, 6), rock(0, 2, 7, 8, 0, -4)]
r.loot = [(0, 0, 3), (0, 2, 2), (1, 0, 1)]
rooms.append(r)
r = R("Flooded pocket", 3, 3, (2, 1), 3)
r.whole(True)
r.extra = [pond(1, 1, 18, 3)]
r.loot = [(0, 0, 3), (0, 2, 2)]
rooms.append(r)
slots.append(("Northwest nest", (-336, 96), (84, 84), rooms))

# ---- S2 Western midden 4x4, door (3,1)
rooms = []
r = R("Shell midden", 4, 4, (3, 1), 4)
r.whole(False)
r.extra = [sand(1, 1, 10, 7), sand(2, 2, 10, 7), rock(0, 3, 7, 9, 4, -4), rock(3, 0, 7, 9, 0, 0)]
r.loot = [(0, 0, 3), (0, 3, 2), (2, 3, 1)]
r.crabs = [[(1, 3), (3, 3)]]
rooms.append(r)
r = R("Boulder scramble", 4, 4, (3, 1), 5)
r.whole(False)
r.extra = [rock(1, 0, 7, 11), rock(1, 2, 7, 11), rock(2, 1, 7, 11, -4, 0), rock(2, 3, 7, 11), rock(0, 1, 7, 10, -2, 0)]
r.loot = [(0, 0, 3), (0, 3, 4), (3, 3, 2)]
rooms.append(r)
r = R("Tunnel loop", 4, 4, (3, 1), 6)
r.make_solid({(1, 1), (1, 2), (2, 1), (2, 2)})
ring = [(3, 1), (3, 0), (2, 0), (1, 0), (0, 0), (0, 1), (0, 2), (0, 3), (1, 3), (2, 3), (3, 3), (3, 2), (3, 1)]
r.carve(*ring)
r.loot = [(0, 2, 4), (3, 3, 2), (0, 0, 1)]
r.crabs = [[(0, 0), (3, 0)], [(0, 3), (3, 3)]]
rooms.append(r)
slots.append(("Western midden", (-336, 236), (112, 112), rooms))

# ---- S3 Southwest collapse 3x4, door (2,1)
rooms = []
r = R("Collapsed chamber", 3, 4, (2, 1), 7)
r.whole(False)
r.extra = [
    '{ Kind = "Ridge", Path = { { cx(0), cz(1) + 6 }, { cx(1), cz(1) + 6 } }, Height = 4, Width = 16 }',
    rock(1, 2, 7, 9),
    rock(0, 3, 7, 8, 8, 0),
]
r.loot = [(0, 3, 4), (2, 3, 2), (0, 0, 1)]
r.crabs = [[(0, 0), (0, 1)]]
rooms.append(r)
r = R("Sea cave", 3, 4, (2, 1), 8)
r.whole(True)
r.extra = [pond(1, 2, 16, 3)]
r.loot = [(1, 3, 3), (0, 0, 2)]
rooms.append(r)
r = R("Dead-end warren", 3, 4, (2, 1), 9)
r.carve((2, 1), (1, 1), (1, 0), (0, 0), (0, 1), (0, 2), (0, 3))
r.loot = [(0, 3, 4), (1, 0, 1)]
r.crabs = [[(1, 1), (1, 0)]]
rooms.append(r)
slots.append(("Southwest collapse", (-336, 460), (84, 112), rooms))

# ---- S4 Northeast nest 3x3, door (0,1)
rooms = []
r = R("Crab nest", 3, 3, (0, 1), 10)
r.carve((0, 1), (0, 0), (1, 0), (2, 0), (2, 1), (2, 2), (1, 2), (1, 1))
r.unroofed.add((1, 1))
r.loot = [(1, 1, 4), (2, 2, 2)]
r.crabs = [[(0, 0), (2, 0)]]
rooms.append(r)
r = R("Shell garden", 3, 3, (0, 1), 11)
r.whole(False)
r.extra = [sand(1, 0, 9, 5), sand(1, 2, 9, 5), rock(2, 1, 7, 9)]
r.loot = [(2, 0, 3), (2, 2, 2)]
rooms.append(r)
r = R("Collapsed corner", 3, 3, (0, 1), 12)
r.whole(True)
r.extra = ['{ Kind = "Ridge", Path = { { cx(1) + 4, cz(0) - 10 }, { cx(1) + 4, cz(2) + 10 } }, Height = 4.2, Width = 24 }']
r.loot = [(2, 1, 4), (2, 0, 2)]
rooms.append(r)
slots.append(("Northeast nest", (252, 124), (84, 84), rooms))

# ---- S5 Eastern midden 4x4, door (0,1)
rooms = []
r = R("Boulder scramble", 4, 4, (0, 1), 13)
r.whole(False)
r.extra = [rock(1, 0, 7, 11), rock(1, 2, 7, 11), rock(2, 1, 7, 11, 4, 0), rock(2, 3, 7, 11), rock(3, 1, 7, 10, 2, 0)]
r.loot = [(3, 0, 3), (3, 3, 4), (0, 3, 2)]
rooms.append(r)
r = R("Crab warren", 4, 4, (0, 1), 14)
r.carve((0, 1), (1, 1), (2, 1), (3, 1), (3, 2), (2, 2), (1, 2), (1, 3), (2, 3), (3, 3))
r.loot = [(3, 3, 4), (0, 3, 1), (3, 0, 2)]
r.crabs = [[(0, 1), (2, 1)], [(3, 2), (1, 2)]]
rooms.append(r)
r = R("Drowned hall", 4, 4, (0, 1), 15)
r.whole(True)
r.extra = [cut(0, 2, 3, 2, 3)]
r.loot = [(3, 3, 3), (3, 0, 2)]
rooms.append(r)
slots.append(("Eastern midden", (224, 236), (112, 112), rooms))

# ---- S6 Southeast burrow 3x4, door (0,2)
rooms = []
r = R("Deep tunnel", 3, 4, (0, 2), 16)
r.carve((0, 2), (1, 2), (2, 2), (2, 3), (1, 3), (0, 3))
r.carve((1, 2), (1, 1), (1, 0), (2, 0))
r.loot = [(0, 3, 4), (2, 0, 3)]
r.crabs = [[(1, 2), (2, 2)]]
rooms.append(r)
r = R("Collapsed gallery", 3, 4, (0, 2), 17)
r.whole(False)
r.extra = [
    '{ Kind = "Ridge", Path = { { cx(1), cz(1) }, { cx(2), cz(1) } }, Height = 4, Width = 16 }',
    rock(1, 3, 7, 9),
    rock(2, 0, 7, 8),
]
r.loot = [(2, 3, 3), (2, 0, 2)]
rooms.append(r)
r = R("Drowned gallery", 3, 4, (0, 2), 18)
r.whole(True)
r.extra = [cut(1, 0, 1, 3, 3)]
r.loot = [(2, 0, 3), (2, 3, 4)]
rooms.append(r)
slots.append(("Southeast burrow", (252, 460), (84, 112), rooms))

# ---- S7 South cellar 3x3, door (1,0)
rooms = []
r = R("Crab cellar", 3, 3, (1, 0), 19)
r.whole(True)
r.extra = [rock(1, 1, 8, 10)]
r.loot = [(0, 2, 3), (2, 2, 3)]
r.crabs = [[(0, 2), (2, 2)]]
rooms.append(r)
r = R("Shell hoard", 3, 3, (1, 0), 20)
r.carve((1, 0), (1, 1), (1, 2), (0, 2), (0, 1), (0, 0))
r.carve((1, 2), (2, 2), (2, 1))
r.loot = [(0, 0, 4), (2, 1, 2)]
rooms.append(r)
r = R("Flooded cellar", 3, 3, (1, 0), 21)
r.whole(True)
r.extra = [pond(1, 1, 18, 3)]
r.loot = [(0, 2, 3), (2, 2, 3)]
rooms.append(r)
slots.append(("South cellar", (56, 488), (84, 84), rooms))

out = []
out.append('''
-- Side rooms ----------------------------------------------------------------------------------
-- Each slot is a block of cells the frame walls off, with one door. A room is drawn in the
-- slot's own coordinates (cell centres at 14 + 28 c, 14 + 28 r) and fills the block.
local function cx(c)
	return 14 + PITCH * c
end
local function cz(r)
	return 14 + PITCH * r
end
local ROOM = gridOf(0, 0)

local function sandMound(x, z, radius, height)
	return { Kind = "Mound", At = { x, z }, Radius = radius, Height = height }
end
local function rockMound(x, z, radius, height)
	return mound(x, z, radius, height)
end
-- A solid block of rock through cell centres, exactly one cell (16) wide.
local function wall16(path)
	return { Kind = "Wall", Path = path, Height = WALL_HEIGHT, Width = 16 }
end

local function roomOf(spec)
	local lattice = parse(spec.Maze)
	local primitives = wallsOf(lattice, ROOM, nil, true)
	append(primitives, rubbleOf(lattice, ROOM))
	append(primitives, roofsOf(lattice, ROOM, nil))
	append(primitives, spec.Extra or {})
	return {
		Name = spec.Name,
		Primitives = primitives,
		Loot = lootOf(ROOM, spec.Loot or {}),
		Hazards = patrolsOf(ROOM, spec.Crabs or {}),
	}
end

local SLOT_ROOMS = {''')
for name, at, size, rooms in slots:
    out.append('\t{')
    out.append('\t\tName = "%s",' % name)
    out.append('\t\tAt = { %d, %d },' % at)
    out.append('\t\tSize = { %d, %d },' % size)
    out.append('\t\tRooms = {')
    for rm in rooms:
        out.append(rm.lua('\t\t\t'))
    out.append('\t\t},')
    out.append('\t},')
out.append('''}

local slots = {}
for _, slot in SLOT_ROOMS do
	local rooms = {}
	for _, spec in slot.Rooms do
		table.insert(rooms, roomOf(spec))
	end
	table.insert(slots, { Name = slot.Name, At = slot.At, Size = slot.Size, Rooms = rooms })
end
zone4.Slots = slots
''')
open(os.path.join(here, 'slots.luau'), 'w').write('\n'.join(out))
print('ok', sum(len(s[3]) for s in slots))
