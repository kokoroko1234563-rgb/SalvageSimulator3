-- Keeps things standing on the ground when a zone's ground changes shape (its biome rolled a
-- new layout and TerrainBuilder rebuilt it). Before the change, GroundShift.capture notes
-- every prop, loose item and player in the zone and the ground height under it; the function
-- it returns, called after the rebuild, moves each one up or down by however much the ground
-- under it moved. Props are the Models and parts in Workspace.Map (each Model moves as one).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)

local GroundShift = {}

-- Map folders whose contents never move with the ground (they stand at fixed heights).
local SKIP = { Shop = true, RockPools = true }

type Record = { target: Instance, x: number, z: number, before: number, player: boolean? }

function GroundShift.capture(zone: number): () -> ()
	local z0, z1 = Beach.zoneRange(zone)
	local records: { Record } = {}
	local function note(target: Instance, position: Vector3, isPlayer: boolean?)
		if position.Z >= z0 and position.Z <= z1 then
			table.insert(records, {
				target = target,
				x = position.X,
				z = position.Z,
				before = Beach.groundAt(position.X, position.Z),
				player = isPlayer,
			})
		end
	end
	local function visit(container: Instance)
		for _, child in container:GetChildren() do
			if child:IsA("Folder") then
				if not SKIP[child.Name] then
					visit(child)
				end
			elseif child:IsA("Model") then
				note(child, child:GetPivot().Position)
			elseif child:IsA("BasePart") then
				note(child, child.Position)
			end
		end
	end
	local map = Workspace:FindFirstChild("Map")
	if map then
		visit(map)
	end
	for _, item in CollectionService:GetTagged("SalvageItem") do
		if item:IsA("BasePart") and item.Anchored and item:GetAttribute("State") == "Unclaimed" then
			note(item, item.Position)
		end
	end
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			note(root, root.Position, true)
		end
	end

	return function()
		for _, record in records do
			local target = record.target
			if not target.Parent then
				continue
			end
			local delta = Beach.groundAt(record.x, record.z) - record.before
			if record.player then
				-- Only ever lift a player (so the new ground doesn't swallow them).
				if delta > 0.05 then
					local root = target :: BasePart
					root.CFrame += Vector3.new(0, delta + 0.5, 0)
				end
			elseif math.abs(delta) > 0.05 then
				if target:IsA("Model") then
					target:PivotTo(target:GetPivot() + Vector3.new(0, delta, 0))
				elseif target:IsA("BasePart") then
					target.CFrame += Vector3.new(0, delta, 0)
				end
			end
		end
	end
end

return GroundShift
