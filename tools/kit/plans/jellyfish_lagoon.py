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
    cx, cz = 0, 340
    f.paint(box(cx, cz, 500, 400), SAND)
    # The lagoon: a row of hollows, the seaward ones deeper (it floods from the sea side first).
    for x in (-120, 0, 120):
        f.hollow((x, 315), radius=88, depth=hollow_depth - 1, rough=3, material=MUD)
        f.hollow((x * 0.85, 395), radius=84, depth=hollow_depth, rough=3, material=MUD)
    # Its ring of sand: wide enough that carts must go round it.
    ring = ellipse(cx, cz, 250, 190, 28)
    f.ridge(closed(ring), height=bank, width=16, rock=False, rough=1)
    # Two causeways across, north to south: one with a ford cut in it (foot only).
    f.ridge([(-70, 165), (-72, 340), (-70, 515)], height=bank - 0.6, width=16, rough=0)
    f.ridge([(96, 165), (98, 340), (96, 510)], height=bank - 0.6, width=16, rough=0)
    f.add(Kind="Channel", Path=[(98, 360), (98, 396)], Depth=2.4, Width=8, Rough=0, Material=MUD)
    f.decor("Weed", area=box(0, 340, 400, 300), count=10)
    f.decor(GLOW, area=box(0, 340, 400, 300), count=8)
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


# ---- zones 4 to 6: the lagoon in a rock cavern --------------------------------------------------
RX = 215  # the cavern's half width


def serp(xin, xfar, rows):
    """Lane points snaking from (xin, rows[0]) out to xfar and back, one pair of rows at a time."""
    pts = []
    for i in range(0, len(rows), 2):
        pts += [(xin, rows[i]), (xfar, rows[i]), (xfar, rows[i + 1]), (xin, rows[i + 1])]
    return pts


def rows_down(first, count, step=36):
    return [first + step * i for i in range(2 * count)]


def lagoon_hall(z, cz, rz, roof, pillars):
    f = z.frame
    poly = ellipse(0, cz, RX, rz, 36)
    f.hall(poly, roof=False, pillars=pillars)
    # The lagoon itself: hollows filling the cavern's middle, the seaward ones deeper.
    r = min(70, rz - 60)  # kept off the ring, where the cart ramp runs
    for x in (-85, 0, 85):
        f.hollow((x, cz - 10), radius=r, depth=3, rough=2, material=MUD)
        f.hollow((x, cz + 15), radius=r, depth=4, rough=2, material=MUD)
    f.paint(poly, SAND)
    if roof:
        f.roof_area(poly)
    f.decor("Weed", area=box(0, cz, 300, rz * 1.4), count=12)
    f.decor(GLOW, area=box(0, cz, 300, rz * 1.4), count=8)
    f.decor("Shells", area=box(0, cz, 2 * RX - 20, rz * 1.8), count=6)
    f.decor("Starfish", area=box(0, cz + rz - 20, 300, 30), count=4)
    return poly


def coves(z, cz, rz, sites):
    """Loot coves off the cavern's rim: a small chamber at the end of a short lane through the rock."""
    f = z.frame
    for x, dz, weight in sites:
        side = 1 if x > 0 else -1
        zz = cz + dz
        f.hall(box(x, zz, 44, 40))
        hw = RX * math.sqrt(max(0.0, 1 - (dz / rz) ** 2))
        f.lane([(side * (hw - 16), zz), (x, zz)], width=12)
        cove(f, (x, zz), weight)


def hall_z(cz, rz, x, side):
    """Where the cavern's rim is at x: its north (side -1) or south (+1) edge."""
    return cz + side * rz * math.sqrt(max(0.0, 1 - (x / RX) ** 2))


def walled(n, rock, roof, cz, rz, plan, jellies, tells, arc_end, p1_step=44):
    """`plan`: pairs of rows each path winds through above and below the cavern, as
    {"p1": (top, bottom), "p2": ..., "p3": ...} (cut down to what fits); `arc_end`: the angle the
    ring path leaves the rim at (-215: west, -325: east, the long way round)."""
    z = Zone(n, NAME, rock=rock)
    f = z.frame
    pillars = [(x, y) for x in (-120, 0, 120) for y in (cz - 50, cz, cz + 50)] if roof else ()
    lagoon_hall(z, cz, rz, roof, pillars)
    q = max(48, int(rz * 0.32))
    sites = ((-283, -q, 1), (283, -q, 2), (-283, q, 4), (283, q, 3))
    coves(z, cz, rz, sites)
    f.entrance((283, cz - q + 12))
    f.decor("Driftwood", at=(272, cz - q - 10), yaw=30)
    for x in (-110, 110):
        f.decor("Starfish", at=(x, 8))

    def top_rows(x, want, step=36):
        room = int((hall_z(cz, rz, x, -1) - 30 - 30) // step) + 1  # rows that fit above the cavern
        return rows_down(30, min(want, room // 2), step)

    def bottom_rows(x, want, step=36):
        first = int(hall_z(cz, rz, x, 1)) + 46
        fit = int((584 - first) // step) + 1
        return rows_down(first, min(want, fit // 2), step)

    ring_z = rz - 20
    east_exit = arc_end < -270
    for spec in (0, 1):
        s = 1 if spec == 0 else -1
        c = z.crossing(("East", "West")[spec] + " way", paths=3)

        # P1, the ring: top snake in the east, round the rim (north, west and, the long way, south),
        # bottom snake.
        t1 = top_rows(190, plan["p1"][0], p1_step)
        ring = [(round(188 * math.cos(math.radians(t))), round(cz + ring_z * math.sin(math.radians(t))))
                for t in range(-35, arc_end - 1, -15)]
        ex = 190 if east_exit else ring[-1][0]
        b1 = bottom_rows(ex, plan["p1"][1], p1_step)
        pts = [(190, -12)]
        if t1:
            pts += serp(190, 350, t1)
            pts += [(190, t1[-1] + 30)]
        pts += ring
        pts += [(ex, ring[-1][1])] if not east_exit else []
        if b1:
            pts += [(ex, b1[0])] + serp(ex, 350 if east_exit else -300, b1)[1:]
        pts += [(ex, 608)]
        c.ramp([(s * x, zz) for x, zz in pts], width=16)

        # P2, the causeway: top snake in the west, across the water on a causeway, down.
        t2 = top_rows(-60, plan["p2"][0])
        p2 = [(-60, -12)] + (serp(-60, -230, t2) if t2 else [])
        p2 += [(-60, hall_z(cz, rz, -60, -1) + 10)]
        c.lane([(s * x, zz) for x, zz in p2], width=12)
        b2 = bottom_rows(-60, plan["p2"][1])
        p2b = [(-60, hall_z(cz, rz, -60, 1) - 10)] + ([(-60, b2[0])] + serp(-60, -230, b2)[1:] if b2 else []) + [(-60, 620)]
        c.lane([(s * x, zz) for x, zz in p2b], width=12)
        c.ridge([(s * -60, hall_z(cz, rz, -60, -1) + 46), (s * -61, cz), (s * -60, hall_z(cz, rz, -60, 1) - 46)],
                height=3.4, width=12, rough=0)
        c.add(Kind="Channel", Path=[(s * -60, cz + 40), (s * -60, cz + 80)], Depth=2.4, Width=8,
              Rough=0, Material=MUD)

        # P3, through the lagoon at low tide: a snake in the middle above and below the floor.
        t3 = top_rows(-24, plan["p3"][0])
        p3 = [(-24, -12)] + (serp(-24, 150, t3) if t3 else []) + [(-24, hall_z(cz, rz, -24, -1) + 10)]
        c.lane([(s * x, zz) for x, zz in p3], width=12)
        b3 = bottom_rows(-24, plan["p3"][1])
        p3b = [(-24, hall_z(cz, rz, -24, 1) - 10)] + ([(-24, b3[0])] + serp(-24, 150, b3)[1:] if b3 else []) + [(-24, 620)]
        c.lane([(s * x, zz) for x, zz in p3b], width=12)

        # Rubble steps in the foot lanes where they reach the cavern: feet clamber, carts can't.
        for x in (-60, -24):
            for side in (-1, 1):
                zz = hall_z(cz, rz, x, side) + side * 26
                c.ridge([(s * (x - 6), zz), (s * (x + 6), zz)], height=2.5, width=12, rough=0)
        # The jellies: drifting in the water, stranded on the rim and the causeway.
        d = rz * 0.4
        drifting(c, [(s * -100, cz - d), (s * 0, cz - d * 0.5), (s * 60, cz - d * 0.9), (s * 120, cz - d * 0.3)])
        drifting(c, [(s * 20, cz + d * 0.1), (s * 40, cz + d * 0.5), (s * -10, cz + d * 0.8), (s * 30, cz + d)])
        for k in range(jellies):
            ang = math.radians(-190 + k * 360 / jellies)
            stranded(c, (s * round(170 * math.cos(ang)), round(cz + (rz - 36) * math.sin(ang))))
        for dz in (-0.45, -0.15, 0.15, 0.45):
            stranded(c, (s * -60, round(cz + dz * rz)))
        tells[spec](c)
    return z


def tell_a(c):
    c.decor(GLOW, path=[(180, 16), (220, 16)], count=3)
    c.decor("Shells", at=(200, 26))


def tell_b(c):
    c.decor("Timber", path=[(-80, 16), (-40, 16)], count=3)
    c.decor("Starfish", at=(-60, 26))


def zone4():
    return walled(4, 14, False, 330, 160, {"p1": (1, 1), "p2": (1, 0), "p3": (2, 1)}, 8,
                  (tell_a, tell_a), -215, p1_step=80)


def zone5():
    return walled(5, 18, True, 340, 150, {"p1": (2, 1), "p2": (2, 0), "p3": (2, 1)}, 10,
                  (tell_a, tell_a), -325)


def zone6():
    return walled(6, 20, True, 330, 120, {"p1": (3, 2), "p2": (3, 2), "p3": (3, 2)}, 12,
                  (tell_a, tell_a), -325)


COMMENT = ("-- Jellyfish Lagoon (planned): drawn with the layout kit from tools/kit/plans/jellyfish_lagoon.py\n"
           "-- (edit the plan and re-run it, not this file). The card: docs/design/cards/jellyfish-lagoon.md.")
if __name__ == "__main__":
    write_zones(OUT, [zone2(), zone3(), zone4(), zone5(), zone6()], COMMENT)
