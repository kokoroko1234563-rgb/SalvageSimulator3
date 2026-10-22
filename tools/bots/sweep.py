#!/usr/bin/env python3
"""The bot sweep: how much item competition is there between X bots on one server?

It builds the game with Rojo, publishes it to the Test Range place (a separate experience, so the
live game is never touched) and runs tools/bots/task.luau there through Open Cloud's Luau Execution
API, one task per X (each is limited to 300 s). In each, X bots (src/server/BotService) play the
real core loop against the real item system; the whole game runs --speed times as fast (the tide,
item spawns and lifetimes, and the bots' walking), so a few minutes hold hours of play. Rates in
the report are per hour of game time.

Usage (from the repo root):
  python3 tools/bots/sweep.py                       X = 1, 2, 4, 8, 12, 16, 20 at --speed 10
  python3 tools/bots/sweep.py --xs 1,8 --speed 10   only some X
  python3 tools/bots/sweep.py --final-trip          one bot, one trip to zone 6 and back
  python3 tools/bots/sweep.py --report-only         rebuild sweep.md and the chart from tools/bots/out

  --xs LIST        the bot counts (default 1,2,4,8,12,16,20)
  --speed N        the one speed-up factor for the whole game (default 10)
  --seconds S      real seconds each task plays (default 250; a task is limited to 300 s)
  --final-trip     measure one bot on one trip to the final zone with the cheapest vessel and a tool
                   able to work it, against Config.Rebirth.BaseCost (prices are not changed)
  --no-publish     reuse the last published build

Writes tools/bots/out/: x<N>.json (each task's raw result), sweep.md (a table per X and the chart),
income_chart.png, and income_log.json (the income-per-tide log the Monte Carlo samples: one entry
per bot per tide with its gear, the zones it worked and the bot count at the time).

It needs network access to apis.roblox.com with the Open Cloud key (Luau execution and place
publishing permissions for the Test Range experience), as tools/range/run.py does.
"""

import argparse
import fcntl
import glob
import json
import os
import re
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RANGE = os.path.join(ROOT, "tools", "range")
SETTINGS = json.load(open(os.path.join(RANGE, "range.json")))
OUT = os.path.join(HERE, "out")
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
    place_file = os.path.join(RANGE, "out", "range.rbxl")
    os.makedirs(os.path.dirname(place_file), exist_ok=True)
    built = subprocess.run(["rojo", "build", os.path.join(ROOT, "default.project.json"), "-o", place_file],
                           capture_output=True, text=True)
    if built.returncode != 0:
        sys.exit(f"rojo build failed:\n{built.stdout}{built.stderr}")
    url = f"{API}/universes/v1/{SETTINGS['universe']}/places/{SETTINGS['place']}/versions?versionType=Published"
    result = request("POST", url, open(place_file, "rb").read(), "application/octet-stream")
    print(f"published the build as version {result.get('versionNumber')}")


def run_task(job):
    script = open(os.path.join(HERE, "task.luau")).read()
    script = "local JOB_JSON = [==[" + json.dumps(job) + "]==]\n" + script
    url = f"{API}/cloud/v2/universes/{SETTINGS['universe']}/places/{SETTINGS['place']}/luau-execution-session-tasks"
    task = request("POST", url, {"script": script, "timeout": "300s"})
    started = time.time()
    while task.get("state") in ("QUEUED", "PROCESSING"):
        time.sleep(5)
        task = request("GET", f"{API}/cloud/v2/{task['path']}")
        print(f"  ... {task.get('state').lower()} ({time.time() - started:.0f}s)", end="\r")
    print()
    logs = request("GET", f"{API}/cloud/v2/{task['path']}/logs")
    messages = [m for entry in logs.get("luauExecutionSessionTaskLogs", []) for m in entry.get("messages", [])]
    if task.get("state") != "COMPLETE":
        print("\n".join(messages[-30:]))
        raise RuntimeError(f"the task failed in the engine: {json.dumps(task.get('error'))}")
    result = json.loads(task["output"]["results"][0])
    result["logs"] = [m for m in messages if "BotService" in m][-20:]
    return result


# Reporting -----------------------------------------------------------------------------------

def per_hour(value, seconds):
    return value / (max(seconds, 1) / 3600)


def table_for(result):
    snap = result["snapshot"]
    bots = snap["Bots"]
    server = snap["Server"]
    lines = []
    lines.append("| bot | colour | coins/h | items/h | trips | lost to bot | lost other | idle % | deaths | lost loads | rebirths | gear |")
    lines.append("|---|---|---|---|---|---|---|---|---|---|---|---|")
    totals = dict(coins=0, items=0, trips=0, lost_bot=0, lost_other=0, idle=0, seconds=0, deaths=0, loads=0)
    for b in bots:
        s = b["GameSeconds"]
        lines.append("| {Bot} | {Color} | {c:,.0f} | {i:,.0f} | {Trips} | {LostToBot} | {LostOther} | {idle:.0f} | {Deaths} | {LostLoads} | {Rebirths} | {tool} + {vessel} |".format(
            c=per_hour(b["Coins"], s), i=per_hour(b["Items"], s), idle=100 * b["IdleGameSeconds"] / max(s, 1),
            tool=b["Gear"]["Tool"], vessel=b["Gear"].get("Vessel") or "hands", **b))
        totals["coins"] += b["Coins"]
        totals["items"] += b["Items"]
        totals["trips"] += b["Trips"]
        totals["lost_bot"] += b["LostToBot"]
        totals["lost_other"] += b["LostOther"]
        totals["idle"] += b["IdleGameSeconds"]
        totals["seconds"] += s
        totals["deaths"] += b["Deaths"]
        totals["loads"] += b["LostLoads"]
    n = max(len(bots), 1)
    mean_s = totals["seconds"] / n
    lines.append("| **all** | | **{c:,.0f}** | **{i:,.0f}** | {trips} | {lb} | {lo} | {idle:.0f} | {d} | {l} | | per bot: {pc:,.0f} coins/h |".format(
        c=per_hour(totals["coins"], mean_s), i=per_hour(totals["items"], mean_s), trips=totals["trips"],
        lb=totals["lost_bot"], lo=totals["lost_other"], idle=100 * totals["idle"] / max(totals["seconds"], 1),
        d=totals["deaths"], l=totals["loads"], pc=per_hour(totals["coins"], mean_s) / n))
    surf_full = 100 * server["SurfFullTicks"] / max(server["SpawnTicks"], 1)
    lines.append("")
    lines.append(f"Server: {server['SurfSpawned']} surf items spawned (+{server.get('SandSpawned', 0)} on open sand, +{server['SpotSpawned']} at loot spots; "
                 f"by zone {'/'.join(str(n) for n in server.get('ZoneSpawned', []))}), "
                 f"{server['Claimed']} claimed ({server['ClaimedByBots']} by bots), "
                 f"{server['Despawned']} despawned unclaimed, every zone at target on {server['SurfFullTicks']} of "
                 f"{server['SpawnTicks']} spawn ticks ({surf_full:.0f}%).")
    return lines, totals, n, mean_s


def summarise(results):
    rows = []
    for x in sorted(results):
        result = results[x]
        bots = result["snapshot"]["Bots"]
        if not bots:
            continue
        rates = [per_hour(b["Coins"], b["GameSeconds"]) for b in bots]
        items = [per_hour(b["Items"], b["GameSeconds"]) for b in bots]
        server = result["snapshot"]["Server"]
        idle = sum(b["IdleGameSeconds"] for b in bots) / max(sum(b["GameSeconds"] for b in bots), 1)
        rows.append(dict(x=x, mean=sum(rates) / len(rates), lo=min(rates), hi=max(rates),
                         items=sum(items) / len(items), lost=sum(b["LostToBot"] for b in bots),
                         lost_per_bot=sum(b["LostToBot"] for b in bots) / len(bots),
                         bought=sum(1 for b in bots if b.get("Purchases", 0) > 0 or b["Rebirths"] > 0),
                         n=len(bots),
                         idle=idle, spawned=server["SurfSpawned"] + server.get("SandSpawned", 0), claimed=server["Claimed"],
                         despawned=server["Despawned"], full=server["SurfFullTicks"] / max(server["SpawnTicks"], 1)))
    return rows


def chart(rows, path):
    from PIL import Image, ImageDraw
    W, H = 900, 520
    left, right, top, bottom = 90, 40, 60, 80
    img = Image.new("RGB", (W, H), (255, 255, 255))
    d = ImageDraw.Draw(img)
    ink, grid, blue, grey = (30, 30, 30), (225, 225, 225), (31, 119, 180), (150, 150, 150)
    xs = [r["x"] for r in rows]
    top_value = max(r["hi"] for r in rows) * 1.1 or 1
    mag = 10 ** (len(str(int(top_value))) - 1)
    top_value = (int(top_value / mag) + 1) * mag

    def px(x):
        return left + (x - min(xs)) / max(max(xs) - min(xs), 1) * (W - left - right)

    def py(v):
        return H - bottom - v / top_value * (H - top - bottom)
    d.text((left, 20), "Income per bot against bots on the server (coins per game hour)", fill=ink)
    for i in range(6):
        v = top_value * i / 5
        d.line([(left, py(v)), (W - right, py(v))], fill=grid)
        d.text((10, py(v) - 5), f"{v:,.0f}", fill=ink)
    d.line([(left, top), (left, H - bottom), (W - right, H - bottom)], fill=ink, width=2)
    for x in xs:
        d.line([(px(x), H - bottom), (px(x), H - bottom + 5)], fill=ink)
        d.text((px(x) - 6, H - bottom + 10), str(x), fill=ink)
    d.text((W // 2 - 60, H - 35), "bots on the server (X)", fill=ink)
    for r in rows:
        d.line([(px(r["x"]), py(r["lo"])), (px(r["x"]), py(r["hi"]))], fill=grey, width=2)
        for v in (r["lo"], r["hi"]):
            d.line([(px(r["x"]) - 5, py(v)), (px(r["x"]) + 5, py(v))], fill=grey, width=2)
    points = [(px(r["x"]), py(r["mean"])) for r in rows]
    if len(points) > 1:
        d.line(points, fill=blue, width=3)
    for p in points:
        d.ellipse([p[0] - 5, p[1] - 5, p[0] + 5, p[1] + 5], fill=blue)
    d.text((W - 330, 40), "line: mean per bot; whiskers: slowest to fastest bot", fill=ink)
    img.save(path)


def write_report():
    results = {}
    for path in glob.glob(os.path.join(OUT, "x*.json")):
        name = os.path.basename(path)[1:-5]
        if name.isdigit():
            results[int(name)] = json.load(open(path))
    lines = ["# Bot sweep", ""]
    if results:
        first = results[min(results)]["job"]
        lines.append(f"Each X is one Test Range task: X bots play the real loop for {first.get('seconds')} s of real time at "
                     f"x{first.get('speed')} speed (tide, item spawns and lifetimes, and walking all x{first.get('speed')}). "
                     "Rates are per hour of game time. Zones are the base layouts (no biomes).")
        lines.append("")
        rows = summarise(results)
        lines.append("| X | mean coins/h per bot | slowest | fastest | items/h per bot | lost to bot per bot | bots that bought gear | idle % | surf spawned | claimed | despawned unclaimed | surf full % |")
        lines.append("|---|---|---|---|---|---|---|---|---|---|---|---|")
        for r in rows:
            lines.append(f"| {r['x']} | {r['mean']:,.0f} | {r['lo']:,.0f} | {r['hi']:,.0f} | {r['items']:,.0f} | {r['lost_per_bot']:.1f} | "
                         f"{r['bought']}/{r['n']} | {100 * r['idle']:.0f} | {r['spawned']} | {r['claimed']} | {r['despawned']} | {100 * r['full']:.0f} |")
        lines.append("")
        extra = {}
        for path in sorted(glob.glob(os.path.join(OUT, "x*_*.json"))):
            extra[os.path.basename(path)[1:-5]] = json.load(open(path))
        if extra:
            groups = {}
            for name, res in extra.items():
                x, tag = name.split("_", 1)
                groups.setdefault((re.sub(r"\d+$", "", tag), int(x)), []).append(res)
            lines.append("Repeated runs, by tag (mean and range over the repeats):")
            lines.append("")
            lines.append("| tag | X | runs | coins/h per bot | server total coins/h | tide deaths per run | claimed per run | gear at the end (bots per run) |")
            lines.append("|---|---|---|---|---|---|---|---|")
            for (tag, x), runs in sorted(groups.items()):
                per_bot, total, deaths, claimed, gear = [], [], [], [], {}
                for res in runs:
                    bots = res["snapshot"]["Bots"]
                    hours = sum(b["GameSeconds"] for b in bots) / len(bots) / 3600
                    coins = sum(b["Coins"] for b in bots)
                    per_bot.append(coins / len(bots) / hours)
                    total.append(coins / hours)
                    deaths.append(sum(b["Deaths"] for b in bots))
                    claimed.append(res["snapshot"]["Server"]["Claimed"])
                    for b in bots:
                        key = f"{b['Gear']['Tool']}+{b['Gear'].get('Vessel') or 'hands'}"
                        gear[key] = gear.get(key, 0) + 1

                def span(v):
                    return f"{sum(v) / len(v):,.0f} ({min(v):,.0f} to {max(v):,.0f})"
                mix = ", ".join(f"{k} {n / len(runs):.1f}" for k, n in sorted(gear.items(), key=lambda kv: -kv[1])[:5])
                lines.append(f"| {tag} | {x} | {len(runs)} | {span(per_bot)} | {span(total)} | {span(deaths)} | {span(claimed)} | {mix} |")
            lines.append("")
        first = {}
        for path in glob.glob(os.path.join(OUT, "first_sweep", "x*.json")):
            name = os.path.basename(path)[1:-5]
            if name.isdigit():
                first[int(name)] = json.load(open(path))
        if first:
            lines.append("The first sweep (before bots spread along the beach), for comparison:")
            lines.append("")
            lines.append("| X | mean coins/h per bot | lost to bot per bot | bots that bought gear | claimed |")
            lines.append("|---|---|---|---|---|")
            for r in summarise(first):
                lines.append(f"| {r['x']} | {r['mean']:,.0f} | {r['lost_per_bot']:.1f} | {r['bought']}/{r['n']} | {r['claimed']} |")
            lines.append("")
        if rows:
            chart(rows, os.path.join(OUT, "income_chart.png"))
            lines.append("![income per bot against X](income_chart.png)")
            lines.append("")
        log = []
        for x in sorted(results):
            for entry in results[x]["log"]:
                entry["Run"] = x
                log.append(entry)
        json.dump(log, open(os.path.join(OUT, "income_log.json"), "w"), indent=1)
        lines.append(f"The income-per-tide log ({len(log)} entries) is in income_log.json.")
        lines.append("")
        for x in sorted(results):
            table, _, _, _ = table_for(results[x])
            lines.append(f"## X = {x}")
            lines.append("")
            lines.extend(table)
            lines.append("")
    trip_path = os.path.join(OUT, "final_trip.json")
    if os.path.exists(trip_path):
        trip = json.load(open(trip_path))["trip"]
        lines.append("## The final-zone trip")
        lines.append("")
        if trip and trip["done"]:
            lines.append(f"One bot with a {trip['tool']} and a {trip['vessel']}, one trip to zone {trip['zone']} and back: "
                         f"{trip['items']} items sold for **{trip['earned']:,} coins** in {trip['gameSeconds']:.0f} s of game time, "
                         f"against a rebirth's base cost of {trip['baseCost']:,}: "
                         f"**{100 * trip['earned'] / trip['baseCost']:.0f}%** of it.")
        else:
            lines.append(f"The trip was not finished in time (earned so far {trip['earned'] if trip else 0}).")
        lines.append("")
    open(os.path.join(OUT, "sweep.md"), "w").write("\n".join(lines) + "\n")
    print(f"wrote {os.path.relpath(os.path.join(OUT, 'sweep.md'), ROOT)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--xs", default="1,2,4,8,12,16,20")
    parser.add_argument("--speed", type=float, default=10)
    parser.add_argument("--seconds", type=int, default=250)
    parser.add_argument("--final-trip", action="store_true")
    parser.add_argument("--no-publish", action="store_true")
    parser.add_argument("--scale", type=float, help="Config.Items.CrowdSpawn.Scale for the run (1 = off)")
    parser.add_argument("--tag", help="name a repeat run (x8_<tag>.json), kept out of the main table")
    parser.add_argument("--report-only", action="store_true")
    args = parser.parse_args()
    os.makedirs(OUT, exist_ok=True)
    if args.report_only:
        write_report()
        return

    jobs = []
    if args.final_trip:
        jobs.append(("final_trip" + (f"_{args.tag}" if args.tag else ""), {"finalTrip": True, "speed": args.speed, "seconds": args.seconds,
                                    "zone": 6, "tool": "HandWinch", "vessel": "Wheelbarrow"}))
    else:
        for x in [int(v) for v in args.xs.split(",")]:
            job = {"bots": x, "speed": args.speed, "seconds": args.seconds}
            if args.scale is not None:
                job["scale"] = args.scale
            jobs.append((f"x{x}" + (f"_{args.tag}" if args.tag else ""), job))

    # One Test Range run at a time: every run publishes its own build to the one place.
    with open("/tmp/salvage-test-range.lock", "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("waiting for another Test Range run to finish ...")
            fcntl.flock(lock, fcntl.LOCK_EX)
        if not args.no_publish:
            publish()
        for name, job in jobs:
            print(f"== {name}: {json.dumps(job)}")
            try:
                result = run_task(job)
            except RuntimeError as error:
                print(f"{name}: {error} (skipped)")
                continue
            with open(os.path.join(OUT, name + ".json"), "w") as f:
                json.dump(result, f, indent=1)
            print("\n".join(result.get("report", [])))
            print("\n".join(result.get("logs", [])[-8:]))
            if result.get("trip"):
                print(json.dumps(result["trip"]))
            frames = result["snapshot"].get("Frames")
            if frames:
                print(f"frames: {frames['Frames']}, worst Heartbeat {1000 * frames['MaxDt']:.0f} ms, "
                      f"worst bot work {1000 * frames['MaxWork']:.1f} ms, over 50 ms: {frames['Slow']}")
            print(f"(setup {result['setupSeconds']:.1f}s, played {result['ranSeconds']:.0f}s)")
    write_report()


if __name__ == "__main__":
    main()
