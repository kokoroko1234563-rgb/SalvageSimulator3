# Biome items

Every biome in the initial build has its own items. They only wash up in that biome (never in the
normal tier pools), replace part of the zone's spawns, and are worth more than a normal find in the
same zone, more so the rarer the biome. Each biome has its own page in the collection log.

## Rules

- **Where.** A biome's items replace `Config.Biomes.ItemShare` (0.45) of the spawns in a zone where
  the biome rolled, at the zone's rarity table (common to very rare, as `Config.Zones[z].Rarity`),
  picking among that biome's items of the rolled rarity. If the biome has no item of that rarity,
  the nearest rarity it has.
- **Tier.** A biome item takes the tier of the zone it washes up in, so the zone's tool lifts it.
- **Worth, relative to the zone.** A biome item's value is set when it spawns:
  `zone's average normal find x biome premium x the item's rarity weight / the zone's average
  rarity weight`, so a biome's average find is its premium over the zone's normal average,
  wherever the biome rolls. Premiums by biome tier: Common 1.25, Uncommon 1.4, Rare 1.6,
  VeryRare 2.0 (`Config.Biomes.Premium`). Rarity weights: Common 1, Uncommon 2, Rare 4,
  VeryRare 8 (`Config.Biomes.RarityWorth`).
- **Collection log.** One page per biome. The tower man's complete-lexicon check stays on the
  normal items only.
- **Models.** Every item has a built model to the standard of `src/server/ItemModels.luau`
  (several welded parts, shaped and shaded, built in the root's frame). Biome items' builders
  live in `src/server/BiomeItemModels/<BiomeId>.luau`, each returning `{ [itemId] = builder }`.

## The items

Size is the physics body (studs, X Y Z); the model is built on it. Shape is the body's shape.

| Biome | Id | Name | Class | Rarity | Size | Shape | Colour (RGB) |
|---|---|---|---|---|---|---|---|
| SandcastleFlats | SandDollar | Sand Dollar | Light | Common | 1.2, 0.15, 1.2 | Block | 235, 220, 180 |
| SandcastleFlats | ToySpade | Toy Spade | Light | Common | 0.6, 0.3, 2.0 | Block | 230, 70, 60 |
| SandcastleFlats | CastleFlag | Castle Flag | Light | Uncommon | 0.3, 2.2, 0.8 | Block | 240, 200, 60 |
| SandcastleFlats | GildedTurret | Gilded Turret | Medium | Rare | 1.4, 2.0, 1.4 | Block | 225, 185, 90 |
| SandcastleFlats | SandKingsCrown | Sand King's Crown | Light | VeryRare | 1.6, 0.9, 1.6 | Block | 250, 210, 80 |
| DriftwoodCove | DriftwoodBranch | Driftwood Branch | Medium | Common | 3.0, 0.5, 0.6 | Block | 180, 160, 135 |
| DriftwoodCove | WovenBasket | Woven Basket | Light | Common | 1.4, 1.0, 1.4 | Block | 190, 150, 95 |
| DriftwoodCove | CarvedFloat | Carved Float | Light | Uncommon | 1.2, 0.7, 0.7 | Block | 160, 110, 70 |
| DriftwoodCove | DriftwoodTotem | Driftwood Totem | Medium | Rare | 0.9, 2.4, 0.9 | Block | 150, 105, 70 |
| DriftwoodCove | AncientFigurehead | Ancient Figurehead | Heavy | VeryRare | 1.2, 2.6, 1.8 | Block | 170, 120, 80 |
| TidepoolRocks | HermitCrabShell | Hermit Crab Shell | Light | Common | 1.0, 0.8, 1.2 | Block | 220, 170, 140 |
| TidepoolRocks | SeaUrchin | Sea Urchin | Light | Common | 0.9, 0.9, 0.9 | Ball | 90, 50, 120 |
| TidepoolRocks | PearlOyster | Pearl Oyster | Light | Uncommon | 1.2, 0.6, 1.0 | Block | 170, 160, 150 |
| TidepoolRocks | CoralFan | Living Coral Fan | Light | Rare | 1.6, 1.6, 0.3 | Block | 240, 110, 150 |
| TidepoolRocks | GiantClamPearl | Giant Clam Pearl | Medium | VeryRare | 1.4, 1.4, 1.4 | Ball | 245, 240, 255 |
| SeagrassShallows | KelpBundle | Kelp Bundle | Light | Common | 1.4, 0.5, 0.8 | Block | 70, 120, 60 |
| SeagrassShallows | DriedSeahorse | Dried Seahorse | Light | Common | 0.4, 1.2, 0.5 | Block | 220, 170, 80 |
| SeagrassShallows | JettySign | Old Jetty Sign | Medium | Uncommon | 2.0, 1.2, 0.3 | Block | 140, 110, 80 |
| SeagrassShallows | MermaidsMirror | Mermaid's Mirror | Light | Rare | 1.0, 1.4, 0.2 | Block | 190, 220, 230 |
| SeagrassShallows | SeaPearlNecklace | Sea Pearl Necklace | Light | VeryRare | 1.2, 0.3, 1.2 | Block | 230, 240, 220 |
| CoralGarden | BrainCoral | Brain Coral | Medium | Common | 1.4, 1.1, 1.4 | Ball | 230, 150, 120 |
| CoralGarden | ParrotfishScale | Parrotfish Scale | Light | Common | 0.8, 0.15, 1.0 | Block | 80, 200, 190 |
| CoralGarden | QueenConch | Queen Conch | Light | Uncommon | 1.4, 1.0, 1.0 | Block | 245, 180, 160 |
| CoralGarden | RedCoralBranch | Red Coral Branch | Light | Rare | 1.2, 1.8, 0.4 | Block | 220, 40, 60 |
| CoralGarden | ReefDiadem | Reef Queen's Diadem | Light | VeryRare | 1.5, 0.8, 1.5 | Block | 250, 120, 170 |
| ShipwreckShallows | BrassPorthole | Brass Porthole | Medium | Common | 1.4, 1.4, 0.4 | Block | 180, 140, 70 |
| ShipwreckShallows | ShipsLogbook | Ship's Logbook | Light | Uncommon | 1.0, 0.3, 1.4 | Block | 120, 80, 50 |
| ShipwreckShallows | SilverDoubloons | Silver Doubloons | Light | Rare | 1.0, 0.4, 1.0 | Block | 200, 205, 215 |
| ShipwreckShallows | TreasureMap | Captain's Treasure Map | Light | VeryRare | 1.6, 0.1, 1.2 | Block | 220, 200, 150 |
| FogBank | FogBell | Fog Bell | Medium | Common | 1.2, 1.4, 1.2 | Block | 150, 160, 170 |
| FogBank | KeepersLogbook | Keeper's Logbook | Light | Uncommon | 1.0, 0.3, 1.4 | Block | 90, 70, 60 |
| FogBank | LostShipsLamp | Lost Ship's Lamp | Medium | Rare | 0.9, 1.6, 0.9 | Block | 200, 190, 140 |
| FogBank | LighthouseLens | Lighthouse Lens | Medium | VeryRare | 1.8, 1.8, 1.0 | Block | 210, 235, 255 |
| JellyfishLagoon | MoonJelly | Moon Jelly | Light | Common | 1.2, 0.6, 1.2 | Block | 200, 210, 255 |
| JellyfishLagoon | GlowShell | Glow Shell | Light | Uncommon | 1.0, 0.7, 1.2 | Block | 120, 240, 220 |
| JellyfishLagoon | BoxJellyLantern | Box Jelly Lantern | Light | Rare | 0.9, 1.3, 0.9 | Block | 170, 140, 255 |
| JellyfishLagoon | CrownJelly | Crown Jelly | Light | VeryRare | 1.6, 1.0, 1.6 | Block | 255, 150, 230 |
| HermitHollows | MoltedClaw | Molted Claw | Medium | Common | 1.8, 0.7, 0.9 | Block | 210, 90, 60 |
| HermitHollows | ShellBead | Polished Shell Bead | Light | Uncommon | 0.7, 0.7, 0.7 | Ball | 240, 200, 170 |
| HermitHollows | CrabCarapace | Giant Crab Carapace | Heavy | Rare | 2.6, 1.0, 2.2 | Block | 190, 80, 50 |
| HermitHollows | CrabKingsHoard | Crab King's Hoard | Heavy | VeryRare | 1.8, 1.4, 1.4 | Block | 230, 190, 90 |
| WhirlwindDunes | SandGlassShard | Sand-Glass Shard | Light | Common | 1.0, 0.3, 0.8 | Block | 230, 220, 180 |
| WhirlwindDunes | Fulgurite | Fulgurite | Medium | Uncommon | 0.6, 2.0, 0.6 | Block | 120, 110, 100 |
| WhirlwindDunes | DesertRose | Desert Rose | Medium | Rare | 1.4, 1.1, 1.4 | Block | 210, 160, 130 |
| WhirlwindDunes | StormIdol | Storm-Tossed Idol | Heavy | VeryRare | 1.0, 2.2, 1.0 | Block | 200, 170, 90 |
| SpearstoneReef | SpearstoneChip | Spearstone Chip | Light | Common | 0.6, 1.2, 0.4 | Block | 110, 120, 140 |
| SpearstoneReef | BarnacledSpearhead | Barnacled Spearhead | Medium | Uncommon | 0.6, 2.0, 0.3 | Block | 120, 130, 120 |
| SpearstoneReef | StoneSpear | Stone Spear | Medium | Rare | 0.5, 4.0, 0.5 | Block | 140, 150, 160 |
| SpearstoneReef | AncientTrident | Ancient Trident | Heavy | VeryRare | 1.2, 4.0, 0.4 | Block | 90, 170, 170 |
| StrandedIceberg | IceChunk | Ice Chunk | Medium | Common | 1.4, 1.2, 1.2 | Block | 200, 230, 255 |
| StrandedIceberg | FrozenHerringCrate | Frozen Herring Crate | Medium | Uncommon | 1.6, 1.0, 1.2 | Block | 170, 200, 220 |
| StrandedIceberg | MammothTusk | Mammoth Tusk | Heavy | Rare | 0.7, 0.7, 3.4 | Block | 235, 225, 200 |
| StrandedIceberg | IceLockedChest | Ice-Locked Chest | Heavy | VeryRare | 2.0, 1.6, 1.4 | Block | 150, 200, 240 |

The old biome `Loot` lists (ordinary catalog items) and `LootShare` go; the common biomes' items
above replace them. Frozen Fish and Big Shell stay normal tier items.
