# Tools and item tiers: one tool per zone

The tool decides how far out you can work; inside a zone you can work, you can lift everything.

## The rule

- Every sellable item has a **`Tier`** from 1 to 7 (`Items.Catalog`): the zone it washes up in
  (`Config.Zones[tier]`, 7 is the Far Sandbar). Zone N's surf spawns and loot-spot finds draw only from
  items of tier N; the zone's `Rarity` table still picks the rarity within the tier
  (`Items.ofTier(tier, rarity)`, `ItemService`).
- A tool has a **`Tier`** (`Gear.Tools`): it lifts every item up to that tier (`Gear.canLift`). The
  Strong Back rebirth reward adds one tier (`Stats.liftWith`), never past the last zone.
- **There is no water-depth limit on lifting.** Reach, grip and the other stats stay. The sea limits
  players the way it always did: wading slows them, deep water drowns them, waves knock them about.
- An item's `Class` (Light, Medium, Heavy, Very heavy) is only its physical feel: density when dragged
  (`Items.ClassDensity`), what fits in Deep Pockets (Light), and where it lies: after a surf spawn is
  chosen, a Heavy or Very heavy item is moved out into deeper water within the same stretch of beach.
- The spawned part carries the effective tier in its **`Tier` attribute**, and every lift check reads
  it (`GrabService.canClaim` for players and bots, the client's hover text). Biome loot (`biome.Loot`)
  takes the tier of the zone it washes up in, whatever its own `Tier`. Unlock items have no tier: they
  are always liftable.

## The ladder

| Zone | Name | Tool (shop price) | Items |
|---|---|---|---|
| 1 | Shopside Shore | Bare Hands | 6 |
| 2 | Sunny Stretch | Beach Rake (150) | 6 |
| 3 | Middle Banks | Fishing Net (600) | 7 |
| 4 | Outer Shore | Grabber Claw (2,500) | 6 |
| 5 | The Shoals | Boat Hook (9,000) | 6 |
| 6 | The Drowned Reach | Hand Winch (30,000) | 5 |
| 7 | The Far Sandbar | Electric Winch (90,000) | 5 |

Exotic and magical tools sit on the ladder by their old strength, until they are redesigned: Freeze
Wand 4, Anchor Hook 5, Tide Magnet 5, Gust Gloves 6, Bubble Wand 7, Crab Claw 7, Obsidian Grabber 7.

## Items per tier

Every tier holds at least one item of each rarity its zone rolls (zone 1: Common and Uncommon; zone 2
adds Rare; zones 3 to 6 all four; zone 7 Rare and Very rare). Validate checks it, and a test too.
Values are unchanged; new items are priced like their neighbours of the same rarity and class.

| Tier | Common | Uncommon | Rare | Very rare |
|---|---|---|---|---|
| 1 | Seashell, Glass Bottle, Flip-Flop, Beach Ball | Sunglasses, Starfish | | |
| 2 | Old Boot, Coconut, Snorkel | Fishing Lure, Big Shell | Message in a Bottle | |
| 3 | Coil of Rope, Tangled Net, Bucket | Glass Float, Buoy | Coral Branch | Pearl |
| 4 | Driftwood Plank, Wooden Oar | Small Crate, Lobster Trap | Frozen Fish | Spyglass |
| 5 | Barrel, Cannonball | Big Crate, Brass Compass | Lantern | Diving Helmet |
| 6 | Iron Chain | Ship's Bell | Anchor | Ship's Wheel, Ship's Cannon |
| 7 | | | Gold Ingots, Jeweled Goblet | Treasure Chest, Old Statue, Golden Crown |

## Crowds

`Config.Items.CrowdSpawn` scales the zones' ordinary surf spawns (and `MaxSurfItems`) with the players
on the server, bots counted. Now that everything in a zone is liftable by its tool, that is all the
scaler needs to touch.
