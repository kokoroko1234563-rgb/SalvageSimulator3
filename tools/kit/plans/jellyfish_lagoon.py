"""Jellyfish Lagoon, a biome rolling in zones 2 to 6 (docs/design/cards/jellyfish-lagoon.md).

One big lagoon held in a ring of sand, causeways across it, the water purple and glowing with
jellyfish. Jellies drift in the water (`Path`) and lie stranded on the sand and causeways (`At`,
sting area): a sting drops what you hold and does damage; from zone 5 it stuns too.

Run it with the quick check, once per zone:
    python3 tools/kit/quick.py 2 Biomes/Planned/JellyfishLagoon --plan tools/kit/plans/jellyfish_lagoon.py

Zones 2 and 3 are open shore (no walls, no rock; banks no taller than the zone allows, 5 and 7):
  the lagoon is a hollow (deeper on its seaward side, so it floods from there first) ringed by a
  low bank of sand, with two causeways across it (one with a ford cut in it: foot-only). A
  crossing is the cart's ramp round the ring (west or east); on foot the causeways cut straight
  across, past the jellies.
Zones 4 to 6 are walled: the lagoon sits in a rock cavern (in zones 5 and 6 under a roof of
  rock held up on pillars, the card's ceiling). Three paths in each crossing: the ring (long, dry,
  the carts' ramp), the causeways (quick, through the jellies) and, at low tide, the lagoon floor.

Map of the open zones (zone coordinates, x -360 west to 360 east, z 0 top to 608 sea):

    z   0  ===== top =====
      160        . . ring of sand . .
      200   cart ramp     ~~~ the lagoon ~~~    cart ramp      (causeways across, N to S)
      310   (round the   ~~~ deeper to the sea ~~~
      460    ring)         . . ring of sand . .
      608  ===== bottom ==
"""

import math

from kit import Zone, write_zones, segment_box, rounded

OUT = "src/shared/Layouts/Biomes/Planned/JellyfishLagoon.luau"
NAME = "Jellyfish Lagoon"
MUD = "Mud"
SAND = "Sand"
GLOW = "GlowWeed"


# ---- helpers: the biome's vocabulary -----------------------------------------------------------
def box(cx, cz, w, d):
    return [(cx - w / 2, cz - d / 2), (cx + w / 2, cz - d / 2), (cx + w / 2, cz + d / 2),
            (cx - w / 2, cz + d / 2)]


def ellipse(cx, cz, rx, rz, n=24, start=0.0):
    return [(round(cx + rx * math.cos(start + 2 * math.pi * i / n)),
             round(cz + rz * math.sin(start + 2 * math.pi * i / n))) for i in range(n)]


def closed(points):
    return list(points) + [points[0]]


def shore_decor(part, at, w=40, d=30):
    part.decor("Weed", area=box(at[0], at[1], w, d), count=3)
    part.decor("Shells", area=box(at[0], at[1], w, d), count=2)
    part.decor("Starfish", at=(at[0] + 4, at[1] - 3))


def stranded(part, at, radius=4):
    """A jelly stranded on the sand: its sting area is lit by its glow."""
    part.hazard("Jelly", at=at, radius=radius)
    part.decor("GlowShells", at=(at[0] + 3, at[1] + 2))


def drifting(part, path):
    part.hazard("Jelly", path=path)


def cove(part, at, weight, radius=5):
    """A find in a cove on the ring, ringed with shells and glowing weed."""
    part.loot(at, radius=radius, weight=weight)
    part.decor("Shells", area=box(at[0], at[1], 24, 16), count=3)
    part.decor(GLOW, at=(at[0] - 5, at[1] + 4))
    part.decor("Starfish", at=(at[0] + 5, at[1] - 3))


# ---- zones 2 and 3: open shore ------------------------------------------------------------------
def shore(n, bank, hollow_depth):
    z = Zone(n, NAME, rock=0)
    f = z.frame
    cx, cz = 0, 310
    f.paint(box(cx, cz, 500, 400), SAND)
    # The lagoon: a row of hollows, the seaward ones deeper (it floods from the sea side first).
    for x in (-120, 0, 120):
        f.hollow((x, 285), radius=88, depth=hollow_depth - 1, rough=3, material=MUD)
        f.hollow((x * 0.85, 365), radius=84, depth=hollow_depth, rough=3, material=MUD)
    # Its ring of sand: wide enough that carts must go round it.
    ring = ellipse(cx, cz, 250, 200, 28)
    f.ridge(closed(ring), height=bank, width=16, rock=False, rough=1)
    # Two causeways across, north to south: one with a ford cut in it (foot only).
    f.ridge([(-70, 125), (-72, 310), (-70, 495)], height=bank - 0.6, width=12, rough=0)
    f.ridge([(96, 130), (98, 310), (96, 490)], height=bank - 0.6, width=12, rough=0)
    f.add(Kind="Channel", Path=[(98, 330), (98, 366)], Depth=2.4, Width=8, Rough=0, Material=MUD)
    f.decor("Weed", area=box(0, 316, 400, 300), count=10)
    f.decor(GLOW, area=box(0, 316, 400, 300), count=8)
    # Where the finds lie: coves round the ring, the best on the sea side.
    for at, w in (((-300, 120), 1), ((300, 150), 1), ((-300, 320), 2), ((300, 400), 3),
                  ((-200, 545), 3), ((110, 555), 4)):
        cove(f, at, w)
    f.entrance((300, 290))
    f.decor("Driftwood", at=(306, 278), yaw=40)
    f.decor("Shells", area=box(0, 580, 600, 40), count=6)
    f.decor("Starfish", area=box(0, 50, 600, 60), count=4)
    return z


def shore_crossing(z, name, side, tell):
    """The cart's ramp round the ring on `side` (-1 west, 1 east); feet cut across the causeways.
    Stranded jellies on the ring and the causeways, drifting ones in the water."""
    c = z.crossing(name, paths=1)
    s = side
    c.ramp([(0, 0), (0, 40), (s * 150, 60), (s * 285, 150), (s * 290, 460), (s * 150, 560), (0, 570),
            (0, 608)], width=16)
    for at in ((-71, 190), (97, 250), (-71, 430), (96, 450), (-200, 160), (190, 460), (0, 118),
               (-230, 300), (232, 330), (20, 505)):
        stranded(c, at)
    drifting(c, [(-150, 250), (-20, 230), (40, 270), (150, 250)])
    drifting(c, [(-130, 380), (0, 420), (130, 380)])
    tell(c)
    return c


def tell_posts(c, x):
    c.decor("Timber", path=[(x - 14, 16), (x + 14, 16)], count=3)
    c.decor(GLOW, at=(x, 30))


def zone2():
    z = shore(2, 4.2, 3)
    shore_crossing(z, "West ring", -1, lambda c: tell_posts(c, -130))
    shore_crossing(z, "East ring", 1, lambda c: tell_posts(c, 130))
    return z


def zone3():
    z = shore(3, 6.0, 4)
    shore_crossing(z, "West ring", -1, lambda c: tell_posts(c, -130))
    shore_crossing(z, "East ring", 1, lambda c: tell_posts(c, 130))
    return z


COMMENT = ("-- Jellyfish Lagoon (planned): drawn with the layout kit from tools/kit/plans/jellyfish_lagoon.py\n"
           "-- (edit the plan and re-run it, not this file). The card: docs/design/cards/jellyfish-lagoon.md.")
if __name__ == "__main__":
    write_zones(OUT, [zone2(), zone3()], COMMENT)
