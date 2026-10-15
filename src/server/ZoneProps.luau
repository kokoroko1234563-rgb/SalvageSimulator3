-- The models that give each zone its look: loungers and huts on Shopside Shore, a pier and
-- beach huts on Sunny Stretch, sandbanks and beached boats on Middle Banks, reef rocks and
-- tidepools on Outer Shore, and a ruined bell tower on The Far Sandbar. They're scenery only.
-- None of it collides or gets queried, so towing, grabbing and the waves are unchanged.
-- Positions use a seeded Random per zone, so every server builds the same zones.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local WaterObstacles = require(Shared.WaterObstacles)
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)

local BeachDressing = require(script.Parent.BeachDressing)
local MapParts = require(script.Parent.MapParts)

local ZoneProps = {}

local Z = Palette.Zone

local add = MapParts.scenery
local ball = MapParts.ball
local column = MapParts.column

local function ground(x: number, z: number): Vector3
	return Vector3.new(x, Beach.groundAt(x, z), z)
end

-- A deck chair: a seat, a backrest tipped back, and four legs.
local function lounger(parent: Instance, cf: CFrame, color: Color3)
	add(parent, {
		Name = "ChairSeat",
		Size = Vector3.new(2.4, 0.5, 4),
		CFrame = cf * CFrame.new(0, 1.6, 0),
		Color = color,
		Material = Palette.Material.Fabric,
	})
	add(parent, {
		Name = "ChairBack",
		Size = Vector3.new(2.4, 0.4, 3),
		CFrame = cf * CFrame.new(0, 2.2, -2) * CFrame.Angles(math.rad(50), 0, 0),
		Color = color,
		Material = Palette.Material.Fabric,
	})
	for _, x in { -1.1, 1.1 } do
		for _, z in { -1.8, 1.8 } do
			add(parent, {
				Name = "ChairLeg",
				Size = Vector3.new(0.3, 1.6, 0.3),
				CFrame = cf * CFrame.new(x, 0.8, z),
				Color = Palette.World.Post,
				Material = Palette.Material.Metal,
			})
		end
	end
end

-- A folded towel lying on the sand.
local function towel(parent: Instance, position: Vector3, yaw: number, color: Color3)
	add(parent, {
		Name = "Towel",
		Size = Vector3.new(2.6, 0.12, 4.6),
		CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, yaw, 0),
		Color = color,
		Material = Palette.Material.Fabric,
	})
end

-- A small open-fronted beach hut with a shed roof.
local function hut(parent: Instance, base: Vector3, yaw: number, wall: Color3, roof: Color3)
	local cf = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
	add(parent, {
		Name = "HutFloor",
		Size = Vector3.new(10, 0.6, 8),
		CFrame = cf * CFrame.new(0, 0.3, 0),
		Color = Palette.World.Boardwalk,
		Material = Palette.Material.WoodPlanks,
	})
	for _, x in { -4.5, 4.5 } do
		for _, z in { -3.5, 3.5 } do
			column(parent, (cf * CFrame.new(x, 0.6, z)).Position, 6, 0.6, Palette.World.Post)
		end
	end
	add(parent, {
		Name = "HutBack",
		Size = Vector3.new(10, 6, 0.4),
		CFrame = cf * CFrame.new(0, 3.6, -3.8),
		Color = wall,
		Material = Palette.Material.Smooth,
	})
	for _, x in { -4.8, 4.8 } do
		add(parent, {
			Name = "HutSide",
			Size = Vector3.new(0.4, 6, 8),
			CFrame = cf * CFrame.new(x, 3.6, 0),
			Color = wall,
			Material = Palette.Material.Smooth,
		})
	end
	add(parent, {
		Name = "HutRoof",
		Size = Vector3.new(11, 0.6, 9),
		CFrame = cf * CFrame.new(0, 6.9, 0) * CFrame.Angles(math.rad(-10), 0, 0),
		Color = roof,
		Material = Palette.Material.Fabric,
	})
end

-- A long low sandbank running along X at a given Z.
-- It's a long cylinder lying along X, sunk into the sand so only a low rounded cap shows:
-- `width` across the cap, at most SANDBANK_MAX_HEIGHT tall. It's scenery you wade through, so
-- it stays low (a tall flat-topped box here looked like a wall you could walk through).
local SANDBANK_MAX_HEIGHT = 1.2
local function sandbank(parent: Instance, x0: number, x1: number, z: number, height: number, width: number)
	local h = math.min(height, SANDBANK_MAX_HEIGHT)
	local half = width / 2
	local radius = (half * half + h * h) / (2 * h) -- the circle through the cap's edges and top
	local bank = add(parent, {
		Name = "Sandbank",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(x1 - x0, radius * 2, radius * 2),
		CFrame = CFrame.new((x0 + x1) / 2, Beach.groundY(z) + h - radius, z),
		Color = Z.Ridge,
		Material = Palette.Material.Sand,
	})
	-- The run-up stops against it unless a wave climbs over it (WaterObstacles).
	WaterObstacles.mark(bank, "Solid")
end

-- A stack of driftwood logs.
local function driftwoodPile(parent: Instance, position: Vector3, rng: Random)
	for level = 0, 3 do
		local offset = Vector3.new(rng:NextNumber(-0.8, 0.8), level * 0.8, rng:NextNumber(-0.8, 0.8))
		BeachDressing.driftwood(parent, position + offset, rng)
	end
end

-- A fishing net strung between two posts.
local function net(parent: Instance, position: Vector3, yaw: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	for _, x in { -4, 4 } do
		add(parent, {
			Name = "NetPost",
			Size = Vector3.new(4, 0.5, 0.5),
			CFrame = cf * CFrame.new(x, 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Palette.World.Post,
			Material = Palette.Material.Wood,
		})
	end
	add(parent, {
		Name = "Net",
		Size = Vector3.new(8, 3, 0.15),
		CFrame = cf * CFrame.new(0, 2.5, 0),
		Color = Z.Net,
		Material = Palette.Material.Fabric,
		Transparency = 0.35,
	})
end

-- A rowing boat lying on the sand, bottom down.
local function boat(parent: Instance, position: Vector3, yaw: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	add(parent, {
		Name = "BoatHull",
		Size = Vector3.new(6, 1.4, 2.4),
		CFrame = cf * CFrame.new(0, 0.7, 0),
		Color = Z.Hull,
		Material = Palette.Material.Smooth,
	})
	add(parent, {
		Name = "BoatInside",
		Size = Vector3.new(5.4, 0.3, 2),
		CFrame = cf * CFrame.new(0, 1.4, 0),
		Color = Z.HullInside,
		Material = Palette.Material.Smooth,
	})
end

-- The ribs of a wreck, tipped on its side and half-buried.
local function wreck(parent: Instance, position: Vector3, yaw: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw, math.rad(20))
	local hull = add(parent, {
		Name = "WreckHull",
		Size = Vector3.new(16, 4, 5),
		CFrame = cf * CFrame.new(0, 1, 0),
		Color = Palette.World.DarkWood,
		Material = Palette.Material.WoodPlanks,
	})
	WaterObstacles.mark(hull, "Solid")
	add(parent, {
		Name = "WreckMast",
		Size = Vector3.new(14, 0.8, 0.8),
		CFrame = cf * CFrame.new(3, 8, 0) * CFrame.Angles(0, 0, math.pi / 2 - math.rad(8)),
		Color = Palette.World.Mast,
		Material = Palette.Material.Wood,
	})
end

-- A cluster of grey rocks, sunk a little into the sand.
local function rockCluster(parent: Instance, center: Vector3, count: number, rng: Random)
	for _ = 1, count do
		local diameter = rng:NextNumber(2.5, 6)
		local offset = Vector3.new(rng:NextNumber(-8, 8), diameter * 0.3, rng:NextNumber(-8, 8))
		local color = if rng:NextNumber() < 0.5 then Z.RockGrey else Z.RockDark
		WaterObstacles.mark(ball(parent, center + offset, diameter, color, Palette.Material.Rock), "Solid")
	end
end

-- A tidepool: a ring of rocks around a patch of glassy water.
local function tidepool(parent: Instance, position: Vector3)
	for i = 0, 7 do
		local angle = i / 8 * math.pi * 2
		local rim = position + Vector3.new(math.cos(angle) * 2.6, 0.5, math.sin(angle) * 2.6)
		ball(parent, rim, 1.6, Z.RockDark, Palette.Material.Rock)
	end
	add(parent, {
		Name = "TidepoolWater",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 4.2, 4.2),
		CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Z.Pool,
		Material = Palette.Material.Glass,
		Transparency = 0.25,
	})
end

-- A clump of coral: bright balls on the sand.
local function coralPatch(parent: Instance, center: Vector3, rng: Random)
	local colors = { Z.Coral1, Z.Coral2, Z.Coral3 }
	for _ = 1, 4 do
		local diameter = rng:NextNumber(1.2, 2.6)
		local offset = Vector3.new(rng:NextNumber(-1.4, 1.4), diameter / 2, rng:NextNumber(-1.4, 1.4))
		ball(parent, center + offset, diameter, colors[rng:NextInteger(1, #colors)], Palette.Material.Smooth)
	end
end

-- A row of pilings running along Z, from the sand out into the water.
local function pilingRow(parent: Instance, x: number, z0: number, z1: number, top: number)
	local z = z0
	while z <= z1 do
		local bottom = Beach.groundAt(x, z) - 2
		column(parent, Vector3.new(x, bottom, z), top - bottom, 0.9, Z.Piling)
		z += 14
	end
end

-- A wooden pier on pilings, running out from the shore.
local function pier(parent: Instance, x: number, z0: number, z1: number, deckY: number)
	local deck = add(parent, {
		Name = "PierDeck",
		Size = Vector3.new(8, 0.8, z1 - z0),
		CFrame = CFrame.new(x, deckY, (z0 + z1) / 2),
		Color = Z.Pier,
		Material = Palette.Material.WoodPlanks,
	})
	WaterObstacles.mark(deck, "Under") -- the water runs underneath
	for _, side in { -3.5, 3.5 } do
		pilingRow(parent, x + side, z0, z1, deckY - 0.4)
	end
end

-- A ruined bell tower: a stone shaft with a ledge, a broken top, and the bell still hanging.
local function bellTower(parent: Instance, base: Vector3)
	column(parent, base, 14, 9, Z.StoneLight, Palette.Material.Rock)
	add(parent, {
		Name = "TowerLedge",
		Size = Vector3.new(12, 0.8, 12),
		CFrame = CFrame.new(base + Vector3.new(0, 14.4, 0)),
		Color = Z.StoneDark,
		Material = Palette.Material.Rock,
	})
	column(parent, base + Vector3.new(0, 15, 0), 6, 7, Z.StoneDark, Palette.Material.Rock)
	column(parent, base + Vector3.new(0.6, 21, 0), 2, 6, Z.StoneLight, Palette.Material.Rock)
	ball(parent, base + Vector3.new(0, 19.5, 0), 2.4, Z.Bell, Palette.Material.Metal)
end

-- A standing column, a little out of true, like the ruins of a colonnade.
local function ruinedColumn(parent: Instance, base: Vector3, rng: Random)
	local height = rng:NextNumber(6, 9)
	local tilt = CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.08, 0.08))
	add(parent, {
		Name = "RuinedColumn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 2.2, 2.2),
		CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * tilt * CFrame.Angles(0, 0, math.pi / 2),
		Color = Z.StoneLight,
		Material = Palette.Material.Rock,
	})
end

local UMBRELLA_COLORS =
	{ Palette.World.UmbrellaRed, Palette.World.UmbrellaTeal, Palette.World.UmbrellaYellow }
local TOWEL_COLORS = { Z.TowelRed, Z.TowelBlue, Z.TowelYellow }

-- Each zone builder fills its band of Z: from zMin to zMax, across the whole beach.
local builders: { [number]: (Folder, Random, number, number) -> () } = {}

-- Zone 1: Shopside Shore. Loungers, umbrellas, palms and beach balls near the shop.
builders[1] = function(folder: Folder, rng: Random, zMin: number, zMax: number)
	for _ = 1, 4 do
		local x = rng:NextNumber(-220, 220)
		local z = rng:NextNumber(zMin + 30, zMax - 20)
		local base = CFrame.new(ground(x, z)) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0)
		lounger(folder, base * CFrame.new(-1.6, 0, 0), Z.ChairWhite)
		lounger(folder, base * CFrame.new(1.6, 0, 0), Z.ChairCoral)
		local color = UMBRELLA_COLORS[rng:NextInteger(1, #UMBRELLA_COLORS)]
		BeachDressing.umbrella(folder, ground(x, z - 3.5), color)
	end
	for _ = 1, 4 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local x = side * rng:NextNumber(260, 330)
		local z = rng:NextNumber(zMin + 10, zMax - 10)
		BeachDressing.palm(folder, ground(x, z), rng:NextNumber(12, 16), rng)
	end
	for i = 1, 6 do
		local center = ground(rng:NextNumber(-260, 260), rng:NextNumber(zMin + 10, zMax - 10))
		local color = UMBRELLA_COLORS[(i % #UMBRELLA_COLORS) + 1]
		ball(folder, center + Vector3.new(0, 1.2, 0), 2.4, color)
	end
	for _ = 1, 6 do
		local x = rng:NextNumber(-280, 280)
		local z = rng:NextNumber(zMin + 10, zMax - 10)
		local color = TOWEL_COLORS[rng:NextInteger(1, #TOWEL_COLORS)]
		towel(folder, ground(x, z), rng:NextNumber(0, math.pi), color)
	end
end

-- Zone 2: Sunny Stretch. Beach huts, a pier, towels and a few palms.
builders[2] = function(folder: Folder, rng: Random, zMin: number, zMax: number)
	hut(folder, ground(-200, zMin + 40), 0.1, Z.HutWall, Z.HutTealRoof)
	hut(folder, ground(180, zMin + 70), -0.2, Z.HutWall, Z.HutThatch)
	pier(folder, 40, zMin + 20, zMin + 210, 2.2)
	for _ = 1, 10 do
		local x = rng:NextNumber(-300, 300)
		local z = rng:NextNumber(zMin + 10, zMax - 10)
		local color = TOWEL_COLORS[rng:NextInteger(1, #TOWEL_COLORS)]
		towel(folder, ground(x, z), rng:NextNumber(0, math.pi), color)
	end
	for _ = 1, 3 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local x = side * rng:NextNumber(250, 330)
		local z = rng:NextNumber(zMin + 10, zMax - 10)
		BeachDressing.palm(folder, ground(x, z), rng:NextNumber(12, 16), rng)
	end
end

-- Zone 3: Middle Banks. Sandbanks, driftwood piles, nets and beached boats.
builders[3] = function(folder: Folder, rng: Random, zMin: number, zMax: number)
	-- (Its sandbanks are now the terrain's own ridges: Config.Beach.Terrain.)
	for _ = 1, 6 do
		local x = rng:NextNumber(-300, 300)
		local z = rng:NextNumber(zMin + 10, zMax - 10)
		driftwoodPile(folder, ground(x, z) + Vector3.new(0, 0.45, 0), rng)
	end
	for _ = 1, 3 do
		local x = rng:NextNumber(-280, 280)
		local z = rng:NextNumber(zMin + 20, zMax - 20)
		net(folder, ground(x, z), rng:NextNumber(0, math.pi))
	end
	boat(folder, ground(-150, zMin + 60), 0.3)
	boat(folder, ground(160, zMin + 100), -0.5)
	for _ = 1, 4 do
		local x = rng:NextNumber(-300, 300)
		local z = rng:NextNumber(zMin + 10, zMax - 10)
		rockCluster(folder, ground(x, z), 5, rng)
	end
end

-- Zone 4: Outer Shore. Reef rocks, tidepools, coral, pilings and a stranded wreck.
builders[4] = function(folder: Folder, rng: Random, zMin: number, zMax: number)
	for _ = 1, 6 do
		local x = rng:NextNumber(-300, 300)
		local z = rng:NextNumber(zMin + 10, zMax - 10)
		rockCluster(folder, ground(x, z), 6, rng)
	end
	for _ = 1, 4 do
		local x = rng:NextNumber(-280, 280)
		local z = rng:NextNumber(zMin + 20, zMax - 20)
		tidepool(folder, ground(x, z) + Vector3.new(0, 0.1, 0))
	end
	for _ = 1, 8 do
		local x = rng:NextNumber(-300, 300)
		local z = rng:NextNumber(zMin + 10, zMax - 10)
		coralPatch(folder, ground(x, z), rng)
	end
	wreck(folder, ground(-120, zMin + 100), 0.4)
	pilingRow(folder, -230, zMin + 10, zMax - 10, 4)
	pilingRow(folder, 230, zMin + 10, zMax - 10, 4)
end

-- Zones 5 and 6 (The Shoals, The Drowned Reach) have no models of their own yet.

-- The Far Sandbar. A sandbar spit with the ruined bell tower and its colonnade.
builders[Config.Beach.FarSandbar.Zone] = function(folder: Folder, rng: Random, zMin: number, zMax: number)
	local zMid = (zMin + zMax) / 2
	bellTower(folder, ground(0, zMid))
	for i = 0, 7 do
		local angle = i / 8 * math.pi * 2
		local x = math.cos(angle) * 14
		local z = zMid + math.sin(angle) * 14
		ruinedColumn(folder, ground(x, z), rng)
	end
	for _ = 1, 3 do
		local x = rng:NextNumber(-260, 260)
		local z = rng:NextNumber(zMin + 20, zMax - 20)
		rockCluster(folder, ground(x, z), 5, rng)
	end
end

-- Builds every zone's models into `map`, the Far Sandbar's included.
function ZoneProps.build(map: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "ZoneProps"
	folder.Parent = map
	for index = 1, #Config.Zones do
		local builder = builders[index]
		if builder then
			local zMin, zMax = Beach.zoneRange(index)
			builder(folder, Random.new(100 + index), zMin, zMax)
		end
	end
end

-- The pieces on their own, for the showroom (ShowroomExhibits).
ZoneProps.pieces = {
	lounger = lounger,
	towel = towel,
	hut = hut,
	sandbank = sandbank,
	driftwoodPile = driftwoodPile,
	net = net,
	boat = boat,
	wreck = wreck,
	rockCluster = rockCluster,
	tidepool = tidepool,
	coralPatch = coralPatch,
	pilingRow = pilingRow,
	pier = pier,
	bellTower = bellTower,
	ruinedColumn = ruinedColumn,
}

return ZoneProps
