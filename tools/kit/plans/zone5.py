"""Zone 5, The Shoals (docs/design/cards/zone5.md), drawn with the layout kit like zone 6.

  1. the frame: the bands, the Grotto, seven sandbar courts with their slots' doors;
  2. each crossing: a wet path (fords, foot only, quick), a dry path (the cart's ramp, long),
     in the three-path crossing a path through the Grotto, in the one-path crossing only that;
  3. each slot's rooms: one door, different kinds, the best finds deepest.

Run it with the quick check:  python3 tools/kit/quick.py 5 --plan tools/kit/plans/zone5.py

The map (zone coordinates: x -360 west to 360 east, z 0 at the top to 608 at the sea):

    z   0  ================ the top band (every path starts here) ==================
       52  rows (the top rows)      the bars cross the zone at z 124, 248, 372, 496
      124  ----- bar 1 ----   [W1 court]                          (rock, 24 thick)
      184  rows                                    [E1 court]
      248  ----- bar 2 ----   [W2 court]
      310  the Grotto: a roofed hall between the middle gaps  [W3 court]  [E2 court]
      372  ----- bar 3 ----
      432  rows                [W4 court]                         [E3 court]
      496  ----- bar 4 ----
      592  ================ the bottom band (the Far Sandbar's approach) ===========

Every path winds in the strip between the courts (x -148 to 148). Between the second and third
bars the only ground is the two gaps beside the Grotto (x -128 and 128) and the Grotto itself,
so each crossing's paths are ordered west to east and pass the bars there. The courts (open sky,
with their slots' doors) are reached by stubs off the paths: every crossing reaches every court.
The wet path (fords, narrow lanes, foot only) is the short one; the dry path (the cart's ramp,
on sandbars) the long one; where one winds the other runs straight.
"""

import math

from kit import Zone, segment_box, rounded

ROCK = 14  # the bars: too high to jump or see over
BARS = (124, 248, 372, 496)  # z of the four bars (24 thick)
COL = 152  # the gaps beside the Grotto: the lanes go down x -152 and 152 (ramps at 148)
RC = 148

z = Zone(5, "The Shoals", rock=ROCK)
f = z.frame


# ---- helpers: the zone's own vocabulary ---------------------------------------------------------
def along(points, every, start=None):
    """Points every `every` studs along a polyline (not the ends)."""
    out = []
    carry = every / 2 if start is None else start
    for (ax, az), (bx, bz) in zip(points, points[1:]):
        length = math.hypot(bx - ax, bz - az)
        d = carry
        while d < length:
            t = d / length
            out.append((ax + (bx - ax) * t, az + (bz - az) * t))
            d += every
        carry = d - length
    return out


def dry_way(part, points, width=16, every=90):
    """The dry path: the cart's ramp over the sandbars, pebbles scattered along its sides."""
    part.ramp(points, width=width)
    side = width / 2 + 3
    n = 0
    for (ax, az), (bx, bz) in zip(points, points[1:]):
        length = math.hypot(bx - ax, bz - az)
        if length < 40:
            continue
        for x, zz in along([(ax, az), (bx, bz)], every, start=every / 2 + 11 * n):
            nx, nz = -(bz - az) / length * side, (bx - ax) / length * side
            sign = 1 if n % 2 == 0 else -1
            part.decor("Pebbles", at=(round(x + sign * nx), round(zz + sign * nz)), scale=1.1)
            n += 1


def wet_way(part, points, width=12):
    """The wet path: a narrow lane through the sandbars, foot only (the fords have sills)."""
    part.lane(points, width=width)


def ford(part, x, zb, sink=None, nook=None):
    """A ford through the bar at `zb` on the vertical lane at x: a cut with a sand sill, the undertow
    in it (safe going down, deadly coming back late), fence posts and a net across it, the holding
    sand on the way in, and (nook) a pit in a niche beside it."""
    part.channel([(x, zb - 20), (x, zb + 20)], depth=3, width=12, rough=1, material="Mud")
    part.ridge([(x, zb - 6), (x, zb + 6)], height=3, width=12, rough=0)  # the sill
    part.hazard("Undertow", path=[(x, zb - 24), (x, zb + 24)], width=12)
    part.decor("Timber", at=(x - 5, zb - 24), yaw=90, scale=0.8)
    part.decor("Timber", at=(x + 5, zb - 24), yaw=90, scale=0.8)
    part.decor("Chain", path=[(x - 4, zb - 24), (x + 4, zb - 24)], count=2)
    part.decor("Weed", area=[(x - 5, zb - 18), (x + 5, zb - 18), (x + 5, zb + 18), (x - 5, zb + 18)],
               count=3)
    if sink is not False:
        part.hazard("Sink", at=(x, zb - 38 if sink is None else sink), radius=9)
    if nook:
        landing_pit(part, x, zb, nook)


def landing_pit(part, x, zb, side):
    """The landing before a ford is wider on one side, with an open spike pit in the widening: a
    careful player on the lane's middle never meets it, one cutting the corner might."""
    part.lane([(x + side * 8, zb - 46), (x + side * 8, zb - 28)], width=28)
    part.hazard("Pit", at=(x + side * 16, zb - 38), radius=4, covered=False)


def row_ford(part, a, b, depth=3):
    """A runnel along a row of a wet lane: a cut with the undertow in it."""
    part.channel([a, b], depth=depth, width=12, rough=1, material="Mud")
    part.hazard("Undertow", path=[a, b], width=12)
    part.decor("Weed", path=[a, b], count=3)


def corner_sink(part, at, radius=9):
    part.hazard("Sink", at=at, radius=radius)


def stub(part, x, zz, court_x):
    """A dead-end lane from a path to a court (the court's slot door opens on it)."""
    part.lane([(x, zz), (court_x, zz)], width=12)


def court_stubs(part, west=(), east=(), via=None):
    """Lanes from a path's lane at x -152 (west) or 152 (east) out to the courts' edges."""
    for zz in west:
        stub(part, -COL, zz, -184)
    for zz in east:
        stub(part, COL, zz, 184)


def scramble(part, a, b, clear=10):
    """A foot-only shortcut between two lanes: a gap choked with rubble, too steep for a cart.
    It cuts a bend without making a path of its own."""
    part.lane([a, b], width=12)
    (ax, az), (bx, bz) = a, b
    length = math.hypot(bx - ax, bz - az)
    ux, uz = (bx - ax) / length, (bz - az) / length
    k = clear + 6
    part.ridge([(ax + ux * k, az + uz * k), (bx - ux * k, bz - uz * k)], height=2.5, width=12, rough=0)


def grotto_door(part, side, zz=294):
    """The Grotto's door onto a gap lane (x -128 or 128): a short lane into the north aisle."""
    part.lane([(side * COL, zz), (side * 96, zz)], width=12)


# ---- the frame ----------------------------------------------------------------------------------
# The bands: the top (where every path starts) and the bottom (the Far Sandbar's approach).
f.hall([(-360, -12), (360, -12), (360, 20), (-360, 20)])
f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])
f.decor("Weed", area=[(-340, 2), (340, 2), (340, 16), (-340, 16)], count=10)

# The Grotto: a roofed hall across the middle, the zone's landmark and shelter. (A cart's way
# through it opens a rift in the roof: ramps clear what they cross.)
f.hall([(-96, 286), (96, 286), (96, 334), (-96, 334)], roof=True,
       pillars=[(-72, 312), (-36, 312), (36, 312), (72, 312)])
f.decor("GlowShells", at=(-60, 296))
f.decor("GlowShells", at=(60, 328))
f.decor("Starfish", at=(-20, 296), scale=0.9)
f.decor("Urchins", at=(24, 296), scale=0.9)
f.decor("Weed", area=[(-90, 290), (90, 290), (90, 330), (-90, 330)], count=5)
f.loot((0, 324), radius=6, weight=3)

# The courts: open sandbars, one for each slot, on the west (x -240 to -184) and the east
# (184 to 240). Paths reach them by stubs; a slot's door opens on the court's outer edge.
COURTS_W = (92, 212, 316, 432)  # the centres' z
COURTS_E = (184, 308, 432)
for cz in COURTS_W:
    f.court([(-240, cz - 34), (-184, cz - 34), (-184, cz + 34), (-240, cz + 34)])
    f.decor("Pebbles", area=[(-236, cz - 30), (-188, cz - 30), (-188, cz + 30), (-236, cz + 30)], count=4)
    f.decor("Weed", area=[(-236, cz - 30), (-188, cz - 30), (-188, cz + 30), (-236, cz + 30)], count=2)
for cz in COURTS_E:
    f.court([(184, cz - 34), (240, cz - 34), (240, cz + 34), (184, cz + 34)])
    f.decor("Pebbles", area=[(188, cz - 30), (236, cz - 30), (236, cz + 30), (188, cz + 30)], count=4)
    f.decor("Weed", area=[(188, cz - 30), (236, cz - 30), (236, cz + 30), (188, cz + 30)], count=2)


# ---- crossing 1: Mussel run (2 paths) -----------------------------------------------------------
# Wet: from the top bank into the west gap (fords at bars 1 to 3), then runs back and forth in
# the south-west and the last ford at bar 4. Dry (the cart's): the top rows winding east and
# west, the east gap, then two rows in the south-east. The Grotto is open on the west.
c = z.crossing("Mussel run", paths=2)
dry_way(c, [(RC, 12), (RC, 52), (-112, 52), (-112, 92), (RC, 92), (RC, 144), (-112, 144), (-112, 184),
            (RC, 184), (RC, 392), (40, 392), (40, 432), (RC, 432), (RC, 608)])
wet_way(c, [(-60, 12), (-60, 52), (-COL, 52), (-COL, 392), (-40, 392), (-40, 432), (-COL, 432),
            (-COL, 472), (-40, 472), (-40, 516), (-COL, 516), (-COL, 608)])
ford(c, -COL, BARS[0], sink=62, nook=1)
ford(c, -COL, BARS[1], sink=186, nook=1)
ford(c, -COL, BARS[2], sink=336)
ford(c, -40, BARS[3], sink=472)
court_stubs(c, west=(72, 232, 316, 432), east=(184, 308, 432))
grotto_door(c, -1)
c.decor("Timber", at=(-160, 8), yaw=80)  # the tell: fence posts and a net across the way in
c.decor("Timber", at=(-136, 8), yaw=80)
c.decor("Chain", path=[(-160, 8), (-136, 8)], count=2)


# ---- crossing 2: Reed bank (2 paths) ------------------------------------------------------------
# Wet: five runs in the north-east, then straight down the east gap (fords at bars 1 to 4).
# Dry (the cart's): straight down the west gap, then five long rows in the south. The Grotto is
# open on the east.
c = z.crossing("Reed bank", paths=2)
dry_way(c, [(-RC, 12), (-RC, 392), (70, 392), (70, 432), (-RC, 432), (-RC, 472), (70, 472),
            (70, 516), (-RC, 516), (-RC, 556), (70, 556), (70, 608)])
wet_way(c, [(20, 12), (20, 52), (COL, 52), (COL, 92), (20, 92), (20, 144), (COL, 144), (COL, 184),
            (20, 184), (20, 224), (COL, 224), (COL, 420), (112, 420), (112, 460), (COL, 460), (COL, 608)])
ford(c, 20, BARS[0], sink=96)
ford(c, COL, BARS[1], sink=186, nook=-1)
ford(c, COL, BARS[2], sink=336, nook=-1)
ford(c, COL, BARS[3], sink=460)
court_stubs(c, west=(72, 232, 316, 432), east=(184, 308, 432))
grotto_door(c, 1)
c.decor("Anchor", at=(-160, 8), yaw=120)  # the tell: an old anchor and its chain at the way in
c.decor("Chain", path=[(-156, 14), (-140, 8)], count=2)


# ---- crossing 3: Three lanes (3 paths) ----------------------------------------------------------
# Wet: the west gap, then runs in the south-west. Dry (the cart's): five long rows across the
# top, then straight down through the Grotto (a rift in its roof). A third, dry foot lane down
# the east gap, with a runnel, and runs in the south-east.
c = z.crossing("Three lanes", paths=3)
dry_way(c, [(-112, 12), (-112, 52), (112, 52), (112, 92), (-112, 92), (-112, 144), (112, 144),
            (112, 184), (-112, 184), (-112, 224), (0, 224), (0, 608)])
wet_way(c, [(-COL, 12), (-COL, 392), (-40, 392), (-40, 432), (-COL, 432),
            (-COL, 472), (-40, 472), (-40, 516), (-COL, 516), (-COL, 608)])
wet_way(c, [(COL, 12), (COL, 392), (40, 392), (40, 432), (COL, 432), (COL, 472), (40, 472), (40, 516),
            (COL, 516), (COL, 556), (40, 556), (40, 608)])
ford(c, -COL, BARS[0], sink=62)
ford(c, -COL, BARS[1], sink=186, nook=1)
ford(c, -COL, BARS[2], sink=336)
ford(c, -40, BARS[3], sink=472)
row_ford(c, (110, 472), (70, 472))
court_stubs(c, west=(72, 232, 316, 432), east=(184, 308, 432))
c.decor("Bones", at=(-8, 8), scale=1.3)  # the tell: an arch of bones over the middle way in
c.decor("GlowShells", at=(8, 14))


# ---- crossing 4: The Grotto way (1 path) --------------------------------------------------------
# Everything funnelled through the Grotto: the top rows, the tunnel (a rift in its roof where the
# cart passes), then straight down. Two rubble scrambles shortcut the rows on foot; the gaps
# beside the Grotto are rock. The courts are reached from the rows and the Grotto's doors.
c = z.crossing("The Grotto way", paths=1)
dry_way(c, [(-112, 12), (-112, 52), (112, 52), (112, 92), (-112, 92), (-112, 144), (112, 144),
            (112, 184), (-112, 184), (-112, 224), (0, 224), (0, 608)])
scramble(c, (0, 52), (0, 92))
scramble(c, (0, 144), (0, 184))
c.lane([(-96, 294), (-184, 294)], width=12)  # the Grotto's doors onto the courts
c.lane([(96, 294), (184, 294)], width=12)
c.lane([(-112, 92), (-184, 92)], width=12)
c.lane([(-112, 184), (-184, 184)], width=12)
c.lane([(112, 184), (184, 184)], width=12)
c.lane([(-184, 432), (184, 432)], width=12)
c.decor("LanternPost", at=(-12, 8))  # the tell: a pair of lanterns over the Grotto way
c.decor("LanternPost", at=(12, 8))


# ---- crossing 5: Sandbar loop (2 paths) ---------------------------------------------------------
# Wet: the west edge, three runs at the top and two at the bottom. Dry (the cart's): the east,
# four rows at the top and four at the bottom. The Grotto is open on the east.
c = z.crossing("Sandbar loop", paths=2)
dry_way(c, [(RC, 12), (RC, 52), (0, 52), (0, 92), (RC, 92), (RC, 144), (0, 144), (0, 184),
            (RC, 184), (RC, 392), (0, 392), (0, 432), (RC, 432), (RC, 472), (0, 472), (0, 516),
            (RC, 516), (RC, 608)])
wet_way(c, [(-52, 12), (-52, 52), (-COL, 52), (-COL, 92), (-52, 92), (-52, 144), (-COL, 144),
            (-COL, 392), (-52, 392), (-52, 432), (-COL, 432), (-COL, 608)])
ford(c, -52, BARS[0], sink=96)
ford(c, -COL, BARS[1], sink=186, nook=1)
ford(c, -COL, BARS[2], sink=336)
ford(c, -COL, BARS[3], sink=450, nook=1)
court_stubs(c, west=(72, 232, 316, 432), east=(184, 308, 432))
grotto_door(c, 1)
c.decor("Urchins", at=(-60, 8))  # the tell: urchins and starfish on the bank
c.decor("Starfish", at=(-40, 10))
c.decor("Starfish", at=(-50, 4), scale=1.2)


# ---- the rooms: kinds a slot can hold (each in the slot's own coordinates) ------------------------
def inward(slot):
    """The door, the point deepest in from it, and the direction in (a unit step)."""
    (w, d), (dx, dz) = slot.size, slot.door
    if dz == 0:
        return (dx, dz), (dx, d - 12), (0, 1)
    if dz == d:
        return (dx, dz), (dx, 12), (0, -1)
    if dx == 0:
        return (dx, dz), (w - 12, dz), (1, 0)
    return (dx, dz), (12, dz), (-1, 0)


def box(slot, inset=8):
    w, d = slot.size
    return [(inset, inset), (w - inset, inset), (w - inset, d - inset), (inset, d - inset)]


def dead_end_cave(slot, name, weight=3):
    """A gallery straight in, short dead-end caves off both sides; the best find in the deepest,
    on a covered pit."""
    r = slot.room(name, lead=False)
    door, deep, (ix, iz) = inward(slot)
    r.lane([door, deep], width=12)
    w, d = slot.size
    length = abs(deep[0] - door[0]) + abs(deep[1] - door[1])
    for k, t in enumerate(range(20, int(length) - 4, 22)):
        x, zz = door[0] + ix * t, door[1] + iz * t
        side = 1 if k % 2 == 0 else -1
        reach = (w if iz else d) / 2 - 10
        end = (x + iz * side * reach, zz + ix * side * reach)
        r.lane([(x, zz), end], width=12)
        r.loot(end, radius=3, weight=1)
    r.loot(deep, radius=4, weight=weight)
    r.hazard("Pit", at=deep, radius=4, covered=True)
    r.decor("Barnacles", area=box(slot), count=6)
    return r


def drowned_pool(slot, name, weight=4):
    """A pool that floods first; the find at its bottom, starfish and urchins round it."""
    r = slot.room(name)
    r.hall(box(slot))
    _, deep, _ = inward(slot)
    w, d = slot.size
    radius = min(w, d) / 2 - 12
    r.hollow(deep, radius=radius, depth=4, material="Mud")
    r.loot(deep, radius=4, weight=weight)
    r.decor("Starfish", area=box(slot, 14), count=3)
    r.decor("Urchins", area=box(slot, 14), count=3)
    r.decor("Weed", area=box(slot, 12), count=4)
    return r


def boulder_scramble(slot, name, weight=2):
    """Fallen boulders to clamber over; the find behind the biggest."""
    r = slot.room(name)
    r.hall(box(slot))
    door, deep, (ix, iz) = inward(slot)
    w, d = slot.size
    for k, (fx, fz) in enumerate([(0.3, 0.35), (0.7, 0.5), (0.4, 0.7), (0.65, 0.25)]):
        r.mound((round(w * fx), round(d * fz)), radius=7, height=5 + k % 2, rock=True)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Barnacles", area=box(slot), count=4)
    return r


def weed_channel(slot, name, weight=2):
    """A channel choked with weed along the room, the undertow in it; the find at its far end."""
    r = slot.room(name)
    r.hall(box(slot))
    door, deep, (ix, iz) = inward(slot)
    w, d = slot.size
    start = (door[0] + ix * 14, door[1] + iz * 14)
    r.channel([start, deep], depth=3, width=12, material="Mud")
    r.hazard("Undertow", path=[start, deep], width=12)
    r.decor("Weed", path=[start, deep], count=8)
    r.decor("Kelp", area=box(slot, 12), count=3)
    r.loot(deep, radius=4, weight=weight)
    return r


# ---- the slots ----------------------------------------------------------------------------------
# West slots (x -352 to -256) and east slots (256 to 352), each with its door onto a court.
# The best finds are deepest: in the caves and at the bottom of the pools.
W, E = -352, 256
s1 = z.slot("Weed cove", at=(W, 92 - 32), size=(96, 64), door=(96, 32))
drowned_pool(s1, "Drowned pool", weight=4)
dead_end_cave(s1, "Dead-end cave", weight=3)

s2 = z.slot("Fallen stacks", at=(W, 212 - 32), size=(96, 64), door=(96, 32))
boulder_scramble(s2, "Boulder scramble", weight=2)
weed_channel(s2, "Weed channel", weight=2)

s3 = z.slot("Reef cave", at=(W, 316 - 32), size=(96, 64), door=(96, 32))
dead_end_cave(s3, "Reef cave", weight=4)
drowned_pool(s3, "Sunk pool", weight=3)

s4 = z.slot("Outer hollow", at=(W, 432 - 32), size=(96, 64), door=(96, 32))
weed_channel(s4, "Weed channel", weight=2)
boulder_scramble(s4, "Boulder scramble", weight=2)

s5 = z.slot("Eastern shelf", at=(E, 184 - 32), size=(96, 64), door=(0, 32))
drowned_pool(s5, "Drowned pool", weight=4)
weed_channel(s5, "Weed channel", weight=2)

s6 = z.slot("Stack gallery", at=(E, 308 - 32), size=(96, 64), door=(0, 32))
dead_end_cave(s6, "Dead-end cave", weight=4)
boulder_scramble(s6, "Boulder scramble", weight=2)

s7 = z.slot("Outer cove", at=(E, 432 - 32), size=(96, 64), door=(0, 32))
drowned_pool(s7, "Drowned pool", weight=4)
dead_end_cave(s7, "Dead-end cave", weight=3)

z.write("src/shared/Layouts/Zones/Zone5.luau",
        "-- Zone 5, The Shoals: drawn with the layout kit from tools/kit/plans/zone5.py (edit the plan\n"
        "-- and re-run it, not this file). Its card: docs/design/cards/zone5.md.")
