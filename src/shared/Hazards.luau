-- Biome hazards: a few generic kinds a biome builds from data (Biomes.List[id].Hazards), each
-- with its own settings. Where they go comes from the tile's layout when it says (a layout's
-- Hazards list, by Type), and otherwise they're scattered over the tile.
--
--   Roller  something rolls down the tile toward the sea every Period seconds, at Speed (the
--           Shipwreck Shallows barrels). Placement: Lanes = { x, ... } it can start from.
--   Patrol  Count creatures walk a route back and forth at Speed (hermit crabs). Placement:
--           Path = { {x, z}, ... }; without one, each wanders around where it starts.
--   Pulse   a spot erupts for Active seconds every Period, after Warning seconds of warning
--           (vents, blowholes). Placement: At = {x, z}.
--   Slow    a patch that slows you to Factor of your speed while you're in it (sea glass,
--           tangled seagrass). Placement: At = {x, z}, Radius.
--
-- What a hazard does to a player who gets within HitRadius of it is its Effect:
--   Knockdown  knocked over (you drop what you hold) and thrown Push studs/s away from it.
--   Drop       what you hold is knocked out of your hands.
--   Slow       slowed (Slow hazards).
-- The server builds and moves the hazards (HazardService); each player's own client checks its
-- character against them and applies the effect (HazardController), like the waves.

local Hazards = {}

Hazards.Tag = "Hazard" -- CollectionService tag on the part a hazard hits with

Hazards.Effects = { Knockdown = true, Drop = true, Slow = true }

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
}

-- What a placement in a layout's Hazards list may hold, by kind.
Hazards.Placement = {
	Roller = { Lanes = true },
	Patrol = { Path = true, Count = true },
	Pulse = { At = true },
	Slow = { At = true, Radius = true },
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
