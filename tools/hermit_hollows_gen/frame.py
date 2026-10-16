# Frame definition for Hermit Hollows zone 4 (cells 24 x 21).
C, R = 24, 20


def XN(i):
    return -336 + 28 * i


def ZN(j):
    return 12 + 28 * j


def XC(c):
    return -322 + 28 * c


def ZC(r):
    return 26 + 28 * r


# edge keys: ('H', j, c) between (c, j-1) and (c, j); ('V', i, r) between (i-1, r) and (i, r)
def cell_edges(c, r):
    return [('H', r, c), ('H', r + 1, c), ('V', c, r), ('V', c + 1, r)]


def other(c, r, e):
    k, a, b = e
    if k == 'H':
        return (b, a) if (c, r) == (b, a - 1) else (b, a - 1)
    return (a, b) if (c, r) == (a - 1, b) else (a - 1, b)


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


def valid(c, r):
    return 0 <= c < C and 0 <= r < R


SLOTS = [  # name, c0, c1, r0, r1, door edge
    ("Northwest nest", 0, 2, 3, 5, ('V', 3, 4)),
    ("Western midden", 0, 3, 8, 11, ('V', 4, 9)),
    ("Southwest collapse", 0, 2, 16, 19, ('V', 3, 17)),
    ("Northeast nest", 21, 23, 4, 6, ('V', 21, 5)),
    ("Eastern midden", 20, 23, 8, 11, ('V', 20, 9)),
    ("Southeast burrow", 21, 23, 16, 19, ('V', 21, 18)),
    ("South cellar", 14, 16, 17, 19, ('H', 17, 15)),
]
# name, c0, c1, r0, r1, gates
CHAMBERS = {
    'P': ("Tide basin", 20, 22, 0, 2, [('V', 20, 1), ('V', 23, 2), ('H', 3, 20), ('H', 3, 22), ('H', 0, 21)]),
    'B': ("Antler hall", 5, 7, 1, 2, [('H', 1, 6), ('V', 5, 2), ('V', 8, 1), ('H', 3, 5), ('H', 3, 7)]),
    'A': ("Brood chamber", 10, 12, 9, 11, [('H', 9, 11), ('V', 10, 10), ('V', 13, 9), ('V', 13, 11), ('H', 12, 10), ('H', 12, 12)]),
    'D': ("Throne", 11, 13, 15, 16, [('H', 15, 12), ('V', 11, 16), ('V', 14, 15), ('H', 17, 11), ('H', 17, 13)]),
    'E': ("Pearl court", 5, 7, 16, 17, [('H', 16, 6), ('V', 5, 17), ('V', 8, 16), ('H', 18, 5), ('H', 18, 7)]),
}
RIB1_DOORS = [1, 6, 10, 15, 19, 23]  # j = 7
RIB2_DOORS = [3, 8, 13, 17, 21]  # j = 14
TOP_DOORS = [3, 8, 12, 16, 21]
BOT_DOORS = [4, 7, 9, 11, 13, 17, 19]


def build_frame():
    state = {}  # edge -> 'wall' | 'open'; absent = free
    cell = {}  # (c,r) -> ('slot', k) / ('ch', X)
    for c in range(C):
        state[('H', 0, c)] = 'wall'
        state[('H', R, c)] = 'wall'
    for r in range(R):
        state[('V', 0, r)] = 'wall'
        state[('V', C, r)] = 'wall'
    for c in TOP_DOORS:
        del state[('H', 0, c)]
    for c in BOT_DOORS:
        del state[('H', R, c)]
    for j, doors in ((7, RIB1_DOORS), (14, RIB2_DOORS)):
        for c in range(C):
            state[('H', j, c)] = 'wall'
        for c in doors:
            del state[('H', j, c)]

    def block(c0, c1, r0, r1, tag, gates):
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                cell[(c, r)] = tag
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                if c < c1:
                    state[('V', c + 1, r)] = 'open'
                if r < r1:
                    state[('H', r + 1, c)] = 'open'
        for r in range(r0, r1 + 1):
            state[('V', c0, r)] = 'wall'
            state[('V', c1 + 1, r)] = 'wall'
        for c in range(c0, c1 + 1):
            state[('H', r0, c)] = 'wall'
            state[('H', r1 + 1, c)] = 'wall'
        for g in gates:
            if g in state:
                del state[g]

    for k, (name, c0, c1, r0, r1, door) in enumerate(SLOTS):
        block(c0, c1, r0, r1, ('slot', k), [])
        state[door] = 'open'
    for key, (name, c0, c1, r0, r1, gates) in CHAMBERS.items():
        block(c0, c1, r0, r1, ('ch', key), gates)
    return state, cell


def ascii_of(state, cell, extra=None, marks=None):
    """49 x 43 text. state: dict edge->'wall'/'open'/'rubble'; absent = open."""
    W, Hh = 2 * C + 1, 2 * R + 1
    g = [[' '] * W for _ in range(Hh)]
    for j in range(R + 1):
        for i in range(C + 1):
            g[2 * j][2 * i] = '+'
    for (k, a, b), v in state.items():
        ch = '#' if v == 'wall' else ('r' if v == 'rubble' else ' ')
        if k == 'H':
            g[2 * a][2 * b + 1] = '-' if ch == '#' else ch
        else:
            g[2 * b + 1][2 * a] = '|' if ch == '#' else ch
    for (c, r), tag in cell.items():
        g[2 * r + 1][2 * c + 1] = 'S' if tag[0] == 'slot' else 'c'
    if marks:
        for (c, r), ch in marks.items():
            g[2 * r + 1][2 * c + 1] = ch
    return [''.join(row) for row in g]


if __name__ == '__main__':
    st, ce = build_frame()
    print('\n'.join(ascii_of(st, ce)))
