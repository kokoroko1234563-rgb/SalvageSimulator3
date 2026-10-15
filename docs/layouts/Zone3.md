# Zone 3: Banks (base)

A bank across the zone with gaps for the fords. Fords and hollows are cut below the sand and flood in order as the waterline comes in: the seaward channel first, then the deeper hollow, then the inner hollow. The pier runs through here too.

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat.

<!-- map Zones/Zone3@3 -->
```text
..............===......................oo............==.................
.............==........................oo.............==................
............==.........................oo.............==................
 ^^^^^^^^^.==^^^^^^^^^^^^^^^^^^^^^^^^^^oo^^^^^^^^^^^^^^==^^^^^^^^^^^^^^.
.........=== ^^^^^^....................oo..............==...............
.........==............................oo...............==..............
..........==...........................oo..............===..............
...........=...........................oo.............===...............
~~~~~~^ ~~~==~~~~~~~~~~~~~~~~ ^^^^~~~~~~~~~~^^^^^^^^^=== ~~~~ ^^^^^^^^ ~
~~~~~~~^^^^~==^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~===~^^^^^^~~~~~~~~~~
~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

## Flood order

As the tide comes in, the sea flows in from the seaward edge and reaches each cut when the waterline falls to the height at which a connected path of water exists. A cut walled off by higher ground floods later than its depth alone suggests.

<!-- floods Zones/Zone3@3 -->
Channel at x -120, z 118: the sea reaches it when the waterline is below Z 423
Hollow at x -200, z 80: the sea reaches it when the waterline is below Z 385
Hollow at x 120, z 60: the sea reaches it when the waterline is below Z 369
<!-- /floods -->

## Shortcuts

Shortcut starts counts how many of five start points on the top edge reach the sea faster on foot than by cart. The ramps are the cart route, and gaps and steep banks are the foot route.

## What a player sees from the top

Mostly hidden from the top. The fords show as dark strips when the tide is in.
