# Fog Bank (planned biome, zones 2 to 6)

Plan: `tools/kit/plans/fog_bank.py` (writes `src/shared/Layouts/Biomes/Planned/FogBank.luau`).
Card: `docs/design/cards/fog-bank.md`. The foghorn (`Fog` hazard, `At`) stands at the
lighthouse in every zone; a lantern does nothing against fog, so no lights are used.
Pictures: `fog-bank-z2.png`, `fog-bank-z4.png`, `fog-bank-z6.png`.

## Zones 2 and 3: open dunes
Three low sand dunes across the zone (z 190, 350, 510; zone 2 height 4.4, zone 3 6.4: within the
caps). Carts can't climb them, feet can: the shortcuts. Each crossing is one cart ramp (16 wide)
winding through a gap in each dune, with marker posts (Timber) and a rope line (Chain) along it.
Lighthouse (decor) at (290, 440) with its door, the entrance, at (290, 458), flat and on foot.
Loot in the dune pockets, best deepest (weights 1 to 5).

| Crossing | Foot (s) | Huge cart (s) |
|---|---|---|
| North posts | 30 | zone 2: 37, zone 3: 37 |
| Bell line | 30 | 38 |
| South rope | 30 | 41 to 42 |

Foot 30 s is 85% of zone 2's 36 s target and 80% of zone 3's 38 s.

## Zones 4 to 6: low rock walls, snaking lanes
Walls 12 (zone 4), 12 (zone 5), 14 (zone 6) high. Three bands (west, middle, east), each a snake
of 100-long runs down the zone; a crossing carves 2 or 3 bands (one the cart's ramp, 16 wide; the
rest foot lanes, 12) with a link lane between two. Dead ends off the corners (24 to 60 long)
hold loot; some end in a covered pit under the prize, and foot lanes carry covered pits. Rope
lines and posts along every way. The foot of the zone is a court: the lighthouse is a 20x20 tower
of rock 24 high, the entrance at its door (-120, 555), the foghorn at it.

| Zone | Crossing | Paths (s, of target) | Huge cart (s) |
|---|---|---|---|
| 4 (55 s) | Rope road / Bell walk | 56, 57, 57 (102 to 104%) | 62 |
| 4 | Post line | 56, 57 | 62 |
| 5 (65 s) | all three | 64, 65, 65 (98 to 100%) | 70 |
| 6 (85 s) | all three | 71, 73, 73 (84 to 86%) | 79 |

Zone 4's first row is at z 108 to keep the ramp clear of the rock pool at (260, 70).

## Checks
- Quick check: no problems, every zone and crossing.
- `bash tools/check.sh`: All checks passed.
- Test Range (crossing 1, `--no-routes`): zones 2, 3, 4 no problems from this layout (terrain
  worst -1.9, -1.9, -2.3); the remaining buried/floating items are the zones' own cosmetics,
  textures and ZoneProps. Zone 5 once reports one "terrain off its layout" sample at -2.7 (limit
  2.5), a point 10 studs off a lane edge; zone 6 passed at -2.4 (rock 14).
