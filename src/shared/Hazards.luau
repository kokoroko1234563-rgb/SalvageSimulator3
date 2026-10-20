-- Hazards: a few generic kinds built from data, each with its own settings: a biome's
-- (Biomes.List[id].Hazards), or a plain zone's (Config.Zones[i].Hazards) where no biome rolled.
-- Where they go comes from the zone's layout (its Hazards list, by Type); without placements, a
-- biome's are scattered over the zone (Scatter), a plain zone's aren't built.
--
--   Roller  every Period seconds a barrel (the Shipwreck Shallows') appears at the top of one
--           of its routes and teeters there Warning seconds, dust falling (the tell), then
--           rolls down it at Speed: it bowls over whoever it hits, tumbling and dropping what
--           they hold (not deadly itself). Placement: Path = { {x, z}, ... } (from the wreck's
--           deck down a gully), or Lanes = { x, ... } (straight down the zone from the top).
--   Patrol  Count creatures walk a route back and forth at Speed (hermit crabs). Placement:
--           Path = { {x, z}, ... }; without one, each wanders around where it starts. With
--           Calls, one that sees someone within CallRange ahead (CallAngle across) stops and
--           drums its claws, a ring pulsing round it, for CallTime seconds: still seen then, it
--           calls the tile's Hunter, which digs to the burrow nearest the caller (only CallChance
--           of sightings, none while the Hunter is already hunting, and one call per tile every
--           CallShared seconds).
--   Pulse   a spot erupts for Active seconds every Period, after Warning seconds of warning
--           (vents, blowholes). Placement: At = {x, z}.
--   Slow    a patch that slows you to Factor of your speed while you're in it (sea glass,
--           tangled seagrass). Placement: At = {x, z}, Radius.
--   Sink    sinking sand: an irregular patch (Radius, in Lobes) that slows you to Factor and
--           stops you jumping, and you visibly sink while you're in it: in SinkTime seconds
--           standing still it swallows you (Damage: 100 kills), moving you sink at MovingShare
--           of that, so wading straight across is tight and stopping is death. Out of it you
--           climb back up. Its tell is dark, wet sand with the odd bubble. Placement: At, Radius.
--   Rockfall  a stretch of roof that's coming down: an area Radius studs across, strewn with
--           old rubble (the tell). On a rhythm a regular can learn: every Interval seconds a
--           boulder falls, sweeping along the area's open ground and back, or now and then
--           (Aimed) where someone inside is standing; every BurstEvery seconds, after Rumble
--           seconds of dust pouring over the whole area, a Burst falls along the sweep. Each is
--           warned Warning seconds ahead by trickling dust and a dark shadow, full size, where
--           it will land (it never follows you: moving away always works); it Harms whoever is
--           within RockRadius, then lies there Lie seconds. Placement: At, Radius.
--   Pit     a spike pit: a hole Radius across and Depth deep cut into the ground, spikes at the
--           bottom (Harm, Damage: 100 kills). Open, you see it; Covered, a false floor of the
--           ground's own sand hides it (a few cracks are its only tell) and gives way under
--           whoever steps on it, coming back Reset seconds later. Placement: At, Radius,
--           Depth, Covered (true or false; without it, the kind's Covered).
--   Undertow  while the sea covers it (deeper than MinDepth), a current along a ford or
--           channel drags you toward the sea at Strength studs/s. Placement: Path, Width.
--   Hunter  a big creature (the giant hermit crab) that keeps to its tunnels and hunts in them
--           like a ghost in a maze: its Routes (paths that meet at junctions, or one Path) are
--           the only ground it walks; at each junction it takes the shortest way through them
--           toward where it thinks you are (it knows the tunnels, not where you are: only what
--           it sees, or where it guesses you went, Predict seconds on from where it last saw
--           you), turning back along a run when it must; hunting no one, it wanders them. It
--           sees a player ahead within SightRange (LightRange if they carry a light) with
--           nothing in the way and chases at ChaseSpeed; someone it can see but can't reach it
--           gives up on after GiveUp seconds, for Ignore seconds. Two moves, both telegraphed:
--           the dash (someone within DashRange ahead: it rears up, eyes red, DashWarn seconds,
--           charges at DashSpeed up to DashDistance, then stands DashRecover seconds), and the
--           dig (losing sight of them, every DigEvery seconds while they're more than DigAway
--           along its tunnels, every RoamEvery seconds hunting no one (toward the latest
--           sighting its patrol crabs passed on, within Hunch seconds), or called by a patrol
--           crab: it burrows in a cloud of dust for DigTime seconds and comes up at the burrow
--           nearest where it's going UnderTime later, the hole shaking and spurting sand all
--           that while). Placement: Routes = { path, ... } or Path, and Burrows = { {x, z}, ... }
--           (on its tunnels, flush churned patches); without Burrows, its tunnels' ends and
--           junctions; without a Path, the layout's longest Patrol route.
--   Gloom   a living, magical darkness (the Drowned Reach's): something unseen that roams
--           its Path at Speed (or lurks At a spot), casting a shadow Radius studs across on the
--           floor under it. Step into the shadow (outside a GloomWard's light: glowing decor)
--           and you're Benighted until you die or leave the deep (zones 5 and 6): the world goes
--           black, and you see only lights (a lantern or headlamp shows you your own
--           surroundings, and the wards light the way). Placement: Path or At, Radius.
--   Jelly   (Jellyfish Lagoon) translucent glowing jellies, pulsing. Placement At: one stranded
--           on the sand, its glow ring on the sand showing how far its sting reaches (Radius);
--           Path: one drifting along it in the water at Speed (HitRadius round it). Placement
--           Damage overrides the setting. Effect Sting.
--   Spears  (Spearstone Reef) a field (At, Radius) of spots Spacing studs apart, on a rhythm of
--           Period seconds set by Pattern: Wave (a wave rolling across the field, west to east:
--           run behind it), Checker (alternate squares, half a Period apart: hop between), Ring
--           (rings from the middle out), All (every spot together). Each spot glows and cracks
--           for Warning seconds, then a stone spear shoots up for Active seconds and Harms
--           (Damage; a placement's Damage overrides it: less in the near zones). Placement: At,
--           Radius, Pattern, Damage.
--   Whirlwind  (Whirlwind Dunes) a column of lifted sand Height studs tall, Radius wide at its
--           foot, circling its Path (a loop: round and round, not back and forth) at Speed.
--           Whoever it catches is flung (effect Fling), not hurt. Placement: Path, Radius.
--   Ice     (Stranded Iceberg) a patch (At, Radius) of slippery ice, flat, glossy and pale
--           blue-white. On it you slide (effect Slide, Grip). Nothing else: no cart spilling.
--
-- What a hazard does to a player who gets within HitRadius of it is its Effect:
--   Knockdown  knocked over (you drop what you hold) and thrown Push studs/s away from it.
--   Drop       what you hold is knocked out of your hands.
--   Slow       slowed (Slow hazards).
--   Sink       slowed, and swallowed if you stay in it (Sink hazards).
--   Current    dragged along (Undertow hazards): into deep water, where you drown.
--   Harm       Damage taken (100 kills), and thrown Push studs/s away from it.
--   Gloom      Benighted: the world goes dark around you until you die or leave the deep.
--   Sting      Damage taken (checked like Harm), you drop what you hold, a small push, and in
--              zones StunZone and deeper you're stunned Stun seconds (can't move).
--   Fling      thrown Push studs/s up and away from the hazard, tumbling, dropping what you
--              hold; not deadly itself (Whirlwind).
--   Slide      slippery (Ice): your movement keeps its momentum and turns slowly; Grip is the
--              share of control you keep (the less, the slipperier).
--   Fog        the mist thickens to Sight studs while you're on the tile (Fog); a foghorn
--              pulse lifts it for Clear seconds every Period.
-- Dangers are meant to be deadly: a hazard that only slows you is scenery.
-- The server builds and moves the hazards (HazardService); each player's own client checks its
-- character against them and applies the effect (HazardController), like the waves.

local Hazards = {}

Hazards.Tag = "Hazard" -- CollectionService tag on the part a hazard hits with

Hazards.Effects = {
	Knockdown = true,
	Drop = true,
	Slow = true,
	Sink = true,
	Current = true,
	Harm = true,
	Gloom = true,
	Sting = true, -- damage, drop what you hold, and in the deep a stun (Jelly)
	Fog = true, -- the fog closes in round you (Fog)
	Fling = true, -- thrown and tumbling, dropping what you hold (Whirlwind)
	Slide = true, -- slippery: you slide, slow to stop and turn (Ice)
}

Hazards.WardTag = "GloomWard" -- a light the Gloom can't reach: a part with a WardRadius attribute

-- Each kind's settings and their defaults. A biome's entry overrides any of them.
Hazards.Types = {
	Roller = {
		Period = 6,
		Warning = 2, -- seconds it teeters at the top of its gully, dust falling, before it goes
		Speed = 20,
		Size = Vector3.new(4, 3.4, 3.4),
		Color = Color3.fromRGB(120, 80, 45),
		Effect = "Knockdown", -- bowled over, tumbling, dropping what you hold: not deadly itself
		HitRadius = 2.6,
		Push = 45,
		HitText = "A barrel bowled you over!",
	},
	Patrol = {
		Count = 3,
		Speed = 6,
		Size = Vector3.new(4, 2.4, 3.4),
		Color = Color3.fromRGB(196, 90, 60),
		Effect = "Knockdown",
		HitRadius = 3,
		Push = 30,
		Wander = 30, -- studs a creature without a Path wanders from where it starts
		Calls = false, -- whether it calls the Hunter when it sees someone
		CallRange = 26,
		CallAngle = 100, -- degrees across the cone it watches, ahead of it
		CallTime = 2, -- seconds of drumming before the call goes out
		CallCooldown = 10,
		CallChance = 0.5, -- the share of sightings it drums for at all
		CallShared = 25, -- seconds after a call before any crab on the tile calls again
		HitText = "You got knocked over!",
	},
	Pulse = {
		Count = 3,
		Period = 8,
		Warning = 1.5,
		Active = 1.2,
		Radius = 5,
		Color = Color3.fromRGB(230, 230, 220),
		Effect = "Knockdown",
		HitRadius = 5,
		Push = 40,
		HitText = "It erupted under you!",
	},
	Slow = {
		Count = 4,
		Radius = 10,
		Factor = 0.5,
		Color = Color3.fromRGB(150, 210, 200),
		Effect = "Slow",
		HitRadius = 10,
		Push = 0,
		HitText = "",
	},
	Sink = {
		Count = 3,
		Radius = 12,
		Lobes = 4, -- the patch is a blob of this many round lobes around its middle
		Factor = 0.4,
		SinkTime = 4, -- seconds standing still until it swallows you
		MovingShare = 0.6, -- how fast you sink while moving, as a share of standing still
		Lethal = true, -- false: it holds you (waist deep, slow, no jumping) but never swallows you
		Damage = 100,
		Color = Color3.fromRGB(84, 72, 54),
		Effect = "Sink",
		HitRadius = 12,
		Push = 0,
		HitText = "The sand swallowed you!",
	},
	Rockfall = {
		Count = 3,
		Radius = 12, -- the area the rock comes down on
		Interval = 1.6, -- seconds between falls (a steady beat)
		Burst = 3, -- this many fall one after another along the sweep...
		BurstEvery = 12, -- ...every this many seconds
		Rumble = 2, -- seconds of dust pouring over the whole area before a burst
		Aimed = 0.35, -- the share of falls dropped where someone inside is standing
		Warning = 1.8, -- seconds of dust and a full-size shadow before a rock lands
		Active = 0.3,
		Lie = 3, -- seconds a fallen boulder lies there before it crumbles
		RockRadius = 5.5, -- the boulder harms whoever is this close to where it lands
		Damage = 100,
		Color = Color3.fromRGB(90, 88, 84),
		Effect = "Harm",
		HitRadius = 5.5,
		Push = 20,
		HitText = "Crushed by falling rock!",
	},
	Pit = {
		Count = 2,
		Radius = 5,
		Depth = 12,
		Covered = false,
		Reset = 10, -- seconds before a broken cover is whole again
		Damage = 100,
		Color = Color3.fromRGB(150, 145, 135), -- the spikes
		Effect = "Harm",
		HitRadius = 5,
		Push = 0,
		HitText = "Impaled on the spikes!",
	},
	Undertow = {
		Count = 2,
		Width = 12,
		Strength = 20, -- under KnockdownPush: it drags, it doesn't throw
		MinDepth = 0.6,
		Color = Color3.fromRGB(200, 235, 240),
		Effect = "Current",
		HitRadius = 6,
		Push = 0,
		HitText = "",
	},
	Hunter = {
		Count = 1,
		Speed = 5,
		ChaseSpeed = 16, -- a player running flat out (20) can outpace it, in the open
		SightRange = 36,
		LightRange = 75, -- how far it sees someone carrying a light
		SightAngle = 120, -- degrees across the cone it sees in, ahead of it (behind it is blind)
		FeelRange = 8, -- this close, it notices you from any side
		LoseTime = 2.5,
		Leash = 90,
		DashRange = 30, -- someone this close ahead, it dashes
		DashWarn = 0.8, -- seconds it rears up first
		DashSpeed = 42,
		DashDistance = 36,
		DashRecover = 1.2, -- seconds it stands after a dash: the chance to get away
		DashCooldown = 5,
		DigTime = 1.5, -- seconds burrowing (dust where it goes down)
		UnderTime = 1, -- seconds under before it comes up (the hole's been shaking since the dig began)
		EmergeTime = 0.6,
		DigEvery = 15,
		DigAway = 40, -- studs along its route someone must be for it to dig after them
		Predict = 1.5, -- seconds on from where it last saw someone that it guesses they went
		GiveUp = 4, -- seconds it waits on someone it can see but can't reach (off its route)
		Ignore = 10, -- seconds it then leaves them be
		RoamEvery = 10, -- hunting no one, it digs to a new spot this often...
		Hunch = 20, -- ...near the latest sighting the patrol crabs passed on, if this recent
		Size = Vector3.new(12, 6, 10),
		Color = Color3.fromRGB(176, 72, 52),
		Damage = 100,
		Effect = "Harm",
		HitRadius = 6.5,
		Push = 40,
		HitText = "The giant crab got you!",
	},
	Gloom = {
		Count = 2,
		Radius = 9, -- its shadow
		Speed = 7, -- studs/s along its Path: a slow walk, so it can be watched and dodged
		Duration = 30, -- seconds you stay Benighted after its shadow touches you
		WardCure = 4, -- how much faster it wears off in a ward's light
		Color = Color3.fromRGB(6, 5, 12),
		Effect = "Gloom",
		HitRadius = 9,
		Push = 0,
		HitText = "The Gloom's shadow fell on you: find the light!",
	},
	-- The planned biomes' dangers (their behaviour is being built: HazardService).
	Jelly = { -- Jellyfish Lagoon: jellies drifting in the water or stranded on the sand
		Count = 6,
		Radius = 4, -- a stranded jelly's sting reaches this far round it (its glow shows it)
		Speed = 3, -- drifting along its Path
		Damage = 25,
		Stun = 1.5, -- seconds stunned by a sting in zones 5 and 6 (StunZone and deeper)
		StunZone = 5,
		Color = Color3.fromRGB(190, 140, 255),
		Effect = "Sting",
		HitRadius = 4,
		Push = 10,
		HitText = "A jellyfish stung you!",
	},
	Fog = { -- Fog Bank: the fog thickens to a few studs' sight; a foghorn clears it for a moment
		Count = 1,
		Sight = 12, -- studs you see in it
		Period = 25, -- seconds between foghorn pulses
		Clear = 5, -- seconds a pulse clears it for
		Color = Color3.fromRGB(215, 220, 225),
		Effect = "Fog",
		HitRadius = 0,
		Push = 0,
		HitText = "",
	},
	Whirlwind = { -- Whirlwind Dunes: a whirlwind circling its Path, flinging whoever it catches
		Count = 1,
		Radius = 10,
		Height = 45, -- the column of sand: tall enough to see from far off
		Speed = 9,
		Color = Color3.fromRGB(220, 190, 140),
		Effect = "Fling",
		HitRadius = 10,
		Push = 70,
		HitText = "The whirlwind threw you!",
	},
	Spears = { -- Spearstone Reef: fields of spears shooting up from the floor on a rhythm
		Count = 2,
		Radius = 12, -- a field
		Pattern = "Wave", -- Wave (rolls across the field), Checker (alternating squares), Ring (outward from the middle), All
		Spacing = 5, -- studs between the spots of a field
		Period = 4,
		Warning = 1, -- seconds a spot glows and cracks before its spear shoots up
		Active = 0.6,
		Damage = 100, -- (layouts set less in the near zones)
		Color = Color3.fromRGB(60, 70, 80),
		Effect = "Harm",
		HitRadius = 2,
		Push = 20,
		HitText = "A spearstone got you!",
	},
	Ice = { -- Stranded Iceberg: slippery ice: you slide, slow to stop and turn
		Count = 3,
		Radius = 16,
		Grip = 0.15, -- how much grip you keep on it (1: none lost)
		Color = Color3.fromRGB(200, 230, 245),
		Effect = "Slide",
		HitRadius = 16,
		Push = 0,
		HitText = "",
	},
}

-- Every kind may set Scatter: whether it's scattered over a zone without placements.
for _, defaults in Hazards.Types do
	defaults.Scatter = true
end

-- What a placement in a layout's Hazards list may hold, by kind.
Hazards.Placement = {
	Roller = { Lanes = true, Path = true },
	Patrol = { Path = true, Count = true },
	Pulse = { At = true },
	Slow = { At = true, Radius = true },
	Sink = { At = true, Radius = true, Lethal = true },
	Rockfall = { At = true, Radius = true },
	Pit = { At = true, Radius = true, Depth = true, Covered = true },
	Undertow = { Path = true, Width = true },
	Gloom = { Path = true, At = true, Radius = true },
	Hunter = { Path = true, Routes = true, Burrows = true },
	Jelly = { At = true, Path = true, Radius = true, Damage = true },
	Fog = { At = true },
	Whirlwind = { Path = true, Radius = true },
	Spears = { At = true, Radius = true, Pattern = true, Damage = true },
	Ice = { At = true, Radius = true },
}

-- A biome's hazard entry with every setting filled in from its kind's defaults.
function Hazards.settings(entry: { [string]: any }): { [string]: any }
	local defaults = Hazards.Types[entry.Type]
	local settings = table.clone(defaults or {})
	for key, value in entry do
		settings[key] = value
	end
	return settings
end

-- What's wrong with a biome's hazard entry (empty: nothing).
function Hazards.problems(entry: any, where: string): { string }
	local problems = {}
	if type(entry) ~= "table" or not Hazards.Types[entry.Type] then
		table.insert(
			problems,
			where .. ": unknown hazard type " .. tostring(type(entry) == "table" and entry.Type)
		)
		return problems
	end
	local defaults = Hazards.Types[entry.Type]
	for key, value in entry do
		if key ~= "Type" and defaults[key] == nil then
			table.insert(problems, where .. " (" .. entry.Type .. "): unknown setting " .. tostring(key))
		elseif key ~= "Type" and typeof(value) ~= typeof(defaults[key]) then
			table.insert(
				problems,
				where .. " (" .. entry.Type .. "): " .. key .. " should be a " .. typeof(defaults[key])
			)
		end
	end
	local settings = Hazards.settings(entry)
	if not Hazards.Effects[settings.Effect] then
		table.insert(problems, where .. ": unknown effect " .. tostring(settings.Effect))
	end
	return problems
end

return Hazards
