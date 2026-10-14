-- The custom hotbar (replaces Roblox's backpack bar, which this game doesn't use). Shows the
-- grabbing tools on the player's bar; press 1-6 or click a slot to equip that tool.
-- Right-click a slot to empty it. From the inventory, "+ Hotbar" puts the bar in place mode:
-- the next slot you click gets that tool (a tool already on the bar swaps places).

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)
local Hotbar = require(Shared.Hotbar)
local Items = require(Shared.Items)
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local HotbarUI = {}

local SLOT = 58
local GAP = 6
local KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
}

local bar: Frame
local prompt: Frame
local promptText: TextLabel
local removeButton: TextButton
local slots: { { button: TextButton, name: TextLabel, band: Frame, stroke: UIStroke } } = {}
local placing: string? = nil -- tool id waiting for a slot

local function act(action: string, arg: any, value: any?)
	local called, ok, reason = pcall(function()
		return Remotes.get("InventoryAction"):InvokeServer(action, arg, value)
	end)
	if not called then
		HUD.notify("That didn't work: " .. tostring(ok))
	elseif not ok then
		HUD.notify(reason or "That didn't work")
	end
end

local function owned(): { [string]: boolean }
	local set = {}
	for id in string.gmatch(player:GetAttribute("OwnedTools") or "", "[^,]+") do
		set[id] = true
	end
	return set
end

-- The bar as shown: tools the player no longer owns (after a rebirth) show as empty.
local function shownBar(): { string }
	local saved = Hotbar.decode(player:GetAttribute(Hotbar.Attribute))
	local have = owned()
	for i, id in saved do
		if not have[id] then
			saved[i] = ""
		end
	end
	return saved
end

local function refresh()
	local current = shownBar()
	local equipped = player:GetAttribute("Tool")
	for i, slot in slots do
		local tool = Gear.findTool(current[i])
		slot.name.Text = if tool then tool.Name else ""
		slot.band.Visible = tool ~= nil
		slot.band.BackgroundColor3 = if tool
			then Items.RarityColors[tool.Rarity] or Palette.UI.Text
			else Palette.UI.Text
		slot.button.BackgroundTransparency = if tool then 0.15 else 0.55
		if placing then
			slot.stroke.Color = Palette.UI.Attune
			slot.stroke.Thickness = 2
			slot.stroke.Transparency = 0
		elseif tool and tool.Id == equipped then
			slot.stroke.Color = Palette.UI.Accent
			slot.stroke.Thickness = 3
			slot.stroke.Transparency = 0
		else
			slot.stroke.Color = Palette.UI.Text
			slot.stroke.Thickness = 1
			slot.stroke.Transparency = 0.7
		end
	end
	prompt.Visible = placing ~= nil
	if placing then
		local tool = Gear.findTool(placing)
		promptText.Text = "Choose a slot for " .. (if tool then tool.Name else "this tool")
		removeButton.Visible = table.find(current, placing) ~= nil
	end
end

-- Inventory: start choosing a slot for a tool.
function HotbarUI.beginPlace(toolId: string)
	placing = toolId
	refresh()
end

local function endPlace()
	placing = nil
	refresh()
end

local function useSlot(index: number)
	if placing then
		local id = placing
		endPlace()
		act("hotbar", index, id)
		return
	end
	local id = shownBar()[index]
	if id ~= "" and id ~= player:GetAttribute("Tool") then
		act("equipTool", id)
	end
end

-- Phones put their buttons along the bottom left, so on narrow screens the bar sits higher.
local function layout()
	local camera = Workspace.CurrentCamera
	local width = if camera then camera.ViewportSize.X else 1000
	bar.Position = UDim2.new(0.5, 0, 1, if width < 900 then -60 else -10)
end

function HotbarUI.init()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "Hotbar"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Size = UDim2.fromOffset(Hotbar.Slots * SLOT + (Hotbar.Slots - 1) * GAP, SLOT)
	bar.BackgroundTransparency = 1
	bar.Parent = gui
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, GAP)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = bar

	for i = 1, Hotbar.Slots do
		local button = Instance.new("TextButton")
		button.Name = "Slot" .. i
		button.LayoutOrder = i
		button.Size = UDim2.fromOffset(SLOT, SLOT)
		button.BackgroundColor3 = Palette.UI.Background
		button.AutoButtonColor = true
		button.Text = ""
		button.Parent = bar
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = button

		local number = Instance.new("TextLabel")
		number.BackgroundTransparency = 1
		number.Position = UDim2.fromOffset(5, 2)
		number.Size = UDim2.fromOffset(14, 14)
		number.Font = Palette.Font.Bold
		number.TextSize = 12
		number.TextColor3 = Palette.UI.Muted
		number.TextXAlignment = Enum.TextXAlignment.Left
		number.Text = tostring(i)
		number.Parent = button

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(3, 14)
		name.Size = UDim2.new(1, -6, 1, -24)
		name.Font = Palette.Font.Bold
		name.TextSize = 11
		name.TextWrapped = true
		name.TextColor3 = Palette.UI.Text
		name.Parent = button

		local band = Instance.new("Frame")
		band.BorderSizePixel = 0
		band.AnchorPoint = Vector2.new(0.5, 1)
		band.Position = UDim2.new(0.5, 0, 1, -4)
		band.Size = UDim2.new(1, -16, 0, 4)
		band.Parent = button
		local bandCorner = Instance.new("UICorner")
		bandCorner.CornerRadius = UDim.new(0, 2)
		bandCorner.Parent = band

		button.Activated:Connect(function()
			useSlot(i)
		end)
		button.MouseButton2Click:Connect(function()
			if shownBar()[i] ~= "" then
				act("hotbar", i, "")
			end
		end)
		slots[i] = { button = button, name = name, band = band, stroke = stroke }
	end

	-- Shown while choosing a slot for a tool from the inventory.
	prompt = Instance.new("Frame")
	prompt.Name = "PlacePrompt"
	prompt.AnchorPoint = Vector2.new(0.5, 1)
	prompt.Position = UDim2.new(0.5, 0, 0, -8)
	prompt.Size = UDim2.fromOffset(bar.Size.X.Offset, 30)
	prompt.BackgroundColor3 = Palette.UI.Background
	prompt.BackgroundTransparency = 0.2
	prompt.Visible = false
	prompt.Parent = bar
	local promptCorner = Instance.new("UICorner")
	promptCorner.CornerRadius = UDim.new(0, 8)
	promptCorner.Parent = prompt
	promptText = Instance.new("TextLabel")
	promptText.BackgroundTransparency = 1
	promptText.Position = UDim2.fromOffset(10, 0)
	promptText.Size = UDim2.new(1, -170, 1, 0)
	promptText.Font = Palette.Font.Body
	promptText.TextSize = 13
	promptText.TextColor3 = Palette.UI.Text
	promptText.TextXAlignment = Enum.TextXAlignment.Left
	promptText.TextTruncate = Enum.TextTruncate.AtEnd
	promptText.Parent = prompt
	removeButton = Instance.new("TextButton")
	removeButton.AnchorPoint = Vector2.new(1, 0.5)
	removeButton.Position = UDim2.new(1, -72, 0.5, 0)
	removeButton.Size = UDim2.fromOffset(84, 24)
	removeButton.BackgroundColor3 = Palette.UI.Danger
	removeButton.Font = Palette.Font.Bold
	removeButton.TextSize = 13
	removeButton.TextColor3 = Palette.UI.Text
	removeButton.Text = "Take off bar"
	removeButton.Parent = prompt
	local removeCorner = Instance.new("UICorner")
	removeCorner.CornerRadius = UDim.new(0, 6)
	removeCorner.Parent = removeButton
	local cancel = Instance.new("TextButton")
	cancel.AnchorPoint = Vector2.new(1, 0.5)
	cancel.Position = UDim2.new(1, -4, 0.5, 0)
	cancel.Size = UDim2.fromOffset(64, 24)
	cancel.BackgroundColor3 = Palette.UI.Tab
	cancel.Font = Palette.Font.Bold
	cancel.TextSize = 13
	cancel.TextColor3 = Palette.UI.Text
	cancel.Text = "Cancel"
	cancel.Parent = prompt
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 6)
	cancelCorner.Parent = cancel
	cancel.Activated:Connect(endPlace)

	removeButton.Activated:Connect(function()
		local id = placing
		endPlace()
		local index = id and table.find(shownBar(), id)
		if index then
			act("hotbar", index, "")
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape and placing then
			endPlace()
			return
		end
		local index = KEYS[input.KeyCode]
		if index and index <= Hotbar.Slots then
			useSlot(index)
		end
	end)

	for _, attribute in { Hotbar.Attribute, "Tool", "OwnedTools" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
	end
	layout()
	refresh()
end

return HotbarUI
