-- Draws the sea locally, from the same shared clock the server uses, so nothing replicates.
-- It draws, across the whole beach:
--   * the sea surface, at the local water level (parts of the beach drain at different times,
--     Config.Tide.Sections), so the waterline curves along the beach;
--   * wave crests rolling in toward the waterline, taller for bigger waves;
--   * the swash: the thin sheet of water a wave pushes up the sand, with a foam edge, which
--     slides back afterwards;
--   * wet sand, from the waterline up to where the tide or the last waves reached.
-- Each of these is one continuous surface (an EditableMesh) whose points are moved every
-- frame, so the waterline and the foam are smooth curves that follow the ground. The water is
-- worked out at columns every SAMPLE studs along the shore and drawn at twice that detail.
-- On a device that can't make editable meshes, it falls back to flat strips, one per STRIP
-- studs of shoreline.
-- It also warns the player when a rogue wave is on its way.

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Palette = require(Shared.Palette)
local Tide = require(Shared.Tide)
local Waves = require(Shared.Waves)
local WaterObstacles = require(Shared.WaterObstacles)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local SeaController = {}

local beach = Config.Beach
local waves = Config.Waves

local STRIP = 24 -- studs along the shoreline per strip
local SEGMENTS = 5 -- pieces per strip for the run-up sheet and the wet sand
local THICKNESS = 4
local SIDE = 700 -- sea beyond the beach on each side, past the headlands
local TILT = CFrame.Angles(math.atan(beach.Slope), 0, 0) -- lies flat on the sloping sand
local FAR = CFrame.new(0, -10000, 0)

local SWASH = Palette.World.Sea:Lerp(Color3.new(1, 1, 1), 0.35)

type Strip = {
	x: number,
	width: number,
	sea: Part,
	swash: { Part },
	edge: Part,
	wet: { Part },
	crests: { Part },
}

local strips: { Strip } = {}
local zMin, zMax = 0, 0

local function makePart(name: string, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = FAR
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function newStrip(folder: Folder, x: number, width: number, detailed: boolean): Strip
	local strip: Strip = {
		x = x,
		width = width,
		sea = makePart("Sea", {
			Size = Vector3.new(width + 0.05, THICKNESS, zMax - zMin),
			Material = Palette.Material.Glass,
			Color = Palette.World.Sea,
			Transparency = 0.3,
		}),
		swash = {},
		edge = nil :: any,
		wet = {},
		crests = {},
	}
	strip.sea.Parent = folder
	if detailed then
		-- The run-up sheet and the wet sand are a few short pieces each, so they can follow
		-- the shape of the ground instead of cutting through ridges or floating over dips.
		for i = 1, SEGMENTS do
			strip.swash[i] = makePart("Swash", {
				Size = Vector3.new(width + 0.05, 0.1, 1),
				Material = Palette.Material.Glass,
				Color = SWASH,
				Transparency = 0.45,
			})
			strip.swash[i].Parent = folder
			strip.wet[i] = makePart("WetSand", {
				Size = Vector3.new(width + 0.05, 0.06, 1),
				Material = Palette.Material.Sand,
				Color = Palette.World.WetSand,
				Transparency = 0.45,
			})
			strip.wet[i].Parent = folder
		end
		strip.edge = makePart("Foam", {
			Size = Vector3.new(width + 0.05, 0.14, 1.4),
			Material = Palette.Material.Smooth,
			Color = Palette.World.Foam,
			Transparency = 0.25,
		})
		for i = 1, 2 do
			local crest = makePart("Crest" .. i, {
				Size = Vector3.new(width + 0.05, 0.6, 2.5),
				Material = Palette.Material.Smooth,
				Color = Palette.World.Foam,
				Transparency = 0.4,
			})
			crest.Parent = folder
			strip.crests[i] = crest
		end
		strip.edge.Parent = folder
	end
	return strip
end

-- The height of the sand as it's actually drawn. Smooth Terrain is built from 4-stud cells,
-- so its surface can sit a stud or so off Beach.groundAt; the water drawn on it follows the
-- real surface. Measured once per point of a 2-stud grid (it never changes) by a ray straight
-- down, and blended smoothly between grid points.
local GRID = 2
local surfaceCache: { [number]: number } = {}
local surfaceParams = RaycastParams.new()
surfaceParams.FilterType = Enum.RaycastFilterType.Include
local function gridY(ix: number, iz: number): number
	local key = ix * 65536 + iz
	local cached = surfaceCache[key]
	if cached then
		return cached
	end
	local x, z = ix * GRID, iz * GRID
	local y = Beach.groundAt(x, z)
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		surfaceParams.FilterDescendantsInstances = { terrain }
		local hit = Workspace:Raycast(Vector3.new(x, y + 30, z), Vector3.new(0, -60, 0), surfaceParams)
		if hit then
			y = hit.Position.Y
		end
	end
	surfaceCache[key] = y
	return y
end

local function surfaceY(x: number, z: number): number
	local fx, fz = x / GRID, z / GRID
	local ix, iz = math.floor(fx), math.floor(fz)
	local tx, tz = fx - ix, fz - iz
	local a = gridY(ix, iz) + (gridY(ix, iz + 1) - gridY(ix, iz)) * tz
	if tx < 1e-6 then
		return a
	end
	local b = gridY(ix + 1, iz) + (gridY(ix + 1, iz + 1) - gridY(ix + 1, iz)) * tz
	return a + (b - a) * tx
end

-- Lays a run of thin parts on the sand from z0 to z1 (z1 < z0: up the beach), each piece
-- spanning between two points on the real surface. Pieces too short to see are put away.
local function onSand(
	pieces: { Part },
	x: number,
	z0: number,
	z1: number,
	lift: number,
	place: (Part, CFrame) -> ()
)
	local count = #pieces
	for i = 1, count do
		local za = z0 + (z1 - z0) * (i - 1) / count
		local zb = z0 + (z1 - z0) * i / count
		local a = Vector3.new(x, surfaceY(x, za) + lift, za)
		local b = Vector3.new(x, surfaceY(x, zb) + lift, zb)
		local piece = pieces[i]
		local length = (b - a).Magnitude
		if length < 0.05 then
			place(piece, FAR)
			continue
		end
		if math.abs(piece.Size.Z - (length + 0.15)) > 0.1 then
			piece.Size = Vector3.new(piece.Size.X, piece.Size.Y, length + 0.15)
		end
		place(piece, CFrame.lookAt((a + b) / 2, b))
	end
end

local function setTransparency(part: Part, value: number)
	if math.abs(part.Transparency - value) > 0.02 then
		part.Transparency = value
	end
end

-- The continuous surfaces -------------------------------------------------------------------

local SAMPLE = 12 -- studs along the shore between the columns where the water is worked out
local SEA_STEP = 8 -- studs between the sea surface's columns over the beach
local SWASH_ROWS = 7 -- points across the run-up sheet and the wet sand
local CREST_SLOTS = 2 -- crest ribbons (a rolling wave uses slot Index % CREST_SLOTS)

-- A sheet: a grid of points (columns along the shore, rows across) drawn as one MeshPart.
-- Its points are given in world space each frame. Both faces are drawn.
type Sheet = {
	mesh: any,
	part: MeshPart,
	center: Vector3,
	half: Vector3,
	ids: { number },
	points: { Vector3 },
	cols: number,
	rows: number,
	batch: boolean,
}

local function newSheet(
	folder: Instance,
	name: string,
	cols: number,
	rows: number,
	low: Vector3,
	high: Vector3,
	props: { [string]: any }
): Sheet
	local mesh = AssetService:CreateEditableMesh()
	assert(mesh, "no memory for an editable mesh")
	local center = (low + high) / 2
	local half = (high - low) / 2
	local ids, points = table.create(cols * rows), table.create(cols * rows)
	for i = 1, cols * rows do
		ids[i] = mesh:AddVertex(Vector3.zero)
		points[i] = center
	end
	for c = 1, cols - 1 do
		for r = 1, rows - 1 do
			local v00 = ids[(c - 1) * rows + r]
			local v01 = ids[(c - 1) * rows + r + 1]
			local v10 = ids[c * rows + r]
			local v11 = ids[c * rows + r + 1]
			mesh:AddTriangle(v00, v10, v01)
			mesh:AddTriangle(v10, v11, v01)
			mesh:AddTriangle(v00, v01, v10)
			mesh:AddTriangle(v10, v01, v11)
		end
	end
	-- A flat, invisible triangle across the whole box, so the mesh's bounds (and so its scale
	-- and centre) stay fixed however its points move.
	mesh:AddTriangle(mesh:AddVertex(-half), mesh:AddVertex(half), mesh:AddVertex(Vector3.zero))
	local part = AssetService:CreateMeshPartAsync(Content.fromObject(mesh))
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Size = part.MeshSize
	part.CFrame = CFrame.new(center)
	part.Parent = folder
	return {
		mesh = mesh,
		part = part,
		center = center,
		half = half,
		ids = ids,
		points = points,
		cols = cols,
		rows = rows,
		batch = true,
	}
end

local function setPoint(sheet: Sheet, col: number, row: number, point: Vector3)
	sheet.points[(col - 1) * sheet.rows + row] = point
end

-- Moves the sheet's points to where they were set this frame.
local function flush(sheet: Sheet)
	local center, half = sheet.center, sheet.half
	local count = #sheet.ids
	local values = table.create(count)
	for i = 1, count do
		local p = sheet.points[i] - center
		values[i] = Vector3.new(
			math.clamp(p.X, -half.X, half.X),
			math.clamp(p.Y, -half.Y, half.Y),
			math.clamp(p.Z, -half.Z, half.Z)
		)
	end
	if sheet.batch then
		local ok = pcall(sheet.mesh.BatchSetValues, sheet.mesh, sheet.ids, values)
		if ok then
			return
		end
		sheet.batch = false
	end
	for i = 1, count do
		sheet.mesh:SetPosition(sheet.ids[i], values[i])
	end
end

type Meshes = {
	sea: Sheet,
	seaXs: { number },
	swash: Sheet,
	foam: Sheet,
	wet: Sheet,
	crests: { Sheet },
	xs: { number }, -- the drawn columns over the beach
	samples: { number }, -- the columns where the water is worked out (every other drawn one)
}

local meshes: Meshes? = nil

local function buildMeshes(folder: Folder): Meshes
	local half = Beach.HalfWidth
	local samples = {}
	local count = math.ceil(beach.Width / SAMPLE)
	for i = 0, count do
		table.insert(samples, -half + beach.Width * i / count)
	end
	local xs = {}
	for i, x in samples do
		table.insert(xs, x)
		if samples[i + 1] then
			table.insert(xs, (x + samples[i + 1]) / 2)
		end
	end
	local seaXs = { -half - SIDE }
	local seaCount = math.ceil(beach.Width / SEA_STEP)
	for i = 0, seaCount do
		table.insert(seaXs, -half + beach.Width * i / seaCount)
	end
	table.insert(seaXs, half + SIDE)

	local low = Beach.groundY(zMax) - 40
	local beachLow = Vector3.new(-half - 1, low, zMin)
	local beachHigh = Vector3.new(half + 1, 20, zMax)
	local result: Meshes = {
		sea = newSheet(
			folder,
			"Sea",
			#seaXs,
			2,
			Vector3.new(-half - SIDE - 1, low, zMin),
			Vector3.new(half + SIDE + 1, 20, zMax),
			{
				Material = Palette.Material.Glass,
				Color = Palette.World.Sea,
				Transparency = 0.3,
			}
		),
		seaXs = seaXs,
		swash = newSheet(folder, "Swash", #xs, SWASH_ROWS, beachLow, beachHigh, {
			Material = Palette.Material.Glass,
			Color = SWASH,
			Transparency = 0.45,
		}),
		foam = newSheet(folder, "Foam", #xs, 3, beachLow, beachHigh, {
			Material = Palette.Material.Smooth,
			Color = Palette.World.Foam,
			Transparency = 0.25,
		}),
		wet = newSheet(folder, "WetSand", #xs, SWASH_ROWS, beachLow, beachHigh, {
			Material = Palette.Material.Sand,
			Color = Palette.World.WetSand,
			Transparency = 0.45,
		}),
		crests = {},
		xs = xs,
		samples = samples,
	}
	for i = 1, CREST_SLOTS do
		result.crests[i] = newSheet(folder, "Crest" .. i, #xs, 3, beachLow, beachHigh, {
			Material = Palette.Material.Smooth,
			Color = Palette.World.Foam,
			Transparency = 0.35,
		})
	end
	return result
end

-- The water at one sample column.
type Column = {
	line: number,
	waterY: number,
	edge: number, -- how far up the sand the swash reaches (0 or negative, from the waterline)
	wetTo: number, -- Z the wet sand reaches up to
	crestZ: { number? }, -- per crest slot: where its crest is (nil: none)
	crestH: { number },
}

local function sampleColumn(x: number, sea: Tide.Sea, wetSea: Tide.Sea): Column
	local line = Tide.waterlineAt(sea, x)
	local waterY = Beach.waterY(line)
	local column: Column = { line = line, waterY = waterY, edge = 0, wetTo = line, crestZ = {}, crestH = {} }
	for i = 1, CREST_SLOTS do
		column.crestH[i] = 0
	end
	local list = Waves.wavesAt(x, sea, line)
	for _, wave in list do
		if wave.Phase == "Rolling" then
			-- Crests vanish where something solid shelters the water from the sea, and grow
			-- as the wave nears the shore.
			local z = line + wave.Front + 1.2
			local slot = wave.Index % CREST_SLOTS + 1
			if not WaterObstacles.sheltered(x, z, waterY) then
				column.crestZ[slot] = z
				column.crestH[slot] = (0.35 + 0.35 * wave.Size) * (0.4 + 0.6 * wave.PhaseProgress)
			end
		else
			-- Stopped short by anything solid in its way.
			local front = Waves.frontAt(x, line, wave.Front)
			if front < column.edge then
				column.edge = front
			end
		end
	end
	local lastReach = -Waves.frontAt(x, line, -Waves.reach(Waves.indexAt(sea.Now) - 1, line, x))
	column.wetTo = math.min(Tide.waterlineAt(wetSea, x), line - lastReach, line + column.edge)
	return column
end

-- Lays one column of a sheet on the sand from z0 to z1, `lift` above it.
local function layOnSand(sheet: Sheet, col: number, x: number, z0: number, z1: number, lift: number)
	local rows = sheet.rows
	for r = 1, rows do
		local z = z0 + (z1 - z0) * (r - 1) / (rows - 1)
		setPoint(sheet, col, r, Vector3.new(x, surfaceY(x, z) + lift, z))
	end
end

local function blend(a: Column, b: Column): Column
	local c: Column = {
		line = (a.line + b.line) / 2,
		waterY = (a.waterY + b.waterY) / 2,
		edge = (a.edge + b.edge) / 2,
		wetTo = (a.wetTo + b.wetTo) / 2,
		crestZ = {},
		crestH = {},
	}
	for i = 1, CREST_SLOTS do
		local za, zb = a.crestZ[i], b.crestZ[i]
		c.crestZ[i] = if za and zb then (za + zb) / 2 else za or zb
		c.crestH[i] = (a.crestH[i] + b.crestH[i]) / 2
	end
	return c
end

local function updateMeshes(m: Meshes, sea: Tide.Sea, wetSea: Tide.Sea)
	-- The sea: flat out to sea at each column's water level.
	for c, x in m.seaXs do
		local y = Beach.waterY(Tide.waterlineAt(sea, x))
		setPoint(m.sea, c, 1, Vector3.new(x, y, zMin))
		setPoint(m.sea, c, 2, Vector3.new(x, y, zMax))
	end
	flush(m.sea)

	local sampled = table.create(#m.samples)
	for i, x in m.samples do
		sampled[i] = sampleColumn(x, sea, wetSea)
	end
	local columns = table.create(#m.xs)
	for c in m.xs do
		columns[c] = if c % 2 == 1 then sampled[(c + 1) // 2] else blend(sampled[c // 2], sampled[c // 2 + 1])
	end
	-- Where a crest ends, fold its ribbon at the nearest crest, so it tapers off in place.
	for i = 1, CREST_SLOTS do
		local last: number? = nil
		local gaps = {}
		for c, column in columns do
			local z = column.crestZ[i]
			if z then
				for _, g in gaps do
					columns[g].crestZ[i] = z
				end
				gaps = {}
				last = z
			elseif last then
				column.crestZ[i] = last
			else
				table.insert(gaps, c)
			end
		end
	end
	for c, x in m.xs do
		local column = columns[c]
		local line = column.line
		-- The swash sheet and its foam edge. With no swash they fold away at the waterline.
		local edge = if column.edge < -0.3 then column.edge else 0
		layOnSand(m.swash, c, x, line, line + edge, 0.08)
		local front = line + edge
		if edge < 0 then
			setPoint(m.foam, c, 1, Vector3.new(x, surfaceY(x, front + 0.8) + 0.1, front + 0.8))
			setPoint(m.foam, c, 2, Vector3.new(x, surfaceY(x, front) + 0.16, front))
			setPoint(m.foam, c, 3, Vector3.new(x, surfaceY(x, front - 0.5) + 0.1, front - 0.5))
		else
			local folded = Vector3.new(x, surfaceY(x, line) - 0.2, line)
			for r = 1, 3 do
				setPoint(m.foam, c, r, folded)
			end
		end
		-- Wet sand: up to where the tide was a little while ago, or the last wave reached.
		local wetTo = if column.wetTo < line - 0.5 then column.wetTo else line
		layOnSand(m.wet, c, x, line, wetTo, 0.05)
		-- Crests: a ridge of foam on the water, folded to a point where there's none.
		for i, sheet in m.crests do
			local z = column.crestZ[i]
			local h = column.crestH[i]
			local y = column.waterY
			if z and h > 0.02 then
				setPoint(sheet, c, 1, Vector3.new(x, y - 0.05, z + 1.4))
				setPoint(sheet, c, 2, Vector3.new(x, y + h, z))
				setPoint(sheet, c, 3, Vector3.new(x, y - 0.05, z - 0.9))
			else
				local folded = Vector3.new(x, y - 0.3, z or line + 20)
				for r = 1, 3 do
					setPoint(sheet, c, r, folded)
				end
			end
		end
	end
	flush(m.swash)
	flush(m.foam)
	flush(m.wet)
	for _, sheet in m.crests do
		flush(sheet)
	end
end

local warnedRogue = -1

local function update()
	local sea = Tide.sea()
	local parts, frames = {}, {}
	local function place(part: Part, frame: CFrame)
		table.insert(parts, part)
		table.insert(frames, frame)
	end
	local wetSea = Tide.sea(
		sea.Now - waves.WetSeconds * (Workspace:GetAttribute(Tide.ScaleAttribute) or Config.Tide.TimeScale)
	)

	if meshes then
		updateMeshes(meshes, sea, wetSea)
	else
		for _, strip in strips do
			local line = Tide.waterlineAt(sea, strip.x)
			local waterY = Beach.waterY(line)
			place(strip.sea, CFrame.new(strip.x, waterY - THICKNESS / 2, (zMin + zMax) / 2))
			if #strip.swash == 0 then
				continue
			end

			local list = Waves.wavesAt(strip.x, sea, line)

			-- Wave crests rolling in, nearest the shore first.
			local crestIndex = 1
			for i = #list, 1, -1 do
				local wave = list[i]
				local crest = strip.crests[crestIndex]
				-- Crests vanish where something solid shelters the water from the sea.
				local crestZ = line + wave.Front + 1.2
				if
					wave.Phase == "Rolling"
					and crest
					and not WaterObstacles.sheltered(strip.x, crestZ, waterY)
				then
					crestIndex += 1
					local height = 0.35 + 0.35 * wave.Size
					if math.abs(crest.Size.Y - height) > 0.05 then
						crest.Size = Vector3.new(crest.Size.X, height, crest.Size.Z)
					end
					-- Fades in out at sea, sharpest as it reaches the shore.
					setTransparency(crest, 0.25 + 0.6 * (1 - wave.PhaseProgress))
					place(crest, CFrame.new(strip.x, waterY + height * 0.3, crestZ))
				end
			end
			for i = crestIndex, #strip.crests do
				place(strip.crests[i], FAR)
			end

			-- The swash sheet and its foam edge.
			local edge, sliding = 0, false
			for _, wave in list do
				if wave.Phase ~= "Rolling" then
					-- Stopped short by anything solid in its way.
					local front = Waves.frontAt(strip.x, line, wave.Front)
					if front < edge then
						edge, sliding = front, wave.Phase == "Backwash"
					end
				end
			end
			if edge < -0.3 then
				-- Only on the sand: once the water is back at the waterline, it's just the sea.
				onSand(strip.swash, strip.x, line, line + edge, 0.08, place)
				place(
					strip.edge,
					CFrame.new(strip.x, surfaceY(strip.x, line + edge) + 0.1, line + edge) * TILT
				)
				for _, piece in strip.swash do
					setTransparency(piece, if sliding then 0.6 else 0.45)
				end
				setTransparency(strip.edge, if sliding then 0.55 else 0.2)
			else
				for _, piece in strip.swash do
					place(piece, FAR)
				end
				place(strip.edge, FAR)
			end

			-- Wet sand: up to where the tide was a little while ago, or the last wave reached.
			local lastReach =
				-Waves.frontAt(strip.x, line, -Waves.reach(Waves.indexAt(sea.Now) - 1, line, strip.x))
			local wetTo = math.min(Tide.waterlineAt(wetSea, strip.x), line - lastReach, line + edge)
			if wetTo < line - 0.5 then
				onSand(strip.wet, strip.x, line, wetTo, 0.05, place)
			else
				for _, piece in strip.wet do
					place(piece, FAR)
				end
			end
		end
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end

	-- Rogue waves are known in advance (the waves are deterministic): warn a few seconds out.
	-- The Foghorn warns earlier, and about big waves too.
	local worn = Gear.getAccessory(player:GetAttribute("Accessory"))
	local extra = if worn and worn.WaveWarning then worn.WaveWarning else 0
	local lead = 8 + extra
	local first = Waves.indexAt(sea.Now) + 1
	for upcoming = first, first + math.ceil(lead / waves.Period) do
		if upcoming <= warnedRogue then
			continue
		end
		local rogue = Waves.isRogue(upcoming)
		local big = extra > 0 and Waves.size(upcoming) >= waves.SetSize
		if rogue or big then
			local arrives = upcoming * waves.Period + waves.StartOffset / waves.Speed
			if arrives - sea.Now < lead then
				warnedRogue = upcoming
				HUD.banner(
					if rogue
						then "A rogue wave is coming! Get away from the water!"
						else "Your foghorn sounds: a big wave is coming!"
				)
			end
		end
	end
end

function SeaController.init()
	local folder = Instance.new("Folder")
	folder.Name = "LocalSea"
	folder.Parent = Workspace

	zMin = -beach.ShopDepth - 60
	zMax = Beach.Depth + beach.SeaExtent + 200

	local ok, built = pcall(buildMeshes, folder)
	if ok then
		meshes = built
	else
		warn("[Sea] drawing the sea as strips: " .. tostring(built))
		folder:ClearAllChildren()
		local half = Beach.HalfWidth
		local count = math.ceil(beach.Width / STRIP)
		local width = beach.Width / count
		for i = 0, count - 1 do
			table.insert(strips, newStrip(folder, -half + width * (i + 0.5), width, true))
		end
		-- Plain sea beyond the headlands on each side.
		table.insert(strips, newStrip(folder, -half - SIDE / 2, SIDE, false))
		table.insert(strips, newStrip(folder, half + SIDE / 2, SIDE, false))
	end

	RunService.RenderStepped:Connect(update)
end

-- For tools/tests.
SeaController._update = update

return SeaController
