# Coral Garden (biome, zones 1 to 4)

Drawn with the kit from `tools/kit/plans/coral_garden.py` (edit the plan and re-run it), written
to `src/shared/Layouts/Biomes/Planned/CoralGarden.luau`. Card: `docs/design/cards/coral-garden.md`.
Gentle choices taken: sharp coral beds are `Slow` patches (radius 8 to 9, coral and urchins
marking them), nothing that knocks you back.

## What was built

- **Zones 1 to 3 (open sand, no walls or rock).** Three pairs of reef spines across the zone with
  a cove between each pair (pale shell-grit coral, coral decor along them), finds in the coves'
  ends (best in the last pair), and the entrance (a flat spot) in an arch at the east end of the
  middle cove, coral standing either side. Zones 2 and 3: spines are Ridges (heights 4.4 / 6.4,
  widths 14 / 18; carts cannot climb them, feet can: the shortcuts), moved to z 190, 350, 510 to
  keep clear of the rock pools. Zone 1: ridges hide too much of the zone from the top (sightline
  test), so its spines are narrow steep clefts in the sand lined with coral, which carts cannot
  cross.
- **Crossings (3 in each of zones 1 to 3, one path each):** North, Middle and South arches. The
  cart's Ramp (16 wide) opens an arch through each pair, at different places in each crossing, with
  coral beds beside it and its own tell at the way in (coral spires, shells and an urchin,
  driftwood and a crate).
- **Zone 4 (rock spines 12 high, 24+ thick).** Two crossings with 2 paths each, Round the reef and
  The arch road (mirror images, different tells): a cart route (Ramp 16, five rows, open sky) round
  the reef, and a foot way down the other side through four arches (12 wide, a 32 stud roof over
  each, a coral rubble step at one end that carts cannot climb). An arch court in the middle holds
  the entrance and a find, reached by roofed arches from each path's middle row. Two slots with two
  rooms each: Coves west (Cove pool, Reef grotto, roofed with pillars) and Coves east (Coconut
  cache, Snorkel hollow), best finds deepest; a dead-end lane with a find per crossing; coral
  beds in wider stretches.

## Measured (quick check, fastest way on foot against the zone's target)

| Zone | Crossing | Foot | Cart (Huge) |
|---|---|---|---|
| 1 | North / Middle / South arches | 30 s (87% of 35) | 37 / 38 / 42 s |
| 2 | the same three | 31 s (85% of 36) | 39 / 40 / 43 s |
| 3 | the same three | 33 to 36 s (88 to 94% of 38) | 39 / 40 / 44 s |
| 4 | Round the reef, The arch road | path 1 52 s (94%), foot only; path 2 56 s (101%), all carts | 60 s |

check.sh: All checks passed.

## Test Range (one zone at a time)

Zones 1 to 4 built. Terrain follows the layout on average (0.05 to 0.37 studs); zones 2 and 3 have
four to five spots 2.6 to 3.2 studs off at the ridges' crests (noted: thin crests come out lower
than drawn). Buried and floating props are shell-grit specks on the pale ridges and the base
zone's props (towels, a tiki torch); the zone 4 rock pool water floats 1.1 studs, not ours. The
range does not roll the biome's loot or entrance spots (it reports 0 of them).

Pictures: `coral-garden-z2.png`, `coral-garden-z4.png`.
