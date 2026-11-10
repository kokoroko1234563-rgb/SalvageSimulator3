# Exotic items

Exotics come from the secrets' chests (`src/shared/Secrets.luau`), need attunement (a core from a
true rebirth) to use, and are kept through every rebirth. They are the hardest things in the game
to get, so each does **something nothing else can do** and stays useful at every point of the
climb, instead of being a bigger number.

## Grabbers: they track your progress

An exotic grabber works up to the tier of the best **shop** tool you own (the `Available` tools in
`Gear.Tools`, read from the `OwnedTools` attribute), and at least tier 2. It never skips the tool
ladder and never goes out of date. Strong Back still adds one. This is `Stats.lift` /
`Stats.liftWith` (exotics have `Tracks = true` and a `Tier` of 2, the floor), so every lift check
uses it, on the server (`GrabService.canClaim`) and the client (hover text). The bots never own
exotics, so `BotEconomy.lift` is unchanged. An exotic is equipped for its power:

| Item | Power |
|---|---|
| Anchor Hook | Key E, 12 s cooldown: hurl the hook at the item under the pointer, up to 3x the tool's reach away (22 studs, so 66), even out in the water. If the item passes the usual claim rules (tier, free, not unlock-restricted) it is claimed and reeled to you. The server checks 3x reach plus the usual slack, and the cooldown. A hook-and-line effect shows the throw |
| Gust Gloves | When you grab an item and your active vessel is within 40 studs of you, the item is blown straight into the vessel (the same load as "To vessel", so a full vessel refuses and you just hold it), with a gust effect |
| Crab Claw | Holds two items at once: grab a second item while the first is lifted and both float beside you; Drop and To vessel act on both. A third grab lets go of the oldest. Every other tool still holds one |
| Obsidian Grabber | The first time an item is grabbed with it, its `Value` attribute rises 15% (marked on the item with `ObsidianBoost`, so once per item) |
| Freeze Wand | Freezes the waves around you (key F, as before). Items grabbed while the waves are frozen get a 10 s window where they can't be knocked loose: no grip break from waves or pulls and no knock-down release (client side, like all grip breaks) |

## Vessels

| Item | Power |
|---|---|
| Captain's Longboat | A boat you ride in: over deep water it carries you and the load, so you can get home on a rising tide. Holds 12 |
| Leviathan Rowboat | A boat like the Longboat, the biggest hold in the game (30), slow |
| Jelly Raft | Swims after you and scoops up any free item it passes over (within 4 studs) while it has room. Holds 10 |
| Magic Carpet | Flies behind you over rock, walls and water, taking the straight line. Holds 10 |
| Shell Wagon | Cargo can never be lost: it never tips or spills, and waves never take anything from it. Holds 14 |
| Glass Swan | Swims; what it carries sells for 10% more. Holds 12 |
| Frost Sled | Fastest on sand; while you tow it you run 15% faster. Holds 12 |

## Accessories (worn)

| Item | Power |
|---|---|
| Deckhand's Satchel | +3 pocket slots, and pocketed items sell for 10% more |
| Tide Crown | Shows the tide's timeline (when each zone uncovers and closes again); waves push you 25% less |
| Glow Pearl | A light the Gloom can't put out (zone 6); breath lasts 25% longer |
| Lantern of Clear Sight | See through the haze and the Fog Bank's fog |
| Foghorn | Warns of big and rogue waves 10 s early; its blast (key G, 30 s cooldown) pulls free items within 30 studs 8 studs toward you |
| Tidewalker Boots | Walk on the water's surface for 3 s (key R, 20 s cooldown); waves push you 30% less |
| Prism Lens | Rare and very rare items, unlock items and biome very-rares within 150 studs shine through anything |
| Ember Lantern | Breath lasts 50% longer; ice in the Stranded Iceberg (Ice hazard) doesn't slide you |

Attunement stays as it is: an exotic needs a core to use.
