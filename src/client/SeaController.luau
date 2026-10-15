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
-- On a device that can't make editable meshes, it draws the same columns with narrow parts
-- instead: the sea ends at the same shore, so the shoreline is still a smooth curve.
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

local THICKNESS = 4
local SIDE = 700 -- sea beyond the beach on each side, past the headlands
local TILT = CFrame.Angles(math.atan(beach.Slope), 0, 0) -- lies flat on the sloping sand
local FAR = CFrame.new(0, -10000, 0)

local SWASH = Palette.World.Sea:Lerp(Color3.new(1, 1, 1), 0.35)

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

-- The ground's ideal height (Beach.groundAt) on the same grid. The terrain is a faceted
-- version of it; deciding what's under water from this keeps the shoreline a smooth curve.
local idealCache: { [number]: number } = {}
local function gridIdeal(ix: number, iz: number): number
	local key = ix * 65536 + iz
	local cached = idealCache[key]
	if not cached then
		cached = Beach.groundAt(ix * GRID, iz * GRID)
		idealCache[key] = cached
	end
	return cached
end

local function bilinear(grid: (number, number) -> number, x: number, z: number): number
	local fx, fz = x / GRID, z / GRID
	local ix, iz = math.floor(fx), math.floor(fz)
	local tx, tz = fx - ix, fz - iz
	local a = grid(ix, iz) + (grid(ix, iz + 1) - grid(ix, iz)) * tz
	if tx < 1e-6 then
		return a
	end
	local b = grid(ix + 1, iz) + (grid(ix + 1, iz + 1) - grid(ix + 1, iz)) * tz
	return a + (b - a) * tx
end

local function surfaceY(x: number, z: number): number
	return bilinear(gridY, x, z)
end

local function idealY(x: number, z: number): number
	return bilinear(gridIdeal, x, z)
end

-- When a zone's biome changes, its ground is rebuilt: measure it again.
local function forgetGround()
	surfaceCache = {}
	idealCache = {}
end

-- The continuous surfaces -------------------------------------------------------------------

local SAMPLE = 12 -- studs along the shore between the columns where the water is worked out
local SEA_STEP = 6 -- studs between the sea surface's columns over the beach
-- Near the shore the sea surface is a band of rows that drapes over the ground: from BAND_BACK
-- studs up the beach of the waterline (the furthest a dip can flood, MaxDepth / Slope) to
-- BAND_OUT studs out, every BAND_STEP studs. What's under water is decided from the ground's
-- ideal shape, so the shoreline is a smooth curve even where the terrain is faceted; the water
-- tucks under the sand where it's dry and lies just over any facet poking up where it's wet.
local BAND_BACK = math.ceil(Config.Beach.Terrain.MaxDepth / Config.Beach.Slope) + 4
local BAND_OUT = 16
local BAND_STEP = 3
local BAND_ROWS = math.floor((BAND_BACK + BAND_OUT) / BAND_STEP) + 1
local SEA_REFRESH = 0.1 -- seconds between sea surface updates (the tide moves slowly)
local SWASH_ROWS = 5 -- points across the run-up sheet and the wet sand
local CREST_SLOTS = 2 -- crest ribbons (a rolling wave uses slot Index % CREST_SLOTS)

-- A sheet: a grid of points (columns along the shore, rows across), given in world space each
-- frame. Only its upper face is drawn. A mesh can only hold so many triangles, so a big sheet is
-- several meshes side by side; neighbours share their edge column, so there's no seam.
local MAX_TRIANGLES = 10000 -- well under Roblox's limit per editable mesh

-- Every editable mesh made, so they can all be freed if the water falls back to parts.
local created: { any } = {}

type Chunk = {
	mesh: any,
	part: MeshPart,
	ids: { number }, -- vertex ids, for the sheet's points `first` onward
	first: number,
	batch: boolean,
	center: Vector3, -- the middle of its box (its points are stored relative to this)
	half: Vector3,
}

type Sheet = {
	chunks: { Chunk },
	points: { Vector3 },
	cols: number,
	rows: number,
}

local function newChunk(
	folder: Instance,
	name: string,
	fromCol: number,
	toCol: number,
	rows: number,
	center: Vector3,
	half: Vector3,
	props: { [string]: any }
): Chunk
	local mesh = AssetService:CreateEditableMesh()
	assert(mesh, "no memory for an editable mesh")
	table.insert(created, mesh)
	local cols = toCol - fromCol + 1
	local ids = table.create(cols * rows)
	for i = 1, cols * rows do
		ids[i] = mesh:AddVertex(Vector3.zero)
	end
	-- All lit as if facing up (the water and sand lie nearly flat), so slopes and folds in
	-- the sheet don't shade it unevenly.
	local up = mesh:AddNormal(Vector3.yAxis)
	local normals = true
	local function triangle(a: number, b: number, c: number)
		local face = mesh:AddTriangle(a, b, c)
		if normals then
			normals = pcall(mesh.SetFaceNormals, mesh, face, { up, up, up })
		end
	end
	for c = 1, cols - 1 do
		for r = 1, rows - 1 do
			local v00 = ids[(c - 1) * rows + r]
			local v01 = ids[(c - 1) * rows + r + 1]
			local v10 = ids[c * rows + r]
			local v11 = ids[c * rows + r + 1]
			-- Counter-clockwise seen from above, so the face looks up.
			triangle(v00, v01, v10)
			triangle(v10, v01, v11)
		end
	end
	-- A flat, invisible triangle across the whole box, so the mesh's bounds (and so its scale
	-- and centre) stay fixed however its points move.
	triangle(mesh:AddVertex(-half), mesh:AddVertex(half), mesh:AddVertex(Vector3.zero))
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
		ids = ids,
		first = (fromCol - 1) * rows + 1,
		batch = true,
		center = center,
		half = half,
	}
end

-- `colXs` is each column's X. A mesh may be at most 2048 studs across, so each chunk's box
-- only spans its own columns (and the sheet's full height and depth).
local function newSheet(
	folder: Instance,
	name: string,
	colXs: { number },
	rows: number,
	low: Vector3,
	high: Vector3,
	props: { [string]: any }
): Sheet
	local cols = #colXs
	local points = table.create(cols * rows, (low + high) / 2)
	local sheet: Sheet = { chunks = {}, points = points, cols = cols, rows = rows }
	-- Each gap between two columns holds (rows - 1) * 2 triangles.
	local span = math.max(1, math.floor(MAX_TRIANGLES / ((rows - 1) * 2)))
	local fromCol = 1
	while fromCol < cols do
		local toCol = math.min(cols, fromCol + span)
		local boxLow = Vector3.new(colXs[fromCol] - 1, low.Y, low.Z)
		local boxHigh = Vector3.new(colXs[toCol] + 1, high.Y, high.Z)
		local center, half = (boxLow + boxHigh) / 2, (boxHigh - boxLow) / 2
		table.insert(sheet.chunks, newChunk(folder, name, fromCol, toCol, rows, center, half, props))
		fromCol = toCol
	end
	return sheet
end

local function setPoint(sheet: Sheet, col: number, row: number, point: Vector3)
	sheet.points[(col - 1) * sheet.rows + row] = point
end

-- Moves the sheet's points to where they were set this frame.
local function flush(sheet: Sheet)
	local points = sheet.points
	for _, chunk in sheet.chunks do
		local center, half = chunk.center, chunk.half
		local ids = chunk.ids
		local count = #ids
		local values = table.create(count)
		local first = chunk.first - 1
		for i = 1, count do
			local p = points[first + i] - center
			values[i] = Vector3.new(
				math.clamp(p.X, -half.X, half.X),
				math.clamp(p.Y, -half.Y, half.Y),
				math.clamp(p.Z, -half.Z, half.Z)
			)
		end
		if chunk.batch then
			local ok = pcall(chunk.mesh.BatchSetValues, chunk.mesh, ids, values)
			if ok then
				continue
			end
			chunk.batch = false
		end
		for i = 1, count do
			chunk.mesh:SetPosition(ids[i], values[i])
		end
	end
end

type Meshes = {
	sea: Sheet,
	seaXs: { number },
	swash: Sheet,
	foam: Sheet,
	wet: Sheet,
	crests: { Sheet },
}

local meshes: Meshes? = nil

-- The columns over the beach: where the water is worked out (`samples`, every SAMPLE studs)
-- and where it's drawn (`xs`: the samples and the midpoints between them).
local samples: { number } = {}
local xs: { number } = {}
local spacing = 0

local function buildColumns()
	local half = Beach.HalfWidth
	local count = math.ceil(beach.Width / SAMPLE)
	for i = 0, count do
		table.insert(samples, -half + beach.Width * i / count)
	end
	for i, x in samples do
		table.insert(xs, x)
		if samples[i + 1] then
			table.insert(xs, (x + samples[i + 1]) / 2)
		end
	end
	spacing = beach.Width / count / 2
end

local function buildMeshes(folder: Folder): Meshes
	local half = Beach.HalfWidth
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
			seaXs,
			BAND_ROWS + 2,
			Vector3.new(-half - SIDE - 1, low, zMin),
			Vector3.new(half + SIDE + 1, 20, zMax),
			{
				Material = Palette.Material.Glass,
				Color = Palette.World.Sea,
				Transparency = 0.3,
			}
		),
		seaXs = seaXs,
		swash = newSheet(folder, "Swash", xs, SWASH_ROWS, beachLow, beachHigh, {
			Material = Palette.Material.Glass,
			Color = SWASH,
			Transparency = 0.45,
		}),
		foam = newSheet(folder, "Foam", xs, 3, beachLow, beachHigh, {
			Material = Palette.Material.Smooth,
			Color = Palette.World.Foam,
			Transparency = 0.25,
		}),
		wet = newSheet(folder, "WetSand", xs, SWASH_ROWS, beachLow, beachHigh, {
			Material = Palette.Material.Sand,
			Color = Palette.World.WetSand,
			Transparency = 0.45,
		}),
		crests = {},
	}
	for i = 1, CREST_SLOTS do
		result.crests[i] = newSheet(folder, "Crest" .. i, xs, 3, beachLow, beachHigh, {
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
	shore: number, -- Z where the sea really meets the sand (Beach.shoreFrom)
	edge: number, -- Z the swash reaches up to (the shore when there's none)
	wetTo: number, -- Z the wet sand reaches up to
	crestZ: { number? }, -- per crest slot: where its crest is (nil: none)
	crestH: { number },
}

local function sampleColumn(x: number, sea: Tide.Sea, wetSea: Tide.Sea): Column
	local line = Tide.waterlineAt(sea, x)
	local waterY = Beach.waterY(line)
	local shore = Beach.shoreFrom(x, line)
	local column: Column =
		{ line = line, waterY = waterY, shore = shore, edge = shore, wetTo = shore, crestZ = {}, crestH = {} }
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
			local front = line + Waves.frontAt(x, line, wave.Front)
			if front < column.edge then
				column.edge = front
			end
		end
	end
	-- Wet sand: up to where the tide was a little while ago, or the last wave reached.
	local lastReach = line
		+ Waves.frontAt(x, line, shore - line - Waves.reach(Waves.indexAt(sea.Now) - 1, line, x))
	local wetLine = Tide.waterlineAt(wetSea, x)
	column.wetTo = math.min(Beach.shoreFrom(x, wetLine), lastReach, column.edge)
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
		shore = (a.shore + b.shore) / 2,
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

local seaUpdatedAt = -math.huge

-- The sea surface: flat at each column's water level, draped over the ground near the shore.
local function updateSea(m: Meshes, sea: Tide.Sea)
	local rows = BAND_ROWS + 2
	local half = Beach.HalfWidth
	for c, x in m.seaXs do
		local line = Tide.waterlineAt(sea, x)
		local waterY = Beach.waterY(line)
		-- Past the headlands (and under the cliffs) it's open sea: flat. The rows keep the
		-- same Z as the beach's, so the surface joins up without stretching.
		local open = math.abs(x) >= half - 1
		local shore = if open then line else Beach.shoreFrom(x, line)
		local first = math.min(line, shore) - BAND_BACK
		-- Far up the beach it's all dry: well under the sand.
		setPoint(m.sea, c, 1, Vector3.new(x, if open then waterY else waterY - 50, zMin))
		for k = 1, BAND_ROWS do
			local z = math.max(first + (k - 1) * BAND_STEP, zMin + k * 0.01)
			local y = waterY
			if not open then
				local ideal = idealY(x, z)
				local wet = if z >= shore then ideal <= waterY + 0.3 else ideal < waterY - 0.3
				local ground = surfaceY(x, z)
				y = if wet then math.max(waterY, ground + 0.06) else ground - 0.3
			end
			setPoint(m.sea, c, k + 1, Vector3.new(x, y, z))
		end
		setPoint(m.sea, c, rows, Vector3.new(x, waterY, zMax))
	end
	flush(m.sea)
end

-- The water at every drawn column this frame.
local function computeColumns(sea: Tide.Sea, wetSea: Tide.Sea): { Column }
	local sampled = table.create(#samples)
	for i, x in samples do
		sampled[i] = sampleColumn(x, sea, wetSea)
	end
	local columns = table.create(#xs)
	for c in xs do
		columns[c] = if c % 2 == 1 then sampled[(c + 1) // 2] else blend(sampled[c // 2], sampled[c // 2 + 1])
	end
	-- Where a crest ends, fold it at the nearest crest, so it tapers off in place.
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
	return columns
end

local function updateMeshes(m: Meshes, sea: Tide.Sea, columns: { Column })
	if os.clock() - seaUpdatedAt >= SEA_REFRESH then
		seaUpdatedAt = os.clock()
		updateSea(m, sea)
	end

	for c, x in xs do
		local column = columns[c]
		local shore = column.shore
		-- The swash sheet and its foam edge, from the shore up. With no swash they fold away.
		local front = if column.edge < shore - 0.3 then column.edge else shore
		layOnSand(m.swash, c, x, shore, front, 0.08)
		if front < shore then
			setPoint(m.foam, c, 1, Vector3.new(x, surfaceY(x, front + 0.8) + 0.1, front + 0.8))
			setPoint(m.foam, c, 2, Vector3.new(x, surfaceY(x, front) + 0.16, front))
			setPoint(m.foam, c, 3, Vector3.new(x, surfaceY(x, front - 0.5) + 0.1, front - 0.5))
		else
			local folded = Vector3.new(x, surfaceY(x, shore) - 0.2, shore)
			for r = 1, 3 do
				setPoint(m.foam, c, r, folded)
			end
		end
		-- Wet sand: up to where the tide was a little while ago, or the last wave reached.
		local wetTo = if column.wetTo < shore - 0.5 then column.wetTo else shore
		layOnSand(m.wet, c, x, shore, wetTo, 0.05)
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
				local folded = Vector3.new(x, y - 0.3, z or shore + 20)
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

-- The fallback: the same columns drawn with narrow parts --------------------------------------

local LONG = 2000 -- the sea part's length (it's moved, never resized, as the shore moves)
local BACK = 400 -- the length of the part that floods dips up the beach

type Pieces = {
	seaOut: { Part }, -- the sea from the shore out
	seaIn: { Part }, -- water in dips up the beach, a little lower so it never fights the shore
	lap: { Part }, -- a band of shallow water over the shore, hiding where the sand meets the sea
	swash: { { Part } },
	wet: { { Part } },
	foam: { Part },
	crests: { { Part } },
	sides: { Part },
}

local pieces: Pieces? = nil
local PIECE_ROWS = 2 -- pieces per column for the run-up sheet and the wet sand

local function buildPieces(folder: Folder): Pieces
	local width = spacing + 0.1
	local result: Pieces =
		{ seaOut = {}, seaIn = {}, lap = {}, swash = {}, wet = {}, foam = {}, crests = {}, sides = {} }
	local function make(name: string, size: Vector3, props: { [string]: any }): Part
		props.Size = size
		local part = makePart(name, props)
		part.Parent = folder
		return part
	end
	local seaProps = function()
		return { Material = Palette.Material.Glass, Color = Palette.World.Sea, Transparency = 0.3 }
	end
	for c in xs do
		result.seaOut[c] = make("Sea", Vector3.new(width, THICKNESS, LONG), seaProps())
		result.seaIn[c] = make("Sea", Vector3.new(width, THICKNESS, BACK), seaProps())
		result.lap[c] = make("Lap", Vector3.new(width, 0.1, 3), {
			Material = Palette.Material.Glass,
			Color = SWASH,
			Transparency = 0.5,
		})
		result.swash[c], result.wet[c] = {}, {}
		for i = 1, PIECE_ROWS do
			result.swash[c][i] = make("Swash", Vector3.new(width, 0.1, 1), {
				Material = Palette.Material.Glass,
				Color = SWASH,
				Transparency = 0.45,
			})
			result.wet[c][i] = make("WetSand", Vector3.new(width, 0.06, 1), {
				Material = Palette.Material.Sand,
				Color = Palette.World.WetSand,
				Transparency = 0.45,
			})
		end
		result.foam[c] = make("Foam", Vector3.new(width, 0.14, 1.4), {
			Material = Palette.Material.Smooth,
			Color = Palette.World.Foam,
			Transparency = 0.25,
		})
		result.crests[c] = {}
		for i = 1, CREST_SLOTS do
			result.crests[c][i] = make("Crest", Vector3.new(width, 1.2, 2.5), {
				Material = Palette.Material.Smooth,
				Color = Palette.World.Foam,
				Transparency = 0.35,
			})
		end
	end
	for i = 1, 2 do
		result.sides[i] = make("Sea", Vector3.new(SIDE, THICKNESS, zMax - zMin), seaProps())
	end
	return result
end

local function resize(part: Part, length: number)
	if math.abs(part.Size.Z - length) > 0.3 then
		part.Size = Vector3.new(part.Size.X, part.Size.Y, length)
	end
end

-- Lays a column's pieces on the sand from z0 to z1 (up the beach), each spanning between two
-- points on the real surface. Pieces too short to see are put away.
local function layPieces(
	list: { Part },
	x: number,
	z0: number,
	z1: number,
	lift: number,
	place: (Part, CFrame) -> ()
)
	local count = #list
	for i = 1, count do
		local za = z0 + (z1 - z0) * (i - 1) / count
		local zb = z0 + (z1 - z0) * i / count
		local a = Vector3.new(x, surfaceY(x, za) + lift, za)
		local b = Vector3.new(x, surfaceY(x, zb) + lift, zb)
		local length = (b - a).Magnitude
		if length < 0.05 then
			place(list[i], FAR)
			continue
		end
		resize(list[i], length + 0.2)
		place(list[i], CFrame.lookAt((a + b) / 2, b))
	end
end

local function updatePieces(p: Pieces, sea: Tide.Sea, columns: { Column }, place: (Part, CFrame) -> ())
	for c, x in xs do
		local column = columns[c]
		local shore, waterY = column.shore, column.waterY
		place(p.seaOut[c], CFrame.new(x, waterY - THICKNESS / 2, shore + LONG / 2))
		place(p.seaIn[c], CFrame.new(x, waterY - 0.4 - THICKNESS / 2, shore - BACK / 2))
		-- The lap: over the shore, never below the water or the sand.
		local a = Vector3.new(x, math.max(waterY, surfaceY(x, shore + 1.5)) + 0.05, shore + 1.5)
		local b = Vector3.new(x, surfaceY(x, shore - 1.5) + 0.05, shore - 1.5)
		place(p.lap[c], CFrame.lookAt((a + b) / 2, b))

		local front = if column.edge < shore - 0.3 then column.edge else shore
		if front < shore then
			layPieces(p.swash[c], x, shore, front, 0.08, place)
			place(p.foam[c], CFrame.new(x, surfaceY(x, front) + 0.1, front) * TILT)
		else
			for _, piece in p.swash[c] do
				place(piece, FAR)
			end
			place(p.foam[c], FAR)
		end
		local wetTo = if column.wetTo < shore - 0.5 then column.wetTo else shore
		if wetTo < shore then
			layPieces(p.wet[c], x, shore, wetTo, 0.05, place)
		else
			for _, piece in p.wet[c] do
				place(piece, FAR)
			end
		end
		for i, crest in p.crests[c] do
			local z = column.crestZ[i]
			local h = column.crestH[i]
			if z and h > 0.02 then
				-- A fixed-size block standing h above the water (the rest is under it).
				place(crest, CFrame.new(x, waterY + h - crest.Size.Y / 2, z))
			else
				place(crest, FAR)
			end
		end
	end
	-- Plain sea past the headlands, at the level at each end of the beach.
	local half = Beach.HalfWidth
	for i, side in { -1, 1 } do
		local y = Beach.waterY(Tide.waterlineAt(sea, side * half))
		place(p.sides[i], CFrame.new(side * (half + SIDE / 2), y - THICKNESS / 2, (zMin + zMax) / 2))
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

	local columns = computeColumns(sea, wetSea)
	if meshes then
		updateMeshes(meshes, sea, columns)
	elseif pieces then
		updatePieces(pieces, sea, columns, place)
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

	Workspace.AttributeChanged:Connect(function(name)
		if string.match(name, "^ZoneBiome") then
			-- The zone's terrain is rebuilt (and replicates a moment later).
			forgetGround()
			seaUpdatedAt = -math.huge
			task.delay(3, forgetGround)
		end
	end)

	buildColumns()
	local ok, built = pcall(buildMeshes, folder)
	if ok then
		meshes = built
		print("[Sea] drawing the water as smooth meshes")
	else
		warn(
			"[Sea] couldn't build the water meshes, drawing the water with parts instead: "
				.. tostring(built)
				.. " (in Studio, check Game Settings > Security > Allow Mesh / Image APIs)"
		)
		-- Free whatever meshes were made before it failed: they count against the budget.
		for _, mesh in created do
			pcall(mesh.Destroy, mesh)
		end
		created = {}
		folder:ClearAllChildren()
		pieces = buildPieces(folder)
	end

	RunService.RenderStepped:Connect(update)
end

-- For tools/tests.
SeaController._update = update

return SeaController
