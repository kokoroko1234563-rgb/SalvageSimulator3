-- Secrets. The layout lives here so the client can build it (they are opened locally, only
-- the player who used the unlock item sees theirs) and the server can verify the run against
-- the same chest position (and checkpoints, for a course).
-- Two kinds, told apart by `Course.Kind`:
--   course (no Kind)  a flooding climb: platforms, checkpoints, a rising flood (the three
--                     vaults below).
--   "Room"            a small themed chamber with a chest in it, one per biome in the build:
--                     no checkpoints, no flood. The run ends when the chest is claimed, the
--                     player leaves or dies, or `Seconds` run out.
-- All positions are relative to the course origin.

local Config = require(script.Parent.Config)
local Palette = require(script.Parent.Palette)

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

-- Sunken Hold: a zig-zag climb up the slanted inside of a wrecked hull.
local function hullCourse()
	local platforms: { Platform } = {}
	local steps = 12
	for i = 1, steps do
		local side = if i % 2 == 0 then 1 else -1
		table.insert(platforms, {
			Position = Vector3.new(side * 9, i * 5, -27 + i * 4.5),
			Size = Vector3.new(8, 1, 5),
		})
	end
	local top = (steps + 1) * 5
	table.insert(platforms, { Position = Vector3.new(0, top, 30), Size = Vector3.new(14, 1, 8) })
	return {
		Floor = { Position = Vector3.new(0, 0, 0), Size = Vector3.new(40, 1, 72) },
		WallHeight = top + 20,
		Platforms = platforms,
		Checkpoints = { platforms[4].Position, platforms[8].Position },
		CheckpointRadius = 6,
		Spawn = Vector3.new(0, 3, -30),
		Chest = Vector3.new(0, top + 1.5, 30),
		ChestRadius = 9,
		FloodFrom = -2,
		FloodTo = top + 6,
		HalfSize = 36, -- the hull is long, so it's a bigger box
	}
end

-- Sunken Bell Tower: a tall square tower, climbed on ledges that run around its walls.
-- The longest climb of the three, and the gaps get wider near the top.
local function towerCourse()
	local platforms: { Platform } = {}
	local steps = 20
	-- Corners and midpoints of the walls, walked round in order.
	local ring = {
		Vector3.new(-13, 0, -13),
		Vector3.new(0, 0, -14),
		Vector3.new(13, 0, -13),
		Vector3.new(14, 0, 0),
		Vector3.new(13, 0, 13),
		Vector3.new(0, 0, 14),
		Vector3.new(-13, 0, 13),
		Vector3.new(-14, 0, 0),
	}
	for i = 1, steps do
		local spot = ring[(i - 1) % #ring + 1]
		local size = if i > 14 then 4 else 5
		table.insert(platforms, {
			Position = spot + Vector3.new(0, i * 5, 0),
			Size = Vector3.new(size, 1, size),
		})
	end
	local top = (steps + 1) * 5
	table.insert(platforms, { Position = Vector3.new(0, top, 0), Size = Vector3.new(10, 1, 10) })
	return {
		Floor = { Position = Vector3.new(0, 0, 0), Size = Vector3.new(36, 1, 36) },
		WallHeight = top + 20,
		Platforms = platforms,
		Checkpoints = { platforms[7].Position, platforms[14].Position },
		CheckpointRadius = 6,
		Spawn = Vector3.new(0, 3, 0),
		Chest = Vector3.new(0, top + 1.5, 0),
		ChestRadius = 8,
		FloodFrom = -2,
		FloodTo = top + 6,
		HalfSize = 18,
	}
end

-- A room: a square chamber with the chest at one end and the player arriving at the other.
-- Props dress it: { Position, Size, Color = "Accent" | "Wall" | "Light", Material, Shape, Glow }
-- (relative to the room's origin); the client colours them from the secret's own colour.
export type Prop = {
	Position: Vector3,
	Size: Vector3,
	Color: string,
	Material: string?,
	Shape: string?,
	Glow: boolean?,
}

local function prop(
	kind: string,
	x: number,
	y: number,
	z: number,
	size: Vector3,
	extra: { [string]: any }?
): Prop
	local made: any = { Position = Vector3.new(x, y, z), Size = size, Color = kind }
	for key, value in extra or {} do
		made[key] = value
	end
	return made
end

local function roomCourse(props: { Prop }, size: number?)
	local half = size or 15
	return {
		Kind = "Room",
		Floor = { Position = Vector3.new(0, 0, 0), Size = Vector3.new(half * 2, 1, half * 2) },
		WallHeight = 14,
		Platforms = {},
		Props = props,
		Checkpoints = {},
		CheckpointRadius = 0,
		Spawn = Vector3.new(0, 3, half - 4),
		Chest = Vector3.new(0, 1.5, 4 - half),
		ChestRadius = 7,
		HalfSize = half,
		Seconds = 60, -- a generous limit, so a run always ends
		MinRunTime = 3, -- the chest is across the room: claiming sooner is implausible
		StartDelay = 0,
	}
end

-- Posts either side of the room.
local function pillars(kind: string, material: string?, height: number, width: number): { Prop }
	local list = {}
	for _, x in { -11, 11 } do
		for _, z in { -8, 4 } do
			table.insert(
				list,
				prop(kind, x, height / 2 + 0.5, z, Vector3.new(width, height, width), { Material = material })
			)
		end
	end
	return list
end

local function extend(list: { Prop }, more: { Prop }): { Prop }
	for _, item in more do
		table.insert(list, item)
	end
	return list
end

local function ball(kind: string, x: number, y: number, z: number, d: number, glow: boolean?): Prop
	return prop(kind, x, y, z, Vector3.new(d, d, d), { Shape = "Ball", Glow = glow })
end

local roomCourses = {
	DriftwoodCove = roomCourse(extend(pillars("Accent", "Wood", 7, 2.5), {
		prop("Wall", 0, 1.2, 0, Vector3.new(14, 1.4, 1.6), { Material = "Wood" }),
		prop("Accent", -6, 2.2, 8, Vector3.new(1.4, 3.2, 1.4), { Material = "Wood" }),
	})),
	TidepoolRocks = roomCourse(extend(pillars("Wall", "Rock", 5, 4), {
		ball("Light", 0, 0.6, 0, 8),
		ball("Accent", -6, 1.5, 6, 2.5),
		ball("Accent", 7, 1.5, 3, 3),
	})),
	SeagrassShallows = roomCourse(extend(pillars("Accent", "Grass", 4, 1.2), {
		prop("Wall", 0, 5, 0, Vector3.new(26, 0.8, 1.4), { Material = "WoodPlanks" }),
		prop("Wall", -10, 3, 0, Vector3.new(1, 5, 1), { Material = "Wood" }),
		prop("Wall", 10, 3, 0, Vector3.new(1, 5, 1), { Material = "Wood" }),
	})),
	CoralGarden = roomCourse(extend(pillars("Accent", "Sand", 6, 3), {
		ball("Accent", -6, 2, 5, 4),
		ball("Accent", 6, 2, 0, 5),
		ball("Light", 0, 1.5, 8, 2.5),
	})),
	FogBank = roomCourse(extend(pillars("Wall", "Rock", 9, 2), {
		prop("Light", 0, 6, -4, Vector3.new(1.6, 4, 1.6), { Material = "Metal" }),
		ball("Light", 0, 9, -4, 3, true),
	})),
	WhirlwindDunes = roomCourse({
		ball("Accent", -8, -1, 3, 9),
		ball("Accent", 9, -1, -2, 8),
		ball("Accent", 0, -1.5, 9, 7),
		prop("Light", 0, 3, -2, Vector3.new(0.5, 5, 0.5), { Material = "Metal" }),
	}),
	HermitHollows = roomCourse(extend(pillars("Wall", "Rock", 6, 3), {
		ball("Accent", -7, 1.8, 2, 4),
		ball("Accent", 7, 2.5, 5, 5),
		ball("Light", 0, 1.2, 4, 2),
	})),
	SpearstoneReef = roomCourse(extend(pillars("Accent", "Rock", 8, 1.6), {
		prop("Wall", -4, 3, 2, Vector3.new(1.2, 6, 1.2), { Material = "Rock" }),
		prop("Wall", 4, 3, 2, Vector3.new(1.2, 6, 1.2), { Material = "Rock" }),
	})),
	JellyfishLagoon = roomCourse({
		ball("Light", -8, 6, 0, 4, true),
		ball("Light", 8, 8, 3, 3, true),
		ball("Accent", 0, 9, 7, 5, true),
		ball("Accent", 0, -2, 0, 12),
	}),
	StrandedIceberg = roomCourse(extend(pillars("Light", "Glass", 8, 2.4), {
		prop("Accent", -6, 1.5, 5, Vector3.new(2, 3, 2), { Material = "Glass" }),
		prop("Accent", 6, 2, 1, Vector3.new(2.4, 4, 2.4), { Material = "Glass" }),
	})),
}

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
	-- Exotic secret: ends in a lootbox instead of a colored coin.
	ShipwreckShallows = {
		Id = "ShipwreckShallows",
		Name = "Sunken Hold",
		Biome = "ShipwreckShallows",
		Unlock = "CaptainsKey",
		Loot = {
			{ Id = "AnchorHook", Weight = 34 },
			{ Id = "CaptainsLongboat", Weight = 33 },
			{ Id = "DeckhandsSatchel", Weight = 33 },
		},
		Variant = "Barnacled", -- the rare cosmetic variant in this secret's style
		VariantChance = 0.015,
		Course = hullCourse(),
		Color = Color3.fromRGB(105, 75, 50),
	},
	-- Exotic secret with a fixed door: the bell tower stands on the Far Sandbar, which is
	-- only uncovered around low tide, so the door is reachable for a short window.
	FarSandbar = {
		Id = "FarSandbar",
		Name = "Sunken Bell Tower",
		Location = "FarSandbar",
		Unlock = "BeaconPearl",
		Loot = {
			{ Id = "LeviathanRowboat", Weight = 50 },
			{ Id = "TideCrown", Weight = 50 },
		},
		Variant = "Gilded",
		VariantChance = 0.015,
		Course = towerCourse(),
		Color = Color3.fromRGB(120, 130, 125),
		-- The water inside rises on its own clock rather than the real tide's, since the
		-- sandbar is already about to flood whenever you can reach the door.
		FloodSeconds = 150,
	},
	-- The rooms: one small chamber per biome in the initial build. A common biome's chest holds
	-- its coin, as the Sandcastle Vault's does; a rare biome's holds one of its exotic rewards.
	DriftwoodCove = {
		Id = "DriftwoodCove",
		Name = "Hollow Trunk",
		Biome = "DriftwoodCove",
		Unlock = "CarvedIdol",
		Coin = "Orange",
		Course = roomCourses.DriftwoodCove,
		Color = Color3.fromRGB(150, 118, 84),
	},
	TidepoolRocks = {
		Id = "TidepoolRocks",
		Name = "Blowhole Grotto",
		Biome = "TidepoolRocks",
		Unlock = "PearlEyedShell",
		Coin = "Blue",
		Course = roomCourses.TidepoolRocks,
		Color = Color3.fromRGB(92, 112, 124),
	},
	SeagrassShallows = {
		Id = "SeagrassShallows",
		Name = "Jetty Hideaway",
		Biome = "SeagrassShallows",
		Unlock = "BarnacledLantern",
		Coin = "Green",
		Course = roomCourses.SeagrassShallows,
		Color = Color3.fromRGB(84, 120, 78),
	},
	CoralGarden = {
		Id = "CoralGarden",
		Name = "Reef Grotto",
		Biome = "CoralGarden",
		Unlock = "CoralComb",
		Coin = "Pink",
		Course = roomCourses.CoralGarden,
		Color = Color3.fromRGB(226, 140, 156),
	},
	FogBank = {
		Id = "FogBank",
		Name = "Lighthouse Lamp Room",
		Biome = "FogBank",
		Unlock = "LighthouseKey",
		Loot = {
			{ Id = "LanternOfClearSight", Weight = 50 },
			{ Id = "Foghorn", Weight = 50 },
		},
		Course = roomCourses.FogBank,
		Color = Color3.fromRGB(170, 176, 182),
	},
	WhirlwindDunes = {
		Id = "WhirlwindDunes",
		Name = "Wind-Carved Hollow",
		Biome = "WhirlwindDunes",
		Unlock = "WindChime",
		Loot = {
			{ Id = "MagicCarpet", Weight = 50 },
			{ Id = "GustGloves", Weight = 50 },
		},
		Course = roomCourses.WhirlwindDunes,
		Color = Color3.fromRGB(214, 180, 122),
	},
	HermitHollows = {
		Id = "HermitHollows",
		Name = "Shell Burrow",
		Biome = "HermitHollows",
		Unlock = "SpiralConch",
		Loot = {
			{ Id = "CrabClaw", Weight = 50 },
			{ Id = "ShellWagon", Weight = 50 },
		},
		Course = roomCourses.HermitHollows,
		Color = Color3.fromRGB(205, 175, 150),
	},
	SpearstoneReef = {
		Id = "SpearstoneReef",
		Name = "Spearstone Cleft",
		Biome = "SpearstoneReef",
		Unlock = "SpearstoneShard",
		Loot = {
			{ Id = "TidewalkerBoots", Weight = 100 },
		},
		Course = roomCourses.SpearstoneReef,
		Color = Color3.fromRGB(70, 80, 92),
	},
	JellyfishLagoon = {
		Id = "JellyfishLagoon",
		Name = "Glowing Grotto",
		Biome = "JellyfishLagoon",
		Unlock = "JellyJar",
		Loot = {
			{ Id = "JellyRaft", Weight = 50 },
			{ Id = "GlowPearl", Weight = 50 },
		},
		Course = roomCourses.JellyfishLagoon,
		Color = Color3.fromRGB(160, 120, 215),
	},
	StrandedIceberg = {
		Id = "StrandedIceberg",
		Name = "Ice Cave",
		Biome = "StrandedIceberg",
		Unlock = "FrozenCompass",
		Loot = {
			{ Id = "FrostSled", Weight = 50 },
			{ Id = "FreezeWand", Weight = 50 },
		},
		Variant = "Frosted",
		VariantChance = 0.015,
		Course = roomCourses.StrandedIceberg,
		Color = Color3.fromRGB(176, 214, 236),
	},
}

Secrets.CoinColors = Palette.Coin
Secrets.CoinOrder = { "Yellow", "Orange", "Blue", "Green", "Pink" }

-- Rolls a lootbox: an item id from the secret's pool, and maybe its cosmetic variant.
function Secrets.rollLoot(secret, rng: Random): (string?, string?)
	if not secret.Loot then
		return nil, nil
	end
	local total = 0
	for _, entry in secret.Loot do
		total += entry.Weight
	end
	local roll = rng:NextNumber() * total
	local picked = secret.Loot[#secret.Loot].Id
	for _, entry in secret.Loot do
		roll -= entry.Weight
		if roll <= 0 then
			picked = entry.Id
			break
		end
	end
	local variant = if secret.Variant and rng:NextNumber() < (secret.VariantChance or 0)
		then secret.Variant
		else nil
	return picked, variant
end

function Secrets.isRoom(secret): boolean
	return secret.Course.Kind == "Room"
end

-- Each player slot gets its own spot far off the map, so courses never overlap.
function Secrets.originFor(slot: number): Vector3
	return Config.Secrets.Origin + Vector3.new(slot * Config.Secrets.Spacing, 0, 0)
end

-- Water level in the course `elapsed` seconds into a run lasting `duration` seconds.
-- (A room doesn't flood: its level stays far below the floor.)
function Secrets.floodLevel(course, elapsed: number, duration: number): number
	if not course.FloodFrom then
		return -math.huge
	end
	local t = math.clamp(elapsed / duration, 0, 1)
	return course.FloodFrom + (course.FloodTo - course.FloodFrom) * t
end

return Secrets
