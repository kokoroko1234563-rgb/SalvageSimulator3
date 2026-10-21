"""Whirlwind Dunes (docs/design/cards/whirlwind-dunes.md): tall dune ridges carved into a maze,
and a bowl in the middle where a whirlwind turns. Zones 4, 5 and 6, each its own layout.

Run it with the quick check, per zone:
  python3 tools/kit/quick.py 4 Biomes/WhirlwindDunes --plan tools/kit/plans/whirlwind_dunes.py

The map (zone coordinates: x -360 west to 360 east, z 0 at the top to 608 at the sea):

    z   0  =============== the top band (every path starts here) ===============
       36  [TL slot]                                              [TR slot]
      124  west rim rows .......  [B top rows]  ....... east rim rows
      272              [W slot] ( the BOWL: the whirlwind turns ) [E slot]
      428  west rim rows .......  [B bottom rows] ..... east rim rows
      504  [BL slot]                                              [BR slot]
      592  =============== the bottom band (the Far Sandbar's approach) ===============

Every crossing has two or three paths: B goes through the bowl (quick, across the whirlwind's
circle) on a narrow foot lane; W and E go round the dunes, down the west rim and the east rim in
winding rows. One of them is the cart's (a 20 wide Ramp, rows 48 apart so its dunes stay thick).
Walls between lanes are the dunes: packed sand, 24 or more thick.
"""

import math

from kit import Zone, write_zones

OUT = "src/shared/Layouts/Biomes/WhirlwindDunes.luau"
COMMENT = (
    "-- Whirlwind Dunes (planned biome, zones 4 to 6): tall dune ridges carved into a maze, a bowl\n"
    "-- in the middle where a whirlwind turns. Drawn with the layout kit from\n"
    "-- tools/kit/plans/whirlwind_dunes.py: edit that plan and run it again, not this file."
)
ROCK = 16  # dunes you can't see over (14 to 20)
DUNE = "Salt"  # packed sand
CENTRE = (0, 304)
BOWL = 60  # the bowl's radius


# ---- helpers: the dunes' vocabulary -------------------------------------------------------------
def circle(cx, cz, r, n=16, start=0.0):
    return [(cx + r * math.cos(start + 2 * math.pi * i / n),
             cz + r * math.sin(start + 2 * math.pi * i / n)) for i in range(n)]


def loop(points):
    return points + [points[0]]


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


def rim_rows(m, step, x_in, x_out, z0, col):
    """A rim path: from the top at x=col, down to z0, then `m` rows between x_out (the cliff
    side) and x_in (the bowl side), ending back at x=col, and down to the sea."""
    pts = [(col, 0), (col, z0)]
    ends = [x_out, x_in]
    z = z0
    cur = col
    for j in range(m):
        cur = col if j == m - 1 else ends[j % 2]  # the last row comes back to the column
        pts.append((cur, z))
        if j < m - 1:
            z += step
            pts.append((cur, z))
    pts.append((col, 608))
    return pts


def bowl_rows(kt, kb, half, side):
    """The bowl path: down from the top band in rows over the middle, into the bowl and out of
    it, rows under the bowl, and down to the sea."""
    top = CENTRE[1] - BOWL
    bot = CENTRE[1] + BOWL
    a, b = side * half, -side * half
    pts = [(a, 0)]
    cur = a
    for i in range(kt):
        z = 60 + 40 * i
        pts.append((cur, z))
        if i == kt - 1:
            pts.append((0, z))
            cur = 0
        else:
            cur = b if cur == a else a
            pts.append((cur, z))
    pts.append((0, top + 4))
    pts.append((0, bot - 4))
    z0 = 548 - 40 * (kb - 1)
    pts.append((0, z0))
    cur = 0
    nxt = a
    for i in range(kb):
        z = z0 + 40 * i
        if i:
            pts.append((cur, z))
        cur = nxt
        pts.append((cur, z))
        nxt = b if cur == a else a
    pts.append((cur, 608))
    return pts


def length(points):
    return sum(math.hypot(bx - ax, bz - az) for (ax, az), (bx, bz) in zip(points, points[1:]))


def post_line(part, points, every=90, skip=0):
    """Wind-worn posts along a way, at its side."""
    for i, (x, z) in enumerate(along(points, every)):
        if i % 2 == skip:
            part.decor("Timber", at=(round(x + 9), round(z + 9)), scale=0.7, yaw=(i * 53) % 180)


def scatter(part, points, kind, every=130, offset=10, scale=1.0):
    for i, (x, z) in enumerate(along(points, every)):
        s = -1 if i % 2 else 1
        part.decor(kind, at=(round(x + s * offset), round(z - s * offset)), scale=scale,
                   yaw=(i * 71) % 360)


def dead_end(part, points, weight=2):
    part.lane(points, width=12)
    part.loot(points[-1], radius=5, weight=weight)
    part.decor("Bones", at=points[-1], scale=0.9, yaw=40)


# ---- rooms: hollows in the dunes ----------------------------------------------------------------
def inward(slot):
    """The door, the point deepest in from it, and the step in."""
    (w, d), (dx, dz) = slot.size, slot.door
    if dz == 0:
        return (dx, dz), (dx, d - 14), (0, 1)
    if dz == d:
        return (dx, dz), (dx, 14), (0, -1)
    if dx == 0:
        return (dx, dz), (w - 14, dz), (1, 0)
    return (dx, dz), (14, dz), (-1, 0)


def box(slot, inset=8):
    w, d = slot.size
    return [(inset, inset), (w - inset, inset), (w - inset, d - inset), (inset, d - inset)]


def scoop(slot, name, weight=3, pit=False):
    """A round hollow in the dune, the find at its bottom."""
    r = slot.room(name)
    r.hall(box(slot))
    _, deep, _ = inward(slot)
    r.hollow(deep, radius=min(slot.size) / 2 - 16, depth=3, material="Sand")
    r.loot(deep, radius=4, weight=weight)
    if pit:
        r.hazard("Pit", at=deep, radius=4, covered=True)
    r.decor("Bones", at=(round(deep[0] + 6), round(deep[1] + 6)), scale=0.8, yaw=30)
    r.decor("Pebbles", area=box(slot, 14), count=5)
    return r


def comb(slot, name, weight=3, pit=False):
    """A gallery straight in with short blind pockets off both sides; the best in the last."""
    r = slot.room(name, lead=False)
    door, deep, (ix, iz) = inward(slot)
    r.lane([door, deep], width=12)
    w, d = slot.size
    span = abs(deep[0] - door[0]) + abs(deep[1] - door[1])
    for k, t in enumerate(range(20, int(span) - 4, 24)):
        x, zz = door[0] + ix * t, door[1] + iz * t
        side = 1 if k % 2 == 0 else -1
        reach = (w if iz else d) / 2 - 12
        end = (x + iz * side * reach, zz + ix * side * reach)
        r.lane([(x, zz), end], width=12)
        r.loot(end, radius=3, weight=1)
    r.loot(deep, radius=4, weight=weight)
    if pit:
        r.hazard("Pit", at=deep, radius=4, covered=True)
    r.decor("Driftwood", area=box(slot, 12), count=3)
    return r


def drift(slot, name, weight=2, pit=False):
    """Sand heaped in drifts to clamber over; the find behind the biggest."""
    r = slot.room(name)
    r.hall(box(slot))
    _, deep, _ = inward(slot)
    w, d = slot.size
    for k, (fx, fz) in enumerate([(0.3, 0.35), (0.7, 0.5), (0.4, 0.7), (0.65, 0.25)]):
        r.mound((round(w * fx), round(d * fz)), radius=8, height=4 + k % 2, rock=False)
    r.loot(deep, radius=4, weight=weight)
    if pit:
        r.hazard("Pit", at=deep, radius=4, covered=True)
    r.decor("Timber", at=(round(w / 2), round(d / 2)), scale=0.8, yaw=70)
    return r


def post_ring(slot, name, weight=3, pit=False):
    """A hollow ringed by wind-worn posts, bones at its heart."""
    r = slot.room(name)
    r.hall(box(slot))
    _, deep, _ = inward(slot)
    w, d = slot.size
    r.hollow((w / 2, d / 2), radius=min(w, d) / 2 - 16, depth=2, material="Sand")
    for x, zz in circle(w / 2, d / 2, min(w, d) / 2 - 14, n=6):
        r.decor("Timber", at=(round(x), round(zz)), scale=0.6, yaw=round(x * 7) % 180)
    r.decor("Bones", at=(round(w / 2), round(d / 2)), scale=1.1)
    r.loot(deep, radius=4, weight=weight)
    if pit:
        r.hazard("Pit", at=deep, radius=4, covered=True)
    return r


KINDS = {"scoop": scoop, "comb": comb, "drift": drift, "ring": post_ring}
SITES = [  # name, corner, size, door (in the slot's own coordinates)
    ("Bowl west hollows", (-136, 272), (64, 64), (64, 32)),
    ("Bowl east hollows", (72, 272), (64, 64), (0, 32)),
    ("Low west hollows", (-352, 504), (88, 72), (44, 72)),
    ("Low east hollows", (264, 504), (88, 72), (44, 72)),
]


# ---- the zone -----------------------------------------------------------------------------------
def rim(kind, p):
    """A rim path's points (W: the west rim, E: the east, mirrored)."""
    col = p.get("col", -220)
    xi, xo = p.get("xi", -184), p.get("xo", -340)
    if p.get("ramp"):  # a 20 wide ramp keeps its edges 10 off the lanes it neighbours
        xi, xo = xi - 8, xo + 16
    pts = rim_rows(p["m"], p["step"], xi, xo, p.get("z0", 60), col)
    return pts if kind == "W" else [(-x, zz) for x, zz in pts]


def build(n, name, spec):
    z = Zone(n, name, rock=ROCK, material=DUNE)
    f = z.frame
    f.hall([(-360, -12), (360, -12), (360, 20), (-360, 20)])
    f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])
    f.hall(circle(*CENTRE, BOWL, n=16, start=math.pi / 16))
    f.hollow(CENTRE, radius=BOWL - 12, depth=3, rough=1, material="Sand")
    f.loot(CENTRE, radius=6, weight=3)
    f.decor("Bones", at=(CENTRE[0] + 6, CENTRE[1] - 4), scale=1.4, yaw=20)
    f.decor("Timber", at=(CENTRE[0] - 8, CENTRE[1] + 6), scale=1.1, yaw=80)
    f.hazard("Whirlwind", path=loop(circle(*CENTRE, 24, n=8)), radius=10)
    if spec.get("second"):  # a wider whirlwind, turning the other way
        f.hazard("Whirlwind", path=loop(circle(*CENTRE, 38, n=12)[::-1]), radius=10)
    if spec.get("pits"):
        # Spike pits on the bowl's rim, where a fling can throw you: two open, two under sand.
        for k, (px, pz) in enumerate([(-36, -36), (36, -36), (-36, 36), (36, 36)]):
            f.hazard("Pit", at=(CENTRE[0] + px, CENTRE[1] + pz), radius=4, covered=k % 2 == 1)
    f.decor("Pebbles", area=[(-340, -6), (340, -6), (340, 14), (-340, 14)], count=8)
    f.decor("Driftwood", area=[(-340, 596), (340, 596), (340, 616), (-340, 616)], count=4)

    for cs in spec["crossings"]:
        c = z.crossing(cs["name"], paths=len(cs["paths"]))
        for p in cs["paths"]:
            if p["kind"] == "B":
                pts = bowl_rows(p["kt"], p["kb"], p["half"], p["side"])
                c.lane(pts, width=12)
                post_line(c, pts[:-3], every=100)
                scatter(c, pts, "Pebbles", every=150)
            else:
                pts = rim(p["kind"], p)
                if p.get("ramp"):
                    c.ramp(pts, width=20)
                else:
                    c.lane(pts, width=12)
                post_line(c, pts, every=110, skip=0 if p["kind"] == "W" else 1)
                scatter(c, pts, "Driftwood", every=190)
            print(f"  zone {n} {cs['name']} {p['kind']}: {length(pts):.0f} studs")
        for d in cs.get("dead", []):
            dead_end(c, d, weight=2)
        for kind, at, kw in cs["tell"]:
            c.decor(kind, at=at, **kw)

    for (sname, at, size, door), (ka, kb, wa, wb) in zip(SITES, spec["rooms"]):
        s = z.slot(sname, at=at, size=size, door=door)
        for kind, w in ((ka, wa), (kb, wb)):
            r = KINDS[kind](s, f"{sname[:-8]} {kind}", weight=w, pit=spec.get("pits", False) and w >= 3)
            if sname == DOOR_SITE and kind in DOOR_AT:
                r.entrance(DOOR_AT[kind])  # the secret's door: a dune hollow, far down the west
    return z


# The secret's door stands in the hollow far down the west (both of its rooms hold it).
DOOR_SITE = "Low west hollows"
DOOR_AT = {"scoop": (44, 46), "ring": (44, 36)}

ROOMS = [("scoop", "drift", 3, 2), ("comb", "ring", 2, 3), ("ring", "scoop", 4, 3),
         ("drift", "comb", 3, 4)]

def B(kt, kb, half, side):
    return dict(kind="B", kt=kt, kb=kb, half=half, side=side)


def R(kind, m, ramp=False, xi=-184, z0=60):
    return dict(kind=kind, m=m, step=48 if ramp else 40, ramp=ramp, xi=xi, z0=z0)


def spec(pits, second, cs):
    """Three crossings: the way in to each has its own tell (a pair of posts, an arch of bones,
    a drift of timber)."""
    posts = [("Timber", (-24, 10), dict(scale=1.3, yaw=0)), ("Timber", (-8, 10), dict(scale=1.3, yaw=0))]
    arch = [("Bones", (-210, 10), dict(scale=1.5, yaw=90))]
    heap = [("Driftwood", (212, 10), dict(scale=1.6, yaw=30)), ("Pebbles", (228, 10), dict(scale=1.2))]
    names = ["West rim", "East rim", "Three ways"]
    return dict(rooms=ROOMS, pits=pits, second=second, crossings=[
        dict(name=nm, paths=ps, tell=t) for nm, ps, t in zip(names, cs, [arch, heap, posts])])


# (bowl path, rim paths) per crossing: the bowl path is the quick one, the cart's ramp the long one
SPEC4 = spec(False, False, [
    [B(1, 1, 140, -1), R("W", 6, True)],
    [B(2, 1, 100, 1), R("E", 7, True, z0=116)],
    [B(1, 1, 140, 1), R("W", 5), R("E", 7, True, z0=116)]])
SPEC5 = spec(False, False, [
    [B(1, 2, 120, -1), R("W", 8, True)],
    [B(2, 2, 100, 1), R("E", 8, True)],
    [B(1, 2, 120, -1), R("W", 7), R("E", 7, True)]])
SPEC6 = spec(True, True, [
    [B(2, 3, 100, -1), R("W", 9, True, xi=-154)],
    [B(2, 3, 104, 1), R("E", 9, True, xi=-164)],
    [B(2, 3, 120, -1), R("W", 8, xi=-160), R("E", 9, True, xi=-164)]])

if __name__ == "__main__":
    zones = [build(4, "The Whirlwind Shore", SPEC4), build(5, "The Whirlwind Shoals", SPEC5),
             build(6, "The Whirlwind Reach", SPEC6)]
    write_zones(OUT, zones, COMMENT)
