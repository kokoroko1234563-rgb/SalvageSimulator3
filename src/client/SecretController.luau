-- Builds the secret course locally when the server starts a run (only this player sees
-- their copy), raises the flood, and lets the player claim the chest at the top. The
-- server checks everything; this side is only what the player sees and touches.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Remotes = require(Shared.Remotes)
local Secrets = require(Shared.Secrets)
local Tide = require(Shared.Tide)

local HUD = require(script.Parent.HUD)

local SecretController = {}

local folder: Folder? = nil
local water: Part? = nil
local run: { course: any, origin: Vector3, duration: number, startedAt: number? }? = nil

local function block(
	parent: Instance,
	name: string,
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	props: { [string]: any }?
)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CFrame = cframe
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Sand
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for key, value in props do
			(part :: any)[key] = value
		end
	end
	part.Parent = parent
	return part
end

local function cleanup()
	if folder then
		folder:Destroy()
	end
	folder, water, run = nil, nil, nil
end

local function build(secret, origin: Vector3)
	cleanup()
	local course = secret.Course
	local root = Instance.new("Folder")
	root.Name = "LocalSecret"

	local dark = secret.Color:Lerp(Color3.new(0, 0, 0), 0.35)
	block(root, "Floor", CFrame.new(origin + course.Floor.Position), course.Floor.Size, dark)
	local half = course.HalfSize
	local height = course.WallHeight
	for _, wall in
		{
			{ Vector3.new(half + 1, height / 2, 0), Vector3.new(2, height, half * 2 + 4) },
			{ Vector3.new(-half - 1, height / 2, 0), Vector3.new(2, height, half * 2 + 4) },
			{ Vector3.new(0, height / 2, half + 1), Vector3.new(half * 2 + 4, height, 2) },
			{ Vector3.new(0, height / 2, -half - 1), Vector3.new(half * 2 + 4, height, 2) },
		}
	do
		block(root, "Wall", CFrame.new(origin + wall[1]), wall[2], dark, { Transparency = 0.15 })
	end

	for index, platform in course.Platforms do
		block(root, "Platform" .. index, CFrame.new(origin + platform.Position), platform.Size, secret.Color)
	end
	for index, checkpoint in course.Checkpoints do
		block(
			root,
			"Checkpoint" .. index,
			CFrame.new(origin + checkpoint + Vector3.new(0, 2.5, 0)),
			Vector3.new(0.4, 4, 0.4),
			Color3.fromRGB(120, 230, 255),
			{ Material = Enum.Material.Neon, CanCollide = false, CanQuery = false }
		)
	end

	local chest = block(
		root,
		"Chest",
		CFrame.new(origin + course.Chest),
		Vector3.new(3, 2, 2),
		Color3.fromRGB(120, 75, 35),
		{ Material = Enum.Material.Wood }
	)
	block(
		root,
		"ChestLid",
		CFrame.new(origin + course.Chest + Vector3.new(0, 1.2, 0)),
		Vector3.new(3.1, 0.4, 2.1),
		Secrets.CoinColors[secret.Coin],
		{ Material = Enum.Material.Neon }
	)
	local glow = Instance.new("PointLight")
	glow.Color = Secrets.CoinColors[secret.Coin]
	glow.Range = 16
	glow.Parent = chest
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open chest"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = chest
	prompt.Triggered:Connect(function()
		Remotes.get("ClaimChest"):FireServer()
	end)

	water = block(
		root,
		"Flood",
		CFrame.new(origin + Vector3.new(0, course.FloodFrom - 100, 0)),
		Vector3.new(half * 2, 200, half * 2),
		Color3.fromRGB(40, 120, 170),
		{
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
		}
	)

	root.Parent = Workspace
	folder = root
end

function SecretController.init()
	local readyRemote = Remotes.get("SecretReady")

	Remotes.get("SecretEvent").OnClientEvent:Connect(function(kind: string, info: any)
		if kind == "start" then
			local secret = Secrets.List[info.Secret]
			if not secret then
				return
			end
			build(secret, info.Origin)
			run = { course = secret.Course, origin = info.Origin, duration = info.Duration, startedAt = nil }
			readyRemote:FireServer()
		elseif kind == "go" and run then
			run.startedAt = info.StartedAt
			HUD.banner("The vault is flooding. Climb!")
		elseif kind == "end" then
			cleanup()
		end
	end)

	RunService.RenderStepped:Connect(function()
		local current = run
		if not current or not water then
			return
		end
		local elapsed = if current.startedAt then Tide.now() - current.startedAt else 0
		local level = Secrets.floodLevel(current.course, elapsed, current.duration)
		water.CFrame = CFrame.new(current.origin + Vector3.new(0, level - 100, 0))
	end)
end

return SecretController
