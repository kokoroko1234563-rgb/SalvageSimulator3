-- The exotic accessories' key abilities, checked on the server (the client only asks):
--   Foghorn (G)           pulls free items near the player toward them.
--   Tidewalker Boots (R)  lets the player walk on the water for a few seconds; the walk is the
--                         player's WaterWalkUntil attribute (server time), which WaveController
--                         (stay on the surface) and DrowningService (no drowning) read.
-- Each is on a cooldown kept here, and needs the accessory worn (attuned). Rules: Accessories.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Accessories = require(Shared.Accessories)

local ItemService = require(script.Parent.ItemService)

local AccessoryService = {}

local FOLDER = "Remotes"
local lastUse: { [any]: { [string]: number } } = {}

-- Whether `ability` can be used now by `player`, and if so starts its cooldown. `spec` is the
-- worn accessory's ability table (Gear: Blast, WaterWalk).
local function begin(player, ability: string, spec, now: number): (boolean, string?)
	if not spec then
		return false, "You aren't wearing anything that does that."
	end
	local used = lastUse[player] or {}
	if not Accessories.ready(used[ability], now, spec.Cooldown) then
		return false, string.format("Recharging (%ds)", math.ceil(used[ability] + spec.Cooldown - now))
	end
	used[ability] = now
	lastUse[player] = used
	return true, nil
end

-- The Foghorn's blast from `origin`: pulls the free items among `items` toward it. Returns
-- whether it sounded, why not, and how many items it moved.
function AccessoryService.foghorn(player, origin: Vector3, items, now: number): (boolean, string?, number)
	local worn = Accessories.worn(player)
	local ok, reason = begin(player, "foghorn", worn and worn.Blast, now)
	if not ok then
		return false, reason, 0
	end
	local blast = (worn :: any).Blast
	local moves = Accessories.foghornPull(origin, items, blast.Range, blast.Pull)
	for _, move in moves do
		move.Item.Position = move.Position
	end
	return true, nil, #moves
end

-- Tidewalker Boots: starts a walk on the water.
function AccessoryService.waterWalk(player, now: number): (boolean, string?)
	local worn = Accessories.worn(player)
	local ok, reason = begin(player, "waterwalk", worn and worn.WaterWalk, now)
	if not ok then
		return false, reason
	end
	player:SetAttribute(Accessories.WalkAttribute, now + (worn :: any).WaterWalk.Duration)
	return true, nil
end

local function rootOf(player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return root
	end
	return nil
end

function AccessoryService.init()
	-- The remote: ("foghorn") | ("waterwalk"), client -> server. Answers with ("result", ability,
	-- ok, reason) so the client can say why it didn't work.
	local folder = ReplicatedStorage:WaitForChild(FOLDER)
	local remote = folder:FindFirstChild("Accessory")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "Accessory"
		remote.Parent = folder
	end
	remote.OnServerEvent:Connect(function(player, ability)
		local root = rootOf(player)
		if not root or type(ability) ~= "string" then
			return
		end
		local now = Workspace:GetServerTimeNow()
		if ability == "foghorn" then
			local ok, reason = AccessoryService.foghorn(player, root.Position, ItemService.list(), now)
			remote:FireClient(player, "result", ability, ok, reason)
		elseif ability == "waterwalk" then
			local ok, reason = AccessoryService.waterWalk(player, now)
			remote:FireClient(player, "result", ability, ok, reason)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

return AccessoryService
