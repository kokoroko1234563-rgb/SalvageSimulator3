-- The custom hotbar: a row of slots holding grabbing tools (shop, magical and exotic alike).
-- Pressing a slot's number, or clicking it, equips that tool. The saved bar is a list of
-- tool ids by slot ("" = empty). A tool keeps its slot through a rebirth, so buying it back
-- puts it where it was. New tools go into the first free slot.

local Gear = require(script.Parent.Gear)

local Hotbar = {}

Hotbar.Slots = 6
Hotbar.Attribute = "Hotbar" -- player attribute: the bar as comma-separated ids, by slot

function Hotbar.empty(): { string }
	local bar = {}
	for i = 1, Hotbar.Slots do
		bar[i] = ""
	end
	return bar
end

-- Cleans a saved or received bar: the right length, only real tool ids, no duplicates.
function Hotbar.sanitize(data: any): { string }
	local bar = Hotbar.empty()
	if type(data) ~= "table" then
		return bar
	end
	local seen = {}
	for i = 1, Hotbar.Slots do
		local id = data[i]
		if type(id) == "string" and Gear.findTool(id) and not seen[id] then
			bar[i] = id
			seen[id] = true
		end
	end
	return bar
end

-- Puts a tool in the first slot that's empty or holds a tool the player doesn't own.
-- Does nothing if it's already on the bar or the bar is full. Returns whether it changed.
function Hotbar.autoAdd(bar: { string }, id: string, owned: { [string]: boolean }): boolean
	if not Gear.findTool(id) or table.find(bar, id) then
		return false
	end
	for i = 1, Hotbar.Slots do
		if bar[i] == "" or not owned[bar[i]] then
			bar[i] = id
			return true
		end
	end
	return false
end

-- Puts `id` in `slot` ("" clears it). If it was in another slot, the two slots swap.
function Hotbar.place(bar: { string }, slot: number, id: string)
	local from = if id ~= "" then table.find(bar, id) else nil
	if from then
		bar[from] = bar[slot]
	end
	bar[slot] = id
end

function Hotbar.encode(bar: { string }): string
	return table.concat(bar, ",")
end

function Hotbar.decode(text: string?): { string }
	local bar = Hotbar.empty()
	local i = 1
	for id in string.gmatch((text or "") .. ",", "([^,]*),") do
		if i > Hotbar.Slots then
			break
		end
		bar[i] = id
		i += 1
	end
	return bar
end

return Hotbar
