-- Gear effects that only matter to the wearer, so they run on their own client:
--   * (The Lantern of Clear Sight's longer sight is in MistController, which owns the haze.)
--   * Prism Lens (RevealRare): rare and unlock items nearby shine through anything.
--   * Freeze Wand (a tool with Freeze): press F, or the on-screen button, to freeze the waves
--     around you for a few seconds, on a cooldown. It stops the waves pushing you, what you
--     hold and your vessel within its radius. It never affects the tide.
-- WaveController asks GearEffects.isFrozen before applying waves; SeaController reads the
-- Foghorn's earlier warning from Gear directly.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)
local Palette = require(Shared.Palette)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local GearEffects = {}

local MAX_HIGHLIGHTS = 20 -- Roblox draws at most 31 highlights at once
local REVEAL_RARITIES = { Rare = true, VeryRare = true, Unlock = true }

-- Freeze Wand state.
local frozenUntil = 0
local frozenAt = Vector3.zero
local frozenRadius = 0
local readyAt = 0
local freezeButton: TextButton? = nil

local function wornAccessory()
	return Gear.getAccessory(player:GetAttribute("Accessory"))
end

local function equippedTool()
	return Gear.findTool(player:GetAttribute("Tool"))
end

-- Whether waves are frozen at a position right now (the Freeze Wand).
function GearEffects.isFrozen(position: Vector3): boolean
	return os.clock() < frozenUntil and (position - frozenAt).Magnitude <= frozenRadius
end

-- Prism Lens ------------------------------------------------------------------------------

local highlights: { [BasePart]: Highlight } = {}

local function updateReveal()
	local worn = wornAccessory()
	local radius = if worn and worn.RevealRare then worn.RevealRare else 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local wanted: { BasePart } = {}
	if radius > 0 and root then
		for _, item in CollectionService:GetTagged("SalvageItem") do
			if
				item:IsA("BasePart")
				and REVEAL_RARITIES[item:GetAttribute("Rarity") or ""]
				and item:GetAttribute("State") == "Unclaimed"
				and (item.Position - root.Position).Magnitude <= radius
			then
				table.insert(wanted, item)
			end
		end
		table.sort(wanted, function(a, b)
			return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
		end)
	end
	local keep = {}
	for i = 1, math.min(#wanted, MAX_HIGHLIGHTS) do
		keep[wanted[i]] = true
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
			highlight.FillTransparency = 0.6
			highlight.FillColor = Palette.Rarity[item:GetAttribute("Rarity")] or Palette.UI.Accent
			highlight.OutlineColor = highlight.FillColor
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Adornee = item
			highlight.Parent = item
			highlights[item] = highlight
		end
	end
end

-- Freeze Wand -----------------------------------------------------------------------------

local function freeze()
	local tool = equippedTool()
	local spec = tool and tool.Freeze
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not spec or not root then
		return
	end
	local now = os.clock()
	if now < readyAt then
		HUD.notify(string.format("The Freeze Wand is recharging (%ds)", math.ceil(readyAt - now)))
		return
	end
	frozenAt = root.Position
	frozenRadius = spec.Radius
	frozenUntil = now + spec.Duration
	readyAt = now + spec.Cooldown
	-- A frosty ring on the water while it lasts.
	local ring = Instance.new("Part")
	ring.Name = "FrozenWaves"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, spec.Radius * 2, spec.Radius * 2)
	ring.CFrame = CFrame.new(frozenAt - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Color = Palette.World.Foam:Lerp(Palette.UI.Breath, 0.5)
	ring.Material = Palette.Material.Glass
	ring.Transparency = 0.55
	ring.Parent = Workspace
	task.delay(spec.Duration, function()
		ring:Destroy()
	end)
	HUD.notify("The waves freeze around you!")
end

local function updateFreezeButton()
	local tool = equippedTool()
	if freezeButton then
		freezeButton.Visible = tool ~= nil and tool.Freeze ~= nil
		local now = os.clock()
		if now < readyAt then
			freezeButton.Text = string.format("Freeze (%d)", math.ceil(readyAt - now))
			freezeButton.BackgroundColor3 = Palette.UI.Disabled
		else
			freezeButton.Text = "Freeze (F)"
			freezeButton.BackgroundColor3 = Palette.UI.Breath
		end
	end
end

function GearEffects.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GearEffects"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local button = Instance.new("TextButton")
	button.Name = "Freeze"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -16, 1, -190)
	button.Size = UDim2.fromOffset(120, 40)
	button.Font = Palette.Font.Bold
	button.TextSize = 16
	button.TextColor3 = Palette.UI.Text
	button.Visible = false
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Activated:Connect(freeze)
	freezeButton = button

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F then
			freeze()
		end
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.5 then
			elapsed = 0
			updateReveal()
			updateFreezeButton()
		end
	end)
end

return GearEffects
