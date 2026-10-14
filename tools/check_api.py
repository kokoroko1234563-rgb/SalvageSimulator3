#!/usr/bin/env python3
"""Checks the Luau source against Roblox's real API, so made-up names fail before they
reach Studio.

  * every Enum.X.Y exists
  * every Instance.new("Class") and GetService("Service") names a real class
  * every property set on a created instance exists on that class, including the
    property tables passed to this project's helpers (make, makePart, block, text, ...)

The API comes from the @rbxts/types npm package (generated from Roblox's API dump). It is
downloaded once into tools/.cache and only read as text.

Usage: python3 tools/check_api.py         (exit code 1 if anything is wrong)
"""

import io
import json
import os
import re
import sys
import tarfile
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "tools", ".cache")
PACKAGE = "@rbxts/types"
VERSION = "1.0.957"

# Helpers in this project that create an instance and apply a property table.
# name -> (class, which call argument holds the table: "first" table literal / "last")
HELPERS = {
    "makePart": "Part",
    "waterPart": "Part",
    "block": "Part",
    "part": "Part",
    "text": "TextLabel",
    "label": "TextLabel",
}


def fetch_definitions():
    folder = os.path.join(CACHE, f"rbxts-types-{VERSION}")
    marker = os.path.join(folder, "include", "generated", "enums.d.ts")
    if os.path.exists(marker):
        return folder
    os.makedirs(CACHE, exist_ok=True)
    meta = json.load(urllib.request.urlopen(f"https://registry.npmjs.org/{PACKAGE}/{VERSION}"))
    data = urllib.request.urlopen(meta["dist"]["tarball"]).read()
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
        for member in tar.getmembers():
            if member.name.startswith("package/include/") and member.name.endswith(".d.ts"):
                target = os.path.join(folder, member.name[len("package/") :])
                os.makedirs(os.path.dirname(target), exist_ok=True)
                with open(target, "wb") as out:
                    out.write(tar.extractfile(member).read())
    return folder


def parse_enums(path):
    enums = {}
    current = None
    for line in open(path, encoding="utf-8"):
        m = re.match(r"\s{4}export namespace (\w+) \{", line)
        if m:
            current = enums.setdefault(m.group(1), set())
            continue
        m = re.match(r"\s{8}export interface (\w+) extends globalThis\.EnumItem", line)
        if m and current is not None:
            current.add(m.group(1))
    return enums


def parse_classes(paths):
    parents, members = {}, {}
    for path in paths:
        current = None
        for line in open(path, encoding="utf-8"):
            m = re.match(r"interface (\w+)(?:<[^{]*?>)?(?: extends ([\w]+)(?:<[^{]*?>)?(?:, [^{]*)?)? \{", line)
            if m:
                current = m.group(1)
                parent = (m.group(2) or "").split(",")[0].strip()
                if parent:
                    parents[current] = parent
                members.setdefault(current, set())
                continue
            if line.startswith("}"):
                current = None
                continue
            if current:
                m = re.match(r"\s{4}(?:readonly\s+)?(\w+)\??\s*[:(<]", line)
                if m:
                    members[current].add(m.group(1))
    return parents, members


def all_members(cls, parents, members):
    seen = set()
    while cls and cls not in seen:
        seen.add(cls)
        yield from members.get(cls, ())
        cls = parents.get(cls)


def table_keys(source, start):
    """Top-level keys of the table literal whose '{' is at `start`."""
    depth, i, keys = 0, start, []
    while i < len(source):
        c = source[i]
        if c in "{([":
            depth += 1
            if depth == 1:
                pass
        elif c in "})]":
            depth -= 1
            if depth == 0:
                break
        elif depth == 1 and (c == "{" or i == start + 1 or source[i - 1] in ",{\n\t "):
            m = re.match(r"\s*(\w+)\s*=(?!=)", source[i:])
            if m and source[i - 1] in ",{\n\t ":
                keys.append((m.group(1), i))
                i += m.end() - 1
        i += 1
    return keys


def line_of(source, index):
    return source.count("\n", 0, index) + 1


def check():
    defs = fetch_definitions()
    enums = parse_enums(os.path.join(defs, "include", "generated", "enums.d.ts"))
    parents, members = parse_classes(
        [
            os.path.join(defs, "include", "generated", "None.d.ts"),
            os.path.join(defs, "include", "generated", "PluginSecurity.d.ts"),
        ]
    )
    problems = []

    def report(path, source, index, message):
        problems.append(f"{os.path.relpath(path, ROOT)}:{line_of(source, index)}: {message}")

    def check_props(path, source, cls, brace_index):
        valid = set(all_members(cls, parents, members))
        for key, index in table_keys(source, brace_index):
            if key not in valid:
                report(path, source, index, f"{cls} has no property '{key}'")

    for folder, _, files in os.walk(os.path.join(ROOT, "src")):
        for name in files:
            if not name.endswith(".luau"):
                continue
            path = os.path.join(folder, name)
            source = open(path, encoding="utf-8").read()
            # Strip comments so examples in comments don't count.
            code = re.sub(r"--[^\n]*", lambda m: " " * len(m.group(0)), source)

            for m in re.finditer(r"\bEnum\.(\w+)\.(\w+)", code):
                enum, item = m.group(1), m.group(2)
                if enum not in enums:
                    report(path, code, m.start(), f"Enum.{enum} doesn't exist")
                elif item not in enums[enum]:
                    report(path, code, m.start(), f"Enum.{enum}.{item} doesn't exist")

            for m in re.finditer(r'GetService\("(\w+)"\)', code):
                if m.group(1) not in members:
                    report(path, code, m.start(), f"no service called {m.group(1)}")

            # local x = Instance.new("Class") ... x.Prop =
            for m in re.finditer(r'local (\w+)(?:\s*:\s*\w+)?\s*=\s*Instance\.new\("(\w+)"\)', code):
                var, cls = m.group(1), m.group(2)
                if cls not in members:
                    report(path, code, m.start(), f"no class called {cls}")
                    continue
                valid = set(all_members(cls, parents, members))
                rest = code[m.end() :]
                stop = re.search(r"\blocal " + var + r"\b", rest)
                scope = rest[: stop.start()] if stop else rest
                for pm in re.finditer(r"(?<![\w.:])" + var + r"\.(\w+)\s*=(?!=)", scope):
                    if pm.group(1) not in valid:
                        report(path, code, m.end() + pm.start(), f"{cls} has no property '{pm.group(1)}'")
            for m in re.finditer(r'Instance\.new\("(\w+)"\)', code):
                if m.group(1) not in members:
                    report(path, code, m.start(), f"no class called {m.group(1)}")

            # make("Class", { ... })
            for m in re.finditer(r'\bmake\(\s*"(\w+)"\s*,\s*\{', code):
                cls = m.group(1)
                if cls not in members:
                    report(path, code, m.start(), f"no class called {cls}")
                else:
                    check_props(path, code, cls, m.end() - 1)

            # project helpers: the property table is a table literal argument
            for helper, cls in HELPERS.items():
                for m in re.finditer(r"(?<![\w.])" + helper + r"\(", code):
                    # find the call's argument span
                    depth, i = 1, m.end()
                    while i < len(code) and depth > 0:
                        depth += {"(": 1, ")": -1}.get(code[i], 0)
                        i += 1
                    args = code[m.end() : i]
                    # check every table literal at the top argument level that looks like props
                    level = 0
                    for j, c in enumerate(args):
                        if c in "([{":
                            if c == "{" and level == 0:
                                keys = table_keys(code, m.end() + j)
                                if keys and all(k[0][0].isupper() for k in keys):
                                    check_props(path, code, cls, m.end() + j)
                            level += 1
                        elif c in ")]}":
                            level -= 1

    if problems:
        print("Roblox API check found problems:")
        for problem in sorted(set(problems)):
            print("  " + problem)
        return 1
    print("Roblox API check: OK")
    return 0


if __name__ == "__main__":
    sys.exit(check())
