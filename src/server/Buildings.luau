-- Buildings and people for the shore. A house is a floor, four walls with a doorway in the front
-- (facing the sea, +Z), a gabled roof, a striped awning over the door, shuttered windows with
-- flower boxes, white trim and a sign on the front. People are real Roblox avatars (the default
-- R15 rig, from the engine itself), recoloured in code.
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

	-- A window: glass a little proud of the wall, in a white frame. `out` is the way the wall
	-- faces (a unit vector along X or Z); `along` is its width along the wall.
	local function window(center: Vector3, out: Vector3, along: number, tall: number, shutters: boolean)
		local flat = if out.X ~= 0 then Vector3.new(0.3, tall, along) else Vector3.new(along, tall, 0.3)
		local frame = if out.X ~= 0
			then Vector3.new(0.4, tall + 1, along + 1)
			else Vector3.new(along + 1, tall + 1, 0.4)
		MapParts.scenery(model, {
			Name = "WindowFrame",
			Size = frame,
			CFrame = CFrame.new(center + out * 0.1),
			Color = Palette.World.Trim,
			Material = Palette.Material.Wood,
		})
		MapParts.scenery(model, {
			Name = "Window",
			Size = flat,
			CFrame = CFrame.new(center + out * 0.3),
			Color = Palette.World.Window,
			Material = Palette.Material.Glass,
			Transparency = 0.3,
		})
		if not shutters then
			return
		end
		-- Shutters either side and a flower box below.
		local side = if out.X ~= 0 then Vector3.new(0, 0, 1) else Vector3.new(1, 0, 0)
		local shutterW = along * 0.32
		for s = -1, 1, 2 do
			MapParts.scenery(model, {
				Name = "Shutter",
				Size = if out.X ~= 0
					then Vector3.new(0.3, tall + 1, shutterW)
					else Vector3.new(shutterW, tall + 1, 0.3),
				CFrame = CFrame.new(center + out * 0.2 + side * s * (along / 2 + 0.5 + shutterW / 2)),
				Color = Palette.World.Shutter,
				Material = Palette.Material.Wood,
			})
		end
		local boxAt = center + out * 0.9 - Vector3.new(0, tall / 2 + 1, 0)
		MapParts.scenery(model, {
			Name = "FlowerBox",
			Size = if out.X ~= 0 then Vector3.new(1.4, 1.2, along + 1) else Vector3.new(along + 1, 1.2, 1.4),
			CFrame = CFrame.new(boxAt),
			Color = Palette.World.Counter,
			Material = Palette.Material.WoodPlanks,
		})
		local blooms = { Palette.World.Bloom, Palette.World.Frond, Palette.World.BloomPale }
		local count = math.max(3, math.floor(along / 1.6))
		for i = 1, count do
			local t = (i - 0.5) / count - 0.5
			MapParts.ball(model, boxAt + side * t * along + Vector3.new(0, 0.9, 0), 1.3, blooms[i % 3 + 1])
		end
	end

	-- Windows on both sides, and either side of the door on the front.
	for side = -1, 1, 2 do
		window(
			Vector3.new(cx + side * (width / 2), floorY + height * 0.55, cz),
			Vector3.new(side, 0, 0),
			depth * 0.35,
			height * 0.35,
			false
		)
		window(
			Vector3.new(cx + side * (doorW / 2 + sideWidth / 2), floorY + height * 0.45, frontZ + WALL / 2),
			Vector3.new(0, 0, 1),
			sideWidth * 0.45,
			height * 0.3,
			true
		)
	end

	-- White boards up the corners and round the doorway.
	for sx = -1, 1, 2 do
		for sz = -1, 1, 2 do
			MapParts.scenery(model, {
				Name = "Corner",
				Size = Vector3.new(1.6, height, 1.6),
				CFrame = CFrame.new(cx + sx * (width / 2 - 0.5), wallsY, cz + sz * (depth / 2 - 0.5)),
				Color = Palette.World.Trim,
				Material = Palette.Material.Wood,
			})
		end
		MapParts.scenery(model, {
			Name = "DoorFrame",
			Size = Vector3.new(1, doorH, 1.4),
			CFrame = CFrame.new(cx + sx * (doorW / 2 + 0.5), floorY + doorH / 2, frontZ),
			Color = Palette.World.Trim,
			Material = Palette.Material.Wood,
		})
	end

	-- A gabled roof: two slopes meeting in a ridge along the front, with an overhang all round.
	local top = floorY + height
	local rise = depth * 0.3
	local half = depth / 2 + 1.5
	for s = -1, 1, 2 do
		local slope = Instance.new("WedgePart")
		slope.Name = "Roof"
		slope.Anchored = true
		slope.Size = Vector3.new(width + 3, rise, half)
		-- A wedge is tall at its +Z end: the back slope as it is, the front one turned round.
		slope.CFrame = CFrame.new(cx, top + rise / 2, cz + s * half / 2)
			* CFrame.Angles(0, if s > 0 then math.pi else 0, 0)
		slope.Color = Palette.World.RoofTile
		slope.Material = Palette.Material.Rock
		slope.TopSurface = Enum.SurfaceType.Smooth
		slope.BottomSurface = Enum.SurfaceType.Smooth
		slope.Parent = model
	end
	MapParts.scenery(model, {
		Name = "Ridge",
		Size = Vector3.new(width + 3.4, 0.8, 0.8),
		CFrame = CFrame.new(cx, top + rise + 0.1, cz),
		Color = Palette.World.DarkWood,
		Material = Palette.Material.Wood,
	})
	-- The eaves: a board along the top of each wall, under the overhang.
	for s = -1, 1, 2 do
		MapParts.scenery(model, {
			Name = "Eave",
			Size = Vector3.new(width + 3, 0.8, 0.6),
			CFrame = CFrame.new(cx, top - 0.2, cz + s * (half - 0.3)),
			Color = Palette.World.Trim,
			Material = Palette.Material.Wood,
		})
	end

	-- A striped awning over the door, sloping down toward the sea.
	local stripes = 5
	local awningW = doorW + 5
	for i = 1, stripes do
		MapParts.scenery(model, {
			Name = "Awning",
			Size = Vector3.new(awningW / stripes, 0.4, 4.6),
			CFrame = CFrame.new(
				cx + ((i - 0.5) / stripes - 0.5) * awningW,
				floorY + doorH + 0.9,
				frontZ + 2.2
			) * CFrame.Angles(math.rad(22), 0, 0),
			Color = if i % 2 == 1 then Palette.World.Awning else Palette.World.AwningCream,
			Material = Palette.Material.Fabric,
		})
	end

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
