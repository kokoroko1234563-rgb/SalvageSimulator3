--[[
	The water lab: runs the game's own water code (src/client/SeaController) for one moment,
	on the terrain as TerrainBuilder really builds it, and writes what it would draw next to
	what the game treats as water, for tools/water/water.py to draw and check.

	lune run tools/water/lab.luau <zone> <layout> <choice> <waterline> <x0> <z0> <x1> <z1> [step] [seconds]

	  zone       1 to 6
	  layout     Base (the zone's own), a biome id, Lab (tools/water's test layout), or Flat
	  choice     the crossing and rooms, e.g. 1: or 2:1,3
	  waterline  the tide's waterline Z at X = 0 (the waterline elsewhere differs a little)
	  x0 .. z1   the region to report
	  step       studs between the reported ground points (default 2)
	  seconds    moves the moment on by this much (the waves), default 0

	Writes JSON to stdout:
	  region, step, waterY (by column), ground: rows of "floor ideal roofBottom material",
	  sheets: { name = { rows, cols = { { x, ys, zs } } } }, columns: { x, line, shore, edge, wetTo }
]]

local process = require("@lune/process")
local serde = require("@lune/serde")

local Harness = require("../tests/harness")
local h = Harness.new(process.cwd)
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3

local args = process.args
local zone = tonumber(args[1]) or 1
local layoutName = args[2] or "Base"
local choiceText = args[3] or "1:"
local target = tonumber(args[4]) or 200
local x0, z0, x1, z1 =
	tonumber(args[5]) or -370, tonumber(args[6]) or 0, tonumber(args[7]) or 370, tonumber(args[8]) or 600
local step = tonumber(args[9]) or 2
local later = tonumber(args[10]) or 0

local Config = h.require("Shared/Config")
local Beach = h.require("Shared/Beach")
local Tide = h.require("Shared/Tide")
local Layouts = h.require("Shared/Layouts")
local TerrainBuilder = h.require("Server/TerrainBuilder")
local SeaController = h.require("Client/SeaController")

local ws = h.game:GetService("Workspace")

-- The zone's layout.
local tile = zone
if layoutName == "Flat" then
	Layouts.setActive(tile, false)
else
	local def
	if layoutName == "Lab" then
		def = Layouts.lab()
	elseif layoutName == "Base" then
		def = Layouts.base(zone)
	else
		def = Layouts.forBiome(layoutName, zone) or Layouts.forPlanned(layoutName, zone)
	end
	assert(def, "no layout " .. layoutName .. " for zone " .. zone)
	Layouts.setActive(tile, def, zone, Layouts.decode(def, choiceText))
end

-- The tide: going out, at the moment its waterline (at X = 0) reaches `target`.
local NOW = 100000
local lo, hi = 0, 0.999
for _ = 1, 40 do
	local mid = (lo + hi) / 2
	ws:SetAttribute(Tide.StartAttribute, Tide.startFor("Out", mid, NOW))
	if Tide.waterline(NOW) < target then
		lo = mid
	else
		hi = mid
	end
end
ws:SetAttribute(Tide.StartAttribute, Tide.startFor("Out", (lo + hi) / 2, NOW))
local sea = Tide.sea(NOW + later)
local scale = ws:GetAttribute(Tide.ScaleAttribute) or Config.Tide.TimeScale
local wetSea = Tide.sea(NOW + later - Config.Waves.WetSeconds * scale)

-- The terrain as built: its voxels, for the region (and a margin, for the water's columns).
local VOXEL = Config.Beach.Terrain.Voxel
local function snap(v: number, up: boolean): number
	return (if up then math.ceil(v / VOXEL) else math.floor(v / VOXEL)) * VOXEL
end
local tz0, tz1 = snap(math.max(z0 - 140, Beach.tileRange(1)), false), snap(z1 + 140, true)
local tx0, tx1 =
	snap(math.max(x0 - 16, -Beach.HalfWidth - 40), false), snap(math.min(x1 + 16, Beach.HalfWidth + 40), true)
local floorAt: { [number]: { [number]: number } } = {}
local materialAt: { [number]: { [number]: any } } = {}
local slabZ = tz0
while slabZ < tz1 do
	local slabEnd = math.min(slabZ + 64, tz1)
	local yLow, yHigh = TerrainBuilder.heightRange(slabZ, slabEnd)
	local materials, occupancy =
		TerrainBuilder.slab(Vector3.new(tx0, yLow, slabZ), Vector3.new(tx1, yHigh, slabEnd), slabZ, slabEnd)
	for ix = 1, #occupancy do
		local column = occupancy[ix]
		for iz = 1, #column[1] do
			-- The floor: the solid run from the bottom up (a roof above it is a separate run).
			local top = yLow
			local material = nil
			for iy = 1, #column do
				local fill = column[iy][iz]
				if fill <= 0 then
					break
				end
				top = yLow + (iy - 1) * VOXEL + fill * VOXEL
				material = materials[ix][iy][iz]
			end
			local cx = tx0 + (ix - 1) * VOXEL
			local cz = slabZ + (iz - 1) * VOXEL
			floorAt[cx] = floorAt[cx] or {}
			materialAt[cx] = materialAt[cx] or {}
			-- Roblox draws the surface half a cell above the fill (TerrainBuilder).
			floorAt[cx][cz] = top + VOXEL / 2
			materialAt[cx][cz] = material
		end
	end
	slabZ = slabEnd
end

-- The drawn ground between cell centres, as the client's rays find it.
local function cellFloor(cx: number, cz: number): number
	local col = floorAt[cx]
	local y = col and col[cz]
	return y or Beach.groundAt(cx + VOXEL / 2, cz + VOXEL / 2)
end
local function drawnGround(x: number, z: number): number
	local fx, fz = (x - VOXEL / 2) / VOXEL, (z - VOXEL / 2) / VOXEL
	local ix, iz = math.floor(fx), math.floor(fz)
	local tx, tz = fx - ix, fz - iz
	local ax, az = ix * VOXEL, iz * VOXEL
	local a = cellFloor(ax, az) + (cellFloor(ax, az + VOXEL) - cellFloor(ax, az)) * tz
	local b = cellFloor(ax + VOXEL, az) + (cellFloor(ax + VOXEL, az + VOXEL) - cellFloor(ax + VOXEL, az)) * tz
	return a + (b - a) * tx
end

local sheets, columns, columnXs = SeaController._frame(sea, wetSea, drawnGround)

local function r2(v: number): number
	return math.floor(v * 100 + 0.5) / 100
end

-- The ground and the game's water, on the reporting grid.
local ground = {}
local z = z0
while z <= z1 do
	local row = {}
	local x = x0
	while x <= x1 do
		local bottom, top = Beach.roofAt(x, z)
		local cx, cz = snap(x, false), snap(z, false)
		local material = materialAt[cx] and materialAt[cx][cz]
		table.insert(
			row,
			string.format(
				"%.2f %.2f %s %s %s",
				drawnGround(x, z),
				Beach.groundAt(x, z),
				if bottom then string.format("%.2f", bottom) else "-",
				if top then string.format("%.2f", top) else "-",
				if material then material.Name else "-"
			)
		)
		x += step
	end
	table.insert(ground, table.concat(row, ";"))
	z += step
end

local waterYs = {}
local x = x0
while x <= x1 do
	table.insert(waterYs, r2(Beach.waterYAt(sea, x)))
	x += step
end

local out =
	{ region = { x0, z0, x1, z1 }, step = step, waterY = waterYs, ground = ground, sheets = {}, columns = {} }
for name, sheet in sheets do
	local cols = {}
	for c, cx in sheet.colXs do
		if cx >= x0 - 12 and cx <= x1 + 12 then
			local ys, zs = {}, {}
			for r = 1, sheet.rows do
				local p = sheet.points[(c - 1) * sheet.rows + r]
				table.insert(ys, r2(p.Y))
				table.insert(zs, r2(p.Z))
			end
			table.insert(cols, { r2(cx), ys, zs })
		end
	end
	local look = sheet.look or {}
	local color = look.Color or roblox.Color3.new(1, 0, 1)
	local colors = nil
	if sheet.colors then
		colors = {}
		for c, cx in sheet.colXs do
			if cx >= x0 - 12 and cx <= x1 + 12 then
				local list = {}
				for r = 1, sheet.rows do
					local k = sheet.colors[(c - 1) * sheet.rows + r]
					table.insert(list, string.format("%02x%02x%02xff", k.R * 255, k.G * 255, k.B * 255))
				end
				table.insert(colors, list)
			end
		end
	end
	out.sheets[name] = {
		rows = sheet.rows,
		cols = cols,
		colors = colors,
		color = string.format("%02x%02x%02x", color.R * 255, color.G * 255, color.B * 255),
		transparency = look.Transparency or 0,
	}
end
for c, column in columns do
	local cx = columnXs[c]
	if cx >= x0 - 12 and cx <= x1 + 12 then
		table.insert(out.columns, {
			r2(cx),
			r2(column.line),
			r2(column.shore),
			r2(column.edge),
			r2(column.wetTo),
			r2(column.waterY),
		})
	end
end
print(serde.encode("json", out))
