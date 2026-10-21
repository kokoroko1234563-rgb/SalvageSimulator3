-- Server-side bots that play the game's core loop, so item competition between X players on one
-- server can be measured (docs/design/bots.md; tools/bots/sweep.py runs the sweep).
--
-- Plan
--   * No physics. A bot is an anchored R15 man in its own colour, moved by CFrame every frame at
--     real walk speed (Stats.walkSpeed's 16, slowed by the water as Beach.wading says, times the
--     sweep's speed factor). Its cart is anchored too and trails it along its own track. A bot
--     still does every motion of the game: walks out, walks to an item, claims it, loads it,
--     walks back, sells at the buyer, walks to the shopkeeper to buy gear or rebirth.
--   * Routes come from src/shared/Routes: a lazily filled grid A* over Beach.shapeAt (the active
--     layouts, so whatever biomes rolled), the same stepping rules as tools/paths.luau, never
--     over rock or too steep a climb (a cart takes the gentler CartSlope and needs room for its
--     size), and never into water deeper than a player can stand in at the moment the bot would
--     be there (the sea's level is predicted along the route from the tide).
--   * Claims are the real ones: the item must be free in ItemService, and GrabService.canClaim
--     (the player's rules: reach, weight class, water depth) must allow it; ItemService.claimForBot
--     then takes it atomically, so whoever arrives first gets it. Bots and players share the
--     surf, the loot spots and the despawn timers. Bots own negative ids, never a UserId.
--   * Money is the game's: ShopService.payout (Value x zone x rebirth multiplier), ShopService
--     .listing and Gear's price lists, Rebirth.cost. A bot's coins, gear and rebirths live in
--     BotEconomy.State in memory; nothing here touches DataService or a DataStore.
--   * One rule for every bot (BotEconomy): rebirth as soon as it can be afforded, taking the
--     reward that raises income most; otherwise buy what raises income most for its price. It
--     goes for the item with the best value for the time it costs (there and back), among what
--     its tool can reach and lift, whose way back the tide won't cut. It heads home when its
--     cart is full or nothing else will do; one the sea catches loses its cart load.
--   * Measures: per bot (coins, items, trips, items lost to another bot, idle time, deaths and
--     lost loads) and an income-per-tide log with gear, zones and bot count (for the Monte
--     Carlo); server-wide counts come from ItemService.stats.
--   * Nothing runs until an admin starts it (AdminService `bots`) or the sweep does.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Routes = require(Shared.Routes)
local Tide = require(Shared.Tide)

local BotEconomy = require(script.Parent.BotEconomy)
local GrabService = require(script.Parent.GrabService)
local ItemService = require(script.Parent.ItemService)

local BotService = {}

BotService.MaxBots = 20
BotService.Tag = "SalvageBot"

-- 20 clearly distinct colours, named for the name tags.
BotService.Colors = {
	{ "Red", Color3.fromRGB(226, 30, 30) },
	{ "Orange", Color3.fromRGB(255, 130, 0) },
	{ "Yellow", Color3.fromRGB(255, 226, 0) },
	{ "Lime", Color3.fromRGB(160, 235, 30) },
	{ "Green", Color3.fromRGB(20, 140, 55) },
	{ "Mint", Color3.fromRGB(130, 235, 180) },
	{ "Teal", Color3.fromRGB(0, 140, 150) },
	{ "Cyan", Color3.fromRGB(0, 215, 255) },
	{ "Sky", Color3.fromRGB(120, 170, 255) },
	{ "Blue", Color3.fromRGB(20, 60, 230) },
	{ "Navy", Color3.fromRGB(15, 25, 90) },
	{ "Violet", Color3.fromRGB(140, 90, 230) },
	{ "Purple", Color3.fromRGB(100, 20, 140) },
	{ "Magenta", Color3.fromRGB(230, 20, 200) },
	{ "Pink", Color3.fromRGB(255, 160, 190) },
	{ "Brown", Color3.fromRGB(120, 70, 30) },
	{ "Maroon", Color3.fromRGB(120, 10, 40) },
	{ "Black", Color3.fromRGB(20, 20, 22) },
	{ "Grey", Color3.fromRGB(140, 142, 146) },
	{ "White", Color3.fromRGB(250, 250, 250) },
}

-- Where the shop's people stand (BeachBuilder's SELL_PAD and the shopkeeper's house): the sell pad
-- and a spot within the shopkeeper's range (Config.Selling.ShopkeeperRange).
local HOME = { x = 90, z = -30 }
local SHOP = { x = -200, z = -31 }
local HIP = 2.9 -- the root's height over the ground
local DEPTH_MARGIN = 0.4 -- routes keep this far short of waist depth (deeper drowns)
local SAFE_SPEED = 0.85 -- routes assume the bot walks this much of its speed (wading, corners)

type Bot = any

local bots: { [number]: Bot } = {}
local running = false
local connection: RBXScriptConnection? = nil
local grid: any = nil
local botFolder: Folder? = nil
local speedFactor = 1
local originals: { [string]: number }? = nil
local incomeLog: { any } = {}
local lastCycle = -1
local lastRefresh = 0
local startedAt = 0
local tripResult: any = nil
local rng = Random.new()

local function now(): number
	return Tide.now()
end

local function commas(n: number): string
	local text = tostring(math.floor(n))
	local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- Looks ----------------------------------------------------------------------------------

local function block(parent: Instance, name: string, size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A basic R15 man (parts, joints, humanoid), every part the one colour and nothing else on it
-- but a name tag. The model stands with its feet on y = 0 at the origin, facing -Z.
local function buildMan(bot: Bot): Model
	local color = bot.Color
	local model = Instance.new("Model")
	model.Name = string.format("Bot %d - %s", bot.Id, bot.ColorName)
	local spec = {
		-- name, size, centre height, x offset, parent
		{ "HumanoidRootPart", Vector3.new(2, 2, 1), HIP, 0, nil },
		{ "LowerTorso", Vector3.new(2, 0.4, 1), 2.9, 0, "HumanoidRootPart" },
		{ "UpperTorso", Vector3.new(2, 1.6, 1), 3.9, 0, "LowerTorso" },
		{ "Head", Vector3.new(2, 1, 1), 5.2, 0, "UpperTorso" },
		{ "LeftUpperArm", Vector3.new(1, 1.2, 1), 4.0, -1.5, "UpperTorso" },
		{ "LeftLowerArm", Vector3.new(1, 1.1, 1), 2.85, -1.5, "LeftUpperArm" },
		{ "LeftHand", Vector3.new(1, 0.3, 1), 2.15, -1.5, "LeftLowerArm" },
		{ "RightUpperArm", Vector3.new(1, 1.2, 1), 4.0, 1.5, "UpperTorso" },
		{ "RightLowerArm", Vector3.new(1, 1.1, 1), 2.85, 1.5, "RightUpperArm" },
		{ "RightHand", Vector3.new(1, 0.3, 1), 2.15, 1.5, "RightLowerArm" },
		{ "LeftUpperLeg", Vector3.new(1, 1.2, 1), 2.1, -0.5, "LowerTorso" },
		{ "LeftLowerLeg", Vector3.new(1, 1.2, 1), 0.9, -0.5, "LeftUpperLeg" },
		{ "LeftFoot", Vector3.new(1, 0.3, 1), 0.15, -0.5, "LeftLowerLeg" },
		{ "RightUpperLeg", Vector3.new(1, 1.2, 1), 2.1, 0.5, "LowerTorso" },
		{ "RightLowerLeg", Vector3.new(1, 1.2, 1), 0.9, 0.5, "RightUpperLeg" },
		{ "RightFoot", Vector3.new(1, 0.3, 1), 0.15, 0.5, "RightLowerLeg" },
	}
	local parts: { [string]: Part } = {}
	local centres: { [string]: Vector3 } = {}
	for _, entry in spec do
		local part = block(model, entry[1], entry[2], color)
		parts[entry[1]] = part
		centres[entry[1]] = Vector3.new(entry[4], entry[3], 0)
		part.CFrame = CFrame.new(centres[entry[1]])
		if entry[1] == "HumanoidRootPart" then
			part.Transparency = 1
		end
	end
	for _, entry in spec do
		if entry[5] then
			local joint = Instance.new("Motor6D")
			joint.Name = entry[1]
			joint.Part0 = parts[entry[5]]
			joint.Part1 = parts[entry[1]]
			joint.C0 = CFrame.new(centres[entry[1]] - centres[entry[5]])
			joint.C1 = CFrame.new()
			joint.Parent = parts[entry[1]]
		end
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model
	model.PrimaryPart = parts.HumanoidRootPart

	-- The name tag, and a status line under it (set on state changes, see setStatus).
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(260, 56)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 900
	gui.Adornee = parts.Head
	gui.Parent = parts.Head
	local function label(name: string, y: number, height: number, size: number, text: string)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Size = UDim2.new(1, 0, 0, height)
		l.Position = UDim2.fromOffset(0, y)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextSize = size
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeColor3 = Color3.new(0, 0, 0)
		l.TextStrokeTransparency = 0.3
		l.Text = text
		l.Parent = gui
		return l
	end
	local tag = label("Name", 0, 28, 22, string.format("Bot %d \u{2013} %s", bot.Id, bot.ColorName))
	tag.TextColor3 = color
	tag.TextStrokeTransparency = 0
	bot.StatusLabel = label("Status", 28, 24, 14, "")
	return model
end

-- A cart in the bot's colour: a bed, low sides, two wheels and a handle, sized by the vessel.
local function buildCart(bot: Bot, vessel): Model
	local box = Config.Carts.Sizes[vessel.Size].Box
	local model = Instance.new("Model")
	model.Name = string.format("Bot %d cart", bot.Id)
	local color = bot.Color
	local bed = block(model, "Cargo", Vector3.new(box.X, 0.5, box.Z), color)
	bed.CFrame = CFrame.new(0, 1.2, 0)
	local side = block(model, "SideL", Vector3.new(0.4, 1, box.Z), color)
	side.CFrame = CFrame.new(-box.X / 2 + 0.2, 1.9, 0)
	local sideR = block(model, "SideR", Vector3.new(0.4, 1, box.Z), color)
	sideR.CFrame = CFrame.new(box.X / 2 - 0.2, 1.9, 0)
	local back = block(model, "Back", Vector3.new(box.X, 1, 0.4), color)
	back.CFrame = CFrame.new(0, 1.9, box.Z / 2 - 0.2)
	for _, sign in { -1, 1 } do
		local wheel = block(model, "Wheel", Vector3.new(0.6, 1.8, 1.8), color)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.CFrame = CFrame.new(sign * (box.X / 2 + 0.3), 0.9, 0)
	end
	local handle = block(model, "Handle", Vector3.new(box.X, 0.3, 0.3), color)
	handle.CFrame = CFrame.new(0, 2.4, -box.Z / 2 - 0.4)
	model.PrimaryPart = bed
	bot.CartBox = box
	return model
end

local function setStatus(bot: Bot, status: string)
	bot.Status = status
	local rebirths = bot.State.Rebirths
	local zone = Beach.zoneAt(bot.Z)
	local text = string.format(
		"%s%s \u{B7} %s \u{B7} %s coins \u{B7} %d rebirth%s",
		status:sub(1, 1):upper() .. status:sub(2),
		if BotEconomy.capacity(bot.State) > 1 or #bot.Cargo > 0
			then string.format(" %d/%d", #bot.Cargo, BotEconomy.capacity(bot.State))
			else "",
		if zone == 0 or zone == nil then "shop" else "zone " .. zone,
		commas(bot.State.Coins),
		rebirths,
		if rebirths == 1 then "" else "s"
	)
	if bot.StatusLabel and bot.StatusText ~= text then
		bot.StatusText = text
		bot.StatusLabel.Text = text
	end
end

-- Moving ---------------------------------------------------------------------------------

local function setCFrame(bot: Bot, groundY: number)
	local position = Vector3.new(bot.X, groundY + HIP, bot.Z)
	bot.Model:PivotTo(CFrame.lookAt(position, position + Vector3.new(bot.DirX, 0, bot.DirZ)))
end

-- Keeps the cart on the bot's track, a few studs behind, and what's in it with it.
local function placeCart(bot: Bot)
	if not bot.Cart then
		-- Hands carry one thing in front of the bot.
		local item = bot.Cargo[1]
		if item then
			item.CFrame = CFrame.new(bot.X + bot.DirX * 1.6, bot.GroundY + 3.8, bot.Z + bot.DirZ * 1.6)
		end
		return
	end
	local trail = bot.Trail
	local back = trail[math.max(1, #trail - 4)]
	local cx, cz = back.x, back.z
	local dx, dz = bot.X - cx, bot.Z - cz
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 0.5 then
		dx, dz = bot.DirX, bot.DirZ
		length = 1
	end
	local groundY = Beach.groundAt(cx, cz)
	local cframe =
		CFrame.lookAt(Vector3.new(cx, groundY, cz), Vector3.new(cx + dx / length, groundY, cz + dz / length))
	-- (the cart's handle is at -Z: it faces the bot)
	bot.Cart:PivotTo(cframe)
	local box = bot.CartBox
	local columns = math.min(2, math.max(1, BotEconomy.capacity(bot.State)))
	local rows = math.ceil(BotEconomy.capacity(bot.State) / columns)
	for slot, item in bot.Cargo do
		local column, row = (slot - 1) % columns, (slot - 1) // columns
		local offset = Vector3.new(
			-box.X / 2 + box.X / columns * (column + 0.5),
			1.45 + item.Size.Y / 2,
			-box.Z / 2 + box.Z / rows * (row + 0.5)
		)
		item.CFrame = cframe * CFrame.new(offset)
	end
end

local function dropTrail(bot: Bot)
	bot.Trail = { { x = bot.X, z = bot.Z } }
end

local function advance(bot: Bot, dt: number, sea: Tide.Sea): boolean
	-- Moves along the path for dt seconds; true when it has arrived.
	local path = bot.Path
	local speed = BotEconomy.walkSpeed(bot.State) * speedFactor
	local wade = Beach.wading(Vector3.new(bot.X, bot.GroundY, bot.Z), sea)
	local remaining = speed * wade * dt
	local moved = false
	while remaining > 0 do
		local target = path[bot.Index]
		if not target then
			break
		end
		local dx, dz = target.x - bot.X, target.z - bot.Z
		local distance = math.sqrt(dx * dx + dz * dz)
		if distance <= remaining then
			bot.X, bot.Z = target.x, target.z
			remaining -= distance
			if distance > 0.01 then
				bot.DirX, bot.DirZ = dx / distance, dz / distance
			end
			bot.Index += 1
			moved = true
		else
			bot.X += dx / distance * remaining
			bot.Z += dz / distance * remaining
			bot.DirX, bot.DirZ = dx / distance, dz / distance
			remaining = 0
			moved = true
		end
	end
	if moved then
		local last = bot.Trail[#bot.Trail]
		if (bot.X - last.x) ^ 2 + (bot.Z - last.z) ^ 2 >= 4 then
			table.insert(bot.Trail, { x = bot.X, z = bot.Z })
			if #bot.Trail > 12 then
				table.remove(bot.Trail, 1)
			end
		end
	end
	return bot.Path[bot.Index] == nil, moved
end

-- Routes ---------------------------------------------------------------------------------

local function waterBlocker(speed: number, limit: number, delay: number)
	-- Whether the sea would be too deep to stand in at a cell when the bot reaches it (`delay`
	-- seconds from now it sets out). The bot may be slower than planned (the water slows it) or
	-- quicker, and the sea goes both ways, so both arrivals count.
	local t0 = now() + delay
	local cache: { [number]: number } = {}
	local factor = speedFactor
	local fast = speed / SAFE_SPEED * 1.1
	local function deepAt(x: number, ground: number, t: number): boolean
		local key = math.floor(t * factor) * 4096 + (x + 400) // 4
		local level = cache[key]
		if not level then
			level = Beach.waterYAt({ Now = t }, x)
			cache[key] = level
		end
		return level - ground >= limit
	end
	return function(x: number, _z: number, ground: number, walked: number): boolean
		return deepAt(x, ground, t0 + walked / speed) or deepAt(x, ground, t0 + walked / fast)
	end
end

-- A route from the bot's spot to (x, z), through the shop's flat ground at either end. Nil if
-- there's no way that the sea won't cut. `safe` false stops looking at the tide.
local function routeTo(
	bot: Bot,
	x: number,
	z: number,
	radius: number?,
	from: { x: number, z: number }?,
	delay: number?
): ({ any }?, number?)
	local start = from or { x = bot.X, z = bot.Z }
	local speed = BotEconomy.walkSpeed(bot.State) * speedFactor * SAFE_SPEED
	local cart = BotEconomy.cartSize(bot.State)
	local limit = Config.Beach.WaistDepth - DEPTH_MARGIN
	local options = {
		slope = if cart then Config.Beach.Terrain.CartSlope else Config.Beach.Terrain.FootSlope,
		cart = cart,
		blocked = waterBlocker(speed, limit, delay or 0),
		radius = radius,
		maxNodes = 90000,
	}
	local gridStart = { x = start.x, z = math.max(start.z, 0) }
	local gridGoal = { x = x, z = math.max(z, 0) }
	local path, length = grid:find(gridStart, gridGoal, options)
	if not path then
		return nil, nil
	end
	local full = {}
	if start.z < 0 then
		table.insert(full, { x = start.x, z = start.z })
	end
	for _, point in path do
		table.insert(full, point)
	end
	if z < 0 then
		table.insert(full, { x = x, z = z })
	end
	return full, length
end

local function beginPath(bot: Bot, path: { any }, mode: string)
	bot.Path = path
	bot.Index = 2
	bot.Mode = mode
	if path[1] and (path[1].x ~= bot.X or path[1].z ~= bot.Z) then
		bot.Index = 1
	end
end

-- Decisions ------------------------------------------------------------------------------

local decide: (Bot) -> ()

local function later(bot: Bot, gameSeconds: number, fn: () -> ())
	bot.WaitUntil = now() + gameSeconds / speedFactor
	bot.After = fn
end

local function atHome(bot: Bot): boolean
	return math.abs(bot.X - HOME.x) < 60 and bot.Z < 20
end

local function loadFraction(bot: Bot): string
	return string.format("%d/%d", #bot.Cargo, BotEconomy.capacity(bot.State))
end

local function goHome(bot: Bot)
	local path = routeTo(bot, HOME.x, HOME.z, 6)
	if not path then
		-- Nothing the tide won't cut: try anyway on the shortest way, rather than stand and drown.
		local cart = BotEconomy.cartSize(bot.State)
		path = grid:find({ x = bot.X, z = math.max(bot.Z, 0) }, { x = HOME.x, z = 0 }, {
			slope = if cart then Config.Beach.Terrain.CartSlope else Config.Beach.Terrain.FootSlope,
			cart = cart,
			radius = 6,
			maxNodes = 90000,
		})
		if path then
			table.insert(path, { x = HOME.x, z = HOME.z })
		end
	end
	if not path then
		bot.StuckUntil = now() + 1
		return
	end
	setStatus(bot, if #bot.Cargo > 0 then "hauling back" else "waiting for the tide")
	beginPath(bot, path, "Home")
end

-- Items worth a look: free, in reach of the tool, no heavier than it lifts, not ones we
-- gave up on, and for a trip bot only in its zone. Scored by value per second there and back.
local function candidates(bot: Bot): { any }
	local tool = BotEconomy.tool(bot.State)
	local lift = BotEconomy.lift(bot.State, tool)
	local speed = BotEconomy.walkSpeed(bot.State) * speedFactor
	local sea = Tide.sea()
	local t = now()
	local list = {}
	for item in ItemService.all() do
		if
			ItemService.getState(item) == "Unclaimed"
			and not item:GetAttribute("Unlock")
			and (item:GetAttribute("Class") or 1) <= lift
			and (not bot.Skip[item] or bot.Skip[item] < t)
			and (not bot.Trip or item:GetAttribute("Zone") == bot.Trip.Zone)
		then
			local position = item.Position
			local band = Beach.depthBand(position, sea)
			if Gear.canReachDepth(tool, band) and not Beach.isLost(position, sea) then
				local there = math.sqrt((position.X - bot.X) ^ 2 + (position.Z - bot.Z) ^ 2)
					* BotEconomy.MazeFactor
					/ speed
				local back = math.sqrt((position.X - HOME.x) ^ 2 + (position.Z - HOME.z) ^ 2)
					* BotEconomy.MazeFactor
					/ speed
				table.insert(list, {
					Item = item,
					Score = (item:GetAttribute("Value") or 0) / (there + 0.6 * back + 6 / speedFactor),
				})
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Score > b.Score
	end)
	return list
end

local function chooseTarget(bot: Bot): boolean
	local list = candidates(bot)
	for i = 1, math.min(#list, 4) do
		local item = list[i].Item
		local position = item.Position
		local out, outLength =
			routeTo(bot, position.X, position.Z, math.min(BotEconomy.tool(bot.State).Reach * 0.6, 8))
		if out then
			-- And the way back from there must stay open, setting out once it's loaded.
			local walk = BotEconomy.walkSpeed(bot.State) * speedFactor * SAFE_SPEED
			local back = routeTo(
				bot,
				HOME.x,
				HOME.z,
				6,
				{ x = out[#out].x, z = out[#out].z },
				(outLength or 0) / walk + 1.2 / speedFactor
			)
			if back then
				bot.Target = item
				bot.Reapproached = false
				setStatus(bot, if atHome(bot) then "walking out" else "heading for an item")
				beginPath(bot, out, "ToItem")
				return true
			end
		end
		bot.Skip[item] = now() + 20 / speedFactor
	end
	return false
end

-- Where a bot waits for what the tide washes up: just landward of the waterline as it will be when
-- the bot gets there, along the bot's own lane of the beach (a trip bot: inside its zone).
local function stagingPoint(bot: Bot): (number, number)
	local x = bot.LaneX
	local speed = BotEconomy.walkSpeed(bot.State) * speedFactor
	local t = now()
	local z = bot.Z
	for _ = 1, 3 do
		local eta = math.sqrt((x - bot.X) ^ 2 + (z - bot.Z) ^ 2) * BotEconomy.MazeFactor / speed
		z = Tide.waterlineAt({ Now = t + eta }, x) - 8
	end
	local top, bottom = 0, Beach.Depth - 20
	if bot.Trip then
		local z0, z1 = Beach.zoneRange(bot.Trip.Zone)
		top, bottom = z0 + 10, z1 - 20
	end
	return x, math.clamp(z, top, bottom)
end

function decide(bot: Bot)
	bot.Target = nil
	local capacity = BotEconomy.capacity(bot.State)
	if #bot.Cargo < capacity and not bot.Finished then
		if chooseTarget(bot) then
			return
		end
	end
	if #bot.Cargo > 0 then
		goHome(bot)
		return
	end
	local t = now()
	-- Nothing to take: walk out with the tide while it's going out (or low), as long as the way
	-- back stays open for a minute longer than it needs to; otherwise wait where it's safe.
	if not bot.Finished and Tide.getState(t).Phase ~= "In" then
		local sx, sz = stagingPoint(bot)
		if math.sqrt((sx - bot.X) ^ 2 + (sz - bot.Z) ^ 2) > 40 then
			local out, outLength = routeTo(bot, sx, sz, 8)
			if out then
				local walk = BotEconomy.walkSpeed(bot.State) * speedFactor * SAFE_SPEED
				local back = routeTo(
					bot,
					HOME.x,
					HOME.z,
					6,
					{ x = out[#out].x, z = out[#out].z },
					(outLength or 0) / walk + 60 / speedFactor
				)
				if back then
					setStatus(bot, "walking out")
					beginPath(bot, out, "Stage")
					return
				end
			end
		elseif atHome(bot) then
			-- (waiting at home)
		elseif (bot.BackCheckAt or 0) > t then
			setStatus(bot, "waiting for the tide")
			bot.WaitUntil = t + 0.3
			bot.After = function() end
			return
		else
			bot.BackCheckAt = t + 3 / speedFactor
			if routeTo(bot, HOME.x, HOME.z, 6, nil, 60 / speedFactor) then
				setStatus(bot, "waiting for the tide")
				bot.WaitUntil = t + 0.3
				bot.After = function() end
				return
			end
		end
	end
	if not atHome(bot) then
		goHome(bot)
		return
	end
	setStatus(bot, "waiting for the tide")
	bot.WaitUntil = now() + 0.5
	bot.After = function() end
end

-- Logging ------------------------------------------------------------------------------

local function gearSnapshot(bot: Bot)
	return BotEconomy.gearOf(bot.State)
end

local function newCycle(bot: Bot, cycle: number)
	bot.Cycle = {
		Cycle = cycle,
		Coins = 0,
		Items = 0,
		Trips = 0,
		Zones = {},
		GearStart = gearSnapshot(bot),
		StartedAt = now(),
	}
end

local function flushCycle(bot: Bot, partial: boolean)
	local entry = bot.Cycle
	if not entry then
		return
	end
	local seconds = (now() - entry.StartedAt) * speedFactor
	table.insert(incomeLog, {
		Bot = bot.Id,
		Cycle = entry.Cycle,
		Income = entry.Coins,
		Items = entry.Items,
		Trips = entry.Trips,
		GameSeconds = seconds,
		Partial = partial,
		BotCount = BotService.count(),
		GearStart = entry.GearStart,
		Gear = gearSnapshot(bot),
		Zones = entry.Zones,
		Speed = speedFactor,
	})
	bot.Cycle = nil
end

-- Acting ---------------------------------------------------------------------------------

local function destroyCart(bot: Bot)
	if bot.Cart then
		bot.Cart:Destroy()
		bot.Cart = nil
	end
end

local function makeCart(bot: Bot)
	destroyCart(bot)
	local vessel = BotEconomy.vessel(bot.State)
	if not vessel then
		return
	end
	bot.Cart = buildCart(bot, vessel)
	bot.Cart.Parent = botFolder
	bot.CartVessel = vessel.Id
	dropTrail(bot)
	placeCart(bot)
end

local function loseLoad(bot: Bot)
	for _, item in bot.Cargo do
		if ItemService.isItem(item) then
			ItemService.destroy(item)
		end
	end
	bot.Stats.LostItems += #bot.Cargo
	bot.Cargo = {}
end

local function die(bot: Bot)
	local state = Tide.getState()
	warn(
		string.format(
			"[BotService] bot %d swept away at z %.0f (zone %s) in the %s tide (%.0f%%), %s, carrying %d",
			bot.Id,
			bot.Z,
			tostring(Beach.zoneAt(bot.Z)),
			state.Phase,
			state.PhaseProgress * 100,
			tostring(bot.Mode),
			#bot.Cargo
		)
	)
	bot.Stats.Deaths += 1
	if #bot.Cargo > 0 then
		bot.Stats.LostLoads += 1
	end
	loseLoad(bot)
	bot.Path = nil
	bot.Target = nil
	setStatus(bot, "swept away by the tide")
	later(bot, 4, function()
		bot.X, bot.Z = HOME.x + rng:NextNumber(-20, 20), HOME.z + rng:NextNumber(-6, 6)
		dropTrail(bot)
		bot.GroundY = Beach.groundAt(bot.X, bot.Z)
		setCFrame(bot, bot.GroundY)
		if bot.Cart then
			placeCart(bot)
		end
		bot.Mode = nil
	end)
end

local function sell(bot: Bot)
	local total, count = 0, 0
	local zones = {}
	for _, item in bot.Cargo do
		if ItemService.isItem(item) then
			local value = item:GetAttribute("Value") or 0
			total += value
			count += 1
			local zone = item:GetAttribute("Zone") or 0
			local z = zones[zone] or { Items = 0, Value = 0 }
			z.Items += 1
			z.Value += value
			zones[zone] = z
			ItemService.destroy(item)
		end
	end
	bot.Cargo = {}
	local paid = if count > 0 then BotEconomy.sell(bot.State, total) else 0
	if count > 0 then
		bot.Stats.Coins += paid
		bot.Stats.Items += count
		bot.Stats.Trips += 1
		if bot.Cycle then
			bot.Cycle.Coins += paid
			bot.Cycle.Items += count
			bot.Cycle.Trips += 1
			for zone, z in zones do
				local entry = bot.Cycle.Zones[tostring(zone)] or { Items = 0, Value = 0 }
				entry.Items += z.Items
				entry.Value += z.Value
				bot.Cycle.Zones[tostring(zone)] = entry
			end
		end
		if bot.Trip then
			bot.Trip.Earned = (bot.Trip.Earned or 0) + paid
			bot.Trip.Items = (bot.Trip.Items or 0) + count
		end
	end
	return count
end

local function shopVisit(bot: Bot)
	-- One thing at a time, a moment each, like the shopkeeper's screen.
	local function step()
		local state = bot.State
		if BotEconomy.canRebirth(state) then
			setStatus(bot, "buying a rebirth")
			later(bot, 1.2, function()
				local pick = BotEconomy.rebirth(state)
				bot.Stats.Rebirths += 1
				bot.Stats.LastPick = pick
				makeCart(bot)
				setStatus(bot, "buying a rebirth")
				step()
			end)
			return
		end
		local purchase = BotEconomy.nextPurchase(state)
		if purchase then
			setStatus(bot, "buying " .. purchase.Name)
			later(bot, 1, function()
				if BotEconomy.buy(state, purchase) then
					bot.Stats.Purchases += 1
					if purchase.Category == "Vessel" then
						makeCart(bot)
					end
				end
				step()
			end)
			return
		end
		bot.Mode = nil
		decide(bot)
	end
	step()
end

local function arrive(bot: Bot)
	local mode = bot.Mode
	bot.Path = nil
	if mode == "ToItem" then
		local item = bot.Target
		bot.Target = nil
		if not item or not ItemService.isItem(item) or ItemService.getState(item) ~= "Unclaimed" then
			bot.Mode = nil
			return
		end
		local tool = BotEconomy.tool(bot.State)
		local from = Vector3.new(bot.X, item.Position.Y, bot.Z)
		local ok, reason =
			GrabService.canClaim(item, bot.OwnerId, tool, BotEconomy.lift(bot.State, tool), from)
		if not ok then
			if reason == "Too far away" and not bot.Reapproached then
				-- Stopped short of it: step right up to it.
				bot.Reapproached = true
				local path = routeTo(bot, item.Position.X, item.Position.Z, 0)
				if path then
					bot.Target = item
					beginPath(bot, path, "ToItem")
					return
				end
			end
			bot.Skip[item] = now() + 20 / speedFactor
			bot.Mode = nil
			return
		end
		if not ItemService.claimForBot(item, bot.OwnerId) then
			bot.Mode = nil
			return
		end
		bot.Mode = "Claiming"
		later(bot, 0.5, function()
			-- Into the cart (or the hands).
			table.insert(bot.Cargo, item)
			if bot.Cart then
				ItemService.setInCart(item, bot.CartVessel, bot.OwnerId)
			end
			bot.GroundY = Beach.groundAt(bot.X, bot.Z)
			placeCart(bot)
			later(bot, 0.4, function()
				bot.Mode = nil
			end)
		end)
	elseif mode == "Home" then
		bot.Mode = "Selling"
		local count = #bot.Cargo
		if count > 0 then
			setStatus(bot, "selling")
		end
		later(bot, if count > 0 then 1 + 0.3 * count else 0.2, function()
			sell(bot)
			if bot.Trip and bot.Trip.Items then
				bot.Finished = true
				bot.Trip.Done = true
				bot.Trip.EndedAt = now()
				bot.Mode = nil
				setStatus(bot, "waiting for the tide")
				return
			end
			if BotEconomy.canRebirth(bot.State) or BotEconomy.nextPurchase(bot.State) then
				-- To the shopkeeper.
				local path = { { x = bot.X, z = bot.Z }, { x = SHOP.x, z = SHOP.z } }
				setStatus(bot, "walking out")
				beginPath(bot, path, "Shop")
				return
			end
			bot.Mode = nil
		end)
	elseif mode == "Shop" then
		bot.Mode = "Shopping"
		shopVisit(bot)
	else
		bot.Mode = nil
	end
end

-- The per-frame step ------------------------------------------------------------------------

local function stepBot(bot: Bot, dt: number, sea: Tide.Sea, t: number, budget: { number })
	if bot.After then
		if t >= bot.WaitUntil then
			local fn = bot.After
			bot.After = nil
			fn()
		end
		if bot.Status == "waiting for the tide" then
			bot.Stats.IdleSeconds += dt
		end
		return
	end
	if bot.Path then
		local arrived, moved = advance(bot, dt, sea)
		bot.GroundY = Beach.groundAt(bot.X, bot.Z)
		-- The sea.
		local depth = Beach.waterYAt(sea, bot.X) - bot.GroundY
		if depth >= Config.Beach.WaistDepth and bot.Z > 0 then
			die(bot)
			return
		end
		if moved then
			setCFrame(bot, bot.GroundY)
			placeCart(bot)
		end
		-- Someone else got there first?
		local target = bot.Target
		if target and bot.Mode == "ToItem" then
			local state = if ItemService.isItem(target) then ItemService.getState(target) else "Gone"
			if state ~= "Unclaimed" then
				local owner = if state == "Gone" then 0 else ItemService.getOwnerId(target)
				bot.Path, bot.Target, bot.Mode = nil, nil, nil
				if owner < 0 and owner ~= bot.OwnerId then
					bot.Stats.LostToBot += 1
					setStatus(bot, string.format("lost item to Bot %d", -owner))
					later(bot, 1.5, function() end)
				else
					bot.Stats.LostOther += 1
				end
				return
			end
		end
		if arrived then
			arrive(bot)
		end
		return
	end
	if bot.Mode == nil then
		if bot.StuckUntil and t < bot.StuckUntil then
			return
		end
		if budget[1] > 0 then
			budget[1] -= 1
			decide(bot)
		end
		if bot.Status == "waiting for the tide" then
			bot.Stats.IdleSeconds += dt
		end
	end
end

local function onFrame(dt: number)
	local t = now()
	dt = math.min(dt, 0.1)
	if t - lastRefresh > 2 then
		lastRefresh = t
		grid:refresh()
	end
	local cycle = Tide.getState(t).Cycle
	if cycle ~= lastCycle then
		for _, bot in bots do
			flushCycle(bot, false)
			newCycle(bot, cycle)
		end
		lastCycle = cycle
	end
	local sea = Tide.sea(t)
	local budget = { 1 }
	for _, bot in bots do
		local ok, err = pcall(stepBot, bot, dt, sea, t, budget)
		if not ok then
			warn("[BotService] bot " .. bot.Id .. " errored: " .. tostring(err))
			bot.Path, bot.Target, bot.Mode, bot.After = nil, nil, nil, nil
			bot.StuckUntil = t + 2
		end
	end
end

-- Spawning -------------------------------------------------------------------------------

local function spawnBot(id: number, state: any, trip: any): Bot
	local entry = BotService.Colors[id]
	local bot: Bot = {
		Id = id,
		OwnerId = -id,
		ColorName = entry[1],
		Color = entry[2],
		State = state or BotEconomy.newState(),
		Cargo = {},
		Skip = {},
		Stats = {
			Coins = 0,
			Items = 0,
			Trips = 0,
			LostToBot = 0,
			LostOther = 0,
			IdleSeconds = 0,
			Deaths = 0,
			LostLoads = 0,
			LostItems = 0,
			Purchases = 0,
			Rebirths = 0,
		},
		Trip = trip,
		DirX = 0,
		DirZ = 1,
		StartedAt = now(),
		StartSpeed = speedFactor,
	}
	bot.X = HOME.x + ((id - 1) % 5 - 2) * 6
	bot.Z = HOME.z + ((id - 1) // 5 - 1.5) * 5
	bot.GroundY = Beach.groundAt(bot.X, bot.Z)
	bot.LaneX = rng:NextNumber(-Beach.HalfWidth + 60, Beach.HalfWidth - 60)
	dropTrail(bot)
	bot.Model = buildMan(bot)
	CollectionService:AddTag(bot.Model, BotService.Tag)
	bot.Model.Parent = botFolder
	setCFrame(bot, bot.GroundY)
	makeCart(bot)
	setStatus(bot, "waiting for the tide")
	bots[id] = bot
	newCycle(bot, if lastCycle >= 0 then lastCycle else Tide.getState().Cycle)
	return bot
end

local function releaseCargo(bot: Bot)
	for _, item in bot.Cargo do
		if ItemService.isItem(item) then
			ItemService.setUnclaimed(item, true)
			ItemService.dropToGround(item)
		end
	end
	bot.Cargo = {}
	local target = bot.Target
	bot.Target = nil
	return target
end

local function despawnBot(bot: Bot)
	flushCycle(bot, true)
	releaseCargo(bot)
	destroyCart(bot)
	bot.Model:Destroy()
	bots[bot.Id] = nil
end

local function ensureRunning()
	if running then
		return
	end
	running = true
	grid = grid or Routes.new()
	grid:refresh()
	if not botFolder then
		botFolder = Instance.new("Folder")
		botFolder.Name = "Bots"
		botFolder.Parent = Workspace
	end
	lastCycle = Tide.getState().Cycle
	startedAt = now()
	connection = RunService.Heartbeat:Connect(onFrame)
end

-- Public ---------------------------------------------------------------------------------

function BotService.count(): number
	local n = 0
	for _ in bots do
		n += 1
	end
	return n
end

function BotService.isRunning(): boolean
	return running
end

-- Runs the whole game faster by one factor: the tide, item spawns and lifetimes, and the bots'
-- walking and delays (the sweep's --speed). 1 restores the real game.
function BotService.setSpeed(factor: number)
	assert(factor > 0, "speed must be positive")
	if not originals then
		originals = {
			SpawnInterval = Config.Items.SpawnInterval,
			FreshLifetime = Config.Items.FreshLifetime,
			TimedOutLifetime = Config.Items.TimedOutLifetime,
			LooseTimeout = Config.Items.LooseTimeout,
		}
	end
	for key, value in originals do
		Config.Items[key] = value / factor
	end
	-- The tide keeps its place while it changes speed (as the admin console's tidespeed does).
	local state = Tide.getState()
	Workspace:SetAttribute(Tide.ScaleAttribute, 1 / factor * Config.Tide.TimeScale)
	Workspace:SetAttribute(Tide.StartAttribute, Tide.startFor(state.Phase, state.PhaseProgress))
	speedFactor = factor
end

function BotService.speed(): number
	return speedFactor
end

-- Makes `n` bots play (adding or removing the highest numbers), 0 to 20.
function BotService.setCount(n: number)
	n = math.clamp(math.floor(n), 0, BotService.MaxBots)
	if n > 0 then
		ensureRunning()
	end
	for id = 1, n do
		if not bots[id] then
			spawnBot(id, nil, nil)
		end
	end
	for id = BotService.MaxBots, n + 1, -1 do
		if bots[id] then
			despawnBot(bots[id])
		end
	end
	if n == 0 then
		BotService.stop()
	end
end

-- One bot on a single trip to zone `zone` and back, with fixed gear (the sweep's --final-trip):
-- it sells once and is done. Returns the bot.
function BotService.startTrip(zone: number, toolId: string, vesselId: string): Bot
	ensureRunning()
	local state = BotEconomy.newState()
	state.Tools[toolId] = true
	state.Vessels[vesselId] = true
	tripResult = { Zone = zone, Tool = toolId, Vessel = vesselId, StartedAt = now() }
	return spawnBot(1, state, tripResult)
end

function BotService.tripResult()
	return tripResult
end

function BotService.stop()
	for _, bot in table.clone(bots) do
		despawnBot(bot)
	end
	if connection then
		connection:Disconnect()
		connection = nil
	end
	running = false
	if botFolder then
		botFolder:Destroy()
		botFolder = nil
	end
end

-- Reports ---------------------------------------------------------------------------------

-- Per-bot and total measures, in game time (the sweep's speed factor is taken out).
function BotService.snapshot()
	local list = {}
	local t = now()
	for id = 1, BotService.MaxBots do
		local bot = bots[id]
		if bot then
			local seconds = (t - bot.StartedAt) * bot.StartSpeed
			local s = bot.Stats
			table.insert(list, {
				Bot = id,
				Color = bot.ColorName,
				GameSeconds = seconds,
				Coins = s.Coins,
				Items = s.Items,
				Trips = s.Trips,
				LostToBot = s.LostToBot,
				LostOther = s.LostOther,
				IdleGameSeconds = s.IdleSeconds * bot.StartSpeed,
				Deaths = s.Deaths,
				LostLoads = s.LostLoads,
				LostItems = s.LostItems,
				Purchases = s.Purchases,
				Rebirths = bot.State.Rebirths,
				Purse = bot.State.Coins,
				Gear = gearSnapshot(bot),
			})
		end
	end
	return {
		Bots = list,
		Server = table.clone(ItemService.stats),
		Speed = speedFactor,
		BotCount = #list,
	}
end

function BotService.incomeLog()
	return incomeLog
end

-- Closes the open tides in the income log (the sweep calls this before it reads the log).
function BotService.closeLog()
	for _, bot in bots do
		flushCycle(bot, true)
		newCycle(bot, lastCycle)
	end
end

function BotService.clearLog()
	incomeLog = {}
	ItemService.resetStats()
	tripResult = nil
end

-- Text lines for `bots report`.
function BotService.report(): { string }
	local snap = BotService.snapshot()
	local lines = {
		string.format("Bots: %d, speed x%.0f. Rates are per hour of game time.", snap.BotCount, snap.Speed),
		"bot  colour    coins/h   items/h  trips  lost-to-bot  lost-other  idle%  deaths  lost-loads  gear",
	}
	local total = {
		Coins = 0,
		Items = 0,
		Trips = 0,
		LostToBot = 0,
		LostOther = 0,
		Idle = 0,
		Deaths = 0,
		LostLoads = 0,
		Hours = 0,
	}
	for _, b in snap.Bots do
		local hours = math.max(b.GameSeconds, 1) / 3600
		total.Coins += b.Coins
		total.Items += b.Items
		total.Trips += b.Trips
		total.LostToBot += b.LostToBot
		total.LostOther += b.LostOther
		total.Idle += b.IdleGameSeconds
		total.Deaths += b.Deaths
		total.LostLoads += b.LostLoads
		total.Hours += hours
		table.insert(
			lines,
			string.format(
				"%-4d %-9s %-9s %-8.0f %-6d %-12d %-11d %-6.0f %-7d %-11d %s + %s, %d rebirth(s)",
				b.Bot,
				b.Color,
				commas(b.Coins / hours),
				b.Items / hours,
				b.Trips,
				b.LostToBot,
				b.LostOther,
				b.IdleGameSeconds / math.max(b.GameSeconds, 1) * 100,
				b.Deaths,
				b.LostLoads,
				b.Gear.Tool,
				b.Gear.Vessel or "hands",
				b.Gear.Rebirths
			)
		)
	end
	if snap.BotCount > 0 then
		local n = snap.BotCount
		table.insert(
			lines,
			string.format(
				"all  total     %-9s %-8.0f %-6d %-12d %-11d %-6.0f %-7d %-11d (per bot: %s coins/h)",
				commas(total.Coins / (total.Hours / n)),
				total.Items / (total.Hours / n),
				total.Trips,
				total.LostToBot,
				total.LostOther,
				total.Idle / math.max(total.Hours * 3600, 1) * 100,
				total.Deaths,
				total.LostLoads,
				commas(total.Coins / math.max(total.Hours, 1e-9))
			)
		)
	end
	local s = snap.Server
	table.insert(
		lines,
		string.format(
			"Server: %d surf items spawned (+%d at loot spots), %d claimed (%d by bots), %d despawned unclaimed, surf full on %d of %d spawn ticks",
			s.SurfSpawned,
			s.SpotSpawned,
			s.Claimed,
			s.ClaimedByBots,
			s.Despawned,
			s.SurfFullTicks,
			s.SpawnTicks
		)
	)
	return lines
end

return BotService
