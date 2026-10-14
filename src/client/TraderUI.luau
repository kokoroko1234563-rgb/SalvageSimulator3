-- The special trader window: who they are, what they sell, what the next level costs, and
-- how many of their items you've brought. Opens when you talk to a trader.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer
local UI = Palette.UI

local TraderUI = {}

local panel: Frame
local body: Frame

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

local function show(offer)
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	panel.Visible = true

	label(
		{ Text = offer.Name, Font = Palette.Font.Title, TextSize = 24, Size = UDim2.new(1, -50, 0, 30) },
		body
	)
	label({
		Text = '"' .. offer.Greeting .. '"',
		TextColor3 = UI.Muted,
		Font = Palette.Font.Body,
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 40),
	}, body)
	label({
		Text = string.format("%s  ·  level %d/%d", offer.Upgrade, offer.Level, offer.MaxLevel),
		Font = Palette.Font.Title,
		TextSize = 19,
		TextColor3 = UI.Accent,
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 0, 24),
	}, body)
	label({
		Text = offer.Effect .. (if offer.Permanent
			then ". Never lost."
			else ". Kept through rebirths, lost on a true rebirth."),
		TextSize = 13,
		TextColor3 = UI.Soft,
		Position = UDim2.fromOffset(0, 106),
		Size = UDim2.new(1, 0, 0, 34),
	}, body)

	local canBuy = false
	local costText
	if offer.Level >= offer.MaxLevel then
		costText = "Maxed out."
	elseif offer.BoughtThisVisit then
		costText = "One level per visit. Come back the next time they appear."
	else
		local parts = {}
		if offer.Coins > 0 then
			table.insert(parts, formatNumber(offer.Coins) .. " coins")
		end
		if offer.Items > 0 then
			table.insert(
				parts,
				string.format("%d %s (you've brought %d)", offer.Items, offer.ItemName, offer.ItemsHere)
			)
		end
		if offer.Cores > 0 then
			table.insert(parts, offer.Cores .. " attunement core" .. (if offer.Cores == 1 then "" else "s"))
		end
		costText = "Next level costs: " .. table.concat(parts, " + ")
		canBuy = true
	end
	label({
		Text = costText,
		Position = UDim2.fromOffset(0, 146),
		Size = UDim2.new(1, 0, 0, 44),
	}, body)
	if offer.Items > 0 and canBuy then
		label({
			Text = "Items count if they're near the trader, in your vessel, held, or in your pockets.",
			TextSize = 12,
			TextColor3 = UI.Muted,
			Position = UDim2.fromOffset(0, 190),
			Size = UDim2.new(1, 0, 0, 30),
		}, body)
	end

	local buy = make("TextButton", {
		Text = if canBuy then "Buy level " .. (offer.Level + 1) else "Can't buy",
		Font = Palette.Font.Title,
		TextSize = 16,
		TextColor3 = UI.Text,
		BackgroundColor3 = if canBuy then UI.Buy else UI.Disabled,
		AutoButtonColor = canBuy,
		Size = UDim2.fromOffset(170, 40),
		Position = UDim2.new(0, 0, 1, -42),
	}, body)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, buy)
	if canBuy then
		buy.Activated:Connect(function()
			local ok, reason = Remotes.get("TraderBuy"):InvokeServer(offer.EncounterId)
			if not ok and reason then
				HUD.notify(reason)
			end
		end)
	end
end

function TraderUI.init()
	local gui = make("ScreenGui", {
		Name = "Trader",
		ResetOnSpawn = false,
		DisplayOrder = 7,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0, 300),
		BackgroundColor3 = UI.Background,
		Visible = false,
	}, gui)
	make("UISizeConstraint", { MaxSize = Vector2.new(480, 300) }, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
	make("UIStroke", { Color = UI.Accent, Thickness = 2, Transparency = 0.3 }, panel)
	body = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -32, 1, -24),
	}, panel)
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
		panel.Visible = false
	end)
	gui.Parent = player:WaitForChild("PlayerGui")

	Remotes.get("TraderOpen").OnClientEvent:Connect(show)
end

return TraderUI
