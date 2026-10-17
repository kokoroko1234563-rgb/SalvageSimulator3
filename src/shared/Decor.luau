-- The layouts' decor: props a layout places on its ground (its Decor list, see Layouts), built
-- by DecorService from these kinds. A Decor entry is
--   { Kind = "Kelp", At = {x, z} }                          one, there
--   { Kind = "Kelp", Area = { {x, z}, ... }, Count = 12 }   Count scattered over an area
--   { Kind = "Kelp", Path = { {x, z}, ... }, Count = 8 }    Count strung along a path
-- with optional Scale (1 = normal size) and Yaw (degrees; random when left out).
-- Each kind's fields:
--   Ward    a light the Gloom can't reach within this many studs (the glowing kinds)
--   OnRock  it may stand on rock (barnacles); others are only put on open ground
--   Note    what it is

local Decor = {}

Decor.Kinds = {
	Kelp = { Note = "a clump of tall kelp, standing up out of the sand" },
	Weed = { Note = "a low mat of weed" },
	Timber = { Note = "a broken, waterlogged timber lying in the sand" },
	WreckRibs = { Note = "the curved ribs of a long-sunk hull, half buried" },
	Anchor = { Note = "an old rusted anchor, tipped over, with its chain" },
	Chain = { Note = "a length of heavy rusted chain trailing over the ground" },
	Bones = { Note = "the bleached ribs of something big, arching out of the sand" },
	DeadCoral = { Note = "a branching clump of dead, grey coral" },
	Barnacles = { OnRock = true, Note = "a crust of barnacles" },
	Urchins = { Note = "a cluster of black sea urchins" },
	Starfish = { Note = "a starfish" },
	Pebbles = { Note = "a scatter of pebbles and shingle" },
	Crate = { Note = "a smashed crate" },
	GlowShells = { Ward = 9, Note = "a cluster of shells glowing pale cyan: a small ward against the Gloom" },
	GlowWeed = { Ward = 12, Note = "a clump of weed glowing green: a ward against the Gloom" },
	LanternPost = {
		Ward = 18,
		Note = "an old lantern on a post, still burning: a strong ward against the Gloom",
	},
}

Decor.MaxCount = 60 -- the most props one entry scatters

local function isPoint(value: any): boolean
	return type(value) == "table" and type(value[1]) == "number" and type(value[2]) == "number"
end

-- What's wrong with a layout's Decor list (messages).
function Decor.problems(list: any, where: string): { string }
	local problems = {}
	if list == nil then
		return problems
	end
	if type(list) ~= "table" then
		return { where .. ": Decor is a list" }
	end
	for index, entry in list do
		local name = where .. " decor " .. index
		if type(entry) ~= "table" or not Decor.Kinds[entry.Kind] then
			table.insert(
				problems,
				name .. ": unknown kind " .. tostring(type(entry) == "table" and entry.Kind)
			)
			continue
		end
		local shapes = (if entry.At ~= nil then 1 else 0)
			+ (if entry.Area ~= nil then 1 else 0)
			+ (if entry.Path ~= nil then 1 else 0)
		if shapes ~= 1 then
			table.insert(problems, name .. ": needs one of At, Area or Path")
		elseif entry.At ~= nil and not isPoint(entry.At) then
			table.insert(problems, name .. ": At is {x, z}")
		elseif entry.At == nil then
			local points = entry.Area or entry.Path
			local ok = type(points) == "table" and #points >= (if entry.Area then 3 else 2)
			for _, point in (if ok then points else {}) do
				ok = ok and isPoint(point)
			end
			if not ok then
				table.insert(
					problems,
					name
						.. ": "
						.. (if entry.Area then "Area needs 3+" else "Path needs 2+")
						.. " {x, z} points"
				)
			end
			if type(entry.Count) ~= "number" or entry.Count < 1 or entry.Count > Decor.MaxCount then
				table.insert(problems, name .. ": Count is 1 to " .. Decor.MaxCount)
			end
		end
		for key, value in entry do
			if key == "Scale" and (type(value) ~= "number" or value <= 0 or value > 4) then
				table.insert(problems, name .. ": Scale is above 0 and at most 4")
			elseif key == "Yaw" and type(value) ~= "number" then
				table.insert(problems, name .. ": Yaw is in degrees")
			elseif not table.find({ "Kind", "At", "Area", "Path", "Count", "Scale", "Yaw" }, key) then
				table.insert(problems, name .. ": unknown field " .. tostring(key))
			end
		end
	end
	return problems
end

return Decor
