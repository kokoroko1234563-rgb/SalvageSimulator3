-- Buildings and people for the shore, made from parts. A house is a floor, four walls with a
-- doorway in the front (facing the sea, +Z), a flat roof, an awning over the door and a sign.
-- They stand on the dry sand behind the shoreline, with the floor raised above it.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local MapParts = require(script.Parent.MapParts)

local Buildings = {}

Buildings.FLOOR = 1.2 -- height of the floor above the sand
local WALL = 1 -- wall thickness
local DOOR_WIDTH = 6
local DOOR_HEIGHT = 8

-- A house whose floor is centred on `center` (its X and Z; Y is ignored and the floor sits on
-- the sand). `signText` goes on the awning over the door.
function Buildings.house(
	parent: Instance,
	name: string,
	center: Vector3,
	width: number,
	depth: number,
	height: number,
	signText: string
)
	local floorY = Buildings.FLOOR
	local cx, cz = center.X, center.Z
	local model = Instance.new("Folder")
	model.Name = name
	local wallsY = floorY + height / 2

	MapParts.part({
		Name = "Floor",
		Size = Vector3.new(width, floorY, depth),
		CFrame = CFrame.new(cx, floorY / 2, cz),
		Color = Palette.World.Boardwalk,
		Material = Palette.Material.WoodPlanks,
	}).Parent =
		model

	local function wall(wallName: string, size: Vector3, position: Vector3)
		MapParts.part({
			Name = wallName,
			Size = size,
			CFrame = CFrame.new(position),
			Color = Palette.World.Stucco,
			Material = Palette.Material.Smooth,
		}).Parent =
			model
	end

	-- Back and sides run the full depth; the front has a doorway in the middle.
	wall("BackWall", Vector3.new(width, height, WALL), Vector3.new(cx, wallsY, cz - depth / 2 + WALL / 2))
	for side = -1, 1, 2 do
		wall(
			"SideWall",
			Vector3.new(WALL, height, depth),
			Vector3.new(cx + side * (width / 2 - WALL / 2), wallsY, cz)
		)
	end

	local frontZ = cz + depth / 2 - WALL / 2
	local sideWidth = (width - DOOR_WIDTH) / 2
	for side = -1, 1, 2 do
		wall(
			"FrontWall",
			Vector3.new(sideWidth, height, WALL),
			Vector3.new(cx + side * (DOOR_WIDTH / 2 + sideWidth / 2), wallsY, frontZ)
		)
	end
	-- Above the doorway.
	wall(
		"Lintel",
		Vector3.new(DOOR_WIDTH, height - DOOR_HEIGHT, WALL),
		Vector3.new(cx, floorY + DOOR_HEIGHT + (height - DOOR_HEIGHT) / 2, frontZ)
	)

	-- Windows on both sides, glass a little proud of the wall.
	for side = -1, 1, 2 do
		MapParts.part({
			Name = "Window",
			Size = Vector3.new(0.3, height * 0.35, depth * 0.35),
			CFrame = CFrame.new(cx + side * (width / 2 + 0.05), floorY + height * 0.55, cz),
			Color = Palette.World.Window,
			Material = Palette.Material.Glass,
			Transparency = 0.3,
			CanCollide = false,
		}).Parent =
			model
	end

	-- Flat roof with a small overhang.
	MapParts.part({
		Name = "Roof",
		Size = Vector3.new(width + 2, 1, depth + 2),
		CFrame = CFrame.new(cx, floorY + height + 0.5, cz),
		Color = Palette.World.RoofTile,
		Material = Palette.Material.Rock,
	}).Parent =
		model

	-- Awning over the door, with the sign on it.
	local awning = MapParts.part({
		Name = "Awning",
		Size = Vector3.new(DOOR_WIDTH + 4, 0.5, 4),
		CFrame = CFrame.new(cx, floorY + DOOR_HEIGHT + 0.5, frontZ + 2),
		Color = Palette.World.Awning,
		Material = Palette.Material.Fabric,
	})
	awning.Parent = model
	MapParts.label(awning, signText, Vector3.new(0, 3.5, 0), Vector2.new(260, 60))

	model.Parent = parent
end

-- A flat-topped counter, `length` wide along X, facing the door.
function Buildings.counter(parent: Instance, position: Vector3, length: number)
	MapParts.part({
		Name = "Counter",
		Size = Vector3.new(length, 3, 2),
		CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)),
		Color = Palette.World.Counter,
		Material = Palette.Material.WoodPlanks,
	}).Parent =
		parent
end

-- A person built from blocks. `base` is the CFrame at their feet (facing is the way their
-- front points). The torso is returned: it's the part you talk to, so it takes the prompt
-- and the sign.
function Buildings.person(
	parent: Instance,
	name: string,
	base: CFrame,
	shirt: Color3,
	signText: string
): BasePart
	local function limb(limbName: string, size: Vector3, offset: Vector3, color: Color3): BasePart
		return MapParts.part({
			Name = limbName,
			Size = size,
			CFrame = base * CFrame.new(offset),
			Color = color,
			Material = Palette.Material.Fabric,
		})
	end

	limb("Legs", Vector3.new(2, 2, 1), Vector3.new(0, 1, 0), Palette.World.Pants).Parent = parent
	for side = -1, 1, 2 do
		limb("Arm", Vector3.new(0.7, 2.2, 0.8), Vector3.new(side * 1.85, 3.1, 0), shirt).Parent = parent
	end
	limb("Head", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 4.8, 0), Palette.World.Skin).Parent = parent

	local torso = limb(name, Vector3.new(2.6, 2.4, 1.3), Vector3.new(0, 3.2, 0), shirt)
	torso.Parent = parent
	MapParts.label(torso, signText, Vector3.new(0, 3.6, 0))
	return torso
end

return Buildings
