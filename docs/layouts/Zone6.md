# Zone 6: The Drowned Reach

The deepest, slowest ground on the beach, drawn as one 720 x 608 piece. A maze of tall rock walls (24 high, 12 wide) on a 40-stud grid: lanes 28 wide between the walls, a roof over many of the straights, low ground everywhere. Four long walls cut the Reach into nine wards, and each tide the sea rolls one of five **crossings** (which gates stay open, which walls fill the wards, where the tunnels and the cart ramp go) and one room for each of seven **side slots**. Every crossing is a single winding route with dead ends hung all along it: nothing is a straight line, and from the top you see nothing at all.

The maze is built from pictures in `Zone6.luau`: a text grid where `+` is a node, `--` or `|` a wall, `==` or `!` rubble, and a blank an opening. A post stands on every node a wall touches, so walls that meet end to end leave no crack (a crack one stud wide is a way through for a player, and the Test Range found one).

## Maps

Top-down, the top edge at the top, the sea at the bottom. Legend: `#` rock, `^` raised sand, `.` flat, `~` floods at mid-tide, `=` cart ramp, `o` entrance flat, `R` under a roof. The whole Reach lies below the mid-tide line, so almost all of it shows as `~`; the walls and roofs are what the maps are for. The first crossing with the first room of every slot:

<!-- map Zones/Zone6@6 -->
```text
```
<!-- /map -->

Crossing 2 (Hall gallery):

<!-- map Zones/Zone6@6/c2 -->
```text
```
<!-- /map -->

Crossing 3 (East switchbacks):

<!-- map Zones/Zone6@6/c3 -->
```text
```
<!-- /map -->

Crossing 4 (Long cross):

<!-- map Zones/Zone6@6/c4 -->
```text
```
<!-- /map -->

Crossing 5 (Backtrack):

<!-- map Zones/Zone6@6/c5 -->
```text
```
<!-- /map -->

## The frame

Always there, whichever crossing and rooms roll:

- **The top and bottom walls** (z 8 and z 568), with five gate candidates each (top at x -260, -100, 20, 140 and 260; bottom at x -300, -180, -60, 60, 180 and 300). A crossing opens the ones it uses and plugs the rest. The strips above and below them (z 0 to 2, z 574 to 608) are bare sand; a player comes down on the top one from zone 5 and sidles along it to a gate.
- **The Long Walls**: two walls the full depth of the Reach at x -120 and x 120, and two the full width at z 208 and z 368. They cut the Reach into nine wards (north-west, gate, north-east; west, hall, east; south-west, sea, south-east), 240 by 200 studs each, and carry between them 25 gate candidates (5 or 6 on each wall).
- **The seven side slots**, each a shell of wall with one door, with a room inside it (below).
- **The Hall Gallery** (a roofed U, 28 wide and about 320 long, round the west, south and east sides of the Drowned Hall, in the middle ward) and **the Sea Gallery** (the same round the Sea Vault, in the sea ward). They run through whichever crossing rolls, and their pools make them the lowest ground in the middle of the Reach.
- **Eight pools** (3 deep) along the two galleries, and a dozen small finds scattered over the wards (Weight 1 to 3).

## The five crossings

Each shuts the gates it doesn't use, draws every other wall of the maze, roofs a dozen straights, sinks a few lanes and pools, and winds a cart ramp (14 wide) along its way through. Each also has two false doors at the top and two at the bottom that lead only into the same long way, and two or three rubble doorways (4 high, 20 wide): a scramble on foot that cuts a bend, too steep for a cart. All five are 63 to 65 lanes long by cart and 53 on foot.

1. **West stair.** In at the north-west gate (x -260), down the west ward, through the south-west ward and back up under the gate ward and hall ward, then down the sea ward: out at the south-west corner (x -300).
2. **Hall gallery.** In at the north-east (x 260), through the gate ward and round the Drowned Hall by its Gallery, down the east side and back through the sea ward: out at x 60.
3. **East switchbacks.** In at x 260 and down the east ward; the ramp climbs back through the gate ward and hall ward before the sea ward and the south-east: out at x 300.
4. **Long cross.** In at x -260 and across the Reach, west to east, to leave by the south-east ward at x 180 after a loop through the sea ward.
5. **Backtrack.** In at x 260, west along the top, down the whole west side, then back east through the hall ward and the sea ward: out at x 60.

## The side slots

Seven slots, each with a door onto the frame, rolled each tide. The first room of each is the deepest cave, a dead end with the best find (Weight 6) at its end; the others differ in kind.

| Slot | Where | Size | Rooms |
|---|---|---|---|
| West cave | x -360, z 48 (cliff) | 120 x 120 | Dead-end cave, Drowned pool, Boulder scramble |
| Gatehouse yard | x -40, z 48 | 120 x 120 | Tunnel loop, Boulder yard, Gatehouse cellar |
| East cellar | x 240, z 208 (cliff) | 120 x 120 | Dead-end cellar, Flooded cellar, Tunnel loop |
| Drowned hall | x -80, z 208 | 160 x 120 | Flooded hall, Collapsed hall, Pillar gallery, Dead-end vault |
| Low west vault | x -360, z 368 (cliff) | 120 x 120 | Tunnel loop, Dead-end cave, Boulder scramble |
| Sea vault | x -80, z 408 | 160 x 120 | Dead-end vault, Flooded vault, Collapsed vault, Tunnel loop |
| East deeps | x 240, z 408 (cliff) | 120 x 120 | Flooded pocket, Dead-end cave, Boulder scramble |

- **Caves, cellars and vaults**: a roofed winding dead end, the best find (Weight 6) at its far end, lesser ones on the way.
- **Flooded rooms**: a third of the cells are pools (3 deep), the best find in the deepest.
- **Boulder scrambles and collapsed halls**: no walls, a field of rock boulders (8 to 10 high) with the finds between them; there is room to go round, but not to see.
- **Tunnel loops and the pillar gallery**: a roofed ring of lanes round a solid block, the best find opposite the door.

## Shortcuts

The rubble doorways are foot-only; the cart ramp has to take the long way round. The map tool counts 5 of 5 starts faster on foot.

## Flood order

SEE BELOW

<!-- floods Zones/Zone6@6 -->
<!-- /floods -->

## What a player sees from the top

Nothing past the first wall: the map tool puts 100% of the lower half out of sight.

## Measured times

TBD
