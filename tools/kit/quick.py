#!/usr/bin/env python3
"""The quick check for a layout, in seconds: its problems, its paths and times, and a picture.

Usage: python3 tools/kit/quick.py <zone> [Zones/Zone5 | Biomes/Id | Biomes/Planned/Id] [choice...]
                                  [--plan plan.py] [--no-png]

  --plan   run a kit plan first (it writes the layout), then check what it wrote
  choice   "2:" crossing 2 with the first rooms, "2:1,3" with rooms; none: every crossing

Prints each problem (the definition's, each way's, the paths'), each path's time against the
zone's target and which carts get down; draws each choice to tools/kit/out/<zone>-<choice>.png
(see tools/layout_render.py for the colours). Exits 1 if anything is wrong.
"""

import argparse
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, "out")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("zone", type=int)
    parser.add_argument("source", nargs="?")
    parser.add_argument("choices", nargs="*")
    parser.add_argument("--plan")
    parser.add_argument("--no-png", action="store_true")
    args = parser.parse_args()
    source = args.source or f"Zones/Zone{args.zone}"

    if args.plan:
        subprocess.run([sys.executable, args.plan], cwd=ROOT, check=True,
                       env={**os.environ, "PYTHONPATH": HERE})
    subprocess.run(["stylua", "src/shared/Layouts"], cwd=ROOT, capture_output=True)

    result = subprocess.run(["lune", "run", "tools/kit/quick.luau", str(args.zone), source, *args.choices],
                            cwd=ROOT, capture_output=True, text=True)
    print((result.stdout + result.stderr).rstrip())

    if not args.no_png and not source.startswith("Biomes/Planned/"):
        spec = "Base" if source.startswith("Zones/") else source.split("/", 1)[1]
        os.makedirs(OUT, exist_ok=True)
        choices = args.choices
        if not choices:
            # Every crossing, as quick.luau reports them.
            choices = [line.split(" ")[1] for line in result.stdout.splitlines()
                       if line.startswith(source + " ")]
        for choice in choices:
            path = os.path.join(OUT, f"{args.zone}-{spec}-{choice.replace(':', 'c').replace(',', '-')}.png")
            drawn = subprocess.run([sys.executable, "tools/layout_render.py", str(args.zone), spec, choice,
                                    "-o", path], cwd=ROOT, capture_output=True, text=True)
            print(f"picture: {os.path.relpath(path, ROOT)}" if drawn.returncode == 0
                  else f"picture failed: {drawn.stderr.strip().splitlines()[-1:]}")
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
