# Zone 4: Outer Shore / Reef (base)

Three long rock walls run across the beach, all the way to the side cliffs, each with three gaps. Each wall's gaps sit 80 studs along from the last wall's, so there is never a straight line down: you sidle in one direction from gap to gap. Between the walls are open lanes with boulders and hollows, and one gap in the middle wall is a roofed tunnel. Rock is only in this zone. Zones 5 and 6 use this layout until they get their own.

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat.

<!-- map Zones/Zone4@4 -->
```text
...........======....................................==.................
......========.......................................==.................
.....=====...........................................==.................
#####==##############################################==#################
.....===...........#...#....................##..##...==.................
......====.........#...#..............  ....##..##....==.........##.....
.........====....................##...~~...............==...............
...........===.....................##RR##..............====.............
~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~~~~~~~=====~~~~~~~~~~
#############==#####################RRRR###################====#########
~~~~~~~~~~~~~======~~~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~~~~~~=======~~~~~~~~~
~~~~~~~~~~~~~~~=======~~~~~~~~~~~~~##RR##~~~~~~~~============~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~
#####################==#########################==###################~##
~~~~~~~~~~~~~~~========~~~~~~~~~~~~~~~~~~~~~~~~~=======~~~~~~~~~~~~~~~~~
```
<!-- /map -->

## What a player meets

- **Three walls** (16 wide, 15 to 16 tall) at z 34, 94 and 134, with 24-wide gaps.
  - First wall: gaps at x -300, -60 and 180.
  - Middle wall: gaps at x -220 and 260, and the **tunnel** at x 20 (20 wide, about 40 long, roofed 12 studs up). It is the only roofed ground in the zone.
  - Third wall: gaps at x -140, 130 and 336.
  - The pattern repeats every 240 studs, 80 studs further along each wall, so going straight down is never possible.
- **Lanes.** The lane under the first wall is open (about 50 wide) with boulders and hollows. The lane under the second wall is a tight 24-stud corridor. The lane under the third wall runs into the next tile's first wall.
- **Cart ramps** wind through the gaps and sidle along the lanes. The west ramp enters at x -200, goes through the gaps at x -300, -220 and -140 and leaves at x -200. The east ramp enters at x 180, goes through the gaps at x 180, 260 and 130 and leaves at x 180.
- **Dead ends.** Two U-shaped pockets (two short spurs off the first wall, at x -166/-126 and x 90/130) are open to the south and hold the best finds. The tunnel and the far corners of the lanes hold smaller ones.

## Shortcuts

On foot the quick way is the nearest gap in each wall. The tunnel at x 20 is a foot route the ramps skip. Carts must drive to x -200 or x 180 first, so some starts are faster on foot (the map tool counts 2 of 5).

## Flood order

The low ground floods as the tide comes in. First is the shallow ford (a channel in the lane below the third wall), then the hollows in the first lane. The tunnel floods with the lane around it, because its floor is level with the ground.

<!-- floods Zones/Zone4@4 -->
Channel at x -100, z 150: the sea reaches it when the waterline is below Z 1975
Hollow at x 30, z 62: the sea reaches it when the waterline is below Z 1897
Hollow at x -250, z 64: the sea reaches it when the waterline is below Z 1887
<!-- /floods -->

## Measured times

- Map tool: about 14.8 s per tile, about 59 s for the zone (target 55 s).
- Test Range (walking the real terrain): fastest way down 49 s, and 49 s back up. From each start: x -280 55 s, x -200 59 s, x -100 54 s, x 0 55 s, x 100 53 s, x 180 50 s, x 280 53 s. The fastest start is at the top edge near x 180, where the ramp's gap is.

## What a player sees from the top

Almost all of the lower half is hidden: the map tool puts it at 96%.
