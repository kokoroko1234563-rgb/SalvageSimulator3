"""Helpers for Zone6.luau's maze pictures: parse them, build the cell graph, find dead ends.

Usage: python3 tools/gen/zone6/maze.py path        # doors and shortest cell path per crossing
       python3 tools/gen/zone6/maze.py deadends    # dead-end cells of every crossing
The pictures are read straight from src/shared/Layouts/Zones/Zone6.luau.
"""
import re, sys, collections, pathlib

SRC = pathlib.Path(__file__).resolve().parents[3] / "src/shared/Layouts/Zones/Zone6.luau"
W, H = 18, 14  # cells across and down the zone


def pictures(text=None):
    text = text or SRC.read_text()
    out = {}
    for m in re.finditer(r"^local ([A-Z0-9]+) = \{\n((?:\t\".*\",\n)+)\}", text, re.M):
        out[m.group(1)] = [l.strip()[1:-2] for l in m.group(2).splitlines()]
    return out


class Grid:
    """Edges between cells. Outside the zone is r = -1 (the top strip) and r = H (the bottom)."""

    def __init__(self):
        self.wall = set()
        self.rubble = set()

    def add(self, art, i0=0, j0=0):
        h = (len(art) - 1) // 2
        w = (len(art[0]) + 2) // 3 - 1
        for j in range(h + 1):
            for c in range(w):
                ch = art[2 * j][3 * c + 1]
                a, b = (i0 + c, j0 + j - 1), (i0 + c, j0 + j)
                if ch == "-":
                    self.wall.add(frozenset((a, b)))
                elif ch == "=":
                    self.rubble.add(frozenset((a, b)))
        for r in range(h):
            for i in range(w + 1):
                ch = art[2 * r + 1][3 * i]
                a, b = (i0 + i - 1, j0 + r), (i0 + i, j0 + r)
                if ch == "|":
                    self.wall.add(frozenset((a, b)))
                elif ch == "!":
                    self.rubble.add(frozenset((a, b)))
        return self

    def open(self, a, b, rubble_ok=True):
        e = frozenset((a, b))
        if e in self.wall:
            return False
        return rubble_ok or e not in self.rubble

    def cells(self):
        return [(c, r) for c in range(W) for r in range(H)]

    def neighbours(self, cell, rubble_ok=True):
        c, r = cell
        for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c + dc, r + dr)
            if not (0 <= n[0] < W) or not (0 <= n[1] < H):
                continue
            if self.open(cell, n, rubble_ok):
                yield n

    def doors(self, side):
        row = 0 if side < 0 else H - 1
        return [(c, row) for c in range(W) if self.open((c, row), (c, side))]

    def shortest(self, rubble_ok=True):
        """Cells walked from the top strip to the bottom strip (BFS)."""
        dist = {}
        q = collections.deque()
        for d in self.doors(-1):
            dist[d] = 1
            q.append(d)
        while q:
            cur = q.popleft()
            for n in self.neighbours(cur, rubble_ok):
                if n not in dist:
                    dist[n] = dist[cur] + 1
                    q.append(n)
        return min((dist[d] for d in self.doors(H) if d in dist), default=None)

    def reachable(self):
        """Cells a player can walk to from the top strip."""
        seen = set(self.doors(-1))
        q = collections.deque(seen)
        while q:
            cur = q.popleft()
            for n in self.neighbours(cur):
                if n not in seen:
                    seen.add(n)
                    q.append(n)
        return seen

    def degree(self, cell):
        """Open sides of a cell, counting the outside strips at the top and bottom."""
        c, r = cell
        n = 0
        for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            o = (c + dc, r + dr)
            if 0 <= o[0] < W and -1 <= o[1] <= H and self.open(cell, o):
                n += 1
        return n


def zone_grid(pics, crossing):
    return Grid().add(pics["FRAME"]).add(pics["CROSSING%d" % crossing])


if __name__ == "__main__":
    pics = pictures()
    cmd = sys.argv[1] if len(sys.argv) > 1 else "path"
    for n in range(1, 6):
        g = zone_grid(pics, n)
        if cmd == "path":
            print(n, "top", [c for c, _ in g.doors(-1)], "bottom", [c for c, _ in g.doors(H)],
                  "shortest", g.shortest(), "no rubble", g.shortest(False))
        else:
            print(n, "dead ends (col,row):", [c for c in g.cells() if g.degree(c) == 1])
