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

## What's in Milestone 1

| Doc item | Where |
| --- | --- |
| Custom waves | `src/shared/Waves.luau` is a deterministic force field from the shared clock. The server pushes loose items (`ItemService`); each client pushes its own character, held item and vessel (`WaveController`). |
| Grabbing | `GrabController` (client) and `GrabService` (server). Items are claimed when grabbed, get physics, are network-owned by the holder, become *Loose* when put down, freeze and turn *Unclaimed* after 25 s, then despawn. |
| Assist grab | Tap an item to lift it, then tap your vessel (or press **To vessel**). This works on every platform. |
| Vessels | `VesselService`: Wheelbarrow (one wheel, tips easily) and Beach Wagon (4 wheels). Wheels are visual; vessels slide on hidden low-friction ball skids. Tow them by the handle. Loaded items are welded into slots, so a vessel always holds its full capacity; they only spill if it tips over. Your client keeps your vessel upright (less so for the wheelbarrow) and parks it when you let go. Other players can't touch the vessel or what's in it (collision groups). A vessel covered by deep water is lost with everything in it, and you can respawn it free at the shop. |
| Shop and selling | `ShopService`: shopkeeper prompt, fixed prices, Bare Hands → Grabber Claw (plus Boat Hook, so Heavy items can be tested). Drop items, or park your vessel, on the yellow sell pad. |
| Items | `src/shared/Items.luau` has 14 placeholder items across Light, Medium and Heavy, with each zone's value multiplier applied. |
| Tide | `src/shared/Tide.luau`: the sea level falls, uncovering the outer zones, holds at low tide, then rises again. The cycle is shortened ×0.4 (10 min) for testing. The sea surface and the foam line at the waterline are drawn on each client from the shared clock. There's a warning when the tide turns each way and no on-screen clock; Studio shows a debug readout in the bottom-right. |
| Drowning | `DrowningService`: you lose breath in water deeper than waist height, which moves in and out with the tide, and then take damage. What you were carrying drops when you die. |
| Saving | `DataService`: coins and gear are saved with UpdateAsync and a session lock, with retries, on PlayerRemoving, BindToClose and every 2 minutes. |

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
| `give <tool or vessel> [player]` | e.g. `give boathook`, `give beachwagon` |
| `vessel <vessel> [player]` | Spawn a vessel next to the player |
| `spawn <item or rarity> [count]` | e.g. `spawn rare 5`, `spawn anchor` |
| `clearitems [all]` | Remove unclaimed items (or all items) |
| `tide <out\|hold\|in> [percent]` | Jump the tide, e.g. `tide in 90` |
| `tidespeed <scale>` | 1 = real 25 min cycle, 0.1 = 2.5 min |
| `waves <multiplier>` | Wave strength, 0 = calm |
| `tp <shop\|zone\|player> [who]` | Teleport |
| `heal`, `god`, `speed <n>` | Health/breath, toggle no-drowning, walk speed |
| `resetdata <player>`, `kick <player> [reason]` | Wipe a save, kick |

Players can be `me` (default), `all`, `others`, or the start of a name. Up/Down recalls history.

## Layout

```
            dunes
   +--------------------------+   Z < 0: shop, sell pad, vessel pad (flat)
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
