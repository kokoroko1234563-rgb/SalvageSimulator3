"""Coral Garden, a biome rolling in zones 1 to 4 (docs/design/cards/coral-garden.md).

A dried-out reef: spines of pale coral standing in pairs with a cove between each pair, arches
through them. Gentle: sharp coral beds (the Slow hazard: step round them) are the only danger.
The entrance is an arch in the reef.

Run it with the quick check, once per zone:
    python3 tools/kit/quick.py 1 Biomes/Planned/CoralGarden --plan tools/kit/plans/coral_garden.py

Zones 1 to 3 are open sand (no walls, no rock, spines no taller than the zone allows):
  the frame is three pairs of low reef ridges across the zone (carts can't climb them, feet can:
  the shortcuts), a cove between each pair, and the entrance arch at the east end of the middle
  cove. A crossing is the cart's ramp, which opens an arch through each pair where it passes
  (a different place in each crossing, so the reef reads differently each tide), the coral beds
  and a tell at its way in.
Zone 4 is walled: the spines are rock. Two crossings, each with a cart path winding round the
  reef's rows (open sky) and a foot path through the arches (short roofs over a gap in the
  rock), two coves off the ways through for loot.

The map of zones 1 to 3 (zone coordinates, x -360 west to 360 east, z 0 top to 608 sea):

    z   0  ===== top ======
      100  ======== spine ========
      120      cove (finds at its ends)
      140  ======== spine ========
      280  ======== spine ========
      300      cove                       (the entrance arch at its east end)
      320  ======== spine ========
      460  ======== spine ========
      480      cove
      500  ======== spine ========
      608  ===== bottom ==
"""

from kit import Zone, write_zones

OUT = "src/shared/Layouts/Biomes/Planned/CoralGarden.luau"
NAME = "Coral Garden"
CORAL = "Concrete"  # the reef's pale, shell-grit ground
PAIRS = (120, 300, 480)  # the coves' middle lines (zones 2 and 3 move them off the rock pools)
SEP = 20  # a spine lies this far either side of its cove's line


# ---- helpers: the biome's vocabulary -----------------------------------------------------------
def box(cx, cz, w, d):
    return [(cx - w / 2, cz - d / 2), (cx + w / 2, cz - d / 2), (cx + w / 2, cz + d / 2),
            (cx - w / 2, cz + d / 2)]


def reef(part, cx, cz, w=60, d=50, count=6):
    """A stand of coral on the sand: dead coral, a few starfish and urchins at its foot."""
    part.decor("DeadCoral", area=box(cx, cz, w, d), count=count)
    part.decor("Starfish", area=box(cx, cz, w * 0.7, d * 0.7), count=2)
    part.decor("Urchins", area=box(cx, cz, w, d), count=1)


def bed(part, at, radius=9):
    """A bed of sharp coral: slows you, easy to step round. Coral thick on it marks it."""
    part.hazard("Slow", at=at, radius=radius)
    part.decor("DeadCoral", area=box(at[0], at[1], radius * 1.6, radius * 1.6), count=6)
    part.decor("Urchins", at=(at[0] + radius * 0.4, at[1] - radius * 0.3))


def spine_pair(part, zc, height, width, k):
    """A pair of reef spines across the zone with a cove between: pale coral ridges, a little
    uneven. `k` (1 or -1) bends the pair one way or the other."""
    for side in (-1, 1):
        zr = zc + side * SEP
        if height is None:
            # Zone 1: no ridge (even a low one hides too much of the zone from the top): the
            # spine is a narrow steep cleft in the sand, lined with coral. Carts can't cross
            # it, feet step down and up.
            part.add(Kind="Channel", Path=[(-364, zr), (-180, zr + 8 * k), (0, zr - 6 * k),
                                           (180, zr + 8 * k), (364, zr)],
                     Depth=2.4, Width=8, Rough=1, Material=CORAL)
            part.decor("DeadCoral", path=[(-330, zr + 6 * k), (330, zr + 6 * k)], count=11)
            continue
        part.add(Kind="Ridge", Path=[(-364, zr), (-180, zr + 8 * k), (0, zr - 6 * k),
                                     (180, zr + 8 * k), (364, zr)],
                 Height=height, Width=width, Rough=1, Material=CORAL)
        part.decor("DeadCoral", path=[(-330, zr + 6 * k), (330, zr + 6 * k)], count=9)
    part.decor("Starfish", path=[(-300, zc), (300, zc)], count=4)
    part.decor("Shells", path=[(-300, zc + 4), (300, zc - 4)], count=4)


def arch_tell(part, x, zc):
    """An arch the ramp opens through a pair: coral standing either side of it."""
    for side in (-1, 1):
        part.decor("DeadCoral", at=(x - 14, zc + side * SEP), scale=1.3)
        part.decor("DeadCoral", at=(x + 14, zc + side * SEP), scale=1.3)


def cove(part, at, weight):
    """A find in the cove between two spines, ringed with coral."""
    part.loot(at, radius=5, weight=weight)
    part.decor("DeadCoral", area=box(at[0], at[1], 24, 14), count=4)
    part.decor("Shells", at=(at[0] + 4, at[1] + 3))


# ---- zones 1 to 3: open sand --------------------------------------------------------------------
def shore(n, hmax, width, loot_at, pairs=PAIRS):
    z = Zone(n, NAME, rock=0)
    f = z.frame
    mid = pairs[1]
    for i, zc in enumerate(pairs):
        spine_pair(f, zc, hmax, width, 1 if i % 2 == 0 else -1)

    # The entrance: an arch in the reef, at the east end of the middle cove (cleared through both
    # spines, a flat place for the secret door).
    f.add(Kind="Flat", At=[322, mid], Radius=9)
    f.entrance((322, mid))
    for side in (-1, 1):
        f.decor("DeadCoral", at=(306, mid + side * SEP), scale=1.5)
        f.decor("DeadCoral", at=(338, mid + side * SEP), scale=1.5)
    f.decor("Starfish", at=(322, mid + 14))

    # Coral growing on the open sand between the pairs, and the finds in the coves.
    for cx, cz in ((-250, 50), (220, 60), (-60, 200), (260, 210), (-230, 390), (30, 400),
                   (-130, 560), (240, 570)):
        reef(f, cx, cz)
    f.decor("Pebbles", area=box(0, 560, 700, 70), count=6)
    f.decor("Shells", area=box(0, 400, 700, 80), count=6)
    f.decor("Driftwood", at=(-300, 400))
    for at, w in loot_at:
        cove(f, at, w)
    return z


def crossing(z, name, start, gaps, end, tell, beds, pairs=PAIRS):
    """The cart's ramp: down from `start`, through an arch `gaps[i]` in each pair, out at `end`.
    Straight down over the spines is quicker on foot."""
    c = z.crossing(name, paths=1)
    pts = [(start, 0), (start, 50)]
    for g, zc in zip(gaps, pairs):
        pts += [(g, zc - SEP - 18), (g, zc + SEP + 18)]
    pts += [(end, 560), (end, 608)]
    c.ramp(pts, width=16)
    for g, zc in zip(gaps, pairs):
        arch_tell(c, g, zc)
    for at in beds:
        bed(c, at)
    tell(c)
    return c


def tell_spires(x):
    def tell(c):
        c.decor("DeadCoral", path=[(x - 20, 14), (x + 20, 14)], count=3, scale=1.4)
        c.decor("Starfish", at=(x, 28))
    return tell


def tell_shells(x):
    def tell(c):
        c.decor("Shells", path=[(x - 20, 14), (x + 20, 14)], count=4)
        c.decor("Urchins", at=(x + 12, 24))
    return tell


def tell_snorkel(x):
    def tell(c):
        c.decor("Driftwood", at=(x, 16), yaw=70)
        c.decor("Crate", at=(x + 14, 10), yaw=20)
    return tell


P23 = (190, 350, 510)  # zones 2 and 3: clear of the rock pools at (140, 120) and (-60, 130)


def zone1():
    z = shore(1, None, 10, [((-300, 120), 1), ((-300, 300), 2),
                           ((300, 480), 3), ((-300, 480), 4)])
    crossing(z, "North arches", -40, (-150, 10, 150), 40, tell_spires(-40),
             [(-70, 60), (90, 210), (-60, 400), (110, 540)])
    crossing(z, "Middle arches", 130, (160, -20, -150), -60, tell_shells(130),
             [(40, 90), (-100, 220), (90, 400), (-40, 540)])
    crossing(z, "South arches", -150, (-120, 130, -10), 120, tell_snorkel(-150),
             [(-60, 70), (60, 230), (-80, 410), (60, 550)])
    return z


def zone2():
    z = shore(2, 4.4, 14, [((300, 190), 1), ((-300, 350), 2), ((-300, 190), 2),
                           ((300, 510), 3), ((-300, 510), 4)], P23)
    crossing(z, "North arches", -40, (-150, 10, 150), 40, tell_spires(-40),
             [(-70, 60), (90, 210), (-60, 400), (110, 540)], P23)
    crossing(z, "Middle arches", 175, (175, -20, -150), -60, tell_shells(175),
             [(40, 90), (-100, 220), (90, 400), (-40, 540)], P23)
    crossing(z, "South arches", -150, (-120, 130, -10), 120, tell_snorkel(-150),
             [(-60, 70), (60, 230), (-80, 410), (60, 550)], P23)
    return z


def zone3():
    z = shore(3, 6.4, 18, [((300, 190), 1), ((-300, 350), 2), ((-300, 190), 2),
                           ((300, 510), 3), ((-300, 510), 4)], P23)
    crossing(z, "North arches", -40, (-150, 10, 150), 40, tell_spires(-40),
             [(-70, 60), (90, 210), (-60, 400), (110, 540)], P23)
    crossing(z, "Middle arches", 175, (175, -20, -150), -60, tell_shells(175),
             [(40, 90), (-100, 220), (90, 400), (-40, 540)], P23)
    crossing(z, "South arches", -150, (-120, 130, -10), 120, tell_snorkel(-150),
             [(-60, 70), (60, 230), (-80, 410), (60, 550)], P23)
    return z


# ---- zone 4: walled, winding ---------------------------------------------------------------------
ROCK = 12  # reef spines you can't see over; arches are roofed at 10 clear


def serpentine(top_x, far_x, rows):
    """A snake down the zone: from the top at `top_x`, along each row from one side to the other,
    out at the bottom."""
    pts = [(top_x, 0)]
    here = top_x
    for zr in rows:
        pts.append((here, zr))
        here = far_x if here == top_x else top_x
        pts.append((here, zr))
    pts.append((here, 608))
    return pts


def bulge(part, at, bed_dx):
    """A wider stretch of a lane where the coral has spread: a bed of sharp coral to one side,
    easy to step round."""
    x, zz = at
    part.hall(box(x, zz, 48, 44))
    bed(part, (x + bed_dx, zz), radius=8)


def arch_way(part, pts):
    """The foot way through the reef: a lane 12 wide whose straight runs through the spines (every
    other segment) each pass under an arch: a short roof over the gap between two walls."""
    part.lane(pts, width=12)
    for i in range(0, len(pts) - 1, 2):
        (x, za), (_, zb) = pts[i], pts[i + 1]
        mid = (za + zb) / 2
        part.roof_lane([(x, mid - 16), (x, mid + 16)], 12)
        # A step of coral rubble in the arch's mouth: feet clamber over it, a cart can't.
        part.ridge([(x - 6, mid + 34), (x + 6, mid + 34)], height=2.5, width=12, rough=0)
        for side in (-1, 1):
            part.decor("DeadCoral", at=(x + side * 10, mid - 22), scale=1.3)
            part.decor("DeadCoral", at=(x + side * 10, mid + 22), scale=1.3)


def spur(part, a, b):
    """The way into the arch court: a lane with a short roof over its middle (an arch), kept
    clear of the junctions at its ends."""
    part.lane([a, b], width=12)
    (ax, az), (bx, _) = a, b
    s = 1 if bx > ax else -1
    part.roof_lane([(ax + s * 12, az), (bx - s * 12, az)], 12)


def dead_end(part, pts, weight):
    part.lane(pts, width=12)
    part.loot(pts[-1], radius=5, weight=weight)
    part.decor("DeadCoral", area=box(*pts[-1], 24, 24), count=4)


def cove_room(slot, name, weight, kind):
    """A cove between spines, off the ways through, in the slot's own coordinates (72 x 96)."""
    r = slot.room(name)
    if kind == "pool":
        r.hall([(8, 8), (64, 8), (64, 88), (8, 88)])
        r.hollow((36, 64), radius=10, depth=2)
        r.loot((36, 64), radius=5, weight=weight)
        r.decor("DeadCoral", area=box(36, 48, 48, 72), count=6)
        r.decor("Starfish", at=(36, 40))
    elif kind == "grotto":
        r.hall([(8, 8), (64, 8), (64, 88), (8, 88)], roof=True, pillars=[(36, 40), (36, 64)])
        r.loot((20, 76), radius=5, weight=weight)
        r.decor("DeadCoral", area=box(36, 52, 44, 70), count=5)
    elif kind == "cache":
        r.hall([(8, 8), (64, 8), (64, 88), (8, 88)], pillars=[(36, 48)])
        r.loot((20, 76), radius=5, weight=weight)
        r.decor("Crate", area=box(36, 48, 40, 70), count=3)
        r.decor("Shells", at=(24, 24))
    else:  # hollow: a snorkel left in a dried pool
        r.hall([(8, 8), (64, 8), (64, 88), (8, 88)])
        r.hollow((24, 70), radius=9, depth=3)
        r.loot((24, 70), radius=5, weight=weight)
        r.decor("Driftwood", at=(44, 30), yaw=30)
        r.decor("Urchins", at=(46, 60))
    return r


def zone4():
    z = Zone(4, NAME, rock=ROCK, material=CORAL)
    f = z.frame

    f.hall([(-260, -12), (260, -12), (260, 24), (-260, 24)])
    f.hall([(-260, 584), (260, 584), (260, 620), (-260, 620)])
    f.decor("DeadCoral", area=box(0, 6, 480, 24), count=8)
    f.decor("Starfish", area=box(0, 600, 480, 24), count=5)

    # The arch court: the reef's own arch in the middle, with the entrance in it. Each crossing
    # reaches it by a roofed arch from its middle row.
    f.hall(box(0, 312, 96, 80), pillars=[(-24, 312), (24, 312)])
    f.decor("DeadCoral", at=(0, 296), scale=1.8)
    f.decor("Starfish", at=(0, 336))
    f.entrance((0, 328))
    f.loot((0, 328), radius=6, weight=2)

    west = z.slot("Coves west", at=(-360, 102), size=(72, 96), door=(72, 48))
    cove_room(west, "Cove pool", 3, "pool")
    cove_room(west, "Reef grotto", 4, "grotto")
    f.lane([(-272, 150), (-224, 150)], width=12)
    east = z.slot("Coves east", at=(288, 140), size=(72, 96), door=(0, 48))
    cove_room(east, "Coconut cache", 3, "cache")
    cove_room(east, "Snorkel hollow", 4, "hollow")
    f.lane([(272, 188), (224, 188)], width=12)

    # ---- crossing 1: Round the reef -----------------------------------------------------------
    # A: the cart path, round the reef's rows in the east, open sky. B: the foot path down the
    # west, through the arches (quicker). Link: the arch court.
    c = z.crossing("Round the reef", paths=2)
    c.ramp(serpentine(96, 224, [96, 196, 300, 404, 504]), width=16)
    arch_way(c, serpentine(-96, -224, [112, 220, 312, 440]))
    spur(c, (96, 300), (48, 300))
    spur(c, (-96, 312), (-48, 312))
    dead_end(c, [(224, 352), (292, 352)], 2)
    bulge(c, (160, 96), 8)
    bulge(c, (160, 300), -8)
    bulge(c, (160, 504), 8)
    bulge(c, (-160, 440), -8)
    c.decor("DeadCoral", path=[(88, 14), (104, 14)], count=3, scale=1.5)  # the tell: coral spires
    c.decor("Starfish", at=(96, 28))
    c.decor("Shells", path=[(-104, 14), (-88, 14)], count=3)

    # ---- crossing 2: The arch road ---------------------------------------------------------------
    # A: the cart path, now in the west. B: the foot path through the arches in the east.
    c = z.crossing("The arch road", paths=2)
    c.ramp(serpentine(-96, -224, [96, 196, 300, 404, 504]), width=16)
    arch_way(c, serpentine(96, 224, [112, 220, 312, 440]))
    spur(c, (-96, 300), (-48, 300))
    spur(c, (96, 312), (48, 312))
    dead_end(c, [(-224, 352), (-292, 352)], 2)
    bulge(c, (-160, 96), -8)
    bulge(c, (-160, 300), 8)
    bulge(c, (-160, 504), -8)
    bulge(c, (160, 440), 8)
    c.decor("Shells", path=[(-104, 14), (-88, 14)], count=4)  # the tell: shells and an urchin
    c.decor("Urchins", at=(-96, 26))
    c.decor("Driftwood", at=(96, 16), yaw=100)
    return z


COMMENT = ("-- Coral Garden (planned): drawn with the layout kit from tools/kit/plans/coral_garden.py\n"
           "-- (edit the plan and re-run it, not this file). The card: docs/design/cards/coral-garden.md.")
write_zones(OUT, [zone1(), zone2(), zone3(), zone4()], COMMENT)
