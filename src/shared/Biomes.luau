-- Biomes. Each tide cycle every zone rolls a biome (or none). The server stores the result
-- on Workspace attributes ("ZoneBiome1", ...) so every client sees the same thing.
-- Milestone 2 only has Sandcastle Flats; the rest of the doc's biomes slot in here.

local Workspace = game:GetService("Workspace")

local Biomes = {}

Biomes.List = {
	SandcastleFlats = {
		Id = "SandcastleFlats",
		Name = "Sandcastle Flats",
		Tier = "Common",
		Loot = { "Bucket", "Sunglasses", "BeachBall", "FlipFlop" },
		LootShare = 0.6, -- this share of the zone's surf spawns comes from Loot
		UnlockItem = "GoldenSpade",
		Secret = "SandcastleFlats",
		EntranceSpots = { -110, -40, 40, 110 }, -- X positions the secret's sandcastle can stand at
		Decor = Color3.fromRGB(230, 200, 140),
	},
}

function Biomes.attributeFor(zone: number): string
	return "ZoneBiome" .. zone
end

function Biomes.activeIn(zone: number?): any
	if not zone or zone < 1 then
		return nil
	end
	local id = Workspace:GetAttribute(Biomes.attributeFor(zone))
	return id and Biomes.List[id] or nil
end

-- Finds a biome by id or name, ignoring case, spaces and punctuation ("sandcastle" works).
function Biomes.find(query: string): any
	local key = query:lower():gsub("[%s%-_']", "")
	for id, biome in Biomes.List do
		local idKey = id:lower()
		local nameKey = biome.Name:lower():gsub("[%s%-_']", "")
		if idKey == key or nameKey == key or idKey:sub(1, #key) == key then
			return biome
		end
	end
	return nil
end

return Biomes
