-- Prints the ground's feature height along a line, to see how steep a shape comes out.
-- lune run tools/gen/shore/probe.luau <zone> <x> <z0> <z1>
local process = require("@lune/process")
local Harness = require("../../tests/harness")
local h = Harness.new(process.cwd)
local Beach = h.require("Shared/Beach")
local Layouts = h.require("Shared/Layouts")
local zone, x, za, zb = tonumber(process.args[1]), tonumber(process.args[2]), tonumber(process.args[3]), tonumber(process.args[4])
local def = Layouts.base(zone)
Layouts.setActive(zone, def, nil, { Crossing = 1, Rooms = {} })
local z0 = Beach.tileRange(zone)
local line = {}
for z = za, zb, 2 do
	table.insert(line, string.format("%d:%.1f", z, Beach.feature(x, z0 + z)))
end
print(table.concat(line, " "))
