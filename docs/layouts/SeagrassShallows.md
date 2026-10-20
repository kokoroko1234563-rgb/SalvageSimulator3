# Seagrass Shallows (biome, zones 1 to 4)

Drawn with the kit from `tools/kit/plans/seagrass_shallows.py` (edit the plan and re-run it),
written to `src/shared/Layouts/Biomes/SeagrassShallows.luau`. Card:
`docs/design/cards/seagrass-shallows.md`. Gentle choices taken: only tangling seagrass (`Slow`,
radius 8 to 10, easy to step round), no undertow.

## What was built

- **Zones 1 to 3 (open sand, no walls or rock).** Channels flood in stages (three across the zone,
  five in zone 1), the collapsed jetty (timber line, two rows of posts, planks, chain, crate) lies
  along the middle channel and the entrance (a flat spot) is under its end. Seagrass meadows are
  painted Leafy Grass with weed; pools hold the finds (weights 1 to 4, best on the far side).
  Zones 2 and 3 have two banks across (heights 4.4 / 6.4, within the zone limits 5 / 7) that carts
  cannot climb and feet can. Zone 1 has no banks (even a 2.4 bank hides more than 20% of the zone
  from the top, which the sightline test forbids): its cart barriers are narrow, steep-sided
  channels. Channels and the jetty are placed clear of the rock pools.
- **Crossings (3 in each of zones 1 to 3, one path each):** Seagrass trail, Reed track, Mud-flat
  way. Each is a Ramp 16 wide winding through a different gap in the banks/channels, its own
  three seagrass patches and its own tell at the way in (posts, chain and crate, kelp).
- **Zone 4 (walls 10, drawn 24+ thick).** Two crossings with 2 paths each, Reed maze and Net
  rows (mirror images, different tells): a cart route (Ramp 16, a snake of five rows) down one side
  round the channels, and a foot way (12 wide lane, a ditch along its straights that carts cannot
  take) down the other. A jetty court in the middle holds the entrance and a find, reached by a
  spur from each path's middle row (the one link). Two slots with two rooms each: Grass pockets
  (Reed pocket, Silted cove) and Jetty cellars (Net store, Under the pier), best finds deepest.
  A dead-end lane with a find per crossing; wider stretches with a seagrass patch to one side.

## Measured (quick check, fastest way on foot against the zone's target)

| Zone | Crossing | Foot | Cart (Huge) |
|---|---|---|---|
| 1 | Seagrass trail / Reed track / Mud-flat way | 30 s (87% of 35) | 41 / 43 / 41 s |
| 2 | the same three | 30 s (84% of 36) | 42 / 46 / 45 s |
| 3 | the same three | 31 s (82% of 38) | 43 / 49 / 44 s |
| 4 | Reed maze, Net rows | path 1 47 s (86%), foot only; path 2 54 s (99%), all carts | 60 s |

check.sh: All checks passed.

## Test Range (one zone at a time)

Zones 1 to 4 built. Terrain follows the layout (average 0.04 to 0.16 studs off); zones 2 and 3
have two spots 2.5 to 2.8 studs off at a bank's crest (noted: thin crests come out lower than
drawn). Buried and floating props reported are the base zone's own props and textures
(loungers, towels, shell-grit specks), none of this biome's decor; the zone 4 rock pool water
floats 1.1 studs (also not ours). The range does not roll the biome's loot or entrance spots
(it reports 0 of them).

Pictures: `seagrass-shallows-z2.png`, `seagrass-shallows-z4.png`.
