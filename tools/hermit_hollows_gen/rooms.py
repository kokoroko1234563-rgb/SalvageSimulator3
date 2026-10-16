import random
from collections import deque


def cx(c):
    return 14 + 28 * c


def cz(r):
    return 14 + 28 * r


class Room:
    def __init__(self, name, cols, rows, door, seed=1):
        self.name, self.cols, self.rows, self.door = name, cols, rows, door
        self.open = set()  # ('H', j, c) / ('V', i, r) interior open edges
        self.rubble = set()
        self.halls = []
        self.unroofed = set()
        self.solid = set()
        self.extra = []  # lua lines
        self.loot = []
        self.crabs = []
        self.rng = random.Random(seed)
        self.tree = True

    def edge(self, a, b):
        (c, r), (c2, r2) = a, b
        if c == c2 and r2 == r + 1:
            return ('H', r2, c)
        if c == c2 and r2 == r - 1:
            return ('H', r, c)
        if r == r2 and c2 == c + 1:
            return ('V', c2, r)
        if r == r2 and c2 == c - 1:
            return ('V', c, r)
        raise ValueError((a, b))

    def carve(self, *cells):
        for a, b in zip(cells, cells[1:]):
            self.open.add(self.edge(a, b))
        return self

    def hall(self, c0, c1, r0, r1, roofed=True):
        cells = [(c, r) for r in range(r0, r1 + 1) for c in range(c0, c1 + 1)]
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                if c < c1:
                    self.open.add(('V', c + 1, r))
                if r < r1:
                    self.open.add(('H', r + 1, c))
        if not roofed:
            self.unroofed.update(cells)
        self.halls.append(cells)
        return self

    def whole(self, roofed=True):
        return self.hall(0, self.cols - 1, 0, self.rows - 1, roofed)

    def make_solid(self, cells):
        self.solid.update(cells)
        return self

    def rub(self, a, b):
        self.rubble.add(self.edge(a, b))
        return self

    def nbrs(self, p):
        c, r = p
        for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (c + d[0], r + d[1])
            if 0 <= q[0] < self.cols and 0 <= q[1] < self.rows and q not in self.solid:
                yield q

    def finish(self):
        # grow a tree over cells not yet connected
        comp = {}
        cells = [(c, r) for r in range(self.rows) for c in range(self.cols) if (c, r) not in self.solid]
        # union by open edges
        def comps():
            seen = {}
            n = 0
            for p in cells:
                if p in seen:
                    continue
                dq = deque([p])
                seen[p] = n
                while dq:
                    x = dq.popleft()
                    for q in self.nbrs(x):
                        if q not in seen and self.edge(x, q) in self.open:
                            seen[q] = n
                            dq.append(q)
                n += 1
            return seen, n
        while True:
            seen, n = comps()
            if n <= 1:
                break
            cand = []
            for p in cells:
                for q in self.nbrs(p):
                    if seen[p] != seen[q] and self.edge(p, q) not in self.open:
                        cand.append((p, q))
            p, q = self.rng.choice(cand)
            self.open.add(self.edge(p, q))
        return self

    def reach(self):
        seen = {self.door}
        dq = deque([self.door])
        while dq:
            x = dq.popleft()
            for q in self.nbrs(x):
                if q not in seen and (self.edge(x, q) in self.open or self.edge(x, q) in self.rubble):
                    seen.add(q)
                    dq.append(q)
        return seen

    def check(self):
        seen = self.reach()
        for c, r, w in self.loot:
            assert (c, r) in seen, (self.name, 'loot', c, r)
        for path in self.crabs:
            for a, b in zip(path, path[1:]):
                dc = (b[0] > a[0]) - (b[0] < a[0])
                dr = (b[1] > a[1]) - (b[1] < a[1])
                p = a
                while p != b:
                    q = (p[0] + dc, p[1] + dr)
                    assert self.edge(p, q) in self.open, (self.name, 'crab', p, q)
                    p = q
        for cell in [(c, r) for r in range(self.rows) for c in range(self.cols) if (c, r) not in self.solid]:
            assert cell in seen, (self.name, 'unreachable', cell)

    def ascii(self):
        W, H = 2 * self.cols + 1, 2 * self.rows + 1
        g = [[' '] * W for _ in range(H)]
        for j in range(self.rows + 1):
            for i in range(self.cols + 1):
                g[2 * j][2 * i] = '+'
        for j in range(self.rows + 1):
            for c in range(self.cols):
                if j in (0, self.rows):
                    continue  # the border belongs to the frame
                e = ('H', j, c)
                if e in self.rubble:
                    g[2 * j][2 * c + 1] = 'r'
                elif e not in self.open:
                    g[2 * j][2 * c + 1] = '-'
        for r in range(self.rows):
            for i in range(self.cols + 1):
                if i in (0, self.cols):
                    continue
                e = ('V', i, r)
                if e in self.rubble:
                    g[2 * r + 1][2 * i] = 'r'
                elif e not in self.open:
                    g[2 * r + 1][2 * i] = '|'
        for p in self.unroofed:
            g[2 * p[1] + 1][2 * p[0] + 1] = '.'
        return [''.join(r) for r in g]

    def solid_lua(self):
        # walls 16 wide through the centres of solid cells, one path per connected group
        out = []
        left = set(self.solid)
        while left:
            start = min(left, key=lambda p: (p[1], p[0]))
            group = [start]
            left.discard(start)
            stack = [start]
            while stack:
                x = stack.pop()
                for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    q = (x[0] + d[0], x[1] + d[1])
                    if q in left:
                        left.discard(q)
                        group.append(q)
                        stack.append(q)
            # emit as strips: horizontal runs per row, connected by vertical pieces
            rows = {}
            for c, r in group:
                rows.setdefault(r, []).append(c)
            for r, cs in sorted(rows.items()):
                cs.sort()
                run = [cs[0]]
                for c in cs[1:] + [None]:
                    if c is not None and c == run[-1] + 1:
                        run.append(c)
                    else:
                        out.append('wall16({ { cx(%d), cz(%d) }, { cx(%d), cz(%d) } })' % (run[0], r, run[-1], r))
                        run = [c] if c is not None else []
            # vertical links between rows
            for c, r in group:
                if (c, r + 1) in self.solid:
                    out.append('wall16({ { cx(%d), cz(%d) }, { cx(%d), cz(%d) } })' % (c, r, c, r + 1))
        return out

    def lua(self, indent='\t\t\t'):
        self.finish()
        self.check()
        t = indent
        s = []
        s.append(t + '{')
        s.append(t + '\tName = "%s",' % self.name)
        s.append(t + '\tMaze = {')
        for row in self.ascii():
            s.append(t + '\t\t"%s",' % row)
        s.append(t + '\t},')
        extras = self.solid_lua() + self.extra
        if extras:
            s.append(t + '\tExtra = {')
            for e in extras:
                s.append(t + '\t\t' + e + ',')
            s.append(t + '\t},')
        if self.loot:
            s.append(t + '\tLoot = { ' + ', '.join('{ %d, %d, %d }' % l for l in self.loot) + ' },')
        if self.crabs:
            s.append(t + '\tCrabs = {')
            for p in self.crabs:
                s.append(t + '\t\t{ ' + ', '.join('{ %d, %d }' % q for q in p) + ' },')
            s.append(t + '\t},')
        s.append(t + '},')
        return '\n'.join(s)
