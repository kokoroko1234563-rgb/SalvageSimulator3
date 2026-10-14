-- The Far Sandbar's landmark: the top of a sunken bell tower sticking out of the sand. Its
-- door is the entrance to the Sunken Bell Tower secret (Beacon Pearl). The sandbar is only
-- uncovered around low tide, so the door can only be used for a short window each cycle;
-- SecretService turns players away while it's underwater.

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Palette = require(Shared.Palette)
local Secrets = require(Shared.Secrets)

local FarSandbarService = {}

local SECRET = "FarSandbar"

local function makePart(parent: Instance, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Palette.Material.Rock
	part.Color = Palette.World.Rock
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = parent
	return part
end

-- Builds the tower and returns its door.
function FarSandbarService.build(parent: Instance): BasePart
	local secret = Secrets.List[SECRET]
	local z = Config.Beach.FarSandbar.DoorZ
	local ground = Beach.groundY(z)
	local model = Instance.new("Model")
	model.Name = "BellTower"

	local size = 16
	local height = 46
	local center = Vector3.new(0, ground + height / 2 - 4, z + size / 2)
	local walls = {
		{ Vector3.new(size, height, 1.5), Vector3.new(0, 0, size / 2) },
		{ Vector3.new(1.5, height, size), Vector3.new(-size / 2, 0, 0) },
		{ Vector3.new(1.5, height, size), Vector3.new(size / 2, 0, 0) },
		-- The front wall, either side of and above the doorway.
		{ Vector3.new(5.5, height, 1.5), Vector3.new(-5.25, 0, -size / 2) },
		{ Vector3.new(5.5, height, 1.5), Vector3.new(5.25, 0, -size / 2) },
		{ Vector3.new(5, height - 12, 1.5), Vector3.new(0, 6, -size / 2) },
	}
	for index, wall in walls do
		makePart(model, {
			Name = "Wall" .. index,
			Size = wall[1],
			CFrame = CFrame.new(center + wall[2]),
			Color = secret.Color,
		})
	end
	local top = center.Y + height / 2
	makePart(model, {
		Name = "Roof",
		Size = Vector3.new(size + 3, 1.5, size + 3),
		CFrame = CFrame.new(center.X, top + 0.75, center.Z),
		Color = Palette.World.DarkWood,
		Material = Palette.Material.Wood,
	})
	makePart(model, {
		Name = "Bell",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 6, 6),
		CFrame = CFrame.new(center.X, top - 4, center.Z),
		Color = Palette.Coin.Yellow,
		Material = Palette.Material.Metal,
		CanCollide = false,
	})

	local door = makePart(model, {
		Name = "Door",
		Size = Vector3.new(5, 7, 0.6),
		CFrame = CFrame.new(0, ground + 3.5, z),
		Color = Palette.World.Hatch,
		Material = Palette.Material.Wood,
	})
	local unlock = Items.get(secret.Unlock)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Use " .. unlock.Name
	prompt.ObjectText = "Bell tower door"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = door

	model.PrimaryPart = door
	model.Parent = parent
	return door
end

function FarSandbarService.init(map: Instance, onEntrance: (Player, string, CFrame) -> ())
	local door = FarSandbarService.build(map)
	local prompt = door:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	prompt.Triggered:Connect(function(player)
		-- Players come back out in front of the door.
		onEntrance(player, SECRET, door.CFrame * CFrame.new(0, 0, -5))
	end)
end

return FarSandbarService
