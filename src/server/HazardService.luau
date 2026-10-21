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
	local z0, z1 = Beach.tileRange(tile)
	-- The ways barrels come down: a layout's Paths (from the wreck's deck down a gully), or
	-- its Lanes (straight down the zone from the top).
	local routes = {}
	for _, placement in Layouts.hazardPlacements(tile, "Roller") do
		if placement.Path then
			local path = {}
			for _, point in placement.Path do
				table.insert(path, Vector2.new(point[1], z0 + point[2]))
			end
			table.insert(routes, path)
		end
		for _, x in placement.Lanes or {} do
			table.insert(routes, { Vector2.new(x, z0 + 5), Vector2.new(x, z1 - 5) })
		end
	end
	if #routes == 0 then
		return
	end
	local size: Vector3 = settings.Size
	-- A point along a route, and the way it runs there.
	local function along(path: { Vector2 }, s: number): (Vector2?, Vector2)
		for i = 1, #path - 1 do
			local segment = path[i + 1] - path[i]
			local length = segment.Magnitude
			if s <= length and length > 0 then
				return path[i] + segment.Unit * s, segment.Unit
			end
			s -= length
		end
		return nil, Vector2.new(0, 1)
	end
	local barrels = {}
	local nextAt = os.clock() + rng:NextNumber(0, settings.Period)
	local function roll(now: number)
		local path = routes[rng:NextInteger(1, #routes)]
		local start = path[1]
		if Beach.isDeep(Vector3.new(start.X, 0, start.Y), Tide.sea()) then
			return -- its start is under water: nothing to roll down
		end
		local barrel = makePart({
			Name = "Roller",
			Shape = Enum.PartType.Cylinder,
			Size = size, -- the axis along X: turned to face down its route
			Color = settings.Color,
			Material = Palette.Material.Wood,
		})
		arm(barrel, settings)
		barrel:SetAttribute("Active", false)
		local dust = Instance.new("ParticleEmitter")
		dust.Color = ColorSequence.new(Color3.fromRGB(200, 180, 150))
		dust.Size = NumberSequence.new(0.8, 1.6)
		dust.Lifetime = NumberRange.new(0.5, 0.9)
		dust.Rate = 25
		dust.Speed = NumberRange.new(2, 4)
		dust.Parent = barrel
		barrel.Parent = folder
		table.insert(
			barrels,
			{ part = barrel, dust = dust, path = path, s = 0, released = now + settings.Warning }
		)
	end
	table.insert(running, {
		folder = folder,
		step = function(now, dt)
			if now >= nextAt then
				nextAt = now + settings.Period
				roll(now)
			end
			for index = #barrels, 1, -1 do
				local b = barrels[index]
				local rolling = now >= b.released
				if rolling then
					b.s += settings.Speed * dt
					b.dust.Enabled = false
					if b.part:GetAttribute("Active") ~= true then
						b.part:SetAttribute("Active", true)
					end
				end
				local at, way = along(b.path, b.s)
				if not at then
					-- Off the end of its gully: it breaks up.
					b.part:Destroy()
					table.remove(barrels, index)
					continue
				end
				local ground = Beach.groundAt(at.X, at.Y)
				local facing = CFrame.lookAt(Vector3.zero, Vector3.new(way.X, 0, way.Y))
				-- Teetering on the edge (the warning), then rolling over and over.
				local spin = if rolling then b.s / (size.Y / 2) else math.sin((now - b.released) * 9) * 0.25
				b.part.CFrame = CFrame.new(at.X, ground + size.Y / 2, at.Y)
					* facing
					* CFrame.Angles(-spin, 0, 0)
					* CFrame.Angles(0, math.pi / 2, 0)
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

-- The calls patrol crabs make to their tile's Hunter (where, and when), when the next may be
-- made, and whether the tile's Hunter is already hunting (then nobody calls).
local calls: { [number]: { at: Vector2, time: number } } = {}
local nextCall: { [number]: number } = {}
local hunting: { [number]: boolean } = {}
-- What patrol crabs have seen (someone near them, and when), passed on to the Hunter.
local sightings: { [number]: { at: Vector2, time: number } } = {}

-- Whether anything solid is between two points (players and the hazards' own parts aside).
local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
local function clearSight(from: Vector3, to: Vector3, folder: Instance): boolean
	local exclude: { Instance } = { folder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	sightParams.FilterDescendantsInstances = exclude
	return Workspace:Raycast(from, to - from, sightParams) == nil
end

-- Patrol: creatures walk a route back and forth, or wander around where they start. With
-- Calls, one that spots someone stops and drums for the Hunter (see Hazards.luau).
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
				table.insert(walkers, { model = model, path = path, dist = 2 * length * (i - 1) / count })
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
	-- Calling: the ring that pulses round a drumming crab.
	local function ring(walker): BasePart
		if not walker.ring then
			walker.ring = makePart({
				Name = "CallRing",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.15, 1, 1),
				Color = Color3.fromRGB(255, 150, 60),
				Material = Enum.Material.Neon,
				Transparency = 1,
			})
			walker.ring.Parent = folder
		end
		return walker.ring
	end
	local callCos = math.cos(math.rad(settings.CallAngle / 2))
	-- Someone the crab can see ahead of it, near enough to call about.
	local function spots(walker): Vector3?
		local at, heading = walker.at, walker.heading
		if not at or not heading then
			return nil
		end
		local eye = Vector3.new(at.X, Beach.groundAt(at.X, at.Y) + size.Y, at.Y)
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				local offset = Vector2.new(root.Position.X, root.Position.Z) - at
				if
					offset.Magnitude <= settings.CallRange
					and offset.Magnitude > 0
					and offset.Unit:Dot(heading) >= callCos
					and clearSight(eye, root.Position, folder)
				then
					return root.Position
				end
			end
		end
		return nil
	end
	table.insert(running, {
		folder = folder,
		step = function(now, dt)
			for _, walker in walkers do
				-- Every crab that can call also tells what it sees, now and then.
				if settings.Calls and walker.path and now >= (walker.nextLook or 0) then
					walker.nextLook = now + 0.5
					local seen = spots(walker)
					if seen then
						sightings[tile] = { at = Vector2.new(seen.X, seen.Z), time = now }
					end
				end
				if settings.Calls and walker.path then
					if walker.callUntil then
						-- Drumming: it stands, claws going, a ring pulsing out round it.
						local k = ((walker.callUntil - now) * 2) % 1
						local r = ring(walker)
						local radius = 2 + (1 - k) * 10
						r.Size = Vector3.new(0.15, radius * 2, radius * 2)
						r.CFrame = CFrame.new(
							walker.at.X,
							Beach.groundAt(walker.at.X, walker.at.Y) + 0.2,
							walker.at.Y
						) * CFrame.Angles(0, 0, math.pi / 2)
						r.Transparency = 0.2 + 0.7 * (1 - k)
						local bob = math.abs(math.sin(now * 14)) * 0.6
						walker.model:PivotTo(
							walker.model:GetPivot() + Vector3.new(0, bob - (walker.bob or 0), 0)
						)
						walker.bob = bob
						if now >= walker.callUntil then
							local seen = spots(walker)
							if seen then
								calls[tile] = { at = walker.at, time = now }
							end
							walker.callUntil, walker.nextCall, walker.bob =
								nil, now + settings.CallCooldown, 0
							r.Transparency = 1
						end
						continue
					elseif
						now >= (walker.nextCall or 0)
						and now >= (nextCall[tile] or 0)
						and not hunting[tile]
						and spots(walker)
					then
						-- Not every crab that sees you drums.
						if rng:NextNumber() < settings.CallChance then
							walker.callUntil = now + settings.CallTime
							nextCall[tile] = now + settings.CallTime + settings.CallShared
							continue
						end
						walker.nextCall = now + settings.CallCooldown
					end
				end
				if walker.path then
					walker.dist += settings.Speed * dt
					local at, heading = HazardService.alongPath(walker.path, walker.dist)
					walker.at, walker.heading = at, heading
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

-- The giant's tunnels as a graph: junctions (nodes) joined by straight runs (edges). Routes
-- that share a point, or where one route's corner lies on another's run, are joined there.
-- A place on it is { e = edge, d = distance along it from its first node }.
local JOIN = 4 -- studs within which two routes' points are the same junction
local function tunnels(routes: { { Vector2 } })
	local nodes: { Vector2 } = {}
	local edges: { { a: number, b: number, len: number } } = {}
	local function node(p: Vector2): number
		for i, n in nodes do
			if (n - p).Magnitude <= JOIN then
				return i
			end
		end
		table.insert(nodes, p)
		return #nodes
	end
	for _, path in routes do
		for i = 1, #path - 1 do
			local a, b = node(path[i]), node(path[i + 1])
			if a ~= b then
				table.insert(edges, { a = a, b = b, len = (nodes[b] - nodes[a]).Magnitude })
			end
		end
	end
	-- Two runs crossing in their middles make a junction there.
	local crossed = true
	while crossed do
		crossed = false
		for i = 1, #edges do
			for j = i + 1, #edges do
				local e1, e2 = edges[i], edges[j]
				if e1.a ~= e2.a and e1.a ~= e2.b and e1.b ~= e2.a and e1.b ~= e2.b then
					local p, r = nodes[e1.a], nodes[e1.b] - nodes[e1.a]
					local q, u = nodes[e2.a], nodes[e2.b] - nodes[e2.a]
					local den = r.X * u.Y - r.Y * u.X
					if math.abs(den) > 1e-6 then
						local t = ((q - p).X * u.Y - (q - p).Y * u.X) / den
						local v = ((q - p).X * r.Y - (q - p).Y * r.X) / den
						if t > 0.01 and t < 0.99 and v > 0.01 and v < 0.99 then
							table.insert(nodes, p + r * t)
							local n = #nodes
							edges[i] = { a = e1.a, b = n, len = (r * t).Magnitude }
							edges[j] = { a = e2.a, b = n, len = (u * v).Magnitude }
							table.insert(edges, { a = n, b = e1.b, len = (r * (1 - t)).Magnitude })
							table.insert(edges, { a = n, b = e2.b, len = (u * (1 - v)).Magnitude })
							crossed = true
							break
						end
					end
				end
			end
			if crossed then
				break
			end
		end
	end
	-- A junction lying on another run splits that run there.
	local split = true
	while split do
		split = false
		for n, p in nodes do
			for ei, e in edges do
				if e.a ~= n and e.b ~= n then
					local A, B = nodes[e.a], nodes[e.b]
					local t = (p - A):Dot(B - A) / (e.len * e.len)
					if t > 0.01 and t < 0.99 and (A + (B - A) * t - p).Magnitude <= JOIN then
						table.insert(edges, { a = n, b = e.b, len = (nodes[e.b] - p).Magnitude })
						edges[ei] = { a = e.a, b = n, len = (p - A).Magnitude }
						split = true
						break
					end
				end
			end
			if split then
				break
			end
		end
	end
	local links: { { number } } = {}
	for i in nodes do
		links[i] = {}
	end
	for ei, e in edges do
		table.insert(links[e.a], ei)
		table.insert(links[e.b], ei)
	end
	local g = { nodes = nodes, edges = edges, links = links }
	function g.at(pt): (Vector2, Vector2)
		local e = edges[pt.e]
		local A, B = nodes[e.a], nodes[e.b]
		local dir = if e.len > 0 then (B - A).Unit else Vector2.new(0, 1)
		return A + dir * math.clamp(pt.d, 0, e.len), dir
	end
	-- The place on the tunnels nearest a point, and how far it is.
	function g.nearest(p: Vector2)
		local best, bestDistance = { e = 1, d = 0 }, math.huge
		for ei, e in edges do
			local A, B = nodes[e.a], nodes[e.b]
			local t = if e.len > 0 then math.clamp((p - A):Dot(B - A) / (e.len * e.len), 0, 1) else 0
			local distance = (A + (B - A) * t - p).Magnitude
			if distance < bestDistance then
				best, bestDistance = { e = ei, d = t * e.len }, distance
			end
		end
		return best, bestDistance
	end
	-- Which end of its run to head for, going from one place to another the shortest way
	-- through the tunnels (nil: it's on the same run, head straight for it), and how far.
	function g.toward(from, to): (number?, number)
		if from.e == to.e then
			return nil, math.abs(to.d - from.d)
		end
		local cost, first = {}, {}
		local fe, te = edges[from.e], edges[to.e]
		cost[fe.a], first[fe.a] = from.d, fe.a
		if (cost[fe.b] or math.huge) > fe.len - from.d then
			cost[fe.b], first[fe.b] = fe.len - from.d, fe.b
		end
		local done = {}
		while true do
			local n, c = nil, math.huge
			for k, v in cost do
				if not done[k] and v < c then
					n, c = k, v
				end
			end
			if not n then
				break
			end
			done[n] = true
			for _, ei in links[n] do
				local e = edges[ei]
				local m = if e.a == n then e.b else e.a
				if c + e.len < (cost[m] or math.huge) then
					cost[m], first[m] = c + e.len, first[n]
				end
			end
		end
		local viaA = (cost[te.a] or math.huge) + to.d
		local viaB = (cost[te.b] or math.huge) + (te.len - to.d)
		if viaA <= viaB then
			return first[te.a], viaA
		end
		return first[te.b], viaB
	end
	return g
end
HazardService._tunnels = tunnels

function builders.Hunter(tile, settings, folder)
	if Beach.zoneOfTile(tile) < settings.FromZone then
		return
	end
	local z0 = Beach.tileRange(tile)
	local function world(path)
		local out = {}
		for _, point in path do
			table.insert(out, Vector2.new(point[1], z0 + point[2]))
		end
		return out
	end
	local giants = {}
	for _, placement in Layouts.hazardPlacements(tile, "Hunter") do
		local routes = {}
		for _, path in placement.Routes or {} do
			table.insert(routes, world(path))
		end
		if placement.Path then
			table.insert(routes, world(placement.Path))
		end
		if #routes > 0 then
			table.insert(giants, { routes = routes, burrows = placement.Burrows })
		end
	end
	if #giants == 0 then
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
			table.insert(giants, { routes = { world(best) } })
		end
	end
	local size: Vector3 = settings.Size
	local calm, angry = Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 40, 30)
	local hunters = {}
	for index, giant in giants do
		if index > settings.Count then
			break
		end
		local g = tunnels(giant.routes)
		local start = giant.routes[1][1]
		local model, body = creature(settings, Vector3.new(start.X, 0, start.Y))
		model.Name = "Hunter"
		local eyes = {}
		for _, side in { -1, 1 } do
			local eye = makePart({
				Name = "Eye",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.9, 0.9, 0.9),
				CFrame = body.CFrame * CFrame.new(side * size.X * 0.15, size.Y * 0.45, -size.Z * 0.45),
				Color = calm,
				Material = Enum.Material.Neon,
			})
			eye.Parent = model
			table.insert(eyes, eye)
		end
		-- The dust it throws up going down.
		local dig = makePart({ Name = "DigDust", Size = Vector3.new(1, 1, 1), Transparency = 1 })
		local digDust = Instance.new("ParticleEmitter")
		digDust.Color = ColorSequence.new(Color3.fromRGB(196, 176, 140))
		digDust.Size = NumberSequence.new(2.5, 5)
		digDust.Lifetime = NumberRange.new(1, 1.6)
		digDust.Rate = 50
		digDust.Speed = NumberRange.new(6, 12)
		digDust.SpreadAngle = Vector2.new(60, 60)
		digDust.EmissionDirection = Enum.NormalId.Top
		digDust.Enabled = false
		digDust.Parent = dig
		dig.Parent = folder
		model.Parent = folder
		-- Its burrow holes: on its tunnels, where it can come up. A churned patch flush with the
		-- floor marks each (it shakes and spurts sand before the giant comes up through it).
		local burrows = {}
		local points = giant.burrows
		if not points then
			points = {}
			for _, n in g.nodes do
				if #g.links[table.find(g.nodes, n) :: number] ~= 2 then
					table.insert(points, { n.X, n.Y - z0 }) -- its tunnels' ends and junctions
				end
			end
		end
		for _, point in points do
			local pt = g.nearest(Vector2.new(point[1], z0 + point[2]))
			local at = g.at(pt)
			local ground = Beach.groundAt(at.X, at.Y)
			local hole = makePart({
				Name = "BurrowHole",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.4, size.X * 0.7, size.X * 0.7),
				CFrame = CFrame.new(at.X, ground + 0.1, at.Y) * CFrame.Angles(0, 0, math.pi / 2),
				Color = Color3.fromRGB(120, 100, 74),
				Material = Enum.Material.Sand,
			})
			hole.Parent = folder
			local spout = makePart({
				Name = "BurrowSpout",
				Size = Vector3.new(size.X * 0.5, 0.2, size.X * 0.5),
				CFrame = CFrame.new(at.X, ground + 0.3, at.Y),
				Transparency = 1,
			})
			local spurt = Instance.new("ParticleEmitter")
			spurt.Color = ColorSequence.new(Color3.fromRGB(206, 186, 150))
			spurt.Size = NumberSequence.new(1.2, 2.5)
			spurt.Lifetime = NumberRange.new(0.6, 1)
			spurt.Rate = 70
			spurt.Speed = NumberRange.new(10, 18)
			spurt.SpreadAngle = Vector2.new(25, 25)
			spurt.EmissionDirection = Enum.NormalId.Top
			spurt.Enabled = false
			spurt.Parent = spout
			spout.Parent = folder
			table.insert(burrows, { pt = pt, at = at, hole = hole, base = hole.CFrame, spurt = spurt })
		end
		local home = g.nearest(start)
		table.insert(hunters, {
			model = model,
			body = body,
			eyes = eyes,
			dig = dig,
			digDust = digDust,
			g = g,
			burrows = burrows,
			pt = home, -- where on its tunnels it is
			came = nil, -- the junction it last left (wandering, it doesn't turn straight back)
			at = start,
			heading = Vector2.new(0, 1),
			mode = "patrol",
			lost = 0,
			sink = 0, -- how far down in the sand it is
			pitch = 0, -- how far it's reared up
			nextDash = 0,
			nextDig = 0,
			heard = 0, -- the last call it answered
		})
	end
	if #hunters == 0 then
		return
	end
	local function place(h)
		local ground = Beach.groundAt(h.at.X, h.at.Y)
		local position = Vector3.new(h.at.X, ground + size.Y / 2 - h.sink, h.at.Y)
		local look = Vector3.new(h.heading.X, 0, h.heading.Y)
		h.model:PivotTo(
			CFrame.lookAt(position, position + (if look.Magnitude > 0 then look else Vector3.zAxis))
				* CFrame.Angles(h.pitch, 0, 0)
		)
	end
	for _, h in hunters do
		place(h) -- on the ground from the start
	end
	local function eyes(h, color: Color3)
		for _, eye in h.eyes do
			eye.Color = color
		end
	end
	local viewCos = math.cos(math.rad(settings.SightAngle / 2))
	-- Whether a hunter can see a point: nothing solid in between, at about eye height.
	local function sees(h, target: Vector3): boolean
		local from = Vector3.new(h.at.X, Beach.groundAt(h.at.X, h.at.Y) + size.Y * 0.6, h.at.Y)
		return clearSight(from, target, folder)
	end
	-- Moves a hunter `step` studs along its run toward `d` on it (clamped to the run's ends).
	local function along(h, d: number, step: number)
		local e = h.g.edges[h.pt.e]
		local moved = math.clamp(d - h.pt.d, -step, step)
		h.pt = { e = h.pt.e, d = math.clamp(h.pt.d + moved, 0, e.len) }
		local at, dir = h.g.at(h.pt)
		h.at = at
		if math.abs(moved) > 1e-4 then
			h.heading = dir * math.sign(moved)
		end
		return step - math.abs(moved)
	end
	-- Steps onto another run from the junction it's standing on.
	local function onto(h, n: number, ei: number)
		local e = h.g.edges[ei]
		h.came = n
		h.pt = { e = ei, d = if e.a == n then 0 else e.len }
	end
	-- Goes toward a place on its tunnels, the shortest way, `speed` studs a second, turning at
	-- junctions and back along its run as it needs (a ghost in a maze: it knows the tunnels,
	-- not where you are). Faces `face` when it's there.
	local function chase(h, goal, speed: number, dt: number, face: Vector2?)
		local left = speed * dt
		for _ = 1, 8 do
			if left <= 1e-4 then
				break
			end
			local endNode = h.g.toward(h.pt, goal)
			if not endNode then
				along(h, goal.d, left)
				break
			end
			local e = h.g.edges[h.pt.e]
			local target = if endNode == e.a then 0 else e.len
			left = along(h, target, left)
			if math.abs(h.pt.d - target) < 1e-3 then
				-- At the junction: onto the run the shortest way continues by.
				local best, bestCost = nil, math.huge
				for _, ei in h.g.links[endNode] do
					local nextE = h.g.edges[ei]
					local trial = { e = ei, d = if nextE.a == endNode then 0 else nextE.len }
					local _, cost = h.g.toward(trial, goal)
					if cost < bestCost then
						best, bestCost = ei, cost
					end
				end
				if best then
					onto(h, endNode, best)
				end
			end
		end
		if
			face
			and (face - h.at).Magnitude > 0.1
			and speed * dt > 0
			and h.pt.e == goal.e
			and math.abs(h.pt.d - goal.d) < 0.5
		then
			h.heading = (face - h.at).Unit
		end
	end
	-- Wanders its tunnels: along its run, then at a junction any other way (back only at a dead end).
	local function wander(h, dt: number)
		local e = h.g.edges[h.pt.e]
		h.dir = h.dir or 1
		local target = if h.dir > 0 then e.len else 0
		along(h, target, settings.Speed * dt)
		if math.abs(h.pt.d - target) < 1e-3 then
			local n = if h.dir > 0 then e.b else e.a
			local options = {}
			for _, ei in h.g.links[n] do
				if ei ~= h.pt.e then
					table.insert(options, ei)
				end
			end
			if #options == 0 then
				h.dir = -h.dir -- a dead end: back the way it came
			else
				local ei = options[rng:NextInteger(1, #options)]
				onto(h, n, ei)
				h.dir = if h.g.edges[ei].a == n then 1 else -1
			end
		end
	end
	-- The dig: down where it is (dust), up at the burrow nearest `toward` (its hole shaking and
	-- spurting sand from now until it's up). False if there's no burrow worth digging to.
	local function startDig(h, toward: Vector2, now: number): boolean
		local best, bestGap = nil, math.huge
		for _, burrow in h.burrows do
			local gap = (burrow.at - toward).Magnitude
			if (burrow.at - h.at).Magnitude > 30 and gap < bestGap then
				best, bestGap = burrow, gap
			end
		end
		if not best then
			return false
		end
		h.mode, h.burrow, h.due, h.toward = "dig", best, now + settings.DigTime, toward
		h.dig.CFrame = CFrame.new(h.at.X, Beach.groundAt(h.at.X, h.at.Y), h.at.Y)
		h.digDust.Enabled = true
		best.spurt.Enabled = true
		best.shakeUntil = now + settings.DigTime + settings.UnderTime
		return true
	end
	table.insert(running, {
		folder = folder,
		step = function(now, dt)
			for _, h in hunters do
				for _, burrow in h.burrows do
					-- A hole about to give up the crab shakes.
					if burrow.shakeUntil and now < burrow.shakeUntil then
						burrow.hole.CFrame = burrow.base
							+ Vector3.new(
								rng:NextNumber(-0.4, 0.4),
								rng:NextNumber(0, 0.4),
								rng:NextNumber(-0.4, 0.4)
							)
					elseif burrow.shakeUntil then
						burrow.hole.CFrame, burrow.spurt.Enabled, burrow.shakeUntil = burrow.base, false, nil
					end
				end
			end
			local call = calls[tile]
			for _, h in hunters do
				h.ignore = h.ignore or {}
				-- A patrol crab's call: it digs to the burrow nearest the caller (not to you: it
				-- has to find you itself when it's up).
				if call and call.time > h.heard and h.mode == "patrol" then
					h.heard = call.time
					h.target = nil
					startDig(h, call.at, now)
				end
				if h.mode == "patrol" then
					-- Looking out: the nearest player it can see.
					for _, player in Players:GetPlayers() do
						local character = player.Character
						local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
						local humanoid = character and character:FindFirstChildOfClass("Humanoid")
						if root and humanoid and humanoid.Health > 0 and now >= (h.ignore[player] or 0) then
							local range = if carriesLight(player)
								then settings.LightRange
								else settings.SightRange
							local offset = Vector2.new(root.Position.X, root.Position.Z) - h.at
							local across = offset.Magnitude
							-- It sees ahead of it, in a cone; behind it, only someone close enough to feel.
							local ahead = across <= settings.FeelRange
								or (across > 0 and offset.Unit:Dot(h.heading) >= viewCos)
							if across <= range and ahead and sees(h, root.Position) then
								h.mode, h.target, h.lost = "chase", player, 0
								h.lastSeen = Vector2.new(root.Position.X, root.Position.Z)
								h.going, h.stuck = Vector2.zero, 0
								h.nextDig = now + settings.DigEvery
								break
							end
						end
					end
				end
				local character = h.target and h.target.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local where = root and Vector2.new(root.Position.X, root.Position.Z)
				if h.mode == "chase" then
					if not root or not humanoid or humanoid.Health <= 0 then
						h.mode, h.target = "patrol", nil
					else
						-- It knows only what it sees: out of sight, it guesses where they went.
						local seen = sees(h, root.Position)
						if seen then
							local v = root.AssemblyLinearVelocity
							h.lost, h.lastSeen, h.going = 0, where, Vector2.new(v.X, v.Z)
						else
							h.lost += dt
						end
						local guess = if seen
							then where
							else h.lastSeen + h.going * math.min(h.lost, settings.Predict)
						local goal, off = h.g.nearest(guess)
						local offset = guess - h.at
						-- Someone it can see but can't reach (off its tunnels): it waits a while,
						-- then leaves them be.
						h.stuck = if seen and select(2, h.g.nearest(where)) > size.X * 0.5 + 6
							then h.stuck + dt
							else 0
						if h.stuck > settings.GiveUp then
							h.ignore[h.target] = now + settings.Ignore
							h.mode, h.target = "patrol", nil
						elseif h.lost > settings.LoseTime then
							-- Lost them: it digs to where it guesses they went, or gives up.
							if not startDig(h, guess, now) then
								h.mode, h.target = "patrol", nil
							end
						elseif
							seen
							and now >= h.nextDash
							and offset.Magnitude <= settings.DashRange
							and offset.Magnitude > 0
							and offset.Unit:Dot(h.heading) > 0.5
						then
							-- The dash: it rears up first, eyes gone red.
							h.mode, h.due, h.dashGoal, h.dashLeft =
								"rear", now + settings.DashWarn, goal, settings.DashDistance
							eyes(h, angry)
						elseif
							seen
							and now >= h.nextDig
							and select(2, h.g.toward(h.pt, goal)) > settings.DigAway
						then
							h.nextDig = now + settings.DigEvery
							if not startDig(h, guess, now) then
								chase(h, goal, settings.ChaseSpeed, dt, guess)
							end
						else
							local _ = off
							chase(h, goal, settings.ChaseSpeed, dt, guess)
						end
					end
				elseif h.mode == "rear" then
					h.pitch = math.min(0.45, h.pitch + dt * 1.5)
					if now >= h.due then
						h.mode, h.due = "dash", now + settings.DashDistance / settings.DashSpeed + 0.3
					end
				elseif h.mode == "dash" then
					h.pitch = math.max(0, h.pitch - dt * 3)
					local before = h.at
					chase(h, h.dashGoal, math.min(settings.DashSpeed, h.dashLeft / math.max(dt, 1e-3)), dt)
					h.dashLeft -= (h.at - before).Magnitude
					if h.dashLeft <= 0.5 or now >= h.due or (h.at - before).Magnitude < 1e-3 then
						h.mode, h.due = "recover", now + settings.DashRecover
						h.nextDash = now + settings.DashRecover + settings.DashCooldown
					end
				elseif h.mode == "recover" then
					-- Standing, getting its breath: the moment to get away.
					if now >= h.due then
						eyes(h, calm)
						h.mode = if h.target then "chase" else "patrol"
						h.lost = 0
					end
				elseif h.mode == "dig" then
					h.sink = math.min(size.Y + 1, h.sink + dt * (size.Y + 1) / settings.DigTime)
					if now >= h.due then
						h.digDust.Enabled = false
						h.body:SetAttribute("Active", false)
						h.mode, h.due = "under", now + settings.UnderTime
					end
				elseif h.mode == "under" then
					if now >= h.due then
						h.pt = h.burrow.pt
						h.at = h.burrow.at
						h.came = nil
						-- Up facing where it dug toward (where it guessed you'd be, or the caller).
						local toward = h.toward or h.at
						h.heading = if (toward - h.at).Magnitude > 0.1
							then (toward - h.at).Unit
							else h.heading
						h.body:SetAttribute("Active", true)
						h.mode, h.due = "emerge", now + settings.EmergeTime
					end
				elseif h.mode == "emerge" then
					h.sink = math.max(0, h.sink - dt * (size.Y + 1) / settings.EmergeTime)
					if now >= h.due then
						-- Up, it looks for you again: only what it sees now.
						h.sink = 0
						h.mode, h.target = "patrol", nil
						h.lost = 0
						h.nextDig = now + settings.DigEvery
					end
				else
					-- Hunting no one, it doesn't wait: every so often it digs to where the patrol
					-- crabs last saw someone, or to another burrow.
					h.nextRoam = h.nextRoam or now + settings.RoamEvery
					if now >= h.nextRoam and #h.burrows > 0 then
						h.nextRoam = now + settings.RoamEvery
						local hunch = sightings[tile]
						local toward = if hunch and now - hunch.time <= settings.Hunch
							then hunch.at
							else h.burrows[rng:NextInteger(1, #h.burrows)].at
						startDig(h, toward, now)
					end
					if h.mode == "patrol" then
						wander(h, dt)
					end
					h.pitch = 0
				end
				-- Up out of the sand whenever it isn't digging.
				if h.mode ~= "dig" and h.mode ~= "under" and h.mode ~= "emerge" then
					h.sink = 0
				end
				hunting[tile] = h.mode ~= "patrol"
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

-- Jelly: translucent, glowing jellyfish (see Hazards.luau). Stranded on the sand (At) one lies
-- still with a ring of glow on the sand round it, as wide as its sting's reach (Radius); in the
-- water (Path) it drifts along its route at Speed, a little under the surface. Both pulse. What
-- stings is the glow ring (stranded) or the bell (drifting), tagged with the sting's Damage,
-- Stun and StunZone: the client does the rest (HazardController).
local JELLY_COLORS = {
	Color3.fromRGB(190, 140, 255),
	Color3.fromRGB(255, 130, 200),
	Color3.fromRGB(150, 160, 255),
	Color3.fromRGB(210, 120, 255),
}
local TENTACLES = 5

function builders.Jelly(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local list = {}
	for _, placement in Layouts.hazardPlacements(tile, "Jelly") do
		if placement.Path then
			local path = {}
			for _, point in placement.Path do
				table.insert(path, Vector2.new(point[1], z0 + point[2]))
			end
			if #path >= 1 then
				table.insert(list, { path = path, placement = placement })
			end
		elseif placement.At then
			table.insert(
				list,
				{ at = Vector2.new(placement.At[1], z0 + placement.At[2]), placement = placement }
			)
		end
	end
	if #list == 0 and settings.Scatter then
		for _ = 1, settings.Count do
			local x, z = randomSpot(tile)
			table.insert(list, { at = Vector2.new(x, z), placement = {} })
		end
	end
	local jellies = {}
	for index, entry in list do
		local stranded = entry.at ~= nil
		local placement = entry.placement
		local look = Random.new(index * 97 + math.floor((entry.at or entry.path[1]).X))
		local color = JELLY_COLORS[look:NextInteger(1, #JELLY_COLORS)]
		local scale = look:NextNumber(0.9, 1.3)
		local bellSize = Vector3.new(3.2, if stranded then 1.8 else 2.4, 3.2) * scale
		local bell = makePart({
			Name = "JellyBell",
			Shape = Enum.PartType.Ball,
			Size = bellSize,
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.4,
		})
		local core = makePart({
			Name = "JellyCore",
			Shape = Enum.PartType.Ball,
			Size = bellSize * 0.55,
			Color = color:Lerp(Color3.new(1, 1, 1), 0.5),
			Material = Enum.Material.Neon,
			Transparency = 0.15,
		})
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 14
		light.Brightness = 1.5
		light.Parent = bell
		local tentacles = {}
		for k = 1, TENTACLES do
			local angle = k / TENTACLES * math.pi * 2
			local length = look:NextNumber(2.5, 4) * scale
			table.insert(tentacles, {
				offset = Vector3.new(
					math.cos(angle) * 0.9 * scale,
					-bellSize.Y * 0.5 - length / 2 + 0.3,
					math.sin(angle) * 0.9 * scale
				),
				part = makePart({
					Name = "JellyTentacle",
					Size = Vector3.new(0.18, length, 0.18),
					Color = color,
					Material = Enum.Material.Neon,
					Transparency = 0.5,
				}),
			})
		end
		local jelly = {
			bell = bell,
			core = core,
			tentacles = tentacles,
			bellSize = bellSize,
			stranded = stranded,
			at = entry.at,
			path = entry.path,
			phase = look:NextNumber(0, 100),
		}
		if stranded then
			local radius = placement.Radius or settings.Radius
			-- The glow on the sand: as far as the sting reaches.
			local ring = makePart({
				Name = "JellyGlow",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.15, radius * 2, radius * 2),
				Color = color,
				Material = Enum.Material.Neon,
				Transparency = 0.75,
			})
			arm(ring, settings)
			ring:SetAttribute("HitRadius", radius)
			jelly.hit, jelly.ring = ring, ring
			ring.Parent = folder
		else
			arm(bell, settings)
			bell:SetAttribute("HitRadius", placement.Radius or settings.HitRadius)
			jelly.hit = bell
			jelly.length = 0
			for i = 1, #entry.path - 1 do
				jelly.length += (entry.path[i + 1] - entry.path[i]).Magnitude
			end
		end
		jelly.hit:SetAttribute("Damage", placement.Damage or settings.Damage)
		jelly.hit:SetAttribute("Stun", settings.Stun)
		jelly.hit:SetAttribute("StunZone", settings.StunZone)
		bell.Parent = folder
		core.Parent = folder
		for _, t in tentacles do
			t.part.Parent = folder
		end
		table.insert(jellies, jelly)
	end
	if #jellies == 0 then
		return
	end
	local function place(j, now: number)
		local pulse = math.sin(now * 2.2 + j.phase)
		local at = j.at
		local y
		if j.stranded then
			y = Beach.groundAt(at.X, at.Y) + j.bellSize.Y * 0.4
		else
			at = if j.length > 0
				then HazardService.alongPath(j.path, (now + j.phase) * settings.Speed)
				else j.path[1]
			-- A little under the water's surface, and bobbing with its pulse.
			local ground = Beach.groundAt(at.X, at.Y)
			local surface = Beach.waterYAt(Tide.sea(), at.X)
			y = math.max(ground + 1.5, surface - 1.5) + pulse * 0.25
		end
		local squash = 1 + 0.12 * pulse
		j.bell.Size =
			Vector3.new(j.bellSize.X * (2 - squash), j.bellSize.Y * squash, j.bellSize.Z * (2 - squash))
		j.bell.CFrame = CFrame.new(at.X, y, at.Y)
		j.core.CFrame = CFrame.new(at.X, y, at.Y)
		j.bell.Transparency = 0.4 + 0.12 * pulse
		for _, t in j.tentacles do
			t.part.CFrame = CFrame.new(at.X + t.offset.X, y + t.offset.Y * squash, at.Y + t.offset.Z)
		end
		if j.ring then
			j.ring.CFrame = CFrame.new(at.X, Beach.groundAt(at.X, at.Y) + 0.1, at.Y)
				* CFrame.Angles(0, 0, math.pi / 2)
			j.ring.Transparency = 0.75 + 0.1 * pulse
		end
	end
	for _, j in jellies do
		place(j, 0)
	end
	table.insert(running, {
		folder = folder,
		step = function(now)
			for _, j in jellies do
				place(j, now)
			end
		end,
	})
end

-- Spears: a field of stone plates that glow and crack, then shoot a spear up, on a rhythm set by
-- the field's Pattern (see Hazards.luau). Each spot is on the same Period; the pattern only sets
-- when in the cycle a spot fires, so a wave can be run behind, a checkerboard hopped between,
-- rings stepped across. The plate is what hits (Active only while the spear is up).
local SPEAR_HEIGHT = 6
local SPEAR_RISE = 0.12 -- seconds a spear takes to shoot up
local SWEEP_SHARE = 0.75 -- the share of a Period a wave or ring takes to cross the field

-- When in the cycle (0-1 of the Period) a spot at (dx, dz) from the middle of a field fires.
local function spearFire(pattern: string, dx: number, dz: number, radius: number, spacing: number): number
	if pattern == "All" then
		return 0
	elseif pattern == "Checker" then
		local parity = (math.round(dx / spacing) + math.round(dz / spacing)) % 2
		return parity * 0.5
	elseif pattern == "Ring" then
		local rings = math.max(1, math.round(radius / spacing))
		return math.min(1, math.round(math.sqrt(dx * dx + dz * dz) / spacing) / rings) * SWEEP_SHARE
	end
	return math.clamp((dx + radius) / (2 * radius), 0, 1) * SWEEP_SHARE
end

function builders.Spears(tile, settings, folder)
	local spears = {}
	for _, spot in spotsFor(tile, "Spears", settings) do
		local placement = spot.placement
		local radius = placement.Radius or settings.Radius
		local pattern = placement.Pattern or settings.Pattern
		local damage = placement.Damage or settings.Damage
		local spacing = settings.Spacing
		local n = math.floor(radius / spacing)
		local scatter = Random.new(math.floor(spot.x * 7 + spot.z * 3))
		for i = -n, n do
			for j = -n, n do
				local dx, dz = i * spacing, j * spacing
				local x, z = spot.x + dx, spot.z + dz
				if dx * dx + dz * dz > radius * radius or Beach.feature(x, z) >= 2 then
					continue
				end
				local ground = Beach.groundAt(x, z)
				local hitRadius = settings.HitRadius
				local plate = makePart({
					Name = "SpearPlate",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(0.2, hitRadius * 2, hitRadius * 2),
					CFrame = CFrame.new(x, ground + 0.1, z) * CFrame.Angles(0, 0, math.pi / 2),
					Color = settings.Color,
					Material = Palette.Material.Rock,
				})
				arm(plate, settings)
				plate:SetAttribute("Damage", damage)
				plate:SetAttribute("Active", false)
				plate.Parent = folder
				local cracks = {}
				for k = 1, 2 do
					local crack = makePart({
						Name = "SpearCrack",
						Size = Vector3.new(0.18, 0.05, hitRadius * 1.9),
						CFrame = CFrame.new(x, ground + 0.24, z)
							* CFrame.Angles(0, k * 1.2 + scatter:NextNumber(-0.3, 0.3), 0),
						Color = Color3.fromRGB(255, 120, 50),
						Material = Enum.Material.Neon,
						Transparency = 1,
					})
					crack.Parent = folder
					table.insert(cracks, crack)
				end
				local shaft = makePart({
					Name = "Spear",
					Size = Vector3.new(0.9, SPEAR_HEIGHT - 1, 0.9),
					CFrame = CFrame.new(x, ground - SPEAR_HEIGHT, z),
					Color = settings.Color:Lerp(Color3.new(1, 1, 1), 0.2),
					Material = Palette.Material.Rock,
					Transparency = 1,
				})
				shaft.Parent = folder
				local tip = makePart({
					Name = "SpearTip",
					Size = Vector3.new(0.9, 0.9, 0.9),
					CFrame = CFrame.new(x, ground - SPEAR_HEIGHT, z),
					Color = settings.Color:Lerp(Color3.new(1, 1, 1), 0.45),
					Material = Palette.Material.Rock,
					Transparency = 1,
				})
				tip.Parent = folder
				table.insert(spears, {
					plate = plate,
					cracks = cracks,
					shaft = shaft,
					tip = tip,
					x = x,
					z = z,
					ground = ground,
					fire = spearFire(pattern, dx, dz, radius, spacing) * settings.Period,
					state = 0,
				})
			end
		end
	end
	if #spears == 0 then
		return
	end
	local idle = settings.Color
	table.insert(running, {
		folder = folder,
		step = function(now)
			for _, s in spears do
				local phase = (now - s.fire) % settings.Period
				local state = if phase < settings.Active
					then 2
					elseif phase >= settings.Period - settings.Warning then 1
					else 0
				if state == 1 then
					-- Glowing and cracking, flickering faster as it nears.
					local near = (phase - (settings.Period - settings.Warning)) / settings.Warning
					local flicker = 0.5 + 0.5 * math.sin(now * (8 + 14 * near))
					s.plate.Material = Enum.Material.Neon
					s.plate.Color = idle:Lerp(Color3.fromRGB(255, 110, 40), 0.5 + 0.5 * flicker)
					for _, crack in s.cracks do
						crack.Transparency = 0.1
					end
				elseif state ~= s.state then
					s.plate.Material = Palette.Material.Rock
					s.plate.Color = idle
					for _, crack in s.cracks do
						crack.Transparency = if state == 2 then 0.1 else 1
					end
				end
				if state == 2 then
					-- Up it shoots, quickly.
					local k = math.min(1, phase / SPEAR_RISE)
					local rise = SPEAR_HEIGHT * k
					local top = s.ground - 0.5 + rise
					s.shaft.CFrame = CFrame.new(s.x, top - (SPEAR_HEIGHT - 1) / 2, s.z)
					s.tip.CFrame = CFrame.new(s.x, top + 0.2, s.z) * CFrame.Angles(0.8, 0.8, 0)
					s.shaft.Transparency, s.tip.Transparency = 0, 0
				elseif s.state == 2 then
					s.shaft.Transparency, s.tip.Transparency = 1, 1
					s.shaft.CFrame = CFrame.new(s.x, s.ground - SPEAR_HEIGHT, s.z)
					s.tip.CFrame = s.shaft.CFrame
				end
				if state ~= s.state then
					s.state = state
					s.plate:SetAttribute("Active", state == 2)
				end
			end
		end,
	})
end

-- Whirlwind: a column of lifted sand circling its Path (a loop) at Speed (see Hazards.luau),
-- tall enough to be seen from far off. Whoever the Radius at its foot catches is flung
-- (HazardController). Without a placement, a loop is scattered round a spot on the tile.
local WHIRL_LAYERS = 8

function builders.Whirlwind(tile, settings, folder)
	local z0 = Beach.tileRange(tile)
	local loops = {}
	for _, placement in Layouts.hazardPlacements(tile, "Whirlwind") do
		local path = {}
		for _, point in placement.Path or {} do
			table.insert(path, Vector2.new(point[1], z0 + point[2]))
		end
		if #path >= 2 then
			table.insert(loops, { path = path, radius = placement.Radius or settings.Radius })
		end
	end
	if #loops == 0 and settings.Scatter then
		for _ = 1, settings.Count do
			local x, z = randomSpot(tile)
			local path = {}
			for k = 0, 7 do
				local angle = k / 8 * math.pi * 2
				table.insert(path, Vector2.new(x + math.cos(angle) * 25, z + math.sin(angle) * 25))
			end
			table.insert(loops, { path = path, radius = settings.Radius })
		end
	end
	local winds = {}
	for _, loop in loops do
		local closed = table.clone(loop.path)
		table.insert(closed, loop.path[1]) -- round and round, not back and forth
		local length = 0
		for i = 1, #closed - 1 do
			length += (closed[i + 1] - closed[i]).Magnitude
		end
		if length <= 0 then
			continue
		end
		local foot = makePart({
			Name = "Whirlwind",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, loop.radius * 2, loop.radius * 2),
			Color = settings.Color,
			Transparency = 1,
		})
		arm(foot, settings)
		foot:SetAttribute("HitRadius", loop.radius)
		local dust = Instance.new("ParticleEmitter")
		dust.Color = ColorSequence.new(settings.Color)
		dust.Size = NumberSequence.new(2.5, 5)
		dust.Transparency = NumberSequence.new(0.4, 1)
		dust.Lifetime = NumberRange.new(0.8, 1.4)
		dust.Rate = 40
		dust.Speed = NumberRange.new(6, 14)
		dust.SpreadAngle = Vector2.new(180, 180)
		dust.Parent = foot
		foot.Parent = folder
		-- The column: layers of swirling sand, wider the higher they go.
		local layers = {}
		for k = 1, WHIRL_LAYERS do
			local t = (k - 0.5) / WHIRL_LAYERS
			local width = loop.radius * (0.5 + 1.3 * t)
			local layer = makePart({
				Name = "WhirlwindSand",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(settings.Height / WHIRL_LAYERS, width, width),
				Color = settings.Color:Lerp(Color3.new(1, 1, 1), 0.15 * t),
				Material = Enum.Material.Sand,
				Transparency = 0.55 + 0.25 * t,
			})
			layer.Parent = folder
			table.insert(layers, { part = layer, t = t })
		end
		table.insert(winds, {
			foot = foot,
			layers = layers,
			closed = closed,
			length = length,
			radius = loop.radius,
			phase = rng:NextNumber(0, length),
		})
	end
	if #winds == 0 then
		return
	end
	local function place(w, now: number)
		local at = HazardService.alongPath(w.closed, (w.phase + now * settings.Speed) % w.length)
		local ground = Beach.groundAt(at.X, at.Y)
		w.foot.CFrame = CFrame.new(at.X, ground + 0.15, at.Y) * CFrame.Angles(0, 0, math.pi / 2)
		for _, layer in w.layers do
			-- Each layer swings round the axis, the higher the further: a leaning, twisting column.
			local swing = math.sin(now * 2.5 - layer.t * 3) * w.radius * 0.25 * layer.t
			local swirl = math.cos(now * 2.5 - layer.t * 3) * w.radius * 0.25 * layer.t
			layer.part.CFrame = CFrame.new(at.X + swing, ground + layer.t * settings.Height, at.Y + swirl)
				* CFrame.Angles(0, now * (1 + layer.t), math.pi / 2)
		end
	end
	for _, w in winds do
		place(w, 0)
	end
	table.insert(running, {
		folder = folder,
		step = function(now)
			for _, w in winds do
				place(w, now)
			end
		end,
	})
end

-- Ice: slippery patches, flat, pale blue-white and glossy, with a few lighter frost streaks. On
-- one you slide (HazardController reads its Grip). Nothing else happens on it: a cart doesn't
-- spill.
function builders.Ice(tile, settings, folder)
	for _, spot in spotsFor(tile, "Ice", settings) do
		local radius = spot.placement.Radius or settings.Radius
		local ground = Beach.groundAt(spot.x, spot.z)
		local ice = makePart({
			Name = "IcePatch",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.2, radius * 2, radius * 2),
			CFrame = CFrame.new(spot.x, ground + 0.1, spot.z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = settings.Color,
			Material = Enum.Material.Ice,
			Reflectance = 0.2,
			Transparency = 0.1,
		})
		arm(ice, settings)
		ice:SetAttribute("HitRadius", radius)
		ice:SetAttribute("Grip", settings.Grip)
		ice.Parent = folder
		local scatter = Random.new(math.floor(spot.x * 19 + spot.z * 23))
		for k = 1, math.clamp(math.floor(radius / 3), 2, 8) do
			local length = scatter:NextNumber(0.4, 0.9) * radius
			local angle = scatter:NextNumber() * math.pi
			local reach = scatter:NextNumber(0, radius * 0.4)
			local x = spot.x + math.cos(k * 2.1) * reach
			local z = spot.z + math.sin(k * 2.1) * reach
			makePart({
				Name = "Frost",
				Size = Vector3.new(0.25, 0.05, length),
				CFrame = CFrame.new(x, Beach.groundAt(x, z) + 0.24, z) * CFrame.Angles(0, angle, 0),
				Color = Color3.fromRGB(245, 250, 255),
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.35,
			}).Parent =
				folder
		end
	end
end

-- Fog: a foghorn (a lighthouse) at each spot (see Hazards.luau). The fog itself is the client's
-- (MistController): every player on the tile sees it close in to Sight studs, except while the
-- horn is pulsing. The horn part is tagged with the tile's range (ZMin, ZMax), Sight, Period and
-- Clear, and its Clearing attribute is true for Clear seconds from each pulse, on the server's
-- clock, so everyone sees the fog lift together. The lamp blinks faster for the last
-- FOG_WARN seconds before a pulse (the tell), and at the pulse a ring of light rolls out from
-- the tower.
local FOG_WARN = 2 -- seconds the lamp blinks before a pulse
local FOG_RING = 2.5 -- seconds the ring takes to roll out
local FOG_RING_REACH = 90 -- studs it rolls out to

function builders.Fog(tile, settings, folder)
	local z0, z1 = Beach.tileRange(tile)
	local horns = {}
	for _, spot in spotsFor(tile, "Fog", settings) do
		local ground = Beach.groundAt(spot.x, spot.z)
		local height = 30
		local tower = makePart({
			Name = "FoghornTower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, 6, 6),
			CFrame = CFrame.new(spot.x, ground + height / 2, spot.z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(235, 235, 230),
			Material = Palette.Material.Smooth,
			CanCollide = true,
			CanQuery = true,
		})
		tower.Parent = folder
		local band = makePart({
			Name = "FoghornBand",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(6, 6.4, 6.4),
			CFrame = CFrame.new(spot.x, ground + height * 0.55, spot.z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(190, 60, 55),
			Material = Palette.Material.Smooth,
		})
		band.Parent = folder
		local lamp = makePart({
			Name = "FoghornLamp",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(5, 5, 5),
			CFrame = CFrame.new(spot.x, ground + height + 2, spot.z),
			Color = Color3.fromRGB(255, 240, 180),
			Material = Enum.Material.Neon,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 240, 180)
		light.Range = 40
		light.Brightness = 3
		light.Parent = lamp
		lamp.Parent = folder
		local ring = makePart({
			Name = "FoghornRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 2, 2),
			CFrame = CFrame.new(spot.x, ground + 1.5, spot.z) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(255, 250, 220),
			Material = Enum.Material.Neon,
			Transparency = 1,
		})
		ring.Parent = folder
		-- What the client reads: it's armed like any hazard but hits no one (HitRadius 0).
		local horn = makePart({
			Name = "Foghorn",
			Size = Vector3.new(1, 1, 1),
			CFrame = CFrame.new(spot.x, ground + height, spot.z),
			Transparency = 1,
		})
		arm(horn, settings)
		horn:SetAttribute("Sight", settings.Sight)
		horn:SetAttribute("Period", settings.Period)
		horn:SetAttribute("Clear", settings.Clear)
		horn:SetAttribute("ZMin", z0)
		horn:SetAttribute("ZMax", z1)
		horn:SetAttribute("Clearing", false)
		horn.Parent = folder
		table.insert(
			horns,
			{ horn = horn, lamp = lamp, ring = ring, x = spot.x, z = spot.z, ground = ground }
		)
	end
	if #horns == 0 then
		return
	end
	table.insert(running, {
		folder = folder,
		step = function(now)
			-- (Phase 0 of each Period is the pulse; the clock is the same for every horn.)
			local phase = now % settings.Period
			local clearing = phase < settings.Clear
			local untilPulse = settings.Period - phase
			for _, h in horns do
				if h.horn:GetAttribute("Clearing") ~= clearing then
					h.horn:SetAttribute("Clearing", clearing)
				end
				-- The lamp: steady, blinking faster before a pulse, flaring at it.
				local blink = if untilPulse < FOG_WARN then math.sin(now * 18) > 0 else true
				h.lamp.Transparency = if clearing then 0 elseif blink then 0.15 else 0.8
				-- The ring of light rolling out, fading as it goes.
				if phase < FOG_RING then
					local k = phase / FOG_RING
					local size = 4 + k * FOG_RING_REACH * 2
					h.ring.Size = Vector3.new(0.4, size, size)
					h.ring.Transparency = 0.2 + 0.8 * k
				elseif h.ring.Transparency < 1 then
					h.ring.Transparency = 1
				end
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
			(effect ~= "Harm" and effect ~= "Sink" and effect ~= "Sting")
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
