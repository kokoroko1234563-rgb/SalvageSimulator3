# The kit's worked example (docs/design/layouts.md, "Building"). Run it only to try the kit:
# it overwrites zone 5 (git checkout the file afterwards).
from kit import Zone

z = Zone(5, "The Shoals", rock=14)
f = z.frame
f.hall([(-80, 260), (80, 260), (80, 340), (-80, 340)], roof=True, pillars=[(-24, 300), (24, 300)])
f.loot((0, 300), weight=4)
f.lane([(-132, 240), (-132, 300)], width=12)
f.decor("LanternPost", at=(0, 270))

c = z.crossing("Zigzag fords", paths=2)
c.ramp([(-280, 0), (-280, 120), (144, 120), (144, 470), (-200, 470), (-200, 608)])
c.lane([(-280, 120), (-280, 300), (-80, 300)], width=12)
c.lane([(80, 300), (260, 300), (260, 608)], width=12)
c.hazard("Sink", at=(144, 400), radius=12)

s = z.slot("Weed cove", at=(-180, 176), size=(96, 64), door=(48, 64))
r = s.room("Drowned pool")
r.hall([(8, 8), (88, 8), (88, 48), (8, 48)])
r.hollow((48, 28), radius=12, depth=3)
r.loot((48, 28), weight=3)

# An example only: it would replace zone 5. Write a real plan to its own file.
z.write("src/shared/Layouts/Zones/Zone5.luau")
