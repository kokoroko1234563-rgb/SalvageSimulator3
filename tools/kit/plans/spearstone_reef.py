"""Spearstone Reef, a biome rolling in zones 4 to 6 (docs/design/cards/spearstone-reef.md).

A black basalt reef: walled halls and corridors, each hall its own spear challenge. The halls
are the frame (islands in the rock: no way between them), the crossings wind between them.

Run it with the quick check, once per zone:
    python3 tools/kit/quick.py 4 Biomes/Planned/SpearstoneReef --plan tools/kit/plans/spearstone_reef.py

The halls (zone coordinates, x -360 west to 360 east, z 0 top to 608 sea):

    z   0  ========== top band ==========
       48  (rows of lanes: the crossings' A1 and A2)
      120  [   H1 the Wave hall: three wave fields, run behind them   ]
      252  [H2 Checker hall]                               [H3 Overlap hall]
      372                       [H4 Ring hall: the prize]
      512  (rows of lanes: the crossings' bottom rows)
      592  ========== bottom band ========

Damage by zone: 35, 60, 100. Paths: through the fields (quick, timed) or round them (long).
"""

from kit import Zone, write_zones

OUT = "src/shared/Layouts/Biomes/Planned/SpearstoneReef.luau"
ROCK = 18
DAMAGE = {4: 35, 5: 60, 6: 100}


def box(cx, cz, w, d):
    return [(cx - w / 2, cz - d / 2), (cx + w / 2, cz - d / 2), (cx + w / 2, cz + d / 2),
            (cx - w / 2, cz + d / 2)]


def field(part, n, at, radius, pattern):
    part.hazard("Spears", at=at, radius=radius, pattern=pattern, damage=DAMAGE[n])


def frame(z, n, entrance):
    f = z.frame
    f.hall([(-360, -12), (360, -12), (360, 12), (-360, 12)])
    f.hall([(-360, 592), (360, 592), (360, 620), (-360, 620)])
    # H1 the Wave hall: three wave fields along it; run behind the waves.
    f.hall(box(0, 156, 320, 72))
    for x in (-100, 0, 100):
        field(f, n, (x, 156), 34, "Wave")
    f.loot((148, 156), radius=5, weight=2)
    f.decor("Rocks", area=box(0, 156, 300, 60), count=6)
    f.decor("Bones", at=(-148, 156), scale=1.1, yaw=20)
    # H2 the Checker hall: hop between the squares.
    f.hall(box(-170, 302, 116, 100))
    field(f, n, (-170, 302), 44, "Checker")
    f.loot((-170, 302), radius=5, weight=3)
    f.decor("Barnacles", area=box(-170, 302, 100, 90), count=5)
    f.decor("Rocks", at=(-208, 340), scale=1.2, yaw=70)
    # H3 the Overlap hall: a wave and a checkerboard over one another.
    f.hall(box(170, 302, 116, 100))
    field(f, n, (150, 302), 40, "Wave")
    field(f, n, (190, 302), 40, "Checker")
    f.loot((170, 302), radius=5, weight=3)
    f.decor("Bones", at=(212, 262), scale=1.2, yaw=120)
    f.decor("Barnacles", area=box(170, 302, 100, 90), count=4)
    # H4 the Ring hall: rings spreading from the middle, the prize at the middle.
    f.hall(box(0, 424, 144, 104))
    field(f, n, (0, 424), 44, "Ring")
    field(f, n, (0, 424), 26, "Ring")
    f.loot((0, 424), radius=4, weight=5)
    f.decor("Rocks", area=box(0, 424, 130, 90), count=5)
    f.decor("Bones", at=(52, 392), scale=1.3, yaw=300)
    f.entrance(entrance)


def spurs(c, pts):
    c.lane(pts, width=12)


def corridor(c, n, x, zs, patterns):
    for zz, p in zip(zs, patterns):
        field(c, n, (x, zz), 12, p)


# ---- crossing 1: Crossed fields -------------------------------------------------------------------
def crossed_fields(z, n):
    c = z.crossing("Crossed fields", paths=2)
    q = [(-300, 0), (-300, 48), (300, 48), (300, 302), (0, 302), (0, 424), (0, 512)]
    if n != 4:  # a switchback down the east side before the Overlap hall
        q[2:4] = [(336, 48), (336, 88), (264, 88), (264, 128), (336, 128), (336, 168), (264, 168),
                  (264, 208), (336, 208), (336, 302)]
    if n == 4:
        q += [(0, 608)]
    else:
        q += [(300, 512), (300, 608)]
        for x, p in zip((60, 110, 160, 210), ("Wave", "Checker", "Wave", "Checker")):
            field(c, n, (x, 512), 12, p)
    c.ramp(q, width=16)
    b = [(60, 0), (60, 88), (-336, 88), (-336, 250), (-264, 250), (-264, 330), (-336, 330),
         (-336, 410), (-264, 410), (-264, 552), (240, 552), (240, 608)]
    if n == 4:
        b = [(60, 0), (60, 88), (-336, 88), (-336, 250), (-264, 250), (-264, 330), (-336, 330),
             (-336, 410), (-264, 410), (-264, 552), (0, 552), (0, 608)]
    c.lane(b, width=12)
    spurs(c, [(-264, 302), (-200, 302)])  # to the Checker hall
    spurs(c, [(-100, 88), (-100, 140)])  # to the Wave hall
    c.decor("Rocks", at=(-288, 6), scale=1.4, yaw=30)  # the tell: a pair of broken spears
    c.decor("Rocks", at=(-312, 6), scale=1.1, yaw=100)
    return c


# ---- crossing 2: Checker hop ----------------------------------------------------------------
def checker_hop(z, n):
    c = z.crossing("Checker hop", paths=2)
    q = [(60, 0), (60, 156), (-300, 156), (-300, 302), (0, 302), (0, 424)]
    q += {4: [(0, 608)], 5: [(0, 512), (0, 608)],
          6: [(0, 512), (-300, 512), (-300, 608)]}[n]
    c.ramp(q, width=16)
    r = [(336, 0)]
    for i, zz in enumerate(range(232, 553, 40)):  # a serpentine down the east side
        r += [(336, zz), (264, zz)] if i % 2 == 0 else [(264, zz), (336, zz)]
    r = r[:-1] if False else r
    end = {4: [(0, 552), (0, 608)], 5: [(-100, 552), (-100, 608)], 6: [(-240, 552), (-240, 608)]}
    r += end[n]
    c.lane(r, width=12)
    spurs(c, [(0, 302), (130, 302)])  # to the Overlap hall
    c.decor("WreckRibs", at=(70, 8), scale=0.8, yaw=90)  # the tell
    return c


# ---- crossing 3: Spear corridor -------------------------------------------------------------
def spear_corridor(z, n):
    c = z.crossing("Spear corridor", paths=2)
    k = [(-300, 0), (-300, 48), (0, 48), (0, 424), (0, 512)]
    if n == 4:
        k += [(200, 512), (200, 556), (0, 556), (0, 608)]
    else:
        k += [(200, 512), (200, 556), (-300, 556), (-300, 608)]
    c.ramp(k, width=16)
    corridor(c, n, 0, [214, 246, 278, 334], ["Wave", "Checker", "Wave", "Ring"])
    spurs(c, [(0, 302), (-130, 302)])
    spurs(c, [(0, 302), (130, 302)])
    start = (-336, 0) if n == 6 else (-120, 0)
    l = [start, (start[0], 88), (336, 88), (336, 250), (264, 250), (264, 330), (336, 330),
         (336, 410), (264, 410), (264, 470), (336, 470), (336, 596)]
    c.lane(l, width=12)
    c.decor("Chain", path=[(-310, 8), (-290, 8)], count=2)
    c.decor("Rocks", at=(-270, 8), scale=1.5, yaw=200)  # the tell
    return c


ENTRANCE = {4: (-152, 130), 5: (222, 262), 6: (-64, 380)}
CROSSINGS = {4: (crossed_fields, checker_hop), 5: (crossed_fields, checker_hop, spear_corridor),
             6: (crossed_fields, checker_hop, spear_corridor)}


def build(n):
    z = Zone(n, {4: "Outer Spearstone", 5: "Spearstone Shoals", 6: "Spearstone Deep"}[n],
             rock=ROCK)
    frame(z, n, ENTRANCE[n])
    for make in CROSSINGS[n]:
        make(z, n)
    return z


zones = [build(n) for n in (4, 5, 6)]
write_zones(OUT, zones,
            "-- Spearstone Reef: drawn with the layout kit from tools/kit/plans/spearstone_reef.py\n"
            "-- (edit the plan and re-run it, not this file). Card: docs/design/cards/spearstone-reef.md.")
