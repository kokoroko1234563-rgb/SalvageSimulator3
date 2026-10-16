import random, sys, json
from collections import deque
from frame import *

FRAME, CELLS = build_frame()


def passable_cells():
    return [(c, r) for r in range(R) for c in range(C) if CELLS.get((c, r), ('', 0))[0] != 'slot']


def can_open(e):
    return FRAME.get(e) != 'wall'


def neighbors(p, edges=None):
    c, r = p
    out = []
    for e in cell_edges(c, r):
        k, a, b = e
        q = other(c, r, e)
        if k == 'H' and (a == 0 or a == R) and (q[1] < 0 or q[1] >= R):
            continue
        if not valid(*q):
            continue
        if CELLS.get(q, ('', 0))[0] == 'slot':
            continue
        out.append((q, e))
    return out


def bfs_path(src, dst, banned, state):
    """shortest path src->dst through cells not in banned, edges not wall in frame and not blocked in state."""
    prev = {src: None}
    dq = deque([src])
    while dq:
        p = dq.popleft()
        if p == dst:
            break
        for q, e in neighbors(p):
            if q in prev or q in banned:
                continue
            if FRAME.get(e) == 'wall':
                continue
            prev[q] = p
            dq.append(q)
    if dst not in prev:
        return None
    path = []
    p = dst
    while p is not None:
        path.append(p)
        p = prev[p]
    return path[::-1]


def backbone(waypoints):
    path = [waypoints[0]]
    for a, b in zip(waypoints, waypoints[1:]):
        banned = set(path[:-1])
        seg = bfs_path(a, b, banned, None)
        if seg is None:
            raise Exception('no path %s -> %s' % (a, b))
        path += seg[1:]
    return path


def chamber_cells(key):
    return [p for p, t in CELLS.items() if t == ('ch', key)]


def make_crossing(waypoints, top_col, bot_col, seed, bias=0.7, braids=3, rubble=None, target=None, path=None):
    rng = random.Random(seed)
    if path is None:
        path = backbone(waypoints)
    # state: edge -> 'wall'/'open'/'rubble' for non-frame-wall edges
    state = {}
    openset = set()

    def open_edge(e):
        openset.add(e)

    for a, b in zip(path, path[1:]):
        open_edge(edge_between(a, b))
    open_edge(('H', 0, top_col))
    open_edge(('H', R, bot_col))
    # chambers/slots interior edges are open by frame
    visited = set(path)
    # include whole chambers touched
    chs = {CELLS[p][1] for p in path if p in CELLS and CELLS[p][0] == 'ch'}

    def add_chamber(key):
        for p in chamber_cells(key):
            visited.add(p)
    for key in chs:
        add_chamber(key)
    lst = list(path)
    for key in chs:
        lst += chamber_cells(key)
    allcells = passable_cells()
    # growing tree
    while True:
        # candidates
        cand = [p for p in lst if any((q not in visited) and FRAME.get(e) != 'wall' for q, e in neighbors(p))]
        if not cand:
            # unvisited left?
            left = [p for p in allcells if p not in visited]
            if not left:
                break
            raise Exception('disconnected cells left: %s' % left[:5])
        if rng.random() < bias:
            # newest cand
            p = None
            for x in reversed(lst):
                if x in cand_set(cand):
                    p = x
                    break
        else:
            p = rng.choice(cand)
        opts = [(q, e) for q, e in neighbors(p) if q not in visited and FRAME.get(e) != 'wall']
        q, e = rng.choice(opts)
        open_edge(e)
        visited.add(q)
        lst.append(q)
        if q in CELLS and CELLS[q][0] == 'ch':
            key = CELLS[q][1]
            for x in chamber_cells(key):
                if x not in visited:
                    visited.add(x)
                    lst.append(x)
    return path, openset


_cs = None


def cand_set(cand):
    return set(cand)


def graph_open(openset):
    """adjacency using frame-open edges and the crossing's open set"""
    def isopen(e):
        return FRAME.get(e) == 'open' or e in openset
    return isopen


def shortest(openset, rubble=(), foot=True):
    isopen = graph_open(openset)
    src = [(c, 0) for c in range(C) if isopen(('H', 0, c)) or ('H', 0, c) in openset]
    dist = {}
    dq = deque()
    for p in src:
        if ('H', 0, p[0]) in openset:
            dist[p] = 1
            dq.append(p)
    best = None
    while dq:
        p = dq.popleft()
        c, r = p
        if r == R - 1 and ('H', R, c) in openset:
            return dist[p], p
        for q, e in neighbors(p):
            if q in dist:
                continue
            if isopen(e) or (foot and e in rubble):
                dist[q] = dist[p] + 1
                dq.append(q)
    return None, None


def render(path, openset, extra=None, rubble=()):
    st = {}
    for j in range(R + 1):
        for c in range(C):
            e = ('H', j, c)
            if FRAME.get(e) == 'wall':
                st[e] = 'wall'
            elif FRAME.get(e) == 'open' or e in openset:
                st[e] = 'open'
            elif e in rubble:
                st[e] = 'rubble'
            else:
                st[e] = 'wall'
    for i in range(C + 1):
        for r in range(R):
            e = ('V', i, r)
            if FRAME.get(e) == 'wall':
                st[e] = 'wall'
            elif FRAME.get(e) == 'open' or e in openset:
                st[e] = 'open'
            elif e in rubble:
                st[e] = 'rubble'
            else:
                st[e] = 'wall'
    marks = {p: '*' for p in path}
    if extra:
        marks.update(extra)
    return ascii_of(st, CELLS, marks=marks)


if __name__ == '__main__':
    pass
