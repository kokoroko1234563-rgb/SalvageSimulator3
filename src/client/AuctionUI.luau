-- The global auction screen (U, or the Auction button): the current lot, its serial number,
-- time left, the top bid, your bid, a bid box, and the most recent winners. It asks the
-- server for the latest state every second while open.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer
local UI = Palette.UI

local AuctionUI = {}

local panel: Frame
local body: Frame
local bidBox: TextBox
local state: any = nil
local fetchedAt = 0

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

local function label(props: { [string]: any }, parent: Instance): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Palette.Font.Body,
		TextColor3 = UI.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	return make("TextLabel", defaults, parent)
end

local function formatNumber(n: number): string
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Labels updated in place (so typing in the bid box isn't interrupted).
local labels: { [string]: TextLabel } = {}

local function build()
	labels.Title = label({ Font = Palette.Font.Title, TextSize = 24, Size = UDim2.new(1, -50, 0, 30) }, body)
	labels.Series = label({
		TextColor3 = Palette.Rarity.Auction,
		Font = Palette.Font.Title,
		TextSize = 16,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 22),
	}, body)
	labels.Note = label({
		TextColor3 = UI.Muted,
		TextSize = 13,
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 0, 34),
	}, body)
	labels.Time = label({
		Font = Palette.Font.Title,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 94),
		Size = UDim2.new(1, 0, 0, 24),
	}, body)
	labels.Top = label({ Position = UDim2.fromOffset(0, 122), Size = UDim2.new(1, 0, 0, 22) }, body)
	labels.Mine = label(
		{ TextColor3 = UI.Soft, Position = UDim2.fromOffset(0, 146), Size = UDim2.new(1, 0, 0, 22) },
		body
	)

	bidBox = make("TextBox", {
		Text = "",
		PlaceholderText = "Your bid",
		ClearTextOnFocus = false,
		Font = Palette.Font.Body,
		TextSize = 16,
		TextColor3 = UI.Text,
		BackgroundColor3 = UI.Input,
		Position = UDim2.fromOffset(0, 178),
		Size = UDim2.new(0.55, -8, 0, 36),
	}, body)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, bidBox)
	local bidButton = make("TextButton", {
		Text = "Bid",
		Font = Palette.Font.Title,
		TextSize = 17,
		TextColor3 = UI.Text,
		BackgroundColor3 = UI.Buy,
		Position = UDim2.new(0.55, 0, 0, 178),
		Size = UDim2.new(0.45, 0, 0, 36),
	}, body)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, bidButton)
	bidButton.Activated:Connect(function()
		if not state then
			return
		end
		local amount = tonumber(bidBox.Text)
		if not amount then
			HUD.notify("Type how many coins to bid")
			return
		end
		local ok, reason = Remotes.get("AuctionBid"):InvokeServer(state.LotId, math.floor(amount))
		if reason then
			HUD.notify(reason)
		end
		if ok then
			bidBox.Text = ""
		end
	end)
	label({
		Text = "Your coins are held while you bid. If you don't win, they come back. The winning bid is gone for good. Rebirthing cancels your bid.",
		TextSize = 12,
		TextColor3 = UI.Muted,
		Position = UDim2.fromOffset(0, 220),
		Size = UDim2.new(1, 0, 0, 34),
	}, body)
	label({
		Text = "Recent winners",
		Font = Palette.Font.Title,
		TextSize = 16,
		TextColor3 = UI.Accent,
		Position = UDim2.fromOffset(0, 258),
		Size = UDim2.new(1, 0, 0, 22),
	}, body)
	labels.Recent =
		label({ TextSize = 13, Position = UDim2.fromOffset(0, 282), Size = UDim2.new(1, 0, 1, -282) }, body)
end

local function render()
	if not state then
		labels.Title.Text = "Global auction"
		labels.Note.Text = "Connecting..."
		return
	end
	local left = state.TimeLeft - (os.clock() - fetchedAt)
	labels.Title.Text = state.Name
	labels.Series.Text = if state.Of == 1
		then "One of a kind"
		else string.format("Numbered: %d of %d already won", state.Issued, state.Of)
	labels.Note.Text = state.Note .. "."
	labels.Time.Text = if state.Available
		then "Ends in " .. formatTime(left)
		else "Sold out: this lot can't be won"
	labels.Top.Text = if state.TopBid > 0
		then string.format("Top bid: %s by %s", formatNumber(state.TopBid), tostring(state.TopName))
		else "No bids yet. Starting bid " .. formatNumber(state.StartingBid)
	labels.Mine.Text = string.format(
		"Your bid: %s   ·   minimum next bid: %s",
		if state.MyBid > 0 then formatNumber(state.MyBid) else "none",
		formatNumber(state.MinNext)
	)
	if bidBox.Text == "" and not bidBox:IsFocused() then
		bidBox.PlaceholderText = "At least " .. formatNumber(state.MinNext)
	end
	local lines = {}
	for _, result in state.Recent or {} do
		local cosmetic = Gear.getCosmetic(result.ItemId)
		table.insert(
			lines,
			string.format(
				"%s won %s #%d of %d for %s",
				tostring(result.Winner),
				if cosmetic then cosmetic.Name else result.ItemId,
				result.Serial,
				result.Of,
				formatNumber(result.Amount)
			)
		)
	end
	labels.Recent.Text = if #lines > 0 then table.concat(lines, "\n") else "Nobody has won anything yet."
end

local function fetch()
	local ok, data = pcall(function()
		return Remotes.get("AuctionState"):InvokeServer()
	end)
	if ok and data then
		state = data
		fetchedAt = os.clock()
	end
end

local function setOpen(open: boolean)
	panel.Visible = open
	if open then
		task.spawn(function()
			fetch()
			render()
		end)
	end
end

function AuctionUI.init()
	local gui = make("ScreenGui", {
		Name = "Auction",
		ResetOnSpawn = false,
		DisplayOrder = 6,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local open = make("TextButton", {
		Text = "Auction (U)",
		Font = Palette.Font.Title,
		TextSize = 15,
		TextColor3 = UI.Text,
		BackgroundColor3 = Palette.Rarity.Auction,
		Size = UDim2.fromOffset(110, 34),
		Position = UDim2.new(0, 250, 1, -46),
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, open)
	open.Activated:Connect(function()
		setOpen(not panel.Visible)
	end)

	panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.8, 0),
		BackgroundColor3 = UI.Background,
		Visible = false,
	}, gui)
	make("UISizeConstraint", { MaxSize = Vector2.new(520, 470) }, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
	make("UIStroke", { Color = Palette.Rarity.Auction, Thickness = 2, Transparency = 0.2 }, panel)
	body = make(
		"Frame",
		{ BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 1, -24) },
		panel
	)
	local close = make("TextButton", {
		Text = "X",
		Font = Palette.Font.Title,
		TextSize = 16,
		TextColor3 = UI.Text,
		BackgroundColor3 = UI.Danger,
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.new(1, -44, 0, 10),
		ZIndex = 2,
	}, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
	close.Activated:Connect(function()
		setOpen(false)
	end)
	build()
	gui.Parent = player:WaitForChild("PlayerGui")

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.U then
			setOpen(not panel.Visible)
		end
	end)

	task.spawn(function()
		while true do
			if panel.Visible then
				fetch()
			end
			for _ = 1, 4 do
				if panel.Visible then
					render()
				end
				task.wait(0.25)
			end
		end
	end)
end

return AuctionUI
