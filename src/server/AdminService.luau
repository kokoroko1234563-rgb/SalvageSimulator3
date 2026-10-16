-- Admin console commands. Every command runs on the server after an admin check, so a
-- client can't use the remote to cheat. Type `help` in the console (F2) for the list.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Biomes = require(Shared.Biomes)
local Catalog = require(Shared.Catalog)
local Rebirth = require(Shared.Rebirth)
local Secrets = require(Shared.Secrets)
local Traders = require(Shared.Traders)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Layouts = require(Shared.Layouts)
local Remotes = require(Shared.Remotes)
local Tide = require(Shared.Tide)
local DayCycle = require(Shared.DayCycle)
local Waves = require(Shared.Waves)

local AuctionService = require(script.Parent.AuctionService)
local BiomeService = require(script.Parent.BiomeService)
local DataService = require(script.Parent.DataService)
local LexiconService = require(script.Parent.LexiconService)
local Showroom = require(script.Parent.Showroom)
local MonetizationService = require(script.Parent.MonetizationService)
local TraderService = require(script.Parent.TraderService)
local RebirthService = require(script.Parent.RebirthService)
local ItemService = require(script.Parent.ItemService)
local VesselService = require(script.Parent.VesselService)

local AdminService = {}

local admins: { [Player]: boolean } = {}
local rng = Random.new()

local function checkAdmin(player: Player): boolean
	local cfg = Config.Admins
	if cfg.AllowStudio and RunService:IsStudio() then
		return true
	end
	if table.find(cfg.UserIds, player.UserId) then
		return true
	end
	if cfg.AllowOwner then
		if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
			return true
		end
		if game.CreatorType == Enum.CreatorType.Group then
			local ok, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
			if ok and rank >= cfg.OwnerGroupMinRank then
				return true
			end
		end
	end
	return false
end

function AdminService.isAdmin(player: Player): boolean
	return admins[player] == true
end

-- Helpers ---------------------------------------------------------------------------

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- "me", "all", "others", or the start of a username / display name.
local function findPlayers(caller: Player, query: string?): ({ Player }, string?)
	if not query or query == "" or query == "me" then
		return { caller }
	end
	query = query:lower()
	if query == "all" then
		return Players:GetPlayers()
	end
	if query == "others" then
		local result = {}
		for _, player in Players:GetPlayers() do
			if player ~= caller then
				table.insert(result, player)
			end
		end
		return result
	end
	local matches = {}
	for _, player in Players:GetPlayers() do
		if
			player.Name:lower():sub(1, #query) == query
			or player.DisplayName:lower():sub(1, #query) == query
		then
			table.insert(matches, player)
		end
	end
	if #matches == 0 then
		return {}, "No player matches '" .. query .. "'"
	end
	if #matches > 1 then
		return {}, "More than one player matches '" .. query .. "'"
	end
	return matches
end

local function names(players: { Player }): string
	local list = {}
	for _, player in players do
		table.insert(list, player.Name)
	end
	return table.concat(list, ", ")
end

local function normalize(text: string): string
	return (text:lower():gsub("[%s%-_'+]", ""))
end

local function findGear(query: string): (string?, any)
	local key = normalize(query)
	for _, tool in Gear.Tools do
		if normalize(tool.Id) == key or normalize(tool.Name) == key then
			return "Tool", tool
		end
	end
	for _, vessel in Gear.Vessels do
		if normalize(vessel.Id) == key or normalize(vessel.Name) == key then
			return "Vessel", vessel
		end
	end
	return nil, nil
end

local function findItems(query: string): { any }
	local key = normalize(query)
	for _, rarity in Items.Rarities do
		if normalize(rarity) == key then
			return Items.ofRarity(rarity)
		end
	end
	for _, def in Items.Catalog do
		if normalize(def.Id) == key or normalize(def.Name) == key then
			return { def }
		end
	end
	return {}
end

-- Commands --------------------------------------------------------------------------

type Command = {
	usage: string,
	description: string,
	run: (caller: Player, args: { string }) -> { string },
}

local commands: { [string]: Command } = {}
local order: { string } = {}

local function command(
	name: string,
	usage: string,
	description: string,
	run: (Player, { string }) -> { string }
)
	commands[name] = { usage = usage, description = description, run = run }
	table.insert(order, name)
end

local function eachTarget(caller: Player, query: string?, fn: (Player) -> ()): { string }?
	local targets, err = findPlayers(caller, query)
	if err then
		return { "Error: " .. err }
	end
	for _, target in targets do
		fn(target)
	end
	return nil
end

command("help", "help", "List commands", function()
	local lines = { "Players: me (default), all, others, or the start of a name." }
	for _, name in order do
		local c = commands[name]
		table.insert(lines, string.format("%s  —  %s", c.usage, c.description))
	end
	return lines
end)

command("status", "status", "Tide, item and player summary", function()
	local state = Tide.getState()
	local counts = { Unclaimed = 0, Held = 0, Loose = 0, InVessel = 0 }
	for item in ItemService.all() do
		local s = ItemService.getState(item)
		counts[s] = (counts[s] or 0) + 1
	end
	return {
		string.format(
			"Tide: %s %.0f%% (%.0fs left), waterline z=%.0f, cycle %.0fs, time scale %.2f",
			state.Phase,
			state.PhaseProgress * 100,
			state.PhaseRemaining,
			state.Waterline,
			Tide.cycleLength(),
			Workspace:GetAttribute(Tide.ScaleAttribute) or Config.Tide.TimeScale
		),
		string.format(
			"Items: %d unclaimed, %d held, %d loose, %d in vessels",
			counts.Unclaimed,
			counts.Held,
			counts.Loose,
			counts.InVessel
		),
		string.format("Wave strength: x%.2f", Workspace:GetAttribute(Waves.ScaleAttribute) or 1),
		string.format("Players (%d): %s", #Players:GetPlayers(), names(Players:GetPlayers())),
	}
end)

command("coins", "coins <amount> [player]", "Set coins", function(caller, args)
	local amount = tonumber(args[1])
	if not amount then
		return { "Usage: coins <amount> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		DataService.setCoins(target, amount)
		table.insert(lines, target.Name .. " now has " .. math.floor(amount) .. " coins")
	end) or lines
end)

command("addcoins", "addcoins <amount> [player]", "Add (or remove) coins", function(caller, args)
	local amount = tonumber(args[1])
	if not amount then
		return { "Usage: addcoins <amount> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		DataService.addCoins(target, amount)
		table.insert(lines, string.format("%s: %+d coins", target.Name, math.floor(amount)))
	end) or lines
end)

-- Any inventory item by id or name: tools, vessels, accessories, unlock and exotic items.
local function findCatalog(query: string)
	local key = normalize(query)
	for id, entry in Catalog.all() do
		if normalize(id) == key or normalize(entry.Name) == key then
			return entry
		end
	end
	return nil
end

command(
	"give",
	"give <item> [player] [variant]",
	"Give any inventory item, e.g. give boathook, give anchorhook me Barnacled",
	function(caller, args)
		if not args[1] then
			return { "Usage: give <item> [player] [variant]" }
		end
		local entry = findCatalog(args[1])
		if not entry then
			return { "Unknown item '" .. args[1] .. "'" }
		end
		local variant = args[3]
		local lines = {}
		return eachTarget(caller, args[2], function(target)
			-- Shop gear is one per player; everything else can stack up copies.
			if entry.ShopItem and DataService.countItemType(target, entry.Id) > 0 then
				table.insert(lines, target.Name .. " already owns " .. entry.Name)
			else
				DataService.addItem(target, entry.Id, "admin", if variant then { Variant = variant } else nil)
				table.insert(
					lines,
					"Gave " .. (if variant then variant .. " " else "") .. entry.Name .. " to " .. target.Name
				)
			end
		end) or lines
	end
)

command("cores", "cores <n> [player]", "Set attunement cores", function(caller, args)
	local n = tonumber(args[1])
	if not n then
		return { "Usage: cores <n> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		local profile = DataService.get(target)
		if profile then
			profile.Cores = math.max(0, math.floor(n))
			DataService.changed(target)
			table.insert(lines, string.format("%s: %d cores", target.Name, profile.Cores))
		end
	end) or lines
end)

command(
	"attune",
	"attune <item|all|none> [player]",
	"Attune to exotic item types (no core needed)",
	function(caller, args)
		local choice = (args[1] or ""):lower()
		local ids = {}
		if choice == "all" or choice == "none" then
			for id, entry in Catalog.all() do
				if entry.Exotic then
					table.insert(ids, id)
				end
			end
		else
			local entry = findCatalog(choice)
			if not entry or not entry.Exotic then
				return { "Usage: attune <exotic item|all|none> [player]" }
			end
			ids = { entry.Id }
		end
		local lines = {}
		return eachTarget(caller, args[2], function(target)
			local profile = DataService.get(target)
			if profile then
				for _, id in ids do
					profile.Attunements[id] = if choice == "none" then nil else true
				end
				DataService.changed(target)
				table.insert(lines, target.Name .. ": attunements updated")
			end
		end) or lines
	end
)

command(
	"truerebirth",
	"truerebirth [player]",
	"True rebirth for free (no coins needed): resets and gives a core",
	function(caller, args)
		local lines = {}
		return eachTarget(caller, args[1], function(target)
			local ok, reason = RebirthService.trueRebirth(target, true)
			table.insert(lines, target.Name .. ": " .. (if ok then "true rebirth done" else tostring(reason)))
		end) or lines
	end
)

command("vessel", "vessel <vessel> [player]", "Spawn a vessel next to the player", function(caller, args)
	local kind, entry = findGear(args[1] or "")
	if kind ~= "Vessel" then
		return { "Usage: vessel <wheelbarrow|beachwagon> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		local ok, reason = VesselService.spawn(target, entry.Id)
		table.insert(
			lines,
			if ok then "Spawned " .. entry.Name .. " for " .. target.Name else "Failed: " .. tostring(reason)
		)
	end) or lines
end)

command(
	"spawn",
	"spawn <item or rarity> [count]",
	"Spawn unclaimed items in front of you",
	function(caller, args)
		local defs = findItems(args[1] or "")
		if #defs == 0 then
			return { "Unknown item or rarity. Try: spawn rare 5, spawn anchor" }
		end
		local count = math.clamp(math.floor(tonumber(args[2]) or 1), 1, 50)
		local root = rootOf(caller)
		if not root then
			return { "You need a character" }
		end
		local look = root.CFrame.LookVector
		local forward = Vector3.new(look.X, 0, look.Z).Unit
		local zone = math.clamp(Beach.zoneAt(root.Position.Z) or 1, 1, Config.Beach.ActiveZones)
		for i = 1, count do
			local def = defs[rng:NextInteger(1, #defs)]
			local spot = root.Position
				+ forward * (6 + i * 0.5)
				+ Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
			local groundY = if spot.Z < 0 then 1 else Beach.groundAt(spot.X, spot.Z)
			ItemService.spawnAt(def, zone, Vector3.new(spot.X, groundY + def.Size.Y / 2, spot.Z))
		end
		return { string.format("Spawned %d item(s) with zone %d value", count, zone) }
	end
)

command(
	"clearitems",
	"clearitems [all]",
	"Remove unclaimed items (or every item with 'all')",
	function(_, args)
		local everything = args[1] == "all"
		local removed = 0
		for item in ItemService.all() do
			if everything or ItemService.getState(item) == "Unclaimed" then
				ItemService.destroy(item)
				removed += 1
			end
		end
		return { "Removed " .. removed .. " item(s)" }
	end
)

command("tide", "tide <out|hold|in> [percent]", "Jump the tide, e.g. tide in 90", function(_, args)
	local phases = { out = "Out", hold = "Hold", ["in"] = "In" }
	local phase = phases[(args[1] or ""):lower()]
	if not phase then
		return { "Usage: tide <out|hold|in> [percent]" }
	end
	local progress = math.clamp((tonumber(args[2]) or 0) / 100, 0, 0.999)
	Workspace:SetAttribute(Tide.StartAttribute, Tide.startFor(phase, progress))
	local state = Tide.getState()
	return {
		string.format(
			"Tide set to %s %.0f%%, waterline z=%.0f",
			state.Phase,
			state.PhaseProgress * 100,
			state.Waterline
		),
	}
end)

command("tidespeed", "tidespeed <scale>", "Tide time scale: 1 = real 25 min, 0.1 = 2.5 min", function(_, args)
	local scale = tonumber(args[1])
	if not scale or scale <= 0 then
		return {
			"Usage: tidespeed <scale>  (current "
				.. (Workspace:GetAttribute(Tide.ScaleAttribute) or Config.Tide.TimeScale)
				.. ")",
		}
	end
	-- Keep the tide where it is while changing how fast it moves.
	local state = Tide.getState()
	Workspace:SetAttribute(Tide.ScaleAttribute, scale)
	Workspace:SetAttribute(Tide.StartAttribute, Tide.startFor(state.Phase, state.PhaseProgress))
	return { string.format("Tide time scale %.2f, full cycle %.0fs", scale, Tide.cycleLength()) }
end)

command(
	"waves",
	"waves <multiplier|rogue|seed [n]>",
	"Wave strength (1 = normal, 0 = calm), send a rogue wave, or change the sea's random seed",
	function(_, args)
		if (args[1] or ""):lower() == "seed" then
			-- A new pattern for the waterline and the waves (random unless a number is given).
			local seed = tonumber(args[2]) or Random.new():NextInteger(1, 999999)
			Workspace:SetAttribute(Tide.SeedAttribute, math.floor(seed))
			return { "Sea seed " .. math.floor(seed) }
		end
		if (args[1] or ""):lower() == "rogue" then
			-- The wave after the one already rolling in (clients get a few seconds' warning).
			local index = Waves.indexAt(Tide.now()) + 1
			Workspace:SetAttribute(Waves.RogueAttribute, index)
			return { string.format("Wave %d will be a rogue wave", index) }
		end
		local scale = tonumber(args[1])
		if not scale or scale < 0 then
			return { "Usage: waves <multiplier|rogue|seed [n]>" }
		end
		Workspace:SetAttribute(Waves.ScaleAttribute, scale)
		return { string.format("Wave strength x%.2f", scale) }
	end
)

command(
	"tp",
	"tp <shop|zone number|sandbar|showroom|player> [who]",
	"Teleport, e.g. tp 3, tp shop, tp sandbar (the bell tower door), tp bob",
	function(caller, args)
		local where = (args[1] or ""):lower()
		local destination: Vector3?
		if where == "shop" then
			destination = Vector3.new(0, 5, -45)
		elseif where == "showroom" then
			destination = Showroom.Entrance
		elseif where == "sandbar" or where == "tower" then
			local z = Config.Beach.FarSandbar.DoorZ - 6
			destination = Vector3.new(0, Beach.groundAt(0, z) + 4, z)
		elseif tonumber(where) then
			local zone = math.clamp(math.floor(tonumber(where) :: number), 1, Config.Beach.ActiveZones)
			local startZ = Beach.zoneRange(zone)
			local z = startZ + 10
			destination = Vector3.new(0, Beach.groundAt(0, z) + 4, z)
		elseif where ~= "" then
			local targets, err = findPlayers(caller, where)
			local root = targets[1] and rootOf(targets[1])
			if err or not root then
				return { "Error: " .. (err or "that player has no character") }
			end
			destination = root.Position + Vector3.new(0, 0, -4)
		end
		if not destination then
			return { "Usage: tp <shop|zone number|sandbar|showroom|player> [who]" }
		end
		local lines = {}
		return eachTarget(caller, args[2], function(target)
			local character = target.Character
			if character then
				character:PivotTo(CFrame.new(destination :: Vector3))
				table.insert(lines, "Teleported " .. target.Name)
			end
		end) or lines
	end
)

command("showroom", "showroom [section]", "Go to the showroom, or one of its sections", function(caller, args)
	local name = table.concat(args, " "):lower()
	local character = caller.Character
	if not character then
		return { "You have no character" }
	end
	local spot = if name == "" then Showroom.Entrance else Showroom.Sections[name]
	if not spot then
		-- Not a full name: take the first section that starts with it.
		for section, position in Showroom.Sections do
			if section:sub(1, #name) == name then
				spot = position
				break
			end
		end
	end
	if not spot then
		local sections = {}
		for section in Showroom.Sections do
			table.insert(sections, section)
		end
		table.sort(sections)
		return { "Sections: " .. table.concat(sections, ", ") }
	end
	character:PivotTo(CFrame.new(spot))
	return { "Teleported to the showroom" }
end)

command("time", "time [hour]", "Show the time of day, or set it, e.g. time 19.5 for dusk", function(_, args)
	local hour = tonumber(args[1])
	if hour then
		Workspace:SetAttribute(
			DayCycle.StartAttribute,
			DayCycle.startFor(hour % 24, Workspace:GetServerTimeNow())
		)
	end
	local now = DayCycle.hour()
	return {
		string.format(
			"It's %02d:%02d (%s), a day lasts %ds",
			math.floor(now),
			math.floor((now % 1) * 60),
			DayCycle.period(now),
			Config.Day.Length
		),
	}
end)

command("heal", "heal [player]", "Full health and breath", function(caller, args)
	local lines = {}
	return eachTarget(caller, args[1], function(target)
		local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
		target:SetAttribute("Breath", 1)
		table.insert(lines, "Healed " .. target.Name)
	end) or lines
end)

command("god", "god [player]", "Toggle no-drowning", function(caller, args)
	local lines = {}
	return eachTarget(caller, args[1], function(target)
		local on = not target:GetAttribute("AdminGod")
		target:SetAttribute("AdminGod", on)
		table.insert(lines, target.Name .. ": no-drowning " .. (if on then "ON" else "OFF"))
	end) or lines
end)

command("speed", "speed <walkspeed> [player]", "Set walk speed (default 16)", function(caller, args)
	local speed = tonumber(args[1])
	if not speed then
		return { "Usage: speed <walkspeed> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = math.clamp(speed, 0, 200)
			humanoid:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
			table.insert(lines, target.Name .. " walk speed " .. humanoid.WalkSpeed)
		end
	end) or lines
end)

command("resetdata", "resetdata <player>", "Wipe a player's coins and gear", function(caller, args)
	if not args[1] then
		return { "Usage: resetdata <player>  (use 'me' for yourself)" }
	end
	local lines = {}
	return eachTarget(caller, args[1], function(target)
		DataService.reset(target)
		table.insert(lines, "Reset " .. target.Name .. "'s save")
	end) or lines
end)

command("kick", "kick <player> [reason]", "Kick a player", function(caller, args)
	if not args[1] or args[1] == "me" then
		return { "Usage: kick <player> [reason]" }
	end
	local reason = table.concat(args, " ", 2)
	local lines = {}
	return eachTarget(caller, args[1], function(target)
		if target ~= caller then
			target:Kick(if reason ~= "" then reason else "Kicked by an admin")
			table.insert(lines, "Kicked " .. target.Name)
		end
	end) or lines
end)

command(
	"biomes",
	"biomes",
	"Show each zone's biome, crossing and rooms, and the biomes that exist",
	function()
		local lines = {}
		for zone = 1, Beach.ActiveTiles do
			local biome = Biomes.activeIn(zone)
			local def = Layouts.activeDef(zone)
			local crossings, slots = if def then Layouts.shape(def) else 1, {}
			table.insert(
				lines,
				string.format(
					"Zone %d: %s, layout %s (%d crossings, %d room slots)",
					zone,
					if biome then biome.Name else "no biome",
					Workspace:GetAttribute(Layouts.attributeFor(zone)) or "-",
					crossings,
					#slots
				)
			)
		end
		local biomeIds = {}
		for id in Biomes.List do
			table.insert(biomeIds, id)
		end
		table.sort(biomeIds)
		table.insert(lines, "Biomes: " .. table.concat(biomeIds, ", "))
		return lines
	end
)

-- The zones a command names: a number, or all.
local function zonesNamed(which: string): { number }?
	local zones = {}
	if which == "all" then
		for zone = 1, Beach.ActiveTiles do
			table.insert(zones, zone)
		end
		return zones
	end
	local zone = tonumber(which)
	if not zone or zone < 1 or zone > Beach.ActiveTiles then
		return nil
	end
	return { math.floor(zone) }
end

command(
	"biome",
	"biome <zone|all> <biome|none|reroll>",
	"Set a zone's biome (a biome takes the whole zone), e.g. biome 4 hermit, biome all none, biome all reroll",
	function(_, args)
		local which, choice = (args[1] or ""):lower(), (args[2] or ""):lower()
		if which == "" or choice == "" then
			return { "Usage: biome <zone|all> <biome|none|reroll>" }
		end
		if choice == "reroll" then
			BiomeService.reroll()
			return { "Rerolled every zone. Type biomes to see the result." }
		end
		local biomeId: string? = nil
		if choice ~= "none" then
			local biome = Biomes.find(choice)
			if not biome then
				return { "Unknown biome '" .. choice .. "'. Type biomes for the list." }
			end
			biomeId = biome.Id
		end
		local zones = zonesNamed(which)
		if not zones then
			return { "Zone must be 1-" .. Beach.ActiveTiles .. " or all" }
		end
		for _, zone in zones do
			BiomeService.set(zone, biomeId)
		end
		return {
			string.format(
				"Zone %s is now %s (until the next tide rerolls it)",
				which,
				if biomeId then Biomes.List[biomeId].Name else "no biome"
			),
		}
	end
)

command(
	"crossing",
	"crossing <zone|all> <n|reroll> [rooms]",
	"Pick a zone's crossing (and its rooms, one number per slot), e.g. crossing 4 2, crossing 5 1 2,1,3, crossing all reroll",
	function(_, args)
		local which, pick, rooms = (args[1] or ""):lower(), (args[2] or ""):lower(), args[3] or ""
		local zones = zonesNamed(which)
		if not zones or pick == "" then
			return { "Usage: crossing <zone|all> <n|reroll> [rooms]" }
		end
		local lines = {}
		for _, zone in zones do
			local biome = Biomes.activeIn(zone)
			BiomeService.set(zone, biome and biome.Id, if pick == "reroll" then nil else pick .. ":" .. rooms)
			table.insert(
				lines,
				string.format(
					"Zone %d: layout %s",
					zone,
					Workspace:GetAttribute(Layouts.attributeFor(zone)) or "-"
				)
			)
		end
		return lines
	end
)

command(
	"unlock",
	"unlock <item> [count] [player]",
	"Bank unlock items, e.g. unlock goldenspade 3",
	function(caller, args)
		local defs = findItems(args[1] or "")
		local def = defs[1]
		if not def or not def.Unlock then
			return { "Usage: unlock <item> [count] [player], e.g. unlock goldenspade" }
		end
		local count = math.floor(tonumber(args[2]) or 1)
		local lines = {}
		return eachTarget(caller, args[3], function(target)
			if count >= 0 then
				for _ = 1, math.min(count, 100) do
					DataService.addItem(target, def.Id, "admin")
				end
			else
				DataService.removeItemsOfType(target, def.Id, -count)
			end
			table.insert(lines, string.format("%s: %+d %s (banked)", target.Name, count, def.Name))
		end) or lines
	end
)

command(
	"colorcoin",
	"colorcoin <color|all|none> [player]",
	"Give or clear colored coins",
	function(caller, args)
		local choice = (args[1] or ""):lower()
		local colors = {}
		if choice == "all" or choice == "none" then
			colors = Secrets.CoinOrder
		else
			for _, color in Secrets.CoinOrder do
				if color:lower() == choice then
					colors = { color }
				end
			end
		end
		if #colors == 0 then
			return { "Usage: colorcoin <yellow|orange|blue|green|pink|all|none> [player]" }
		end
		local lines = {}
		return eachTarget(caller, args[2], function(target)
			local profile = DataService.get(target)
			if profile then
				for _, color in colors do
					profile.ColoredCoins[color] = if choice == "none" then nil else true
				end
				DataService.changed(target)
				table.insert(lines, target.Name .. ": coins updated")
			end
		end) or lines
	end
)

command(
	"rebirth",
	"rebirth [player]",
	"Rebirth for free (normal reset and reward pick)",
	function(caller, args)
		local lines = {}
		return eachTarget(caller, args[1], function(target)
			local ok, reason = RebirthService.rebirth(target, true)
			table.insert(lines, target.Name .. ": " .. (if ok then "reborn" else tostring(reason)))
		end) or lines
	end
)

command("rebirths", "rebirths <n> [player]", "Set the rebirth count (and multiplier)", function(caller, args)
	local n = tonumber(args[1])
	if not n then
		return { "Usage: rebirths <n> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		local profile = DataService.get(target)
		if profile then
			profile.Rebirths = math.max(0, math.floor(n))
			DataService.changed(target)
			table.insert(
				lines,
				string.format(
					"%s: %d rebirths (x%.1f)",
					target.Name,
					profile.Rebirths,
					Rebirth.multiplier(profile.Rebirths)
				)
			)
		end
	end) or lines
end)

command("reward", "reward <id|all|none> [player]", "Grant or clear rebirth rewards", function(caller, args)
	local choice = (args[1] or ""):lower():gsub("[%s%-_]", "")
	local ids = {}
	if choice == "all" or choice == "none" then
		ids = Rebirth.Order
	else
		for _, id in Rebirth.Order do
			if id:lower() == choice then
				ids = { id }
			end
		end
	end
	if #ids == 0 then
		return { "Usage: reward <" .. table.concat(Rebirth.Order, "|"):lower() .. "|all|none> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		local profile = DataService.get(target)
		if not profile then
			return
		end
		for _, id in ids do
			if choice == "none" then
				profile.Rewards[id] = nil
				local item = Rebirth.Rewards[id].GrantsItem
				if item then
					DataService.removeItemsOfType(target, item, math.huge)
				end
			else
				RebirthService.grantReward(target, id)
			end
		end
		profile.PendingPick = nil
		DataService.changed(target)
		RebirthService.applyEffects(target)
		table.insert(lines, target.Name .. ": rewards updated")
	end) or lines
end)

command("inv", "inv [player]", "List a player's inventory", function(caller, args)
	local lines = {}
	return eachTarget(caller, args[1], function(target)
		local profile = DataService.get(target)
		if not profile then
			return
		end
		local counts = {}
		for _, record in profile.Items do
			counts[record.Id] = (counts[record.Id] or 0) + 1
		end
		local parts = {}
		for id, count in counts do
			local entry = Catalog.get(id)
			table.insert(parts, string.format("%s x%d", if entry then entry.Name else id, count))
		end
		table.sort(parts)
		table.insert(
			lines,
			target.Name .. ": " .. (if #parts > 0 then table.concat(parts, ", ") else "(empty)")
		)
		table.insert(lines, string.format("  pockets %d, cores %d", #profile.Pockets, profile.Cores))
	end) or lines
end)

command("towerman", "towerman [zone]", "Make the tower man appear (zone 1 by default)", function(_, args)
	local zone = math.clamp(math.floor(tonumber(args[1]) or 1), 1, Config.Beach.ActiveZones)
	LexiconService.spawnTowerMan(zone)
	return { "The tower man is in zone " .. zone .. " until the next tide cycle" }
end)

command("lexicon", "lexicon <all|none> [player]", "Fill or clear the lexicon", function(caller, args)
	local choice = (args[1] or ""):lower()
	if choice ~= "all" and choice ~= "none" then
		return { "Usage: lexicon <all|none> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		local profile = DataService.get(target)
		if profile then
			profile.Lexicon = {}
			if choice == "all" then
				for _, item in Items.Catalog do
					profile.Lexicon[item.Id] = os.time()
				end
			end
			DataService.changed(target)
			table.insert(
				lines,
				target.Name .. ": lexicon " .. (if choice == "all" then "complete" else "cleared")
			)
		end
	end) or lines
end)

command("trader", "trader <id> [zone]", "Make a special trader appear, e.g. trader gary 1", function(_, args)
	local key = (args[1] or ""):lower()
	local trader
	for id, entry in Traders.List do
		if id:lower() == key then
			trader = entry
		end
	end
	if not trader then
		local ids = {}
		for id in Traders.List do
			table.insert(ids, id)
		end
		table.sort(ids)
		return { "Usage: trader <" .. table.concat(ids, "|") .. "> [zone]" }
	end
	local zone = math.clamp(math.floor(tonumber(args[2]) or 1), 1, Config.Beach.ActiveZones)
	local parent = Workspace:FindFirstChild("AdminTraders") or Instance.new("Folder")
	parent.Name = "AdminTraders"
	parent.Parent = Workspace
	TraderService.spawn(trader, (zone - 1) * Config.Beach.TilesPerZone + 1, parent) -- the zone's first tile
	return {
		trader.Name
			.. " is in zone "
			.. zone
			.. ", about 65 studs in. Admin traders stay until the server restarts.",
	}
end)

command(
	"upgrade",
	"upgrade <id> <level> [player]",
	"Set a trader upgrade level, e.g. upgrade deeplungs 3",
	function(caller, args)
		local key = (args[1] or ""):lower()
		local upgradeId
		for id in Traders.Upgrades do
			if id:lower() == key then
				upgradeId = id
			end
		end
		local level = tonumber(args[2])
		if not upgradeId or not level then
			return { "Usage: upgrade <" .. table.concat(Traders.UpgradeOrder, "|") .. "> <level> [player]" }
		end
		local lines = {}
		return eachTarget(caller, args[3], function(target)
			local profile = DataService.get(target)
			if profile then
				profile.Upgrades[upgradeId] =
					math.clamp(math.floor(level), 0, Traders.Upgrades[upgradeId].MaxLevel)
				DataService.changed(target)
				RebirthService.applyEffects(target)
				table.insert(
					lines,
					string.format("%s: %s level %d", target.Name, upgradeId, profile.Upgrades[upgradeId])
				)
			end
		end) or lines
	end
)

command("auction", "auction [end]", "Show the current auction lot, or end it now", function(caller, args)
	if (args[1] or ""):lower() == "end" then
		local state = AuctionService._stateFor(caller)
		Workspace:SetAttribute(
			AuctionService.OffsetAttribute,
			(Workspace:GetAttribute(AuctionService.OffsetAttribute) or 0) + math.max(0, state.TimeLeft) + 1
		)
		return { "Ended " .. state.Name .. ". It's resolved within a few seconds and the next lot starts." }
	end
	local state = AuctionService._stateFor(caller)
	return {
		string.format("%s (%s), %ds left", state.Name, state.LotId, state.TimeLeft),
		string.format(
			"Top bid %d by %s, minimum next %d",
			state.TopBid,
			tostring(state.TopName),
			state.MinNext
		),
		string.format("%d of %d already won", state.Issued, state.Of),
	}
end)

-- Remote --------------------------------------------------------------------------

local function onCommand(player: Player, line: any): { string }
	if not admins[player] then
		return { "You are not an admin." }
	end
	if type(line) ~= "string" or #line > 300 then
		return { "Invalid command" }
	end
	local args = {}
	for word in line:gmatch("%S+") do
		table.insert(args, word)
	end
	local name = table.remove(args, 1)
	if not name then
		return {}
	end
	local cmd = commands[name:lower()]
	if not cmd then
		return { "Unknown command '" .. name .. "'. Type help." }
	end
	local ok, result = pcall(cmd.run, player, args)
	if not ok then
		warn("[AdminService]", player.Name, line, result)
		return { "Error: " .. tostring(result) }
	end
	print(string.format("[Admin] %s: %s", player.Name, line))
	return result
end

command(
	"pass",
	"pass <id|list> [on|off] [player]",
	"Give or take a gamepass for this session, to test its effect, e.g. pass extrapockets on",
	function(caller, args)
		local choice = (args[1] or ""):lower()
		local pass
		for _, candidate in Config.Monetization.Gamepasses do
			if candidate.Id:lower() == choice then
				pass = candidate
			end
		end
		if not pass then
			local lines = { "Gamepasses (PassId 0 = not set up on Roblox yet):" }
			for _, candidate in Config.Monetization.Gamepasses do
				table.insert(
					lines,
					string.format("  %s (%d): %s", candidate.Id, candidate.PassId, candidate.Note)
				)
			end
			return lines
		end
		local on = (args[2] or "on"):lower() ~= "off"
		local lines = {}
		return eachTarget(caller, args[3], function(target)
			MonetizationService.setPass(target, pass.Id, on)
			table.insert(
				lines,
				string.format("%s: %s %s", target.Name, pass.Name, if on then "on" else "off")
			)
		end) or lines
	end
)

command(
	"private",
	"private <players|off>",
	"Act as a private server with this many players (rare spawns scale with it)",
	function(_, args)
		local count = tonumber(args[1])
		if count then
			MonetizationService.simulatePrivate(math.max(0, math.floor(count)))
		elseif (args[1] or ""):lower() == "off" then
			MonetizationService.simulatePrivate(nil)
		else
			return { "Usage: private <players|off>" }
		end
		return { string.format("Rare spawns at x%.2f", MonetizationService.rareScale()) }
	end
)

function AdminService.init()
	local function onPlayer(player: Player)
		local isAdmin = checkAdmin(player)
		admins[player] = isAdmin or nil
		player:SetAttribute("IsAdmin", isAdmin)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		admins[player] = nil
	end)

	Remotes.get("AdminCommand").OnServerInvoke = onCommand
end

return AdminService
