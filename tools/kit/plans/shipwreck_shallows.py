"""Shipwreck Shallows, a biome rolling in zones 2 to 6 (docs/design/cards/shipwreck-shallows.md).

One big wreck broken on the sand: the barrels still rolling off her deck down the gullies, scour
channels round her with an undertow in them, spike pits in the rotten decking and debris.

Run it with the quick check, once per zone:
    python3 tools/kit/quick.py 4 Biomes/ShipwreckShallows --plan tools/kit/plans/shipwreck_shallows.py

Zones 2 and 3 are open sand (no rock, no walls): the wreck lies low, a ridge of sand-buried hull
across the top, scour channels and gullies cut down from her deck. One wide ramp for carts,
foot shortcuts over the low ridges.
Zones 4 to 6 are walled: the wreck's hull is the rock between the top band and the deck court.
You go round her down either flank, or through the hatch (a roofed passage with the holds
off it); the gullies start at the deck court and run down the zone (the barrels roll down them,
and the quick path takes a gully); the scour below holds the channels, mounds and pits.
"""

import math

from kit import Zone, write_zones

OUT = "src/shared/Layouts/Biomes/ShipwreckShallows.luau"
NAME = "Shipwreck Shallows"
SPOTS = (-100, -20, 60, 120)  # the biome's EntranceSpots (Biomes.luau): flat, 30 studs in
TAR = "Pavement"


# ---- helpers: the biome's vocabulary -----------------------------------------------------------
def box(cx, cz, w, d):
    return [(cx - w / 2, cz - d / 2), (cx + w / 2, cz - d / 2), (cx + w / 2, cz + d / 2),
            (cx - w / 2, cz + d / 2)]


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


def debris(part, cx, cz, w=40, d=30, count=4):
    """A heap of wreckage: timber, a crate or two, rope-ends."""
    part.decor("Timber", area=box(cx, cz, w, d), count=count)
    part.decor("Crate", at=(cx + w * 0.2, cz - d * 0.2), yaw=cx % 90)


def pit(part, at, covered, radius=4):
    """A spike pit in the rotten decking: open (the gap is the tell) or under a false floor
    (the cracks and a loose plank are)."""
    part.hazard("Pit", at=at, radius=radius, covered=covered)
    part.decor("Timber", at=(at[0] + radius + 3, at[1]), yaw=40)
    if not covered:
        part.decor("Chain", at=(at[0] - radius - 3, at[1] + 2))


def barrels(part, path):
    """Barrels teeter on the deck's edge then roll down the gully that starts there."""
    part.hazard("Roller", path=path)
    x, z = path[0]
    part.decor("Crate", at=(x + 10, z - 6), yaw=30)
    part.decor("Chain", at=(x - 10, z - 4))


def undertow(part, path, width=12, depth=2):
    """A scour channel the sea fills: the current drags seaward while it does."""
    part.channel(path, depth=depth, width=width, rough=1, material="Mud")
    part.hazard("Undertow", path=path, width=width)


def ford(part, x, z, width=12, depth=1.8):
    """A scour channel across a lane (a cart climbs in and out; the undertow drags in it)."""
    path = [(x - 10, z), (x + 10, z)]
    part.channel(path, depth=depth, width=width, rough=0, material="Mud")
    part.hazard("Undertow", path=path, width=width)
    part.decor("Weed", at=(x + 12, z + 8))


def gully(part, path, depth=2.4, width=10):
    """A gully cut down from the deck (feet climb its sides, carts can't)."""
    part.channel(path, depth=depth, width=width, rough=1, material=TAR)
    part.decor("Timber", path=path, count=3)


def hull_ribs(part, at, scale=1.5, yaw=0):
    part.decor("WreckRibs", at=at, scale=scale, yaw=yaw)


# ---- zones 2 and 3: open sand --------------------------------------------------------------------
def open_zone(n, cap, ridge_w):
    z = Zone(n, NAME, rock=0)
    f = z.frame
    # The wreck lies low across the top: a hull of sand-buried timber, a bow and a stern.
    f.add(Kind="Ridge", Path=[(-330, 84), (-200, 96), (-60, 88), (60, 100), (160, 86)],
          Height=cap - 0.6, Width=ridge_w, Rough=1, Material=TAR)
    hull_ribs(f, (-120, 92), 1.8, 90)
    hull_ribs(f, (20, 94), 1.5, 80)
    f.decor("Timber", path=[(-320, 80), (150, 84)], count=9)
    f.decor("Anchor", at=(-250, 70), yaw=30)
    f.decor("Chain", path=[(-90, 110), (-60, 118)], count=2)
    # The entrance flats (the biome's EntranceSpots), the hatch at the bow's foot.
    for x in SPOTS:
        f.add(Kind="Flat", At=[x, 30], Radius=10)
    f.entrance((-20, 30))
    f.decor("Crate", at=(-20, 46), yaw=10)
    f.decor("Chain", at=(-8, 40))
    return z, f


def zone2():
    z, f = open_zone(2, 5, 14)
    # Gullies from the deck (the barrels' ways), a scour channel across the middle, mounds.
    g_w = [(-180, 100), (-180, 200), (-210, 300), (-210, 420)]
    g_e = [(110, 106), (110, 210), (140, 330), (140, 430)]
    gully(f, g_w)
    gully(f, g_e)
    scour = [(-330, 360), (-150, 372), (20, 356), (200, 372), (340, 360)]
    f.channel(scour, depth=2, width=10, rough=1, material="Mud")
    for x, zz, h in ((-60, 220, 2.4), (60, 250, 2.8), (-250, 160, 2.4), (250, 190, 2.8),
                     (-40, 480, 2.6), (220, 500, 2.6), (-280, 520, 2.4)):
        f.mound((x, zz), radius=11, height=h, rock=False)
        debris(f, x + 14, zz + 12)
    f.decor("Rocks", area=box(0, 570, 600, 40), count=5)
    f.decor("Driftwood", at=(-300, 440), yaw=60)
    f.decor("Pebbles", area=box(0, 600, 640, 30), count=5)

    # 1: the east loop, the west gully's barrels.
    c = z.crossing("Gully run", paths=1)
    c.ramp([(130, 0), (130, 120), (-100, 250), (-100, 420), (90, 500), (90, 608)], width=20)
    barrels(c, g_w)
    undertow(c, [(-60, 366), (60, 360)])
    pit(c, (-30, 190), True)
    pit(c, (200, 440), False)
    c.decor("Crate", at=(120, 12), yaw=10)
    c.decor("Chain", path=[(140, 10), (150, 20)], count=2)
    # 2: down the west.
    c = z.crossing("Port side", paths=1)
    c.ramp([(-170, 0), (-170, 120), (0, 230), (0, 440), (-140, 520), (-140, 608)], width=20)
    barrels(c, g_e)
    undertow(c, [(120, 366), (190, 366)])
    pit(c, (90, 200), True)
    pit(c, (-250, 380), False)
    c.decor("Timber", at=(-160, 12), yaw=80)
    c.decor("Anchor", at=(-190, 14), yaw=200)
    # 3: through the middle.
    c = z.crossing("Under the stern", paths=1)
    c.ramp([(10, 0), (10, 150), (-160, 260), (-160, 450), (40, 510), (40, 608)], width=20)
    barrels(c, g_w)
    barrels(c, g_e)
    undertow(c, [(-300, 366), (-230, 366)])
    pit(c, (150, 260), True)
    pit(c, (-80, 300), False)
    c.decor("Chain", path=[(-4, 12), (24, 12)], count=3)
    c.decor("Crate", at=(30, 16), yaw=60)
    return z


def zone3():
    z, f = open_zone(3, 7, 18)
    g_w = [(-100, 106), (-100, 220), (-140, 320), (-140, 440)]
    g_e = [(190, 110), (190, 230), (160, 340), (160, 450)]
    gully(f, g_w, depth=3)
    gully(f, g_e, depth=3)
    scour = [(-330, 330), (-120, 344), (60, 326), (240, 344), (340, 330)]
    f.channel(scour, depth=2.4, width=10, rough=1, material="Mud")
    for x, zz, h in ((-20, 210, 3.4), (-260, 200, 3.2), (300, 220, 3.4), (30, 440, 3.6),
                     (-240, 480, 3.4), (260, 500, 3.2)):
        f.mound((x, zz), radius=12, height=h, rock=False)
        debris(f, x + 14, zz + 12)
    f.decor("Rocks", area=box(0, 570, 600, 40), count=5)
    f.decor("Driftwood", at=(300, 420), yaw=100)
    f.decor("Pebbles", area=box(0, 600, 640, 30), count=5)

    c = z.crossing("Deck run", paths=1)
    c.ramp([(-180, 0), (-180, 140), (50, 240), (50, 440), (-200, 520), (-200, 608)], width=20)
    barrels(c, g_w)
    barrels(c, g_e)
    undertow(c, [(-60, 336), (30, 332)])
    pit(c, (-20, 120), True)
    pit(c, (-260, 400), False)
    pit(c, (270, 380), True)
    c.decor("Anchor", at=(-190, 14), yaw=10)
    c.decor("Crate", at=(-170, 12), yaw=40)
    c = z.crossing("Starboard way", paths=1)
    c.ramp([(240, 0), (240, 150), (10, 250), (10, 450), (230, 520), (230, 608)], width=20)
    barrels(c, g_w)
    undertow(c, [(120, 336), (200, 340)])
    pit(c, (-60, 290), True)
    pit(c, (100, 200), False)
    pit(c, (-260, 400), True)
    c.decor("Timber", at=(230, 12), yaw=70)
    c.decor("Chain", path=[(250, 10), (262, 22)], count=2)
    return z


# ---- zones 4 to 6: walled ------------------------------------------------------------------------
# The map (zone coordinates; x -360 west to 360 east, z 0 at the top to 608 at the sea):
#
#    z   0  ============= the top band (every path starts here; the entrance spots at z 30) ======
#       46  [ rock: the hull ]  the hatch passage runs down it (x -20), the holds off it
#       72  [W hold]  hatch  [E hold]       the flanks (x 214 to 340 each side) run down her sides
#       HZ  --- the stern: scuppers at x +-150, where the gullies start (the barrels' ways) -----
#     below   the scour: the gullies' rows, the mound rows, the centre's rows, channels
#      504  [cargo west]        [scour hole]        [cargo east]
#      592  ============= the bottom band ====================================================
#
# The hull is the rock between the top band and the stern: you go round her down a flank, or
# through the hatch. The zone is three sectors (west, centre, east); a crossing's paths each keep
# to their own, so no way across between them cuts a path short (each has its own length).

def wide(part, points, width=16):
    part.ramp(points, width=width)


def narrow(part, points, width=12):
    part.lane(points, width=width)


def dead_end(part, pts, weight, open_pit=True):
    """A lane into a pile of wreckage with a find at its end, on a covered pit; an open one in
    the mouth (the gap is the tell)."""
    part.lane(pts, width=12)
    end = pts[-1]
    part.loot(end, radius=4, weight=weight)
    pit(part, end, True)
    if open_pit:
        (ax, az), (bx, bz) = pts[-2], pts[-1]
        part.hall(box((ax + bx) / 2, (az + bz) / 2, 28, 28))
        pit(part, (round((ax + bx) / 2), round((az + bz) / 2)), False)
    debris(part, end[0], end[1] - 12, 30, 20, 3)


def scramble(part, a, b, clear=10):
    """A foot-only shortcut: a gap choked with a bank of wreckage no cart can climb."""
    part.lane([a, b], width=12)
    (ax, az), (bx, bz) = a, b
    length = math.hypot(bx - ax, bz - az)
    ux, uz = (bx - ax) / length, (bz - az) / length
    k = clear + 6
    part.ridge([(ax + ux * k, az + uz * k), (bx - ux * k, bz - uz * k)], height=2.5, width=12,
               rough=0)


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


def inset(slot, k=8):
    w, d = slot.size
    return [(k, k), (w - k, k), (w - k, d - k), (k, d - k)]


def cargo_hold(slot, name, weight):
    """A hold stacked with cargo: crates, barrels' staves, the find at the far end."""
    r = slot.room(name)
    r.hall(inset(slot), pillars=[(slot.size[0] / 2, slot.size[1] / 2)])
    _, deep, _ = inward(slot)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Crate", area=inset(slot, 14), count=6)
    r.decor("Timber", area=inset(slot, 14), count=3)
    return r


def flooded_hold(slot, name, weight):
    """A hold the sea still fills: the find at the bottom of the water."""
    r = slot.room(name)
    r.hall(inset(slot))
    _, deep, _ = inward(slot)
    r.hollow(deep, radius=min(slot.size) / 2 - 12, depth=3, material="Mud")
    r.loot(deep, radius=4, weight=weight)
    r.decor("Chain", area=inset(slot, 14), count=3)
    return r


def bell_hold(slot, name, weight, pits=1):
    """The deepest hold: a gallery in, the bell on its false floor (a covered pit), more in
    the corners."""
    r = slot.room(name, lead=False)
    door, deep, (ix, iz) = inward(slot)
    r.lane([door, deep], width=12)
    w, d = slot.size
    side = [(deep[0] + iz * 22, deep[1] + ix * 22), (deep[0] - iz * 22, deep[1] - ix * 22)]
    for end in side:
        r.lane([deep, end], width=12)
        r.loot(end, radius=3, weight=1)
    r.loot(deep, radius=4, weight=weight)
    r.hazard("Pit", at=deep, radius=4, covered=True)
    if pits > 1:
        r.hazard("Pit", at=side[0], radius=3, covered=False)
    r.decor("Chain", at=(round(deep[0] + 8), round(deep[1] + 8)))
    r.decor("Crate", at=(round(deep[0] - 8), round(deep[1] - 8)))
    return r


def scour_hole(slot, name, weight):
    """A hole the scour dug under the sand: a deep round pool with the find in its bottom."""
    r = slot.room(name)
    r.hall(inset(slot))
    _, deep, _ = inward(slot)
    r.hollow(deep, radius=min(slot.size) / 2 - 12, depth=4, material="Mud")
    r.loot(deep, radius=4, weight=weight)
    r.decor("Kelp", area=inset(slot, 14), count=4)
    return r


def cargo_pile(slot, name, weight):
    """Spilled cargo: boulders of tangled wreckage to clamber round, the find behind."""
    r = slot.room(name)
    r.hall(inset(slot))
    _, deep, _ = inward(slot)
    w, d = slot.size
    for k, (fx, fz) in enumerate([(0.3, 0.4), (0.7, 0.5), (0.45, 0.7)]):
        r.mound((round(w * fx), round(d * fz)), radius=7, height=4 + k % 2, rock=True)
    r.loot(deep, radius=4, weight=weight)
    r.decor("Crate", area=inset(slot, 14), count=5)
    return r


def walled(n, rock, HZ, spec):
    """One walled zone. HZ: where the hull ends (the stern); `spec` draws the crossings."""
    z = Zone(n, NAME, rock=rock)
    f = z.frame
    f.hall([(-360, -12), (360, -12), (360, 46), (-360, 46)])
    f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])
    f.decor("Timber", area=box(0, 6, 640, 16), count=8)
    f.decor("Rocks", area=box(0, 606, 640, 16), count=6)
    f.decor("Starfish", area=box(0, 604, 640, 16), count=3)
    for x in SPOTS:
        f.add(Kind="Flat", At=[x, 30], Radius=10)

    # The hull's hatch: a passage down into her from the top band (the entrance), the holds off
    # it. It stops inside the hull: a crossing may open it through the stern.
    f.lane([(-20, 44), (-20, HZ - 36)], width=12)
    f.entrance((-20, 30))
    f.decor("Chain", at=(-34, 38))
    f.decor("Crate", at=(-6, 38), yaw=20)
    f.decor("WreckRibs", at=(-20, 18), scale=1.8, yaw=0)
    f.decor("WreckRibs", at=(-170, 30), scale=1.6, yaw=90)
    f.decor("WreckRibs", at=(150, 30), scale=1.6, yaw=90)
    f.decor("Anchor", at=(-230, 26), yaw=40)
    f.decor("Timber", path=[(-200, 34), (200, 34)], count=6)
    f.decor("Chain", path=[(60, 36), (110, 36)], count=3)

    # The holds, inside the hull off the hatch passage (the best crates and the bell deepest).
    hw = z.slot("The port hold", at=(-150, 72), size=(104, 72), door=(104, 36))
    cargo_hold(hw, "Cargo hold", 2)
    flooded_hold(hw, "Flooded hold", 3)
    he = z.slot("The bell hold", at=(46, 72), size=(104, 72), door=(0, 36))
    f.lane([(30, 108), (-20, 108)], width=12)
    bell_hold(he, "Ship's bell", 5)
    cargo_hold(he, "Lower hold", 3)
    # Below, off the bottom band: cargo piles and the scour hole.
    sw = z.slot("Cargo west", at=(-330, 504), size=(104, 72), door=(52, 72))
    cargo_pile(sw, "Spilled cargo", 2)
    flooded_hold(sw, "Sunken stores", 3)
    sc = z.slot("The scour hole", at=(-52, 504), size=(104, 72), door=(52, 72))
    scour_hole(sc, "Scour hole", 4)
    cargo_pile(sc, "Cargo heap", 3)
    se = z.slot("Cargo east", at=(226, 504), size=(104, 72), door=(52, 72))
    cargo_pile(se, "Wrecked stores", 2)
    scour_hole(se, "Flooded scour", 3)

    spec(z, HZ)
    return z


F = 340  # the flanks' outer x
X1 = 214  # their inner x
G = 150  # the gullies' x
CH = 104  # the centre's chutes' x


def sector(HZ, flank_rows, scour_rows, mound_rows, centre_rows):
    """The ways a crossing is made of, in the zone's numbers (z).

    West (-1) and east (+1) sectors each have a flank (switchbacks down the side of the hull to
    the stern), then either the gully (from a scupper at the stern down x +-G, into the scour's
    rows) or the mound rows (a second set of switchbacks). The centre is the hatch through the
    hull, then switchbacks down the middle. A crossing's paths keep to their own sectors, so
    none is a way across to another: only the single-path crossing wanders."""
    DM = HZ + 22

    def flank(s):
        pts = [(s * F, 0)]
        x = F
        for zz in flank_rows:
            pts += [(s * x, zz)]
            x = X1 + F - x
            pts += [(s * x, zz)]
        pts += [(s * x, DM)]
        return pts, x

    def gully(s):
        """Flank, the scupper at the stern, the gully down, the scour's rows, out down x G.
        Returns the points and the barrels' path (from the deck's edge down the gully)."""
        pts, x = flank(s)
        pts += [(s * G, DM), (s * G, scour_rows[0])]
        barrels_path = [(s * G, HZ + 8), (s * G, scour_rows[0] - 8)]
        xx = G
        for i, zz in enumerate(scour_rows):
            if i:
                pts += [(s * xx, zz)]
            xx = F if xx == G else G
            pts += [(s * xx, zz)]
        if xx != G:
            pts += [(s * G, scour_rows[-1])]
        pts += [(s * G, 608)]
        return pts, barrels_path

    def mounds(s, x_in=None):
        """Flank, then the mound rows below it, out down the chute at x 190."""
        pts, x = flank(s)
        x_in = x if x_in is None else x_in
        pts += [(s * x, mound_rows[0])]
        for i, zz in enumerate(mound_rows):
            if i:
                pts += [(s * x, zz)]
            x = X1 + F - x
            pts += [(s * x, zz)]
        pts += [(s * 190, mound_rows[-1]), (s * 190, 608)]
        return pts

    def centre(first=88):
        """Through the hatch, out of the stern, and the switchbacks down the middle."""
        pts = [(-20, 0), (-20, centre_rows[0])]
        x = first
        for i, zz in enumerate(centre_rows):
            if i:
                pts += [(-x, zz)]
            pts += [(x, zz)]
            x = -x
        end = -x  # where the last row ended
        side = 1 if end > 0 else -1
        return pts + [(side * CH, centre_rows[-1]), (side * CH, 608)]

    return flank, gully, mounds, centre, DM


def hatch_through(c, HZ, z_to):
    """Open the hatch passage through the hull's stern: the way to the centre."""
    c.lane([(-20, HZ - 40), (-20, z_to)], width=12)
    c.roof_lane([(-20, 56), (-20, 90)], 12)
    c.roof_lane([(-20, 126), (-20, HZ - 4)], 12)


def scupper(c, s, HZ):
    """The stern's deck edge where a gully starts: broken planking (pits), ribs, the barrels'
    crates stacked ready."""
    DM = HZ + 22
    c.hall(box(s * G, DM, 56, 44))
    c.decor("WreckRibs", at=(s * (G + 20), DM - 10), scale=1.0, yaw=90)
    c.decor("Chain", at=(s * (G - 18), DM + 4), yaw=0)
    c.decor("Crate", at=(s * (G + 14), DM + 10), yaw=30)
    pit(c, (s * (G + 14), DM - 8), True)
    pit(c, (s * (G - 16), DM + 14), False)


def tell(part, x, kind):
    """A tell at the way in: landmarks on the top band."""
    if kind == "anchor":
        part.decor("Anchor", at=(x, 14), yaw=20)
        part.decor("Chain", path=[(x + 14, 8), (x + 30, 16)], count=2)
    elif kind == "crates":
        part.decor("Crate", at=(x, 12), yaw=10)
        part.decor("Crate", at=(x + 12, 20), yaw=60)
    elif kind == "ribs":
        part.decor("WreckRibs", at=(x, 12), scale=1.1, yaw=90)
    else:
        part.decor("Timber", path=[(x - 14, 12), (x + 14, 12)], count=3)


def crossings(z, HZ, flank_rows, scour_rows, mound_rows, centre_rows):
    flank, gully, mounds, centre, DM = sector(HZ, flank_rows, scour_rows, mound_rows, centre_rows)
    to = centre_rows[0]

    # 1: Gully run (2): A the west flank and gully (quick, the barrels coming down it), B the
    #    east mounds (slow, safe).
    c = z.crossing("Gully run", paths=2)
    pts, rolls = gully(-1)
    wide(c, pts)
    scupper(c, -1, HZ)
    barrels(c, rolls)
    narrow(c, mounds(1))
    ford(c, 190, 540)
    tell(c, -300, "anchor")
    tell(c, 300, "timber")

    # 2: Through the hatch (2): A the east gully, B through the hull and down the middle.
    c = z.crossing("Through the hatch", paths=2)
    pts, rolls = gully(1)
    wide(c, pts)
    scupper(c, 1, HZ)
    barrels(c, rolls)
    hatch_through(c, HZ, to)
    path = centre()
    narrow(c, path)
    ford(c, path[-1][0], 540)
    tell(c, 300, "ribs")
    tell(c, -20, "crates")

    # 3: The long gully (1): one way with everything on it: the west flank, across the stern,
    #    the east gully and its scour.
    c = z.crossing("The long gully", paths=1)
    pts, rolls = gully(1)
    west, x = flank(-1)
    wide(c, west)
    wide(c, [west[-1], (G, DM)])
    wide(c, pts[len(flank(1)[0]):])
    scupper(c, 1, HZ)
    barrels(c, rolls)
    c.lane([(G, 540), (G + 36, 540)], width=12)  # a side spur with the scour's ford in it
    ford(c, G + 26, 540)
    c.loot((G + 36, 540), radius=3, weight=1)
    tell(c, -300, "anchor")
    tell(c, -280, "crates")

    # 4: Three ways (3): A the west gully, B the hatch and the middle, C the east mounds.
    c = z.crossing("Three ways", paths=3)
    pts, rolls = gully(-1)
    wide(c, pts)
    scupper(c, -1, HZ)
    barrels(c, rolls)
    hatch_through(c, HZ, to)
    path = centre()
    narrow(c, path)
    ford(c, path[-1][0], 540)
    narrow(c, mounds(1))
    ford(c, 190, 540)
    tell(c, -300, "timber")
    tell(c, 300, "ribs")

    # 5: Scour round (2): A the west mounds, B the east gully.
    c = z.crossing("Scour round", paths=2)
    wide(c, mounds(-1))
    pts, rolls = gully(1)
    narrow(c, pts)
    scupper(c, 1, HZ)
    barrels(c, rolls)
    ford(c, G, 540)
    tell(c, -300, "crates")
    tell(c, 300, "anchor")


def rows_from(z0, last, step=40):
    return list(range(z0, last + 1, step))


def zone4():
    return walled(4, 14, 170, lambda z, HZ: crossings(
        z, HZ, [84, 132], [262, 302], [258, 298, 338, 378, 418], rows_from(214, 454)))


def zone5():
    return walled(5, 16, 200, lambda z, HZ: crossings(
        z, HZ, [84, 126, 168], [310, 350, 390, 430], [288, 328, 368, 408, 448], rows_from(244, 484)))


def zone6():
    return walled(6, 20, 230, lambda z, HZ: crossings(
        z, HZ, [84, 124, 164, 204], [358, 398, 438, 478], [318, 358, 398, 438, 478],
        rows_from(274, 474)))


ZONES = [zone2, zone3, zone4, zone5, zone6]

COMMENT = ("-- Shipwreck Shallows: drawn with the layout kit from tools/kit/plans/shipwreck_shallows.py\n"
           "-- (edit the plan and re-run it, not this file). The card: docs/design/cards/shipwreck-shallows.md.")
write_zones(OUT, [build() for build in ZONES], COMMENT)
