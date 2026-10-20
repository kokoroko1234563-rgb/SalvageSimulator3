"""Hermit Hollows, a biome rolling in zones 4 to 6 (docs/design/cards/hermit-hollows.md).

A giant hermit crab's warren: tunnels in shell-crusted rock, mostly roofed, opening into
chambers. Laid out like zone 6's plan (tools/kit/plans/zone6.py):
  1. the frame: the bands, the chambers (hubs) and the slots' doors onto them;
  2. each crossing: its paths, links, crab patrols, the giant (zones 5 and 6), its tell;
  3. each slot's rooms: crab nests (dead ends, big shells), shell middens, collapsed chambers.

Run it with the quick check, once per zone:
    python3 tools/kit/quick.py 4 Biomes/HermitHollows --plan tools/kit/plans/hermit_hollows.py

The map (zone coordinates, x -360 west to 360 east, z 0 top to 608 the sea), all three zones:

    z   0  ===================== the top band (every path starts here) =======================
       28  [S1 nests]                                                          [S2 nests]
      168  [S3 midden][Midden Court]
      248                                  [ the Moult Hall ]
      328                                                      [Shell Court / the Lair]
      352                                      [S4]                                [S6]
      504                   [S7]                      [S5]
      584  ===================== the bottom band ============================================

Every crossing reaches every chamber, so every slot's door can be walked to. In zones 5 and 6
the east chamber is the Lair, where the giant's route begins; each crossing has the giant in its
own long straight tunnel (a different one each tide), which the cart's way keeps clear of.
"""

import math

from kit import Zone, write_zones

OUT = "src/shared/Layouts/Biomes/HermitHollows.luau"
ROCK = 20  # walls you can't see over; roofs at 18 clear
GRIT = "Concrete"


# ---- helpers: the biome's vocabulary ------------------------------------------------------------
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


def box(cx, cz, w, d):
    return [(cx - w / 2, cz - d / 2), (cx + w / 2, cz - d / 2), (cx + w / 2, cz + d / 2),
            (cx - w / 2, cz + d / 2)]


def glow(part, points, every=110):
    """Glowing shells down a safe way: the only light in the tunnels."""
    for x, zz in along(points, every):
        part.decor("GlowShells", at=(round(x), round(zz)))


def tunnel(part, points, width=12, roofs=None, shells=True, every=110):
    """A foot tunnel: a lane, roofed along segments `roofs` (indices; None: all), glowing shells
    marking it."""
    part.lane(points, width=width)
    idx = range(len(points) - 1) if roofs is None else roofs
    for i in idx:
        part.roof_lane([points[i], points[i + 1]], 12)
    if shells:
        glow(part, points, every)
    return part


def cart_way(part, points, roofs=None, shells=True, every=110):
    """The cart's way: a 16 wide ramp, roofed along segments `roofs` (None: all)."""
    part.ramp(points, width=16)
    idx = range(len(points) - 1) if roofs is None else roofs
    for i in idx:
        part.roof_lane([points[i], points[i + 1]], 16)
    if shells:
        glow(part, points, every)
    return part


def crabs(part, points, count=3):
    """A patrol: crabs walking a stretch of tunnel back and forth, across the ways."""
    part.hazard("Patrol", path=points, count=count)


def giant(part, route, burrows, roofs=True):
    """The giant's tunnel: one straight lane it fills (12 wide), roofed, with its burrow holes
    (churned mounds) on the route. No glowing shells: this is the way not to take."""
    part.lane(route, width=12)
    if roofs:
        for a, b in zip(route, route[1:]):
            part.roof_lane([a, b], 12)
    part.hazard("Hunter", path=route, burrows=burrows)
    for bx, bz in burrows:
        part.decor("Rocks", at=(bx, bz), scale=0.8)
        part.decor("Pebbles", at=(bx + 4, bz + 3))


def scramble(part, a, b, clear=10):
    """A foot-only shortcut between two lanes: a gap choked with rubble, too steep for a cart."""
    part.lane([a, b], width=12)
    (ax, az), (bx, bz) = a, b
    length = math.hypot(bx - ax, bz - az)
    ux, uz = (bx - ax) / length, (bz - az) / length
    k = clear + 6
    part.ridge([(ax + ux * k, az + uz * k), (bx - ux * k, bz - uz * k)], height=2.5, width=12,
               rough=0)


def rubble(part, at, axis="z"):
    """A rockfall across a foot tunnel: a heap of rubble that feet clamber over and a cart can't
    (so the tunnel is foot only)."""
    x, zz = at
    seg = [(x, zz - 8), (x, zz + 8)] if axis == "z" else [(x - 8, zz), (x + 8, zz)]
    part.ridge(seg, height=2.5, width=12, rough=0)
    part.decor("Rocks", at=(round(x), round(zz)), scale=0.7)


def dead_end(part, points, weight=2, shells=True):
    """A lane to a dead end: a crab's hoard of shells at its end."""
    part.lane(points, width=12)
    part.loot(points[-1], radius=5, weight=weight)
    part.decor("Shells", at=(round(points[-1][0]), round(points[-1][1])), scale=1.4)
    if shells:
        part.decor("GlowShells", at=(round(points[-2][0]), round(points[-2][1])))


def tell_bones(part, at, scale=1.3, yaw=0):
    part.decor("Bones", at=at, scale=scale, yaw=yaw)


# ---- the rooms: kinds a slot can hold (each in the slot's own coordinates) ----------------------
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


def inset(slot, by=8):
    w, d = slot.size
    return [(by, by), (w - by, by), (w - by, d - by), (by, d - by)]


def crab_nest(slot, name, weight=4, branches=0):
    """A dead-end nest: a roofed tunnel straight in and a chamber at its end heaped with big
    shells (the best find there), a smaller heap beside it."""
    r = slot.room(name, lead=False)
    door, deep, (ix, iz) = inward(slot)
    w, d = slot.size
    chamber = (22, 12) if iz else (12, 22)  # half the chamber's width and depth
    mid = (deep[0] - ix * 8, deep[1] - iz * 8)
    r.lane([door, mid], width=12)
    r.roof_lane([door, (door[0] + ix * 24, door[1] + iz * 24)], 12)
    r.hall(box(mid[0], mid[1], chamber[0] * 2, chamber[1] * 2))
    r.loot(deep, radius=5, weight=weight)
    r.decor("Shells", at=(round(deep[0]), round(deep[1])), scale=2.0)
    r.decor("Bones", at=(round(mid[0] + iz * 10), round(mid[1] + ix * 10)), scale=0.8)
    r.decor("Shells", at=(round(mid[0] - iz * 10), round(mid[1] - ix * 10)), scale=1.2)
    r.decor("Barnacles", area=box(mid[0], mid[1], 36, 20), count=4)
    return r


def shell_midden(slot, name, weight=3, pits=1):
    """A heap of old shells in an open chamber: shell mounds to wind between, covered pits in the
    heaps (the cracks are the tell), the find deepest."""
    r = slot.room(name)
    r.hall(inset(slot))
    door, deep, (ix, iz) = inward(slot)
    w, d = slot.size
    r.decor("Shells", area=inset(slot, 12), count=14, scale=1.3)
    r.decor("Bones", at=(round(w / 2), round(d / 2)), scale=0.9)
    r.mound((round(w * 0.3), round(d * 0.5)), radius=6, height=3, rock=False)
    r.mound((round(w * 0.7), round(d * 0.5)), radius=6, height=3, rock=False)
    r.loot(deep, radius=4, weight=weight)
    r.hazard("Pit", at=deep, radius=4, covered=True)
    if pits > 1:
        r.hazard("Pit", at=(round(w / 2), round(d / 2)), radius=4, covered=True)
    return r


def collapsed_chamber(slot, name, weight=2):
    """A chamber whose roof came down: boulders to clamber round, the find behind the biggest."""
    r = slot.room(name)
    r.hall(inset(slot))
    door, deep, (ix, iz) = inward(slot)
    w, d = slot.size
    for k, (fx, fz) in enumerate([(0.3, 0.35), (0.7, 0.5), (0.4, 0.7), (0.65, 0.25)]):
        r.mound((round(w * fx), round(d * fz)), radius=7, height=5 + k % 2, rock=True)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Rocks", area=inset(slot, 12), count=5)
    r.decor("Barnacles", area=inset(slot), count=4)
    return r


# ---- the frame: the same chambers in every zone (zones 5 and 6 turn the east one into the Lair)
def frame(z, lair, entrance):
    f = z.frame
    f.hall([(-360, -12), (360, -12), (360, 20), (-360, 20)])
    f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])
    f.decor("Shells", area=[(-300, 0), (300, 0), (300, 16), (-300, 16)], count=8, scale=1.2)

    # The Midden Court: open sky, a heap of shells.
    f.court([(-272, 176), (-176, 176), (-176, 264), (-272, 264)])
    f.decor("Shells", area=[(-264, 184), (-184, 184), (-184, 256), (-264, 256)], count=12, scale=1.5)
    f.decor("Bones", at=(-224, 220), scale=1.1, yaw=40)
    f.decor("GlowShells", at=(-200, 200))

    # The Moult Hall: the pillared chamber in the middle, roofed.
    f.hall([(-72, 248), (72, 248), (72, 344), (-72, 344)], roof=True,
           pillars=[(-36, 280), (0, 280), (36, 280), (-36, 312), (0, 312), (36, 312)])
    f.decor("Bones", at=(0, 296), scale=1.3, yaw=90)
    f.decor("GlowShells", at=(-54, 296))
    f.decor("GlowShells", at=(54, 296))
    f.loot((0, 296), weight=3)

    if lair:
        # The Lair: a big open chamber, a nest of shells and bones; the giant's route begins here.
        f.court([(152, 320), (296, 320), (296, 440), (152, 440)])
        f.decor("Shells", area=[(160, 328), (288, 328), (288, 432), (160, 432)], count=16, scale=2.0)
        f.decor("Bones", at=(224, 380), scale=2.0, yaw=20)
        f.decor("Bones", at=(184, 410), scale=1.2, yaw=140)
        f.decor("Barnacles", area=[(160, 328), (288, 328), (288, 432), (160, 432)], count=6)
        f.loot((256, 410), weight=4)
    else:
        # The Shell Court: open sky round a heap of moulted shells.
        f.court([(176, 328), (280, 328), (280, 424), (176, 424)])
        f.decor("Shells", area=[(184, 336), (272, 336), (272, 416), (184, 416)], count=12, scale=1.6)
        f.decor("Bones", at=(228, 376), scale=1.2, yaw=30)
        f.decor("GlowShells", at=(200, 352))
        f.loot((228, 376), weight=2)

    # Crabs always in the chambers: they see you before you see them.
    f.hazard("Patrol", path=[(-252, 214), (-196, 214)], count=2)
    f.hazard("Patrol", path=[(-56, 296), (56, 296)], count=2)
    if lair:
        f.hazard("Patrol", path=[(170, 396), (280, 396)], count=2)
    else:
        f.hazard("Patrol", path=[(190, 376), (270, 376)], count=2)

    f.entrance(entrance)
    f.decor("GlowShells", at=(entrance[0] + 10, entrance[1] + 6))


def slots(z, lair, pool=False):
    s1 = z.slot("Nest row west", at=(-352, 36), size=(104, 72), door=(52, 0))
    crab_nest(s1, "Crab nest", weight=3, branches=2)
    shell_midden(s1, "Shell midden", weight=2)

    # (zone 4's rock pool at (260, 70) is kept clear)
    s2 = (z.slot("Nest row east", at=(284, 36), size=(72, 72), door=(36, 0)) if pool else
          z.slot("Nest row east", at=(248, 36), size=(104, 72), door=(52, 0)))
    crab_nest(s2, "Crab nest", weight=3, branches=2)
    collapsed_chamber(s2, "Collapsed chamber", weight=2)

    s3 = z.slot("Western midden", at=(-360, 168), size=(72, 104), door=(72, 52))
    shell_midden(s3, "Old midden", weight=2, pits=2)
    crab_nest(s3, "Hermit nest", weight=3)

    s4 = z.slot("Deep nest", at=(-48, 360), size=(96, 72), door=(48, 0))
    crab_nest(s4, "Brood nest", weight=5, branches=1)
    shell_midden(s4, "Moult midden", weight=3)

    s5 = z.slot("Hoard", at=(120, 504), size=(112, 72), door=(56, 72))
    crab_nest(s5, "Hoard nest", weight=5, branches=2)
    collapsed_chamber(s5, "Fallen hoard", weight=3)

    s7 = z.slot("Sea nests", at=(-232, 504), size=(112, 72), door=(56, 72))
    crab_nest(s7, "Sea nest", weight=6, branches=2)
    shell_midden(s7, "Drowned midden", weight=4, pits=2)

    if not lair:
        s6 = z.slot("East collapse", at=(296, 328), size=(64, 96), door=(0, 48))
        collapsed_chamber(s6, "Collapsed chamber", weight=3)
        crab_nest(s6, "East nest", weight=4)


# The blocks the paths are made of (centre lines; 12 wide lanes, or 16 wide ramps where the
# rows are 40 or more apart): top to the chambers, chambers to the bottom.
TW_S = [(-136, 0), (-136, 48), (-224, 48), (-224, 176)]  # top west, down to the Midden Court
TW_L = [(-136, 0), (-136, 48), (-224, 48), (-224, 100), (-152, 100), (-152, 148), (-224, 148),
        (-224, 176)]
WR_S = [(-224, 264), (-224, 300), (-136, 300), (-136, 340), (-288, 340), (-288, 380),
        (-136, 380), (-136, 480), (-280, 480), (-280, 608)]  # Midden Court to the bottom
WR_L = [(-224, 264), (-224, 300), (-136, 300), (-136, 340), (-288, 340), (-288, 380),
        (-136, 380), (-136, 420), (-288, 420), (-288, 460), (-136, 460), (-136, 500),
        (-280, 500), (-280, 608)]
CR_S = [(40, 0), (40, 48), (-88, 48), (-88, 104), (40, 104), (40, 248)]  # top centre to the Hall
HALL_BOTTOM = [(0, 344), (0, 352)]
BC = [(-72, 336), (-100, 336), (-100, 452), (80, 452), (80, 520), (-60, 520), (-60, 608)]
ES_S = [(224, 0), (224, 132), (336, 132), (336, 188), (232, 188), (232, 328)]  # to the east chamber
EAST_SNAKE = [(224, 0), (224, 132), (336, 132), (336, 188), (150, 188), (150, 240), (336, 240),
              (336, 288), (190, 288), (190, 340)]  # into the Lair's top
BE = [(232, 424), (232, 452), (336, 452), (336, 500), (256, 500), (256, 548), (336, 548), (336, 608)]


def length(points):
    return sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(points, points[1:]))


def patrols(part, points, every=260, half=30, count=2, start=120):
    """Crab routes along a path, a stretch of `half` either side every `every` studs: the crabs
    walk back and forth across it, so a way is crossed in the gaps between them."""
    d = start
    total = length(points)
    while d < total - 40:
        walked = 0
        for a, b in zip(points, points[1:]):
            seg = math.hypot(b[0] - a[0], b[1] - a[1])
            if walked + seg >= d:
                t = (d - walked) / seg
                ux, uz = (b[0] - a[0]) / seg, (b[1] - a[1]) / seg
                cx, cz = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                h = min(half, d - walked - 8 if d - walked > 8 else 0, seg - (d - walked) - 8)
                h = max(h, 0)
                if h >= 14:
                    part.hazard("Patrol", path=[(round(cx - ux * h), round(cz - uz * h)),
                                                (round(cx + ux * h), round(cz + uz * h))], count=count)
                break
            walked += seg
        d += every


# =================================================================================================
# Zone 4: Outer Shore. No giant yet: the crabs, and the warren's maze.
# =================================================================================================
z4 = Zone(4, "Outer Shore", rock=ROCK)
frame(z4, lair=False, entrance=(-224, 232))
slots(z4, lair=False, pool=True)

# ---- crossing 1: Crab walk (2 paths) ------------------------------------------------------------
# A: the cart's way: west, then down the long spine at x -140.
# B: the east snake, the Shell Court, the bottom east rows: foot only.
c = z4.crossing("Crab walk", paths=2)
A = [(-200, 0), (-200, 60), (120, 60), (120, 128), (-140, 128), (-140, 456), (-60, 456),
     (-60, 608)]
cart_way(c, A)
tunnel(c, ES_S)
tunnel(c, BE)
tunnel(c, [(-140, 220), (-176, 220)], roofs=(), shells=False)  # to the Midden Court
tunnel(c, [(-140, 300), (-72, 300)], roofs=(), shells=False)  # to the Hall's west door
tunnel(c, [(72, 336), (176, 336)], roofs=(), shells=False)  # the link: Hall to the east chamber
patrols(c, A, every=250, count=2)
patrols(c, ES_S + BE[1:], every=250, count=2)
c.hazard("Patrol", path=[(-100, 300), (-72, 300)], count=1)
dead_end(c, [(-140, 380), (-240, 380), (-240, 420)], weight=2)
c.decor("Shells", at=(-188, 10), scale=1.8)  # the tell: a heap of shells and a glow at the way in
c.decor("GlowShells", at=(-210, 12))


# ---- crossing 2: Midden descent (2 paths) ---------------------------------------------------------
# A: the cart's way down the east, in rows, past the east chamber and round the bottom.
# B: foot only, the west: the top west wiggle, the Midden Court, the west rows.
# Links: the Hall's two doors.
c = z4.crossing("Midden descent", paths=2)
A = [(120, 0), (120, 76), (220, 76), (220, 150), (120, 150), (120, 230), (220, 230), (220, 466),
     (60, 466), (60, 608)]
cart_way(c, A)
tunnel(c, TW_S)
tunnel(c, WR_S)
tunnel(c, [(-72, 300), (-136, 300)], roofs=(), shells=False)  # the Hall's west door
tunnel(c, [(72, 296), (220, 296)], roofs=(), shells=False)  # the Hall's east door
tunnel(c, [(220, 376), (176, 376)], roofs=(), shells=False)  # into the east chamber
patrols(c, A, every=240, count=2)
patrols(c, TW_S + [(-224, 264)] + WR_S[1:], every=240, count=2)
c.hazard("Patrol", path=[(100, 296), (190, 296)], count=2)
dead_end(c, [(120, 190), (24, 190)], weight=2)
c.decor("Bones", at=(128, 12), scale=1.2, yaw=90)  # the tell: bones at the way in
c.decor("GlowShells", at=(110, 12))
scramble(c, (-136, 340), (-136, 380))  # shortcuts for feet: rubble a cart can't climb

# ---- crossing 3: Three ways (3 paths) -------------------------------------------------------------
# A: the cart's way, down the east (a ramp).
# B: foot: the west, through the Midden Court.
# C: foot: the middle rows, the Hall and the bottom centre.
c = z4.crossing("Three ways", paths=3)
cart_way(c, ES_S + BE)
tunnel(c, TW_S)
tunnel(c, WR_S)
tunnel(c, CR_S)
tunnel(c, BC)
tunnel(c, [(-72, 300), (-136, 300)], roofs=(), shells=False)
tunnel(c, [(72, 336), (176, 336)], roofs=(), shells=False)
patrols(c, ES_S + BE, every=170, count=1, start=100)
patrols(c, TW_S + [(-224, 264)] + WR_S[1:], every=170, count=1, start=100)
patrols(c, CR_S + [(40, 336), (-72, 336)] + BC, every=170, count=1, start=100)
c.decor("Shells", at=(30, 12), scale=2.2)  # the tell: a great heap of shells, bones on it
c.decor("Bones", at=(44, 10), scale=0.9, yaw=60)


# ---- crossing 4: The long hollow (1 path) -------------------------------------------------------
# One long way, the cart's too: the top west wiggle, the Midden Court, the west rows. Side lanes
# are dead ends with hoards; the Hall's doors only lead to the chambers.
c = z4.crossing("The long hollow", paths=1)
A = TW_L + [(-224, 264)] + WR_S[1:]
cart_way(c, A)
tunnel(c, [(-136, 300), (-72, 300)], roofs=(), shells=False)  # to the Hall's west door
tunnel(c, [(72, 336), (176, 336)], roofs=(), shells=False)  # the Hall to the east chamber
patrols(c, A, every=130, count=2, start=90)
c.hazard("Patrol", path=[(-110, 300), (-72, 300)], count=1)
dead_end(c, [(-136, 460), (-60, 460), (-60, 420)], weight=3)
dead_end(c, [(-152, 124), (-60, 124), (-60, 160)], weight=2)
scramble(c, (-136, 340), (-136, 380))
c.decor("Bones", at=(-150, 12), scale=1.6, yaw=0)  # the tell: an arch of bones at the way in
c.decor("Bones", at=(-122, 12), scale=1.6, yaw=180)

# ---- crossing 5: Moult run (2 paths) --------------------------------------------------------------
# A: the cart's way: the centre rows, then down the east side of the Hall.
# B: foot: the east snake into the Shell Court, down the bottom east.
# Link: the Hall's east door to both.
c = z4.crossing("Moult run", paths=2)
A = [(40, 0), (40, 48), (-88, 48), (-88, 104), (104, 104), (104, 470), (60, 470), (60, 608)]
cart_way(c, A)
B = [(224, 0), (224, 132), (336, 132), (336, 188), (104 + 40, 188), (144, 244), (336, 244), (336, 300),
     (140, 300), (140, 376), (176, 376)]
tunnel(c, B)
tunnel(c, [(232, 376), (232, 470), (300, 470), (300, 608)])
tunnel(c, [(176, 376), (232, 376)], roofs=(), shells=False)
patrols(c, A, every=240, count=2)
patrols(c, B, every=240, count=2)
tunnel(c, [(72, 296), (104, 296)], roofs=(), shells=False)  # the Hall's east door onto A
dead_end(c, [(60, 540), (-20, 540), (-20, 500)], weight=2)
tunnel(c, [(-72, 256), (-176, 256)], roofs=(), shells=False)  # the Hall's west door to the Midden Court
c.decor("Shells", at=(52, 12), scale=1.8)  # the tell: shells in a ring and a glow at the way in
c.decor("GlowShells", at=(28, 12))
c.decor("GlowShells", at=(52, 24))

# =================================================================================================
# Zone 5: The Shoals. The Lair, and the giant: one tunnel each crossing, from the Lair out.
# =================================================================================================
LAIR = (224, 380)  # where every giant's route begins
z5 = Zone(5, "The Shoals", rock=ROCK)
frame(z5, lair=True, entrance=(54, 328))
slots(z5, lair=True)


def lair_links(c, court=True, west=True):
    """The Hall's doors: to the Lair, to the Midden Court, and west onto the way there."""
    tunnel(c, [(72, 336), (152, 336)], roofs=(), shells=False)
    if court:
        tunnel(c, [(-72, 256), (-176, 256)], roofs=(), shells=False)
    if west:
        tunnel(c, [(-72, 300), (-136, 300)], roofs=(), shells=False)


def giant_tunnel(c, route, burrows):
    giant(c, route, burrows)
    c.decor("Bones", at=(route[0][0] - 14, route[0][1] - 20), scale=1.2, yaw=70)  # at its mouth


# ---- crossing 1: Lair watch (2 paths) -----------------------------------------------------------
# A: the cart's way, the long spine west of the centre, away from the Lair.
# B: foot: east across the giant's tunnel (north from the Lair, x 224) and down the east side.
c = z5.crossing("Lair watch", paths=2)
A = [(-200, 0), (-200, 60), (100, 60), (100, 128), (-140, 128), (-140, 300), (-288, 300),
     (-288, 340), (-140, 340), (-140, 456), (-60, 456), (-60, 608)]
B = [(170, 0), (170, 50), (222, 50), (222, 100), (170, 100), (170, 200), (336, 200), (336, 244), (262, 244), (262, 288), (336, 288), (336, 452),
     (336, 500), (256, 500), (256, 548), (336, 548), (336, 608)]
cart_way(c, A)
tunnel(c, B)
giant_tunnel(c, [(224, 380), (224, 140)], [(224, 340), (224, 250), (224, 170)])
rubble(c, (336, 400))
rubble(c, (336, 570), "z")
lair_links(c)
tunnel(c, [(-140, 220), (-176, 220)], roofs=(), shells=False)
patrols(c, A, every=230, count=2)
patrols(c, B, every=230, count=2)
dead_end(c, [(-140, 420), (-240, 420), (-240, 460)], weight=3)
c.decor("Bones", at=(-188, 12), scale=1.8, yaw=20)  # the tell: a great claw of bones at the way in
c.decor("Shells", at=(-210, 14), scale=2.0)

# ---- crossing 2: Bone road (3 paths) --------------------------------------------------------------
# A: the cart's way, the centre rows and the long column east of the Hall.
# B: foot: the west, through the Midden Court and the rows.
# C: foot: the east snake, through the Lair itself, out its south mouth past the giant's tunnel.
c = z5.crossing("Bone road", paths=3)
A = [(40, 0), (40, 48), (-88, 48), (-88, 104), (104, 104), (104, 160), (-88, 160), (-88, 216),
     (104, 216), (104, 470), (60, 470), (60, 608)]
cart_way(c, A)
tunnel(c, TW_L)
tunnel(c, WR_S)
tunnel(c, EAST_SNAKE)
tunnel(c, [(232, 424), (232, 452), (336, 452), (336, 500), (256, 500), (256, 548), (336, 548), (336, 608)])
giant_tunnel(c, [(268, 400), (268, 592)], [(268, 450), (268, 520), (268, 570)])
rubble(c, (-136, 430))
rubble(c, (336, 160), "z")
lair_links(c, court=False, west=False)
tunnel(c, [(-72, 300), (-136, 300)], roofs=(), shells=False)
patrols(c, A, every=300, count=2, start=130)
patrols(c, TW_L + [(-224, 264)] + WR_S[1:], every=300, count=2, start=130)
patrols(c, EAST_SNAKE + [(232, 424), (232, 452), (336, 452), (336, 500), (256, 500), (256, 548), (336, 548), (336, 608)], every=300, count=2, start=130)
c.decor("Shells", at=(30, 12), scale=2.4)  # the tell: a great heap of shells, and bones, at the way in
c.decor("Bones", at=(44, 10), scale=1.0, yaw=60)

# ---- crossing 3: Nest road (2 paths) --------------------------------------------------------------
# A: the cart's way, the long way west: the top west wiggle, the Midden Court, the west rows.
# B: foot: the centre rows, then east across the giant's tunnel (north from the Lair, x 188).
c = z5.crossing("Nest road", paths=2)
A = TW_L + [(-224, 264)] + WR_S[1:]
B = [(40, 0), (40, 48), (-88, 48), (-88, 104), (100, 104), (100, 190), (336, 190), (336, 452),
     (336, 500), (256, 500), (256, 548), (336, 548), (336, 608)]
cart_way(c, A)
tunnel(c, B)
giant_tunnel(c, [(188, 380), (188, 120)], [(188, 340), (188, 262), (188, 190), (188, 140)])
rubble(c, (336, 350))
rubble(c, (-88, 80), "z")
lair_links(c)
patrols(c, A, every=210, count=2, start=100)
patrols(c, B, every=210, count=2, start=100)
dead_end(c, [(-136, 430), (-80, 430)], weight=3)
c.decor("Bones", at=(-150, 12), scale=1.6, yaw=0)  # the tell: an arch of bones at the way in
c.decor("Bones", at=(-122, 12), scale=1.6, yaw=180)
c.decor("Shells", at=(-136, 24), scale=1.6)

# ---- crossing 4: Hunter's gate (3 paths) ----------------------------------------------------------
# A: the cart's way: a west spine and the bottom.
# B: foot: the east snake, which crosses the giant's tunnel (north from the Lair, x 268) three
#    times, then through the Lair and out the bottom east.
# C: foot: the centre rows, the Hall and the bottom centre.
c = z5.crossing("Hunter's gate", paths=3)
A = [(-200, 0), (-200, 128), (-140, 128), (-140, 300), (-288, 300), (-288, 340), (-140, 340),
     (-140, 480), (-280, 480), (-280, 608)]
cart_way(c, A)
EAST_LONG = [(224, 0), (224, 50), (150, 50), (150, 100), (224, 100), (224, 132)] + EAST_SNAKE[2:]
tunnel(c, EAST_LONG)
tunnel(c, [(232, 424), (232, 452), (336, 452), (336, 500), (256, 500), (256, 548), (336, 548), (336, 608)])
tunnel(c, CR_S)
tunnel(c, BC)
giant_tunnel(c, [(268, 380), (268, 188)], [(268, 340), (268, 264), (268, 214), (268, 196)])
rubble(c, (336, 520), "z")
rubble(c, (-100, 400))
lair_links(c, court=False, west=False)
tunnel(c, [(-140, 220), (-176, 220)], roofs=(), shells=False)  # to the Midden Court
tunnel(c, [(-72, 300), (-136, 300)], roofs=(), shells=False)
patrols(c, A, every=300, count=2, start=100)
patrols(c, EAST_LONG, every=250, count=2, start=100)
patrols(c, CR_S + [(40, 336), (-72, 336)] + BC, every=300, count=1, start=100)
c.decor("Shells", at=(-148, 12), scale=2.4)  # the tell: a great heap of shells, bones on it
c.decor("Bones", at=(-122, 10), scale=1.0, yaw=60)

# ---- crossing 5: Midden maze (2 paths) ------------------------------------------------------------
# A: the cart's way: the centre rows and the long column east of the Hall.
# B: foot: the top west wiggle, the Midden Court, and the long west rows.
c = z5.crossing("Midden maze", paths=2)
A = [(40, 0), (40, 48), (-88, 48), (-88, 104), (104, 104), (104, 160), (-88, 160), (-88, 216),
     (104, 216), (104, 470), (60, 470), (60, 608)]
B = TW_L + [(-224, 264)] + [(-224, 300), (-136, 300), (-136, 340), (-288, 340), (-288, 380),
                           (-136, 380), (-136, 420), (-288, 420), (-288, 460), (-136, 460),
                           (-136, 500), (-280, 500), (-280, 608)]
cart_way(c, A)
tunnel(c, B)
giant_tunnel(c, [(164, 380), (164, 126)], [(164, 340), (164, 270), (164, 210), (164, 150)])
rubble(c, (-136, 480), "z")
rubble(c, (-224, 100), "z")
lair_links(c, court=False, west=False)
tunnel(c, [(-72, 300), (-136, 300)], roofs=(), shells=False)
patrols(c, A, every=210, count=1, start=100)
patrols(c, B, every=170, count=1, start=100)
dead_end(c, [(60, 540), (-20, 540), (-20, 500)], weight=3)
c.decor("Shells", at=(52, 12), scale=1.8)  # the tell: a ring of shells, glowing
c.decor("GlowShells", at=(28, 12))
c.decor("GlowShells", at=(52, 24))

z4_comment = ("-- Hermit Hollows (zones 4 to 6): a giant hermit crab's warren, drawn with the layout kit from\n"
              "-- tools/kit/plans/hermit_hollows.py (edit the plan and re-run it, not this file).\n"
              "-- See docs/layouts/HermitHollows.md and docs/design/cards/hermit-hollows.md.")

def report(z):
    fr = sum(h.get("Count", 0) for h in z.frame.hazards if h["Type"] == "Patrol")
    for c in z.crossings:
        n = fr + sum(h.get("Count", 0) for h in c.hazards if h["Type"] == "Patrol")
        g = sum(1 for h in c.hazards if h["Type"] == "Hunter")
        print(f"zone {z.number} {c.name}: {n} crabs, {g} giants")


if __name__ == "__main__":
    report(z4)
    write_zones(OUT, [z4, z5], z4_comment)
    report(z5)
