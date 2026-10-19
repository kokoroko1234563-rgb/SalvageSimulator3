"""The layout kit: describe a zone as a plan, and it writes the layout (src/shared/Layouts).

A walled zone starts as solid rock, and you carve the ground you can walk: lanes (corridors
along a line), halls and courts (open areas), and rooms in the side slots. Walls are whatever
you didn't carve, so they always meet; roofs rest on the rock either side of what they cover;
lane edges snap to the terrain's grid; a slot's door is cut through automatically. An open zone
(the shore) skips the rock and places features on open sand instead.

    from kit import Zone

    z = Zone(5, "The Shoals", rock=14)            # rock everywhere, 14 high
    f = z.frame
    f.hall([(-80, 260), (80, 260), (80, 340), (-80, 340)], roof=True, pillars=[(-24, 300), (24, 300)])
    f.lane([(-132, 240), (-132, 300)], width=12)  # up to the slot's door
    f.loot((0, 300), weight=4)

    c = z.crossing("Zigzag fords", paths=2)
    c.ramp([(-280, 0), (-280, 120), (144, 120), (144, 470), (-200, 470), (-200, 608)])
    c.lane([(-280, 120), (-280, 300), (-80, 300)], width=12)
    c.lane([(80, 300), (260, 300), (260, 608)], width=12)
    c.hazard("Sink", at=(144, 400), radius=12)

    s = z.slot("Weed cove", at=(-180, 176), size=(96, 64), door=(48, 64))
    r = s.room("Drowned pool")
    r.hall([(8, 8), (88, 8), (88, 48), (8, 48)])
    r.hollow((48, 28), radius=12, depth=3)
    r.loot((48, 28), weight=3)

    z.write("src/shared/Layouts/Zones/Zone5.luau")

Then check it in seconds:  python3 tools/kit/quick.py 5 --plan tools/kit/plans/zone5.py

Coordinates: frame and crossings in zone coordinates (x -360 to 360, z 0 at the top to 608 at
the bottom); a room in its slot's own (x 0 to the slot's width, z 0 to its depth). Heights in
studs above the beach's even slope. Every shape the layout engine knows can also be added
directly (`add(Kind=..., ...)`); see docs/design/layouts.md.
"""

import math
import os

GRID = 4  # the terrain's cells
HALF = 360  # the beach's half width
LENGTH = 608  # a zone's length
EDGE = 380  # how far past the sides the rock reaches (it runs on under the cliffs)

KINDS = ("Wall", "Ridge", "Mound", "Roof", "Channel", "Hollow", "Ramp", "Flat", "Paint")


# ---- writing Luau ------------------------------------------------------------------------------
def lua(value, indent=0):
    pad = "\t" * indent
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        v = round(value, 2)
        return str(int(v)) if v == int(v) else repr(v)
    if isinstance(value, str):
        return '"' + value.replace('"', '\\"') + '"'
    if isinstance(value, (list, tuple)):
        if all(isinstance(v, (int, float)) for v in value):
            return "{ " + ", ".join(lua(v) for v in value) + " }"
        if not value:
            return "{}"
        inner = ",\n".join(pad + "\t" + lua(v, indent + 1) for v in value)
        return "{\n" + inner + ",\n" + pad + "}"
    if isinstance(value, dict):
        if not value:
            return "{}"
        items = []
        for key, v in value.items():
            items.append(f"{key} = {lua(v, indent + 1)}")
        short = "{ " + ", ".join(items) + " }"
        if len(short) + len(pad) <= 96 and "\n" not in short:
            return short
        inner = ",\n".join(pad + "\t" + item for item in items)
        return "{\n" + inner + ",\n" + pad + "}"
    raise TypeError(f"can't write {value!r}")


# ---- geometry ----------------------------------------------------------------------------------
def snap(v, step=GRID):
    return round(v / step) * step


def lane_width(width):
    """A lane's width, so that with its centre on the grid its edges fall where walls' faces
    must (4k + 2): widths of 4 mod 8 (12, 20, 28) go with a centre on a multiple of 4."""
    w = max(8, int(math.ceil(width)))
    while w % 8 != 4:
        w += 1
    return w


def segment_box(a, b, width):
    """The four corners of the band `width` wide along a to b."""
    (ax, az), (bx, bz) = a, b
    dx, dz = bx - ax, bz - az
    length = math.hypot(dx, dz) or 1
    nx, nz = -dz / length * width / 2, dx / length * width / 2
    return [[ax + nx, az + nz], [bx + nx, bz + nz], [bx - nx, bz - nz], [ax - nx, az - nz]]


def grow(points, by):
    """A polygon pushed out from its middle by `by` studs (roughly: fine for convex shapes)."""
    cx = sum(p[0] for p in points) / len(points)
    cz = sum(p[1] for p in points) / len(points)
    out = []
    for x, z in points:
        dx, dz = x - cx, z - cz
        d = math.hypot(dx, dz) or 1
        out.append([x + dx / d * by, z + dz / d * by])
    return out


def clip(points, x0, z0, x1, z1):
    """The part of a polygon inside the box x0..x1, z0..z1 (Sutherland-Hodgman)."""
    def cut(pts, inside, cross):
        out = []
        for i, cur in enumerate(pts):
            prev = pts[i - 1]
            if inside(cur):
                if not inside(prev):
                    out.append(cross(prev, cur))
                out.append(cur)
            elif inside(prev):
                out.append(cross(prev, cur))
        return out

    def at_x(x):
        return lambda a, b: (x, a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]))

    def at_z(z):
        return lambda a, b: (a[0] + (b[0] - a[0]) * (z - a[1]) / (b[1] - a[1]), z)

    pts = list(points)
    for inside, cross in ((lambda p: p[0] >= x0, at_x(x0)), (lambda p: p[0] <= x1, at_x(x1)),
                          (lambda p: p[1] >= z0, at_z(z0)), (lambda p: p[1] <= z1, at_z(z1))):
        if not pts:
            break
        pts = cut(pts, inside, cross)
    return pts


def without(area, holes):
    """A polygon less some boxes (x0, z0, x1, z1), as polygons: Flats clear everything, so a
    hall's pillars must be left out of its Flat rather than added on top."""
    if not holes:
        return [list(area)]
    xs = [p[0] for p in area]
    zs = [p[1] for p in area]
    cuts = sorted({min(zs), max(zs)} | {v for h in holes for v in (h[1], h[3])})
    pieces = []
    for za, zb in zip(cuts, cuts[1:]):
        inside = sorted((h[0], h[2]) for h in holes if h[1] < zb and h[3] > za)
        x = min(xs)
        spans = []
        for hx0, hx1 in inside:
            if hx0 > x:
                spans.append((x, hx0))
            x = max(x, hx1)
        spans.append((x, max(xs)))
        for xa, xb in spans:
            piece = clip(area, xa, za, xb, zb)
            if len(piece) >= 3:
                pieces.append(piece)
    return pieces


def rounded(points):
    return [[round(x, 2), round(z, 2)] for x, z in points]


# ---- a part of a zone: the frame, a crossing, or a room ----------------------------------------
class Part:
    def __init__(self, zone, name=None, offset=(0, 0)):
        self.zone = zone
        self.name = name
        self.offset = offset
        self.primitives = []
        self.loots = []
        self.entrances = []
        self.hazards = []
        self.decors = []
        self.paths = None

    # -- carving (in a rock zone) --
    def lane(self, points, width=16, roof=False, floor=None, rough=0):
        """A corridor along the points, `width` wide (snapped so its edges sit on the grid).
        `roof` covers it (True, or a clearance in studs); `floor` paints its ground."""
        width = lane_width(width)
        points = [(snap(x), snap(z)) for x, z in points]
        for a, b in zip(points, points[1:]):
            box = segment_box(a, b, width)
            self.primitives.append({"Kind": "Flat", "Area": rounded(box)})
            if floor:
                self.primitives.append({"Kind": "Paint", "Area": rounded(box), "Material": floor})
        for x, z in points:
            # Round the corners where the lane turns.
            self.primitives.append({"Kind": "Flat", "At": [x, z], "Radius": width / 2})
        if roof:
            self.roof_lane(points, width, roof)
        return self

    def hall(self, area, roof=False, floor=None, pillars=(), pillar=8):
        """An open area (a polygon) carved out of the rock. `pillars` leave rock standing (posts
        `pillar` studs across) to hold up a roof and break the space."""
        area = [(snap(x, 2), snap(z, 2)) for x, z in area]
        h = pillar / 2
        holes = [(snap(x) - h, snap(z) - h, snap(x) + h, snap(z) + h) for x, z in pillars]
        for piece in without(area, holes):
            self.primitives.append({"Kind": "Flat", "Area": rounded(piece)})
        if floor:
            self.primitives.append({"Kind": "Paint", "Area": rounded(area), "Material": floor})
        if roof:
            self.roof_area(area, roof)
        return self

    court = hall  # an open-sky hall

    def door(self, at, width=16, depth=16, along="z"):
        """A gap through rock at `at`: a short lane `depth` long, across the rock `along` z
        (a wall running across the beach) or x."""
        x, z = at
        if along == "z":
            return self.lane([(x, z - depth / 2), (x, z + depth / 2)], width=width)
        return self.lane([(x - depth / 2, z), (x + depth / 2, z)], width=width)

    def roof_lane(self, points, width, clearance=True):
        rock = self.zone.rock
        clear = (rock - 2) if clearance is True else clearance
        for a, b in zip(points, points[1:]):
            # The roof is wider than the lane: it rests on the rock either side.
            box = segment_box(a, b, width + 8)
            self.primitives.append(
                {"Kind": "Roof", "Area": rounded(box), "Clearance": clear, "Thickness": 6})
        return self

    def roof_area(self, area, clearance=True):
        rock = self.zone.rock
        clear = (rock - 2) if clearance is True else clearance
        self.primitives.append(
            {"Kind": "Roof", "Area": rounded(grow(area, 4)), "Clearance": clear, "Thickness": 6})
        return self

    # -- adding (anywhere) --
    def wall(self, points, width=12, height=None, rough=0, material=None):
        p = {"Kind": "Wall", "Path": rounded(points), "Width": width,
             "Height": height or self.zone.rock or 14}
        if rough:
            p["Rough"] = min(rough, 1)
        if material:
            p["Material"] = material
        self.primitives.append(p)
        return self

    def wall_area(self, area, height=None, material=None):
        p = {"Kind": "Wall", "Area": rounded(area), "Height": height or self.zone.rock or 14}
        if material:
            p["Material"] = material
        self.primitives.append(p)
        return self

    def ridge(self, points, height=4, width=16, rock=False, rough=3):
        p = {"Kind": "Ridge", "Path": rounded(points), "Height": height, "Width": width, "Rough": rough}
        if rock:
            p["Rock"] = True
        self.primitives.append(p)
        return self

    def mound(self, at, radius=8, height=5, rock=True):
        self.primitives.append({"Kind": "Mound", "At": list(at), "Radius": radius, "Height": height,
                                "Rock": rock})
        return self

    def hollow(self, at, radius=10, depth=3, rough=3):
        self.primitives.append({"Kind": "Hollow", "At": list(at), "Radius": radius, "Depth": depth,
                                "Rough": rough})
        return self

    def channel(self, points, depth=3, width=14, rough=2):
        self.primitives.append({"Kind": "Channel", "Path": rounded(points), "Depth": depth,
                                "Width": width, "Rough": rough})
        return self

    def ramp(self, points, width=16):
        """The cart route (bare slope, cleared through everything): a Huge cart needs 14."""
        self.primitives.append({"Kind": "Ramp", "Path": rounded(points), "Width": max(width, 14)})
        return self

    def paint(self, area, material):
        self.primitives.append({"Kind": "Paint", "Area": rounded(area), "Material": material})
        return self

    def add(self, **primitive):
        assert primitive.get("Kind") in KINDS, primitive
        self.primitives.append(primitive)
        return self

    # -- placements --
    def loot(self, at, radius=6, weight=1):
        self.loots.append({"At": list(at), "Radius": radius, "Weight": weight})
        return self

    def entrance(self, at):
        self.entrances.append(list(at))
        return self

    def hazard(self, kind, **fields):
        h = {"Type": kind}
        for key, value in fields.items():
            h[key[:1].upper() + key[1:]] = list(value) if isinstance(value, tuple) else value
        if "Path" in h:
            h["Path"] = rounded(h["Path"])
        self.hazards.append(h)
        return self

    def decor(self, kind, **fields):
        d = {"Kind": kind}
        for key, value in fields.items():
            d[key[:1].upper() + key[1:]] = list(value) if isinstance(value, tuple) else value
        for key in ("Path", "Area"):
            if key in d:
                d[key] = rounded(d[key])
        self.decors.append(d)
        return self

    def table(self):
        t = {}
        if self.name is not None:
            t["Name"] = self.name
        if self.paths is not None:
            t["Paths"] = self.paths
        t["Primitives"] = self.primitives
        for key, items in (("Loot", self.loots), ("Entrances", self.entrances),
                           ("Hazards", self.hazards), ("Decor", self.decors)):
            if items:
                t[key] = items
        return t


class Slot:
    def __init__(self, zone, name, at, size, door):
        self.zone = zone
        self.name = name
        self.at = at
        self.size = size
        self.door = door
        self.rooms = []

    def room(self, name):
        """A room in the slot, in the slot's own coordinates. Its way to the door is cut for it."""
        r = Part(self.zone, name)
        if self.door is not None and self.zone.rock:
            dx, dz = self.door
            w, d = self.size
            # From the door straight into the middle of the slot.
            r.lane([(dx, dz), (w / 2, d / 2)], width=12)
        self.rooms.append(r)
        return r

    def table(self):
        return {"Name": self.name, "At": list(self.at), "Size": list(self.size),
                "Rooms": [r.table() for r in self.rooms]}


class Zone:
    def __init__(self, number, name, rock=0, material=None):
        """`rock`: a walled zone starts as rock this many studs high (0: open sand)."""
        self.number = number
        self.name = name
        self.rock = rock
        self.frame = Part(self, None)
        self.crossings = []
        self.slots = []
        if rock:
            fill = {"Kind": "Wall", "Area": [[-EDGE, -12], [EDGE, -12], [EDGE, LENGTH + 12],
                                             [-EDGE, LENGTH + 12]], "Height": rock}
            if material:
                fill["Material"] = material
            self.frame.primitives.append(fill)

    def crossing(self, name, paths=1):
        """A way through (one is rolled each tide). `paths`: how many distinct paths it has (1 to
        3), which the checks hold it to."""
        c = Part(self, name)
        c.paths = paths
        self.crossings.append(c)
        return c

    def slot(self, name, at, size, door=None):
        """A side pocket: its corner `at` (lowest x, lowest z), `size` (width, depth), and its
        door in its own coordinates, which the frame cuts through to the lane outside."""
        s = Slot(self, name, at, size, door)
        if door is not None and self.rock:
            x, z = at[0] + door[0], at[1] + door[1]
            self.frame.lane([(x, z - 8), (x, z + 8)] if door[1] in (0, size[1]) else [(x - 8, z), (x + 8, z)],
                            width=12)
        self.slots.append(s)
        return s

    def table(self):
        t = self.frame.table()
        t["Name"] = self.name
        if self.crossings:
            t["Crossings"] = [c.table() for c in self.crossings]
        if self.slots:
            t["Slots"] = [s.table() for s in self.slots]
        return t

    def write(self, path, comment=None):
        head = comment or f"-- Zone {self.number}, {self.name}: drawn with the layout kit (tools/kit)."
        text = head.rstrip() + "\n" + "return " + lua(self.table()) + "\n"
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        with open(path, "w") as f:
            f.write(text)
        return path
