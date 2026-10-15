# Zone 2: Dunes (base)

A dune line that hides most of the lower half from the top. Gaps at the two ramps and along the pier let the eye through, so the far side is seen in strips. Two hollows hold water behind the dunes. The pier runs out at x = 40 on a clear path.

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat.

<!-- map Zones/Zone2@2 -->
```text
..............===....................................==.................
.............==........................oo.............==................
............==.........................oo..............=................
........ ^===  ........................oo..............==.^^^^^ ........
 ^^^^^^^^^==^^^^^^^^^^^^^^^^^^^^^^^^^^^oo^^^^^^^^^^^^^^ ==^^^^^^^^^^^^^ 
...........==..........................oo...............==..............
...........==..........................oo................=..............
............==...............  ........oo...............==..............
............==...............  .........................==...  .........
....^ .......==........ ^^^^^^.........oo...^^^^^^^^^^^^==^^^^^^ .......
....^^^^^^^^^==^^^^^^^^^^^ ............oo...^^^  .......=... ^^^^^^^^ ..
..............=........................oo..............==...............
..............==.......................oo..............==...............
...............=.......................oo.............==................
...............==......................oo............==.................
```
<!-- /map -->

## Flood order

As the tide comes in, each cut floods once the waterline falls to its floor. Deeper and further-out cuts flood first.

<!-- floods Zones/Zone2@2 -->
Hollow at x 260, z 82 floods when the waterline is below Z 265
Hollow at x -60, z 80 floods when the waterline is below Z 263
<!-- /floods -->

## Shortcuts

Shortcut starts counts how many of five start points on the top edge reach the sea faster on foot than by cart. The ramps are the cart route, and gaps and steep banks are the foot route.

## What a player sees from the top

From the top, the lower half is mostly behind the dune. The ramps and the pier show as strips of sand.
