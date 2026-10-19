# The water lab

See the water at any moment, on any zone, and check it against the water the game plays by.

The game's water rule is simple: the sea is level, at a height that depends on the tide (and a
little on X). Wherever the ground (`Beach.groundAt`) is below that height it's water, as deep as
the difference. Depth decides everything: wading speed, drowning (`WaistDepth`) and lost items
(`LostDepth`). The water you see is drawn by `src/client/SeaController` as meshes around the
shore. The lab runs that same code offline, on the terrain as `TerrainBuilder` really builds it,
and compares the two.

## Looking

```
python3 tools/water/water.py <zone> <layout> <choice> <waterline> [options]
```

- `layout` is `Base` (the zone's own), a biome id (`HermitHollows`, ...), `Lab` (the test
  ground below) or `Flat`.
- `waterline` is the tide's waterline Z at X = 0.
- `--region X0 Z0 X1 Z1` sets the area; the default is 320 studs wide around the waterline.
- `--views top,eye,cut` picks the pictures; `-o prefix` sets where they go (default
  `tools/water/out/`).
- `--eye X Z YAW` says where the eye view stands; `--cut-x X` says where the section is cut.
- `--seconds S` moves the moment on, to catch the waves at a different point.

The pictures:

- **top**: from above. The ground and the water as drawn, coloured as drawn. Lines mark where
  the game's water reaches knee depth (orange), drowning depth (dark red) and lost depth
  (black). Magenta: the game says wet but no water shows. Red: water shows where the game says
  dry. Grey: under a roof.
- **eye**: what a player standing on the shore sees.
- **cut**: a section down the beach. The ground as built (brown), the layout's ground (dotted),
  the game's water level (blue line) and each sheet as drawn (sea cyan, swash, foam, wet sand).

Every run prints its checks: wet cells, disagreements both ways, and how high the drawn water
gets above sea level.

## The test ground

`src/shared/Layouts/Lab.luau` has every kind of ground the water must cope with, in lanes down a
whole zone, so the waterline meets each of them at any tide:

- the bare slope;
- a wall down the beach with breakwaters across it, and lagoons behind them;
- banks with pools behind;
- a deep then shallow channel;
- a roofed tunnel;
- pits from narrow to wide;
- rock domes;
- two walls with a 6-stud gap;
- a bank running under the cliffs.

In the review place, `waterlab <zone>` (admin) puts it in a zone and `waterlab off` takes it
out. `tide at <z>` brings the waterline to that Z, and `tidespeed 10` slows the tide right down
so you can look.

## The checks

`python3 tools/water/water.py check` runs the lab and every zone at several tides, including
high tide at the shop and low tide at the channel to the Far Sandbar. `tools/check.sh` runs it
too. Each case must keep:

- the drawn water no more than 0.7 above sea level (it never climbs walls or banks);
- under 1% of the wet cells showing no water;
- under 3% of them showing water where the game says dry.

Cells right at a steep edge, under roofs and past the beach's sides aren't judged. The terrain
is drawn a little inside a layout's steep edges by design, so the edges always disagree by a
cell.

## How the water is drawn (`SeaController`)

- **The sea:** a sheet over a band from the shore up the beach (as far as the deepest cut can
  flood) and out to sea (past lost depth), then flat to the horizon.
  - Where the game's ground is wet, the sheet lies level at sea height. It lifts at most 0.6
    over terrain that bulges above the water.
  - Where the ground is dry, the sheet sinks just under sea height, inside the ground.
  - So the terrain cuts the shoreline out of a level sheet everywhere: along banks, walls, pits
    and channels, under roofs too.
- **Its colour is the game's depth:**
  - pale where you can wade and see the sand;
  - darker through knee and waist depth;
  - a clear step to deep blue where you drown;
  - darker still where loose things are lost.

  Points on dry ground take the depth of the water nearest them in their column, so a wall
  standing in deep water doesn't get a pale halo.
- **The run-up, its foam and the crests** follow the waves (`Waves`) and stop at anything
  solid (`WaterObstacles`, the layouts' ridges and walls).
- **Wet sand** is a dark see-through tint, up to 24 studs above the shore, so wet ground looks
  darker than dry in every zone's colours.
- **The fallback:** where editable meshes aren't allowed (the experience's Security setting
  "Allow Mesh / Image APIs" is off), the same water is drawn with parts. It's pale out to
  drowning depth on the open slope and deep blue beyond. It can't follow each bank and pit.
