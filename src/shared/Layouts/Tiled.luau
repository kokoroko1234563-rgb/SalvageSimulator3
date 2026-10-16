-- Turns a layout drawn for the old 152-stud tiles into a zone's layout: the tile repeated
-- down the zone, with the shapes fading out at each old tile edge as before (FadeEvery), so
-- it plays as it did. For layouts not yet redrawn for whole zones. Takes one layout, or a
-- table of them by zone.

local OLD_TILE = 152
local REPEATS = 4

local function shifted(value: any, dz: number): any
	if type(value) ~= "table" then
		return value
	end
	if type(value[1]) == "number" and type(value[2]) == "number" and #value == 2 then
		return { value[1], value[2] + dz }
	end
	local copy = {}
	for key, item in value do
		copy[key] = shifted(item, dz)
	end
	return copy
end

local function tiled(layout: any): any
	local out = { Name = layout.Name, Primitives = {}, FadeEvery = OLD_TILE }
	for _, key in { "Loot", "Entrances", "Hazards" } do
		if layout[key] then
			out[key] = {}
		end
	end
	for k = 0, REPEATS - 1 do
		local dz = k * OLD_TILE
		for _, key in { "Primitives", "Loot", "Entrances", "Hazards" } do
			for _, item in layout[key] or {} do
				table.insert(out[key], shifted(item, dz))
			end
		end
	end
	return out
end

return function(value: any): any
	if value.Primitives then
		return tiled(value)
	end
	local byZone = {}
	for zone, layout in value do
		byZone[zone] = tiled(layout)
	end
	return byZone
end
