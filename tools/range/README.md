# The Test Range

Checks a zone of the beach inside the **real Roblox engine**, without Studio. It builds the
game with Rojo, publishes it to the Test Range place (its own private experience, so the live
game is never touched), and runs `check.luau` there through Open Cloud's Luau Execution API.
The engine builds the real terrain, props and biomes, so this catches what the Lune tests in
`tools/tests` can't.

```
python3 tools/range/run.py --zone 4 --all HermitHollows
python3 tools/range/run.py --zone 5 --tile 17=Biomes/Planned/TidepoolRocks --tide 2500
python3 tools/range/run.py --zone 2 --no-routes
```

- `--zone N`: the zone to check (1 to 6).
- `--all SPEC`: every tile of the zone. SPEC is `Base`, a biome id (`HermitHollows`), or a
  layout path under `src/shared/Layouts` (`Zones/Zone5`, `Biomes/Planned/CoralGarden`), so a
  layout can be checked before it's a biome.
- `--tile T=SPEC`: one tile. Tiles are numbered from the shop, four to a zone (zone 4 is tiles
  13 to 16).
- `--tide Z`: a waterline Z to measure the water at (repeatable). By default: the zone's top,
  middle and bottom, and low tide.
- `--no-routes`: skip pathfinding (quicker). `--no-publish`: reuse the last published build.

A check takes about 15 to 60 seconds. The report is printed and saved to `tools/range/out/zone<N>.json`;
the exit code is 1 when it found problems.

## What it checks

Problems (each with examples and positions):

- **floating / buried**: props, biome decor, creatures and hazards whose bottom is more than a
  stud over the real terrain with nothing under them, or whose top is under it.
- **inside rock**: anything inside a wall or roof.
- **terrain off its layout**: on gentle ground, the real terrain more than 2.5 studs from the
  height the game uses for water, items and props (Beach.groundAt). Narrow rock ridges (under
  about 16 wide) get rounded off and show up here.
- **wall width off / wall missing**: walls drawn more than 3 studs off their layout's Width.
- **roof off its layout / roof missing**: roof undersides more than 2.5 studs off, away from
  their edges.
- **patrol route blocked**: a layout's patrol route crossing raised ground.
- **no way across**: Roblox's pathfinding finds no way from the zone's top edge to its bottom.
- **path too steep**: the pathfinder's route climbs steeper than players can (FootSlope);
  Roblox's pathfinding doesn't know the game's climb limit, so treat that route as suspect.
- **unreachable spot**: a layout's loot spot or entrance that pathfinding can't reach on foot.

Measurements:

- `crossing`: the fastest way across the zone on foot (seconds at walking speed, from seven
  starts along the top edge), against the zone's `CrossTime` target.
- `tides`: at each waterline, how much of the zone is under water, how much too deep to stand
  in, and how much of its tunnels (under roofs) are flooded.
- `terrainOffset`, `roofOffset`, `wallWidths`: how closely the real terrain matches the layouts.

## How the terrain is matched to the layouts

Roblox draws smooth terrain's solid regions 2 studs (half a 4-stud cell) bigger in every
direction than its cells' fill. `TerrainBuilder` writes everything shrunk by that much, and tiles
are 152 studs long (a multiple of 4) so every tile lines up with the cells. The Test Range is
how that was measured, and how to check it stays true.

## Setup

`range.json` holds the Test Range experience and place ids. It needs network access to
`apis.roblox.com` with an Open Cloud key that has, for that experience, **Luau execution
sessions: write** and **universe places: write**.
