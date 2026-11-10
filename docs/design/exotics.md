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

Each power is a field on its `Gear.Vessels` entry; `src/shared/VesselPowers.luau` holds the rules
the server, the client and the tests share (`Config.Grab` has the numbers).

| Item | Power, as built |
|---|---|
| Captain's Longboat | A boat you ride in (`Rides`, `Boat`). Holds 12 |
| Leviathan Rowboat | The same, the biggest hold in the game (30), slow (Speed 0.6). Holds 30 |
| Jelly Raft | Swims after you; scoops the nearest free (Unclaimed) item within 4 studs while it has room, at most one per 0.5 s. Holds 10 |
| Magic Carpet | Flies behind you in a straight line at hover height above the ground or water, with no collision with the map (rock, walls, water). The server pulls it back within 45 studs of you. Holds 10 |
| Shell Wagon | Cargo can never be lost. Holds 14 |
| Glass Swan | Swims; items sold from it sell for 10% more. Holds 12 |
| Frost Sled | The fastest vessel on sand (Speed 2); while you tow it you run 15% faster. Holds 12 |

### Boats (Longboat, Leviathan)

- Each has an invisible `Helm` seat and a prompt (key B, so it never clashes with E). Boarding needs
  the boat within 12 studs of you **and over deep water**; on sand it tows as before. Jumping, or
  the prompt again, gets you out (`VesselService.toggleBoard`).
- Seated, you are in the boat: your `Riding` attribute is set, you are not in the water, so you
  neither wade nor drown, and the boat is driven from your movement keys
  (`src/client/BoatController.luau`): floating on the sea surface at 22 studs/s times the boat's
  Speed (and the owner's vessel-speed upgrades), carrying its cargo. That is the way home on a
  rising tide. If the boat runs aground you stand up and tow it again.
- The server checks a ridden boat's speed every 0.3 s (`VesselPowers.boatSpeedOk`, 1.5x slack); a
  boat that jumps further than that is put back and the rider let go.
- Boats may cross the Far Sandbar's channel (swimmers already do). The tide still limits how much
  of the sandbar you can work, and what you lift is still limited by your tool, so nothing is
  skipped. Cargo can still wash off in deep water as for any boat, and a boat that flips is lost.
- The Leviathan's hold lays its cargo out in four columns instead of two.

### The other powers

- **Jelly Raft:** the scoop goes through `GrabService.canClaim` for the owner (their tool's tier,
  Strong Back and the item being free), then `ItemService.setHeld` and `VesselService.load`. It
  does not write the lexicon. The raft scans every half interval.
- **Magic Carpet:** all its parts are non-colliding (`Ghost`), so walls and rock never stop it.
- **Shell Wagon** (`Unspillable`): `Stability` 12 keeps it upright on the client; the server
  stands it back up if it ever leans past 25 degrees and never spills its cargo; the swim wash-off
  and the deep-water loss skip it (it floats where the water covers it), so nothing is lost.
- **Glass Swan:** `ShopService.soldValue` multiplies the Value of an item that is in a Glass Swan
  (found through its `VesselId`) by 1.1 before the rebirth and pass multipliers. Items taken out of
  the swan first sell at face value.
- **Frost Sled:** while you hold its handle the client multiplies your humanoid's `BaseWalkSpeed`
  (the path WaveController scales for the water) by 1.15 and restores it when you let go. It is
  not checked by the server, which does not police walk speed.

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
