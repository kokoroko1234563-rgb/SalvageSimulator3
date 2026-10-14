-- Shop gear: grabbing tools and vessels. Order matters: a player always uses the best
-- (highest-listed) tool they own.

local Gear = {}

-- Weight classes and water depth bands are numbered so they can be compared.
Gear.WeightClass = { Light = 1, Medium = 2, Heavy = 3, VeryHeavy = 4 }
Gear.Depth = { Dry = 0, Shallow = 1, KneeDeep = 2, Waist = 3, Deep = 4 }

-- Grip is the acceleration (studs/s^2) the tool can hold an item with; gravity is ~196,
-- so a weak grip barely lifts and is easily knocked loose by waves.
-- GripBreak is how far (studs) an item can be pulled from the hold point before it slips.
Gear.Tools = {
	{
		Id = "BareHands",
		Name = "Bare Hands",
		Price = 0,
		Reach = 10,
		Lift = Gear.WeightClass.Light,
		Depth = Gear.Depth.Shallow,
		Grip = 235,
		GripBreak = 5,
		Note = "Weak grip",
		Available = true,
	},
	{
		Id = "BeachRake",
		Name = "Beach Rake",
		Price = 150,
		Reach = 14,
		Lift = Gear.WeightClass.Light,
		Depth = Gear.Depth.Shallow,
		Grip = 260,
		GripBreak = 6,
		Note = "Pulls items out of the shallows",
		Available = true,
	},
	{
		Id = "FishingNet",
		Name = "Fishing Net",
		Price = 600,
		Reach = 14,
		Lift = Gear.WeightClass.Medium,
		Depth = Gear.Depth.Shallow,
		Grip = 330,
		GripBreak = 7,
		Note = "Better grip",
		Available = true,
	},
	{
		Id = "GrabberClaw",
		Name = "Grabber Claw",
		Price = 2500,
		Reach = 18,
		Lift = Gear.WeightClass.Medium,
		Depth = Gear.Depth.KneeDeep,
		Grip = 360,
		GripBreak = 7,
		Note = "Grabs from knee-deep water",
		Available = true,
	},
	{
		-- Not in the doc's Milestone 1 list, but enabled so Heavy placeholder items can be tested.
		Id = "BoatHook",
		Name = "Boat Hook",
		Price = 9000,
		Reach = 18,
		Lift = Gear.WeightClass.Heavy,
		Depth = Gear.Depth.Waist,
		Grip = 420,
		GripBreak = 8,
		Note = "Reaches deeper water",
		Available = true,
	},
	{
		Id = "HandWinch",
		Name = "Hand Winch",
		Price = 30000,
		Reach = 24,
		Lift = Gear.WeightClass.Heavy,
		Depth = Gear.Depth.Waist,
		Grip = 520,
		GripBreak = 10,
		Note = "Strong grip against waves",
		Available = false,
	},
	{
		Id = "ElectricWinch",
		Name = "Electric Winch",
		Price = 90000,
		Reach = 24,
		Lift = Gear.WeightClass.VeryHeavy,
		Depth = Gear.Depth.Waist,
		Grip = 620,
		GripBreak = 10,
		Note = "Pulls chests out of rough water",
		Available = false,
	},
}

Gear.Vessels = {
	{
		Id = "Wheelbarrow",
		Name = "Wheelbarrow",
		Price = 250,
		Capacity = 4,
		Note = "Slow, tips easily",
		Available = true,
	},
	{
		Id = "BeachWagon",
		Name = "Beach Wagon",
		Price = 1500,
		Capacity = 6,
		Note = "More stable",
		Available = true,
	},
	{
		Id = "SandCart",
		Name = "Sand Cart",
		Price = 6000,
		Capacity = 10,
		Note = "Fast on soft sand",
		Available = false,
	},
	{
		Id = "QuadBike",
		Name = "Quad Bike + Trailer",
		Price = 25000,
		Capacity = 16,
		Note = "Fast, bumps can spill items",
		Available = false,
	},
	{
		Id = "Dinghy",
		Name = "Inflatable Dinghy",
		Price = 60000,
		Capacity = 14,
		Note = "Travels through shallow water",
		Available = false,
	},
	{
		Id = "PickupTruck",
		Name = "Pickup Truck",
		Price = 150000,
		Capacity = 24,
		Note = "Fastest and most stable",
		Available = false,
	},
}

local toolsById = {}
for index, tool in Gear.Tools do
	tool.Order = index
	toolsById[tool.Id] = tool
end

local vesselsById = {}
for index, vessel in Gear.Vessels do
	vessel.Order = index
	vesselsById[vessel.Id] = vessel
end

function Gear.getTool(id: string?)
	return toolsById[id or ""] or Gear.Tools[1]
end

function Gear.getVessel(id: string?)
	return vesselsById[id or ""]
end

-- Picks the best tool from a set of owned ids ({ [id] = true }).
function Gear.bestTool(owned: { [string]: boolean })
	local best = Gear.Tools[1]
	for _, tool in Gear.Tools do
		if owned[tool.Id] then
			best = tool
		end
	end
	return best
end

function Gear.canLift(tool, weightClass: number): boolean
	return weightClass <= tool.Lift
end

function Gear.canReachDepth(tool, depthBand: number): boolean
	return depthBand <= tool.Depth
end

return Gear
