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
local Palette = require(Shared.Palette)
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Rebirth = require(Shared.Rebirth)
local Traders = require(Shared.Traders)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)
local Tide = require(Shared.Tide)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer
local grabCfg = Config.Grab

local GrabController = {}

-- This player's trader upgrade levels.
local function upgrades(): { [string]: number }
	return Traders.parseLevels(player:GetAttribute("Upgrades"))
end

type Held = {
	part: BasePart,
	kind: "item" | "vessel",
	mode: "drag" | "lifted",
	holdDistance: number,
	attachment: Attachment,
	align: AlignPosition,
	startedAt: number,
	farFor: number,
	checkedOwnership: boolean?,
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
-- On touch screens a touch that starts while something is lifted might be a camera pan,
-- so it's only treated as a tap (and acted on) once it ends short and still.
local liftedTouch: Press? = nil
local pointer = Vector2.zero -- screen position (no GUI inset) of the active pointer

local grabRemote
local releaseRemote
local sendRemote

local CLASS_NAMES = { "Light", "Medium", "Heavy", "Very heavy" }

-- Clicks that land on the sand this close to an item (or anywhere on your own vessel)
-- still grab it, so small or half-sunk items aren't fiddly to hit.
local PICK_RADIUS = 2.5

-- In Studio, explain every click in the Output window.
local DEBUG = RunService:IsStudio()
local function debugLog(...)
	if DEBUG then
		print("[Grab]", ...)
	end
end

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
	-- Any part of your own vessel tows it by its handle (hovering magical vessels follow you
	-- on their own and can't be towed).
	local vessel = ownVesselFrom(part)
	if vessel and not vessel:GetAttribute("Hover") then
		for _, child in vessel:GetChildren() do
			if CollectionService:HasTag(child, "VesselHandle") then
				return child :: BasePart, "vessel"
			end
		end
	end
	return nil, nil
end

-- Finds what the player is pointing at: the part under the pointer if it's grabbable,
-- otherwise the nearest grabbable thing close to where the pointer ray landed.
local function pick(screenPosition: Vector2): (BasePart?, ("item" | "vessel")?, Vector3?, string)
	local hit = raycastFrom(screenPosition)
	if not hit then
		return nil, nil, nil, "pointer hit nothing"
	end
	local part, kind = grabbableFrom(hit.Instance)
	if part and kind then
		return part, kind, hit.Position, "hit " .. hit.Instance:GetFullName()
	end

	local include = {}
	for _, name in { "Items", "Vessels" } do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(include, folder)
		end
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = include
	local best, bestKind, bestDistance = nil, nil, math.huge
	for _, nearby in Workspace:GetPartBoundsInRadius(hit.Position, PICK_RADIUS, params) do
		local candidate, candidateKind = grabbableFrom(nearby)
		if candidate and candidateKind then
			local distance = (nearby.Position - hit.Position).Magnitude
			if distance < bestDistance then
				best, bestKind, bestDistance = candidate, candidateKind, distance
			end
		end
	end
	if best then
		return best, bestKind, hit.Position, "near " .. hit.Instance:GetFullName()
	end
	return nil, nil, nil, "hit " .. hit.Instance:GetFullName() .. ", nothing grabbable nearby"
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

-- The vessel plus everything loaded in it, so towing a full cart feels like towing an
-- empty one.
local function loadedMass(vessel: Model): number
	local mass = vesselMass(vessel)
	local vesselId = vessel:GetAttribute("VesselId")
	for _, item in CollectionService:GetTagged("SalvageItem") do
		if item:GetAttribute("VesselId") == vesselId and item:GetAttribute("State") == "InVessel" then
			mass += (item :: BasePart).Mass
		end
	end
	return mass
end

local function hasReward(id: string): boolean
	return string.find("," .. (player:GetAttribute("Rewards") or "") .. ",", "," .. id .. ",", 1, true) ~= nil
end

-- Whether the held item could go in Deep Pockets (the server checks again).
local function canPocket(): boolean
	local current = held
	local slots = player:GetAttribute("PocketSlots") or 0
	if not current or current.kind ~= "item" or slots == 0 then
		return false
	end
	local part = current.part
	return part:GetAttribute("Class") == Gear.WeightClass.Light
		and not part:GetAttribute("Unlock")
		and (player:GetAttribute("Pockets") or 0) < slots
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

-- Deep Pockets: put the held Light item in your pockets. The server destroys the item,
-- and update() notices it's gone and cleans up.
function GrabController.pocket()
	local current = held
	if not current or current.kind ~= "item" then
		return
	end
	if (player:GetAttribute("PocketSlots") or 0) == 0 then
		return
	end
	Remotes.get("Pocket"):FireServer("store", current.part)
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
		* (if hasReward("SwiftFeet") and kind == "vessel" then Rebirth.SwiftFeetSpeed else 1)
		* (if kind == "vessel" then Traders.vesselSpeedMultiplier(upgrades()) else 1)
	if kind == "item" then
		align.ApplyAtCenterOfMass = true
		-- part.Mass, not AssemblyMass: the item may still read as anchored on this client for a
		-- moment after the server lets go of it, and an anchored assembly's mass isn't usable.
		align.MaxForce = part.Mass * currentTool().Grip
	else
		local vessel = part.Parent :: Model
		align.ApplyAtCenterOfMass = false
		align.MaxForce = loadedMass(vessel)
			* grabCfg.TowAcceleration
			* Traders.vesselSpeedMultiplier(upgrades())
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

-- Height of the map surface (sand, seabed or boardwalk) under a position.
local function groundBelow(position: Vector3): number
	local map = Workspace:FindFirstChild("Map")
	if map then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { map }
		local hit = Workspace:Raycast(position + Vector3.new(0, 30, 0), Vector3.new(0, -100, 0), params)
		if hit then
			return hit.Position.Y
		end
	end
	return Beach.groundY(position.Z)
end

-- Parking brake: while you aren't towing your vessel, hold it where you left it so it
-- doesn't slide down the beach. Horizontal only, so it still sits on the ground and can tip.
-- This client simulates its own vessel, so the brake lives here like the tow constraint.
-- The same client also keeps its vessel upright: an AlignOrientation that only aligns the
-- vessel's up axis with world up, so it can still turn freely but resists flipping.
local UPRIGHT = CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, Vector3.xAxis) -- X axis = up

local brake: {
	vessel: Model,
	align: AlignPosition,
	attachment: Attachment,
	upright: AlignOrientation,
	uprightAttachment: Attachment,
	park: Vector3,
}? =
	nil

local function updateBrake()
	local vessel = myVessel()
	local base = vessel and vessel.PrimaryPart
	if brake and (brake.vessel ~= vessel or not brake.align.Parent) then
		brake.align:Destroy()
		brake.attachment:Destroy()
		brake.upright:Destroy()
		brake.uprightAttachment:Destroy()
		brake = nil
	end
	if not vessel or not base then
		return
	end
	if not brake then
		local attachment = Instance.new("Attachment")
		attachment.Name = "BrakeAttachment"
		attachment.Parent = base
		local align = Instance.new("AlignPosition")
		align.Name = "ParkingBrake"
		align.Mode = Enum.PositionAlignmentMode.OneAttachment
		align.Attachment0 = attachment
		align.ApplyAtCenterOfMass = true
		align.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		align.Responsiveness = 15
		align.Position = base.Position
		align.Parent = base
		local uprightAttachment = Instance.new("Attachment")
		uprightAttachment.Name = "UprightAttachment"
		uprightAttachment.CFrame = UPRIGHT
		uprightAttachment.Parent = base
		local upright = Instance.new("AlignOrientation")
		upright.Name = "Upright"
		upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
		upright.Attachment0 = uprightAttachment
		upright.PrimaryAxisOnly = true
		upright.CFrame = UPRIGHT
		upright.Responsiveness = 15
		upright.Parent = base

		brake = {
			vessel = vessel,
			align = align,
			attachment = attachment,
			upright = upright,
			uprightAttachment = uprightAttachment,
			park = base.Position,
		}
	end

	local current = brake :: any
	local mass = loadedMass(vessel)

	-- Magical hovering vessel: follow behind the player, upright and facing the same way.
	if vessel:GetAttribute("Hover") then
		local root = getRoot()
		if root then
			local look = root.CFrame.LookVector
			local flatLook = Vector3.new(look.X, 0, look.Z).Unit
			local spot = root.Position - flatLook * 7
			current.align.Position = Vector3.new(spot.X, groundBelow(spot) + grabCfg.HoverHeight, spot.Z)
			current.upright.CFrame =
				CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, flatLook:Cross(Vector3.yAxis))
		end
		local force = mass * grabCfg.HoverAcceleration * Traders.vesselSpeedMultiplier(upgrades())
		current.align.MaxAxesForce = Vector3.new(force, force, force)
		current.align.Enabled = true
		current.upright.PrimaryAxisOnly = false
		current.upright.MaxTorque = mass * grabCfg.StabilizerTorque * 3
		return
	end

	local towing = held ~= nil and held.kind == "vessel"
	local offset = base.Position - current.park
	if towing or Vector3.new(offset.X, 0, offset.Z).Magnitude > grabCfg.BrakeSlip then
		current.park = base.Position
	end
	local force = mass * grabCfg.BrakeAcceleration
	current.align.MaxAxesForce = Vector3.new(force, 0, force)
	current.upright.MaxTorque = mass * grabCfg.StabilizerTorque * (vessel:GetAttribute("Stability") or 1)
	current.align.Enabled = not towing
	current.align.Position = current.park
end

local function enterLifted()
	local current = held
	if not current then
		return
	end
	current.mode = "lifted"
	HUD.setHoldButtons(true, current.kind == "item" and myVessel() ~= nil, canPocket())
end

local function targetPosition(current: Held, root: BasePart): Vector3
	local reach = if current.kind == "item" then currentTool().Reach else grabCfg.VesselHandleReach
	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit

	local handleHeight = current.part:GetAttribute("HandleHeight") or grabCfg.DefaultHandleHeight

	if current.mode == "lifted" then
		if current.kind == "vessel" then
			local spot = root.Position + flatLook * 3.5
			return Vector3.new(spot.X, groundBelow(spot) + handleHeight, spot.Z)
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
	-- The pointer ray usually ends at the ground, which would press things into the sand
	-- and pin them with friction. Keep items lifted clear of it, and handles at towing height.
	local ground = groundBelow(target)
	if current.kind == "vessel" then
		return Vector3.new(target.X, ground + handleHeight, target.Z)
	end
	local floor = ground + current.part.Size.Y / 2 + grabCfg.HoldLift
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
	if current.kind == "vessel" then
		-- Cargo gets loaded and spilled while towing, so keep the pull matched to the load.
		current.align.MaxForce = loadedMass(part.Parent :: Model)
			* grabCfg.TowAcceleration
			* Traders.vesselSpeedMultiplier(upgrades())
	end

	if DEBUG and not current.checkedOwnership and os.clock() - current.startedAt > 1 then
		current.checkedOwnership = true
		-- ReceiveAge > 0 means the server is still simulating it, so our constraint can't move it.
		debugLog(
			"after 1s:",
			part.Name,
			"anchored:",
			part.Anchored,
			"owned by this client:",
			part.ReceiveAge == 0,
			"distance to target:",
			math.floor((part.Position - target).Magnitude * 10) / 10
		)
	end

	if current.kind == "item" then
		-- Damp spinning so held things don't tumble forever.
		part.AssemblyAngularVelocity *= 0.9

		-- Waves (or bumps) pulling it out of your grip knock it loose.
		local tool = currentTool()
		if
			os.clock() - current.startedAt > 0.8
			and (part.Position - target).Magnitude
				> tool.GripBreak * Traders.gripMultiplier(upgrades()) + part.Size.Magnitude / 2
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
			HUD.setHoldButtons(true, myVessel() ~= nil, canPocket())
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
		return line .. " (claimed)", Palette.UI.Claimed
	end
	local tool = currentTool()
	if not Gear.canLift(tool, class) then
		return line .. " (too heavy)", Palette.UI.Bad
	end
	if
		state ~= "InVessel" and not Gear.canReachDepth(tool, Beach.depthBand(part.Position, Tide.waterline()))
	then
		return line .. " (too deep)", Palette.UI.Bad
	end
	local rarityColor = Items.RarityColors[part:GetAttribute("Rarity") or "Common"]
	return line, rarityColor or Palette.UI.Text
end

local function updateHover()
	if held or UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		HUD.setTooltip(nil)
		return
	end
	local mouse = UserInputService:GetMouseLocation()
	local inset = game:GetService("GuiService"):GetGuiInset()
	local screen = mouse - inset
	local part, kind = pick(screen)
	if part and kind == "item" then
		local message, color = describe(part)
		HUD.setTooltip(message, color, screen)
	elseif part and kind == "vessel" then
		HUD.setTooltip("Your vessel · drag to tow, release items over it to load", Palette.UI.Text, screen)
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
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			debugLog("click was taken by the UI, not the world")
		end
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
	if current and current.mode == "lifted" and input.UserInputType == Enum.UserInputType.Touch then
		liftedTouch = {
			input = input,
			startedAt = os.clock(),
			startPosition = screen,
			ended = false,
			moved = 0,
		}
		return
	end
	if current and current.mode == "lifted" then
		local hit = raycastFrom(screen)
		if current.kind == "item" and hit and ownVesselFrom(hit.Instance) then
			GrabController.sendToVessel()
		else
			GrabController.release()
		end
		return
	end
	if held then
		return
	end
	if press then
		-- Never let a lost press block grabbing for good.
		if os.clock() - press.startedAt < 5 then
			debugLog("ignored click: still waiting on the previous grab")
			return
		end
		press = nil
	end

	local part, kind, hitPosition, why = pick(screen)
	if not part or not kind or not hitPosition then
		debugLog("click did not grab:", why)
		return
	end
	debugLog("requesting", kind, part:GetFullName(), "(" .. why .. ")")

	pointer = screen
	local thisPress: Press = {
		input = input,
		startedAt = os.clock(),
		startPosition = screen,
		ended = false,
		moved = 0,
	}
	press = thisPress

	task.spawn(function()
		local called, ok, reason = pcall(grabRemote.InvokeServer, grabRemote, part)
		if not called then
			ok, reason = false, "Grab failed: " .. tostring(ok)
		end
		if press == thisPress and (thisPress.ended or not ok) then
			press = nil
		end
		if not ok then
			debugLog("server refused:", reason)
			HUD.notify(reason or "Couldn't grab that")
			return
		end
		if not part.Parent then
			return
		end
		debugLog("grabbed", part:GetFullName(), "anchored on this client:", part.Anchored)
		begin(part, kind, hitPosition :: Vector3)
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
	local touch = liftedTouch
	if touch and input == touch.input then
		local position = Vector2.new(input.Position.X, input.Position.Y)
		touch.moved = math.max(touch.moved, (position - touch.startPosition).Magnitude)
	end
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
		or (input.UserInputType == Enum.UserInputType.MouseButton1)
	if isPointerMove then
		pointer = Vector2.new(input.Position.X, input.Position.Y)
		p.moved = math.max(p.moved, (pointer - p.startPosition).Magnitude)
	end
end

local function onInputEnded(input: InputObject)
	local touch = liftedTouch
	if touch and input == touch.input then
		liftedTouch = nil
		touch.endedAt = os.clock()
		local current = held
		-- Only a real tap on your own vessel sends the item there. Pans and swipes do
		-- nothing, and dropping is the Drop button, so moving the camera never drops it.
		if current and current.mode == "lifted" and current.kind == "item" and isTap(touch) then
			local hit = raycastFrom(touch.startPosition)
			if hit and ownVesselFrom(hit.Instance) then
				GrabController.sendToVessel()
			end
		end
		return
	end

	local p = press
	if not p then
		return
	end
	-- Touches are matched exactly; for the mouse, any left-button release ends the press.
	local matches = if p.input.UserInputType == Enum.UserInputType.Touch
		then input == p.input
		else input.UserInputType == Enum.UserInputType.MouseButton1
	if not matches then
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

	HUD.bindHoldButtons(GrabController.release, GrabController.sendToVessel, GrabController.pocket)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Q then
			GrabController.pocket()
		end
	end)

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputChanged:Connect(onInputChanged)
	UserInputService.InputEnded:Connect(onInputEnded)

	RunService.RenderStepped:Connect(function(dt)
		update(dt)
		updateBrake()
		updateHover()
	end)

	player.CharacterRemoving:Connect(cleanup)
end

return GrabController
