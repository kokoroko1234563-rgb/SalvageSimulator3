# Zone 5: The Shoals (target 65 s)

**Identity.** Flooded ground between low rock bars: sandbars, fords and runnels, the water
always half in. You wade more than you walk; the tide decides which ways are open.

**Look.** Floor: Mud. Rock: weed-stained Rock (green). Fog heavier. Decor: weed mats in the
water, starfish and urchins in the pools, pebbles on the sandbars, old fence posts and nets
across fords (they were someone's).

**The frame.**
- Four low rock bars across the zone (14 tall: can't jump or see over), each with several doors.
- **The Grotto**: a roofed tunnel across the middle lane, the zone's landmark and shelter.
- Sandbars and runnels in every lane, so the ground between bars weaves.

**The paths.** Five crossings. Path counts: 2, 2, 3, 1, 2.
- Paths are split by **water**: a dry path along the sandbars (long, safe, the cart's), a wet
  path straight through the fords (short, but the fords flood early as the tide comes in and the
  undertow runs in them), and in the three-path crossing a path through the Grotto.
- The one-path crossing: the Grotto way, everything funnelled through the tunnel.
- Paths link at the bars' doors (the same door can serve two paths from either side).
- The wet path is foot-only (fords have a sill a cart can't climb).

**Dangers** (the zone's own kit, new: `Config.Zones[5].Hazards`).
- **Sinking sand that holds** (`Lethal = false`): patches across the wet path's approaches to
  fords, on dark mud. It never kills by itself: it takes you waist deep, slows you hard and
  stops you jumping for as long as you're in it. Going down at low tide that's lost seconds;
  coming back late it's what lets the sea and the undertow catch you.
- **Undertow** in every ford and runnel: deadly once the sea covers it, it drags you into the
  deep. The quick wet path is safe going down and deadly coming back late.
- **Spike pits**, well placed: open ones at the edges of fords and on corner-cutting lines,
  covered ones only where a hurried player shortcuts. A careful player walking the lane never
  meets one; a careless one does.
- No crabs: they're Hermit Hollows' own.
- A regular learns: take the fords early and the sandbars late, keep to the lanes.

**Rooms and loot.** Seven pockets against the bars: a drowned pool (floods first), a dead-end
cave, a boulder scramble, a weed-choked channel. Best finds in the caves and at the bottom of
the drowned pools (reachable only at low tide).

**Keep.** The cart route on dry ground the whole way. The rock pools clear.

**Decided.**
- No patrol crabs (Hermit Hollows keeps them); well-placed spike pits instead.
- The wet path is quite a bit quicker (75 to 80% of the target; the dry path 115 to 135%), and
  its sinking sand holds rather than kills: the sea does that.

**Questions (answered by the designer).**
1. Patrol crabs in zone 5 as well as Hermit Hollows, or keep crabs Hermit Hollows' own?
Answer: With how I talked about the patrolling crabs in the hermit hollows section, I think we should keep it to Hermit hollows, Instead I think this is where we can work with some spike pits that are well placed (will almost never catch any player that is being cautious, but can catch others.)
2. Should the wet path be quicker by a lot (tempting, 75% of the target) or a little?
Answer: It can be quite a bit quicker, but in exchange, you should not kill you by itself, instead helping the sea do that job, this will make it so that people do not really die to it when going down, but can very easily when going up too late
