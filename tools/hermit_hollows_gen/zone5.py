"""Zone 5 of Hermit Hollows: the sump. Flooded, low-roofed, wetter than zone 4."""
from warren import Warren

NAME = "Hermit Hollows (zone 5)"
ZONE = 5
WALL_HEIGHT = 20
CLEARANCE = 16
THICKNESS = 8

SLOTS = [
    dict(name="Weed pocket", box=(0, 2, 1, 3), door=('V', 3, 2)),
    dict(name="Sunken grotto", box=(21, 23, 1, 3), door=('V', 21, 2)),
    dict(name="Pool cave", box=(0, 3, 8, 11), door=('V', 4, 9)),
    dict(name="Channel cave", box=(20, 23, 7, 10), door=('V', 20, 9)),
    dict(name="Low den", box=(0, 2, 15, 18), door=('V', 3, 16)),
    dict(name="Sea den", box=(21, 23, 15, 18), door=('V', 21, 16)),
    dict(name="Deep cellar", box=(10, 12, 17, 19), door=('H', 17, 11)),
]
CHAMBERS = {
    'H': dict(name="Weed hall", box=(9, 11, 2, 3)),
    'N': dict(name="Drowned nave", box=(5, 7, 8, 10)),
    'B': dict(name="Brood pool", box=(10, 12, 8, 9)),
    'G': dict(name="Grotto", box=(16, 18, 8, 10)),
    'F': dict(name="Flood court", box=(5, 7, 15, 17)),
    'S': dict(name="Sea hall", box=(15, 17, 15, 16)),
}
TOP_DOORS = [1, 5, 10, 14, 18, 20]
BOT_DOORS = [2, 6, 9, 14, 16, 20, 23]
RIBS = [(6, [2, 7, 11, 16, 21]), (13, [4, 9, 14, 19, 22])]


def warren():
    return Warren(24, 20, TOP_DOORS, BOT_DOORS, RIBS, SLOTS, CHAMBERS, seed=5)


SPECS = [
    dict(name="West fords", top=1, bot=2, seed=105, bias=0.75, foot=64, cart=72, braids=6,
         wps=[(1, 0), (10, 3), (2, 5), (2, 6), (6, 9), (4, 12), (4, 13), (6, 16), (2, 19)]),
    dict(name="Weed hall run", top=5, bot=20, seed=117, bias=0.75, foot=64, cart=72, braids=6,
         wps=[(5, 0), (9, 2), (11, 5), (11, 6), (11, 8), (14, 12), (14, 13), (16, 15), (20, 19)]),
    dict(name="Brood crossing", top=10, bot=14, seed=131, bias=0.75, foot=64, cart=72, braids=6,
         wps=[(10, 0), (16, 2), (16, 5), (16, 6), (17, 8), (19, 12), (19, 13), (16, 16), (14, 19)]),
    dict(name="East grotto road", top=18, bot=23, seed=149, bias=0.75, foot=64, cart=72, braids=6,
         wps=[(18, 0), (21, 4), (21, 5), (21, 6), (16, 8), (14, 12), (14, 13), (23, 19)]),
    dict(name="Cellar spiral", top=20, bot=9, seed=163, bias=0.8, foot=62, cart=68, braids=6, lair='G',
         wps=[(20, 0), (20, 3), (2, 5), (2, 6), (6, 9), (17, 9), (20, 11), (22, 12), (22, 13), (9, 19)]),
]
