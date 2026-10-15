# Descent layouts

One note per layout: the base layouts for zones 1 to 4, the two biomes that roll now (Sandcastle
Flats and Shipwreck Shallows), and draft layouts for the six planned biomes (not in use yet).

The maps and flood orders in these notes are generated from the game's own ground data by
`tools/layout_map.luau`. Run it from the repo root to refresh them:

    lune run tools/layout_map.luau docs/layouts

The tests in `tools/tests/run.luau` check the layouts themselves (ramps, reachability, shortcuts,
sightlines, heights, the pier, the entrance spots and the pools).

## Checking the layouts against the water

To check the layouts against the tide, the ground was flowed with the sea (connected water only,
flowing in from the seaward edge) at four moments of the tide cycle: high (waterline Z 60), ebb
(Z 300), flood (Z 420) and low (Z 700). Findings:

- **Carts and players on foot can cross the dry beach only at low tide.** Over dry sand, a route
  from the shop to the seaward edge of zone 4 exists only at low tide. This is what the design doc
  says (the outer zones are reachable around low tide), so it's intended, but it means the ramps
  guarantee a route over the *terrain*, not over dry sand.
- **Entrance flats in zones 2 to 4 are under water for most of the cycle.** At high tide the zone 2
  entrances are under water; at ebb and flood, zone 3 and zone 4 entrances are. Only zone 1's
  entrances stay dry all the way. A secret in zone 3 or 4 can only be opened around low tide.
- **A cut floods when the sea can reach it, not when the level passes its floor.** A channel or
  hollow walled off by higher ground stays dry until the waterline is high enough to pass the wall.
  The flood orders in the notes come from a connected flood, so they're the real thresholds, and
  they can be lower than the depth alone suggests.
- **The order of the fords holds.** In every zone, the seaward cuts flood first, as the notes say.
