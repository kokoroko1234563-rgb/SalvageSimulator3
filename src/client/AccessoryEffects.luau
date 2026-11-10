-- The exotic accessories' powers that live on the wearer's own client (rules: Shared/Accessories,
-- the server's half: AccessoryService). The always-on numbers are elsewhere (Stats for breath
-- and waves, MistController for the haze and fog, HazardController for the Gloom and ice).
--   * Foghorn (key G): asks the server to sound its blast, which pulls free items toward you;
--     a ring spreads out from you.
--   * Tidewalker Boots (key R): asks the server for a walk on the water. WaveController holds
--     you at the surface while it lasts; a ring of foam rides under your feet.
--   * Tide Crown: a panel of when each zone uncovers and closes again, as countdowns.
--   * Prism Lens: Rare and VeryRare items, unlock items (and so biome very-rares) within its
--     radius shine through anything.
--   * Glow Pearl: in the Gloom, a bright light on your head the dark can't put out.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Accessories = require(Shared.Accessories)
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)
local Tide = require(Shared.Tide)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local AccessoryEffects = {}

local MAX_HIGHLIGHTS = 20 -- Roblox draws at most 31 highlights at once

local readyAt: { [string]: number } = {} -- server time each ability is ready again
local buttons: { [string]: TextButton } = {}
local remote: any = nil

local function worn(): any
	return Accessories.worn(player)
end

local function rootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- A ring that spreads out from a point and fades.
local function ring(position: Vector3, radius: number, color: Color3, seconds: number)
	local part = Instance.new("Part")
	part.Name = "AccessoryRing"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Shape = Enum.PartType.Cylinder
	part.Material = Palette.Material.Glass
	part.Color = color
	part.Transparency = 0.4
	part.Size = Vector3.new(0.4, 2, 2)
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	part.Parent = Workspace
	local tween = TweenService:Create(
		part,
		TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.4, radius * 2, radius * 2), Transparency = 1 }
	)
	tween.Completed:Connect(function()
		part:Destroy()
	end)
	tween:Play()
end

-- Key abilities -------------------------------------------------------------------------------

local ABILITIES = {
	foghorn = { Field = "Blast", Name = "Foghorn" },
	waterwalk = { Field = "WaterWalk", Name = "Tidewalk" },
}

local function specOf(ability: string): any
	local accessory = worn()
	return accessory and accessory[ABILITIES[ability].Field]
end

local function use(ability: string)
	if not specOf(ability) or not rootPart() or not remote then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local ready = readyAt[ability] or 0
	if now < ready then
		HUD.notify(string.format("%s is recharging (%ds)", ABILITIES[ability].Name, math.ceil(ready - now)))
		return
	end
	remote:FireServer(ability)
end

local function onResult(ability: string, ok: boolean, reason: string?)
	if not ok then
		if reason then
			HUD.notify(reason)
		end
		return
	end
	local spec = specOf(ability)
	local root = rootPart()
	if not spec or not root then
		return
	end
	readyAt[ability] = Workspace:GetServerTimeNow() + spec.Cooldown
	if ability == "foghorn" then
		ring(root.Position - Vector3.new(0, 2.5, 0), spec.Range, Palette.UI.Banner, 0.8)
		HUD.banner("The foghorn sounds!")
	else
		HUD.notify("You walk on the water!")
	end
end

local function updateButtons()
	local now = Workspace:GetServerTimeNow()
	for ability, button in buttons do
		local spec = specOf(ability)
		button.Visible = spec ~= nil
		if spec then
			local left = (readyAt[ability] or 0) - now
			if left > 0 then
				button.Text = string.format("%s (%d)", ABILITIES[ability].Name, math.ceil(left))
				button.BackgroundColor3 = Palette.UI.Disabled
			else
				button.Text = string.format("%s (%s)", ABILITIES[ability].Name, spec.Key)
				button.BackgroundColor3 = Palette.UI.Spawn
			end
		end
	end
end

-- Water walk: foam under the feet while it lasts.
local foam: Part? = nil
local function updateWalk()
	local root = rootPart()
	local walking = root ~= nil and Accessories.isWaterWalking(player, Tide.now())
	if walking and root then
		local part = foam
		if not part then
			part = Instance.new("Part")
			local made = part :: Part
			made.Name = "TidewalkFoam"
			made.Anchored = true
			made.CanCollide = false
			made.CanQuery = false
			made.CanTouch = false
			made.CastShadow = false
			made.Shape = Enum.PartType.Cylinder
			made.Size = Vector3.new(0.2, 7, 7)
			made.Material = Palette.Material.Glass
			made.Color = Palette.World.Foam
			made.Transparency = 0.35
			made.Parent = Workspace
			foam = made
		end
		local surface = Beach.surfaceY(root.Position, Tide.sea());
		(foam :: Part).CFrame = CFrame.new(root.Position.X, surface + 0.1, root.Position.Z)
			* CFrame.Angles(0, 0, math.pi / 2)
	elseif foam then
		foam:Destroy()
		foam = nil
	end
end

-- Tide Crown: the tide's timeline ----------------------------------------------------------------

local panel: Frame? = nil
local rows: { TextLabel } = {}
local edges: { { Zone: number, Z: number } } = {}

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds + 0.5))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- One line of the panel for a zone's window.
function AccessoryEffects.describe(window: Accessories.Window): string
	if window.AlwaysOpen then
		return "always uncovered"
	elseif window.NeverOpen then
		return "stays covered"
	elseif window.Open then
		return if window.ClosesIn then "open, closes in " .. clock(window.ClosesIn) else "open"
	end
	local text = "opens in " .. clock(window.OpensIn or 0)
	if window.ClosesIn then
		text ..= ", closes in " .. clock(window.ClosesIn)
	end
	return text
end

local function updateTimeline()
	local frame = panel
	if not frame then
		return
	end
	local accessory = worn()
	frame.Visible = accessory ~= nil and accessory.TideTimeline == true
	if not frame.Visible then
		return
	end
	local windows = Accessories.timeline(function(t)
		return Tide.waterlineAt(Tide.sea(t), 0)
	end, Tide.now(), Tide.cycleLength(), edges)
	for i, window in windows do
		local name = if window.Zone == Beach.FarSandbarZone then "Far Sandbar" else "Zone " .. window.Zone
		rows[i].Text = name .. ": " .. AccessoryEffects.describe(window)
		rows[i].TextColor3 = if window.Open then Palette.UI.Text else Palette.UI.Muted
	end
end

-- Prism Lens ---------------------------------------------------------------------------------------

local highlights: { [BasePart]: Highlight } = {}

local function updatePrism()
	local accessory = worn()
	local radius = if accessory and accessory.Prism then accessory.Prism else 0
	local root = rootPart()
	local wanted: { { Item: BasePart, Distance: number } } = {}
	if radius > 0 and root then
		for _, item in CollectionService:GetTagged("SalvageItem") do
			if item:IsA("BasePart") then
				local distance = (item.Position - root.Position).Magnitude
				if Accessories.prismReveals(item, distance, radius) then
					table.insert(wanted, { Item = item, Distance = distance })
				end
			end
		end
		table.sort(wanted, function(a, b)
			return a.Distance < b.Distance
		end)
	end
	local keep: { [BasePart]: boolean } = {}
	for i = 1, math.min(#wanted, MAX_HIGHLIGHTS) do
		keep[wanted[i].Item] = true
	end
	for item, highlight in highlights do
		if not keep[item] or not item.Parent then
			highlight:Destroy()
			highlights[item] = nil
		end
	end
	for item in keep do
		if not highlights[item] then
			local highlight = Instance.new("Highlight")
			highlight.Name = "PrismGlow"
			highlight.FillTransparency = 0.5
			highlight.FillColor = Palette.Rarity[item:GetAttribute("Rarity")] or Palette.UI.Accent
			highlight.OutlineColor = highlight.FillColor
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Adornee = item
			highlight.Parent = item
			highlights[item] = highlight
		end
	end
end

-- Glow Pearl --------------------------------------------------------------------------------------

local pearlLight: PointLight? = nil

local function updatePearl()
	local accessory = worn()
	local spec = accessory and accessory.GloomLight
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if spec and head and player:GetAttribute("Benighted") then
		if not pearlLight or pearlLight.Parent ~= head then
			if pearlLight then
				pearlLight:Destroy()
			end
			local made = Instance.new("PointLight")
			made.Name = "GloomPearl"
			made.Shadows = false
			made.Color = Color3.fromRGB(150, 240, 255)
			made.Parent = head
			pearlLight = made
		end
		-- Steady where the Gloom flickers every other light.
		local light = pearlLight :: PointLight
		light.Range = spec.Range
		light.Brightness = spec.Brightness
	elseif pearlLight then
		pearlLight:Destroy()
		pearlLight = nil
	end
end

function AccessoryEffects.init()
	remote = Remotes.get("Accessory")
	remote.OnClientEvent:Connect(function(kind, ability, ok, reason)
		if kind == "result" and ABILITIES[ability] then
			onResult(ability, ok, reason)
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "AccessoryEffects"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local order = 0
	for ability, info in ABILITIES do
		order += 1
		local button = Instance.new("TextButton")
		button.Name = info.Name
		button.AnchorPoint = Vector2.new(1, 1)
		button.Position = UDim2.new(1, -16, 1, -240 - 46 * order)
		button.Size = UDim2.fromOffset(120, 40)
		button.Font = Palette.Font.Bold
		button.TextSize = 16
		button.TextColor3 = Palette.UI.Text
		button.Visible = false
		button.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button
		button.Activated:Connect(function()
			use(ability)
		end)
		buttons[ability] = button
	end

	-- The Tide Crown's panel, one row per zone.
	for zone = 1, Config.Beach.ActiveZones do
		table.insert(edges, { Zone = zone, Z = (Beach.zoneRange(zone)) })
	end
	table.insert(edges, { Zone = Beach.FarSandbarZone, Z = (Beach.zoneRange(Beach.FarSandbarZone)) })
	local frame = Instance.new("Frame")
	frame.Name = "TideTimeline"
	frame.Position = UDim2.new(0, 12, 0.3, 0)
	frame.Size = UDim2.fromOffset(250, 28 + #edges * 18)
	frame.BackgroundColor3 = Palette.UI.Background
	frame.BackgroundTransparency = 0.25
	frame.Visible = false
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(8, 4)
	title.Size = UDim2.new(1, -16, 0, 18)
	title.Font = Palette.Font.Bold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Palette.UI.Accent
	title.Text = "Tide timeline"
	title.Parent = frame
	for i = 1, #edges do
		local row = Instance.new("TextLabel")
		row.BackgroundTransparency = 1
		row.Position = UDim2.fromOffset(8, 24 + (i - 1) * 18)
		row.Size = UDim2.new(1, -16, 0, 18)
		row.Font = Palette.Font.Body
		row.TextSize = 13
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = Palette.UI.Text
		row.Text = ""
		row.Parent = frame
		rows[i] = row
	end
	panel = frame

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		for ability in ABILITIES do
			local spec = specOf(ability)
			if spec and input.KeyCode == Enum.KeyCode[spec.Key] then
				use(ability)
			end
		end
	end)

	RunService.Heartbeat:Connect(updateWalk)
	local quick, steady = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		quick += dt
		steady += dt
		if quick >= 0.25 then
			quick = 0
			updateButtons()
			updatePearl()
		end
		if steady >= 0.5 then
			steady = 0
			updateTimeline()
			updatePrism()
		end
	end)
end

return AccessoryEffects
