"""Zone 6 of Hermit Hollows: the deepest warren, tall walls, roofed corridors, a giant in each way."""
from warren import Warren

NAME = "Hermit Hollows (zone 6)"
ZONE = 6
WALL_HEIGHT = 24
CLEARANCE = 20
THICKNESS = 10

SLOTS = [
    dict(name="West nest", box=(0, 2, 1, 3), door=('V', 3, 2)),
    dict(name="East nest", box=(21, 23, 1, 3), door=('V', 21, 2)),
    dict(name="West midden", box=(0, 3, 6, 9), door=('V', 4, 7)),
    dict(name="East midden", box=(20, 23, 6, 9), door=('V', 20, 8)),
    dict(name="West deep", box=(0, 2, 11, 14), door=('V', 3, 12)),
    dict(name="East deep", box=(21, 23, 11, 14), door=('V', 21, 12)),
    dict(name="West vault", box=(0, 3, 16, 19), door=('V', 4, 17)),
    dict(name="East vault", box=(20, 23, 16, 19), door=('V', 20, 18)),
]
CHAMBERS = {
    'M': dict(name="Moult hall", box=(4, 6, 1, 3)),
    'A': dict(name="Antler cavern", box=(17, 19, 1, 3)),
    'C': dict(name="Carapace hall", box=(8, 10, 6, 8)),
    'E': dict(name="Nursery", box=(12, 14, 6, 7)),
    'T': dict(name="Shell throne", box=(14, 16, 11, 13)),
    'S': dict(name="Sea cavern", box=(6, 8, 16, 18)),
}
TOP_DOORS = [2, 7, 11, 15, 20, 22]
BOT_DOORS = [4, 7, 10, 13, 16, 19]
RIBS = [(5, [3, 8, 13, 19]), (10, [6, 11, 16, 19]), (15, [4, 9, 14, 18])]


def warren():
    return Warren(24, 20, TOP_DOORS, BOT_DOORS, RIBS, SLOTS, CHAMBERS, seed=6)


SPECS = [
    dict(name="Moult descent", top=2, bot=10, seed=206, bias=0.8, foot=84, cart=92, braids=6, lair='M',
         wps=[(2, 0), (5, 2), (13, 3), (19, 4), (19, 5), (12, 7), (9, 7), (6, 9), (6, 10), (6, 12), (12, 12),
              (14, 14), (14, 15), (10, 17), (10, 19)]),
    dict(name="Antler road", top=20, bot=19, seed=219, bias=0.8, foot=84, cart=92, braids=6, lair='A',
         wps=[(20, 0), (18, 2), (8, 4), (8, 5), (9, 7), (16, 8), (16, 9), (16, 10), (15, 12), (4, 13), (4, 14),
              (4, 15), (7, 17), (19, 19)]),
    dict(name="Carapace crossing", top=11, bot=13, seed=231, bias=0.8, foot=84, cart=92, braids=6, lair='C',
         wps=[(11, 0), (3, 3), (3, 4), (3, 5), (9, 7), (12, 7), (16, 9), (16, 10), (15, 12), (4, 13), (4, 14),
              (4, 15), (7, 17), (13, 19)]),
    dict(name="Throne road", top=7, bot=7, seed=247, bias=0.8, foot=84, cart=92, braids=6, lair='T',
         wps=[(7, 0), (7, 2), (15, 2), (13, 4), (13, 5), (13, 7), (6, 9), (6, 10), (15, 12), (18, 14), (18, 15),
              (12, 17), (7, 19)]),
    dict(name="Cavern spiral", top=22, bot=16, seed=263, bias=0.85, foot=88, cart=96, braids=6, lair='S',
         wps=[(22, 0), (3, 3), (3, 4), (3, 5), (18, 8), (19, 9), (19, 10), (5, 13), (4, 14), (4, 15), (7, 17),
              (16, 19)]),
]
