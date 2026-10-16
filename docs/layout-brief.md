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
