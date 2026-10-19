# Designing a zone

How the beach's zones and biomes are designed and built. This is the one current statement of
the rules; `docs/design/cards/` has a card for each zone and biome saying what it should be.
(The old rounds of the layout brief are in `docs/archive/layout-brief.md`, for history only.)

## The game, and what a zone is for

- The beach runs out to sea along +Z: **720 studs wide** (X from -360 to 360) and six zones of
  **608 studs** each, then the Far Sandbar. Each zone is drawn as **one piece**, and a biome
  that rolls takes the whole zone with its own layout.
- The tide takes about 10 minutes to go out and 10 to come back. Players follow it down,
  explore at low tide, then race it back up with what they've found.
- **The walk down takes a regular about 7 minutes** (walking at 20 studs/s, picking up a few
  finds, heading for the Far Sandbar). Most of it is spent in zones 4 to 6, which should feel
  claustrophobic and maze-like: walls you can't see over, tunnels, dead ends, heavy fog, and
  the water coming back in behind you.
- **Hard for a first-timer, quick for someone who knows it.** Every zone is learnable: its
  landmarks and dangers are where they were last time (for that crossing), and each crossing
  has a tell where it starts, so a regular knows which way it is before committing.
- **Dangers are deadly.** A danger that only slows you is scenery. Each one has a tell that a
  player can learn to read, and a regular gets through by timing and route, not luck.

## How a zone is put together

Every tide, each zone rolls **one of its crossings** and **one room for each of its slots**,
so a zone keeps its identity while the way through and the side pockets change.

- **The frame** is always there: the zone's identity, its landmarks, the outer structure.
- **A crossing** decides the ways through. Shapes add up, except Ramps and Flats, which clear
  everything (walls included), so a crossing can open frame walls as well as add its own.
  Five crossings, each feeling different: other sides, other landmarks on the way, another
  order of tunnels and chambers.
- **A slot** is a side pocket off the ways through, with one door onto the frame. Each of its
  rooms keeps that door open and is reachable whichever crossing rolled. Rooms in a slot differ
  in kind (a dead-end cave, a flooded pocket, a boulder scramble, a tunnel loop). **Most loot is
  in rooms**, the best deepest in.
- **Coordinates:** frame and crossings in zone coordinates (X -360 to 360, z 0 at the zone's top
  toward the shop to 608 at its bottom toward the sea); rooms in their slot's own coordinates.
  Heights are studs above the beach's even slope.

## Paths through a zone

- **1, 2 or 3 paths through each crossing**, said on the crossing: `Paths = 2`. Vary it: one
  path is a tense corridor, three a web.
- **Distinct but allowed to cross.** Paths may cross and link up (one or two links per zone:
  that's what makes getting lost recoverable). Each needs its own way: at most 40% of it runs
  along another in the same open ground.
- **Every path takes 75% to 140% of the zone's target time** on foot. No path, however it's
  found, may be quicker: that's what stops a straight run.
- **Each path has a character**: short but through the dangers; long and safe; dark (the
  Gloom's); foot-only through squeezes and fords.

| Zone | Name | Target (fastest way across on foot) |
|---|---|---|
| 1 | Shopside Shore | 35 s |
| 2 | Sunny Stretch | 40 s |
| 3 | Middle Banks | 45 s |
| 4 | Outer Shore | 55 s |
| 5 | The Shoals | 65 s |
| 6 | The Drowned Reach | 85 s |

(Walking straight down a zone takes about 30 s.)

## Carts

Carts meet the map as one of four standard boxes, whatever their model (`Config.Carts`):

| Size | Box (wide × long) | Needs a path at least |
|---|---|---|
| Small | 4 × 6 | 8 wide |
| Medium | 6 × 9 | 10 wide |
| Large | 7 × 12 | 12 wide |
| Huge | 8 × 15 | 14 wide |

- Narrower than 8 is foot-only. Carts climb no steeper than `CartSlope` (0.35); feet manage
  `FootSlope` (0.9, about 42°). Fords, steps and scrambles are foot-only.
- **Every crossing has at least one path a Huge cart can take** within the time window: the
  cart route, a `Ramp` (14+ wide) from the top edge to the bottom edge. Other paths may be
  narrower, giving smaller carts and feet their shortcuts.

## The shapes

| Kind | Fields | What it is |
|---|---|---|
| `Wall` | `Path` + `Width`, or `Area`; `Height` | rock with a flat top and sheer sides; can't be climbed |
| `Ridge` | `Path` + `Width`, `Height`, `Rock?` | a smooth bank (sand, or rock) |
| `Mound` | `At`, `Radius`, `Height`, `Rock?` | a hump or boulder |
| `Roof` | `Path` + `Width`, `At` + `Radius`, or `Area`; `Clearance`, `Thickness` | rock overhead: a tunnel or cave |
| `Channel` | `Path`, `Depth`, `Width` | a cut that floods when the sea reaches it |
| `Hollow` | `At`, `Radius`, `Depth` | a round dip, a pool |
| `Ramp` | `Path`, `Width` | the cart route: bare slope, cleared through everything |
| `Flat` | `At` + `Radius`, or `Area` | cleared back to bare slope, through everything |
| `Paint` | a shape, `Material` | the ground's material only |

- `Area = { {x, z}, ... }` takes a polygon instead of a Path or At (Wall, Ridge, Roof, Hollow,
  Flat, Paint). `Rough = n` wobbles an edge by up to n studs; `Material = "Basalt"` (any of
  `Config.Looks.Materials`) sets a shape's own material.
- Placements: `Loot = { { At, Radius, Weight } }` (the best finds have the highest Weight),
  `Entrances = { {x, z} }` (a biome's secret door, kept flat), `Hazards` (below), `Decor`
  (below).

## Limits the engine sets (learned the hard way)

- **Terrain is 4-stud cells.** Anything narrower than about 8 studs rounds away; thin crests
  come out lower than drawn. Walls are 12 to 24 wide and up to 24 tall.
- **Walls' faces on the 4-stud grid**: both faces at 4k+2 (centre ± Width/2). A Width of 12 or
  20 needs its centre on a multiple of 4; 16 or 24 on 4k+2.
- **Walls' `Rough` at most 1** (the Test Range's wall-width tolerance is 3); rubble, pools and
  boulders can take 3. Run a wall 4 studs into a post or the wall it meets, or worn ends leave
  a crack.
- **Roofs sit on walls**: `Clearance` at least 8 and a little under the walls' `Height`,
  `Thickness` at least 6, the two together at most 32. Roof a cell only where at least two of
  its sides are walls: nothing floating over a junction. At most about 40% of a zone roofed.
- **Edges**: shapes fade to flat over the zone's first and last 6 studs (zones meet along that
  strip) and run on to the side cliffs; keep 6+ studs clear of the rock pools.
- **Cuts at most 4 deep** (spike pits up to 12, by the hazard).

## Dangers (Hazards.luau)

Each placed in the layout's `Hazards` list; a zone's own kit is `Config.Zones[i].Hazards`, a
biome's its `Hazards`.

| Danger | Placement | Put it |
|---|---|---|
| **Rockfall**: an area strewn with rubble; rocks fall at random in it, mostly aimed at whoever is inside, each warned by dust and a growing shadow | `At`, `Radius` (≈12) | on a stretch a path must cross: a timing test |
| **Sink**: an irregular patch of wet sand; slows hard, no jumping, visibly swallows; stopping kills | `At`, `Radius` (≈12) | across a lane, so going round costs real time |
| **Gloom**: something unseen walking its path, casting a shadow; touch it and you're Benighted (dark, only lights show) for half a minute | `Path` or `At`, `Radius` (≈9) | along galleries, with lantern posts and glowing weed (wards) |
| **Pit**: a spike pit, open or under a false floor whose cracks are the only tell | `At`, `Radius`, `Depth` (≤12), `Covered` | off the cart route and clear of doors; covered under a prize |
| **Undertow**: a current dragging seaward while the sea covers a ford or channel | `Path`, `Width` | along the channels |
| **Patrol**: creatures walking a route | `Path`, `Count` | in corridors, crossing the ways through |
| **Hunter**: the giant crab; sees in a cone ahead, keeps to its route, chases and kills | `Path` | down a tunnel: it fills it, so it can't be run round |
| **Roller**: things rolling down the zone on a timer | `Lanes` | down the gullies |

## Decor and tells

- Decor kinds (`Decor.luau`): Kelp, Weed, Timber, WreckRibs, Anchor, Chain, Bones, DeadCoral,
  Barnacles, Urchins, Starfish, Pebbles, Crate, Shells, Rocks, DuneGrass, Driftwood, and the
  lights (GlowShells, GlowWeed, LanternPost) that also ward off the Gloom.
- **A landmark at each crossing's way in** (a wreck, a lantern post, an arch of bones), so a
  regular knows which crossing rolled; **a tell at each room's door**.
- Enough to make every stretch look like somewhere; not clutter.

## Checking your work

| Check | Command | What it tells you |
|---|---|---|
| Quick look (seconds) | see "Building" below | the render, paths, times, cart sizes, problems for one crossing |
| Everything (a minute) | `bash tools/check.sh` | formatting, data, all tests (paths for layouts that say `Paths`), the water |
| Map tool | `lune run tools/layout_map.luau - Zones/Zone5` | every crossing and room: hidden share, times, paths, carts |
| Test Range (the engine) | `python3 tools/range/run.py --zone 5 --choice 2:` | floating or buried things, terrain against the layout, the real walk; `--every` once at the end |
| Review notes | `python3 tools/review/review.py notes --zone 5` | what was noted playing it; address each |

**Done when**: `check.sh` passes, the Test Range `--every` is clean, the card is met, and the
zone's note in `docs/layouts/` says what was built and the measured times.

## Building

Draw a zone with the layout kit (`tools/kit/kit.py`) rather than by hand: a short Python plan
says what's carved where, and the kit writes the layout file. A walled zone starts as solid
rock (`rock=14`: its height) and you carve what can be walked; walls are whatever you didn't
carve, so they always meet, lane edges land on the terrain's grid, and roofs rest on the rock
either side. An open zone (`rock=0`, the shore) places features on open sand instead.

(`tools/kit/plans/example.py`; it writes over zone 5, so only to try the kit.)

```python
from kit import Zone

z = Zone(5, "The Shoals", rock=14)
f = z.frame                                    # always there
f.hall([(-80, 260), (80, 260), (80, 340), (-80, 340)], roof=True, pillars=[(-24, 300), (24, 300)])
f.lane([(-132, 240), (-132, 300)], width=12)  # up to the slot's door
f.loot((0, 300), weight=4)
f.decor("LanternPost", at=(0, 270))

c = z.crossing("Zigzag fords", paths=2)         # one rolled each tide
c.ramp([(-280, 0), (-280, 120), (144, 120), (144, 470), (-200, 470), (-200, 608)])
c.lane([(-280, 120), (-280, 300), (-80, 300)], width=12)
c.lane([(80, 300), (260, 300), (260, 608)], width=12)
c.hazard("Sink", at=(144, 400), radius=12)

s = z.slot("Weed cove", at=(-180, 176), size=(96, 64), door=(48, 64))
r = s.room("Drowned pool")                     # in the slot's own coordinates
r.hall([(8, 8), (88, 8), (88, 48), (8, 48)])
r.hollow((48, 28), radius=12, depth=3)
r.loot((48, 28), weight=3)

z.write("src/shared/Layouts/Zones/Zone5.luau")
```

| Call | What it makes |
|---|---|
| `lane(points, width=16, roof=False, floor=None)` | a corridor along the points (width snapped to 12, 20, 28...; 12 is foot and small carts) |
| `hall(area, roof=False, pillars=[...])`, `court(...)` | an open area; pillars are rock left standing (8 across) |
| `door(at, width, depth, along="z")` | a short gap through rock |
| `ramp(points, width=16)` | the cart route, cleared through everything (14+) |
| `wall`, `wall_area`, `ridge`, `mound`, `hollow`, `channel`, `paint` | the shapes in "The shapes" |
| `add(Kind=..., ...)` | any shape as the engine takes it |
| `loot(at, radius, weight)`, `entrance(at)`, `hazard(Type, ...)`, `decor(Kind, ...)` | placements; fields as in the tables above (`at=`, `radius=`, `path=`) |

- A slot's `door` (in its own coordinates, on its edge) is cut through the rock for you, and each
  room gets a lane from the door to its middle. **Lead a lane of the frame up to the door**: the
  quick check says if a find can't be walked to.
- Keep each zone's plan beside its layout, as `tools/kit/plans/zone5.py` (or the biome's name),
  so the next person changes the plan and re-runs it, not the Luau.

**The quick check** runs the plan and checks what it wrote, in a few seconds:

```
python3 tools/kit/quick.py 5 --plan tools/kit/plans/zone5.py      # every crossing
python3 tools/kit/quick.py 5 Zones/Zone5 2: 3:                    # just crossings 2 and 3
python3 tools/kit/quick.py 5 Biomes/HermitHollows 1:2,1            # a biome; rooms too
```

It prints every problem (the definition's, each way's, paths that are too quick or too slow or
too few, finds and entrances nobody can walk to), each path's time and which carts fit it, and
draws each choice to `tools/kit/out/` (look at the pictures). Iterate with it; then the map tool
and the Test Range as in "Checking your work".

## Working rules for agents

- Work in your own worktree; commit after each working step with the trailer lines you're
  given; never write model names or IDs in the repository; edit only your assignment's files.
- Run the Test Range in the foreground; `--choice` while iterating, `--every` once at the end.
  No background timers, monitors or sleep loops. Keep outputs short (`tail`, `grep`, summary
  modes). Before stopping, check nothing of yours is left running.
- If something blocks you, stop and report it rather than working around it.
