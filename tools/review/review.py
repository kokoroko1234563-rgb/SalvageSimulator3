#!/usr/bin/env python3
"""The review place: publish the game there, and read the notes left by playing it.

In the review place (a private experience of its own, see review.json and Config.Review),
admins get a review panel: where they are (zone, biome, crossing, slot and room), buttons to
step through the variations, a stopwatch per zone, and notes pinned where they stand. Notes,
zone times and walked paths are saved in a DataStore. This tool reads them through Open
Cloud's Luau Execution in that place (no DataStore permission needed on the key).

Usage (from the repo root):
  python3 tools/review/review.py publish                 build and publish to the review place
  python3 tools/review/review.py notes [--zone 6] [--all] [--layout "Drowned Reach"]
                                                          open notes (--all: resolved too)
  python3 tools/review/review.py times [--zone 6]        timed crossings, by variation
  python3 tools/review/review.py resolve 12 "what was done"
  python3 tools/review/review.py trails [--last 3]       the latest walked paths, summarised

Notes print one per line: id, zone, layout, crossing and rooms (the choice, as
Layouts.encode), crossing name, slot and room, position in the zone (x, z from its top
edge), rating, tags and text.
"""

import argparse
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
SETTINGS = json.load(open(os.path.join(HERE, "review.json")))
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
    place_file = os.path.join(HERE, "out", "review.rbxl")
    os.makedirs(os.path.dirname(place_file), exist_ok=True)
    built = subprocess.run(["rojo", "build", os.path.join(ROOT, "default.project.json"), "-o", place_file],
                           capture_output=True, text=True)
    if built.returncode != 0:
        sys.exit(f"rojo build failed:\n{built.stdout}{built.stderr}")
    url = f"{API}/universes/v1/{SETTINGS['universe']}/places/{SETTINGS['place']}/versions?versionType=Published"
    result = request("POST", url, open(place_file, "rb").read(), "application/octet-stream")
    print(f"published to the review place as version {result.get('versionNumber')}")


def run_luau(script):
    url = f"{API}/cloud/v2/universes/{SETTINGS['universe']}/places/{SETTINGS['place']}/luau-execution-session-tasks"
    task = request("POST", url, {"script": script, "timeout": "120s"})
    while task.get("state") in ("QUEUED", "PROCESSING"):
        time.sleep(2)
        task = request("GET", f"{API}/cloud/v2/{task['path']}")
    if task.get("state") != "COMPLETE":
        sys.exit(f"the script failed in the review place: {json.dumps(task.get('error'))}")
    return json.loads(task["output"]["results"][0])


STORE = f'game:GetService("DataStoreService"):GetDataStore("{SETTINGS["datastore"]}")'
JSON = 'game:GetService("HttpService")'


def fetch_notes():
    return run_luau(f'return {JSON}:JSONEncode({STORE}:GetAsync("notes") or {{}})') or []


def where(note):
    parts = [f"zone {note.get('Zone', '?')}"]
    if note.get("Biome"):
        parts.append(note["Biome"])
    if note.get("Layout"):
        parts.append(f"{note['Layout']} {note.get('Choice', '')}")
    if note.get("Crossing"):
        parts.append(f"crossing \"{note['Crossing']}\"")
    if note.get("Slot"):
        parts.append(f"slot \"{note['Slot']}\" room \"{note.get('Room', '?')}\"")
    if note.get("X") is not None:
        parts.append(f"at x {note['X']}, z {note.get('Z')}")
    return ", ".join(parts)


def show_notes(args):
    notes = [n for n in fetch_notes() if n.get("Kind") == "note"]
    shown = 0
    for n in notes:
        if args.zone and n.get("Zone") != args.zone:
            continue
        if args.layout and args.layout.lower() not in (n.get("Layout") or "").lower():
            continue
        if n.get("Resolved") and not args.all:
            continue
        shown += 1
        state = "resolved" if n.get("Resolved") else "open"
        rating = f" rating {n['Rating']}/5" if n.get("Rating") else ""
        tags = f" [{', '.join(n['Tags'])}]" if n.get("Tags") else ""
        print(f"#{n.get('Id')} ({state}) {where(n)}{rating}{tags}: {n.get('Text', '')}")
        if n.get("Resolved") and n.get("Resolution"):
            print(f"    resolved: {n['Resolution']}")
    print(f"({shown} of {len(notes)} notes)")


def show_times(args):
    rows = {}
    for n in fetch_notes():
        if n.get("Kind") != "time" or (args.zone and n.get("Zone") != args.zone):
            continue
        key = (n.get("Zone"), n.get("Layout"), n.get("Choice"), n.get("Crossing"), n.get("Target"))
        rows.setdefault(key, []).append(n.get("Seconds", 0))
    for (zone, layout, choice, crossing, target), seconds in sorted(
            rows.items(), key=lambda r: (r[0][0] or 0, str(r[0][2]))):
        avg = sum(seconds) / len(seconds)
        print(f"zone {zone} {layout} {choice} \"{crossing}\": {len(seconds)} runs, "
              f"best {min(seconds):.0f}s, average {avg:.0f}s (target {target}s)")
    if not rows:
        print("no timed crossings yet")


def resolve(args):
    comment = args.comment.replace("]==]", "] ==]")
    script = f'''
local ok = false
{STORE}:UpdateAsync("notes", function(list)
	for _, note in list or {{}} do
		if note.Id == {int(args.id)} then
			note.Resolved = true
			note.Resolution = [==[{comment}]==]
			note.ResolvedAt = os.time()
			ok = true
		end
	end
	return list
end)
return {JSON}:JSONEncode(ok)'''
    print("resolved" if run_luau(script) else f"no note #{args.id}")


def show_trails(args):
    script = f'''
local store = {STORE}
local keys = {{}}
local pages = store:ListKeysAsync("trail/")
while true do
	for _, key in pages:GetCurrentPage() do
		table.insert(keys, key.KeyName)
	end
	if pages.IsFinished then break end
	pages:AdvanceToNextPageAsync()
end
table.sort(keys, function(a, b)
	return tonumber(string.match(a, "(%d+)$")) > tonumber(string.match(b, "(%d+)$"))
end)
local out = {{}}
for index = 1, math.min(#keys, {int(args.last)}) do
	table.insert(out, {{ Key = keys[index], Points = store:GetAsync(keys[index]) }})
end
return {JSON}:JSONEncode(out)'''
    for trail in run_luau(script) or []:
        points = trail.get("Points") or []
        print(f"{trail['Key']}: {len(points)} points over {points[-1][0] if points else 0} s")
        # Time spent in each zone and variation, in the order walked.
        spans = []
        for t, zone, choice, x, z in points:
            if spans and spans[-1][0] == zone and spans[-1][1] == choice:
                spans[-1][3] = t
            else:
                spans.append([zone, choice, t, t])
        for zone, choice, start, end in spans:
            print(f"    zone {zone} ({choice}): {end - start} s")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("publish")
    notes = sub.add_parser("notes")
    notes.add_argument("--zone", type=int)
    notes.add_argument("--layout")
    notes.add_argument("--all", action="store_true")
    times = sub.add_parser("times")
    times.add_argument("--zone", type=int)
    res = sub.add_parser("resolve")
    res.add_argument("id", type=int)
    res.add_argument("comment")
    trails = sub.add_parser("trails")
    trails.add_argument("--last", type=int, default=3)
    args = parser.parse_args()
    {"publish": lambda: publish(), "notes": lambda: show_notes(args), "times": lambda: show_times(args),
     "resolve": lambda: resolve(args), "trails": lambda: show_trails(args)}[args.command]()


if __name__ == "__main__":
    main()
