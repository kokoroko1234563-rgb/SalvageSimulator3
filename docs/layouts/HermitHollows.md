# Hermit Hollows

A giant hermit crab's burrow. Zone 4 is drawn as one whole-zone warren (below); zones 5 and 6 are still the old 152-stud layouts repeated down the zone (Layouts/Tiled), described after it.

## Zone 4: the warren

A lattice of 24 x 20 cells. Each cell is a 16 x 16 floor, walls between cells are 12 thick and 22 tall, so corridors are 16 wide and the lattice pitch is 28 (node lines at x = -336 + 28 i, z = 12 + 28 j, so every wall face is on the 4-stud grid). Almost every cell is roofed (roof underside 20, top 28), so it plays as tunnels. Below the last wall row is an open court (z 578 to 608) where every way comes out. Two more walls beyond x = +-336 close the strip out to the cliffs.

### The frame (always there)

- **Outer walls**, with doors in the top wall (columns 3, 8, 12, 16, 21) and the bottom wall (4, 7, 9, 11, 13, 17, 19). Each crossing opens one of each and plugs the rest.
- **Two ribs**: long walls across the warren at z 208 and z 404, with doors at columns 1, 6, 10, 15, 19, 23 and 3, 8, 13, 17, 21. Every way through passes one door in each.
- **Five open chambers** (no roof, doors in each): the **Tide basin** (NE, round the rock pool at (260, 70)), the **Antler hall** (NW, a boulder), the **Brood chamber** (centre, two boulders and the flat for the secret's entrance at (-14, 306)), the **Throne** (south centre, a tall rock seat) and the **Pearl court** (SW, a sunken pool that floods first). One crab walks each chamber's floor, two the Brood chamber.
- **Seven side-room slots**, each a walled block with one door onto the corridors: Northwest nest, Western midden, Southwest collapse, Northeast nest, Eastern midden, Southeast burrow and South cellar.

### The five crossings

Each crossing is its own maze over the whole warren (every wall the frame doesn't already have), with its own cart ramp (14 wide, along the corridors, in at the top door and out at the bottom), its own rubble scrambles (a sand pile across a doorway, 4 high: players climb it, a cart can't), loot at its dead ends and crab routes across the way through. About ten crabs each.

1. **Basin run**: in through the Tide basin in the north-east, west along the first corridors, across the ribs on the east side, through the Brood chamber and down the west of the centre to the court.
2. **Antler descent**: in at the top near the middle, west through the Antler hall, then down the west side of the warren past the Western midden and the Pearl court.
3. **Throne road**: down the centre: in at x 16, a long swing west, through the Brood chamber and the Throne.
4. **East flank**: in at the north-west, east across the top, then down the east side by the Eastern midden and Southeast burrow.
5. **Cellar spiral**: in at the middle, a loop through the far west rib door, then down the west edge to the south-west.

### The side rooms (three each; the first is on the map)

| Slot | Rooms |
|---|---|
| Northwest nest (3 x 3) | Crab nest (spiral tunnel, a crab, best loot at the centre), Shell midden (open, sand heaps), Flooded pocket (roofed, a pool) |
| Western midden (4 x 4) | Shell midden, Boulder scramble (a boulder field, best loot deepest), Tunnel loop (ring corridor round a solid core, two crabs) |
| Southwest collapse (3 x 4) | Collapsed chamber (open, rubble and boulders), Sea cave (roofed pool), Dead-end warren |
| Northeast nest (3 x 3) | Crab nest, Shell garden, Collapsed corner (a rubble bar across the room) |
| Eastern midden (4 x 4) | Boulder scramble, Crab warren (snaking tunnel, two crabs), Drowned hall (a sunken cut across it) |
| Southeast burrow (3 x 4) | Deep tunnel, Collapsed gallery, Drowned gallery (a sunken cut down it) |
| South cellar (3 x 3) | Crab cellar, Shell hoard, Flooded cellar |

Most of the loot is in the rooms (weights 1 to 4, the best deepest); each crossing has six dead-end spots (weights 1 to 3) and the chambers one each.

### Crabs

Frame 6, each crossing 5 to 10, first rooms 6: 17 to 22 crabs a tide. All walk straight runs of corridor or chamber floor.

### Flood order

The sunken Pearl court pool floods first of the frame; rooms with pools or cuts (Flooded pocket, Sea cave, Drowned hall, Drowned gallery, Flooded cellar) flood before their neighbours. The warren's own floor is the beach slope, so as the tide comes in the seaward corridors and the court go under first and cut off the way back; the north-east basin and the top rows stay dry longest. Test Range at four waterlines (crossing 1): at the zone's top 81% of the zone is under water and 82% of the tunnels; at mid-zone about 35%; at the zone's bottom and low tide none.

<!-- floods Biomes/HermitHollows@4 -->
Hollow at x -154, z 488: the sea reaches it when the waterline is below Z 2312
<!-- /floods -->

### Maps

Top-down, the top edge at the top, the sea at the bottom. `#` rock, `R` under a roof, `=` cart ramp, `o` entrance flat, `~` floods at mid-tide. Roofs hide the walls, so the maps show mostly the chambers, the open court and the ramp.

First of everything:

<!-- map Biomes/HermitHollows@4 -->
```text
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR====..##RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#==....##RRRRR
RRRRRRRRRRRRRRRR#########RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#==.....#RRRRR
RRRRRRRRRRRRRRRRR.##.....RRRRRRRRRRRRRRRRRRRRRRRRRR=========......#RRRRR
RRRRRRRRRRRRRRRR#.......#RRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRR#.......#RRRRR
RRRRRRRRRRRRRRRR#.......#RRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRR#........RRRRR
RRRRRRRRRRRRRRRRR~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRR~~~~~~~~RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======RRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======RRRRRRRRRRRRRRRRRRRR
RRRRRRRRRR#~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRR
RRRRR#~#RRR~~RRRRRRRRRRRRRRRRRR~~RRRRRRRRRRRR==R=======RRRRRRRRRRRRRRRRR
RRRRR#~#RRR~~~RRRRRRRRRRRRRRRR~~~RRRRRRRRRRRR==R=======RRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==R=RRRR==RRRRRRRRR###RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR====RRRR=====RRRRRR#~#RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRR#~#RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRR~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======R~~~#~~~~~~RRR
RRR~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR======RR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRRRRRRRRRRRRRRRR~~~~~~~#~~RRRRRRRRRR=======R~~~~~~#~~#RRR
RRR~~~~~~~~~~~RRRRRRRRRRRRRRRR#~~~~~#~#~~#RRRRRRRRR=======~~~~~~~~~~~RRR
RRR~~~~~~~~~~#RRRRR#~#RRRRRRRR#~~~~~~~#RRRRRRRRRRRRRRRRR==#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRRRR~~#RRRRRRRRR~~~oo~~#RRRRRR=======RRRR==R~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRRRR#~#RRRRRRRR#~~~o~~~#RRRRRR==RRRR=RRRR==#~~~~~~~~~~RRR
RRR~#~~~~~~~~#RRRRRRRRRRRRRRRR#~#~~~~~~RRRRRR==RRRR=RRRR==#~~~~~~~~~~RRR
RRR~#~~~~~~~~RRRRRRRRRRRRRRRRRR~#~~~~====RRRR==RRRR=======R~~~~~~#~~~RRR
RRR###########RRRRRRRRRRRRRRRR######~=#==RRRR==RRRRRRRRRRR###########RRR
RRRRRRRRRRRRRRRRRRRRRRRRRR======RRRRR=R========RRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR========RRRR=RR======RRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRR==RRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR=======RRRRRRRRRRRRRRR~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR======RRRRRRRRRRRRRRRR~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRR####~####RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRR#~~~#~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRR#~~~#~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR########RRRRR###~=~###RRRRRRRR#~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRR~~~=~~~~RRRRRRRR#~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRR#~~~=~~~#RRRRRRRR######~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~RRRRR#~~~===~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~RRRRRR~~~====#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRR#RRRRRRRRRRRRRRRRRRR#RRRRRRRRRR
RRR~~~#~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~#~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRR#RRRRRRRRRRRRRRRRRRR#RRRRRRRRRR
RRR~#~~~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~RRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~RRRRRRRRRRRRRR
RRR###################~=#############################################RRR
RRR~~~~~~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RRR
RRR~~~~~~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RRR
```
<!-- /map -->

Crossing 2 (Antler descent):

<!-- map Biomes/HermitHollows@4/c2 -->
```text
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR=======R..RRRRRRRRRRRRRRRRRRRRRRRRRRRRR......##RRRRR
RRRRRRRRRRRRRRRRRRRR=RRRRRRR..RRRRRRRRRRRRRRRRRRRRRRRRRRRR#......##RRRRR
RRRRRRRRRRRRRRRR###^=.###RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#.......#RRRRR
RRRRRRRRRRRRRRRRR.##=....RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR.......#RRRRR
RRRRRRRRRRRRRRRR#...=...#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#.......#RRRRR
RRRRRRRRRRRR=========...#RRRRRRRRRRRRRR..#RRRRRRRRRRRRRRRR#........RRRRR
RRRRRRRRRRR==========~~~#RRRRRRRRRRRRRR~~RRRRRRRRRRRRRRRRRR~~~~~~~~RRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRR#==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRR#~#RRR=====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~#RRRRRRRRRRRRRRRRRRR
RRRRR#~#RRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~#RRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR###RRRRR
RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~#RRRRR
RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~#RRRRR
RRRRRRRRRRRRRR==RRRRRRRRRRRRRR###RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRR=======RRRRRRRRRR~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR=RRRRRRRRR#~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~~#RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~#RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRR=============R~~~~~~~~RRRRRRRRRRRRRRRRRRRR~~~~~~#~~#RRR
RRR~~~~~~~~~~~RRR============R#~~~~~#~~RRRRRRRRRRRRRRRRRRR~~~~~~~~~~~RRR
RRR~~~~~~~~~~#RRR==RRRRRRRRRRR#~~~~~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRR==RRRRRRRRRRRR~~~oo~~#RRRRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRR==RRRRRRRRRRR#~~~o~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~#~~~~~~~~#RRR==RRRRRRRRRRR#~#~~~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~#~~~~~~~~RRRR==RRRRRRRRRRRR~#~~~~~~RRRRRRRRRRRRRRRRRRRR~~~~~~#~~~RRR
RRR###########RRR==RRRRRRRRRRR#########RRRRRRRRRRRRRRRRRRR###########RRR
RRRRRRRRRRRRRRRRR============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRR####~####RRRRRRRRRRRRRRRRRRR#~#RRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR=======R#~~~#~~~RRRRRRRRRRRRRRRRRRRR#~~RRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==#~~~#~~~#RRRRRRRRRRRRRRRRRRR###RRRRRRRR
RRR########RRRRR#########RRRRRR==#~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRR~~~~~~=========R~~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRR#~~~~~~=#RRRRRRRR######~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~RRRRR#~~~~~~=#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~RRRRRR~~~~~~=#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRR#RRRRRRRRRRRRRRRRRRR#RRRRRRRRRR
RRR~~~#~~~#RRRRRRRRRRRR=RR=========R#~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~#~~~#RRRRRRRRRRRR=R==========R#~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRR=R==RRRRRRR=RRRRRR#RRRRRRRRRRRRRRRRRRR#RRRRRRRRRR
RRR~#~~~~~#RRRRRRRRRRRR====RRRRRRR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRR===RRRRRRRRR======RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR####################################==############################RRR
RRR~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~RRR
RRR~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~RRR
```
<!-- /map -->

Crossing 3 (Throne road):

<!-- map Biomes/HermitHollows@4/c3 -->
```text
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======RRRR=RRRRRRRRRR......##RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRR==RRRR=RRRRRRRRR#......##RRRRR
RRRRRRRRRRRRRRRR#########RRRRRRRRRRRR=RRRR==RRRR=RRRRRRRRR#.......#RRRRR
RRRRRRRRRRRRRRRRR.##....#RRRRRR=======R=====RRRR====RRRRRRR.......#RRRRR
RRRRRRRRRRRRRRRR#.......#RRRRRR==RRRRRR==RRRRRRRRRR=RRRRRR#.......#RRRRR
RRRRRRRRRRRRRRRR........#RRRRRR==#..RRR==RR======RR=RRRRRR#........RRRRR
RRRRRRRRRRRRRRRRR~~~~~~~#RRRRRR==#~~RRR==R=======RR=RRRRRRR~~~~~~~~RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRR==R==RRRR=RR=RRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======R=====RRRR====RRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======RR===RRRRR====RRRRRRRRRRRRRRRRRRRR
RRRRRRRRRR#RRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRR#~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRR#~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRR###RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR====RRRR==RRRRRRRRRRRRRRRRRRRR#~#RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RR=RRRR==RRRRRRRRRRRRRRRRRRRR#~#RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RR=RRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR====RR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~RRRRRRRRRRRRRRRRRRRRR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~RRRRR
RRR~~RRRRRRRRRRRRRRRRRRRR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~RRRRR
RRR###RRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR###RRRRR
RRR~~~~~~~~~#RRRRRRRRRRRR==========RRRR~~RRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~#RRRRRRRRRRRRR=========RRRR~~RRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRRRRRRRRRRRRRRRRRRR=RRR#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRRRR~~#RRRRRRRRR~~~=~~~#RRRRRRRRRRRRRRRRRRRR~~~~~~#~~#RRR
RRR~~~~~~~~~~~RRRRR~~#RRRRRRRR#~~~=~#~#RRRRRRRRRRRRRRRRRRR~~~~~~~~~~~RRR
RRR~~~~~~~~~~#RRRRRRRRRRRRRRRR#~~~=~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRRRRRRRRRRRRRRRR~~~oo~~#RRRRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRRRRRRRRRRRRRRR#~~~o~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~#~~~~~~~~#RRRRRRRRRRRRRRRR#~#~=~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~#~~~~~~~~RRRRRRRRRRRRRRRRRR~#~====~RRRRRRRRRRRRRRRRRRRR~~~~~~#~~~RRR
RRR###########RRRRRRRRRRRRRRRR######~=#RRRRRRRRRRRRRRRRRRR###########RRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR===RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR###~=####RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~~~=~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~~~=~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR########RRRRR#########RRRRRRRR#~~~=~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRR~~~~~~~~RRRRRRRR#~~~====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRR#~~~~~~~#RRRRRRRR#~####==#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~RRRRR#~~~~~~~#RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~RRRRRR~~~~~~~#RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRR#RRRRRRRRRRRRRRRRRRRRRR==#RRRRRRRRRRRRRRRRRRR#RRRRRRRRRR
RRR~~~#~~~#RRR~~RRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~#~~~#RRR~~RRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRR==#RRRRRRRRRRRRRRRRRRR#RRRRRRRRRR
RRR~#~~~~~#RRRRRRRRRRRRRRRRRRRRRRR=======RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRR======RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR###############################=~#################################RRR
RRR~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RRR
RRR~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RRR
```
<!-- /map -->

Crossing 4 (East flank):

<!-- map Biomes/HermitHollows@4/c4 -->
```text
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR......##RRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#......##RRRRR
RRRRRRRRRRR==RRR#########RRRRR#..RRRRRRRRRRRRRRRRRRRRRRRRR#.......#RRRRR
RRRRRRRRRRR==RRRR.##.....RRRRRR..RRRRRRRRRRRRRRRRRRRRRRRRRR.......#RRRRR
RRRRRRRRRRR==RRR#.......#RRRRR###RRRRRRRRRRRRRRRRRRRRRRRRR#.......#RRRRR
RRRRRRRRRRR==RRR........#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#........RRRRR
RRRRRRRRRRR==RRRR~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~~~~~~RRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRR#~~RRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRR#~~RRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRR#RRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRR#~#RRRRRRRRRRRR=RRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRR#~#RRRRRRRRRRRR=RRRR=====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRR=RRRR==#==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR###RRRRR
RRRRRRRRRRRRRRRRRRRR=======R==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~#RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR~~#==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~#RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRR=====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR============RRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRRRRRRRRRRRRRRRR~~~~~~~~RRR==========RRRRRRR~~~~~~#~~#RRR
RRR~~~~~~~~~~~RRRRRRRRRRRRRRRR#~~~~~#~~RRRR=========RRRRRR~~~~~~~~~~~RRR
RRR~~~~~~~~~~#RRRRRRRRRRRRRRRR#~~~~~~~#RRRRRRRRRRRR=RRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRRRRRRRRRRRRRRRR~~~oo~~#RRRRRR=======RRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRRRRRRRRRRRRRRR#~~~o~~~#RRRRRR==RRRRRRRRRRR#~~~~~~~~~~RRR
RRR~#~~~~~~~~#RRRRRRRRRRRRRRRR#~#~~~~~#RRRRRR==RRRRRRRRRRR#~~~~~~~~~~RRR
RRR~#~~~~~~~~RRRRRRRRRRRRRRRRRR~#~~~~~#RRRRRR==RRRR=======R~~~~~~#~~~RRR
RRR###########RRRRRRRRRRRRRRRR#~~####~#RRRRRR==RRRR=RRRR==###########RRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======RRRR==RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=======RRRR==RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~RRRRRRRRRRRR=======RRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~RRRRRRRRRRRR======RRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR============RRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR============RRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#########RRRRRRRRRRRRRRRRRRRR=RRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~~~#~~~RRRRRRRRRRRRRRR=======RRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~~~#~~~#RRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRR########RRRRR#########RRRRRRRR#~~~~~~~#RRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRR~~~~~~~#RRRRRRRR~~~~~~~~RRRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRR~~~~~~~#RRRRR#~~~~~~~#RRRRRRRR######~~#RRRRRRRRRRRRRR==RRRRRRRRRRRRRR
RRR~~~~~~~~RRR~~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR====RRRRRRRRRRRR
RRR~~~~~~~~RRR~~~~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=====RRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#RRRRRRRRRRRRRRRRR==#RRRRRRRRRR
RRR~~~#~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRR
RRR~~~#~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#RRRRRRRRRRRRRRRRR==#RRRRRRRRRR
RRR~#~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRR~~RRRRRRRRRRRRRRR=====RRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRR~~#RRRRRRRRRRRRRR====RRRRRRRRRRRR
RRR#####################################################==###########RRR
RRR~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~RRR
RRR~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~RRR
```
<!-- /map -->

Crossing 5 (Cellar spiral):

<!-- map Biomes/HermitHollows@4/c5 -->
```text
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRR..#......##RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRR###......##RRRRR
RRR..RRRRRRRRRRR####..###RRR##RRRRRRR=RRRRRRRRRRRRRRRRRRRR#.......#RRRRR
RRR..RRRRRRRRRRRR.##.....RRR..RRRRRRR=RRRRRRRRRRRRRRRRRRRRR.......#RRRRR
RRR..RRRRRRRRRRR#.......#RR#..#RRRRRR=RRRRRRRRRRRRRRRRRRRR#.......#RRRRR
RRRRRRRRRRRRRRRR........#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRR#........RRRRR
RRRRRRRRRRRRRRRRR~~~~~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRR~~~~~~~~RRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRRR======RRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRRRRRRRRRR========RRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRR#RRRRRRRRRRRRRR==RRRR==RRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRR#~#RRRRRR=======RRRR==RRRR==RRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRR#~#RRRRRR=======RRRR==RRRR==RRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRR==RRRR=RRRR==RRRR==RRRRRR==RRRRRRRRRRRRRRRRRRRRRRR###RRRRR
RRRRRRRRRRRRRR==RRRR=======RRRR==========RRRRRRRRRRRRRRRRRRRRRRR#~#RRRRR
RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~#RRRRR
RRRRRRRRRRRRRR==#~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRR==========R~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRR=RRRRRRRRR###RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRR============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~~#RRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~#RRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRR==RRRRRRRRRRRR~~~~~~~#RRRRRRRRRRRRRRRRRRRR~~~~~~#~~#RRR
RRR~~~~~~~~~~~RRR==RRRRRRRRRRR#~~~~~#~#RRRRRRRRRRRRRRRRRRR~~~~~~~~~~~RRR
RRR~~~~~~~~~~#RRR==RRRRRRRRRRR#~~~~~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~~~~~~~~~~RRRR==RRRRRRRRRRRR~~~oo~~#RRRRRRRRRRRRRRRRRRRR~~~#~~~~~~RRR
RRR~~~~~~~~~~#RRR==RRRRRRRRRRR#~~~o~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~#~~~~~~~~#RRR==RRRRRRRRRRR#~#~~~~~#RRRRRRRRRRRRRRRRRRR#~~~~~~~~~~RRR
RRR~#~~~~~~~~R====RRRRRRRRRRRRR~#~~~~~#RRRRRRRRRRRRRRRRRRRR~~~~~~#~~~RRR
RRR###########==RRRRRRRRRRRRRR#~~####~#RRRRRRRRRRRRRRRRRRR###########RRR
RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR====RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR==#RRRRRRRRRRRRRRRRRRR####~####RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR=====RRRRRRRRRRRRRRRRR#~~~#~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRRRRRRRRRR###==RRRRRRRRRRRRRRRRR#~~~#~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR########RRR==#########RRRRRRRR#~~~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#=====R~~~~~~~~RRRRRRRR#~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#==RRR#~~~~~~~#RRRRRRRR######~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~==RRR~~~~~~~~#~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~~==RRRR~~~~~~~#~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#==RRRRRRRRRRRRRRRRRRRRRRRRRRRR#RRRRRRRRRRRRRRRRRRR#RRRRRRRRRR
RRR~~~#~~~#=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~#~~~#R============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRRRRRRRRRRR=RRRRRRRRRRRRRRRRR#RRRRRRRRRRRRRRRRRRR#RRRRRRRRRR
RRR~#~~~~~#RRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR~~~~~~~#RRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
RRR###########==#####################################################RRR
RRR~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RRR
RRR~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RRR
```
<!-- /map -->

### Measured times

Target 55 s (a rare biome may be up to 30% slower).

| Crossing | Map tool | Test Range |
|---|---|---|
| 1 Basin run | 65 s | 56 s |
| 2 Antler descent | 66 s | 55 s |
| 3 Throne road | 68 s | 57 s |
| 4 East flank | 65 s | 55 s |
| 5 Cellar spiral | 63 s | 56 s |

The map tool steps only along X and Z, so it reads about 15% above the Test Range, which also steps diagonally. All five have 5 of 5 shortcut starts (the rubble scrambles) and hide 100% of the lower half from the top.

The Test Range still reports, on every crossing: ten cosmetic specks and a starfish buried up to 0.8 studs (cosmetics placed at the layout's height, the real terrain is a little lower beside the long walls and in the court) and the rock pool's water 1.1 studs over the ground in the Tide basin; "path too steep" is only a note now (Roblox's pathfinder walks round outside the side cliffs, 41 s, and is not a walking route).

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
###############==######RR############################==#################
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==========RRRRRRRRR
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRR
RRRRRRR=========RRRRRRRRRRRRRRRRR~~~~~~~~RRRRRRRRRRRRR=========RRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRR~~~~o~~#~RRRRRRRRRRRR==========RRRRRRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRR#~~~ooo~~~#RRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRRR=========RRRRRRRRRRRRRRR~~~~o~~~~RRRRRRRRRRRR=========RRR~~~~~~~
RRRRRRR=========RRRRRRRRRRRRRRRR~~~~~~~~RRRRRRRRRRRRRR=========RR~~~~~~~
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==R#~~~~~~~
RRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==========RR~~~~~~~
RRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=========RRR~~~~~~~
###############==#################RR#################==#################
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~RR~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==========RRRRRRRRR
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRR
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRR########RRRRRRRRRRRRRRRRRRRR==RRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRR~~~~~~~~~RRRRRRRRRRRR==========RRRRRRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRR~~~ooo~~~RRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRRR=========RRRRRRRRRRRRRRR~~~~o~~~~RRRRRRRRRRRR=========RRR~~~~~~~
RRRRRRR==========RRRRRRRRRRRRRRR~~~~~~~~RRRRRRRRRRRRR==========RR~~~~~~~
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRR#########RRRRRRRRRRRRRRRRRRRRR==R#~~~~~~~
RRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=========RR~~~~~~~
RRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=========RRR~~~~~~~
###############==#################RR#################==#################
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~RR~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~RR~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==========RRRRRRRRR
RRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=========RRRRRRRRR
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRR########RRRRRRRRRRRRRRRRRRRR==RRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRR~~~~~~~~~RRRRRRRRRRRR==========RRRRRRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRR~~~ooo~#~RRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRR~~~ooo~~~RRRRRRRRRRRR==RRRRRRRRRR####~~#
RRRRRRR==========RRRRRRRRRRRRRRR~~~~~~~~~RRRRRRRRRRRR==========RR~~~~~~~
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRR########RRRRRRRRRRRRRRRRRRRRR==R#~~~~~~~
RRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=========RR~~~~~~~
RRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==========RR~~~~~~~
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRR########
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~RR~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~RR~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
###############==######RR############################==#################
RRRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=========RRRRRRRRRR
RRRRRRR=========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=========RRRRRRRRR
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRR#########RRRRRRRRRRRRRRRRRRR==RRRRRRRRR
RRRRRRR==========RRRRRRRRRRRRRRRR~~~~~~~~RRRRRRRRRRRR==========RRRRRRRRR
RRRRRRRR=========RRRRRRRRRRRRRRR~~~~o~~#~RRRRRRRRRRRR=========RRRRRRRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRR~~~ooo~~~RRRRRRRRRRRR==RRRRRRRRR#####~~#
RRRRRRR==========RRRRRRRRRRRRRRR~~~~~~~~~RRRRRRRRRRRR==========RR~~~~~~~
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRR########RRRRRRRRRRRRRRRRRRRRR==RR~~~~~~~
RRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RR~~~~~~~
RRRRRRR==========RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==========RR~~~~~~~
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRR########
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~RR~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

### Flood order

The sunken lanes are the wet heart of it. The bottom lane and the cut through the last two gaps are open to the sea, so they flood as soon as the waterline reaches the tile's seaward edge; then the third lane (waterline at about tile z 125), the gallery's pool (z 97), the second lane (z 69) and the first (z 41). Each lane is under water while the waterline is still 50 to 80 studs seaward of it, so on the way back the quick way through the middle drowns first, from the bottom up, and the dry ramps far out at the sides are what's left. Test Range at four waterlines: at the zone's top (z 2432) 88% of the zone is under water and 87% of the tunnels; at mid-zone (z 2736) 39% and 38%; at the zone's bottom (z 3040) 1% and 2% (the sunken lanes of the last tile); at low tide, none.

<!-- floods Biomes/HermitHollows@5 -->
Channel at x -10, z 602: the sea reaches it when the waterline is below Z 3039
Channel at x -160, z 574: the sea reaches it when the waterline is below Z 3039
Channel at x 50, z 574: the sea reaches it when the waterline is below Z 3039
Channel at x -160, z 546: the sea reaches it when the waterline is below Z 3013
Hollow at x 326, z 562: the sea reaches it when the waterline is below Z 2986
Channel at x -160, z 518: the sea reaches it when the waterline is below Z 2958
Channel at x -160, z 490: the sea reaches it when the waterline is below Z 2930
Channel at x -10, z 450: the sea reaches it when the waterline is below Z 2888
Channel at x 50, z 422: the sea reaches it when the waterline is below Z 2888
Channel at x -160, z 422: the sea reaches it when the waterline is below Z 2888
Channel at x -160, z 394: the sea reaches it when the waterline is below Z 2861
Hollow at x 326, z 410: the sea reaches it when the waterline is below Z 2834
Channel at x -160, z 366: the sea reaches it when the waterline is below Z 2806
Channel at x -160, z 338: the sea reaches it when the waterline is below Z 2778
Channel at x 50, z 270: the sea reaches it when the waterline is below Z 2736
Channel at x -10, z 298: the sea reaches it when the waterline is below Z 2736
Channel at x -160, z 270: the sea reaches it when the waterline is below Z 2736
Channel at x -160, z 242: the sea reaches it when the waterline is below Z 2709
Hollow at x 326, z 258: the sea reaches it when the waterline is below Z 2682
Channel at x -160, z 214: the sea reaches it when the waterline is below Z 2654
Channel at x -160, z 186: the sea reaches it when the waterline is below Z 2626
Channel at x 50, z 118: the sea reaches it when the waterline is below Z 2584
Channel at x -160, z 118: the sea reaches it when the waterline is below Z 2584
Channel at x -10, z 146: the sea reaches it when the waterline is below Z 2584
Channel at x -160, z 90: the sea reaches it when the waterline is below Z 2557
Hollow at x 326, z 106: the sea reaches it when the waterline is below Z 2530
Channel at x -160, z 62: the sea reaches it when the waterline is below Z 2502
Channel at x -160, z 34: the sea reaches it when the waterline is below Z 2474
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
###############==#####RR####################RR#######==#################
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRR==============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR=============RRR~~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRR
RRR==============RR~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRRRRRRRRRRRRR==R#~~oo~~#RRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRR=============RR~~oo~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRR
RRR=============RRR~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRR
RRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR==============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRR
###############==########RR##########################==#################
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~RR~~~~~~~~~~~~~~~~~~~~RR~~~~~~~==~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRR==============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR==RRRRRRRRRRRRRR#######RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR==============RR~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRRRRRRRRRRRRR==R#~~oo~~#RRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRR=============RR~~oo~~~RRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRR
RRR==============RR~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRR==RRRRRRRRRRRRR########RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRR
RRRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRR
###############==########RR##########################==#################
~~~~~~~~~~~~~~~==~~~~~~~~RR~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~RR~~~~~~~~~~~~~~~~~~~~RR~~~~~~~==~~~~~~~~~~~~~~~~~
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRR==============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRR
RRR==RRRRRRRRRRRRR########RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR==============RR~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRRRRRRRRRRRRR==RR~~oo~~~RRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRRRRRRRRRRRRRR==RR~~oo~~~RRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRR==============RR~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRR==RRRRRRRRRRRRR########RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRR
RRR==============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
~~~~~~~~~~~~~~~==~~~~~~~~RR~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~==~~~~~RR~~~~~~~~~~~~~~~~~~~~RR~~~~~~~==~~~~~~~~~~~~~~~~~
###############==#####RR####################RR#######==#################
RRRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRR
RRR=============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRR
RRR==RRRRRRRRRRRRR########RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR==============RR~~~~~#RRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRR=============RR~~oo~~~RRRRRRRRRRRRRRRRRRRRRRRRRRR=============RRRRRR
RRRRRRRRRRRRRRR==R#~~oo~~#RRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
RRR==============RR~~~~~~RRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRR==RRRRRRRRRRRRRR#######RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRR
RRR==============RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==============RRRRR
RRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR==RRRRRRRRRRRRRRRRR
~~~~~~~~~~~~~~~==~~~~~~~~RR~~~~~~~~~~~~~~~~~~~~~~~~~~==~~~~~~~~~~~~~~~~~
```
<!-- /map -->

### Flood order

No cuts: the floor is the beach's own slope, and almost all of it is under a roof. Test Range at four waterlines: at the zone's top (z 3040) 85% of the zone is under water and 84% of the tunnels; at mid-zone (z 3344) 37% and 36%; at the zone's bottom and low tide, none. The seaward lanes go under first, and with the ramps 28 s a tile, a cart left late is a cart lost.

<!-- floods Biomes/HermitHollows@6 -->

<!-- /floods -->

### Measured times

- Map tool: 26.8 s per tile, about 107 s for the zone (target 85 s), 2 of 5 shortcut starts. (The map tool steps only along X and Z; the Test Range also steps diagonally, so it is quicker.)
- Test Range (walking the terrain): the fastest way down is 98 s, and the same back up; from each start x -280: 105 s, -200: 101 s, -100: 99 s, 0: 104 s, 100: 108 s, 180: 104 s, 280: 108 s. The fastest is the middle maze over the rubble. That is 15% over the target, inside the 30% a rare biome may take.
