-- Things that make it a beach rather than a slope: palms, umbrellas, driftwood, shells and a
-- lifeguard tower. All of it is scenery: it doesn't collide or get queried, so it never gets
-- in the way of towing, grabbing or the waves. The layout comes from a seeded Random, so every
-- server builds the same beach.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Beach = require(Shared.Beach)

local MapParts = require(script.Parent.MapParts)

local BeachDressing = {}

local function scenery(props: { [string]: any }): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	return MapParts.part(props)
end

-- A tall trunk with a crown of drooping fronds.
local function palm(parent: Instance, base: Vector3, height: number, rng: Random)
	local trunkTop = base + Vector3.new(0, height, 0)
	scenery({
		Name = "PalmTrunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.4, 1.4),
		CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Palette.World.Palm,
		Material = Palette.Material.Wood,
	}).Parent =
		parent
	for i = 1, 7 do
		local yaw = (i / 7) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		scenery({
			Name = "Frond",
			Size = Vector3.new(1.4, 0.3, 8),
			CFrame = CFrame.new(trunkTop)
				* CFrame.Angles(0, yaw, 0)
				* CFrame.Angles(math.rad(-28), 0, 0)
				* CFrame.new(0, 0, -4),
			Color = Palette.World.Frond,
			Material = Palette.Material.Foil,
		}).Parent =
			parent
	end
end

-- A striped-looking beach umbrella: a pole and a flat canopy.
local function umbrella(parent: Instance, base: Vector3, color: Color3)
	scenery({
		Name = "UmbrellaPole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 0.3, 0.3),
		CFrame = CFrame.new(base + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Palette.World.Post,
		Material = Palette.Material.Metal,
	}).Parent =
		parent
	scenery({
		Name = "UmbrellaCanopy",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 9, 9),
		CFrame = CFrame.new(base + Vector3.new(0, 5.8, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Material = Palette.Material.Fabric,
	}).Parent =
		parent
end

-- A driftwood log lying on the sand.
local function driftwood(parent: Instance, position: Vector3, rng: Random)
	local length = rng:NextNumber(4, 9)
	scenery({
		Name = "Driftwood",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(length, 0.9, 0.9),
		CFrame = CFrame.new(position) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0),
		Color = Palette.World.Driftwood,
		Material = Palette.Material.Wood,
	}).Parent =
		parent
end

-- A flat shell: a thin disc lying on the sand.
local SHELLS = { Palette.World.ShellPink, Palette.World.ShellCream, Palette.World.ShellTan }
local function shell(parent: Instance, position: Vector3, rng: Random)
	scenery({
		Name = "Shell",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, rng:NextNumber(0.5, 0.9), rng:NextNumber(0.5, 0.9)),
		CFrame = CFrame.new(position)
			* CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
			* CFrame.Angles(0, 0, math.pi / 2),
		Color = SHELLS[rng:NextInteger(1, #SHELLS)],
		Material = Palette.Material.Smooth,
	}).Parent =
		parent
end

-- A lifeguard chair on four legs, with a cabin and a roof.
local function lifeguardTower(parent: Instance, base: Vector3)
	local legHeight = 10
	for side = -1, 1, 2 do
		for end_ = -1, 1, 2 do
			scenery({
				Name = "TowerLeg",
				Size = Vector3.new(0.8, legHeight, 0.8),
				CFrame = CFrame.new(base + Vector3.new(side * 2.5, legHeight / 2, end_ * 2.5)),
				Color = Palette.World.Post,
				Material = Palette.Material.Wood,
			}).Parent =
				parent
		end
	end
	local deck = scenery({
		Name = "TowerDeck",
		Size = Vector3.new(6, 0.6, 6),
		CFrame = CFrame.new(base + Vector3.new(0, legHeight, 0)),
		Color = Palette.World.Boardwalk,
		Material = Palette.Material.WoodPlanks,
	})
	deck.Parent = parent
	scenery({
		Name = "TowerCabin",
		Size = Vector3.new(4.5, 3.5, 4.5),
		CFrame = CFrame.new(base + Vector3.new(0, legHeight + 2.3, 0)),
		Color = Palette.World.Lifeguard,
		Material = Palette.Material.Smooth,
	}).Parent =
		parent
	local roof = scenery({
		Name = "TowerRoof",
		Size = Vector3.new(6, 0.5, 6),
		CFrame = CFrame.new(base + Vector3.new(0, legHeight + 4.3, 0)),
		Color = Palette.World.Post,
		Material = Palette.Material.Smooth,
	})
	roof.Parent = parent
	MapParts.sign(parent, "LIFEGUARD", CFrame.new(base + Vector3.new(0, legHeight + 2.3, 2.5)), 4, 1.2)
end

-- Scatters the dressing over the dry sand, the dunes and the top of the beach.
function BeachDressing.build(map: Instance, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "Dressing"
	folder.Parent = map

	local half = Beach.HalfWidth
	local function groundAt(x: number, z: number): Vector3
		return Vector3.new(x, Beach.groundAt(x, z), z)
	end

	-- Palms beyond the shop buildings, on the dry sand at the sides of the cove.
	for _ = 1, 12 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local x = side * rng:NextNumber(250, half - 25)
		local z = rng:NextNumber(-70, -12)
		palm(folder, groundAt(x, z), rng:NextNumber(14, 20), rng)
	end

	-- Umbrellas on the top of the beach, scattered along it.
	local umbrellaColors =
		{ Palette.World.UmbrellaRed, Palette.World.UmbrellaTeal, Palette.World.UmbrellaYellow }
	for i = 1, 9 do
		local x = rng:NextNumber(-half + 60, half - 60)
		local z = rng:NextNumber(12, 45)
		umbrella(folder, groundAt(x, z), umbrellaColors[(i % #umbrellaColors) + 1])
	end

	-- Driftwood along the high-tide line.
	for _ = 1, 40 do
		local x = rng:NextNumber(-half + 20, half - 20)
		local z = rng:NextNumber(4, 40)
		driftwood(folder, groundAt(x, z) + Vector3.new(0, 0.45, 0), rng)
	end

	-- Shells and pebbles scattered over the sand, dry and wet.
	for _ = 1, 260 do
		local x = rng:NextNumber(-half + 5, half - 5)
		local z = rng:NextNumber(-70, 50)
		shell(folder, groundAt(x, z) + Vector3.new(0, 0.08, 0), rng)
	end

	lifeguardTower(folder, groundAt(-265, -22))
end

-- The zone props reuse these.
BeachDressing.scenery = scenery
BeachDressing.palm = palm
BeachDressing.umbrella = umbrella
BeachDressing.driftwood = driftwood
BeachDressing.shell = shell
BeachDressing.lifeguardTower = lifeguardTower

return BeachDressing
