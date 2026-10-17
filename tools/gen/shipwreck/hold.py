"""Rooms and the wreck's hull for Shipwreck Shallows, zones 4 to 6 (walls and roofs allowed)."""

from lib import *

W = 116  # a pocket's width (x), slot coordinates; the door is on the east edge for a west pocket


# ---- the hull ---------------------------------------------------------------------------------
HX = -60  # the hull's centre line
HULL_W, HULL_E = -86, -34  # side wall centre lines (16 wide: faces -94/-78 and -42/-26)


def hull(zs, zb, h, longer=False):
    """The big wreck, lying with its stern at zs and its bow at zb. Returns (prims, loot, decor).

    Stern door in the transom, a roofed cabin, bulkheads with doors on alternate sides, a breach
    in each side, a solid prow. A ramp through x = HX cuts straight through all of it."""
    hh = h - 2
    mat = "Pavement"
    zbs = zb - 52  # where the side walls end and the prow begins
    b1, b2, b3 = zs + 56, zs + 100, zs + 144
    prims = []
    # Transom with its door [-70, -50].
    prims.append(wall_x(zs, -94, -70, hh, 16, Material=mat))
    prims.append(wall_x(zs, -50, -26, hh, 16, Material=mat))
    # Side walls, with breaches: west in the second compartment, east in the third.
    prims.append(wall_z(HULL_W, zs, zs + 64, hh, 16, Material=mat))
    prims.append(wall_z(HULL_W, zs + 88, zbs, hh, 16, Material=mat))
    prims.append(wall_z(HULL_E, zs, zs + 108, hh, 16, Material=mat))
    prims.append(wall_z(HULL_E, zs + 132, zbs, hh, 16, Material=mat))
    # Bulkheads: doors alternate west [-78, -62] and east [-58, -42].
    prims.append(wall_x(b1, -62, -38, hh, 16, Material=mat))
    prims.append(wall_x(b2, -82, -58, hh, 16, Material=mat))
    if longer and b3 + 20 < zbs:
        prims.append(wall_x(b3, -62, -38, hh, 16, Material=mat))
    # The prow, solid.
    prims.append(
        wall_area([(-94, zbs - 4), (-26, zbs - 4), (-38, zb - 14), (-60, zb), (-82, zb - 14)], hh, Material=mat)
    )
    # The cabin's roof: exactly on the transom, the side walls and the first bulkhead.
    prims.append(roof_area(rect(-94, zs - 8, -26, b1 + 8), hh - 2, 6))
    prims.append(hollow(HX, (b2 + zbs) // 2, 10, 2))  # a bilge where the hold is flooded
    items = [
        loot(-60, zs + 32, 2),  # the cabin
        loot(-68, zs + 78, 3),  # second compartment
        loot(-60, zbs - 14, 6),  # the last compartment, a dead end below the prow
    ]
    decors = [
        decor("WreckRibs", at=(-116, (zs + zbs) // 2), scale=1.3, yaw=90),
        decor("WreckRibs", at=(-4, zs + 90), scale=1.1, yaw=90),
        decor("Timber", area=rect(-120, zs, 0, zbs), count=6),
        decor("Crate", area=rect(-76, zs + 12, -44, zs + 48), count=2),
        decor("Chain", at=(-56, zb + 14)),
        decor("Barnacles", area=rect(-96, zs + 4, -24, zbs), count=6),
    ]
    return prims, items, decors


# ---- rooms (west orientation; the east pockets are mirrored) ----------------------------------
# c is the door's row (a multiple of 4), d the pocket's depth. Everything stays out of the
# door's 28-wide mouth at x 92 to 116. Wall centres are multiples of 4 (faces land on 4k + 2).


def room_hold(c, d, h):
    hh = h - 4
    return dict(
        Name="Cargo hold",
        Primitives=[
            wall_z(36, c - 28, c + 28, hh, 16, Material="Pavement"),
            wall_x(c - 28, 36, 80, hh, 16, Material="Pavement"),
            wall_x(c + 28, 36, 80, hh, 16, Material="Pavement"),
            roof_area(rect(28, c - 36, 80, c + 36), hh - 2, 6),
        ],
        Loot=[loot(52, c, 5), loot(52, c - 16, 3)],
        Decor=[decor("Crate", area=rect(44, c - 16, 70, c + 16), count=3), decor("Barnacles", area=rect(30, c - 34, 80, c + 34), count=3)],
    )


def room_galley(c, d, h):
    return dict(
        Name="Flooded galley",
        Primitives=[
            hollow(52, c, 26, 3.5),
            mound(52, c, 7, 4.5),
            wall_x(c - 36, 28, 60, h - 6, 16),
            wall_x(c + 36, 28, 60, h - 6, 16),
            mound(24, c, 8, 6, rock=True),
        ],
        Loot=[loot(52, c, 5), loot(44, c - 22, 2)],
        Decor=[decor("Kelp", area=rect(34, c - 20, 74, c + 20), count=4), decor("Bones", at=(76, c + 18))],
    )


def room_scramble(c, d, h):
    return dict(
        Name="Debris scramble",
        Primitives=[
            mound(32, c - 26, 11, 7, rock=True),
            mound(56, c - 24, 10, 6, rock=True),
            mound(30, c + 24, 11, 7, rock=True),
            mound(58, c + 26, 10, 7, rock=True),
            mound(24, c, 9, 6, rock=True),
            mound(80, c - 36, 9, 6, rock=True),
        ],
        Loot=[loot(44, c, 4), loot(16, c + 4, 2), loot(44, c + 34, 1)],
        Decor=[decor("Timber", area=rect(36, c - 16, 72, c + 16), count=3), decor("Anchor", at=(48, c))],
    )


def room_cove(c, d, h):
    return dict(
        Name="Anchor cove",
        Primitives=[
            ridge([(76, c - 44), (36, c - 40), (20, c), (36, c + 40), (76, c + 44)], 5, 16),
            hollow(56, c, 12, 2.5),
        ],
        Loot=[loot(56, c, 4), loot(36, c + 4, 2)],
        Decor=[decor("Anchor", at=(44, c - 10)), decor("Chain", at=(60, c + 12)), decor("DeadCoral", at=(36, c - 18))],
    )


TEMPLATES = {"hold": room_hold, "galley": room_galley, "scramble": room_scramble, "cove": room_cove}
