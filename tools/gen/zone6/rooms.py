"""Writes the side rooms of Zone6.luau (between the `<<< rooms` and `>>> rooms` markers).

    python3 tools/gen/zone6/rooms.py          # check the rooms and rewrite the file's rooms
    python3 tools/gen/zone6/rooms.py --check  # only check

Each slot is a block of 40-stud lane cells (3 x 3, or 4 x 3) with one door onto the frame. A
room is drawn with walls and rubble between cells (H = a wall across a lane between the cell
above and below, V = one between left and right), then dressed with shapes, roof cells, loot,
decor and dangers (Luau expressions, see the helpers at the top of Zone6.luau). The checker
walks each room from its door: every cell must be reachable, and every loot spot must stand in
a dead end (a cell with one way in) or, in an open room, in its farthest cell; the best finds
deepest.
"""
import pathlib, sys, collections

SRC = pathlib.Path(__file__).resolve().parents[3] / "src/shared/Layouts/Zones/Zone6.luau"

# slot index: (name, at, cols, door cell (c, r), door side, edgeL, edgeR)
SLOTS = {
    1: ("West cave", (-360, 52), 3, (2, 1), "E", True, False),
    2: ("Gatehouse yard", (-40, 52), 3, (0, 1), "W", False, False),
    3: ("East cellar", (240, 212), 3, (0, 1), "W", False, True),
    4: ("Drowned hall", (-80, 212), 4, (1, 2), "S", False, False),
    5: ("Low west vault", (-360, 372), 3, (2, 1), "E", True, False),
    6: ("Sea vault", (-80, 412), 4, (2, 0), "N", False, False),
    7: ("East deeps", (240, 412), 3, (1, 0), "N", False, True),
}

ROOMS = []

# Each room's kind gives the tell at its door (a regular learns what's behind it).
KINDS = {
    "Comb of caves": "cave", "Gatehouse cellar": "cave", "Dead-end cave": "cave",
    "Drowned pool": "pool", "Flooded cellar": "pool", "Flooded hall": "pool", "Flooded vault": "pool", "Flooded pocket": "pool",
    "Boulder scramble": "scramble", "Gatehouse ring": "ring", "Tunnel ring": "ring", "Ring and vault": "ring",
    "Pillar court": "court", "Pillar gallery": "court", "Sinking flats": "flats", "Weed hall": "weed",
    "Collapsed hall": "rubble", "Collapsed vault": "rubble", "Dead-end vault": "vault", "Drowned gallery": "gallery",
}
# kind: (decor kind, count) pairs scattered over the door cell
TELLS = {
    "cave": [("DeadCoral", 2), ("Pebbles", 4)],
    "pool": [("Kelp", 3), ("Starfish", 1)],
    "scramble": [("Crate", 1), ("Urchins", 2), ("Pebbles", 4)],
    "ring": [("Anchor", 1), ("Chain", 1)],
    "court": [("Timber", 2), ("Chain", 1)],
    "flats": [("Bones", 1), ("Starfish", 2)],
    "weed": [("Weed", 4), ("Kelp", 2)],
    "rubble": [("Timber", 1), ("Crate", 1), ("Pebbles", 5)],
    "vault": [("Bones", 1), ("DeadCoral", 1)],
    "gallery": [("Chain", 2), ("WreckRibs", 1)],
}


def room(slot, name, h=(), v=(), rh=(), rv=(), roofs=(), shapes=(), loot=(), decor=(), hazards=(), runs=(), tell=None, open_room=False):
    """h/v: walls across/between lanes, rh/rv: rubble; roofs: cells; runs: roof paths (Luau);
    loot: (cell col, cell row, weight) or (x, z, weight) with x or z beyond 10."""
    ROOMS.append(dict(slot=slot, name=name, h=set(h), v=set(v), rh=set(rh), rv=set(rv), roofs=list(roofs), shapes=list(shapes),
                      loot=list(loot), decor=list(decor), hazards=list(hazards), runs=list(runs), tell=tell, open=open_room))


def cx(c):
    return 20 + 40 * c


def post(i, j):
    return "post(%d, %d)" % (40 * i, 40 * j)


def boulder(x, z, r=11, h=10):
    return "boulder(%d, %d, %d, %d)" % (x, z, r, h)


# ---- slot 1: West cave (door east, middle row) ----
room(1, "Comb of caves", h=[(1, 1), (2, 1), (1, 2), (2, 2)], roofs=[(1, 0), (2, 0), (1, 2), (2, 2)],
     loot=[(2, 0, 6), (2, 2, 4)])
room(1, "Drowned pool", v=[(1, 0), (1, 2)], shapes=["pool(60, 60, 20)", "mud({ { 24, 36 }, { 96, 36 }, { 96, 84 }, { 24, 84 } })"],
     loot=[(0, 0, 6), (0, 2, 4)])
room(1, "Boulder scramble", h=[(0, 1), (1, 1)],
     shapes=[boulder(60, 70, 13, 10), boulder(34, 74, 11, 9), boulder(96, 80, 11, 10), boulder(100, 34, 11, 10)],
     loot=[(0, 0, 6), (0, 2, 3)])

# ---- slot 2: Gatehouse yard (door west) ----
room(2, "Gatehouse ring", h=[(1, 1), (1, 2)], v=[(1, 1), (2, 2)], roofs=[(0, 0), (1, 0), (2, 0), (2, 1)],
     loot=[(1, 1, 6), (1, 2, 3), (2, 2, 2)])
room(2, "Pillar court", v=[(2, 0), (2, 2)], shapes=[post(1, 1), post(2, 1), post(1, 2), post(2, 2)],
     loot=[(2, 0, 5), (2, 2, 6)])
room(2, "Gatehouse cellar", h=[(1, 1)], v=[(1, 1), (2, 1), (1, 2)], roofs=[(1, 1), (1, 2), (2, 1)],
     loot=[(1, 1, 6), (0, 2, 3)])

# ---- slot 3: East cellar (door west, cliff to the east) ----
room(3, "Sinking flats", v=[(2, 0), (2, 2)], shapes=["mud({ { 44, 4 }, { 76, 4 }, { 76, 36 }, { 44, 36 } })", "mud({ { 44, 84 }, { 76, 84 }, { 76, 116 }, { 44, 116 } })"],
     loot=[(2, 0, 6), (2, 2, 5)])
room(3, "Flooded cellar", h=[(1, 1), (2, 1)], v=[(2, 2)], roofs=[(1, 0), (2, 0)], shapes=["pool(60, 100, 16)"],
     loot=[(2, 0, 6), (2, 2, 4)])
room(3, "Weed hall", v=[(1, 0), (1, 2)], h=[(2, 1)], shapes=["lane({ { 60, 60 }, { 100, 60 } })", "weed({ { 44, 28 }, { 116, 28 }, { 116, 92 }, { 44, 92 } })"],
     loot=[(2, 0, 6), (0, 0, 3), (0, 2, 3)])

# ---- slot 4: Drowned hall (4 x 3, door south) ----
room(4, "Flooded hall", v=[(3, 0), (1, 0)], shapes=[post(1, 1), post(3, 1), post(1, 2), post(3, 2), "pool(60, 60, 15)", "pool(100, 60, 15)"],
     loot=[(3, 0, 6), (0, 0, 5)])
room(4, "Collapsed hall", h=[(1, 1), (2, 1)], v=[(3, 0), (3, 2)], rv=[],
     shapes=[boulder(40, 76, 11, 9), boulder(120, 40, 12, 10), boulder(80, 96, 11, 8)],
     loot=[(2, 0, 6), (3, 2, 4)])
room(4, "Pillar gallery", h=[(3, 1)], v=[(1, 2)], shapes=[post(1, 1), post(2, 1), post(3, 1), post(2, 2), post(3, 2)],
     loot=[(3, 0, 6), (0, 2, 3)])
room(4, "Dead-end vault", h=[(1, 1), (2, 1), (3, 1)], v=[(1, 2)], roofs=[(1, 0), (3, 0)],
     loot=[(3, 0, 6), (0, 2, 3)])

# ---- slot 5: Low west vault (door east) ----
room(5, "Tunnel ring", h=[(1, 1), (1, 2)], v=[(1, 1)], roofs=[(0, 0), (2, 0), (0, 1), (0, 2), (2, 2)],
     loot=[(1, 1, 6)])
room(5, "Dead-end cave", h=[(0, 2), (1, 2)], v=[(1, 0)], roofs=[(0, 2), (1, 2), (0, 0)],
     loot=[(0, 2, 6), (0, 0, 4)])
room(5, "Boulder scramble", h=[(0, 1)], rv=[(1, 0)],
     shapes=[boulder(70, 62, 13, 10), boulder(100, 100, 11, 10), boulder(30, 100, 11, 9)],
     loot=[(0, 0, 6)])

# ---- slot 6: Sea vault (4 x 3, door north) ----
room(6, "Drowned gallery", h=[(0, 1), (1, 1), (2, 1), (1, 2), (2, 2), (3, 2)],
     runs=["roof({ { 140, 60 }, { 20, 60 }, { 20, 100 }, { 140, 100 } })"],
     loot=[(3, 2, 6), (0, 0, 3)])
room(6, "Flooded vault", h=[(0, 1), (1, 1)], v=[(3, 2)], shapes=[post(2, 1), post(2, 2), "pool(80, 80, 18)", "pool(120, 60, 12)"],
     loot=[(0, 0, 6), (3, 2, 4)])
room(6, "Collapsed vault", v=[(2, 1)], h=[(0, 2)], rv=[(2, 2)],
     shapes=[boulder(30, 70, 11, 9), boulder(110, 90, 12, 10), boulder(140, 60, 11, 9)],
     loot=[(0, 2, 6)])
room(6, "Ring and vault", h=[(1, 1), (2, 1), (1, 2), (2, 2)], v=[(1, 1)], roofs=[(0, 1), (0, 2), (3, 2), (1, 2)],
     loot=[(1, 1, 6)])

# ---- slot 7: East deeps (door north, cliff to the east) ----
room(7, "Flooded pocket", v=[(2, 1), (2, 2)], shapes=["pool(40, 80, 20)"], loot=[(2, 2, 6), (0, 2, 3)])
room(7, "Dead-end cave", h=[(0, 1), (1, 1), (2, 2)], roofs=[(1, 1), (0, 1), (0, 2), (1, 2)], loot=[(2, 2, 6), (0, 0, 3)])
room(7, "Boulder scramble", h=[(0, 2)], shapes=[boulder(70, 62, 13, 10), boulder(96, 76, 11, 10), boulder(30, 56, 11, 9)],
     loot=[(0, 2, 6), (2, 2, 3)])


def lua_pic(w, room):
    lines = []
    for j in range(4):
        s = "+"
        for c in range(w):
            s += ("--" if (c, j) in room["h"] else "==" if (c, j) in room["rh"] else "  ") + "+"
        lines.append(s)
        if j < 3:
            t = [" "] * (3 * w + 1)
            for i in range(w + 1):
                if (i, j) in room["v"]:
                    t[3 * i] = "|"
                elif (i, j) in room["rv"]:
                    t[3 * i] = "!"
            lines.append("".join(t))
    return lines


def analyse(r):
    """Walk the room from its door: (reachable, dead ends, depth by cell)."""
    name, at, w, door, side, _, _ = SLOTS[r["slot"]]
    cells = [(c, j) for c in range(w) for j in range(3)]

    def open_(a, b):
        (c1, j1), (c2, j2) = a, b
        if j1 == j2:
            i = max(c1, c2)
            return (i, j1) not in r["v"]
        c = c1
        j = max(j1, j2)
        return (c, j) not in r["h"]

    dist = {door: 0}
    q = collections.deque([door])
    while q:
        cur = q.popleft()
        for dc, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (cur[0] + dc, cur[1] + dj)
            if n in cells and n not in dist and open_(cur, n):
                dist[n] = dist[cur] + 1
                q.append(n)
    deadends = []
    for c in cells:
        deg = sum(1 for dc, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (c[0] + dc, c[1] + dj) in cells and open_(c, (c[0] + dc, c[1] + dj)))
        if c == door:
            deg += 1
        if deg == 1:
            deadends.append(c)
    return cells, dist, deadends


def check():
    bad = 0
    for r in ROOMS:
        cells, dist, dead = analyse(r)
        label = "slot %d %s" % (r["slot"], r["name"])
        if len(dist) != len(cells):
            print("UNREACHABLE", label, [c for c in cells if c not in dist])
            bad += 1
        far = max(dist.values())
        best = max((l[2] for l in r["loot"]), default=0)
        for l in r["loot"]:
            cell = (l[0], l[1])
            if cell not in dead and dist.get(cell) != far:
                print("loot not at a dead end:", label, l, "dead ends", dead)
                bad += 1
            if l[2] == best and dist.get(cell, 0) < max(dist.get((d[0], d[1]), 0) for d in r["loot"]) - 1:
                print("best loot not deepest:", label, l)
        if not r["loot"]:
            print("no loot:", label)
    return bad


def door_tell(r):
    name, at, w, door, side, _, _ = SLOTS[r["slot"]]
    x0, z0 = 40 * door[0] + 8, 40 * door[1] + 8
    area = "{ { %d, %d }, { %d, %d }, { %d, %d }, { %d, %d } }" % (x0, z0, x0 + 24, z0, x0 + 24, z0 + 24, x0, z0 + 24)
    return ['{ Kind = "%s", Area = %s, Count = %d }' % (k, area, n) for k, n in TELLS[KINDS[r["name"]]]]


def lua_room(r):
    name, at, w, door, side, edgeL, edgeR = SLOTS[r["slot"]]
    out = []
    out.append("\t\t\tmakeRoom(%s, %s, {" % (str(edgeL).lower(), str(edgeR).lower()))
    out.append('\t\t\t\tName = "%s",' % r["name"])
    out.append("\t\t\t\tArt = {")
    for l in lua_pic(w, r):
        out.append('\t\t\t\t\t"%s",' % l)
    out.append("\t\t\t\t},")
    items = list(r["shapes"]) + ["cellRoof(%d, %d)" % (cx(c), cx(j)) for c, j in r["roofs"]] + list(r["runs"])
    out.append("\t\t\t\tShapes = {")
    for s in items:
        out.append("\t\t\t\t\t%s," % s)
    out.append("\t\t\t\t},")
    out.append("\t\t\t\tLoot = {")
    for l in sorted(r["loot"], key=lambda l: -l[2]):
        x, z = (cx(l[0]), cx(l[1])) if l[0] < 10 and l[1] < 10 else (l[0], l[1])
        out.append("\t\t\t\t\tloot(%d, %d, %d)," % (x, z, l[2]))
    out.append("\t\t\t\t},")
    decor = door_tell(r) + r["decor"]
    if decor:
        out.append("\t\t\t\tDecor = {")
        for d in decor:
            out.append("\t\t\t\t\t%s," % d)
        out.append("\t\t\t\t},")
    if r["hazards"]:
        out.append("\t\t\t\tHazards = {")
        for d in r["hazards"]:
            out.append("\t\t\t\t\t%s," % d)
        out.append("\t\t\t\t},")
    out.append("\t\t\t}),")
    return "\n".join(out)


def build():
    out = ["frame.Slots = {"]
    for k, (name, at, w, door, side, edgeL, edgeR) in SLOTS.items():
        out.append("\t{")
        out.append('\t\tName = "%s",' % name)
        out.append("\t\tAt = { %d, %d }," % at)
        out.append("\t\tSize = { %d, 120 }," % (40 * w))
        out.append("\t\tRooms = {")
        for r in ROOMS:
            if r["slot"] == k:
                out.append(lua_room(r))
        out.append("\t\t},")
        out.append("\t},")
    out.append("}")
    return "\n".join(out)


def main():
    bad = check()
    print("rooms:", len(ROOMS), "problems:", bad)
    if "--check" in sys.argv:
        return
    text = SRC.read_text()
    a = text.index("-- <<< rooms")
    b = text.index("-- >>> rooms")
    chunk = build()
    text = text[: a + len("-- <<< rooms (written by tools/gen/zone6/rooms.py; edit that, not this)\n")] + chunk + "\n" + text[b:]
    SRC.write_text(text)


if __name__ == "__main__":
    main()
