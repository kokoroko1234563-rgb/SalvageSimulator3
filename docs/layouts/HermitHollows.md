# Hermit Hollows

A giant hermit crab's burrow, with its own layout in each of zones 4, 5 and 6. All three share one frame: five rock walls across the tile at z 20, 48, 76, 104 and 132, four lanes 16 wide between them (z 34, 62, 90 and 118), and walls running down the beach that cut the lanes into cells. Each zone goes a step deeper: zone 5's tunnels are lower and sunk below the slope, zone 6's are a roofed labyrinth.

## Zone 4

The first burrow: five rock walls (22 tall, 12 wide) run right across the tile, with corridors 16 wide between them, and vertical dividers cut the lanes into cells. Almost every corridor is roofed, so it plays as tunnels; a few places break the roof.

### What a player meets

- **The cart ramps** are the main ways through. Each one zig-zags down a cell, east then west along the lanes and through a gap in every wall (about 76 studs of lane per wall). The left one starts at x = -200, the right one at x = 180. Their cells have dead-end pockets at both ends of every lane, with small loot.
- **The central cell** (x -70 to 90) is the quickest way on foot. Its middle wall is open for 70 studs: a roofless hall with two boulders and the entrance flat at (-25, 76). A hermit crab walks the hall's top lane.
- **The scramble.** One 36-stud pile of rubble (sand, 5 high) stands in the fourth wall of the central cell. Players on foot can climb it; carts can't. It saves about 28 studs a tile, which is the foot shortcut (3 of the 5 test starts are faster on foot than by cart).
- **Far left (x -250 and beyond)** is a sealed burrow: a door off the left cell's top lane leads into a spiral of tunnels that ends in the best loot, in the deepest dead end (weight 5).
- **Far right** is the pool cavern: a roofless chamber, 68 studs wide, built round the rock pool at (260, 70), with boulders. A door in the right cell's third lane leads in. A gap in the cavern's floor wall leads to a long dead-end tunnel to the east with the other best loot (weight 5).
- **Crabs.** Six hermit crabs a tile (one each on the six routes), walking back and forth along a lane. Four stand on the ramp cells' hop lanes, so the main way through has to be timed. Each route stays inside one lane.
- **Loot:** 10 spots, weights 1 to 5. The harder to reach, the higher the weight.

### Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat, `R` under a roof.

<!-- map Biomes/HermitHollows@4 -->
```text
...............==....................................==.................
...............==........................RR..........==.................
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR.....RRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRR=========RRRRRR####RRRRRRR
RRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRR.....RRRRRRR
RRRRRRRRRRRRRRRR========RRRRRRR..RR.RRRRRRRRRR========RRRRRR.....RRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRR..o#.RRRRRRRRRR=========RRRRRR....RRRRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRR.ooo#RRRRRRRRRRRRRRRRR==RRRRR.....RRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRR~~o~#RRRRRRRRRR=========RRRRRR~~~~RRRRRRR
RRRRRRRRRRRRRRRR========RRRRRRR#####RRRRRRRRRR========RRRRRRRRR##RRRRRRR
RRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRR
###############==####~~##########RR#############~~###==##############~##
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

### Flood order

As the tide comes in, the sea flows in from the seaward edge and reaches each cut when the waterline falls to the height at which a connected path of water exists. This layout has no cuts, so the tool lists none: the whole floor is the beach's own slope. Test Range at four waterlines: at the zone's top (z 1824) 86% of the zone is under water and 85% of the tunnels; at mid-zone (z 2128) 38% and 37%; at the zone's bottom and low tide, none. Lanes toward the sea flood first, and they cut off the way back.

<!-- floods Biomes/HermitHollows@4 -->

<!-- /floods -->

### Shortcuts

Shortcut starts counts how many of five start points on the top edge reach the sea faster on foot than by cart. The rubble pile is the only foot route a cart can't take.

### What a player sees from the top

The five walls hide the whole of the lower half (100% hidden from the top), so the first sight of the tile is the row of wall tops and the roofed lane mouths.

### Measured times

- Map tool: 14.8 s per tile, about 59 s for the zone (target 55 s), 3 of 5 shortcut starts.
- Test Range (walking the terrain): the fastest way down is 57 s; from each start x -280: 72 s, -200: 69 s, -100: 64 s, 0: 59 s, 100: 59 s, 180: 61 s, 280: 65 s. Roblox's pathfinder finds 40 s because it jumps and climbs over the walls; that is not a walking route.
- A rare biome may be up to 30% slower than the target; the quick route is the central cell.

## Zone 5: the sump

Lower and wetter. The walls are 18 tall and the roofs hang at 14 (zone 4's are 22 and 20), and the middle maze's four lanes are sunk 4 studs below the slope, so the floor of the main way through is the first thing the sea takes back.

### What a player meets

- **The cart ramps** zig-zag *outward*, away from the middle: the left one between x -200 and -280, the right one between 180 and 260, 80 studs of lane per wall. They stay on the slope, dry, the whole way. Their cells have short pockets at each lane's ends.
- **The sunken maze** (x -170 to 150) is the quick way on foot. One door in the first wall (x -120) leads down into the first sunken lane; then a gap at -40, the chamber, a gap at 50 and the last gap at -10, with the cut through the last two gaps running on toward the sea. The lanes' ends are long dead ends, each with a loot spot.
- **The chamber** (x -38 to 48, across the third wall) is the one break in the middle's roof: a dry shelf at slope level between the two sunken lanes, a boulder, and the entrance flat at (5, 76).
- **The burrow, far left** (x -360 to -318): a door off the left ramp cell's second lane leads into it. Up is a dead end (weight 3); down, through two more gaps, is the deepest pocket, with the best loot (weight 5).
- **The gallery, far right** (x 290 to 360): a door in the right ramp cell's third lane opens into a roofless cavern two lanes tall, round a pool (a hollow 3 deep). A gap in its roof wall leads up into a sealed lane with the other best loot (weight 5). The right ramp cell's first lane runs on east as a long pocket (weight 2).
- **The scramble** is the sunken lanes themselves: their sides are too steep for a cart, so the middle is foot-only. 2 of the 5 test starts are faster on foot than by cart.
- **Crabs.** Six a tile, one to a route, each inside one lane: three on the ramps' lanes (left second lane, right first and third), three across the middle's way through (first, third and fourth lanes).
- **Loot:** 12 spots, weights 2 to 5, the best at the far ends of the burrow and the gallery.

### Maps

<!-- map Biomes/HermitHollows@5 -->
```text
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~RR~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==========RRRRRRRRR
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRR
RRRRRRR=========RRRRRRRRRRRRRRRRR~~~~~~~~RRRRRRRRRRRRR=========RRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRR~~~~o~~~~RRRRRRRRRRRR==========RRRRRRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRR####ooo####RRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRRR=========RRRRRRRRRRRRRRR~~~~o~~~~RRRRRRRRRRRR=========RRR~~~~~~~
RRRRRRR=========RRRRRRRRRRRRRRRR~~~~~~~~RRRRRRRRRRRRRR=========RR~~~~~~~
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==R~~~~~~~~
RRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==========RR#######
RRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=========RRR#######
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~RR~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

### Flood order

The sunken lanes are the wet heart of it. The bottom lane and the cut through the last two gaps are open to the sea, so they flood as soon as the waterline reaches the tile's seaward edge; then the third lane (waterline at about tile z 125), the gallery's pool (z 97), the second lane (z 69) and the first (z 41). Each lane is under water while the waterline is still 50 to 80 studs seaward of it, so on the way back the quick way through the middle drowns first, from the bottom up, and the dry ramps far out at the sides are what's left. Test Range at four waterlines: at the zone's top (z 2432) 88% of the zone is under water and 87% of the tunnels; at mid-zone (z 2736) 39% and 38%; at the zone's bottom (z 3040) 1% and 2% (the sunken lanes of the last tile); at low tide, none.

<!-- floods Biomes/HermitHollows@5 -->
Channel at x -160, z 118: the sea reaches it when the waterline is below Z 2583
Channel at x 50, z 118: the sea reaches it when the waterline is below Z 2583
Channel at x -10, z 146: the sea reaches it when the waterline is below Z 2583
Channel at x -160, z 90: the sea reaches it when the waterline is below Z 2557
Hollow at x 326, z 106: the sea reaches it when the waterline is below Z 2529
Channel at x -160, z 62: the sea reaches it when the waterline is below Z 2501
Channel at x -160, z 34: the sea reaches it when the waterline is below Z 2473
<!-- /floods -->

### Measured times

- Map tool: 17.8 s per tile, about 71 s for the zone (target 65 s), 2 of 5 shortcut starts.
- Test Range (walking the terrain): the fastest way down is 72 s, and the same back up; from each start x -280: 75 s, -200: 72 s, -100: 73 s, 0: 78 s, 100: 76 s, 180: 72 s, 280: 76 s. The left ramp and the sunken maze are about level (72 and 73 s). That is 11% over the target, inside the 30% a rare biome may take.
- The Test Range still lists two things that aren't the layout's own: a GlitterSand speck (cosmetic texture) at (144, 2906) buried under the first wall of the zone's last tile, and Roblox's pathfinder from x 180 taking a waypoint from y -145 up to y 0 at the zone's top edge (x 198, z 2434), which it reports as a 24.2 slope. All 52 loot and entrance spots are reachable, the crab routes stay in their lanes, and the walls and roofs match the layout.

## Zone 6: the labyrinth

The deepest burrow. Walls 24 tall, roofs at 20, and everything roofed but one chamber. The ramps swing 120 studs a lane, and the middle is a maze of false doors and long dead ends, with the best loot at their far ends.

### What a player meets

- **The cart ramps** zig-zag outward between x -200 and -320 and between 180 and 300: the longest switchbacks on the beach (about 28 s a tile). The far ends of their lanes are dead-end pockets with good loot (weights 3 and 4).
- **The middle maze** (x -170 to 150). Two doors in the first wall: the one at x -130 is the way through; the one at 90 is a false door into a sealed lane end (weight 2). The way through runs -130, -50, 90, -10, -100: a long east-west swing in every lane. A false door at 130 in the fourth wall leads from the third lane's far end into a sealed stretch of the bottom lane: the deepest dead end, with the best loot (weight 5).
- **The scramble.** The fourth wall's gap at x -10 is choked with rubble (sand, 5 high): players climb it, carts can't. It is what makes the middle foot-only (2 of the 5 test starts are faster on foot).
- **The chamber**, off the second lane's west end, is the only open sky: two lanes tall (x -170 to -106), a boulder, and the entrance flat at (-140, 76). A stub of the third lane behind it is a dead end (weight 4).
- **Crabs.** Eight a tile, one to a route, each inside one lane: four on the ramps' lanes and one in each of the middle's four lanes, all across the way through.
- **Loot:** 11 spots, weights 1 to 5.

### Maps

<!-- map Biomes/HermitHollows@6 -->
```text
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
##############~==~##~~RR#####~~#############RR##~~##~==~################
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRR==============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR=============RRR#####~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRR
RRR==============RR~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRRRRRRRRRRRRR==R~~~oo~~~RRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRR=============RR~~oo~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRR
RRR=============RRR######RRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRR
RRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR==============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRR
##############~==~#######RR##~~#####################~==~################
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

### Flood order

No cuts: the floor is the beach's own slope, and almost all of it is under a roof. Test Range at four waterlines: at the zone's top (z 3040) 85% of the zone is under water and 84% of the tunnels; at mid-zone (z 3344) 37% and 36%; at the zone's bottom and low tide, none. The seaward lanes go under first, and with the ramps 28 s a tile, a cart left late is a cart lost.

<!-- floods Biomes/HermitHollows@6 -->

<!-- /floods -->

### Measured times

- Map tool: 26.8 s per tile, about 107 s for the zone (target 85 s), 2 of 5 shortcut starts. (The map tool steps only along X and Z; the Test Range also steps diagonally, so it is quicker.)
- Test Range (walking the terrain): the fastest way down is 98 s, and the same back up; from each start x -280: 105 s, -200: 101 s, -100: 99 s, 0: 104 s, 100: 108 s, 180: 104 s, 280: 108 s. The fastest is the middle maze over the rubble. That is 15% over the target, inside the 30% a rare biome may take.
