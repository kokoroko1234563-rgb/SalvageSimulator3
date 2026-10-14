-- Click-and-drag grabbing, LT2-style, plus the assist grab for every platform.
--
--   Drag:   press on an item and hold. It follows the pointer within your tool's reach.
--           Release to put it down; release over your vessel to load it. Scroll to push/pull.
--   Assist: tap an item to lift it. It floats in front of you. Tap your vessel (or press
--           "To vessel") to send it there; tap anywhere else (or press "Drop") to drop it.
--   Vessels are towed the same way by grabbing their handle.
--
-- The server gives us network ownership of what we hold, so the constraint that moves it
-- lives only on this client.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer
local grabCfg = Config.Grab

local GrabController = {}

type Held = {
	part: BasePart,
	kind: "item" | "vessel",
	mode: "drag" | "lifted",
	holdDistance: number,
	attachment: Attachment,
	align: AlignPosition,
	startedAt: number,
	farFor: number,
}

type Press = {
	input: InputObject,
	startedAt: number,
	startPosition: Vector2,
	ended: boolean,
	endedAt: number?,
	moved: number,
}

local held: Held? = nil
local press: Press? = nil
local pointer = Vector2.zero -- screen position (no GUI inset) of the active pointer

local grabRemote
local releaseRemote
local sendRemote

local CLASS_NAMES = { "Light", "Medium", "Heavy", "Very heavy" }

local function getRoot(): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function currentTool()
	return Gear.getTool(player:GetAttribute("Tool"))
end

local function raycastFrom(screenPosition: Vector2): RaycastResult?
	local camera = Workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if player.Character then
		table.insert(exclude, player.Character)
	end
	if held then
		table.insert(exclude, held.part)
	end
	params.FilterDescendantsInstances = exclude
	return Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
end

local function ownVesselFrom(part: Instance?): Model?
	local current = part
	while current and current ~= Workspace do
		if current:IsA("Model") and CollectionService:HasTag(current, "Vessel") then
			if current:GetAttribute("Owner") == player.UserId then
				return current
			end
			return nil
		end
		current = current.Parent
	end
	return nil
end

local function myVessel(): Model?
	for _, vessel in CollectionService:GetTagged("Vessel") do
		if vessel:GetAttribute("Owner") == player.UserId then
			return vessel
		end
	end
	return nil
end

local function grabbableFrom(part: Instance?): (BasePart?, ("item" | "vessel")?)
	if not part or not part:IsA("BasePart") then
		return nil, nil
	end
	if CollectionService:HasTag(part, "SalvageItem") then
		return part, "item"
	end
	if CollectionService:HasTag(part, "VesselHandle") and ownVesselFrom(part) then
		return part, "vessel"
	end
	return nil, nil
end

local function vesselMass(vessel: Model): number
	local mass = 0
	for _, descendant in vessel:GetDescendants() do
		if descendant:IsA("BasePart") then
			mass += descendant.Mass
		end
	end
	return mass
end

local function cleanup()
	if not held then
		return
	end
	held.align:Destroy()
	held.attachment:Destroy()
	held = nil
	HUD.setHoldButtons(false)
end

function GrabController.release()
	local current = held
	if not current then
		return
	end
	cleanup()
	if current.kind == "item" then
		releaseRemote:FireServer(current.part)
	end
end

function GrabController.sendToVessel()
	local current = held
	if not current or current.kind ~= "item" then
		return
	end
	-- Stop pulling it; the server either loads it or tells us why not (and it stays held
	-- server-side, so drop it properly in that case).
	cleanup()
	sendRemote:FireServer(current.part)
	task.delay(0.6, function()
		if
			current.part.Parent
			and current.part:GetAttribute("State") == "Held"
			and current.part:GetAttribute("Owner") == player.UserId
		then
			releaseRemote:FireServer(current.part)
		end
	end)
end

local function begin(part: BasePart, kind: "item" | "vessel", hitPosition: Vector3)
	cleanup()
	local camera = Workspace.CurrentCamera
	local attachment = Instance.new("Attachment")
	attachment.Name = "GrabAttachment"
	attachment.Parent = part

	local align = Instance.new("AlignPosition")
	align.Name = "GrabAlign"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.Responsiveness = 25
	align.MaxVelocity = 60
	if kind == "item" then
		align.ApplyAtCenterOfMass = true
		align.MaxForce = part.AssemblyMass * currentTool().Grip
	else
		local vessel = part.Parent :: Model
		align.ApplyAtCenterOfMass = false
		align.MaxForce = vesselMass(vessel) * grabCfg.TowAcceleration
	end
	align.Position = part.Position
	align.Parent = part

	held = {
		part = part,
		kind = kind,
		mode = "drag",
		holdDistance = math.max((hitPosition - camera.CFrame.Position).Magnitude, grabCfg.MinHoldDistance),
		attachment = attachment,
		align = align,
		startedAt = os.clock(),
		farFor = 0,
	}
end

local function enterLifted()
	local current = held
	if not current then
		return
	end
	current.mode = "lifted"
	HUD.setHoldButtons(true, current.kind == "item" and myVessel() ~= nil)
end

local function targetPosition(current: Held, root: BasePart): Vector3
	local reach = if current.kind == "item" then currentTool().Reach else grabCfg.VesselHandleReach
	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit

	if current.mode == "lifted" then
		if current.kind == "vessel" then
			return root.Position + flatLook * 3.5 - Vector3.new(0, 0.6, 0)
		end
		local size = current.part.Size.Magnitude / 2
		return root.Position + flatLook * (2.5 + size) + Vector3.new(0, 2.5, 0)
	end

	local camera = Workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(pointer.X, pointer.Y)
	local target = ray.Origin + ray.Direction * current.holdDistance
	local offset = target - root.Position
	if offset.Magnitude > reach then
		target = root.Position + offset.Unit * reach
	end
	-- Don't drive items into the ground.
	local floor = Beach.groundY(target.Z) + current.part.Size.Y / 2
	if target.Y < floor then
		target = Vector3.new(target.X, floor, target.Z)
	end
	return target
end

local function update(dt: number)
	local current = held
	if not current then
		return
	end
	local part = current.part
	if not part.Parent then
		cleanup()
		return
	end
	if current.kind == "item" and os.clock() - current.startedAt > 1 then
		-- Server took it from us (died, leash, sold, loaded into the vessel, ...).
		if part:GetAttribute("State") ~= "Held" or part:GetAttribute("Owner") ~= player.UserId then
			cleanup()
			return
		end
	end

	local root = getRoot()
	if not root then
		GrabController.release()
		return
	end

	local target = targetPosition(current, root)
	current.align.Position = target

	if current.kind == "item" then
		-- Damp spinning so held things don't tumble forever.
		part.AssemblyAngularVelocity *= 0.9

		-- Waves (or bumps) pulling it out of your grip knock it loose.
		local tool = currentTool()
		if
			os.clock() - current.startedAt > 0.8
			and (part.Position - target).Magnitude > tool.GripBreak + part.Size.Magnitude / 2
		then
			current.farFor += dt
			if current.farFor > grabCfg.GripBreakTime then
				GrabController.release()
				HUD.notify("Knocked loose!")
			end
		else
			current.farFor = 0
		end

		if current.mode == "lifted" then
			HUD.setHoldButtons(true, myVessel() ~= nil)
		end
	end
end

local function describe(part: BasePart): (string, Color3)
	local def = Items.get(part:GetAttribute("ItemId") or "")
	local name = if def then def.Name else part.Name
	local class = part:GetAttribute("Class") or 1
	local value = part:GetAttribute("Value") or 0
	local state = part:GetAttribute("State")
	local ownerId = part:GetAttribute("Owner") or 0
	local line =
		string.format("%s · %s coins · %s", name, HUD.formatNumber(value), CLASS_NAMES[class] or "?")

	if state ~= "Unclaimed" and ownerId ~= player.UserId then
		return line .. " (claimed)", Color3.fromRGB(180, 180, 180)
	end
	local tool = currentTool()
	if not Gear.canLift(tool, class) then
		return line .. " (too heavy)", Color3.fromRGB(255, 120, 110)
	end
	if state ~= "InVessel" and not Gear.canReachDepth(tool, Beach.depthBand(part.Position.Z)) then
		return line .. " (too deep)", Color3.fromRGB(255, 120, 110)
	end
	local rarityColor = Items.RarityColors[part:GetAttribute("Rarity") or "Common"]
	return line, rarityColor or Color3.new(1, 1, 1)
end

local function updateHover()
	if held or UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		HUD.setTooltip(nil)
		return
	end
	local mouse = UserInputService:GetMouseLocation()
	local inset = game:GetService("GuiService"):GetGuiInset()
	local screen = mouse - inset
	local hit = raycastFrom(screen)
	local part, kind = grabbableFrom(hit and hit.Instance)
	if part and kind == "item" then
		local message, color = describe(part)
		HUD.setTooltip(message, color, screen)
	elseif part and kind == "vessel" then
		HUD.setTooltip("Your vessel · drag the handle to tow", Color3.new(1, 1, 1), screen)
	else
		HUD.setTooltip(nil)
	end
end

local function isTap(p: Press): boolean
	local duration = (p.endedAt or os.clock()) - p.startedAt
	return duration <= grabCfg.TapTime and p.moved <= grabCfg.TapMovePixels
end

local function onInputBegan(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if
		input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end
	local screen = Vector2.new(input.Position.X, input.Position.Y)

	-- While something is lifted, the next tap decides where it goes.
	local current = held
	if current and current.mode == "lifted" then
		local hit = raycastFrom(screen)
		if current.kind == "item" and hit and ownVesselFrom(hit.Instance) then
			GrabController.sendToVessel()
		else
			GrabController.release()
		end
		return
	end
	if held or press then
		return
	end

	local hit = raycastFrom(screen)
	local part, kind = grabbableFrom(hit and hit.Instance)
	if not part or not kind or not hit then
		return
	end

	pointer = screen
	local thisPress: Press = {
		input = input,
		startedAt = os.clock(),
		startPosition = screen,
		ended = false,
		moved = 0,
	}
	press = thisPress

	local hitPosition = hit.Position
	task.spawn(function()
		local ok, reason = grabRemote:InvokeServer(part)
		if press == thisPress and (thisPress.ended or not ok) then
			press = nil
		end
		if not ok then
			if reason then
				HUD.notify(reason)
			end
			return
		end
		begin(part, kind, hitPosition)
		if thisPress.ended then
			-- The press finished while we waited for the server.
			if isTap(thisPress) then
				enterLifted()
			else
				GrabController.release()
			end
		end
	end)
end

local function onInputChanged(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local current = held
		if current and current.mode == "drag" then
			current.holdDistance =
				math.max(grabCfg.MinHoldDistance, current.holdDistance - input.Position.Z * 2)
		end
		return
	end
	local p = press
	if not p then
		return
	end
	local isPointerMove = input.UserInputType == Enum.UserInputType.MouseMovement
		or (input.UserInputType == Enum.UserInputType.Touch and input == p.input)
	if isPointerMove then
		pointer = Vector2.new(input.Position.X, input.Position.Y)
		p.moved = math.max(p.moved, (pointer - p.startPosition).Magnitude)
	end
end

local function onInputEnded(input: InputObject)
	local p = press
	if not p or input ~= p.input then
		return
	end
	p.ended = true
	p.endedAt = os.clock()

	local current = held
	if not current then
		-- Still waiting on the server; the grab callback finishes this press.
		return
	end
	press = nil
	if current.mode == "drag" then
		if isTap(p) then
			enterLifted()
		else
			GrabController.release()
		end
	end
end

function GrabController.init()
	grabRemote = Remotes.get("GrabRequest")
	releaseRemote = Remotes.get("Release")
	sendRemote = Remotes.get("SendToVessel")

	HUD.bindHoldButtons(GrabController.release, GrabController.sendToVessel)

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputChanged:Connect(onInputChanged)
	UserInputService.InputEnded:Connect(onInputEnded)

	RunService.RenderStepped:Connect(function(dt)
		update(dt)
		updateHover()
	end)

	player.CharacterRemoving:Connect(cleanup)
end

return GrabController
