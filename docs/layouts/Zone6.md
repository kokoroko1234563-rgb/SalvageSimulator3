# Zone 6: The Drowned Reach

The deepest, slowest ground on the beach, drawn as one 720 x 608 piece. A maze of tall rock walls (24 high, 12 wide; the ones running across worn by a stud, the Test Range's tolerance) on a 40-stud grid: lanes 28 wide between the walls, a roof over some of the straights, low ground everywhere. Four long walls cut the Reach into nine wards, and each tide the sea rolls one of five **crossings** (which gates stay open, which walls fill the wards, where the tunnels and the cart ramp go) and one room for each of seven **side slots**. Every crossing is a single winding route with dead ends hung all along it: nothing is a straight line, and from the top you see nothing at all. The dead ends hold the loot; the dangers (sinking sand, falling rock, the undertow and the Gloom) sit on the way, each with its tell and a way to avoid it.

The maze is built from pictures in `Zone6.luau`: a text grid where `+` is a node, `--` or `|` a wall, `==` or `!` rubble, and a blank an opening. A post stands on every node a wall touches, and the walls run 4 studs into it, so walls that meet end to end leave no crack even with their edges worn. The side rooms are drawn by `tools/gen/zone6/rooms.py`, which writes them into the file between its `<<< rooms` markers (and checks that every room is reachable from its door and that every find lies in a dead end); `tools/gen/zone6/maze.py` and `bars.py` are the maze helpers (`bars.py` broke up the end walls once).

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat, `R` under a roof. The whole Reach lies below the mid-tide line, so almost all of it shows as `~`; the walls and roofs are what the maps are for. The first crossing with the first room of every slot:

<!-- map Zones/Zone6@6 -->
```text
~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#########==######~~#########RRRRRRRR####RRRR#####~~##~~#################
~~~~~~~~~=============~##~~~RRRRRRRR#~~~RRRR~~~##~~##~~##~~~~~~##~~~~~~~
~~~~~~~~~==============##~~~RRRRRRRR#~~~RRRR~~~##~~##~~##~~~~~~##~~~~~~~
~~~~~~~~~~~~~~~##~~~~==##~~~RRRRRRRR#~~~RRRR~~~##~~##~~##~~~~~~##~~~~~~~
####RRRRRRRR#########==##~~#####RRRRRRRRRRRR#~~##########~~##~~##~~##~~~
~~~~RRRRRRRR#~~~~~~##==##~~##~~#RRRRRRRRRRRR#~~##~~~~~~~~~~##~~~~~~##~~~
~~~~RRRRRRRR#~~~~~~##==##~~##~~#RRRRRRRRRRRR#~~##~~~~~~~~~~##~~~~~~##~~~
~~~~RRRRRRRR#~~~~~~##==##~~##~~#RRRRRRRRRRRR#~~##~~~~~~~~~~##~~~~~~##~~~
~~~##########~~##~~##==##~~##~~##~~######~~##~~#RRRRRRRR####RRRRRRRR#~~~
~~~~~~~~~~~~~~~##~~##==##~~##~~~~~~##~~~~~~##~~~RRRRRRRR~~~~RRRRRRRR~~~~
~~~~~~~~~~~~~~~##~~##==##~~##~~~~~~##~~~~~~##~~~RRRRRRRR~~~~RRRRRRRR~~~~
~~~~~~~~~~~~~~~##~~##==##~~##~~~~~~##~~~~~~##~~~RRRRRRRR~~~~RRRRRRRR~~~~
~~~#RRRRRRRR#~~######==##~~##~~##~~######~~##~~######################~~~
~~~~RRRRRRRR#~=========##~~~~~~##~~~~~~##~~##~~##~~~~~~~~~~##~~~~~~~~~~~
~~~~RRRRRRRR#==========##~~~~~~##~~~~~~##~~##~~##~~~~~~~~~~##~~~~~~~~~~~
~~~~RRRRRRRR#==~~~~~~~~##~~~~~~##~~~~~~##~~##~~##~~~~~~~~~~##~~~~~~~~~~~
#############==######~~#####RRRRRRRR####RRRR#~~##~~##########~~#########
~~~~~~=========##~~~~~~##~====================~##~~~~~~~~~~~~~~~~~~~~~~~
~~~~~==========##~~~~~~##======================##~~~~~~~~~~~~~~~~~~~~~~~
~~~~~==~~~~~~~~##~~~~~~##==~RRRRRRRR~~~~RRRR~==##~~~~~~~~~~~~~~~~~~~~~~~
#####==##########~~#####R==R################R==R#####~~#################
~~~##==##~====~##~~~~~~#R==R#~~##~~~~~~##~~#R==R#~~##~~~~~~##~~~~~~##~~~
~~~##==##======##~~~~~~#R==R#~~##~~~~~~##~~#R==R#~~##~~~~~~##~~~~~~##~~~
~~~##==##==~~==##~~~~~~#R==R#~~##~~~~~~##~~#R==R#~~##~~~~~~##~~~~~~##~~~
~~~##==##==##==######~~#R==R#~~##~~~~~~##~~#R==R#~~######~~##~~~~~~##~~~
~~~~~==~~==##==##~~~~~~#R==R#~~~~~~~~~~~~~~#R==R#~~~~~~~~~~~~~~~~~~~~~~~
~~~~~==~~==##==##~~~~~~#R==R#~~~~~~~~~~~~~~#R==R#~~~~~~~~~~~~~~~~~~~~~~~
~~~~~==~~==##==##~~~~~~#R==R#~~~~~~~~~~~~~~#R==R#~~~~~~~~~~~~~~~~~~~~~~~
#####==~~==##==##~~######==##~~##~~~~~~##~~#R==R#~~##########~~~~~~##~~~
~~=====~~==##==##~~##~=====##~~~~~~~~~~~~~~#R==R#~~~~~~##~~##~~~~~~##~~~
~======~~==##==##~~##======##~~~~~~~~~~~~~~#R==R#~~~~~~##~~##~~~~~~##~~~
~==~~~~~~==##==##~~##==~~~~##~~~~~~~~~~~~~~#R==R#~~~~~~##~~##~~~~~~##~~~
~==######==##==~#~~##==#RRRRRRRR#~~#####RRRRR==R#####~~##~~#############
~==========##==~~~~##==#RRRRRRRR~~~~~~~~RRRRR==R#~~~~~~##~~~~~~~~~~~~~~~
~==========##==~~~~##==#RRRRRRRR~~~~~~~~RRRRR==R#~~~~~~##~~~~~~~~~~~~~~~
~~~~~~~~~~~##==~~~~##==#RRRRRRRR~~~~~~~~RRRRR==R#~~~~~~##~~~~~~~~~~~~~~~
RRRR####RRRR#==######==##############~~######==##~~##########~~#########
RRRR~~~~RRRR#==##~=====##~=====================##~~~~~~~~~~~~~~~~~~~~~~~
RRRR~~~~RRRR#==##======##======================##~~~~~~~~~~~~~~~~~~~~~~~
RRRR~~~~RRRR#==##==~~~~##==~~~~~~~~~~~~~~~~~~~~##~~~~~~~~~~~~~~~~~~~~~~~
RRRR#####~~##==##==######==##########~~#####RRRR#########~~######~~#####
RRRR#~~~~~~~~======##~~##==##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~~~~~~~~~~
RRRR#~~~~~~~~======##~~##==##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~~~~~~~~~~
RRRR#~~~~~~~~~~~~~~##~~##==##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~~~~~~~~~~
RRRR####RRRR#########~~##==#RRRR####RRRRRRRR#~~##~~##~~######~~~~~~##~~~
RRRR~~~~RRRR#~====~##~~##==#RRRR~~~~RRRRRRRR#~~~~~~##~~~~~~##~~~~~~##~~~
RRRR~~~~RRRR#======##~~##==#RRRR~~~~RRRRRRRR#~~~~~~##~~~~~~##~~~~~~##~~~
RRRR~~~~RRRR#==~~==##~~##==#RRRR~~~~RRRRRRRR#~~~~~~##~~~~~~##~~~~~~##~~~
#############==##==##~~##==#RRRR####RRRRRRRRRRRR#~~######~~##~~~~~~##~~~
~~~~~~~##~=====##==========#RRRR~~~~RRRRRRRRRRRR#~~~~~~~~~~##~~~~~~##~~~
~~~~~~~##======##==========#RRRR~~~~RRRRRRRRRRRR#~~~~~~~~~~##~~~~~~##~~~
~~~~~~~##==~~~~##~~~~~~~~~~#RRRR~~~~RRRRRRRRRRRR#~~~~~~~~~~##~~~~~~##~~~
~~~######==##########~~#########RRRR####RRRR#~~#####RRRR####RRRR########
~~~~~~=====##~~~~~~~~~~##~~~~~~~RRRR~~~~RRRR~~~~~~~~RRRR~~~~RRRR~~~~~~~~
~~~~~======##~~~~~~~~~~##~~~~~~~RRRR~~~~RRRR~~~~~~~~RRRR~~~~RRRR~~~~~~~~
~~~~~==~~~~##~~~~~~~~~~##~~~~~~~RRRR~~~~RRRR~~~~~~~~RRRR~~~~RRRR~~~~~~~~
#####==######~~##############~~##################~~##############~~#####
~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
<!-- /map -->

Crossing 2 (Hall gallery):

<!-- map Zones/Zone6@6/c2 -->
```text
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~
RRRR#~~#RRRR#############~~#####RRRR####RRRR#####~~##~~######==#########
RRRR#~~#RRRR~~~##~~~~~~##~~##~================~##~=============##~~~~~~~
RRRR#~~#RRRR~~~##~~~~~~##~~##==================##==============##~~~~~~~
RRRR#~~#RRRR~~~##~~~~~~##~~##==~RRRR~~~~RRRR~==##==##~~##~~~~~~##~~~~~~~
####RRRRRRRR#~~##~~##~~######==#RRRRRRRRRRRR#==##==######~~######~~#RRRR
~~~~RRRRRRRR#~~~~~~##~~~~~~~~==#RRRRRRRRRRRR#==##==##~~##~~##~~~~~~#RRRR
~~~~RRRRRRRR#~~~~~~##~~~~~~~~==#RRRRRRRRRRRR#==##==##~~##~~##~~~~~~#RRRR
~~~~RRRRRRRR#~~~~~~##~~~~~~~~==#RRRRRRRRRRRR#==##==##~~##~~##~~~~~~#RRRR
~~~##########~~##########~~##==##~~######~~##==##==##~~##~~##~~#####RRRR
~~~~~~~~~~~~~~~~~~~##~~##~~##==~~~~##~~~~~~##======##~~~~~~##~~~~~~#RRRR
~~~~~~~~~~~~~~~~~~~##~~##~~##==~~~~##~~~~~~##======##~~~~~~##~~~~~~#RRRR
~~~~~~~~~~~~~~~~~~~##~~##~~##==~~~~##~~~~~~##~~~~~~##~~~~~~##~~~~~~#RRRR
~~~#RRRRRRRR#####~~##~~######==##~~######~~##########~~######~~##~~##~~~
~~~~RRRRRRRR#~~##~~~~~~##~=====##~~~~~~##~~##~~##~~##~~##~~~~~~##~~##~~~
~~~~RRRRRRRR#~~##~~~~~~##======##~~~~~~##~~##~~##~~##~~##~~~~~~##~~##~~~
~~~~RRRRRRRR#~~##~~~~~~##==~~~~##~~~~~~##~~##~~##~~##~~##~~~~~~##~~##~~~
#############~~######~~##==#RRRRRRRR####RRRR#~~##~~##~~##########~~#RRRR
~~~~~~~~~~~~~~~~~~~~~~~##=====================~##~~~~~~~~~~~~~~~~~~#RRRR
~~~~~~~~~~~~~~~~~~~~~~~##======================##~~~~~~~~~~~~~~~~~~#RRRR
~~~~~~~~~~~~~~~~~~~~~~~##~~~RRRRRRRR~~~~RRRR~==##~~~~~~~~~~~~~~~~~~#RRRR
#####~~#################RRRR#################==######~~#################
~~~~~~~##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~##=====~##~~~~~~##~~~~~~##~~~
~~~~~~~##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~##======##~~~~~~##~~~~~~##~~~
~~~~~~~##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~##~~~~==##~~~~~~##~~~~~~##~~~
~~~######~~##~~#########RRRR#~~##~~~~~~##~~#RRRR#==######~~##~~~~~~##~~~
~~~~~~~##~~##~~##~~~~~~#RRRR#~~~~~~~~~~~~~~#RRRR#==##~~~~~~~~~~~~~~~~~~~
~~~~~~~##~~##~~##~~~~~~#RRRR#~~~~~~~~~~~~~~#RRRR#==##~~~~~~~~~~~~~~~~~~~
~~~~~~~##~~##~~##~~~~~~#RRRR#~~~~~~~~~~~~~~#RRRR#==##~~~~~~~~~~~~~~~~~~~
#####~~######~~##~~##~~##~~##~~##~~~~~~##~~#RRRR#==##########~~~~~~##~~~
~~~##~~~~~~##~~~~~~##~~~~~~##~~~~~~~~~~~~~~#RRRR#=========~##~~~~~~##~~~
~~~##~~~~~~##~~~~~~##~~~~~~##~~~~~~~~~~~~~~#RRRR#==========##~~~~~~##~~~
~~~##~~~~~~##~~~~~~##~~~~~~##~~~~~~~~~~~~~~#RRRR#~~~~~~~~==##~~~~~~##~~~
~~~######~~##########~~#####RRRR#~~#####RRRR#~~##########==#############
~~~~~~~~~~~~~~~~~~~~~~~##~====================~##~=========##~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~##======================##==========##~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~##==~RRRR~~~~~~~~RRRR~==##==~~~~~~~~##~~~~~~~~~~~
RRRR####RRRR########RRRRR==RRRRRRRRR####RRRR#==##==##########~~#########
RRRR~~~~RRRR#~~~~~~#RRRRR==RRRRRRRRR~~~~RRRR~==##==##~~~~~~~~~~~~~~~~~~~
RRRR~~~~RRRR#~~~~~~#RRRRR==RRRRRRRRR~~~~RRRR~==##==##~~~~~~~~~~~~~~~~~~~
RRRR~~~~RRRR#~~~~~~#RRRRR==RRRRRRRRR~~~~RRRR~==##==##~~~~~~~~~~~~~~~~~~~
RRRR#####~~##~~##~~##~~#R==R#########~~#####R==R#==##~~##########~~#####
RRRR#~~~~~~~~~~##~~##~~#R==R#~~~~~~~~~~~~~~#R==R#==##~~~~~~##~~~~~~~~~~~
RRRR#~~~~~~~~~~##~~##~~#R==R#~~~~~~~~~~~~~~#R==R#==##~~~~~~##~~~~~~~~~~~
RRRR#~~~~~~~~~~##~~##~~#R==R#~~~~~~~~~~~~~~#R==R#==##~~~~~~##~~~~~~~~~~~
RRRR####RRRR#####~~#RRRR#==#RRRR####RRRRRRRR#==#~==######~~##~~~~~~##~~~
RRRR~~~~RRRR#~~~~~~#RRRR#==#RRRR~~~~RRRRRRRR#==~~=====~~~~~##~~~~~~##~~~
RRRR~~~~RRRR#~~~~~~#RRRR#==#RRRR~~~~RRRRRRRR#==~~======~~~~##~~~~~~##~~~
RRRR~~~~RRRR#~~~~~~#RRRR#==#RRRR~~~~RRRRRRRR#==~~~~~~==~~~~##~~~~~~##~~~
#############~~######~~#R==RRRRR####RRRRRRRRR==R#####==##~~##~~~~~~##~~~
~~~~~~~~~~~~~~~##~~~~~~#R==RRRRR~~~~RRRRRRRRR==R#~~##==##~~##~~~~~~##~~~
~~~~~~~~~~~~~~~##~~~~~~#R==RRRRR~~~~RRRRRRRRR==R#~~##==##~~##~~~~~~##~~~
~~~~~~~~~~~~~~~##~~~~~~#R==RRRRR~~~~RRRRRRRRR==R#~~##==##~~##~~~~~~##~~~
~~~#RRRR####RRRR#~~######==#########RRRR#####==##~~##==##~~#RRRR####RRRR
~~~~RRRR~~~~RRRR~~~~~~~##=================~##==========##~~~RRRR~~~~RRRR
~~~~RRRR~~~~RRRR~~~~~~~##==================##==========##~~~RRRR~~~~RRRR
~~~~RRRR~~~~RRRR~~~~~~~##~~~~~~~~~~~RRRR~==##~~~~~~~~~~##~~~RRRR~~~~RRRR
#############################~~##########==#############################
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
<!-- /map -->

Crossing 3 (East switchbacks):

<!-- map Zones/Zone6@6/c3 -->
```text
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~
RRRR#~~#RRRR#############~~#####RRRR#~~#RRRR#####~~##~~##~~##==#####RRRR
RRRR#~~#RRRR~~~~~~~~~~~##~~##~~~RRRR#~~~RRRR~~~##~~##~~##~~##=====~#RRRR
RRRR#~~#RRRR~~~~~~~~~~~##~~##~~~RRRR#~~~RRRR~~~##~~##~~##~~##======#RRRR
RRRR#~~#RRRR~~~~~~~~~~~##~~##~~~RRRR#~~~RRRR~~~##~~##~~##~~##~~~~==#RRRR
####RRRRRRRR#~~######~~######~~#RRRRRRRRRRRR#~~##############~~##==##~~~
~~~~RRRRRRRR#~~##~~~~~~~~~~~~~~#RRRRRRRRRRRR#~~##~~##~========~##==##~~~
~~~~RRRRRRRR#~~##~~~~~~~~~~~~~~#RRRRRRRRRRRR#~~##~~##==========##==##~~~
~~~~RRRRRRRR#~~##~~~~~~~~~~~~~~#RRRRRRRRRRRR#~~##~~##==~~~~~~==##==##~~~
~~~##########~~##~~##########~~##~~######~~##~~##~~##==######==##==#RRRR
~~~~~~~~~~~~~~~##~~~~~~##~~##~~~~~~##~~~~~~##~~~~~~##==##~=====##==#RRRR
~~~~~~~~~~~~~~~##~~~~~~##~~##~~~~~~##~~~~~~##~~~~~~##==##======##==#RRRR
~~~~~~~~~~~~~~~##~~~~~~##~~##~~~~~~##~~~~~~##~~~~~~##==##==~~~~##==#RRRR
~~~#RRRRRRRR#~~######~~##~~##~~##~~######~~##~~##~~##==##==##~~~#==##~~~
~~~~RRRRRRRR#~~~~~~##~~##~~~~~~##~~~~~~##~~##~~##~~##==##==##~~~~==~~~~~
~~~~RRRRRRRR#~~~~~~##~~##~~~~~~##~~~~~~##~~##~~##~~##==##==##~~~~==~~~~~
~~~~RRRRRRRR#~~~~~~##~~##~~~~~~##~~~~~~##~~##~~##~~##==##==##~~~~==~~~~~
########RRRR####RRRR#~~#####RRRRRRRR####RRRR#####~~##==~#==######==##~~~
~~~~~~~~RRRR~~~~RRRR~~~##~====================~##~~##==~~==========##~~~
~~~~~~~~RRRR~~~~RRRR~~~##======================##~~##==~~==========##~~~
~~~~~~~~RRRR~~~~RRRR~~~##==~RRRRRRRR~~~~RRRR~==##~~##==~~~~~~~~~~~~##~~~
#####~~#################R==R#################==######==#################
~~~##~~~~~~~~~~~~~~~~~~#R==R#~~##~~~~~~##~~##==========~~~~##~~~~~~##~~~
~~~##~~~~~~~~~~~~~~~~~~#R==R#~~##~~~~~~##~~##==========~~~~##~~~~~~##~~~
~~~##~~~~~~~~~~~~~~~~~~#R==R#~~##~~~~~~##~~##~~~~~~~~~~~~~~##~~~~~~##~~~
~~~##~~##########~~#####R==R#~~##~~~~~~##~~#RRRR#########~~##~~~~~~##~~~
~~~~~~~##~~~~~~##~~~~~~#R==R#~~~~~~~~~~~~~~#RRRR#~~~~~~##~~~~~~~~~~~~~~~
~~~~~~~##~~~~~~##~~~~~~#R==R#~~~~~~~~~~~~~~#RRRR#~~~~~~##~~~~~~~~~~~~~~~
~~~~~~~##~~~~~~##~~~~~~#R==R#~~~~~~~~~~~~~~#RRRR#~~~~~~##~~~~~~~~~~~~~~~
~~~######~~#RRRR#####~~##==##~~##~~~~~~##~~#RRRR#~~######~~##~~~~~~##~~~
~~~~~~~##~~#RRRR#~~##~~~~==##~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~##~~~~~~##~~~
~~~~~~~##~~#RRRR#~~##~~~~==##~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~##~~~~~~##~~~
~~~~~~~##~~#RRRR#~~##~~~~==##~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~##~~~~~~##~~~
#####~~##~~##~~##~~######==#RRRR#~~#####RRRR#~~######~~#################
~~~~~~~~~~~##~~##~~~~~~##=============~~RRRR#~====~##~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~##~~##~~~~~~##==============~RRRR#======##~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~##~~##~~~~~~##~~~RRRR~~~~~==~RRRR#==~~==##~~~~~~~~~~~~~~~~~~~
RRRR####RRRRRRRR#####~~##############==#####R==R#==##########~~#########
RRRR~~~~RRRRRRRR#~~~~~~##~=============~~~~#R==R#=====~##~~~~~~~~~~~~~~~
RRRR~~~~RRRRRRRR#~~~~~~##==============~~~~#R==R#======##~~~~~~~~~~~~~~~
RRRR~~~~RRRRRRRR#~~~~~~##==~~~~~~~~~~~~~~~~#R==R#~~~~==##~~~~~~~~~~~~~~~
RRRR#####~~##~~######~~#R==R#########~~#####R==R#####==##~~######~~#####
RRRR#~~~~~~~~~~~~~~~~~~#R==R#~~~~~~~~~~~~~~#R==R#~=====##~~##~~~~~~~~~~~
RRRR#~~~~~~~~~~~~~~~~~~#R==R#~~~~~~~~~~~~~~#R==R#======##~~##~~~~~~~~~~~
RRRR#~~~~~~~~~~~~~~~~~~#R==R#~~~~~~~~~~~~~~#R==R#==~~~~##~~##~~~~~~~~~~~
RRRR####RRRR#########~~##==#RRRR####RRRRRRRR#==##==##########~~~~~~##~~~
RRRR~~~~RRRR#~~##~~~~~~##==#RRRR~~~~RRRRRRRR#==##=========~##~~~~~~##~~~
RRRR~~~~RRRR#~~##~~~~~~##==#RRRR~~~~RRRRRRRR#==##==========##~~~~~~##~~~
RRRR~~~~RRRR#~~##~~~~~~##==#RRRR~~~~RRRRRRRR#==##~~~~~~~~==##~~~~~~##~~~
#############~~##~~#####R==RRRRR####RRRRRRRRR==R#~~######==##~~~~~~##~~~
~~~##~~~~~~~~~~~~~~##~~#R==RRRRR~~~~RRRRRRRRR==R#~~##~~##==##~~~~~~##~~~
~~~##~~~~~~~~~~~~~~##~~#R==RRRRR~~~~RRRRRRRRR==R#~~##~~##==##~~~~~~##~~~
~~~##~~~~~~~~~~~~~~##~~#R==RRRRR~~~~RRRRRRRRR==R#~~##~~##==##~~~~~~##~~~
~~~##~~#RRRR#########~~##==#RRRRRRRR####RRRR#==##~~##~~##==#############
~~~~~~~~RRRR~~~~~~~~~~~##======================##~~~~~~##=========~~~~~~
~~~~~~~~RRRR~~~~~~~~~~~##======================##~~~~~~##==========~~~~~
~~~~~~~~RRRR~~~~~~~~~~~##~~~RRRRRRRR~~~~RRRR~~~##~~~~~~##~~~~~~~~==~~~~~
#################~~~~~~##########################~~##########~~~~==#####
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~
```
<!-- /map -->

Crossing 4 (Long cross):

<!-- map Zones/Zone6@6/c4 -->
```text
~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#########==##########~~#####RRRRRRRR####RRRR#####~~##########~~#########
~~~~~~~~~=====~##~~##~~##~====================~##~~##~~~~~~##~~~~~~~~~~~
~~~~~~~~~======##~~##~~##======================##~~##~~~~~~##~~~~~~~~~~~
~~~~~~~~~~~~~==##~~##~~##==~RRRRRRRR~~~~RRRR~==##~~##~~~~~~##~~~~~~~~~~~
####RRRRRRRR#==##~~######==#####RRRRRRRRRRRR#==######~~##~~##########~~~
~~~~RRRRRRRR#==##~=========##~~#RRRRRRRRRRRR#==##~====~##~~~~~~##~~##~~~
~~~~RRRRRRRR#==##==========##~~#RRRRRRRRRRRR#==##======##~~~~~~##~~##~~~
~~~~RRRRRRRR#==##==~~~~~~~~##~~#RRRRRRRRRRRR#==##==~~==##~~~~~~##~~##~~~
~~~##########==##==##~~######~~##~~######~~##==##==#R==R#########~~##~~~
~~~~~~~~~~~~~======##~~##~====~~~~~##~~~~~~##======#R==R#~~~~~~##~~~~~~~
~~~~~~~~~~~~~======##~~##======~~~~##~~~~~~##======#R==R#~~~~~~##~~~~~~~
~~~~~~~~~~~~~~~~~~~##~~##==~~==~~~~##~~~~~~##~~~~~~#R==R#~~~~~~##~~~~~~~
~~~#RRRRRRRR#########~~#R==R#==##~~######~~######~~##==##~~##~~##~~#####
~~~~RRRRRRRR#~~~~~~##~~#R==R#==##~~~~~~##~~##~~##~~##==##~~##~~##~~##~~~
~~~~RRRRRRRR#~~~~~~##~~#R==R#==##~~~~~~##~~##~~##~~##==##~~##~~##~~##~~~
~~~~RRRRRRRR#~~~~~~##~~#R==R#==##~~~~~~##~~##~~##~~##==##~~##~~##~~##~~~
#############~~######~~#R==R#==#RRRR####RRRR#~~##~~#R==R#~~##~~##~~##~~~
~~~~~~~~~~~~~~~~~~~~~~~#R==R#=================~##~~#R==R#~~##~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~#R==R#==================##~~#R==R#~~##~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~#R==R#~~~RRRR~~~~RRRR~==##~~#R==R#~~##~~~~~~~~~~~
RRRR#~~#################R==R#################==######==#################
RRRR#~~~~~~##~========~#R==R#~~##~~~~~~##~~##==========##~~##~~~~~~##~~~
RRRR#~~~~~~##==========#R==R#~~##~~~~~~##~~##==========##~~##~~~~~~##~~~
RRRR#~~~~~~##==~~~~~~==#R==R#~~##~~~~~~##~~##~~~~~~~~~~##~~##~~~~~~##~~~
~~~######~~##==######==#R==R#~~##~~~~~~##~~#RRRR#########~~##~~~~~~##~~~
~~~##~~~~~~##==##~~##==#R==R#~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~~~~~~~~~~~~~~
~~~##~~~~~~##==##~~##==#R==R#~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~~~~~~~~~~~~~~
~~~##~~~~~~##==##~~##==#R==R#~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~~~~~~~~~~~~~~
RRRR#~~######==##~~##==##==##~~##~~~~~~##~~#RRRR#~~##~~######~~~~~~##~~~
RRRR#~~~~~~##==##~~##======##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~~~~~##~~~
RRRR#~~~~~~##==##~~##======##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~~~~~##~~~
RRRR#~~~~~~##==##~~##~~~~~~##~~~~~~~~~~~~~~#RRRR#~~##~~~~~~##~~~~~~##~~~
~~~######~~##==~#~~##~~#####RRRR#~~#####RRRR#~~######~~##~~#############
~~~~~~~~~~~##==~~~~~~~~##~~~RRRR~~~##~============~##~~##~~~~~~~~~~~~~~~
~~~~~~~~~~~##==~~~~~~~~##~~~RRRR~~~##==============##~~##~~~~~~~~~~~~~~~
~~~~~~~~~~~##==~~~~~~~~##~~~RRRR~~~##==~RRRR~~~~~==##~~##~~~~~~~~~~~~~~~
RRRR####RRRR#==######~~##~~##########==##########==##########~~#########
RRRR~~~~RRRR#==~~~~~~~~##~=============##~~~~~~##=====~##~~~~~~~~~~~~~~~
RRRR~~~~RRRR#==~~~~~~~~##==============##~~~~~~##======##~~~~~~~~~~~~~~~
RRRR~~~~RRRR#==~~~~~~~~##==~~~~~~~~~~~~##~~~~~~##~~~~==##~~~~~~~~~~~~~~~
RRRR#####~~##==##########==##########~~#####RRRR#####==##~~######~~#####
RRRR#~~~~~~~~==============##~~~~~~~~~~~~~~#RRRR#~~##==##~~##~~~~~~~~~~~
RRRR#~~~~~~~~==============##~~~~~~~~~~~~~~#RRRR#~~##==##~~##~~~~~~~~~~~
RRRR#~~~~~~~~~~~~~~~~~~~~~~##~~~~~~~~~~~~~~#RRRR#~~##==##~~##~~~~~~~~~~~
RRRR####RRRR####~~~~########RRRR####RRRRRRRR#~~##~~##==##~~##~~~~~~##~~~
RRRR~~~~RRRR#~~~~~~~~~~##~~#RRRR~~~~RRRRRRRR#~~~~~~~~==~~~~##~~~~~~##~~~
RRRR~~~~RRRR#~~~~~~~~~~##~~#RRRR~~~~RRRRRRRR#~~~~~~~~==~~~~##~~~~~~##~~~
RRRR~~~~RRRR#~~~~~~~~~~##~~#RRRR~~~~RRRRRRRR#~~~~~~~~==~~~~##~~~~~~##~~~
#############~~##~~######~~#RRRR####RRRRRRRRRRRR#####==##~~##~~~~~~##~~~
~~~~~~~~~~~~~~~##~~##~~~~~~#RRRR~~~~RRRRRRRRRRRR#~~##==##~~##~~~~~~##~~~
~~~~~~~~~~~~~~~##~~##~~~~~~#RRRR~~~~RRRRRRRRRRRR#~~##==##~~##~~~~~~##~~~
~~~~~~~~~~~~~~~##~~##~~~~~~#RRRR~~~~RRRRRRRRRRRR#~~##==##~~##~~~~~~##~~~
~~~##################~~##~~#####RRRR#########~~##~~##==##~~#RRRR####RRRR
~~~~~~~~~~~~~~~##~~~~~~##~~~~~~~RRRR~~~~~~~~~~~~~~~##==##~~~RRRR~~~~RRRR
~~~~~~~~~~~~~~~##~~~~~~##~~~~~~~RRRR~~~~~~~~~~~~~~~##==##~~~RRRR~~~~RRRR
~~~~~~~~~~~~~~~##~~~~~~##~~~~~~~RRRR~~~~~~~~~~~~~~~##==##~~~RRRR~~~~RRRR
#####~~##########~~##########~~##########~~##########==#################
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

Crossing 5 (Backtrack):

<!-- map Zones/Zone6@6/c5 -->
```text
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~
RRRRRRRR#~~#RRRRRRRR#~~#####RRRRRRRR####RRRR#####~~##~~##~~##==#########
RRRRRRRR#~~#RRRRRRRR#~~##~====================~##~~##~~##~~##==##~~~~~~~
RRRRRRRR#~~#RRRRRRRR#~~##======================##~~##~~##~~##==##~~~~~~~
RRRRRRRR#~~#RRRRRRRR#~~##==~RRRRRRRR~~~~RRRR~==##~~##~~##~~##==##~~~~~~~
####RRRRRRRR#############==#####RRRRRRRRRRRR#==##############==##~~##~~~
~~~~RRRRRRRR#~=============##~~#RRRRRRRRRRRR#==##~~~~~~~~~~##==##~~##~~~
~~~~RRRRRRRR#==============##~~#RRRRRRRRRRRR#==##~~~~~~~~~~##==##~~##~~~
~~~~RRRRRRRR#==~~~~~~~~~~~~##~~#RRRRRRRRRRRR#==##~~~~~~~~~~##==##~~##~~~
~~~##########==######~~######~~##~~######~~##==##########~~##==##~~##~~~
~~~~~~~~~~~~~==##~~##~~##~~~~~~~~~~##~~~~~~##=========~##~~~~==~~~~##~~~
~~~~~~~~~~~~~==##~~##~~##~~~~~~~~~~##~~~~~~##==========##~~~~==~~~~##~~~
~~~~~~~~~~~~~==##~~##~~##~~~~~~~~~~##~~~~~~##~~~~~~~~==##~~~~==~~~~##~~~
~~~#RRRRRRRR#==##~~##~~##~~##~~##~~######~~##########==######==######~~~
~~~~RRRRRRRR#==##~~~~~~##~~##~~##~~~~~~##~~##~~##~~##=====~##==##~~~~~~~
~~~~RRRRRRRR#==##~~~~~~##~~##~~##~~~~~~##~~##~~##~~##======##==##~~~~~~~
~~~~RRRRRRRR#==##~~~~~~##~~##~~##~~~~~~##~~##~~##~~##~~~~==##==##~~~~~~~
RRRR####RRRR#==######~~######~~#RRRR####RRRR#~~##~~######==##==##~~#####
RRRR~~~~RRRR~=====~##~~~~~~~~~~~RRRR~~~~RRRR~~~##~~~~~~##======##~~~~~~~
RRRR~~~~RRRR~======##~~~~~~~~~~~RRRR~~~~RRRR~~~##~~~~~~##======##~~~~~~~
RRRR~~~~RRRR~~~~~==##~~~~~~~~~~~RRRR~~~~RRRR~~~##~~~~~~##~~~~~~##~~~~~~~
#################==#####RRRR#################~~######~~#################
~~~##~=============##~~#RRRR#~~##~~~~~~##~~##~~~~~~##~~~~~~##~~~~~~##~~~
~~~##==============##~~#RRRR#~~##~~~~~~##~~##~~~~~~##~~~~~~##~~~~~~##~~~
~~~##==~~~~~~~~~~~~##~~#RRRR#~~##~~~~~~##~~##~~~~~~##~~~~~~##~~~~~~##~~~
~~~##==##############~~#RRRR#~~##~~~~~~##~~#RRRR#~~######~~##~~~~~~##~~~
~~~##==##~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~~~~~#RRRR#~~~~~~##~~~~~~~~~~~~~~~
~~~##==##~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~~~~~#RRRR#~~~~~~##~~~~~~~~~~~~~~~
~~~##==##~~~~~~~~~~~~~~#RRRR#~~~~~~~~~~~~~~#RRRR#~~~~~~##~~~~~~~~~~~~~~~
~~~##==##~~##~~##############~~##~~~~~~##~~#RRRR#####~~##~~##~~~~~~##~~~
~~~~~==~~~~##~~##~========~##~~~~~~~~~~~~~~#RRRR#~~~~~~##~~##~~~~~~##~~~
~~~~~==~~~~##~~##==========##~~~~~~~~~~~~~~#RRRR#~~~~~~##~~##~~~~~~##~~~
~~~~~==~~~~##~~##==~~~~~~==##~~~~~~~~~~~~~~#RRRR#~~~~~~##~~##~~~~~~##~~~
~~~##==##########==######==#RRRR#~~#####RRRR#~~##~~######~~#############
~~~##=========~##=====~##==~RRRR~~~~~~~~RRRR~~~~~~~##~~~~~~~~~~~~~~~~~~~
~~~##==========##======##==~RRRR~~~~~~~~RRRR~~~~~~~##~~~~~~~~~~~~~~~~~~~
~~~##~~~~~~~~==##~~~~==##==~RRRR~~~~~~~~RRRR~~~~~~~##~~~~~~~~~~~~~~~~~~~
RRRR####RRRR#==######==##==#RRRRRRRR####RRRR#####~~##########~~#########
RRRR~~~~RRRR#=====~##==##=====================~##~~##~~~~~~~~~~~~~~~~~~~
RRRR~~~~RRRR#======##==##======================##~~##~~~~~~~~~~~~~~~~~~~
RRRR~~~~RRRR#~~~~==##==##~~~RRRRRRRR~~~~RRRR~==##~~##~~~~~~~~~~~~~~~~~~~
RRRR#####~~##~~##==~#==##############~~#####R==R#~~######~~######~~#####
RRRR#~~~~~~~~~~##==~~==~~~~##~~~~~~~~~~~~~~#R==R#~~~~~~~~~~##~~~~~~~~~~~
RRRR#~~~~~~~~~~##==~~==~~~~##~~~~~~~~~~~~~~#R==R#~~~~~~~~~~##~~~~~~~~~~~
RRRR#~~~~~~~~~~##==~~==~~~~##~~~~~~~~~~~~~~#R==R#~~~~~~~~~~##~~~~~~~~~~~
RRRR####RRRR#####==##==##~~#RRRR####RRRRRRRR#==##########~~##~~~~~~##~~~
RRRR~~~~RRRR#~=====##==##~~#RRRR~~~~RRRRRRRR#==##~~~~~~##~~##~~~~~~##~~~
RRRR~~~~RRRR#======##==##~~#RRRR~~~~RRRRRRRR#==##~~~~~~##~~##~~~~~~##~~~
RRRR~~~~RRRR#==~~~~##==##~~#RRRR~~~~RRRRRRRR#==##~~~~~~##~~##~~~~~~##~~~
#############==######==##~~#RRRR####RRRRRRRRR==R#~~######~~##~~~~~~##~~~
~~~~~~~~~~~##=====~##==##~~#RRRR~~~~RRRRRRRRR==R#~~##~~~~~~##~~~~~~##~~~
~~~~~~~~~~~##======##==##~~#RRRR~~~~RRRRRRRRR==R#~~##~~~~~~##~~~~~~##~~~
~~~~~~~~~~~##~~~~==##==##~~#RRRR~~~~RRRRRRRRR==R#~~##~~~~~~##~~~~~~##~~~
~~~######~~##~~##==##==##~~#RRRR####RRRR#####==##~~##~~#RRRRRRRR####RRRR
~~~~~~~##~~~~~~##======##~~~RRRR~~~~RRRR#~=====##~~~~~~~RRRRRRRR~~~~RRRR
~~~~~~~##~~~~~~##======##~~~RRRR~~~~RRRR#======##~~~~~~~RRRRRRRR~~~~RRRR
~~~~~~~##~~~~~~##~~~~~~##~~~RRRR~~~~RRRR#==~~~~##~~~~~~~RRRRRRRR~~~~RRRR
#########################################==~~~~#########################
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
<!-- /map -->

## The frame

Always there, whichever crossing and rooms roll:

- **The Long Walls**: two walls the full depth of the Reach at x -120 and x 120, and two the full width at z 212 and z 372. They cut the Reach into nine wards (north-west, gate, north-east; west, hall, east; south-west, sea, south-east), 240 by 200 studs each, and carry between them 25 gate candidates (5 or 6 on each wall). Each ward has its own look (below), and its own rock: Slate in the gate, east and south-west wards, Limestone in the west and sea wards, Basalt elsewhere.
- **The ends**: the frame draws no wall across the top (z 12) or the bottom (z 572). Each crossing draws its own, from the old bars with the long runs cut by a niche (a lane opened to the edge and walled off from the maze: a dead end) or an opening; the longest unbroken run is now about 6 lanes, not the whole width. Where a bar still runs long (crossing 2 and 5, bottom) the lane behind it is the route itself, and opening it would have shortened the way across.
- **The seven side slots**, each a shell of wall with one door, with a room inside it (below).
- **The Drowned Hall and the Sea Hall**: two big chambers in the middle and sea wards, ringed by roofed galleries wherever a crossing's walls hold a roof up. Eight pools (3 deep, muddy floors) lie along them: the lowest ground in the middle of the Reach.
- **Ground**: patches of mud and drowned silt (Mud, Limestone, with worn edges) over about a quarter of the lanes, the same every tide.

## Roofs

Every roof is an exact rectangle on the lane grid, its edges on the walls under it. A cell is roofed only if two or more of its sides are walls (a bend, a straight, a dead end: never an open junction), and a gallery's roof is broken by light shafts, every third cell open to the sky. About 17 to 19% of the Reach is under a roof (the maps' `R`), down from about half; the side rooms are mostly open to the sky, with at most four roofed cells.

## The five crossings

Each shuts the gates it doesn't use, draws every other wall of the maze, roofs some straights, sinks a few lanes and pools, and winds a cart ramp (14 wide) along its way through. Each has a few false doors and niches at the edges, and rubble doorways (4 high, 20 wide, worn): a scramble on foot that cuts a bend, too steep for a cart. Each crossing has its **tell** at its way in, so a regular knows which rolled before committing:

1. **West stair** (in at x -260; an anchor and its chain, kelp). Down the west ward, through the south-west ward and back up under the gate ward and hall ward, then down the sea ward: out at the south-west corner (x -300). Glooms: the west gallery (x -220, z 252 to 412) and the hall's east side (x 100, z 212 to 372).
2. **Hall gallery** (in at x 260; two sets of a hull's ribs and a timber). Through the gate ward and round the Drowned Hall by its gallery, down the east side and back through the sea ward: out at x 60. Glooms: the hall's north gallery (z 192) and the sea gallery (x -100, z 372 to 532).
3. **East switchbacks** (in at x 260; an arch of bones). Down the east ward; the ramp climbs back through the gate ward and hall ward before the sea ward and the south-east: out at x 300. Glooms: the hall's north gallery and the south gallery (z 552).
4. **Long cross** (in at x -260; a pair of lantern posts). Across the Reach, west to east, to leave by the south-east ward after a loop through the sea ward. Glooms: the top gallery (z 32) and the west gallery (x -220).
5. **Backtrack** (in at x 260; dead coral, urchins and a smashed crate). West along the top, down the whole west side, then back east through the hall ward and the sea ward: out at x 60. Glooms: the top gallery and the sea hall's north gallery (z 392).

## The side slots

Seven slots, each with a door onto the frame, rolled each tide. Every room keeps the door open and joins the frame, so any crossing reaches any room. Each room is drawn differently (walls and rubble between its lanes, its own shapes and roof cells), the best find (Weight 6) is in its furthest dead end, and its door has a **tell** by its kind: dead coral and pebbles for the caves and cellars, kelp for the pools, a crate and urchins for the scrambles, an anchor and chain for the rings, timbers and chain for the courts, bones and starfish for the sinking flats, weed for the weed hall, timbers, a crate and rubble for the collapsed rooms, bones for the vaults, hull ribs and chain for the gallery.

| Slot | Where | Size | Rooms |
|---|---|---|---|
| West cave | x -360, z 52 (cliff), door east | 120 x 120 | Comb of caves (two roofed dead-end caves), Drowned pool (a muddy pool between two dead ends), Boulder scramble (a boulder field, the find behind a wall) |
| Gatehouse yard | x -40, z 52, door west | 120 x 120 | Gatehouse ring (a roofed ring round a vault), Pillar court (open, four free columns, two niches), Gatehouse cellar (a roofed spiral to a vault) |
| East cellar | x 240, z 212 (cliff), door west | 120 x 120 | Sinking flats (open sand with two patches of sinking sand to weave round, two niches), Flooded cellar (a roofed row and a pool), Weed hall (a weed channel and weed floor) |
| Drowned hall | x -80, z 212, door south | 160 x 120 | Flooded hall (columns and two pools), Collapsed hall (boulders, a roofed passage with falling rock), Pillar gallery (columns, the Gloom lying at its far dead end, a lantern and glowing weed), Dead-end vault (a long roofed passage, a rock fall) |
| Low west vault | x -360, z 372 (cliff), door east | 120 x 120 | Tunnel ring (a roofed ring round an open vault), Dead-end cave (roofed dead ends), Boulder scramble (the find behind a rubble pile) |
| Sea vault | x -80, z 412, door north | 160 x 120 | Drowned gallery (a long serpentine, roofed with light shafts), Flooded vault (columns, two pools), Collapsed vault (boulders, rubble, a rock fall before the find), Ring and vault (a roofed ring, a vault) |
| East deeps | x 240, z 412 (cliff), door north | 120 x 120 | Flooded pocket (a pool and a dead end along the cliff), Dead-end cave (a long roofed way round), Boulder scramble (boulders, the find in a corner) |

## Dangers

Every danger has its tell, sits where it can be learned (the same spot in its crossing or room) and leaves a way round or a safe moment.

- **Sinking sand** (radius 9, on dark mud with a bone and a starfish by it): in the lane that leads to a dead end's loot, two to a crossing (never on the ramp); and two patches in the Sinking flats, placed so the straight line between them is clear. Cross it moving: it swallows you only if you stand in it.
- **Falling rock**: in the roofed cells along the cart route (up to three a crossing, every third one), in the middle of the lane on a floor of pebbles and timber; the lane is wider than its reach, and the rock keeps its rhythm. Also in the Collapsed hall, the Collapsed vault and the Dead-end vault, in the passage before the find.
- **Undertow**: along every channel the crossings sink (the same path and width), while the sea covers it. The channels lie off the ramp.
- **The Gloom**: two to a crossing, each drifting back and forth along a straight gallery of the way through (the galleries are listed with the crossings), with a lantern post at each end and a trail of glowing weed and shells between them: wait in the light until it drifts off, or follow the trail through. A third lies still in the Pillar gallery's dead end, with a lantern post at the door and glowing shells at the find.

## Decor

Each ward has a theme: a kelp forest (north-west), a wreck yard (gate ward: ribs, timbers, chain, crates, an anchor), a bone field (north-east), coral gardens (west), the halls (ribs, timbers, crates), weed beds (east), an anchorage (south-west), a sunken grove (sea ward) and a graveyard (south-east); barnacles crust the tops of the long walls. Each room kind has its own fill, and the dark ones (caves, vaults, rings) a glow of shells by the best find. Walls and roofs clear props away, and the Gloom's wards are the lantern posts, glowing weed and shells above.

## Shortcuts

The rubble doorways are foot-only; the cart ramp has to take the long way round. The map tool counts 5 of 5 starts faster on foot.

## Flood order

Everything lies below the mid-tide line, so the sea comes in from the bottom and the Reach fills from the sea wards up. The two pools in the Sea Gallery (x +-60, z 552) go first, as the waterline passes Z 3604, then the sunk lanes and pools of the south wards (Z 3526 to 3404), then the middle of the Reach round the Drowned Hall (Z 3325 to 3246), and last the north wards (Z 3198 to 3084). The Test Range finds 82% of the zone under water (69% too deep to stand in) with the waterline at the top of the zone (Z 3040) and 37% (28% too deep) at its middle (Z 3344); the share of tunnels under water is 78 to 82% at the top and 36 to 40% at the middle. Coming back up, the lower wards are cut off first, and the roofed galleries are the first places you cannot shelter.

<!-- floods Zones/Zone6@6 -->
Hollow at x -60, z 552: the sea reaches it when the waterline is below Z 3604
Hollow at x 60, z 552: the sea reaches it when the waterline is below Z 3604
Channel at x -220, z 552: the sea reaches it when the waterline is below Z 3598
Hollow at x -180, z 512: the sea reaches it when the waterline is below Z 3552
Hollow at x 100, z 472: the sea reaches it when the waterline is below Z 3524
Hollow at x -100, z 472: the sea reaches it when the waterline is below Z 3512
Hollow at x 280, z 492: the sea reaches it when the waterline is below Z 3444
Hollow at x 60, z 352: the sea reaches it when the waterline is below Z 3404
Hollow at x 300, z 352: the sea reaches it when the waterline is below Z 3404
Channel at x 300, z 352: the sea reaches it when the waterline is below Z 3404
Hollow at x -60, z 352: the sea reaches it when the waterline is below Z 3403
Hollow at x 20, z 272: the sea reaches it when the waterline is below Z 3328
Hollow at x -20, z 272: the sea reaches it when the waterline is below Z 3328
Hollow at x 100, z 272: the sea reaches it when the waterline is below Z 3312
Hollow at x -100, z 272: the sea reaches it when the waterline is below Z 3244
Hollow at x -300, z 272: the sea reaches it when the waterline is below Z 3244
Channel at x -100, z 272: the sea reaches it when the waterline is below Z 3244
Hollow at x -140, z 232: the sea reaches it when the waterline is below Z 3244
Hollow at x -260, z 312: the sea reaches it when the waterline is below Z 3244
Channel at x 180, z 152: the sea reaches it when the waterline is below Z 3198
Hollow at x 140, z 72: the sea reaches it when the waterline is below Z 3086
Hollow at x -340, z 32: the sea reaches it when the waterline is below Z 3078
Channel at x -340, z 32: the sea reaches it when the waterline is below Z 3078
Hollow at x -60, z 152: the sea reaches it when the waterline is below Z 3044
<!-- /floods -->

## What a player sees from the top

Nothing past the first wall: the map tool puts 100% of the lower half out of sight.

## Measured times

- Map tool (4-stud steps along X and Z only, so it over-counts diagonals): about 87, 87, 90, 95 and 99 s for crossings 1 to 5 (target 85 s); 5 of 5 shortcut starts faster on foot. The end walls' openings cut one to four lanes off the ways across, which brought crossings 1 to 3 into the range the brief asks for; crossing 5 stays at the old length.
- Test Range (walking the real terrain), fastest way down on foot with the first room of every slot: crossing 1 76 s, crossing 2 77 s, crossing 3 78 s, crossing 4 82 s, crossing 5 88 s (target 85 s); every other room (with crossing 1) measures 76 s.
