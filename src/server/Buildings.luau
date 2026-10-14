-- Buildings and people for the shore. A house is a floor, four walls with a doorway in the front
-- (facing the sea, +Z), a flat roof, an awning over the door and a sign on the front. People are
-- real Roblox avatars (the default R15 rig, from the engine itself), recoloured in code.
-- Everything stands on the dry sand behind the shoreline, with the floor raised above it.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local MapParts = require(script.Parent.MapParts)

local Buildings = {}

Buildings.FLOOR = 1.2 -- height of the floor above the sand
Buildings.WALL_HEIGHT = 18
Buildings.DOOR_WIDTH = 8
Buildings.DOOR_HEIGHT = 9
local WALL = 1 -- wall thickness
local BOARD_OFFSET = 0.3 -- how far a sign stands proud of the wall it hangs on

-- A house whose floor is centred on `center` (its X and Z; Y is ignored and the floor sits on
-- the sand). `signText` goes on the front, above the door.
function Buildings.house(
	parent: Instance,
	name: string,
	center: Vector3,
	width: number,
	depth: number,
	signText: string
)
	local floorY = Buildings.FLOOR
	local height = Buildings.WALL_HEIGHT
	local doorW = Buildings.DOOR_WIDTH
	local doorH = Buildings.DOOR_HEIGHT
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
		local x = cx + side * (width / 2 - WALL / 2)
		wall("SideWall", Vector3.new(WALL, height, depth), Vector3.new(x, wallsY, cz))
	end

	local frontZ = cz + depth / 2 - WALL / 2
	local sideWidth = (width - doorW) / 2
	for side = -1, 1, 2 do
		wall(
			"FrontWall",
			Vector3.new(sideWidth, height, WALL),
			Vector3.new(cx + side * (doorW / 2 + sideWidth / 2), wallsY, frontZ)
		)
	end
	-- Above the doorway.
	wall(
		"Lintel",
		Vector3.new(doorW, height - doorH, WALL),
		Vector3.new(cx, floorY + doorH + (height - doorH) / 2, frontZ)
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

	-- Awning over the door.
	MapParts.part({
		Name = "Awning",
		Size = Vector3.new(doorW + 5, 0.5, 4),
		CFrame = CFrame.new(cx, floorY + doorH + 0.5, frontZ + 2),
		Color = Palette.World.Awning,
		Material = Palette.Material.Fabric,
	}).Parent =
		model

	-- The sign goes on the front wall, above the awning.
	MapParts.sign(
		model,
		signText,
		CFrame.new(cx, floorY + height - 2.5, frontZ + WALL / 2 + BOARD_OFFSET),
		width * 0.7,
		3.5
	)

	model.Parent = parent
end

-- A counter, `length` wide along X, with a sign on its front (the side facing the door).
function Buildings.counter(parent: Instance, position: Vector3, length: number, signText: string?)
	MapParts.part({
		Name = "Counter",
		Size = Vector3.new(length, 3, 2),
		CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)),
		Color = Palette.World.Counter,
		Material = Palette.Material.WoodPlanks,
	}).Parent =
		parent
	if signText then
		MapParts.sign(
			parent,
			signText,
			CFrame.new(position + Vector3.new(0, 4.2, 1 + 0.3)),
			length * 0.6,
			1.6
		)
	end
end

-- A real Roblox character: the engine's default R15 avatar, recoloured. It's anchored in place
-- and has no name tag, so the sign next to it says who it is. Its HumanoidRootPart is the
-- part you talk to, so the prompt goes there. Returns the model.
function Buildings.person(parent: Instance, name: string, cf: CFrame, shirt: Color3): Model
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = Palette.World.Skin
	description.TorsoColor = shirt
	description.LeftArmColor = shirt
	description.RightArmColor = shirt
	description.LeftLegColor = Palette.World.Pants
	description.RightLegColor = Palette.World.Pants

	-- Yields while the avatar loads, so people are built from the server's start-up thread.
	local model = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	model.Name = name
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanTouch = false
		elseif part:IsA("Humanoid") then
			part.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

return Buildings
