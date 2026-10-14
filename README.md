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
| Vessels | `VesselService`: Wheelbarrow (one wheel, tips easily) and Beach Wagon (4 wheels). Tow them by the handle. Items fall out when the vessel spills, and other players can't touch the vessel or what's in it (collision groups). A vessel covered by deep water is lost with everything in it, and you can respawn it free at the shop. |
| Shop and selling | `ShopService`: shopkeeper prompt, fixed prices, Bare Hands → Grabber Claw (plus Boat Hook, so Heavy items can be tested). Drop items, or park your vessel, on the yellow sell pad. |
| Items | `src/shared/Items.luau` has 14 placeholder items across Light, Medium and Heavy, with each zone's value multiplier applied. |
| Tide | `src/shared/Tide.luau`: the tide travels down the beach, holds, then returns, over 3 zones. The cycle is shortened ×0.4 (10 min) for testing. There's a warning when the tide turns each way and no on-screen clock; Studio shows a debug readout in the bottom-right. |
| Drowning | `DrowningService`: you lose breath in deep water (far out, or under the tide) and then take damage. What you were carrying drops when you die. |
| Saving | `DataService`: coins and gear are saved with UpdateAsync and a session lock, with retries, on PlayerRemoving, BindToClose and every 2 minutes. |

All tuning numbers are in `src/shared/Config.luau`, `Gear.luau` and `Items.luau`.

## Layout

The beach runs along +X from the shop (X = 0). Each zone is 400 studs. The waterline is at
Z = 0 and the sea is toward +Z. Depth bands are measured out from the waterline:
shallow < 15, knee-deep < 30, waist < 45, and deep (drowning) beyond that.

## Known simplifications

- Your own character passes through your vessel, as well as other players' vessels. Giving each player a separate character group would need 40+ collision groups, and Roblox allows 32.
- Unclaimed items sit still. They don't follow scripted movement in the surf yet.
- Deep water is a gameplay region with a visual-only water part. There is no terrain water or swimming.
- The server doesn't check character walk speed yet. Held items are leashed by distance and speed.
