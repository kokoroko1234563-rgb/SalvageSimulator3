# Exotic items

Exotics come from the secrets' chests (`src/shared/Secrets.luau`), need attunement (a core from a
true rebirth) to use, and are kept through every rebirth. They are the hardest things in the game
to get, so each does **something nothing else can do** and stays useful at every point of the
climb, instead of being a bigger number.

## Grabbers: they track your progress

An exotic grabber works up to the tier of the best shop tool you own (at least tier 2), never past
it (`Stats.lift` / `Gear.canLift`; Strong Back still adds one). So it never skips the tool ladder
and never goes out of date. It is equipped for its power:

| Item | Power |
|---|---|
| Anchor Hook | Hurl the hook (key E, 12 s cooldown): grab one item from 3x reach, even out in the water, and reel it in |
| Gust Gloves | A grabbed item within 40 studs of your cart is blown straight into it (no carrying) |
| Crab Claw | Holds two items at once |
| Obsidian Grabber | Anything you grab with it is worth 15% more (its Value attribute rises once, on the first grab) |
| Freeze Wand | Freezes the waves around you (key F, as now), and items you grab while they're frozen can't be knocked loose for 10 s |

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

Rules live in `src/shared/Accessories.luau` (shared by server, client and the tests); the key
abilities are checked in `src/server/AccessoryService.luau` (the client only asks, over the
`Accessory` remote) and drawn in `src/client/AccessoryEffects.luau`.

| Item | Power, as built |
|---|---|
| Deckhand's Satchel | +3 pocket slots. What is sold from the pockets pays 10% more: `PocketService.takeAll` (which the buyer calls) raises each entry's Value, rounded to a coin. Items dropped on death keep their plain value |
| Tide Crown | A "Tide timeline" panel (left of the screen) lists every zone and the Far Sandbar: "open, closes in 4:12", "opens in 1:30, closes in 6:00", "always uncovered" or "stays covered". A zone counts as uncovered while the waterline is past its near edge. Computed by `Accessories.timeline` from `Tide.waterlineAt` over the next cycle or two, refreshed twice a second. Waves push 25% less |
| Glow Pearl | In the Gloom (zones 5 and 6) a steady light (range 38) is kept on your head, and the Gloom blacks the world out only to 60% (`GloomLight.Blind`) instead of fully. Not put out by the shadow, and it flickers no more. Breath +25% |
| Lantern of Clear Sight | Haze thins 2.5x (as before). In the Fog Bank's Fog hazard only 1/2.5 of the fog closes in, and you see 2.5x as far through it |
| Foghorn | Warns of big and rogue waves 10 s early (`SeaController`). Key G, 30 s cooldown: the server pulls every free (Unclaimed) item within 30 studs 8 studs toward you (never past you); held, loose and vessel items are not touched. A ring spreads out from you and a banner shows. There is no audio asset yet |
| Tidewalker Boots | Key R, 20 s cooldown: for 3 s you walk on the surface. The server sets your `WaterWalkUntil` attribute; `WaveController` holds your feet at the surface and skips the water's slowdown, `DrowningService` doesn't tick breath down while it lasts, and foam rides under your feet. Waves push 30% less, water slows half as much |
| Prism Lens | Within 150 studs, free (Unclaimed) items that are Rare or VeryRare (every biome very-rare among them) or unlock items get a Highlight that draws through walls, nearest 20 at a time. Its Gear field is `Prism` (not the old `RevealRare`, which `GearEffects` still reads) |
| Ember Lantern | Breath +50%. The Slide (ice) hazard in `HazardController` doesn't slide you (`Accessories.iceGrip`) |

Attunement stays as it is: an exotic needs a core to use.
