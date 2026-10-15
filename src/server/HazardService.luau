-- Builds and runs a biome's hazards on a tile, from its data (Biomes.List[id].Hazards, see
-- Hazards.luau). Where they go comes from the tile's layout when it places them, otherwise
-- they're scattered over the tile. Everything is built into the tile's folder, so a hazard
-- stops when the folder goes (the biome changed). The part each hazard hits with is tagged
-- Hazards.Tag with its Effect, HitRadius, Push, HitText (and Factor, Active): each player's
-- client checks itself against those (HazardController).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Hazards = require(Shared.Hazards)
local Layouts = require(Shared.Layouts)
local Palette = require(Shared.Palette)
local Tide = require(Shared.Tide)

local CollisionGroups = require(script.Parent.CollisionGroups)

local HazardService = {}

local rng = Random.new()

type Running = {
	folder: Instance,
	step: (now: number, dt: number) -> (),
}

local running: { Running } = {}

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

-- Marks the part a hazard hits with.
local function arm(part: BasePart, settings: { [string]: any })
	part:SetAttribute("Effect", settings.Effect)
	part:SetAttribute("HitRadius", settings.HitRadius)
	part:SetAttribute("Push", settings.Push)
	part:SetAttribute("HitText", settings.HitText)
	if settings.Factor then
		part:SetAttribute("Factor", settings.Factor)
	end
	CollectionService:AddTag(part, Hazards.Tag)
end

-- A random spot on the tile, clear of its edges.
local function randomSpot(tile: number): (number, number)
	local z0, z1 = Beach.tileRange(tile)
	return rng:NextNumber(-Beach.HalfWidth + 40, Beach.HalfWidth - 40), rng:NextNumber(z0 + 15, z1 - 15)
end

-- A point along a path (a list of world X/Z points) at a distance from its start, going back
-- and forth: returns the point and the direction it's heading.
function HazardService.alongPath(path: { Vector2 }, distance: number): (Vector2, Vector2)
	local lengths, total = {}, 0
	for i = 1, #path - 1 do
		lengths[i] = (path[i + 1] - path[i]).Magnitude
		total += lengths[i]
	end
	if total <= 0 then
		return path[1], Vector2.new(0, 1)
	end
	local d = distance % (2 * total)
	local forward = d <= total
	if not forward then
		d = 2 * total - d
	end
	for i = 1, #path - 1 do
		if d <= lengths[i] or i == #path - 1 then
			local t = if lengths[i] > 0 then math.clamp(d / lengths[i], 0, 1) else 0
			local dir = (path[i + 1] - path[i]).Unit
			return path[i]:Lerp(path[i + 1], t), if forward then dir else -dir
		end
		d -= lengths[i]
	end
	return path[#path], Vector2.new(0, 1)
end

local builders: { [string]: (tile: number, settings: { [string]: any }, folder: Instance) -> () } = {}

-- Roller: something rolls down the tile toward the sea every Period seconds.
function builders.Roller(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local lanes = {}
	for _, placement in Layouts.hazardPlacements(tile, "Roller") do
		for _, x in placement.Lanes do
			table.insert(lanes, x)
		end
	end
	local nextAt = os.clock() + rng:NextNumber(0, settings.Period)
	local function roll()
		local fromZ = math.max(z0 + 5, 1)
		if Beach.isDeep(Vector3.new(0, 0, fromZ), Tide.sea()) then
			return -- the top of the tile is under water: nothing to roll down
		end
		local x = if #lanes > 0
			then lanes[rng:NextInteger(1, #lanes)]
			else rng:NextNumber(-Beach.HalfWidth + 20, Beach.HalfWidth - 20)
		local size: Vector3 = settings.Size
		local roller = makePart({
			Name = "Roller",
			Shape = Enum.PartType.Cylinder,
			Size = size, -- the axis along X, so it rolls toward the sea
			CFrame = CFrame.new(x, Beach.groundAt(x, fromZ) + size.Y / 2 + 0.3, fromZ),
			Color = settings.Color,
			Material = Palette.Material.Wood,
			Anchored = false,
			CanCollide = true,
			CustomPhysicalProperties = PhysicalProperties.new(2, 0.3, 0.2),
		})
		roller.CollisionGroup = CollisionGroups.Items
		roller.AssemblyLinearVelocity = Vector3.new(0, 0, settings.Speed)
		roller.AssemblyAngularVelocity = Vector3.new(settings.Speed / (size.Y / 2), 0, 0)
		arm(roller, settings)
		roller.Parent = folder
		pcall(roller.SetNetworkOwner, roller, nil)
		task.delay(12, function()
			roller:Destroy()
		end)
	end
	table.insert(running, {
		folder = folder,
		step = function(now)
			if now >= nextAt then
				nextAt = now + settings.Period
				roll()
			end
		end,
	})
end

-- A creature: a shell on a body with two claws. The body is what hits.
local function creature(settings, at: Vector3): (Model, BasePart)
	local size: Vector3 = settings.Size
	local model = Instance.new("Model")
	model.Name = "Creature"
	local body = makePart({
		Name = "Body",
		Size = Vector3.new(size.X * 0.8, size.Y * 0.4, size.Z * 0.8),
		CFrame = CFrame.new(at + Vector3.new(0, -size.Y * 0.25, 0)),
		Color = settings.Color,
	})
	body.Parent = model
	local shell = makePart({
		Name = "Shell",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(size.X, size.X, size.X),
		CFrame = CFrame.new(at + Vector3.new(0, size.Y * 0.15, size.Z * 0.15)),
		Color = settings.Color:Lerp(Color3.new(1, 1, 1), 0.55),
		Material = Palette.Material.Smooth,
	})
	shell.Parent = model
	for _, side in { -1, 1 } do
		local claw = makePart({
			Name = "Claw",
			Size = Vector3.new(size.X * 0.25, size.Y * 0.25, size.Z * 0.35),
			CFrame = CFrame.new(at + Vector3.new(side * size.X * 0.35, -size.Y * 0.2, -size.Z * 0.55)),
			Color = settings.Color,
		})
		claw.Parent = model
	end
	model.PrimaryPart = body
	arm(body, settings)
	return model, body
end

-- Patrol: creatures walk a route back and forth, or wander around where they start.
function builders.Patrol(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local size: Vector3 = settings.Size
	local function place(model: Model, at: Vector2, heading: Vector2)
		local ground = Beach.groundAt(at.X, at.Y)
		local position = Vector3.new(at.X, ground + size.Y / 2, at.Y)
		local look = Vector3.new(heading.X, 0, heading.Y)
		model:PivotTo(
			CFrame.lookAt(position, position + (if look.Magnitude > 0 then look else Vector3.zAxis))
		)
	end
	local placements = Layouts.hazardPlacements(tile, "Patrol")
	local walkers = {}
	if #placements > 0 then
		for _, placement in placements do
			local path = {}
			for _, point in placement.Path do
				table.insert(path, Vector2.new(point[1], z0 + point[2]))
			end
			local count = placement.Count or settings.Count
			local length = 0
			for i = 1, #path - 1 do
				length += (path[i + 1] - path[i]).Magnitude
			end
			for i = 1, count do
				local model = creature(settings, Vector3.new(path[1].X, 0, path[1].Y))
				model.Parent = folder
				-- Spread out along the route, coming and going.
				table.insert(walkers, { model = model, path = path, offset = 2 * length * (i - 1) / count })
			end
		end
	else
		for _ = 1, settings.Count do
			local x, z = randomSpot(tile)
			local model = creature(settings, Vector3.new(x, 0, z))
			model.Parent = folder
			local home = Vector2.new(x, z)
			table.insert(walkers, { model = model, home = home, at = home, target = home })
		end
	end
	local started = os.clock()
	table.insert(running, {
		folder = folder,
		step = function(now, dt)
			for _, walker in walkers do
				if walker.path then
					local at, heading =
						HazardService.alongPath(walker.path, walker.offset + (now - started) * settings.Speed)
					place(walker.model, at, heading)
				else
					local toTarget = walker.target - walker.at
					if toTarget.Magnitude < 1 then
						local angle = rng:NextNumber(0, 2 * math.pi)
						local reach = rng:NextNumber(0, settings.Wander)
						walker.target = walker.home + Vector2.new(math.cos(angle), math.sin(angle)) * reach
					else
						local stepLength = math.min(toTarget.Magnitude, settings.Speed * dt)
						walker.at += toTarget.Unit * stepLength
						place(walker.model, walker.at, toTarget.Unit)
					end
				end
			end
		end,
	})
end

-- Pulse: a spot erupts for Active seconds every Period, after a warning.
function builders.Pulse(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local spots = {}
	for _, placement in Layouts.hazardPlacements(tile, "Pulse") do
		table.insert(spots, Vector2.new(placement.At[1], z0 + placement.At[2]))
	end
	if #spots == 0 then
		for _ = 1, settings.Count do
			local x, z = randomSpot(tile)
			table.insert(spots, Vector2.new(x, z))
		end
	end
	local vents = {}
	for _, spot in spots do
		local ground = Beach.groundAt(spot.X, spot.Y)
		local radius = settings.Radius
		local vent = makePart({
			Name = "Vent",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, radius * 2, radius * 2),
			CFrame = CFrame.new(spot.X, ground + 0.1, spot.Y) * CFrame.Angles(0, 0, math.pi / 2),
			Color = settings.Color:Lerp(Color3.new(0, 0, 0), 0.5),
			Material = Palette.Material.Rock,
		})
		local plume = makePart({
			Name = "Plume",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(14, radius * 1.6, radius * 1.6),
			CFrame = CFrame.new(spot.X, ground + 7, spot.Y) * CFrame.Angles(0, 0, math.pi / 2),
			Color = settings.Color,
			Material = Palette.Material.Smooth,
			Transparency = 1,
		})
		arm(vent, settings)
		vent:SetAttribute("Active", false)
		vent.Parent = folder
		plume.Parent = folder
		-- Not all in step, so the way through changes.
		table.insert(vents, { vent = vent, plume = plume, offset = rng:NextNumber(0, settings.Period) })
	end
	local calm = settings.Color:Lerp(Color3.new(0, 0, 0), 0.5)
	local warning = settings.Color:Lerp(Color3.fromRGB(255, 140, 60), 0.6)
	table.insert(running, {
		folder = folder,
		step = function(now)
			for _, v in vents do
				local t = (now + v.offset) % settings.Period
				local active = t >= settings.Period - settings.Active
				local warned = not active and t >= settings.Period - settings.Active - settings.Warning
				if v.vent:GetAttribute("Active") ~= active then
					v.vent:SetAttribute("Active", active)
					v.plume.Transparency = if active then 0.35 else 1
				end
				local color = if warned or active then warning else calm
				if v.vent.Color ~= color then
					v.vent.Color = color
				end
			end
		end,
	})
end

-- Slow: patches that slow you while you're in them.
function builders.Slow(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local patches = {}
	for _, placement in Layouts.hazardPlacements(tile, "Slow") do
		table.insert(patches, { x = placement.At[1], z = z0 + placement.At[2], radius = placement.Radius })
	end
	if #patches == 0 then
		for _ = 1, settings.Count do
			local x, z = randomSpot(tile)
			table.insert(patches, { x = x, z = z })
		end
	end
	for _, patch in patches do
		local radius = patch.radius or settings.Radius
		local part = makePart({
			Name = "SlowPatch",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.2, radius * 2, radius * 2),
			CFrame = CFrame.new(patch.x, Beach.groundAt(patch.x, patch.z) + 0.08, patch.z)
				* CFrame.Angles(0, 0, math.pi / 2),
			Color = settings.Color,
			Material = Palette.Material.Glass,
			Transparency = 0.3,
		})
		arm(part, settings)
		part:SetAttribute("HitRadius", radius)
		part.Parent = folder
	end
end

HazardService.Builders = builders

-- Builds a biome's hazards on a tile into its folder.
function HazardService.start(tile: number, biome: any, folder: Instance)
	for _, entry in biome.Hazards or {} do
		local settings = Hazards.settings(entry)
		local build = builders[settings.Type]
		if build then
			build(tile, settings, folder)
		end
	end
end

function HazardService.init()
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for i = #running, 1, -1 do
			local entry = running[i]
			if not entry.folder.Parent then
				table.remove(running, i) -- the biome changed: its hazards went with its folder
			else
				local ok, err = pcall(entry.step, now, dt)
				if not ok then
					warn("[Hazards] " .. tostring(err))
					table.remove(running, i)
				end
			end
		end
	end)
end

-- For tools/tests: run every hazard one step.
function HazardService._step(now: number, dt: number)
	for _, entry in running do
		entry.step(now, dt)
	end
end

return HazardService
