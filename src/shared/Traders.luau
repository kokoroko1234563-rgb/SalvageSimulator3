-- Special traders: quirky characters who sometimes appear in their biome and sell one level
-- of a stat upgrade per appearance. Levels cost coins plus some of the biome's own items,
-- brought to them; Madame Gull takes attunement cores instead.
-- Traders whose biome doesn't exist yet are defined but can't appear.

local Config = require(script.Parent.Config)

local Traders = {}

Traders.List = {
	Gary = {
		Id = "Gary",
		Name = "Gary the Tourist",
		Biome = "SandcastleFlats",
		Upgrade = "ComfySandals",
		PaidWithItem = "FlipFlop",
		Greeting = "Lost my sandals ages ago. Trade you some comfy ones for a few flip-flops?",
	},
	OldNell = {
		Id = "OldNell",
		Name = "Old Nell, net-mender",
		Biome = "SeagrassShallows",
		Upgrade = "TightKnots",
		PaidWithItem = "Net",
		Greeting = "Bring me nets and I'll teach you knots the sea can't undo.",
	},
	Rusty = {
		Id = "Rusty",
		Name = "Rusty, a talking figurehead",
		Biome = "ShipwreckShallows",
		Upgrade = "DeepLungs",
		PaidWithItem = "ShipBell",
		Greeting = "Ring me a bell or three, sailor, and I'll stretch those lungs.",
	},
	MadameGull = {
		Id = "MadameGull",
		Name = "Madame Gull, fortune-telling seagull",
		Biome = "FogBank",
		Upgrade = "TideReading",
		PaidWithCores = { 1, 2, 3 },
		Greeting = "The tide whispers to me. For a core, it might whisper to you.",
	},
	CaptainPebble = {
		Id = "CaptainPebble",
		Name = "Captain Pebble, crab in a teacup",
		Biome = "HermitHollows",
		Upgrade = "BarnacleBoots",
		PaidWithItem = "BigShell",
		Greeting = "Big shells for little boots. Fair trade, says the captain.",
	},
	Pip = {
		Id = "Pip",
		Name = "Pip, a lost penguin",
		Biome = "StrandedIceberg",
		Upgrade = "FrostrunnerWax",
		PaidWithItem = "FrozenFish",
		LargeCoinCost = 250000,
		Greeting = "Fish? Fish! Wax for your wheels, for fish!",
	},
}

-- Effects are per level. Upgrades are kept through normal rebirths and lost on a true
-- rebirth, except where Permanent.
Traders.Upgrades = {
	ComfySandals = { Name = "Comfy Sandals", MaxLevel = 3, Effect = "+5% walk speed per level" },
	TightKnots = {
		Name = "Tight Knots",
		MaxLevel = 3,
		Effect = "Held items 15% harder to knock loose per level",
	},
	DeepLungs = { Name = "Deep Lungs", MaxLevel = 3, Effect = "+20% breath in deep water per level" },
	TideReading = {
		Name = "Tide Reading",
		MaxLevel = 3,
		Effect = "1: whether a rare biome is out. 2: its tier. 3: its zone. Told when you join and each tide",
		Permanent = true,
	},
	BarnacleBoots = { Name = "Barnacle Boots", MaxLevel = 3, Effect = "Waves push you 10% less per level" },
	FrostrunnerWax = { Name = "Frostrunner Wax", MaxLevel = 1, Effect = "+20% speed on all vessels" },
}
Traders.UpgradeOrder =
	{ "ComfySandals", "TightKnots", "DeepLungs", "TideReading", "BarnacleBoots", "FrostrunnerWax" }

-- Multipliers for a set of levels ({ [upgradeId] = level }).
function Traders.walkMultiplier(levels): number
	return 1 + 0.05 * (levels.ComfySandals or 0)
end
function Traders.gripMultiplier(levels): number
	return 1 + 0.15 * (levels.TightKnots or 0)
end
function Traders.breathMultiplier(levels): number
	return 1 + 0.2 * (levels.DeepLungs or 0)
end
function Traders.wavePushMultiplier(levels): number
	return math.max(Config.Traders.MinWavePush, 1 - 0.1 * (levels.BarnacleBoots or 0))
end
function Traders.vesselSpeedMultiplier(levels): number
	return 1 + 0.2 * (levels.FrostrunnerWax or 0)
end

-- What the next level costs: coins, item count, and/or cores.
function Traders.cost(trader, nextLevel: number): { Coins: number, Items: number, Cores: number }
	if trader.PaidWithCores then
		return { Coins = 0, Items = 0, Cores = trader.PaidWithCores[nextLevel] or 0 }
	end
	return {
		Coins = trader.LargeCoinCost or Config.Traders.LevelCoins[nextLevel] or 0,
		Items = Config.Traders.LevelItems[nextLevel] or 0,
		Cores = 0,
	}
end

-- Reads the "Upgrades" attribute ("ComfySandals:2,DeepLungs:1") into a table.
function Traders.parseLevels(text: string?): { [string]: number }
	local levels = {}
	for entry in string.gmatch(text or "", "[^,]+") do
		local id, level = string.match(entry, "^(%w+):(%d+)$")
		if id then
			levels[id] = tonumber(level)
		end
	end
	return levels
end

return Traders
