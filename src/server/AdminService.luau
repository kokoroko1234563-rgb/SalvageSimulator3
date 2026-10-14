-- Admin console commands. Every command runs on the server after an admin check, so a
-- client can't use the remote to cheat. Type `help` in the console (F2) for the list.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)
local Tide = require(Shared.Tide)
local Waves = require(Shared.Waves)

local DataService = require(script.Parent.DataService)
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
			"Tide: %s %.0f%% (%.0fs left), front x=%.0f, cycle %.0fs, time scale %.2f",
			state.Phase,
			state.PhaseProgress * 100,
			state.PhaseRemaining,
			state.FrontX,
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

command("give", "give <tool or vessel> [player]", "Give gear, e.g. give boathook", function(caller, args)
	if not args[1] then
		return { "Usage: give <tool or vessel> [player]" }
	end
	local kind, entry = findGear(args[1])
	if not kind then
		return { "Unknown tool or vessel '" .. args[1] .. "'" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		if kind == "Tool" then
			DataService.grantTool(target, entry.Id)
		else
			DataService.grantVessel(target, entry.Id)
		end
		table.insert(lines, "Gave " .. entry.Name .. " to " .. target.Name)
	end) or lines
end)

command("vessel", "vessel <vessel> [player]", "Spawn a vessel next to the player", function(caller, args)
	local kind, entry = findGear(args[1] or "")
	if kind ~= "Vessel" then
		return { "Usage: vessel <wheelbarrow|beachwagon> [player]" }
	end
	local lines = {}
	return eachTarget(caller, args[2], function(target)
		local root = rootOf(target)
		local at: CFrame? = nil
		if root then
			local look = root.CFrame.LookVector
			local spot = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 8
			local groundY = if spot.X < 0 then 1 else Beach.groundY(spot.Z)
			at = CFrame.new(spot.X, groundY + 0.2, spot.Z)
		end
		local ok, reason = VesselService.spawn(target, entry.Id, at)
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
		local zone = math.clamp(Beach.zoneAt(root.Position.X) or 1, 1, Config.Beach.ActiveZones)
		for i = 1, count do
			local def = defs[rng:NextInteger(1, #defs)]
			local spot = root.Position
				+ forward * (6 + i * 0.5)
				+ Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
			local groundY = if spot.X < 0 then 1 else Beach.groundY(spot.Z)
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
			"Tide set to %s %.0f%%, front x=%.0f",
			state.Phase,
			state.PhaseProgress * 100,
			state.FrontX
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

command("waves", "waves <multiplier>", "Wave strength: 1 = normal, 0 = calm", function(_, args)
	local scale = tonumber(args[1])
	if not scale or scale < 0 then
		return { "Usage: waves <multiplier>" }
	end
	Workspace:SetAttribute(Waves.ScaleAttribute, scale)
	return { string.format("Wave strength x%.2f", scale) }
end)

command(
	"tp",
	"tp <shop|zone number|player> [who]",
	"Teleport, e.g. tp 3, tp shop, tp bob",
	function(caller, args)
		local where = (args[1] or ""):lower()
		local destination: Vector3?
		if where == "shop" then
			destination = Vector3.new(-60, 4, -40)
		elseif tonumber(where) then
			local zone = math.clamp(math.floor(tonumber(where) :: number), 1, Config.Beach.ActiveZones)
			local startX, endX = Beach.zoneRange(zone)
			destination = Vector3.new((startX + endX) / 2, 4, -10)
		elseif where ~= "" then
			local targets, err = findPlayers(caller, where)
			local root = targets[1] and rootOf(targets[1])
			if err or not root then
				return { "Error: " .. (err or "that player has no character") }
			end
			destination = root.Position + Vector3.new(0, 0, -4)
		end
		if not destination then
			return { "Usage: tp <shop|zone number|player> [who]" }
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
