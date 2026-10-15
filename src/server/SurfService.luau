-- The swash moves unclaimed items around. Unclaimed items are anchored (no physics), so the
-- wave field can't push them; instead, after each wave has slid back, every unclaimed item
-- it reached may get dragged a few studs: mostly toward the sea, sometimes up the beach,
-- further for bigger waves. Leaving loot by the water is a gamble, and things washed out far
-- enough are lost to the tide (ItemService). Claimed items left lying around (Loose) are
-- simulated, so the wave field pushes and drags them directly.

local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)
local Waves = require(Shared.Waves)

local ItemService = require(script.Parent.ItemService)

local cfg = Config.Waves
local rng = Random.new()

local SurfService = {}

local dragging: { [BasePart]: Tween } = {}

local function drag(item: BasePart, size: number)
	local distance = cfg.DragDistance * size * rng:NextNumber(0.4, 1)
	-- Ordinary waves shuffle things either way; big ones mostly drag them out to sea.
	local seaward = if size >= cfg.SetSize then 0.85 else 0.5
	local dz = if rng:NextNumber() < seaward then distance else -distance
	local dx = rng:NextNumber(-0.5, 0.5) * distance
	local from = item.Position
	local toZ = from.Z + dz
	local target = item.CFrame
		+ Vector3.new(dx, Beach.groundAt(from.X + dx, toZ) - Beach.groundAt(from.X, from.Z), dz)
	local tween = TweenService:Create(
		item,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = target }
	)
	dragging[item] = tween
	-- Someone grabbing it mid-drag takes over.
	local stateChanged = item:GetAttributeChangedSignal("State"):Connect(function()
		tween:Cancel()
	end)
	tween.Completed:Connect(function()
		stateChanged:Disconnect()
		dragging[item] = nil
	end)
	tween:Play()
end

-- Wave n has slid back everywhere: drag what it reached.
function SurfService.afterWave(n: number)
	local sea = Tide.sea(n * cfg.Period + Waves.lifetime(n))
	for item in ItemService.all() do
		if ItemService.getState(item) ~= "Unclaimed" or dragging[item] then
			continue
		end
		local position = item.Position
		local line = Tide.waterlineAt(sea, position.X)
		local reach = Waves.reach(n, line, position.X)
		local rel = position.Z - line
		-- Not past something solid that stopped this wave's water.
		local front = Waves.frontAt(position.X, line, -reach)
		if rel < front then
			continue
		end
		if rel >= -reach and rel <= cfg.DragShallows then
			local size = reach / cfg.RunUp
			if rng:NextNumber() < math.min(1, cfg.DragChance * size) then
				drag(item, size)
			end
		end
	end
end

function SurfService.init()
	local nextWave = Waves.indexAt(Tide.now())
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = Tide.now()
			while nextWave * cfg.Period + Waves.lifetime(nextWave) <= now do
				SurfService.afterWave(nextWave)
				nextWave += 1
			end
		end
	end)
end

return SurfService
