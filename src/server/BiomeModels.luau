-- The models for each biome in the design: the common ones (where a normal secret waits) and the
-- rarer ones (where an exotic secret waits). Each has its own silhouette, built from parts, and
-- they're sized for the real map: a plot is 90 studs across, and a lighthouse or a tornado is
-- tens of studs tall, the way things are on a 720-stud beach.
--
-- The hazards (barrels, jellyfish, fog, tornado, the hermit crab, spike floors, glass, ice,
-- vents) are grouped in models named "Hazard_..." so the mechanics can find them later. They
-- don't do anything yet. Nothing here collides or is queried.
--
-- Shown on a showcase strip behind the dunes; see BiomeModels.showcase.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local BeachDressing = require(script.Parent.BeachDressing)
local MapParts = require(script.Parent.MapParts)

local BiomeModels = {}

local B = Palette.Biome
local Z = Palette.Zone
local W = Palette.World
local M = Palette.Material

local SIZE = 90 -- a plot is this many studs across
local add = MapParts.scenery
local ball = MapParts.ball
local column = MapParts.column

-- A block with its own orientation, for the bits that aren't column-shaped.
local function block(
	parent: Instance,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	return add(parent, {
		Name = "Block",
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material or M.Smooth,
		Transparency = transparency or 0,
	})
end

-- A flat horizontal disc: a lake, a patch, a vent's rim.
local function disc(
	parent: Instance,
	center: Vector3,
	diameter: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	return add(parent, {
		Name = "Disc",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(thickness, diameter, diameter),
		CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Material = material or M.Smooth,
		Transparency = transparency or 0,
	})
end

-- A tower that tapers from `d0` at the bottom to `d1` at the top, in `levels` steps.
local function taper(
	parent: Instance,
	base: Vector3,
	levels: number,
	d0: number,
	d1: number,
	height: number,
	color: Color3,
	material: Enum.Material?
)
	local each = height / levels
	for i = 0, levels - 1 do
		local t = i / math.max(levels - 1, 1)
		column(parent, base + Vector3.new(0, each * i, 0), each, d0 + (d1 - d0) * t, color, material)
	end
end

-- A standing post, a few studs thick.
local function post(parent: Instance, base: Vector3, height: number, color: Color3)
	column(parent, base, height, 1, color, M.Wood)
end

-- A plot: the slab the biome sits on, and its name on a sign.
local function plot(folder: Folder, c: Vector3, name: string, ground: Color3): Folder
	local p = Instance.new("Folder")
	p.Name = name
	p.Parent = folder
	block(p, CFrame.new(c + Vector3.new(0, 0.2, 0)), Vector3.new(SIZE, 0.4, SIZE), ground, M.Sand)
	MapParts.sign(p, name, CFrame.new(c.X, 14, c.Z - SIZE / 2 + 2), SIZE * 0.6, 3, c.Y)
	return p
end

-- Common biomes ---------------------------------------------------------------------------

-- A giant sandcastle with four towers and a door, in a moat, with small castles around it.
local function sandcastleFlats(p: Instance, c: Vector3, rng: Random)
	disc(p, c + Vector3.new(0, 0.4, 0), 78, 0.3, B.Moat, M.Glass, 0.3)
	disc(p, c + Vector3.new(0, 0.6, 0), 46, 0.4, B.SandcastleSand, M.Sand)
	block(p, CFrame.new(c + Vector3.new(0, 12, 0)), Vector3.new(24, 22, 24), B.SandcastleSand, M.Sand)
	for _, x in { -12, 12 } do
		for _, z in { -12, 12 } do
			local top = c + Vector3.new(x, 30.8, z)
			column(p, c + Vector3.new(x, 0.8, z), 30, 8, B.SandcastleSand, M.Sand)
			post(p, top, 6, W.Post)
			block(
				p,
				CFrame.new(top + Vector3.new(1.5, 4, 0)),
				Vector3.new(3, 2, 0.2),
				Color3.fromHSV(rng:NextNumber(), 0.7, 1)
			)
		end
	end
	block(p, CFrame.new(c + Vector3.new(0, 6, -12.2)), Vector3.new(6, 11, 0.6), B.Hollow, M.Wood)
	for _ = 1, 8 do
		local s = rng:NextNumber(3, 6)
		local x = rng:NextNumber(-34, 34)
		local z = rng:NextNumber(-34, 34)
		if math.abs(x) > 16 or math.abs(z) > 16 then
			block(
				p,
				CFrame.new(c + Vector3.new(x, s / 2 + 0.6, z)),
				Vector3.new(s, s, s),
				B.SandcastleSand,
				M.Sand
			)
		end
	end
end

-- A huge beached tree trunk with a hollow end, a driftwood arch, rope coils and bottles.
local function driftwoodCove(p: Instance, c: Vector3, rng: Random)
	add(p, {
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(60, 12, 12),
		CFrame = CFrame.new(c + Vector3.new(0, 6, -4)) * CFrame.Angles(0, math.pi / 2, 0),
		Color = W.Driftwood,
		Material = M.Wood,
	})
	add(p, {
		Name = "TrunkHollow",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 10, 10),
		CFrame = CFrame.new(c + Vector3.new(0, 6, -34)) * CFrame.Angles(0, math.pi / 2, 0),
		Color = B.Hollow,
		Material = M.Wood,
	})
	for _, x in { -26, -14 } do
		column(p, c + Vector3.new(x, 0.6, 22), 26, 3.5, W.DarkWood, M.Wood)
	end
	block(p, CFrame.new(c + Vector3.new(-20, 26.5, 22)), Vector3.new(16, 3, 4), W.DarkWood, M.Wood)
	for level = 0, 3 do
		disc(p, c + Vector3.new(26, 0.8 + level * 0.8, -22), 6, 0.8, B.Rope, M.Fabric)
	end
	for _ = 1, 8 do
		local x = rng:NextNumber(-36, 36)
		local z = rng:NextNumber(-36, 36)
		add(p, {
			Name = "Bottle",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.4, 0.9, 0.9),
			CFrame = CFrame.new(c + Vector3.new(x, 0.8, z))
				* CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0),
			Color = B.Bottle,
			Material = M.Glass,
			Transparency = 0.2,
		})
	end
	for _ = 1, 10 do
		local x = rng:NextNumber(-36, 36)
		local z = rng:NextNumber(-36, 36)
		block(
			p,
			CFrame.new(c + Vector3.new(x, 0.5, z)) * CFrame.Angles(0, rng:NextNumber() * math.pi, 0),
			Vector3.new(8, 0.8, 1.2),
			W.Driftwood,
			M.Wood
		)
	end
	block(p, CFrame.new(c + Vector3.new(-30, 1.5, 30)), Vector3.new(3, 3, 5), B.Boot, M.Fabric)
	block(p, CFrame.new(c + Vector3.new(-25, 1.5, 33)), Vector3.new(3, 3, 5), B.Boot, M.Fabric)
end

-- A ridge of grey rocks in an arc, pools in the rock, a blowhole and starfish.
local function tidepoolRocks(p: Instance, c: Vector3, rng: Random)
	for i = 0, 9 do
		local a = math.pi * (0.1 + 0.8 * i / 9)
		local d = rng:NextNumber(8, 14)
		ball(p, c + Vector3.new(math.cos(a) * 32, d * 0.3, -math.sin(a) * 26 - 6), d, Z.RockGrey, M.Rock)
	end
	for _, pos in
		{ Vector3.new(-14, 0, 6), Vector3.new(14, 0, 4), Vector3.new(-6, 0, 22), Vector3.new(18, 0, 24) }
	do
		disc(p, c + pos + Vector3.new(0, 0.4, 0), 6, 0.3, B.Lagoon, M.Glass, 0.25)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			ball(p, c + pos + Vector3.new(math.cos(a) * 3.8, 0.5, math.sin(a) * 3.8), 1.8, Z.RockDark, M.Rock)
		end
	end
	column(p, c + Vector3.new(-28, 0, -28), 14, 6, Z.RockDark, M.Rock)
	disc(p, c + Vector3.new(-28, 14.2, -28), 4, 0.4, B.Hollow, M.Rock)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		add(p, {
			Name = "Starfish",
			Size = Vector3.new(1.2, 0.4, 4),
			CFrame = CFrame.new(c + Vector3.new(30 + math.cos(a) * 2.4, 0.5, 30 + math.sin(a) * 2.4))
				* CFrame.Angles(0, a, 0),
			Color = B.Starfish,
			Material = M.Smooth,
		})
	end
end

-- A jetty that has collapsed into the shallows, a line of buoys, seagrass and glass floats.
local function seagrassShallows(p: Instance, c: Vector3, rng: Random)
	block(
		p,
		CFrame.new(c + Vector3.new(0, 6, 0)) * CFrame.Angles(0, math.rad(35), math.rad(-14)),
		Vector3.new(60, 1.2, 8),
		Z.Pier,
		M.WoodPlanks
	)
	for k = -2, 2 do
		column(p, c + Vector3.new(k * 12, 0.6, 0), rng:NextNumber(6, 9), 1.8, W.DarkWood, M.Wood)
	end
	for i = 0, 5 do
		local x = i * 12 - 30
		post(p, c + Vector3.new(x, 0.6, 34), 6, W.Post)
		ball(p, c + Vector3.new(x, 6.8, 34), 3, if i % 2 == 0 then B.BuoyRed else B.BuoyWhite, M.Smooth)
	end
	for _ = 1, 40 do
		local x = rng:NextNumber(-40, 40)
		local z = rng:NextNumber(-40, 40)
		local h = rng:NextNumber(3, 6)
		block(
			p,
			CFrame.new(c + Vector3.new(x, h / 2, z))
				* CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2)),
			Vector3.new(0.4, h, 0.4),
			B.Seagrass,
			M.Grass
		)
	end
	for _ = 1, 6 do
		ball(p, c + Vector3.new(rng:NextNumber(-36, 36), 1, rng:NextNumber(-36, 36)), 2, B.Float, M.Glass)
	end
end

-- Branching coral towers around a reef arch, with a palm and coconuts.
local function coralGarden(p: Instance, c: Vector3, rng: Random)
	local colors = { Z.Coral1, Z.Coral2, Z.Coral3 }
	for _ = 1, 5 do
		local base = c + Vector3.new(rng:NextNumber(-30, 30), 0, rng:NextNumber(-30, 30))
		local color = colors[rng:NextInteger(1, #colors)]
		local height = rng:NextNumber(14, 22)
		taper(p, base, 4, 6, 2, height, color, M.Smooth)
		for _ = 1, 3 do
			local yaw = rng:NextNumber() * math.pi * 2
			local tip = base + Vector3.new(0, height * 0.6, 0)
			add(p, {
				Name = "Branch",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(7, 1.4, 1.4),
				CFrame = CFrame.new(tip)
					* CFrame.Angles(0, yaw, 0)
					* CFrame.Angles(0, 0, math.rad(60))
					* CFrame.new(3, 0, 0),
				Color = color,
				Material = M.Smooth,
			})
		end
		ball(p, base + Vector3.new(0, height + 1.2, 0), 2.6, color, M.Smooth)
	end
	for _, x in { -16, 16 } do
		column(p, c + Vector3.new(x, 0, -22), 17, 4, Z.Coral2, M.Smooth)
	end
	block(p, CFrame.new(c + Vector3.new(0, 17.5, -22)), Vector3.new(36, 4, 7), Z.Coral1, M.Smooth)
	BeachDressing.palm(p, c + Vector3.new(28, 0, 28), 14, rng)
	for _ = 1, 6 do
		ball(p, c + Vector3.new(rng:NextNumber(22, 34), 0.7, rng:NextNumber(22, 34)), 1.4, B.Coconut, M.Wood)
	end
	for _ = 1, 3 do
		column(
			p,
			c + Vector3.new(rng:NextNumber(-38, -24), 0, rng:NextNumber(20, 36)),
			4,
			0.6,
			B.Snorkel,
			M.Smooth
		)
	end
end

-- Rare biomes -----------------------------------------------------------------------------

-- A hull lying on its side, planks, a broken mast, a hatch, a ship's bell and barrels that
-- roll down the sand (hazard).
local function shipwreckShallows(p: Instance, c: Vector3, rng: Random)
	block(
		p,
		CFrame.new(c + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(18)),
		Vector3.new(60, 14, 18),
		W.DarkWood,
		M.WoodPlanks
	)
	for _ = 1, 10 do
		local x = rng:NextNumber(-38, 38)
		local z = rng:NextNumber(-38, 38)
		block(
			p,
			CFrame.new(c + Vector3.new(x, 0.6, z))
				* CFrame.Angles(0, rng:NextNumber() * math.pi, rng:NextNumber(-0.3, 0.3)),
			Vector3.new(10, 0.8, 1.4),
			W.DarkWood,
			M.WoodPlanks
		)
	end
	add(p, {
		Name = "Mast",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(40, 1.6, 1.6),
		CFrame = CFrame.new(c + Vector3.new(8, 20, 0)) * CFrame.Angles(0, 0, math.pi / 2 - math.rad(12)),
		Color = W.Mast,
		Material = M.Wood,
	})
	block(p, CFrame.new(c + Vector3.new(0, 8, -9)), Vector3.new(6, 8, 0.6), B.Hollow, M.Wood)
	post(p, c + Vector3.new(-22, 0, -22), 8, W.Post)
	ball(p, c + Vector3.new(-22, 8.4, -22), 2.8, Z.Bell, M.Metal)
	local barrels = Instance.new("Model")
	barrels.Name = "Hazard_Barrels"
	barrels.Parent = p
	for _ = 1, 6 do
		local x = rng:NextNumber(-34, 34)
		local z = rng:NextNumber(-34, 34)
		add(barrels, {
			Name = "Barrel",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(5, 4, 4),
			CFrame = CFrame.new(c + Vector3.new(x, 2, z))
				* CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0),
			Color = W.Barrel,
			Material = M.Wood,
		})
	end
end

-- A lagoon ringed with rocks, glowing jellyfish hanging over it (hazard) and a grotto.
local function jellyfishLagoon(p: Instance, c: Vector3, rng: Random)
	disc(p, c + Vector3.new(0, 0.2, 0), 70, 0.3, B.Lagoon, M.Glass, 0.2)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		block(
			p,
			CFrame.new(c + Vector3.new(math.cos(a) * 38, 3, math.sin(a) * 38)),
			Vector3.new(8, 6, 8),
			Z.RockGrey,
			M.Rock
		)
	end
	local jellies = Instance.new("Model")
	jellies.Name = "Hazard_Jellyfish"
	jellies.Parent = p
	for i = 1, 6 do
		local x = rng:NextNumber(-24, 24)
		local z = rng:NextNumber(-24, 24)
		local height = rng:NextNumber(16, 22)
		local color = if i % 2 == 0 then B.JellyBlue else B.JellyPink
		ball(jellies, c + Vector3.new(x, height, z), rng:NextNumber(8, 12), color, M.Neon).Transparency = 0.35
		for _ = 1, 4 do
			local tx = x + rng:NextNumber(-3, 3)
			local tz = z + rng:NextNumber(-3, 3)
			column(jellies, c + Vector3.new(tx, height - 8, tz), 8, 0.4, B.Tentacle, M.Neon).Transparency =
				0.3
		end
	end
	for _, x in { -36, -26 } do
		block(p, CFrame.new(c + Vector3.new(x, 8, -30)), Vector3.new(4, 16, 6), Z.RockDark, M.Rock)
	end
	block(p, CFrame.new(c + Vector3.new(-31, 17, -30)), Vector3.new(16, 3, 6), Z.RockDark, M.Rock)
	ball(p, c + Vector3.new(-31, 4, -30), 6, B.Glow, M.Neon)
end

-- A lighthouse in its own fog bank, a foghorn and banks of fog (hazard).
local function fogBank(p: Instance, c: Vector3, rng: Random)
	local base = c + Vector3.new(-20, 0, -20)
	taper(p, base, 8, 14, 9, 60, B.LighthouseWhite, M.Smooth)
	for _, y in { 20, 40 } do
		column(p, base + Vector3.new(0, y, 0), 4, 15, B.LighthouseRed, M.Smooth)
	end
	column(p, base + Vector3.new(0, 60, 0), 6, 10, B.LampGlass, M.Glass)
	disc(p, base + Vector3.new(0, 66.5, 0), 12, 1, B.LighthouseRed, M.Smooth)
	block(p, CFrame.new(base + Vector3.new(0, 3, 7.2)), Vector3.new(4, 6, 0.6), B.Hollow, M.Wood)
	post(p, c + Vector3.new(20, 0, 20), 10, W.Post)
	add(p, {
		Name = "Foghorn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(8, 3, 3),
		CFrame = CFrame.new(c + Vector3.new(20, 10, 20)) * CFrame.Angles(0, math.pi / 4, 0),
		Color = B.Foghorn,
		Material = M.Metal,
	})
	local fog = Instance.new("Model")
	fog.Name = "Hazard_Fog"
	fog.Parent = p
	for _ = 1, 4 do
		local cx = rng:NextNumber(-28, 28)
		local cz = rng:NextNumber(-20, 28)
		for _ = 1, 6 do
			ball(
				fog,
				c + Vector3.new(cx + rng:NextNumber(-8, 8), rng:NextNumber(6, 18), cz + rng:NextNumber(-8, 8)),
				rng:NextNumber(14, 22),
				B.Fog,
				M.Smooth
			).Transparency =
				0.5
		end
	end
end

-- Spires of sand, and a tornado that spins across the plot (hazard).
local function whirlwindDunes(p: Instance, c: Vector3, rng: Random)
	taper(p, c + Vector3.new(-26, 0, -18), 5, 18, 9, 36, W.Sand, M.Sand)
	taper(p, c + Vector3.new(18, 0, -26), 4, 14, 7, 26, W.Sand, M.Sand)
	taper(p, c + Vector3.new(-4, 0, 24), 4, 16, 8, 30, W.Sand, M.Sand)
	local tornado = Instance.new("Model")
	tornado.Name = "Hazard_Tornado"
	tornado.Parent = p
	for i = 0, 13 do
		local t = i / 13
		local sway = math.sin(i * 0.9) * 3
		disc(tornado, c + Vector3.new(20 + sway, 2 + t * 56, 10), 34 - 30 * t, 1.2, B.WhirlSand, M.Sand, 0.55)
	end
end

-- A giant hermit crab with a shell (hazard), tunnels through a sand mound.
local function hermitHollows(p: Instance, c: Vector3, rng: Random)
	local crab = Instance.new("Model")
	crab.Name = "Hazard_HermitCrab"
	crab.Parent = p
	local body = c + Vector3.new(0, 7, 0)
	ball(crab, body, 14, B.Hermit, M.Smooth)
	taper(crab, c + Vector3.new(-8, 2, 0), 4, 22, 8, 22, B.ShellTan, M.Smooth)
	for _, side in { -1, 1 } do
		for k = 0, 2 do
			block(
				crab,
				CFrame.new(body + Vector3.new(side * 7, -4 + k * 2, -2 + k * 3))
					* CFrame.Angles(0, 0, side * math.rad(35)),
				Vector3.new(1, 1, 10),
				B.Hermit,
				M.Smooth
			)
		end
	end
	for _, side in { -1, 1 } do
		ball(crab, c + Vector3.new(side * 10, 9, 8), 6, B.Claw, M.Smooth)
	end
	for _, side in { -1, 1 } do
		ball(crab, body + Vector3.new(side * 2, 5, 6.5), 1.2, B.Hollow, M.Smooth)
	end
	block(p, CFrame.new(c + Vector3.new(22, 3, -30)), Vector3.new(60, 6, 16), B.WhirlSand, M.Sand)
	for _, x in { -30, -10, 10 } do
		for _, side in { -1, 1 } do
			column(p, c + Vector3.new(x + side * 4, 0.6, -10), 12, 3, B.Tunnel, M.Sand)
		end
		block(p, CFrame.new(c + Vector3.new(x, 12.5, -10)), Vector3.new(16, 3, 8), B.Tunnel, M.Sand)
	end
end

-- Spears of stone standing out of the reef, a field of spikes (hazard) and a timing gap.
local function spearstoneReef(p: Instance, c: Vector3, rng: Random)
	for _, pos in
		{ Vector3.new(-28, 0, -26), Vector3.new(26, 0, -30), Vector3.new(-30, 0, 4), Vector3.new(30, 0, 8) }
	do
		taper(p, c + pos, 6, 10, 1.5, rng:NextNumber(36, 44), B.Spear, M.Rock)
		ball(p, c + pos + Vector3.new(0, 44, 0), 1.2, B.SpearTip, M.Metal)
	end
	local spikes = Instance.new("Model")
	spikes.Name = "Hazard_Spikes"
	spikes.Parent = p
	for i = 0, 5 do
		for k = 0, 5 do
			taper(spikes, c + Vector3.new(-15 + i * 6, 0, 22 + k * 6), 3, 4, 0.6, 5, B.SpearTip, M.Smooth)
		end
	end
	for _, x in { -12, 12 } do
		block(p, CFrame.new(c + Vector3.new(x, 10, -2)), Vector3.new(10, 20, 6), B.Spear, M.Rock)
	end
end

-- Prism pillars, shards of sea-glass (hazard), coloured glass patches and a prism arch.
local function seaGlassShore(p: Instance, c: Vector3, rng: Random)
	local glass = { B.GlassTeal, B.GlassPink, B.GlassWhite, B.GlassViolet }
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local pillar = block(
			p,
			CFrame.new(c + Vector3.new(math.cos(a) * 22, 14, math.sin(a) * 22))
				* CFrame.Angles(0, 0, rng:NextNumber(-0.05, 0.05)),
			Vector3.new(2.4, 28, 2.4),
			glass[(i % #glass) + 1],
			M.Glass,
			0.25
		)
		pillar.Name = "Prism"
	end
	local shards = Instance.new("Model")
	shards.Name = "Hazard_Glass"
	shards.Parent = p
	for _ = 1, 20 do
		local x = rng:NextNumber(-38, 38)
		local z = rng:NextNumber(-38, 38)
		local h = rng:NextNumber(5, 12)
		block(
			shards,
			CFrame.new(c + Vector3.new(x, h / 2, z))
				* CFrame.Angles(
					rng:NextNumber(-0.3, 0.3),
					rng:NextNumber() * math.pi,
					rng:NextNumber(-0.3, 0.3)
				),
			Vector3.new(1.2, h, 1.2),
			glass[rng:NextInteger(1, #glass)],
			M.Glass,
			0.15
		)
	end
	for _ = 1, 6 do
		disc(
			p,
			c + Vector3.new(rng:NextNumber(-34, 34), 0.3, rng:NextNumber(-34, 34)),
			rng:NextNumber(6, 10),
			0.3,
			glass[rng:NextInteger(1, #glass)],
			M.Glass,
			0.4
		)
	end
	for _, x in { -30, -18 } do
		block(p, CFrame.new(c + Vector3.new(x, 10, -34)), Vector3.new(3, 20, 3), B.GlassWhite, M.Glass, 0.2)
	end
	block(p, CFrame.new(c + Vector3.new(-24, 20.5, -34)), Vector3.new(15, 2, 4), B.GlassViolet, M.Glass, 0.2)
end

-- A berg of stacked ice, a cave at its foot, a slippery slope (hazard) and chunks around it.
local function strandedIceberg(p: Instance, c: Vector3, rng: Random)
	local layers = { { 34, 6, 30 }, { 28, 8, 24 }, { 22, 9, 18 }, { 14, 9, 12 }, { 8, 7, 7 } }
	local y = 0
	for i, dims in layers do
		block(
			p,
			CFrame.new(c + Vector3.new(rng:NextNumber(-2, 2), y + dims[2] / 2, rng:NextNumber(-2, 2)))
				* CFrame.Angles(0, i * 0.5, 0),
			Vector3.new(dims[1], dims[2], dims[3]),
			if i % 2 == 0 then B.IceWhite else B.IceBlue,
			M.Smooth,
			0.05
		)
		y += dims[2]
	end
	block(p, CFrame.new(c + Vector3.new(0, 5, -15)), Vector3.new(12, 10, 4), B.IceCave, M.Smooth)
	local slope = Instance.new("Model")
	slope.Name = "Hazard_Ice"
	slope.Parent = p
	block(
		slope,
		CFrame.new(c + Vector3.new(28, 8, 8)) * CFrame.Angles(0, 0, math.rad(12)),
		Vector3.new(40, 1, 30),
		B.IceDeep,
		M.Glass,
		0.1
	)
	for _ = 1, 8 do
		ball(p, c + Vector3.new(rng:NextNumber(-38, 38), 2, rng:NextNumber(-38, 38)), 4, B.IceWhite, M.Smooth)
	end
end

-- Black sand, three steaming vents (hazard) and a lava tube arch.
local function blackSandVents(p: Instance, c: Vector3, rng: Random)
	block(
		p,
		CFrame.new(c + Vector3.new(0, 0.3, 0)),
		Vector3.new(SIZE - 10, 0.4, SIZE - 10),
		B.BlackSand,
		M.Sand
	)
	local vents = Instance.new("Model")
	vents.Name = "Hazard_Vent"
	vents.Parent = p
	for _, pos in { Vector3.new(-22, 0, -20), Vector3.new(14, 0, -24), Vector3.new(0, 0, 16) } do
		column(vents, c + pos, 34, 8, B.VentGrey, M.Rock)
		disc(vents, c + pos + Vector3.new(0, 34.3, 0), 7, 0.6, B.Lava, M.Neon)
		for _ = 1, 3 do
			ball(
				vents,
				c + pos + Vector3.new(rng:NextNumber(-4, 4), 40 + rng:NextNumber(0, 8), rng:NextNumber(-4, 4)),
				10,
				B.Steam,
				M.Smooth
			).Transparency =
				0.5
		end
	end
	for _, x in { -28, -16 } do
		block(p, CFrame.new(c + Vector3.new(x, 9, 26)), Vector3.new(4, 18, 4), B.TubeDark, M.Rock)
	end
	block(p, CFrame.new(c + Vector3.new(-22, 18.5, 26)), Vector3.new(16, 4, 8), B.TubeDark, M.Rock)
end

-- Every biome in the design, with its ground colour and builder. Common ones first.
local BIOMES = {
	{ "Sandcastle Flats", B.SandcastleSand, sandcastleFlats },
	{ "Driftwood Cove", W.Sand, driftwoodCove },
	{ "Tidepool Rocks", W.Sand, tidepoolRocks },
	{ "Seagrass Shallows", W.Sand, seagrassShallows },
	{ "Coral Garden", W.Sand, coralGarden },
	{ "Shipwreck Shallows", W.Sand, shipwreckShallows },
	{ "Jellyfish Lagoon", W.Sand, jellyfishLagoon },
	{ "Fog Bank", W.Sand, fogBank },
	{ "Whirlwind Dunes", B.WhirlSand, whirlwindDunes },
	{ "Hermit Hollows", W.Sand, hermitHollows },
	{ "Spearstone Reef", W.Rock, spearstoneReef },
	{ "Sea-Glass Shore", W.Sand, seaGlassShore },
	{ "Stranded Iceberg", W.Sand, strandedIceberg },
	{ "Black Sand Vents", B.BlackSand, blackSandVents },
}

-- The showcase strip: every biome on a flat strip behind the dunes, seven to a row. It's
-- off the playable beach, so it's there to look at and walk around.
local ROW_Z = { -200, -320 }
local COLUMN_X = { -300, -200, -100, 0, 100, 200, 300 }

function BiomeModels.showcase(map: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "BiomeShowcase"
	folder.Parent = map
	-- Flat ground under the plots, so they don't float over the void.
	MapParts.part({
		Name = "ShowcaseGround",
		Size = Vector3.new(720, 10, 300),
		CFrame = CFrame.new(0, -5, -260),
		Color = W.Sand,
		Material = M.Sand,
	}).Parent =
		folder

	for i, entry in BIOMES do
		local name, ground, build = entry[1], entry[2], entry[3]
		local index = i - 1
		local c = Vector3.new(COLUMN_X[index % #COLUMN_X + 1], 0, ROW_Z[math.floor(index / #COLUMN_X) + 1])
		local p = plot(folder, c, name, ground)
		build(p, c, Random.new(300 + i))
	end
end

return BiomeModels
