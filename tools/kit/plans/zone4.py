"""Zone 4, The Outer Shore: where the rock starts (docs/design/cards/zone4.md).

Drawn the way zone 6's plan is (tools/kit/plans/zone6.py, the role model):
  1. the frame: the landmarks and hubs that are always there (the Arch, the Bend, the Stacks,
     the pool court) and the slots' doors onto them;
  2. each crossing: its paths (the cart's, the foot ways), their dangers, the tell at the way in;
  3. each slot's rooms: one door, different kinds, the best finds deepest.

Run it with the quick check:  python3 tools/kit/quick.py 4 --plan tools/kit/plans/zone4.py

The map (zone coordinates: x -360 west to 360 east, z 0 at the top to 608 at the sea):

    z   0  ==================== the top band (every path starts here) ====================
       36  [S1 barnacle caves]                                   [pool court][S2 the drift]
      148  ---- the top rows: the snakes the ways wind through before the first rib ----
      190  [the Bend]               [ the Arch: north court ]
      254                              the Arch (roofed, through the middle rib)
      316  [S3 the rib hall]         [ the Arch: south court ]    [the Stacks][S4 stack caves]
      440  ---- the bottom rows: the snakes before the sea ----
      504  [S5 the wreck yard]                                                 [S6 the shingle]
      592  ==================== the bottom band (the Far Sandbar's approach) =============

Three long ribs of rock run across the beach (z 120 to 190, 254 to 346 and 430 to 504): the
ways wind round their ends and through their breaks. Lanes are 12 wide (foot and small carts),
the cart's way a 20 wide ramp; every rock wall between carvings is at least 24 thick.
"""

from kit import Zone

ROCK = 16  # walls you can't see over; roofs at 14 clear
z = Zone(4, "Outer Shore", rock=ROCK)
f = z.frame


# ---- helpers: the zone's own vocabulary ---------------------------------------------------------
def cart_way(part, points):
    """The cart's way: a 20 wide ramp (a Huge cart needs 14), from the top edge to the bottom."""
    part.ramp(points, width=20)


def foot_way(part, points, width=12):
    part.lane(points, width=width)


def spur(part, points, width=12):
    part.lane(points, width=width)


def rock_break(part, a, b, width=12, at=None, radius=12):
    """A break where the rib overhangs: a stretch of lane under rock, strewn with rubble, where
    rock comes down on a beat (time it). `a`-`b` is the roofed stretch (straight, between two
    walls); the rockfall sits in its middle."""
    part.roof_lane([a, b], width)
    mid = at or (round((a[0] + b[0]) / 2), round((a[1] + b[1]) / 2))
    part.hazard("Rockfall", at=mid, radius=radius)


def pit_break(part, a, b, at):
    """A narrow break widened to 20 with an open spike pit in it (clearly shown): step round it."""
    part.lane([a, b], width=20)
    part.hazard("Pit", at=at, radius=4, covered=False)


def low_ground(part, a, b, width=20):
    """The cart's way through the lowest lane: a long, gentle dip (a cart climbs out) that floods
    first, with the undertow running in it. Safe going down, deadly coming back late."""
    from kit import segment_box, rounded
    part.add(Kind="Hollow", Area=rounded(segment_box(a, b, width + 32)), Width=16, Depth=3,
             Over=True, Material="Mud")
    part.hazard("Undertow", path=[a, b], width=width)


def flood_channel(part, a, b, width=12):
    """A foot way's lowest lane: a cut that floods when the sea reaches it, the undertow in it."""
    part.channel([a, b], depth=2, width=width, material="Mud")
    part.hazard("Undertow", path=[a, b], width=width)


def scramble(part, a, b, clear=10):
    """A foot-only shortcut between two lanes (or a squeeze in one): a gap choked with rubble,
    too steep for a cart. The rubble keeps `clear` studs off the lanes' middles."""
    import math
    part.lane([a, b], width=12)
    (ax, az), (bx, bz) = a, b
    length = math.hypot(bx - ax, bz - az)
    ux, uz = (bx - ax) / length, (bz - az) / length
    k = clear + 6
    part.ridge([(ax + ux * k, az + uz * k), (bx - ux * k, bz - uz * k)], height=2.5, width=12,
               rough=0)


def dead_end(part, points, weight=2, pit=True):
    """A lane to a dead end with a find at its end; under the find a covered spike pit (the cracks
    round it are the tell)."""
    part.lane(points, width=12)
    end = points[-1]
    part.loot(end, radius=5, weight=weight)
    if pit:
        part.hazard("Pit", at=end, radius=4, covered=True)


# ---- the frame ----------------------------------------------------------------------------------
# The bands: the top (where every path starts) and the bottom (the Far Sandbar's approach).
f.hall([(-360, -12), (360, -12), (360, 20), (-360, 20)])
f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])

# The pool court: a nook off the top band round the rock pool at (260, 70).
f.hall([(232, 46), (280, 46), (280, 94), (232, 94)])
f.lane([(256, 12), (256, 52)], width=12)
f.loot((240, 84), radius=4, weight=1)
f.decor("Kelp", area=[(236, 50), (252, 50), (252, 90), (236, 90)], count=3)
f.decor("Starfish", at=(242, 58))

# The Bend: the west rib curls back on itself into a cove (loot in the cove).
f.hall([(-280, 190), (-184, 190), (-184, 300), (-280, 300)])
# The wall's short return (16 long) is drawn as an area, 28 wide like the rest: as a path leg it
# would overlap the corner and the Range would measure the corner (35.5), not the wall.
f.wall([(-288, 252), (-228, 252)], width=28, height=ROCK)
f.wall_area([(-242, 252), (-214, 252), (-214, 268), (-242, 268)], height=ROCK)
f.loot((-262, 284), radius=5, weight=2)
f.decor("WreckRibs", at=(-262, 218), scale=1.2, yaw=70)  # one rib broken (its ribs are)
f.decor("Kelp", area=[(-274, 276), (-250, 276), (-250, 296), (-274, 296)], count=3)
f.decor("Timber", area=[(-216, 270), (-190, 270), (-190, 296), (-216, 296)], count=3)

# The Arch: a roofed passage through the middle rib, with a court at each end.
f.hall([(-48, 214), (48, 214), (48, 254), (-48, 254)])
f.lane([(0, 254), (0, 346)], width=20)
f.roof_lane([(0, 266), (0, 334)], 20)
f.hall([(-48, 346), (48, 346), (48, 386), (-48, 386)])
f.hazard("Rockfall", at=(0, 300), radius=14)
f.loot((-30, 366), radius=4, weight=3)
f.decor("Bones", at=(-30, 234), scale=1.5, yaw=0)  # the Arch's bones
f.decor("Chain", path=[(-8, 268), (-8, 332)], count=2)
f.decor("Barnacles", area=[(-30, 268), (-14, 268), (-14, 332), (-30, 332)], count=4)
f.decor("Timber", at=(30, 372), scale=1.0, yaw=40)

# The Stacks: the east rib broken into sea stacks, an open court between them.
f.hall([(176, 320), (280, 320), (280, 410), (176, 410)],
       pillars=[(232, 350), (264, 350), (232, 398), (264, 398)])
f.loot((248, 380), radius=4, weight=2)
f.decor("WreckRibs", at=(250, 330), scale=1.6, yaw=20)  # a broken hull jammed between the stacks
f.decor("Timber", area=[(180, 326), (226, 326), (226, 406), (180, 406)], count=4)
f.decor("Crate", at=(190, 400))
f.decor("Anchor", at=(270, 404), yaw=200)
f.decor("Barnacles", area=[(226, 344), (270, 344), (270, 404), (226, 404)], count=5)

# Rocks to look at: weed and barnacles at the ribs' feet.
f.decor("Weed", area=[(-30, 150), (30, 150), (30, 196), (-30, 196)], count=4)


# ---- the regions the ways wind through (each a snake of lanes, used by the crossings in turn) ------
# Rows run across the beach at z 60, 104 and 148 (the top rows), 448, 500 and 552 (the bottom
# rows); columns run down between the landmarks: x -140 or -88 west of the Arch, 100 east of it,
# 196 through the Stacks, -336 down the west edge. Parallel carvings keep 24 of rock between.
TOP_W = [(-200, 0), (-200, 60), (-100, 60), (-100, 104), (-200, 104)]  # the west snake
TOP_E = [(100, 0), (100, 60), (192, 60), (192, 104), (100, 104)]  # the east snake
TOP_E3 = [(100, 0), (100, 60), (196, 60), (196, 104), (100, 104), (100, 148), (196, 148)]
BOT_W = [(-140, 448), (-60, 448), (-60, 500), (-180, 500), (-180, 552), (-60, 552), (-60, 608)]
BOT_E = [(100, 448), (160, 448), (160, 500), (60, 500), (60, 552), (160, 552), (160, 608)]


# ---- crossing 1: Rib doors (2 paths) ------------------------------------------------------------
# A: the cart's way, down the east and back and forth across the bottom; B: the foot way west
# through the Bend, with a scramble; the Arch and the Stacks are spurs off A.
c = z.crossing("Rib doors", paths=2)
cart_way(c, TOP_E + [(100, 448)] + BOT_E[1:])
rock_break(c, (100, 276), (100, 316), width=20)
low_ground(c, (60, 552), (160, 552))
spur(c, [(100, 234), (48, 234)])  # to the Arch's north court
spur(c, [(100, 380), (176, 380)])  # to the Stacks
dead_end(c, [(100, 408), (64, 408)], weight=2)
foot_way(c, TOP_W + [(-200, 228), (-140, 228)] + BOT_W)
pit_break(c, (-180, 104), (-120, 104), (-150, 104))
rock_break(c, (-140, 290), (-140, 330))
scramble(c, (-140, 350), (-140, 420))
flood_channel(c, (-160, 552), (-80, 552))
c.decor("WreckRibs", at=(-20, 8), scale=1.1, yaw=90)  # the tell: a hull's ribs at the way in
c.decor("Timber", at=(-4, 6), yaw=20)


# ---- crossing 2: The long way round (1 path) ----------------------------------------------------
# One way: the west snake, across the top, through the Arch, and the east snake to the sea. It is
# the cart's way and every danger is on it; two rubble scrambles shortcut it on foot.
c = z.crossing("The long way round", paths=1)
cart_way(c, TOP_W + [(-200, 148), (0, 148), (0, 448), (120, 448), (120, 500), (40, 500), (40, 552),
                     (120, 552), (120, 608)])
low_ground(c, (40, 552), (120, 552))
scramble(c, (-150, 104), (-150, 148))
scramble(c, (60, 448), (60, 500))
spur(c, [(-200, 148), (-200, 190)])  # to the Bend
spur(c, [(120, 448), (228, 448), (228, 410)])  # to the Stacks
c.lane([(150, 448), (190, 448)], width=20)
c.hazard("Pit", at=(170, 448), radius=4, covered=False)
c.hazard("Pit", at=(-30, 366), radius=4, covered=True)  # under the Arch's prize
c.decor("Bones", at=(-160, 8), scale=1.3, yaw=0)  # the tell: an arch of bones at the way in
c.decor("Barnacles", at=(-140, 6))


# ---- crossing 3: Stack and Bend (2 paths) -------------------------------------------------------
# A: the cart's way, west through the Bend; B: the foot way east through the Stacks.
c = z.crossing("Stack and Bend", paths=2)
cart_way(c, TOP_W + [(-200, 228), (-140, 228)] + BOT_W)
rock_break(c, (-140, 300), (-140, 340), width=20)
low_ground(c, (-180, 552), (-60, 552))
spur(c, [(-140, 228), (-48, 228)])  # to the Arch's north court
dead_end(c, [(-140, 420), (-210, 420)], weight=2)
foot_way(c, TOP_E3 + [(196, 448), (150, 448), (150, 500), (60, 500), (60, 552), (150, 552),
                      (150, 608)])
pit_break(c, (130, 148), (170, 148), (150, 148))
rock_break(c, (196, 190), (196, 230))
scramble(c, (196, 262), (196, 322))
flood_channel(c, (80, 552), (130, 552))
c.decor("Anchor", at=(-150, 8), yaw=40)  # the tell: an anchor and its chain at the way in
c.decor("Chain", path=[(-140, 8), (-110, 8)], count=2)


# ---- crossing 4: Three ways (3 paths) -----------------------------------------------------------
# A: the cart's way down the middle west of the Arch; B: the foot way through the Stacks; C: the
# foot way down the west edge through two coves joined by a squeeze.
c = z.crossing("Three ways", paths=3)
cart_way(c, [(-88, 0), (-88, 60), (20, 60), (20, 104), (-88, 104), (-88, 448), (0, 448), (0, 500),
             (-88, 500), (-88, 552), (0, 552), (0, 608)])
rock_break(c, (-88, 300), (-88, 340), width=20)
low_ground(c, (-88, 552), (0, 552))
spur(c, [(-88, 234), (-48, 234)])  # to the Arch's north court
foot_way(c, TOP_E3 + [(196, 448), (150, 448), (150, 500), (60, 500), (60, 552), (150, 552),
                      (150, 608)])
pit_break(c, (130, 148), (170, 148), (150, 148))
rock_break(c, (196, 190), (196, 230))
scramble(c, (196, 262), (196, 322))
flood_channel(c, (80, 552), (130, 552))
foot_way(c, [(-200, 0), (-200, 136), (-336, 136), (-336, 448), (-190, 448), (-190, 500),
             (-130, 500), (-130, 552), (-190, 552), (-190, 608)])
spur(c, [(-200, 136), (-200, 190)])  # to the Bend
c.hall([(-352, 188), (-314, 188), (-314, 252), (-352, 252)])  # the first cove
c.hall([(-352, 384), (-314, 384), (-314, 440), (-352, 440)])  # the second
scramble(c, (-336, 270), (-336, 370))  # the squeeze between them
c.loot((-340, 220), radius=4, weight=2)
c.loot((-340, 412), radius=4, weight=3)
c.hazard("Pit", at=(-340, 412), radius=4, covered=True)
rock_break(c, (-300, 136), (-240, 136))
pit_break(c, (-290, 448), (-230, 448), (-260, 448))
flood_channel(c, (-184, 552), (-136, 552))
c.decor("Timber", at=(-60, 8), yaw=70)  # the tell: a heap of timber and a crate
c.decor("Crate", at=(-44, 8))
c.decor("Kelp", area=[(-348, 192), (-318, 192), (-318, 248), (-348, 248)], count=3)
c.decor("Barnacles", area=[(-348, 388), (-318, 388), (-318, 436), (-348, 436)], count=3)


# ---- crossing 5: Back door (2 paths) ------------------------------------------------------------
# A: the cart's way east and down through the Stacks; B: the foot way west through the Bend.
c = z.crossing("Back door", paths=2)
cart_way(c, TOP_E3 + [(196, 448), (110, 448), (110, 500), (30, 500), (30, 552), (110, 552),
                      (110, 608)])
rock_break(c, (196, 190), (196, 230), width=20)
low_ground(c, (30, 552), (110, 552))
dead_end(c, [(196, 380), (150, 380)], weight=2)
foot_way(c, TOP_W + [(-200, 228), (-140, 228)] + BOT_W)
spur(c, [(-140, 228), (-48, 228)])  # to the Arch's north court
pit_break(c, (-180, 104), (-120, 104), (-150, 104))
rock_break(c, (-140, 290), (-140, 330))
scramble(c, (-140, 350), (-140, 420))
flood_channel(c, (-160, 552), (-80, 552))
c.decor("DeadCoral", at=(40, 8), scale=1.3)  # the tell: dead coral and a driftwood spar
c.decor("Driftwood", at=(60, 8))


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


def cave_under_the_rib(slot, name, weight=3):
    """A gallery straight in, with short dead-end caves off both sides; the best find in the
    deepest cave, on a covered pit."""
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


def tide_pool(slot, name, weight=3):
    """A pocket whose far half is a pool that floods first; the find at its bottom."""
    r = slot.room(name)
    r.hall(box(slot))
    _, deep, _ = inward(slot)
    w, d = slot.size
    radius = min(w, d) / 2 - 12
    r.hollow(deep, radius=radius, depth=3, material="Mud")
    r.loot(deep, radius=4, weight=weight)
    r.decor("Kelp", area=box(slot, 12), count=5)
    r.decor("Starfish", at=(round(w / 2), round(d / 2)))
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
    r.decor("Barnacles", area=box(slot, 12), count=3)
    return r


def wreck_yard(slot, name, weight=2):
    """A drift of timber and crates jammed in a pocket, a wreck's ribs over the find."""
    r = slot.room(name)
    r.hall(box(slot))
    _, deep, _ = inward(slot)
    w, d = slot.size
    r.decor("Timber", area=box(slot, 12), count=6)
    r.decor("Crate", area=box(slot, 12), count=4)
    r.decor("WreckRibs", at=(round(w / 2), round(d / 2)), scale=0.9, yaw=30)
    r.decor("Chain", at=(round(deep[0]), round(deep[1])))
    r.loot(deep, radius=4, weight=weight)
    return r


def tunnel_ring(slot, name, weight=3):
    """A roofed tunnel round a block of rock, the find in a niche at its far side."""
    r = slot.room(name, lead=False)
    door, deep, (ix, iz) = inward(slot)
    w, d = slot.size
    x0, z0, x1, z1 = 14, 14, w - 14, d - 14
    ring = [(x0, z0), (x1, z0), (x1, z1), (x0, z1), (x0, z0)]
    r.lane(ring, width=12)
    r.roof_lane(ring, 12)
    near = (door[0] + ix * 14, door[1] + iz * 14)
    r.lane([door, near], width=12)
    r.loot(deep, radius=3, weight=weight)
    r.decor("Barnacles", at=(round(deep[0]), round(deep[1])))
    return r


def pillar_chamber(slot, name, weight=2, rockfall=False):
    """A roofed chamber on pillars (the rock overhangs, rubble on the floor); rockfall if it's
    coming down."""
    r = slot.room(name)
    w, d = slot.size
    pillars = [(x, zz) for x in range(28, int(w) - 20, 28) for zz in range(28, int(d) - 20, 28)]
    r.hall(box(slot), roof=True, pillars=pillars)
    _, deep, _ = inward(slot)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Pebbles", at=(round(w / 2), round(d / 2)), scale=1.2)
    if rockfall:
        r.hazard("Rockfall", at=(round(w / 2), round(d / 2)), radius=12)
    return r


# ---- the slots ----------------------------------------------------------------------------------
s1 = z.slot("Barnacle caves", at=(-352, 36), size=(104, 72), door=(52, 0))
cave_under_the_rib(s1, "Cave under the rib", weight=3)
boulder_scramble(s1, "Fallen stacks", weight=1)

s2 = z.slot("The drift", at=(296, 36), size=(64, 80), door=(0, 40))
tide_pool(s2, "Tide pool", weight=2)
wreck_yard(s2, "Timber drift", weight=1)

s3 = z.slot("The rib hall", at=(-296, 316), size=(104, 72), door=(52, 0))
tunnel_ring(s3, "Ring under the rib", weight=3)
tide_pool(s3, "Drowned pocket", weight=2)

s4 = z.slot("Stack caves", at=(296, 336), size=(64, 96), door=(0, 48))
pillar_chamber(s4, "Stack chamber", weight=2, rockfall=True)
boulder_scramble(s4, "Boulder choke", weight=2)

s5 = z.slot("The wreck yard", at=(-352, 504), size=(104, 72), door=(52, 72))
wreck_yard(s5, "Wreck yard", weight=2)
cave_under_the_rib(s5, "Deep cave", weight=4)

s6 = z.slot("The shingle", at=(192, 504), size=(112, 72), door=(56, 72))
pillar_chamber(s6, "Rib chapel", weight=2, rockfall=True)
tide_pool(s6, "Sea pool", weight=4)

z.write("src/shared/Layouts/Zones/Zone4.luau",
        "-- Zone 4, The Outer Shore: drawn with the layout kit from tools/kit/plans/zone4.py (edit\n"
        "-- the plan and re-run it, not this file). Its card: docs/design/cards/zone4.md.")
