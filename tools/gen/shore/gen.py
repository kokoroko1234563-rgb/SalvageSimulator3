#!/usr/bin/env python3
"""Generates src/shared/Layouts/Zones/Zone1-3.luau (the shore). Usage: python3 tools/gen/shore/gen.py [1 2 3]
Seeded, so the output is stable; edit the zone functions and rerun.

What the engine does with slopes (why the numbers below): a Path ridge of Width W and Height h
has sides up to about h * 1.54 / (W / 2) steep. Carts climb 0.35 at most, players 0.9. So a
low dune (h 2.4, W 16: 0.46) stops carts but not people; a bar with h 5, W 14 (1.1) stops both,
and a saddle in it (h 3, W 20: 0.46) is a foot-only way over. An Area ridge only works when
thin (its inradius at most its Width), so banks here are Path ridges."""
import math, os, random, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(ROOT, "src/shared/Layouts/Zones")


# ---- Luau serialising -------------------------------------------------------------------
def lua(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        r = round(v, 1)
        return str(int(r)) if r == int(r) else str(r)
    if isinstance(v, str):
        return '"%s"' % v
    if isinstance(v, (list, tuple)):
        return "{ " + ", ".join(lua(x) for x in v) + " }"
    if isinstance(v, dict):
        return "{ " + ", ".join("%s = %s" % (k, lua(x)) for k, x in v.items()) + " }"
    raise TypeError(v)


# ---- geometry ---------------------------------------------------------------------------
def spline(pts, step=24):
    """Catmull-Rom through pts, sampled about every `step` studs."""
    out = [pts[0]]
    P = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        n = max(2, int(math.dist(p1, p2) / step))
        for k in range(1, n + 1):
            t = k / n
            out.append([0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t * t
                               + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t ** 3) for j in (0, 1)])
    return [[round(x), round(z)] for x, z in out]


def curve(cx, cz, length, angle, bend, n=6):
    """A gently bent line of `length` centred on (cx, cz), heading `angle` degrees (0 = along x)."""
    pts = []
    for i in range(n):
        t = i / (n - 1) - 0.5
        a = math.radians(angle + bend * t)
        d = length * t
        pts.append([cx + d * math.cos(a), cz + d * math.sin(a)])
    bow = length * math.radians(bend) / 8
    nx, nz = -math.sin(math.radians(angle)), math.cos(math.radians(angle))
    for i, pt in enumerate(pts):
        k = 1 - (2 * i / (n - 1) - 1) ** 2
        pt[0] += nx * bow * k
        pt[1] += nz * bow * k
    return [[round(x), round(z)] for x, z in pts]


def blob(rng, cx, cz, rx, rz, rot=0, n=12):
    pts = []
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    for i in range(n):
        a = 2 * math.pi * i / n
        k = rng.uniform(0.82, 1.15)
        x, z = rx * k * math.cos(a), rz * k * math.sin(a)
        pts.append([round(cx + x * c - z * s), round(cz + x * s + z * c)])
    return pts


def sub(path, a, b):
    """Part of a sampled path, from fraction a to b."""
    n = len(path)
    return path[int(a * (n - 1)): int(b * (n - 1)) + 1]


def row_z(x, z0, amp, ph, tilt=0.0):
    """A row's centre at x: it waves, and with a tilt it runs a little across the zone, so
    neighbouring rows close in and open out instead of lying parallel."""
    return z0 + tilt * x + amp * math.sin((x + ph) / 85.0) + 0.35 * amp * math.sin((x + 2 * ph) / 31.0)


def row_path(z0, amp, ph, x0, x1, tilt=0.0):
    """A bar's centre line along a row, from x0 to x1."""
    n = max(2, int(abs(x1 - x0) / 22))
    return [[round(x0 + (x1 - x0) * i / n), round(row_z(x0 + (x1 - x0) * i / n, z0, amp, ph, tilt))] for i in range(n + 1)]


def offset(path, d):
    """The path moved sideways by d studs (to its left of travel for d > 0)."""
    out = []
    for i, (x, z) in enumerate(path):
        a, b = path[max(0, i - 1)], path[min(len(path) - 1, i + 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        n = math.hypot(dx, dz) or 1
        out.append([round(x - dz / n * d), round(z + dx / n * d)])
    return out


def bank(p, h, w, trench):
    """A crest between two runnels, as primitives."""
    out = [dict(Kind="Ridge", Path=p, Height=h, Width=w, Rough=3)]
    for side in (-1, 1):
        q = offset(p, side * (w / 2 + 3))
        out.append(dict(Kind="Channel", Path=q, Depth=trench, Width=10, Rough=2))
        out.append(dict(Kind="Paint", Path=q, Width=22, Material="Ground", Rough=3))
    return out


# ---- builder ----------------------------------------------------------------------------
class Zone:
    def __init__(self, seed, name, blocked=lambda x, z: False):
        self.rng = random.Random(seed)
        self.name = name
        self.prims, self.decor = [], []
        self.blocked = blocked

    def ok(self, pts):
        return not any(self.blocked(x, z) for x, z in pts)

    def add(self, kind, **kw):
        pts = kw.get("Path") or kw.get("Area") or ([kw["At"]] if "At" in kw else [])
        assert self.ok(pts), (kind, [p for p in pts if self.blocked(*p)][:3])
        self.prims.append(dict(Kind=kind, **kw))

    def dec(self, kind, count=None, **kw):
        e = dict(Kind=kind, **kw)
        if count:
            e["Count"] = min(count, 60)
        pts = kw.get("Path") or kw.get("Area") or ([kw["At"]] if "At" in kw else [])
        if self.ok(pts):
            self.decor.append(e)

    def lua(self, crossings, header):
        parts = [header, "", "local frame = {", '\tName = "%s",' % self.name, "\tPrimitives = {"]
        for p in self.prims:
            parts.append("\t\t" + lua(p) + ",")
        parts += ["\t},", "\tDecor = {"]
        for d in self.decor:
            parts.append("\t\t" + lua(d) + ",")
        parts += ["\t},", "}", "", "frame.Crossings = {"]
        for name, prims in crossings:
            parts.append('\t{ Name = "%s", Primitives = { %s } },' % (name, ", ".join(lua(p) for p in prims)))
        parts += ["}", "", "return frame", ""]
        return "\n".join(parts)


def ramp(path):
    return dict(Kind="Ramp", Path=path, Width=16)


def write(n, text):
    path = os.path.join(OUT, "Zone%d.luau" % n)
    open(path, "w").write(text)
    subprocess.run(["stylua", path], check=True)


def wrack(Z, lines, cuts, counts=(26, 18, 4, 10)):
    """Strings of weed, shells and driftwood where the high tides left them: broken, bunched."""
    r = Z.rng
    for ln in lines:
        path = spline(ln, 22)
        for a, b in cuts:
            seg = sub(path, a, b)
            if len(seg) < 2:
                continue
            Z.dec("Weed", counts[0] + r.randint(-4, 6), Path=seg)
            Z.dec("Shells", counts[1] + r.randint(-3, 5), Path=seg)
            if r.random() < 0.75:
                Z.dec("Driftwood", counts[2], Path=seg)
            Z.dec("Pebbles", counts[3], Path=seg)
            if r.random() < 0.4:
                Z.dec("Starfish", 2, Path=seg)


def scatter(Z, kinds, n, zlo, zhi, size=(12, 8)):
    r = Z.rng
    for _ in range(n):
        cx, cz = r.randint(-325, 325), r.randint(zlo, zhi)
        k = r.choice(kinds)
        Z.dec(k, r.randint(3, 8), Area=blob(r, cx, cz, size[0] * r.uniform(0.7, 1.4), size[1] * r.uniform(0.7, 1.3), r.uniform(0, 180), 8))


# ---- zone 1 -----------------------------------------------------------------------------
CAMPS = [(-265, 24), (-120, 32), (170, 26), (290, 36)]


def blocked1(x, z):
    if abs(x) < 20 and z < 28:
        return True
    return any(math.dist((x, z), c) < 18 for c in CAMPS)


def zone1():
    Z = Zone(11, "Shopside Shore", blocked1)
    r = Z.rng
    # The boardwalk's walkway and the umbrella camps stay flat.
    Z.prims.append(dict(Kind="Flat", Area=[[-16, 0], [16, 0], [16, 24], [-16, 24]]))
    for c in CAMPS:
        Z.prims.append(dict(Kind="Flat", At=list(c), Radius=12))
    # Soft dunes, mostly near the top, in drifts with open sand between: (x, z, length, heading, bend, height).
    dunes = [(-310, 100, 100, 15, 30, 2.4), (-205, 150, 70, -25, 40, 2.2), (-70, 90, 120, 8, -35, 2.5),
             (80, 120, 110, -12, 40, 2.4), (215, 85, 90, 20, -30, 2.3), (310, 175, 70, 70, 30, 2.4),
             (-150, 235, 80, 15, 40, 2.3), (30, 235, 100, -18, -30, 2.5), (170, 285, 70, 10, 35, 2.2),
             (-295, 310, 60, 100, 30, 2.2), (-30, 330, 60, 20, -30, 2.0), (240, 395, 80, -10, 30, 2.0)]
    dune_paths = []
    for cx, cz, ln, ang, bend, h in dunes:
        p = curve(cx, cz, ln, ang, bend)
        Z.add("Ridge", Path=p, Height=h, Width=16, Rough=3)
        Z.add("Paint", Path=p, Width=12, Material="Salt", Rough=3)
        dune_paths.append(p)
    # A shallow creek meandering to the sea.
    creek = spline([[78, 44], [30, 110], [80, 190], [10, 270], [-60, 345], [-10, 425], [62, 485], [14, 555], [-26, 608]], 26)
    Z.add("Channel", Path=creek, Depth=1.4, Width=14, Rough=2)
    Z.add("Paint", Path=creek, Width=30, Material="Ground", Rough=4)
    # Tide pools.
    for (px, pz, rad) in [(158, 330, 13), (-92, 440, 11), (-250, 520, 10)]:
        Z.add("Hollow", At=[px, pz], Radius=rad, Depth=1.3, Rough=2)
        Z.add("Paint", At=[px, pz], Radius=rad + 10, Material="Salt", Rough=4)
        Z.dec("Pebbles", 6, Area=blob(r, px, pz, rad + 8, rad + 6, 0, 8))
        Z.dec("Rocks", 2, Area=blob(r, px + 6, pz - 4, rad + 14, rad + 8, 0, 8), Scale=0.8)
        Z.dec("Starfish", 3, Area=blob(r, px, pz, rad - 3, rad - 4, 0, 8))
    # Damp firm sand near the sea, and a pebble bank.
    Z.add("Paint", Area=[[-362, 560], [-200, 548], [-40, 566], [120, 552], [270, 568], [362, 556], [362, 608], [-362, 608]],
          Material="Salt", Rough=6)
    bank = blob(r, -190, 395, 38, 12, 20)
    Z.add("Paint", Area=bank, Material="Slate", Rough=3)
    Z.dec("Pebbles", 24, Area=bank)
    # Wrack lines, wavering and broken, where the highest tides left them.
    wrack(Z, [
        [[-345, 215], [-270, 262], [-190, 215], [-110, 270], [-20, 238], [60, 288], [150, 235], [250, 290], [345, 250]],
        [[-345, 400], [-250, 355], [-150, 420], [-40, 375], [60, 440], [180, 392], [270, 445], [345, 405]],
        [[-345, 510], [-240, 540], [-120, 498], [-10, 535], [110, 500], [220, 538], [345, 505]],
    ], [(0.0, 0.2), (0.25, 0.42), (0.5, 0.58), (0.64, 0.84), (0.9, 1.0)])
    for p in dune_paths:
        Z.dec("DuneGrass", 8, Path=p)
    scatter(Z, ["Shells", "Shells", "Pebbles", "Weed"], 26, 60, 580)
    Z.dec("Crate", At=[212, 470])
    Z.dec("Driftwood", 1, At=[-300, 440], Scale=1.4)
    Z.dec("Timber", 1, At=[255, 190])
    Z.dec("Rocks", 3, Area=blob(r, 265, 340, 24, 14, 10, 8))
    west = ramp(spline([[-205, 2], [-262, 130], [-170, 270], [-282, 420], [-205, 606]], 40))
    east = ramp(spline([[200, 2], [262, 150], [150, 300], [270, 450], [190, 606]], 40))
    write(1, Z.lua([("West road", [west]), ("East road", [east])],
          "-- Zone 1, Shopside Shore: one 720 x 608 piece, drawn by tools/gen/shore/gen.py (edit that, then rerun it).\n"
          "-- Soft dunes near the top, a creek winding to the sea, tide pools, wrack lines. Walkway and camps stay flat."))


# ---- rows: bars across a zone, with open gaps and foot-only saddles ------------------------
def bars(Z, z0, amp, ph, gaps, saddles, h, w, saddle_h, saddle_w, rough=3, trench=3.0, tilt=0.0):
    """A row across the zone from side to side, made of bars. gaps: [(x0, x1)] left open;
    saddles: [(x0, x1)] low enough to walk over but not to haul a cart over."""
    cuts = sorted([(a, b, "gap") for a, b in gaps] + [(a, b, "saddle") for a, b in saddles])
    x = -362
    pieces = []
    for a, b, kind in cuts:
        if a > x + 8:
            pieces.append((x, a, "solid"))
        if kind == "saddle":
            pieces.append((a, b, "saddle"))
        x = b
    if x < 362:
        pieces.append((x, 362, "solid"))
    for a, b, kind in pieces:
        p = row_path(z0, amp, ph, a, b, tilt)
        if kind == "solid":
            # A crest between two runnels: from the bottom of a runnel to the crest is too steep to walk.
            for prim in bank(p, h, w, trench):
                Z.add(prim.pop("Kind"), **prim)
        else:
            Z.add("Ridge", Path=p, Height=saddle_h, Width=saddle_w, Rough=rough)
        Z.add("Paint", Path=p, Width=10, Material="Salt", Rough=2)
        yield a, b, kind, p


# ---- zone 2 -----------------------------------------------------------------------------
def blocked2(x, z):
    if z < 330 and abs(x - 40) < 28:
        return True
    return any(math.dist((x, z), p) < 30 for p in [(-280, 20), (140, 120)])


def solids(row, gaps):
    """The row's solid stretches between its gaps, as (x0, x1)."""
    out, x = [], -362
    for a, b in sorted(gaps):
        out.append((x, a))
        x = b
    out.append((x, 362))
    return out


def zone2():
    Z = Zone(22, "Sunny Stretch", blocked2)
    r = Z.rng
    # The pier's line stays clear.
    for pz in (22, 76, 130, 184, 238, 292):
        Z.prims.append(dict(Kind="Flat", At=[40, pz], Radius=9))
    A, B, C = (200, 30, 0), (330, 26, 60), (460, 32, 130)
    # Row gaps zigzag: the pier's (x 2 to 78), then west, then east. Saddles are foot-only ways over.
    rows = [(A, [(2, 78)], [(-260, -215)]), (B, [(-175, -125)], [(215, 260)]), (C, [(125, 175)], [(-260, -215)])]
    for row, gaps, saddles in rows:
        for a, b, kind, p in bars(Z, *row, gaps=gaps, saddles=saddles, h=4.2, w=18, saddle_h=3.0, saddle_w=22, trench=2.0):
            if kind == "solid":
                Z.dec("DuneGrass", 8, Path=p)
    # Low curving bars between the rows, with runnels beside those near the ends of the zone.
    lows = [(-210, 70, 120, 200, 40, 1), (210, 80, 100, 20, -35, 1), (-40, 100, 70, 30, 30, 1),
            (-200, 265, 90, 10, 20, 0), (210, 265, 90, -10, 20, 0), (-60, 395, 100, 5, 25, 0), (190, 395, 90, -15, 25, 0),
            (60, 545, 100, 10, 30, 1), (-200, 550, 110, -10, 35, 1), (240, 545, 80, 15, -30, 1)]
    for cx, cz, ln, ang, bend, runnel in lows:
        p = curve(cx, cz, ln, ang, bend)
        if not Z.ok(p):
            continue
        Z.add("Ridge", Path=p, Height=2.6, Width=18, Rough=3)
        Z.add("Paint", Path=p, Width=10, Material="Salt", Rough=2)
        Z.dec("Shells", 8, Path=p)
        nx, nz = -math.sin(math.radians(ang)), math.cos(math.radians(ang))
        q = [[round(x + nx * 24), round(z + nz * 24)] for x, z in p]
        if runnel and Z.ok(q) and all(30 < zz < 580 for _, zz in q):
            Z.add("Channel", Path=q, Depth=1.5, Width=14, Rough=2)
            Z.add("Paint", Path=q, Width=26, Material="Ground", Rough=3)
    # outcrops (decor rocks)
    for (cx, cz) in [(-215, 265), (215, 395), (-95, 130), (130, 270), (-300, 520)]:
        Z.dec("Rocks", 5, Area=blob(r, cx, cz, 24, 15, r.uniform(0, 90), 9), Scale=1.5)
        Z.dec("Barnacles", 3, Area=blob(r, cx, cz, 18, 10, 0, 8))
        Z.dec("Weed", 6, Area=blob(r, cx, cz, 30, 20, 0, 8))
        Z.dec("Starfish", 3, Area=blob(r, cx, cz, 30, 20, 0, 8))
    scatter(Z, ["Shells", "Pebbles", "Weed", "Shells"], 20, 40, 580)
    wrack(Z, [[[-345, 265], [-250, 290], [-150, 262], [-50, 292], [60, 262], [160, 292], [250, 265], [345, 285]],
              [[-345, 395], [-240, 372], [-130, 400], [-10, 378], [100, 402], [210, 380], [345, 398]],
              [[-345, 560], [-240, 540], [-130, 572], [-10, 545], [100, 575], [210, 550], [345, 570]]],
          [(0, 0.22), (0.3, 0.5), (0.58, 0.8), (0.86, 1)])
    c1 = ramp(spline([[40, 2], [48, 110], [40, 200], [0, 250], [-100, 290], [-150, 335], [-90, 390], [50, 420], [150, 462], [130, 540], [110, 606]], 40))
    c2 = ramp(spline([[40, 2], [48, 110], [40, 200], [90, 250], [150, 290], [150, 335], [60, 390], [-60, 420], [-150, 462], [-130, 540], [-110, 606]], 40))
    plugs1 = bank(row_path(*B, -175, -125), 4.2, 18, 2.0) + bank(row_path(*C, 125, 175), 4.6, 14, 2.0)
    write(2, Z.lua([("Pier, then west, then east", [c1]), ("Pier, then east, then west", plugs1 + [c2])],
          "-- Zone 2, Sunny Stretch: three rows of sandbars (a crest between two runnels) with gaps that zigzag and low\n"
          "-- saddles, curving bars and runnels, outcrops. Drawn by tools/gen/shore/gen.py. The pier's line (x = 40,\n"
          "-- first half) and the rock pools stay clear."))


# ---- zone 3 -----------------------------------------------------------------------------
def blocked3(x, z):
    return (abs(x - 40) < 20 and z < 90) or math.dist((x, z), (-60, 130)) < 30


def zone3():
    Z = Zone(33, "Middle Banks", blocked3)
    r = Z.rng
    A, B, C, D = (200, 22, 10, 0.07), (320, 28, 70, -0.05), (440, 24, 130, 0.06), (555, 20, 40, 0.015)
    rows = [(A, [(-135, -85)], [(190, 240)]), (B, [(85, 135)], [(-250, -200)]),
            (C, [(-135, -85)], [(190, 240)]), (D, [(85, 135)], [(-250, -200)])]
    for row, gaps, saddles in rows:
        for a, b, kind, p in bars(Z, *row[:3], gaps=gaps, saddles=saddles, h=5.8, w=22, saddle_h=3.2, saddle_w=24, rough=4, trench=2.0, tilt=row[3]):
            if kind == "solid":
                Z.dec("DuneGrass", 10, Path=p)
                Z.dec("Pebbles", 4, Path=p)
    # a few banks beyond the rows, to hide the way ahead from the top
    extra = [(-290, 110, 90, 10, 30, 5.6), (-20, 100, 100, -10, -30, 5.4), (200, 110, 90, 25, 30, 5.6)]
    for cx, cz, ln, ang, bend, h in extra:
        p = curve(cx, cz, ln, ang, bend)
        if Z.ok(p):
            Z.add("Ridge", Path=p, Height=h, Width=20, Rough=3)
            Z.add("Paint", Path=p, Width=10, Material="Salt", Rough=2)
            Z.dec("DuneGrass", 8, Path=p)
    # the creek finds the gaps, and ends in a wide mouth
    creek = spline([[-130, 30], [-115, 120], [-110, 200], [-60, 255], [40, 285], [110, 320], [110, 380], [40, 410], [-60, 435],
                    [-110, 440], [-100, 500], [0, 530], [110, 555], [150, 585]], 26)
    Z.add("Channel", Path=creek, Depth=1.6, Width=16, Rough=2)
    Z.add("Paint", Path=creek, Width=34, Material="Ground", Rough=4)
    Z.add("Hollow", At=[140, 590], Radius=26, Depth=1.8, Rough=3)
    Z.dec("Weed", 20, Area=blob(r, 140, 585, 40, 14, 0, 10))
    # an old wreck, half buried, between rows 2 and 3
    Z.add("Hollow", At=[235, 380], Radius=22, Depth=1.2, Rough=3)
    Z.dec("WreckRibs", 1, At=[235, 380], Scale=1.6, Yaw=20)
    Z.dec("WreckRibs", 1, At=[256, 388], Scale=1.1, Yaw=15)
    Z.dec("Timber", 4, Area=blob(r, 238, 380, 34, 20, 15, 8))
    Z.dec("Crate", 2, Area=blob(r, 218, 392, 12, 8, 0, 8))
    for (cx, cz) in [(-310, 380), (310, 255)]:
        Z.dec("Rocks", 4, Area=blob(r, cx, cz, 22, 14, 0, 8), Scale=1.4)
    scatter(Z, ["Shells", "Pebbles", "Weed", "Starfish"], 22, 40, 585)
    wrack(Z, [[[-345, 260], [-230, 280], [-110, 255], [10, 285], [130, 262], [250, 282], [345, 260]],
              [[-345, 380], [-210, 400], [-80, 375], [60, 402], [200, 395], [345, 380]],
              [[-345, 500], [-200, 520], [-60, 495], [90, 522], [250, 500], [345, 520]]],
          [(0, 0.2), (0.28, 0.5), (0.58, 0.78), (0.85, 1)], (16, 12, 3, 6))
    c1 = ramp(spline([[-110, 2], [-110, 100], [-110, 200], [-40, 255], [60, 285], [110, 322], [110, 380], [40, 415], [-60, 440], [-110, 445],
                      [-95, 500], [0, 530], [110, 555], [110, 606]], 40))
    c2 = ramp(spline([[-110, 2], [-110, 100], [-110, 150], [60, 240], [110, 285], [-110, 325], [-110, 380], [60, 415], [110, 440],
                      [110, 480], [0, 530], [-110, 555], [-110, 606]], 40))
    plugs = []
    for row, gap in [(A, (-135, -85)), (B, (85, 135)), (C, (-135, -85)), (D, (85, 135))]:
        plugs += bank(row_path(*row[:3], *gap, row[3]), 5.8, 22, 2.0)
    write(3, Z.lua([("Down the gaps", [c1]), ("Across the banks", plugs + [c2])],
          "-- Zone 3, Middle Banks: four rows of tall banks (a crest between two runnels) with gaps that zigzag and low\n"
          "-- saddles; they hide the way ahead from the top. A creek that finds the gaps, an old wreck. Drawn by\n"
          "-- tools/gen/shore/gen.py."))


if __name__ == "__main__":
    which = [int(a) for a in sys.argv[1:]] or [1, 2, 3]
    for n in which:
        {1: zone1, 2: zone2, 3: zone3}[n]()
