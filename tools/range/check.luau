--[[
	The Test Range check: runs inside the real Roblox engine (Open Cloud Luau Execution, in the
	Test Range place, see tools/range/run.py) and checks one zone of the beach as the game
	builds it: real terrain, real props and biomes, real raycasts and real pathfinding.

	run.py puts the job in front of this script as JOB_JSON:
	  { zone = 4, tiles = { ["13"] = "HermitHollows", ... }, tides = { 1800, 2100 }, routes = true }
	A tile's entry is "Base", a biome id, or a layout module path under Layouts
	("Biomes/Planned/TidepoolRocks", "Zones/Zone5"); tiles of the zone not named keep "Base".

	It returns a report (JSON): problems (things that are wrong) and measurements.
]]

local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local JOB = HttpService:JSONDecode(JOB_JSON) -- luacheck: ignore (set by run.py)

local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Layouts = require(Shared.Layouts)

local report = { job = JOB, problems = {}, measurements = {}, notes = {} }
local MAX_EXAMPLES = 25

local function problem(kind: string, text: string)
	report.problems[kind] = report.problems[kind] or { count = 0, examples = {} }
	local entry = report.problems[kind]
	entry.count += 1
	if #entry.examples < MAX_EXAMPLES then
		table.insert(entry.examples, text)
	end
end

local function fmt(v: Vector3): string
	return string.format("(%.0f, %.1f, %.0f)", v.X, v.Y, v.Z)
end

-- Building -----------------------------------------------------------------------------------

local zone = JOB.zone
local zStart, zEnd = Beach.zoneRange(zone)
local perZone = Config.Beach.TilesPerZone
local firstTile = (zone - 1) * perZone + 1

local function findLayout(path: string): any
	local node: Instance = Shared.Layouts
	for part in string.gmatch(path, "[^/]+") do
		node = node:FindFirstChild(part) :: Instance
		assert(node, "no layout module at Layouts/" .. path)
	end
	local value = require(node :: ModuleScript)
	if value.Primitives then
		return value
	end
	-- A table of layouts by zone: the nearest at or above this zone.
	for index = zone, 1, -1 do
		if value[index] then
			return value[index]
		end
	end
	error("Layouts/" .. path .. " has no layout for zone " .. zone)
end

local t0 = os.clock()
require(Server.BeachBuilder).build()
local HazardService = require(Server.HazardService)
local BiomeService = require(Server.BiomeService)
BiomeService.init(function() end, function() end)
-- Everything plain, then this zone's tiles as asked.
for tile = 1, Beach.ActiveTiles do
	BiomeService.set(tile, nil)
end
local TerrainBuilder = require(Server.TerrainBuilder)
local tileSpecs = {}
for tile = firstTile, firstTile + perZone - 1 do
	local spec = (JOB.tiles and JOB.tiles[tostring(tile)]) or JOB.all or "Base"
	tileSpecs[tostring(tile)] = spec
	if spec == "Base" then
		continue
	elseif require(Shared.Biomes).List[spec] then
		BiomeService.set(tile, spec)
	else
		Layouts.setActive(tile, findLayout(spec))
		TerrainBuilder.buildTile(tile)
	end
end
report.measurements.tiles = tileSpecs
task.wait(3) -- terrain collision catches up with the voxels
report.measurements.buildSeconds = os.clock() - t0

-- Ground ---------------------------------------------------------------------------------------

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Workspace.Terrain }

-- The real terrain surface under (x, z), looking down from `fromY`, or from just over the
-- layout's ground (under any roof). Nil where there's no room to look from: a wall that
-- meets a roof is solid all the way up.
local function surfaceAt(x: number, z: number, fromY: number?): number?
	local y = fromY
	if not y then
		y = Beach.groundAt(x, z) + 3
		local roofBottom = Beach.roofAt(x, z)
		if roofBottom and y > roofBottom - 0.5 then
			return nil
		end
	end
	local hit = Workspace:Raycast(Vector3.new(x, y, z), Vector3.new(0, -200, 0), terrainOnly)
	return hit and hit.Position.Y
end

-- How steep the layout's ground is at (x, z): rise over run.
local function steepness(x: number, z: number): number
	local dx = Beach.groundAt(x + 2, z) - Beach.groundAt(x - 2, z)
	local dz = Beach.groundAt(x, z + 2) - Beach.groundAt(x, z - 2)
	return math.sqrt(dx * dx + dz * dz) / 4
end

-- How solid the terrain is around a point (0 to 1).
local function solidity(point: Vector3): number
	local region = Region3.new(point - Vector3.new(1, 1, 1), point + Vector3.new(1, 1, 1)):ExpandToGrid(4)
	local _, occupancy = Workspace.Terrain:ReadVoxels(region, 4)
	local total, count = 0, 0
	for x = 1, occupancy.Size.X do
		for y = 1, occupancy.Size.Y do
			for z = 1, occupancy.Size.Z do
				total += occupancy[x][y][z]
				count += 1
			end
		end
	end
	return if count > 0 then total / count else 0
end

-- How far the real terrain sits from the layout's ground, across the zone: large gaps mean the
-- terrain doesn't match what the water and items think the ground is.
do
	local worst, sum, n = 0, 0, 0
	for z = zStart + 4, zEnd - 4, 16 do
		for x = -320, 320, 32 do
			-- Only gentle ground: on a steep side, a stud across is a long way up.
			local roofBottom = Beach.roofAt(x, z)
			local walled = roofBottom ~= nil and Beach.groundAt(x, z) + 3 > roofBottom - 0.5
			local real = if steepness(x, z) < 0.3 and not walled then surfaceAt(x, z) else nil
			if real then
				local gap = real - Beach.groundAt(x, z)
				sum += math.abs(gap)
				n += 1
				if math.abs(gap) > math.abs(worst) then
					worst = gap
				end
				if math.abs(gap) > 2.5 then
					problem(
						"terrain off its layout",
						string.format(
							"at x %d, z %d the terrain is %.1f studs from the layout's ground",
							x,
							z,
							gap
						)
					)
				end
			elseif steepness(x, z) < 0.3 and not walled then
				problem("no terrain", string.format("nothing under x %d, z %d", x, z))
			end
		end
	end
	report.measurements.terrainOffset = { average = if n > 0 then sum / n else 0, worst = worst }

	-- Roofs: is the underside where the layout puts it? (Looking up from the floor.)
	local roofWorst, roofCount = 0, 0
	for z = zStart + 4, zEnd - 4, 8 do
		for x = -340, 340, 8 do
			local roofBottom = Beach.roofAt(x, z)
			local floor = Beach.groundAt(x, z)
			-- Away from the roof's edges, which follow the terrain's 4-stud cells.
			local inside = roofBottom ~= nil
			for _, o in { { 6, 0 }, { -6, 0 }, { 0, 6 }, { 0, -6 } } do
				inside = inside and Beach.roofAt(x + o[1], z + o[2]) ~= nil
			end
			if inside and floor + 3 < (roofBottom :: number) - 1 and steepness(x, z) < 0.3 then
				local hit =
					Workspace:Raycast(Vector3.new(x, floor + 3, z), Vector3.new(0, 60, 0), terrainOnly)
				roofCount += 1
				if not hit then
					problem("roof missing", string.format("no roof over x %d, z %d", x, z))
				else
					local gap = hit.Position.Y - roofBottom
					if math.abs(gap) > math.abs(roofWorst) then
						roofWorst = gap
					end
					if math.abs(gap) > 2.5 then
						problem(
							"roof off its layout",
							string.format(
								"at x %d, z %d the roof's underside is %.1f studs from the layout's",
								x,
								z,
								gap
							)
						)
					end
				end
			end
		end
	end
	report.measurements.roofOffset = { checked = roofCount, worst = roofWorst }

	-- Walls: as wide as the layout says? Measured across each wall where nothing's overhead.
	local widths = {}
	for tile = firstTile, firstTile + perZone - 1 do
		local layout = Layouts.active(tile)
		local z0 = Beach.tileRange(tile)
		for _, p in (layout and layout.Primitives) or {} do
			if p.Kind ~= "Wall" then
				continue
			end
			for i = 1, #p.Path - 1 do
				for _, t in { 0.3, 0.7 } do
					local a = Vector3.new(p.Path[i][1], 0, z0 + p.Path[i][2])
					local b = Vector3.new(p.Path[i + 1][1], 0, z0 + p.Path[i + 1][2])
					local middle = a:Lerp(b, t)
					local across = Vector3.new(-(b - a).Unit.Z, 0, (b - a).Unit.X)
					if
						Beach.roofAt(middle.X, middle.Z)
						or Beach.feature(middle.X, middle.Z) < p.Height * 0.9
					then
						continue -- under a roof, or cut by a ramp
					end
					local base = Beach.groundY(middle.Z)
					local fromY = base + p.Height + 5
					local first, last = nil, nil
					for d = -(p.Width / 2 + 8), p.Width / 2 + 8, 0.5 do
						local point = middle + across * d
						local top = surfaceAt(point.X, point.Z, fromY)
						if top and top > Beach.groundY(point.Z) + p.Height / 2 then
							first = first or d
							last = d
						end
					end
					if first then
						local drawn = last - first
						table.insert(widths, { designed = p.Width, drawn = drawn })
						if math.abs(drawn - p.Width) > 3 then
							problem(
								"wall width off",
								string.format(
									"tile %d: a wall meant to be %d wide is %.1f wide at x %.0f, z %.0f",
									tile,
									p.Width,
									drawn,
									middle.X,
									middle.Z
								)
							)
						end
					else
						problem(
							"wall missing",
							string.format("tile %d: no wall at x %.0f, z %.0f", tile, middle.X, middle.Z)
						)
					end
				end
			end
		end
	end
	report.measurements.wallWidths = widths
end

-- Props: floating, buried, inside rock --------------------------------------------------------

local SKIP_FOLDERS = { MapEdge = true, SandPatches = true, BiomeShowcase = true, Shop = true }

local function units(): { { name: string, cframe: CFrame, size: Vector3, instance: Instance } }
	local list = {}
	local function consider(instance: Instance)
		local cframe, size
		if instance:IsA("Model") then
			cframe, size = instance:GetBoundingBox()
		elseif instance:IsA("BasePart") then
			if instance.Transparency >= 1 then
				return
			end
			cframe, size = instance.CFrame, instance.Size
		else
			return
		end
		if cframe.Position.Z >= zStart and cframe.Position.Z <= zEnd then
			table.insert(
				list,
				{ name = instance:GetFullName(), cframe = cframe, size = size, instance = instance }
			)
		end
	end
	local function visit(container: Instance)
		for _, child in container:GetChildren() do
			if child:IsA("Folder") then
				if not SKIP_FOLDERS[child.Name] then
					visit(child)
				end
			else
				consider(child)
			end
		end
	end
	visit(Workspace.Map)
	if Workspace:FindFirstChild("Biomes") then
		visit(Workspace.Biomes)
	end
	return list
end

do
	local checked = 0
	for _, unit in units() do
		checked += 1
		local cframe, size = unit.cframe, unit.size
		-- The box's lowest corners and middle, in the world.
		local corners = {}
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				for _, sy in { -1, 1 } do
					table.insert(
						corners,
						cframe * Vector3.new(sx * size.X / 2, sy * size.Y / 2, sz * size.Z / 2)
					)
				end
			end
		end
		local bottom, top = math.huge, -math.huge
		for _, c in corners do
			bottom = math.min(bottom, c.Y)
			top = math.max(top, c.Y)
		end
		local centre = cframe.Position
		local ground = surfaceAt(
			centre.X,
			centre.Z,
			math.min(top + 1, (Beach.roofAt(centre.X, centre.Z) or math.huge) - 0.5)
		)
		if ground then
			if top < ground - 0.2 then
				problem(
					"buried",
					string.format(
						"%s at %s is under the ground (its top %.1f below it)",
						unit.name,
						fmt(centre),
						ground - top
					)
				)
			elseif bottom > ground + 1 then
				-- Floating, unless it's resting on something else.
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { unit.instance }
				local under = Workspace:Raycast(
					Vector3.new(centre.X, bottom + 0.1, centre.Z),
					Vector3.new(0, -(bottom - ground), 0),
					params
				)
				if not under or under.Instance == Workspace.Terrain then
					problem(
						"floating",
						string.format(
							"%s at %s floats %.1f studs over the ground",
							unit.name,
							fmt(centre),
							bottom - ground
						)
					)
				end
			end
		end
		if solidity(centre) > 0.85 and centre.Y > Beach.groundAt(centre.X, centre.Z) + 1 then
			problem("inside rock", string.format("%s at %s is inside a wall or roof", unit.name, fmt(centre)))
		end
	end
	report.measurements.propsChecked = checked
end

-- Hazards: creatures walking through walls ----------------------------------------------------

do
	local creatures = 0
	for tile = firstTile, firstTile + perZone - 1 do
		local folder = BiomeService.tileFolder(tile)
		if folder then
			for _, model in folder:GetChildren() do
				if model:IsA("Model") and model.Name == "Creature" then
					creatures += 1
				end
			end
		end
		local z0 = Beach.tileRange(tile)
		for _, placement in Layouts.hazardPlacements(tile, "Patrol") do
			for i = 1, #placement.Path - 1 do
				local a, b = placement.Path[i], placement.Path[i + 1]
				for t = 0, 1, 0.05 do
					local x = a[1] + (b[1] - a[1]) * t
					local z = z0 + a[2] + (b[2] - a[2]) * t
					if Beach.feature(x, z) > 3 then
						problem(
							"patrol route blocked",
							string.format(
								"tile %d: a patrol route crosses raised ground at x %.0f, z %.0f",
								tile,
								x,
								z
							)
						)
						break
					end
				end
			end
		end
	end
	report.measurements.creatures = creatures
end

-- Water at each tide -------------------------------------------------------------------------

local waist = Config.Beach.WaistDepth
local tides = JOB.tides or { zStart, (zStart + zEnd) / 2, zEnd, Config.Tide.LowWaterline }
report.measurements.tides = {}
for _, line in tides do
	local waterY = Beach.waterY(line)
	local cells, wet, deep, roofed, roofedFlooded = 0, 0, 0, 0, 0
	for z = zStart + 2, zEnd - 2, 8 do
		for x = -340, 340, 8 do
			local depth = waterY - Beach.groundAt(x, z)
			cells += 1
			wet += if depth > 0 then 1 else 0
			deep += if depth >= waist then 1 else 0
			if Beach.roofAt(x, z) then
				roofed += 1
				roofedFlooded += if depth > 0 then 1 else 0
			end
		end
	end
	table.insert(report.measurements.tides, {
		waterline = line,
		underWater = wet / cells,
		tooDeep = deep / cells,
		tunnelsFlooded = if roofed > 0 then roofedFlooded / roofed else nil,
	})
end

-- Paths on foot ------------------------------------------------------------------------------

local function wadingSpeed(depth: number): number
	local points = Config.Beach.Wading
	if depth <= points[1].Depth then
		return points[1].Speed
	end
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		if depth < b.Depth then
			return a.Speed + (b.Speed - a.Speed) * (depth - a.Depth) / (b.Depth - a.Depth)
		end
	end
	return points[#points].Speed
end

local WALK = 20
local footSlope = Config.Beach.Terrain.FootSlope

-- A path from one point to another: its length, the time it takes walking (slowed by wading
-- at the dry tide, or at `line`), its steepest climb and its deepest water.
local function route(from: Vector3, to: Vector3, line: number?)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = false,
		WaypointSpacing = 6,
	})
	local ok, err = pcall(function()
		path:ComputeAsync(from, to)
	end)
	if not ok then
		return { status = "error: " .. tostring(err) }
	end
	if path.Status ~= Enum.PathStatus.Success then
		return { status = path.Status.Name }
	end
	local points = path:GetWaypoints()
	local length, seconds, steepest, deepest = 0, 0, 0, 0
	local waterY = if line then Beach.waterY(line) else -math.huge
	for i = 2, #points do
		local a, b = points[i - 1].Position, points[i].Position
		local across = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
		local climb = b.Y - a.Y
		length += (b - a).Magnitude
		if across > 0.5 and points[i].Action ~= Enum.PathWaypointAction.Jump then
			steepest = math.max(steepest, climb / across)
		end
		local depth = math.max(0, waterY - Beach.groundAt(b.X, b.Z))
		deepest = math.max(deepest, depth)
		seconds += (b - a).Magnitude / (WALK * wadingSpeed(depth))
	end
	return {
		status = "Success",
		length = length,
		seconds = seconds,
		steepest = steepest,
		deepest = deepest,
		waypoints = #points,
	}
end

local function standAt(x: number, z: number): Vector3
	return Vector3.new(x, Beach.groundAt(x, z) + 3, z)
end

if JOB.routes ~= false then
	local crossings = {}
	local fastest = math.huge
	for _, x in JOB.starts or { -280, -200, -100, 0, 100, 180, 280 } do
		local from = standAt(x, zStart + 3)
		local best
		for _, gx in { x, -200, 180 } do
			local result = route(from, standAt(gx, zEnd - 3))
			if result.status == "Success" and (not best or result.seconds < best.seconds) then
				best = result
				best.to = gx
			end
		end
		if best then
			fastest = math.min(fastest, best.seconds)
			if best.steepest > footSlope * 1.15 then
				problem(
					"path too steep",
					string.format(
						"from x %d: the pathfinder climbs a %.2f slope, steeper than players can (%.2f)",
						x,
						best.steepest,
						footSlope
					)
				)
			end
			table.insert(crossings, { from = x, to = best.to, seconds = best.seconds, length = best.length })
		else
			problem(
				"no way across",
				string.format("from x %d at the top of zone %d there's no path to the bottom", x, zone)
			)
			table.insert(crossings, { from = x, seconds = nil })
		end
	end
	local target = Config.Zones[zone] and Config.Zones[zone].CrossTime
	report.measurements.crossing = {
		fastestSeconds = if fastest < math.huge then fastest else nil,
		perStart = crossings,
		targetSeconds = target,
		-- Each tile of the zone is crossed in turn: the zone takes about the tile times added.
	}
	-- Entrances and loot spots: reachable on foot from the top of the zone?
	local spots = {}
	for tile = firstTile, firstTile + perZone - 1 do
		local z0 = Beach.tileRange(tile)
		for _, e in Layouts.entrances(tile, z0) do
			table.insert(spots, { kind = "entrance", x = e.X, z = e.Y })
		end
		for _, l in Layouts.lootSpots(tile, z0) do
			table.insert(spots, { kind = "loot", x = l.X, z = l.Z })
		end
	end
	for _, spot in spots do
		local result = route(standAt(0, zStart + 3), standAt(spot.x, spot.z))
		if result.status ~= "Success" then
			problem(
				"unreachable spot",
				string.format(
					"%s spot at x %.0f, z %.0f can't be reached on foot (%s)",
					spot.kind,
					spot.x,
					spot.z,
					result.status
				)
			)
		end
	end
	report.measurements.spotsChecked = #spots
end

report.measurements.seconds = os.clock() - t0
return HttpService:JSONEncode(report)
