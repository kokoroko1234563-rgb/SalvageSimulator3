-- Secret runs. Using a banked unlock item at a secret's door (always uses it up) sends the
-- player to their own copy of the course. The client builds the course locally; the server
-- never sees those parts, so it verifies the run from the character's replicated position:
-- checkpoints in order, staying above the rising flood, a plausible time, and standing at
-- the chest when claiming it. Failing (flooded, fell out, died, out of time) loses the item.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)
local Secrets = require(Shared.Secrets)
local Tide = require(Shared.Tide)

local CollisionGroups = require(script.Parent.CollisionGroups)
local DataService = require(script.Parent.DataService)
local GrabService = require(script.Parent.GrabService)

local cfg = Config.Secrets

local SecretService = {}

type Run = {
	secret: any,
	origin: Vector3,
	duration: number,
	returnTo: CFrame,
	startedAt: number?, -- nil until the player has been teleported in
	nextCheckpoint: number,
	ready: boolean, -- the client has built the course
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
		if Beach.isDeep(door, Tide.waterline(now + t)) then
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
	if Beach.isDeep(returnTo.Position, Tide.waterline()) then
		notify(player, "The door is underwater. Come back when the tide is out.")
		return
	end
	if profile.ColoredCoins[secret.Coin] then
		notify(player, "You already have the " .. secret.Coin:lower() .. " coin from this secret.")
		return
	end
	local unlockName = Items.get(secret.Unlock).Name
	if DataService.countItemType(player, secret.Unlock) < 1 then
		notify(
			player,
			"You need a banked " .. unlockName .. ". Find one in the surf and bring it to the bank pad."
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
		duration = floodDuration(returnTo.Position),
		returnTo = returnTo,
		startedAt = nil,
		nextCheckpoint = 1,
		ready = false,
		finished = false,
	}
	runs[player] = run
	eventRemote:FireClient(
		player,
		"start",
		{ Secret = secret.Id, Origin = run.origin, Duration = run.duration }
	)

	-- Wait for the client to build the course (or give up waiting), then send them in.
	task.spawn(function()
		local deadline = os.clock() + cfg.ReadyTimeout
		while runs[player] == run and not run.ready and os.clock() < deadline do
			task.wait(0.1)
		end
		if runs[player] ~= run then
			return
		end
		local character = player.Character
		if not character then
			endRun(player, nil, false)
			return
		end
		character:PivotTo(CFrame.new(run.origin + secret.Course.Spawn))
		run.startedAt = Tide.now()
		eventRemote:FireClient(player, "go", { StartedAt = run.startedAt })
		notify(player, "Climb to the chest before the sea floods the vault!")
	end)
end

local function onReady(player: Player)
	local run = runs[player]
	if run then
		run.ready = true
	end
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
	DataService.grantColoredCoin(player, run.secret.Coin)
	endRun(player, "You found the " .. run.secret.Coin:lower() .. " coin!", true)
end

local function tick()
	local now = Tide.now()
	for player, run in runs do
		if not run.startedAt or run.finished then
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
