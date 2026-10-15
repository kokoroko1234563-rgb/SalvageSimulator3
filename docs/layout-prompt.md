# Prompt: hand-build the descent layouts

> **For the user:** this is the prompt for the cheaper model. Read it and tell me what to
> change. It assumes that **I build the layout format and the terrain plumbing first**
> (section 3), so the other model only writes layout data, tests and notes. It never touches
> the wave, tide or terrain code that every client depends on. Send it once that plumbing is
> pushed (I'll tell you when).

---

You are working on **Salvage Simulator 3**, a Roblox game written in Luau and built with
Rojo. Your job is to **hand-design the shape of the ground** for the walk down the beach to
the sea. You do this as layout data: one layout per zone, plus a layout for each biome. The
engine that turns layouts into terrain already exists. You write the layouts, the tests that
prove they're playable, and a short design note for each.

## 1. Repository and git rules

- Repo: `kokoroko1234563-rgb/SalvageSimulator3`. Work on the branch
  `claude/exciting-ride-aqbwyx`: fetch it, check it out, and pull before you start. Don't
  start from any other branch, and don't create a new one.
- Commit in small steps with clear messages, and push with
  `git push -u origin claude/exciting-ride-aqbwyx`.
- Never write AI model names or model IDs anywhere in the repo, including comments, docs and
  commit messages.
- Before every push, `bash tools/check.sh` must pass. It runs StyLua, the API check, the Lune
  tests and the Rojo build. Run `stylua src tools` if formatting fails. Don't disable or skip
  any test.
- Don't open a pull request.
- Only edit the files listed in section 6. If something outside them looks wrong or missing,
  write it down in your final report instead of changing it.

## 2. The game, and what the layouts are for

Players walk down a beach toward the sea to salvage washed-up items, then carry them back up
to sell. The tide goes out and comes in on a cycle. Waves push players around, knock them
down and drag items away.

The beach is split into zones running down to the sea. +Z points seaward, and the ground
drops 0.06 studs per stud of Z. Each zone is 150 studs deep and the beach is 720 studs wide
(X from -360 to 360), with cliffs along both sides.

| Zone | Z range | Name | Character |
|---|---|---|---|
| 0 | before 0 | Shop / dry sand | flat. **Don't touch.** |
| 1 | 0 – 150 | Open Shore | gentle, readable, almost flat. The tutorial. |
| 2 | 150 – 300 | Dunes | low dunes and hollows. Sightlines start to break. |
| 3 | 300 – 450 | Banks | sandbanks and channels that flood as the tide turns. A maze of fords. |
| 4 | 450 – 600 | Outer Shore / Reef | rock spines, boulder fields, narrow corridors and sea caves. Floods from the sea side first. |
| — | 600 – 640 | Channel | deep water before the Far Sandbar. **Don't touch.** |
| — | 640 – 760 | Far Sandbar | **don't touch.** |

**The feel we want.** The descent should feel **claustrophobic and exploration-driven**, not
like an open slope you can read at a glance:

1. **Items must not be visible from the top.** From the top edge of a zone (standing eye
   height is about 5 studs above the ground), ridges and banks should hide most of the
   zone's floor. You find things by going in.
2. **Danger grows the lower you go.** The waves get bigger lower down (Config.Waves.ZoneScale:
   1, 1.15, 1.35, 1.65), and the mist gets thicker. Low ground below the sea level floods
   first, and water in a channel catches you.
3. **The basic threat is that the way back is slow.** Winding routes, dead ends, and fords
   that flood behind you. A player who goes deep must think about the tide.
4. **Biomes add their own dangers on top**, for example a Hermit Crab maze of tight
   corridors. The engine handles the hazards themselves (crabs, barrels and so on). Your
   layout gives them the space they need.
5. **The terrain blocks vessels.** Carts and other vessels can't climb steep ground, so
   every zone needs **guaranteed ramps** for them. Players on foot get **shortcuts**:
   steeper climbs that carts can't use.

## 3. The layout format (already implemented; read the code)

Read these files before you write anything:

- `src/shared/Beach.luau`: `groundY(z)` (the base slope), `feature(x, z)` (the shape on top
  of the slope, which now comes from the layouts), `groundAt(x, z)`, `zoneAt(z)` and
  `zoneRange(i)`.
- `src/shared/Layouts/init.luau`: the layout engine. It evaluates the primitives below.
- `src/shared/Layouts/Zones/Zone1.luau` … `Zone4.luau`: the base layout of each zone, used
  when the zone has no biome.
- `src/shared/Layouts/Biomes/<BiomeId>.luau`: a biome's layout. Each rolls in place of the
  zone's base layout.
- `src/server/TerrainBuilder.luau`: rebuilds a zone's terrain when its biome changes.
- `src/shared/Biomes.luau`: `Biomes.List` (the biomes that roll now) and `Biomes.Planned`
  (biomes designed but not yet built).
- `src/shared/Config.luau`: `Config.Beach` (including `Terrain`), `Config.Waves` and
  `Config.Tide`.
- `README.md`: the sections on the beach's shape and on things the water reacts to.

**Coordinates.** X runs from -360 to 360. `z` is **local to the zone**, from 0 (its
landward edge) to 150 (its seaward edge). Heights are in studs **above or below the base
slope**, not absolute heights.

**Primitives.** A layout is a table of primitives:

```lua
return {
	Name = "Dunes (base)",
	Primitives = {
		-- A raised bank along a path. Its cross-section is smooth, and its top is `Height`
		-- above the slope. Width is the full width at the base.
		{ Kind = "Ridge", Path = { { -300, 40 }, { -120, 55 }, { 40, 48 } }, Height = 6, Width = 16 },
		-- Rock instead of sand, and it takes a steeper face.
		{ Kind = "Ridge", Path = { ... }, Height = 9, Width = 12, Rock = true },
		-- A round hump or boulder.
		{ Kind = "Mound", At = { 120, 90 }, Radius = 10, Height = 5, Rock = true },
		-- A cut below the slope. If it dips below sea level, it floods.
		{ Kind = "Channel", Path = { ... }, Depth = 2.5, Width = 10 },
		-- A round dip that holds water: a pool or puddle.
		{ Kind = "Hollow", At = { -60, 110 }, Radius = 9, Depth = 1.5 },
		-- A guaranteed cart route. Along its path, the ground is evened out so the climb
		-- never exceeds Config.Beach.Terrain.CartSlope, and it overrides everything else
		-- within Width.
		{ Kind = "Ramp", Path = { { -200, 0 }, { -180, 75 }, { -210, 150 } }, Width = 16 },
		-- Clears the shape back to the bare slope (for entrance spots, the pier and so on).
		{ Kind = "Flat", At = { 40, 75 }, Radius = 12 },
	},
}
```

**How the engine combines them:**

- Raised shapes take the **max** of the overlapping heights. Cuts take the **min**.
- `Ramp` and `Flat` are applied last and blend smoothly into the ground around them.
- The engine fades every shape to zero over the first and last 6 studs of the zone, and
  near the side cliffs, so zones join with no seam.
- Terrain voxels are 4 studs, so nothing narrower than **8 studs** will show up.

**Tunables** (in `Config.Beach.Terrain`; read their values, don't change them):

- `CartSlope`: the steepest climb a vessel can take.
- `FootSlope`: the steepest a player can walk up.
- `MaxHeight` / `MaxDepth`: the limits on shape height.
- `EyeHeight`: the standing eye height used by the sightline test.

## 4. Design rules for every layout

1. **Ramps.** At least **two Ramps per zone**, one in the left half (x < 0) and one in the
   right half (x > 0). Each runs **from z = 0 to z = 150** and is at least 14 studs wide.
   - Each ramp should **meet a ramp of the zone above and the zone below at the boundary**.
     The neighbouring zone's ramp should end within 20 studs of X at z = 150 (or begin
     there at z = 0). That way a cart can always get from the shop to zone 4's seaward edge,
     whatever biomes rolled.
   - To make that work, **every layout (base and biome) must have ramps that cross z = 0 and
     z = 150 at the same anchor X positions:** x = -200 and x = 180. Between the edges, a
     ramp may wander freely.
2. **Foot shortcuts.** Give each zone at least two places where a player on foot can cut
   through faster than the ramps, up a slope steeper than `CartSlope` but no steeper than
   `FootSlope`. They should feel like a risk-for-time trade: a narrow gap between two rock
   spines, or a ford across a channel that floods.
3. **Sightlines.** From the top edge of each zone at eye height, at least **60%** of the
   ground in the zone's lower half should be hidden by ridges. Zone 1 is the exception:
   aim for 0–20%, since it's the readable tutorial zone.
4. **Flooding.** In zones 3 and 4, the Channels and Hollows should flood in stages as the
   tide comes in. Set their depths so that **some fords cut off before others**. Read
   `Tide.luau` for the range of the waterline. Describe the order in your design note.
5. **Entrances.** Each biome in `Biomes.List` has `EntranceSpots` (X positions where its
   secret entrance can stand, at the middle of the zone, z = 75). Put a `Flat` with a radius
   of at least 10 at every one of these, and make sure each spot can be reached on foot.
6. **Items.** Items wash in from the sea and settle in low ground. Hollows and the backs of
   ridges are where finds collect. Spread them out so the player has to explore.
7. **Don't touch:**
   - the rock pools at `Config.Beach.Pools`: the engine already flattens around them, but
     don't put ridges through them;
   - the pier corridor: read where `ZoneProps.luau` builds the pier, and keep a `Flat` path
     under it;
   - the side cliffs.
8. **Scale with depth.** Each zone gets more rugged than the one above:
   - Zone 1: up to about 2.5 studs high, no rock.
   - Zone 2: up to about 5 studs, sand only.
   - Zone 3: up to about 7 studs, with channels 2–3 studs deep.
   - Zone 4: up to about 10 studs of rock, plus corridors, boulder fields (Mounds) and
     cave-like slots (two tall rock Ridges close together).
9. **No floating labels or signs** anywhere. You're writing ground shape only, so you
   shouldn't need any.

## 5. What to build

1. **Base layouts** for zones 1–4 (`Layouts/Zones/Zone1.luau` … `Zone4.luau`), following
   the character table in section 2.
2. **Biome layouts** for each biome in `Biomes.List`:
   - **Sandcastle Flats:** wide, open, almost-flat sand with a few castle mounds. It is the
     relief zone, easy to cross, but still keep one or two ridges that block sightlines.
   - **Shipwreck Shallows:** a scour channel cut around where the wreck lies, with debris
     mounds and a long gully the barrels roll down (the barrel hazard rolls toward +Z; read
     `BiomeService.luau`).

   A biome layout replaces the base layout in **whichever zone it rolls in (1–4)**, so it
   must work in all of them. If it needs to differ by zone, return a table indexed by zone:
   `{ [1] = layout, [2] = layout, ... }`. The engine accepts both.
3. **Draft layouts** for the biomes in `Biomes.Planned`, in
   `Layouts/Biomes/Planned/<Id>.luau`. They are not used yet. Do these **last**, and only
   if everything above is finished and passing. Ideas for each:
   - Driftwood Cove: log-jam ridges.
   - Tidepool Rocks: rock benches with many Hollows.
   - Seagrass Shallows: low, flood-prone flats.
   - Coral Garden: reef spines with arches.
   - Jellyfish Lagoon: one big lagoon Hollow ringed by a bank, with narrow causeways.
   - **Hermit Hollows**: a tight maze of rock-walled corridors about 10–14 studs wide, with
     several dead ends, one way through, and a cart ramp around the outside.
4. **Tests** in `tools/tests/run.luau` (follow the style already there). They must use the
   engine's own functions (`Beach.groundAt` with each layout active, through
   `Layouts.setActive` or whatever the engine exposes; read it):
   - Every layout loads and has only known primitive kinds and fields.
   - **Cart test:** for every layout, walk each Ramp's path in 2-stud steps. The slope
     between steps must never exceed `CartSlope`, and the anchors must sit at x = -200 and
     x = 180 at z = 0 and z = 150. Then check that from the shop (z = -5) a cart can get to
     z = 595 under every combination of base and biome layouts across zones 1–4. To do
     that, run a flood-fill on a 4-stud grid where a step between neighbours is allowed
     only if its slope is at most `CartSlope`.
   - **Foot test:** the same flood-fill with `FootSlope`, from z = -5 to z = 595, and to
     every EntranceSpot.
   - **Sightline test** (rule 3): cast from 9 points along z = 0 of each zone, at eye
     height, to a grid over the zone's lower half.
   - Heights stay within `MaxHeight` / `MaxDepth`, and nothing changes outside zones 1–4.
5. **A design note per layout** in `docs/layouts/<Name>.md`. Each note has:
   - A top-down ASCII map, 72 columns (10 studs each) by 15 rows (10 studs each), using
     `#` for rock, `^` for a ridge or bank, `.` for flat ground, `~` for ground that floods
     (dips below sea level at mid-tide), `=` for a ramp and `o` for an entrance flat.
   - Where the shortcuts are.
   - The order in which the fords flood.
   - What a player sees from the top.

   Generate the ASCII maps from the real `groundAt` data with a small Lune script in
   `tools/` so they can't drift from the layout. Don't draw them by hand.

## 6. Files you may create or edit

- `src/shared/Layouts/Zones/*.luau`
- `src/shared/Layouts/Biomes/*.luau`
- `src/shared/Layouts/Biomes/Planned/*.luau`
- `tools/tests/run.luau` (append your tests)
- `tools/layout_map.luau` (the ASCII map script)
- `docs/layouts/*.md`

**Don't edit** the layout engine, Beach, TerrainBuilder, Config, the wave, tide or sea code,
or anything else. If the engine is missing something you need, stop and say what it is in
your report.

## 7. When you're done

Push, then report:

- each layout in one paragraph;
- the test results (`bash tools/check.sh` output, summarized);
- anything you couldn't satisfy, and why;
- anything you think the engine needs.
