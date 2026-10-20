"""Seagrass Shallows, a biome rolling in zones 1 to 4 (docs/design/cards/seagrass-shallows.md).

Low green flats cut by shallow channels that flood in stages, and a collapsed jetty as the
landmark (its entrance is under the jetty). Gentle: tangling seagrass patches (Slow) are the only
danger, and they are easy to step round.

Run it with the quick check, once per zone:
    python3 tools/kit/quick.py 1 Biomes/SeagrassShallows --plan tools/kit/plans/seagrass_shallows.py

Zones 1 to 3 are open sand (no walls, no rock, banks no taller than the zone allows):
  the frame is two low banks across the zone (carts can't climb them, feet can: the shortcuts),
  three channels (they flood one after another as the sea comes in) and the jetty. A crossing
  is the cart's ramp, which clears a gap through every bank and channel it meets, wiggling from
  one gap to the next so that walking over the banks is quicker, plus its seagrass patches and a
  tell at its way in.
Zone 4 is walled: two crossings, each with a cart path round the channels and a foot path
  through them (fords carts can't take), two pockets off the ways through for loot.

The map of zones 1 to 3 (zone coordinates, x -360 west to 360 east, z 0 top to 608 sea):

    z   0  ===== top ======
      110  ~~~~~~~~ channel ~~~~~~~~
      190  ======== bank ========   (gaps where the ramp passes)
      300  ~~~~~~~~ channel ~~~~~~~~       [jetty and its entrance, beside the middle channel]
      410  ======== bank ========
      510  ~~~~~~~~ channel ~~~~~~~~
      608  ===== bottom ==
"""

from kit import Zone, write_zones, segment_box, rounded

OUT = "src/shared/Layouts/Biomes/SeagrassShallows.luau"
NAME = "Seagrass Shallows"
MUD = "Mud"


# ---- helpers: the biome's vocabulary -----------------------------------------------------------
def box(cx, cz, w, d):
    return [(cx - w / 2, cz - d / 2), (cx + w / 2, cz - d / 2), (cx + w / 2, cz + d / 2),
            (cx - w / 2, cz + d / 2)]


def meadow(part, cx, cz, w=80, d=60, count=10):
    """A stand of seagrass: weed over an area, a few shells in it."""
    part.paint(box(cx, cz, w, d), "LeafyGrass")
    part.decor("Weed", area=box(cx, cz, w, d), count=count)
    part.decor("Shells", area=box(cx, cz, w * 0.6, d * 0.6), count=2)


def patch(part, at, radius=10):
    """Tangling seagrass: slows you, easy to step round. Weed growing thick marks it."""
    part.hazard("Slow", at=at, radius=radius)
    part.decor("Weed", area=box(at[0], at[1], radius * 1.6, radius * 1.6), count=7)


def jetty(part, x, z0, z1, side=8):
    """The collapsed jetty: a line of planks fallen along the channel, two rows of posts leaning
    either side, more planks flung about."""
    part.decor("Timber", path=[(x, z0), (x, z1)], count=9)
    for s in (-side, side):
        part.decor("Timber", path=[(x + s, z0 + 6), (x + s, z1 - 6)], count=5, scale=1.5, yaw=90)
    part.decor("Timber", area=box(x, (z0 + z1) / 2, 50, z1 - z0), count=6)
    part.decor("Chain", at=(x + 14, z1 - 10), yaw=40)
    part.decor("Crate", at=(x - 16, z0 + 14), yaw=20)


def pocket(part, at, weight, radius=10, depth=2):
    """A pool in the grass with a find in it."""
    part.hollow(at, radius=radius, depth=depth, rough=2, material=MUD)
    part.loot(at, radius=5, weight=weight)
    part.decor("Weed", area=box(at[0], at[1], radius * 2.4, radius * 2.4), count=6)


# ---- zones 1 to 3: open sand --------------------------------------------------------------------
def shore(n, name, hmax, bank_w, depth, jx, loot_at, tide_z=(110, 300, 510), bank_z=(190, 410),
          chan_w=14):
    """One open zone. `hmax`: the banks' height (the zone's limit, with a little under it)."""
    z = Zone(n, name, rock=0)
    f = z.frame

    # The banks across the zone: carts climb no steeper than 0.35, feet 0.9 (the shortcuts).
    # (Zone 1 has none: even a low bank hides too much of the zone from the top, so its
    # barriers to carts are narrow steep-sided channels, which feet step down and up.)
    for i, zb in enumerate(bank_z if hmax else ()):
        k = 1 if i == 0 else -1
        f.ridge([(-364, zb), (-180, zb + 8 * k), (0, zb - 6 * k), (180, zb + 8 * k), (364, zb)],
                height=hmax, width=bank_w, rough=1)

    # The channels: shallow cuts across the zone that flood one after another as the sea comes in.
    for i, zc in enumerate(tide_z):
        k = 1 if i % 2 == 0 else -1
        f.channel([(-364, zc), (-200, zc + 10 * k), (-40, zc - 8 * k), (120, zc + 10 * k),
                   (364, zc - 4 * k)], depth=depth, width=chan_w, rough=1, material=MUD)
        f.decor("Kelp", path=[(-330, zc + 12), (330, zc - 4)], count=5)

    # The jetty, fallen along the middle channel; its entrance is under the end of it.
    z0, z1 = tide_z[1] - 60, tide_z[1] + 40
    jetty(f, jx, z0, z1)
    f.add(Kind="Flat", At=[jx, z1 + 24], Radius=9)
    f.entrance((jx, z1 + 24))
    f.decor("Starfish", at=(jx + 10, z1 + 34))

    # Seagrass meadows in the flats between, the zone's green.
    for cx, cz in ((-240, 60), (190, 55), (-80, 150), (260, 250), (-250, 350), (60, 360),
                   (-120, 460), (250, 460), (-40, 560), (200, 570)):
        meadow(f, cx, cz)
    f.decor("Pebbles", area=box(0, 304, 700, 40), count=6)
    f.decor("Driftwood", area=box(0, 304, 700, 80), count=4)
    f.decor("Shells", area=box(0, 560, 700, 80), count=6)

    # Finds: under the jetty, in pockets in the grass, the best deepest (far side, last bank).
    f.loot((jx, z1 - 14), radius=6, weight=2)
    for i, (at, w) in enumerate(loot_at):
        pocket(f, at, w)
    return z


def crossing(z, name, start, g1, mid, g2, end, tell, patches, paths=1):
    """The cart's ramp: down from `start` (x on the top edge) through the gap `g1` in the first
    bank, `mid`, the gap `g2` in the second bank, out at `end`. Straight down over the banks is
    quicker on foot."""
    c = z.crossing(name, paths=paths)
    bank1, bank2 = 190, 410
    c.ramp([(start, 0), (start, 70), (g1, bank1 - 20), (g1, bank1 + 25), (mid, 300),
            (g2, bank2 - 30), (g2, bank2 + 25), ((g2 + end) / 2, 520), (end, 608)], width=16)
    for at in patches:
        patch(c, at)
    # The tell at the way in: a heap of timber and a net buoy-chain, different at each.
    tell(c)
    return c


def tell_posts(x):
    def tell(c):
        c.decor("Timber", path=[(x - 20, 14), (x + 20, 14)], count=3, scale=1.4, yaw=90)
        c.decor("Weed", at=(x, 26), scale=1.4)
    return tell


def tell_chain(x):
    def tell(c):
        c.decor("Chain", at=(x, 16), yaw=60)
        c.decor("Crate", at=(x + 14, 10), yaw=30)
    return tell


def tell_kelp(x):
    def tell(c):
        c.decor("Kelp", path=[(x - 16, 14), (x + 16, 14)], count=3, scale=1.3)
        c.decor("Starfish", at=(x, 28))
    return tell


def zone1():
    z = shore(1, NAME, hmax=None, bank_w=0, depth=2.4, jx=-70, chan_w=8,
              tide_z=(110, 200, 300, 410, 510),
              loot_at=[((-290, 250), 1), ((280, 350), 2), ((-230, 480), 3), ((300, 556), 4)])
    crossing(z, "Seagrass trail", 0, -140, -30, 140, 0, tell_posts(0),
             [(-70, 130), (60, 262), (110, 470)])
    crossing(z, "Reed track", -150, 130, 40, -130, -20, tell_chain(-150),
             [(120, 120), (-60, 340), (-130, 540)])
    crossing(z, "Mud-flat way", 150, -60, -150, 70, 130, tell_kelp(150),
             [(30, 60), (-120, 250), (80, 470)])
    return z


def zone2():
    z = shore(2, NAME, hmax=4.4, bank_w=14, depth=3, jx=90,
              tide_z=(70, 300, 510), loot_at=[((-300, 240), 1), ((-60, 360), 2), ((250, 470), 3), ((-290, 560), 4)])
    # The pier runs along x 40 over the zone's first 150 studs: its path kept clear (the
    # channel passes under it).
    z.frame.add(Kind="Flat", Area=[[32, 0], [48, 0], [48, 156], [32, 156]])
    crossing(z, "Seagrass trail", 0, 140, 20, -140, 0, tell_posts(0),
             [(-80, 140), (-60, 270), (100, 480)])
    crossing(z, "Reed track", 140, -130, -50, 130, 20, tell_chain(140),
             [(-100, 100), (130, 330), (-110, 560)])
    crossing(z, "Mud-flat way", -150, 60, 150, -70, -120, tell_kelp(-150),
             [(-30, 60), (210, 250), (-30, 480)])
    return z


def zone3():
    z = shore(3, NAME, hmax=6.4, bank_w=18, depth=3, jx=-110,
              tide_z=(60, 300, 510), loot_at=[((290, 230), 1), ((60, 350), 2), ((-260, 470), 3), ((280, 560), 4)])
    crossing(z, "Seagrass trail", 0, 140, 0, -140, 0, tell_posts(0),
             [(-120, 140), (120, 260), (60, 480)])
    crossing(z, "Reed track", -140, 140, 60, -120, 40, tell_chain(-140),
             [(-90, 110), (-30, 340), (110, 560)])
    crossing(z, "Mud-flat way", 140, -40, -140, 60, 140, tell_kelp(140),
             [(60, 60), (150, 260), (-60, 470)])
    return z


# ---- zone 4: walled, winding ---------------------------------------------------------------------
ROCK = 10  # walls you can't see over, but low: this is still the shallows


def serpentine(top_x, far_x, rows, last_x=None):
    """A snake down the zone: from the top at `top_x`, along each row from one side to the other,
    out at the bottom at the last side."""
    pts = [(top_x, 0)]
    here = top_x
    for zr in rows:
        pts.append((here, zr))
        here = far_x if here == top_x else top_x
        pts.append((here, zr))
    pts.append((here, 608))
    return pts


def bulge(part, at, tangle):
    """A wider stretch of a lane where the grass has taken over: a patch of tangling seagrass
    to one side that is easy to step round."""
    x, zz = at
    part.hall(box(x, zz, 48, 44))
    patch(part, (x + tangle, zz), radius=8)


def ford_way(part, pts, fords):
    """The foot way through the channels: a lane 12 wide with a ditch along the stretches in
    `fords` (segment indexes), floods first, carts can't cross."""
    part.lane(pts, width=12)
    for i in fords:
        a, b = pts[i], pts[i + 1]
        part.channel([a, b], depth=3, width=10, rough=0, material=MUD)
        part.decor("Kelp", path=[a, b], count=3)


def dead_end(part, pts, weight):
    part.lane(pts, width=12)
    part.loot(pts[-1], radius=5, weight=weight)
    part.decor("Weed", area=box(*pts[-1], 24, 24), count=4)


def pocket_room(slot, name, weight, kind):
    """A pocket off the ways through, in the slot's own coordinates (72 wide, 96 deep)."""
    r = slot.room(name)
    if kind == "pool":
        r.hall([(8, 8), (64, 8), (64, 88), (8, 88)])
        r.hollow((36, 64), radius=10, depth=2, material=MUD)
        r.loot((36, 64), radius=5, weight=weight)
        r.decor("Weed", area=box(36, 48, 48, 72), count=8)
    elif kind == "nets":
        r.hall([(8, 8), (64, 8), (64, 88), (8, 88)], pillars=[(36, 48)])
        r.loot((20, 76), radius=5, weight=weight)
        r.decor("Crate", area=box(36, 48, 40, 70), count=3)
        r.decor("Chain", at=(24, 20), yaw=70)
    elif kind == "pier":
        r.hall([(8, 8), (64, 8), (64, 88), (8, 88)])
        r.decor("Timber", path=[(36, 12), (36, 84)], count=6)
        r.loot((36, 80), radius=5, weight=weight)
    else:  # cove: a silted corner with a find in the mud
        r.hall([(8, 8), (64, 8), (64, 88), (8, 88)])
        r.hollow((22, 24), radius=9, depth=3, material=MUD)
        r.loot((22, 24), radius=5, weight=weight)
        r.decor("Kelp", area=box(40, 50, 40, 60), count=4)
    return r


def zone4():
    z = Zone(4, NAME, rock=ROCK)
    f = z.frame

    # The bands every path starts and ends in.
    f.hall([(-260, -12), (260, -12), (260, 24), (-260, 24)], floor="LeafyGrass")
    f.hall([(-260, 584), (260, 584), (260, 620), (-260, 620)], floor="LeafyGrass")
    f.decor("Weed", area=box(0, 6, 480, 24), count=10)
    f.decor("Shells", area=box(0, 600, 480, 24), count=6)

    # The jetty court: the collapsed jetty lies across a flooded court in the middle; the entrance
    # is under it. Both crossings can reach it by a spur from the middle row.
    f.hall(box(0, 312, 96, 80), floor="LeafyGrass")
    jetty(f, 0, 280, 340)
    f.hollow((0, 330), radius=8, depth=2, material=MUD)
    f.entrance((0, 322))
    f.decor("Starfish", at=(-24, 340))
    f.loot((0, 322), radius=6, weight=2)

    # Two pockets off the ways through, one each side; a stub of lane leads to each door.
    west = z.slot("Grass pockets", at=(-360, 102), size=(72, 96), door=(72, 48))
    pocket_room(west, "Reed pocket", 3, "pool")
    pocket_room(west, "Silted cove", 4, "cove")
    f.lane([(-272, 150), (-224, 150)], width=12)
    east = z.slot("Jetty cellars", at=(288, 140), size=(72, 96), door=(0, 48))
    pocket_room(east, "Net store", 3, "nets")
    pocket_room(east, "Under the pier", 4, "pier")
    f.lane([(272, 188), (224, 188)], width=12)

    # ---- crossing 1: Reed maze ---------------------------------------------------------------
    # A: the cart path, a long snake down the east side, round the channels.
    # B: the foot path down the west side, through the channel ditches (quicker while they're dry).
    # Link: the court, between the two middle rows.
    c = z.crossing("Reed maze", paths=2)
    a = serpentine(96, 224, [100, 200, 300, 400, 500])
    c.ramp(a, width=16)
    b = serpentine(-96, -224, [148, 300, 448])
    ford_way(c, b, fords=[1, 5])
    c.lane([(96, 300), (48, 300)], width=12)
    c.lane([(-96, 300), (-48, 300)], width=12)
    dead_end(c, [(224, 352), (292, 352)], 2)
    bulge(c, (160, 100), 8)
    bulge(c, (160, 300), -8)
    bulge(c, (160, 500), 8)
    bulge(c, (-160, 448), -8)
    c.decor("Timber", path=[(88, 14), (104, 14)], count=3, scale=1.4, yaw=90)  # the tell
    c.decor("Weed", at=(96, 28), scale=1.4)
    c.decor("Kelp", path=[(-104, 14), (-88, 14)], count=2, scale=1.3)

    # ---- crossing 2: Net rows -------------------------------------------------------------------
    # A: the cart path, now down the west side. B: the foot path through the ditches in the east.
    c = z.crossing("Net rows", paths=2)
    a = serpentine(-96, -224, [92, 188, 300, 412, 508])
    c.ramp(a, width=16)
    b = serpentine(96, 224, [132, 300, 468])
    ford_way(c, b, fords=[1, 5])
    c.lane([(-96, 300), (-48, 300)], width=12)
    c.lane([(96, 300), (48, 300)], width=12)
    dead_end(c, [(-224, 352), (-292, 352)], 2)
    bulge(c, (-160, 92), -8)
    bulge(c, (-160, 300), 8)
    bulge(c, (-160, 508), -8)
    bulge(c, (160, 468), 8)
    c.decor("Chain", at=(-96, 16), yaw=60)  # the tell: a net's chain and a crate at the way in
    c.decor("Crate", at=(-84, 10), yaw=30)
    c.decor("Chain", at=(96, 16), yaw=100)
    return z


COMMENT = ("-- Seagrass Shallows (planned): drawn with the layout kit from tools/kit/plans/seagrass_shallows.py\n"
           "-- (edit the plan and re-run it, not this file). The card: docs/design/cards/seagrass-shallows.md.")
write_zones(OUT, [zone1(), zone2(), zone3(), zone4()], COMMENT)
