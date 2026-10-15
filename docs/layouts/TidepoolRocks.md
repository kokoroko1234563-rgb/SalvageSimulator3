# Tidepool Rocks (planned, draft)

Draft, not in use. Rock benches with small pools in them, behind a bank across the zone. The pools hold water after the sea leaves, so a player can be caught as the tide turns.

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat.

<!-- map Biomes/Planned/TidepoolRocks@1 -->
```text
..............===....................................==.................
.............==.......................................==................
............==.........................................=................
..........===..........................................==...............
..........==............................................==..............
...........==...........................................==..............
...........==............................................=..............
............==.... ^^^^^^^^^^^  ........................==..............
............==..........................................==..............
.............==.........................................==..............
.............==.........................................=...............
..............=........................................==...............
..............==.......................................==...............
...............=......................................==................
..^^^^^..^^^^^^==^^^^^^^^^^^^^^^^^ .. ^^^^^^^^^^^^^^^== ^^^^^^^^^^^^^^..
```
<!-- /map -->
<!-- map Biomes/Planned/TidepoolRocks@2 -->
```text
..............===....................................==.................
.............==.......................................==................
............==.........................................=................
........ ^===  ........................................==.^^^^^ ........
 ^^^^^^^^^==^^^^^^^^^^^^^^^^^^^^^^^^^^^..^^^^^^^^^^^^^^ ==^^^^^^^^^^^^^ 
...........==...........................................==..............
...........==............................................=..............
............==...............  .........................==..............
............==...............  .........................==...  .........
....^ .......==........ ^^^^^^..............^^^^^^^^^^^^==^^^^^^ .......
....^^^^^^^^^==^^^^^^^^^^^ .................^^^  .......=... ^^^^^^^^ ..
..............=........................................==...............
..............==.......................................==...............
...............=......................................==................
...............==....................................==.................
```
<!-- /map -->
<!-- map Biomes/Planned/TidepoolRocks@3 -->
```text
..............===....................................==.................
.............==.......................................==................
............==.........................................=................
 ^^^^^^^^^===^^^^^^^^^^^^^^^^^^^^^^^^^^..^^^^^^^^^^^^^^==^^^^^^^^^^^^^^.
..........== ^^^^^^.....................................==..............
...........==...........................................==..............
...........==............................................=..............
............==..........................................==..............
~~~~~~^ ~~~~==~~~~~~~~~~~~~~~ ^^^^~~~~~~~~~~^^^^^^^^^~~~==~~~ ^^^^^^^^ ~
~~~~~~~^^^^~~==^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~==^^^^~~~~~~~~~~
~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->
<!-- map Biomes/Planned/TidepoolRocks@4 -->
```text
~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~
~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~
~#########===###~~#####~~~~~~~~~##################~~~~~==~~~~~~~~~~~~~~~
~~~~~~~~~~==~~~~~~~~~~####~~~~~~#~~~~~~~~~~~~~~~~~##~~##==#############~
~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~
~~~~~~~~~~~==~~~~~~~##~~~~~~~~~~~~~~~~~##~~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~
~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~
~~~~~~~~~~~~==~~~~~########~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~#####~~
~~~~~########==#~~~####################~~~~########~~~##==############~~
~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~#~~#~~~~~~~~
~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~#~~#~~~~~~~~
~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~#~~#~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

## Flood order

As the tide comes in, the sea flows in from the seaward edge and reaches each cut when the waterline falls to the height at which a connected path of water exists. A cut walled off by higher ground floods later than its depth alone suggests.

<!-- floods Biomes/Planned/TidepoolRocks@1 -->
Hollow at x 60, z 96: the sea reaches it when the waterline is below Z 99
Hollow at x 210, z 90: the sea reaches it when the waterline is below Z 89
Hollow at x -200, z 72: the sea reaches it when the waterline is below Z 75
Hollow at x 30, z 60: the sea reaches it when the waterline is below Z 65
Hollow at x 250, z 56: the sea reaches it when the waterline is below Z 61
Hollow at x -240, z 50: the sea reaches it when the waterline is below Z 49
<!-- /floods -->
<!-- floods Biomes/Planned/TidepoolRocks@2 -->
Hollow at x 60, z 96: the sea reaches it when the waterline is below Z 241
Hollow at x 210, z 90: the sea reaches it when the waterline is below Z 239
Hollow at x -200, z 72: the sea reaches it when the waterline is below Z 225
Hollow at x 30, z 60: the sea reaches it when the waterline is below Z 215
Hollow at x 250, z 56: the sea reaches it when the waterline is below Z 211
Hollow at x -240, z 50: the sea reaches it when the waterline is below Z 199
<!-- /floods -->
<!-- floods Biomes/Planned/TidepoolRocks@3 -->
Hollow at x 60, z 96: the sea reaches it when the waterline is below Z 391
Hollow at x 210, z 90: the sea reaches it when the waterline is below Z 389
Hollow at x -200, z 72: the sea reaches it when the waterline is below Z 375
Hollow at x 30, z 60: the sea reaches it when the waterline is below Z 365
Hollow at x 250, z 56: the sea reaches it when the waterline is below Z 361
Hollow at x -240, z 50: the sea reaches it when the waterline is below Z 349
<!-- /floods -->
<!-- floods Biomes/Planned/TidepoolRocks@4 -->
Hollow at x 60, z 96: the sea reaches it when the waterline is below Z 549
Hollow at x 210, z 90: the sea reaches it when the waterline is below Z 539
Hollow at x -200, z 72: the sea reaches it when the waterline is below Z 525
Hollow at x 30, z 60: the sea reaches it when the waterline is below Z 515
Hollow at x 250, z 56: the sea reaches it when the waterline is below Z 511
Hollow at x -240, z 50: the sea reaches it when the waterline is below Z 499
<!-- /floods -->

## Shortcuts

Shortcut starts counts how many of five start points on the top edge reach the sea faster on foot than by cart. The ramps are the cart route, and gaps and steep banks are the foot route.

## What a player sees from the top

The bank across each zone is the main shape from the top: zone 1 stays open, and zones 2 to 4 hide most of the lower half. The maze, pools and channels show as strips and gaps where the bank breaks.