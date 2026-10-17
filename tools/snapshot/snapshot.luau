--[[
	Run inside the engine (tools/snapshot/snapshot.py sends it through Open Cloud Luau
	Execution, with SNAPSHOT_JSON put in front): builds the beach as the game does, optionally
	sets zones' biomes and choices, or lays out a showcase, and returns what's in a region: the
	terrain's height and colour on a grid, and every visible part (position, rotation, size,
	colour, shape), for snapshot.py to draw.

	SNAPSHOT_JSON: { region = {x0, z0, x1, z1}, step = 2, zones = { ["6"] = { biome, choice } },
	showcase = "decor" | nil, limit = 9000 }
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local JOB = HttpService:JSONDecode(SNAPSHOT_JSON) -- luacheck: ignore (set by snapshot.py)
local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Layouts = require(Shared.Layouts)
local Looks = require(Shared.Looks)

require(Server.BeachBuilder).build()
local BiomeService = require(Server.BiomeService)
BiomeService.init(function() end, function() end)
for tile = 1, Beach.ActiveTiles do
	local want = JOB.zones and JOB.zones[tostring(tile)]
	BiomeService.set(tile, want and want.biome or nil, (want and want.choice) or "1:")
end

if JOB.showcase == "decor" then
	-- Every decor kind in a row on zone 1's open sand, for a close look.
	local Decor = require(Shared.Decor)
	local DecorService = require(Server.DecorService)
	local kinds = {}
	for kind in Decor.Kinds do
		table.insert(kinds, kind)
	end
	table.sort(kinds)
	local entries = {}
	for index, kind in kinds do
		table.insert(entries, { Kind = kind, At = { -300 + (index - 1) * 36, 300 }, Yaw = 30 })
	end
	Layouts.setActive(1, { Name = "showcase", Primitives = {}, Decor = entries })
	DecorService.build(1)
end

local x0, z0, x1, z1 = JOB.region[1], JOB.region[2], JOB.region[3], JOB.region[4]
local step = JOB.step or 2

-- The terrain: height and colour on a grid (the colour of the material the terrain is built of).
local reader = Looks.terrainReader()
local terrain = {}
for z = z0, z1, step do
	local row = {}
	for x = x0, x1, step do
		local height, rock, shapeMaterial = Beach.shapeAt(x, z)
		local floor, rockMaterial = reader(x, z)
		local paint = Beach.paintAt(x, z)
		local name = shapeMaterial or (if rock then rockMaterial.Name elseif paint then paint else floor.Name)
		local color = Config.Looks.Materials[name] or Color3.new(1, 0, 1)
		local roof = Beach.roofAt(x, z) ~= nil
		table.insert(
			row,
			string.format(
				"%.1f %02x%02x%02x%s",
				Beach.groundY(z) + height,
				color.R * 255,
				color.G * 255,
				color.B * 255,
				if roof then " R" else ""
			)
		)
	end
	table.insert(terrain, table.concat(row, ";"))
end

-- Every visible part in the region (and a margin above the ground).
local parts = {}
local limit = JOB.limit or 9000
for _, part in Workspace:GetDescendants() do
	if #parts >= limit then
		break
	end
	if part:IsA("BasePart") and part.Transparency < 0.95 and not part:IsA("Terrain") then
		local p = part.Position
		if p.X >= x0 - 20 and p.X <= x1 + 20 and p.Z >= z0 - 20 and p.Z <= z1 + 20 then
			local shape = if part:IsA("Part")
				then part.Shape.Name
				elseif part:IsA("WedgePart") then "Wedge"
				else "Block"
			local cf = part.CFrame
			local r = { cf:GetComponents() }
			table.insert(parts, {
				c = { r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12] },
				s = { part.Size.X, part.Size.Y, part.Size.Z },
				k = string.format("%02x%02x%02x", part.Color.R * 255, part.Color.G * 255, part.Color.B * 255),
				t = part.Transparency,
				h = shape,
				n = part.Name,
				m = part.Material.Name,
			})
		end
	end
end
return HttpService:JSONEncode({ region = JOB.region, step = step, terrain = terrain, parts = parts })
