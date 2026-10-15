--[[
	Writes the geometry of the game's models to JSON, so tools/preview/render.mjs can draw
	them in a browser and you can look at them without opening Studio. It runs the real
	builders (items, vessels, tools, the beach) against Lune's Roblox API, then records every
	part: shape, size, transform, colour, material and transparency.

	Usage (from the repo root): lune run tools/preview/dump.luau <output folder>
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Harness = require("../tests/harness")

local outDir = process.args[1] or "tools/preview/out"
fs.writeDir(outDir)

local h = Harness.new(process.cwd)
local roblox = h.roblox

local function color(c)
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

-- Every BasePart under `root` (and root itself when `includeRoot`), in the frame of `frame`.
local function parts(root, frame, includeRoot)
	local list = {}
	local inverse = frame:Inverse()
	local function add(part)
		local shape = "Block"
		local ok, value = pcall(function()
			return part.Shape.Name
		end)
		if ok then
			shape = value
		end
		table.insert(list, {
			name = part.Name,
			class = part.ClassName,
			shape = shape,
			size = { part.Size.X, part.Size.Y, part.Size.Z },
			cf = { (inverse * part.CFrame):GetComponents() },
			color = color(part.Color),
			material = part.Material.Name,
			transparency = part.Transparency,
		})
	end
	if includeRoot and root:IsA("BasePart") then
		add(root)
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			add(descendant)
		end
	end
	return list
end

local function write(name, data)
	fs.writeFile(outDir .. "/" .. name .. ".json", serde.encode("json", data))
end

local subjects = {}

-- Beach items: the root is the hidden physics body, the models hang off it.
local Items = h.require("Shared/Items")
local ItemService = h.require("Server/ItemService")
for _, def in Items.Catalog do
	local root = ItemService.spawnAt(def, 1, roblox.Vector3.new(0, 5, 0))
	table.insert(subjects, {
		group = "items",
		id = def.Id,
		name = def.Name,
		parts = parts(root, root.CFrame, false),
	})
end

-- Vessels: built at the origin, front towards -Z.
local VesselService = h.require("Server/VesselService")
for id, build in VesselService._builders do
	local model = Harness.wrap(roblox.Instance.new("Model"))
	build(model, roblox.CFrame.new(0, 0, 0))
	table.insert(
		subjects,
		{ group = "vessels", id = id, name = id, parts = parts(model, roblox.CFrame.new(), false) }
	)
end

-- Tools: built at the origin, as they would sit in a hand.
local okTools, ToolModels = pcall(function()
	return h.require("Server/ToolModels")
end)
if okTools then
	for id in ToolModels._builders do
		-- Built the way the game builds it: an Accessory with an invisible Handle at the
		-- hand's grip point. Forward is -Z.
		local accessory = ToolModels.build(id)
		local handle = accessory:FindFirstChild("Handle")
		table.insert(
			subjects,
			{ group = "tools", id = id, name = id, parts = parts(accessory, handle.CFrame, false) }
		)
	end
end

for _, subject in subjects do
	write(subject.group .. "-" .. subject.id, subject)
end

-- The beach itself.
local BeachBuilder = h.require("Server/BeachBuilder")
local map = BeachBuilder.build()
write(
	"beach",
	{ group = "beach", id = "beach", name = "Beach", parts = parts(map, roblox.CFrame.new(), false) }
)

local Lighting = h.game:GetService("Lighting")
local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
write("lighting", {
	Saturation = correction and correction.Saturation or 0,
	Contrast = correction and correction.Contrast or 0,
	CorrectionBrightness = correction and correction.Brightness or 0,
	TintColor = correction and color(correction.TintColor) or { 255, 255, 255 },
	ExposureCompensation = Lighting.ExposureCompensation,
	ClockTime = Lighting.ClockTime,
	Brightness = Lighting.Brightness,
	Ambient = color(Lighting.Ambient),
	OutdoorAmbient = color(Lighting.OutdoorAmbient),
	FogColor = color(Lighting.FogColor),
	FogStart = Lighting.FogStart,
	FogEnd = Lighting.FogEnd,
})

print(string.format("wrote %d models and the beach to %s", #subjects, outDir))
