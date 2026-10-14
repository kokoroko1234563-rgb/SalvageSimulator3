-- Normal rebirth: cost, multiplier and the reward picks. The doc has a pool of 8 rewards;
-- the test build has the three it names for Milestone 2.

local Config = require(script.Parent.Config)

local cfg = Config.Rebirth

local Rebirth = {}

Rebirth.Rewards = {
	SwiftFeet = {
		Id = "SwiftFeet",
		Name = "Swift Feet",
		Type = "Modifier",
		Description = "+20% walk speed, and faster vessel towing",
	},
	SeaLegs = {
		Id = "SeaLegs",
		Name = "Sea Legs",
		Type = "Modifier",
		Description = "Waves push you 40% less, and you drown 50% slower",
	},
	StrongBack = {
		Id = "StrongBack",
		Name = "Strong Back",
		Type = "Modifier",
		Description = "Every grabber lifts one weight class heavier",
	},
	DeepPockets = {
		Id = "DeepPockets",
		Name = "Deep Pockets",
		Type = "Modifier",
		Description = "3 pocket slots for Light items, safe from bumps and waves. Dropped if you drown.",
	},
	TideMagnet = {
		Id = "TideMagnet",
		Name = "Tide Magnet",
		Type = "Magical grabber",
		Description = "Pulls items toward you through the water. Lifts up to Heavy.",
		GrantsItem = "TideMagnet",
	},
	BubbleWand = {
		Id = "BubbleWand",
		Name = "Bubble Wand",
		Type = "Magical grabber",
		Description = "Floats any item toward you in a bubble, slowly. Waves can't knock it loose.",
		GrantsItem = "BubbleWand",
	},
	FloatingClamshell = {
		Id = "FloatingClamshell",
		Name = "Floating Clamshell",
		Type = "Magical vessel",
		Description = "Hovers behind you and carries 8. Never tips. Lost if fully covered by water.",
		GrantsItem = "FloatingClamshell",
	},
	SeaTurtle = {
		Id = "SeaTurtle",
		Name = "Sea Turtle",
		Type = "Magical vessel",
		Description = "Carries 6 and swims, so it survives being covered. Cargo can wash off. Slow on sand.",
		GrantsItem = "SeaTurtle",
	},
}
Rebirth.Order = {
	"SwiftFeet",
	"SeaLegs",
	"StrongBack",
	"DeepPockets",
	"TideMagnet",
	"BubbleWand",
	"FloatingClamshell",
	"SeaTurtle",
}

Rebirth.SwiftFeetSpeed = 1.2

-- Cost of the next rebirth for someone who has rebirthed `count` times.
function Rebirth.cost(count: number): number
	return math.floor(cfg.BaseCost * cfg.CostGrowth ^ count)
end

function Rebirth.multiplier(count: number): number
	return 1 + cfg.MultiplierStep * count
end

-- Rewards still available to someone who already has `owned`.
function Rebirth.remaining(owned: { [string]: boolean }): { string }
	local list = {}
	for _, id in Rebirth.Order do
		if not owned[id] then
			table.insert(list, id)
		end
	end
	return list
end

return Rebirth
