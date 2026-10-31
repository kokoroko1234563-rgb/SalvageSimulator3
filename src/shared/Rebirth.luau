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
		Description = "Waves push you 50% less, the water slows you half as much, and your breath lasts twice as long",
	},
	StrongBack = {
		Id = "StrongBack",
		Name = "Strong Back",
		Type = "Modifier",
		Description = "Every grabber works one zone further out (+1 tier)",
	},
	DeepPockets = {
		Id = "DeepPockets",
		Name = "Deep Pockets",
		Type = "Modifier",
		Description = "3 pocket slots for any item, safe from bumps and waves. Dropped if you drown.",
	},
	TideMagnet = {
		Id = "TideMagnet",
		Name = "Tide Magnet",
		Type = "Magical grabber",
		Description = "Pulls items toward you through the water. Works up to zone 4 (Outer Shore).",
		GrantsItem = "TideMagnet",
	},
	BubbleWand = {
		Id = "BubbleWand",
		Name = "Bubble Wand",
		Type = "Magical grabber",
		Description = "Floats items toward you in a bubble, from any depth, slowly. Works up to zone 4 (Outer Shore). Waves can't knock it loose.",
		GrantsItem = "BubbleWand",
	},
	FloatingClamshell = {
		Id = "FloatingClamshell",
		Name = "Floating Clamshell",
		Type = "Magical vessel",
		Description = "Hovers behind you and carries 10. Never tips, and floats over the Far Sandbar's channel. Lost if fully covered by water.",
		GrantsItem = "FloatingClamshell",
	},
	SeaTurtle = {
		Id = "SeaTurtle",
		Name = "Sea Turtle",
		Type = "Magical vessel",
		Description = "Carries 10 and swims, so it survives being covered and crosses the Far Sandbar's channel. Cargo can wash off, half as often as a boat's. Slow on sand.",
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

-- The rewards offered at a pick: Config.Rebirth.Choices of those still available, at random
-- (all of them when fewer are left), in the rewards' usual order.
function Rebirth.rollOptions(owned: { [string]: boolean }, rng: Random): { string }
	local pool = Rebirth.remaining(owned)
	local offered = {}
	for _ = 1, math.min(cfg.Choices, #pool) do
		local id = table.remove(pool, rng:NextInteger(1, #pool))
		offered[id] = true
	end
	local options = {}
	for _, id in Rebirth.Order do
		if offered[id] then
			table.insert(options, id)
		end
	end
	return options
end

return Rebirth
