-- The trade screen (T, or the Trade button). Not trading: answer invites and invite other
-- players. Trading: both offers side by side, your tradeable items to add, a coin box, and
-- the accept button with its countdown. The server decides everything; this only draws the
-- state it sends and passes on clicks.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Catalog)
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)

local HUD = require(script.Parent.HUD)
local InventoryUI = require(script.Parent.InventoryUI)

local player = Players.LocalPlayer
local UI = Palette.UI

local TradeUI = {}

local state: any = { Invites = {} }
local countdownEnds = 0

local panel: Frame
local body: Frame
local acceptButton: TextButton?
local statusLabel: TextLabel?

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
		Font = Palette.Font.Body,
		TextColor3 = UI.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
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
		Font = Palette.Font.Title,
		TextSize = 15,
		TextColor3 = UI.Text,
		BackgroundColor3 = color,
		AutoButtonColor = true,
	}, parent)
	corner(b, 6)
	return b
end

local function send(action: string, ...)
	local args = table.pack(...)
	task.spawn(function()
		local called, ok, reason = pcall(function()
			return Remotes.get("Trade"):InvokeServer(action, table.unpack(args, 1, args.n))
		end)
		if not called then
			HUD.notify("Trade error: " .. tostring(ok))
		elseif reason then
			HUD.notify(reason)
		end
	end)
end

local function itemName(item): string
	local entry = Catalog.get(item.Id)
	local name = if entry then entry.Name else item.Id
	if item.Variant then
		name = item.Variant .. " " .. name
	end
	if item.Serial then
		name ..= string.format(" #%d", item.Serial)
	end
	return name
end

local function itemColor(item): Color3
	local entry = Catalog.get(item.Id)
	return entry and Palette.Rarity[entry.Rarity] or UI.Text
end

local function list(parent: Instance, position: UDim2, size: UDim2): ScrollingFrame
	local frame = make("ScrollingFrame", {
		Position = position,
		Size = size,
		BackgroundColor3 = UI.Card,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UI.Accent,
	}, parent)
	corner(frame, 8)
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, frame)
	return frame
end

local function itemRow(parent: Instance, item, actionText: string?, onClick: (() -> ())?)
	local row = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 26) }, parent)
	label({
		Text = itemName(item),
		TextColor3 = itemColor(item),
		Size = UDim2.new(1, if actionText then -56 else 0, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
	}, row)
	if actionText and onClick then
		local b = button(actionText, if actionText == "Add" then UI.Spawn else UI.Danger, row)
		b.TextSize = 13
		b.Size = UDim2.fromOffset(50, 22)
		b.Position = UDim2.new(1, -50, 0, 2)
		b.Activated:Connect(onClick)
	end
end

local function clear()
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	acceptButton, statusLabel = nil, nil
end

local function drawLobby()
	label({ Text = "Trade", Font = Palette.Font.Title, TextSize = 26, Size = UDim2.new(1, -60, 0, 34) }, body)

	label({
		Text = "Invites",
		Font = Palette.Font.Title,
		TextSize = 17,
		TextColor3 = UI.Accent,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 22),
	}, body)
	local invites = list(body, UDim2.fromOffset(0, 64), UDim2.new(1, 0, 0, 110))
	if #state.Invites == 0 then
		label(
			{ Text = "No invites right now.", TextColor3 = UI.Muted, Size = UDim2.new(1, 0, 0, 22) },
			invites
		)
	end
	for _, invite in state.Invites do
		local row = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 30) }, invites)
		label({ Text = invite.Name .. " wants to trade", Size = UDim2.new(1, -170, 1, 0) }, row)
		local yes = button("Accept", UI.Equipped, row)
		yes.Size = UDim2.fromOffset(78, 26)
		yes.Position = UDim2.new(1, -164, 0, 2)
		yes.Activated:Connect(function()
			send("respond", invite.UserId, true)
		end)
		local no = button("Decline", UI.Danger, row)
		no.Size = UDim2.fromOffset(78, 26)
		no.Position = UDim2.new(1, -80, 0, 2)
		no.Activated:Connect(function()
			send("respond", invite.UserId, false)
		end)
	end

	label({
		Text = "Players in this server",
		Font = Palette.Font.Title,
		TextSize = 17,
		TextColor3 = UI.Accent,
		Position = UDim2.fromOffset(0, 184),
		Size = UDim2.new(1, 0, 0, 22),
	}, body)
	local others = list(body, UDim2.fromOffset(0, 208), UDim2.new(1, 0, 1, -208))
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			count += 1
			local row = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 30) }, others)
			label({ Text = other.DisplayName, Size = UDim2.new(1, -100, 1, 0) }, row)
			local ask = button("Invite", UI.Buy, row)
			ask.Size = UDim2.fromOffset(90, 26)
			ask.Position = UDim2.new(1, -90, 0, 2)
			ask.Activated:Connect(function()
				send("request", other.UserId)
			end)
		end
	end
	if count == 0 then
		label(
			{ Text = "Nobody else is here yet.", TextColor3 = UI.Muted, Size = UDim2.new(1, 0, 0, 22) },
			others
		)
	end
end

local function drawTrade()
	label({
		Text = "Trading with " .. state.Partner,
		Font = Palette.Font.Title,
		TextSize = 24,
		Size = UDim2.new(1, -60, 0, 32),
	}, body)

	-- Your offer (left) and theirs (right).
	local function offerColumn(title: string, offer, x: number, mine: boolean)
		label({
			Text = title,
			Font = Palette.Font.Title,
			TextSize = 16,
			TextColor3 = UI.Accent,
			Position = UDim2.new(x, if x > 0 then 6 else 0, 0, 38),
			Size = UDim2.new(0.5, -6, 0, 22),
		}, body)
		local column = list(body, UDim2.new(x, if x > 0 then 6 else 0, 0, 62), UDim2.new(0.5, -6, 0, 150))
		for _, item in offer.Items do
			if mine then
				itemRow(column, item, "Take", function()
					send("offerItem", item.Uid, false)
				end)
			else
				itemRow(column, item)
			end
		end
		if #offer.Items == 0 then
			label({ Text = "No items", TextColor3 = UI.Muted, Size = UDim2.new(1, 0, 0, 22) }, column)
		end
		local coinText = if mine
			then string.format(
				"They receive %d coins (%d%% tax)",
				offer.Receives,
				math.floor(state.Tax * 100 + 0.5)
			)
			else string.format("%d coins: you receive %d", offer.Coins, offer.Receives)
		label({
			Text = coinText,
			TextColor3 = UI.Muted,
			TextSize = 13,
			Position = UDim2.new(x, if x > 0 then 6 else 0, 0, 216),
			Size = UDim2.new(0.5, -6, 0, 18),
		}, body)
	end
	offerColumn("Your offer", state.Mine, 0, true)
	offerColumn(state.Partner .. "'s offer", state.Theirs, 0.5, false)

	-- Coins you offer.
	local coinBox = make("TextBox", {
		Text = tostring(state.Mine.Coins),
		PlaceholderText = "Coins to offer",
		ClearTextOnFocus = false,
		Font = Palette.Font.Body,
		TextSize = 15,
		TextColor3 = UI.Text,
		BackgroundColor3 = UI.Input,
		Position = UDim2.fromOffset(0, 240),
		Size = UDim2.new(0.5, -6, 0, 30),
	}, body)
	corner(coinBox, 6)
	coinBox.FocusLost:Connect(function()
		local amount = tonumber(coinBox.Text) or 0
		if amount ~= state.Mine.Coins then
			send("offerCoins", amount)
		end
	end)

	-- Your tradeable items, to add.
	label({
		Text = "Your tradeable items",
		Font = Palette.Font.Title,
		TextSize = 16,
		TextColor3 = UI.Accent,
		Position = UDim2.new(0.5, 6, 0, 240),
		Size = UDim2.new(0.5, -6, 0, 22),
	}, body)
	local pool = list(body, UDim2.new(0.5, 6, 0, 264), UDim2.new(0.5, -6, 1, -330))
	local offered = {}
	for _, item in state.Mine.Items do
		offered[item.Uid] = true
	end
	local inventory = InventoryUI.getSnapshot()
	local any = false
	for _, item in (inventory and inventory.Items) or {} do
		local entry = Catalog.get(item.Id)
		if entry and entry.Tradeable and not offered[item.Uid] then
			any = true
			itemRow(pool, item, "Add", function()
				send("offerItem", item.Uid, true)
			end)
		end
	end
	if not any then
		label({
			Text = "Nothing tradeable. Shop gear can't be traded.",
			TextColor3 = UI.Muted,
			Size = UDim2.new(1, 0, 0, 36),
		}, pool)
	end

	label({
		Text = "Any change resets both accepts and restarts the countdown. Colored coins, cores and shop gear can't be traded.",
		TextColor3 = UI.Muted,
		TextSize = 12,
		Position = UDim2.fromOffset(0, 278),
		Size = UDim2.new(0.5, -6, 0, 48),
	}, body)

	-- Status and buttons.
	statusLabel = label({
		Text = "",
		TextSize = 14,
		Position = UDim2.new(0, 0, 1, -58),
		Size = UDim2.new(1, -260, 0, 50),
	}, body)
	acceptButton = button("Accept", UI.Equipped, body)
	local accept = acceptButton :: TextButton
	accept.Size = UDim2.fromOffset(130, 40)
	accept.Position = UDim2.new(1, -250, 1, -50)
	accept.Activated:Connect(function()
		send("accept", not state.MyAccepted)
	end)
	local cancel = button("Cancel", UI.Danger, body)
	cancel.Size = UDim2.fromOffset(110, 40)
	cancel.Position = UDim2.new(1, -110, 1, -50)
	cancel.Activated:Connect(function()
		send("cancel")
	end)
end

local function redraw()
	if not panel.Visible then
		return
	end
	clear()
	if state.Trading then
		drawTrade()
	else
		drawLobby()
	end
end

-- Countdown and accept status, updated every frame.
local function tick()
	local accept, status = acceptButton, statusLabel
	if not state.Trading or not accept or not status then
		return
	end
	local left = math.max(0, countdownEnds - os.clock())
	if state.MyAccepted then
		accept.Text = "Accepted (undo)"
		accept.BackgroundColor3 = UI.ToggleOn
	elseif left > 0 then
		accept.Text = string.format("Wait %d", math.ceil(left))
		accept.BackgroundColor3 = UI.Disabled
	else
		accept.Text = "Accept"
		accept.BackgroundColor3 = UI.Equipped
	end
	status.Text = string.format(
		"You: %s\n%s: %s",
		if state.MyAccepted then "accepted" else "not accepted",
		state.Partner,
		if state.TheirAccepted then "accepted" else "not accepted"
	)
end

local function setOpen(open: boolean)
	panel.Visible = open
	redraw()
	if open then
		send("sync")
	end
end

function TradeUI.init()
	local gui = make("ScreenGui", {
		Name = "Trade",
		ResetOnSpawn = false,
		DisplayOrder = 6,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local open = button("Trade (T)", UI.Buy, gui)
	open.Size = UDim2.fromOffset(100, 34)
	open.Position = UDim2.new(0, 140, 1, -46)
	open.Activated:Connect(function()
		setOpen(not panel.Visible)
	end)

	panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.84),
		BackgroundColor3 = UI.Background,
		Visible = false,
	}, gui)
	make("UISizeConstraint", { MaxSize = Vector2.new(720, 560) }, panel)
	make("UIStroke", { Color = UI.Accent, Thickness = 2, Transparency = 0.3 }, panel)
	corner(panel, 12)
	body = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -32, 1, -24),
	}, panel)
	local close = button("X", UI.Danger, panel)
	close.Size = UDim2.fromOffset(34, 34)
	close.Position = UDim2.new(1, -46, 0, 10)
	close.ZIndex = 2
	close.Activated:Connect(function()
		setOpen(false)
	end)

	gui.Parent = player:WaitForChild("PlayerGui")

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.T then
			setOpen(not panel.Visible)
		end
	end)

	Remotes.get("TradeSync").OnClientEvent:Connect(function(newState)
		local wasTrading = state.Trading
		state = newState or { Invites = {} }
		countdownEnds = os.clock() + (state.CountdownLeft or 0)
		-- A trade starting opens the screen for both players.
		if state.Trading and not wasTrading then
			panel.Visible = true
		end
		redraw()
	end)
	InventoryUI.onChanged(redraw)
	Players.PlayerAdded:Connect(redraw)
	Players.PlayerRemoving:Connect(function()
		task.defer(redraw)
	end)
	RunService.Heartbeat:Connect(tick)
end

return TradeUI
