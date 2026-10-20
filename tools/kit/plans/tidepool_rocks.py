"""Tidepool Rocks (docs/design/cards/tidepool-rocks.md): flat benches of dark rock stepping down
the beach, pocked with pools full of life; the pools keep their water after the sea goes.

Zones 1 to 3 are open sand (no walls, no rock, nothing taller than the zone's limit): a bench is
a flat-topped slate-coloured bank across the beach with pools in its top (the frame), and each
crossing's cart Ramp is a sand gully cut through every bench, so a cart winds from gully to gully
while someone on foot just climbs the benches and wades the pools (a bench's flanks are too
steep for a cart, not for feet). The pools slow you (gentle: nothing deadly, a common biome).

Zone 4 is walled: slate walls and two winding ways down, each in its own half of the beach. The
cart way is the gully (20 wide) and goes the long way round; the foot way is narrower, shorter,
and steps up over low ledges and wades pool to pool. Side pools open off the top and bottom bands.
Two crossings: the gully is in the east, or in the west.

Run:  python3 tools/kit/quick.py <zone> Biomes/Planned/TidepoolRocks --plan tools/kit/plans/tidepool_rocks.py
"""

from kit import Zone, near_path, write_zones

OUT = "src/shared/Layouts/Biomes/Planned/TidepoolRocks.luau"
COMMENT = (
    "-- Tidepool Rocks (planned): rock benches pocked with pools, drawn with the layout kit from\n"
    "-- tools/kit/plans/tidepool_rocks.py. Edit that plan and run it again, not this file.\n"
    "-- Zones 1 to 3: open sand, low benches across the beach with a cart gully through each (a\n"
    "-- walker climbs the benches). Zone 4: walled slate, a cart gully and a quicker foot way."
)

WOBBLE = [0, 6, -4, 8, -7, 3, -5, 7, -2]


# ---- helpers: the rocks' vocabulary -------------------------------------------------------------
def bench(part, zc, depth, height, rw, shift=0, x0=-370, x1=370):
    """A bench: a flat-topped slate bank, its edges worn irregular. It is three overlapping banks
    side by side (each `rw` wide), so its top is broad and level and its two faces steep (a cart
    can't climb them, a walker can). x0 to x1: how far it runs (right across the beach, or a part)."""
    n = max(2, round((x1 - x0) / 92.5) + 1)
    xs = [x0 + (x1 - x0) * i / (n - 1) for i in range(n)]
    gap = (depth - rw) / 2
    for off in (-gap, 0, gap):
        part.ridge([(x, zc + off + WOBBLE[(i + shift) % 9] * 0.5) for i, x in enumerate(xs)],
                   height=height, width=rw, rough=2)
    part.add(Kind="Paint", Path=[[x, zc + WOBBLE[(i + shift) % 9] * 0.5] for i, x in enumerate(xs)],
             Width=depth, Material="Slate", Rough=2)
    part.decor("Rocks", path=[(x, zc) for x in xs], count=max(2, n - 1), scale=0.8)


def pool_on_bench(part, at, radius, depth):
    """A pool in a bench's top: a round dip of drowned silt, weed and shells in it, life at its rim."""
    part.hollow(at, radius=radius, depth=depth, material="Limestone")
    x, z = at
    r = radius - 3
    part.decor("Weed", area=[(x - r, z - r), (x + r, z - r), (x + r, z + r), (x - r, z + r)], count=4)
    part.decor("Starfish", at=(x - r, z + 1))
    part.decor("Urchins", at=(x + r, z - 1))


def slow_pools(part, pools, ramp):
    """Wading the pools slows you; the gully's ramp is kept clear so a cart is never held."""
    for at, r in pools:
        if not near_path(ramp, at[0], at[1], 8 + r + 8):
            part.hazard("Slow", at=at, radius=r - 1)


def gully(part, gaps, benches, width=16):
    """The cart route: straight through each bench at its gully, slanting across the sand between."""
    pts = [(gaps[0], 0)]
    for g, (zc, depth) in zip(gaps, benches):
        pts += [(g, zc - depth / 2 - 18), (g, zc + depth / 2 + 18)]
    pts.append((gaps[-1], 608))
    part.ramp(pts, width=width)
    return pts


# ---- zones 1 to 3: open sand --------------------------------------------------------------------
# Per zone: the height limit (benches just under it), each bench (centre z, depth), the pools in
# them (centre, radius), loot (the deepest is the best), the entrance, and each crossing: its
# name, its gully through each bench, and its tell at the way in.
OPEN = {
    # Zone 1 may not hide the beach from the top (a bank right across it would), so its crossings
    # are tide channels, dark with silt, with short benches beside them.
    1: dict(
        name="Shopside Shore", h=2.4, band=16, benches=[], channels=[170, 400],
        pieces=[(110, 30, -340, -220), (250, 30, 200, 320), (470, 30, -300, -180)],
        pools=[((-250, 172), 10), ((-110, 170), 9), ((70, 168), 10), ((240, 172), 9),
               ((-260, 402), 10), ((-70, 398), 9), ((120, 404), 10), ((270, 400), 9)],
        loot=[((-250, 172), 1), ((240, 172), 1), ((270, 400), 2), ((-70, 398), 4)],
        entrance=(-250, 290),
        crossings=[("Starfish gully", (-150, 150), "Starfish"),
                   ("Urchin gully", (150, -130), "Urchins"),
                   ("Shell gully", (0, 210), "Shells")],
    ),
    2: dict(
        name="Sunny Stretch", h=4.6, band=20, benches=[(210, 44), (350, 44), (490, 44)],
        channels=[], pieces=[],
        pools=[((-270, 212), 11), ((-90, 210), 10), ((90, 208), 11), ((260, 212), 10),
               ((-260, 352), 11), ((-60, 348), 10), ((140, 352), 11), ((290, 348), 10),
               ((-250, 492), 11), ((-70, 488), 10), ((110, 492), 11), ((270, 488), 10)],
        loot=[((-270, 212), 1), ((290, 348), 2), ((-60, 348), 2), ((270, 488), 4)],
        entrance=(-60, 280),
        crossings=[("Starfish gully", (-140, 100, -90), "Starfish"),
                   ("Urchin gully", (180, -80, 110), "Urchins"),
                   ("Shell gully", (-30, 200, 20), "Shells")],
    ),
    3: dict(
        name="Middle Banks", h=6.4, band=28, benches=[(200, 62), (340, 62), (480, 62)],
        channels=[], pieces=[],
        pools=[((-280, 202), 12), ((-100, 200), 11), ((80, 198), 12), ((270, 202), 11),
               ((-270, 342), 12), ((-70, 338), 11), ((150, 342), 12), ((300, 338), 11),
               ((-260, 482), 12), ((-60, 478), 11), ((120, 482), 12), ((280, 478), 11)],
        loot=[((-280, 202), 1), ((300, 338), 2), ((-70, 338), 2), ((280, 478), 4)],
        entrance=(40, 410),
        crossings=[("Starfish gully", (-150, 110, -100), "Starfish"),
                   ("Urchin gully", (170, -120, 140), "Urchins"),
                   ("Shell gully", (-20, 210, 10), "Shells")],
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
    for i, (zc, depth) in enumerate(s["benches"]):
        bench(f, zc, depth, s["h"], s["band"], shift=i * 3 + n)
    for i, zt in enumerate(s["channels"]):
        line = [(-370 + 92.5 * k, zt + WOBBLE[(k + i * 3 + n) % 9]) for k in range(9)]
        f.channel(line, depth=3, width=14, rough=2, material="Limestone")
        f.decor("Rocks", path=[(x, zz - 14) for x, zz in line], count=6, scale=0.8)
    for zc, depth, x0, x1 in s["pieces"]:
        bench(f, zc, depth, s["h"], 14, shift=n, x0=x0, x1=x1)
    for at, r in s["pools"]:
        pool_on_bench(f, at, r, depth=3)
    for at, weight in s["loot"]:
        f.loot(at, radius=8, weight=weight)
    # The entrance: a blowhole in the rocks, on flat sand at a bench's foot, rimmed with rock.
    ex, ez = s["entrance"]
    f.entrance((ex, ez))
    f.decor("Rocks", at=(ex + 14, ez - 8), scale=1.8, yaw=30)
    f.decor("Rocks", at=(ex - 14, ez + 8), scale=1.5, yaw=110)
    f.decor("Barnacles", at=(ex, ez + 16))
    f.decor("Shells", area=[(ex - 20, ez - 20), (ex + 20, ez - 20), (ex + 20, ez + 20), (ex - 20, ez + 20)],
            count=3)
    # Scatter in the gullies between, so no stretch is bare.
    f.decor("Pebbles", area=[(-330, 20), (330, 20), (330, 70), (-330, 70)], count=10)
    f.decor("Shells", area=[(-330, 240), (330, 240), (330, 330), (-330, 330)], count=10)
    f.decor("Starfish", area=[(-300, 540), (300, 540), (300, 600), (-300, 600)], count=5)
    crosses = s["benches"] or [(zt, 14) for zt in s["channels"]]
    for k, (name, gaps, tell) in enumerate(s["crossings"], 1):
        c = z.crossing(name, paths=1)
        ramp = gully(c, gaps, crosses)
        clear_of_pools(n, ramp)
        slow_pools(c, s["pools"], ramp)
        # The tell, at the way in: beside the first gully.
        gx = gaps[0]
        c.decor(tell, at=(gx + 26, 22), scale=1.2, yaw=40 * k)
        c.decor("Rocks", at=(gx - 24, 30), scale=1.3, yaw=100 * k)
    return z


# ---- zone 4: walled ----------------------------------------------------------------------------
ROCK = 12  # slate walls, too tall to see over or jump


def ledge(part, x, z, along="x"):
    """A low ledge of rock across a lane: too steep for a cart, a step up on foot."""
    if along == "x":
        part.ridge([(x, z - 8), (x, z + 8)], height=3, width=12, rough=0)
    else:
        part.ridge([(x - 8, z), (x + 8, z)], height=3, width=12, rough=0)
    part.decor("Rocks", at=(x, z), scale=0.7, yaw=45)


def pool(part, at, radius=8, depth=2):
    """A pool in the lane, life in it: wading slows you."""
    part.hollow(at, radius=radius, depth=depth, material="Limestone")
    part.hazard("Slow", at=at, radius=radius - 1)
    part.decor("Weed", at=(at[0] + 2, at[1] + 2))
    part.decor("Starfish", at=(at[0] - radius + 2, at[1]))


def way(part, cart, foot, ledges, cart_pool, foot_pools, tell, loots):
    """A crossing: the cart's gully (lane 20, ramp 16) and the foot way (lane 12, ledges, pools)."""
    part.lane(cart, width=20)
    part.ramp(cart, width=16)
    part.lane(foot, width=12)
    for x, zz, along in ledges:
        ledge(part, x, zz, along)
    pool(part, cart_pool, radius=10, depth=1)
    for at in foot_pools:
        pool(part, at)
    for kind, at, scale in tell:
        part.decor(kind, at=at, scale=scale, yaw=at[0] % 160)
    for at, weight in loots:
        part.loot(at, radius=6, weight=weight)


def side_pool(slot, name, loot_weight, big=False):
    """A sheltered pool room: its water in the middle, finds at the heart of it."""
    w, d = slot.size
    r = slot.room(name)
    r.hall([(8, 8), (w - 8, 8), (w - 8, d - 8), (8, d - 8)])
    r.hollow((w / 2, d / 2), radius=14 if big else 11, depth=2, material="Limestone")
    r.decor("Weed", at=(w / 2, d / 2))
    r.decor("Starfish", at=(w / 2 + 12, d / 2 - 6))
    r.loot((w / 2, d / 2), radius=6, weight=loot_weight)
    return r


def zone4():
    z = Zone(4, "Outer Shore", rock=ROCK, material="Slate")
    f = z.frame
    # The top and bottom bands: every path starts and ends in them; the side pools open onto them.
    f.hall([(-360, -12), (360, -12), (360, 20), (-360, 20)])
    f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])
    f.decor("Pebbles", area=[(-340, 4), (340, 4), (340, 16), (-340, 16)], count=8)
    f.decor("Shells", area=[(-340, 598), (340, 598), (340, 614), (-340, 614)], count=6)
    # The blowhole court: a hole in the rocks off the top band, rimmed with barnacles.
    f.hall([(-32, 20), (32, 20), (32, 68), (-32, 68)])
    f.entrance((0, 48))
    f.hollow((0, 48), radius=6, depth=1, material="Basalt")
    f.decor("Rocks", at=(-18, 40), scale=1.4, yaw=20)
    f.decor("Rocks", at=(20, 58), scale=1.2, yaw=110)
    f.decor("Barnacles", at=(0, 62))
    f.decor("Urchins", at=(-22, 60))

    # Sheltered pools in the benches: two off the top band, one at the sea end (the best find).
    s = z.slot("West shelter", at=(-340, 36), size=(80, 60), door=(40, 0))
    side_pool(s, "Round pool", 2)
    r = s.room("Ledge and lure")
    r.hall([(8, 8), (72, 8), (72, 52), (8, 52)])
    r.decor("Rocks", area=[(14, 14), (66, 14), (66, 46), (14, 46)], count=3)
    r.decor("Barnacles", at=(40, 20))
    r.loot((40, 36), radius=6, weight=1)
    s = z.slot("East shelter", at=(276, 36), size=(80, 60), door=(40, 0))
    side_pool(s, "Twin pool", 2)
    r = s.room("Overhang")
    r.hall([(8, 8), (72, 8), (72, 52), (8, 52)], roof=True, pillars=[(40, 30)])
    r.decor("Urchins", at=(20, 40))
    r.loot((24, 40), radius=6, weight=1)
    s = z.slot("Deep shelter", at=(-40, 524), size=(80, 52), door=(40, 52))
    side_pool(s, "Deep pool", 5, big=True)
    r = s.room("Crack and pool")
    r.hall([(8, 8), (72, 8), (72, 44), (8, 44)])
    r.hollow((26, 26), radius=9, depth=2, material="Limestone")
    r.decor("Weed", at=(26, 26))
    r.loot((54, 26), radius=6, weight=4)

    # Crossing 1: the cart gully in the east, the foot way in the west.
    c = z.crossing("East gully", paths=2)
    way(c,
        cart=[(80, 0), (80, 150), (280, 150), (280, 320), (80, 320), (80, 470), (280, 470),
              (280, 608)],
        foot=[(-80, 0), (-80, 140), (-280, 140), (-280, 330), (-80, 330), (-80, 608)],
        ledges=[(-190, 140, "x"), (-150, 330, "x"), (-80, 470, "z")],
        cart_pool=(180, 320), foot_pools=[(-250, 235), (-80, 400), (-80, 540)],
        tell=[("Starfish", (104, 12), 1.4), ("Rocks", (60, 14), 1.4)],
        loots=[((200, 470), 1), ((-280, 260), 3)])
    # Crossing 2: the cart gully in the west, the foot way in the east.
    c = z.crossing("West gully", paths=2)
    way(c,
        cart=[(-80, 0), (-80, 140), (-280, 140), (-280, 300), (-80, 300), (-80, 460),
              (-280, 460), (-280, 608)],
        foot=[(80, 0), (80, 150), (280, 150), (280, 330), (80, 330), (80, 608)],
        ledges=[(190, 150, "x"), (150, 330, "x"), (80, 470, "z")],
        cart_pool=(-180, 300), foot_pools=[(250, 240), (80, 400), (80, 540)],
        tell=[("Urchins", (-104, 12), 1.4), ("Rocks", (-60, 14), 1.4)],
        loots=[((-200, 460), 1), ((280, 260), 3)])
    return z


write_zones(OUT, [open_zone(1), open_zone(2), open_zone(3), zone4()], COMMENT)
