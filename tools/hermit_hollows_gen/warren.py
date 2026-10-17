"""A warren: a lattice of cells with a frame (outer walls, ribs, chambers, slots) and mazes grown
over it, one per crossing. Cell (c, r) is a 16 x 16 floor at x = -322 + 28 c, z = 26 + 28 r;
walls between cells are 12 thick (node lines at x = -336 + 28 i, z = 12 + 28 j).

Edges: ('H', j, c) lies between cells (c, j - 1) and (c, j); ('V', i, r) between (i - 1, r) and (i, r).
This is the zone 4 generator (frame.py, gen.py, build.py, export.py) turned into a class, so zones
5 and 6 can each have their own frame."""

import random
from collections import deque
from itertools import combinations


def XC(c):
    return -322 + 28 * c


def ZC(r):
    return 26 + 28 * r


def XN(i):
    return -336 + 28 * i


def ZN(j):
    return 12 + 28 * j


def edge_between(p, q):
    (c, r), (c2, r2) = p, q
    if c == c2 and r2 == r + 1:
        return ('H', r2, c)
    if c == c2 and r2 == r - 1:
        return ('H', r, c)
    if r == r2 and c2 == c + 1:
        return ('V', c2, r)
    if r == r2 and c2 == c - 1:
        return ('V', c, r)
    raise ValueError((p, q))


def cells_of(e):
    k, a, b = e
    return ((b, a - 1), (b, a)) if k == 'H' else ((a - 1, b), (a, b))


def cell_edges(c, r):
    return [('H', r, c), ('H', r + 1, c), ('V', c, r), ('V', c + 1, r)]


def corners(path):
    out = [path[0]]
    for i in range(1, len(path) - 1):
        a, b, c = path[i - 1], path[i], path[i + 1]
        if (b[0] - a[0], b[1] - a[1]) != (c[0] - b[0], c[1] - b[1]):
            out.append(b)
    out.append(path[-1])
    return out


class Warren:
    def __init__(self, C, R, top_doors, bot_doors, ribs, slots, chambers, seed=1):
        """ribs: [(j, [door columns])]; slots: [dict(name, box=(c0,c1,r0,r1), door=edge)];
        chambers: {key: dict(name, box=(c0,c1,r0,r1), drop=[gates to wall up])}"""
        self.C, self.R = C, R
        self.top_doors, self.bot_doors = top_doors, bot_doors
        self.slots, self.chambers = slots, chambers
        self.state = {}  # frame edge -> 'wall' | 'open'; absent = free
        self.cell = {}  # (c, r) -> ('slot', k) | ('ch', key)
        rng = random.Random(seed)
        st = self.state
        for c in range(C):
            st[('H', 0, c)] = 'wall'
            st[('H', R, c)] = 'wall'
        for r in range(R):
            st[('V', 0, r)] = 'wall'
            st[('V', C, r)] = 'wall'
        for c in top_doors:
            del st[('H', 0, c)]
        for c in bot_doors:
            del st[('H', R, c)]
        for j, doors in ribs:
            for c in range(C):
                st[('H', j, c)] = 'wall'
            for c in doors:
                del st[('H', j, c)]

        def block(box, tag, gates):
            c0, c1, r0, r1 = box
            for r in range(r0, r1 + 1):
                for c in range(c0, c1 + 1):
                    self.cell[(c, r)] = tag
                    if c < c1:
                        st[('V', c + 1, r)] = 'open'
                    if r < r1:
                        st[('H', r + 1, c)] = 'open'
            for r in range(r0, r1 + 1):
                st[('V', c0, r)] = 'wall'
                st[('V', c1 + 1, r)] = 'wall'
            for c in range(c0, c1 + 1):
                st[('H', r0, c)] = 'wall'
                st[('H', r1 + 1, c)] = 'wall'
            for g in gates:
                st.pop(g, None)

        for k, s in enumerate(slots):
            block(s['box'], ('slot', k), [])
            st[s['door']] = 'open'
        for key, ch in chambers.items():
            c0, c1, r0, r1 = ch['box']
            gates = []
            sides = [
                [('H', r0, c) for c in range(c0, c1 + 1)],
                [('H', r1 + 1, c) for c in range(c0, c1 + 1)],
                [('V', c0, r) for r in range(r0, r1 + 1)],
                [('V', c1 + 1, r) for r in range(r0, r1 + 1)],
            ]
            for side in sides:
                picks = {side[0], side[-1]} if len(side) > 1 else {side[0]}
                for g in picks:
                    if g not in ch.get('drop', ()):
                        gates.append(g)
            ch['gates'] = gates
            block(ch['box'], ('ch', key), gates)
        self.rng = rng

    # ---------------------------------------------------------------- graph
    def valid(self, c, r):
        return 0 <= c < self.C and 0 <= r < self.R

    def is_slot(self, p):
        return self.cell.get(p, ('',))[0] == 'slot'

    def passable(self):
        return [(c, r) for r in range(self.R) for c in range(self.C) if not self.is_slot((c, r))]

    def nbrs(self, p):
        c, r = p
        out = []
        for e in cell_edges(c, r):
            q = cells_of(e)
            q = q[1] if q[0] == p else q[0]
            if self.valid(*q) and not self.is_slot(q):
                out.append((q, e))
        return out

    def chamber_cells(self, key):
        return [p for p, t in self.cell.items() if t == ('ch', key)]

    def bfs_path(self, src, dst, banned):
        prev = {src: None}
        dq = deque([src])
        while dq:
            p = dq.popleft()
            if p == dst:
                break
            for q, e in self.nbrs(p):
                if q in prev or q in banned or self.state.get(e) == 'wall':
                    continue
                prev[q] = p
                dq.append(q)
        if dst not in prev:
            return None
        path, p = [], dst
        while p is not None:
            path.append(p)
            p = prev[p]
        return path[::-1]

    def backbone(self, wps):
        path = [wps[0]]
        for a, b in zip(wps, wps[1:]):
            seg = self.bfs_path(a, b, set(path[:-1]))
            if seg is None:
                raise Exception('no path %s -> %s' % (a, b))
            path += seg[1:]
        return path

    def pad(self, path, target, rng, avoid=()):
        path = list(path)
        tries = 0
        while len(path) < target and tries < 3000:
            tries += 1
            if len(path) < 6:
                break
            i = rng.randrange(1, len(path) - 3)
            j = i + 2
            d = (path[i + 1][0] - path[i][0], path[i + 1][1] - path[i][1])
            while j + 1 < len(path) - 1 and (path[j + 1][0] - path[j][0], path[j + 1][1] - path[j][1]) == d and rng.random() < 0.7:
                j += 1
            if any((path[k + 1][0] - path[k][0], path[k + 1][1] - path[k][1]) != d for k in range(i, j)):
                continue
            s = rng.choice([(d[1], d[0]), (-d[1], -d[0])])
            new = [path[i]] + [(path[k][0] + s[0], path[k][1] + s[1]) for k in range(i, j + 1)] + [path[j]]
            pset = set(path)
            if any(not self.valid(*q) or q in pset or self.is_slot(q) or q in avoid or q in self.cell for q in new[1:-1]):
                continue
            ok = True
            for a, b in zip(new, new[1:]):
                try:
                    e = edge_between(a, b)
                except ValueError:
                    ok = False
                    break
                if self.state.get(e) == 'wall':
                    ok = False
                    break
            if not ok:
                continue
            path = path[:i] + new + path[j + 1:]
        return path

    # ---------------------------------------------------------------- mazes
    def grow(self, path, top_col, bot_col, seed, bias):
        """A spanning tree of corridors from the backbone: returns the open edge set."""
        rng = random.Random(seed)
        openset = set()
        for a, b in zip(path, path[1:]):
            openset.add(edge_between(a, b))
        openset.add(('H', 0, top_col))
        openset.add(('H', self.R, bot_col))
        visited = set(path)
        chs = {self.cell[p][1] for p in path if p in self.cell and self.cell[p][0] == 'ch'}
        lst = list(path)
        for key in chs:
            for p in self.chamber_cells(key):
                visited.add(p)
                lst.append(p)
        allcells = self.passable()
        while True:
            cand = set(p for p in lst if any(q not in visited and self.state.get(e) != 'wall' for q, e in self.nbrs(p)))
            if not cand:
                left = [p for p in allcells if p not in visited]
                if left:
                    raise Exception('disconnected cells left: %s' % left[:5])
                break
            if rng.random() < bias:
                p = next(x for x in reversed(lst) if x in cand)
            else:
                p = rng.choice(sorted(cand))
            opts = [(q, e) for q, e in self.nbrs(p) if q not in visited and self.state.get(e) != 'wall']
            q, e = rng.choice(opts)
            openset.add(e)
            visited.add(q)
            lst.append(q)
            if q in self.cell and self.cell[q][0] == 'ch':
                for x in self.chamber_cells(self.cell[q][1]):
                    if x not in visited:
                        visited.add(x)
                        lst.append(x)
        return openset

    def isopen(self, openset):
        return lambda e: self.state.get(e) == 'open' or e in openset

    def route(self, openset, rubble=()):
        """The shortest route on foot (rubble included) from the one open top door to the bottom."""
        isopen = self.isopen(openset)
        tops = [(c, 0) for c in range(self.C) if ('H', 0, c) in openset]
        assert len(tops) == 1, tops
        src = tops[0]
        prev = {src: None}
        dq = deque([src])
        end = None
        while dq:
            p = dq.popleft()
            if p[1] == self.R - 1 and ('H', self.R, p[0]) in openset:
                end = p
                break
            for q, e in self.nbrs(p):
                if q in prev:
                    continue
                if isopen(e) or e in rubble:
                    prev[q] = p
                    dq.append(q)
        if end is None:
            return None
        path, p = [], end
        while p is not None:
            path.append(p)
            p = prev[p]
        return path[::-1]

    def dist_from(self, openset, sources):
        isopen = self.isopen(openset)
        dist = {s: 0 for s in sources}
        dq = deque(sources)
        while dq:
            p = dq.popleft()
            for q, e in self.nbrs(p):
                if q not in dist and isopen(e):
                    dist[q] = dist[p] + 1
                    dq.append(q)
        return dist

    def free_edges(self, openset):
        out = []
        for j in range(1, self.R):
            for c in range(self.C):
                e = ('H', j, c)
                if self.state.get(e) is None and e not in openset and not self.is_slot((c, j - 1)) and not self.is_slot((c, j)):
                    out.append(e)
        for i in range(1, self.C):
            for r in range(self.R):
                e = ('V', i, r)
                if self.state.get(e) is None and e not in openset and not self.is_slot((i - 1, r)) and not self.is_slot((i, r)):
                    out.append(e)
        return out

    def build(self, spec):
        rng = random.Random(spec['seed'] * 7919)
        base = self.backbone(spec['wps'])
        if spec.get('cart'):
            base = self.pad(base, spec['cart'], random.Random(spec['seed']))
        openset = self.grow(base, spec['top'], spec['bot'], spec['seed'], spec.get('bias', 0.7))
        cart = self.route(openset)
        n0 = len(cart)
        cands = self.free_edges(openset)
        rng.shuffle(cands)
        nb = 0
        for e in cands:
            if nb >= spec.get('braids', 6):
                break
            a, b = cells_of(e)
            if self.cell.get(a) and self.cell.get(a) == self.cell.get(b):
                continue
            openset.add(e)
            if len(self.route(openset)) < n0:
                openset.discard(e)
                continue
            nb += 1
        cart = self.route(openset)
        # rubble: foot-only shortcuts across the cart route
        index = {p: i for i, p in enumerate(cart)}
        want = len(cart) - spec['foot']
        cand = []
        for e in self.free_edges(openset):
            a, b = cells_of(e)
            if a in index and b in index:
                i, j = sorted((index[a], index[b]))
                if j - i >= 3:
                    cand.append((j - i - 1, i, j, e))
        cand.sort()
        options = [()] + [(c,) for c in cand]
        options += [pr for pr in combinations(cand, 2) if pr[0][2] <= pr[1][1] or pr[1][2] <= pr[0][1]]
        scored = sorted((abs(sum(o[0] for o in opt) - want) + 0.01 * len(opt), rng.random(), opt) for opt in options)
        rubble = set(o[3] for o in scored[0][2])
        foot = self.route(openset, rubble)
        return dict(spec=spec, openset=openset, cart=cart, rubble=rubble, foot=foot, base=base)

    # ---------------------------------------------------------------- picks
    def open_nbrs(self, p, openset):
        isopen = self.isopen(openset)
        return [q for q, e in self.nbrs(p) if isopen(e)]

    def pick_loot(self, res, n=6, spacing=5):
        openset, cart = res['openset'], res['cart']
        dist = self.dist_from(openset, list(cart))
        cells = sorted(((d, p) for p, d in dist.items() if p not in self.cell and len(self.open_nbrs(p, openset)) == 1), reverse=True)
        chosen = []
        for d, p in cells:
            if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= spacing for _, q in chosen):
                chosen.append((d, p))
            if len(chosen) >= n:
                break
        return [(p[0], p[1], 3 if d >= 9 else (2 if d >= 5 else 1)) for d, p in chosen]

    def pick_crabs(self, res, n, rng, take=()):
        openset, cart = res['openset'], res['cart']
        isopen = self.isopen(openset)
        cartset = set(cart)

        def cell_ok(q):
            return self.valid(*q) and not self.is_slot(q)

        def open_between(p, q):
            try:
                return isopen(edge_between(p, q))
            except ValueError:
                return False

        cands = []
        for i in range(3, len(cart) - 3):
            p = cart[i]
            din = (p[0] - cart[i - 1][0], p[1] - cart[i - 1][1])
            dout = (cart[i + 1][0] - p[0], cart[i + 1][1] - p[1])
            for dd in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if dd in (din, (-din[0], -din[1]), dout, (-dout[0], -dout[1])):
                    continue
                q = (p[0] + dd[0], p[1] + dd[1])
                if cell_ok(q) and open_between(p, q) and q not in cartset:
                    path = [p, q]
                    q2 = (q[0] + dd[0], q[1] + dd[1])
                    if cell_ok(q2) and open_between(q, q2) and q2 not in cartset:
                        path.append(q2)
                    o = (p[0] - dd[0], p[1] - dd[1])
                    if cell_ok(o) and open_between(p, o) and o not in cartset:
                        path = [o] + path
                    cands.append((i, 'cross', path))
        i = 1
        while i < len(cart) - 3:
            a, b = cart[i], cart[i + 1]
            d = (b[0] - a[0], b[1] - a[1])
            run = [a, b]
            k = i + 1
            while k + 1 < len(cart) and (cart[k + 1][0] - cart[k][0], cart[k + 1][1] - cart[k][1]) == d:
                run.append(cart[k + 1])
                k += 1
            if len(run) >= 3:
                cands.append((i + len(run) // 2, 'along', run[:4]))
            i += max(1, len(run) - 1)
        rng.shuffle(cands)
        cands.sort(key=lambda t: 0 if t[1] == 'cross' else 1)
        used = [t for t in take]
        out = []
        for i, kind, path in cands:
            if len(out) >= n:
                break
            if all(abs(i - j) >= 3 for j in used) and (kind == 'cross' or sum(1 for k in out if k[0] == 'along') < 3):
                if any(c in self.cell for c in path):
                    continue
                used.append(i)
                out.append((kind, path))
        return out

    def pick_breaks(self, rng, n=6, spacing=6, avoid=()):
        cells = [(c, r) for r in range(self.R) for c in range(self.C) if (c, r) not in self.cell and (c, r) not in avoid]
        rng.shuffle(cells)
        out = []
        for p in cells:
            if len(out) >= n:
                break
            if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= spacing for q in out):
                out.append(p)
        return out

    # ---------------------------------------------------------------- text
    def ascii_of(self, st, marks=None):
        W, H = 2 * self.C + 1, 2 * self.R + 1
        g = [[' '] * W for _ in range(H)]
        for j in range(self.R + 1):
            for i in range(self.C + 1):
                g[2 * j][2 * i] = '+'
        for (k, a, b), v in st.items():
            ch = {'wall': '#', 'rubble': 'r'}.get(v, ' ')
            if k == 'H':
                g[2 * a][2 * b + 1] = '-' if ch == '#' else ch
            else:
                g[2 * b + 1][2 * a] = '|' if ch == '#' else ch
        for (c, r), tag in self.cell.items():
            g[2 * r + 1][2 * c + 1] = 'S' if tag[0] == 'slot' else 'c'
        for (c, r), ch in (marks or {}).items():
            g[2 * r + 1][2 * c + 1] = ch
        return [''.join(row) for row in g]

    def frame_rows(self):
        return self.ascii_of(self.state)

    def render(self, openset, rubble=(), marks=None):
        st = {}
        for j in range(self.R + 1):
            for c in range(self.C):
                st[('H', j, c)] = None
        for i in range(self.C + 1):
            for r in range(self.R):
                st[('V', i, r)] = None
        for e in list(st):
            if self.state.get(e) == 'wall':
                st[e] = 'wall'
            elif self.state.get(e) == 'open' or e in openset:
                st[e] = 'open'
            elif e in rubble:
                st[e] = 'rubble'
            else:
                st[e] = 'wall'
        return self.ascii_of(st, marks)

    def show(self, res):
        marks = {p: '*' for p in res['cart']}
        for p in res['foot']:
            marks[p] = '+' if p not in marks else '*'
        print(res['spec']['name'], 'cart', len(res['cart']), 'foot', len(res['foot']), 'rubble', len(res['rubble']))
        print('\n'.join(self.render(res['openset'], res['rubble'], marks)))
