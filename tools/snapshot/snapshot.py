#!/usr/bin/env python3
"""Snapshots of the built game, drawn from the engine's own parts: what's on the ground, seen
from above (top) or from the shop side (front), so props, decor and terrain can be looked at
without Studio. The game is built inside the review place (tools/review) by snapshot.luau.

Usage (from the repo root):
  python3 tools/snapshot/snapshot.py top -360 -80 360 608 -o out.png      # region x0 z0 x1 z1
  python3 tools/snapshot/snapshot.py front -320 280 320 320 --showcase decor -o decor.png
  python3 tools/snapshot/snapshot.py top -360 3040 360 3648 --zone 6=Base:1: --scale 1.5

  --zone N=BIOME:CHOICE  set a zone's biome (Base for none) and choice before the snapshot
  --scale PX             pixels per stud (default 2)
  --showcase decor       every decor kind in a row on zone 1's sand (z 300)
Top: terrain coloured by its material and shaded by relief (darker under roofs), then parts
from the lowest up. Front: looking from the shop toward the sea, parts from the farthest in.
Sea: looking back at the shore from the sea.
"""

import argparse
import json
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "tools", "review"))
import review  # noqa: E402


def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(rgb, k):
    return tuple(max(0, min(255, int(c * k))) for c in rgb)


def corners(part):
    c = part["c"]
    x, y, z = c[0], c[1], c[2]
    r = [[c[3], c[4], c[5]], [c[6], c[7], c[8]], [c[9], c[10], c[11]]]
    sx, sy, sz = (v / 2 for v in part["s"])
    out = []
    for dx in (-sx, sx):
        for dy in (-sy, sy):
            for dz in (-sz, sz):
                out.append((x + r[0][0] * dx + r[0][1] * dy + r[0][2] * dz,
                            y + r[1][0] * dx + r[1][1] * dy + r[1][2] * dz,
                            z + r[2][0] * dx + r[2][1] * dy + r[2][2] * dz))
    return out


def hull(points):
    points = sorted(set(points))
    if len(points) <= 2:
        return points

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in points:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(points):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("view", choices=["top", "front", "sea"])
    parser.add_argument("x0", type=float)
    parser.add_argument("z0", type=float)
    parser.add_argument("x1", type=float)
    parser.add_argument("z1", type=float)
    parser.add_argument("--zone", action="append", default=[])
    parser.add_argument("--scale", type=float, default=2)
    parser.add_argument("--showcase")
    parser.add_argument("--step", type=float, default=2)
    parser.add_argument("-o", "--out", required=True)
    args = parser.parse_args()

    job = {"region": [args.x0, args.z0, args.x1, args.z1], "step": args.step, "zones": {}}
    for spec in args.zone:
        zone, rest = spec.split("=", 1)
        biome, choice = (rest.split(":", 1) + ["1:"])[:2]
        job["zones"][zone] = {"biome": None if biome == "Base" else biome, "choice": choice or "1:"}
    if args.showcase:
        job["showcase"] = args.showcase
    script = open(os.path.join(HERE, "snapshot.luau")).read()
    data = review.run_luau("local SNAPSHOT_JSON = [==[" + json.dumps(job) + "]==]\n" + script)
    parts = data["parts"]
    s = args.scale
    x0, z0, x1, z1 = args.x0, args.z0, args.x1, args.z1

    if args.view == "top":
        w, h = int((x1 - x0) * s), int((z1 - z0) * s)
        image = Image.new("RGB", (w, h), (30, 30, 34))
        draw = ImageDraw.Draw(image, "RGBA")
        rows = [[cell.split(" ") for cell in row.split(";")] for row in data["terrain"]]
        step = data["step"]
        heights = [[float(c[0]) for c in row] for row in rows]
        for j, row in enumerate(rows):
            for i, cell in enumerate(row):
                color = hex_rgb(cell[1])
                # Relief: light from the north-west.
                hl = heights[j][i - 1] if i > 0 else heights[j][i]
                hu = heights[j - 1][i] if j > 0 else heights[j][i]
                k = 1 + max(-0.35, min(0.35, ((heights[j][i] - hl) + (heights[j][i] - hu)) * 0.06))
                color = shade(color, k)
                if len(cell) > 2:
                    color = shade(color, 0.55)
                px, pz = (i * step) * s, (j * step) * s
                draw.rectangle([px, pz, px + step * s, pz + step * s], fill=color)
        for part in sorted(parts, key=lambda p: max(c[1] for c in corners(p))):
            pts = corners(part)
            top = max(c[1] for c in pts)
            rgb = shade(hex_rgb(part["k"]), 0.85 + min(0.3, max(0, (top - pts[0][1]) * 0.02)))
            alpha = int(255 * (1 - part["t"]))
            poly = [((p[0] - x0) * s, (p[2] - z0) * s) for p in pts]
            if part["h"] == "Ball":
                cx, cz = (part["c"][0] - x0) * s, (part["c"][2] - z0) * s
                r = part["s"][0] / 2 * s
                draw.ellipse([cx - r, cz - r, cx + r, cz + r], fill=rgb + (alpha,), outline=shade(rgb, 0.6) + (alpha,))
            else:
                outline = hull(poly)
                if len(outline) >= 3:
                    draw.polygon(outline, fill=rgb + (alpha,), outline=shade(rgb, 0.6) + (alpha,))
    else:
        # The terrain's skyline first: for each column of the grid, its highest point
        # anywhere along the region, in that point's colour.
        rows = [[cell.split(" ") for cell in row.split(";")] for row in data["terrain"]]
        step = data["step"]
        skyline = []
        for i in range(len(rows[0]) if rows else 0):
            top = max(rows, key=lambda r: float(r[i][0]))[i]
            skyline.append((float(top[0]), hex_rgb(top[1])))
        # Front: x across, y up; a band of y from the lowest part. Sea: the same from the other
        # side, looking back at the shore, so x runs the other way and the nearest parts are
        # the ones farthest out.
        sea = args.view == "sea"
        px = (lambda x: (x1 - x) * s) if sea else (lambda x: (x - x0) * s)
        ys = [c[1] for p in parts for c in corners(p)] + [h for h, _ in skyline] or [0, 10]
        y0, y1 = min(ys) - 2, max(ys) + 2
        w, h = int((x1 - x0) * s), int((y1 - y0) * s)
        image = Image.new("RGB", (w, h), (205, 225, 235))
        draw = ImageDraw.Draw(image, "RGBA")
        for i, (top, rgb) in enumerate(skyline):
            xa = x0 + i * step
            ax, bx = sorted((px(xa), px(xa + step)))
            draw.rectangle([ax, (y1 - top) * s, bx, h], fill=shade(rgb, 0.8))
        for part in sorted(parts, key=lambda p: p["c"][2] if sea else -p["c"][2]):
            pts = corners(part)
            if not (z0 - 10 <= part["c"][2] <= z1 + 10):
                continue
            rgb = hex_rgb(part["k"])
            alpha = int(255 * (1 - part["t"]))
            poly = [(px(p[0]), (y1 - p[1]) * s) for p in pts]
            if part["h"] == "Ball":
                cx, cy = px(part["c"][0]), (y1 - part["c"][1]) * s
                rx, ry = part["s"][0] / 2 * s, part["s"][1] / 2 * s
                draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=rgb + (alpha,), outline=shade(rgb, 0.6) + (alpha,))
            else:
                outline = hull(poly)
                if len(outline) >= 3:
                    draw.polygon(outline, fill=rgb + (alpha,), outline=shade(rgb, 0.6) + (alpha,))
    image.save(args.out)
    print(f"{args.out}: {len(parts)} parts")


if __name__ == "__main__":
    main()
