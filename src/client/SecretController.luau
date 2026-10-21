-- Builds the secret course (or room) locally when the server starts a run (only this player
-- sees their copy), raises the flood in a course, and lets the player claim the chest. A room
-- (Course.Kind = "Room") is a small themed chamber with a ceiling and props instead of
-- platforms and a flood. The server checks everything; this side is only what the player sees
-- and touches.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
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
	part.Material = Palette.Material.Sand
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

	local isRoom = Secrets.isRoom(secret)
	if isRoom then
		-- A ceiling, and the props in the secret's colours.
		block(
			root,
			"Ceiling",
			CFrame.new(origin + Vector3.new(0, height + 1, 0)),
			Vector3.new(half * 2 + 4, 2, half * 2 + 4),
			dark
		)
		local colors = {
			Accent = secret.Color,
			Wall = secret.Color:Lerp(Color3.new(0, 0, 0), 0.2),
			Light = secret.Color:Lerp(Color3.new(1, 1, 1), 0.55),
		}
		for index, item in course.Props or {} do
			block(
				root,
				"Prop" .. index,
				CFrame.new(origin + item.Position),
				item.Size,
				colors[item.Color] or secret.Color,
				{
					Material = if item.Material
						then Palette.Material[item.Material]
						else Palette.Material.Sand,
					Shape = if item.Shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Block,
				}
			)
			if item.Glow then
				local light = Instance.new("PointLight")
				light.Color = colors.Light
				light.Range = 14
				light.Parent = root:FindFirstChild("Prop" .. index)
			end
		end
		local lamp = Instance.new("PointLight")
		lamp.Brightness = 1.5
		lamp.Range = 40
		lamp.Color = colors.Light
		lamp.Parent = root:FindFirstChild("Floor")
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
			Palette.UI.Checkpoint,
			{ Material = Palette.Material.Neon, CanCollide = false, CanQuery = false }
		)
	end

	-- Normal secrets glow in their coin's colour; exotic ones (a lootbox) in the exotic colour.
	local accent = if secret.Coin then Secrets.CoinColors[secret.Coin] else Palette.Rarity.Exotic
	local chest = block(
		root,
		"Chest",
		CFrame.new(origin + course.Chest),
		Vector3.new(3, 2, 2),
		Palette.World.ChestWood,
		{ Material = Palette.Material.Wood }
	)
	block(
		root,
		"ChestLid",
		CFrame.new(origin + course.Chest + Vector3.new(0, 1.2, 0)),
		Vector3.new(3.1, 0.4, 2.1),
		accent,
		{ Material = Palette.Material.Neon }
	)
	local glow = Instance.new("PointLight")
	glow.Color = accent
	glow.Range = 16
	glow.Parent = chest
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = if secret.Coin then "Open chest" else "Open lootbox"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = chest
	prompt.Triggered:Connect(function()
		Remotes.get("ClaimChest"):FireServer()
	end)

	if isRoom then
		root.Parent = Workspace
		folder = root
		return
	end
	water = block(
		root,
		"Flood",
		CFrame.new(origin + Vector3.new(0, course.FloodFrom - 100, 0)),
		Vector3.new(half * 2, 200, half * 2),
		Palette.World.Flood,
		{
			Material = Palette.Material.Glass,
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

-- For tools/tests.
SecretController._build = build

function SecretController.init()
	local readyRemote = Remotes.get("SecretReady")

	Remotes.get("SecretEvent").OnClientEvent:Connect(function(kind: string, info: any)
		if kind == "start" then
			local secret = Secrets.List[info.Secret]
			if not secret then
				return
			end
			local built, err = pcall(build, secret, info.Origin)
			if not built then
				-- Tell the server straight away so it cancels the run and returns the unlock item.
				warn("[SecretController] couldn't build " .. tostring(info.Secret) .. ": " .. tostring(err))
				cleanup()
				readyRemote:FireServer(false)
				return
			end
			run = { course = secret.Course, origin = info.Origin, duration = info.Duration, startedAt = nil }
			-- This client owns the character's physics, so it moves the character in itself.
			local character = Players.LocalPlayer.Character
			if character then
				character:PivotTo(CFrame.new(info.Origin + secret.Course.Spawn))
				local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end
			readyRemote:FireServer(true)
		elseif kind == "go" and run then
			run.startedAt = info.StartedAt
			HUD.banner(
				if run.course.Kind == "Room" then "Find the chest!" else "The vault is flooding. Climb!"
			)
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
