-- Things on the beach the water reacts to. Tag a part "WaterObstacle" (CollectionService) and
-- give it a "Water" attribute saying how the water treats it:
--   "Solid" (the default): the water can't pass through it. The run-up stops against it unless
--     the wave climbs higher than its top, so a big wave overtops a low sandbank while a small
--     one stops at it. Out in the sea, waves are sheltered behind it where it stands above the
--     water: they push much less and their crests vanish.
--   "Under": the water goes under it (a pier deck, an arch). It has no effect on the water.
-- The part's top is taken from its shape: a block's flat top, a cylinder lying along its X
-- axis (a ridge, like the sandbanks), or a ball (a dome, like a boulder). Parts may be turned
-- about the vertical axis. The water code (Waves, the sea visuals, the swash) asks this module
-- where solid things stand, and both the server and every client build the same lookup from
-- the tagged parts, so what you see matches what pushes you.
--
-- WaterObstacles.mark(part, kind) tags a part from code.

local CollectionService = game:GetService("CollectionService")

local Beach = require(script.Parent.Beach)
local Config = require(script.Parent.Config)

local cfg = Config.Water

local WaterObstacles = {}

WaterObstacles.Tag = "WaterObstacle"

type Obstacle = {
	part: BasePart,
	shape: "Block" | "Ridge" | "Dome",
	inverse: CFrame,
	y: number,
	size: Vector3,
	buckets: { number },
}

local byPart: { [BasePart]: Obstacle } = {}
local watched: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local buckets: { [number]: { Obstacle } } = {}

local function bucketOf(x: number): number
	return math.floor(x / cfg.Bucket)
end

function WaterObstacles.remove(part: BasePart)
	local obstacle = byPart[part]
	if not obstacle then
		return
	end
	byPart[part] = nil
	for _, key in obstacle.buckets do
		local list = buckets[key]
		local index = list and table.find(list, obstacle)
		if index then
			table.remove(list, index)
		end
	end
end

function WaterObstacles.add(part: BasePart)
	WaterObstacles.remove(part)
	if not watched[part] then
		-- Re-register it when it moves (props shift when a zone's ground changes shape).
		watched[part] = true
		local ok, signal = pcall(function()
			return part:GetPropertyChangedSignal("CFrame")
		end)
		if ok and signal then
			signal:Connect(function()
				if byPart[part] then
					WaterObstacles.add(part)
				end
			end)
		end
	end
	if (part:GetAttribute("Water") or "Solid") ~= "Solid" then
		return -- "Under": the water passes beneath it
	end
	local shape = if part.Shape == Enum.PartType.Cylinder
		then "Ridge"
		elseif part.Shape == Enum.PartType.Ball then "Dome"
		else "Block"
	local cf = part.CFrame
	local size = part.Size
	-- The footprint's X range, from its corners (it may be turned about Y).
	local half = size / 2
	local minX, maxX = math.huge, -math.huge
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local corner = cf * Vector3.new(half.X * sx, 0, half.Z * sz)
			minX = math.min(minX, corner.X)
			maxX = math.max(maxX, corner.X)
		end
	end
	local obstacle: Obstacle = {
		part = part,
		shape = shape,
		inverse = cf:Inverse(),
		y = cf.Position.Y,
		size = size,
		buckets = {},
	}
	for key = bucketOf(minX), bucketOf(maxX) do
		buckets[key] = buckets[key] or {}
		table.insert(buckets[key], obstacle)
		table.insert(obstacle.buckets, key)
	end
	byPart[part] = obstacle
end

-- Tags a part as a water obstacle ("Solid" or "Under") and registers it.
function WaterObstacles.mark(part: BasePart, kind: string?)
	part:SetAttribute("Water", kind or "Solid")
	CollectionService:AddTag(part, WaterObstacles.Tag)
	WaterObstacles.add(part)
end

-- Whether anything solid stands anywhere along this X (a quick check before scanning).
function WaterObstacles.near(x: number): boolean
	local list = buckets[bucketOf(x)]
	return list ~= nil and #list > 0
end

-- The height of the highest solid top over (x, z), or nil if nothing stands there.
function WaterObstacles.topAt(x: number, z: number): number?
	local list = buckets[bucketOf(x)]
	if not list then
		return nil
	end
	local best: number? = nil
	for _, obstacle in list do
		local p = obstacle.inverse * Vector3.new(x, obstacle.y, z)
		local size = obstacle.size
		local top: number? = nil
		if obstacle.shape == "Block" then
			if math.abs(p.X) <= size.X / 2 and math.abs(p.Z) <= size.Z / 2 then
				top = obstacle.y + size.Y / 2
			end
		elseif obstacle.shape == "Ridge" then
			local r = size.Y / 2
			if math.abs(p.X) <= size.X / 2 and math.abs(p.Z) < r then
				top = obstacle.y + math.sqrt(r * r - p.Z * p.Z)
			end
		else
			local r = size.X / 2
			local d2 = p.X * p.X + p.Z * p.Z
			if d2 < r * r then
				top = obstacle.y + math.sqrt(r * r - d2)
			end
		end
		if top and (not best or top > best) then
			best = top
		end
	end
	return best
end

-- The highest solid thing over (x, z): an obstacle, or the ground's own ridges.
local function solidAt(x: number, z: number): number?
	local top = WaterObstacles.topAt(x, z)
	if Beach.isRough(z) then
		local ground = Beach.groundAt(x, z)
		if not top or ground > top then
			top = ground
		end
	end
	return top
end

-- How far up the beach a wave's run-up really gets at X. `front` is how far it would get on
-- open sand (0 or negative: studs up the beach from the waterline `line`), and `reachY` the
-- height its water climbs to. It stops just short of anything solid that rises above that.
function WaterObstacles.limitFront(x: number, line: number, front: number, reachY: number): number
	if front >= 0 or not (WaterObstacles.near(x) or Beach.isRough(line) or Beach.isRough(line + front)) then
		return front
	end
	local z = line
	while z > line + front do
		local top = solidAt(x, z)
		if top and top > reachY then
			return math.min(0, z + 1 - line)
		end
		z -= cfg.Step
	end
	return front
end

-- Whether (x, z) is sheltered from waves rolling in from the sea: something solid stands
-- above the water surface (waterY) within ShelterRange seaward of it.
function WaterObstacles.sheltered(x: number, z: number, waterY: number): boolean
	if not (WaterObstacles.near(x) or Beach.isRough(z) or Beach.isRough(z + cfg.ShelterRange)) then
		return false
	end
	local zz = z + cfg.ShelterStep
	while zz <= z + cfg.ShelterRange do
		local top = solidAt(x, zz)
		if top and top > waterY + cfg.ShelterHeight then
			return true
		end
		zz += cfg.ShelterStep
	end
	return false
end

-- Picks up every tagged part now and as they appear (the map replicates to clients).
function WaterObstacles.init()
	for _, part in CollectionService:GetTagged(WaterObstacles.Tag) do
		if part:IsA("BasePart") then
			WaterObstacles.add(part)
		end
	end
	CollectionService:GetInstanceAddedSignal(WaterObstacles.Tag):Connect(function(part)
		if part:IsA("BasePart") then
			WaterObstacles.add(part)
		end
	end)
	CollectionService:GetInstanceRemovedSignal(WaterObstacles.Tag):Connect(function(part)
		if part:IsA("BasePart") then
			WaterObstacles.remove(part)
		end
	end)
end

-- For tools/tests.
function WaterObstacles._clear()
	byPart = {}
	buckets = {}
end

return WaterObstacles
