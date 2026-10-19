-- Hazards: a few generic kinds built from data, each with its own settings: a biome's
-- (Biomes.List[id].Hazards), or a plain zone's (Config.Zones[i].Hazards) where no biome rolled.
-- Where they go comes from the zone's layout (its Hazards list, by Type); without placements, a
-- biome's are scattered over the zone (Scatter), a plain zone's aren't built.
--
--   Roller  something rolls down the tile toward the sea every Period seconds, at Speed (the
--           Shipwreck Shallows barrels). Placement: Lanes = { x, ... } it can start from.
--   Patrol  Count creatures walk a route back and forth at Speed (hermit crabs). Placement:
--           Path = { {x, z}, ... }; without one, each wanders around where it starts.
--   Pulse   a spot erupts for Active seconds every Period, after Warning seconds of warning
--           (vents, blowholes). Placement: At = {x, z}.
--   Slow    a patch that slows you to Factor of your speed while you're in it (sea glass,
--           tangled seagrass). Placement: At = {x, z}, Radius.
--   Sink    sinking sand: slows you to Factor, and you sink while you're in it: in SinkTime
--           seconds standing still (several times that if you keep moving), it swallows you
--           (Damage: 100 kills). Out of it you climb back up. Its tell is darker, wet-looking
--           sand. Placement: At = {x, z}, Radius.
--   Rockfall  rock falls from the roof every Period seconds, after Warning seconds of dust and
--           pebbles trickling down; it Harms whoever it lands on. Placement: At = {x, z}.
--   Undertow  while the sea covers it (deeper than MinDepth), a current along a ford or
--           channel drags you toward the sea at Strength studs/s. Placement: Path, Width.
--   Hunter  a big creature (the giant hermit crab) that patrols its Path at Speed and hunts:
--           it sees a player within SightRange (LightRange if they carry a light) with nothing
--           in the way, chases at ChaseSpeed, gives up LoseTime seconds after losing sight of
--           them or Leash studs from its route, and walks back the way it came. Placement:
--           Path; without one it takes the layout's longest Patrol route.
--   Gloom   a living, magical darkness (the Drowned Reach's): an inky fog Radius studs across
--           that drifts along its Path at Speed (or lies still At a spot), and swells by Swell
--           once the tide turns. Inside it your dread rises: in Fill seconds it takes you
--           (Damage), in LightFill if you carry a light. Out of it, or within a GloomWard's
--           light (glowing decor), it drains. Placement: Path or At, Radius.
--
-- What a hazard does to a player who gets within HitRadius of it is its Effect:
--   Knockdown  knocked over (you drop what you hold) and thrown Push studs/s away from it.
--   Drop       what you hold is knocked out of your hands.
--   Slow       slowed (Slow hazards).
--   Sink       slowed, and swallowed if you stay in it (Sink hazards).
--   Current    dragged along (Undertow hazards): into deep water, where you drown.
--   Harm       Damage taken (100 kills), and thrown Push studs/s away from it.
--   Gloom      dread rising while you're in it (Gloom hazards); full, it takes you (Damage).
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
		Radius = 8,
		Factor = 0.55,
		SinkTime = 3, -- seconds standing still until it swallows you
		MovingShare = 0.3, -- how fast you sink while moving, as a share of standing still
		Damage = 100,
		Color = Color3.fromRGB(120, 104, 78),
		Effect = "Sink",
		HitRadius = 8,
		Push = 0,
		HitText = "The sand swallowed you!",
	},
	Rockfall = {
		Count = 3,
		Period = 7,
		Warning = 1.6,
		Active = 0.5,
		Radius = 4,
		Damage = 100,
		Color = Color3.fromRGB(90, 88, 84),
		Effect = "Harm",
		HitRadius = 4,
		Push = 20,
		HitText = "Crushed by falling rock!",
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
		Radius = 22,
		Speed = 2.5, -- studs/s along its Path
		Swell = 1.5, -- its size once the tide is coming back in
		Fill = 7, -- seconds inside it, without a light, until it takes you
		LightFill = 16, -- with a light
		Drain = 3, -- how much faster the dread drains than it rises
		Damage = 100,
		Color = Color3.fromRGB(12, 10, 20),
		Effect = "Gloom",
		HitRadius = 22,
		Push = 0,
		HitText = "The Gloom took you.",
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
	Sink = { At = true, Radius = true },
	Rockfall = { At = true },
	Undertow = { Path = true, Width = true },
	Gloom = { Path = true, At = true, Radius = true },
	Hunter = { Path = true },
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
