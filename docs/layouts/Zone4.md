# Zone 4: Outer Shore / Reef (base)

Three long rock walls run across the beach, 100 to 130 studs apart in their gaps, so you zig-zag from gap to gap. Between the walls are open lanes with boulders and hollows. One gap in the middle wall is a roofed tunnel, the landmark. Rock is only in this zone. Zones 5 and 6 use this layout until they get their own.

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat.

<!-- map Zones/Zone4@4 -->
```text
..............===....................................====...............
.....##......===........                      ......##..=====....##.....
^###########==################..##########################.===#########^
^###########==################..############################==#########^
......##.....===..........................................===.....##....
......##......====..  ......................##..  ......====......##....
......##........=======......##....................=======........##....
....................======.............##RR##...======..................
~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~#RRRR#~~===~~~~~~~~~~~~~~~~~~~~~~
^########################==#############RRRR###==######################^
~~~~~~~~~~~~~~~~~~~~~~=====~~~~~~~~~~~~#RRRR#~~=====~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~=============~~~~~~~~~~~~~~##RR##~~~~=============~~~~~~~~~~
~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~
~###########==~#########################################~~====#########~
~~~~~~~~~~~~=====~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~=========~~~~~~~~~~
```
<!-- /map -->

## What a player meets

- **Three walls** (16 wide, 15 to 16 tall) at z 30, 94 and 134, each running to the side cliffs. Their gaps are 24 wide.
  - First and third wall: gaps at x -230, -50 and 250.
  - Middle wall: gaps at x -100 and 120, and the **tunnel** at x 60. The tunnel is 20 wide and about 40 long, roofed 12 studs up. It is the only roofed ground in the zone.
- **Lanes.** The lane between the first and second wall is the open one (about 50 wide), with three boulders and two hollows. The lane between the second and third wall is a tight 24-stud corridor. Going on from the third wall into the next tile's first wall is another open lane.
- **Cart ramps** wind through the same gaps: the west ramp passes the walls at x -230, -100, -230; the east ramp at x 250, 120, 250.
- **Dead ends.** Two spurs off the first wall (x -290 and x 310) close off the corners of the first lane. The loot behind them has the highest weight. The tunnel and the corner lanes of the middle corridor hold smaller finds.

## Shortcuts

The gaps are staggered by 100 to 130 studs from wall to wall, so the way down is a zig-zag. The tunnel at x 60 is a foot route (the ramps skip it) that links the first-wall gap at x -50 with the third-wall gap at x -50.

Players on foot go through the gaps nearest to them, and the carts have to drive to x -200 or x 180 first, so four of the five starts are faster on foot.

## Flood order

The low ground floods as the tide comes in. First is the shallow ford (a channel at z 10 to 12, in the lane across the seam between tiles), then the hollows in the first lane. The tunnel floods with the lane around it, because its floor is the same as the ground. The Test Range at a waterline of Z 2128 (the middle of the zone) puts about 40% of the zone under water, and at Z 1824 (the top) about 88%.

<!-- floods Zones/Zone4@4 -->
Hollow at x 130, z 56: the sea reaches it when the waterline is below Z 1891
Hollow at x -150, z 54: the sea reaches it when the waterline is below Z 1884
Channel at x -120, z 12: the sea reaches it when the waterline is below Z 1841
<!-- /floods -->

## Measured times

- Map tool: the on-foot figure counts the strip of beach next to the side cliffs (see below), so it says about 7.6 s per tile.
- Test Range (real pathfinding, seven starts): from x 0 it takes 52 s for the zone, from x -200 45 s, from x 180 47 s, from x -100 or 100 51 s, close to the 55 s target. The fastest start is x -280 or 280, at 38 s.

The two starts at the sides are quick because the beach edge is not blocked. Shapes fade to flat over the last 30 studs before the side cliffs, so there is always a 15 stud strip along each side that no wall can close. Starting at x 280 you walk 70 studs to the strip, run the whole zone down it and walk 70 back. That is about 750 studs, 38 s, whatever the layout.

## What a player sees from the top

Almost all of the lower half is hidden: the map tool puts it at 96%. The first wall alone is 16 tall.
