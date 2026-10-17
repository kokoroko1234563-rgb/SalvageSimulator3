-- Lists where a walker on the 4-stud grid can cross a band of the zone straight down (no step over 0.9 slope).
-- lune run tools/gen/shore/leaks.luau <zone> <z0> <z1>
local process = require("@lune/process")
local Harness = require("../../tests/harness")
local h = Harness.new(process.cwd)
local Beach = h.require("Shared/Beach")
local Layouts = h.require("Shared/Layouts")
local zone, za, zb = tonumber(process.args[1]), tonumber(process.args[2]), tonumber(process.args[3])
Layouts.setActive(zone, Layouts.base(zone), nil, { Crossing = tonumber(process.args[4]) or 1, Rooms = {} })
local zs = Beach.tileRange(zone)
local open = {}
for x = -360, 360, 4 do
	local ok = true
	local prev = Beach.groundAt(x, zs + za)
	for z = za + 4, zb, 4 do
		local y = Beach.groundAt(x, zs + z)
		if y - prev > 3.6 then
			ok = false
			break
		end
		prev = y
	end
	if ok then
		table.insert(open, x)
	end
end
print(#open .. " open columns: " .. table.concat(open, ","))
