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
local WET_TINT = Color3.fromRGB(60, 45, 28) -- darkens the ground under it: wet sand

local zMax = 0

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
		local hit =
			Workspace:Raycast(Beach.rayFrom(Vector3.new(x, y, z), 30), Vector3.new(0, -60, 0), surfaceParams)
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

-- tools/water (the water lab) swaps in the ground it measured from the terrain's voxels.
local groundOverride: ((number, number) -> number)? = nil

local function surfaceY(x: number, z: number): number
	if groundOverride then
		return groundOverride(x, z)
	end
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
local SEA_STEP = 8 -- studs between the sea surface's columns over the beach
-- Near the shore the sea surface is a band of rows over the ground: from BAND_BACK studs up the
-- beach of the shore (the furthest a dip can flood, MaxDepth / Slope) to BAND_OUT studs out.
-- The surface lies flat at the sea's height where the game's ground is wet and sinks into the
-- sand where it's dry (seaPointY), so the drawn ground cuts the shoreline out of it: the rows
-- needn't be close for the shore to be a smooth curve. They're every BAND_NEAR studs from
-- NEAR_BACK up the beach to NEAR_OUT out, where the water first gets deep, and every BAND_FAR
-- further up and out. Up the beach it reaches as far as a cut can flood: the deepest of the
-- layouts' cuts and the channel to the Far Sandbar. Out to sea
-- the band reaches past where the sea is deep enough to lose things on the plain slope, and
-- then some, so the colour that shows the depth (depthColor) follows every bank and pit.
local BAND_BACK = math.ceil(
	math.max(Config.Beach.Terrain.MaxDepth, Config.Beach.FarSandbar.ChannelDepth) / Config.Beach.Slope
) + 4
local BAND_OUT = math.ceil((Config.Beach.LostDepth + 6) / Config.Beach.Slope)
local BAND_NEAR, BAND_FAR, NEAR_BACK, NEAR_OUT = 4, 8, 40, 24
local BAND_OFFSETS: { number } = {} -- each row's offset from the shore
do
	local offset = -BAND_BACK
	while offset < -NEAR_BACK do
		table.insert(BAND_OFFSETS, offset)
		offset += BAND_FAR
	end
	offset = -NEAR_BACK
	while offset < NEAR_OUT do
		table.insert(BAND_OFFSETS, offset)
		offset += BAND_NEAR
	end
	while offset < BAND_OUT do
		table.insert(BAND_OFFSETS, offset)
		offset += BAND_FAR
	end
	table.insert(BAND_OFFSETS, BAND_OUT)
end
local BAND_ROWS = #BAND_OFFSETS
local FAR_LENGTH = 2000 -- the open sea parts' length (a part can be at most 2048)
local SEA_OUT = 900 -- studs out to sea the sea mesh reaches past the waterline (then flat parts)
local BOX_BACK = 400 -- each sheet's box reaches this far up the beach of the tide's anchor
local BOX_OUT = 1200 -- and this far out to sea
local SEA_REFRESH = 0.2 -- seconds between sea surface updates (the tide moves slowly)
local SWASH_ROWS = 5 -- points across the run-up sheet and the wet sand
local WET_BAND = 24 -- the most sand shown wet above the shore, in studs
local CREST_SLOTS = 2 -- crest ribbons (a rolling wave uses slot Index % CREST_SLOTS)

-- A sheet: a grid of points (columns along the shore, rows across), given in world space each
-- frame. Only its upper face is drawn. A mesh can only hold so many triangles, so a big sheet is
-- several meshes side by side; neighbours share their edge column, so there's no seam.
local MAX_TRIANGLES = 10000 -- well under Roblox's limit per editable mesh
local MAX_WIDTH = 1800 -- studs: a mesh may be at most 2048 across

-- Every editable mesh made, so they can all be freed if the water falls back to parts.
local created: { any } = {}

type Chunk = {
	mesh: any,
	part: MeshPart,
	ids: { number }, -- vertex ids, for the sheet's points `first` onward
	colorIds: { number }?, -- each vertex's own colour id, for a sheet coloured per point
	shown: { Color3 }?, -- the colours last set, so only the ones that change are set again
	first: number,
	batch: boolean,
	center: Vector3, -- the middle of its box; Z is from the sheet's anchor (see flush)
	half: Vector3,
}

type Sheet = {
	chunks: { Chunk },
	points: { Vector3 },
	colors: { Color3 }?, -- each point's colour, for a sheet coloured per point
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
	-- Coloured per point: each vertex gets a colour of its own, and every face's corners use
	-- their vertices' colours, so the colour blends smoothly across the sheet.
	local perPoint = props.PerPointColor
	local colorIds: { number }? = nil
	local colorOf: { [number]: number } = {}
	if perPoint then
		local list = table.create(cols * rows)
		for i, id in ids do
			list[i] = mesh:AddColor(Color3.new(1, 1, 1), 1)
			colorOf[id] = list[i]
		end
		colorIds = list
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
		if colorIds and colorOf[a] then
			mesh:SetFaceColors(face, { colorOf[a], colorOf[b], colorOf[c] })
		end
	end
	for c = 1, cols - 1 do
		for r = 1, rows - 1 do
			local v00 = ids[(c - 1) * rows + r]
			local v01 = ids[(c - 1) * rows + r + 1]
			local v10 = ids[c * rows + r]
			local v11 = ids[c * rows + r + 1]
			-- Counter-clockwise seen from above when rows run seaward (+Z), so the face looks up.
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
		if key ~= "PerPointColor" then
			(part :: any)[key] = value
		end
	end
	if perPoint then
		part.Color = Color3.new(1, 1, 1) -- the vertices carry the colour
	end
	part.Size = part.MeshSize
	part.CFrame = CFrame.new(center)
	part.Parent = folder
	return {
		mesh = mesh,
		part = part,
		ids = ids,
		colorIds = colorIds,
		shown = if colorIds then {} else nil,
		first = (fromCol - 1) * rows + 1,
		batch = true,
		center = center,
		half = half,
	}
end

-- How a sheet's columns are split into meshes: { fromCol, toCol } each, sharing edge columns.
-- Each gap between two columns holds (rows - 1) * 2 triangles; a mesh holds at most
-- MAX_TRIANGLES and is at most MAX_WIDTH across (but always at least one gap).
local function chunkRanges(colXs: { number }, rows: number): { { number } }
	local span = math.max(1, math.floor(MAX_TRIANGLES / ((rows - 1) * 2)))
	local ranges = {}
	local fromCol = 1
	while fromCol < #colXs do
		local toCol = math.min(#colXs, fromCol + span)
		while toCol > fromCol + 1 and colXs[toCol] - colXs[fromCol] > MAX_WIDTH do
			toCol -= 1
		end
		table.insert(ranges, { fromCol, toCol })
		fromCol = toCol
	end
	return ranges
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
	local sheet: Sheet = {
		chunks = {},
		points = points,
		colors = if props.PerPointColor then table.create(cols * rows, Palette.Water.Shallow) else nil,
		cols = cols,
		rows = rows,
	}
	for _, range in chunkRanges(colXs, rows) do
		local fromCol, toCol = range[1], range[2]
		local boxLow = Vector3.new(colXs[fromCol] - 1, low.Y, low.Z)
		local boxHigh = Vector3.new(colXs[toCol] + 1, high.Y, high.Z)
		local center, half = (boxLow + boxHigh) / 2, (boxHigh - boxLow) / 2
		table.insert(sheet.chunks, newChunk(folder, name, fromCol, toCol, rows, center, half, props))
	end
	return sheet
end

local function setPoint(sheet: Sheet, col: number, row: number, point: Vector3)
	sheet.points[(col - 1) * sheet.rows + row] = point
end

-- A point's colour, on a sheet drawn with colours per point (the sea).
local function setColor(sheet: Sheet, col: number, row: number, color: Color3)
	local colors = sheet.colors
	if colors then
		colors[(col - 1) * sheet.rows + row] = color
	end
end

-- Moves the sheet's points to where they were set this frame.
-- The sheets cover a stretch around the waterline, not the whole sea (a mesh can only be 2048
-- studs across): their boxes' Z is measured from `anchorZ`, which follows the tide, and each
-- mesh moves with it.
local function flush(sheet: Sheet, anchorZ: number)
	local points = sheet.points
	for _, chunk in sheet.chunks do
		local half = chunk.half
		local center = chunk.center + Vector3.new(0, 0, anchorZ)
		if math.abs(chunk.part.Position.Z - center.Z) > 0.01 then
			chunk.part.CFrame = CFrame.new(center)
		end
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
		local colorIds, shown, colors = chunk.colorIds, chunk.shown, sheet.colors
		if colorIds and shown and colors then
			-- Only the colours that changed enough to see.
			for i = 1, count do
				local color = colors[first + i]
				local last = shown[i]
				if
					not last
					or math.abs(last.R - color.R)
							+ math.abs(last.G - color.G)
							+ math.abs(last.B - color.B)
						> 0.02
				then
					shown[i] = color
					chunk.mesh:SetColor(colorIds[i], color)
				end
			end
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
	far: { Part }, -- flat open sea past the sea mesh's reach, one for each half of the width
}

local meshes: Meshes? = nil

-- Where the sheets are anchored this frame: the waterline in the middle of the beach.
local function anchorFor(sea: Tide.Sea): number
	return Tide.waterlineAt(sea, 0)
end

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

type Plan = {
	name: string,
	colXs: { number },
	rows: number,
	low: Vector3,
	high: Vector3,
	props: { [string]: any },
}

-- Every water sheet: its columns, rows and box. (tools/tests checks these fit Roblox's limits.)
local function plan(): { Plan }
	local half = Beach.HalfWidth
	local seaXs = { -half - SIDE }
	local seaCount = math.ceil(beach.Width / SEA_STEP)
	for i = 0, seaCount do
		table.insert(seaXs, -half + beach.Width * i / seaCount)
	end
	table.insert(seaXs, half + SIDE)
	local low = Beach.groundY(zMax) - 40
	local beachLow = Vector3.new(-half - 1, low, -BOX_BACK)
	local beachHigh = Vector3.new(half + 1, 20, BOX_OUT)
	local sheets: { Plan } = {
		{
			name = "Sea",
			colXs = seaXs,
			rows = BAND_ROWS + 2,
			low = Vector3.new(-half - SIDE - 1, low, -BOX_BACK),
			high = Vector3.new(half + SIDE + 1, 20, BOX_OUT),
			props = { Material = Palette.Material.Glass, Transparency = 0.25, PerPointColor = true },
		},
		{
			name = "Swash",
			colXs = xs,
			rows = SWASH_ROWS,
			low = beachLow,
			high = beachHigh,
			props = { Material = Palette.Material.Glass, Color = SWASH, Transparency = 0.45 },
		},
		{
			name = "Foam",
			colXs = xs,
			rows = 3,
			low = beachLow,
			high = beachHigh,
			props = { Material = Palette.Material.Smooth, Color = Palette.World.Foam, Transparency = 0.25 },
		},
		{
			name = "WetSand",
			colXs = xs,
			rows = SWASH_ROWS,
			low = beachLow,
			high = beachHigh,
			-- A dark, see-through tint, so wet ground looks darker than dry in any zone's colours.
			props = { Material = Palette.Material.Smooth, Color = WET_TINT, Transparency = 0.7 },
		},
	}
	for i = 1, CREST_SLOTS do
		table.insert(sheets, {
			name = "Crest" .. i,
			colXs = xs,
			rows = 3,
			low = beachLow,
			high = beachHigh,
			props = { Material = Palette.Material.Smooth, Color = Palette.World.Foam, Transparency = 0.35 },
		})
	end
	return sheets
end

local function buildMeshes(folder: Folder): Meshes
	local built: { [string]: Sheet } = {}
	local seaXs = {}
	for _, sheet in plan() do
		built[sheet.name] =
			newSheet(folder, sheet.name, sheet.colXs, sheet.rows, sheet.low, sheet.high, sheet.props)
		if sheet.name == "Sea" then
			seaXs = sheet.colXs
		end
	end
	local result: Meshes = {
		sea = built.Sea,
		seaXs = seaXs,
		swash = built.Swash,
		foam = built.Foam,
		wet = built.WetSand,
		crests = {},
		far = {},
	}
	for i = 1, CREST_SLOTS do
		result.crests[i] = built["Crest" .. i]
	end
	for i = 1, 2 do
		local part = makePart("FarSea", {
			Size = Vector3.new(Beach.HalfWidth + SIDE, THICKNESS, FAR_LENGTH),
			Material = Palette.Material.Glass,
			Color = Palette.Water.Lost, -- the open sea is deep
			Transparency = 0.25,
		})
		part.Parent = folder
		result.far[i] = part
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
	-- At most WET_BAND up the beach: its few rows can only follow the ground that far (past
	-- it, the sheet would float over dips and cut through banks).
	column.wetTo = math.max(math.min(Beach.shoreFrom(x, wetLine), lastReach, column.edge), shore - WET_BAND)
	return column
end

-- Lays one column of a sheet on the sand between z0 and z1, `lift` above it. A sheet's rows
-- always run seaward (+Z): that's what makes its faces look up.
local function layOnSand(sheet: Sheet, col: number, x: number, z0: number, z1: number, lift: number)
	local rows = sheet.rows
	local lo, hi = math.min(z0, z1), math.max(z0, z1)
	for r = 1, rows do
		local z = lo + (hi - lo) * (r - 1) / (rows - 1)
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

-- How high the sea surface is drawn at (x, z). The game's water is level: wherever the ground
-- (Beach.groundAt) is below the sea's height it's water, as deep as the difference. So the
-- surface lies flat at the sea's height, and the drawn ground cuts the shoreline out of it,
-- along banks, walls, pits and channels alike. Where the game's ground is dry it sinks just
-- under the sea's height (or under the drawn ground, if that's lower), so it's hidden in the
-- sand and never slants up a wall between a wet point and a dry one. Where the game's ground
-- is wet but the drawn terrain bulges above the water (its cells round things off), the
-- surface lifts over it a little, but never far above the sea.
local LIFT = 0.6 -- the most the surface lifts over the drawn ground in the water

-- The sea's colour over water `depth` deep (the game's depth, from Beach.groundAt): pale where
-- it's shallow, darkening through knee and waist deep, then a quick step to deep blue where
-- it's deep enough to drown (WaistDepth), and darker still where things are lost (LostDepth).
-- So you can read from the colour how the water will treat you.
local DEPTH_COLORS = {
	{ 0, Palette.Water.Shallow },
	{ beach.ShallowDepth, Palette.Water.Shallow:Lerp(Palette.Water.Knee, 0.5) },
	{ beach.KneeDepth, Palette.Water.Knee },
	{ beach.WaistDepth - 0.4, Palette.Water.Waist },
	{ beach.WaistDepth, Palette.Water.Deep },
	{ beach.LostDepth, Palette.Water.Lost },
}
local function depthColor(depth: number): Color3
	if depth <= DEPTH_COLORS[1][1] then
		return DEPTH_COLORS[1][2]
	end
	for i = 2, #DEPTH_COLORS do
		local b = DEPTH_COLORS[i]
		if depth < b[1] then
			local a = DEPTH_COLORS[i - 1]
			return a[2]:Lerp(b[2], (depth - a[1]) / (b[1] - a[1]))
		end
	end
	return DEPTH_COLORS[#DEPTH_COLORS][2]
end
local function seaPointY(x: number, z: number, waterY: number, ideal: number): number
	local ground = surfaceY(x, z)
	if ideal < waterY then
		return math.max(waterY, math.min(ground + 0.06, waterY + LIFT))
	end
	-- Dry: a hair under the sea's height, which the ground above it hides; or, where the drawn
	-- ground dips below the sea, under that. (Sinking it further would drag the shoreline out:
	-- the level sheet must meet the sand right at the shore.)
	if ground >= waterY then
		return waterY - 0.02
	end
	return ground - 0.3
end

-- The sea surface: flat at each column's water level, draped over the ground near the shore.
local depths = table.create(BAND_ROWS, 0)
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
		local from = math.min(line, shore)
		local first = from - BAND_BACK
		-- Far up the beach it's all dry: well under the sand.
		setPoint(m.sea, c, 1, Vector3.new(x, if open then waterY else waterY - 50, first - 40))
		setColor(m.sea, c, 1, Palette.Water.Shallow)
		for k = 1, BAND_ROWS do
			local z = from + BAND_OFFSETS[k]
			local ideal = idealY(x, z)
			local y = waterY
			if not open then
				y = seaPointY(x, z, waterY, ideal)
			end
			setPoint(m.sea, c, k + 1, Vector3.new(x, y, z))
			depths[k] = waterY - ideal
		end
		-- A point on dry ground (a wall, a bank, the beach) is hidden, but its colour blends into
		-- the water around it: give it the depth of the nearest wet point in the column, or the
		-- open slope's there, so deep water beside a wall doesn't look shallow.
		for k = 1, BAND_ROWS do
			local depth = depths[k]
			if depth <= 0 then
				local z = from + BAND_OFFSETS[k]
				depth = waterY - Beach.groundY(z)
				for reach = 1, 3 do
					local before, after = depths[k - reach], depths[k + reach]
					if before and before > 0 then
						depth = before
						break
					elseif after and after > 0 then
						depth = after
						break
					end
				end
			end
			setColor(m.sea, c, k + 1, depthColor(depth))
		end
		setPoint(m.sea, c, rows, Vector3.new(x, waterY, line + SEA_OUT))
		setColor(m.sea, c, rows, Palette.Water.Lost)
	end
	flush(m.sea, anchorFor(sea))
	-- The open sea beyond, a hair under the mesh where they meet.
	for i, side in { -1, 1 } do
		local line = Tide.waterlineAt(sea, side * half)
		local y = Beach.waterY(line) - 0.05
		local z = math.min(line, Tide.waterlineAt(sea, 0)) + SEA_OUT - 20 + FAR_LENGTH / 2
		m.far[i].CFrame = CFrame.new(side * (half + SIDE) / 2, y - THICKNESS / 2, z)
	end
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
			setPoint(m.foam, c, 1, Vector3.new(x, surfaceY(x, front - 0.5) + 0.1, front - 0.5))
			setPoint(m.foam, c, 2, Vector3.new(x, surfaceY(x, front) + 0.16, front))
			setPoint(m.foam, c, 3, Vector3.new(x, surfaceY(x, front + 0.8) + 0.1, front + 0.8))
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
				setPoint(sheet, c, 1, Vector3.new(x, y - 0.05, z - 0.9))
				setPoint(sheet, c, 2, Vector3.new(x, y + h, z))
				setPoint(sheet, c, 3, Vector3.new(x, y - 0.05, z + 1.4))
			else
				local folded = Vector3.new(x, y - 0.3, z or shore + 20)
				for r = 1, 3 do
					setPoint(sheet, c, r, folded)
				end
			end
		end
	end
	local anchor = anchorFor(sea)
	flush(m.swash, anchor)
	flush(m.foam, anchor)
	flush(m.wet, anchor)
	for _, sheet in m.crests do
		flush(sheet, anchor)
	end
end

-- The fallback: the same columns drawn with narrow parts --------------------------------------

local LONG = 2000 -- the sea part's length (it's moved, never resized, as the shore moves)
local BACK = 400 -- the length of the part that floods dips up the beach

type Pieces = {
	seaNear: { Part }, -- the sea from the shore out to where it's deep enough to drown
	seaOut: { Part }, -- the sea from there out, deep blue
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
	local result: Pieces = {
		seaNear = {},
		seaOut = {},
		seaIn = {},
		lap = {},
		swash = {},
		wet = {},
		foam = {},
		crests = {},
		sides = {},
	}
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
		result.seaNear[c] = make("Sea", Vector3.new(width, THICKNESS, 1), {
			Material = Palette.Material.Glass,
			Color = Palette.Water.Knee,
			Transparency = 0.3,
		})
		result.seaOut[c] = make("Sea", Vector3.new(width, THICKNESS, LONG), {
			Material = Palette.Material.Glass,
			Color = Palette.Water.Deep,
			Transparency = 0.25,
		})
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
				Material = Palette.Material.Smooth,
				Color = WET_TINT,
				Transparency = 0.7,
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
		local deep = seaProps()
		deep.Color = Palette.Water.Lost -- the open sea is deep
		result.sides[i] = make("Sea", Vector3.new(SIDE, THICKNESS, FAR_LENGTH), deep)
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
		-- Pale out to where the sea is deep enough to drown (on the open slope), deep blue beyond:
		-- the parts can't follow every bank and pit as the meshes do, but the step shows.
		local drown = math.max(shore + 0.5, column.line + beach.WaistDepth / beach.Slope)
		resize(p.seaNear[c], drown - shore)
		place(p.seaNear[c], CFrame.new(x, waterY - THICKNESS / 2 + 0.02, (shore + drown) / 2))
		place(p.seaOut[c], CFrame.new(x, waterY - THICKNESS / 2, drown + LONG / 2))
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
		local line = Tide.waterlineAt(sea, side * half)
		place(
			p.sides[i],
			CFrame.new(side * (half + SIDE / 2), y - THICKNESS / 2, line + FAR_LENGTH / 2 - 400)
		)
	end
end

-- The sea's extent and the columns (once).
local function setup()
	if #xs > 0 then
		return
	end
	zMax = Beach.Depth + beach.SeaExtent + 200
	buildColumns()
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

	setup()

	Workspace.AttributeChanged:Connect(function(name)
		if string.match(name, "^TileBiome") or string.match(name, "^TileLayout") or name == "WaterLab" then
			-- The tile's terrain is rebuilt (and replicates a moment later).
			forgetGround()
			seaUpdatedAt = -math.huge
			task.delay(3, forgetGround)
		end
	end)

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

-- For tools/tests and the water lab (tools/water): everything the water would draw at a
-- moment, without drawing it. Each sheet's points are listed column by column, `rows` to a
-- column, at the X positions in `colXs`.
local virtual: Meshes? = nil
function SeaController._frame(sea: Tide.Sea, wetSea: Tide.Sea, ground: ((number, number) -> number)?)
	setup()
	groundOverride = ground
	forgetGround()
	if not virtual then
		local sheets: { [string]: Sheet } = {}
		local colXsOf: { [string]: { number } } = {}
		local looks: { [string]: { [string]: any } } = {}
		for _, entry in plan() do
			looks[entry.name] = entry.props
			local count = #entry.colXs * entry.rows
			sheets[entry.name] = {
				chunks = {},
				points = table.create(count, Vector3.zero),
				colors = if entry.props.PerPointColor
					then table.create(count, Palette.Water.Shallow)
					else nil,
				cols = #entry.colXs,
				rows = entry.rows,
			}
			colXsOf[entry.name] = entry.colXs
		end
		local crests = {}
		for i = 1, CREST_SLOTS do
			crests[i] = sheets["Crest" .. i]
		end
		virtual = {
			sea = sheets.Sea,
			seaXs = colXsOf.Sea,
			swash = sheets.Swash,
			foam = sheets.Foam,
			wet = sheets.WetSand,
			crests = crests,
			far = { {} :: any, {} :: any },
		}
		(virtual :: any).colXsOf = colXsOf;
		(virtual :: any).byName = sheets;
		(virtual :: any).looks = looks
	end
	local m = virtual :: Meshes
	seaUpdatedAt = -math.huge
	local columns = computeColumns(sea, wetSea)
	updateMeshes(m, sea, columns)
	groundOverride = nil
	local out = {}
	for name, sheet in (m :: any).byName do
		out[name] = {
			points = sheet.points,
			colors = (sheet :: any).colors,
			rows = sheet.rows,
			colXs = (m :: any).colXsOf[name],
			look = (m :: any).looks[name],
		}
	end
	return out, columns, xs
end

-- For tools/tests: the fallback's parts, laid out for one moment.
function SeaController._piecesFrame(sea: Tide.Sea, wetSea: Tide.Sea)
	setup()
	local folder = Instance.new("Folder")
	local built = buildPieces(folder)
	updatePieces(built, sea, computeColumns(sea, wetSea), function(part: Part, frame: CFrame)
		part.CFrame = frame
	end)
	return built, xs
end

-- For tools/tests.
SeaController._update = update
SeaController._limits = { Triangles = MAX_TRIANGLES, Width = MAX_WIDTH }
function SeaController._meshPlan()
	setup()
	local list = {}
	for _, sheet in plan() do
		table.insert(list, { sheet = sheet, ranges = chunkRanges(sheet.colXs, sheet.rows) })
	end
	return list
end

return SeaController
