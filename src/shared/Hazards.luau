-- Hazards: a few generic kinds built from data, each with its own settings: a biome's
-- (Biomes.List[id].Hazards), or a plain zone's (Config.Zones[i].Hazards) where no biome rolled.
-- Where they go comes from the zone's layout (its Hazards list, by Type); without placements, a
-- biome's are scattered over the zone (Scatter), a plain zone's aren't built.
--
--   Roller  something rolls down the tile toward the sea every Period seconds, at Speed (the
--           Shipwreck Shallows barrels). Placement: Lanes = { x, ... } it can start from.
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
--   Hunter  a big creature (the giant hermit crab) that patrols its Path at Speed and hunts,
--           always on its route, like a rail: it sees a player ahead within SightRange
--           (LightRange if they carry a light) with nothing in the way, and chases at
--           ChaseSpeed, no further than Leash from where it began. Two moves, both telegraphed:
--           the dash (someone within DashRange ahead: it rears up, eyes red, for DashWarn
--           seconds, charges at DashSpeed up to DashDistance, then stands DashRecover seconds),
--           and the dig (losing sight of them, or every DigEvery seconds while they're more than
--           DigAway along its route, or called by a patrol crab: it burrows in a cloud of dust
--           for DigTime seconds and comes out of the burrow hole nearest them after UnderTime
--           more, the hole shaking and spurting sand all that while). Placement: Path, and
--           Hunting no one, every RoamEvery seconds it digs to the burrow nearest the latest
--           sighting its patrol crabs passed on (any crab that sees someone tells it; within
--           Hunch seconds), or another burrow if there's none: it's never far from players.
--           It knows only what it sees: out of sight, it heads for where they were going
--           (Predict seconds on from where it last saw them), and someone it can see but not
--           reach (off its route) it gives up on after GiveUp seconds, for Ignore seconds.
--           Burrows = { {x, z}, ... } (on its route); without Burrows, its route's ends and
--           middle; without a Path, the layout's longest Patrol route.
--   Gloom   a living, magical darkness (the Drowned Reach's): something unseen that roams
--           its Path at Speed (or lurks At a spot), casting a shadow Radius studs across on the
--           floor under it. Step into the shadow and you're Benighted for Duration seconds:
--           the world goes black, and you see only lights (a lantern or headlamp shows you your
--           own surroundings). Within a GloomWard's light (glowing decor) it wears off
--           WardCure times faster. Placement: Path or At, Radius.
--
-- What a hazard does to a player who gets within HitRadius of it is its Effect:
--   Knockdown  knocked over (you drop what you hold) and thrown Push studs/s away from it.
--   Drop       what you hold is knocked out of your hands.
--   Slow       slowed (Slow hazards).
--   Sink       slowed, and swallowed if you stay in it (Sink hazards).
--   Current    dragged along (Undertow hazards): into deep water, where you drown.
--   Harm       Damage taken (100 kills), and thrown Push studs/s away from it.
--   Gloom      Benighted: the world goes dark around you for a while (Gloom hazards).
-- Dangers are meant to be deadly: a hazard that only slows you is scenery.
-- The server builds and moves the hazards (HazardService); each player's own client checks its
-- character against them and applies the effect (HazardController), like the waves.

local Hazards = {}

Hazards.Tag = "Hazard" -- CollectionService tag on the part a hazard hits with

Hazards.Effects =
	{ Knockdown = true, Drop = true, Slow = true, Sink = true, Current = true, Harm = true, Gloom = true }

Hazards.WardTag = "GloomWard" -- a light the Gloom can't reach: a part with a WardRadius attribute

-- Each kind's settings and their defaults. A biome's entry overrides any of them.
Hazards.Types = {
	Roller = {
		Period = 6,
		Speed = 16,
		Size = Vector3.new(3, 2.6, 2.6),
		Color = Color3.fromRGB(120, 80, 45),
		Effect = "Drop",
		HitRadius = 2.2,
		Push = 0,
		HitText = "Something rolled into you and knocked it out of your hands!",
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
}

-- Every kind may set Scatter: whether it's scattered over a zone without placements.
for _, defaults in Hazards.Types do
	defaults.Scatter = true
end

-- What a placement in a layout's Hazards list may hold, by kind.
Hazards.Placement = {
	Roller = { Lanes = true },
	Patrol = { Path = true, Count = true },
	Pulse = { At = true },
	Slow = { At = true, Radius = true },
	Sink = { At = true, Radius = true, Lethal = true },
	Rockfall = { At = true, Radius = true },
	Pit = { At = true, Radius = true, Depth = true, Covered = true },
	Undertow = { Path = true, Width = true },
	Gloom = { Path = true, At = true, Radius = true },
	Hunter = { Path = true, Burrows = true },
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
