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
