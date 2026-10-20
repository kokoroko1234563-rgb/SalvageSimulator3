"""Fog Bank, a biome rolling in zones 2 to 6 (docs/design/cards/fog-bank.md).

A wall of fog that stays; a foghorn at the lighthouse clears it for a moment (the Fog hazard,
placed at the lighthouse: its behaviour is the engine's). A lantern does nothing against fog.

Run it with the quick check, once per zone:
    python3 tools/kit/quick.py 4 Biomes/FogBank --plan tools/kit/plans/fog_bank.py

Zones 2 and 3 are open dunes (no walls, no rock; sand dunes no taller than the zone allows):
  three low dunes across the zone (carts can't climb them, feet can: the shortcuts), the cart's
  ramp through a gap in each, marker posts and rope lines along it, the lighthouse (decor, with
  its door as the entrance) at the east side.
Zones 4 to 6 are walled with low rock: three bands (west, middle, east), each a snake of lanes
  down the zone. A crossing carves two or three of the bands (one is the cart's ramp, the rest
  foot ways), with a link between two of them. Corners of a snake can have a dead end the fog
  hides; some end in a covered pit under the prize. The foot of the zone is a court with the
  lighthouse (a tall rock) and the entrance at its door. Rope lines run along the safe ways.
"""

import math

from kit import Zone, write_zones

OUT = "src/shared/Layouts/Biomes/FogBank.luau"
NAME = "Fog Bank"
POST = "Timber"
ROPE = "Chain"


# ---- helpers -------------------------------------------------------------------------------------
def box(cx, cz, w, d):
    return [(cx - w / 2, cz - d / 2), (cx + w / 2, cz - d / 2), (cx + w / 2, cz + d / 2),
            (cx - w / 2, cz + d / 2)]


def rope(part, pts, off=9, every=5):
    """A rope line (chain) along a way, to one side, with a marker post at each bend."""
    for (ax, az), (bx, bz) in zip(pts, pts[1:]):
        length = math.hypot(bx - ax, bz - az)
        if length < 24:
            continue
        nx, nz = -(bz - az) / length * off, (bx - ax) / length * off
        n = max(2, min(12, int(length / every / 4)))
        part.decor(ROPE, path=[(ax + nx, az + nz), (bx + nx, bz + nz)], count=n)
    for x, z in pts[1:-1]:
        part.decor(POST, at=(x + off, z + off), scale=1.5)


def posts(part, pts, every=48, off=10):
    """Marker posts every `every` studs along a way."""
    carry = every / 2
    for (ax, az), (bx, bz) in zip(pts, pts[1:]):
        length = math.hypot(bx - ax, bz - az)
        if length < 1:
            continue
        nx, nz = -(bz - az) / length * off, (bx - ax) / length * off
        d = carry
        while d < length:
            t = d / length
            part.decor(POST, at=(round(ax + (bx - ax) * t + nx), round(az + (bz - az) * t + nz)),
                       scale=1.4)
            d += every
        carry = d - length


def bell(part, at):
    """A bell on a post: an anchor and a hanging chain."""
    part.decor("Anchor", at=at, scale=0.8)
    part.decor(ROPE, at=(at[0] + 5, at[1] + 4))


def lighthouse(part, at, scale=4):
    """The landmark: a tower of timber and boulders, an anchor and chain at its foot."""
    x, z = at
    part.decor("Rocks", area=box(x, z, 30, 30), count=5)
    part.decor(POST, at=(x, z), scale=scale, yaw=0)
    part.decor(POST, at=(x + 3, z + 2), scale=scale, yaw=90)
    part.decor("Anchor", at=(x + 12, z + 12))
    part.decor(ROPE, path=[(x - 14, z + 12), (x + 14, z + 14)], count=3)
    part.decor("Pebbles", area=box(x, z, 40, 40), count=4)


def tell(part, x, kind):
    """The tell at a crossing's way in: what stands by the top of its ramp."""
    if kind == 0:
        part.decor(POST, path=[(x - 12, 12), (x + 12, 12)], count=2, scale=1.8)
        part.decor(ROPE, path=[(x - 12, 16), (x + 12, 16)], count=3)
    elif kind == 1:
        bell(part, (x - 10, 14))
        bell(part, (x + 10, 14))
    else:
        part.decor("Driftwood", at=(x, 14), yaw=70)
        part.decor(POST, at=(x + 12, 12), scale=1.8)
        part.decor("Pebbles", at=(x - 8, 18))


# ---- zones 2 and 3: open dunes -------------------------------------------------------------------
P23 = (190, 350, 510)  # the dunes' lines (clear of the rock pools at (140, 120), (-60, 130))
LH = (290, 440)  # the lighthouse


def shore(n, hmax, width, loot_at):
    z = Zone(n, NAME, rock=0)
    f = z.frame
    for i, zc in enumerate(P23):
        k = 1 if i % 2 == 0 else -1
        f.add(Kind="Ridge", Path=[(-364, zc), (-180, zc + 8 * k), (0, zc - 6 * k),
                                  (180, zc + 8 * k), (364, zc)],
              Height=hmax, Width=width, Rough=1)
        f.decor("DuneGrass", path=[(-330, zc + 6 * k), (330, zc + 6 * k)], count=10)
    # The lighthouse, its door the entrance (a flat place).
    f.add(Kind="Flat", At=[LH[0], LH[1] + 18], Radius=9)
    f.entrance((LH[0], LH[1] + 18))
    lighthouse(f, LH)
    f.hazard("Fog", at=LH)
    for cx, cz in ((-250, 60), (210, 70), (-60, 270), (240, 260), (-230, 430), (30, 430),
                   (-130, 570), (240, 575)):
        f.decor("Pebbles", area=box(cx, cz, 60, 40), count=3)
        f.decor("Driftwood", at=(cx + 10, cz + 6))
    f.decor("Shells", area=box(0, 400, 700, 80), count=6)
    for at, w in loot_at:
        f.loot(at, radius=5, weight=w)
        f.decor("Pebbles", at=(at[0] + 6, at[1] + 4))
        f.decor(POST, at=(at[0] - 7, at[1] - 5), scale=1.4)
    bell(f, (LH[0] - 30, LH[1] + 10))
    return z


def dune_way(z, name, start, gaps, end, kind):
    """The cart's ramp: down from `start`, through a gap in each dune, out at `end`; marker posts
    and a rope along it. Straight down over the dunes is quicker on foot."""
    c = z.crossing(name, paths=1)
    pts = [(start, 0), (start, 50)]
    for g, zc in zip(gaps, P23):
        pts += [(g, zc - 34), (g, zc + 34)]
    pts += [(end, 560), (end, 608)]
    c.ramp(pts, width=16)
    posts(c, pts, every=52, off=11)
    rope(c, pts, off=-11)
    tell(c, start, kind)
    return c


def open_zone(n, hmax, width, loot_at, starts):
    z = shore(n, hmax, width, loot_at)
    dune_way(z, "North posts", starts[0], (-150, 10, 150), 40, 0)
    dune_way(z, "Bell line", starts[1], (175, -20, -150), -60, 1)
    dune_way(z, "South rope", starts[2], (-120, 130, -10), 120, 2)
    return z


def zone2():
    return open_zone(2, 4.4, 18, [((300, 220), 1), ((-300, 300), 2), ((-300, 440), 3),
                                  ((-250, 570), 4), ((310, 580), 5)], (-40, 175, -150))


def zone3():
    return open_zone(3, 6.4, 22, [((300, 220), 1), ((-300, 300), 2), ((-300, 440), 3),
                                  ((-250, 570), 4), ((310, 580), 5)], (-40, 175, -150))


# ---- zones 4 to 6: walled, snaking ---------------------------------------------------------------
BAND = {"W": -200, "M": 0, "E": 200}
HALF_RUN = 50  # a snake's runs are 100 long


def snake(band, rows, flip=False):
    """A snake down the zone in a band: from the top at one end of its runs, along each row to
    the other end, out at the bottom (into the court)."""
    c = BAND[band]
    xa, xb = c - HALF_RUN, c + HALF_RUN
    if flip:
        xa, xb = xb, xa
    pts = [(xa, 0)]
    here = xa
    for zr in rows:
        pts.append((here, zr))
        here = xb if here == xa else xa
        pts.append((here, zr))
    pts.append((here, 608))
    return pts


def dead_end(part, at, direction, length, weight=None, pit=False):
    """A lane out of a corner, away from the band, ending where the fog hides it: the prize at
    its end (over a covered pit if `pit`)."""
    x, zz = at
    end = (x + direction * length, zz)
    part.lane([at, end], width=12)
    part.decor("Bones", at=(end[0] - direction * 8, end[1] + 3), scale=0.8)
    part.decor("Pebbles", at=(end[0] - direction * 4, end[1] - 3))
    if weight:
        part.loot(end, radius=4, weight=weight)
    if pit:
        part.hazard("Pit", at=end, radius=4, covered=True)
    return end


def walled(n, rock, loot_court):
    z = Zone(n, NAME, rock=rock)
    f = z.frame
    f.hall([(-310, -12), (310, -12), (310, 24), (-310, 24)])
    f.hall([(-310, 530), (310, 530), (310, 620), (-310, 620)])
    f.decor("Pebbles", area=box(0, 6, 560, 24), count=6)
    f.decor("DuneGrass", area=box(0, 600, 560, 40), count=8)
    # The lighthouse: a tall tower of rock in the court, its door the entrance.
    lh = (-120, 585)
    f.add(Kind="Wall", Area=[[-130, 574], [-110, 574], [-110, 594], [-130, 594]], Height=24,
          Over=True)
    lighthouse(f, (lh[0] + 34, lh[1] + 6), scale=3)
    f.entrance((lh[0], lh[1] - 30))
    f.hazard("Fog", at=lh)
    f.loot((loot_court, 575), radius=6, weight=4)
    f.decor(POST, path=[(-290, 548), (290, 548)], count=12, scale=1.5)
    f.decor(ROPE, path=[(-290, 554), (290, 554)], count=10)
    bell(f, (lh[0] + 24, lh[1] - 8))
    bell(f, (160, 560))
    return z


def run_mid(pts, i):
    """The middle of the i-th row's run in a snake's points."""
    a, b = pts[2 * i + 1], pts[2 * i + 2]
    return ((a[0] + b[0]) / 2, a[1])


def way(part, pts, ramp=False, pits=()):
    """One way down a band: the cart's ramp (16 wide) or a foot lane (12), roped."""
    if ramp:
        part.ramp(pts, width=16)
    else:
        part.lane(pts, width=12)
    rope(part, pts, off=-9 if ramp else 8)
    posts(part, pts, every=60, off=9)
    for at in pits:
        part.hazard("Pit", at=at, radius=4, covered=True)
        part.decor("Pebbles", path=[(at[0] - 3, at[1]), (at[0] + 3, at[1] + 2)], count=3)


def zone_walled(n, rock, rows, loot_court, specs):
    """`specs`: crossings as (name, tell kind, ramp band, [foot bands], links, dead ends, pits)."""
    z = walled(n, rock, loot_court)
    for name, kind, rb, feet, links, dead, pits in specs:
        c = z.crossing(name, paths=1 + len(feet))
        rp = snake(rb, rows, flip=(rb == "W"))
        way(c, rp, ramp=True)
        tell(c, rp[0][0], kind)
        for fb in feet:
            fp = snake(fb, rows, flip=(fb != "W"))
            way(c, fp, pits=[run_mid(fp, i) for i in pits.get(fb, ())])
            tell(c, fp[0][0], (kind + 1) % 3)
        for band, i, side, length, w, pit in dead:
            dead_end(c, (BAND[band] + side * HALF_RUN, rows[i]), side, length, w, pit)
        for a, b, i in links:  # a lane across the gap at row i
            lo, hi = sorted((BAND[a], BAND[b]))
            c.lane([(lo + HALF_RUN, rows[i]), (hi - HALF_RUN, rows[i])], width=12)
    return z


def rows_for(count, first=76, last=468):
    step = (last - first) / (count - 1)
    return [int(round((first + step * i) / 4)) * 4 for i in range(count)]


def zone4():
    rows = rows_for(7, first=108)
    return zone_walled(4, 12, rows, 100, [
        ("Rope road", 0, "E", ["M", "W"], [("M", "E", 3)],
         [("W", 2, -1, 56, 2, True), ("M", 4, 1, 24, 1, False), ("E", 5, 1, 56, 3, False)],
         {"M": (2, 5), "W": (1, 4)}),
        ("Bell walk", 1, "M", ["W", "E"], [("W", "M", 2)],
         [("W", 4, -1, 56, 3, True), ("E", 1, 1, 56, 2, False), ("E", 5, 1, 24, 1, True)],
         {"W": (3,), "E": (2, 4)}),
        ("Post line", 2, "W", ["M"], [("W", "M", 4)],
         [("W", 1, -1, 56, 3, False), ("M", 2, 1, 24, 2, True), ("M", 5, -1, 24, 1, False)],
         {"M": (1, 3, 5)}),
    ])


def zone5():
    rows = rows_for(9)
    return zone_walled(5, 12, rows, -60, [
        ("Rope road", 0, "E", ["M", "W"], [("M", "E", 4)],
         [("W", 3, -1, 56, 3, True), ("M", 6, 1, 24, 2, False), ("E", 7, 1, 56, 4, True)],
         {"M": (2, 5, 7), "W": (1, 5)}),
        ("Bell walk", 1, "M", ["W", "E"], [("W", "M", 3)],
         [("W", 6, -1, 56, 4, True), ("E", 2, 1, 56, 3, False), ("E", 7, 1, 24, 2, True)],
         {"W": (2, 4), "E": (3, 6)}),
        ("Post line", 2, "W", ["M", "E"], [("M", "E", 6)],
         [("W", 2, -1, 56, 3, False), ("M", 3, 1, 24, 3, True), ("E", 4, 1, 56, 4, False)],
         {"M": (1, 4), "E": (2, 5)}),
    ])


def zone6():
    rows = rows_for(11, first=72, last=476)
    return zone_walled(6, 14, rows, 100, [
        ("Rope road", 0, "E", ["M", "W"], [("M", "E", 5)],
         [("W", 3, -1, 60, 4, True), ("M", 6, 1, 24, 3, False), ("E", 8, 1, 60, 5, True)],
         {"M": (2, 7), "W": (1, 5, 8)}),
        ("Bell walk", 1, "M", ["W", "E"], [("W", "M", 4)],
         [("W", 7, -1, 60, 5, True), ("E", 2, 1, 60, 4, False), ("E", 8, 1, 24, 3, True)],
         {"W": (2, 6), "E": (3, 6)}),
        ("Post line", 2, "W", ["M", "E"], [("M", "E", 7)],
         [("W", 2, -1, 60, 4, False), ("M", 3, 1, 24, 3, True), ("E", 5, 1, 60, 5, True)],
         {"M": (1, 5), "E": (2, 8)}),
    ])


COMMENT = ("-- Fog Bank (planned): drawn with the layout kit from tools/kit/plans/fog_bank.py\n"
           "-- (edit the plan and re-run it, not this file). The card: docs/design/cards/fog-bank.md.")
write_zones(OUT, [zone2(), zone3(), zone4(), zone5(), zone6()], COMMENT)
