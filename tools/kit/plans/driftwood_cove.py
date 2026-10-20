"""Driftwood Cove (docs/design/cards/driftwood-cove.md): a log jam. The sea has piled whole trees
across the beach; you thread the gaps, climb the low logs, and the water pools behind them.

Zones 1 to 3 are open sand (no walls, no rock, nothing taller than the zone's limit): the jams
are long low banks across the beach (the frame), and each crossing's cart Ramp cuts one wide gap
through every jam, so a cart zigzags from gap to gap while someone on foot simply climbs the logs
(a jam's flanks are too steep for a cart, not for feet). Dips behind the jams hold water and slow
you (gentle: nothing deadly here, it is a common biome by the shop).

Zone 4 is walled: weathered grey drift-rock and two winding ways down, each in its own half of
the beach. The cart way is 20 wide and goes the long way round; the foot way is narrower,
shorter, and climbs over low log stacks lying across its lane. Side hollows open off the top and
bottom bands. Two crossings: the cart way is in the west, or in the east.

Run:  python3 tools/kit/quick.py <zone> Biomes/DriftwoodCove --plan tools/kit/plans/driftwood_cove.py
"""

from kit import Zone, near_path, write_zones

OUT = "src/shared/Layouts/Biomes/DriftwoodCove.luau"
COMMENT = (
    "-- Driftwood Cove (planned): a log jam, drawn with the layout kit from\n"
    "-- tools/kit/plans/driftwood_cove.py. Edit that plan and run it again, not this file.\n"
    "-- Zones 1 to 3: open sand, low jams across the beach with a cart gap in each (a walker\n"
    "-- climbs the logs). Zone 4: walled drift-rock, a cart way and a quicker foot-only way."
)


# ---- helpers: the cove's vocabulary ------------------------------------------------------------
WOBBLE = [0, 7, -5, 9, -8, 4, -6, 8, -3]


def jam_line(z, shift=0):
    """The centre line of a jam across the beach: a gently wandering line of logs."""
    return [(-370 + 90 * i, z + WOBBLE[(i + shift) % len(WOBBLE)]) for i in range(9)]


def jam(part, z, height, width, shift=0):
    """A log jam: a long low bank across the beach, wet dark sand behind it, logs along it."""
    line = jam_line(z, shift)
    part.ridge(line, height=height, width=width, rough=3)
    part.add(Kind="Paint", Path=[[x, zz + width] for x, zz in line], Width=width * 1.6,
             Material="Ground", Rough=3)
    part.decor("Driftwood", path=line, count=14)
    part.decor("Timber", path=line, count=6)
    return line


def stub(part, a, b, height, width):
    """A short stack of logs that doesn't reach across: cover, not a barrier."""
    part.ridge([a, b], height=height, width=width, rough=3)
    part.decor("Driftwood", path=[a, b], count=5)


def dip(part, at, radius=14, depth=2):
    """Water pooling behind a jam: a dip in wet sand, shells and weed washed into it."""
    part.hollow(at, radius=radius, depth=depth, material="Ground")
    x, z = at
    r = radius - 4
    part.decor("Weed", area=[(x - r, z - r), (x + r, z - r), (x + r, z + r), (x - r, z + r)], count=4)
    part.decor("Shells", at=(x + r // 2, z - r // 2))


def slow_dips(part, dips, ramp, radius=12):
    """The dips a crossing's cart gap doesn't pass through slow you (wading); the ramp is kept
    clear so a cart is never held."""
    for at, r in dips:
        if not near_path(ramp, at[0], at[1], 8 + r + 8):
            part.hazard("Slow", at=at, radius=min(radius, r))


def danger(part, ramp, pits=(), sinks=()):
    """Open spike pits and quicksand (zones 3 and 4), kept off the cart route."""
    for at in pits:
        if not near_path(ramp, at[0], at[1], 8 + 4 + 8):
            part.hazard("Pit", at=at, radius=4, covered=False)
    for at in sinks:
        if not near_path(ramp, at[0], at[1], 8 + 10 + 6):
            part.hazard("Sink", at=at, radius=10)


def cart_gap(part, gaps, jams, width=16):
    """The cart route: straight through each jam at its gap, slanting between jams."""
    pts = [(gaps[0], 0)]
    for g, zj in zip(gaps, jams):
        pts += [(g, zj - 26), (g, zj + 26)]
    pts.append((gaps[-1], 608))
    part.ramp(pts, width=width)
    return pts


# ---- zones 1 to 3: open sand --------------------------------------------------------------------
# Per zone: its height limit (the jams just under it), the jams' z, stubs, the dips behind the
# jams (centre, radius), loot (the deepest is the best), the entrance, and each crossing: its
# name, its gap in each jam, and the landmark that is its tell at the way in.
OPEN = {
    # Zone 1 may not hide the beach from the top (a low bank would), so its "jams" are dark trenches
    # across the beach, where the water pools behind the logs, with short stacks of logs beside them.
    1: dict(
        name="Shopside Shore", h=2.4, w=14, jams=[], trench=[170, 400],
        stubs=[((-330, 90), (-230, 96)), ((200, 300), (320, 292)), ((-300, 500), (-190, 506))],
        dips=[((-250, 172), 12), ((60, 170), 12), ((240, 402), 12), ((-90, 400), 12)],
        loot=[((-300, 210), 1), ((260, 440), 2), ((-60, 548), 4)],
        entrance=(-270, 290),
        crossings=[("Anchor gap", (-150, 150), "Anchor"),
                   ("Crate gap", (150, -130), "Crate"),
                   ("Chain gap", (0, 210), "Chain")],
    ),
    2: dict(
        name="Sunny Stretch", h=4.6, w=20, jams=[210, 350, 490], trench=[],
        stubs=[((-320, 70), (-220, 76)), ((180, 150), (310, 158)), ((-330, 420), (-200, 414)),
               ((120, 560), (260, 566))],
        dips=[((-270, 248), 16), ((90, 246), 14), ((250, 388), 16), ((-110, 386), 14),
              ((200, 528), 14), ((-250, 530), 16)],
        loot=[((-300, 248), 1), ((270, 388), 2), ((-260, 530), 3), ((230, 552), 4)],
        entrance=(-60, 280),
        crossings=[("Anchor gap", (-140, 100, -90), "Anchor"),
                   ("Crate gap", (180, -80, 110), "Crate"),
                   ("Ribs gap", (-30, 200, 20), "Bones")],
    ),
    3: dict(
        name="Middle Banks", h=6.4, w=26, jams=[200, 340, 480], trench=[],
        stubs=[((-330, 60), (-210, 66)), ((150, 140), (310, 148)), ((-340, 410), (-190, 404)),
               ((100, 560), (270, 568))],
        dips=[((-280, 238), 16), ((80, 236), 14), ((260, 378), 16), ((-90, 376), 14),
              ((210, 518), 14), ((-260, 520), 16)],
        loot=[((-310, 238), 1), ((290, 378), 2), ((-270, 520), 3), ((240, 556), 4)],
        entrance=(40, 410),
        pits=[(-300, 300), (-40, 300), (300, 300), (-230, 440), (40, 440), (290, 440),
              (-20, 570), (220, 570)],
        sinks=[(-190, 285), (190, 280), (-300, 425), (150, 425), (-120, 560), (-300, 570)],
        crossings=[("Anchor gap", (-150, 110, -100), "Anchor"),
                   ("Crate gap", (170, -120, 140), "Crate"),
                   ("Ribs gap", (-20, 210, 10), "Bones")],
    ),
}

# The beach's own rock pools, in each zone's coordinates (x, z, radius): kept clear of by every
# ridge and cart route (tools/tests checks it).
POOLS = {2: [(-280, 20, 9), (140, 120, 12)], 3: [(-60, 130, 10)], 4: [(260, 70, 8)]}


def clear_of_pools(n, ramp, half=8):
    for x, z, r in POOLS.get(n, []):
        assert not near_path(ramp, x, z, r + 2 + half + 1), f"zone {n}: ramp near the pool at {x}, {z}"


def open_zone(n):
    s = OPEN[n]
    z = Zone(n, s["name"], rock=0)
    f = z.frame
    for i, zj in enumerate(s["jams"]):
        jam(f, zj, s["h"], s["w"], shift=i * 3 + n)
    for i, zt in enumerate(s["trench"]):
        line = jam_line(zt, i * 3 + n)
        f.channel(line, depth=3, width=14, rough=2, material="Ground")
        f.decor("Driftwood", path=[(x, zz - 12) for x, zz in line], count=12)
        f.decor("Timber", path=[(x, zz + 12) for x, zz in line], count=5)
    for a, b in s["stubs"]:
        stub(f, a, b, s["h"] * 0.75, s["w"] * 0.8)
    for at, r in s["dips"]:
        dip(f, at, radius=r)
    for at, weight in s["loot"]:
        f.loot(at, radius=8, weight=weight)
    # The entrance: a hollow beached tree trunk on flat sand, boughs round it.
    ex, ez = s["entrance"]
    f.entrance((ex, ez))
    f.decor("Driftwood", at=(ex, ez), scale=3.2, yaw=70)
    f.decor("Timber", at=(ex + 18, ez - 12), scale=1.6, yaw=20)
    f.decor("Driftwood", at=(ex - 16, ez + 14), scale=2, yaw=140)
    # Scatter between the jams, so no stretch is bare.
    f.decor("DuneGrass", area=[(-340, 20), (340, 20), (340, 80), (-340, 80)], count=10)
    f.decor("Pebbles", area=[(-330, 230), (330, 230), (330, 330), (-330, 330)], count=10)
    f.decor("Starfish", area=[(-300, 560), (300, 560), (300, 600), (-300, 600)], count=4)
    crosses = s["jams"] or s["trench"]
    for k, (name, gaps, tell) in enumerate(s["crossings"], 1):
        c = z.crossing(name, paths=1)
        ramp = cart_gap(c, gaps, crosses)
        clear_of_pools(n, ramp)
        slow_dips(c, s["dips"], ramp)
        danger(c, ramp, s.get("pits", ()), s.get("sinks", ()))
        # The tell, at the way in: the landmark beside the first gap.
        gx = gaps[0]
        c.decor(tell, at=(gx + 26, 22), scale=1.2, yaw=40 * k)
        c.decor("Driftwood", at=(gx - 24, 30), scale=1.4, yaw=100 * k)
    return z


# ---- zone 4: walled ----------------------------------------------------------------------------
ROCK = 12  # drift-rock walls, too tall to see over or jump


def log_stack(part, x, z, along="x"):
    """A low stack of logs lying across a lane: too steep for a cart, a scramble on foot."""
    if along == "x":  # the lane runs east-west: the stack lies across it (north-south)
        part.ridge([(x, z - 8), (x, z + 8)], height=3, width=12, rough=0)
    else:
        part.ridge([(x - 8, z), (x + 8, z)], height=3, width=12, rough=0)
    part.decor("Driftwood", at=(x, z), scale=1.1, yaw=90 if along == "x" else 0)


def pool(part, at, radius=9, depth=2):
    """A pool behind the logs, in the lane: wading slows you."""
    part.hollow(at, radius=radius, depth=depth, material="Ground")
    part.hazard("Slow", at=at, radius=radius - 1)
    part.decor("Weed", at=(at[0] + 3, at[1] + 3))


def way(part, cart, foot, stacks, cart_dip, foot_dip, tell, loots):
    """A crossing: the cart's way (lane 20, ramp 16) and the foot way (lane 12, log stacks)."""
    part.lane(cart, width=20)
    part.ramp(cart, width=16)
    part.lane(foot, width=12)
    for x, zz, along in stacks:
        log_stack(part, x, zz, along)
    pool(part, cart_dip, radius=10, depth=1)
    pool(part, foot_dip, radius=8)
    # The foot way, in its long run to the sea: quicksand in the lane (wade it fast, or die) and
    # an open pit beside it, a gap left to squeeze by.
    fx = foot[-1][0]
    part.hazard("Sink", at=(fx, 410), radius=10)
    part.hazard("Pit", at=(fx + (6 if fx > 0 else -6), 540), radius=4, covered=False)
    for kind, at, scale in tell:
        part.decor(kind, at=at, scale=scale, yaw=at[0] % 160)
    for at, weight in loots:
        part.loot(at, radius=6, weight=weight)


def zone4():
    z = Zone(4, "Outer Shore", rock=ROCK, material="Ground")
    f = z.frame
    # The top and bottom bands: every path starts and ends in them; the side hollows open onto them.
    f.hall([(-360, -12), (360, -12), (360, 20), (-360, 20)])
    f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])
    f.decor("DuneGrass", area=[(-340, 4), (340, 4), (340, 16), (-340, 16)], count=8)
    f.decor("Pebbles", area=[(-340, 598), (340, 598), (340, 614), (-340, 614)], count=6)
    # The trunk court: the beached tree whose hollow is the secret's door, off the top band.
    f.hall([(-32, 20), (32, 20), (32, 68), (-32, 68)])
    f.entrance((0, 48))
    f.decor("Driftwood", at=(0, 48), scale=3.4, yaw=80)
    f.decor("Timber", at=(-20, 36), scale=1.5, yaw=30)
    f.decor("Timber", at=(22, 60), scale=1.5, yaw=120)
    f.decor("Shells", area=[(-24, 28), (24, 28), (24, 62), (-24, 62)], count=3)

    # Open spike pits and quicksand in the top and bottom bands, between the ways' ends.
    for x in (-180, 180):
        f.hazard("Pit", at=(x, 4), radius=4, covered=False)
        f.hazard("Sink", at=(x, 602), radius=10)
    f.decor("Bones", at=(-180, 14), scale=0.9, yaw=30)
    f.decor("Bones", at=(180, 14), scale=0.9, yaw=110)

    # Side hollows under the jams: two off the top band, one at the sea end (the best find).
    s = z.slot("West hollow", at=(-340, 36), size=(80, 60), door=(40, 0))
    r = s.room("Under the root-ball")
    r.hall([(8, 8), (72, 8), (72, 52), (8, 52)])
    r.decor("Timber", area=[(14, 14), (66, 14), (66, 46), (14, 46)], count=4)
    r.loot((40, 36), radius=6, weight=2)
    r = s.room("Flooded hollow")
    r.hall([(8, 8), (72, 8), (72, 52), (8, 52)])
    r.hollow((40, 32), radius=14, depth=2, material="Ground")
    r.decor("Weed", at=(40, 32))
    r.loot((40, 32), radius=6, weight=1)
    s = z.slot("East hollow", at=(276, 36), size=(80, 60), door=(40, 0))
    r = s.room("Boot-heap")
    r.hall([(8, 8), (72, 8), (72, 52), (8, 52)])
    r.decor("Crate", at=(30, 34))
    r.decor("Driftwood", at=(52, 24), scale=1.2)
    r.loot((40, 36), radius=6, weight=2)
    r = s.room("Log cave")
    r.hall([(8, 8), (72, 8), (72, 52), (8, 52)], roof=True, pillars=[(40, 30)])
    r.loot((22, 38), radius=6, weight=1)
    s = z.slot("Deep hollow", at=(-40, 524), size=(80, 52), door=(40, 52))
    r = s.room("Silted pool")
    r.hall([(8, 8), (72, 8), (72, 44), (8, 44)])
    r.hollow((40, 26), radius=14, depth=2, material="Ground")
    r.decor("Shells", at=(40, 26))
    r.loot((40, 26), radius=6, weight=5)
    r = s.room("Wedged hull")
    r.hall([(8, 8), (72, 8), (72, 44), (8, 44)])
    r.decor("Timber", area=[(14, 14), (66, 14), (66, 38), (14, 38)], count=4)
    r.loot((40, 26), radius=6, weight=4)

    # Crossing 1: the cart way in the west, the foot way in the east.
    c = z.crossing("West cart way", paths=2)
    way(c,
        cart=[(-80, 0), (-80, 140), (-280, 140), (-280, 300), (-80, 300), (-80, 460),
              (-280, 460), (-280, 608)],
        foot=[(80, 0), (80, 150), (280, 150), (280, 330), (80, 330), (80, 608)],
        stacks=[(200, 150, "x"), (140, 330, "x"), (80, 470, "z")],
        cart_dip=(-180, 300), foot_dip=(260, 240),
        tell=[("Anchor", (-104, 12), 1.2), ("Driftwood", (-60, 14), 1.4)],
        loots=[((-180, 460), 1), ((280, 260), 3)])
    # Crossing 2: the cart way in the east, the foot way in the west.
    c = z.crossing("East cart way", paths=2)
    way(c,
        cart=[(80, 0), (80, 150), (280, 150), (280, 320), (80, 320), (80, 470), (280, 470),
              (280, 608)],
        foot=[(-80, 0), (-80, 130), (-280, 130), (-280, 310), (-80, 310), (-80, 608)],
        stacks=[(-190, 130, "x"), (-140, 310, "x"), (-80, 470, "z")],
        cart_dip=(180, 150), foot_dip=(-260, 220),
        tell=[("Crate", (104, 12), 1.2), ("Chain", (60, 14), 1.0)],
        loots=[((200, 470), 1), ((-280, 250), 3)])
    return z


write_zones(OUT, [open_zone(1), open_zone(2), open_zone(3), zone4()], COMMENT)
