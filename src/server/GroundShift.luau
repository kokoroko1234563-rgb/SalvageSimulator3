-- Keeps the map's scenery and everything on the ground right when the ground changes shape.
--
-- Scenery only stands on level ground: a prop whose footprint would straddle a wall's edge,
-- the side of a bank or lie under a roof is put away (into ServerStorage), and comes back if
-- the ground under it opens up again. The map's scenery was placed for open sand; the layouts
-- add walls and caves.
-- GroundShift.tidy goes over the whole map once it's built.
--
-- When a tile's ground changes shape (its biome rolled a new layout and TerrainBuilder rebuilt
-- it), GroundShift.capture notes every prop (and put-away prop), loose item and player on the
-- tile and the ground height under it; the function it returns, called after the rebuild, moves
-- each one up or down by however much the ground under it moved, then puts away or brings back
-- props as the new ground allows. Props are the Models and parts in Workspace.Map (each Model
-- moves as one).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)

local GroundShift = {}

-- Map folders whose contents never move with the ground (they stand at fixed heights) or aren't
-- scenery on the beach.
local SKIP = { Shop = true, RockPools = true, MapEdge = true, BiomeShowcase = true }

local LEVEL = 0.5 -- studs a prop's footprint may rise or fall from its middle and still stand
local MARGIN = 6 -- studs past a prop's footprint that are checked too (a terrain cell, and the
-- couple of studs the terrain sags by at the foot of a rock face)

type Record = { target: Instance, x: number, z: number, before: number, player: boolean? }

-- Props put away, and the folder each goes back into.
local away: { [Instance]: Instance } = {}

local function awayFolder(): Folder
	local folder = ServerStorage:FindFirstChild("SceneryAway")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SceneryAway"
		folder.Parent = ServerStorage
	end
	return folder :: Folder
end

-- Whether a prop stands on open ground: nothing overhead, and its footprint level with its
-- middle (not across a wall, a bank's side or a cut). The footprint is checked a little wider
-- than the prop (the terrain rounds shapes' edges off over that much), and for a Model, under
-- each of its parts too (scattered pieces can lie far from its corners).
function GroundShift.fits(target: Instance): boolean
	local cframe, size
	if target:IsA("Model") then
		cframe, size = target:GetBoundingBox()
	elseif target:IsA("BasePart") then
		cframe, size = target.CFrame, target.Size
	else
		return true
	end
	local middle = cframe.Position
	if middle.Z < 0 or not Beach.tileAt(middle.Z) then
		return true -- the shop and the sandbar have no layouts
	end
	local level = Beach.feature(middle.X, middle.Z)
	local points = { middle }
	local function corners(frame: CFrame, extent: Vector3)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = frame * Vector3.new(sx * extent.X / 2, -extent.Y / 2, sz * extent.Z / 2)
				local out = Vector3.new(corner.X - frame.Position.X, 0, corner.Z - frame.Position.Z)
				if out.Magnitude > 0.01 then
					corner += out.Unit * MARGIN
				end
				table.insert(points, corner)
			end
		end
	end
	corners(cframe, size)
	if target:IsA("Model") then
		for _, part in target:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(points, part.CFrame.Position)
			end
		end
	end
	for _, point in points do
		if Beach.roofAt(point.X, point.Z) then
			return false
		end
		if math.abs(Beach.feature(point.X, point.Z) - level) > LEVEL then
			return false
		end
	end
	return true
end

-- The props (Models and visible parts) in the map's scenery folders.
local function eachProp(container: Instance, fn: (Instance, Vector3) -> ())
	for _, child in container:GetChildren() do
		if child:IsA("Folder") then
			if not SKIP[child.Name] then
				eachProp(child, fn)
			end
		elseif child:IsA("Model") then
			fn(child, child:GetPivot().Position)
		elseif child:IsA("BasePart") and child.Transparency < 1 then
			fn(child, child.CFrame.Position)
		end
	end
end

local function putAway(target: Instance)
	away[target] = target.Parent :: Instance
	target.Parent = awayFolder()
end

local function bringBack(target: Instance)
	local parent = away[target]
	away[target] = nil
	if parent and parent.Parent then
		target.Parent = parent
	else
		target:Destroy()
	end
end

-- Puts away every prop in the map that doesn't stand on open ground (once it's built).
function GroundShift.tidy(map: Instance)
	local tidied = 0
	eachProp(map, function(target)
		if not GroundShift.fits(target) then
			putAway(target)
			tidied += 1
		end
	end)
	return tidied
end

-- Destroys the props in a folder that don't stand on open ground (a biome's decor, just built).
function GroundShift.clearMisfits(folder: Instance)
	eachProp(folder, function(target)
		if not GroundShift.fits(target) then
			target:Destroy()
		end
	end)
end

local function moveBy(target: Instance, delta: number)
	if math.abs(delta) <= 0.05 then
		return
	end
	if target:IsA("Model") then
		target:PivotTo(target:GetPivot() + Vector3.new(0, delta, 0))
	elseif target:IsA("BasePart") then
		target.CFrame += Vector3.new(0, delta, 0)
	end
end

function GroundShift.capture(tile: number): () -> ()
	local z0, z1 = Beach.tileRange(tile)
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
	local map = Workspace:FindFirstChild("Map")
	if map then
		eachProp(map, note)
	end
	-- Props put away on this tile might fit again.
	for target in away do
		local position = if target:IsA("Model")
			then target:GetPivot().Position
			else (target :: BasePart).CFrame.Position
		note(target, position)
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
				continue
			end
			moveBy(target, delta)
			if CollectionService:HasTag(target, "SalvageItem") then
				continue
			end
			local fits = GroundShift.fits(target)
			if away[target] and fits then
				bringBack(target)
			elseif not away[target] and not fits then
				putAway(target)
			end
		end
	end
end

-- For tools/tests.
function GroundShift._away(): { [Instance]: Instance }
	return away
end

return GroundShift
