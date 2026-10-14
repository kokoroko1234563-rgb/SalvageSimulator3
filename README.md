# Salvage Simulator 3

A physics-based Roblox game: drag items out of the tide, sell them, buy better gear.
This repo is the **Milestone 1 test build** from the design doc: the core loop only.

## Running it

The code is a [Rojo](https://rojo.space) project. The tool versions are pinned in `rokit.toml`.

```sh
rokit install          # installs rojo, selene, stylua
rojo serve             # then connect from the Rojo plugin in Studio
# or
rojo build -o SalvageSimulator3.rbxlx   # and open the file in Studio
```

The map is built from code at server start, so any empty place or Baseplate works (the
baseplate is removed). For saving to work in Studio, turn on **Game Settings → Security →
Enable Studio Access to API Services**. Without it, the game still runs but nothing is saved.
Set **Max Players to 20** in Game Settings: each player gets one vessel collision group.

Test with **Test → Clients and Servers** (2 or more players) to check bumping and ownership.

## Checks

Run `bash tools/check.sh` before pushing. It checks:

1. **Formatting:** StyLua formatting.
2. **Lint:** selene lint.
3. **Roblox API names:** `tools/check_api.py` checks every `Enum.X.Y`, class name, service and instance property against Roblox's real API. The API comes from the `@rbxts/types` npm package, downloaded once into `tools/.cache`.
4. **Lune tests:** `tools/tests/run.luau` uses [Lune](https://lune-org.github.io), which ships Roblox's API database. It loads every module the way Roblox does, runs the data validator, and builds every item, vessel, biome (decor, entrance, hazard), secret course and the beach with real instances. A wrong property, Enum item or value type (such as `nil` where a colour is needed) fails here, just as it would in Studio.
5. **Rojo build:** `rojo build` succeeds.

Two more safeguards live in the game itself:

- **Palette:** `src/shared/Palette.luau` holds every shared colour, material and font by name. Code uses `Palette.UI.Accent` or `Palette.Material.Wood`, never inline values, so one look changes in one place.
- **Data validator:** `src/shared/Validate.luau` checks that the data fits together when the server starts. For example: every secret has a coin *or* a loot table, every loot item exists, every rarity has a colour, and every ownable vessel has a builder. Problems print to Output as `[Validate]` warnings.

## What's in Milestone 1

| Doc item | Where |
| --- | --- |
| Custom waves | `src/shared/Waves.luau` is a deterministic force field from the shared clock. The server pushes loose items (`ItemService`); each client pushes its own character, held item and vessel (`WaveController`). |
| Grabbing | `GrabController` (client) and `GrabService` (server). Items are claimed when grabbed, get physics, are network-owned by the holder, become *Loose* when put down, freeze and turn *Unclaimed* after 25 s, then despawn. |
| Assist grab | Tap an item to lift it, then tap your vessel (or press **To vessel**). This works on every platform. On touch screens, a lifted item is only dropped with the **Drop** button, so panning the camera never drops it. |
| Vessels | `VesselService`: Wheelbarrow (one wheel, tips easily) and Beach Wagon (4 wheels). Wheels are visual; vessels slide on hidden low-friction ball skids. Tow them by the handle. Loaded items are welded into slots, so a vessel always holds its full capacity; they only spill if it tips over. Your client keeps your vessel upright (less so for the wheelbarrow) and parks it when you let go. Other players can't touch the vessel or what's in it (collision groups). A vessel covered by deep water is lost with everything in it, and you can spawn it again for free from your inventory, in front of you, anywhere except deep water or a secret. |
| Shop and selling | `ShopService`: shopkeeper prompt, fixed prices, Bare Hands → Grabber Claw (plus Boat Hook, so Heavy items can be tested). Drop items, or park your vessel, on the yellow sell pad. |
| Items | `src/shared/Items.luau` has 14 placeholder items across Light, Medium and Heavy, with each zone's value multiplier applied. |
| Tide | `src/shared/Tide.luau`: the sea level falls, uncovering the outer zones, holds at low tide, then rises again. The cycle is shortened ×0.4 (10 min) for testing. The sea surface and the foam line at the waterline are drawn on each client from the shared clock. There's a warning when the tide turns each way and no on-screen clock; Studio shows a debug readout in the bottom-right. |
| Drowning | `DrowningService`: you lose breath in water deeper than waist height, which moves in and out with the tide, and then take damage. What you were carrying drops when you die. |
| Saving | `DataService`: coins and gear are saved with UpdateAsync and a session lock, with retries, on PlayerRemoving, BindToClose and every 2 minutes. |

## What's in Milestone 2

| Doc item | Where |
| --- | --- |
| Biomes | `BiomeService` rolls each zone every tide cycle (test build: Sandcastle Flats or nothing, `Config.Biomes.RollChance`). A biome zone gets sandcastle decor, mostly its own loot (`Biomes.luau`), and the giant sandcastle with the secret's door. |
| Unlock item | The Golden Spade sometimes washes up in a Sandcastle Flats zone (`Config.Unlocks`). It glows, can be bumped and lost like any item, and is only safe once dropped on the purple **bank pad** at the shore. It is never sold. |
| Secret course | Use a banked spade at the sandcastle door (always used up). You go to your own copy of the Sandcastle Vault, built only on your client (`SecretController`, layout in `Secrets.luau`): a spiral climb while the sea floods in. The flood time depends on when the real tide would cover the door. `SecretService` verifies the run from your position (checkpoints in order, above the water, plausible time, at the chest) before granting the yellow coin. |
| Rebirth | In the shop: costs 100,000 coins, ×1.5 more each time. Resets coins, tools and shop vessels, adds ×0.5 coin multiplier. At each of the first 5 rebirths you pick a reward you don't have yet: Swift Feet, Deep Pockets (press **Q** or **Pocket** to pocket a Light item; pockets sell on the sell pad) or the Floating Clamshell (a magical vessel that hovers behind you). |

## True rebirth, attunement and exotic secrets

| Doc item | Where |
| --- | --- |
| Rare biome | **Shipwreck Shallows** (Uncommon tier) rolls by weight with the others (`Config.Biomes.Weights`) and is never announced. It has wreck debris, ship loot, and its hazard: barrels roll down the sand every 6 s (`Config.Hazards`), and a hit knocks what you hold out of your hands. |
| Exotic unlock item | The **Captain's Key** washes up in Shipwreck Shallows, much more rarely than common unlock items (`Config.Unlocks.ExoticSpawnChance`). It is banked like the Golden Spade. |
| Exotic secret | The **Sunken Hold**: use a banked key at the wreck's hatch. It's a zig-zag climb up a hull while it floods, and it can be repeated. It ends in a **lootbox** (`Secrets.luau`) rolling the Anchor Hook (grabber), Captain's Longboat (vessel, holds 12) or Deckhand's Satchel (accessory, +3 pocket slots), with a 1.5% chance of the **Barnacled** cosmetic variant. Rewards go straight to the inventory. |
| True rebirth | In the shop: redeem all 5 colored coins (two clicks). It resets coins, gear, rebirths, multiplier, rewards, magical vessels, colored coins and pockets. It keeps unlock items, exotic items, cores and attunements, and gives **1 attunement core**. |
| Attunement | Exotic items can't be used until you spend a core on them (**Attune** on the inventory card). Attunement is to the item type, so trading the copy away and getting another later still works. |

## Trading

Press **T** (or the orange **Trade** button). Invite anyone on the server. They get a message and can accept or decline from their trade screen.

- **Offering:** both sides offer items and coins. Only tradeable items can be offered: unlock items and exotic items. Shop gear, colored coins and attunement cores can't be traded.
- **Accepting:** any change clears both accepts and restarts a 5-second countdown (`Config.Trading`) before either player can accept.
- **The swap:** when both accept, `DataService.executeTrade` re-checks every item and coin, then swaps everything in one step. Items keep their unique id, variant and serial number. Both saves are written straight away. If anything is no longer valid, nothing changes and the trade is cancelled.
- **Coin tax:** 10% of coins in every trade leave the game. That stops players parking coins with a friend before a rebirth, and acts as a coin sink.
- **Vessels:** a vessel that changes hands is put away for its old owner.
- **Tests:** `tools/tests` cover the swap: items move rather than copy, the coin tax is applied, a replayed trade fails, and trades with shop gear, missing items or too many coins change nothing.

## Inventory

Press **I** (or the purple bag button) to open it.

- **Saving:** every owned item is its own record on the save, with a unique id (`DataService`). Later on, a copy can be traded, carry a variant or a serial number, and never be duplicated. Only `DataService.addItem` / `removeItem` / `removeItemsOfType` change items. Older saves are converted when they load.
- **Item rules:** `src/shared/Catalog.luau` gives each item type its category, rarity, whether it can be traded, and which reset removes it. Shop gear is lost on rebirth. The Floating Clamshell is lost on a true rebirth. Unlock items are never lost.
- **Cards:** the colour band is the item's rarity. The border shows when it's lost: orange on a rebirth, purple on a true rebirth, none if never. The **Reset text** setting adds the same as a line of text, and **Hide shop gear** hides tools and vessels. Both settings are saved.
- **Shop gear:** once bought, it lives in the inventory, not the shop. Tools are equipped there, and vessels are spawned there and appear in front of you.
- **Other tabs:** **Coins** shows the five colored-coin slots and attunement cores. **Rewards** shows rebirth rewards. Deep Pockets slots run along the bottom and are saved.

All tuning numbers are in `src/shared/Config.luau`, `Gear.luau` and `Items.luau`.

## Admin console

Press **F2** (or the gold **Admin** button, top right) to open it. Type `help` for every
command. Admins are: anyone in Studio, the place owner (or rank 254+ in the owning group),
and any UserId added to `Config.Admins.UserIds` in `src/shared/Config.luau`. Every command
is checked on the server, so non-admins can't use it even with exploits.

| Command | What it does |
| --- | --- |
| `status` | Tide phase, item counts, wave strength, players |
| `coins <n> [player]` / `addcoins <n> [player]` | Set or add coins |
| `vessel <vessel> [player]` | Spawn a vessel next to the player |
| `spawn <item or rarity> [count]` | e.g. `spawn rare 5`, `spawn anchor` |
| `clearitems [all]` | Remove unclaimed items (or all items) |
| `tide <out\|hold\|in> [percent]` | Jump the tide, e.g. `tide in 90` |
| `tidespeed <scale>` | 1 = real 25 min cycle, 0.1 = 2.5 min |
| `waves <multiplier>` | Wave strength, 0 = calm |
| `tp <shop\|zone\|player> [who]` | Teleport |
| `heal`, `god`, `speed <n>` | Health/breath, toggle no-drowning, walk speed |
| `resetdata <player>`, `kick <player> [reason]` | Wipe a save, kick |
| `biomes` | Show each zone's biome and the biomes that exist |
| `biome <zone\|all> <biome\|none\|reroll>` | e.g. `biome 1 sandcastle`, `biome all none`, `biome all reroll` |
| `unlock <item> [count] [player]` | Bank unlock items, e.g. `unlock goldenspade 3` |
| `colorcoin <color\|all\|none> [player]` | Give or clear colored coins |
| `rebirth [player]`, `rebirths <n> [player]` | Free rebirth (with reward pick), or set the count |
| `reward <id\|all\|none> [player]` | `swiftfeet`, `deeppockets`, `floatingclamshell` |
| `inv [player]` | List a player's inventory |
| `give <item> [player] [variant]` | Any inventory item: `give anchorhook`, `give deckhandssatchel me Barnacled` |
| `cores <n> [player]` | Set attunement cores |
| `attune <item\|all\|none> [player]` | Attune without spending a core |
| `truerebirth [player]` | True rebirth without needing the 5 coins |

Players can be `me` (default), `all`, `others`, or the start of a name. Up/Down recalls history.

## Layout

```
            dunes
   +--------------------------+   Z < 0: shop, sell pad, bank pad (flat)
   |  shop   sell   vessels   |
 ==+==========================+== Z = 0: top of the beach
   |  zone 1  Shopside Shore  |   the sand slopes gently down toward +Z
   |..........................|   <- waterline at high tide (Z = 60)
   |  zone 2  Sunny Stretch   |
   |                          |
   |  zone 3  Middle Banks    |
   |..........................|   <- waterline at low tide (Z = 560)
   |  open sea                |
   +--------------------------+
 headland     X ->     headland
```

The shoreline runs along X (320 studs wide, between two rocky headlands). The zones are
200-stud bands running out to sea along +Z. The sand slopes down 0.06 studs per stud, so
the tide is simply the sea level rising and falling: as it drops, the waterline moves out
and uncovers the richer zones. Items wash up in the surf around the current waterline, and
their zone (value and rarity) depends on where they land. Water depth sets the bands:
shallow < 1.5, knee-deep < 3, waist < 4.5, and deep (drowning, vessels lost) beyond that.

## Known simplifications

- Your own character passes through your vessel, as well as other players' vessels. Giving each player a separate character group would need 40+ collision groups, and Roblox allows 32.
- Unclaimed items sit still. They don't follow scripted movement in the surf yet.
- The sea is a visual-only part; depth comes from the sea level and the beach slope. There is no terrain water or swimming.
- The server doesn't check character walk speed yet. Held items are leashed by distance and speed.
