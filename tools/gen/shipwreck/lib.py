"""Small helpers for the Shipwreck Shallows generator: shape constructors and a Lua writer."""


def simple(x):
    if isinstance(x, (int, float, str, bool, tuple)):
        return True
    return isinstance(x, list) and all(isinstance(y, (tuple, int, float)) for y in x)


def lua(v, indent=0):
    pad = "\t" * indent
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(int(v)) if float(v).is_integer() else repr(round(v, 2))
    if isinstance(v, str):
        return '"' + v.replace('"', '\\"') + '"'
    if isinstance(v, tuple):
        return "{ " + ", ".join(lua(x) for x in v) + " }"
    if isinstance(v, list):
        if all(isinstance(x, tuple) or isinstance(x, (int, float, str)) for x in v):
            return "{ " + ", ".join(lua(x) for x in v) + " }"
        inner = "".join(pad + "\t" + lua(x, indent + 1) + ",\n" for x in v)
        return "{\n" + inner + pad + "}"
    if isinstance(v, dict):
        if all(simple(x) for x in v.values()):
            return "{ " + ", ".join(k + " = " + lua(x) for k, x in v.items()) + " }"
        inner = "".join(pad + "\t" + k + " = " + lua(x, indent + 1) + ",\n" for k, x in v.items())
        return "{\n" + inner + pad + "}"
    raise TypeError(v)


def P(*pts):
    return [tuple(p) for p in pts]


def wall_x(z, x1, x2, h, w=16, **kw):
    return {"Kind": "Wall", "Path": P((x1, z), (x2, z)), "Height": h, "Width": w, **kw}


def wall_z(x, z1, z2, h, w=16, **kw):
    return {"Kind": "Wall", "Path": P((x, z1), (x, z2)), "Height": h, "Width": w, **kw}


def wall_area(pts, h, **kw):
    return {"Kind": "Wall", "Area": P(*pts), "Height": h, **kw}


def roof_area(pts, clearance, thickness=6, **kw):
    return {"Kind": "Roof", "Area": P(*pts), "Clearance": clearance, "Thickness": thickness, **kw}


def rect(x1, z1, x2, z2):
    return [(x1, z1), (x2, z1), (x2, z2), (x1, z2)]


def mound(x, z, r, h, rock=False, **kw):
    d = {"Kind": "Mound", "At": (x, z), "Radius": r, "Height": h}
    if rock:
        d["Rock"] = True
    d.update(kw)
    return d


def ridge(path, h, w, rock=False, **kw):
    d = {"Kind": "Ridge", "Path": P(*path), "Height": h, "Width": w}
    if rock:
        d["Rock"] = True
    d.update(kw)
    return d


def channel(path, depth, w, **kw):
    return {"Kind": "Channel", "Path": P(*path), "Depth": depth, "Width": w, **kw}


def hollow(x, z, r, depth, **kw):
    return {"Kind": "Hollow", "At": (x, z), "Radius": r, "Depth": depth, **kw}


def ramp(path, w=16):
    return {"Kind": "Ramp", "Path": P(*path), "Width": w}


def flat(x, z, r):
    return {"Kind": "Flat", "At": (x, z), "Radius": r}


def paint(mat, **kw):
    return {"Kind": "Paint", "Material": mat, **kw}


def loot(x, z, weight, r=6):
    return {"At": (x, z), "Radius": r, "Weight": weight}


def decor(kind, at=None, area=None, path=None, count=None, scale=None, yaw=None):
    d = {"Kind": kind}
    if at is not None:
        d["At"] = tuple(at)
    if area is not None:
        d["Area"] = P(*area)
    if path is not None:
        d["Path"] = P(*path)
    if count is not None:
        d["Count"] = count
    if scale is not None:
        d["Scale"] = scale
    if yaw is not None:
        d["Yaw"] = yaw
    return d


def shift(item, dx, dz):
    """A copy of a primitive/loot/decor entry moved by (dx, dz)."""
    out = dict(item)
    for key in ("At",):
        if key in out:
            out[key] = (out[key][0] + dx, out[key][1] + dz)
    for key in ("Path", "Area"):
        if key in out:
            out[key] = [(p[0] + dx, p[1] + dz) for p in out[key]]
    return out


def mirror(item, width):
    out = dict(item)
    if "At" in out:
        out["At"] = (width - out["At"][0], out["At"][1])
    for key in ("Path", "Area"):
        if key in out:
            out[key] = [(width - p[0], p[1]) for p in out[key]]
    return out
