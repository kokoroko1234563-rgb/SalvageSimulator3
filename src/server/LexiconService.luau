-- The lexicon and the tower man.
--   * The first time a player grabs an item type off the beach, it's recorded in their
--     lexicon forever (see GrabService).
--   * Each tide cycle, every zone has a tiny chance of a man appearing on top of a tall dirt
--     tower. Players with a complete lexicon can climb up and claim the Tall Top Hat from
--     him: untradeable, never lost, worn from the inventory.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Palette = require(Shared.Palette)
local Tide = require(Shared.Tide)

local DataService = require(script.Parent.DataService)

local LexiconService = {}

local HAT = "TallTopHat"
local TOWER_HEIGHT = 44

local folder: Folder
local rng = Random.new()
local notify: (Player, string) -> () = function(_player: Player, _text: string) end

local function makePart(parent: Instance, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = parent
	return part
end

local function claim(player: Player)
	if DataService.countItemType(player, HAT) > 0 then
		notify(player, '"You\'ve already got one, and it suits you."')
		return
	end
	if not DataService.lexiconComplete(player) then
		local profile = DataService.get(player)
		local found = 0
		for _, item in Items.Lexicon do
			if profile and profile.Lexicon[item.Id] then
				found += 1
			end
		end
		notify(
			player,
			string.format('"Come back when your lexicon is complete." (%d/%d found)', found, #Items.Lexicon)
		)
		return
	end
	DataService.addItem(player, HAT, "towerman")
	local profile = DataService.get(player)
	if profile then
		profile.EquippedCosmetic = HAT
		DataService.changed(player)
	end
	notify(player, "The man on the tower hands you a Tall Top Hat!")
end

-- A dirt tower with ledges spiralling up it, and the man waiting at the top.
function LexiconService.buildTower(parent: Instance, position: Vector3): Model
	local tower = Instance.new("Model")
	tower.Name = "TowerMan"
	local base = makePart(tower, {
		Name = "Tower",
		Size = Vector3.new(7, TOWER_HEIGHT, 7),
		CFrame = CFrame.new(position + Vector3.new(0, TOWER_HEIGHT / 2, 0)),
		Color = Palette.World.Dirt,
		Material = Palette.Material.Dirt,
	})
	tower.PrimaryPart = base
	local steps = 11
	for i = 1, steps do
		local angle = math.rad(i * 70)
		makePart(tower, {
			Name = "Ledge",
			Size = Vector3.new(3.5, 1, 3.5),
			CFrame = CFrame.new(
				position
					+ Vector3.new(math.cos(angle) * 5, i * (TOWER_HEIGHT / (steps + 1)), math.sin(angle) * 5)
			),
			Color = Palette.World.Dirt,
			Material = Palette.Material.Dirt,
		})
	end
	local top = position + Vector3.new(0, TOWER_HEIGHT, 0)
	local body = makePart(tower, {
		Name = "Man",
		Size = Vector3.new(2, 3, 1.2),
		CFrame = CFrame.new(top + Vector3.new(0, 1.5, 0)),
		Color = Palette.World.TraderCoat,
	})
	makePart(tower, {
		Name = "Head",
		Size = Vector3.new(1.4, 1.4, 1.4),
		CFrame = CFrame.new(top + Vector3.new(0, 3.7, 0)),
		Color = Palette.World.Skin,
	})
	makePart(tower, {
		Name = "Hat",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.6, 1.3, 1.3),
		CFrame = CFrame.new(top + Vector3.new(0, 5.7, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Palette.World.Hat,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = "The man on the tower"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(claim)
	tower.Parent = parent
	return tower
end

-- Puts a tower man somewhere in a zone (until the next tide cycle).
function LexiconService.spawnTowerMan(zone: number)
	local startZ, endZ = Beach.zoneRange(zone)
	local z = rng:NextNumber(startZ + 40, endZ - 40)
	local x = rng:NextNumber(-Beach.HalfWidth + 30, Beach.HalfWidth - 30)
	LexiconService.buildTower(folder, Vector3.new(x, Beach.groundAt(x, z), z))
	print(string.format("[Lexicon] the tower man appeared in zone %d", zone))
end

local function rollTowerMen()
	folder:ClearAllChildren()
	for zone = 1, Config.Beach.ActiveZones do
		if rng:NextNumber() < Config.Lexicon.TowerManChance then
			LexiconService.spawnTowerMan(zone)
		end
	end
end

function LexiconService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	folder = Instance.new("Folder")
	folder.Name = "TowerMen"
	folder.Parent = Workspace

	rollTowerMen()
	local lastCycle = Tide.getState().Cycle
	task.spawn(function()
		while true do
			task.wait(1)
			local cycle = Tide.getState().Cycle
			if cycle ~= lastCycle then
				lastCycle = cycle
				rollTowerMen()
			end
		end
	end)
end

return LexiconService
