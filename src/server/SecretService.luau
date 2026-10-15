-- Secret runs. Using a banked unlock item at a secret's door (always uses it up) sends the
-- player to their own copy of the course. The client builds the course locally; the server
-- never sees those parts, so it verifies the run from the character's replicated position:
-- checkpoints in order, staying above the rising flood, a plausible time, and standing at
-- the chest when claiming it. Failing (flooded, fell out, died, out of time) loses the item.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)
local Secrets = require(Shared.Secrets)
local Tide = require(Shared.Tide)

local CollisionGroups = require(script.Parent.CollisionGroups)
local DataService = require(script.Parent.DataService)
local GrabService = require(script.Parent.GrabService)

local cfg = Config.Secrets
local rng = Random.new()

local SecretService = {}

type Run = {
	secret: any,
	origin: Vector3,
	duration: number,
	returnTo: CFrame,
	startedAt: number?, -- nil until the player has been teleported in
	nextCheckpoint: number,
	ready: boolean, -- the client has built the course and moved the character in
	openedAt: number, -- os.clock() when the door was used
	nudged: boolean, -- the server has tried moving the character in itself
	finished: boolean,
}

local runs: { [Player]: Run } = {}
local notify: (Player, string) -> () = function(_player: Player, _text: string) end
local eventRemote

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root, humanoid
end

function SecretService.isInRun(player: Player): boolean
	return runs[player] ~= nil
end

-- How long the course takes to flood: until the real tide would cover the door, so entering
-- just before the tide comes in leaves the least time.
local function floodDuration(door: Vector3): number
	local now = Tide.now()
	local t = 0
	while t < cfg.MaxFlood do
		if Beach.isDeep(door, Tide.sea(now + t)) then
			break
		end
		t += 2
	end
	return math.clamp(t, cfg.MinFlood, cfg.MaxFlood)
end

local function endRun(player: Player, message: string?, sendBack: boolean)
	local run = runs[player]
	if not run then
		return
	end
	runs[player] = nil
	eventRemote:FireClient(player, "end")
	if sendBack then
		local character = player.Character
		if character then
			character:PivotTo(run.returnTo + Vector3.new(0, 3, 0))
		end
	end
	if message then
		notify(player, message)
	end
end

function SecretService.tryEnter(player: Player, secretId: string, returnTo: CFrame)
	local secret = Secrets.List[secretId]
	local profile = DataService.get(player)
	local root, humanoid = rootOf(player)
	if not secret or not profile or not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if runs[player] then
		return
	end
	if (root.Position - returnTo.Position).Magnitude > 20 then
		return
	end
	if Beach.isDeep(returnTo.Position, Tide.sea()) then
		notify(player, "The door is underwater. Come back when the tide is out.")
		return
	end
	if secret.Coin and profile.ColoredCoins[secret.Coin] then
		notify(player, "You already have the " .. secret.Coin:lower() .. " coin from this secret.")
		return
	end
	local unlockName = Items.get(secret.Unlock).Name
	if DataService.countItemType(player, secret.Unlock) < 1 then
		notify(
			player,
			"You need a banked " .. unlockName .. ". Find one in the surf and bring it to the bank house."
		)
		return
	end
	local slot = CollisionGroups.slotFor(player)
	if not slot then
		return
	end

	-- The unlock item is always used up, win or lose.
	DataService.removeItemsOfType(player, secret.Unlock, 1)
	GrabService.forceRelease(player)

	local run: Run = {
		secret = secret,
		origin = Secrets.originFor(slot),
		duration = secret.FloodSeconds or floodDuration(returnTo.Position),
		returnTo = returnTo,
		startedAt = nil,
		nextCheckpoint = 1,
		ready = false,
		openedAt = os.clock(),
		nudged = false,
		finished = false,
	}
	runs[player] = run
	eventRemote:FireClient(
		player,
		"start",
		{ Secret = secret.Id, Origin = run.origin, Duration = run.duration }
	)

	run.openedAt = os.clock()
end

local function onReady(player: Player, ok: any)
	local run = runs[player]
	if not run or run.startedAt then
		return
	end
	if ok == false then
		-- The client couldn't build the course: our fault, so give the unlock item back.
		DataService.addItem(player, run.secret.Unlock, "refund")
		endRun(
			player,
			"Couldn't open the secret. Your " .. Items.get(run.secret.Unlock).Name .. " was returned.",
			true
		)
		return
	end
	run.ready = true
end

local function onClaim(player: Player)
	local run = runs[player]
	if not run or not run.startedAt or run.finished then
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local course = run.secret.Course
	local rel = root.Position - run.origin
	local elapsed = Tide.now() - run.startedAt
	local ok = run.nextCheckpoint > #course.Checkpoints
		and (rel - course.Chest).Magnitude <= course.ChestRadius
		and elapsed >= cfg.MinRunTime
		and elapsed <= run.duration + 2
	if not ok then
		warn(
			string.format(
				"[SecretService] rejected chest claim from %s (checkpoint %d/%d, %.1f studs from chest, %.1fs)",
				player.Name,
				run.nextCheckpoint - 1,
				#course.Checkpoints,
				(rel - course.Chest).Magnitude,
				elapsed
			)
		)
		return
	end
	run.finished = true
	if run.secret.Coin then
		DataService.grantColoredCoin(player, run.secret.Coin)
		endRun(player, "You found the " .. run.secret.Coin:lower() .. " coin!", true)
	else
		-- Exotic secret: a lootbox. The reward goes straight into the inventory.
		local itemId, variant = Secrets.rollLoot(run.secret, rng)
		local entry = itemId and Catalog.get(itemId)
		if itemId and entry then
			DataService.addItem(player, itemId, "secret", { Variant = variant })
			local name = (if variant then variant .. " " else "") .. entry.Name
			endRun(player, "The lootbox held: " .. name .. "! It's in your inventory.", true)
		else
			endRun(player, nil, true)
		end
	end
end

local function insideCourse(run: Run, position: Vector3): boolean
	local rel = position - run.origin
	local half = run.secret.Course.HalfSize + 6
	return math.abs(rel.X) <= half and math.abs(rel.Z) <= half and rel.Y > -15 and rel.Y < 200
end

-- A run starts only once the server actually sees the character inside the course. The
-- client moves its own character there (it owns the character's physics, so a server-side
-- move can be overwritten by the client's last position); the server only nudges as a
-- fallback, and gives the unlock item back if the player never arrives.
local function waitForArrival(player: Player, run: Run)
	local root = rootOf(player)
	if root and run.ready and insideCourse(run, root.Position) then
		run.startedAt = Tide.now() + cfg.FloodDelay -- the water waits a moment before rising
		eventRemote:FireClient(player, "go", { StartedAt = run.startedAt })
		notify(player, "Climb to the chest before the sea floods in!")
		return
	end
	local waited = os.clock() - run.openedAt
	if root and run.ready and waited > 1.5 and not run.nudged then
		run.nudged = true
		local character = player.Character
		if character then
			character:PivotTo(CFrame.new(run.origin + run.secret.Course.Spawn))
		end
	end
	if waited > cfg.ReadyTimeout + 3 then
		-- Our fault, not theirs: give the unlock item back.
		DataService.addItem(player, run.secret.Unlock, "refund")
		endRun(
			player,
			"Couldn't open the secret. Your " .. Items.get(run.secret.Unlock).Name .. " was returned.",
			true
		)
	end
end

local function tick()
	local now = Tide.now()
	for player, run in runs do
		if run.finished then
			continue
		end
		if not run.startedAt then
			waitForArrival(player, run)
			continue
		end
		local root, humanoid = rootOf(player)
		if not root or not humanoid or humanoid.Health <= 0 then
			endRun(player, "You didn't make it out of the vault.", false)
			continue
		end
		local course = run.secret.Course
		local rel = root.Position - run.origin
		local elapsed = now - run.startedAt

		local cp = course.Checkpoints[run.nextCheckpoint]
		if cp and (rel - cp).Magnitude <= course.CheckpointRadius then
			run.nextCheckpoint += 1
		end

		local water = Secrets.floodLevel(course, elapsed, run.duration)
		if rel.Y < water then
			endRun(
				player,
				"The flood caught you. The " .. Items.get(run.secret.Unlock).Name .. " is gone.",
				true
			)
		elseif
			math.abs(rel.X) > course.HalfSize + 6
			or math.abs(rel.Z) > course.HalfSize + 6
			or rel.Y < -15
		then
			endRun(
				player,
				"You left the vault. The " .. Items.get(run.secret.Unlock).Name .. " is gone.",
				true
			)
		elseif elapsed > run.duration + 2 then
			endRun(player, "The vault flooded.", true)
		end
	end
end

function SecretService.init(notifyFn: (Player, string) -> ())
	notify = notifyFn
	eventRemote = Remotes.get("SecretEvent")
	Remotes.get("SecretReady").OnServerEvent:Connect(onReady)
	Remotes.get("ClaimChest").OnServerEvent:Connect(onClaim)

	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(0.1)
			tick()
		end
	end)
end

return SecretService
