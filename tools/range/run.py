#!/usr/bin/env python3
"""The Test Range: checks a zone of the beach inside the real Roblox engine.

It builds the game with Rojo, publishes it to the Test Range place (a separate experience, so
the live game is never touched), runs tools/range/check.luau there through Open Cloud's Luau
Execution API, and writes the report. The engine builds the real terrain, props and biomes,
so the check catches what the Lune tests can't: props floating or buried, things inside rock,
creatures walking through walls, and whether Roblox's own pathfinding gets across the zone
(and how long it takes, against the zone's CrossTime), at each tide level.

Usage (from the repo root):
  python3 tools/range/run.py --zone 4 --all HermitHollows
  python3 tools/range/run.py --zone 5 --tile 17=Biomes/Planned/TidepoolRocks --tide 2400 --tide 3000
  python3 tools/range/run.py --zone 1 --no-routes --no-publish

  --zone N            the zone to check (1 to Config.Beach.ActiveZones)
  --all SPEC          every tile of the zone: "Base", a biome id, or a layout path under
                      src/shared/Layouts ("Zones/Zone5", "Biomes/Planned/CoralGarden")
  --tile T=SPEC       one tile (tiles are numbered from the shop, 4 to a zone)
  --tide Z            a waterline Z to measure the water at (repeatable; default: the zone's top,
                      middle and bottom, and low tide)
  --no-routes         skip the pathfinding (quicker)
  --no-publish        reuse the last published build (when only the job changed)

It needs network access to apis.roblox.com with the Open Cloud key (with Luau execution and
place publishing permissions for the Test Range experience). The report is written to
tools/range/out/zone<N>.json and summarised on screen. Exit code 1 if it found problems.
"""

import argparse
import fcntl
import json
import os
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SETTINGS = json.load(open(os.path.join(HERE, "range.json")))
API = "https://apis.roblox.com"

CA = "/root/.ccr/ca-bundle.crt"
CONTEXT = ssl.create_default_context(cafile=CA) if os.path.exists(CA) else ssl.create_default_context()


def request(method, url, body=None, content_type="application/json"):
    data = None
    if body is not None:
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
    req = urllib.request.Request(url, method=method, data=data, headers={"Content-Type": content_type})
    try:
        with urllib.request.urlopen(req, context=CONTEXT, timeout=300) as response:
            return json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as error:
        sys.exit(f"{method} {url} failed: {error.code} {error.read().decode()[:500]}")


def publish():
    place_file = os.path.join(HERE, "out", "range.rbxl")
    os.makedirs(os.path.dirname(place_file), exist_ok=True)
    subprocess.run(["rojo", "build", os.path.join(ROOT, "default.project.json"), "-o", place_file], check=True)
    url = f"{API}/universes/v1/{SETTINGS['universe']}/places/{SETTINGS['place']}/versions?versionType=Published"
    result = request("POST", url, open(place_file, "rb").read(), "application/octet-stream")
    print(f"published the build as version {result.get('versionNumber')}")


def run_check(job):
    script = open(os.path.join(HERE, "check.luau")).read()
    script = "local JOB_JSON = [==[" + json.dumps(job) + "]==]\n" + script
    url = f"{API}/cloud/v2/universes/{SETTINGS['universe']}/places/{SETTINGS['place']}/luau-execution-session-tasks"
    task = request("POST", url, {"script": script, "timeout": "300s"})
    started = time.time()
    while task.get("state") in ("QUEUED", "PROCESSING"):
        time.sleep(4)
        task = request("GET", f"{API}/cloud/v2/{task['path']}")
        print(f"  ... {task.get('state').lower()} ({time.time() - started:.0f}s)", end="\r")
    print()
    logs = request("GET", f"{API}/cloud/v2/{task['path']}/logs")
    messages = [m for entry in logs.get("luauExecutionSessionTaskLogs", []) for m in entry.get("messages", [])]
    if task.get("state") != "COMPLETE":
        print("\n".join(messages[-30:]))
        sys.exit(f"the check failed in the engine: {json.dumps(task.get('error'))}")
    return json.loads(task["output"]["results"][0]), messages


def summarise(report):
    m = report["measurements"]
    lines = [f"Zone {report['job']['zone']}: tiles {m.get('tiles')}"]
    lines.append(f"  built in {m.get('buildSeconds', 0):.1f}s, checked {m.get('propsChecked')} props, "
                 f"{m.get('creatures')} creatures, {m.get('spotsChecked', 0)} loot/entrance spots")
    offset = m.get("terrainOffset", {})
    lines.append(f"  terrain vs layout: {offset.get('average', 0):.2f} studs on average, worst {offset.get('worst', 0):.2f}")
    crossing = m.get("crossing")
    if crossing:
        fastest, back = crossing.get("fastestSeconds"), crossing.get("backSeconds")
        lines.append(f"  fastest way down on foot: {fastest:.0f}s (target {crossing.get('targetSeconds')}s)"
                     if fastest else "  no way down on foot")
        lines.append(f"  fastest way back up: {back:.0f}s" if back else "  no way back up")
        starts = ", ".join(f"x {s['from']}: {s['seconds']:.0f}s" if s.get("seconds") else f"x {s['from']}: none"
                           for s in crossing.get("perStart", []))
        lines.append(f"  down from each start: {starts}")
        route = crossing.get("route") or []
        if route:
            lines.append(f"  fastest way down turns at: {' '.join(route[:40])}{' ...' if len(route) > 40 else ''}")
        if crossing.get("pathfinderSeconds"):
            lines.append(f"  (Roblox's pathfinder: {crossing['pathfinderSeconds']:.0f}s)")
    for note in report.get("notes", []):
        lines.append(f"  note: {note}")
    for tide in m.get("tides", []):
        flooded = tide.get("tunnelsFlooded")
        lines.append(f"  waterline z {tide['waterline']:.0f}: {tide['underWater'] * 100:.0f}% under water, "
                     f"{tide['tooDeep'] * 100:.0f}% too deep to stand"
                     + (f", {flooded * 100:.0f}% of tunnels flooded" if flooded is not None else ""))
    problems = report["problems"]
    if not problems:
        lines.append("  no problems found")
    for kind, entry in problems.items():
        lines.append(f"  PROBLEM {kind}: {entry['count']}")
        for example in entry["examples"][:8]:
            lines.append(f"    - {example}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--zone", type=int, required=True)
    parser.add_argument("--all")
    parser.add_argument("--tile", action="append", default=[])
    parser.add_argument("--tide", action="append", type=float, default=[])
    parser.add_argument("--no-routes", action="store_true")
    parser.add_argument("--no-publish", action="store_true")
    args = parser.parse_args()

    job = {"zone": args.zone, "routes": not args.no_routes}
    if args.all:
        job["all"] = args.all
    if args.tile:
        job["tiles"] = dict(entry.split("=", 1) for entry in args.tile)
    if args.tide:
        job["tides"] = args.tide

    # One Test Range run at a time: every run publishes its own build to the one place, so
    # runs from other worktrees wait their turn.
    with open("/tmp/salvage-test-range.lock", "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("waiting for another Test Range run to finish ...")
            fcntl.flock(lock, fcntl.LOCK_EX)
        if not args.no_publish:
            publish()
        report, messages = run_check(job)
    out = os.path.join(HERE, "out", f"zone{args.zone}.json")
    with open(out, "w") as f:
        json.dump({"report": report, "logs": messages}, f, indent=2)
    print(summarise(report))
    print(f"(full report: {os.path.relpath(out, ROOT)})")
    sys.exit(1 if report["problems"] else 0)


if __name__ == "__main__":
    main()
