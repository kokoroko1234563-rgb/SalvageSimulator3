-- Admin flight (`fly` in the admin console): noclip flight for getting round the map. While the
-- player's AdminFly attribute is on, the character floats free of gravity and collisions and
-- goes where the camera looks: the usual move keys (or stick) steer, Space/E rises,
-- Ctrl/Q sinks, Shift goes faster. The character is moved by its CFrame each frame, so waves,
-- knockdowns and walls don't touch it; the server sees it move as it sees any character.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local FlyController = {}

local SPEED = 60 -- studs per second
local FAST = 3 -- times as fast with Shift held
local RENDER_NAME = "AdminFly"

local controls = nil -- the default PlayerModule's controls, for the move keys or stick
local flying = false
local collisions: { [BasePart]: boolean } = {} -- each part's CanCollide before flying
local stepped: RBXScriptConnection? = nil

local function moveVector(): Vector3
	if not controls then
		local ok, module = pcall(function()
			return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: any)
		end)
		controls = ok and module:GetControls() or false
	end
	return if controls then controls:GetMoveVector() else Vector3.zero
end

local function held(...: Enum.KeyCode): boolean
	for _, key in { ... } do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return false
end

local function parts(): { BasePart }
	local list = {}
	local character = player.Character
	if character then
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(list, part)
			end
		end
	end
	return list
end

local function stop()
	if not flying then
		return
	end
	flying = false
	RunService:UnbindFromRenderStep(RENDER_NAME)
	if stepped then
		stepped:Disconnect()
		stepped = nil
	end
	for part, collide in collisions do
		if part.Parent then
			part.CanCollide = collide
		end
	end
	table.clear(collisions)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function start()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if flying or not humanoid or not root then
		return
	end
	flying = true
	for _, part in parts() do
		collisions[part] = part.CanCollide
	end
	-- The Humanoid turns some parts' collisions back on each step, so noclip runs every step.
	stepped = RunService.Stepped:Connect(function()
		for _, part in parts() do
			if collisions[part] == nil then
				collisions[part] = part.CanCollide
			end
			part.CanCollide = false
		end
	end)
	local position = root.Position
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Character.Value, function(dt)
		if not root.Parent then
			stop()
			return
		end
		humanoid.PlatformStand = true -- (a wave's or hazard's knockdown may have let go of it)
		local camera = Workspace.CurrentCamera
		local look = camera.CFrame
		local move = moveVector()
		local direction = look.RightVector * move.X - look.LookVector * move.Z
		if held(Enum.KeyCode.Space, Enum.KeyCode.E) then
			direction += Vector3.yAxis
		end
		if held(Enum.KeyCode.LeftControl, Enum.KeyCode.Q) then
			direction -= Vector3.yAxis
		end
		if direction.Magnitude > 1 then
			direction = direction.Unit
		end
		local speed = SPEED * (if held(Enum.KeyCode.LeftShift) then FAST else 1)
		position += direction * speed * dt
		-- Face where the camera faces, level.
		local flat = Vector3.new(look.LookVector.X, 0, look.LookVector.Z)
		local facing = if flat.Magnitude > 0.01 then flat.Unit else root.CFrame.LookVector
		root.CFrame = CFrame.lookAt(position, position + facing)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function update()
	if player:GetAttribute("AdminFly") then
		start()
	else
		stop()
	end
end

function FlyController.init()
	player:GetAttributeChangedSignal("AdminFly"):Connect(update)
	player.CharacterAdded:Connect(function(character)
		stop()
		character:WaitForChild("HumanoidRootPart")
		character:WaitForChild("Humanoid")
		update()
	end)
	update()
end

return FlyController
