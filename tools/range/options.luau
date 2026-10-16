--[[
	Lists every way a zone can come out (Layouts.options): one line per way, the choice
	(Layouts.encode) and its label, tab-separated. For run.py --every.

	Usage: lune run tools/range/options.luau <zone> [Base | biome id | layout path]
]]

local process = require("@lune/process")

local Harness = require("../tests/harness")

local h = Harness.new(process.cwd)
local Layouts = h.require("Shared/Layouts")

local zone = tonumber(process.args[1]) or error("which zone?")
local spec = process.args[2] or "Base"

local def
if spec == "Base" then
	def = Layouts.base(zone)
else
	def = Layouts.forBiome(spec, zone) or Layouts.forPlanned(spec, zone)
	if not def then
		-- A layout path: "Zones/Zone5", "Biomes/Planned/CoralGarden".
		local id = string.match(spec, "([^/]+)$")
		local index = tonumber(string.match(id or "", "^Zone(%d+)$"))
		def = if index
			then Layouts.base(index)
			else Layouts.forBiome(id, zone) or Layouts.forPlanned(id, zone)
	end
end
assert(def, "no layout for " .. spec .. " in zone " .. zone)
for _, way in Layouts.options(def) do
	print(
		Layouts.encode(way.Choice) .. "\t" .. (if way.Label ~= "" then way.Label else "first of everything")
	)
end
