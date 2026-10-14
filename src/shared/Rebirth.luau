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
	DeepPockets = {
		Id = "DeepPockets",
		Name = "Deep Pockets",
		Type = "Modifier",
		Description = "3 pocket slots for Light items, safe from bumps and waves. Dropped if you drown.",
	},
	FloatingClamshell = {
		Id = "FloatingClamshell",
		Name = "Floating Clamshell",
		Type = "Magical vessel",
		Description = "Hovers behind you and carries 8. Never tips. Lost if fully covered by water.",
	},
}
Rebirth.Order = { "SwiftFeet", "DeepPockets", "FloatingClamshell" }

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
