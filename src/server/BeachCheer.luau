-- Colour for the beach: striped umbrellas with towels, pastel beach huts, bunting over the
-- boardwalk, surfboards in the sand and flower tufts. Like the rest of the beach dressing it
-- is only scenery: it doesn't collide, can't be touched or picked, and the layout comes from
-- a seeded Random, so every server builds the same beach.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Beach = require(Shared.Beach)

local MapParts = require(script.Parent.MapParts)

local BeachCheer = {}

local C = Palette.Cheer

-- The bright colours that take turns round the umbrellas, towels, boards and flags.
local BRIGHT = { C.Coral, C.Sun, C.Aqua, C.Pink, C.Lime, C.Lilac, C.Sky }
local PASTEL = { C.Mint, C.Peach, C.Butter, C.Sky, C.Pink, C.Lilac }

local function scenery(props: { [string]: any }): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	return MapParts.part(props)
end

local function groundAt(x: number, z: number): Vector3
	return Vector3.new(x, Beach.groundAt(x, z), z)
end

-- A striped umbrella: a pole and twelve canopy panels, two colours taking turns, sloping
-- down from the top.
local function umbrella(parent: Instance, base: Vector3, colorA: Color3, yaw: number)
	scenery({
		Name = "UmbrellaPole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(7, 0.28, 0.28),
		CFrame = CFrame.new(base + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = C.Pole,
		Material = Palette.Material.Metal,
	}).Parent =
		parent
	local top = CFrame.new(base + Vector3.new(0, 6.9, 0))
	for panel = 0, 11 do
		-- Alternate panels sit a hair higher, so where they overlap they don't flicker.
		local lift = if panel % 2 == 0 then 0 else 0.04
		scenery({
			Name = "UmbrellaPanel",
			Size = Vector3.new(2.2, 0.22, 4.9),
			CFrame = top
				* CFrame.Angles(0, yaw + panel * math.pi / 6, 0)
				* CFrame.Angles(math.rad(-14), 0, 0)
				* CFrame.new(0, lift, -2.4),
			Color = if panel % 2 == 0 then colorA else C.White,
			Material = Palette.Material.Fabric,
		}).Parent =
			parent
	end
	scenery({
		Name = "UmbrellaTip",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.7, 0.7, 0.7),
		CFrame = top * CFrame.new(0, 0.15, 0),
		Color = colorA,
		Material = Palette.Material.Smooth,
	}).Parent =
		parent
end

-- A towel on the sand: a coloured rectangle with two pale stripes.
local function towel(parent: Instance, position: Vector3, color: Color3, yaw: number)
	local frame = CFrame.new(position + Vector3.new(0, 0.07, 0)) * CFrame.Angles(0, yaw, 0)
	scenery({
		Name = "Towel",
		Size = Vector3.new(4.2, 0.12, 8),
		CFrame = frame,
		Color = color,
		Material = Palette.Material.Fabric,
	}).Parent =
		parent
	for _, z in { -1.8, 1.8 } do
		scenery({
			Name = "TowelStripe",
			Size = Vector3.new(4.2, 0.14, 0.7),
			CFrame = frame * CFrame.new(0, 0, z),
			Color = C.White,
			Material = Palette.Material.Fabric,
		}).Parent =
			parent
	end
end

-- A surfboard stuck upright in the sand, with a stripe down the middle.
local function surfboard(parent: Instance, base: Vector3, color: Color3, rng: Random)
	local frame = CFrame.new(base + Vector3.new(0, 3.7, 0))
		* CFrame.Angles(0, rng:NextNumber() * math.pi * 2, math.rad(rng:NextNumber(-9, 9)))
	scenery({
		Name = "Surfboard",
		Size = Vector3.new(1.7, 9, 0.3),
		CFrame = frame,
		Color = color,
		Material = Palette.Material.Smooth,
	}).Parent =
		parent
	scenery({
		Name = "SurfboardStripe",
		Size = Vector3.new(0.45, 9.02, 0.34),
		CFrame = frame,
		Color = C.White,
		Material = Palette.Material.Smooth,
	}).Parent =
		parent
	scenery({
		Name = "SurfboardNose",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 1.7, 1.7),
		CFrame = frame * CFrame.new(0, 4.5, 0) * CFrame.Angles(0, math.pi / 2, math.pi / 2),
		Color = color,
		Material = Palette.Material.Smooth,
	}).Parent =
		parent
end

-- A beach hut: pastel walls with white stripes on the front, a door, a window and a gabled
-- roof. It faces the sea (+Z).
local function hut(parent: Instance, base: Vector3, color: Color3)
	local width, height, depth = 7, 6.5, 6.5
	local frame = CFrame.new(base + Vector3.new(0, height / 2, 0))
	scenery({
		Name = "HutWalls",
		Size = Vector3.new(width, height, depth),
		CFrame = frame,
		Color = color,
		Material = Palette.Material.Smooth,
	}).Parent =
		parent
	for _, x in { -2.4, -0.8, 0.8, 2.4 } do
		scenery({
			Name = "HutStripe",
			Size = Vector3.new(0.7, height, 0.08),
			CFrame = frame * CFrame.new(x, 0, depth / 2 + 0.03),
			Color = C.White,
			Material = Palette.Material.Smooth,
		}).Parent =
			parent
	end
	scenery({
		Name = "HutDoor",
		Size = Vector3.new(1.9, 4.2, 0.14),
		CFrame = frame * CFrame.new(0, -(height - 4.2) / 2, depth / 2 + 0.08),
		Color = C.Door,
		Material = Palette.Material.WoodPlanks,
	}).Parent =
		parent
	scenery({
		Name = "HutWindow",
		Size = Vector3.new(0.14, 1.5, 1.5),
		CFrame = frame * CFrame.new(width / 2 + 0.05, 0.8, 0),
		Color = Palette.World.Window,
		Material = Palette.Material.Glass,
	}).Parent =
		parent
	-- The gable: two slabs leaning together over the ridge, running front to back.
	for _, side in { -1, 1 } do
		scenery({
			Name = "HutRoof",
			Size = Vector3.new(4.5, 0.4, depth + 1.2),
			CFrame = frame
				* CFrame.new(side * 1.85, height / 2 + 1.2, 0)
				* CFrame.Angles(0, 0, math.rad(-30 * side)),
			Color = C.Coral,
			Material = Palette.Material.Smooth,
		}).Parent =
			parent
	end
end

-- Bunting strung between poles along the front of the boardwalk: small flags hanging from
-- a sagging line.
local function bunting(parent: Instance, z: number, poleXs: { number }, top: number)
	local ground = 1 -- the boardwalk's surface
	for _, x in poleXs do
		scenery({
			Name = "BuntingPole",
			Size = Vector3.new(0.4, top - ground, 0.4),
			CFrame = CFrame.new(x, ground + (top - ground) / 2, z),
			Color = C.Pole,
			Material = Palette.Material.Wood,
		}).Parent =
			parent
	end
	local flagIndex = 0
	for span = 1, #poleXs - 1 do
		local x1, x2 = poleXs[span], poleXs[span + 1]
		local previous = nil
		local flags = 10
		for step = 0, flags do
			local t = step / flags
			local point = Vector3.new(x1 + (x2 - x1) * t, top - 0.3 - 2.4 * 4 * t * (1 - t), z)
			if previous then
				local length = (point - previous).Magnitude
				scenery({
					Name = "BuntingLine",
					Size = Vector3.new(0.06, 0.06, length),
					CFrame = CFrame.lookAt((point + previous) / 2, point),
					Color = C.Pole,
					Material = Palette.Material.Fabric,
				}).Parent =
					parent
			end
			previous = point
			if step > 0 and step < flags then
				flagIndex += 1
				scenery({
					Name = "BuntingFlag",
					Size = Vector3.new(0.95, 1.2, 0.08),
					CFrame = CFrame.new(point + Vector3.new(0, -0.65, 0))
						* CFrame.Angles(0, 0, math.rad(if flagIndex % 2 == 0 then 6 else -6)),
					Color = BRIGHT[(flagIndex % #BRIGHT) + 1],
					Material = Palette.Material.Fabric,
				}).Parent =
					parent
			end
		end
	end
end

-- A tuft of grass with a few flowers, on the dry sand.
local function tuft(parent: Instance, base: Vector3, rng: Random)
	local blades = rng:NextInteger(4, 6)
	for _ = 1, blades do
		local height = rng:NextNumber(1.2, 2.2)
		local offset = Vector3.new(rng:NextNumber(-0.7, 0.7), 0, rng:NextNumber(-0.7, 0.7))
		scenery({
			Name = "Blade",
			Size = Vector3.new(0.16, height, 0.16),
			CFrame = CFrame.new(base + offset + Vector3.new(0, height / 2, 0))
				* CFrame.Angles(math.rad(rng:NextNumber(-14, 14)), 0, math.rad(rng:NextNumber(-14, 14))),
			Color = C.Leaf,
			Material = Palette.Material.Smooth,
		}).Parent =
			parent
	end
	for _ = 1, rng:NextInteger(1, 3) do
		local offset = Vector3.new(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8))
		local stem = rng:NextNumber(1.3, 2.1)
		scenery({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.55, 0.55, 0.55),
			CFrame = CFrame.new(base + offset + Vector3.new(0, stem, 0)),
			Color = BRIGHT[rng:NextInteger(1, #BRIGHT)],
			Material = Palette.Material.Smooth,
		}).Parent =
			parent
	end
end

-- Turns the plain round umbrellas BeachDressing put up into striped ones, in the same
-- colours and places, so the whole beach matches.
local function restyleUmbrellas(map: Instance, folder: Instance)
	local dressing = map:FindFirstChild("Dressing")
	if not dressing then
		return
	end
	local poles, canopies = {}, {}
	for _, child in dressing:GetChildren() do
		if child.Name == "UmbrellaPole" then
			table.insert(poles, child)
		elseif child.Name == "UmbrellaCanopy" then
			table.insert(canopies, child)
		end
	end
	for _, pole in poles do
		local at = pole.CFrame.Position
		local base = Vector3.new(at.X, at.Y - 3, at.Z)
		local color = nil
		-- The canopy that belongs to this pole is the one standing over it.
		for index, canopy in canopies do
			local over = canopy.CFrame.Position
			if (Vector3.new(over.X, 0, over.Z) - Vector3.new(base.X, 0, base.Z)).Magnitude < 0.5 then
				color = canopy.Color
				canopy:Destroy()
				table.remove(canopies, index)
				break
			end
		end
		if color then
			pole:Destroy()
			umbrella(folder, base, color, 0)
		end
	end
end

function BeachCheer.build(map: Instance, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "Cheer"
	folder.Parent = map

	restyleUmbrellas(map, folder)

	local half = Beach.HalfWidth

	-- Umbrellas with towels (and now and then a surfboard), gathered in a few camps along the
	-- top of the beach with open sand between them, as people would: each umbrella is a
	-- colour, with a towel or two on the sand under it.
	local camps = { { -265, 24, 3 }, { -120, 32, 2 }, { 170, 26, 3 }, { 290, 36, 2 } }
	local spots = {}
	for _, camp in camps do
		for k = 1, camp[3] do
			local offset = (k - (camp[3] + 1) / 2) * 11
			table.insert(spots, { camp[1] + offset + rng:NextNumber(-2, 2), camp[2] + rng:NextNumber(-4, 4) })
		end
	end
	for index, spot in spots do
		local x, z = spot[1], spot[2]
		local color = BRIGHT[(index % #BRIGHT) + 1]
		local centre = groundAt(x, z)
		umbrella(folder, centre, color, rng:NextNumber() * math.pi)
		towel(
			folder,
			groundAt(x - 3.2, z + 5),
			BRIGHT[((index + 2) % #BRIGHT) + 1],
			rng:NextNumber(-0.4, 0.4)
		)
		towel(
			folder,
			groundAt(x + 3.2, z + 5.5),
			BRIGHT[((index + 4) % #BRIGHT) + 1],
			rng:NextNumber(-0.4, 0.4)
		)
		if index % 2 == 0 then
			surfboard(folder, groundAt(x + 8, z - 3), BRIGHT[((index + 1) % #BRIGHT) + 1], rng)
		end
	end

	-- Beach huts along the shore, either side of the shop and the bank.
	local huts = { -300, -135, 135, 300 }
	for index, x in huts do
		hut(folder, groundAt(x, -18), PASTEL[(index % #PASTEL) + 1])
	end

	-- Bunting over the front of the boardwalk.
	bunting(folder, -8, { -60, -20, 20, 60 }, 11)

	-- Flower tufts on the dry sand, away from the boardwalk.
	for _ = 1, 36 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local x = side * rng:NextNumber(75, half - 20)
		tuft(folder, groundAt(x, rng:NextNumber(-14, -3)), rng)
	end
end

return BeachCheer
