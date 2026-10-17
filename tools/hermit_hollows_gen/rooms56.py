"""Side rooms for zones 5 and 6: one function per kind of room, so the three rooms of a slot differ
in shape and in what they hold. A room is drawn in its slot's own coordinates (cell centres at
14 + 28 c, 14 + 28 r)."""

import random
from collections import deque
from rooms import Room


def px(c):
    return 14 + 28 * c


def decor_cell(kind, c, r, count=1, scale=None, spread=6, dx=0, dz=0):
    x, z = px(c) + dx, px(r) + dz
    s = '{ Kind = "%s", Area = { { %d, %d }, { %d, %d }, { %d, %d }, { %d, %d } }, Count = %d' % (
        kind, x - spread, z - spread, x + spread, z - spread, x + spread, z + spread, x - spread, z + spread, count)
    if scale:
        s += ', Scale = %s' % scale
    return s + ' }'


def decor_at(kind, x, z, scale=None, yaw=None):
    s = '{ Kind = "%s", At = { %d, %d }' % (kind, x, z)
    if scale:
        s += ', Scale = %s' % scale
    if yaw is not None:
        s += ', Yaw = %d' % yaw
    return s + ' }'


def decor_path(kind, pts, count, scale=None):
    s = '{ Kind = "%s", Path = { %s }, Count = %d' % (kind, ', '.join('{ %d, %d }' % p for p in pts), count)
    if scale:
        s += ', Scale = %s' % scale
    return s + ' }'


def sand(c, r, rad, h, dx=0, dz=0):
    return 'sandMound(cx(%d) + %d, cz(%d) + %d, %d, %d)' % (c, dx, r, dz, rad, h)


def rock(c, r, rad, h, dx=0, dz=0):
    return 'rockMound(cx(%d) + %d, cz(%d) + %d, %d, %d)' % (c, dx, r, dz, rad, h)


def pond(c, r, rad, depth):
    return '{ Kind = "Hollow", At = { cx(%d), cz(%d) }, Radius = %d, Depth = %d }' % (c, r, rad, depth)


def cut(c0, r0, c1, r1, depth, width=16):
    return '{ Kind = "Channel", Path = { { cx(%d), cz(%d) }, { cx(%d), cz(%d) } }, Depth = %d, Width = %d }' % (
        c0, r0, c1, r1, depth, width)


class Room56(Room):
    def __init__(self, name, cols, rows, door, door_edge, seed):
        Room.__init__(self, name, cols, rows, door, seed)
        self.door_edge = door_edge
        self.decor = []
        self.path = []  # the room's main run from the door, for loot and crabs
        self.kind = ''

    # -- walls ------------------------------------------------------------
    def wall_at(self, e):
        k, a, b = e
        border = (k == 'H' and a in (0, self.rows)) or (k == 'V' and a in (0, self.cols))
        if border:
            return e != self.door_edge
        return e not in self.open and e not in self.rubble

    def cell_chars(self):
        """'.' where a cell stays open to the sky (fewer than two walls round it, a chamber)."""
        out = {}
        for r in range(self.rows):
            for c in range(self.cols):
                if (c, r) in self.solid:
                    continue
                walls = sum(1 for e in [('H', r, c), ('H', r + 1, c), ('V', c, r), ('V', c + 1, r)] if self.wall_at(e))
                if walls < 2 or (c, r) in self.unroofed:
                    out[(c, r)] = '.'
        return out

    def ascii(self):
        rows = Room.ascii(self)
        rows = [list(x) for x in rows]
        for (c, r), ch in self.cell_chars().items():
            rows[2 * r + 1][2 * c + 1] = ch
        return [''.join(x) for x in rows]

    # -- queries ----------------------------------------------------------
    def dist(self):
        d = {self.door: 0}
        dq = deque([self.door])
        while dq:
            x = dq.popleft()
            for q in self.nbrs(x):
                e = self.edge(x, q)
                if q not in d and (e in self.open or e in self.rubble):
                    d[q] = d[x] + 1
                    dq.append(q)
        return d

    def deep_loot(self, n=3, weights=(4, 3, 2, 1)):
        d = self.dist()
        deg = {p: sum(1 for q in self.nbrs(p) if self.edge(p, q) in self.open or self.edge(p, q) in self.rubble) for p in d}
        cells = sorted((p for p in d if p != self.door), key=lambda p: (-d[p], deg[p], p))
        # dead ends first, then the rest by depth
        cells = sorted(cells, key=lambda p: (0 if deg[p] == 1 else 1, -d[p]))
        chosen = []
        for p in cells:
            if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= 2 for q in chosen):
                chosen.append(p)
            if len(chosen) >= n:
                break
        chosen.sort(key=lambda p: -d[p])
        self.loot = [(p[0], p[1], weights[i]) for i, p in enumerate(chosen)]

    def longest_path(self, start, budget=60000):
        best = [start]
        rng = self.rng
        count = [0]
        seen = {start}
        cur = [start]

        def go():
            nonlocal best
            count[0] += 1
            if count[0] > budget:
                return
            if len(cur) > len(best):
                best = list(cur)
            if len(best) == len([1 for r in range(self.rows) for c in range(self.cols) if (c, r) not in self.solid]):
                return
            opts = [q for q in self.nbrs(cur[-1]) if q not in seen]
            rng.shuffle(opts)
            for q in opts:
                seen.add(q)
                cur.append(q)
                go()
                cur.pop()
                seen.discard(q)
                if count[0] > budget:
                    return

        go()
        return best

    def crab_on(self, path, start=1):
        """A crab on the first straight run of two or more steps in `path`."""
        for i in range(start, len(path) - 2):
            a, b, c = path[i], path[i + 1], path[i + 2]
            if (b[0] - a[0], b[1] - a[1]) == (c[0] - b[0], c[1] - b[1]):
                self.crabs.append([a, c])
                return True
        return False

    def inner(self):
        return [(c, r) for r in range(self.rows) for c in range(self.cols) if (c, r) not in self.solid]

    def lua(self, indent='\t\t\t'):
        txt = Room.lua(self, indent)
        if self.decor:
            t = indent + '\t'
            block = t + 'Decor = {\n' + ''.join(t + '\t' + d + ',\n' for d in self.decor) + t + '},\n'
            idx = txt.rindex(indent + '},')
            txt = txt[:idx] + block + txt[idx:]
        return txt


# ------------------------------------------------------------------------------------- kinds
def make(kind, name, cols, rows, door, door_edge, seed, style):
    """style: dict(zone=5|6) with the zone's flavour."""
    r = Room56(name, cols, rows, door, door_edge, seed)
    r.kind = kind
    globals()['k_' + kind](r, style)
    return r


def door_decor(r, style):
    d = r.door
    k = r.kind
    pick = {
        'nest': [('Bones', 1)],
        'midden': [('Shells', 3), ('Urchins', 1)],
        'pool': [('Weed', 2), ('Kelp', 1)],
        'cut': [('Kelp', 2)],
        'loop': [('Pebbles', 3), ('Shells', 2)],
        'scramble': [('DeadCoral', 1), ('Pebbles', 3)],
        'warren': [('Chain', 1)],
        'gallery': [('Timber', 1)],
        'collapse': [('Timber', 1), ('Pebbles', 3)],
        'dead': [('Bones', 1), ('Shells', 2)],
    }[k]
    for kind, n in pick:
        r.decor.append(decor_cell(kind, d[0], d[1], n))
    if style['zone'] == 6 and k in ('nest', 'dead', 'loop'):
        r.decor.append(decor_cell('GlowShells', d[0], d[1], 1, spread=4))
    if style['zone'] == 5 and k in ('pool', 'cut'):
        r.decor.append(decor_cell('GlowWeed', d[0], d[1], 1, spread=4))


def vault_decor(r, style, cell, bones=True):
    c, rr = cell
    if bones:
        r.decor.append(decor_cell('Bones', c, rr, 1))
    r.decor.append(decor_cell('Shells', c, rr, 4))
    r.decor.append(decor_cell('GlowShells', c, rr, 1, spread=3))


def k_nest(r, style):
    """A tunnel in a spiral to a vault: the best finds at its end."""
    p = r.longest_path(r.door)
    r.carve(*p)
    r.path = p
    r.unroofed.add(p[-1])
    r.finish()
    r.crab_on(p)
    r.deep_loot(3)
    vault_decor(r, style, p[-1])
    door_decor(r, style)


def k_midden(r, style):
    """Open sand, shell heaps and boulders."""
    r.whole(False)
    cells = [p for p in r.inner() if p != r.door]
    r.rng.shuffle(cells)
    for i, p in enumerate(cells[:3]):
        r.extra.append(sand(p[0], p[1], 9, 6, 4 * (i - 1), 3))
    p = cells[3]
    r.extra.append(rock(p[0], p[1], 7, 8))
    for p in cells[4:8]:
        r.decor.append(decor_cell('Shells', p[0], p[1], 3))
    r.decor.append(decor_cell('Urchins', cells[8][0], cells[8][1], 2))
    r.deep_loot(3, (3, 2, 1))
    r.crab_on(r.inner(), 0) if False else None
    # a crab along the far row
    far = max(r.inner(), key=lambda p: abs(p[0] - r.door[0]) + abs(p[1] - r.door[1]))
    row = [q for q in r.inner() if q[1] == far[1]]
    if len(row) >= 3:
        row.sort()
        r.crabs.append([row[0], row[-1]])
    door_decor(r, style)


def k_pool(r, style):
    """A sunken pool in the middle of an open chamber: the sea takes it first."""
    r.whole(False)
    mid = (r.cols // 2, r.rows // 2)
    r.extra.append(pond(mid[0], mid[1], 20 if r.cols >= 4 else 18, 3))
    corners = [(0, 0), (r.cols - 1, 0), (0, r.rows - 1), (r.cols - 1, r.rows - 1)]
    far = [p for p in corners if p != r.door]
    r.loot = [(far[0][0], far[0][1], 4), (far[-1][0], far[-1][1], 2)]
    if len(far) > 2:
        r.loot.append((far[1][0], far[1][1], 3))
    for p in far[:2]:
        r.decor.append(decor_cell('Kelp', p[0], p[1], 2))
        r.decor.append(decor_cell('Weed', p[0], p[1], 2))
    if r.rows >= 3:
        r.crabs.append([(0, r.rows - 1), (r.cols - 1, r.rows - 1)] if r.door[1] != r.rows - 1 else [(0, 0), (r.cols - 1, 0)])
    door_decor(r, style)


def k_cut(r, style):
    """An open chamber with a sunk channel across it: you wade, or go round."""
    r.whole(False)
    horizontal = r.door[0] in (0, r.cols - 1)  # door on a side wall: cut runs door to far wall
    if horizontal:
        mid = max(0, min(r.rows - 1, r.rows // 2 + (1 if r.door[1] <= r.rows // 2 and r.rows > 2 else 0)))
        r.extra.append(cut(0, mid, r.cols - 1, mid, 3))
        beyond = [p for p in r.inner() if abs(p[0] - r.door[0]) >= r.cols - 1 and p[1] != mid]
    else:
        mid = r.cols // 2
        r.extra.append(cut(mid, 0, mid, r.rows - 1, 3))
        beyond = [p for p in r.inner() if abs(p[1] - r.door[1]) >= r.rows - 1 and p[0] != mid]
    r.loot = []
    far = sorted(beyond, key=lambda p: -(abs(p[0] - r.door[0]) + abs(p[1] - r.door[1])))
    for i, p in enumerate(far[:3]):
        r.loot.append((p[0], p[1], (4, 3, 2)[i]))
    for p in far[:2]:
        r.decor.append(decor_cell('Kelp', p[0], p[1], 3))
    r.decor.append(decor_cell('Weed', r.cols // 2, r.rows // 2, 4, spread=8))
    if horizontal:
        r.crabs.append([(0, 0 if mid != 0 else r.rows - 1), (r.cols - 1, 0 if mid != 0 else r.rows - 1)])
    door_decor(r, style)


def k_loop(r, style):
    """A ring corridor round a solid core, a vault in the corner, crabs on the long sides."""
    core = {(c, rr) for c in range(1, r.cols - 1) for rr in range(1, r.rows - 1)}
    r.make_solid(core)
    ring = []
    c, rr = 0, 0
    while (c, rr) != (r.cols - 1, 0):
        ring.append((c, rr))
        c += 1
    while (c, rr) != (r.cols - 1, r.rows - 1):
        ring.append((c, rr))
        rr += 1
    while (c, rr) != (0, r.rows - 1):
        ring.append((c, rr))
        c -= 1
    while (c, rr) != (0, 0):
        ring.append((c, rr))
        rr -= 1
    ring.append((0, 0))
    r.carve(*ring)
    r.carve(ring[-1], ring[0])
    r.path = ring
    d = r.dist()
    far = max(d, key=lambda p: d[p])
    r.loot = [(far[0], far[1], 4)]
    others = sorted((p for p in d if p not in (far, r.door)), key=lambda p: -d[p])
    for i, p in enumerate(others[:2]):
        r.loot.append((p[0], p[1], 2 + (1 - i)))
    top = [(c, 0) for c in range(r.cols)]
    bottom = [(c, r.rows - 1) for c in range(r.cols)]
    for run in (top, bottom):
        if r.door not in run:
            r.crabs.append([run[0], run[-1]])
    r.decor.append(decor_cell('Bones', far[0], far[1], 1))
    r.decor.append(decor_cell('Shells', far[0], far[1], 4))
    # the core's middle holds a boulder-strewn courtyard (outside, on the walls: barnacles)
    door_decor(r, style)


def k_warren(r, style):
    """Snaking tunnels with crabs, dead ends on the way."""
    p = r.longest_path(r.door)
    r.carve(*p)
    r.path = p
    r.finish()
    r.crab_on(p)
    r.crab_on(p[len(p) // 2:], 0)
    r.deep_loot(3)
    r.decor.append(decor_path('Pebbles', [(px(p[2][0]), px(p[2][1])), (px(p[4][0]), px(p[4][1]))], 4) if len(p) > 4 else decor_cell('Pebbles', p[-1][0], p[-1][1], 3))
    r.decor.append(decor_cell('Chain', p[-1][0], p[-1][1], 1))
    r.decor.append(decor_cell('Shells', p[-1][0], p[-1][1], 3))
    door_decor(r, style)


def k_gallery(r, style):
    """A long gallery, caved in once: a rubble pile across it, the best finds beyond."""
    p = r.longest_path(r.door)
    cut_at = max(2, len(p) // 2)
    for i, (a, b) in enumerate(zip(p, p[1:])):
        if i == cut_at:
            r.rub(a, b)
        else:
            r.open.add(r.edge(a, b))
    r.path = p
    r.finish()
    r.deep_loot(3)
    r.decor.append(decor_cell('Timber', p[cut_at][0], p[cut_at][1], 2))
    r.decor.append(decor_cell('Pebbles', p[cut_at][0], p[cut_at][1], 5))
    r.decor.append(decor_cell('Bones', p[-1][0], p[-1][1], 1))
    r.decor.append(decor_cell('Shells', p[-1][0], p[-1][1], 3))
    door_decor(r, style)


def k_collapse(r, style):
    """An open chamber, a fallen bar of rock across it, boulders: the finds lie behind."""
    r.whole(False)
    door = r.door
    if door[0] in (0, r.cols - 1):
        mid = r.cols // 2
        if mid == door[0]:
            mid = max(1, mid - 1)
        x = px(mid) + 4
        r.extra.append('{ Kind = "Ridge", Path = { { %d, cz(0) - 10 }, { %d, cz(%d) + 10 } }, Height = 4.2, Width = 24 }' % (x, x, r.rows - 1))
        behind = [p for p in r.inner() if (p[0] - mid) * (door[0] - mid) < 0]
    else:
        mid = r.rows // 2
        if mid == door[1]:
            mid = max(1, mid - 1)
        z = px(mid) + 4
        r.extra.append('{ Kind = "Ridge", Path = { { cx(0) - 10, %d }, { cx(%d) + 10, %d } }, Height = 4.2, Width = 24 }' % (z, r.cols - 1, z))
        behind = [p for p in r.inner() if (p[1] - mid) * (door[1] - mid) < 0]
    behind.sort(key=lambda p: -(abs(p[0] - door[0]) + abs(p[1] - door[1])))
    r.loot = [(p[0], p[1], w) for p, w in zip(behind, (4, 3, 2))]
    front = [p for p in r.inner() if p not in behind and p != door]
    if front:
        p = front[-1]
        r.extra.append(rock(p[0], p[1], 7, 9))
    for p in behind[:2]:
        r.decor.append(decor_cell('Pebbles', p[0], p[1], 4))
        r.decor.append(decor_cell('Bones', p[0], p[1], 1))
    r.crabs.append([behind[0], behind[min(len(behind) - 1, 2)]] if len(behind) > 2 and behind[0][0] == behind[2][0] or len(behind) > 2 and behind[0][1] == behind[2][1] else [behind[0], behind[1]])
    door_decor(r, style)


def k_scramble(r, style):
    """A field of boulders: you pick your way, the best find at the far corner."""
    r.whole(False)
    cells = [p for p in r.inner() if p != r.door]
    far = max(cells, key=lambda p: abs(p[0] - r.door[0]) + abs(p[1] - r.door[1]))
    pool = [p for p in cells if p != far and abs(p[0] - far[0]) + abs(p[1] - far[1]) > 1]
    r.rng.shuffle(pool)
    n = max(4, len(cells) // 3)
    for i, p in enumerate(pool[:n]):
        r.extra.append(rock(p[0], p[1], 7, 10 + (i % 2), (i % 3 - 1) * 3, ((i + 1) % 3 - 1) * 3))
    r.loot = [(far[0], far[1], 4)]
    rest = sorted((p for p in cells if p != far), key=lambda p: -(abs(p[0] - r.door[0]) + abs(p[1] - r.door[1])))
    for i, p in enumerate(rest[:2]):
        if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= 2 for q in [far]):
            r.loot.append((p[0], p[1], 3 - i))
    r.decor.append(decor_cell('DeadCoral', far[0], far[1], 2))
    r.decor.append(decor_cell('Shells', far[0], far[1], 3))
    door_decor(r, style)


def k_dead(r, style):
    """A tangle of dead-end tunnels: every wrong turn ends in a pocket of shells."""
    r.finish()
    r.path = []
    d = r.dist()
    r.deep_loot(3)
    ends = [p for p in d if p != r.door and sum(1 for q in r.nbrs(p) if r.edge(p, q) in r.open) == 1]
    for p in ends[:3]:
        r.decor.append(decor_cell('Shells', p[0], p[1], 3))
    if ends:
        r.decor.append(decor_cell('Bones', ends[0][0], ends[0][1], 1))
    near = sorted((p for p in d if p != r.door), key=lambda p: d[p])
    for p in near:
        if any((p[0] + q[0], p[1] + q[1]) in d and r.edge(p, (p[0] + q[0], p[1] + q[1])) in r.open and r.edge(p, (p[0] + 2 * q[0], p[1] + 2 * q[1])) in r.open if (p[0] + 2 * q[0], p[1] + 2 * q[1]) in d else False for q in ((1, 0), (0, 1))):
            break
    door_decor(r, style)
