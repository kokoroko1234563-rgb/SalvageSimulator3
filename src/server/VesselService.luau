-- Vessels: built from parts, towed by their handle, loaded with items, spill when items
-- fall out, and disappear (with their contents) when covered by deep water.
-- Each player has at most one vessel out. Respawning a bought vessel at the shore is free.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
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

-- Physics wheels on hinges are fiddly in Roblox, so wheels are just for looks: each one is
-- welded on and doesn't collide, and a hidden low-friction ball under it is what actually
-- touches the ground. A ball slides smoothly and doesn't catch on seams or slopes.
local SKID_PHYSICS = PhysicalProperties.new(0.6, 0.02, 0, 100, 1) -- friction 0.02, and it wins over the sand's

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
		{ Shape = Enum.PartType.Cylinder, CanCollide = false, Massless = true }
	)
	weld(base, w)

	local skidSize = diameter * 0.6
	local skid = part(
		model,
		name .. "Skid",
		Vector3.new(skidSize, skidSize, skidSize),
		base.CFrame * CFrame.new(offset - Vector3.new(0, (diameter - skidSize) / 2, 0)),
		Color3.fromRGB(40, 40, 40),
		{
			Shape = Enum.PartType.Ball,
			Transparency = 1,
			CanQuery = false,
			CustomPhysicalProperties = SKID_PHYSICS,
		}
	)
	weld(base, skid)
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

-- How hard each vessel's owner keeps it upright (see GrabController). The wheelbarrow is
-- meant to tip more easily than the wagon.
local stability = {
	Wheelbarrow = 0.6,
	BeachWagon = 1.2,
	FloatingClamshell = 1,
	CaptainsLongboat = 2,
	SeaTurtle = 1,
	LeviathanRowboat = 3,
}

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
				CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.5, 0.1),
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

-- Magical: a pearly shell that hovers behind its owner (driven by the owner's client, see
-- GrabController). No wheels or skids; the handle only exists so the model has one.
function builders.FloatingClamshell(model: Model, at: CFrame)
	local color = Color3.fromRGB(255, 220, 230)
	local base = tray(model, at * CFrame.new(0, 3, 0), Vector3.new(5, 0, 5), 1.2, color)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "Cargo" then
			child.Material = Palette.Material.Smooth
			child.Reflectance = 0.25 -- pearly sheen
		end
	end
	local lid = part(
		model,
		"Lid",
		Vector3.new(5.6, 0.3, 3),
		base.CFrame * CFrame.new(0, 2.6, 3.4) * CFrame.Angles(math.rad(-55), 0, 0),
		color,
		{ Material = Palette.Material.Smooth, Reflectance = 0.25, CanCollide = false }
	)
	weld(base, lid)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 200, 255)
	glow.Range = 8
	glow.Parent = base
	local handle = part(
		model,
		"Handle",
		Vector3.new(1, 0.3, 1),
		base.CFrame * CFrame.new(0, -0.2, 0),
		color,
		{ Transparency = 1, CanCollide = false }
	)
	weld(base, handle)
	return handle
end

-- Exotic: a long wooden boat dragged over the sand on hidden skids, tow rope at the bow.
function builders.CaptainsLongboat(model: Model, at: CFrame)
	local color = Color3.fromRGB(110, 75, 45)
	local base = tray(model, at * CFrame.new(0, 1.1, 0), Vector3.new(4.6, 0, 10.5), 1.4, color)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "Cargo" then
			child.Material = Palette.Material.WoodPlanks
		end
	end
	local bow = part(
		model,
		"Bow",
		Vector3.new(3.4, 1.6, 3.4),
		base.CFrame * CFrame.new(0, 0.6, -6.4) * CFrame.Angles(0, math.rad(45), 0),
		color,
		{ Material = Palette.Material.WoodPlanks }
	)
	weld(base, bow)
	local handle = part(
		model,
		"Handle",
		Vector3.new(0.5, 0.5, 2.6),
		base.CFrame * CFrame.new(0, 0.8, -9),
		Color3.fromRGB(200, 180, 120),
		{ Material = Palette.Material.Fabric }
	)
	weld(base, handle)
	-- Skids along the keel: the same low-friction balls the wheels use, just no wheels.
	for _, offset in
		{
			Vector3.new(-1.8, -0.6, -4),
			Vector3.new(1.8, -0.6, -4),
			Vector3.new(-1.8, -0.6, 0),
			Vector3.new(1.8, -0.6, 0),
			Vector3.new(-1.8, -0.6, 4),
			Vector3.new(1.8, -0.6, 4),
		}
	do
		local skid =
			part(model, "Skid", Vector3.new(0.9, 0.9, 0.9), base.CFrame * CFrame.new(offset), color, {
				Shape = Enum.PartType.Ball,
				Transparency = 1,
				CanQuery = false,
				CustomPhysicalProperties = SKID_PHYSICS,
			})
		weld(base, skid)
	end
	return handle
end

-- Magical: a turtle with a flat shell to load. It follows its owner like the clamshell, but
-- swims at the surface instead of hovering, so deep water doesn't take it (GrabController).
function builders.SeaTurtle(model: Model, at: CFrame)
	local shell = Color3.fromRGB(70, 120, 70)
	local skin = Color3.fromRGB(150, 175, 110)
	local base = tray(model, at * CFrame.new(0, 2, 0), Vector3.new(4.4, 0, 5), 0.9, shell)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "Cargo" then
			child.Material = Palette.Material.Smooth
		end
	end
	local head =
		part(model, "Head", Vector3.new(1.6, 1.4, 1.8), base.CFrame * CFrame.new(0, 0.2, -3.6), skin, {
			Shape = Enum.PartType.Ball,
			CanCollide = false,
		})
	weld(base, head)
	for side = -1, 1, 2 do
		for _, z in { -1.8, 1.8 } do
			local flipper = part(
				model,
				"Flipper",
				Vector3.new(1.8, 0.25, 1),
				base.CFrame * CFrame.new(side * 3, -0.2, z) * CFrame.Angles(0, math.rad(side * z * 10), 0),
				skin,
				{ CanCollide = false }
			)
			weld(base, flipper)
		end
	end
	local handle = part(
		model,
		"Handle",
		Vector3.new(1, 0.3, 1),
		base.CFrame * CFrame.new(0, -0.2, 0),
		shell,
		{ Transparency = 1, CanCollide = false }
	)
	weld(base, handle)
	return handle
end

-- Exotic: the longboat's big sibling, a dark rowboat with a carved prow and oars.
function builders.LeviathanRowboat(model: Model, at: CFrame)
	local color = Color3.fromRGB(55, 60, 70)
	local base = tray(model, at * CFrame.new(0, 1.1, 0), Vector3.new(6, 0, 13), 1.6, color)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "Cargo" then
			child.Material = Palette.Material.WoodPlanks
		end
	end
	local prow = part(
		model,
		"Prow",
		Vector3.new(4.4, 2, 4.4),
		base.CFrame * CFrame.new(0, 0.8, -7.8) * CFrame.Angles(0, math.rad(45), 0),
		color,
		{ Material = Palette.Material.WoodPlanks }
	)
	weld(base, prow)
	local eye = part(
		model,
		"Eye",
		Vector3.new(0.8, 0.8, 0.8),
		base.CFrame * CFrame.new(0, 2, -9.6),
		Color3.fromRGB(90, 230, 200),
		{ Shape = Enum.PartType.Ball, Material = Palette.Material.Neon, CanCollide = false }
	)
	weld(base, eye)
	for side = -1, 1, 2 do
		local oar = part(
			model,
			"Oar",
			Vector3.new(0.3, 0.3, 6),
			base.CFrame * CFrame.new(side * 3.8, 1, 0) * CFrame.Angles(0, math.rad(side * 20), 0),
			Palette.World.Mast,
			{ Material = Palette.Material.Wood, CanCollide = false }
		)
		weld(base, oar)
	end
	local handle = part(
		model,
		"Handle",
		Vector3.new(0.5, 0.5, 2.6),
		base.CFrame * CFrame.new(0, 0.8, -11),
		Color3.fromRGB(200, 180, 120),
		{ Material = Palette.Material.Fabric }
	)
	weld(base, handle)
	for _, x in { -2.4, 2.4 } do
		for _, z in { -5, 0, 5 } do
			local skid =
				part(model, "Skid", Vector3.new(1, 1, 1), base.CFrame * CFrame.new(x, -0.6, z), color, {
					Shape = Enum.PartType.Ball,
					Transparency = 1,
					CanQuery = false,
					CustomPhysicalProperties = SKID_PHYSICS,
				})
			weld(base, skid)
		end
	end
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

	-- Each item gets its own slot in a 2-wide grid over the cargo floor and is welded there,
	-- so odd shapes can't jam, bounce out or stop the vessel holding its full capacity.
	local capacity = vessel:GetAttribute("Capacity") or 1
	local used = {}
	for _, other in VesselService.contents(vessel) do
		used[other:GetAttribute("Slot") or 0] = true
	end
	local slot = 1
	while used[slot] do
		slot += 1
	end
	local columns = math.min(2, capacity)
	local rows = math.ceil(capacity / columns)
	local column = (slot - 1) % columns
	local row = math.floor((slot - 1) / columns)
	local cellX, cellZ = cargo.Size.X / columns, cargo.Size.Z / rows
	local offset = Vector3.new(
		-cargo.Size.X / 2 + cellX * (column + 0.5),
		-cargo.Size.Y / 2 + item.Size.Y / 2 + 0.05,
		-cargo.Size.Z / 2 + cellZ * (row + 0.5)
	)

	item.CFrame = cargo.CFrame * CFrame.new(offset)
	item.AssemblyLinearVelocity = base.AssemblyLinearVelocity
	item.AssemblyAngularVelocity = Vector3.zero
	item.Massless = true
	item.CanCollide = false
	local slotWeld = Instance.new("WeldConstraint")
	slotWeld.Name = "VesselWeld"
	slotWeld.Part0 = base
	slotWeld.Part1 = item
	slotWeld.Parent = item
	item:SetAttribute("Slot", slot)
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

-- `at` is where the bottom of the vessel goes; defaults to in front of the player.
-- Where a vessel called by this player appears: 8 studs in front of them, on the ground,
-- facing the way they face. Nil (with a reason) inside a secret or over deep water.
function VesselService.spotNear(player: Player): (CFrame?, string?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil, "You need to be on the beach"
	end
	if root.Position.Y > Config.Secrets.Origin.Y - 100 then
		return nil, "You can't call a vessel in here"
	end
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z)
	forward = if forward.Magnitude > 0.01 then forward.Unit else Vector3.new(0, 0, -1)
	local spot = root.Position + forward * 8

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Map }
	local hit = Workspace:Raycast(spot + Vector3.new(0, 30, 0), Vector3.new(0, -120, 0), params)
	local groundY = if hit then hit.Position.Y else Beach.groundY(spot.Z)
	local ground = Vector3.new(spot.X, groundY, spot.Z)
	if Beach.isDeep(ground, Tide.waterline()) then
		return nil, "The water is too deep for a vessel here"
	end
	return CFrame.lookAt(ground, ground + forward)
end

-- Removes the player's vessel; anything in it is dropped as loose items.
function VesselService.despawn(player: Player)
	local vessel = VesselService.getVessel(player)
	if vessel then
		for _, item in VesselService.contents(vessel) do
			ItemService.setLoose(item)
		end
	end
	destroyVessel(player, nil)
end

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

	local origin = at
	if not origin then
		local spot, reason = VesselService.spotNear(player)
		if not spot then
			return false, reason
		end
		origin = spot
	end

	-- Respawning replaces the old one. Its contents are dropped as loose items.
	local old = VesselService.getVessel(player)
	if old then
		for _, item in VesselService.contents(old) do
			ItemService.setLoose(item)
		end
		destroyVessel(player, nil)
	end

	local model = Instance.new("Model")
	model.Name = player.Name .. "'s " .. def.Name
	local handle = build(model, origin :: CFrame)

	local vesselId = HttpService:GenerateGUID(false)
	model:SetAttribute("VesselId", vesselId)
	model:SetAttribute("Kind", def.Id)
	model:SetAttribute("Owner", player.UserId)
	model:SetAttribute("Capacity", def.Capacity)
	model:SetAttribute("Stability", stability[def.Id] or 1)
	model:SetAttribute("Hover", def.Magical == true)
	model:SetAttribute("Swims", def.Swims == true)
	handle:SetAttribute("VesselId", vesselId)
	-- A little above its resting height, so the wheelbarrow's legs lift clear of the sand.
	handle:SetAttribute("HandleHeight", handle.Position.Y - origin.Position.Y + 0.5)
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
		local swims = vessel:GetAttribute("Swims") == true
		if swims and Beach.isDeep(base.Position, waterline) then
			-- Swimming vessels survive deep water, but the waves can wash cargo off.
			if math.random() < Config.Grab.SwimWashChance then
				local contents = VesselService.contents(vessel)
				if #contents > 0 then
					ItemService.setLoose(contents[math.random(#contents)])
					notify(player, "A wave washed something off your vessel!")
				end
			end
		end
		if
			(not swims and Beach.isDeep(base.Position, waterline))
			or base.Position.Y < Beach.groundY(base.Position.Z) - 30
		then
			destroyVessel(
				player,
				"Your vessel was lost to the water, along with everything in it. Spawn it again for free from your inventory (I)."
			)
			continue
		end
		-- Cargo is welded in, so it only comes out if the vessel actually tips over.
		if base.CFrame.UpVector.Y < 0.25 then
			local contents = VesselService.contents(vessel)
			for _, item in contents do
				ItemService.setLoose(item)
			end
			if #contents > 0 then
				notify(player, "Your vessel tipped over and spilled its load!")
			end
		end
	end
end

-- For the data validator and tools/tests.
VesselService._builders = builders

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
