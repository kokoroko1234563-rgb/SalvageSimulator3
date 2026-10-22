# Bots

Server-side bots that play the game's core loop, to measure **item competition between X players on
one server**. They are admin-only: nothing runs until an admin starts them (`bots <n>`) or the sweep
does.

Code: `src/server/BotService.luau` (the bots), `src/server/BotEconomy.luau` (purse, gear, buying
rule), `src/shared/Routes.luau` (walkable routes), `tools/bots/` (the sweep).

## How a bot plays

- **No physics.** A bot is an anchored R15 man in its own colour (all body parts that colour, a name
  tag "Bot 7 – Teal" and a live status line under it), moved by CFrame every frame at real walk speed
  (16 studs/s, slowed by water as `Beach.wading` says, times the sweep's speed factor). Its cart, in the
  same colour, is anchored too and trails it along its own track; what it carries rides in the cart
  (in the hands, one thing, until it owns a vessel). Twenty distinct colours are in `BotService.Colors`.
- **Real motions.** Walks out with the tide (waits just landward of the waterline, following it out and back in again, so the incoming tide is still worked),
  walks to an item, claims it, loads it, walks back, sells at the buyer, walks to the shopkeeper to buy
  gear or rebirth.
- **Routes.** `Routes` is a lazily filled grid (4 studs) over `Beach.shapeAt`, so it follows the active
  layouts and whatever biomes rolled, with A*. It uses the stepping rules of `tools/paths.luau` (eight
  directions, no climb steeper than `FootSlope`, or `CartSlope` once the bot owns a vessel, no cutting a
  wall's corner), never walks on rock, keeps a cart's size clear of the edges it can't cross, and blocks
  any cell where the sea would be too deep to stand in (waist depth, less a margin) at the moment the
  bot would be there: the sea's level is predicted along the route from the tide, for a slower and a
  quicker bot. `tools/paths.luau` itself is unchanged: it measures a tile at a time with penalties for
  repeated runs, and the runtime needs one grid with one-off searches, so the two only share their rules.
- **Real claims.** A bot takes an item from the real item system. `GrabService.canClaim` is the player's
  rule (free item, tool able to pick up, reach plus slack, and the item's zone tier within the tool's
  tier; see [tools.md](tools.md)) and
  `ItemService.claimForBot` takes it atomically, so whoever arrives first gets it; bots and players
  compete for the same surf spawns and loot spots, and share the despawn timers. Bots own negative ids.
- **Real prices.** `ShopService.payout` (item Value, which holds the zone multiplier, times the rebirth
  multiplier), `ShopService.listing` over `Gear.Tools` and `Gear.Vessels`, `Rebirth.cost`.
- **State in memory only.** Coins, gear and rebirths live in `BotEconomy.State`; nothing touches
  `DataService` or a DataStore (a test checks).
- **The tide.** A bot only goes for an item if a route there and a route back stay open (the way back
  is planned from the item's spot, setting out once loaded). It heads home when its cart is full or
  nothing else will do. One the sea catches (water at waist depth) is swept away: it loses its cart load
  and returns home four seconds later.

- **Spreading.** The beach's width is split between the bots present (by number, re-split when bots
  join or leave); each bot works its own stretch first and only leaves it when the stretch has nothing
  it can take. A bot with no cart (one thing in its hands) keeps to trips of at most 200 game seconds
  outside its stretch. A bot reserves its target (a soft claim in BotService; other bots skip it) and
  gives up at once if anyone claims it first. Items are scored by value per second of the walk there and
  on home.
- **Never blocks a frame.** Each bot thinks (picks a target, plans routes) in its own thread, one at a
  time, while movement carries on. Route searches call a yield every 200 node expansions, and all bots
  together may use about 3 ms of a frame; searches are bounded by the distance. The sweep reports the
  worst Heartbeat and bot work time.

- **Tide safety.** Routes assume a slower bot (0.7 of its speed) and keep 1 stud short of waist depth (wading
  is slow); a bot only sets out for an item if the way home would still be open 40 game seconds after
  it got there (double while the sea is coming in, 1.5x with a load). If no route keeps those margins the
  way home falls back to looser ones, then to the shortest way. A bot goes anywhere along the beach for
  an item beyond the first zone (or in knee-deep water or deeper); the stretch is for the cheap finds of
  the first zone's shallows.
  A trip bot sets out once the tide is 40% out and plans with the looser margins.
- **Crowds.** `Config.Items.CrowdSpawn = { Players = 20, Scale = 3 }`: every zone's spawn
  target and max rate grow linearly with the players on the server, bots counted, to Scale times a solo
  server's (`spawning.md`). `--scale` on the sweep sets Scale.

- **Cheap planning.** One flood outward from the sell pad over the route grid (`Routes.buildField`, one per
  kind of walker: on foot, or each cart size in use) gives every cell its distance home, the way home
  itself, and the latest moment a walker may be there and still get home before the sea closes the way
  (from the tide's own curve, with the tight margins). "Is the way back open from here" and "how far home"
  are lookups; going home follows the field; the way out from the pad is the way home reversed. A bot
  scores candidates by straight-line distance and the field, and runs one real search, only when it
  starts from somewhere other than the pad. Thinking is time-sliced (see below) and counted:
  `ThinkingGameSeconds` per bot, search nodes per game minute server-wide.
- **Water.** An item in the water is claimed from a safe spot within the tool's reach (plus the server's
  slack, less a little), never by wading to it: the spot must stay safe for the walk there, the grab and
  load, the way home and the tide margin. With no such spot the item is skipped. Staging never goes past
  the furthest zone the tool works (its tier, Strong Back included), so nothing without a tier 7 tool
  goes to the Far Sandbar or the channel.

## One buying rule, for every bot

1. Rebirth as soon as it can be afforded, taking the reward after which its estimated income is highest.
2. Otherwise buy what raises estimated income most for its price among what it can afford.

`BotEconomy.income` is the bot's own estimate of a tide's income with some gear. The tide works through
the zones one after another, and a tool works every zone up to its tier, so it adds up, for each of
those zones, how long the waterline leaves its surf items there, the walk to it and back, and the
average item of that zone's tier, as many per trip as its vessel carries (heavy things only where a bot
wades). A bot targets the free item with the best value per second there and back among what its tier
lifts and the tide leaves open. Trading, the auction,
traders and Robux are out of scope.

## Commands (admin console)

- `bots <n>` starts up to 20 bots (adds or removes the highest numbers).
- `bots stop` removes them (what they carried is left on the beach).
- `bots report` prints per bot and in total: coins per hour, items per hour, trips, items lost to
  another bot, idle time, deaths and lost loads (per hour of game time).
- `bots speed <factor>` runs the tide, item spawns and bot walking faster (1 = the real game).

## What each measure means

- **coins/h, items/h**: coins paid and items sold, per hour of game time (real elapsed time times the
  speed factor).
- **trips**: sales of at least one item.
- **lost to bot**: it was heading for an item and another bot claimed it first. **lost other**: the
  item was taken by a player or despawned first.
- **idle %**: share of time with status "waiting for the tide" (nothing to take and nowhere to walk).
- **deaths / lost loads**: times swept away by the sea, and how many of them lost a carried load.
- Server-wide (`ItemService.stats`): items spawned (surf, open sand and loot spots, and the count per zone), items claimed, items that
  despawned unclaimed (timed out, drowned or lost), and how many spawn ticks found every zone
  at its target.
- **income log**: one entry per bot per tide (cycle): income, items, trips, game seconds, gear at start
  and end, the zones worked (items and value per zone), the bot count at the time. `Partial` marks a
  tide cut short by the start or end of the run.

## The sweep

```
python3 tools/bots/sweep.py                         X = 1, 2, 4, 8, 12, 16, 20 at --speed 10
python3 tools/bots/sweep.py --xs 1,8 --speed 10
python3 tools/bots/sweep.py --final-trip
python3 tools/bots/sweep.py --report-only
```

It publishes the build to the Test Range and runs `tools/bots/task.luau` once per X through Open Cloud's
Luau Execution (300 s limit per task, so 250 s of play by default). `--speed` is the one factor that
speeds the whole game: the tide's `TimeScale`, item spawn interval and lifetimes (fresh, timed out,
loose) and the bots' walking and delays. Outputs in `tools/bots/out/`: `sweep.md` (a table per X, a
summary and the chart), `income_chart.png` (income per bot against X), `income_log.json` (for the Monte
Carlo; each entry also carries `Run`, the X), and `x<N>.json` (raw results).

The sweep builds no terrain and rolls no biomes: every tile has its zone's base layout, which is what the
bots walk and where items spawn. Each task starts a fresh server, so every bot starts with bare hands and
no coins and is still early in its game when the run ends (250 s at x10 is about 1.7 tides).

### The final-zone trip

`--final-trip` runs one bot alone, with a Hand Winch (the zone 6 tool) and a Wheelbarrow (the cheapest
vessel), on one trip to zone 6 and back,
taking zone 6 items only. It reports what the trip earned against `Config.Rebirth.BaseCost`. Prices are
not changed.

## Approximations

- Hazards (rockfall, pits, undertow, sinking sand, the gloom), waves and knock-downs don't touch bots.
- Vessel speed, stability and the tow don't matter; Magical grabbers' pulling (Tide Magnet, Bubble Wand)
  is treated as plain reach and tier; Deep Pockets adds three slots of capacity.
- Unlock items are skipped (they are banked, not sold). Pass multipliers are 1.
- Carts follow along the bot's track; their clearance on corners is checked on the grid, not simulated.
