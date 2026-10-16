# Brief: the lower zones' layouts (for the layout subagents)

> Part 1 is shared by every layout subagent; Part 2 is the assignments, one each. The first
> round was zone 4: its base layout (A) and Hermit Hollows in zone 4 (D), both done. The second
> round is zones 5 and 6 (B, C) and Hermit Hollows in zones 5 and 6 (E).

---

## Part 1: for every subagent

You are building ground layouts for **Salvage Simulator 3**, a Roblox game written in Luau and
built with Rojo. Players walk down a long beach toward the sea to salvage washed-up items, then
race the incoming tide back up with their finds. Your job is one part of the beach's ground,
written as layout data. You prove it works with the tests and the **Test Range**, which runs the
game in the real Roblox engine.

### The game, and what the lower zones are for

- The beach runs out to sea along +Z. It is 720 studs wide (X from -360 to 360) and has six
  zones of 608 studs each. **Each zone is four 152-stud tiles deep.** A zone's base layout is used
  on each of its four tiles, unless a biome rolls on a tile and brings its own layout.
- The tide takes 10 minutes to go out and 10 to come back. Players follow it down, explore at low
  tide, then race it back. **The walk down should take about 7 minutes**, and most of that time
  is spent in the lower zones. They should feel claustrophobic and maze-like: walls you can't
  see over, tunnels, dead ends, and the water coming back in behind you.
- Each zone has a target for the fastest way across it on foot (`Config.Zones[i].CrossTime`):
  - zone 4: 55 s
  - zone 5: 65 s
  - zone 6: 85 s

  A zone is four tiles of the same layout, so **one tile should take about a quarter of that**:
  - zone 4: about 14 s per tile
  - zone 5: about 16 s per tile
  - zone 6: about 21 s per tile

  Walking straight down a tile takes 7.5 s, so the fastest route through your layout must be 2 to
  3 times longer than straight.
- **The cart ramp is also a route on foot.** If the ramp runs straight, it is the fastest way across
  and the zone will be too quick. To hit the time, ramps must wind (switchbacks, a long way
  round), and walls must close off every straight line.

### Repository rules

- You are working in your own copy of the repository (a git worktree). Commit there with clear
  messages. Don't push, and don't open a pull request. Your work is reviewed and merged for you.
- End every commit message with these two lines:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01Rzk2jo5zeuLgwEsf1G5YzW
  ```
- Never write AI model names or model IDs anywhere in the repository.
- **Only edit the files your assignment lists.** If something else seems wrong or missing (the
  engine, a test, the config), don't change it. Say so in your report.
- If something blocks you, stop and report it rather than working around it.

### Read first

- `src/shared/Layouts/init.luau`: the layout format and engine.
- `src/shared/Layouts/Zones/Zone1.luau` … `Zone4.luau` and `Biomes/HermitHollows.luau`: the
  existing layouts, for the style.
- `src/shared/Config.luau`: `Config.Beach.Terrain` (the limits) and `Config.Zones` (the targets).
- `tools/range/README.md`: the Test Range.
- `docs/layouts/README.md`: the layout notes.

### The layout format

A layout is `{ Name = "...", Primitives = { ... }, Loot = { ... }, Entrances = { ... },
Hazards = { ... } }`. Coordinates are X from -360 to 360 and z local to the tile, from 0 at its
landward edge to 150 at its seaward edge. Heights are studs above the beach's even slope.

| Kind | Fields | What it is |
|---|---|---|
| `Ridge` | `Path`, `Height`, `Width`, `Rock?` | a smooth bank (sand, or rock with `Rock = true`) |
| `Mound` | `At`, `Radius`, `Height`, `Rock?` | a hump or boulder |
| `Wall` | `Path`, `Height`, `Width` | rock with a flat top and sheer sides. It can't be climbed or jumped (an invisible barrier inside it rises 9 studs over its top). Use it for maze walls and cave sides |
| `Roof` | `Path` + `Width`, or `At` + `Radius`; `Clearance`, `Thickness` | rock overhead: a tunnel or a cave chamber. Its underside is `Clearance` studs over the slope. Rest it on walls (`Clearance` a little under the walls' `Height`) |
| `Channel` | `Path`, `Depth`, `Width` | a cut that floods when the sea reaches it |
| `Hollow` | `At`, `Radius`, `Depth` | a round dip, a pool |
| `Ramp` | `Path`, `Width` | the cart route: bare slope, cleared through everything |
| `Flat` | `At`, `Radius` | cleared back to bare slope |

Placements, all optional and in tile coordinates:

- `Loot = { { At = {x, z}, Radius = 6, Weight = 1 }, ... }`: where finds settle. A higher
  `Weight` means more finds there.
- `Entrances = { {x, z}, ... }`: where a biome's secret entrance can stand. Keep each one flat
  (a `Flat` of radius 10 or more).
- `Hazards = { { Type = "Patrol", Path = { {x, z}, ... }, Count = 2 }, ... }`: where the biome's
  hazards go. See `src/shared/Hazards.luau` for each kind's fields.

### Hard rules (the tests check them)

1. **Ramps.** At least two Ramps per layout, at least 14 wide. One must cross both tile edges
   (z = 0 and z = 150) at **x = -200**, the other at **x = 180**. They must never climb steeper
   than `CartSlope` (0.35). Between the edges they may wind as much as you like.
2. **Everything reachable.** A cart and a player on foot must get from the top edge to the
   bottom edge. Players can't walk up anything steeper than `FootSlope` (0.9, about 42°).
3. **Foot shortcuts.** At least two of the starts x = -300, -150, 0, 150, 300 on the top edge
   must have a faster way down on foot than by cart (a scramble a cart can't take).
4. **Hidden from the top.** At least 60% of the tile's lower half must be out of sight from its
   top edge at eye height.
5. **Sizes.**
   - Walls: 12 to 24 studs wide and at most 24 tall.
   - Roofs: `Clearance` at least 8, `Thickness` at least 6, and `Clearance + Thickness` at most 32.
   - Other shapes: at most 12 high and 4 deep.
   - Rock ridges: at least 16 wide. Narrower ones get rounded off by the terrain.
   - Nothing narrower than 8 studs. The terrain is built in 4-stud cells.
   - **Put walls on the 4-stud grid**: a wall's centre line at z (and x, for walls running down
     the beach) a multiple of 4, and an even `Width` that's a multiple of 4. Off the grid, a wall
     is drawn a few studs wider or narrower than its layout says.
6. **Rock pools.** Keep shapes 6+ studs clear of the rock pools that lie in your zone (see
   `Config.Beach.Pools`; the tests check the pools against the zone they lie in).
7. **Edges.** Shapes fade to flat over the first and last 6 studs of a tile and the last 30
   studs before the side cliffs. Don't rely on anything there.

### Making it good, not just legal

- **Corridors 12 to 20 studs wide.** That's tight but fair for a player carrying something. A cart
  needs the ramp's width.
- **Dead ends with a reason.** Put loot spots at dead ends and behind walls, so wrong turns can
  still pay off. Give the harder-to-reach spots a higher `Weight`.
- **The water.** Low ground and tunnels below the slope flood as the tide comes in. A ford or
  tunnel that floods early can cut off the quick way back, and that's the tension we want. Say
  in your notes which parts flood first.
- **Readable, not random.** Players should be able to learn a zone: a few big landmarks (a tall
  wall, a cave mouth), and a rhythm of open pockets and tight passages.

### How to check your work

1. `bash tools/check.sh`: formatting, the data checks and all the Lune tests (about 25 s). It must
   pass. Run `stylua src tools` if formatting fails.
2. `lune run tools/layout_map.luau docs/layouts`: prints each layout's measurements, including
   **"fastest crossing on foot … s per tile, about … s for the zone (target … s)"**. It also
   writes the maps into the notes.
3. **The Test Range**, the real engine, once the first two pass:
   ```
   python3 tools/range/run.py --zone N --all <your layout path or biome id>
   ```
   It reports, with positions:
   - things floating, buried or inside rock;
   - the terrain, walls and roofs against your layout;
   - patrol routes that cross walls;
   - Roblox pathfinding across the zone, with the fastest time against the target;
   - loot spots and entrances it can't reach;
   - how much floods at four tide levels.

   Only one Test Range run can go at a time (the runner waits its turn). Each takes under a
   minute.

### Done when

- `bash tools/check.sh` passes.
- The Test Range for your zone reports no problems. (The game's own scenery is put away
  wherever it would straddle a wall or stand under a roof, so props from the rest of the game
  shouldn't be listed any more; if some are, note them, don't fix them.)
- **The Test Range's fastest crossing is within 15% of your target**, or the gap is explained in
  your report.
- **Every loot spot and entrance is reachable on foot.**
- You've written your layout's note in `docs/layouts/`. Copy the style of the existing notes,
  with `<!-- map ... -->` / `<!-- floods ... -->` markers so the tool fills them in. Cover what a
  player meets, where the shortcuts are, what floods first, and the measured times.

### Your report

Keep it short:
- what you built;
- the measured times (the map tool's and the Test Range's) against the target;
- what the Test Range still reports and why;
- anything you couldn't do or think the engine needs.

---

## Part 2: the assignments

### A. Zone 4, Outer Shore (`src/shared/Layouts/Zones/Zone4.luau`, rewrite)

- **Files:** `Zones/Zone4.luau`, `docs/layouts/Zone4.md`.
- **Target:** 55 s for the zone, about 14 s per tile.
- **Feel:** the first zone of real rock. Long rock walls and spines across the beach with a few
  gaps, so you zig-zag between them. Boulder fields. One short tunnel through a spine as a
  landmark. Still mostly open sky. This is where the maze feeling starts, not where it peaks.
- **Note:** zones 5 and 6 use this layout until theirs exist, and Hermit Hollows' ramps meet it
  at the tile edges.

### B. Zone 5, The Shoals (`src/shared/Layouts/Zones/Zone5.luau`, new)

- **Files:** `Zones/Zone5.luau`, `docs/layouts/Zone5.md`.
- **Target:** 65 s for the zone, about 16 s per tile.
- **Feel:** flooded ground between rock bars. Channels and fords that flood in a clear order,
  low walls you have to go round, and a cave chamber or two to shelter in. The tide is the main
  danger here: the quick way is through the fords, and they go under first.

### C. Zone 6, The Drowned Reach (`src/shared/Layouts/Zones/Zone6.luau`, new)

- **Files:** `Zones/Zone6.luau`, `docs/layouts/Zone6.md`.
- **Target:** 85 s for the zone, about 21 s per tile.
- **Feel:** the deepest, slowest ground. A true maze of tall walls and roofed passages, with long
  switchback ramps for carts. Low ground everywhere, so most of it floods early on the way back.
  Dead ends hold the best finds.

### D. Hermit Hollows (`src/shared/Layouts/Biomes/HermitHollows.luau`, rewrite) (done)

- **Files:** `Biomes/HermitHollows.luau`, `docs/layouts/HermitHollows.md`.
- **Where it rolls:** zones 4 to 6 only. **This round: zone 4 only.** Return `{ [4] = layout }`.
  Zones 5 and 6 use the zone 4 version until they get their own, so drop the old drafts for
  zones 1 to 3. Check it with `--zone 4 --all HermitHollows`.
- **Target:** at least the zone's own crossing time. A rare biome may be slower: up to 30% over is
  fine.
- **Feel:** a giant hermit crab's tunnels. A maze of rock-walled, mostly roofed corridors 12 to 16
  wide, with a few open chambers where the roof breaks.
- **Its hazard:** hermit crabs patrolling the corridors (a Patrol hazard). Run into one and it
  knocks you flat.
  - Place their routes with `Hazards = { { Type = "Patrol", Path = ..., Count = ... }, ... }`.
  - The routes must stay in the corridors; the Test Range reports routes that cross walls.
  - Make about 4 to 6 crabs per tile, on routes that cross the main way through, so they have to
    be timed.
- **Entrance:** add one `Entrances` spot per layout, in a chamber, kept flat, for when its secret
  is built.
- **Loot:** spots at the dead ends, with the best (`Weight`) deepest in the maze.

### E. Hermit Hollows in zones 5 and 6 (`src/shared/Layouts/Biomes/HermitHollows.luau`, add to)

- **Files:** `Biomes/HermitHollows.luau`, `docs/layouts/HermitHollows.md`.
- **What:** add `[5]` and `[6]` layouts next to the existing `[4]` (keep `[4]` as it is). Check
  them with `--zone 5 --all HermitHollows` and `--zone 6 --all HermitHollows`.
- **Targets:** at least the zone's own crossing time (zone 5: 65 s, zone 6: 85 s), up to 30% over.
- **Feel:** the same crab tunnels as zone 4, going deeper: zone 5's are lower and wetter (more
  of the corridors below the slope, so they flood early), zone 6's a true labyrinth, nearly all
  roofed, with the best loot in its far dead ends. Each should feel like a step down from the
  one above, not a copy.
- **Hazards, entrance and loot** as in D: about 4 to 6 crabs per tile (a few more in zone 6 is
  fine), one flat entrance spot in a chamber, the best loot deepest in.
- The ramps meet the zone's base layout at the tile edges (x = -200 and x = 180), whatever the
  base layout does in between.
