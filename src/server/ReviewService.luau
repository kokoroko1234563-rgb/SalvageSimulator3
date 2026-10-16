-- The review place (Config.Review; nothing here runs anywhere else). Admins appraise the
-- layouts by playing them:
--   - step through the variations where they stand: the zone's crossings, the nearest slot's
--     rooms, a reroll, the biome;
--   - leave notes (text, tags, a 1-5 rating) pinned where they stand, with everything about
--     the spot (zone, biome, crossing, slot and room, position, view, tide);
--   - their time across each zone is logged with the variation it was on (the client times
--     it), and so is the path they walk, every few seconds.
-- Notes and times go to a DataStore ("notes", one list), paths to "trail/<user>/<start>".
-- tools/review/review.py reads and resolves them. Open notes show as pins in the world.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Layouts = require(Shared.Layouts)
local Remotes = require(Shared.Remotes)
local Review = require(Shared.Review)
local Tide = require(Shared.Tide)

local AdminService = require(script.Parent.AdminService)
local BiomeService = require(script.Parent.BiomeService)

local cfg = Config.Review

local ReviewService = {}

local store: DataStore? = nil
local pins: Folder

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function pin(note)
	if note.Resolved or note.Kind ~= "note" or not note.World then
		return
	end
	local ball = Instance.new("Part")
	ball.Name = "Note" .. note.Id
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1.2, 1.2, 1.2)
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 200, 60)
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.Position = Vector3.new(note.World[1], note.World[2] + 3, note.World[3])
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 60)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
	label.TextColor3 = Color3.fromRGB(255, 230, 170)
	label.TextWrapped = true
	label.TextScaled = true
	label.Font = Enum.Font.GothamMedium
	local tags = if note.Tags and #note.Tags > 0 then " [" .. table.concat(note.Tags, ", ") .. "]" else ""
	label.Text = "#" .. note.Id .. tags .. " " .. (note.Text or "")
	label.Parent = gui
	gui.Parent = ball
	ball.Parent = pins
end

-- Appends a record to the notes list; returns its id.
local function save(record): (boolean, string)
	if not store then
		return false, "No DataStore here"
	end
	local id
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync("notes", function(list)
			list = list or {}
			id = #list + 1
			record.Id = id
			table.insert(list, record)
			return list
		end)
	end)
	if not ok then
		return false, "Couldn't save: " .. tostring(err)
	end
	return true, tostring(id)
end

-- Everything about where a player stands, for a record.
local function describe(player: Player, look: Vector3?)
	local root = rootOf(player)
	if not root then
		return nil
	end
	local where = Review.where(root.Position)
	return {
		Time = os.time(),
		User = player.Name,
		Zone = where.Zone,
		Biome = where.Biome,
		Layout = where.Layout,
		Choice = where.Choice,
		Crossing = where.CrossingName,
		Slot = where.SlotName,
		Room = where.RoomName,
		X = math.floor(where.X + 0.5),
		Z = math.floor(where.Z + 0.5),
		World = { math.floor(root.Position.X), math.floor(root.Position.Y), math.floor(root.Position.Z) },
		Look = if look then { math.floor(look.X * 100) / 100, math.floor(look.Z * 100) / 100 } else nil,
		Waterline = math.floor(Tide.waterlineAt(Tide.sea(), root.Position.X)),
	}
end

-- The zone (tile) a player is in, its biome id and its current choice.
local function zoneOf(player: Player): (number?, string?, any)
	local root = rootOf(player)
	local tile = root and Beach.tileAt(root.Position.Z)
	if not tile then
		return nil
	end
	local biome = Biomes.activeIn(tile)
	return tile, biome and biome.Id, Layouts.activeChoice(tile)
end

local actions = {}

-- Step the zone's crossing by `arg` (+1 or -1).
function actions.crossing(player: Player, arg)
	local tile, biomeId, choice = zoneOf(player)
	if not tile or not choice then
		return false, "Stand in a zone first"
	end
	local crossings = Layouts.shape(Layouts.activeDef(tile))
	choice.Crossing = (choice.Crossing - 1 + (tonumber(arg) or 1)) % crossings + 1
	BiomeService.set(tile, biomeId, choice)
	return true, "Crossing " .. choice.Crossing .. " of " .. crossings
end

-- Step the nearest slot's room.
function actions.room(player: Player)
	local tile, biomeId, choice = zoneOf(player)
	local root = rootOf(player)
	if not tile or not choice or not root then
		return false, "Stand in a zone first"
	end
	local slot = Review.nearestSlot(tile, root.Position)
	if not slot then
		return false, "This zone has no rooms"
	end
	local _, rooms = Layouts.shape(Layouts.activeDef(tile))
	choice.Rooms[slot] = (choice.Rooms[slot] or 1) % rooms[slot] + 1
	BiomeService.set(tile, biomeId, choice)
	return true, "Slot " .. slot .. ": room " .. choice.Rooms[slot] .. " of " .. rooms[slot]
end

-- Roll the zone's crossing and rooms again.
function actions.reroll(player: Player)
	local tile, biomeId = zoneOf(player)
	if not tile then
		return false, "Stand in a zone first"
	end
	BiomeService.set(tile, biomeId)
	return true, "Rerolled"
end

-- Step the zone's biome: none, then each biome that can roll in this zone.
function actions.biome(player: Player)
	local tile, biomeId = zoneOf(player)
	if not tile then
		return false, "Stand in a zone first"
	end
	local options = { "" }
	for id in BiomeService.weightsFor(tile) do
		if id ~= "None" then
			table.insert(options, id)
		end
	end
	table.sort(options)
	local index = table.find(options, biomeId or "") or 1
	local nextId = options[index % #options + 1]
	BiomeService.set(tile, if nextId ~= "" then nextId else nil)
	return true, if nextId ~= "" then Biomes.List[nextId].Name else "No biome"
end

-- Back to the zone's top edge, where you are along it.
function actions.top(player: Player)
	local root = rootOf(player)
	local tile = root and Beach.tileAt(root.Position.Z)
	if not root or not tile then
		return false, "Stand in a zone first"
	end
	local z = Beach.tileRange(tile) + 3
	local x = root.Position.X
	root.CFrame = CFrame.new(x, Beach.groundAt(x, z) + 4, z)
	return true, "At the top of zone " .. tile
end

-- A note pinned where the player stands: { Text, Tags, Rating, Look }.
function actions.note(player: Player, arg)
	if type(arg) ~= "table" then
		return false, "Bad note"
	end
	local look = if typeof(arg.Look) == "Vector3" then arg.Look else nil
	local record = describe(player, look)
	if not record then
		return false, "No character"
	end
	record.Kind = "note"
	record.Text = string.sub(tostring(arg.Text or ""), 1, 500)
	record.Tags = {}
	for _, tag in (if type(arg.Tags) == "table" then arg.Tags else {}) do
		if table.find(cfg.Tags, tag) then
			table.insert(record.Tags, tag)
		end
	end
	local rating = tonumber(arg.Rating)
	record.Rating = if rating and rating >= 1 and rating <= 5 then math.floor(rating) else nil
	record.Resolved = false
	local ok, id = save(record)
	if ok then
		pin(record)
		return true, "Saved note #" .. id
	end
	return false, id
end

-- A timed crossing of a zone, measured by the client: { Zone, Seconds }.
function actions.time(player: Player, arg)
	if type(arg) ~= "table" or type(arg.Seconds) ~= "number" then
		return false, "Bad time"
	end
	local record = describe(player)
	if not record then
		return false, "No character"
	end
	record.Kind = "time"
	record.Zone = tonumber(arg.Zone) or record.Zone
	record.Seconds = math.floor(arg.Seconds * 10) / 10
	-- The variation is the one of the zone just crossed (the player is now past it).
	local tile = record.Zone
	if tile then
		local def = Layouts.activeDef(tile)
		local choice = Layouts.activeChoice(tile)
		record.Layout = def and def.Name
		record.Choice = choice and Layouts.encode(choice)
		local crossing = def and choice and def.Crossings and def.Crossings[choice.Crossing]
		record.Crossing = crossing and crossing.Name
		record.Target = Config.Zones[tile] and Config.Zones[tile].CrossTime
	end
	record.Slot, record.Room = nil, nil
	return save(record)
end

-- Logs where each reviewing admin walks, every few seconds, saved when they leave (and every
-- few minutes).
local function trackTrails()
	local trails: { [Player]: { started: number, points: { any } } } = {}
	local function flush(player: Player)
		local trail = trails[player]
		if not trail or #trail.points == 0 or not store then
			return
		end
		local key = "trail/" .. player.UserId .. "/" .. trail.started
		local points = trail.points
		pcall(function()
			(store :: DataStore):SetAsync(key, points)
		end)
	end
	task.spawn(function()
		local sinceFlush = 0
		while true do
			task.wait(cfg.TrailEvery)
			sinceFlush += cfg.TrailEvery
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				if root and AdminService.isAdmin(player) and Beach.tileAt(root.Position.Z) then
					local trail = trails[player]
					if not trail then
						trail = { started = os.time(), points = {} }
						trails[player] = trail
					end
					local where = Review.where(root.Position)
					table.insert(trail.points, {
						os.time() - trail.started,
						where.Zone,
						where.Choice,
						math.floor(root.Position.X),
						math.floor(where.Z),
					})
				end
			end
			if sinceFlush >= 120 then
				sinceFlush = 0
				for player in trails do
					flush(player)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		flush(player)
		trails[player] = nil
	end)
end

function ReviewService.init()
	if not Review.enabled() then
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(cfg.DataStore)
	end)
	store = if ok then result else nil
	pins = Instance.new("Folder")
	pins.Name = "ReviewPins"
	pins.Parent = Workspace
	task.spawn(function()
		if store then
			local loaded, notes = pcall(function()
				return (store :: DataStore):GetAsync("notes")
			end)
			for _, note in (if loaded and notes then notes else {}) do
				pin(note)
			end
		end
	end)
	Remotes.get("Review").OnServerInvoke = function(player: Player, action: string, arg)
		if not AdminService.isAdmin(player) then
			return false, "Admins only"
		end
		local handler = actions[action]
		if not handler then
			return false, "Unknown action"
		end
		return handler(player, arg)
	end
	trackTrails()
end

return ReviewService
