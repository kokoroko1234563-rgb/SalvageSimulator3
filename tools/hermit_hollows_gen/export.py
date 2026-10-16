import random, os
from build import *
import specs


def isopen_for(openset):
    return isopen_fn(openset)


def deg_open(p, openset):
    isopen = isopen_fn(openset)
    return [q for q, e in neighbors(p) if isopen(e)]


def pick_loot(res, n=6):
    openset = res['openset']
    cart = res['cart']
    dist = dist_from(openset, list(cart))
    cells = []
    for p, d in dist.items():
        if p in CELLS:
            continue
        if len(deg_open(p, openset)) == 1:
            cells.append((d, p))
    cells.sort(reverse=True)
    chosen = []
    for d, p in cells:
        if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= 5 for _, q in chosen):
            chosen.append((d, p))
        if len(chosen) >= n:
            break
    out = []
    for d, p in chosen:
        w = 3 if d >= 9 else (2 if d >= 5 else 1)
        out.append((p[0], p[1], w))
    return out


def collinear_run(cart, i):
    """cells around index i that are collinear: returns list of cells"""
    a, b = cart[i], cart[i + 1]
    d = (b[0] - a[0], b[1] - a[1])
    run = [a, b]
    k = i + 1
    while k + 1 < len(cart) and (cart[k + 1][0] - cart[k][0], cart[k + 1][1] - cart[k][1]) == d:
        run.append(cart[k + 1])
        k += 1
    return run


def pick_crabs(res, n=10, rng=None):
    rng = rng or random.Random(5)
    openset = res['openset']
    cart = res['cart']
    isopen = isopen_fn(openset)
    cartset = set(cart)
    used = []  # indices used
    out = []

    def cell_ok(q):
        return valid(*q) and CELLS.get(q, ('',))[0] != 'slot'

    def open_between(p, q):
        try:
            e = edge_between(p, q)
        except ValueError:
            return False
        return isopen(e)

    cands = []
    for i in range(3, len(cart) - 3):
        p = cart[i]
        # skip rubble edges
        din = (p[0] - cart[i - 1][0], p[1] - cart[i - 1][1])
        dout = (cart[i + 1][0] - p[0], cart[i + 1][1] - p[1])
        for dd in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if dd == din or dd == (-din[0], -din[1]) or dd == dout or dd == (-dout[0], -dout[1]):
                continue
            q = (p[0] + dd[0], p[1] + dd[1])
            if cell_ok(q) and open_between(p, q) and q not in cartset:
                # branch: crab from p into branch, up to 2 cells deep
                path = [p, q]
                q2 = (q[0] + dd[0], q[1] + dd[1])
                if cell_ok(q2) and open_between(q, q2) and q2 not in cartset:
                    path.append(q2)
                # and the other side if open
                o = (p[0] - dd[0], p[1] - dd[1])
                if cell_ok(o) and open_between(p, o) and o not in cartset:
                    path = [o] + path
                cands.append((i, 'cross', path))
    # along-route stretches
    i = 1
    while i < len(cart) - 3:
        run = collinear_run(cart, i)
        if len(run) >= 3:
            cands.append((i + len(run) // 2, 'along', run[:4] if len(run) > 4 else run))
        i += max(1, len(run) - 1)
    rng.shuffle(cands)
    cands.sort(key=lambda t: 0 if t[1] == 'cross' else 1)
    for i, kind, path in cands:
        if len(out) >= n:
            break
        if all(abs(i - j) >= 3 for j in used) and (kind == 'cross' or sum(1 for k in out if k[0] == 'along') < 3):
            # a crab patrol shouldn't start in a chamber door region of pool cells
            if any(c in CELLS for c in path):
                continue
            used.append(i)
            out.append((kind, path))
    return out


def pick_breaks(res, rng):
    cart = res['cart']
    openset = res['openset']
    cells = []
    for r in range(R):
        for c in range(C):
            p = (c, r)
            if p in CELLS:
                continue
            cells.append(p)
    rng.shuffle(cells)
    out = []
    for p in cells:
        if len(out) >= 6:
            break
        if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= 6 for q in out):
            out.append(p)
    return out


def lua_cells(path):
    return '{ ' + ', '.join('{%d, %d}' % p for p in path) + ' }'


def emit_crossing(res, rng):
    sp = res['spec']
    cart = res['cart']
    breaks = pick_breaks(res, rng)
    marks = {p: '.' for p in breaks}
    rows = render([], res['openset'], extra=marks, rubble=res['rubble'])
    ramp = corners(cart)
    top = sp['top']
    bot = sp['bot']
    loot = pick_loot(res)
    crabs = pick_crabs(res, sp.get('crabs', 10), rng)
    s = []
    s.append('\t{')
    s.append('\t\tName = "%s",' % sp['name'])
    s.append('\t\tMaze = {')
    for row in rows:
        s.append('\t\t\t"%s",' % row)
    s.append('\t\t},')
    s.append('\t\tRamp = %s,' % lua_cells(ramp))
    s.append('\t\tLoot = %s,' % ('{ ' + ', '.join('{%d, %d, %d}' % t for t in loot) + ' }'))
    s.append('\t\tCrabs = {')
    for kind, path in crabs:
        s.append('\t\t\t%s,' % lua_cells(path))
    s.append('\t\t},')
    s.append('\t},')
    return '\n'.join(s), dict(loot=loot, crabs=crabs, breaks=breaks, ramp=ramp)


if __name__ == '__main__':
    st, ce = build_frame()
    frame_rows = ascii_of(st, ce)
    out = []
    out.append('local FRAME = {')
    for row in frame_rows:
        out.append('\t"%s",' % row)
    out.append('}')
    out.append('')
    out.append('local CROSSINGS = {')
    infos = []
    for sp in specs.SPECS:
        res = build(sp)
        rng = random.Random(sp['seed'])
        text, info = emit_crossing(res, rng)
        out.append(text)
        infos.append((sp['name'], len(res['cart']), len(res['foot']), len(info['crabs']), len(info['loot'])))
    out.append('}')
    open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data.lua'), 'w').write('\n'.join(out) + '\n')
    for i in infos:
        print(i)
