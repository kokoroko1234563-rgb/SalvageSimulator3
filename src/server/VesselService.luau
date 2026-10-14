-- Vessels: built from parts, towed by their handle, loaded with items, spill when items
-- fall out, and disappear (with their contents) when covered by deep water.
-- Each player has at most one vessel out. Respawning a bought vessel at the shore is free.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Gear = require(Shared.Gear)
local Tide = require(Shared.Tide)

local CollisionGroups = require(script.Parent.CollisionGroups)
local ItemService = require(script.Parent.ItemService)

local VesselService = {}

VesselService.Tag = "Vessel"
VesselService.HandleTag = "VesselHandle"

local folder: Folder
local vesselOf: { [Player]: Model } = {}
local notify: (Player, string) -> () = function(_player: Player, _text: string) end

-- Builds a vessel model in local space: front is -Z, the floor ("Base") is the PrimaryPart,
-- "Cargo" is an invisible box marking the load space, "Handle" is what players grab.
local function part(
	model: Model,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	props: { [string]: any }?
)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.3, 0.1)
	if props then
		for key, value in props do
			(p :: any)[key] = value
		end
	end
	p.Parent = model
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function wheel(
	model: Model,
	base: BasePart,
	name: string,
	offset: Vector3,
	diameter: number,
	width: number
)
	local w = part(
		model,
		name,
		Vector3.new(width, diameter, diameter),
		base.CFrame * CFrame.new(offset),
		Color3.fromRGB(40, 40, 40),
		{
			Shape = Enum.PartType.Cylinder,
			CustomPhysicalProperties = PhysicalProperties.new(0.6, 0.9, 0.2),
		}
	)
	local a0 = Instance.new("Attachment")
	a0.Name = name .. "Axle"
	a0.Position = offset
	a0.Parent = base
	local a1 = Instance.new("Attachment")
	a1.Name = "Axle"
	a1.Parent = w
	local hinge = Instance.new("HingeConstraint")
	hinge.Attachment0 = a0
	hinge.Attachment1 = a1
	hinge.Parent = w
	for _, other in model:GetChildren() do
		if other:IsA("BasePart") and other ~= w and other.Name ~= "Cargo" then
			local nc = Instance.new("NoCollisionConstraint")
			nc.Part0 = w
			nc.Part1 = other
			nc.Parent = w
		end
	end
	return w
end

-- Tray with walls. Returns the floor part.
local function tray(model: Model, origin: CFrame, inner: Vector3, wallHeight: number, color: Color3): BasePart
	local t = 0.3
	local base = part(model, "Base", Vector3.new(inner.X + t * 2, t, inner.Z + t * 2), origin, color)
	local walls = {
		{ Vector3.new(t, wallHeight, inner.Z + t * 2), Vector3.new(-(inner.X + t) / 2, wallHeight / 2, 0) },
		{ Vector3.new(t, wallHeight, inner.Z + t * 2), Vector3.new((inner.X + t) / 2, wallHeight / 2, 0) },
		{ Vector3.new(inner.X, wallHeight, t), Vector3.new(0, wallHeight / 2, -(inner.Z + t) / 2) },
		{ Vector3.new(inner.X, wallHeight, t), Vector3.new(0, wallHeight / 2, (inner.Z + t) / 2) },
	}
	for index, wall in walls do
		local w = part(model, "Wall" .. index, wall[1], origin * CFrame.new(wall[2]), color)
		weld(base, w)
	end
	local cargo = part(
		model,
		"Cargo",
		Vector3.new(inner.X, wallHeight + 0.5, inner.Z),
		origin * CFrame.new(0, (wallHeight + 0.5) / 2 + t / 2, 0),
		color,
		{ Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true }
	)
	weld(base, cargo)
	model.PrimaryPart = base
	return base
end

local builders = {}

-- One wheel at the front, two legs at the back: tips easily, lifts by the handles.
function builders.Wheelbarrow(model: Model, at: CFrame)
	local color = Color3.fromRGB(70, 140, 90)
	local base = tray(model, at * CFrame.new(0, 2, 0), Vector3.new(3, 0, 4), 1.4, color)
	for side = -1, 1, 2 do
		local leg = part(
			model,
			"Leg",
			Vector3.new(0.3, 1.9, 0.3),
			base.CFrame * CFrame.new(side * 1.2, -0.95, 1.6),
			color,
			{
				CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.8, 0.1),
			}
		)
		weld(base, leg)
	end
	local handle = part(
		model,
		"Handle",
		Vector3.new(3, 0.3, 1.6),
		base.CFrame * CFrame.new(0, 0.6, 3),
		Color3.fromRGB(150, 110, 70)
	)
	weld(base, handle)
	wheel(model, base, "FrontWheel", Vector3.new(0, -1, -3), 1.8, 0.5)
	return handle
end

-- Four wheels, low and wide, handle at the front.
function builders.BeachWagon(model: Model, at: CFrame)
	local color = Color3.fromRGB(220, 70, 60)
	local base = tray(model, at * CFrame.new(0, 1.3, 0), Vector3.new(4.2, 0, 6), 1.2, color)
	local handle = part(
		model,
		"Handle",
		Vector3.new(0.4, 0.4, 3),
		base.CFrame * CFrame.new(0, 0.6, -4.6),
		Color3.fromRGB(60, 60, 60)
	)
	weld(base, handle)
	for _, offset in
		{
			Vector3.new(-2.55, -0.6, -2.2),
			Vector3.new(2.55, -0.6, -2.2),
			Vector3.new(-2.55, -0.6, 2.2),
			Vector3.new(2.55, -0.6, 2.2),
		}
	do
		wheel(model, base, "Wheel", offset, 1.4, 0.5)
	end
	return handle
end

function VesselService.getVessel(player: Player): Model?
	local vessel = vesselOf[player]
	if vessel and vessel.Parent then
		return vessel
	end
	return nil
end

function VesselService.ownerOf(vessel: Model): Player?
	return Players:GetPlayerByUserId(vessel:GetAttribute("Owner") or 0)
end

function VesselService.contents(vessel: Model): { BasePart }
	local id = vessel:GetAttribute("VesselId")
	local result = {}
	for item in ItemService.all() do
		if item:GetAttribute("VesselId") == id and ItemService.getState(item) == "InVessel" then
			table.insert(result, item)
		end
	end
	return result
end

function VesselService.isFull(vessel: Model): boolean
	return #VesselService.contents(vessel) >= (vessel:GetAttribute("Capacity") or 0)
end

-- True if a world position is inside (or just above) the vessel's cargo space.
function VesselService.isOverCargo(vessel: Model, position: Vector3): boolean
	local cargo = vessel:FindFirstChild("Cargo") :: BasePart?
	if not cargo then
		return false
	end
	local rel = cargo.CFrame:PointToObjectSpace(position)
	local half = cargo.Size / 2
	return math.abs(rel.X) <= half.X + 0.75
		and math.abs(rel.Z) <= half.Z + 0.75
		and rel.Y >= -half.Y - 1
		and rel.Y <= half.Y + 8
end

local function isOutsideCargo(vessel: Model, position: Vector3): boolean
	local cargo = vessel:FindFirstChild("Cargo") :: BasePart?
	if not cargo then
		return true
	end
	local rel = cargo.CFrame:PointToObjectSpace(position)
	local half = cargo.Size / 2
	return math.abs(rel.X) > half.X + 1.5
		or math.abs(rel.Z) > half.Z + 1.5
		or rel.Y < -half.Y - 2
		or rel.Y > half.Y + 8
end

-- Puts an item into the player's vessel. Returns ok, reason.
function VesselService.load(player: Player, item: BasePart): (boolean, string?)
	local vessel = VesselService.getVessel(player)
	if not vessel then
		return false, "You don't have a vessel out"
	end
	if VesselService.isFull(vessel) then
		return false, "Your vessel is full"
	end
	local cargo = vessel:FindFirstChild("Cargo") :: BasePart
	local base = vessel.PrimaryPart :: BasePart
	local group = CollisionGroups.vesselGroupFor(player)
	if not group then
		return false, "No vessel slot"
	end

	-- Drop it in from just above the middle of the cargo space so it settles on the pile.
	local count = #VesselService.contents(vessel)
	local spread = cargo.Size / 2 - Vector3.new(0.6, 0, 0.6)
	local offset = Vector3.new(
		((count % 2) * 2 - 1) * math.max(spread.X, 0) * 0.5,
		cargo.Size.Y / 2 + item.Size.Y / 2,
		((math.floor(count / 2) % 3) - 1) * math.max(spread.Z, 0) * 0.6
	)
	item.CFrame = cargo.CFrame * CFrame.new(offset)
	item.AssemblyLinearVelocity = base.AssemblyLinearVelocity
	item.AssemblyAngularVelocity = Vector3.zero
	ItemService.setInVessel(item, vessel:GetAttribute("VesselId"), player, group)
	return true
end

local function destroyVessel(player: Player, reason: string?)
	local vessel = vesselOf[player]
	vesselOf[player] = nil
	player:SetAttribute("ActiveVessel", "")
	if not vessel then
		return
	end
	for _, item in VesselService.contents(vessel) do
		ItemService.destroy(item)
	end
	vessel:Destroy()
	if reason then
		notify(player, reason)
	end
end

-- `at` is where the bottom of the vessel goes; defaults to the shop's vessel pad.
function VesselService.spawn(player: Player, kind: string, at: CFrame?): (boolean, string?)
	local def = Gear.getVessel(kind)
	local build = def and builders[kind]
	if not def or not build then
		return false, "Unknown vessel"
	end
	local group = CollisionGroups.vesselGroupFor(player)
	if not group then
		return false, "No vessel slot"
	end

	-- Respawning replaces the old one. Its contents are dropped as loose items.
	local old = VesselService.getVessel(player)
	if old then
		for _, item in VesselService.contents(old) do
			ItemService.setLoose(item)
		end
		destroyVessel(player, nil)
	end

	local pad = Workspace.Map.Shop.VesselPad :: BasePart
	local model = Instance.new("Model")
	model.Name = player.Name .. "'s " .. def.Name
	local origin = at or CFrame.new(pad.Position.X, pad.Position.Y, pad.Position.Z)
	local handle = build(model, origin)

	local vesselId = HttpService:GenerateGUID(false)
	model:SetAttribute("VesselId", vesselId)
	model:SetAttribute("Kind", def.Id)
	model:SetAttribute("Owner", player.UserId)
	model:SetAttribute("Capacity", def.Capacity)
	handle:SetAttribute("VesselId", vesselId)
	CollectionService:AddTag(model, VesselService.Tag)
	CollectionService:AddTag(handle, VesselService.HandleTag)

	CollisionGroups.setGroup(model, group)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end
	model.Parent = folder
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			ItemService.trySetNetworkOwner(descendant, player)
		end
	end

	vesselOf[player] = model
	player:SetAttribute("ActiveVessel", def.Id)
	return true
end

local function tick()
	local waterline = Tide.waterline()
	for player, vessel in vesselOf do
		local base = vessel.PrimaryPart
		if not base or not vessel.Parent then
			destroyVessel(player, nil)
			continue
		end
		if
			Beach.isDeep(base.Position, waterline)
			or base.Position.Y < Beach.groundY(base.Position.Z) - 30
		then
			destroyVessel(
				player,
				"Your vessel was lost to the water, along with everything in it. Respawn it free at the shop."
			)
			continue
		end
		-- Anything that fell out of the cargo space is spilled onto the beach.
		local spilled = 0
		for _, item in VesselService.contents(vessel) do
			if isOutsideCargo(vessel, item.Position) then
				ItemService.setLoose(item)
				spilled += 1
			end
		end
		if spilled > 0 then
			notify(player, if spilled == 1 then "An item spilled out!" else spilled .. " items spilled out!")
		end
	end
end

function VesselService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	folder = Instance.new("Folder")
	folder.Name = "Vessels"
	folder.Parent = Workspace

	task.spawn(function()
		while true do
			task.wait(0.3)
			tick()
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		destroyVessel(player, nil)
	end)
end

return VesselService
