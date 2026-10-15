-- The edge of the map: a rocky coast instead of a flat grey wall. On each side the cove is closed by
-- a headland made of staggered cliff terraces, capped with moss and bushes and palms, with boulders
-- at its foot and sea stacks standing off its end. The cliff is tall by the shop and sinks into the
-- sea as it runs out, the way a real headland does.
--
-- What keeps players inside is a plain invisible barrier (built in BeachBuilder); everything here
-- is scenery and doesn't collide. Behind the dunes, a fringe of dune grass softens the back edge.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Config = require(Shared.Config)
local Beach = require(Shared.Beach)

local BeachDressing = require(script.Parent.BeachDressing)
local MapParts = require(script.Parent.MapParts)

local MapEdge = {}

local Z = Palette.Zone
local C = Palette.Cosmetic
local W = Palette.World
local M = Palette.Material
local add = MapParts.scenery

local ROCKS = { Z.RockGrey, Z.RockDark, W.Rock, C.Stone }
local MOSS = { C.Moss, C.Olive, C.Green }

local STEP = 22 -- how far along Z each cliff section runs
local START_Z = -130 -- the cliff starts behind the dunes
local TOP_HEIGHT = 46 -- how tall the headland is at its tallest

local function pick<T>(list: { T }, rng: Random): T
	return list[rng:NextInteger(1, #list)]
end

-- The cliff's top height at a given Z: tall at the back, sinking into the sea at the far end.
local function topAt(z: number, seaEnd: number): number
	local t = math.clamp((z - START_Z) / (seaEnd - START_Z), 0, 1)
	return TOP_HEIGHT - (TOP_HEIGHT + 2) * t ^ 0.9
end

-- One headland, on `side` (-1 or 1) of the cove.
local function headland(folder: Folder, side: number, rng: Random)
	local half = Beach.HalfWidth
	local seaEnd = Beach.Depth + Config.Beach.SeaExtent
	local z = START_Z
	local index = 0
	while z < seaEnd do
		index += 1
		local top = topAt(z, seaEnd)
		local floorY = Beach.groundY(z) - 8

		-- Two terraces: a lower one at the front and a higher one behind it.
		for layer = 1, 2 do
			local width = if layer == 1 then 22 else 34
			local inner = half + 14 + (if layer == 1 then 0 else 22)
			local heightTop = if layer == 1 then top - rng:NextNumber(0, 7) else top + rng:NextNumber(3, 12)
			local height = heightTop - floorY
			local x = side * (inner + width / 2)
			add(folder, {
				Name = "Cliff",
				Size = Vector3.new(width, height, STEP + 4),
				CFrame = CFrame.new(x, (heightTop + floorY) / 2, z + STEP / 2),
				Color = pick(ROCKS, rng),
				Material = M.Rock,
			})
			if layer == 1 then
				-- A mossy cap on the front terrace.
				add(folder, {
					Name = "Moss",
					Size = Vector3.new(width + 1, 1.2, STEP + 2),
					CFrame = CFrame.new(x, heightTop + 0.4, z + STEP / 2),
					Color = pick(MOSS, rng),
					Material = M.Grass,
				})
				if heightTop > 4 then
					for _ = 1, 3 do
						local d = rng:NextNumber(4, 7)
						MapParts.ball(
							folder,
							Vector3.new(
								x + rng:NextNumber(-8, 8),
								heightTop + d * 0.35,
								z + rng:NextNumber(0, STEP)
							),
							d,
							pick(MOSS, rng),
							M.Grass
						)
					end
					if index % 2 == 0 then
						local px = x + rng:NextNumber(-6, 6)
						BeachDressing.palm(
							folder,
							Vector3.new(px, heightTop + 0.6, z + STEP / 2),
							rng:NextNumber(12, 18),
							rng
						)
					end
				end
			end
		end

		-- Boulders at the foot, where the cliff meets the beach and the sea.
		for _ = 1, 3 do
			local d = rng:NextNumber(10, 18)
			local bz = z + rng:NextNumber(0, STEP)
			MapParts.ball(
				folder,
				Vector3.new(side * (half + 10 + rng:NextNumber(0, 8)), Beach.groundY(bz) + d * 0.3, bz),
				d,
				pick(ROCKS, rng),
				M.Rock
			)
		end
		z += STEP
	end
end

-- Tall rock pillars standing in the sea off the end of each headland.
local function seaStacks(folder: Folder, side: number, rng: Random)
	local half = Beach.HalfWidth
	local seaEnd = Beach.Depth + Config.Beach.SeaExtent
	for _ = 1, 10 do
		local z = rng:NextNumber(250, seaEnd - 40)
		local x = side * (half + rng:NextNumber(60, 200))
		local bottom = Beach.groundY(z) - 6
		local top = -3 + rng:NextNumber(8, 26)
		local diameter = rng:NextNumber(10, 16)
		local color = pick(ROCKS, rng)
		local lower = (top - bottom) * 0.7
		MapParts.column(folder, Vector3.new(x, bottom, z), lower, diameter, color, M.Rock)
		MapParts.column(
			folder,
			Vector3.new(x, bottom + lower, z),
			top - bottom - lower,
			diameter * 0.65,
			color,
			M.Rock
		)
	end
end

-- A fringe of dune grass and bushes along the back of the beach, behind the dunes.
local function backFringe(folder: Folder, rng: Random)
	local half = Beach.HalfWidth
	for _ = 1, 40 do
		local x = rng:NextNumber(-half + 10, half - 10)
		local z = rng:NextNumber(-124, -84)
		local color = pick(MOSS, rng)
		for _ = 1, 5 do
			local h = rng:NextNumber(2, 4)
			add(folder, {
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
	for _ = 1, 24 do
		local d = rng:NextNumber(3, 6)
		MapParts.ball(
			folder,
			Vector3.new(rng:NextNumber(-half + 10, half - 10), 4 + d * 0.3, rng:NextNumber(-126, -86)),
			d,
			pick(MOSS, rng),
			M.Grass
		)
	end
end

function MapEdge.build(map: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "MapEdge"
	folder.Parent = map
	local rng = Random.new(41)
	for side = -1, 1, 2 do
		headland(folder, side, rng)
		seaStacks(folder, side, rng)
	end
	backFringe(folder, rng)
end

return MapEdge
