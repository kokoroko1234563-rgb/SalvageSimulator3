-- The inventory screen (I, or the bag button). Shows the snapshot the server sends.
--   Items tab:   one card per item type (identical plain copies stack as "x3"). The card's
--                colour band is the rarity; its border is when it's lost: orange = on
--                rebirth, purple = on true rebirth, none = never. Optional reset text.
--   Coins tab:   the five colored coins and attunement cores.
--   Rewards tab: rebirth rewards.
--   Pockets:     the Deep Pockets slots, along the bottom.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Catalog = require(Shared.Catalog)
local Items = require(Shared.Items)
local Rebirth = require(Shared.Rebirth)
local Remotes = require(Shared.Remotes)
local Secrets = require(Shared.Secrets)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

local InventoryUI = {}

local FONT = Palette.Font.Title
local BODY = Palette.Font.Body
local BG = Palette.UI.Background
local CARD = Palette.UI.Card
local MUTED = Palette.UI.Muted
local ACCENT = Palette.UI.Accent
local BORDER = Palette.Reset

local snapshot: any = nil
local tab = "Items"

local panel: Frame
local content: ScrollingFrame
local filterRow: Frame
local pocketsRow: Frame
local tabButtons: { [string]: TextButton } = {}

local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function corner(parent: Instance, radius: number?)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function label(props: { [string]: any }, parent: Instance): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = BODY,
		TextColor3 = Palette.UI.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	return make("TextLabel", defaults, parent)
end

local function button(text: string, color: Color3, parent: Instance): TextButton
	local b = make("TextButton", {
		Text = text,
		Font = FONT,
		TextSize = 15,
		TextColor3 = Palette.UI.Text,
		BackgroundColor3 = color,
		AutoButtonColor = true,
	}, parent)
	corner(b, 6)
	return b
end

local function act(action: string, arg: any, value: any?)
	local called, ok, reason = pcall(function()
		return Remotes.get("InventoryAction"):InvokeServer(action, arg, value)
	end)
	if not called then
		HUD.notify("That didn't work: " .. tostring(ok))
	elseif not ok then
		HUD.notify(reason or "That didn't work")
	elseif reason then
		HUD.notify(reason)
	end
end

local function clearContent()
	for _, child in content:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for _, child in content:GetChildren() do
		if child:IsA("UIGridLayout") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function border(parent: GuiObject, resets: string?)
	local color = resets and BORDER[resets]
	if color then
		make(
			"UIStroke",
			{ Color = color, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			parent
		)
	end
end

-- Groups identical plain copies so 5 spades show as one card "x5".
local function groupItems(items)
	local groups, byKey = {}, {}
	for _, item in items do
		local plain = item.Variant == nil and item.Serial == nil
		local key = if plain then item.Id else item.Uid
		local group = byKey[key]
		if not group then
			group = { Item = item, Count = 0 }
			byKey[key] = group
			table.insert(groups, group)
		end
		group.Count += 1
	end
	return groups
end

local function itemCard(group, order: number)
	local item = group.Item
	local entry = Catalog.get(item.Id)
	if not entry then
		return
	end
	local settings = snapshot.Settings or {}
	local card = make("Frame", { BackgroundColor3 = CARD, LayoutOrder = order }, content)
	corner(card, 8)
	border(card, if entry.Resets ~= "Never" then entry.Resets else nil)

	local band = make("Frame", {
		BackgroundColor3 = Items.RarityColors[entry.Rarity] or Palette.UI.Text,
		Size = UDim2.new(1, 0, 0, 8),
		BorderSizePixel = 0,
	}, card)
	corner(band, 8)

	local title = entry.Name
	if group.Count > 1 then
		title ..= "  x" .. group.Count
	end
	label({
		Text = title,
		Font = FONT,
		TextSize = 17,
		Position = UDim2.fromOffset(8, 12),
		Size = UDim2.new(1, -16, 0, 22),
	}, card)

	local sub = entry.Category .. " · " .. (if entry.Rarity == "VeryRare" then "Very rare" else entry.Rarity)
	if item.Variant then
		sub ..= " · " .. item.Variant
	end
	if item.Serial then
		sub ..= string.format(" · #%d of %d", item.Serial, item.Of or 0)
	end
	label({
		Text = sub,
		TextSize = 12,
		TextColor3 = Items.RarityColors[entry.Rarity] or MUTED,
		Position = UDim2.fromOffset(8, 34),
		Size = UDim2.new(1, -16, 0, 16),
	}, card)

	local lines = { entry.Description }
	if settings.ShowResetText then
		table.insert(lines, Catalog.ResetText[entry.Resets])
	end
	local attuned = table.find(snapshot.Attunements or {}, item.Id) ~= nil
	if entry.Exotic then
		table.insert(lines, if attuned then "Attuned" else "Not attuned: needs 1 core to use")
	end
	table.insert(lines, if entry.Tradeable then "Tradeable" else "Not tradeable")
	label({
		Text = table.concat(lines, "\n"),
		TextSize = 12,
		TextColor3 = MUTED,
		Position = UDim2.fromOffset(8, 52),
		Size = UDim2.new(1, -16, 1, -96),
	}, card)

	local actionButton: TextButton? = nil
	if entry.Exotic and not attuned then
		local hasCore = (snapshot.Cores or 0) > 0
		actionButton = button(
			if hasCore then "Attune · 1 core" else "Needs a core",
			if hasCore then Palette.UI.Attune else Palette.UI.Disabled,
			card
		)
		if hasCore then
			(actionButton :: TextButton).Activated:Connect(function()
				act("attune", item.Uid)
			end)
		end
	elseif entry.Category == "Accessory" then
		local worn = snapshot.EquippedAccessory == item.Id
		actionButton = button(if worn then "Take off" else "Wear", Palette.UI.Pocket, card);
		(actionButton :: TextButton).Activated:Connect(function()
			act(if worn then "unequip" else "equip", item.Uid)
		end)
	elseif entry.Category == "Tool" then
		local equipped = snapshot.EquippedTool == item.Id
		actionButton = button(
			if equipped then "Equipped" else "Equip",
			if equipped then Palette.UI.Equipped else Palette.UI.Buy,
			card
		)
		if not equipped then
			(actionButton :: TextButton).Activated:Connect(function()
				act("equip", item.Uid)
			end)
		end
	elseif entry.Category == "Vessel" then
		local out = snapshot.ActiveVessel == item.Id
		actionButton = button(if out then "Respawn" else "Spawn", Palette.UI.Spawn, card);
		(actionButton :: TextButton).Activated:Connect(function()
			act("spawn", item.Uid)
		end)
	end
	if actionButton then
		actionButton.Size = UDim2.new(1, -16, 0, 30)
		actionButton.Position = UDim2.new(0, 8, 1, -38)
	end
end

local function showItems()
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(170, 200),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)
	local hideShop = snapshot.Settings and snapshot.Settings.HideShopGear
	local shown = {}
	for _, item in snapshot.Items do
		local entry = Catalog.get(item.Id)
		if entry and not (hideShop and entry.ShopItem) then
			table.insert(shown, item)
		end
	end
	for index, group in groupItems(shown) do
		itemCard(group, index)
	end
	if #shown == 0 then
		label({
			Text = if hideShop and #snapshot.Items > 0
				then 'Only shop gear here, and it\'s hidden. Turn off "Hide shop gear" to see it.'
				else "Nothing yet. Bank unlock items at the shore, or buy gear at the shop.",
			Size = UDim2.fromOffset(340, 60),
			TextColor3 = MUTED,
		}, content)
	end
end

local function showCoins()
	make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, content)
	label({
		Text = "Clear the 5 normal secrets for all 5 coins, then redeem them for a true rebirth. Colored coins can't be traded and are spent on a true rebirth.",
		Size = UDim2.new(1, -10, 0, 40),
		TextColor3 = MUTED,
		LayoutOrder = 1,
	}, content)
	local row = make(
		"Frame",
		{ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 110), LayoutOrder = 2 },
		content
	)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) }, row)
	local owned = {}
	for _, color in snapshot.ColoredCoins do
		owned[color] = true
	end
	for _, color in Secrets.CoinOrder do
		local slot = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(90, 110) }, row)
		local coin = make("Frame", {
			Size = UDim2.fromOffset(70, 70),
			Position = UDim2.fromOffset(10, 0),
			BackgroundColor3 = if owned[color] then Secrets.CoinColors[color] else CARD,
		}, slot)
		corner(coin, 35)
		make("UIStroke", { Color = Secrets.CoinColors[color], Thickness = 3 }, coin)
		label({
			Text = color .. (if owned[color] then "" else "\nnot found"),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = if owned[color] then Palette.UI.Text else MUTED,
			Position = UDim2.fromOffset(0, 74),
			Size = UDim2.new(1, 0, 0, 36),
		}, slot)
	end
	label({
		Text = string.format(
			"Attunement cores: %d   ·   True rebirths: %d",
			snapshot.Cores or 0,
			snapshot.TrueRebirths or 0
		),
		Font = FONT,
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 3,
	}, content)
	local attunedNames = {}
	for _, id in snapshot.Attunements or {} do
		local entry = Catalog.get(id)
		table.insert(attunedNames, if entry then entry.Name else id)
	end
	label({
		Text = "Attuned to: "
			.. (if #attunedNames > 0 then table.concat(attunedNames, ", ") else "nothing yet")
			.. "\nSpend a core on an exotic item you own (Items tab) to use that kind of item for good, even if you trade the copy away.",
		TextColor3 = MUTED,
		Size = UDim2.new(1, -10, 0, 54),
		LayoutOrder = 4,
	}, content)
end

local function showRewards()
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, content)
	if #snapshot.Rewards == 0 then
		label({
			Text = "No rebirth rewards yet. Each of your first 5 rebirths lets you pick one.",
			Size = UDim2.new(1, -10, 0, 40),
			TextColor3 = MUTED,
		}, content)
	end
	for index, id in snapshot.Rewards do
		local reward = Rebirth.Rewards[id]
		local card = make(
			"Frame",
			{ BackgroundColor3 = CARD, Size = UDim2.new(1, -12, 0, 64), LayoutOrder = index },
			content
		)
		corner(card, 8)
		border(card, "TrueRebirth")
		label({
			Text = reward.Name .. "  ·  " .. reward.Type,
			Font = FONT,
			TextSize = 17,
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -20, 0, 22),
		}, card)
		local desc = reward.Description
		if snapshot.Settings and snapshot.Settings.ShowResetText then
			desc ..= "  (" .. Catalog.ResetText.TrueRebirth .. ")"
		end
		label({
			Text = desc,
			TextSize = 13,
			TextColor3 = MUTED,
			Position = UDim2.fromOffset(10, 30),
			Size = UDim2.new(1, -20, 0, 30),
		}, card)
	end
end

local function refreshFilters()
	for _, child in filterRow:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local settings = snapshot.Settings or {}
	local function toggle(name: string, key: string, order: number)
		local on = settings[key] == true
		local b = button(
			name .. ": " .. (if on then "On" else "Off"),
			if on then Palette.UI.ToggleOn else Palette.UI.Disabled,
			filterRow
		)
		b.Size = UDim2.fromOffset(170, 28)
		b.LayoutOrder = order
		b.Activated:Connect(function()
			act("setting", key, not on)
		end)
	end
	toggle("Hide shop gear", "HideShopGear", 1)
	toggle("Reset text", "ShowResetText", 2)
end

local function refreshPockets()
	for _, child in pocketsRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local slots = snapshot.PocketSlots or 0
	pocketsRow.Visible = slots > 0
	if slots == 0 then
		return
	end
	for slot = 1, math.max(slots, #snapshot.Pockets) do
		local entry = snapshot.Pockets[slot]
		local frame = make(
			"Frame",
			{ BackgroundColor3 = CARD, Size = UDim2.fromOffset(112, 44), LayoutOrder = slot },
			pocketsRow
		)
		corner(frame, 6)
		if entry then
			local def = Items.get(entry.ItemId)
			label({
				Text = string.format("%s\n%d coins", if def then def.Name else entry.ItemId, entry.Value),
				TextSize = 12,
				Position = UDim2.fromOffset(6, 4),
				Size = UDim2.new(1, -46, 1, -8),
			}, frame)
			local out = button("Out", Palette.UI.Pocket, frame)
			out.TextSize = 13
			out.Size = UDim2.fromOffset(36, 28)
			out.Position = UDim2.new(1, -40, 0.5, -14)
			out.Activated:Connect(function()
				Remotes.get("Pocket"):FireServer("drop", slot)
			end)
		else
			label({
				Text = "Empty",
				TextSize = 12,
				TextColor3 = MUTED,
				Position = UDim2.fromOffset(8, 14),
				Size = UDim2.new(1, -16, 0, 16),
			}, frame)
		end
	end
end

local function refresh()
	if not panel.Visible or not snapshot then
		return
	end
	for name, b in tabButtons do
		b.BackgroundColor3 = if name == tab then Palette.UI.Buy else Palette.UI.Tab
	end
	filterRow.Visible = tab == "Items"
	refreshFilters()
	refreshPockets()
	clearContent()
	if tab == "Items" then
		showItems()
	elseif tab == "Coins" then
		showCoins()
	else
		showRewards()
	end
end

local function setOpen(open: boolean)
	panel.Visible = open
	refresh()
end

-- The latest inventory snapshot (the trade screen lists your tradeable items from it).
function InventoryUI.getSnapshot()
	return snapshot
end

local changedCallbacks = {}
function InventoryUI.onChanged(callback: () -> ())
	table.insert(changedCallbacks, callback)
end

function InventoryUI.init()
	local gui = make("ScreenGui", {
		Name = "Inventory",
		ResetOnSpawn = false,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local bag = button("Inventory (I)", Palette.UI.Pocket, gui)
	bag.Size = UDim2.fromOffset(120, 34)
	bag.Position = UDim2.new(0, 12, 1, -46)
	bag.Activated:Connect(function()
		setOpen(not panel.Visible)
	end)

	panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.84),
		BackgroundColor3 = BG,
		Visible = false,
	}, gui)
	make("UISizeConstraint", { MaxSize = Vector2.new(780, 640) }, panel)
	make("UIStroke", { Color = ACCENT, Thickness = 2, Transparency = 0.3 }, panel)
	corner(panel, 12)

	label({
		Text = "Inventory",
		Font = FONT,
		TextSize = 26,
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.fromOffset(200, 32),
		TextYAlignment = Enum.TextYAlignment.Center,
	}, panel)
	local close = button("X", Palette.UI.Danger, panel)
	close.Size = UDim2.fromOffset(34, 34)
	close.Position = UDim2.new(1, -46, 0, 10)
	close.Activated:Connect(function()
		setOpen(false)
	end)

	local tabs = make(
		"Frame",
		{ BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 50), Size = UDim2.new(1, -32, 0, 32) },
		panel
	)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, tabs)
	for _, name in { "Items", "Coins", "Rewards" } do
		local b = button(name, Palette.UI.Tab, tabs)
		b.Size = UDim2.fromOffset(100, 32)
		b.Activated:Connect(function()
			tab = name
			refresh()
		end)
		tabButtons[name] = b
	end

	filterRow = make(
		"Frame",
		{ BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 90), Size = UDim2.new(1, -32, 0, 28) },
		panel
	)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, filterRow)
	local legend = label({
		Text = "Border: orange = lost on rebirth · purple = lost on true rebirth · none = never lost",
		TextSize = 12,
		TextColor3 = MUTED,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.fromOffset(360, 28),
		LayoutOrder = 3,
	}, filterRow)
	legend.TextWrapped = true

	content = make("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 126),
		Size = UDim2.new(1, -32, 1, -196),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = ACCENT,
	}, panel)

	pocketsRow = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 1, -60),
		Size = UDim2.new(1, -32, 0, 44),
		Visible = false,
	}, panel)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, pocketsRow)
	label({
		Text = "Pockets",
		Font = FONT,
		TextSize = 16,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.fromOffset(70, 44),
		LayoutOrder = 0,
	}, pocketsRow)

	gui.Parent = player:WaitForChild("PlayerGui")

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.I then
			setOpen(not panel.Visible)
		end
	end)

	Remotes.get("InventorySync").OnClientEvent:Connect(function(data)
		snapshot = data
		refresh()
		for _, callback in changedCallbacks do
			task.spawn(callback)
		end
	end)
	-- The first snapshot: the profile may still be loading, so ask until there is one.
	task.spawn(function()
		while not snapshot do
			local ok, data = pcall(function()
				return Remotes.get("GetInventory"):InvokeServer()
			end)
			if ok and data then
				snapshot = snapshot or data
				refresh()
			else
				task.wait(1)
			end
		end
	end)
end

return InventoryUI
