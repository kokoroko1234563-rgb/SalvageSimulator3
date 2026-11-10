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
local Stats = require(Shared.Stats)
local Tide = require(Shared.Tide)
local VesselPowers = require(Shared.VesselPowers)

local CollisionGroups = require(script.Parent.CollisionGroups)
local ItemService = require(script.Parent.ItemService)
local VesselTrim = require(script.Parent.VesselTrim)

local VesselService = {}

VesselService.Tag = "Vessel"
VesselService.HandleTag = "VesselHandle"

local folder: Folder
local vesselOf: { [Player]: Model } = {}
local lastPosition: { [Model]: { at: Vector3, time: number } } = {} -- a ridden boat, for the speed check
local lastScoop: { [Model]: number } = {} -- when each Jelly Raft last took something
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

-- Helpers for the builders below. `attach` makes a part placed relative to the base and welds
-- it on; `skids` adds the hidden low-friction balls a wheel-less towed vessel slides on;
-- `dress` restyles the tray parts (everything but the invisible Cargo box).
local function attach(
	model: Model,
	base: BasePart,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	props: { [string]: any }?
)
	local p = part(model, name, size, base.CFrame * offset, color, props)
	weld(base, p)
	return p
end

local function skids(model: Model, base: BasePart, offsets: { Vector3 }, size: number)
	for _, offset in offsets do
		attach(model, base, "Skid", Vector3.new(size, size, size), CFrame.new(offset), base.Color, {
			Shape = Enum.PartType.Ball,
			Transparency = 1,
			CanQuery = false,
			CustomPhysicalProperties = SKID_PHYSICS,
		})
	end
end

local function dress(model: Model, props: { [string]: any })
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "Cargo" then
			for key, value in props do
				(child :: any)[key] = value
			end
		end
	end
end

-- The invisible handle a follower vessel carries (it's moved by its owner's client).
local function followerHandle(model: Model, base: BasePart)
	return attach(
		model,
		base,
		"Handle",
		Vector3.new(1, 0.3, 1),
		CFrame.new(0, -0.2, 0),
		base.Color,
		{ Transparency = 1, CanCollide = false }
	)
end

-- Sand cart: a light buggy on wide balloon wheels that float over soft sand.
function builders.SandCart(model: Model, at: CFrame)
	local color = Color3.fromRGB(240, 170, 50)
	local base = tray(model, at * CFrame.new(0, 1.6, 0), Vector3.new(4.4, 0, 7.5), 1.2, color)
	local frame = Color3.fromRGB(60, 60, 65)
	-- Roll bar over the back of the tray.
	for side = -1, 1, 2 do
		attach(
			model,
			base,
			"RollBar",
			Vector3.new(0.3, 2.4, 0.3),
			CFrame.new(side * 2.35, 1.2, 3.6),
			frame,
			{ Material = Palette.Material.Metal, CanCollide = false }
		)
	end
	attach(
		model,
		base,
		"RollBarTop",
		Vector3.new(5, 0.3, 0.3),
		CFrame.new(0, 2.4, 3.6),
		frame,
		{ Material = Palette.Material.Metal, CanCollide = false }
	)
	local handle = attach(
		model,
		base,
		"Handle",
		Vector3.new(0.4, 0.4, 3),
		CFrame.new(0, 0.6, -5.6),
		frame,
		{ Material = Palette.Material.Metal }
	)
	for _, offset in
		{
			Vector3.new(-3.15, -0.5, -2.6),
			Vector3.new(3.15, -0.5, -2.6),
			Vector3.new(-3.15, -0.5, 2.6),
			Vector3.new(3.15, -0.5, 2.6),
		}
	do
		local w = wheel(model, base, "Wheel", offset, 2.2, 1.2)
		attach(
			model,
			base,
			"Hub",
			Vector3.new(1.25, 0.8, 0.8),
			CFrame.new(offset),
			color,
			{ Shape = Enum.PartType.Cylinder, CanCollide = false, Massless = true }
		)
		w.Color = Color3.fromRGB(30, 30, 30)
	end
	return handle
end

-- Quad bike pulling a trailer: the trailer is the tray, the quad sits out front and its
-- handlebars are the handle.
function builders.QuadBike(model: Model, at: CFrame)
	local trailer = Color3.fromRGB(90, 95, 105)
	local body = Color3.fromRGB(200, 40, 40)
	local base = tray(model, at * CFrame.new(0, 1.4, 0), Vector3.new(5, 0, 9), 1.2, trailer)
	dress(model, { Material = Palette.Material.Metal })
	-- Tow bar from the trailer to the quad.
	attach(
		model,
		base,
		"TowBar",
		Vector3.new(0.3, 0.3, 2.4),
		CFrame.new(0, -0.1, -5.8),
		Color3.fromRGB(50, 50, 55),
		{ Material = Palette.Material.Metal, CanCollide = false }
	)
	-- The quad: body, fenders, seat, handlebar post.
	attach(model, base, "QuadBody", Vector3.new(2.6, 1.2, 4.4), CFrame.new(0, 0.3, -9.2), body)
	for _, z in { -7.6, -10.8 } do
		attach(
			model,
			base,
			"Fender",
			Vector3.new(4.4, 0.25, 1.8),
			CFrame.new(0, 0.95, z),
			body,
			{ CanCollide = false }
		)
	end
	attach(
		model,
		base,
		"Seat",
		Vector3.new(1.6, 0.5, 2),
		CFrame.new(0, 1.15, -8.6),
		Color3.fromRGB(30, 30, 30),
		{ Material = Palette.Material.Fabric }
	)
	attach(
		model,
		base,
		"Post",
		Vector3.new(0.3, 1.2, 0.3),
		CFrame.new(0, 1.4, -10.6) * CFrame.Angles(math.rad(-20), 0, 0),
		Color3.fromRGB(50, 50, 55),
		{ Material = Palette.Material.Metal, CanCollide = false }
	)
	attach(
		model,
		base,
		"Headlight",
		Vector3.new(0.8, 0.4, 0.2),
		CFrame.new(0, 0.6, -11.45),
		Color3.fromRGB(255, 245, 200),
		{ Material = Palette.Material.Neon, CanCollide = false }
	)
	local handle = attach(
		model,
		base,
		"Handle",
		Vector3.new(3, 0.35, 0.5),
		CFrame.new(0, 2, -10.9),
		Color3.fromRGB(30, 30, 30),
		{ Material = Palette.Material.Metal }
	)
	-- Quad wheels, then the trailer's tandem axle.
	for _, offset in
		{
			Vector3.new(-1.8, -0.5, -7.6),
			Vector3.new(1.8, -0.5, -7.6),
			Vector3.new(-1.8, -0.5, -10.8),
			Vector3.new(1.8, -0.5, -10.8),
		}
	do
		wheel(model, base, "QuadWheel", offset, 1.8, 0.9)
	end
	for _, offset in
		{
			Vector3.new(-2.95, -0.6, -2),
			Vector3.new(2.95, -0.6, -2),
			Vector3.new(-2.95, -0.6, 2),
			Vector3.new(2.95, -0.6, 2),
		}
	do
		wheel(model, base, "TrailerWheel", offset, 1.6, 0.5)
	end
	return handle
end

-- Inflatable dinghy: a grey floor ringed with orange tubes, dragged on hidden skids.
function builders.Dinghy(model: Model, at: CFrame)
	local floor = Color3.fromRGB(110, 115, 120)
	local tube = Color3.fromRGB(240, 110, 40)
	local base = tray(model, at * CFrame.new(0, 1.1, 0), Vector3.new(5, 0, 9), 0.9, floor)
	dress(model, { Material = Palette.Material.Fabric })
	local tubeProps =
		{ Shape = Enum.PartType.Cylinder, Material = Palette.Material.Smooth, CanCollide = false }
	for side = -1, 1, 2 do
		attach(
			model,
			base,
			"SideTube",
			Vector3.new(9.6, 1.4, 1.4),
			CFrame.new(side * 3.3, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0),
			tube,
			tubeProps
		)
		-- Rounded bow corners.
		attach(
			model,
			base,
			"BowCorner",
			Vector3.new(1.4, 1.4, 1.4),
			CFrame.new(side * 3.3, 0.5, -4.8),
			tube,
			{ Shape = Enum.PartType.Ball, Material = Palette.Material.Smooth, CanCollide = false }
		)
		-- Grey grab lines along the tubes.
		attach(
			model,
			base,
			"Line",
			Vector3.new(0.15, 0.15, 8),
			CFrame.new(side * 3.3, 1.22, 0),
			floor,
			{ Material = Palette.Material.Fabric, CanCollide = false }
		)
	end
	attach(model, base, "BowTube", Vector3.new(6.6, 1.4, 1.4), CFrame.new(0, 0.5, -4.8), tube, tubeProps)
	attach(
		model,
		base,
		"Transom",
		Vector3.new(5.6, 1.2, 0.3),
		CFrame.new(0, 0.6, 4.75),
		floor,
		{ Material = Palette.Material.Smooth }
	)
	attach(
		model,
		base,
		"Motor",
		Vector3.new(0.8, 1.8, 0.8),
		CFrame.new(0, 0.7, 5.3),
		Color3.fromRGB(35, 35, 40),
		{ Material = Palette.Material.Smooth, CanCollide = false }
	)
	local handle = attach(
		model,
		base,
		"Handle",
		Vector3.new(0.5, 0.5, 2.6),
		CFrame.new(0, 0.8, -6.8),
		Color3.fromRGB(230, 230, 220),
		{ Material = Palette.Material.Fabric }
	)
	skids(model, base, {
		Vector3.new(-2, -0.6, -3.2),
		Vector3.new(2, -0.6, -3.2),
		Vector3.new(-2, -0.6, 0),
		Vector3.new(2, -0.6, 0),
		Vector3.new(-2, -0.6, 3.2),
		Vector3.new(2, -0.6, 3.2),
	}, 0.9)
	return handle
end

-- Pickup truck: the cargo bed is the tray, the cab and bonnet are out front, and the tow
-- handle sticks out of the front bumper.
function builders.PickupTruck(model: Model, at: CFrame)
	local paint = Color3.fromRGB(40, 90, 160)
	local trim = Color3.fromRGB(60, 60, 65)
	local base = tray(model, at * CFrame.new(0, 2.2, 0), Vector3.new(6.4, 0, 10), 1.6, paint)
	dress(model, { Material = Palette.Material.Metal })
	attach(
		model,
		base,
		"Cab",
		Vector3.new(7.4, 3.8, 4),
		CFrame.new(0, 1.3, -7.3),
		paint,
		{ Material = Palette.Material.Metal }
	)
	attach(
		model,
		base,
		"Windshield",
		Vector3.new(6.6, 1.8, 0.2),
		CFrame.new(0, 2.1, -9.35),
		Color3.fromRGB(150, 200, 230),
		{ Material = Palette.Material.Glass, Transparency = 0.3, CanCollide = false }
	)
	for side = -1, 1, 2 do
		attach(
			model,
			base,
			"SideWindow",
			Vector3.new(0.2, 1.6, 2.8),
			CFrame.new(side * 3.75, 2.1, -7.3),
			Color3.fromRGB(150, 200, 230),
			{ Material = Palette.Material.Glass, Transparency = 0.3, CanCollide = false }
		)
		attach(
			model,
			base,
			"Headlight",
			Vector3.new(1.2, 0.5, 0.2),
			CFrame.new(side * 2.8, 0.4, -12.95),
			Color3.fromRGB(255, 245, 200),
			{ Material = Palette.Material.Neon, CanCollide = false }
		)
		attach(
			model,
			base,
			"TailLight",
			Vector3.new(0.6, 1, 0.2),
			CFrame.new(side * 3.2, 0.8, 5.4),
			Color3.fromRGB(220, 30, 30),
			{ Material = Palette.Material.Neon, CanCollide = false }
		)
	end
	attach(
		model,
		base,
		"Bonnet",
		Vector3.new(7.4, 2, 3.6),
		CFrame.new(0, 0.4, -11.1),
		paint,
		{ Material = Palette.Material.Metal }
	)
	attach(
		model,
		base,
		"Grille",
		Vector3.new(3.6, 1, 0.2),
		CFrame.new(0, 0.4, -12.95),
		trim,
		{ Material = Palette.Material.Metal, CanCollide = false }
	)
	attach(
		model,
		base,
		"Bumper",
		Vector3.new(7.8, 0.6, 0.6),
		CFrame.new(0, -0.5, -13.1),
		trim,
		{ Material = Palette.Material.Metal }
	)
	attach(
		model,
		base,
		"RearBumper",
		Vector3.new(7.4, 0.5, 0.5),
		CFrame.new(0, -0.5, 5.5),
		trim,
		{ Material = Palette.Material.Metal, CanCollide = false }
	)
	local handle = attach(
		model,
		base,
		"Handle",
		Vector3.new(0.5, 0.5, 2.6),
		CFrame.new(0, -0.4, -14.6),
		trim,
		{ Material = Palette.Material.Metal }
	)
	for _, offset in
		{
			Vector3.new(-3.6, -0.9, -10.8),
			Vector3.new(3.6, -0.9, -10.8),
			Vector3.new(-3.6, -0.9, 2.6),
			Vector3.new(3.6, -0.9, 2.6),
		}
	do
		wheel(model, base, "Wheel", offset, 2.6, 1)
	end
	return handle
end

-- Exotic: a giant ridged spiral shell on wheels, its open mouth the load space.
function builders.ShellWagon(model: Model, at: CFrame)
	local shell = Color3.fromRGB(240, 220, 190)
	local ridge = Color3.fromRGB(225, 160, 140)
	local base = tray(model, at * CFrame.new(0, 1.5, 0), Vector3.new(5, 0, 9), 1.4, shell)
	dress(model, { Material = Palette.Material.Smooth, Reflectance = 0.1 })
	-- Ridges ribbing both sides.
	for side = -1, 1, 2 do
		for _, z in { -3.4, -1.7, 0, 1.7, 3.4 } do
			attach(
				model,
				base,
				"Ridge",
				Vector3.new(0.4, 1.9, 0.5),
				CFrame.new(side * 2.95, 0.6, z) * CFrame.Angles(0, 0, math.rad(side * -10)),
				ridge,
				{ Material = Palette.Material.Smooth, CanCollide = false }
			)
		end
	end
	-- Flared pink lip around the mouth at the front.
	attach(
		model,
		base,
		"Lip",
		Vector3.new(6.4, 0.4, 0.8),
		CFrame.new(0, 1.5, -4.7) * CFrame.Angles(math.rad(25), 0, 0),
		Color3.fromRGB(245, 170, 175),
		{ Material = Palette.Material.Smooth, CanCollide = false }
	)
	-- The spiral: whorls shrinking and climbing at the back.
	local whorls = {
		{ 4.4, Vector3.new(0, 1.4, 5.4) },
		{ 3.4, Vector3.new(0.8, 3, 5.6) },
		{ 2.5, Vector3.new(0.1, 4.3, 5.1) },
		{ 1.7, Vector3.new(-0.6, 5.2, 5.5) },
		{ 1.1, Vector3.new(-0.1, 5.9, 5.9) },
	}
	for index, whorl in whorls do
		attach(
			model,
			base,
			"Whorl",
			Vector3.new(whorl[1], whorl[1], whorl[1]),
			CFrame.new(whorl[2]),
			if index % 2 == 0 then ridge else shell,
			{
				Shape = Enum.PartType.Ball,
				Material = Palette.Material.Smooth,
				Reflectance = 0.1,
				CanCollide = false,
			}
		)
	end
	local handle = attach(
		model,
		base,
		"Handle",
		Vector3.new(0.4, 0.4, 3),
		CFrame.new(0, 0.6, -6.4),
		Color3.fromRGB(200, 180, 120),
		{ Material = Palette.Material.Fabric }
	)
	for _, offset in
		{
			Vector3.new(-3.3, -0.7, -3),
			Vector3.new(3.3, -0.7, -3),
			Vector3.new(-3.3, -0.7, 3),
			Vector3.new(3.3, -0.7, 3),
		}
	do
		wheel(model, base, "Wheel", offset, 1.6, 0.6)
	end
	return handle
end

-- Exotic: an icy sled on curled runners, sliding on hidden skids.
function builders.FrostSled(model: Model, at: CFrame)
	local ice = Color3.fromRGB(170, 215, 240)
	local snow = Color3.fromRGB(245, 250, 255)
	local base = tray(model, at * CFrame.new(0, 1, 0), Vector3.new(4.6, 0, 9), 1, ice)
	dress(model, { Material = Palette.Material.Glass, Transparency = 0.2, Reflectance = 0.2 })
	base.Color = snow
	base.Transparency = 0
	-- Snow caps along the side walls.
	for side = -1, 1, 2 do
		attach(
			model,
			base,
			"SnowCap",
			Vector3.new(0.6, 0.25, 9.6),
			CFrame.new(side * 2.45, 1.1, 0),
			snow,
			{ Material = Palette.Material.Smooth, CanCollide = false }
		)
		attach(
			model,
			base,
			"Runner",
			Vector3.new(0.3, 0.5, 10.4),
			CFrame.new(side * 2, -0.55, 0),
			Color3.fromRGB(120, 170, 210),
			{ Material = Palette.Material.Metal, Reflectance = 0.3, CanCollide = false }
		)
		attach(
			model,
			base,
			"RunnerCurl",
			Vector3.new(0.3, 0.5, 2),
			CFrame.new(side * 2, 0, -5.6) * CFrame.Angles(math.rad(50), 0, 0),
			Color3.fromRGB(120, 170, 210),
			{ Material = Palette.Material.Metal, Reflectance = 0.3, CanCollide = false }
		)
		for _, z in { -3, 0, 3 } do
			attach(
				model,
				base,
				"Strut",
				Vector3.new(0.25, 0.5, 0.25),
				CFrame.new(side * 2, -0.25, z),
				Color3.fromRGB(120, 170, 210),
				{ Material = Palette.Material.Metal, CanCollide = false }
			)
		end
		-- Icicles under the sides.
		for _, z in { -3.6, -1.2, 1.2, 3.6 } do
			attach(
				model,
				base,
				"Icicle",
				Vector3.new(0.2, 0.6, 0.2),
				CFrame.new(side * 2.75, -0.35, z),
				ice,
				{ Material = Palette.Material.Glass, Transparency = 0.2, CanCollide = false, Massless = true }
			)
		end
	end
	local handle = attach(
		model,
		base,
		"Handle",
		Vector3.new(0.5, 0.5, 2.6),
		CFrame.new(0, 0.8, -6.3),
		Color3.fromRGB(230, 240, 250),
		{ Material = Palette.Material.Fabric }
	)
	skids(model, base, {
		Vector3.new(-2, -0.6, -3.5),
		Vector3.new(2, -0.6, -3.5),
		Vector3.new(-2, -0.6, 0),
		Vector3.new(2, -0.6, 0),
		Vector3.new(-2, -0.6, 3.5),
		Vector3.new(2, -0.6, 3.5),
	}, 0.8)
	return handle
end

-- Exotic follower: a wobbly translucent jelly raft trailing tentacles, glowing softly.
function builders.JellyRaft(model: Model, at: CFrame)
	local jelly = Color3.fromRGB(230, 140, 220)
	local glowColor = Color3.fromRGB(255, 170, 250)
	local base = tray(model, at * CFrame.new(0, 3, 0), Vector3.new(5.4, 0, 6.4), 0.8, jelly)
	dress(model, { Material = Palette.Material.Glass, Transparency = 0.35 })
	attach(model, base, "Bell", Vector3.new(7, 1.6, 8), CFrame.new(0, -0.7, 0), jelly, {
		Shape = Enum.PartType.Ball,
		Material = Palette.Material.Glass,
		Transparency = 0.45,
		CanCollide = false,
	})
	for index = 1, 8 do
		local angle = (index / 8) * math.pi * 2
		local x, z = math.cos(angle) * 2.6, math.sin(angle) * 3
		attach(
			model,
			base,
			"Tentacle",
			Vector3.new(0.25, 2.6, 0.25),
			CFrame.new(x, -2.4, z) * CFrame.Angles(math.rad(z * 4), 0, math.rad(-x * 4)),
			jelly,
			{ Material = Palette.Material.Glass, Transparency = 0.3, CanCollide = false, Massless = true }
		)
		attach(
			model,
			base,
			"GlowSpot",
			Vector3.new(0.4, 0.4, 0.4),
			CFrame.new(x * 1.05, 0.85, z * 1.05),
			glowColor,
			{
				Shape = Enum.PartType.Ball,
				Material = Palette.Material.Neon,
				CanCollide = false,
				Massless = true,
			}
		)
	end
	local glow = Instance.new("PointLight")
	glow.Color = glowColor
	glow.Range = 10
	glow.Parent = base
	return followerHandle(model, base)
end

-- Exotic follower: a flat patterned carpet with gold tassels; the cargo rides on it.
function builders.MagicCarpet(model: Model, at: CFrame)
	local red = Color3.fromRGB(150, 30, 50)
	local gold = Color3.fromRGB(230, 185, 70)
	local blue = Color3.fromRGB(40, 60, 140)
	local base = tray(model, at * CFrame.new(0, 3, 0), Vector3.new(5, 0, 7), 0.3, red)
	dress(model, { Material = Palette.Material.Fabric })
	local flat = { Material = Palette.Material.Fabric, CanCollide = false, Massless = true }
	-- Woven pattern: a gold border, a blue inner band and a medallion in the middle.
	for side = -1, 1, 2 do
		attach(
			model,
			base,
			"Border",
			Vector3.new(0.3, 0.05, 6.4),
			CFrame.new(side * 2.1, 0.17, 0),
			gold,
			flat
		)
		attach(
			model,
			base,
			"Border",
			Vector3.new(4.5, 0.05, 0.3),
			CFrame.new(0, 0.17, side * 3.05),
			gold,
			flat
		)
		attach(model, base, "Band", Vector3.new(0.25, 0.05, 5), CFrame.new(side * 1.5, 0.17, 0), blue, flat)
		attach(model, base, "Band", Vector3.new(3.2, 0.05, 0.25), CFrame.new(0, 0.17, side * 2.4), blue, flat)
	end
	attach(
		model,
		base,
		"Medallion",
		Vector3.new(0.06, 1.8, 1.8),
		CFrame.new(0, 0.17, 0) * CFrame.Angles(0, 0, math.rad(90)),
		gold,
		{
			Shape = Enum.PartType.Cylinder,
			Material = Palette.Material.Fabric,
			CanCollide = false,
			Massless = true,
		}
	)
	-- Tassels hanging off the front and back edges.
	for _, z in { -3.9, 3.9 } do
		for index = 0, 4 do
			attach(
				model,
				base,
				"Tassel",
				Vector3.new(0.2, 0.2, 0.7),
				CFrame.new(-2.2 + index * 1.1, -0.05, z),
				gold,
				{ Material = Palette.Material.Fabric, CanCollide = false, Massless = true }
			)
		end
	end
	return followerHandle(model, base)
end

-- Exotic follower: a glass swan boat. The cargo rides in its back, the curved neck rises at
-- the front.
function builders.GlassSwan(model: Model, at: CFrame)
	local glass = Color3.fromRGB(200, 235, 245)
	local glassProps = { Material = Palette.Material.Glass, Transparency = 0.3, Reflectance = 0.2 }
	local base = tray(model, at * CFrame.new(0, 2.2, 0), Vector3.new(5, 0, 7.4), 1.3, glass)
	dress(model, glassProps)
	local function piece(name: string, size: Vector3, offset: CFrame, ball: boolean?)
		return attach(model, base, name, size, offset, glass, {
			Shape = if ball then Enum.PartType.Ball else Enum.PartType.Block,
			Material = Palette.Material.Glass,
			Transparency = 0.3,
			Reflectance = 0.2,
			CanCollide = false,
		})
	end
	piece("Hull", Vector3.new(6.6, 2, 9.6), CFrame.new(0, -0.95, 0), true)
	for side = -1, 1, 2 do
		piece(
			"Wing",
			Vector3.new(0.4, 1.8, 6.4),
			CFrame.new(side * 3.05, 1.1, 0.6) * CFrame.Angles(math.rad(-12), 0, math.rad(side * -18))
		)
	end
	piece("Tail", Vector3.new(2.4, 0.4, 2), CFrame.new(0, 1.2, 4.6) * CFrame.Angles(math.rad(-35), 0, 0))
	-- Neck: an S-curve of shrinking glass beads rising from the bow.
	local segments = 8
	for index = 0, segments do
		local t = index / segments
		local size = 1.1 - t * 0.35
		piece(
			"Neck",
			Vector3.new(size, size, size),
			CFrame.new(0, 0.8 + t * 4.6, -4.4 - math.sin(t * math.pi) * 1.3 + t * 0.2),
			true
		)
	end
	piece("Head", Vector3.new(1.2, 1.1, 1.5), CFrame.new(0, 5.7, -4.6), true)
	attach(
		model,
		base,
		"Beak",
		Vector3.new(0.4, 0.35, 1),
		CFrame.new(0, 5.55, -5.6) * CFrame.Angles(math.rad(-15), 0, 0),
		Color3.fromRGB(255, 170, 90),
		{ Material = Palette.Material.Glass, Transparency = 0.2, CanCollide = false }
	)
	for side = -1, 1, 2 do
		attach(
			model,
			base,
			"Eye",
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(side * 0.55, 5.9, -4.9),
			Color3.fromRGB(30, 40, 60),
			{ Shape = Enum.PartType.Ball, Material = Palette.Material.Smooth, CanCollide = false }
		)
	end
	return followerHandle(model, base)
end

function VesselService.getVessel(player: Player): Model?
	local vessel = vesselOf[player]
	if vessel and vessel.Parent then
		return vessel
	end
	return nil
end

-- The kind of the vessel with this id (items carry their vessel's VesselId), if it's out.
function VesselService.kindOfId(vesselId: string?): string?
	for _, vessel in vesselOf do
		if vessel.Parent and vessel:GetAttribute("VesselId") == vesselId then
			return vessel:GetAttribute("Kind")
		end
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
	local columns = math.min(if capacity > 24 then 4 else 2, capacity) -- (the Leviathan's hold is wide)
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
	player:SetAttribute("Riding", nil)
	if not vessel then
		return
	end
	lastPosition[vessel] = nil
	lastScoop[vessel] = nil
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
	params.FilterDescendantsInstances = { Workspace.Map, Workspace.Terrain }
	local hit = Workspace:Raycast(Beach.rayFrom(spot, 30), Vector3.new(0, -120, 0), params)
	local groundY = if hit then hit.Position.Y else Beach.groundAt(spot.X, spot.Z)
	local ground = Vector3.new(spot.X, groundY, spot.Z)
	if Beach.isDeep(ground, Tide.sea()) then
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
	model:SetAttribute("Stability", def.Stability or stability[def.Id] or 1)
	-- Magical vessels and exotic followers move by themselves behind their owner.
	model:SetAttribute("Hover", def.Magical == true or def.Follows == true)
	model:SetAttribute("Swims", def.Swims == true)
	model:SetAttribute("Flies", def.Flies == true)
	model:SetAttribute("Boat", def.Boat == true)
	model:SetAttribute("Rides", def.Rides == true)
	model:SetAttribute("Ridden", false)
	model:SetAttribute("Unspillable", def.Unspillable == true)
	model:SetAttribute("Speed", def.Speed or 1)
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
	if def.Ghost then
		VesselService.makeGhost(model)
	end
	local prompt = model:FindFirstChild("BoardPrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.Triggered:Connect(function(who: Player)
			if who == player then
				VesselService.toggleBoard(player)
			end
		end)
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

local function humanoidOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil, nil
	end
	return humanoid, root
end

-- Whether the player is sitting at the helm of their boat.
function VesselService.isRiding(player: Player): boolean
	local vessel = vesselOf[player]
	local humanoid = humanoidOf(player)
	local helm = vessel and vessel:FindFirstChild("Helm")
	return humanoid ~= nil and helm ~= nil and humanoid.SeatPart == helm
end

-- Boards the player's boat (over deep water, close by) or, if they're already aboard, leaves it.
function VesselService.toggleBoard(player: Player): (boolean, string?)
	local vessel = VesselService.getVessel(player)
	local helm = vessel and vessel:FindFirstChild("Helm") :: Seat?
	if not vessel or not helm or not vessel.PrimaryPart then
		return false, "You don't have a boat out"
	end
	local humanoid, root = humanoidOf(player)
	if not humanoid or not root then
		return false, "You can't board right now"
	end
	if humanoid.SeatPart == helm then
		humanoid.Sit = false
		return true, "left"
	end
	local base = vessel.PrimaryPart
	local ok, reason = VesselPowers.canBoard(
		(base.Position - root.Position).Magnitude,
		Beach.isDeep(base.Position, Tide.sea())
	)
	if not ok then
		notify(player, reason or "Can't board")
		return false, reason
	end
	helm:Sit(humanoid)
	vessel:SetAttribute("Ridden", true)
	player:SetAttribute("Riding", true)
	return true, "boarded"
end

-- Keeps a boat's riding state true to the seat: no rider (they jumped off, died, were
-- teleported) or a boat that has left the water clears it; a boat moving faster than a boat can
-- is put back where it was and the rider let go.
local function tickRider(player: Player, vessel: Model, base: BasePart, sea: number)
	if vessel:GetAttribute("Rides") ~= true then
		return
	end
	local riding = VesselService.isRiding(player)
	local humanoid = humanoidOf(player)
	if riding and humanoid and Beach.depthAt(base.Position, sea) <= 0 then
		humanoid.Sit = false -- aground: they stand and tow it as usual
		riding = false
		notify(player, "Your boat ran aground")
	end
	vessel:SetAttribute("Ridden", riding)
	player:SetAttribute("Riding", if riding then true else nil)
	if not riding then
		lastPosition[vessel] = nil
		return
	end
	local now = os.clock()
	local last = lastPosition[vessel]
	if last then
		local moved = Vector3.new(base.Position.X - last.at.X, 0, base.Position.Z - last.at.Z).Magnitude
		local speedOk = VesselPowers.boatSpeedOk(
			vessel:GetAttribute("Kind"),
			Stats.vesselSpeed(player),
			moved,
			now - last.time
		)
		if not speedOk then
			vessel:PivotTo(CFrame.new(last.at) * base.CFrame.Rotation)
			base.AssemblyLinearVelocity = Vector3.zero
			if humanoid then
				humanoid.Sit = false
			end
			lastPosition[vessel] = nil
			notify(player, "Your boat can't go that fast")
			return
		end
	end
	lastPosition[vessel] = { at = base.Position, time = now }
end

-- The Magic Carpet stays within a leash of its owner whatever happens to it.
local function tickLeash(player: Player, vessel: Model, base: BasePart)
	local _, root = humanoidOf(player)
	if not root or not VesselPowers.ghost(vessel:GetAttribute("Kind")) then
		return
	end
	local target = VesselPowers.leashed(base.Position, root.Position, Config.Grab.CarpetLeash)
	if target ~= base.Position then
		vessel:PivotTo(base.CFrame.Rotation + target)
		base.AssemblyLinearVelocity = Vector3.zero
	end
end

local function tick()
	local sea = Tide.sea()
	for player, vessel in vesselOf do
		local base = vessel.PrimaryPart
		if not base or not vessel.Parent then
			destroyVessel(player, nil)
			continue
		end
		-- Swimming and flying vessels, and boats, survive deep water.
		local flies = vessel:GetAttribute("Flies") == true
		local boat = vessel:GetAttribute("Boat") == true
		local unspillable = vessel:GetAttribute("Unspillable") == true
		-- The Shell Wagon floats like a shell: the sea never takes it or what it holds.
		local swims = vessel:GetAttribute("Swims") == true or boat or unspillable
		tickRider(player, vessel, base, sea)
		tickLeash(player, vessel, base)
		if swims and not unspillable and Beach.isDeep(base.Position, sea) then
			-- Swimming vessels survive deep water, but the waves can wash cargo off.
			local def = Gear.getVessel(vessel:GetAttribute("Kind"))
			if
				math.random()
				< Config.Grab.SwimWashChance * (if def and def.WashScale then def.WashScale else 1)
			then
				local contents = VesselService.contents(vessel)
				if #contents > 0 then
					ItemService.setLoose(contents[math.random(#contents)])
					notify(player, "A wave washed something off your vessel!")
				end
			end
		end
		if
			(not swims and not flies and Beach.isDeep(base.Position, sea))
			or base.Position.Y < Beach.groundY(base.Position.Z) - 30
		then
			destroyVessel(
				player,
				"Your vessel was lost to the water, along with everything in it. Spawn it again for free from your inventory (I)."
			)
			continue
		end
		-- A boat that flips over is lost (the doc's dinghy).
		if boat and not unspillable and base.CFrame.UpVector.Y < 0.25 then
			destroyVessel(player, "Your boat flipped over and sank, along with everything in it.")
			continue
		end
		-- Cargo is welded in, so it only comes out if the vessel actually tips over. The Shell
		-- Wagon never does: if it leans, it's stood upright where it is.
		if unspillable then
			if base.CFrame.UpVector.Y < 0.9 then
				local _, yaw = base.CFrame:ToOrientation()
				vessel:PivotTo(CFrame.new(base.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, yaw, 0))
				base.AssemblyAngularVelocity = Vector3.zero
			end
		elseif base.CFrame.UpVector.Y < 0.25 then
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

-- A boat's helm: an invisible seat over the deck (the owner sits in it to ride) with the prompt
-- that boards and leaves. Nothing walks onto it by touch; the server sits the owner in it.
local function addHelm(model: Model)
	local base = model.PrimaryPart :: BasePart
	local helm = Instance.new("Seat")
	helm.Name = "Helm"
	helm.Size = Vector3.new(2, 0.4, 2)
	helm.CFrame = base.CFrame * CFrame.new(0, 0.9, 1.5)
	helm.Transparency = 1
	helm.CanCollide = false
	helm.CanTouch = false
	helm.CanQuery = false
	helm.Massless = true
	helm.TopSurface = Enum.SurfaceType.Smooth
	helm.BottomSurface = Enum.SurfaceType.Smooth
	helm.Parent = model
	weld(base, helm)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BoardPrompt"
	prompt.ActionText = "Board"
	prompt.ObjectText = "Boat"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.B -- (E is the Anchor Hook's)
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = Config.Grab.BoardRange
	prompt.Parent = helm
end

-- For the data validator and tools/tests.
-- The builders above make each vessel's bare shape; VesselTrim paints and trims it.
for kind, build in builders do
	builders[kind] = function(model: Model, at: CFrame)
		local handle = build(model, at)
		VesselTrim.apply(model, kind)
		if VesselPowers.rides(kind) then
			addHelm(model)
		end
		return handle
	end
end

-- The Magic Carpet flies on a straight line, so nothing of it collides with the map.
function VesselService.makeGhost(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
		end
	end
end

VesselService._builders = builders

-- The Jelly Raft's scoop: if the raft has room and its interval is up, claims the nearest free
-- item within range for its owner through GrabService.canClaim (the owner's tool tier and lift),
-- and loads it. Returns the item scooped.
function VesselService.scoop(player: Player, now: number): BasePart?
	local vessel = VesselService.getVessel(player)
	local base = vessel and vessel.PrimaryPart
	local def = vessel and Gear.getVessel(vessel:GetAttribute("Kind"))
	if not vessel or not base or not def or not def.Scoops then
		return nil
	end
	local held = #VesselService.contents(vessel)
	local capacity = vessel:GetAttribute("Capacity") or 0
	local since = now - (lastScoop[vessel] or -math.huge)
	if held >= capacity or since < Config.Grab.ScoopInterval then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for item in ItemService.all() do
		if ItemService.getState(item) == "Unclaimed" then
			local distance = (item.Position - base.Position).Magnitude
			if distance < bestDistance and VesselPowers.canScoop(distance, held, capacity, since) then
				best, bestDistance = item, distance
			end
		end
	end
	if not best then
		return nil
	end
	-- (Required here: GrabService requires this module.)
	local GrabService = require(script.Parent.GrabService)
	local tool = Gear.getTool(player:GetAttribute("Tool"))
	local ok = GrabService.canClaim(
		best,
		player.UserId,
		{ Name = "Jelly Raft", Reach = Config.Grab.ScoopRange, Tier = tool.Tier },
		Stats.lift(player, tool),
		base.Position
	)
	if not ok then
		return nil
	end
	lastScoop[vessel] = now
	ItemService.setHeld(best, player)
	if not VesselService.load(player, best) then
		ItemService.setLoose(best)
		return nil
	end
	return best
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

	task.spawn(function()
		while true do
			task.wait(Config.Grab.ScoopInterval / 2)
			for player, vessel in vesselOf do
				if vessel.Parent and vessel:GetAttribute("Kind") == "JellyRaft" then
					VesselService.scoop(player, os.clock())
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		destroyVessel(player, nil)
	end)
end

return VesselService
