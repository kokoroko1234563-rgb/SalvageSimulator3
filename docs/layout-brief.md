# Brief: whole-zone layouts (for the layout subagents)

> Part 1 is shared by every layout subagent; Part 2 is the assignments, one each. This round:
> zones 4, 5 and 6 (A, B, C) and Hermit Hollows in zone 4 (D), each drawn as a whole zone with
> a frame, five crossings and rolled side rooms. Zones 1 to 3 follow later.

---

## Part 1: for every subagent

You are building ground layouts for **Salvage Simulator 3**, a Roblox game written in Luau and
built with Rojo. Players walk down a long beach toward the sea to salvage washed-up items, then
race the incoming tide back up with their finds. Your job is one zone of the beach's ground,
written as layout data. You prove it works with the tests and the **Test Range**, which runs the
game in the real Roblox engine.

### The game, and what the lower zones are for

- The beach runs out to sea along +Z. It is 720 studs wide (X from -360 to 360) and has six
  zones of **608 studs** each. **A zone is drawn as one piece**: there's no repeating tile.
  A biome that rolls takes the whole zone with its own layout.
- The tide takes 10 minutes to go out and 10 to come back. Players follow it down, explore at low
  tide, then race it back. **The walk down should take about 7 minutes**, and most of that time
  is spent in the lower zones. They should feel claustrophobic and maze-like: walls you can't
  see over, tunnels, dead ends, heavy fog, and the water coming back in behind you.
- Each zone has a target for the fastest way across it on foot (`Config.Zones[i].CrossTime`):
  zone 4: 55 s, zone 5: 65 s, zone 6: 85 s. Walking straight down a zone takes about 30 s, so
  the fastest route must be about 2 to 3 times longer than straight.
- **What went wrong last time** (why this rewrite): layouts were 152-stud strips repeated four
  times down each zone. Being nearly five times wider than deep, every design came out as walls
  across the beach with a gap ("walk sideways to the gap, step down, repeat"), and once you'd
  solved the first strip you'd solved the zone. Now you have the whole 720 × 608 zone: use the
  depth. Make routes that wind down **and** across, double back, go under and around things.
  Avoid long sideways walks along a wall as the main source of time.

### How a zone is built: a frame, crossings and rooms

Every tide, each zone rolls **one of its five crossings** and **one room for each of its side
slots**. So the zone keeps its identity but the way through and the side pockets change.

```lua
return {
	Name = "Outer Shore",
	-- The frame: always there. The zone's landmarks and big structure.
	Primitives = { ... }, Loot = { ... }, Entrances = { ... }, Hazards = { ... },
	-- The ways through: one is picked each tide and added to the frame.
	Crossings = {
		{ Name = "West gallery", Primitives = { ... }, Loot = { ... } },
		... -- five of them
	},
	-- Side rooms: each tide every slot picks one of its Rooms.
	Slots = {
		{
			Name = "West cave",
			At = { -340, 120 }, -- the slot's corner (lowest x, lowest z) in zone coordinates
			Size = { 100, 80 }, -- its width (x) and depth (z)
			Rooms = {
				{ Name = "Drowned pool", Primitives = { ... }, Loot = { ... } }, -- slot coordinates
				... -- three or four rooms
			},
		},
		... -- five to eight slots
	},
}
```

- **Coordinates.** Frame and crossings: X from -360 to 360, z from 0 (the zone's top, toward
  the shop) to 608 (its bottom, toward the sea). Rooms: the slot's own coordinates, x from 0 to
  the slot's width and z from 0 to its depth; they're moved into place. Everything in a room
  stays inside its slot (the tests check). Heights are studs above the beach's even slope.
- **The frame** is the zone's identity: its landmarks (a tall spine, a cave mouth, a long
  gallery), its outer walls, the slots' surroundings. Keep it recognisable from tide to tide.
- **A crossing** decides the way through. Shapes only add up, but **Ramps and Flats clear
  everything, walls included**, so a crossing can open a frame wall (a Flat of radius 10+ or a
  Ramp through it) as well as close gaps (its own Walls). A good pattern: the frame has big
  walls with several possible doors; each crossing opens some and plugs others, and adds its own
  walls, rubble and tunnels. **The five crossings must feel different**: different sides,
  different landmarks on the way, a different order of tunnels and chambers. Not the same route
  with one gap moved.
- **A slot** is a side pocket off the way through. Each slot has a door onto the frame (where
  it opens). Every room in it must keep that door open and be reachable on foot **whichever
  crossing rolled** (the tests check every crossing with the first room, and every room with
  the first crossing, so rooms must join the frame, not one crossing). Rooms in a slot should
  differ in kind: a dead-end cave, a flooded pocket, a boulder scramble, a tunnel loop. **Most
  of the zone's loot goes in rooms**, the best (highest `Weight`) deepest in.

### Repository rules

- You are working in your own copy of the repository (a git worktree). Commit there with clear
  messages. Don't push, and don't open a pull request. Your work is reviewed and merged for you.
- End every commit message with these two lines:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01Rzk2jo5zeuLgwEsf1G5YzW
  ```
- Never write AI model names or model IDs anywhere in the repository.
- **Only edit the files your assignment lists** (plus your own generator scripts under
  `tools/gen/`). If something else seems wrong or missing (the engine, a test, the config),
  don't change it. Say so in your report.
- If something blocks you, stop and report it rather than working around it.

### Read first

- `src/shared/Layouts/init.luau`: the layout format and engine (the comments at the top and
  above "Zone definitions"; `Layouts.compose`, `Layouts.options`, `Layouts.defProblems`).
- The current zone 4 to 6 layouts and Hermit Hollows (`src/shared/Layouts/Zones/`,
  `Biomes/HermitHollows.luau`) and their notes in `docs/layouts/`: drawn for the old strips
  and repeated with `Layouts/Tiled`, but their ideas are good material (zone 5's flooding fords,
  zone 6's galleries and rubble, Hermit Hollows' roofed crab corridors).
- `src/shared/Config.luau`: `Config.Beach.Terrain` (the limits) and `Config.Zones` (the targets).
- `tools/range/README.md`: the Test Range.

### Primitives and placements

| Kind | Fields | What it is |
|---|---|---|
| `Ridge` | `Path`, `Height`, `Width`, `Rock?` | a smooth bank (sand, or rock with `Rock = true`) |
| `Mound` | `At`, `Radius`, `Height`, `Rock?` | a hump or boulder |
| `Wall` | `Path`, `Height`, `Width` | rock with a flat top and sheer sides. It can't be climbed or jumped (an invisible barrier inside it rises 9 studs over its top) |
| `Roof` | `Path` + `Width`, or `At` + `Radius`; `Clearance`, `Thickness` | rock overhead: a tunnel or a cave chamber. Rest it on walls (`Clearance` a little under the walls' `Height`) |
| `Channel` | `Path`, `Depth`, `Width` | a cut that floods when the sea reaches it |
| `Hollow` | `At`, `Radius`, `Depth` | a round dip, a pool |
| `Ramp` | `Path`, `Width` | the cart route: bare slope, cleared through everything |
| `Flat` | `At`, `Radius` | cleared back to bare slope, through everything |
| `Paint` | a shape, `Material` | the ground's material only (mud, shingle, weed), no shape |

- **Any outline:** `Wall`, `Ridge`, `Roof`, `Hollow`, `Flat` and `Paint` can take an
  `Area = { {x, z}, {x, z}, {x, z}, ... }` (a polygon) instead of a Path or At. Use it for rock
  masses, rectangular roofs that sit exactly on their walls, irregular chambers.
- **Worn edges:** `Rough = 4` makes a shape's edge wobble in and out by up to 4 studs (at
  most 8) so it looks eroded, not drawn; its middle stays put.
- **Materials:** `Material = "Basalt"` makes a shape (a roof, a cut's floor, a Paint) of that
  terrain material instead of the zone's own. The choices and their colours are in
  `Config.Looks.Materials`.

Placements: `Loot = { { At = {x, z}, Radius = 6, Weight = 1 }, ... }` (finds settle there once
each tide as the sea leaves them dry; Weight raises both the chance and the rarity),
`Entrances = { {x, z}, ... }` (flat spots for a biome's secret entrance),
`Hazards = { { Type = "Patrol", Path = { {x, z}, ... }, Count = 2 }, ... }` (see
`src/shared/Hazards.luau`).

### Hard rules (the tests check them)

1. **Cart route.** Every crossing has a Ramp (at least 14 wide, never steeper than `CartSlope`
   0.35) from the zone's top edge (a Path end at z 0 to 8) to its bottom edge (z 600 to 608). It
   can be one long winding Ramp or a chain. Ramps clear 7 studs either side and blend over 8
   more, so keep walls 15+ studs from a ramp's centre line unless you mean to cut them.
2. **Everything reachable.** In every crossing, a cart and a player on foot get from the top
   edge to the bottom edge, and every loot spot and entrance can be reached on foot from the
   top. Players can't walk up anything steeper than `FootSlope` (0.9, about 42°).
3. **Foot shortcuts.** At least two of the starts x = -300, -150, 0, 150, 300 on the top edge
   have a faster way down on foot than by cart (a scramble a cart can't take).
4. **Hidden from the top.** At least 60% of the zone's lower half is out of sight from its top
   edge at eye height.
5. **Sizes.**
   - Walls: 12 to 24 studs wide and at most 24 tall. Roofs: `Clearance` at least 8,
     `Thickness` at least 6, `Clearance + Thickness` at most 32. Other shapes: at most 12 high
     and 4 deep. Rock ridges at least 16 wide. Nothing narrower than 8 studs.
   - **Walls' faces on the 4-stud grid**: both faces at 4k+2 (the centre line ± Width/2, in z,
     or x for walls running down the beach). A Width of 12 or 20 needs its centre on a multiple
     of 4; 16 or 24 a centre on 4k+2. Wall ends at 4k+2 too. Walls under about 12 tall get their
     tops rounded off and draw narrower.
6. **Rock pools.** Keep shapes 6+ studs clear of the rock pools in your zone (`Config.Beach.Pools`).
7. **Edges.** Shapes fade to flat over the first and last 6 studs of the zone (the zones meet
   along that flat strip, so a route can enter anywhere on the top edge) and the last 30 studs
   before the side cliffs.
8. **Placements on the zone**, z 0 to 608; rooms' everything inside their slot.

### Making it good, not just legal

- **Each crossing's fastest time within 15% of the zone's target.** A crossing much quicker
  than the others will be the one everyone remembers; much slower feels unfair.
- **Corridors 12 to 20 studs wide**: tight but fair for a player carrying something. A cart
  needs the ramp's width.
- **Use the depth.** Switchbacks down, spirals, a route that dives under a roof and comes out
  somewhere unexpected. A good zone has places you only see if you go looking.
- **Dead ends with a reason**: loot. Wrong turns should still pay off sometimes.
- **The water.** Low ground and tunnels below the slope flood as the tide comes in. A ford or
  tunnel that floods early can cut off the quick way back. Say which parts flood first.
- **Readable, not random.** A few big landmarks in the frame, so players learn the zone even
  though the way through changes.

### How to check your work

1. `bash tools/check.sh`: formatting, the data checks and all the Lune tests (about a minute).
   It must pass. Run `stylua src tools` if formatting fails. Read only the result:
   `bash tools/check.sh 2>&1 | grep -A3 "^FAIL\|passed\|All checks\|FAILED"`.
2. `lune run tools/layout_map.luau - Zones/Zone5` (your layout's source): prints, for every
   crossing and room, two lines of measurements, including **"fastest crossing on foot: about
   … s (target …)"**. Add `--maps` to see the ASCII maps and flood orders (long: only when you
   need to look). With `docs/layouts` instead of `-` it writes the maps into the notes'
   `<!-- map Zones/Zone5@5 -->` markers (keys: `@5` the first of everything, `@5/c2` crossing 2,
   `@5/s3r2` room 2 of slot 3). It rewrites every note it has a marker for; revert the notes
   that aren't yours.
3. **The Test Range**, the real engine, once the first two pass:
   ```
   python3 tools/range/run.py --zone 5 --choice 2:1,1,1   # one variation while you iterate
   python3 tools/range/run.py --zone 5 --every            # once, at the very end
   ```
   (`--all HermitHollows` for the biome.) It reports things floating or buried or inside rock,
   the terrain, walls and roofs against your layout, patrol routes crossing walls, unreachable
   or one-way loot spots, the fastest crossing walking the real terrain against the target, and
   how much floods at four tide levels. `--every` prints one line per variation (choice, fastest
   time, problem count) and the details only for variations with problems; `--summary` does the
   same for a single run. Each run takes about a minute, and only one runs at a time across all
   the agents (the runner waits its turn).

### Notes from the review place

The game is also played and appraised in the **review place**, where notes are pinned to the
spot they're about, with the zone, crossing, slot and room they were left in. **Before you start,
read the open notes for your zone and address each one:**

```
python3 tools/review/review.py notes --zone 5      # open notes, one per line
python3 tools/review/review.py times --zone 5      # crossings timed by playing, per variation
```

Positions are in your layout's coordinates (x, and z from the zone's top edge). In your
report, say what you did about each note by its number (`#12: moved the door, see crossing 3`);
the coordinator marks them resolved. Notes outrank the measurements: a crossing that times
right but plays badly still needs fixing.

### Keeping the work cheap (rules)

- **Run the Test Range in the foreground and wait for it.** Never start background tasks,
  timers, monitors or `sleep` loops to wait for anything. Use `--choice` while iterating and
  `--every` once at the very end.
- **Keep outputs short.** Pipe long output through `tail`, `grep` or the summary modes; don't
  read full reports or whole JSON files. Read only the part of a file you need.
- **Generator scripts are committed files** in your worktree (e.g. under `tools/gen/`, named for
  your layout), not scratch files you re-read or re-paste.
- **Commit after each working step.** If `git commit` or `git push` is refused by a permission
  check, don't work around it: leave the work uncommitted and say so in your report.
- **Before you stop**, check that no background tasks of yours are left running.

### Done when

- `bash tools/check.sh` passes.
- The Test Range `--every` reports no problems for your zone.
- Every crossing's Test Range fastest time is within 15% of the target (or the gap is explained).
- You've written your zone's note in `docs/layouts/`: the frame and its landmarks, each crossing
  in a line or two, each slot and its rooms, what floods first, and the measured times, with the
  map markers for the first of everything and each crossing.

### Your report

Keep it short: what you built (frame, crossings, slots), the measured times per crossing (map
tool and Test Range) against the target, what the Test Range still reports and why, and anything
you couldn't do or think the engine needs.

---

## Part 2: the assignments

### A. Zone 4, Outer Shore (`src/shared/Layouts/Zones/Zone4.luau`, rewrite)

- **Files:** `Zones/Zone4.luau`, `docs/layouts/Zone4.md`.
- **Target:** 55 s.
- **Feel:** the first zone of real rock, where the maze feeling starts, not where it peaks.
  Long rock spines and boulder fields, still mostly open sky (fog does the hiding), one or two
  short tunnels as landmarks. Rooms: sheltered coves behind the spines, a boulder scramble, a
  sea cave.

### B. Zone 5, The Shoals (`src/shared/Layouts/Zones/Zone5.luau`, rewrite)

- **Files:** `Zones/Zone5.luau`, `docs/layouts/Zone5.md`.
- **Target:** 65 s.
- **Feel:** flooded ground between rock bars. Channels and fords that flood in a clear order,
  low walls you go round, a cave chamber or two to shelter in. The tide is the main danger: the
  quick ways go through the fords, and they go under first. Crossings can differ in which fords
  they use. Rooms: flooded pockets, a grotto, a weed-choked channel.

### C. Zone 6, The Drowned Reach (`src/shared/Layouts/Zones/Zone6.luau`, rewrite)

- **Files:** `Zones/Zone6.luau`, `docs/layouts/Zone6.md`.
- **Target:** 85 s.
- **Feel:** the deepest, slowest ground. A true maze of tall walls and roofed passages, long
  switchback ramps for carts, low ground everywhere so most of it floods early on the way back.
  Rooms: the far dead ends, drowned galleries, collapsed chambers, with the best finds on the
  beach.

### D. Hermit Hollows in zone 4 (`src/shared/Layouts/Biomes/HermitHollows.luau`, rewrite `[4]`)

- **Files:** `Biomes/HermitHollows.luau`, `docs/layouts/HermitHollows.md`.
- **What:** a whole-zone definition for zone 4: `return { [4] = def, [5] = ..., [6] = ... }`.
  Keep the existing zone 5 and 6 layouts as they are for now, wrapped with
  `require(script.Parent.Parent.Tiled)(layout)` each, so they still play; only `[4]` is new.
- **Target:** at least zone 4's 55 s; a rare biome may be slower, up to 30% over.
- **Feel:** a giant hermit crab's tunnels. A maze of rock-walled, mostly roofed corridors 12 to
  16 wide, with a few open chambers where the roof breaks. Crossings: different tunnel systems
  through the same warren. Rooms: crab nests, shell middens, a collapsed chamber.
- **Its hazard:** hermit crabs patrolling the corridors (`Hazards = { { Type = "Patrol",
  Path = ..., Count = ... } }`, in the frame, a crossing or a room). The routes must stay in the
  corridors (the Test Range reports routes that cross walls). About 16 to 24 crabs in the zone,
  on routes that cross the way through, so they have to be timed.
- **Entrance:** one `Entrances` spot in the frame, in a chamber, kept flat, for its secret.

---

## Round 4: zone 6 as the role model

Zone 6, The Drowned Reach, is being finished to the standard every other zone will copy:
its structure fixed, its dangers placed, and its ground decorated. Assignment G below.

### Dangers are deadly (the rule)

A danger that only slows you is scenery. The plain zones' own dangers (`Config.Zones[i].Hazards`,
placed by the layout's `Hazards` list, see `src/shared/Hazards.luau`) kill, or come close:

| Type | Placement | What it does | Its tell |
|---|---|---|---|
| `Sink` | `At`, `Radius` | sinking sand: you sink while in it (fast standing still, slowly moving); fully sunk, you die | darker, wet-looking sand |
| `Rockfall` | `At` (under a roof) | a rock falls every few seconds and kills whoever it lands on | dust and pebbles trickle down first; old rubble on the floor |
| `Undertow` | `Path`, `Width` | while the sea covers a ford or channel, a current drags you seaward into deep water (you drown) | foam streaming along it |
| `Gloom` | `Path` (it drifts back and forth) or `At`, `Radius` | zone 6's own: a living darkness. Inside it your dread rises; full, it takes you. Slower with a light; it drains outside it and within a ward's light. It swells once the tide turns | an inky fog; your light gutters |

**Fair, not random:** a regular who knows the zone must be able to avoid every danger.
Each has its tell, sits where it can be learned (the same spot in the frame, or the same spot
in its crossing or room), and never blocks the only way through without a safe moment (a
rockfall's rhythm, a ward to wait in, a way round).

### Decor (the decorating pass)

A layout's `Decor` list places props (`src/shared/Decor.luau` lists the kinds):
`{ Kind = "Kelp", At = {x, z} }`, or `Count` of them over an `Area` or along a `Path`, with
optional `Scale` and `Yaw`. Props stand on open ground (Barnacles may cling to rock), never
collide, and come out the same every time. **Wards:** `GlowShells`, `GlowWeed` and
`LanternPost` give off light and the Gloom can't reach within their ward radius (9, 12, 18
studs): they're the safe spots in the Gloom's galleries, and a trail of them is a way through.

The ground itself is decorated with the shape tools: `Rough` (worn edges), `Material` (a
shape's own terrain material) and `Paint` (the ground's material in an area: mud, shingle,
weed) and any outline with `Area`.

### Looking at your work

- `python3 tools/layout_render.py 6 Base 2:1,1,1,1,1,1,1 -o out.png` draws one way the zone
  comes out from above: walls, roofs, ramps, loot, slots, every hazard, the wards' light and the
  decor. **Look at it** (open the PNG) after each step.
- `python3 tools/snapshot/snapshot.py top -360 3040 360 3648 --zone 6=Base:1: -o out.png` draws
  the built game from the engine's own parts (slower: a minute).

### G. Zone 6, The Drowned Reach, finished (`src/shared/Layouts/Zones/Zone6.luau`)

- **Files:** `Zones/Zone6.luau`, `docs/layouts/Zone6.md`, and any generator scripts you write
  under `tools/gen/zone6/` (commit them).
- **Keep:** the maze itself (its walls, its five crossings' routes and times, the slots). It
  plays well; this round is about its flaws and its dressing, not a redraw.
- **Fix the structure:**
  1. **Roofs fit their walls.** Replace the rounded `Path` roofs with `Area` rectangles (or
     polygons) that sit exactly on the walls under them: no roof overhanging an open lane, no
     rounded ends sticking into corridors, no roof floating over a junction.
  2. **Less roof, with light.** At most about 40% of the zone under a roof. Break the long
     galleries with gaps of open sky (light shafts). The side rooms mostly open to the sky.
  3. **Rooms that differ.** The seven slots' rooms all look alike (a roofed box with a few
     walls). Make each slot's rooms differ in shape and kind.
  4. **No bars at the ends.** The top and bottom walls run nearly the full width with gates:
     break them up so the zone's edges aren't a "find the gap" wall.
  5. **Loot at real dead ends**, the best deepest in.
- **Tells:** each crossing's way in (the first stretch from the top edge) gets its own
  landmark (a big piece of decor or a shape: a wreck, a lantern post, an arch of bones), so a
  regular knows which crossing rolled before committing. Each room's door gets one too.
- **Dangers:** place the zone's kit, deadly and fair (see the rule above):
  - sinking sand in a few lanes (not on the cart ramps);
  - rockfall in some roofed passages;
  - undertow in the channels and fords;
  - **two or three Glooms** drifting along the galleries, with wards (lantern posts, glowing
    weed and shells) placed as safe spots and as a lit trail through.
  - Every crossing must stay crossable; the Gloom may make a route slow and frightening, not
    impossible.
- **Decorate:** a drowned, long-sunk feel. Wreck ribs, bones, kelp, chains and an anchor,
  barnacles on the walls, dead coral, timbers; `Rough` edges on the walls (2 to 3 studs) to
  break the grid; `Material`s (Basalt, Slate, Limestone) and `Paint` (Mud, Limestone) for
  variety in the ground. Enough to make every lane look like somewhere, not clutter.
- **Check:** `bash tools/check.sh`, the map tool's times (each crossing within 15% of 85 s,
  as now), `layout_render.py` for each crossing (look at them), and the Test Range `--every`
  once at the end, clean.
- **Report:** what you changed, the times, a render of the first crossing, anything you
  couldn't do.

### H. The shore, zones 1 to 3, as whole natural zones (`Zones/Zone1.luau`, `Zone2.luau`, `Zone3.luau`)

- **Files:** those three, their notes in `docs/layouts/`, and your scripts under
  `tools/gen/shore/`.
- **What's wrong now** (look at `python3 tools/layout_render.py 1 Base 1: -o z1.png`): each is an
  old 152-stud strip repeated four times down the zone, so the same low banks come round every
  152 studs as straight horizontal stripes, like corduroy. Between the shop and the water there's
  nothing to look at: flat sand.
- **What it should be:** a sunny, inviting shore that gets a little wilder going out. Natural,
  never repeated, nothing ruled straight:
  - **Zone 1, Shopside Shore** (35 s): open and readable from the top (hides at most 20% of its
    lower half). Soft dunes near the top, a shallow creek meandering down to the sea, a couple of
    tide pools, wrack lines (weed, shells and driftwood strung along where high tides left them).
  - **Zone 2, Sunny Stretch** (40 s): low curving sandbars and runnels (shallow channels between
    them) that make you weave, a rocky outcrop or two (decor rocks), the rock pools.
  - **Zone 3, Middle Banks** (45 s): bigger banks with worn edges, a creek mouth, a small old
    wreck half buried, more wrack. Starts to hide the way ahead (at least 60% of its lower half).
- **Tools:** curving `Path`s and `Area` outlines, `Rough` edges (2 to 4), `Paint` for damp or
  firm sand (`Salt`, `Ground`) and a pebble bank (`Slate`), and `Decor`: `Shells`, `Rocks`,
  `DuneGrass`, `Driftwood`, `Weed`, `Starfish`, `Pebbles`, `Timber`, `WreckRibs` (zone 3),
  `Crate`. Compose: clusters and lines with open sand between, not an even sprinkle.
- **Rules (the tests check them):** no rock shapes or walls before zone 4 (rocks as decor are
  fine); heights at most 2.5 (zone 1), 5 (zone 2), 7 (zone 3); cuts at most 4 deep; keep 6+
  studs clear of the rock pools in your zones; keep the pier's line clear in zone 2 (the test
  "the pier's path and every entrance spot are clear of shapes" says where); a cart ramp from
  each zone's top edge to its bottom edge in every crossing; at least two foot shortcuts.
  Crossings and slots are optional here: one or two crossings each is plenty, and a slot or two
  (a tide-pool cove, a dune hollow) where rolled rooms add variety.
- **Times:** each zone's fastest crossing on foot near its target (35, 40, 45 s) on the
  Test Range.
- **Check:** `bash tools/check.sh`, the map tool, `layout_render.py` (look at each zone), the Test
  Range `--every` per zone at the end.

---

## Round 5: the biomes as whole zones

Zone 6 (assignment G, `docs/layouts/Zone6.md`) is the model for how a zone is finished: roofs
that fit their walls, little roof, rooms that differ, no "find the gap" bars at the ends, loot at
real dead ends, a landmark at each crossing's way in and at each room's door, deadly but fair
dangers, and decor that makes every stretch look like somewhere. What it learned:

- Walls take at most `Rough = 1` (the Test Range's wall-width tolerance is 3); rubble, pools and
  boulders take 3. Run walls 4 studs into their posts so worn ends leave no crack.
- Roof a cell only where at least two of its sides are walls.
- A generator script (`tools/gen/<name>/`) that checks reachability and dead ends is cheaper
  than hand-editing 1500 lines.

### I. Hermit Hollows in zones 5 and 6 (`Biomes/HermitHollows.luau`, rewrite `[5]` and `[6]`)

- **Files:** `Biomes/HermitHollows.luau`, `docs/layouts/HermitHollows.md`, the generator in
  `tools/hermit_hollows_gen/` (extend it; commit it).
- **What:** `[5]` and `[6]` are still the old 152-stud tiles repeated (`Tiled(zone5)`,
  `Tiled(zone6)`). Make each a whole-zone warren like `[4]`, deeper and meaner: zone 5's target is
  zone 5's CrossTime, zone 6's is zone 6's, a rare biome may be up to 30% over.
- **Its dangers:** the hermit crab Patrols (on routes that stay in the corridors and cross the
  way through) and, in zone 6, **the giant hermit crab** (`{ Type = "Hunter", ... }`, see
  `Hazards.luau`; it patrols, sees you in its sight range, chases and kills). One giant per
  crossing in zone 6, with its own lair (a big chamber), on a route through the warren so a
  player has to sneak past or outrun it. It may also appear in zone 5's deepest crossing.
  Glowing shells and weed (`GlowShells`, `GlowWeed`) mark the safe ways where it's dark.
- **Apply the zone 6 lessons above:** landmarks at each crossing's way in, rooms that differ,
  loot at dead ends, decor (shell middens, bones, crab moults: use the decor kinds there are).
- **Keep:** `[4]` as it is; the biome's `Entrances` spot (one per zone, in a chamber, kept flat).

### J. Shipwreck Shallows as whole zones (`Biomes/ShipwreckShallows.luau`, rewrite)

- **Files:** `Biomes/ShipwreckShallows.luau`, `docs/layouts/ShipwreckShallows.md`, your scripts
  in `tools/gen/shipwreck/`.
- **What:** it's one old 152-stud tile repeated down whichever zone it rolls in (zones 2 to 6,
  `Biomes.luau`). Make whole-zone definitions, one per zone it can roll in (`[2]` to `[6]`, they
  may share a generator with the depth as a parameter): a wreck-strewn stretch around one big
  wreck, with scour channels, debris mounds, a gully for the rolling barrels, and the ship's
  hatch (its `Entrances`) kept as the biome needs (read `BiomeService` and the current file
  before changing them).
- **Rules by depth:** in zones 2 and 3 no `Wall` or rock (the shore rules, assignment H); from
  zone 4 on, walls and roofs as the plain zone may have (the wreck's hull can be a wall).
- **Its dangers:** the barrels (`Roller`) must still be deadly and readable: the gully and the
  channels are where they run. Add the zone's own plain dangers where they fit.
- **Times:** each zone's CrossTime, a biome up to 30% over.
- **Apply the zone 6 lessons above.**
