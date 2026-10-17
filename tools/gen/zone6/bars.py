"""Break up the walls across the zone's top and bottom edges.

The frame's bars at the top (picture row 0) and the bottom (the last row) ran nearly the full
width with a few gates; each crossing plugged the gates it didn't want. Here the frame's bars
are cleared and each crossing draws its own: the union it had before, with a niche or an
opening cut into every run longer than MAXRUN cells. A niche is a cell opened to the edge and
walled off from the maze (a dead end for loot); an opening is a cell opened onto the maze. Both
are only kept where the shortest way across (in cells, rubble crossed) doesn't change by more
than SLACK, so the crossings' times stay near what they were.
Run once: python3 tools/gen/zone6/bars.py --apply  (rewrites Zone6.luau's pictures)
"""
import sys, pathlib

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import maze

MAXRUN = 4
SLACK = 6  # cells the way across may get shorter (crossings 2 and 5 were over time)


def e(a, b):
    return frozenset((a, b))


def runs(walls):
    out, c = [], 0
    while c < len(walls):
        if walls[c]:
            s = c
            while c < len(walls) and walls[c]:
                c += 1
            out.append((s, c - 1))
        else:
            c += 1
    return out


def ok(g, base, base_nr, reach):
    a, b = g.shortest(), g.shortest(False)
    return len(g.reachable()) >= reach and a is not None and b is not None and base - SLACK <= a <= base + 2 and base_nr - SLACK <= b <= base_nr + 4


def process(pics, n):
    g = maze.zone_grid(pics, n)
    base, base_nr = g.shortest(), g.shortest(False)
    reach = len(g.reachable())
    added = []  # edges added to the walls beyond the union
    for side, row in ((-1, 0), (maze.H, maze.H - 1)):
        stuck = set()
        inner = row + 1 if side < 0 else row - 1
        for _ in range(40):
            walls = [e((c, row), (c, side)) in g.wall for c in range(maze.W)]
            long_runs = [(s, t) for s, t in runs(walls) if t - s + 1 > MAXRUN and (s, t) not in stuck]
            if not long_runs:
                break
            s, t = max(long_runs, key=lambda x: x[1] - x[0])
            cand = sorted(range(s, t + 1), key=lambda c: abs(c - (s + t) / 2))
            done = False
            sides = lambda c: [(c - 1, row), (c + 1, row), (c, inner)]
            for keep in ((0, 1, 2), (0, 2), (1, 2), (0, 1), (2,), (0,), (1,), ()):
                for c in cand:
                    saved = set(g.wall)
                    g.wall.discard(e((c, row), (c, side)))
                    for k in keep:
                        o = sides(c)[k]
                        if 0 <= o[0] < maze.W and e((c, row), o) not in g.wall:
                            g.wall.add(e((c, row), o))
                            added.append(e((c, row), o))
                    if ok(g, base, base_nr, reach):
                        done = True
                        break
                    g.wall = saved
                    added = [x for x in added if x in g.wall]
                if done:
                    break
            if not done:
                stuck.add((s, t))
    return g, added


def put(lines, a, b, ch):
    """Set the picture character for the edge between cells a and b."""
    (c1, r1), (c2, r2) = sorted((a, b), key=lambda p: (p[1], p[0]))
    if c1 == c2:  # horizontal wall on node row r2
        row = 2 * r2
        i = 3 * c1 + 1
        line = lines[row]
        lines[row] = line[:i] + ch * 2 + line[i + 2 :]
    else:
        row = 2 * r1 + 1
        i = 3 * c2
        line = lines[row]
        lines[row] = line[:i] + ch + line[i + 1 :]


def main():
    text = maze.SRC.read_text()
    pics = maze.pictures(text)
    result = {}
    for n in range(1, 6):
        g, added = process(pics, n)
        old = maze.zone_grid(pics, n)
        print(n, "shortest", old.shortest(), "->", g.shortest(), "no rubble", old.shortest(False), "->", g.shortest(False))
        lines = list(pics["CROSSING%d" % n])
        # rewrite the crossing's top and bottom rows from the new union; add the niche walls
        for side, row, art_row in ((-1, 0, 0), (maze.H, maze.H - 1, 2 * maze.H)):
            for c in range(maze.W):
                edge = e((c, row), (c, side))
                put(lines, (c, row), (c, side), "-" if edge in g.wall else " ")
        for edge in added:
            a, b = sorted(edge)
            if 0 <= a[1] < maze.H and 0 <= b[1] < maze.H:
                put(lines, a, b, "|" if a[1] == b[1] else "-")
        result["CROSSING%d" % n] = lines
        top = "".join("#" if e((c, 0), (c, -1)) in g.wall else "." for c in range(maze.W))
        bot = "".join("#" if e((c, maze.H - 1), (c, maze.H)) in g.wall else "." for c in range(maze.W))
        print("  top", top, "bottom", bot)
    frame = list(pics["FRAME"])
    for c in range(maze.W):
        put(frame, (c, 0), (c, -1), " ")
        put(frame, (c, maze.H - 1), (c, maze.H), " ")
    result["FRAME"] = frame
    if "--apply" not in sys.argv:
        return
    for name, lines in result.items():
        start = text.index("local %s = {\n" % name)
        end = text.index("\n}\n", start)
        body = "\n".join('\t"' + l + '",' for l in lines)
        text = text[:start] + "local %s = {\n" % name + body + text[end:]
    maze.SRC.write_text(text)


main()
