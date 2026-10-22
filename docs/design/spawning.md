# Item spawning

How free items appear on the beach (`src/server/ItemService.luau`; numbers in `Config.Zones` and
`Config.Items`). Loot spots and the layouts that hold them are in `layouts.md`.

## The rule

Every zone, 1 to 7 (the Far Sandbar included), keeps its own supply of free items:

- **Count.** The items lying in the zone that are Unclaimed or Loose, on sand or in the surf (not in
  deep water). Held and InVessel items don't count.
- **Target.** `Config.Zones[i].Target` free items on a solo server.
- **Rate.** Each spawn tick (`Config.Items.SpawnInterval`, 1.25 s) a zone spawns `MaxRate * interval *
  (target - count) / target` items on average: the emptier, the faster, up to `MaxRate` per second when
  empty, and nothing at or above the target. (More than one a tick only at a high rate; the fraction is a
  chance.)
- **No shared budget.** A zone only looks at its own count. Dropping items in one zone can't speed up
  another, and a zone cannot starve because the waterline is elsewhere.
- **What it spawns is unchanged.** Rarity, tier, biome loot and the unlock items are rolled by
  `chooseDef` exactly as before. Emptiness changes how often a zone spawns, never what.

## Where

- **Zones 1 to 3 (`SpawnOnSand = true`):** a spawn lands on the zone's open sand at any point of the tide
  (not under the sea, not rock, not under a roof, not on a slope a player can't walk), or, when the
  waterline is in the zone, with chance `Config.Items.SurfShare` in its surf.
- **Zones 4 to 6 and the Far Sandbar:** only the wet sand and surf around the waterline (as before), so
  they refill only while the water is in or near them. When it isn't, an attempt finds no point.
- **Open-sand spawns are ordinary items only.** No unlock item and no Beacon Pearl (`chooseDef`'s
  `ordinary` option); the zone's biome loot is allowed. Unlock items and the pearl only come from surf
  spawns.
- Loot spots (`settleSpots`) are unchanged: once each tide, not counted against the target.

## Crowds

`Config.Items.CrowdSpawn` (players plus bots, `setBotCount`) multiplies every zone's target and its max
rate, linear from 1 at one player to `Scale` at `Players`. `Config.Items.MaxTotal` stops all spawning
when the map holds that many items.

## Default numbers

Chosen so a solo server makes about as many items per tide as the old single-surf spawner. Measured
with `lune run tools/spawn_sim.luau` (a tide is 1500 s; nobody collects; items live their real
lifetimes):

| zone | 1 | 2 | 3 | 4 | 5 | 6 | 7 | all |
|---|---|---|---|---|---|---|---|---|
| spawned per tide, before | 226 | 128 | 106 | 143 | 103 | 146 | 95 | 947 |
| spawned per tide, now | 226 | 161 | 122 | 131 | 119 | 173 | 89 | 1019 |
| target / max rate (per s) | 80 / 0.4 | 55 / 0.4 | 45 / 0.4 | 70 / 1.2 | 45 / 1.2 | 60 / 1.2 | 40 / 1.2 | |

(Loot-spot finds, about 29 a tide, are in the totals.) At 20 players the same run makes about 2,900 a
tide, 2.9 times as many.

The outer zones can only fill while the water is in them, so they get a high max rate and a target that
the window of the tide fills. The inner three fill all the time, so a low rate is enough.
