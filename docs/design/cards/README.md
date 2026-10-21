# Zone and biome cards

One card per zone and biome: what it should be, before anyone builds it. A card is approved
(by the game's designer) before an agent starts on it, and the built zone is checked against
it. The rules every zone follows are in `docs/design/layouts.md`.

| Card | Zones | Status |
|---|---|---|
| [Zone 4: Outer Shore](zone4.md) | 4 | approved |
| [Zone 5: The Shoals](zone5.md) | 5 | approved |
| [Zone 6: The Drowned Reach](zone6.md) | 6 | approved; the role model (built first) |
| [Hermit Hollows](hermit-hollows.md) | 4 to 6 | approved; the giant crab's new moves first |
| [Shipwreck Shallows](shipwreck-shallows.md) | 2 to 6 | approved; the barrels' tumble first |
| [Sandcastle Flats](sandcastle-flats.md) | 1 to 4 | on hold: upper floors and traps to discuss |
| [The shore](shore.md) | 1 to 3 | approved; targets lowered |
| [Driftwood Cove](driftwood-cove.md) | 1 to 4 | draft |
| [Tidepool Rocks](tidepool-rocks.md) | 1 to 4 | draft |
| [Seagrass Shallows](seagrass-shallows.md) | 1 to 4 | draft |
| [Coral Garden](coral-garden.md) | 1 to 4 | draft |
| [Jellyfish Lagoon](jellyfish-lagoon.md) | 2 to 6 | draft |
| [Fog Bank](fog-bank.md) | 2 to 6 | draft |
| [Whirlwind Dunes](whirlwind-dunes.md) | 4 to 6 | draft |
| [Spearstone Reef](spearstone-reef.md) | 4 to 6 | draft |
| [Stranded Iceberg](stranded-iceberg.md) | 5 and 6 | draft |

Each card says:

- **Identity**: the zone in a sentence, and how it should feel.
- **Look**: ground and rock materials, fog, the decor that makes it somewhere.
- **The frame**: the landmarks that are always there.
- **The paths**: how many each crossing has, the character of each, where they link.
- **Dangers**: which, where, and what a regular learns to do about them.
- **Rooms and loot**: the kinds of side pockets, and where the best finds are.
- **Keep**: what must stay as it is (entrances, pools, the edges).
- **Questions**: what the designer still has to decide.

## The initial build

The biomes to build before launch (decided with the designer):

- **Rebuilt with the kit** (zone 6 is the model): zones 4 and 5, Hermit Hollows, Shipwreck
  Shallows (its own zones 2 to 6).
- **New:** one VeryRare biome, **Stranded Iceberg** (Pip the penguin's), rolling **only in zones 5
  and 6**; Sea-Glass Shore and Black Sand Vents wait. All the planned Common, Uncommon and Rare
  biomes join it (decided).

Each biome turns up **at most once a tide**, and a tide usually has **1 or 2 biomes** in all:
each zone rolls whether it gets one (`Config.Biomes.Chance`, about 25%), and the weights below
only decide which (decided).

Where each biome rolls, by tier (decided):

| Tier | Zones | Weight each (which biome, when a zone gets one) |
|---|---|---|
| Common | 1 to 4 | 20 to 45 |
| Uncommon | 2 to 6 | 12 to 15 |
| Rare | 4 to 6 | 8 to 15 |
| VeryRare | 5 and 6 only | 4 to 6 |

## The secrets: an opening, an item and a chest in each biome

Every biome of the initial build has its own secret. Its **unlock item** washes up on the beach
(whether or not that tide's door stands), there is an **opening** in the biome, and using the
item at the opening (it is always used up) takes you into a small themed **room** with a chest
(`Secrets.luau`, kind `Room`: no checkpoints, no flood, a 60 second limit). Sandcastle Flats and
Shipwreck Shallows keep their flooding courses. Sea-Glass Shore and Black Sand Vents wait.

**When the door stands.** Each time a biome rolls, its door stands with a chance by the biome's
tier (`Config.Secrets.DoorChance`): Common 50%, Uncommon 65%, Rare 80%, VeryRare 90%.

**Where.** The door is in a far-off place, off the cart route and away from the main paths: a far
corner of the beach in the open zones, a side room or a chamber off a lane in the walled ones.
Each layout's `Entrances` (from its kit plan) says where; every way a zone can come out has at
least one. `lune run tools/entrances.luau` lists them, with what is wrong with any that is not
in clear ground.

| Biome | Opening | Unlock item | Chest |
|---|---|---|---|
| Driftwood Cove | Hollow beached tree trunk | Carved Idol | Orange coin |
| Tidepool Rocks | Blowhole in the rocks | Pearl-Eyed Shell | Blue coin |
| Seagrass Shallows | Under a collapsed jetty | Barnacled Lantern | Green coin |
| Coral Garden | Arch in the reef | Coral Comb | Pink coin |
| Fog Bank | Lighthouse door | Lighthouse Key | Lantern of Clear Sight or Foghorn |
| Whirlwind Dunes | Hollow in a dune, a wind-carved arch | Wind Chime | Magic Carpet or Gust Gloves |
| Hermit Hollows | Shell burrow, on the floor of a chamber | Spiral Conch | Crab Claw or Shell Wagon |
| Spearstone Reef | Cleft between leaning spearstones | Spearstone Shard | Tidewalker Boots |
| Jellyfish Lagoon | Glowing lagoon grotto | Jelly Jar | Jelly Raft or Glow Pearl |
| Stranded Iceberg | Ice cave mouth | Frozen Compass | Frost Sled or Freeze Wand (rare Frosted variant) |

The common biomes' chests pay as the Sandcastle Vault's does (the biome's coloured coin). The
rare biomes' chests are a lootbox of the exotic rewards already defined in `Gear.luau`; these
will be reworked later, so the tables are placeholders.
