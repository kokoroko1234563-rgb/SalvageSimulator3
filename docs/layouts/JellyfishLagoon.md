# Jellyfish Lagoon (biome, planned; zones 2 to 6)

Drawn with the kit from `tools/kit/plans/jellyfish_lagoon.py` (edit the plan and re-run it),
written to `src/shared/Layouts/Biomes/Planned/JellyfishLagoon.luau`. Card:
`docs/design/cards/jellyfish-lagoon.md`. Decisions from the card's answers: some jellies lie
stranded on land with a sting area (radius 4, they also damage); in zones 5 and 6 the stun
applies and the whole lagoon sits under a rock ceiling.

## What was built

- **Zones 2 and 3 (open shore, no walls or rock).** A lagoon of six overlapping hollows (the
  seaward row deeper, so it floods from the sea side first) in a ring of sand (a ridge, 4.2 high in
  zone 2, 6 in zone 3), two causeways across it north to south (one has a foot-only ford cut in
  it), mud and glowing weed in the water, six loot coves round the ring (best on the sea side)
  and the entrance on the east. Two crossings (West ring, East ring): the cart's ramp swings round
  the ring on that side, feet cut across the causeways.
- **Zones 4 to 6 (rock 14, 18 and 20 high).** The lagoon is an oval cavern with the
  hollows inside and the ring floor round the rim. Each of the two crossings (East way, West way,
  mirror images) has three paths: **the ring** (the cart's ramp, snaking through a top snake,
  round the rim, a bottom snake), **the causeway** (a foot lane with a snake above, a causeway
  across the water with a foot-only ford, down), **the lagoon floor at low tide** (a foot lane with
  its own snakes, across the hollows). The foot lanes have a rubble step where they reach the
  cavern (feet clamber, carts can't). Four loot coves in rock chambers off the rim, the entrance
  in the north-east one. Zones 5 and 6: a kit roof over the whole cavern, resting on the rock rim
  with nine pillars (about 30% of the zone roofed).
- **Jellies.** Drifting ones (`Path`) in the water: 2 in each zone. Stranded ones (`At`, radius 4):
  on the ring and the causeway, 10 in zone 2 and 3 (on foot's way across), then 12 (zone 4),
  14 (zone 5), 16 (zone 6), with glowing shells at each one as the tell.

## Measured (quick check; fastest on foot against the target)

| Zone | Target | Paths (s) | Huge cart (s) |
|---|---|---|---|
| 2 | 36 | 30 / 30 / 30 (84%) | 30 |
| 3 | 38 | 30 / 30 / 30 (80%) | 30 |
| 4 | 55 | 46 (causeway) / 49 (floor) / 63 (ring) | 69 |
| 5 | 65 | 61 (causeway) / 63 (floor) / 72 (ring) | 77 |
| 6 | 85 | 76 (causeway) / 77 (floor) / 86 (ring) | 91 |

Each crossing has a Huge cart's way (the ring ramp, 16 wide, top to bottom). On the shore a cart
has to go round the ring while feet cut across.

## Test Range (one zone at a time, `--no-routes`)

- Zone 2: terrain follows (0.05 average); one spot 2.5 off at a causeway crest; buried and floating
  props are the zone's own (shell grit, lounge chairs), none of this biome's.
- Zone 3: 0.06 average, worst 2.5 (causeways widened to 16 to stop crests coming out low).
- Zone 4: 0.15 average; nothing of ours reported.
- Zone 5: 0.3 average; **open**: the roof's underside is 2.5 to 2.9 studs off its layout at some
  rows (z 2628 to 2844, at every clearance tried: 12, 14, 16, 17), tolerance 2.5; seems to be the
  terrain's 4-stud steps under a wide roof, zone 6 comes within 2.4 of it.
- Zone 6: 0.25 average, one spot 2.5 off at a pillar edge; no roof problems.

Pictures: `jellyfish-lagoon-z2.png`, `-z4.png`, `-z5.png`, `-z6.png`.
