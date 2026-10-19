#!/usr/bin/env python3
"""The water lab: see the game's water at any moment, on any zone, and check it against the
water the game plays by.

It runs tools/water/lab.luau (the game's own water code, src/client/SeaController, on the
terrain as TerrainBuilder builds it) and draws:
  top   from above: the ground, the water as it's drawn, and where the drawn water and the
        game's water disagree (magenta: the game says wet but no water shows; red: water
        shows where the game says dry). Lines mark where the water gets deep enough to slow
        you (knee, orange), drown you (waist, dark red) and lose loose items (black).
  eye   what a player sees standing on the shore looking out to sea.
  cut   a slice down the beach at one X: the ground as built (brown), the layout's ground
        (dotted), the game's water level (blue line) and each water sheet as drawn.
and prints the checks (tools/water/README.md).

Usage (from the repo root):
  python3 tools/water/water.py 4 Base 1: 2000                     # zone 4, waterline z 2000
  python3 tools/water/water.py 6 Lab 1: 3300 --views top,eye,cut --cut-x 40
  python3 tools/water/water.py 3 Base 2: 1500 --region -200 1400 200 1700 -o out/z3
"""
import argparse
import json
import math
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

DEPTHS = {"Shallow": 1.5, "Knee": 3.0, "Waist": 4.5, "Lost": 7.0}
HALF_WIDTH = 360
MATERIALS = {}


def load_materials():
    """Terrain colours from Config.Looks.Materials (read from the source)."""
    import re
    text = open(os.path.join(ROOT, "src", "shared", "Config.luau")).read()
    block = text[text.index("Materials = {"):]
    block = block[:block.index("}")]
    for name, r, g, b in re.findall(r"(\w+) = rgb\((\d+), (\d+), (\d+)\)", block):
        MATERIALS[name] = (int(r), int(g), int(b))


def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def run_lab(args):
    cmd = ["lune", "run", os.path.join(HERE, "lab.luau"), str(args.zone), args.layout, args.choice,
           str(args.waterline), *[str(v) for v in args.region], str(args.step), str(args.seconds)]
    done = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    if done.returncode != 0:
        sys.exit(done.stderr[-3000:])
    start = done.stdout.index("{")
    return json.loads(done.stdout[start:])


class Scene:
    """The lab's moment on a grid: the ground, the game's water and the drawn sheets."""

    def __init__(self, data):
        self.data = data
        x0, z0, x1, z1 = data["region"]
        self.x0, self.z0, self.x1, self.z1 = x0, z0, x1, z1
        self.step = step = data["step"]
        rows = [[cell.split(" ") for cell in row.split(";")] for row in data["ground"]]
        self.nz, self.nx = len(rows), len(rows[0])
        self.xs = x0 + np.arange(self.nx) * step
        self.zs = z0 + np.arange(self.nz) * step
        self.floor = np.array([[float(c[0]) for c in r] for r in rows])
        self.ideal = np.array([[float(c[1]) for c in r] for r in rows])
        self.roof = np.array([[float(c[2]) if c[2] != "-" else np.nan for c in r] for r in rows])
        self.roof_top = np.array([[float(c[3]) if c[3] != "-" else np.nan for c in r] for r in rows])
        self.material = [[c[4] for c in r] for r in rows]
        self.water_y = np.tile(np.array(data["waterY"]), (self.nz, 1))
        self.depth = self.water_y - self.ideal  # the game's water depth
        self.sheets = {}
        for name, sheet in data["sheets"].items():
            self.sheets[name] = self.sample(sheet)

    def sample(self, sheet):
        """A sheet's height (and colour, alpha) at every grid point; NaN where it isn't."""
        cols = sheet["cols"]
        cx = np.array([c[0] for c in cols])
        ys = np.zeros((self.nz, len(cols)))
        for i, (_, cy, cz) in enumerate(cols):
            cz, cy = np.array(cz), np.array(cy)
            order = np.argsort(cz, kind="stable")
            cz, cy = cz[order], cy[order]
            inside = (self.zs >= cz[0]) & (self.zs <= cz[-1]) & (cz[-1] - cz[0] > 0.05)
            ys[:, i] = np.where(inside, np.interp(self.zs, cz, cy), np.nan)
        y = np.full((self.nz, self.nx), np.nan)
        colour = None
        base = np.array(hex_rgb(sheet["color"]), dtype=float)
        alpha = np.full((self.nz, self.nx), 1 - sheet["transparency"])
        rgb = np.tile(base, (self.nz, self.nx, 1))
        if sheet.get("colors"):
            per = []
            for i, (_, cy, cz) in enumerate(cols):
                cz = np.array(cz)
                order = np.argsort(cz, kind="stable")
                k = [sheet["colors"][i][j] for j in order]
                cz = cz[order]
                chans = [np.array([int(h[n:n + 2], 16) for h in k], dtype=float) for n in (0, 2, 4, 6)]
                per.append([np.interp(self.zs, cz, ch) for ch in chans])
            colour = per
        for j, x in enumerate(self.xs):
            k = np.searchsorted(cx, x) - 1
            k = min(max(k, 0), len(cx) - 2)
            t = (x - cx[k]) / max(cx[k + 1] - cx[k], 1e-6)
            if t < -0.01 or t > 1.01:
                continue
            a, b = ys[:, k], ys[:, k + 1]
            y[:, j] = a + (b - a) * t
            if colour:
                for n in range(3):
                    rgb[:, j, n] = colour[k][n] + (colour[k + 1][n] - colour[k][n]) * t
                alpha[:, j] = (colour[k][3] + (colour[k + 1][3] - colour[k][3]) * t) / 255 * (1 - sheet["transparency"])
        return {"y": y, "rgb": rgb, "alpha": alpha}

    def ground_rgb(self):
        rgb = np.zeros((self.nz, self.nx, 3))
        for j in range(self.nz):
            for i in range(self.nx):
                rgb[j, i] = MATERIALS.get(self.material[j][i], (200, 180, 140))
        # Relief: light from the north-west.
        gz, gx = np.gradient(self.floor, self.step)
        k = np.clip(1 - (gx + gz) * 0.6, 0.55, 1.35)
        return rgb * k[..., None]

    def drawn_water(self):
        """Where water shows (open sky): the sea sheet above the drawn ground."""
        sea = self.sheets["Sea"]["y"]
        return np.nan_to_num(sea, nan=-1e9) > self.floor + 0.02

    def checks(self):
        """The numbers tools/tests holds the water to. Away from roofs (caves get their own)."""
        open_sky = np.isnan(self.roof)
        # Leave out the cells at a steep edge (a wall's or a bank's side: the terrain is drawn
        # a little inside the layout's edge there, by design) and past the beach's sides.
        gz, gx = np.gradient(self.ideal, self.step)
        steep = np.hypot(gx, gz) > 0.9
        near_steep = steep.copy()
        for dz in (-1, 0, 1):
            for dx in (-1, 0, 1):
                near_steep |= np.roll(np.roll(steep, dz, 0), dx, 1)
        inside = np.abs(self.xs)[None, :] <= HALF_WIDTH - 2
        judged = open_sky & ~near_steep & inside
        wet = (self.depth > 0.15) & judged
        dry = (self.depth < -0.15) & judged
        shown = self.drawn_water() & open_sky
        sea = self.sheets["Sea"]["y"]
        rise = np.nan_to_num(sea - self.water_y, nan=-1e9)
        visible = shown
        climb = rise[visible].max() if visible.any() else 0.0
        return {
            "wet cells": int(wet.sum()),
            "wet but no water shows": int((wet & ~shown).sum()),
            "dry but water shows": int((dry & shown).sum()),
            "highest water above sea level": round(float(climb), 2),
            "water showing over 0.5 above sea level": int((visible & (rise > 0.5)).sum()),
        }


def contour(mask):
    """Edge cells of a boolean mask."""
    edge = np.zeros_like(mask)
    edge[1:, :] |= mask[1:, :] != mask[:-1, :]
    edge[:, 1:] |= mask[:, 1:] != mask[:, :-1]
    return edge


def draw_top(scene, out, scale):
    rgb = scene.ground_rgb()
    for name in ("WetSand", "Sea", "Swash", "Foam", "Crest1", "Crest2"):
        sheet = scene.sheets.get(name)
        if not sheet:
            continue
        show = np.nan_to_num(sheet["y"], nan=-1e9) > scene.floor + 0.02
        a = (sheet["alpha"] * show)[..., None]
        rgb = rgb * (1 - a) + sheet["rgb"] * a
    roofed = ~np.isnan(scene.roof)
    rgb[roofed] = rgb[roofed] * 0.35 + np.array([70, 70, 75]) * 0.65
    wet = scene.depth > 0.15
    dry = scene.depth < -0.15
    shown = scene.drawn_water()
    rgb[wet & ~shown & ~roofed] = (255, 0, 255)
    rgb[dry & shown & ~roofed] = (255, 0, 0)
    for depth, colour in ((DEPTHS["Knee"], (255, 140, 0)), (DEPTHS["Waist"], (140, 0, 0)), (DEPTHS["Lost"], (0, 0, 0))):
        rgb[contour(scene.depth >= depth)] = colour
    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8))
    img = img.resize((int(scene.nx * scale), int(scene.nz * scale)), Image.NEAREST)
    img.save(out)


def draw_cut(scene, out, cut_x, yscale=6, scale=3):
    i = int(np.argmin(np.abs(scene.xs - cut_x)))
    zs = scene.zs
    lines = [scene.floor[:, i], scene.ideal[:, i], scene.water_y[:, i]]
    ys = np.concatenate([l[~np.isnan(l)] for l in lines])
    y0, y1 = ys.min() - 2, ys.max() + 4
    w, h = int(len(zs) * scale), int((y1 - y0) * yscale * scale / scene.step) + 20
    img = Image.new("RGB", (w, h), (215, 232, 240))
    d = ImageDraw.Draw(img)

    def p(j, y):
        return (j * scale, (y1 - y) * yscale * scale / scene.step)

    for j in range(len(zs) - 1):
        d.polygon([p(j, scene.floor[j, i]), p(j + 1, scene.floor[j + 1, i]), p(j + 1, y0), p(j, y0)], fill=(196, 160, 110))
        if not np.isnan(scene.roof[j, i]):
            d.polygon([p(j, scene.roof[j, i]), p(j + 1, scene.roof[j, i]), p(j + 1, scene.roof_top[j, i]),
                       p(j, scene.roof_top[j, i])], fill=(110, 110, 115))
    for j in range(0, len(zs) - 1, 2):
        d.line([p(j, scene.ideal[j, i]), p(j + 1, scene.ideal[j + 1, i])], fill=(90, 60, 30))
    d.line([p(j, scene.water_y[j, i]) for j in range(len(zs))], fill=(0, 60, 200), width=1)
    for name, colour in (("Sea", (0, 170, 200)), ("Swash", (120, 220, 230)), ("Foam", (255, 255, 255)),
                         ("WetSand", (150, 110, 60)), ("Crest1", (240, 240, 255)), ("Crest2", (240, 240, 255))):
        sheet = scene.sheets.get(name)
        if not sheet:
            continue
        y = sheet["y"][:, i]
        pts = [p(j, y[j]) for j in range(len(zs)) if not np.isnan(y[j])]
        if len(pts) > 1:
            d.line(pts, fill=colour, width=2)
    img.save(out)


# ---- eye: a small z-buffered rasteriser ------------------------------------------------------
def draw_eye(scene, out, eye_x, eye_z, width=960, height=540, fov=70, pitch=-10, yaw=0):
    j = int(np.clip((eye_z - scene.z0) / scene.step, 0, scene.nz - 1))
    i = int(np.argmin(np.abs(scene.xs - eye_x)))
    eye = np.array([eye_x, scene.floor[j, i] + 5.5, eye_z])
    cy, sy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    cp, sp = math.cos(math.radians(pitch)), math.sin(math.radians(pitch))
    forward = np.array([sy * cp, sp, cy * cp])
    # Facing +Z with Y up, the screen's right is -X.
    right = np.array([-cy, 0, sy])
    up = np.cross(right, forward)
    f = (width / 2) / math.tan(math.radians(fov / 2))

    zbuf = np.full((height, width), np.inf)
    img = np.zeros((height, width, 3))
    # Sky.
    for row in range(height):
        t = row / height
        img[row, :] = np.array([150, 200, 235]) * (1 - t) + np.array([210, 230, 245]) * t

    def project(p):
        v = p - eye
        x, y, z = v @ right, v @ up, v @ forward
        return np.stack([width / 2 + x / np.maximum(z, 1e-3) * f, height / 2 - y / np.maximum(z, 1e-3) * f, z], -1)

    def raster(tris, colours, alphas, opaque):
        """tris: (n, 3, 3) world points; colours: (n, 3); alphas: (n,)."""
        pts = project(tris.reshape(-1, 3)).reshape(-1, 3, 3)
        keep = (pts[:, :, 2] > 0.5).all(1)
        for t in np.nonzero(keep)[0]:
            a, b, c = pts[t]
            xmin, xmax = int(max(min(a[0], b[0], c[0]), 0)), int(min(max(a[0], b[0], c[0]) + 1, width))
            ymin, ymax = int(max(min(a[1], b[1], c[1]), 0)), int(min(max(a[1], b[1], c[1]) + 1, height))
            if xmin >= xmax or ymin >= ymax:
                continue
            px, py = np.meshgrid(np.arange(xmin, xmax) + 0.5, np.arange(ymin, ymax) + 0.5)
            den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
            if abs(den) < 1e-9:
                continue
            w0 = ((b[1] - c[1]) * (px - c[0]) + (c[0] - b[0]) * (py - c[1])) / den
            w1 = ((c[1] - a[1]) * (px - c[0]) + (a[0] - c[0]) * (py - c[1])) / den
            w2 = 1 - w0 - w1
            inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
            if not inside.any():
                continue
            depth = 1 / (w0 / a[2] + w1 / b[2] + w2 / c[2])
            region = zbuf[ymin:ymax, xmin:xmax]
            near = inside & (depth < region)
            if not near.any():
                continue
            colour = colours[t]
            if opaque:
                region[near] = depth[near]
                img[ymin:ymax, xmin:xmax][near] = colour
            else:
                al = alphas[t]
                img[ymin:ymax, xmin:xmax][near] = img[ymin:ymax, xmin:xmax][near] * (1 - al) + colour * al

    def grid_tris(ys, rgb, alpha=None, stride=1):
        xs, zs = scene.xs[::stride], scene.zs[::stride]
        ys, rgb = ys[::stride, ::stride], rgb[::stride, ::stride]
        if alpha is not None:
            alpha = alpha[::stride, ::stride]
        tris, cols, als = [], [], []
        for jj in range(len(zs) - 1):
            for ii in range(len(xs) - 1):
                q = [(ii, jj), (ii + 1, jj), (ii, jj + 1), (ii + 1, jj + 1)]
                yy = [ys[b, a] for a, b in q]
                if any(np.isnan(v) for v in yy):
                    continue
                p = [np.array([xs[a], ys[b, a], zs[b]]) for a, b in q]
                c = rgb[jj, ii]
                for tri in ((p[0], p[2], p[1]), (p[1], p[2], p[3])):
                    tris.append(tri)
                    cols.append(c)
                    als.append(alpha[jj, ii] if alpha is not None else 1)
        if not tris:
            return np.zeros((0, 3, 3)), np.zeros((0, 3)), np.zeros(0)
        return np.array(tris), np.array(cols), np.array(als)

    ground = scene.ground_rgb()
    stride = 1 if scene.step >= 2 else 2
    t, c, a = grid_tris(scene.floor, ground, stride=stride)
    raster(t, c, a, True)
    roof_top = scene.roof_top
    if not np.isnan(roof_top).all():
        t, c, a = grid_tris(roof_top, np.full_like(ground, 105), stride=stride)
        raster(t, c, a, True)
    order = ("WetSand", "Sea", "Swash", "Foam", "Crest1", "Crest2")
    # Water: far to near, blended over what's behind (it's see-through).
    for name in order:
        sheet = scene.sheets.get(name)
        if not sheet:
            continue
        y = sheet["y"].copy()
        # Only what's above the ground shows (the rest is hidden in the sand).
        y[~(np.nan_to_num(y, nan=-1e9) > scene.floor + 0.01)] = np.nan
        t, c, a = grid_tris(y, sheet["rgb"], sheet["alpha"], stride=stride)
        if len(t):
            centre = t.mean(1)
            far = np.argsort(-np.linalg.norm(centre - eye, axis=1))
            raster(t[far], c[far], a[far], False)
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("zone", type=int)
    parser.add_argument("layout")
    parser.add_argument("choice")
    parser.add_argument("waterline", type=float)
    parser.add_argument("--region", type=float, nargs=4, metavar=("X0", "Z0", "X1", "Z1"))
    parser.add_argument("--step", type=float, default=2)
    parser.add_argument("--seconds", type=float, default=0)
    parser.add_argument("--views", default="top,eye,cut")
    parser.add_argument("--cut-x", type=float, default=0)
    parser.add_argument("--eye", type=float, nargs=3, metavar=("X", "Z", "YAW"),
                        help="where the eye view stands (default: up the beach from the waterline, at the cut's X)")
    parser.add_argument("--scale", type=float, default=2)
    parser.add_argument("-o", "--out", default=os.path.join(ROOT, "tools", "water", "out", "water"))
    args = parser.parse_args()
    if not args.region:
        args.region = [-160, args.waterline - 100, 160, args.waterline + 140]
    load_materials()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    scene = Scene(run_lab(args))
    views = args.views.split(",")
    if "top" in views:
        draw_top(scene, args.out + "-top.png", args.scale)
    if "cut" in views:
        draw_cut(scene, args.out + "-cut.png", args.cut_x)
    if "eye" in views:
        ex, ez, yaw = args.eye if args.eye else (args.cut_x, args.waterline - 60, 0)
        draw_eye(scene, args.out + "-eye.png", ex, ez, yaw=yaw)
    print(json.dumps(scene.checks()))


if __name__ == "__main__":
    main()
