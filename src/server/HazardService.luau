-- Builds and runs the hazards on a tile (a zone), from data (see Hazards.luau): its biome's,
-- or the plain zone's own. Where they go comes from the tile's layout when it places them,
-- otherwise they're scattered over the tile (unless the entry says Scatter = false). Everything is built into the tile's folder, so a hazard
-- stops when the folder goes (the biome changed). The part each hazard hits with is tagged
-- Hazards.Tag with its Effect, HitRadius, Push, HitText (and Factor, Active): each player's
-- client checks itself against those (HazardController).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Gear = require(Shared.Gear)
local Hazards = require(Shared.Hazards)
local Layouts = require(Shared.Layouts)
local Looks = require(Shared.Looks)
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)
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
	if settings.Damage then
		part:SetAttribute("Damage", settings.Damage)
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
				place(model, path[1], Vector2.new(0, 1)) -- on the ground from the start
				model.Parent = folder
				-- Spread out along the route, coming and going.
				table.insert(walkers, { model = model, path = path, offset = 2 * length * (i - 1) / count })
			end
		end
	else
		for _ = 1, settings.Count do
			local x, z = randomSpot(tile)
			local model = creature(settings, Vector3.new(x, 0, z))
			place(model, Vector2.new(x, z), Vector2.new(0, 1))
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
	if #spots == 0 and settings.Scatter then
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
	if #patches == 0 and settings.Scatter then
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

-- The spots a layout places a kind at, in world X/Z (and each placement), or, with none and
-- Scatter set, Count random spots.
local function spotsFor(tile: number, kind: string, settings): { { x: number, z: number, placement: any } }
	local z0 = Beach.tileRange(tile)
	local spots = {}
	for _, placement in Layouts.hazardPlacements(tile, kind) do
		if placement.At then
			table.insert(spots, { x = placement.At[1], z = z0 + placement.At[2], placement = placement })
		end
	end
	if #spots == 0 and settings.Scatter then
		for _ = 1, settings.Count do
			local x, z = randomSpot(tile)
			table.insert(spots, { x = x, z = z, placement = {} })
		end
	end
	return spots
end

-- Sink: sinking sand. An irregular patch of dark, wet sand (a blob of round lobes, each a hazard
-- part) that slows you, stops you jumping and swallows you (HazardController), with the odd
-- bubble rising out of it.
function builders.Sink(tile, settings, folder)
	for _, spot in spotsFor(tile, "Sink", settings) do
		local radius = spot.placement.Radius or settings.Radius
		local shape = Random.new(math.floor(spot.x * 31 + spot.z * 17))
		local lobes = { { 0, 0, radius * 0.7 } }
		for k = 1, settings.Lobes do
			local angle = (k / settings.Lobes + shape:NextNumber(-0.12, 0.12)) * math.pi * 2
			local reach = radius * shape:NextNumber(0.4, 0.55)
			table.insert(
				lobes,
				{ math.cos(angle) * reach, math.sin(angle) * reach, radius * shape:NextNumber(0.4, 0.55) }
			)
		end
		for index, lobe in lobes do
			local x, z, r = spot.x + lobe[1], spot.z + lobe[2], lobe[3]
			local part = makePart({
				Name = "SinkingSand",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.2, r * 2, r * 2),
				CFrame = CFrame.new(x, Beach.groundAt(x, z) + 0.06 + index * 0.005, z)
					* CFrame.Angles(0, 0, math.pi / 2),
				Color = settings.Color,
				Material = Enum.Material.Mud,
				Reflectance = 0.12, -- a wet sheen: the tell
			})
			arm(part, settings)
			part:SetAttribute("HitRadius", r)
			part:SetAttribute("Factor", settings.Factor)
			part:SetAttribute("SinkTime", settings.SinkTime)
			part:SetAttribute("MovingShare", settings.MovingShare)
			part:SetAttribute(
				"Lethal",
				if spot.placement.Lethal ~= nil then spot.placement.Lethal else settings.Lethal
			)
			if index == 1 then
				local bubbles = Instance.new("ParticleEmitter")
				bubbles.Color = ColorSequence.new(settings.Color:Lerp(Color3.new(1, 1, 1), 0.25))
				bubbles.Size = NumberSequence.new(0.35, 0)
				bubbles.Lifetime = NumberRange.new(0.4, 0.8)
				bubbles.Rate = 3
				bubbles.Speed = NumberRange.new(0.5, 1.5)
				bubbles.EmissionDirection = Enum.NormalId.Right -- up, for a cylinder lying on its side
				bubbles.Shape = Enum.ParticleEmitterShape.Cylinder
				bubbles.Parent = part
			end
			part.Parent = folder
		end
	end
end

-- Rockfall: a stretch of roof that's coming down (see Hazards.luau). Old rubble strews the
-- area: that's the tell that it's dangerous. Boulders fall on a beat, sweeping along its open
-- ground and back, now and then where someone is standing (never ahead of them), with a burst
-- after a rumble; each is warned by trickling dust and its full-size shadow, then harms whoever
-- is right there and lies a while as a boulder to step round.
local ROCK_SLOTS = 10 -- boulders falling or lying at once, per area
local SWEEP_STEP = 6 -- studs between the spots the sweep drops on
local LYING = 0.6 -- a fallen boulder's size, as a share of the falling one's

function builders.Rockfall(tile, settings, folder)
	local areas = {}
	for _, spot in spotsFor(tile, "Rockfall", settings) do
		local radius = spot.placement.Radius or settings.Radius
		local ground = Beach.groundAt(spot.x, spot.z)
		local scatter = Random.new(math.floor(spot.x * 13 + spot.z * 7))
		-- The rubble: what has fallen before.
		for _ = 1, math.floor(radius * 0.9) do
			local angle, reach = scatter:NextNumber() * math.pi * 2, math.sqrt(scatter:NextNumber()) * radius
			local x, z = spot.x + math.cos(angle) * reach, spot.z + math.sin(angle) * reach
			local size = scatter:NextNumber(0.6, 1.8)
			if Beach.feature(x, z) >= 2 then
				continue -- on open ground only, not up the rock round it
			end
			makePart({
				Name = "Rubble",
				Size = Vector3.new(size, size * 0.6, size * scatter:NextNumber(0.7, 1.3)),
				CFrame = CFrame.new(x, Beach.groundAt(x, z) + size * 0.2, z) * CFrame.Angles(
					scatter:NextNumber(-0.4, 0.4),
					scatter:NextNumber() * math.pi,
					scatter:NextNumber(-0.4, 0.4)
				),
				Color = settings.Color,
				Material = Palette.Material.Rock,
			}).Parent =
				folder
		end
		local slots = {}
		for _ = 1, ROCK_SLOTS do
			local shadow = makePart({
				Name = "RockfallShadow",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.12, 1, 1),
				CFrame = CFrame.new(spot.x, ground - 20, spot.z),
				Color = Color3.new(0, 0, 0),
				Material = Enum.Material.SmoothPlastic,
				Transparency = 1,
			})
			arm(shadow, settings)
			shadow:SetAttribute("HitRadius", settings.RockRadius)
			shadow:SetAttribute("Active", false)
			shadow.Parent = folder
			local rock = makePart({
				Name = "FallingRock",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.7, 1.5, 1.7) * settings.RockRadius,
				CFrame = CFrame.new(spot.x, ground - 20, spot.z),
				Color = settings.Color,
				Material = Palette.Material.Rock,
				Transparency = 1,
			})
			local dust = Instance.new("ParticleEmitter")
			dust.Color = ColorSequence.new(settings.Color:Lerp(Color3.new(1, 1, 1), 0.4))
			dust.Size = NumberSequence.new(0.3, 0.1)
			dust.Lifetime = NumberRange.new(0.8, 1.2)
			dust.Rate = 40
			dust.Speed = NumberRange.new(5, 8)
			dust.SpreadAngle = Vector2.new(10, 10)
			dust.EmissionDirection = Enum.NormalId.Bottom
			dust.Enabled = false
			dust.Parent = rock
			rock.Parent = folder
			table.insert(slots, { shadow = shadow, rock = rock, size = rock.Size, dust = dust, start = nil })
		end
		-- The sweep: the open ground in the area (not the rock round it), ordered along the area's
		-- longer way, so falls walk along it and back.
		local open = {}
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for dx = -radius, radius, SWEEP_STEP do
			for dz = -radius, radius, SWEEP_STEP do
				local x, z = spot.x + dx, spot.z + dz
				if dx * dx + dz * dz <= radius * radius and Beach.feature(x, z) < 2 then
					table.insert(open, Vector2.new(x, z))
					minX, maxX = math.min(minX, x), math.max(maxX, x)
					minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
				end
			end
		end
		if #open == 0 then
			open = { Vector2.new(spot.x, spot.z) }
		end
		local alongX = maxX - minX >= maxZ - minZ
		table.sort(open, function(a, b)
			if alongX then
				return a.X < b.X or (a.X == b.X and a.Y < b.Y)
			end
			return a.Y < b.Y or (a.Y == b.Y and a.X < b.X)
		end)
		-- A haze of dust over the whole area: the rumble before a burst.
		local haze = makePart({
			Name = "RockfallRumble",
			Size = Vector3.new(radius * 2, 0.2, radius * 2),
			CFrame = CFrame.new(spot.x, (Beach.roofAt(spot.x, spot.z) or ground + 16) - 1, spot.z),
			Transparency = 1,
		})
		local rumble = Instance.new("ParticleEmitter")
		rumble.Color = ColorSequence.new(settings.Color:Lerp(Color3.new(1, 1, 1), 0.4))
		rumble.Size = NumberSequence.new(0.6, 0.2)
		rumble.Lifetime = NumberRange.new(1, 1.6)
		rumble.Rate = 60
		rumble.Speed = NumberRange.new(4, 7)
		rumble.EmissionDirection = Enum.NormalId.Bottom
		rumble.Enabled = false
		rumble.Parent = haze
		haze.Parent = folder
		table.insert(areas, {
			x = spot.x,
			z = spot.z,
			radius = radius,
			slots = slots,
			sweep = open,
			sweepAt = 1,
			sweepDir = 1,
			rumble = rumble,
			nextFall = 0,
			nextBurst = settings.BurstEvery,
		})
	end
	if #areas == 0 then
		return
	end
	-- The sweep's next spot: along the open ground and back again.
	local function nextSweep(area): Vector2
		local at = area.sweep[area.sweepAt]
		if #area.sweep > 1 then
			local nextAt = area.sweepAt + area.sweepDir
			if nextAt < 1 or nextAt > #area.sweep then
				area.sweepDir = -area.sweepDir
				nextAt = area.sweepAt + area.sweepDir
			end
			area.sweepAt = nextAt
		end
		return at
	end
	-- Where a rock will land: where someone inside is standing now (never ahead of them: moving
	-- away always works), or the sweep's next spot.
	local function pick(area, aimed: boolean): Vector2
		if aimed then
			local inside = {}
			for _, player in Players:GetPlayers() do
				local root = player.Character
					and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if
					root
					and (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(area.x, area.z)).Magnitude
						<= area.radius + 2
				then
					table.insert(inside, root)
				end
			end
			if #inside > 0 then
				local root = inside[rng:NextInteger(1, #inside)]
				return Vector2.new(root.Position.X, root.Position.Z)
			end
		end
		return nextSweep(area)
	end
	local function drop(area, now: number, delay: number, aimed: boolean)
		for _, slot in area.slots do
			if not slot.start then
				local at = pick(area, aimed)
				local ground = Beach.groundAt(at.X, at.Y)
				slot.start = now + delay
				slot.ground = ground
				slot.top = (Beach.roofAt(at.X, at.Y) or ground + 16) - 1.6
				slot.at = at
				return
			end
		end
	end
	local landing = settings.Warning + settings.Active
	table.insert(running, {
		folder = folder,
		step = function(now)
			for _, area in areas do
				if now >= area.nextFall then
					drop(area, now, 0, rng:NextNumber() < settings.Aimed)
					area.nextFall = now + settings.Interval
				end
				-- The rumble, then the burst along the sweep.
				area.rumble.Enabled = now >= area.nextBurst - settings.Rumble and now < area.nextBurst
				if now >= area.nextBurst then
					for k = 1, settings.Burst do
						drop(area, now, (k - 1) * 0.35, false)
					end
					area.nextBurst = now + settings.BurstEvery
				end
				for _, slot in area.slots do
					local start = slot.start
					if not start then
						continue
					end
					local t = now - start
					local at, ground = slot.at, slot.ground
					if t < 0 then
						continue
					elseif t < settings.Warning then
						-- The warning: dust trickling from above, a shadow growing where it lands.
						-- Full size from the start (where it lands is never in doubt), darkening.
						local k = t / settings.Warning
						local size = settings.RockRadius * 2
						slot.shadow.Size = Vector3.new(0.12, size, size)
						slot.shadow.CFrame = CFrame.new(at.X, ground + 0.08, at.Y)
							* CFrame.Angles(0, 0, math.pi / 2)
						slot.shadow.Transparency = 0.7 - 0.45 * k
						slot.rock.CFrame = CFrame.new(at.X, slot.top, at.Y)
						slot.dust.Enabled = true
					elseif t < landing then
						-- The fall, and the moment it harms.
						local k = math.min(1, (t - settings.Warning) / (settings.Active * 0.6))
						slot.dust.Enabled = false
						slot.rock.Transparency = 0
						slot.rock.CFrame = CFrame.new(
							at.X,
							slot.top + (ground + slot.rock.Size.Y * 0.4 - slot.top) * k,
							at.Y
						)
						if slot.shadow:GetAttribute("Active") ~= true then
							slot.shadow:SetAttribute("Active", true)
						end
					elseif t < landing + settings.Lie then
						-- Lying there a while: a boulder to step round.
						if slot.shadow:GetAttribute("Active") ~= false then
							-- It breaks as it lands: what's left is a boulder you step round.
							slot.shadow:SetAttribute("Active", false)
							slot.shadow.Transparency = 1
							slot.rock.Size = slot.size * LYING
							slot.rock.CFrame = CFrame.new(at.X, ground + slot.rock.Size.Y * 0.4, at.Y)
							slot.rock.CanCollide = true
						end
					else
						slot.rock.CanCollide = false
						slot.rock.Size = slot.size
						slot.rock.Transparency = 1
						slot.rock.CFrame = CFrame.new(at.X, ground - 20, at.Y)
						slot.shadow.CFrame = CFrame.new(at.X, ground - 20, at.Y)
						slot.start = nil
					end
				end
			end
		end,
	})
end

-- Empties every terrain cell whose middle is within `radius` of (x, z), between heights y0 and
-- y1. (The engine's own FillCylinder leaves cells half full near a small hole's floor.)
local function carve(terrain: Terrain, x: number, z: number, radius: number, y0: number, y1: number)
	local cell = 4
	local low = Vector3.new(
		math.floor((x - radius) / cell) * cell,
		math.floor(y0 / cell) * cell,
		math.floor((z - radius) / cell) * cell
	)
	local high = Vector3.new(
		math.ceil((x + radius) / cell) * cell,
		math.ceil(y1 / cell) * cell,
		math.ceil((z + radius) / cell) * cell
	)
	local region = Region3.new(low, high)
	local materials, occupancy = terrain:ReadVoxels(region, cell)
	for ix = 1, #materials do
		local cx = low.X + (ix - 0.5) * cell
		for iz = 1, #materials[ix][1] do
			local cz = low.Z + (iz - 0.5) * cell
			if (cx - x) ^ 2 + (cz - z) ^ 2 <= radius * radius then
				for iy = 1, #materials[ix] do
					materials[ix][iy][iz] = Enum.Material.Air
					occupancy[ix][iy][iz] = 0
				end
			end
		end
	end
	terrain:WriteVoxels(region, cell, materials, occupancy)
end

-- Pit: a spike pit cut into the ground (see Hazards.luau), open or under a false floor that
-- gives way when someone steps on it.
function builders.Pit(tile, settings, folder)
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	local reader = Looks.terrainReader()
	for _, spot in spotsFor(tile, "Pit", settings) do
		-- Its own folder: the Test Range leaves pits out of its props-on-the-ground check.
		local pit = Instance.new("Folder")
		pit.Name = "Pit"
		pit.Parent = folder
		local placement = spot.placement
		local radius = placement.Radius or settings.Radius
		-- (No deeper than the ground's crust under the deepest cut, or it opens onto nothing.)
		local depth = math.min(placement.Depth or settings.Depth, 12)
		local covered = if placement.Covered ~= nil then placement.Covered else settings.Covered
		local ground = Beach.groundAt(spot.x, spot.z)
		local bottom = ground - depth
		-- The hole: air from just above the ground down to its floor. Terrain is made of 4-stud
		-- cells, so it's cut a little wider than the pit for the cells to really empty; whatever
		-- falls into it lands on the spikes.
		local hole = radius + 1.5
		if terrain then
			-- (From a cell below its floor, so the floor's own cells empty too: the spiked floor
			-- plate is what you land on.)
			carve(terrain, spot.x, spot.z, hole, bottom - 4, ground + 2)
		end
		-- The spikes, all over its floor, and what they do.
		local scatter = Random.new(math.floor(spot.x * 11 + spot.z * 5))
		for _ = 1, math.max(5, math.floor(hole * hole * 0.5)) do
			local angle, reach =
				scatter:NextNumber() * math.pi * 2, math.sqrt(scatter:NextNumber()) * (hole - 1)
			local x, z = spot.x + math.cos(angle) * reach, spot.z + math.sin(angle) * reach
			local height = scatter:NextNumber(2.2, 3.4)
			makePart({
				Name = "Spike",
				Size = Vector3.new(0.35, height, 0.35),
				CFrame = CFrame.new(x, bottom + height / 2, z) * CFrame.Angles(
					scatter:NextNumber(-0.2, 0.2),
					scatter:NextNumber() * math.pi,
					scatter:NextNumber(-0.2, 0.2)
				),
				Color = settings.Color,
				Material = Palette.Material.Metal,
			}).Parent =
				pit
		end
		local floor = makePart({
			Name = "SpikePit",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.2, hole * 2, hole * 2),
			CFrame = CFrame.new(spot.x, bottom + 0.1, spot.z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(30, 26, 22),
			Material = Enum.Material.Slate,
			CanCollide = true,
		})
		arm(floor, settings)
		floor:SetAttribute("HitRadius", hole)
		floor.Parent = pit
		if not covered then
			continue
		end
		-- The false floor: the ground's own sand, a little darker, with a few cracks.
		local floorMaterial = reader(spot.x, spot.z)
		local color = if terrain then terrain:GetMaterialColor(floorMaterial) else settings.Color
		local lid = makePart({
			Name = "PitCover",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1, hole * 2 + 1, hole * 2 + 1),
			CFrame = CFrame.new(spot.x, ground - 0.4, spot.z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.06),
			Material = floorMaterial,
			CanCollide = true,
			CanTouch = true,
			CanQuery = true,
		})
		local cracks = {}
		for k = 1, 3 do
			local crack = makePart({
				Name = "Crack",
				Size = Vector3.new(0.15, 0.05, radius * scatter:NextNumber(0.6, 1.2)),
				CFrame = CFrame.new(spot.x, ground + 0.11, spot.z)
					* CFrame.Angles(0, k * 1.1 + scatter:NextNumber(-0.3, 0.3), 0),
				Color = color:Lerp(Color3.new(0, 0, 0), 0.45),
				Material = Enum.Material.SmoothPlastic,
			})
			crack.Parent = pit
			table.insert(cracks, crack)
		end
		local broken = false
		lid.Touched:Connect(function(hit)
			if broken then
				return
			end
			local model = hit:FindFirstAncestorOfClass("Model")
			if not (model and model:FindFirstChildOfClass("Humanoid")) then
				return
			end
			broken = true
			-- It gives way: gone from under them, and back later.
			lid.CanCollide = false
			lid.Transparency = 1
			for _, crack in cracks do
				crack.Transparency = 1
			end
			task.delay(settings.Reset, function()
				lid.CanCollide = true
				lid.Transparency = 0
				for _, crack in cracks do
					crack.Transparency = 0
				end
				broken = false
			end)
		end)
		lid.Parent = pit
	end
end

-- Undertow: while the sea covers a ford or channel, a current along it drags you seaward.
-- Built as a row of current parts down its Path, each active while the water there is deep
-- enough, with foam streaming along it to show it.
function builders.Undertow(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local currents = {}
	for _, placement in Layouts.hazardPlacements(tile, "Undertow") do
		local width = placement.Width or settings.Width
		local path = placement.Path
		for i = 1, #path - 1 do
			local a = Vector3.new(path[i][1], 0, z0 + path[i][2])
			local b = Vector3.new(path[i + 1][1], 0, z0 + path[i + 1][2])
			local along = b - a
			if along.Magnitude < 0.5 then
				continue
			end
			-- Toward the sea: along the path, whichever way runs seaward.
			local direction = if along.Z >= 0 then along.Unit else -along.Unit
			local count = math.max(1, math.ceil(along.Magnitude / (width * 0.75)))
			for k = 0, count - 1 do
				local at = a:Lerp(b, (k + 0.5) / count)
				local part = makePart({
					Name = "Undertow",
					Size = Vector3.new(width, 0.2, along.Magnitude / count),
					CFrame = CFrame.lookAt(at, at + direction)
						+ Vector3.new(0, Beach.groundAt(at.X, at.Z) + 0.3, 0),
					Transparency = 1,
				})
				arm(part, settings)
				part:SetAttribute("HitRadius", width / 2)
				part:SetAttribute("Direction", direction)
				part:SetAttribute("Strength", settings.Strength)
				part:SetAttribute("Active", false)
				local foam = Instance.new("ParticleEmitter")
				foam.Color = ColorSequence.new(settings.Color)
				foam.Size = NumberSequence.new(0.6, 0.2)
				foam.Transparency = NumberSequence.new(0.3, 1)
				foam.Lifetime = NumberRange.new(1, 1.6)
				foam.Rate = 6
				foam.Speed = NumberRange.new(settings.Strength * 0.8, settings.Strength)
				foam.EmissionDirection = Enum.NormalId.Front
				foam.SpreadAngle = Vector2.new(8, 2)
				foam.Enabled = false
				foam.Parent = part
				part.Parent = folder
				table.insert(currents, { part = part, foam = foam })
			end
		end
	end
	if #currents == 0 then
		return
	end
	local since = 1
	table.insert(running, {
		folder = folder,
		step = function(_, dt)
			since += dt
			if since < 0.5 then
				return
			end
			since = 0
			local sea = Tide.sea()
			for _, c in currents do
				local active = Beach.seaDepthAt(c.part.CFrame.Position, sea) > settings.MinDepth
				if c.part:GetAttribute("Active") ~= active then
					c.part:SetAttribute("Active", active)
					c.foam.Enabled = active
				end
			end
		end,
	})
end

-- Hunter: a big creature that patrols a route and hunts players it sees (Hazards.luau). It sees
-- ahead of it, in a cone, with nothing solid in the way (and feels anyone right beside it), and
-- it never leaves its route: it runs along it to the point nearest its prey, so in a tunnel it
-- fills the way and can't be run round.
local function carriesLight(player: Player): boolean
	local worn = Gear.getAccessory(player:GetAttribute("Accessory"))
	local tool = Gear.findTool(player:GetAttribute("Tool"))
	return (worn ~= nil and worn.Light ~= nil) or (tool ~= nil and tool.Light ~= nil)
end

-- A route as a rail: the point (and the way it runs) at a distance along it, and the distance
-- along it of the point nearest a position.
local function rail(path: { Vector2 })
	local starts, total = {}, 0
	for i = 1, #path - 1 do
		starts[i] = total
		total += (path[i + 1] - path[i]).Magnitude
	end
	local function at(s: number): (Vector2, Vector2)
		s = math.clamp(s, 0, total)
		for i = #path - 1, 1, -1 do
			if s >= starts[i] then
				local segment = path[i + 1] - path[i]
				local length = segment.Magnitude
				if length <= 0 then
					return path[i], Vector2.new(0, 1)
				end
				return path[i] + segment.Unit * math.min(s - starts[i], length), segment.Unit
			end
		end
		return path[1], Vector2.new(0, 1)
	end
	local function nearest(p: Vector2): number
		local best, bestDistance = 0, math.huge
		for i = 1, #path - 1 do
			local a, segment = path[i], path[i + 1] - path[i]
			local length = segment.Magnitude
			local t = if length > 0 then math.clamp((p - a):Dot(segment) / (length * length), 0, 1) else 0
			local distance = (a + segment * t - p).Magnitude
			if distance < bestDistance then
				best, bestDistance = starts[i] + t * length, distance
			end
		end
		return best
	end
	return { at = at, nearest = nearest, length = total }
end
HazardService._rail = rail

function builders.Hunter(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local routes = {}
	for _, placement in Layouts.hazardPlacements(tile, "Hunter") do
		table.insert(routes, placement.Path)
	end
	if #routes == 0 then
		-- The longest crab route the layout has (the Test Range checks those stay in corridors).
		local best, bestLength = nil, 0
		for _, placement in Layouts.hazardPlacements(tile, "Patrol") do
			local length = 0
			for i = 1, #placement.Path - 1 do
				local a, b = placement.Path[i], placement.Path[i + 1]
				length += math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
			end
			if length > bestLength then
				best, bestLength = placement.Path, length
			end
		end
		if best then
			table.insert(routes, best)
		end
	end
	local size: Vector3 = settings.Size
	local hunters = {}
	for index, route in routes do
		if index > settings.Count then
			break
		end
		local path = {}
		for _, point in route do
			table.insert(path, Vector2.new(point[1], z0 + point[2]))
		end
		local model, body = creature(settings, Vector3.new(path[1].X, 0, path[1].Y))
		model.Name = "Hunter"
		for _, side in { -1, 1 } do
			local eye = makePart({
				Name = "Eye",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.9, 0.9, 0.9),
				CFrame = body.CFrame * CFrame.new(side * size.X * 0.15, size.Y * 0.45, -size.Z * 0.45),
				Color = Color3.fromRGB(255, 230, 120),
				Material = Enum.Material.Neon,
			})
			eye.Parent = model
		end
		model.Parent = folder
		table.insert(hunters, {
			model = model,
			rail = rail(path),
			s = 0, -- how far along its route it is
			dir = 1, -- which way it's patrolling
			at = path[1],
			heading = Vector2.new(0, 1),
			mode = "patrol",
			home = 0, -- where along the route the chase began (its leash runs from there)
			lost = 0,
		})
	end
	if #hunters == 0 then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function place(h)
		local ground = Beach.groundAt(h.at.X, h.at.Y)
		local position = Vector3.new(h.at.X, ground + size.Y / 2, h.at.Y)
		local look = Vector3.new(h.heading.X, 0, h.heading.Y)
		h.model:PivotTo(
			CFrame.lookAt(position, position + (if look.Magnitude > 0 then look else Vector3.zAxis))
		)
	end
	local viewCos = math.cos(math.rad(settings.SightAngle / 2))
	-- Whether a hunter can see a point: nothing solid in between, at about eye height.
	local function sees(h, target: Vector3): boolean
		local from = Vector3.new(h.at.X, Beach.groundAt(h.at.X, h.at.Y) + size.Y * 0.6, h.at.Y)
		local exclude = { folder }
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(exclude, p.Character)
			end
		end
		params.FilterDescendantsInstances = exclude
		return Workspace:Raycast(from, target - from, params) == nil
	end
	-- Moves a hunter along its route toward `goal` (a distance along it) at `speed`. It turns to
	-- face the way it goes, or, standing still, toward `face`.
	local function slide(h, goal: number, speed: number, dt: number, face: Vector2?)
		local step = math.clamp(goal - h.s, -speed * dt, speed * dt)
		h.s += step
		local at, tangent = h.rail.at(h.s)
		h.at = at
		if math.abs(step) > 1e-4 then
			h.heading = tangent * math.sign(step)
		elseif face and (face - at).Magnitude > 0.1 then
			h.heading = (face - at).Unit
		end
	end
	table.insert(running, {
		folder = folder,
		step = function(_, dt)
			for _, h in hunters do
				if h.mode ~= "chase" then
					-- Looking out: the nearest player it can see.
					for _, player in Players:GetPlayers() do
						local character = player.Character
						local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
						local humanoid = character and character:FindFirstChildOfClass("Humanoid")
						if root and humanoid and humanoid.Health > 0 then
							local range = if carriesLight(player)
								then settings.LightRange
								else settings.SightRange
							local offset = Vector2.new(root.Position.X, root.Position.Z) - h.at
							local across = offset.Magnitude
							-- It sees ahead of it, in a cone; behind it, only someone close
							-- enough to feel.
							local ahead = across <= settings.FeelRange
								or (across > 0 and offset.Unit:Dot(h.heading) >= viewCos)
							if across <= range and ahead and sees(h, root.Position) then
								h.mode, h.target, h.lost, h.home = "chase", player, 0, h.s
								break
							end
						end
					end
				end
				if h.mode == "chase" then
					-- It hunts along its route, never off it: to the point of its route
					-- nearest the player, no further than its leash from where it began. In a
					-- tunnel it fills the way, so it can't be run round.
					local character = h.target and h.target.Character
					local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if not root or not humanoid or humanoid.Health <= 0 then
						h.mode = "patrol"
					else
						local where = Vector2.new(root.Position.X, root.Position.Z)
						if sees(h, root.Position) then
							h.lost = 0
						else
							h.lost += dt
						end
						if h.lost > settings.LoseTime then
							h.mode = "patrol"
						else
							local goal = math.clamp(
								h.rail.nearest(where),
								h.home - settings.Leash,
								h.home + settings.Leash
							)
							slide(h, goal, settings.ChaseSpeed, dt, where)
						end
					end
				else
					-- Patrolling: back and forth along its route.
					local goal = if h.dir > 0 then h.rail.length else 0
					slide(h, goal, settings.Speed, dt)
					if math.abs(h.s - goal) < 0.01 then
						h.dir = -h.dir
					end
				end
				place(h)
			end
		end,
	})
end

-- Gloom: something unseen roams the halls (see Hazards.luau). All that shows of it is its
-- shadow on the floor, which it drags along its path; whoever it touches is Benighted, each
-- player's own client darkening their world (HazardController).
function builders.Gloom(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local glooms = {}
	for _, placement in Layouts.hazardPlacements(tile, "Gloom") do
		local path = {}
		for _, point in placement.Path or { placement.At } do
			table.insert(path, Vector2.new(point[1], z0 + point[2]))
		end
		if #path == 0 then
			continue
		end
		local radius = placement.Radius or settings.Radius
		local shadow = makePart({
			Name = "GloomShadow",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.1, radius * 2, radius * 2),
			Color = settings.Color,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.15,
		})
		arm(shadow, settings)
		shadow:SetAttribute("HitRadius", radius)
		shadow:SetAttribute("Duration", settings.Duration)
		shadow:SetAttribute("WardCure", settings.WardCure)
		shadow.Parent = folder
		-- A soft edge: a fainter ring round it.
		local fringe = makePart({
			Name = "GloomFringe",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.08, radius * 2.6, radius * 2.6),
			Color = settings.Color,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.6,
		})
		fringe.Parent = folder
		local length = 0
		for i = 1, #path - 1 do
			length += (path[i + 1] - path[i]).Magnitude
		end
		table.insert(
			glooms,
			{ shadow = shadow, fringe = fringe, path = path, length = length, phase = rng:NextNumber(0, 100) }
		)
	end
	if #glooms == 0 then
		return
	end
	table.insert(running, {
		folder = folder,
		step = function(now)
			for _, g in glooms do
				local at = g.path[1]
				if g.length > 0 then
					at = HazardService.alongPath(g.path, (now + g.phase) * settings.Speed)
				end
				local ground = Beach.groundAt(at.X, at.Y)
				local flat = CFrame.Angles(0, 0, math.pi / 2)
				-- It breathes a little, so the shadow never quite sits still.
				local wobble = 1 + 0.06 * math.sin(now * 1.7 + g.phase)
				g.shadow.CFrame = CFrame.new(at.X, ground + 0.1, at.Y) * flat
				g.fringe.CFrame = CFrame.new(at.X, ground + 0.08, at.Y) * flat
				local r = g.shadow:GetAttribute("HitRadius")
				g.fringe.Size = Vector3.new(0.08, r * 2.6 * wobble, r * 2.6 * wobble)
			end
		end,
	})
end

HazardService.Builders = builders

-- Builds a source's hazards on a tile into its folder: a biome's, or a plain zone's
-- (Config.Zones[i]), anything with a Hazards list.
function HazardService.start(tile: number, source: any, folder: Instance)
	for _, entry in source.Hazards or {} do
		local settings = Hazards.settings(entry)
		local build = builders[settings.Type]
		if build then
			build(tile, settings, folder)
		end
	end
end

local HARM_SLACK = 6 -- studs of lag the server allows on a reported hit
local HARM_COOLDOWN = 1 -- seconds before the same hazard can harm the same player again

function HazardService.init()
	-- A client reports its own character hit by a Harm hazard or swallowed by a Sink: the
	-- server checks it was there (and that the hazard was live) and applies the damage.
	local lastHarm: { [Player]: { [Instance]: number } } = {}
	Remotes.get("HazardHarm").OnServerEvent:Connect(function(player: Player, part)
		if
			typeof(part) ~= "Instance"
			or not part:IsA("BasePart")
			or not CollectionService:HasTag(part, Hazards.Tag)
		then
			return
		end
		local effect = part:GetAttribute("Effect")
		if
			(effect ~= "Harm" and effect ~= "Sink")
			or part:GetAttribute("Active") == false
			or part:GetAttribute("Lethal") == false
		then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoid or not root or humanoid.Health <= 0 then
			return
		end
		local offset = root.Position - part.Position
		local across = Vector3.new(offset.X, 0, offset.Z).Magnitude
		if across > (part:GetAttribute("HitRadius") or 0) + HARM_SLACK or math.abs(offset.Y) > 10 then
			return
		end
		local now = os.clock()
		local mine = lastHarm[player] or {}
		lastHarm[player] = mine
		if now - (mine[part] or -math.huge) < HARM_COOLDOWN then
			return
		end
		mine[part] = now
		humanoid:TakeDamage(part:GetAttribute("Damage") or 100)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastHarm[player] = nil
	end)
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
	for i = #running, 1, -1 do
		-- (A hazard whose folder an earlier test destroyed fails: drop it.)
		local ok, err = pcall(running[i].step, now, dt)
		if not ok then
			if HazardService._debug then
				print(err)
			end
			table.remove(running, i)
		end
	end
end

return HazardService
