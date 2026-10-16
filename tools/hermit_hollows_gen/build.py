import json, random, sys
from collections import deque
from gen import *


def isopen_fn(openset):
    return lambda e: FRAME.get(e) == 'open' or e in openset


POOLBAN = {(21, 1), (21, 2)}


def bfs(openset, rubble=(), banned=POOLBAN):
    isopen = isopen_fn(openset)
    tops = [(c, 0) for c in range(C) if ('H', 0, c) in openset]
    assert len(tops) == 1, tops
    src = tops[0]
    prev = {src: None}
    dq = deque([src])
    end = None
    while dq:
        p = dq.popleft()
        if p[1] == R - 1 and ('H', R, p[0]) in openset:
            end = p
            break
        for q, e in neighbors(p):
            if q in prev or q in banned:
                continue
            if isopen(e) or e in rubble:
                prev[q] = p
                dq.append(q)
    if end is None:
        return None
    path = []
    p = end
    while p is not None:
        path.append(p)
        p = prev[p]
    return path[::-1]


def dist_from(openset, sources):
    isopen = isopen_fn(openset)
    dist = {s: 0 for s in sources}
    dq = deque(sources)
    while dq:
        p = dq.popleft()
        for q, e in neighbors(p):
            if q in dist:
                continue
            if isopen(e):
                dist[q] = dist[p] + 1
                dq.append(q)
    return dist


def free_edges(openset):
    out = []
    for j in range(1, R):
        for c in range(C):
            e = ('H', j, c)
            if FRAME.get(e) is None and e not in openset:
                a, b = (c, j - 1), (c, j)
                if CELLS.get(a, ('',))[0] != 'slot' and CELLS.get(b, ('',))[0] != 'slot':
                    out.append(e)
    for i in range(1, C):
        for r in range(R):
            e = ('V', i, r)
            if FRAME.get(e) is None and e not in openset:
                a, b = (i - 1, r), (i, r)
                if CELLS.get(a, ('',))[0] != 'slot' and CELLS.get(b, ('',))[0] != 'slot':
                    out.append(e)
    return out


def cells_of(e):
    k, a, b = e
    return ((b, a - 1), (b, a)) if k == 'H' else ((a - 1, b), (a, b))


def pad(path, target, rng, avoid=POOLBAN):
    path = list(path)
    tries = 0
    while len(path) < target and tries < 2000:
        tries += 1
        i = rng.randrange(1, len(path) - 3)
        j = i + 2
        # extend run while collinear
        d = (path[i + 1][0] - path[i][0], path[i + 1][1] - path[i][1])
        while j + 1 < len(path) - 1 and (path[j + 1][0] - path[j][0], path[j + 1][1] - path[j][1]) == d and rng.random() < 0.7:
            j += 1
        if any((path[k + 1][0] - path[k][0], path[k + 1][1] - path[k][1]) != d for k in range(i, j)):
            continue
        s = rng.choice([(d[1], d[0]), (-d[1], -d[0])])
        new = [path[i]]
        ok = True
        for k in range(i, j + 1):
            q = (path[k][0] + s[0], path[k][1] + s[1])
            new.append(q)
        new.append(path[j])
        pset = set(path)
        for q in new[1:-1]:
            if not valid(*q) or q in pset or CELLS.get(q, ('',))[0] == 'slot' or q in avoid:
                ok = False
        if not ok:
            continue
        # edge legality
        for a, b in zip(new, new[1:]):
            try:
                e = edge_between(a, b)
            except ValueError:
                ok = False
                break
            if FRAME.get(e) == 'wall':
                ok = False
                break
        if not ok:
            continue
        # chambers: avoid bumps into chamber cells (keep chambers whole)
        if any(q in CELLS for q in new[1:-1]):
            continue
        path = path[:i] + new + path[j + 1:]
    return path


def build(spec):
    rng = random.Random(spec['seed'] * 7919)
    base_path = backbone(spec['wps'])
    if spec.get('cart'):
        base_path = pad(base_path, spec['cart'], random.Random(spec['seed']))
    path, openset = make_crossing(None, spec['top'], spec['bot'], spec['seed'], spec.get('bias', 0.7), path=base_path)
    openset = set(openset)
    cart = bfs(openset)
    base = len(cart)
    # braids: extra loops that don't shorten the cart route
    cands = free_edges(openset)
    rng.shuffle(cands)
    nb = 0
    for e in cands:
        if nb >= spec.get('braids', 6):
            break
        a, b = cells_of(e)
        if CELLS.get(a) and CELLS.get(a) == CELLS.get(b):
            continue
        openset.add(e)
        if len(bfs(openset)) < base:
            openset.discard(e)
            continue
        nb += 1
    cart = bfs(openset)
    # rubble: foot-only shortcuts across the cart route
    index = {p: i for i, p in enumerate(cart)}
    want = len(cart) - spec['foot']
    cand = []
    for e in free_edges(openset):
        a, b = cells_of(e)
        if a in index and b in index:
            i, j = sorted((index[a], index[b]))
            if j - i >= 3:
                cand.append((j - i - 1, i, j, e))
    best = None
    rub = []
    cand.sort()
    # choose up to 3 disjoint intervals with total savings closest to want
    import itertools
    options = [()]
    options += [(c,) for c in cand]
    options += [pair for pair in itertools.combinations(cand, 2) if pair[0][2] <= pair[1][1] or pair[1][2] <= pair[0][1]]
    scored = []
    for opt in options:
        sv = sum(o[0] for o in opt)
        scored.append((abs(sv - want) + 0.01 * len(opt), rng.random(), opt))
    scored.sort()
    opt = scored[0][2]
    rubble = set(o[3] for o in opt)
    foot = bfs(openset, rubble)
    return dict(spec=spec, openset=openset, cart=cart, rubble=rubble, foot=foot, rng=rng)


def corners(path):
    out = [path[0]]
    for i in range(1, len(path) - 1):
        a, b, c = path[i - 1], path[i], path[i + 1]
        if (b[0] - a[0], b[1] - a[1]) != (c[0] - b[0], c[1] - b[1]):
            out.append(b)
    out.append(path[-1])
    return out


def show(res):
    path = res['cart']
    marks = {p: '*' for p in path}
    for p in res['foot']:
        marks[p] = '+' if p not in marks else '*'
    print(res['spec']['name'], 'cart', len(res['cart']), 'foot', len(res['foot']), 'rubble', len(res['rubble']))
    print('\n'.join(render([], res['openset'], extra=marks, rubble=res['rubble'])))


if __name__ == '__main__':
    from specs import SPECS
    for sp in SPECS:
        r = build(sp)
        show(r)
