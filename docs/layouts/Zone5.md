# Zone 5: The Shoals (base)

Three low rock bars run across the beach, cliff to cliff, with flooded lanes between them. The quick way down is through the **fords**: gaps in the bars whose floor is cut below the slope, each with a sand sill you scramble over. They zig-zag through the middle of the beach. The dry gaps carry the cart ramps out to the side cliffs and back, a longer way. The fords go under first, the seaward one before the rest, so on the way back up the quick way closes behind you one ford at a time.

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat, `R` under a roof.

<!-- map Zones/Zone5@5 -->
```text
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
###############==######~~##########RR##########~~####==#################
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~RRRR~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~=============~~~~~~~~~~~~~~~~RRRRRR~~~~~~~~~~~~~~===============~~~~
~~============~~~~~~~~~~~~~~~#~~~RRRRRR~~~#~~~~~~~~~~~~~==============~~
~==~~~~~~~~~~~~~~~~~~~~~~~~~~#~~~~RRRR~~~~#~~~~~~~~~~~~~~~~~~~~~~~~~~==~
~=~###############################RRRR###############################~=~
~==~~~~~~~~~~~~~~~~~~~~~~~~~~#~~~~RRRR~~~~#~~~~~~~~~~~~~~~~~~~~~~~~~~==~
~==============~~~~~~~~~~~~~~#~~~~RRRR~~~~#~~~~~~~~~~~~================~
~~~~=============~~~~~~~~~~~~~~~~~RRRR~~~~~~~~~~~~~~~===============~~~~
###############==######~~##########RR##########~~####==#################
###############==######~~######################~~####==#################
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

## What a player meets

- **Three bars** (12 wide, 12 tall: you can't see over them, but they are lower than zone 4's walls) at z 28, 76 and 120.
  - First bar: fords at x -120 and 120, dry gaps (the ramps) at x -200 and 180.
  - Second bar: one ford, at x 0, and dry gaps against both cliffs (x -344 and 344).
  - Third bar: the same gaps as the first.
- **The fords.** Each is a cut 4 deep and 16 wide running down through its gap, with a sand sill across the gap: easy on foot, too steep for a cart. The quick way goes ford, ford, ford: x ±120, then 0, then ±120, and straight on into the next tile's first ford.
- **The Grotto.** The middle ford runs through a cave on both sides of the second bar (roofed 10 studs up). It is the landmark of the zone and the only shelter, and it floods with the lanes.
- **Lanes.** Between the bars are two lanes, 36 and 32 wide, each with a shallow shoal (a cut 2 deep and 20 wide) along its middle that joins its fords. Four short walls off the second bar stand either side of the Grotto, so the way to and from the middle ford has to go round them.
- **Cart ramps** go through the dry gaps: in at x -200 (or 180), along the first lane out to the cliff, round the end of the second bar, back along the second lane and out at x -200 (or 180). Nearly 300 studs of lateral driving a tile.
- **Loot.** The best finds are in the Grotto (Weight 3) and the four pockets between the Grotto and the short walls (Weight 2). The lanes' far corners and the cliff ends, where only the ramps go, hold smaller ones.

## Shortcuts

The fords are the foot shortcut: carts can't cross their sills, so from the middle of the top edge a cart has to drive out to x -200 or 180 and round the cliffs. The map tool counts 3 of 5 starts faster on foot. With the fords closed, the dry way on foot (through the ramp gaps, round the cliff ends of the second bar) is about 10% longer on the map tool (19.6 s a tile against 18.0 s), and much longer for anyone coming from the middle of the beach.

## Flood order

The fords are cut 4 deep and the shoals 2, so they fill well before the open ground. The seaward fords (third bar) go first, then the second lane's shoal and the middle ford (through the Grotto), then the first lane and its fords. Coming back up on a rising tide, the third bar's fords are the first thing you reach and the first to go under, so the quick way is cut off at its far end.

<!-- floods Zones/Zone5@5 -->
Channel at x -120, z 142: the sea reaches it when the waterline is below Z 2581
Channel at x 120, z 142: the sea reaches it when the waterline is below Z 2581
Channel at x 0, z 98: the sea reaches it when the waterline is below Z 2560
Channel at x -170, z 98: the sea reaches it when the waterline is below Z 2560
Channel at x 120, z 50: the sea reaches it when the waterline is below Z 2512
Channel at x -170, z 52: the sea reaches it when the waterline is below Z 2512
Channel at x -120, z 50: the sea reaches it when the waterline is below Z 2512
<!-- /floods -->

## Measured times

- Map tool (4-stud steps along X and Z only): about 18.0 s per tile, about 72 s for the zone (target 65 s).
- Test Range (walking the real terrain): fastest way down 63 s, and 63 s back up. From each start: x -280 70 s, x -200 66 s, x -100 63 s, x 0 68 s, x 100 63 s, x 180 65 s, x 280 70 s. The fastest route goes through the fords at x -120 and 0, round the short walls by the Grotto, and straight across each tile edge.

## What a player sees from the top

Nothing of the lower half: the map tool puts the hidden share at 100%.
