"""Stranded Iceberg, a biome rolling in zones 5 and 6 (docs/design/cards/stranded-iceberg.md).

An iceberg run aground: a mountain of blue ice (walls of Glacier, snow underfoot) with the
frozen lake across its middle, ice tunnels and crevasses. Laid out like zone 6's plan: the frame,
then each crossing's paths (a character each), then the slots' rooms.

Run it with the quick check, once per zone:
    python3 tools/kit/quick.py 5 Biomes/StrandedIceberg --plan tools/kit/plans/stranded_iceberg.py
    python3 tools/kit/quick.py 6 Biomes/StrandedIceberg --plan tools/kit/plans/stranded_iceberg.py

Three kinds of way, 2 or 3 in each crossing:
  the lake    across the frozen lake, a wide flat hall of Glacier ice covered with big overlapping
              Ice patches: quick, but you slide; open crevasses (Pits) wait at its edges
  the tunnels narrow roofed lanes lit only by glow shells; covered crevasses (Pit, covered)
              under thin ice, the cracks the tell
  the round   the cart's ramp (14+ wide) the long way round the berg
Pip, a lost penguin (the trader), stands in the small flat court off the top band (the first
place a way in leads to): zone coordinates, the court's middle.

Zone 5 (the berg across the zone, the lake in the middle):
    z   0  ====================== the top band ===========================
       28  [S1 caves]   (Pip's court)   [S2 caves]
      148  ------------------ the top row ------------------
      196  [          the frozen lake  x -264..264           ]
      404
      452  ------------------ the bottom row -----------------
      500  [S3 caves]                    [S4 caves]
      592  ====================== the bottom band =========================
"""

import math

from kit import Zone, write_zones

OUT = "src/shared/Layouts/Biomes/StrandedIceberg.luau"
ICE = "Glacier"
SNOW = "Snow"
ROCK = 20  # walls you can't see over; roofs at 18 clear


# ---- helpers: the biome's vocabulary ------------------------------------------------------------
def along(points, every):
    """Points every `every` studs along a polyline (not the ends)."""
    out = []
    carry = every / 2
    for (ax, az), (bx, bz) in zip(points, points[1:]):
        length = math.hypot(bx - ax, bz - az)
        d = carry
        while d < length:
            t = d / length
            out.append((ax + (bx - ax) * t, az + (bz - az) * t))
            d += every
        carry = d - length
    return out


def box(cx, cz, w, d):
    return [(cx - w / 2, cz - d / 2), (cx + w / 2, cz - d / 2), (cx + w / 2, cz + d / 2),
            (cx - w / 2, cz + d / 2)]


def lake(part, x0, z0, x1, z1):
    """The frozen lake: a wide flat hall of glacier ice."""
    part.hall([(x0, z0), (x1, z0), (x1, z1), (x0, z1)], floor=ICE)


def ice_field(part, x0, z0, x1, z1, r=34):
    """Big overlapping Ice patches over a whole rectangle (a staggered grid)."""
    step = r * 1.2
    row = 0
    z = z0 + r * 0.5
    while z < z1 - r * 0.2:
        x = x0 + r * 0.5 + (step / 2 if row % 2 else 0)
        while x < x1 - r * 0.2:
            part.hazard("Ice", at=(round(x), round(z)), radius=r)
            x += step
        z += step * 0.85
        row += 1


def tunnel(part, points, roofed=(), glow=140, width=12):
    """An ice tunnel: a narrow lane, roofed along the given segments, glow shells for light."""
    part.lane(points, width=width, floor=SNOW)
    for i in roofed:
        part.roof_lane([points[i], points[i + 1]], 12)
    for x, zz in along(points, glow):
        part.decor("GlowShells", at=(round(x), round(zz)))


def crevasse(part, at, radius=4, covered=True):
    """A crack in the ice: covered (thin ice over a spike pit, the cracks the tell) or open."""
    part.hazard("Pit", at=at, radius=radius, covered=covered)


def cart_way(part, points, width=16):
    """The long way round: the cart's ramp, with a few rocks and pebbles at its side."""
    part.ramp(points, width=width)
    for i, (x, zz) in enumerate(along(points, 150)):
        part.decor("Rocks" if i % 2 == 0 else "Pebbles", at=(round(x + 12), round(zz)), scale=0.8)


def spur(part, points, width=12):
    part.lane(points, width=width, floor=SNOW)


def finish(zone):
    """Roofs are ice too."""
    parts = [zone.frame] + zone.crossings
    for s in zone.slots:
        parts += s.rooms
    for part in parts:
        for p in part.primitives:
            if p.get("Kind") == "Roof":
                p["Material"] = ICE
    return zone


# ---- the rooms: ice caves (each in its slot's own coordinates) -----------------------------------
def inward(slot):
    (w, d), (dx, dz) = slot.size, slot.door
    if dz == 0:
        return (dx, dz), (dx, d - 12), (0, 1)
    if dz == d:
        return (dx, dz), (dx, 12), (0, -1)
    if dx == 0:
        return (dx, dz), (w - 12, dz), (1, 0)
    return (dx, dz), (12, dz), (-1, 0)


def inset(slot, by=8):
    w, d = slot.size
    return [(by, by), (w - by, by), (w - by, d - by), (by, d - by)]


def comb_of_caves(slot, name, weight=3):
    """A gallery straight in, short dead-end caves off both sides, the best find in the deepest
    on a covered crevasse."""
    r = slot.room(name, lead=False)
    door, deep, (ix, iz) = inward(slot)
    r.lane([door, deep], width=12, floor=SNOW)
    w, d = slot.size
    length = abs(deep[0] - door[0]) + abs(deep[1] - door[1])
    for k, t in enumerate(range(20, int(length) - 4, 22)):
        x, zz = door[0] + ix * t, door[1] + iz * t
        side = 1 if k % 2 == 0 else -1
        reach = (w if iz else d) / 2 - 10
        end = (x + iz * side * reach, zz + ix * side * reach)
        r.lane([(x, zz), end], width=12, floor=SNOW)
        r.loot(end, radius=3, weight=1)
    r.loot(deep, radius=4, weight=weight)
    crevasse(r, deep)
    r.decor("Pebbles", area=inset(slot), count=4)
    return r


def frozen_pool(slot, name, weight=3):
    """A cave with a frozen pool, ice underfoot: the find in its middle."""
    r = slot.room(name)
    r.hall(inset(slot), floor=ICE)
    _, deep, _ = inward(slot)
    w, d = slot.size
    r.hollow(deep, radius=min(w, d) / 2 - 14, depth=3, material=ICE)
    r.hazard("Ice", at=(round(deep[0]), round(deep[1])), radius=16)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Bones", at=(round(w / 2), round(d / 2)), scale=0.8)
    # The secret's door: an ice cave mouth on the floor opposite the pool.
    r.entrance((52, d - 20 if deep[1] < d / 2 else 20))
    return r


def grotto(slot, name, weight=3):
    """A cave with a frozen pool to one side and the secret's ice cave mouth on the clear floor
    on the other."""
    r = slot.room(name)
    r.hall(inset(slot), floor=ICE)
    w, d = slot.size
    pool = (round(w * 0.72), round(d / 2))
    r.hollow(pool, radius=14, depth=2, material=ICE)
    r.hazard("Ice", at=pool, radius=14)
    r.loot(pool, radius=4, weight=weight)
    r.entrance((round(w * 0.28), round(d / 2)))
    r.decor("GlowShells", at=(round(w * 0.28), round(d / 2 + 22)))
    return r


def tunnel_ring(slot, name, weight=3):
    """A roofed tunnel round a block of ice, the find in a niche at its far side."""
    r = slot.room(name, lead=False)
    door, deep, (ix, iz) = inward(slot)
    w, d = slot.size
    x0, z0, x1, z1 = 14, 14, w - 14, d - 14
    ring = [(x0, z0), (x1, z0), (x1, z1), (x0, z1), (x0, z0)]
    r.lane(ring, width=12, floor=SNOW)
    r.roof_lane(ring, 12)
    r.lane([door, (door[0] + ix * 14, door[1] + iz * 14)], width=12, floor=SNOW)
    r.loot(deep, radius=3, weight=weight)
    r.decor("GlowShells", at=(round(deep[0]), round(deep[1])))
    return r


def pillar_cave(slot, name, weight=2):
    """A roofed cave on ice pillars; bones frozen in the floor."""
    r = slot.room(name)
    w, d = slot.size
    pillars = [(x, zz) for x in range(28, int(w) - 20, 28) for zz in range(28, int(d) - 20, 28)]
    r.hall(inset(slot), roof=True, pillars=pillars)
    _, deep, _ = inward(slot)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Bones", at=(round(w / 2), round(d / 2)), scale=1.0)
    r.decor("GlowShells", at=(round(w / 2), round(d / 2 + 12)))
    return r


def boulder_cave(slot, name, weight=2):
    """Fallen blocks of ice to clamber over; the find behind the biggest."""
    r = slot.room(name)
    r.hall(inset(slot))
    _, deep, _ = inward(slot)
    w, d = slot.size
    for k, (fx, fz) in enumerate([(0.3, 0.35), (0.7, 0.5), (0.4, 0.7), (0.65, 0.25)]):
        r.mound((round(w * fx), round(d * fz)), radius=7, height=5 + k % 2, rock=True)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Rocks", at=(round(w * 0.5), round(d * 0.55)), scale=0.8)
    return r


KINDS = {"comb": comb_of_caves, "pool": frozen_pool, "grotto": grotto, "ring": tunnel_ring,
         "pillar": pillar_cave, "boulder": boulder_cave}


def slots(z, spec):
    """spec: (name, at, size, door, (kind, weight), (kind, weight)): two rooms per slot."""
    for name, at, size, door, (ka, wa), (kb, wb) in spec:
        s = z.slot(name, at=at, size=size, door=door)
        KINDS[ka](s, f"{name}, {ka}", weight=wa)
        KINDS[kb](s, f"{name}, {kb}", weight=wb)


# ---- the frame shared by both zones --------------------------------------------------------------
def bands(f):
    f.hall([(-360, -12), (360, -12), (360, 20), (-360, 20)], floor=SNOW)
    f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)], floor=SNOW)


def pips_court(f, cx=0, top=52):
    """Pip's court: flat, open sky, just off the top band (the way in). The secret's door is in the
    caves."""
    area = [(cx - 24, top), (cx + 24, top), (cx + 24, top + 56), (cx - 24, top + 56)]
    f.court(area)
    f.paint(area, SNOW)
    f.lane([(cx, 20), (cx, top)], width=12)
    f.decor("Pebbles", area=box(cx, top + 28, 50, 40), count=4)
    f.decor("Bones", at=(cx - 18, top + 40), scale=0.7, yaw=40)
    f.decor("Rocks", at=(cx + 20, top + 12), scale=0.8)


# ==== zone 5 ====================================================================================
LAKE5 = (-272, 248, 272, 392)


def zone5():
    z = Zone(5, "The Shoals", rock=ROCK, material=ICE)
    f = z.frame
    bands(f)
    pips_court(f)
    f.decor("Chain", path=[(-300, 6), (-250, 6)], count=2)
    z5_slots(z)

    # ---- crossing 1: Lake road (3 paths) ----
    # R: the cart's way round the east side. T: tunnels down the west. L: the lake, in from the
    # top by the tunnels' first stretch, out at the bottom middle.
    c = z.crossing("Lake road", paths=3)
    lake_paths(c)
    cart_way(c, R_EAST)
    tunnel(c, T_WEST, roofed=(0, 1, 3, 5, 7))
    spur(c, L_IN)
    spur(c, L_OUT)
    c.decor("Bones", at=(-70, 12), scale=1.2, yaw=90)  # the tell: an arch of bones
    c.decor("Chain", path=[(-80, 8), (-44, 8)], count=2)
    c.decor("Rocks", at=(230, 12), scale=1.0)

    # ---- crossing 2: Frozen cut (2 paths): the lake in from the east, the cart's way west ----
    c = z.crossing("Frozen cut", paths=2)
    lake_paths(c)
    cart_way(c, mirror(R_EAST))
    spur(c, [(56, 0)] + mirror(L_IN))
    spur(c, [(-40, 392), (-40, 440), (60, 440), (60, 608)])
    tunnel(c, [(96, 156), (96, 204)])
    c.decor("Rocks", at=(70, 12), scale=1.3)  # the tell: a rock cairn
    c.decor("Pebbles", at=(84, 14))
    c.decor("Chain", path=[(-236, 8), (-200, 8)], count=2)

    # ---- crossing 3: The ice maze (2 paths): east tunnels, the cart's way west ----
    c = z.crossing("The ice maze", paths=2)
    cart_way(c, [(-216, 0), (-216, 60), (-96, 60), (-96, 108), (-216, 108), (-216, 156), (-96, 156),
                 (-96, 204), (-312, 204), (-312, 432), (-216, 432), (-216, 476), (-100, 476),
                 (-100, 520), (-216, 520), (-216, 608)])
    tunnel(c, mirror(T_WEST), roofed=(0, 1, 3, 5, 7))
    c.decor("GlowShells", at=(-60, 14))  # the tell: a glow at the middle way in
    c.decor("GlowShells", at=(-76, 14))
    crevasse(c, (312, 300), covered=True)
    return finish(z)


def lake_paths(c):
    """The lake itself, wherever a crossing crosses it: ice patches over the whole hall, open
    crevasses at its edges."""
    lake(c, *LAKE5)
    ice_field(c, *LAKE5)
    for at in [(-262, 320), (262, 320), (-150, 252), (150, 388)]:
        crevasse(c, at, covered=False)  # the open ones: you slide into them


def mirror(points):
    return [(-x, zz) for x, zz in points]


R_EAST = [(216, 0), (216, 60), (96, 60), (96, 108), (216, 108), (216, 156), (96, 156), (96, 204),
          (312, 204), (312, 432), (216, 432), (216, 476), (100, 476), (100, 520), (216, 520),
          (216, 608)]
T_WEST = [(-56, 0), (-56, 156), (-312, 156), (-312, 432), (-216, 432), (-216, 476), (-96, 476),
          (-96, 520), (-216, 520), (-216, 608)]
L_IN = [(-56, 156), (-56, 204), (-260, 204), (-260, 248)]
L_OUT = [(40, 392), (40, 608)]


def z5_slots(z):
    slots(z, [
        ("Ice caves west", (-352, 36), (104, 72), (52, 0), ("comb", 2), ("boulder", 1)),
        ("Ice caves east", (248, 36), (104, 72), (52, 0), ("pool", 2), ("pillar", 2)),
        ("Deep caves west", (-352, 504), (104, 72), (52, 72), ("grotto", 3), ("pool", 3)),
        ("Deep caves east", (248, 504), (104, 72), (52, 72), ("comb", 3), ("pillar", 3)),
    ])


# ==== zone 6 ====================================================================================
LAKE6 = (-272, 300, 272, 420)

# R: the cart's way (a ramp), round the berg by the west strip; T: tunnels down the east strip;
# L: across the lake, in at its north-west corner, out at the south-east.
R6_A = [(-216, 0), (-216, 60), (-96, 60), (-96, 108), (-216, 108), (-216, 156), (-96, 156),
        (-96, 204), (-312, 204), (-312, 472), (-96, 472), (-96, 520), (-216, 520), (-216, 560),
        (-96, 560), (-96, 608)]
R6_B = [(-96, 0), (-96, 60), (-216, 60), (-216, 108), (-96, 108), (-96, 156), (-312, 156),
        (-312, 472), (-96, 472), (-96, 520), (-216, 520), (-216, 560), (-96, 560), (-96, 608)]
T6 = [(56, 0), (56, 156), (312, 156), (312, 204), (96, 204), (96, 252), (312, 252), (312, 472),
      (216, 472), (216, 520), (100, 520), (100, 608)]
L6_IN = [(-56, 0), (-56, 252), (-260, 252), (-260, 300)]
L6_OUT = [(260, 420), (260, 472), (40, 472), (40, 608)]


def lake6(c):
    lake(c, *LAKE6)
    ice_field(c, *LAKE6)
    for at in [(-262, 360), (262, 360), (-150, 304), (150, 416), (0, 304)]:
        crevasse(c, at, covered=False)


def zone6():
    z = Zone(6, "The Drowned Reach", rock=ROCK, material=ICE)
    f = z.frame
    bands(f)
    pips_court(f)
    f.decor("Chain", path=[(250, 6), (300, 6)], count=2)
    z6_slots(z)

    # ---- crossing 1: The great crevasse (3 paths) ----
    c = z.crossing("The great crevasse", paths=3)
    lake6(c)
    cart_way(c, R6_A)
    tunnel(c, T6, roofed=(0, 1, 3, 5, 7, 9))
    crevasse(c, (200, 156))
    crevasse(c, (312, 360))
    crevasse(c, (160, 520))
    spur(c, L6_IN)
    spur(c, L6_OUT)
    c.decor("Bones", at=(-70, 12), scale=1.4, yaw=90)  # the tell: a skeleton in the ice
    c.decor("GlowShells", at=(62, 12))
    c.decor("Rocks", at=(-230, 12), scale=1.0)

    # ---- crossing 2: Whiteout road (2 paths): the lake from the east, the cart's way east ----
    c = z.crossing("Whiteout road", paths=2)
    lake6(c)
    cart_way(c, mirror(R6_A))
    spur(c, mirror(L6_IN))
    spur(c, mirror(L6_OUT))
    c.decor("Rocks", at=(70, 12), scale=1.3)  # the tell: a cairn
    c.decor("Pebbles", at=(84, 14))
    c.decor("Chain", path=[(-80, 8), (-44, 8)], count=2)

    # ---- crossing 3: The ice maze (3 paths): west tunnels, the cart's way east, the lake ----
    c = z.crossing("Heart of the berg", paths=3)
    lake6(c)
    cart_way(c, mirror(R6_B))
    tunnel(c, mirror(T6), roofed=(0, 1, 3, 5, 7, 9))
    crevasse(c, (-200, 156))
    crevasse(c, (-312, 400))
    crevasse(c, (-160, 520))
    spur(c, mirror(L6_IN))
    spur(c, mirror(L6_OUT))
    c.decor("GlowShells", at=(-60, 14))  # the tell: glow at the middle way in
    c.decor("GlowShells", at=(-76, 14))
    return finish(z)


def z6_slots(z):
    slots(z, [
        ("Blue caves west", (-352, 36), (104, 72), (52, 0), ("pool", 2), ("pillar", 2)),
        ("Blue caves east", (248, 36), (104, 72), (52, 0), ("comb", 2), ("boulder", 2)),
        ("Deep grottos west", (-352, 504), (104, 72), (52, 72), ("pillar", 4), ("comb", 4)),
        ("Deep grottos east", (248, 504), (104, 72), (52, 72), ("grotto", 4), ("pool", 4)),
    ])


COMMENT = ("-- Stranded Iceberg: drawn with the layout kit from tools/kit/plans/stranded_iceberg.py\n"
           "-- (edit the plan and re-run it, not this file). Card: docs/design/cards/stranded-iceberg.md.")

zones = [zone5(), zone6()]
write_zones(OUT, zones, COMMENT)
