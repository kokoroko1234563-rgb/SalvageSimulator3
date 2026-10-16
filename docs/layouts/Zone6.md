# Zone 6: The Drowned Reach

The deepest, slowest ground on the beach, drawn as one 720 x 608 piece. A maze of tall rock walls (24 high, 12 wide) on a 40-stud grid: lanes 28 wide between the walls, a roof over many of the straights, low ground everywhere. Four long walls cut the Reach into nine wards, and each tide the sea rolls one of five **crossings** (which gates stay open, which walls fill the wards, where the tunnels and the cart ramp go) and one room for each of seven **side slots**. Every crossing is a single winding route with dead ends hung all along it: nothing is a straight line, and from the top you see nothing at all.

The maze is built from pictures in `Zone6.luau`: a text grid where `+` is a node, `--` or `|` a wall, `==` or `!` rubble, and a blank an opening. A post stands on every node a wall touches, so walls that meet end to end leave no crack (a crack one stud wide is a way through for a player, and the Test Range found one).

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat, `R` under a roof. The whole Reach lies below the mid-tide line, so almost all of it shows as `~`; the walls and roofs are what the maps are for. The first crossing with the first room of every slot:

<!-- map Zones/Zone6@6 -->
```text
~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#########==#################RRRRRRRRRRRRRRRR############################
~~~~~~~~~=============~##~~RRRRRRRRRRRRRRRRRR~~##~~~~~~##~~~~~~##~~~~~~~
~~~~~~~~~==============##~~RRRRRRRRRRRRRRRRRR~~##~~~~~~##~~~~~~##~~~~~~~
~~~~~~~~~~~~~~~~~~~~~==##~~~RRRRRRRRRRRRRRRR~~~##~~~~~~##~~~~~~##~~~~~~~
RRRRRRRRRRRR#########==##~~##RRRRRRRRRRRRRRR#~~##~~######~~##~~##~~##~~~
RRRRRRRRRRRRR~~~~~~##==##~~##~~RRRRRRRRRRRRRR~~##~~~~~~~~~~##~~~~~~##~~~
RRRRRRRRRRRRR~~~~~~##==##~~##~~RRRRRRRRRRRRRR~~##~~~~~~~~~~##~~~~~~##~~~
RRRRRRRRRRRR#~~~~~~##==##~~##~~#RRRRRRRRRRRR#~~##~~~~~~~~~~##~~~~~~##~~~
RRRRRRRR#RR##~~##~~##==##~~##~~##RR##RR#RRRR#~~#RRRRRRRRRRRRRRRRRRRR#~~~
RRRRRRRRR~~~~~~##~~##==##~~##~~~~~~##~~RRRRRR~~RRRRRRRRRRRRRRRRRRRRRR~~~
RRRRRRRRR~~~~~~##~~##==##~~##~~~~~~##~~RRRRRR~~RRRRRRRRRRRRRRRRRRRRRR~~~
RRRRRRRR~~~~~~~##~~##==##~~##~~~~~~##~~#RRRR#~~~RRRRRRRRRRRRRRRRRRRR~~~~
RRRRRRRRRRRR#~~######==##~~##~~#RRRRRRRRRRRR#~~##RRRRRRRRRRRRRRRRRR##~~~
RRRRRRRRRRRRR~=========##~~~~~~RRRRRRRRRRRRRR~~##~~~~~~~~~~##~~~~~~~~~~~
RRRRRRRRRRRRR==========##~~~~~~RRRRRRRRRRRRRR~~##~~~~~~~~~~##~~~~~~~~~~~
RRRRRRRRRRRR#==~~~~~~~~##~~~~~~#RRRRRRRRRRRR#~~##~~~~~~~~~~##~~~~~~~~~~~
#RR##RR##RR##==######~~#####RRRRRRRRRRRRRRRR#~~##~~##########~~#########
~~~~~~=========##~~~~~~##~====================~##~~~~~~~~~~~~~~~~~~~~~~~
~~~~~==========##~~~~~~##======================##~~~~~~~~~~~~~~~~~~~~~~~
~~~~~==~~~~~~~~##~~~~~~##==~RRRRRRRRRRRRRRRR~==##~~~~~~~~~~~~~~~~~~~~~~~
#####==##########~~#####R==RRRRRRRRRRRRRRRR#R==R#####~~#####RRRRRRRRRRRR
~~~##==##~====~##~~~~~~RR==RRRRRR~~~~~~~~~~RR==RR~~##~~~~~~RRRRRRRRRRRRR
~~~##==##======##~~~~~~RR==RRRRRR~~~~~~~~~~RR==RR~~##~~~~~~RRRRRRRRRRRRR
~~~##==##==~~==##~~~~~~RR==RRRRR~~~~~~~~~~~RR==RR~~##~~~~~~#RRRRRRRRRRRR
~~~##==##==##==######~~RR==RRRRR#########~~RR==RR~~######~~##RR#RRRRRRRR
~~~~~==~~==##==##~~~~~~RR==RRRRRR~~##~~~~~~RR==RR~~~~~~~~~~~~~~RRRRRRRRR
~~~~~==~~==##==##~~~~~~RR==RRRRRR~~##~~~~~~RR==RR~~~~~~~~~~~~~~RRRRRRRRR
~~~~~==~~==##==##~~~~~~RR==RRRRR~~~##~~~~~~RR==RR~~~~~~~~~~~~~~#RRRRRRRR
#####==~~==##==##~~####RR==RRRRR#~~##~~####RR==RR~~#########RRRRRRRRRRRR
~~=====~~==##==##~~##~=====RRRRRR~~##~~~~~~RR==RR~~~~~~##~~RRRRRRRRRRRRR
~======~~==##==##~~##======RRRRRR~~##~~~~~~RR==RR~~~~~~##~~RRRRRRRRRRRRR
~==~~~~~~==##==##~~##==RRRRRRRRR#~~##~~~~~~RR==RR~~~~~~##~~#RRRRRRRRRRRR
~==######==##==##~~##==RRRRRRRRRRRRRRRRRRRRRR==RR####~~##~~##RR##RR##RR#
~==========##==~~~~##==RRRRRRRRRRRRRRRRRRRRRR==RR~~~~~~##~~~~~~~~~~~~~~~
~==========##==~~~~##==RRRRRRRRRRRRRRRRRRRRRR==RR~~~~~~##~~~~~~~~~~~~~~~
~~~~~~~~~~~##==~~~~##==#RRRRRRRRRRRRRRRRRRRRR==R#~~~~~~##~~~~~~~~~~~~~~~
RRRRRRRRRRRR#==######==#RRRRRRRRRRRRRRRRRRRRR==R#~~##########~~#########
RRRRRRRRRRRRR==##~=====RRR=====================RR~~~~~~~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRR==##======RR======================RR~~~~~~~~~~~~~~~~~~~~~~~
RRRRRRRRRRRR#==##==~~~~RR==RR~~~~~~~~~~~~~~RRRRRR~~~~~~~~~~~~~~~~~~~~~~~
RRRR#RR##RR##==##==####RR==RRRRRRRRR#~~#RRRRRRRRR########~~#RRRR#~~#####
RRRRR~~##~~~~======##~~RR==RRRRRRRRRR~~RRRRRRRRRR~~##~~~~~~RRRRRR~~~~~~~
RRRRR~~##~~~~======##~~RR==RRRRRRRRRR~~RRRRRRRRRR~~##~~~~~~RRRRRR~~~~~~~
RRRR#~~##~~~~~~~~~~##~~RR==RRRRRRRRR~~~#RRRRRRRRR~~##~~~~~~#RRRR#~~~~~~~
RRRRRRRRRRRR#########~~RR==RRRRRRRRRRRRRRRRRRRRRR~~##~~######RR#####RRRR
RRRRRRRRRRRRR~====~##~~RR==RRRRRRRRRRRRRRRRRRRRRR~~##~~~~~~##~~~~~~RRRRR
RRRRRRRRRRRRR======##~~RR==RRRRRRRRRRRRRRRRRRRRRR~~##~~~~~~##~~~~~~RRRRR
RRRRRRRRRRRR#==~~==##~~RR==RRRRRRRRRRRRRRRRRRRRRR~~##~~~~~~##~~~~~~#RRRR
#RR##RR##RR##==##==##~~RR==RRRRRRRRRRRRRRRRRRRRRR~~######~~#RRRR#~~##RR~
~~~~~~~##~=====##==========RRRRRRRRRRRRRRRRRRRRRR~~~~~~~~~~RRRRRR~~~~~~~
~~~~~~~##======##==========RRRRRRRRRRRRRRRRRRRRRR~~~~~~~~~~RRRRRR~~~~~~~
~~~~~~~##==~~~~##~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~~~~~~~~~#RRRR#~~~~~~~
~~~######==##########~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR########
~~~~~~=====##~~~~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~~~~~
~~~~~======##~~~~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~~~~~
~~~~~==~~~~##~~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~~~~~~
#####==##################RRRRRRRRRRRRRRRRRRRRRR##RRRRRRRRRRRRRR##~~#####
~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
<!-- /map -->

Crossing 2 (Hall gallery):

<!-- map Zones/Zone6@6/c2 -->
```text
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~
RRRRRRRRRRRR####################RRRRRRRRRRRR#################==#########
RRRRRRRRRRRRR~~##~~~~~~##~~##~================~##~=============##~~~~~~~
RRRRRRRRRRRRR~~##~~~~~~##~~##==================##==============##~~~~~~~
RRRRRRRRRRRR~~~##~~~~~~##~~##==~RRRRRRRRRRRR~==##==~~~~~~~~~~~~##~~~~~~~
RRRRRRRRRRRR#~~##~~##~~##~~##==#RRRRRRRRRRRR#==##==######~~######~~#RRRR
RRRRRRRRRRRRR~~~~~~##~~~~~~~~==RRRRRRRRRRRRRR==##==##~~##~~##~~~~~~RRRRR
RRRRRRRRRRRRR~~~~~~##~~~~~~~~==RRRRRRRRRRRRRR==##==##~~##~~##~~~~~~RRRRR
RRRRRRRRRRRR#~~~~~~##~~~~~~~~==#RRRRRRRRRRRR#==##==##~~##~~##~~~~~~RRRRR
RRRRRRRR#RR##~~##########~~##==##RR##RR#RRRR#==##==##~~##~~##~~####RRRRR
RRRRRRRRR~~~~~~~~~~##~~##~~##==~~~~##~~RRRRRR======##~~~~~~##~~~~~~RRRRR
RRRRRRRRR~~~~~~~~~~##~~##~~##==~~~~##~~RRRRRR======##~~~~~~##~~~~~~RRRRR
RRRRRRRR~~~~~~~~~~~##~~##~~##==~~~~##~~#RRRR#~~~~~~##~~~~~~##~~~~~~RRRRR
RRRRRRRRRRRR#####~~##~~######==#RRRRRRRRRRRR#########~~######~~##~~RRRRR
RRRRRRRRRRRRR~~##~~~~~~##~=====RRRRRRRRRRRRRR~~##~~##~~##~~~~~~##~~RRRRR
RRRRRRRRRRRRR~~##~~~~~~##======RRRRRRRRRRRRRR~~##~~##~~##~~~~~~##~~RRRRR
RRRRRRRRRRRR#~~##~~~~~~##==~~~~#RRRRRRRRRRRR#~~##~~##~~##~~~~~~##~~RRRRR
#RR##RR##RR##~~######~~##==#RRRRRRRRRRRRRRRR#~~##~~##~~##########~~RRRRR
~~~~~~~~~~~~~~~~~~~~~~~##=====================~##~~~~~~~~~~~~~~~~~~RRRRR
~~~~~~~~~~~~~~~~~~~~~~~##======================##~~~~~~~~~~~~~~~~~~RRRRR
~~~~~~~~~~~~~~~~~~~~~~~##~~~RRRRRRRRRRRRRRRR~==##~~~~~~~~~~~~~~~~~~#RRRR
#####~~#################RRRRRRRRRRRRRRRRRRR#R==R#####~~#####RRRRRRRRRRRR
~~~~~~~##~~~~~~~~~~~~~~RRRRRRRRRR~~~~~~~~~~RR=====~##~~~~~~RRRRRRRRRRRRR
~~~~~~~##~~~~~~~~~~~~~~RRRRRRRRRR~~~~~~~~~~RR======##~~~~~~RRRRRRRRRRRRR
~~~~~~~##~~~~~~~~~~~~~~RRRRRRRRR~~~~~~~~~~~RRRRRR==##~~~~~~#RRRRRRRRRRRR
~~~######~~##~~########RRRRRRRRR#########~~RRRRRR==######~~##RR#RRRRRRRR
~~~~~~~##~~##~~##~~~~~~RRRRRRRRRR~~##~~~~~~RRRRRR==##~~~~~~~~~~RRRRRRRRR
~~~~~~~##~~##~~##~~~~~~RRRRRRRRRR~~##~~~~~~RRRRRR==##~~~~~~~~~~RRRRRRRRR
~~~~~~~##~~##~~##~~~~~~RRRRRRRRR~~~##~~~~~~RRRRRR==##~~~~~~~~~~#RRRRRRRR
#####~~######~~##~~##~~RRRRRRRRR#~~##~~####RRRRRR==#########RRRRRRRRRRRR
~~~##~~~~~~##~~~~~~##~~RRRRRRRRRR~~##~~~~~~RRRRRR=========~RRRRRRRRRRRRR
~~~##~~~~~~##~~~~~~##~~RRRRRRRRRR~~##~~~~~~RRRRRR==========RRRRRRRRRRRRR
~~~##~~~~~~##~~~~~~##~~RRRRRRRRR#~~##~~~~~~RRRRRR~~~~~~~~==#RRRRRRRRRRRR
~~~######~~##########~~RRRRRRRRRRRRRRRRRRRRRRRRRR########==##RR##RR##RR#
~~~~~~~~~~~~~~~~~~~~~~~RRR====================RRR~=========##~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~RR======================RR==========##~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~#R==RRRRRRRRRRRRRRRRRR==R#==~~~~~~~~##~~~~~~~~~~~
RRRRRRRRRRRR########RRRRR==RRRRRRRRRRRRRRRRRR==R#==##########~~#########
RRRRRRRRRRRRR~~~~~~RRRRRR==RRRRRRRRRRRRRRRRRR==RR==##~~~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRR~~~~~~RRRRRR==RRRRRRRRRRRRRRRRRR==RR==##~~~~~~~~~~~~~~~~~~~
RRRRRRRRRRRR#~~~~~~RRRRRR==RRRRRRRRRRRRRRRRRR==RR==##~~~~~~~~~~~~~~~~~~~
RRRR#RR##RR##~~##~~RRRRRR==RRRRRRRRRRRRRRRRRR==RR==##~~#####RRRR#~~#####
RRRRR~~##~~~~~~##~~RRRRRR==RRRRRRRRRR~~RRRRRR==RR==##~~~~~~RRRRRR~~~~~~~
RRRRR~~##~~~~~~##~~RRRRRR==RRRRRRRRRR~~RRRRRR==RR==##~~~~~~RRRRRR~~~~~~~
RRRR#~~##~~~~~~##~~RRRRRR==RRRRRRRRR~~~#RRRRR==RR==##~~~~~~#RRRR#~~~~~~~
RRRRRRRRRRRR#####~~RRRRRR==RRRRRRRRRRRRRRRRRR==RR==######~~##RR#####RRRR
RRRRRRRRRRRRR~~~~~~RRRRRR==RRRRRRRRRRRRRRRRRR==RR=====~~~~~##~~~~~~RRRRR
RRRRRRRRRRRRR~~~~~~RRRRRR==RRRRRRRRRRRRRRRRRR==RR======~~~~##~~~~~~RRRRR
RRRRRRRRRRRR#~~~~~~#RRRRR==RRRRRRRRRRRRRRRRRR==RR~~~~==~~~~##~~~~~~#RRRR
#RR##RR##RR##~~######RRRR==RRRRRRRRRRRRRRRRRR==RR####==##~~#RRRR#~~##RR~
~~~~~~~~~~~~~~~##~~~~~~RR==RRRRRRRRRRRRRRRRRR==RR~~##==##~~RRRRRR~~~~~~~
~~~~~~~~~~~~~~~##~~~~~~RR==RRRRRRRRRRRRRRRRRR==RR~~##==##~~RRRRRR~~~~~~~
~~~~~~~~~~~~~~~##~~~~~~RR==RRRRRRRRRRRRRRRRRR==RR~~##==##~~#RRRR#~~~~~~~
~~~#RRRRRRRRRRRR#~~####RR==RRRRRRRRRRRRRRRRRR==RR~~##==##~~#RRRRRRRRRRRR
~~~RRRRRRRRRRRRRR~~~~~~RR=================RRR==========##~~RRRRRRRRRRRRR
~~~RRRRRRRRRRRRRR~~~~~~RR==================RR==========##~~RRRRRRRRRRRRR
~~~~RRRRRRRRRRRR~~~~~~~#RRRRRRRRRRRRRRRRR==RRRRR~~~~~~~##~~~RRRRRRRRRRRR
#####RRRRRRRRRR##########RRRRRRRRRRRRRRRR==RRRR##############RRRRRRRRRR#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
<!-- /map -->

Crossing 3 (East switchbacks):

<!-- map Zones/Zone6@6/c3 -->
```text
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~
RRRRRRRRRRRR####################RRRRRRRRRRRR#################==#####RRRR
RRRRRRRRRRRRR~~~~~~~~~~##~~~~~~RRRRRRRRRRRRRR~~##~~~~~~~~~~##=====~RRRRR
RRRRRRRRRRRRR~~~~~~~~~~##~~~~~~RRRRRRRRRRRRRR~~##~~~~~~~~~~##======RRRRR
RRRRRRRRRRRR~~~~~~~~~~~##~~~~~~~RRRRRRRRRRRR~~~##~~~~~~~~~~##~~~~==RRRRR
RRRRRRRRRRRR#~~######~~######~~#RRRRRRRRRRRR#~~##~~#########~~~~#==RRRRR
RRRRRRRRRRRRR~~##~~~~~~~~~~~~~~RRRRRRRRRRRRRR~~##~~##~========~##==RRRRR
RRRRRRRRRRRRR~~##~~~~~~~~~~~~~~RRRRRRRRRRRRRR~~##~~##==========##==RRRRR
RRRRRRRRRRRR#~~##~~~~~~~~~~~~~~#RRRRRRRRRRRR#~~##~~##==~~~~~~==##==RRRRR
RRRRRRRR#RR##~~##~~##########~~##RR##RR#RRRR#~~##~~##==######==##==RRRRR
RRRRRRRRR~~~~~~##~~~~~~##~~##~~~~~~##~~RRRRRR~~~~~~##==##~=====##==RRRRR
RRRRRRRRR~~~~~~##~~~~~~##~~##~~~~~~##~~RRRRRR~~~~~~##==##======##==RRRRR
RRRRRRRR~~~~~~~##~~~~~~##~~##~~~~~~##~~#RRRR#~~~~~~##==##==~~~~##==#RRRR
RRRRRRRRRRRR#~~######~~##~~##~~#RRRRRRRRRRRR#~~##~~##==##==#~~~~#==##RR~
RRRRRRRRRRRRR~~~~~~##~~##~~~~~~RRRRRRRRRRRRRR~~##~~##==##==##~~~~==~~~~~
RRRRRRRRRRRRR~~~~~~##~~##~~~~~~RRRRRRRRRRRRRR~~##~~##==##==##~~~~==~~~~~
RRRRRRRRRRRR#~~~~~~##~~##~~~~~~#RRRRRRRRRRRR#~~##~~##==##==##~~~~==~~~~~
#RR##RR#RRRRRRRRRRRR#~~#####RRRRRRRRRRRRRRRR#####~~##==##==######==##~~~
~~~~~~~RRRRRRRRRRRRRR~~##~====================~##~~##==~~==========##~~~
~~~~~~~RRRRRRRRRRRRRR~~##======================##~~##==~~==========##~~~
~~~~~~~~RRRRRRRRRRRR~~~##==~RRRRRRRRRRRRRRRR~==##~~##==~~~~~~~~~~~~##~~~
#####~~##RRRRRRRRRR#####R==RRRRRRRRRRRRRRRR#R==R#####==#####RRRRRRRRRRRR
~~~##~~~~~~~~~~~~~~~~~~RR==RRRRRR~~~~~~~~~~RR==========~~~~RRRRRRRRRRRRR
~~~##~~~~~~~~~~~~~~~~~~RR==RRRRRR~~~~~~~~~~RR==========~~~~RRRRRRRRRRRRR
~~~##~~~~~~~~~~~~~~~~~~RR==RRRRR~~~~~~~~~~~RRRRRR~~~~~~~~~~#RRRRRRRRRRRR
~~~##~~##########~~####RR==RRRRR#########~~RRRRRR########~~##RR#RRRRRRRR
~~~~~~~##~~~~~~##~~~~~~RR==RRRRRR~~##~~~~~~RRRRRR~~~~~~##~~~~~~RRRRRRRRR
~~~~~~~##~~~~~~##~~~~~~RR==RRRRRR~~##~~~~~~RRRRRR~~~~~~##~~~~~~RRRRRRRRR
~~~~~~~##~~~~~~##~~~~~~RR==RRRRR~~~##~~~~~~RRRRRR~~~~~~##~~~~~~#RRRRRRRR
~~~######~~#RRRR#####~~RR==RRRRR#~~##~~####RRRRRR~~######~~#RRRRRRRRRRRR
~~~~~~~##~~RRRRRR~~##~~RR==RRRRRR~~##~~~~~~RRRRRR~~~~~~~~~~RRRRRRRRRRRRR
~~~~~~~##~~RRRRRR~~##~~RR==RRRRRR~~##~~~~~~RRRRRR~~~~~~~~~~RRRRRRRRRRRRR
~~~~~~~##~~RRRRRR~~##~~RR==RRRRR#~~##~~~~~~RRRRRR~~~~~~~~~~#RRRRRRRRRRRR
#####~~##~~RRRRRR~~####RR==RRRRRRRRRRRRRRRRRRRRRR####~~######RR##RR##RR#
~~~~~~~~~~~RRRRRR~~~~~~RR=============RRRRRRRR====~##~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~RRRRRR~~~~~~RR==============RRRRRR======##~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~RRRRRR~~~~~~#RRRRRRRRRRRRR==RRRRRR==R~==##~~~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRRRR####~~#RRRRRRRRRRRRR==RRRRRR==R#==##########~~#########
RRRRRRRRRRRRRRRRR~~~~~~RRR=============~~~~RR==RR=====~##~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRRRR~~~~~~RR==============~~~~RR==RR======##~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRRR#~~~~~~RR==RR~~~~~~~~~~~~~~RR==RR~~~~==##~~~~~~~~~~~~~~~
RRRR#RR##RR##RR######~~RR==RRRRRRRRR#~~#RRRRR==RR####==##~~#RRRR#~~#####
RRRRR~~##~~~~~~~~~~~~~~RR==RRRRRRRRRR~~RRRRRR==RR~=====##~~RRRRRR~~~~~~~
RRRRR~~##~~~~~~~~~~~~~~RR==RRRRRRRRRR~~RRRRRR==RR======##~~RRRRRR~~~~~~~
RRRR#~~##~~~~~~~~~~~~~~RR==RRRRRRRRR~~~#RRRRR==RR==~~~~##~~#RRRR#~~~~~~~
RRRRRRRRRRRR#########~~RR==RRRRRRRRRRRRRRRRRR==RR==##########RR#####RRRR
RRRRRRRRRRRRR~~##~~~~~~RR==RRRRRRRRRRRRRRRRRR==RR=========~##~~~~~~RRRRR
RRRRRRRRRRRRR~~##~~~~~~RR==RRRRRRRRRRRRRRRRRR==RR==========##~~~~~~RRRRR
RRRRRRRRRRRR#~~##~~~~~~RR==RRRRRRRRRRRRRRRRRR==RR~~~~~~~~==##~~~~~~#RRRR
#RR##RR##RR##~~##~~####RR==RRRRRRRRRRRRRRRRRR==RR~~######==#RRRR#~~##RR~
~~~##~~~~~~~~~~~~~~##~~RR==RRRRRRRRRRRRRRRRRR==RR~~##~~##==RRRRRR~~~~~~~
~~~##~~~~~~~~~~~~~~##~~RR==RRRRRRRRRRRRRRRRRR==RR~~##~~##==RRRRRR~~~~~~~
~~~##~~~~~~~~~~~~~~##~~RR==RRRRRRRRRRRRRRRRRR==RR~~##~~##==#RRRR#~~~~~~~
~~~##~~#RRRRRRRRRRRR#~~RR==RRRRRRRRRRRRRRRRRR==RR~~##~~##==##RR#########
~~~~~~~RRRRRRRRRRRRRR~~RR======================RR~~~~~~##=========~~~~~~
~~~~~~~RRRRRRRRRRRRRR~~RR======================RR~~~~~~##==========~~~~~
~~~~~~~~RRRRRRRRRRRR~~~#RRRRRRRRRRRRRRRRRRRRRRRR#~~~~~~##~~~~~~~~==~~~~~
#########RRRRRRRRRR######RRRRRRRRRRRRRRRRRRRRRR##################==#####
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~
```
<!-- /map -->

Crossing 4 (Long cross):

<!-- map Zones/Zone6@6/c4 -->
```text
~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#########==#################RRRRRRRRRRRRRRRR############################
~~~~~~~~~=====~##~~~~~~##~====================~##~~~~~~~~~~##~~~~~~~~~~~
~~~~~~~~~======##~~~~~~##======================##~~~~~~~~~~##~~~~~~~~~~~
~~~~~~~~~~~~~==##~~~~~~##==~RRRRRRRRRRRRRRRR~==##~~~~~~~~~~##~~~~~~~~~~~
RRRRRRRRRRRR#==##~~######==##RRRRRRRRRRRRRRR#==######~~##~~##~~######~~~
RRRRRRRRRRRRR==##~=========##~~RRRRRRRRRRRRRR==##~====~##~~~~~~##~~##~~~
RRRRRRRRRRRRR==##==========##~~RRRRRRRRRRRRRR==##======##~~~~~~##~~##~~~
RRRRRRRRRRRR#==##==~~~~~~~~##~~#RRRRRRRRRRRR#==##==~~==##~~~~~~##~~##~~~
RRRRRRRR#RR##==##==##~~######~~##RR##RR#RRRR#==##==#R==R#########~~##~~~
RRRRRRRRR~~~~======##~~##~====~~~~~##~~RRRRRR======RR==RR~~~~~~##~~~~~~~
RRRRRRRRR~~~~======##~~##======~~~~##~~RRRRRR======RR==RR~~~~~~##~~~~~~~
RRRRRRRR~~~~~~~~~~~##~~##==~~==~~~~##~~#RRRR#~~~~~~RR==RR~~~~~~##~~~~~~~
RRRRRRRRRRRR#########~~#R==R#==#RRRRRRRRRRRR#####~~RR==RR~~##~~##~~#####
RRRRRRRRRRRRR~~~~~~##~~RR==RR==RRRRRRRRRRRRRR~~##~~RR==RR~~##~~##~~##~~~
RRRRRRRRRRRRR~~~~~~##~~RR==RR==RRRRRRRRRRRRRR~~##~~RR==RR~~##~~##~~##~~~
RRRRRRRRRRRR#~~~~~~##~~RR==RR==#RRRRRRRRRRRR#~~##~~RR==RR~~##~~##~~##~~~
#RR##RR##RR##~~######~~RR==RR==#RRRRRRRRRRRR#~~##~~RR==RR~~##~~##~~##~~~
~~~~~~~~~~~~~~~~~~~~~~~RR==RR=================~##~~RR==RR~~##~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~RR==RR==================##~~RR==RR~~##~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~RR==RR~~~RRRRRRRRRRRR~==##~~#R==R#~~##~~~~~~~~~~~
RRRR#~~################RR==RRRRR#RRRRRRRRRR#R==R#####==#####RRRRRRRRRRRR
RRRRR~~~~~~##~========~RR==RRRRRR~~~~~~~~~~RR==========##~~RRRRRRRRRRRRR
RRRRR~~~~~~##==========RR==RRRRRR~~~~~~~~~~RR==========##~~RRRRRRRRRRRRR
RRRRR~~~~~~##==~~~~~~==RR==RRRRR~~~~~~~~~~~RRRRRR~~~~~~##~~#RRRRRRRRRRRR
RRRRR####~~##==######==RR==RRRRR#########~~RRRRRR########~~##RR#RRRRRRRR
RRRRR~~~~~~##==##~~##==RR==RRRRRR~~##~~~~~~RRRRRR~~~~~~~~~~~~~~RRRRRRRRR
RRRRR~~~~~~##==##~~##==RR==RRRRRR~~##~~~~~~RRRRRR~~~~~~~~~~~~~~RRRRRRRRR
RRRRR~~~~~~##==##~~##==RR==RRRRR~~~##~~~~~~RRRRRR~~~~~~~~~~~~~~#RRRRRRRR
RRRRR~~######==##~~##==RR==RRRRR#~~##~~####RRRRRR~~##~~#####RRRRRRRRRRRR
RRRRR~~~~~~##==##~~##======RRRRRR~~##~~~~~~RRRRRR~~##~~~~~~RRRRRRRRRRRRR
RRRRR~~~~~~##==##~~##======RRRRRR~~##~~~~~~RRRRRR~~##~~~~~~RRRRRRRRRRRRR
RRRR#~~~~~~##==##~~##~~RRRRRRRRR#~~##~~~~~~RRRRRR~~##~~~~~~#RRRRRRRRRRRR
~RR######~~##==##~~##~~RRRRRRRRRRRRRRRRRRRRRRRRRR####~~##~~##RR##RR##RR#
~~~~~~~~~~~##==~~~~~~~~RRRRRRRRRRRRRRR============~##~~##~~~~~~~~~~~~~~~
~~~~~~~~~~~##==~~~~~~~~RRRRRRRRRRRRRR==============##~~##~~~~~~~~~~~~~~~
~~~~~~~~~~~##==~~~~~~~~#RRRRRRRRRRRRR==RRRRRRRRR~==##~~##~~~~~~~~~~~~~~~
RRRRRRRRRRRR#==######~~#RRRRRRRRRRRRR==RRRRRRRRR#==##########~~#########
RRRRRRRRRRRRR==~~~~~~~~RRR=============##~~RRRRRR=====~##~~~~~~~~~~~~~~~
RRRRRRRRRRRRR==~~~~~~~~RR==============##~~RRRRRR======##~~~~~~~~~~~~~~~
RRRRRRRRRRRR#==~~~~~~~~RR==RR~~~~~~~~~~##~~RRRRRR~~~~==##~~~~~~~~~~~~~~~
RRRR#RR##RR##==########RR==RRRRRRRRR#~~#RRRRRRRRR####==##~~#RRRR#~~#####
RRRRR~~##~~~~==============RRRRRRRRRR~~RRRRRRRRRR~~##==##~~RRRRRR~~~~~~~
RRRRR~~##~~~~==============RRRRRRRRRR~~RRRRRRRRRR~~##==##~~RRRRRR~~~~~~~
RRRR#~~##~~~~~~~~~~~~~~RRRRRRRRRRRRR~~~#RRRRRRRRR~~##==##~~#RRRR#~~~~~~~
RRRRRRRRRRRR####~~~~###RRRRRRRRRRRRRRRRRRRRRRRRRR~~##==##~~##RR#####RRRR
RRRRRRRRRRRRR~~~~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~~~==~~~~##~~~~~~RRRRR
RRRRRRRRRRRRR~~~~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~~~==~~~~##~~~~~~RRRRR
RRRRRRRRRRRR#~~~~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~~~==~~~~##~~~~~~#RRRR
#RR##RR##RR##~~##~~####RRRRRRRRRRRRRRRRRRRRRRRRRR####==##~~#RRRR#~~##RR~
~~~~~~~~~~~~~~~##~~##~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~##==##~~RRRRRR~~~~~~~
~~~~~~~~~~~~~~~##~~##~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~##==##~~RRRRRR~~~~~~~
~~~~~~~~~~~~~~~##~~##~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~##==##~~#RRRR#~~~~~~~
~~~##############~~##~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~##==##~~#RRRRRRRRRRRR
~~~~~~~~~~~~~~~##~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~##==##~~RRRRRRRRRRRRR
~~~~~~~~~~~~~~~##~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRR~~##==##~~RRRRRRRRRRRRR
~~~~~~~~~~~~~~~##~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRR~~~##==##~~~RRRRRRRRRRRR
#####~~##################RRRRRRRRRRRRRRRRRRRRRR######==######RRRRRRRRRR#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

Crossing 5 (Backtrack):

<!-- map Zones/Zone6@6/c5 -->
```text
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~
RRRRRRRRRRRRRRRRRRRR########RRRRRRRRRRRRRRRR#################==#########
RRRRRRRRRRRRRRRRRRRRR~~##~====================~##~~~~~~~~~~##==##~~~~~~~
RRRRRRRRRRRRRRRRRRRRR~~##======================##~~~~~~~~~~##==##~~~~~~~
RRRRRRRRRRRRRRRRRRRR~~~##==~RRRRRRRRRRRRRRRR~==##~~~~~~~~~~##==##~~~~~~~
RRRRRRRRRRRRRRRRRRR##~~##==##RRRRRRRRRRRRRRR#==##~~##########==##~~##~~~
RRRRRRRRRRRRR~=============##~~RRRRRRRRRRRRRR==##~~~~~~~~~~##==##~~##~~~
RRRRRRRRRRRRR==============##~~RRRRRRRRRRRRRR==##~~~~~~~~~~##==##~~##~~~
RRRRRRRRRRRR#==~~~~~~~~~~~~##~~#RRRRRRRRRRRR#==##~~~~~~~~~~##==##~~##~~~
RRRRRRRR#RR##==######~~######~~##RR##RR#RRRR#==##########~~##==##~~##~~~
RRRRRRRRR~~~~==##~~##~~##~~~~~~~~~~##~~RRRRRR=========~##~~~~==~~~~##~~~
RRRRRRRRR~~~~==##~~##~~##~~~~~~~~~~##~~RRRRRR==========##~~~~==~~~~##~~~
RRRRRRRR~~~~~==##~~##~~##~~~~~~~~~~##~~#RRRR#~~~~~~~~==##~~~~==~~~~##~~~
RRRRRRRRRRRR#==##~~##~~##~~##~~#RRRRRRRRRRRR#########==######==######~~~
RRRRRRRRRRRRR==##~~~~~~##~~##~~RRRRRRRRRRRRRR~~##~~##=====~##==##~~~~~~~
RRRRRRRRRRRRR==##~~~~~~##~~##~~RRRRRRRRRRRRRR~~##~~##======##==##~~~~~~~
RRRRRRRRRRRR#==##~~~~~~##~~##~~#RRRRRRRRRRRR#~~##~~##~~~~==##==##~~~~~~~
RRRRRRRRRRRR#==######~~######~~#RRRRRRRRRRRR#~~##~~######==##==##~~#####
RRRRRRRRRRRRR=====~##~~~~~~~~~~RRRRRRRRRRRRRR~~##~~~~~~##======##~~~~~~~
RRRRRRRRRRRRR======##~~~~~~~~~~RRRRRRRRRRRRRR~~##~~~~~~##======##~~~~~~~
RRRRRRRRRRRR~~~~~==##~~~~~~~~~~~RRRRRRRRRRRR~~~##~~~~~~##~~~~~~##~~~~~~~
#RRRRRRRRRR######==#####RRRRRRRR#RRRRRRRRRR#RRRR#####~~#####RRRRRRRRRRRR
~~~##~=============##~~RRRRRRRRRR~~~~~~~~~~RRRRRR~~##~~~~~~RRRRRRRRRRRRR
~~~##==============##~~RRRRRRRRRR~~~~~~~~~~RRRRRR~~##~~~~~~RRRRRRRRRRRRR
~~~##==~~~~~~~~~~~~##~~RRRRRRRRR~~~~~~~~~~~RRRRRR~~##~~~~~~#RRRRRRRRRRRR
~~~##==##############~~RRRRRRRRR#########~~RRRRRR~~######~~##RR#RRRRRRRR
~~~##==##~~~~~~~~~~~~~~RRRRRRRRRR~~##~~~~~~RRRRRR~~~~~~##~~~~~~RRRRRRRRR
~~~##==##~~~~~~~~~~~~~~RRRRRRRRRR~~##~~~~~~RRRRRR~~~~~~##~~~~~~RRRRRRRRR
~~~##==##~~~~~~~~~~~~~~RRRRRRRRR~~~##~~~~~~RRRRRR~~~~~~##~~~~~~#RRRRRRRR
~~~##==##~~##~~########RRRRRRRRR#~~##~~####RRRRRR####~~##~~#RRRRRRRRRRRR
~~~~~==~~~~##~~##~========RRRRRRR~~##~~~~~~RRRRRR~~~~~~##~~RRRRRRRRRRRRR
~~~~~==~~~~##~~##==========RRRRRR~~##~~~~~~RRRRRR~~~~~~##~~RRRRRRRRRRRRR
~~~~~==~~~~##~~##==~~~~RR==RRRRR#~~##~~~~~~RRRRRR~~~~~~##~~#RRRRRRRRRRRR
~~~##==##########==####RR==RRRRRRRRRRRRRRRRRRRRRR~~######~~##RR##RR##RR#
~~~##=========~##=====~RR==RRRRRRRRRRRRRRRRRRRRRR~~##~~~~~~~~~~~~~~~~~~~
~~~##==========##======RR==RRRRRRRRRRRRRRRRRRRRRR~~##~~~~~~~~~~~~~~~~~~~
~~~##~~~~~~~~==##~~~~==#R==RRRRRRRRRRRRRRRRRRRRR~~~##~~~~~~~~~~~~~~~~~~~
RRRRRRRRRRRR#==######==#R==RRRRRRRRRRRRRRRRRRRRR#~~##########~~#########
RRRRRRRRRRRRR=====~##==RR=====================RRR~~##~~~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRR======##==RR======================RR~~##~~~~~~~~~~~~~~~~~~~
RRRRRRRRRRRR#~~~~==##==RRRRRRRRRRRRRRRRRRRRRR==RR~~##~~~~~~~~~~~~~~~~~~~
RRRR#RR##RR##~~##==##==RRRRRRRRRRRRRRRRRRRRRR==RR~~######~~#RRRR#~~#####
RRRRR~~##~~~~~~##==~~==RRRRRRRRRRRRRR~~RRRRRR==RR~~~~~~~~~~RRRRRR~~~~~~~
RRRRR~~##~~~~~~##==~~==RRRRRRRRRRRRRR~~RRRRRR==RR~~~~~~~~~~RRRRRR~~~~~~~
RRRR#~~##~~~~~~##==~~==RRRRRRRRRRRRR~~~#RRRRR==RR~~~~~~~~~~#RRRR#~~~~~~~
RRRRRRRRRRRR#####==##==RRRRRRRRRRRRRRRRRRRRRR==RR########~~##RR#####RRRR
RRRRRRRRRRRRR~=====##==RRRRRRRRRRRRRRRRRRRRRR==RR~~~~~~##~~##~~~~~~RRRRR
RRRRRRRRRRRRR======##==RRRRRRRRRRRRRRRRRRRRRR==RR~~~~~~##~~##~~~~~~RRRRR
RRRRRRRRRRRR#==~~~~##==RRRRRRRRRRRRRRRRRRRRRR==RR~~~~~~##~~##~~~~~~#RRRR
#RR##RR##RR##==######==RRRRRRRRRRRRRRRRRRRRRR==RR~~######~~#RRRR#~~##RR~
~~~~~~~~~~~##=====~##==RRRRRRRRRRRRRRRRRRRRRR==RR~~##~~~~~~RRRRRR~~~~~~~
~~~~~~~~~~~##======##==RRRRRRRRRRRRRRRRRRRRRR==RR~~##~~~~~~RRRRRR~~~~~~~
~~~~~~~~~~~##~~~~==##==RRRRRRRRRRRRRRRRRRRRRR==RR~~##~~~~~~#RRRR#~~~~~~~
~~~######~~##~~##==##==RRRRRRRRRRRRRRRRRRRRRR==RR~~##~~#RRRRRRRRRRRRRRRR
~~~~~~~##~~~~~~##======RRRRRRRRRRRRRRRRRRR=====RR~~~~~~RRRRRRRRRRRRRRRRR
~~~~~~~##~~~~~~##======RRRRRRRRRRRRRRRRRR======RR~~~~~~RRRRRRRRRRRRRRRRR
~~~~~~~##~~~~~~##~~~~~~#RRRRRRRRRRRRRRRRR==RRRRR#~~~~~~~RRRRRRRRRRRRRRRR
#########################RRRRRRRRRRRRRRRR==RRRR##########RRRRRRRRRRRRRR#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
<!-- /map -->

## The frame

Always there, whichever crossing and rooms roll:

- **The top and bottom walls** (z 12 and z 572), with five gate candidates each (top at x -260, -100, 20, 140 and 260; bottom at x -300, -180, -60, 60, 180 and 300). A crossing opens the ones it uses and plugs the rest. The strips above and below them (z 0 to 6, z 578 to 608) are bare sand; a player comes down on the top one from zone 5 and sidles along it to a gate.
- **The Long Walls**: two walls the full depth of the Reach at x -120 and x 120, and two the full width at z 212 and z 372. They cut the Reach into nine wards (north-west, gate, north-east; west, hall, east; south-west, sea, south-east), 240 by 200 studs each, and carry between them 25 gate candidates (5 or 6 on each wall).
- **The seven side slots**, each a shell of wall with one door, with a room inside it (below).
- **The Hall Gallery** (a roofed U, 28 wide and about 320 long, round the west, south and east sides of the Drowned Hall, in the middle ward) and **the Sea Gallery** (the same round the Sea Vault, in the sea ward). They run through whichever crossing rolls, and their pools make them the lowest ground in the middle of the Reach.
- **Eight pools** (3 deep) along the two galleries, and twelve small finds scattered over the wards (Weight 1 to 3; the rooms hold most of the zone's loot, the crossings six dead-end finds each, Weight 1 to 5).

## The five crossings

Each shuts the gates it doesn't use, draws every other wall of the maze, roofs a dozen straights, sinks a few lanes and pools, and winds a cart ramp (14 wide) along its way through. Each also has two false doors at the top and two at the bottom that lead only into the same long way, and two or three rubble doorways (4 high, 20 wide): a scramble on foot that cuts a bend, too steep for a cart. All five are 63 to 65 lanes long by cart and 53 on foot.

1. **West stair.** In at the north-west gate (x -260), down the west ward, through the south-west ward and back up under the gate ward and hall ward, then down the sea ward: out at the south-west corner (x -300).
2. **Hall gallery.** In at the north-east (x 260), through the gate ward and round the Drowned Hall by its Gallery, down the east side and back through the sea ward: out at x 60.
3. **East switchbacks.** In at x 260 and down the east ward; the ramp climbs back through the gate ward and hall ward before the sea ward and the south-east: out at x 300.
4. **Long cross.** In at x -260 and across the Reach, west to east, to leave by the south-east ward at x 180 after a loop through the sea ward.
5. **Backtrack.** In at x 260, west along the top, down the whole west side, then back east through the hall ward and the sea ward: out at x 60.

## The side slots

Seven slots, each with a door onto the frame, rolled each tide. Every room keeps the door open and joins the frame, so any crossing reaches any room. The best find in a room (Weight 6) is always the furthest from its door.

| Slot | Where | Size | Rooms |
|---|---|---|---|
| West cave | x -360, z 52 (cliff) | 120 x 120 | Dead-end cave, Drowned pool, Boulder scramble |
| Gatehouse yard | x -40, z 52 | 120 x 120 | Tunnel loop, Boulder yard, Gatehouse cellar |
| East cellar | x 240, z 212 (cliff) | 120 x 120 | Dead-end cellar, Flooded cellar, Tunnel loop |
| Drowned hall | x -80, z 212 | 160 x 120 | Flooded hall, Collapsed hall, Pillar gallery, Dead-end vault |
| Low west vault | x -360, z 372 (cliff) | 120 x 120 | Tunnel loop, Dead-end cave, Boulder scramble |
| Sea vault | x -80, z 412 | 160 x 120 | Dead-end vault, Flooded vault, Collapsed vault, Tunnel loop |
| East deeps | x 240, z 412 (cliff) | 120 x 120 | Flooded pocket, Dead-end cave, Boulder scramble |

- **Caves, cellars and vaults**: a roofed winding dead end, the best find (Weight 6) at its far end, lesser ones on the way.
- **Flooded rooms**: a third of the cells are pools (3 deep), the best find in the deepest.
- **Boulder scrambles and collapsed halls**: no walls, a field of rock boulders (8 to 10 high) with the finds between them; there is room to go round, but not to see.
- **Tunnel loops and the pillar gallery**: a roofed ring of lanes round a solid block, the best find opposite the door.

## Shortcuts

The rubble doorways are foot-only; the cart ramp has to take the long way round. The map tool counts 5 of 5 starts faster on foot.

## Flood order

Everything lies below the mid-tide line, so the sea comes in from the bottom and the Reach fills from the sea wards up. The two pools in the Sea Gallery (x +-60, z 552) go first, as the waterline passes Z 3604, then the sunk lanes and pools of the south wards (Z 3526 to 3404), then the middle of the Reach round the Drowned Hall (Z 3325 to 3246), and last the north wards (Z 3198 to 3084). The Test Range finds 82% of the zone under water (69% too deep to stand in) with the waterline at the top of the zone (Z 3040) and 37% (28% too deep) at its middle (Z 3344); the share of tunnels under water is 78 to 82% at the top and 36 to 40% at the middle. Coming back up, the lower wards are cut off first, and the roofed galleries are the first places you cannot shelter.

<!-- floods Zones/Zone6@6 -->
Hollow at x 60, z 552: the sea reaches it when the waterline is below Z 3604
Hollow at x -60, z 552: the sea reaches it when the waterline is below Z 3604
Channel at x -220, z 552: the sea reaches it when the waterline is below Z 3526
Hollow at x -180, z 512: the sea reaches it when the waterline is below Z 3526
Hollow at x 100, z 472: the sea reaches it when the waterline is below Z 3524
Hollow at x -100, z 472: the sea reaches it when the waterline is below Z 3512
Hollow at x 300, z 512: the sea reaches it when the waterline is below Z 3446
Hollow at x 260, z 472: the sea reaches it when the waterline is below Z 3446
Hollow at x 300, z 472: the sea reaches it when the waterline is below Z 3446
Hollow at x 300, z 352: the sea reaches it when the waterline is below Z 3404
Channel at x 300, z 352: the sea reaches it when the waterline is below Z 3404
Hollow at x -60, z 352: the sea reaches it when the waterline is below Z 3404
Hollow at x 60, z 352: the sea reaches it when the waterline is below Z 3404
Hollow at x -20, z 272: the sea reaches it when the waterline is below Z 3325
Hollow at x 100, z 272: the sea reaches it when the waterline is below Z 3312
Hollow at x 20, z 312: the sea reaches it when the waterline is below Z 3286
Hollow at x 60, z 272: the sea reaches it when the waterline is below Z 3286
Hollow at x 20, z 232: the sea reaches it when the waterline is below Z 3285
Hollow at x -100, z 272: the sea reaches it when the waterline is below Z 3246
Hollow at x -260, z 312: the sea reaches it when the waterline is below Z 3246
Channel at x -100, z 272: the sea reaches it when the waterline is below Z 3246
Hollow at x -300, z 272: the sea reaches it when the waterline is below Z 3246
Hollow at x -140, z 232: the sea reaches it when the waterline is below Z 3246
Channel at x 180, z 152: the sea reaches it when the waterline is below Z 3198
Hollow at x 140, z 72: the sea reaches it when the waterline is below Z 3086
Hollow at x -60, z 152: the sea reaches it when the waterline is below Z 3086
Channel at x -340, z 32: the sea reaches it when the waterline is below Z 3084
Hollow at x -340, z 32: the sea reaches it when the waterline is below Z 3084
<!-- /floods -->

## What a player sees from the top

Nothing past the first wall: the map tool puts 100% of the lower half out of sight.

## Measured times

- Map tool (4-stud steps along X and Z only, so it over-counts diagonals): about 95 to 100 s for the five crossings (target 85 s); 5 of 5 shortcut starts faster on foot.
- Test Range (walking the real terrain), fastest way down on foot with the first room of every slot: crossing 1 84 s, crossing 2 86 s, crossing 3 85 s, crossing 4 82 s, crossing 5 88 s (target 85 s); the way back up takes 82 to 88 s. Every other room (with crossing 1) measures 84 s. From each start along the top edge the Test Range pathfinder is slower than that, up to 114 s, because it has to sidle along the top wall to a gate. Roblox's own pathfinder finds about 38 s because it jumps and climbs over the walls; that is not a walking route. `--every` reports no problems for any crossing or room.
