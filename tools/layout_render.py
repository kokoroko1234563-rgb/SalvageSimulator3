#!/usr/bin/env python3
"""Draws one way a zone comes out as a PNG, top-down (the shop at the top, the sea below).

Usage: python3 tools/layout_render.py <zone> [Base|biome id] [choice] [-o out.png]

Sand is shaded by height (darker = lower: cuts and pools), rock walls are dark grey, roofs a
blue tint over what's under them, cart ramps orange. Loot spots are yellow circles (bigger =
higher Weight), entrances green squares, the side-room slots cyan outlines with their names.
Hazards: patrols red, sinking sand brown circles, rockfall white crosses, undertow cyan lines,
the Gloom purple (its path, and its reach as a haze); wards' light pale yellow; decor green
dots.
"""

import argparse
import json
import os
import subprocess

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SCALE = 2  # pixels per stud


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("zone", type=int)
    parser.add_argument("spec", nargs="?", default="Base")
    parser.add_argument("choice", nargs="?", default="1:")
    parser.add_argument("-o", "--out")
    args = parser.parse_args()
    raw = subprocess.run(["lune", "run", "tools/layout_render.luau", str(args.zone), args.spec, args.choice],
                         cwd=ROOT, check=True, capture_output=True, text=True).stdout
    data = json.loads(raw[raw.index("{"):])
    step = data["step"]
    rows = [r.split(" ") for r in data["rows"]]
    width, height = len(rows[0]) * step * SCALE, len(rows) * step * SCALE
    image = Image.new("RGB", (width, height + 30), (20, 24, 30))
    draw = ImageDraw.Draw(image, "RGBA")
    for j, row in enumerate(rows):
        for i, code in enumerate(row):
            h = float(code.rstrip("rR="))
            if "r" in code:
                shade = int(70 + min(h, 24) * 2)
                color = (shade, shade, shade + 8)
            else:
                v = max(-4, min(h, 12))
                base = 205 + int(v * 6)
                color = (min(255, base + 20), min(255, base + 5), max(0, base - 50))
                if "=" in code:
                    color = (235, 140, 50)
            if "R" in code:
                color = (int(color[0] * 0.5), int(color[1] * 0.55), int(color[2] * 0.75 + 60))
            x, y = i * step * SCALE, j * step * SCALE
            draw.rectangle([x, y, x + step * SCALE - 1, y + step * SCALE - 1], fill=color)

    def px(point):
        return ((point[0] + 360) * SCALE, point[1] * SCALE)

    for slot in data["slots"]:
        (sx, sz), (w, d) = slot["at"], slot["size"]
        a, b = px((sx, sz)), px((sx + w, sz + d))
        draw.rectangle([a, b], outline=(60, 230, 255), width=2)
        draw.text((a[0] + 3, a[1] + 2), f"{slot['name']}: {slot['room']}", fill=(160, 245, 255))
    colors = {"Patrol": (255, 60, 60), "Sink": (120, 70, 20), "Rockfall": (255, 255, 255),
              "Undertow": (40, 220, 255), "Gloom": (170, 60, 255)}
    for hazard in data["hazards"]:
        color = colors.get(hazard.get("Type"), (255, 60, 60))
        path = hazard.get("Path")
        if path and len(path) > 1:
            draw.line([px(p) for p in path], fill=color + (230,), width=3 if hazard.get("Type") != "Gloom" else 5)
        if hazard.get("At"):
            cx, cy = px(hazard["At"])
            r = (hazard.get("Radius") or 4) * SCALE
            if hazard.get("Type") == "Rockfall":
                draw.line([cx - r, cy - r, cx + r, cy + r], fill=color, width=3)
                draw.line([cx - r, cy + r, cx + r, cy - r], fill=color, width=3)
            else:
                draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=3)
        if hazard.get("Type") == "Gloom":
            for point in (path or [hazard.get("At")]):
                if point:
                    cx, cy = px(point)
                    r = (hazard.get("Radius") or 22) * SCALE
                    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(60, 0, 90, 50))
    for ward in data.get("wards", []):
        cx, cy = px(ward["at"])
        r = ward["radius"] * SCALE
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 240, 120, 60), outline=(255, 240, 120))
    for entry in data.get("decor", []):
        for point in ([entry["At"]] if entry.get("At") else (entry.get("Area") or entry.get("Path") or [])):
            cx, cy = px(point)
            draw.rectangle([cx - 2, cy - 2, cx + 2, cy + 2], fill=(40, 160, 70))
    for spot in data["loot"]:
        cx, cy = px(spot["At"])
        r = (3 + 2 * spot.get("Weight", 1)) * SCALE / 2
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 230, 40), width=2)
    for point in data["entrances"]:
        cx, cy = px(point)
        draw.rectangle([cx - 6, cy - 6, cx + 6, cy + 6], outline=(60, 255, 120), width=2)
    title = f"Zone {data['zone']} {data['name']}  {data['choice']}  {data.get('crossing') or ''}"
    draw.text((8, height + 8), title, fill=(255, 220, 140))
    out = args.out or os.path.join(ROOT, "tools", "range", "out", f"render-zone{args.zone}-{args.choice.replace(':', '_').replace(',', '-')}.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    image.save(out)
    print(out)


if __name__ == "__main__":
    main()
