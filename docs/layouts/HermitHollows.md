# Hermit Hollows (zone 4)

A giant hermit crab's burrow: five rock walls (22 tall, 12 wide) run right across the tile, with corridors 16 wide between them, and vertical dividers cut the lanes into cells. Almost every corridor is roofed, so it plays as tunnels; a few places break the roof. Zones 5 and 6 use this version until they get their own.

## What a player meets

- **The cart ramps** are the main ways through. Each one zig-zags down a cell, east then west along the lanes and through a gap in every wall (about 76 studs of lane per wall). The left one starts at x = -200, the right one at x = 180. Their cells have dead-end pockets at both ends of every lane, with small loot.
- **The central cell** (x -70 to 90) is the quickest way on foot. Its middle wall is open for 70 studs: a roofless hall with two boulders and the entrance flat at (-25, 76). A hermit crab walks the hall's top lane.
- **The scramble.** One 36-stud pile of rubble (sand, 5 high) stands in the fourth wall of the central cell. Players on foot can climb it; carts can't. It saves about 28 studs a tile, which is the foot shortcut (3 of the 5 test starts are faster on foot than by cart).
- **Far left (x -250 and beyond)** is a sealed burrow: a door off the left cell's top lane leads into a spiral of tunnels that ends in the best loot, in the deepest dead end (weight 5).
- **Far right** is the pool cavern: a roofless chamber, 68 studs wide, built round the rock pool at (260, 70), with boulders. A door in the right cell's third lane leads in. A gap in the cavern's floor wall leads to a long dead-end tunnel to the east with the other best loot (weight 5).
- **Crabs.** Six hermit crabs a tile (one each on the six routes), walking back and forth along a lane. Four stand on the ramp cells' hop lanes, so the main way through has to be timed. Each route stays inside one lane.
- **Loot:** 10 spots, weights 1 to 5. The harder to reach, the higher the weight.

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat, `R` under a roof.

<!-- map Biomes/HermitHollows@4 -->
```text
...............==....................................==.................
.....##........==.......                 RR   ......#==..........##.....
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR..###RRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRR=========RRRRRR.###RRRRRRR
RRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRR.....RRRRRRR
RRRRRRRRRRRRRRRR========RRRRRRR..RR.RRRRRRRRRR========RRRRRR.....RRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRR..o..RRRRRRRRRR=========RRRRRR....RRRRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRR.ooo.RRRRRRRRRRRRRRRRR==RRRRR.....RRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRR~~o~~RRRRRRRRRR=========RRRRRR~~~~RRRRRRR
RRRRRRRRRRRRRRRR========RRRRRRR#####RRRRRRRRRR========RRRRRRRRR##RRRRRRR
RRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRR
############~~~==################RR##################==#~~~~~~##########
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

## Flood order

As the tide comes in, the sea flows in from the seaward edge and reaches each cut when the waterline falls to the height at which a connected path of water exists. This layout has no cuts, so the tool lists none: the whole floor is the beach's own slope. Test Range at four waterlines: at the zone's top (z 1824) 86% of the zone is under water and 85% of the tunnels; at mid-zone (z 2128) 38% and 37%; at the zone's bottom and low tide, none. Lanes toward the sea flood first, and they cut off the way back.

<!-- floods Biomes/HermitHollows@4 -->

<!-- /floods -->

## Shortcuts

Shortcut starts counts how many of five start points on the top edge reach the sea faster on foot than by cart. The rubble pile is the only foot route a cart can't take.

## What a player sees from the top

The five walls hide the whole of the lower half (100% hidden from the top), so the first sight of the tile is the row of wall tops and the roofed lane mouths.

## Measured times

- Map tool: 14.8 s per tile, about 59 s for the zone (target 55 s), 3 of 5 shortcut starts.
- Test Range (walking the terrain): the fastest way down is 57 s; from each start x -280: 72 s, -200: 69 s, -100: 64 s, 0: 59 s, 100: 59 s, 180: 61 s, 280: 65 s. Roblox's pathfinder finds 40 s because it jumps and climbs over the walls; that is not a walking route.
- A rare biome may be up to 30% slower than the target; the quick route is the central cell.
