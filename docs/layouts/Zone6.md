# Zone 6: The Drowned Reach (base)

The deepest, slowest ground on the beach: a maze of tall rock walls (24 high, 12 wide) in three cells, divided by walls that run down the beach at x -80 and x 60. Each outer cell holds a cart ramp that winds through three long galleries, out to the cliffs and back. The middle cell is a tight maze of sunken lanes: the quick way on foot, but shut to carts by rubble. Every gallery end the ramps don't use is a dead end, and the roofed ones by the cliffs hold the best finds.

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat, `R` under a roof.

<!-- map Zones/Zone6@6 -->
```text
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRR==~##~~#######~~#################~~##~==~#RRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR===========~##~~############~===========~~RRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR===========~##~~~~~~~~~~~~##~===========~RRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR~~~~~~~~~~=~###########~~###~=~~~~~~~~~~~~RRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRR
RR========================RRRRRRRRRRRRRRRRRR========================RRRR
RR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRR
RR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRR
~~==~~~~~~~~~~~~~~~~~~~~~~~###########~~###~~~~~~~~~~~~~~~~~~~~~~~==~~~~
~~===============~~~~~~~~~~##~~~~~~~~~~~~##~~~~~~~~~~===============~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~##~~~~~~~~~~~~##~~~~~~~~~~==~~~~~~~~~~~~~~~~~
##############~==~###########~~#####################~==~################
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

## What a player meets

- **The ramp cells** (x -360 to -80 and 60 to 360). Each has three galleries, at z 32, 74 and 116, 28 wide between walls 44 apart (so the ramps' cleared edges never cut into the walls). The west ramp comes in at x -200, runs east to x -104, drops through a gap into the middle gallery, runs the whole of it west to x -330 under the cliff, drops into the third gallery and comes back east to x -200 and out. The east ramp is its mirror: in at x 180, west to 84, east to 310, west to 180. The middle galleries are roofed: about 230 studs of tunnel each, the landmark of the zone.
- **The middle cell** (x -74 to 54): five walls 28 apart make four 16-wide lanes. Their gaps swap sides (x -60, then x 32), so every lane is walked from end to end. The lanes are sunk 2 studs, and the two inner ones are roofed. Its first gap (x -60, top wall) and fourth (x 32) are choked with rubble.
- **Rubble.** Four piles of sand rubble, 4 high: the two in the middle cell, and one in the top wall of each ramp cell (x -152 and x 132), a short cut into the first gallery. Players climb them; carts can't.
- **Dead ends.** The first galleries run on past the ramps' start to the cliffs, roofed: the west one holds a drowned pool (a hollow 3 deep at x -300) and the best finds at its far end (weight 5), and so does the east one. The third galleries run on past the ramps' exit to the middle cell's wall (weight 2). Each middle-cell lane ends in a short pocket behind its gap (weights 1 to 2).
- **Loot:** 10 spots, weights 1 to 5; the deeper and further from the way through, the higher.

## Shortcuts

The middle cell is foot-only (its rubble shuts carts out) and is the fastest way through. A cart starting at x 0 has to go all the way to a ramp at x -200 or 180 first. From x -150 and x 150 the rubble gaps into the ramp cells' first galleries save players the trip to the ramp's gate. The map tool counts 3 of 5 starts faster on foot.

## Flood order

Low ground everywhere: this is the last zone before the sandbar, so the sea leaves it last and comes back to it first. The middle cell's sunken lanes are its lowest ground and flood first: the seaward lane as soon as the sea reaches the tile, then (once the pool in the west dead-end gallery has filled) the other three together, as the water tops the rubble. Then the galleries go under with the slope. Under the roofs it is the same: at mid-zone (waterline Z 3344) the Test Range finds 39% of the zone and 44% of its tunnels under water, and at the zone's top (Z 3040) 86% and 91%. The middle cell is the quick way back up, and the first to be cut off.

<!-- floods Zones/Zone6@6 -->
Channel at x -68, z 118: the sea reaches it when the waterline is below Z 3163
Hollow at x -300, z 32: the sea reaches it when the waterline is below Z 3081
Channel at x -68, z 90: the sea reaches it when the waterline is below Z 3077
Channel at x -68, z 62: the sea reaches it when the waterline is below Z 3077
Channel at x -68, z 34: the sea reaches it when the waterline is below Z 3077
<!-- /floods -->

## What a player sees from the top

Nothing past the first wall: the map tool puts 99% of the lower half out of sight.

## Measured times

- Map tool: 22.8 s per tile, about 91 s for the zone (target 85 s); 3 of 5 shortcut starts. The fastest tile is the middle cell; the ramp cells on foot through their rubble take about 23 s, and by the ramps alone about 25 s.
- Test Range (walking the real terrain): fastest way down 82 s, and 82 s back up (target 85 s). From each start: x -280 93 s, x -200 89 s, x -100 84 s, x 0 85 s, x 100 90 s, x 180 93 s, x 280 98 s. The fastest route runs straight down the middle cell. Roblox's own pathfinder finds 40 s because it jumps and climbs over the walls; that is not a walking route.
