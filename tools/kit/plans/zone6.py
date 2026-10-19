"""Zone 6, The Drowned Reach: the role model (docs/design/cards/zone6.md).

Other zones and biomes copy how this plan is laid out:
  1. the frame: the landmarks and hubs that are always there, and the slots' doors onto them;
  2. each crossing: its paths (each with its character), the links between them, its dangers,
     its tell at the way in;
  3. each slot's rooms: one door, different kinds, the best finds deepest.

Run it with the quick check:  python3 tools/kit/quick.py 6 --plan tools/kit/plans/zone6.py

The map (zone coordinates: x -360 west to 360 east, z 0 at the top to 608 at the sea):

    z   0  ===================== the top band (every path starts here) ======================
       28  [S1 shore caves]                                                [S2 the lockers]
      168  [S3 west vault][West Court]
      248                                  [ the Drowned Hall ]
      296  the Stair
      328                                                           [Wreck Court][S6 the hold]
      352                                      [S4 the crypt]
      504                   [S7 the sea vault]                 [S5 the chapel]
      584  ===================== the bottom band (the Far Sandbar's approach) ================

The slots and hubs keep to the sides, the middle and the bands, leaving room between them for
the long winding paths an 85-second zone needs (each path 1300 to 2300 studs of walking).

The hubs (the courts, the Hall, the bands) are islands in the frame: each crossing connects
them its own way, and every crossing reaches every hub, so every slot's door can be walked to.
"""

from kit import Zone

ROCK = 20  # walls you can't see over; roofs at 18 clear
LIT = "LanternPost"

z = Zone(6, "The Drowned Reach", rock=ROCK)
f = z.frame


# ---- helpers: the zone's own vocabulary ---------------------------------------------------------
def along(points, every):
    """Points every `every` studs along a polyline (not the ends)."""
    import math
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


def lit_way(part, points, width=16):
    """The lit path: the cart's ramp with lantern posts along it, at its side (wards against
    the Gloom)."""
    part.ramp(points, width=width)
    side = width / 2 + 1
    for (ax, az), (bx, bz) in zip(points, points[1:]):
        length = ((bx - ax) ** 2 + (bz - az) ** 2) ** 0.5
        for x, zz in along([(ax, az), (bx, bz)], 72) if length > 40 else []:
            nx, nz = -(bz - az) / length * side, (bx - ax) / length * side
            part.decor(LIT, at=(round(x + nx), round(zz + nz)))


def dark_way(part, points, roofed=(), gloom=None, width=12):
    """A dark gallery: a narrow lane, roofed along the given segments (index ranges), the Gloom
    walking `gloom` (a sub-path), and a few glowing shells as the only light."""
    part.lane(points, width=width)
    for i in roofed:
        part.roof_lane([points[i], points[i + 1]], 12)
    if gloom:
        part.hazard("Gloom", path=gloom, radius=9)
    for x, zz in along(points, 140):
        part.decor("GlowShells", at=(round(x), round(zz)))


def spur(part, points, width=12):
    part.lane(points, width=width)


def scramble(part, a, b, clear=10):
    """A foot-only shortcut between two lanes: a gap choked with rubble, too steep for a cart.
    It cuts a bend without making a path of its own. The rubble keeps `clear` studs off the
    lanes' middles (off a ramp, so carts pass)."""
    import math
    part.lane([a, b], width=12)
    (ax, az), (bx, bz) = a, b
    length = math.hypot(bx - ax, bz - az)
    ux, uz = (bx - ax) / length, (bz - az) / length
    k = clear + 6
    part.ridge([(ax + ux * k, az + uz * k), (bx - ux * k, bz - uz * k)], height=2.5, width=12,
               rough=0)


def dead_end(part, points, weight=2, sink=True):
    """A lane to a dead end with a find at its end; sinking sand on the way in (stopping in it
    kills), so the find costs nerve as well as time."""
    part.lane(points, width=12)
    end = points[-1]
    part.loot(end, radius=5, weight=weight)
    if sink:
        (ax, az), (bx, bz) = points[-2], points[-1]
        part.hazard("Sink", at=(round((ax + bx) / 2), round((az + bz) / 2)), radius=10)


# ---- the frame ----------------------------------------------------------------------------------
# The bands: the top (where every path starts) and the bottom (the Far Sandbar's approach).
f.hall([(-360, -12), (360, -12), (360, 20), (-360, 20)])
f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])

# The West Court: open sky, light falling in; paths cross here.
f.court([(-272, 176), (-176, 176), (-176, 264), (-272, 264)])
f.decor("DeadCoral", area=[(-264, 184), (-184, 184), (-184, 256), (-264, 256)], count=6)
f.decor("GlowWeed", at=(-224, 220))

# The Drowned Hall: the pillared chamber in the middle, roofed.
f.hall([(-72, 248), (72, 248), (72, 344), (-72, 344)], roof=True,
       pillars=[(-36, 280), (0, 280), (36, 280), (-36, 312), (0, 312), (36, 312)])
f.decor("Bones", at=(0, 296), scale=1.4, yaw=90)
f.loot((0, 296), weight=3)

# The Wreck Court: open sky round a broken hull.
f.court([(176, 328), (280, 328), (280, 424), (176, 424)])
f.decor("WreckRibs", at=(228, 376), scale=1.6, yaw=30)
f.decor("Timber", area=[(184, 336), (272, 336), (272, 416), (184, 416)], count=6)
f.decor("Anchor", at=(196, 404), yaw=200)
f.loot((228, 376), weight=2)

# The Stair: a long gallery down the west side, stepping down over rubble (foot only).
f.lane([(-328, 296), (-328, 488)], width=20)
for step in range(320, 488, 36):
    f.ridge([(-340, step), (-316, step)], height=2.5, width=12, rough=0)
f.decor("Chain", path=[(-328, 300), (-328, 484)], count=3)


# ---- crossing 1: Lantern way (2 paths) ----------------------------------------------------------
# A: the lit cart path, winding west then down past the West Court and the Hall's west door.
# B: the dark galleries, a serpentine through the east (the Gloom walks its roofed loop), then
#    the Wreck Court and down the east side.
# Link: the Hall's east door onto B.
c = z.crossing("Lantern way", paths=2)
lit_way(c, [(-200, 0), (-200, 60), (184, 60), (184, 128), (-140, 128), (-140, 456), (88, 456),
            (88, 530), (-60, 530), (-60, 608)])
spur(c, [(-140, 220), (-176, 220)])  # to the West Court
spur(c, [(-140, 296), (-72, 296)])  # to the Hall's west door
dark = [(224, 0), (224, 132), (340, 132), (340, 188), (104, 188), (104, 244), (336, 244),
        (336, 300), (140, 300), (140, 376), (176, 376)]
dark_way(c, dark, roofed=(3, 5), gloom=[(340, 188), (104, 188), (104, 244), (336, 244)])
spur(c, [(72, 320), (140, 320)])  # the link: the Hall's east door
dark_way(c, [(228, 424), (228, 464), (272, 464), (272, 608)])
dead_end(c, [(-140, 380), (-240, 380), (-240, 420)], weight=2)
c.decor(LIT, at=(-188, 10))  # the tell: lanterns at the way in
c.decor("Anchor", at=(236, 12), yaw=120)


# The regions the paths wind through (each a snake of lanes), used by the crossings in turn:
# the top-west wiggle, the West rows (below the West Court), the centre rows (above the Hall),
# the east switchbacks or the east rows (above the Wreck Court), and the bottom snakes.
TOP_WEST = [(-136, 0), (-136, 48), (-224, 48), (-224, 100), (-152, 100), (-152, 148), (-224, 148),
            (-224, 176)]
WEST_ROWS = [(-224, 264), (-224, 300), (-136, 300), (-136, 336), (-288, 336), (-288, 372),
             (-136, 372), (-136, 408), (-288, 408), (-288, 444), (-136, 444), (-136, 480),
             (-280, 480), (-280, 608)]
CENTRE_ROWS = [(40, 0), (40, 48), (-88, 48), (-88, 104), (80, 104), (80, 160), (-88, 160),
               (-88, 216), (40, 216), (40, 248)]
BOTTOM_CENTRE = [(-72, 328), (-100, 328), (-100, 452), (80, 452), (80, 520), (-60, 520), (-60, 608)]
BOTTOM_EAST = [(228, 424), (228, 452), (336, 452), (336, 500), (256, 500), (256, 548), (336, 548),
               (336, 608)]


# ---- crossing 2: The falling hall (3 paths) -----------------------------------------------------
# A: the lit cart path: switchbacks down the east into the Wreck Court, then the bottom snake.
# B: the dark west: the top-west wiggle, the West Court, the Gloom's roofed rows.
# C: the centre: rows above the Hall, through the Hall (rockfall), the flooding bottom snake.
# Link: the Hall's east door to the Wreck Court.
c = z.crossing("The falling hall", paths=3)
lit_way(c, [(120, 0), (120, 72), (224, 72), (224, 128), (336, 128), (336, 296), (288, 296),
            (288, 168), (240, 168), (240, 296), (192, 296), (192, 168), (144, 168), (144, 376),
            (176, 376)])
lit_way(c, BOTTOM_EAST)
dark_way(c, TOP_WEST)
dark_way(c, WEST_ROWS, roofed=(4, 6, 8), gloom=[(-288, 336), (-288, 372), (-136, 372), (-136, 408),
                                                (-288, 408)])
dark_way(c, CENTRE_ROWS, roofed=(5,))
c.hazard("Rockfall", at=(0, 296), radius=16)
dark_way(c, BOTTOM_CENTRE)
c.channel([(60, 520), (-40, 520)], depth=2, width=12, material="Mud")
c.hazard("Undertow", path=[(60, 520), (-40, 520)], width=12)
spur(c, [(72, 328), (144, 328)])  # the link: the Hall to the lit path
c.decor("WreckRibs", at=(130, 12), scale=0.8, yaw=90)  # the tell: a hull's ribs at the way in


# ---- crossing 3: The Stair (2 paths) ------------------------------------------------------------
# A: the lit cart path, a long sweep across the middle and the east, round by the Wreck Court.
# B: foot only and dark: the top-west wiggle, the West Court, down past the rows and back up
#    them (the Gloom's), then down the Stair.
c = z.crossing("The Stair", paths=2)
lit_way(c, [(40, 0), (40, 56), (200, 56), (200, 120), (-60, 120), (-60, 200), (330, 200),
            (330, 296), (140, 296), (140, 376), (176, 376)])
lit_way(c, [(228, 424), (228, 470), (-60, 470), (-60, 608)])
spur(c, [(72, 320), (140, 320)])  # the Hall's east door
dark_way(c, TOP_WEST, roofed=(1, 3), gloom=[(-136, 48), (-224, 48), (-224, 100), (-152, 100)])
dark_way(c, [(-176, 240), (-120, 240), (-120, 480), (-288, 480), (-288, 420), (-160, 420),
             (-160, 360), (-288, 360), (-288, 300), (-328, 300)], roofed=(5,),
         gloom=[(-160, 360), (-288, 360)])
dark_way(c, [(-328, 488), (-328, 540), (-260, 540), (-260, 608)])
dead_end(c, [(330, 296), (330, 260)], weight=2)
c.decor("Bones", at=(-136, 12), scale=1.3, yaw=0)  # the tell: an arch of bones at the way in


# ---- crossing 4: The long dark (1 path) ---------------------------------------------------------
# One long way with every danger on it, the cart's too: the Gloom's switchbacks in the east, the
# Wreck Court, the Hall (rockfall), the West Court, and down the west. Side lanes are dead ends
# (one floods, with an undertow).
c = z.crossing("The long dark", paths=1)
lit_way(c, [(200, 0), (200, 128), (336, 128), (336, 296), (288, 296), (288, 168), (240, 168),
            (240, 328)])
c.roof_lane([(336, 160), (336, 264)], 16)
c.roof_lane([(288, 200), (288, 264)], 16)
c.hazard("Gloom", path=[(336, 136), (336, 288), (288, 288), (288, 176)], radius=9)
lit_way(c, [(176, 376), (120, 376), (120, 336), (-104, 336), (-104, 220), (-176, 220)])
c.hazard("Rockfall", at=(0, 330), radius=16)
lit_way(c, [(-224, 264), (-224, 300), (-144, 300), (-144, 360), (-280, 360), (-280, 420),
            (-144, 420), (-144, 480), (-280, 480), (-280, 608)])
dead_end(c, [(200, 128), (40, 128), (40, 200)], weight=2)
dead_end(c, [(228, 424), (228, 470), (60, 470)], weight=3)
spur(c, [(-280, 540), (-244, 540)])
c.channel([(-262, 540), (-248, 540)], depth=2, width=12, material="Mud")
c.hazard("Undertow", path=[(-262, 540), (-248, 540)], width=12)
c.loot((-248, 540), radius=4, weight=2)
scramble(c, (-200, 300), (-200, 360))  # shortcuts for feet: rubble a cart can't climb
scramble(c, (336, 220), (288, 220))
c.decor(LIT, at=(188, 10))  # the tell: a pair of lanterns at the way in
c.decor(LIT, at=(212, 10))


# ---- crossing 5: The courts (3 paths) -----------------------------------------------------------
# Three ways, two of them meeting in the Wreck Court (open sky, a place to regroup):
# A: the lit cart path through the centre rows, down the Hall's east side, through the Wreck
#    Court, and the long sweep west along the bottom.
# B: the dark west: the top-west wiggle, the West Court, the rows.
# C: the east rows (the Gloom's), the Wreck Court, the bottom-east snake.
c = z.crossing("The courts", paths=3)
lit_way(c, CENTRE_ROWS[:-1] + [(100, 216), (100, 376), (176, 376)])
lit_way(c, [(228, 424), (228, 470), (-60, 470), (-60, 608)])
spur(c, [(72, 320), (100, 320)])  # the Hall's east door
dark_way(c, TOP_WEST)
dark_way(c, WEST_ROWS, roofed=(8,), gloom=[(-136, 408), (-288, 408)])
dark_way(c, [(200, 0), (200, 128), (336, 128), (336, 184), (152, 184), (152, 240), (336, 240),
             (336, 296), (240, 296), (240, 328)], roofed=(3,), gloom=[(336, 184), (152, 184)])
dark_way(c, [(272, 424), (272, 452)] + BOTTOM_EAST[2:])
dead_end(c, [(-60, 520), (60, 520)], weight=2)
c.decor("DeadCoral", at=(40, 12), scale=1.3)  # the tell: dead coral and a smashed crate
c.decor("Crate", at=(56, 10))


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


def comb_of_caves(slot, name, weight=3):
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


def flooded_vault(slot, name, weight=3):
    """A vault whose far half is a pool that floods first; the find at its bottom."""
    r = slot.room(name)
    r.hall(box(slot))
    _, deep, _ = inward(slot)
    w, d = slot.size
    radius = min(w, d) / 2 - 12
    r.hollow(deep, radius=radius, depth=4, material="Mud")
    r.loot(deep, radius=4, weight=weight)
    r.decor("Kelp", area=box(slot, 12), count=5)
    return r


def sinking_flat(slot, name, weight=2):
    """Open sand between the door and the find, most of it sinking: cross it moving."""
    r = slot.room(name)
    r.hall(box(slot))
    door, deep, (ix, iz) = inward(slot)
    mid = ((door[0] + deep[0]) / 2, (door[1] + deep[1]) / 2)
    r.hazard("Sink", at=(round(mid[0]), round(mid[1])), radius=12)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Bones", at=(round(deep[0] - iz * 14), round(deep[1] - ix * 14)), scale=0.8)
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
    # In from the door to the ring.
    near = (door[0] + ix * 14, door[1] + iz * 14)
    r.lane([door, near], width=12)
    r.loot(deep, radius=3, weight=weight)
    r.decor("GlowShells", at=(round(deep[0]), round(deep[1])))
    return r


def pillar_chamber(slot, name, weight=2, rockfall=False):
    """A roofed chamber on pillars; bones, and rockfall if it's coming down."""
    r = slot.room(name)
    w, d = slot.size
    pillars = [(x, zz) for x in range(28, int(w) - 20, 28) for zz in range(28, int(d) - 20, 28)]
    r.hall(box(slot), roof=True, pillars=pillars)
    _, deep, _ = inward(slot)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Bones", at=(round(w / 2), round(d / 2)), scale=1.1)
    if rockfall:
        r.hazard("Rockfall", at=(round(w / 2), round(d / 2)), radius=12)
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
    return r


# ---- the slots ----------------------------------------------------------------------------------
# Rooms differ in kind; the best finds are deepest (the sea vault and the crypt), on covered pits.
s1 = z.slot("Shore caves", at=(-352, 36), size=(104, 72), door=(52, 0))
comb_of_caves(s1, "Comb of caves", weight=2)
boulder_scramble(s1, "Boulder scramble", weight=1)

s2 = z.slot("The lockers", at=(248, 36), size=(104, 72), door=(52, 0))
r = s2.room("Crate store")
r.hall(box(s2))
r.decor("Crate", area=box(s2, 12), count=5)
r.loot((24, 52), weight=1)
flooded_vault(s2, "Flooded locker", weight=2)

s3 = z.slot("West vault", at=(-360, 168), size=(72, 104), door=(72, 52))
flooded_vault(s3, "Drowned pool", weight=2)
sinking_flat(s3, "Sinking flat", weight=2)

s4 = z.slot("The crypt", at=(-48, 360), size=(96, 72), door=(48, 0))
r = pillar_chamber(s4, "Bone crypt", weight=3)
r.hazard("Pit", at=(48, 52), radius=4, covered=True)
tunnel_ring(s4, "Ring crypt", weight=3)

s5 = z.slot("The chapel", at=(120, 504), size=(112, 72), door=(56, 72))
pillar_chamber(s5, "Pillar chapel", weight=2, rockfall=True)
comb_of_caves(s5, "Chapel caves", weight=3)

s6 = z.slot("The hold", at=(296, 328), size=(64, 96), door=(0, 48))
flooded_vault(s6, "Flooded hold", weight=3)
sinking_flat(s6, "Silted hold", weight=2)

s7 = z.slot("The sea vault", at=(-232, 504), size=(112, 72), door=(56, 72))
r = tunnel_ring(s7, "Sea vault", weight=4)
r.hazard("Pit", at=(56, 12), radius=4, covered=True)
r = flooded_vault(s7, "Drowned vault", weight=4)
boulder_scramble(s7, "Fallen vault", weight=3)

z.write("src/shared/Layouts/Zones/Zone6.luau",
        "-- Zone 6, The Drowned Reach: drawn with the layout kit from tools/kit/plans/zone6.py (edit\n"
        "-- the plan and re-run it, not this file). The role model: docs/design/cards/zone6.md.")
