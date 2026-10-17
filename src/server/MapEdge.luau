-- The edge of the map: a rocky coast instead of a flat grey wall. On each side the cove is closed by
-- a headland of terrain rock, two staggered terraces with grass on the lower one and bushes and
-- palms on it, boulders at its foot and sea stacks standing off its end. The rock is each zone's
-- own (Config.Looks), and the cliff is tall by the shop and sinks into the sea as it runs out,
-- the way a real headland does. Behind the dunes, green hills with palm groves close the view.
--
-- It is all built outside the area TerrainBuilder writes (TerrainBuilder.bounds), so rebuilding
-- a tile never cuts into it. What keeps players inside is a plain invisible barrier (built in
-- BeachBuilder); the palms and bushes here are scenery and don't collide.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)

local BeachDressing = require(script.Parent.BeachDressing)
local MapParts = require(script.Parent.MapParts)
local TerrainBuilder = require(script.Parent.TerrainBuilder)

local MapEdge = {}

local C = Palette.Cosmetic
local M = Palette.Material

local MOSS = { C.Moss, C.Olive, C.Green }

local STEP = 18 -- how far along Z each cliff section runs
local START_Z = -130 -- the cliff starts behind the dunes
local TOP_HEIGHT = 46 -- how tall the headland is at its tallest
local HILLS_DEPTH = 260 -- how far back the hills behind the dunes run

local function pick<T>(list: { T }, rng: Random): T
	return list[rng:NextInteger(1, #list)]
end

-- The cliff's top height at a given Z: tall at the back, sinking into the sea at the far end.
local function topAt(z: number, seaEnd: number): number
	local t = math.clamp((z - START_Z) / (seaEnd - START_Z), 0, 1)
	return TOP_HEIGHT - (TOP_HEIGHT + 2) * t ^ 0.9
end

-- The zone's rock at a given Z (the shop's behind the shoreline).
local function rockAt(z: number): Enum.Material
	local zone = Config.Looks.Zones[Beach.tileAt(z) or 0] or Config.Looks.Zones[0]
	return (Enum.Material :: any)[zone.Rock]
end

-- One headland, on `side` (-1 or 1) of the cove. `inner` is where the terrain may start.
local function headland(terrain: Terrain, folder: Folder, side: number, inner: number, rng: Random)
	local seaEnd = Beach.Depth + Config.Beach.SeaExtent
	local z = START_Z
	local index = 0
	while z < seaEnd do
		index += 1
		local top = topAt(z, seaEnd)
		local floorY = Beach.groundY(z) - 10
		local rock = rockAt(z)
		local mid = z + STEP / 2

		-- A straight backing right against the beach's terrain, so no gap shows between them.
		terrain:FillBlock(
			CFrame.new(side * (inner + 6), (top - 8 + floorY) / 2, mid),
			Vector3.new(12, math.max(top - 8 - floorY, 8), STEP),
			rock
		)
		-- Two terraces: a lower one at the front and a higher one behind it, each section
		-- turned a little so the face wanders.
		for layer = 1, 2 do
			local width = (if layer == 1 then 26 else 40) + rng:NextNumber(0, 6)
			local x0 = inner + (if layer == 1 then rng:NextNumber(3, 7) else 22)
			local heightTop = if layer == 1 then top - rng:NextNumber(0, 7) else top + rng:NextNumber(3, 12)
			local x = side * (x0 + width / 2)
			local turn = CFrame.Angles(rng:NextNumber(-0.05, 0.05), rng:NextNumber(-0.2, 0.2), 0)
			terrain:FillBlock(
				CFrame.new(x, (heightTop + floorY) / 2, mid) * turn,
				Vector3.new(width, heightTop - floorY, STEP + 8),
				rock
			)
			if layer == 1 and heightTop > 4 then
				-- Grass on the front terrace, and bushes and now and then a palm on it.
				terrain:FillBlock(
					CFrame.new(x + side * 2, heightTop + 0.5, mid) * turn,
					Vector3.new(width - 6, 3, STEP + 2),
					Enum.Material.Grass
				)
				for _ = 1, 2 do
					local d = rng:NextNumber(4, 7)
					MapParts.ball(
						folder,
						Vector3.new(
							x + rng:NextNumber(-6, 6),
							heightTop + 2 + d * 0.3,
							z + rng:NextNumber(0, STEP)
						),
						d,
						pick(MOSS, rng),
						M.Grass
					)
				end
				if index % 2 == 0 then
					BeachDressing.palm(
						folder,
						Vector3.new(x + rng:NextNumber(-6, 6), heightTop + 2, mid),
						rng:NextNumber(12, 18),
						rng
					)
				end
			end
		end

		-- Boulders at the foot, half sunk in the cliff.
		for _ = 1, 2 do
			local r = rng:NextNumber(4, 8)
			local bz = z + rng:NextNumber(0, STEP)
			terrain:FillBall(
				Vector3.new(side * (inner + r + rng:NextNumber(0, 3)), Beach.groundY(bz) + r * 0.2, bz),
				r,
				rock
			)
		end
		z += STEP
	end
end

-- Tall rock pillars standing in the sea off the end of each headland.
local function seaStacks(terrain: Terrain, side: number, inner: number, rng: Random)
	local half = Beach.HalfWidth
	local seaEnd = Beach.Depth + Config.Beach.SeaExtent
	for _ = 1, 10 do
		local z = rng:NextNumber(250, seaEnd - 40)
		local radius = rng:NextNumber(5, 8)
		local x = side * math.max(inner + radius, half + rng:NextNumber(60, 200))
		local bottom = Beach.groundY(z) - 6
		local top = -3 + rng:NextNumber(8, 26)
		local rock = rockAt(z)
		local lower = (top - bottom) * 0.7
		terrain:FillCylinder(CFrame.new(x, bottom + lower / 2, z), lower, radius, rock)
		terrain:FillCylinder(
			CFrame.new(x + rng:NextNumber(-1, 1), bottom + lower + (top - bottom - lower) / 2, z),
			top - bottom - lower,
			radius * 0.65,
			rock
		)
		terrain:FillBall(Vector3.new(x, top, z), radius * 0.6, rock)
	end
end

-- Behind the dunes: a strip of sand, then rolling green hills with palm groves on them.
local function hills(terrain: Terrain, folder: Folder, back: number, outer: number, rng: Random)
	local depth = HILLS_DEPTH
	local sand = 16
	terrain:FillBlock(
		CFrame.new(0, -6, back - sand / 2),
		Vector3.new(outer * 2, 12, sand),
		Enum.Material.Sand
	)
	terrain:FillBlock(
		CFrame.new(0, -6, back - sand - (depth - sand) / 2),
		Vector3.new(outer * 2, 12, depth - sand),
		Enum.Material.Grass
	)
	local tops, balls = {}, {}
	for _ = 1, 54 do
		local r = rng:NextNumber(22, 46)
		local x = rng:NextNumber(-outer, outer)
		-- Low mounds near the front, growing taller further back.
		local z = back - sand - rng:NextNumber(r * 0.4, depth - r)
		local height = 2 + (back - z) * rng:NextNumber(0.06, 0.14)
		terrain:FillBall(Vector3.new(x, height - r, z), r, Enum.Material.Grass)
		table.insert(tops, Vector3.new(x, height, z))
		table.insert(balls, { Vector3.new(x, height - r, z), r })
	end
	-- The ground's height at (x, z): the highest of the hills there, or the flat at 0.
	local function groundAt(x: number, z: number): number
		local y = 0
		for _, hill in balls do
			local c, r = hill[1], hill[2]
			local flat = (x - c.X) ^ 2 + (z - c.Z) ^ 2
			if flat < r * r then
				y = math.max(y, c.Y + math.sqrt(r * r - flat))
			end
		end
		return y
	end
	local function onGround(at: Vector3, a: number, d: number, sink: number): Vector3
		local x, z = at.X + math.cos(a) * d, at.Z + math.sin(a) * d
		return Vector3.new(x, groundAt(x, z) - sink, z)
	end
	-- Palm groves on a few of the hilltops, and bushes round them.
	for index, at in tops do
		if index % 3 == 0 then
			for _ = 1, rng:NextInteger(3, 6) do
				local a = rng:NextNumber() * math.pi * 2
				local d = rng:NextNumber(2, 14)
				BeachDressing.palm(folder, onGround(at, a, d, 0.8), rng:NextNumber(14, 22), rng)
			end
		end
		for _ = 1, 3 do
			local a = rng:NextNumber() * math.pi * 2
			local d = rng:NextNumber(6, 18)
			local size = rng:NextNumber(5, 9)
			MapParts.ball(folder, onGround(at, a, d, -size * 0.3), size, pick(MOSS, rng), M.Grass)
		end
	end
end

-- Dune grass along the back of the beach, in clumps along the dunes' crest with open sand
-- between them.
local function backFringe(folder: Folder, rng: Random)
	local half = Beach.HalfWidth
	for _ = 1, 16 do
		local cx = rng:NextNumber(-half + 20, half - 20)
		local cz = rng:NextNumber(-120, -96)
		local color = pick(MOSS, rng)
		for _ = 1, rng:NextInteger(4, 8) do
			local x = cx + rng:NextNumber(-7, 7)
			local z = cz + rng:NextNumber(-5, 5)
			for _ = 1, 5 do
				local h = rng:NextNumber(2, 4)
				MapParts.scenery(folder, {
					Name = "Grass",
					Size = Vector3.new(0.25, h, 0.06),
					CFrame = CFrame.new(
						x + rng:NextNumber(-0.6, 0.6),
						4 + h / 2 - 0.5,
						z + rng:NextNumber(-0.6, 0.6)
					) * CFrame.Angles(
						rng:NextNumber(-0.25, 0.25),
						rng:NextNumber() * math.pi,
						rng:NextNumber(-0.25, 0.25)
					),
					Color = color,
					Material = M.Grass,
				})
			end
		end
		local d = rng:NextNumber(3, 6)
		MapParts.ball(folder, Vector3.new(cx, 4 + d * 0.3, cz - 4), d, color, M.Grass)
	end
end

function MapEdge.build(map: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "MapEdge"
	folder.Parent = map
	local rng = Random.new(41)
	backFringe(folder, rng)
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		return -- tools/tests: no Terrain to write to
	end
	local lo, hi = TerrainBuilder.bounds()
	local inner = hi.X
	for side = -1, 1, 2 do
		headland(terrain, folder, side, inner, rng)
		seaStacks(terrain, side, inner, rng)
	end
	hills(terrain, folder, lo.Z, inner + 80, rng)
end

return MapEdge
