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
--     (the player's rules: reach, and the zone tier its tool lifts) must allow it; ItemService.claimForBot
--     then takes it atomically, so whoever arrives first gets it. Bots and players share the
--     surf, the loot spots and the despawn timers. Bots own negative ids, never a UserId.
--   * Money is the game's: ShopService.payout (Value x zone x rebirth multiplier), ShopService
--     .listing and Gear's price lists, Rebirth.cost. A bot's coins, gear and rebirths live in
--     BotEconomy.State in memory; nothing here touches DataService or a DataStore.
--   * One rule for every bot (BotEconomy): rebirth as soon as it can be afforded, taking the
--     reward that raises income most; otherwise buy what raises income most for its price. It
--     goes for the item with the best value for the time it costs (there and back), among what
--     its tool can reach and lift (every item up to the tool's tier, at any depth the bot can
--     stand in), whose way back the tide won't cut. It heads home when its
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
local Items = require(Shared.Items)
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
local DEPTH_MARGIN = 1.0 -- routes keep this far short of waist depth (deeper drowns, and wading is slow)
local SAFE_SPEED = 0.7 -- routes assume the bot walks this much of its speed (wading, corners)
local LOOSE_MARGIN, LOOSE_SPEED = 0.3, 0.85 -- the second try, when no route keeps the full margins
-- A bot only sets out for an item (or on) if the way home would still be open this many game seconds
-- after it got there; more once the sea is coming in, and more again with a load.
local TIDE_SLACK = 40

type Bot = any

local bots: { [number]: Bot } = {}
local running = false
local connection: RBXScriptConnection? = nil
local grid: any = nil
local botFolder: Folder? = nil
local speedFactor = 1
local originals: any = nil
local incomeLog: { any } = {}
local lastCycle = -1
local lastRefresh = 0
local startedAt = 0
local nodesBase = { Search = 0, Field = 0 }
local searchStats = {
	DrySkipped = 0,
	Decisions = 0,
	NoCandidates = 0,
	NoRoute = 0,
	Closed = 0,
	Chosen = 0,
	WaterTaken = 0,
	WaterSkipped = 0,
	HomeFull = 0, -- bots that set off home with a full cart
	HomeTide = 0, -- ... with free slots, because the tide forced it
	SandNoPlan = 0, -- decisions of tier 7 bots with no sandbar plan (no window, or no way)
	SandShort = 0, -- ... with a window too short for a useful stay
	SandWaiting = 0, -- ... with a useful stay once the channel opens
	SandOpen = 0, -- ... with the channel open and a useful stay
	HomeNothing = 0, -- ... with free slots, because nothing more was worth waiting for
} -- what became of the item searches, and why bots set off home
local tripResult: any = nil
local cycleBase = 0 -- tide cycles before this server clock's (a chained sweep carries the game over)
local moved: { any } = {} -- bots put somewhere safe when a carried-over game was imported
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
	local cframe
	if bot.Parked then
		-- (Left at the channel's shore side while the bot works the sandbar on foot.)
		cframe = bot.Parked.CFrame
		local hands = bot.Hands
		if hands then
			hands.CFrame = CFrame.new(bot.X + bot.DirX * 1.6, bot.GroundY + 3.8, bot.Z + bot.DirZ * 1.6)
		end
	else
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
		cframe = CFrame.lookAt(
			Vector3.new(cx, groundY, cz),
			Vector3.new(cx + dx / length, groundY, cz + dz / length)
		)
		-- (the cart's handle is at -Z: it faces the bot)
		bot.Cart:PivotTo(cframe)
	end
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

-- The cart a bot's routes must fit: its vessel's size, or none (on foot) while it is on a sandbar
-- shuttle, its cart parked at the channel's shore side (wheeled carts can't climb the channel's banks).
local function cartOf(bot: Bot): string?
	if bot.Foot then
		return nil
	end
	return BotEconomy.cartSize(bot.State)
end

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

-- Time slicing: route searches run in the bot's own thread and give the frame back once all bots
-- together have used FRAME_BUDGET seconds of it, so thinking never stalls the server.
local FRAME_BUDGET = 0.003
local frameUsed = 0
local lastMark = 0

local function mark()
	local t = os.clock()
	frameUsed += t - lastMark
	lastMark = t
end

local function yieldFor(bot: Bot): () -> ()
	return function()
		mark()
		-- (A bot with a load to get home gets more of the frame.)
		while frameUsed > FRAME_BUDGET * (if #bot.Cargo > 0 then 3 else 1) do
			task.wait()
			if bot.Gone or not running then
				error("bot gone")
			end
			lastMark = os.clock()
		end
	end
end

-- How many node expansions a search over this distance may take before it is given up as hopeless.
local function nodeBound(ax: number, az: number, bx: number, bz: number, generous: boolean?): number
	local cells = math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2) / Routes.STEP
	if generous then
		return math.clamp(math.floor(2000 + 150 * cells), 2000, 150000)
	end
	return math.clamp(math.floor(2000 + 40 * cells), 2000, 30000)
end

-- A route from the bot's spot to (x, z), through the shop's flat ground at either end. Nil if
-- there's no way that the sea won't cut. `safe` false stops looking at the tide.
local function routeTo(
	bot: Bot,
	x: number,
	z: number,
	radius: number?,
	from: { x: number, z: number }?,
	delay: number?,
	loose: boolean?,
	ignoreTide: boolean?
): ({ any }?, number?)
	local start = from or { x = bot.X, z = bot.Z }
	-- (A trip bot is a measurement of what one trip can earn, at the pace the tide allows: it
	-- plans with the second try's margins, which the zone 6 round trip needs.)
	loose = loose or bot.Trip ~= nil
	local speed = BotEconomy.walkSpeed(bot.State) * speedFactor * (if loose then LOOSE_SPEED else SAFE_SPEED)
	local cart = cartOf(bot)
	local limit = Config.Beach.WaistDepth - (if loose then LOOSE_MARGIN else DEPTH_MARGIN)
	local options = {
		slope = if cart then Config.Beach.Terrain.CartSlope else Config.Beach.Terrain.FootSlope,
		cart = cart,
		blocked = if ignoreTide then nil else waterBlocker(speed, limit, delay or 0),
		radius = radius,
		maxNodes = nodeBound(start.x, start.z, x, z, bot.Trip ~= nil),
		weight = if bot.Trip then nil else 1.5,
		yield = yieldFor(bot),
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

-- The way out from the sell pad to a point is the way home from it, walked the other way: no
-- search needed (the field already knows it, for this kind of walker).
local function reverseOf(bot: Bot, entry: any, x: number, z: number): ({ any }?, number?)
	local path = entry.Field:path(x, math.max(z, 0))
	if not path then
		return nil, nil
	end
	local out = {}
	if bot.Z < 0 then
		table.insert(out, { x = bot.X, z = bot.Z })
	end
	for i = #path, 1, -1 do
		table.insert(out, path[i])
	end
	if z < 0 then
		table.insert(out, { x = x, z = z })
	end
	return out, entry.Field:distance(x, math.max(z, 0))
end

local function beginPath(bot: Bot, path: { any }, mode: string)
	bot.Path = path
	bot.Index = 2
	bot.Mode = mode
	if path[1] and (path[1].x ~= bot.X or path[1].z ~= bot.Z) then
		bot.Index = 1
	end
end

-- The way home, as fields ----------------------------------------------------------------

-- One flood from the sell pad outward over the route grid gives, for every cell, how far the way
-- home is, the way itself, and the latest moment a walker may be there and still get home before the
-- sea closes the way (Routes.buildField). It is built once for each kind of walker (on foot, or with
-- a cart of a size) and answers every "is the way back open" and "how far home" by lookup, so a
-- bot's thinking is one search to its chosen item rather than a handful of searches.
local FIELD_SAMPLE = 2 -- game seconds between samples of the sea
local fields: { [string]: any } = {}
local building: { [string]: boolean } = {}

-- When the sea is at a cell's depth limit, in seconds from t0, from the tide's own curve: the
-- waterline at a column is the shared waterline a lag earlier, and a cell is too deep once the
-- waterline falls to (ground + limit) / -slope.
local function makeClosing(t0: number, limit: number)
	local dt = FIELD_SAMPLE / speedFactor
	local n = math.floor(2 * BotEconomy.CycleSeconds / FIELD_SAMPLE)
	local pad = 24
	local base: { [number]: number } = {}
	for i = -pad, n + pad do
		base[i] = Tide.waterline(t0 + i * dt)
	end
	-- Per column: the waterline at each sample from now (raw), its running minimum (pmin), the end
	-- of its rising stretch (peak) and of the falling stretch after that (trough).
	local columns: { [number]: any } = {}
	local slope = Config.Beach.Slope
	local function column(x: number)
		local lag = math.clamp(math.floor(Tide.lagAt(x, t0) / dt + 0.5), -pad, pad)
		local raw, pmin = table.create(n + 1), table.create(n + 1)
		local lowest = math.huge
		for i = 0, n do
			local value = base[i - lag]
			raw[i + 1] = value
			lowest = math.min(lowest, value)
			pmin[i + 1] = lowest
		end
		-- (The tide's curve can wobble a little on its way, so the peak is the highest the sea gets
		-- in the next cycle, and the trough the lowest after it.)
		local cycle = math.floor(BotEconomy.CycleSeconds / FIELD_SAMPLE)
		local peak = 0
		for i = 0, math.min(cycle, n) do
			if raw[i + 1] >= raw[peak + 1] then
				peak = i
			end
		end
		local trough = peak
		for i = peak, math.min(peak + cycle, n) do
			if raw[i + 1] <= raw[trough + 1] then
				trough = i
			end
		end
		return { Raw = raw, Min = pmin, Peak = peak, Trough = trough }
	end
	return function(x: number, _z: number, ground: number): number
		local col = columns[x]
		if not col then
			col = column(x)
			columns[x] = col
		end
		-- Too deep once the waterline has fallen to this.
		local critical = -(ground + limit) / slope
		local raw, pmin = col.Raw, col.Min
		if pmin[1] > critical then
			-- Dry enough now: closes when the waterline first falls that far.
			if pmin[n + 1] > critical then
				return 1e6
			end
			local lo, hi = 1, n + 1 -- pmin[lo] > critical >= pmin[hi]
			while hi - lo > 1 do
				local mid = (lo + hi) // 2
				if pmin[mid] <= critical then
					hi = mid
				else
					lo = mid
				end
			end
			return (hi - 1) * dt
		end
		-- Too deep now. If the sea is on its way out it reopens (the bot can be there once it has),
		-- and closes again as the tide turns; if it is coming in, it stays closed.
		local peak, trough = col.Peak, col.Trough
		if raw[peak + 1] <= critical then
			return 0
		end
		if raw[trough + 1] > critical then
			return 1e6
		end
		local lo, hi = peak + 1, trough + 1 -- raw[lo] > critical >= raw[hi], falling
		while hi - lo > 1 do
			local mid = (lo + hi) // 2
			if raw[mid] <= critical then
				hi = mid
			else
				lo = mid
			end
		end
		return (hi - 1) * dt
	end
end

BotService._closing = makeClosing -- for tools/tests

local function fieldKey(cart: string?, loose: boolean): string
	return (cart or "foot") .. (if loose then ":trip" else "")
end

local function buildFieldFor(cart: string?, loose: boolean, urgent: boolean?)
	local key = fieldKey(cart, loose)
	if building[key] then
		return
	end
	building[key] = true
	local worker = { Cargo = {}, Gone = false }
	local function run()
		local t0 = now()
		local version = grid.version
		local speed = BotEconomy.WalkSpeed * speedFactor * (if loose then LOOSE_SPEED else SAFE_SPEED)
		local limit = Config.Beach.WaistDepth - (if loose then LOOSE_MARGIN else DEPTH_MARGIN)
		local yieldNow = if urgent
			then function()
				-- (Warm-up, before bots play: take big slices.)
				if os.clock() - lastMark > 0.02 then
					task.wait()
					lastMark = os.clock()
				end
			end
			else yieldFor(worker)
		local field = grid:buildField({
			goals = { { x = HOME.x, z = 0 } },
			goalRadius = 8,
			speed = speed,
			slope = if cart then Config.Beach.Terrain.CartSlope else Config.Beach.Terrain.FootSlope,
			cart = cart,
			closing = makeClosing(t0, limit),
			yield = yieldNow,
		})
		fields[key] = { Field = field, T0 = t0, Version = version }
	end
	local ok, err = pcall(run)
	building[key] = false
	if not ok and not string.find(tostring(err), "bot gone", 1, true) then
		warn("[BotService] building the way-home field failed: " .. tostring(err))
	end
end

-- The field for a bot's kind of walker, built (and rebuilt when the layouts changed, or it is old
-- enough that its picture of the sea runs short) in a thread of its own; the caller waits, in its
-- own thread, until there is one.
local function ensureField(bot: Bot, onFoot: boolean?)
	local cart = if onFoot then nil else cartOf(bot)
	local loose = bot.Trip ~= nil
	local key = fieldKey(cart, loose)
	local entry = fields[key]
	local stale = entry
		and (entry.Version ~= grid.version or now() - entry.T0 > 0.8 * BotEconomy.CycleSeconds / speedFactor)
	if (not entry or stale) and not building[key] then
		task.spawn(buildFieldFor, cart, loose)
	end
	while not fields[key] do
		task.wait()
		if bot.Gone or not running then
			error("bot gone")
		end
	end
	return fields[key]
end

-- Whether a walker at (x, z) can still get home if it sets out `delay` seconds from now.
local function wayHomeOpen(entry: any, x: number, z: number, delay: number): boolean
	local slack = entry.Field:slack(x, math.max(z, 0))
	return slack ~= nil and slack >= now() - entry.T0 + delay
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

local function goHome(bot: Bot): boolean
	local entry = ensureField(bot)
	local path = entry.Field:path(bot.X, math.max(bot.Z, 0))
	if path then
		if bot.Z < 0 then
			table.insert(path, 1, { x = bot.X, z = bot.Z })
		end
		table.insert(path, { x = HOME.x, z = HOME.z })
	else
		-- Walled in from the field's point of view: the plain shortest way, if any.
		local cart = cartOf(bot)
		path = grid:find({ x = bot.X, z = math.max(bot.Z, 0) }, { x = HOME.x, z = 0 }, {
			slope = if cart then Config.Beach.Terrain.CartSlope else Config.Beach.Terrain.FootSlope,
			cart = cart,
			radius = 6,
			maxNodes = nodeBound(bot.X, bot.Z, HOME.x, 0),
			yield = yieldFor(bot),
		})
		if path then
			table.insert(path, { x = HOME.x, z = HOME.z })
		end
	end
	if not path then
		bot.StuckUntil = now() + 1
		return false
	end
	setStatus(bot, if #bot.Cargo > 0 then "hauling back" else "waiting for the tide")
	beginPath(bot, path, "Home")
	return true
end

-- Sets off home with a load, and counts why: the mean load (items over capacity) when setting off,
-- and, server-wide, whether the cart was full, the tide forced it, or nothing more was worth
-- waiting for.
local function setOffHome(bot: Bot, reason: string)
	local count = #bot.Cargo
	if goHome(bot) and count > 0 then
		bot.Stats.HomeTrips += 1
		bot.Stats.HomeLoad += count / BotEconomy.capacity(bot.State)
		local key = "Home" .. reason
		searchStats[key] = (searchStats[key] or 0) + 1
	end
end

-- A bot's own stretch of the beach along X: the width is split between the bots present, in
-- order of their numbers, so it is re-split whenever bots join or leave.
local function stretchOf(bot: Bot): (number, number)
	local ids = {}
	for id in bots do
		table.insert(ids, id)
	end
	table.sort(ids)
	local rank = table.find(ids, bot.Id) or 1
	local n = math.max(#ids, 1)
	local edge = Beach.HalfWidth - 30
	local width = 2 * edge / n
	return -edge + (rank - 1) * width, -edge + rank * width
end

-- Whether another bot is already heading for an item (a soft claim: ItemService knows nothing of it).
local function reservedItems(bot: Bot): { [BasePart]: boolean }
	local set = {}
	for _, other in bots do
		if other ~= bot and other.Target then
			set[other.Target] = true
		end
	end
	return set
end

-- Real seconds of slack to leave the way home: more while the sea is coming in, more with a load.
local function tideSlack(bot: Bot): number
	if bot.Trip then
		return 0
	end
	local game = TIDE_SLACK
	if Tide.getState(now()).Phase == "In" then
		game *= 2
	end
	if #bot.Cargo > 0 or bot.Hands then
		game *= 1.5
	end
	return game / speedFactor
end

-- The Far Sandbar ------------------------------------------------------------------------------

-- Zone 7 lies across a channel that is only shallow enough to cross for a while around low tide. A
-- tier 7 bot plans for that window: it waits at the zone 6 edge until the channel opens, crosses,
-- works, and leaves with margin so it is back across before the channel deepens again.
local SAND_MIN_STAY = 60 -- game seconds on the sandbar that make a trip worth the crossing
local SAND_LEAD = 90 -- game seconds spare, over the walk to its bank, that a bot gives up other work and follows the tide there
local SAND_BANK = 12 -- studs short of the channel where a bot waits for it to open
local SAND_SAMPLE = 5 -- game seconds between samples of the channel's depth
local channelCache: { [number]: { At: number, Start: number, Opens: number? } } = {}

-- When the channel at X is next shallow enough to cross (water no deeper than the bots' route limit
-- at its deepest point): an absolute time, now if it is already, nil if not within a cycle.
local function channelOpens(x: number): number?
	local bucket = math.floor(x / 40)
	local t = now()
	local hit = channelCache[bucket]
	if hit and hit.Start == Tide.cycleStart() and t - hit.At < 20 / speedFactor then
		return hit.Opens
	end
	local sandbar = Config.Beach.FarSandbar
	local lowest = math.huge
	for z = sandbar.ChannelStart, sandbar.ChannelEnd, 4 do
		lowest = math.min(lowest, Beach.groundAt(x, z))
	end
	local limit = Config.Beach.WaistDepth - DEPTH_MARGIN
	local opens = nil
	local dt = SAND_SAMPLE / speedFactor
	for i = 0, math.floor(1.1 * BotEconomy.CycleSeconds / SAND_SAMPLE) do
		local at = t + i * dt
		if Beach.waterYAt(Tide.sea(at), x) - lowest <= limit then
			opens = at
			break
		end
	end
	channelCache[bucket] = { At = t, Start = Tide.cycleStart(), Opens = opens }
	return opens
end

export type SandbarPlan = {
	Opens: number, -- real seconds from now until the channel is shallow enough (0: it is)
	Arrive: number, -- ... until the bot could be across
	LeaveBy: number, -- ... until the latest moment it may start back (the way home's deadline less margin)
	Stay: number, -- real seconds it could work over there
	ToBank: number, -- ... for it to walk to the channel's shore side
	BankZ: number,
	X: number,
	Feasible: boolean, -- a stay of SAND_MIN_STAY game seconds fits
}

-- The plan for a sandbar trip from (fromX, fromZ), or nil if the bot's tool doesn't work zone 7 or
-- there is no window. `entry` is the way-home field's entry: its slack at the sandbar's near edge
-- is the latest moment the bot may be there and still get home across the channel.
local function sandbarPlan(
	state: any,
	entry: any,
	fromX: number,
	fromZ: number,
	cartEntry: any?
): SandbarPlan?
	local zone = Beach.FarSandbarZone
	if BotEconomy.lift(state, BotEconomy.tool(state)) < zone then
		return nil
	end
	local sandbar = Config.Beach.FarSandbar
	local t = now()
	local x = math.clamp(fromX, -(Beach.HalfWidth - 30), Beach.HalfWidth - 30)
	local opensAt = channelOpens(x)
	if not opensAt then
		return nil
	end
	local slack = entry.Field:slack(x, sandbar.ChannelEnd + 8)
	if not slack then
		return nil
	end
	local speed = BotEconomy.walkSpeed(state) * speedFactor * SAFE_SPEED
	local bankZ = sandbar.ChannelStart - SAND_BANK
	-- (The way out is dry ground ahead of the tide, not the slow wade the other plans assume.)
	local bankSpeed = BotEconomy.walkSpeed(state) * speedFactor * 0.9
	local toBank = math.max(bankZ - fromZ, 0) * BotEconomy.MazeFactor / bankSpeed
	if cartEntry then
		-- (A cart goes by the zones' paths, which are longer than the straight line: the cart field's
		-- way home from the bank, less the bot's own, is the walk there.)
		local dBank = cartEntry.Field:distance(x, bankZ)
		local dBot = cartEntry.Field:distance(fromX, math.max(fromZ, 0))
		if dBank and dBot then
			toBank = math.max(dBank - dBot, 0) / bankSpeed
		end
	end
	local crossing = (sandbar.ChannelEnd - sandbar.ChannelStart + 16) / speed
	local arrive = math.max(t + toBank, opensAt) + crossing
	local leaveBy = entry.T0 + slack - TIDE_SLACK * 1.5 / speedFactor
	local stay = leaveBy - arrive
	return {
		Opens = if opensAt - t < 1 / speedFactor then 0 else opensAt - t, -- (a second off is open)
		Arrive = arrive - t,
		LeaveBy = leaveBy - t,
		Stay = stay,
		ToBank = toBank,
		BankZ = bankZ,
		X = x,
		Feasible = stay >= SAND_MIN_STAY / speedFactor,
	}
end
BotService.sandbarPlan = sandbarPlan -- for tools/tests

-- Items worth a look: free, not reserved by another bot, of a zone tier the tool lifts, not ones we
-- gave up on, and for a trip bot only in its zone. Scored by value per second
-- of the walk there and on home. Those in the bot's own stretch come first; the rest only when
-- the stretch has nothing it can take (a bot with no cart, carrying one thing at a time, keeps to
-- short trips then).
-- The least share of the best finds' average value (for the cart's free slots) worth taking up a
-- slot for (BotService.candidates).
local SLOT_FLOOR = 0.3
local SAMPLE_ITEMS = 8 -- free items per zone looked at for the share with a safe approach

local function candidates(bot: Bot, entry: any, relaxed: boolean?): ({ any }, { any })
	local lift = BotEconomy.lift(bot.State, BotEconomy.tool(bot.State))
	local speed = BotEconomy.walkSpeed(bot.State) * speedFactor
	local sea = Tide.sea()
	local t = now()
	local lo, hi = stretchOf(bot)
	local hands = BotEconomy.cartSize(bot.State) == nil and BotEconomy.capacity(bot.State) == 1
	local mine, others = {}, {}
	local reserved = reservedItems(bot)
	-- Zone 7 only while a sandbar trip is on (the channel shallow, a useful stay fits).
	-- (A cart bot's plan is for its feet: it parks its cart at the channel and crosses alone.)
	local cartBot = BotEconomy.cartSize(bot.State) ~= nil
	local footEntry = if cartBot and not bot.Foot then ensureField(bot, true) else entry
	local plan =
		sandbarPlan(bot.State, footEntry, bot.X, bot.Z, if cartBot and not bot.Foot then entry else nil)
	bot.Plan = plan
	if BotEconomy.lift(bot.State, BotEconomy.tool(bot.State)) >= Beach.FarSandbarZone then
		local key = if not plan
			then "SandNoPlan"
			elseif not plan.Feasible then "SandShort"
			elseif plan.Opens > 0 then "SandWaiting"
			else "SandOpen"
		searchStats[key] += 1
	end
	local sandbarOpen = bot.Foot == true
		or (not cartBot and plan ~= nil and plan.Feasible and plan.Opens <= 0)
	local sandbarZone = Beach.FarSandbarZone
	local samples: { [number]: { any } } = {}
	for item in ItemService.all() do
		local zone = item:GetAttribute("Zone")
		if bot.Foot and zone ~= sandbarZone then
			continue -- (a shuttle is for the sandbar only)
		end
		if
			zone == sandbarZone
			and not sandbarOpen
			and ItemService.getState(item) == "Unclaimed"
			and Gear.canLift(lift, item:GetAttribute("Tier"))
		then
			-- (Not a candidate now, but a sample of what a trip would find.)
			local list = samples[zone] or {}
			samples[zone] = list
			if #list < SAMPLE_ITEMS then
				table.insert(list, item)
			end
			continue
		end
		if
			ItemService.getState(item) == "Unclaimed"
			and not item:GetAttribute("Unlock")
			and Gear.canLift(lift, item:GetAttribute("Tier"))
			and (not bot.Skip[item] or bot.Skip[item] < t)
			and (not bot.Trip or item:GetAttribute("Zone") == bot.Trip.Zone)
			and not reserved[item]
		then
			local position = item.Position
			local band = Beach.depthBand(position, sea)
			if not Beach.isLost(position, sea) then
				local there = math.sqrt((position.X - bot.X) ^ 2 + (position.Z - bot.Z) ^ 2)
					* BotEconomy.MazeFactor
					/ speed
				-- The way home from there, from the field: its length, and whether it stays open
				-- for the walk there, the lift, and a margin.
				local homeLength = entry.Field:distance(position.X, math.max(position.Z, 0))
				local back = if homeLength then homeLength / speed else math.huge
				-- What lies beyond the first zone (or in deeper water) is worth going anywhere
				-- along the beach for; the stretch is for the cheap finds of the first zone's shallows.
				local premium = (item:GetAttribute("Tier") or 1) >= 2 or band >= Gear.Depth.KneeDeep
				local list = samples[zone or 0] or {}
				samples[zone or 0] = list
				if #list < SAMPLE_ITEMS then
					table.insert(list, item)
				end
				local inStretch = premium or (position.X >= lo and position.X <= hi)
				-- Hands-only bots stay on short trips (200 game seconds there and back at most).
				if back < math.huge and (inStretch or not hands or (there + back) * speedFactor <= 200) then
					table.insert(if inStretch then mine else others, {
						Item = item,
						There = there,
						Score = (item:GetAttribute("Value") or 0) / (there + back + 2 / speedFactor),
					})
				end
			end
		end
	end
	-- A cart slot is worth something: skip what's worth much less than the best finds the free
	-- slots could hold, anywhere the bot can reach, or than a find in the best zone the tide will
	-- still uncover for its tool (so cheap things by the shore don't fill the cart on the way out
	-- to better ones, even before those have washed up).
	local free = math.max(1, BotEconomy.capacity(bot.State) - #bot.Cargo)
	local values = {}
	for _, list in { mine, others } do
		for _, entry in list do
			table.insert(values, entry.Item:GetAttribute("Value") or 0)
		end
	end
	table.sort(values, function(a, b)
		return a > b
	end)
	local sum, n = 0, math.min(free, #values)
	for i = 1, n do
		sum += values[i]
	end
	-- And what's still to come this tide: while the sea is going out (or low) every zone the
	-- tool works that the bot can work this tide will be uncovered, so a slot is worth a find from
	-- the best of them even before anything lies there; once it comes in, only the zones still
	-- uncovered count. A zone counts only if the bot can work it from where it is (zone 7: a
	-- crossing, a useful stay and the way back fit in the channel's window), and its find is
	-- weighted by the share of its free items that have a safe approach.
	local coming = BotService.comingValue(bot, entry, plan, samples, footEntry)
	bot.Coming = coming
	local floor = if relaxed then 0 else SLOT_FLOOR * math.max(if n > 0 then sum / n else 0, coming)
	local function worthASlot(list)
		local kept = {}
		for _, entry in list do
			if (entry.Item:GetAttribute("Value") or 0) >= floor then
				table.insert(kept, entry)
			end
		end
		return kept
	end
	mine, others = worthASlot(mine), worthASlot(others)
	local function byScore(a, b)
		return a.Score > b.Score
	end
	table.sort(mine, byScore)
	table.sort(others, byScore)
	return mine, others
end

-- Where to stand to claim an item: the nearest spot to the bot, within the tool's reach of the item,
-- that stays safe (the way home open, the water under the route limit) for `delay` seconds from
-- now (the walk there, the grab and load, and a margin), or nil if there is none. An item in the
-- water is claimed from the shore side of it, never by wading to it.
local function approachFor(
	entry: any,
	itemX: number,
	itemZ: number,
	reach: number,
	fromX: number,
	fromZ: number,
	delay: number
): { x: number, z: number }?
	grid = grid or Routes.new()
	local best, bestDistance = nil, math.huge
	for _, fraction in { 0, 0.4, 0.7, 1 } do
		local radius = reach * fraction
		local count = if radius == 0 then 1 else 12
		for k = 0, count - 1 do
			local angle = k / count * 2 * math.pi
			local col, row = grid:cellOf(itemX + math.cos(angle) * radius, itemZ + math.sin(angle) * radius)
			local x, z = grid:centerOf(col, row)
			if
				(x - itemX) ^ 2 + (z - itemZ) ^ 2 <= reach * reach
				and not grid:isRock(col, row)
				and wayHomeOpen(entry, x, z, delay)
			then
				local distance = (x - fromX) ^ 2 + (z - fromZ) ^ 2
				if distance < bestDistance then
					best, bestDistance = { x = x, z = z }, distance
				end
			end
		end
	end
	return best
end
BotService.approachFor = approachFor -- for tools/tests

-- The value of a slot's worth of find still to come this tide, for a bot as it stands: the best, over
-- the zones it can work this tide, of the zone's average find (BotEconomy.findValue) times the
-- share of the zone's free items (`samples`, a few of them) that have a safe approach. While the sea
-- is going out or low every zone its tool works counts, once it comes in only the ones still
-- uncovered. Zone 7 counts only if `plan` (sandbarPlan) shows a crossing, a useful stay and the way
-- back fit in the channel's window.
function BotService.comingValue(
	bot: Bot,
	entry: any,
	plan: SandbarPlan?,
	samples: { [number]: { any } },
	footEntry: any?
): number
	local tide = Tide.getState()
	local sandbarZone = Beach.FarSandbarZone
	local order = {}
	for z = 1, #Config.Zones do
		local raw = BotEconomy.findValue(bot.State, z)
		local z0 = Beach.zoneRange(z)
		if
			raw > 0
			and (tide.Phase ~= "In" or z0 < tide.Waterline)
			and (z ~= sandbarZone or (plan and plan.Feasible))
		then
			table.insert(order, { Zone = z, Raw = raw })
		end
	end
	table.sort(order, function(a, b)
		return a.Raw > b.Raw
	end)
	local tool = BotEconomy.tool(bot.State)
	local reach = tool.Reach + Config.Items.ReachSlack - 3
	local speed = BotEconomy.walkSpeed(bot.State) * speedFactor
	local best = 0
	for _, e in order do
		if e.Raw <= best then
			break -- (the rest are worth less even with every item reachable)
		end
		local list = samples[e.Zone] or {}
		local safe = 0
		for _, item in list do
			local position = item.Position
			local there = math.sqrt((position.X - bot.X) ^ 2 + (position.Z - bot.Z) ^ 2)
				* BotEconomy.MazeFactor
				/ speed
			if e.Zone == sandbarZone and plan then
				there = math.max(there, plan.Arrive)
			end
			if
				approachFor(
					if e.Zone == sandbarZone and footEntry then footEntry else entry,
					position.X,
					position.Z,
					reach,
					bot.X,
					bot.Z,
					there + 1.2 / speedFactor + tideSlack(bot)
				)
			then
				safe += 1
			end
		end
		-- (A zone with nothing to look at yet is taken on trust, the sandbar half: its surf is
		-- mostly out of reach.)
		local prior = if e.Zone == sandbarZone then 0.5 else 1
		best = math.max(best, e.Raw * (safe + 2 * prior) / (#list + 2))
	end
	return best
end

local function chooseTarget(bot: Bot, relaxed: boolean?): boolean
	local entry = ensureField(bot)
	local mine, others = candidates(bot, entry, relaxed)
	searchStats.Decisions += 1
	if #mine + #others == 0 then
		searchStats.NoCandidates += 1
	end
	local list = {}
	for _, group in { mine, others } do
		for i = 1, math.min(#group, 40) do
			table.insert(list, group[i])
		end
	end
	local tool = BotEconomy.tool(bot.State)
	local reach = tool.Reach + Config.Items.ReachSlack - 3 -- (cells are 4 studs: a little in hand)
	local walk = BotEconomy.walkSpeed(bot.State) * speedFactor * SAFE_SPEED
	local sea = Tide.sea()
	local searches = 0
	for _, candidate in list do
		local item = candidate.Item
		local position = item.Position
		local inWater = Beach.depthAt(position, sea) > 0
		local point = approachFor(
			entry,
			position.X,
			position.Z,
			reach,
			bot.X,
			bot.Z,
			candidate.There + 1.2 / speedFactor + tideSlack(bot)
		)
		if not point then
			-- No safe place within reach of it, now or by the time the bot is there.
			if inWater then
				searchStats.WaterSkipped += 1
			else
				searchStats.DrySkipped += 1
			end
			bot.Skip[item] = now() + 10 / speedFactor
			continue
		end
		local out, outLength
		if atHome(bot) then
			out, outLength = reverseOf(bot, entry, point.x, point.z)
		else
			searches += 1
			out, outLength = routeTo(bot, point.x, point.z, 2)
		end
		if not out then
			searchStats.NoRoute += 1
		else
			-- And the way back from where the route ends must stay open, setting out once loaded.
			local last = out[#out]
			if
				wayHomeOpen(
					entry,
					last.x,
					last.z,
					(outLength or 0) / walk + 1.2 / speedFactor + tideSlack(bot)
				)
			then
				searchStats.Chosen += 1
				if item:GetAttribute("Zone") == Beach.FarSandbarZone and not bot.OnSandbar then
					bot.OnSandbar = true
					bot.Stats.SandbarTrips += 1
				end
				if inWater then
					searchStats.WaterTaken += 1
				end
				bot.Target = item
				bot.Reapproached = false
				setStatus(bot, if atHome(bot) then "walking out" else "heading for an item")
				beginPath(bot, out, "ToItem")
				return true
			end
			searchStats.Closed += 1
		end
		bot.Skip[item] = now() + 60 / speedFactor
		if searches >= 2 then
			break
		end
	end
	return false
end

-- Where a bot waits for what the tide washes up: just landward of the waterline as it will be when
-- the bot gets there, along the bot's own lane of the beach (a trip bot: inside its zone).
-- It never goes further out than the furthest zone the bot's tool works (its tier, Strong Back
-- included: Bare Hands zone 1, Rake zone 2, ...): when the waterline is beyond that, it waits at the
-- seaward edge of that zone. Zone 7 (past the channel) only for a tier 7 tool.
local function stagingFor(
	state: any,
	lo: number,
	hi: number,
	fromX: number,
	fromZ: number,
	tripZone: number?,
	holdBack: boolean?,
	atBank: boolean?
): (number, number)
	grid = grid or Routes.new()
	local x = (lo + hi) / 2
	local speed = BotEconomy.walkSpeed(state) * speedFactor
	local t = now()
	local z = fromZ
	for _ = 1, 3 do
		local eta = math.sqrt((x - fromX) ^ 2 + (z - fromZ) ^ 2) * BotEconomy.MazeFactor / speed
		-- (Further up the beach while the sea comes in: it gains on a bot standing at its edge.)
		local margin = if Tide.getState(t).Phase == "In" then 30 else 8
		z = Tide.waterlineAt({ Now = t + eta }, x) - margin
	end
	local top, bottom = 0, Beach.Depth - 20
	local reach = math.clamp(BotEconomy.lift(state, BotEconomy.tool(state)), 1, #Config.Zones)
	if reach < #Config.Zones then
		bottom = select(2, Beach.zoneRange(reach)) - 20
	end
	if holdBack or atBank then
		-- A tier 7 bot waits on the channel's shore side, not across it: it crosses (a sandbar trip)
		-- only while the channel is open (decide).
		bottom = math.min(bottom, Config.Beach.FarSandbar.ChannelStart - SAND_BANK)
	end
	if tripZone then
		local z0, z1 = Beach.zoneRange(tripZone)
		top, bottom = z0 + 10, math.min(bottom, z1 - 20)
	end
	z = math.clamp(z, top, bottom)
	-- Not inside a wall: the nearest open ground.
	local col, row = grid:cellOf(x, z)
	for radius = 0, 25 do
		for dc = -radius, radius do
			for dr = -radius, radius do
				if
					math.max(math.abs(dc), math.abs(dr)) == radius
					and col + dc >= 0
					and col + dc < grid.cols
					and row + dr >= 0
					and row + dr < grid.rows
					and not grid:isRock(col + dc, row + dr)
				then
					local ox, oz = grid:centerOf(col + dc, row + dr)
					return ox, math.clamp(oz, top, bottom)
				end
			end
		end
	end
	return x, z
end
BotService.stagingFor = stagingFor -- for tools/tests

local function stagingPoint(bot: Bot): (number, number)
	local lo, hi = stretchOf(bot)
	local plan = bot.Plan
	local holdBack, atBank = false, false
	if plan and not bot.Trip then
		if plan.Feasible and plan.Opens <= 0 and BotEconomy.cartSize(bot.State) == nil then
			-- (The channel is open and a stay fits: no holding back.)
		elseif plan.Feasible and plan.Opens - plan.ToBank <= SAND_LEAD / speedFactor then
			-- Time to be at the channel's shore side, as it opens.
			holdBack, atBank = true, true
			lo, hi = plan.X, plan.X
		else
			holdBack = true
		end
	elseif
		not bot.Trip and BotEconomy.lift(bot.State, BotEconomy.tool(bot.State)) >= Beach.FarSandbarZone
	then
		holdBack = true
	end
	return stagingFor(
		bot.State,
		lo,
		hi,
		bot.X,
		bot.Z,
		if bot.Trip then bot.Trip.Zone else nil,
		holdBack,
		atBank
	)
end

-- Real seconds until the way home from where the bot stands closes (its deadline).
local function timeLeft(bot: Bot, entry: any): number
	local slack = entry.Field:slack(bot.X, math.max(bot.Z, 0))
	if not slack then
		return 0
	end
	return slack - (now() - entry.T0)
end

-- Why a bot with a load should set off home now, or nil to keep working: "Full" (the cart is),
-- "Tide" (the way home's deadline, less the margin the bot keeps, is near) or "Nothing" (the sea is
-- coming in and no zone still uncovered that the bot can work offers more than the bar for a slot,
-- against what it carries).
local function homeReason(bot: Bot, entry: any): string?
	if #bot.Cargo >= BotEconomy.capacity(bot.State) then
		return "Full"
	end
	if bot.Trip or bot.Finished then
		return "Nothing"
	end
	if timeLeft(bot, entry) < tideSlack(bot) + 20 / speedFactor then
		return "Tide"
	end
	if Tide.getState().Phase == "In" then
		local sum = 0
		for _, item in bot.Cargo do
			sum += item:GetAttribute("Value") or 0
		end
		local coming = bot.Coming or 0
		if coming <= 0 or coming < SLOT_FLOOR * sum / #bot.Cargo then
			return "Nothing"
		end
	end
	return nil
end

BotService.homeReason = homeReason -- for tools/tests

-- The sandbar shuttle ---------------------------------------------------------------------------
-- A wheeled cart can't climb the channel's banks (Config.Beach.Terrain.CartSlope), so a bot with one
-- crosses alone: it parks the cart at the channel's shore side, walks over on foot, carries one item
-- at a time back across to the cart and loads it, and comes back for the next while the channel is
-- open (every pick-up needs the way home across the channel to stay open, as ever), then takes the
-- cart on home. (A bot with no cart, or one that flies, just goes: no shuttle.)

local function depositHands(bot: Bot)
	local item = bot.Hands
	bot.Hands = nil
	if item and ItemService.isItem(item) then
		table.insert(bot.Cargo, item)
		ItemService.setInCart(item, bot.CartVessel, bot.OwnerId)
	end
	placeCart(bot)
end

local function endShuttle(bot: Bot)
	if bot.Hands then
		depositHands(bot)
	end
	bot.Foot = false
	bot.Parked = nil
	bot.ParkSpot = nil
	bot.ShuttleAfter = now() + 20 / speedFactor
	dropTrail(bot)
	placeCart(bot)
end

-- At the channel's shore side as it opens, with free slots and sandbar finds about: park the cart.
local function startShuttle(bot: Bot): boolean
	if bot.Foot or bot.Trip or bot.Finished or not bot.Cart or (bot.ShuttleAfter or 0) > now() then
		return false
	end
	if #bot.Cargo >= BotEconomy.capacity(bot.State) then
		return false
	end
	local plan = sandbarPlan(bot.State, ensureField(bot, true), bot.X, bot.Z)
	if not plan or not plan.Feasible or plan.Opens > 0 or bot.Z < plan.BankZ - 40 then
		return false
	end
	local lift = BotEconomy.lift(bot.State, BotEconomy.tool(bot.State))
	local t = now()
	local found = false
	for item in ItemService.all() do
		if
			item:GetAttribute("Zone") == Beach.FarSandbarZone
			and ItemService.getState(item) == "Unclaimed"
			and not item:GetAttribute("Unlock")
			and Gear.canLift(lift, item:GetAttribute("Tier"))
			and (not bot.Skip[item] or bot.Skip[item] < t)
		then
			found = true
			break
		end
	end
	if not found then
		bot.ShuttleAfter = t + 10 / speedFactor
		return false
	end
	bot.Parked = { CFrame = bot.Cart:GetPivot() }
	bot.ParkSpot = { x = bot.X, z = bot.Z }
	bot.Foot = true
	if not bot.OnSandbar then
		bot.OnSandbar = true
		bot.Stats.SandbarTrips += 1
	end
	setStatus(bot, "crossing to the sandbar")
	return true
end

local function decideShuttle(bot: Bot)
	local spot = bot.ParkSpot
	local near = (bot.X - spot.x) ^ 2 + (bot.Z - spot.z) ^ 2 < 64
	local function toCart(mode: string): boolean
		local path = routeTo(bot, spot.x, spot.z, 4)
		if path then
			setStatus(bot, if bot.Hands then "carrying it back to the cart" else "back to the cart")
			beginPath(bot, path, mode)
			return true
		end
		return false
	end
	if bot.Hands then
		if near then
			bot.Mode = "Claiming"
			setStatus(bot, "loading")
			later(bot, 0.5, function()
				depositHands(bot)
				bot.Mode = nil
			end)
			return
		end
		if not toCart("Deposit") then
			goHome(bot) -- (no way back to the cart: home on foot, and the cart is fetched there)
		end
		return
	end
	if #bot.Cargo < BotEconomy.capacity(bot.State) and chooseTarget(bot) then
		return
	end
	-- Nothing more to take over there (or the cart is full): back to the cart and on.
	if near then
		endShuttle(bot)
		return
	end
	if not toCart("Unpark") then
		goHome(bot)
	end
end

-- Whether a bot should drop what it is doing and be at the channel's shore side as it opens: its tool
-- works zone 7, a useful stay fits from where it is, it has room for what it would bring back, and
-- it is time to set off (the walk to the bank takes it there as the channel opens).
local function headForBank(bot: Bot): boolean
	if bot.Foot or bot.Trip or bot.Finished then
		return false
	end
	if BotEconomy.lift(bot.State, BotEconomy.tool(bot.State)) < Beach.FarSandbarZone then
		return false
	end
	local capacity = BotEconomy.capacity(bot.State)
	if capacity - #bot.Cargo < math.max(2, capacity // 3) and capacity > 1 then
		return false
	end
	local cartBot = BotEconomy.cartSize(bot.State) ~= nil
	local plan = sandbarPlan(
		bot.State,
		ensureField(bot, cartBot),
		bot.X,
		bot.Z,
		if cartBot then ensureField(bot) else nil
	)
	bot.Plan = plan
	return plan ~= nil
		and plan.Feasible
		and plan.Opens - plan.ToBank <= SAND_LEAD / speedFactor
		and bot.Z < plan.BankZ - 40
end

function decide(bot: Bot)
	bot.Target = nil
	local pending = bot.Pending
	if pending then
		-- Stopped short of an item: step right up to it.
		bot.Pending = nil
		if ItemService.isItem(pending) and ItemService.getState(pending) == "Unclaimed" then
			-- (From a safe place close in: never into the water.)
			local entry = ensureField(bot)
			local tool = BotEconomy.tool(bot.State)
			local point = approachFor(
				entry,
				pending.Position.X,
				pending.Position.Z,
				(tool.Reach + Config.Items.ReachSlack - 3) * 0.5,
				bot.X,
				bot.Z,
				5 / speedFactor + tideSlack(bot)
			)
			local path = if point then routeTo(bot, point.x, point.z, 0) else nil
			if path then
				bot.Target = pending
				beginPath(bot, path, "ToItem")
				return
			end
		end
		bot.Skip[pending] = now() + 20 / speedFactor
	end
	if bot.Foot then
		decideShuttle(bot)
		return
	end
	if startShuttle(bot) then
		decideShuttle(bot)
		return
	end
	local capacity = BotEconomy.capacity(bot.State)
	-- A sandbar trip is planned: time to be at the channel's shore side as it opens, so no new
	-- targets (the staging below walks there).
	local bankBound = headForBank(bot)
	if #bot.Cargo < capacity and not bot.Finished and not bankBound then
		if chooseTarget(bot) then
			return
		end
	end
	if #bot.Cargo > 0 then
		-- Free slots and nothing worth taking: keep working (wait at the best zone the tide is
		-- uncovering) unless the cart is full, the tide forces the bot home, or nothing is left.
		local reason = homeReason(bot, ensureField(bot))
		if reason then
			if reason ~= "Full" and not bot.Trip and not bot.Finished and chooseTarget(bot, true) then
				return -- (one of the last items, worth little but safe to take on the way)
			end
			setOffHome(bot, reason)
			return
		end
	end
	local t = now()
	-- Nothing to take: wait at the waterline in the bot's own stretch, following the sea out and
	-- back in again (as it comes in, what it washes up lands in the earlier zones, still worth
	-- working), as long as the way back stays open for a minute longer than it needs to;
	-- otherwise wait where it's safe.
	if not bot.Finished then
		local sx, sz = stagingPoint(bot)
		-- Walks toward a staging point if there's a way there that stays open on the way back.
		local function stageAt(sx: number, sz: number): boolean
			-- (The trip bot sets out once the tide is well on its way out, so it trails the waterline
			-- all the way: its outbound leg needn't look at the water.)
			local state = Tide.getState(t)
			local tripReady = state.Phase ~= "Out" or state.PhaseProgress >= 0.4
			local out, outLength
			if not bot.Trip or tripReady then
				if atHome(bot) then
					out, outLength = reverseOf(bot, ensureField(bot), sx, sz)
				else
					out, outLength = routeTo(bot, sx, sz, 8, nil, nil, nil, bot.Trip ~= nil)
				end
			end
			if bot.Trip then
				bot.Trip.Diag = string.format(
					"stage (%.0f, %.0f) from (%.0f, %.0f): out %s %.0f",
					sx,
					sz,
					bot.X,
					bot.Z,
					tostring(out ~= nil),
					outLength or -1
				)
			end
			if out then
				local entry = ensureField(bot)
				local walk = BotEconomy.walkSpeed(bot.State)
					* speedFactor
					* (if bot.Trip then LOOSE_SPEED else SAFE_SPEED)
				local last = out[#out]
				local back = wayHomeOpen(
					entry,
					last.x,
					last.z,
					(outLength or 0) / walk + (if bot.Trip then 0 else 60) / speedFactor
				)
				if bot.Trip then
					bot.Trip.Diag = string.format(
						"%s, back %s (tide %s %.0f%%), slack %s, needed %.0f",
						bot.Trip.Diag,
						tostring(back),
						Tide.getState(t).Phase,
						Tide.getState(t).PhaseProgress * 100,
						tostring(entry.Field:slack(last.x, math.max(last.z, 0))),
						now() - entry.T0 + (outLength or 0) / walk
					)
					bot.Trip.First = bot.Trip.First or bot.Trip.Diag
				end
				if back then
					setStatus(bot, "walking out")
					beginPath(bot, out, "Stage")
					return true
				end
			end
			return false
		end
		if math.sqrt((sx - bot.X) ^ 2 + (sz - bot.Z) ^ 2) > 40 then
			if stageAt(sx, sz) then
				return
			end
			-- (No safe way to all the way there, a long walk after a tide that outruns the bot: a
			-- nearer point on the way, rather than giving up and going home.)
			for _, fraction in { 0.6, 0.3 } do
				local tx, tz = bot.X + (sx - bot.X) * fraction, bot.Z + (sz - bot.Z) * fraction
				if
					not bot.Trip
					and math.sqrt((tx - bot.X) ^ 2 + (tz - bot.Z) ^ 2) > 40
					and stageAt(tx, tz)
				then
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
			if wayHomeOpen(ensureField(bot), bot.X, bot.Z, 60 / speedFactor) then
				setStatus(bot, "waiting for the tide")
				bot.WaitUntil = t + 0.3
				bot.After = function() end
				return
			end
		end
	end
	if #bot.Cargo > 0 then
		-- (Couldn't wait out here: the way back needs leaving, or there's nowhere to stand.)
		setOffHome(bot, if atHome(bot) then "Nothing" else "Tide")
		return
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
		Cycle = cycleBase + entry.Cycle,
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
	if bot.Hands then
		if ItemService.isItem(bot.Hands) then
			ItemService.destroy(bot.Hands)
		end
		bot.Stats.LostItems += 1
		bot.Hands = nil
	end
	bot.Foot, bot.Parked, bot.ParkSpot = false, nil, nil
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
	bot.OnSandbar = false
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
	bot.OnSandbar = false
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
				bot.Pending = item
				bot.Mode = nil
				return
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
			-- Into the cart (or the hands: one thing, or the one thing a shuttle carries back).
			if bot.Foot then
				bot.Hands = item
			else
				table.insert(bot.Cargo, item)
				if bot.Cart then
					ItemService.setInCart(item, bot.CartVessel, bot.OwnerId)
				end
			end
			bot.GroundY = Beach.groundAt(bot.X, bot.Z)
			placeCart(bot)
			later(bot, 0.4, function()
				bot.Mode = nil
			end)
		end)
	elseif mode == "Deposit" then
		bot.Mode = "Claiming"
		setStatus(bot, "loading")
		later(bot, 0.5, function()
			depositHands(bot)
			bot.Mode = nil
		end)
	elseif mode == "Unpark" then
		endShuttle(bot)
		bot.Mode = nil
	elseif mode == "Home" then
		if bot.Foot then
			-- (Came home on foot: the cart is fetched, and what's in the hands goes in with the rest.)
			if bot.Hands then
				table.insert(bot.Cargo, bot.Hands)
				bot.Hands = nil
			end
			bot.Foot = false
			bot.Parked = nil
			bot.ParkSpot = nil
			dropTrail(bot)
			placeCart(bot)
		end
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

-- A bot's thinking (decide) runs in its own thread, one at a time; movement carries on meanwhile.
local function think(bot: Bot)
	if bot.Thinking or bot.Gone then
		return
	end
	-- (A thread runs until its first yield: start no new thinking in a frame that's used its share.)
	mark()
	if frameUsed > FRAME_BUDGET then
		return
	end
	bot.Thinking = true
	task.spawn(function()
		mark()
		local startedThinking = now()
		local ok, err = pcall(decide, bot)
		bot.Thinking = false
		bot.Stats.ThinkSeconds += now() - startedThinking
		if not ok and not bot.Gone and not string.find(tostring(err), "bot gone", 1, true) then
			warn("[BotService] bot " .. bot.Id .. " errored while thinking: " .. tostring(err))
			bot.Path, bot.Target, bot.Mode, bot.After = nil, nil, nil, nil
			bot.StuckUntil = now() + 2
		end
	end)
end

local function stepBot(bot: Bot, dt: number, sea: Tide.Sea, t: number)
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
		think(bot)
		if bot.Status == "waiting for the tide" then
			bot.Stats.IdleSeconds += dt
		end
	end
end

-- How long the server's frames take while bots play (Heartbeat's own dt, and the time spent in
-- onFrame); the sweep reports the worst.
local frameStats = { Frames = 0, MaxDt = 0, MaxWork = 0, Slow = 0 }

function BotService.resetFrameStats()
	frameStats = { Frames = 0, MaxDt = 0, MaxWork = 0, Slow = 0 }
end

local function onFrame(rawDt: number)
	local started = os.clock()
	frameUsed = 0
	lastMark = started
	frameStats.Frames += 1
	frameStats.MaxDt = math.max(frameStats.MaxDt, rawDt)
	if rawDt > 0.05 then
		frameStats.Slow += 1
	end
	local dt = math.min(rawDt, 0.1)
	local t = now()
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
	for _, bot in bots do
		local ok, err = pcall(stepBot, bot, dt, sea, t)
		if not ok then
			warn("[BotService] bot " .. bot.Id .. " errored: " .. tostring(err))
			bot.Path, bot.Target, bot.Mode, bot.After = nil, nil, nil, nil
			bot.StuckUntil = t + 2
		end
	end
	frameStats.MaxWork = math.max(frameStats.MaxWork, os.clock() - started)
end

-- Spawning -------------------------------------------------------------------------------

local function spawnBot(id: number, state: any, trip: any, at: { x: number, z: number }?): Bot
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
			ThinkSeconds = 0,
			Deaths = 0,
			LostLoads = 0,
			LostItems = 0,
			Purchases = 0,
			Rebirths = 0,
			HomeTrips = 0, -- times set off home with a load
			HomeLoad = 0, -- the sum of their loads (items over capacity)
			SandbarTrips = 0,
		},
		Trip = trip,
		DirX = 0,
		DirZ = 1,
		StartedAt = now(),
		StartSpeed = speedFactor,
	}
	bot.X = if at then at.x else HOME.x + ((id - 1) % 5 - 2) * 6
	bot.Z = if at then at.z else HOME.z + ((id - 1) // 5 - 1.5) * 5
	bot.GroundY = Beach.groundAt(bot.X, bot.Z)
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
	if bot.Hands and ItemService.isItem(bot.Hands) then
		ItemService.setUnclaimed(bot.Hands, true)
		ItemService.dropToGround(bot.Hands)
	end
	bot.Hands = nil
	local target = bot.Target
	bot.Target = nil
	return target
end

local function despawnBot(bot: Bot)
	bot.Gone = true
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
	nodesBase = { Search = grid.nodes, Field = grid.fieldNodes }
	connection = RunService.Heartbeat:Connect(onFrame)
end

-- Public ---------------------------------------------------------------------------------

-- Builds the way-home fields before any bot plays (the sweep does this in its set-up), in big slices:
-- each is { Cart = size or nil, Loose = true for a trip bot }. Without it a bot waits for its field.
function BotService.warmUp(modes: { { Cart: string?, Loose: boolean? } })
	grid = grid or Routes.new()
	grid:refresh()
	for _, mode in modes do
		buildFieldFor(mode.Cart, mode.Loose == true, true)
	end
end

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
			MaxRate = {},
		}
		for index, zone in Config.Zones do
			originals.MaxRate[index] = zone.MaxRate
		end
	end
	for key, value in originals do
		if key ~= "MaxRate" then
			Config.Items[key] = value / factor
		end
	end
	-- Each zone's spawn rate is per second: it goes up by the factor too (the ticks come more
	-- often, but each tick's share of the rate is smaller, so without this the supply per second
	-- of game time would fall by the factor).
	for index, zone in Config.Zones do
		if zone.MaxRate then
			zone.MaxRate = originals.MaxRate[index] * factor
		end
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

-- Makes `n` bots play (adding or removing the highest numbers), 0 to 20. `gear` (tool and vessel
-- ids, e.g. { "ElectricWinch", "QuadBike" }) is owned from the start by the first `gearBots` of the
-- bots that join (all of them if not given): the sweep's way to put tier 7 gear in play.
function BotService.setCount(n: number, gear: { string }?, gearBots: number?)
	n = math.clamp(math.floor(n), 0, BotService.MaxBots)
	if n > 0 then
		ensureRunning()
	end
	for id = 1, n do
		if not bots[id] then
			local state = nil
			if gear and id <= (gearBots or n) then
				state = BotEconomy.newState()
				for _, gearId in gear do
					if Gear.findTool(gearId) then
						state.Tools[gearId] = true
					elseif Gear.getVessel(gearId) then
						state.Vessels[gearId] = true
					else
						warn("[BotService] unknown starting gear " .. tostring(gearId))
					end
				end
			end
			spawnBot(id, state, nil)
		end
	end
	for id = BotService.MaxBots, n + 1, -1 do
		if bots[id] then
			despawnBot(bots[id])
		end
	end
	ItemService.setBotCount(BotService.count())
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
	ItemService.setBotCount(0)
	running = false
	if botFolder then
		botFolder:Destroy()
		botFolder = nil
	end
end

-- Carrying a game over -----------------------------------------------------------------------

-- The whole game as plain data (JSON-safe), so a sweep can run one long game as a chain of tasks:
-- the tide's place, every bot (purse, gear, rewards, stats, position, cargo), every free item on
-- the beach, which loot spots have settled this tide, and the counts. importState puts it back.
local function round1(v: number): number
	return math.floor(v * 10 + 0.5) / 10
end

function BotService.exportState()
	local t = now()
	local tide = Tide.getState(t)
	local out = {
		Version = 1,
		Speed = speedFactor,
		Tide = { Phase = tide.Phase, Progress = tide.PhaseProgress },
		Seed = Workspace:GetAttribute(Tide.SeedAttribute),
		CycleBase = cycleBase + tide.Cycle,
		Bots = {},
		Items = {},
		Settled = ItemService.exportSettled(tide.Cycle),
		ServerStats = {},
		Searches = table.clone(searchStats),
	}
	for key, value in ItemService.stats do
		out.ServerStats[key] = if type(value) == "table" then table.clone(value) else value
	end
	for id, bot in bots do
		local cargo = {}
		for _, item in bot.Cargo do
			if ItemService.isItem(item) then
				table.insert(cargo, { Id = item:GetAttribute("ItemId"), Zone = item:GetAttribute("Zone") })
			end
		end
		local state = bot.State
		out.Bots[tostring(id)] = {
			Id = id,
			X = round1(bot.X),
			Z = round1(bot.Z),
			GameSeconds = (t - bot.StartedAt) * bot.StartSpeed,
			Stats = table.clone(bot.Stats),
			Cargo = cargo,
			State = {
				Coins = state.Coins,
				Rebirths = state.Rebirths,
				Rewards = state.Rewards,
				Tools = state.Tools,
				Vessels = state.Vessels,
			},
		}
	end
	local carried = {}
	for _, bot in bots do
		for _, item in bot.Cargo do
			carried[item] = true
		end
	end
	for item in ItemService.all() do
		-- (Whatever a bot is holding but hasn't loaded goes back on the beach where it is.)
		if not carried[item] then
			local position = item.CFrame.Position
			table.insert(out.Items, {
				Id = item:GetAttribute("ItemId"),
				Zone = item:GetAttribute("Zone"),
				X = round1(position.X),
				Z = round1(position.Z),
				Fresh = item:GetAttribute("Fresh") == true,
				Age = round1(math.max(0, t - (item:GetAttribute("Since") or t))),
			})
		end
	end
	return out
end

-- Where a carried-over bot stands: its own spot if the sea would let it, else the nearest safe
-- ground toward the shore (logged in `BotService.moves()`).
local function safeSpot(x: number, z: number): (number, number, boolean)
	grid = grid or Routes.new()
	local sea = Tide.sea()
	local limit = Config.Beach.WaistDepth - DEPTH_MARGIN
	local function safe(px: number, pz: number): boolean
		local col, row = grid:cellOf(px, pz)
		return not grid:isRock(col, row) and Beach.waterYAt(sea, px) - Beach.groundAt(px, pz) < limit
	end
	if z < 0 or safe(x, z) then
		return x, z, false
	end
	for step = 1, 400 do
		local pz = z - step * Routes.STEP
		if pz < 0 then
			break
		end
		if safe(x, pz) then
			return x, pz, true
		end
	end
	return HOME.x, HOME.z, true
end

-- Puts the tide and the beach back (before the way-home fields are built, which read the tide).
function BotService.importWorld(data: any)
	assert(math.abs((data.Speed or 1) - speedFactor) < 1e-9, "a chained game runs at one speed")
	ensureRunning()
	local t = now()
	if data.Seed then
		Workspace:SetAttribute(Tide.SeedAttribute, data.Seed)
	end
	Workspace:SetAttribute(Tide.StartAttribute, Tide.startFor(data.Tide.Phase, data.Tide.Progress, t))
	lastCycle = Tide.getState(t).Cycle
	cycleBase = data.CycleBase or 0
	for _, record in data.Items do
		local def = Items.get(record.Id)
		if def then
			local item = ItemService.spawnAt(
				def,
				record.Zone,
				Vector3.new(record.X, Beach.groundAt(record.X, record.Z) + def.Size.Y / 2, record.Z)
			)
			item:SetAttribute("Fresh", record.Fresh)
			item:SetAttribute("Since", t - record.Age)
		end
	end
	ItemService.importSettled(data.Settled or {}, lastCycle)
end

-- Puts the bots back: purses, gear, stats, positions and what they carried.
function BotService.importBots(data: any)
	ensureRunning()
	local t = now()
	table.clear(moved)
	local ids = {}
	for key in data.Bots do
		table.insert(ids, tonumber(key) :: number)
	end
	table.sort(ids)
	for _, id in ids do
		local record = data.Bots[tostring(id)]
		local state = BotEconomy.newState()
		state.Coins = record.State.Coins
		state.Rebirths = record.State.Rebirths
		state.Rewards = table.clone(record.State.Rewards)
		state.Tools = table.clone(record.State.Tools)
		state.Vessels = table.clone(record.State.Vessels)
		local x, z, wasMoved = safeSpot(record.X, record.Z)
		if wasMoved then
			table.insert(
				moved,
				{ Bot = id, From = { record.X, record.Z }, To = { x, z }, Cargo = #record.Cargo }
			)
		end
		local bot = spawnBot(id, state, nil, { x = x, z = z })
		for key, value in record.Stats do
			bot.Stats[key] = value
		end
		bot.StartedAt = t - record.GameSeconds / speedFactor
		for _, carried in record.Cargo do
			local def = Items.get(carried.Id)
			if def then
				local item = ItemService.spawnAt(def, carried.Zone, Vector3.new(x, bot.GroundY + 2, z))
				if ItemService.claimForBot(item, bot.OwnerId) then
					table.insert(bot.Cargo, item)
					if bot.Cart then
						ItemService.setInCart(item, bot.CartVessel, bot.OwnerId)
					end
				end
			end
		end
		placeCart(bot)
		setStatus(bot, "waiting for the tide")
	end
	ItemService.setBotCount(BotService.count())
	-- The counts carry on from where they were (importing re-made things and counted them).
	for key, value in data.ServerStats or {} do
		ItemService.stats[key] = if type(value) == "table" then table.clone(value) else value
	end
	for key, value in data.Searches or {} do
		searchStats[key] = value
	end
end

function BotService.importState(data: any, warmModes: { any }?)
	BotService.importWorld(data)
	if warmModes then
		BotService.warmUp(warmModes)
	end
	BotService.importBots(data)
end

-- Bots that had to be moved to safety by the last import: { Bot, From, To, Cargo }.
function BotService.moves(): { any }
	return moved
end

-- Coins earned by all bots so far and the game time they have played (for a sweep's progress curve).
function BotService.progress()
	local coins, seconds, n = 0, 0, 0
	local t = now()
	for _, bot in bots do
		coins += bot.Stats.Coins
		seconds += (t - bot.StartedAt) * bot.StartSpeed
		n += 1
	end
	return { Coins = coins, GameSeconds = if n > 0 then seconds / n else 0, Bots = n }
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
				ThinkingGameSeconds = s.ThinkSeconds * bot.StartSpeed,
				Deaths = s.Deaths,
				LostLoads = s.LostLoads,
				LostItems = s.LostItems,
				Purchases = s.Purchases,
				HomeTrips = s.HomeTrips,
				MeanHomeLoad = if s.HomeTrips > 0 then s.HomeLoad / s.HomeTrips else 0, -- items over capacity
				SandbarTrips = s.SandbarTrips,
				Rebirths = bot.State.Rebirths,
				Purse = bot.State.Coins,
				Gear = gearSnapshot(bot),
			})
		end
	end
	local server = table.clone(ItemService.stats)
	server.ZoneSpawned = table.clone(server.ZoneSpawned)
	return {
		Bots = list,
		Server = server,
		Speed = speedFactor,
		BotCount = #list,
		Frames = table.clone(frameStats),
		Searches = table.clone(searchStats),
		Nodes = {
			Search = grid and grid.nodes - nodesBase.Search or 0,
			Field = grid and grid.fieldNodes - nodesBase.Field or 0,
			GameMinutes = (now() - startedAt) * speedFactor / 60,
		},
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
		"bot  colour    coins/h   items/h  trips  lost-to-bot  lost-other  idle%  deaths  lost-loads  home-load%  sandbar  gear, thinking%",
	}
	local total = {
		Coins = 0,
		Items = 0,
		Trips = 0,
		LostToBot = 0,
		LostOther = 0,
		Idle = 0,
		Think = 0,
		Deaths = 0,
		LostLoads = 0,
		Hours = 0,
		HomeTrips = 0,
		HomeLoad = 0,
		Sandbar = 0,
	}
	for _, b in snap.Bots do
		local hours = math.max(b.GameSeconds, 1) / 3600
		total.Coins += b.Coins
		total.Items += b.Items
		total.Trips += b.Trips
		total.LostToBot += b.LostToBot
		total.LostOther += b.LostOther
		total.Idle += b.IdleGameSeconds
		total.Think += b.ThinkingGameSeconds
		total.Deaths += b.Deaths
		total.LostLoads += b.LostLoads
		total.Hours += hours
		total.HomeTrips += b.HomeTrips
		total.HomeLoad += b.MeanHomeLoad * b.HomeTrips
		total.Sandbar += b.SandbarTrips
		table.insert(
			lines,
			string.format(
				"%-4d %-9s %-9s %-8.0f %-6d %-12d %-11d %-6.0f %-7d %-11d %-11.0f %-8d %s + %s, %d rebirth(s), thinking %.1f%%",
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
				b.MeanHomeLoad * 100,
				b.SandbarTrips,
				b.Gear.Tool,
				b.Gear.Vessel or "hands",
				b.Gear.Rebirths,
				b.ThinkingGameSeconds / math.max(b.GameSeconds, 1) * 100
			)
		)
	end
	if snap.BotCount > 0 then
		local n = snap.BotCount
		table.insert(
			lines,
			string.format(
				"all  total     %-9s %-8.0f %-6d %-12d %-11d %-6.0f %-7d %-11d %-11.0f %-8d (per bot: %s coins/h), thinking %.1f%%",
				commas(total.Coins / (total.Hours / n)),
				total.Items / (total.Hours / n),
				total.Trips,
				total.LostToBot,
				total.LostOther,
				total.Idle / math.max(total.Hours * 3600, 1) * 100,
				total.Deaths,
				total.LostLoads,
				total.HomeLoad / math.max(total.HomeTrips, 1) * 100,
				total.Sandbar,
				commas(total.Coins / math.max(total.Hours, 1e-9)),
				total.Think / math.max(total.Hours * 3600, 1) * 100
			)
		)
	end
	local nodes = snap.Nodes
	table.insert(
		lines,
		string.format(
			"Searches: %.0f nodes per game minute (route searches %d, way-home fields %d); frames: worst Heartbeat %.0f ms, bot work %.0f ms, %d over 50 ms; item searches: %d chosen, %d no route, %d way home closed; water items: %d taken, %d skipped (dry ones skipped: %d); %d of %d target choices found no candidate",
			(nodes.Search + nodes.Field) / math.max(nodes.GameMinutes, 1e-9),
			nodes.Search,
			nodes.Field,
			snap.Frames.MaxDt * 1000,
			snap.Frames.MaxWork * 1000,
			snap.Frames.Slow,
			snap.Searches.Chosen,
			snap.Searches.NoRoute,
			snap.Searches.Closed,
			snap.Searches.WaterTaken,
			snap.Searches.WaterSkipped,
			snap.Searches.DrySkipped,
			snap.Searches.NoCandidates,
			snap.Searches.Decisions
		)
	)
	local sr = snap.Searches
	table.insert(
		lines,
		string.format(
			"Tier 7 bots' decisions: %d without a sandbar plan, %d with too short a window, %d waiting for the channel, %d with it open",
			sr.SandNoPlan,
			sr.SandShort,
			sr.SandWaiting,
			sr.SandOpen
		)
	)
	table.insert(
		lines,
		string.format(
			"Set off home: %d with a full cart, %d with free slots because the tide forced it, %d with free slots because nothing more was worth waiting for",
			sr.HomeFull,
			sr.HomeTide,
			sr.HomeNothing
		)
	)
	local s = snap.Server
	table.insert(
		lines,
		string.format(
			"Server: %d surf items spawned (+%d on open sand, +%d at loot spots; by zone %s), %d claimed (%d by bots), %d despawned unclaimed, every zone at target on %d of %d spawn ticks",
			s.SurfSpawned,
			s.SandSpawned,
			s.SpotSpawned,
			table.concat(s.ZoneSpawned, "/"),
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
