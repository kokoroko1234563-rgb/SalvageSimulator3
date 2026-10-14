-- Secret courses. The layout lives here so the client can build it (courses are opened
-- locally, only the player who used the unlock item sees theirs) and the server can verify
-- the run against the same checkpoints and chest position.
-- All positions are relative to the course origin.

local Config = require(script.Parent.Config)

local Secrets = {}

export type Platform = { Position: Vector3, Size: Vector3 }

-- Sandcastle Vault: a spiral climb up the inside of a giant sandcastle while the sea pours
-- in from below.
local function sandcastleCourse()
	local platforms: { Platform } = {}
	local steps = 14
	for i = 1, steps do
		local angle = math.rad(i * 52)
		table.insert(platforms, {
			Position = Vector3.new(math.cos(angle) * 13, i * 5, math.sin(angle) * 13),
			Size = Vector3.new(6, 1, 6),
		})
	end
	local top = (steps + 1) * 5
	table.insert(platforms, { Position = Vector3.new(0, top, 0), Size = Vector3.new(12, 1, 12) })
	return {
		Floor = { Position = Vector3.new(0, 0, 0), Size = Vector3.new(44, 1, 44) },
		WallHeight = top + 20,
		Platforms = platforms,
		Checkpoints = { platforms[5].Position, platforms[10].Position }, -- must be visited in order
		CheckpointRadius = 6,
		Spawn = Vector3.new(0, 3, 0),
		Chest = Vector3.new(0, top + 1.5, 0),
		ChestRadius = 9,
		FloodFrom = -2, -- water level at the start...
		FloodTo = top + 6, -- ...and once the time is up
		HalfSize = 22, -- leaving this box (sideways) ends the run
	}
end

Secrets.List = {
	SandcastleFlats = {
		Id = "SandcastleFlats",
		Name = "Sandcastle Vault",
		Biome = "SandcastleFlats",
		Unlock = "GoldenSpade",
		Coin = "Yellow",
		Course = sandcastleCourse(),
		Color = Color3.fromRGB(230, 200, 140),
	},
}

Secrets.CoinColors = {
	Yellow = Color3.fromRGB(255, 215, 40),
	Orange = Color3.fromRGB(255, 140, 40),
	Blue = Color3.fromRGB(60, 140, 255),
	Green = Color3.fromRGB(70, 200, 90),
	Pink = Color3.fromRGB(255, 120, 200),
}
Secrets.CoinOrder = { "Yellow", "Orange", "Blue", "Green", "Pink" }

-- Each player slot gets its own spot far off the map, so courses never overlap.
function Secrets.originFor(slot: number): Vector3
	return Config.Secrets.Origin + Vector3.new(slot * Config.Secrets.Spacing, 0, 0)
end

-- Water level in the course `elapsed` seconds into a run lasting `duration` seconds.
function Secrets.floodLevel(course, elapsed: number, duration: number): number
	local t = math.clamp(elapsed / duration, 0, 1)
	return course.FloodFrom + (course.FloodTo - course.FloodFrom) * t
end

return Secrets
