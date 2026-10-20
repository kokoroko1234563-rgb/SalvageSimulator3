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
  and 6**; Sea-Glass Shore and Black Sand Vents wait. Which of the planned Common, Uncommon and
  Rare biomes join it: to decide.

Each biome turns up **at most once a tide**, and a tide usually has **1 or 2 biomes** in all:
each zone rolls whether it gets one (`Config.Biomes.Chance`, about 25%), and the weights below
only decide which (decided).

Where each biome rolls, by tier (VeryRare decided; the rest proposed):

| Tier | Zones | Weight each (which biome, when a zone gets one) |
|---|---|---|
| Common | 1 to 4 | 20 to 45 |
| Uncommon | 2 to 6 | 12 to 15 |
| Rare | 4 to 6 | 8 to 15 |
| VeryRare | 5 and 6 only | 4 to 6 |
