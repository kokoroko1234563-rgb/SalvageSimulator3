-- Placeholder UI for the test build: coins and gear, zone name, notifications, tide
-- warnings, breath bar, hold buttons for the assist grab, a hover tooltip and the shop.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)
local Config = require(Shared.Config)
local Gear = require(Shared.Gear)
local Rebirth = require(Shared.Rebirth)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local HUD = {}

local FONT = Palette.Font.Title
local BG = Palette.UI.Background

local gui: ScreenGui
local statsLabel: TextLabel
local zoneLabel: TextLabel
local toastList: Frame
local bannerLabel: TextLabel
local breathFrame: Frame
local breathFill: Frame
local holdButtons: Frame
local tooltip: TextLabel
local debugLabel: TextLabel
local shopFrame: Frame
local shopRows: ScrollingFrame
local shopCoinsLabel: TextLabel

local rewardFrame: Frame
local onPocket: () -> () = function() end
local onDrop: () -> () = function() end
local onSendToVessel: () -> () = function() end

local function formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end
HUD.formatNumber = formatNumber

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

local function text(props: { [string]: any }, parent: Instance): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = FONT,
		TextColor3 = Palette.UI.Text,
		TextStrokeTransparency = 0.6,
		TextScaled = false,
		TextSize = 18,
	}
	for key, value in props do
		defaults[key] = value
	end
	return make("TextLabel", defaults, parent)
end

local function button(label: string, color: Color3, parent: Instance): TextButton
	local b = make("TextButton", {
		Text = label,
		Font = FONT,
		TextSize = 18,
		TextColor3 = Palette.UI.Text,
		BackgroundColor3 = color,
		AutoButtonColor = true,
	}, parent)
	corner(b)
	return b
end

local function refreshStats()
	local tool = Gear.getTool(player:GetAttribute("Tool"))
	local vesselId = player:GetAttribute("ActiveVessel")
	local vessel = vesselId and Gear.getVessel(vesselId)
	local lines = {
		"Coins: " .. formatNumber(player:GetAttribute("Coins") or 0),
		"Tool: " .. tool.Name,
		"Vessel: " .. (if vessel then vessel.Name else "Arms"),
	}
	local rebirths = player:GetAttribute("Rebirths") or 0
	if rebirths > 0 then
		table.insert(
			lines,
			string.format("Rebirths: %d (coins x%.1f)", rebirths, player:GetAttribute("Multiplier") or 1)
		)
	end
	local slots = player:GetAttribute("PocketSlots") or 0
	if slots > 0 then
		table.insert(lines, string.format("Pockets: %d/%d", player:GetAttribute("Pockets") or 0, slots))
	end
	local cores = player:GetAttribute("Cores") or 0
	if cores > 0 then
		table.insert(lines, string.format("Attunement cores: %d", cores))
	end
	statsLabel.Text = table.concat(lines, "\n")
end

-- The reward choice after a rebirth stays up until one is picked.
local function refreshRewardPick()
	for _, child in rewardFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local options = {}
	for id in string.gmatch(player:GetAttribute("PendingPick") or "", "[^,]+") do
		table.insert(options, id)
	end
	rewardFrame.Visible = #options > 0
	for index, id in options do
		local reward = Rebirth.Rewards[id]
		local choice = make("TextButton", {
			Text = "",
			BackgroundColor3 = Palette.UI.CardRaised,
			Size = UDim2.new(1, -24, 0, 70),
			Position = UDim2.new(0, 12, 0, 50 + (index - 1) * 78),
			AutoButtonColor = true,
		}, rewardFrame)
		corner(choice, 8)
		text({
			Text = reward.Name .. "  ·  " .. reward.Type,
			Size = UDim2.new(1, -20, 0, 26),
			Position = UDim2.fromOffset(10, 6),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 20,
			TextStrokeTransparency = 1,
		}, choice)
		text({
			Text = reward.Description,
			Size = UDim2.new(1, -20, 0, 34),
			Position = UDim2.fromOffset(10, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			TextSize = 14,
			Font = Palette.Font.Body,
			TextStrokeTransparency = 1,
			TextColor3 = Palette.UI.Soft,
		}, choice)
		choice.Activated:Connect(function()
			local ok, reason = Remotes.get("ChooseReward"):InvokeServer(id)
			if not ok and reason then
				HUD.notify(reason)
			end
		end)
	end
	rewardFrame.Size = UDim2.fromOffset(420, 60 + #options * 78)
end

function HUD.notify(message: string)
	local toast = text({
		Text = message,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 0.35,
		BackgroundColor3 = BG,
		TextSize = 18,
	}, toastList)
	corner(toast)
	task.delay(3, function()
		local tween = TweenService:Create(
			toast,
			TweenInfo.new(0.5),
			{ TextTransparency = 1, BackgroundTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Wait()
		toast:Destroy()
	end)
	local toasts = toastList:GetChildren()
	local count = 0
	for _, child in toasts do
		if child:IsA("TextLabel") then
			count += 1
		end
	end
	if count > 5 then
		for _, child in toasts do
			if child:IsA("TextLabel") and child ~= toast then
				child:Destroy()
				break
			end
		end
	end
end

local bannerToken = 0
function HUD.banner(message: string)
	bannerToken += 1
	local token = bannerToken
	bannerLabel.Text = message
	bannerLabel.TextTransparency = 0
	bannerLabel.TextStrokeTransparency = 0.3
	task.delay(5, function()
		if token == bannerToken then
			TweenService
				:Create(bannerLabel, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 })
				:Play()
		end
	end)
end

function HUD.setZone(message: string)
	zoneLabel.Text = message
end

function HUD.setDebug(message: string?)
	debugLabel.Visible = message ~= nil
	debugLabel.Text = message or ""
end

function HUD.setTooltip(message: string?, color: Color3?, screenPosition: Vector2?)
	if not message or not screenPosition then
		tooltip.Visible = false
		return
	end
	tooltip.Visible = true
	tooltip.Text = message
	tooltip.TextColor3 = color or Palette.UI.Text
	tooltip.Position = UDim2.fromOffset(screenPosition.X + 16, screenPosition.Y + 8)
end

function HUD.setHoldButtons(visible: boolean, canSendToVessel: boolean?, canPocket: boolean?)
	holdButtons.Visible = visible
	local send = holdButtons:FindFirstChild("SendToVessel") :: TextButton
	send.Visible = canSendToVessel == true
	local pocket = holdButtons:FindFirstChild("Pocket") :: TextButton
	pocket.Visible = canPocket == true
end

function HUD.bindHoldButtons(drop: () -> (), sendToVessel: () -> (), pocket: () -> ())
	onDrop = drop
	onSendToVessel = sendToVessel
	onPocket = pocket
end

local function owned(attribute: string): { [string]: boolean }
	local set = {}
	for id in string.gmatch(player:GetAttribute(attribute) or "", "[^,]+") do
		set[id] = true
	end
	return set
end

local CLASS_NAMES = { "Light", "Medium", "Heavy", "Very heavy" }
local DEPTH_NAMES =
	{ [0] = "Dry sand", [1] = "Shallows", [2] = "Knee-deep", [3] = "Waist-deep", [4] = "Deep" }

local ROW_BG = Palette.UI.Card
local MUTED = Palette.UI.Muted
local BUY = Palette.UI.Buy
local DISABLED = Palette.UI.Disabled

local function sectionHeader(label: string, order: number)
	text({
		Text = label,
		Size = UDim2.new(1, -8, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 15,
		TextColor3 = Palette.UI.Accent,
		TextStrokeTransparency = 1,
		LayoutOrder = order,
	}, shopRows)
end

-- Robux prices come from Roblox, so they're fetched once and cached.
local priceCache: { [string]: number } = {}
local function robuxPrice(kind: "product" | "pass", id: number, callback: (number) -> ())
	local key = kind .. id
	if priceCache[key] then
		callback(priceCache[key])
		return
	end
	task.spawn(function()
		local ok, info = pcall(
			MarketplaceService.GetProductInfo,
			MarketplaceService,
			id,
			if kind == "product" then Enum.InfoType.Product else Enum.InfoType.GamePass
		)
		if ok and info and type(info.PriceInRobux) == "number" then
			priceCache[key] = info.PriceInRobux
			callback(info.PriceInRobux)
		end
	end)
end

local function refreshShop()
	for _, child in shopRows:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local coins = player:GetAttribute("Coins") or 0
	shopCoinsLabel.Text = formatNumber(coins) .. " coins"

	local ownedTools = owned("OwnedTools")
	local ownedVessels = owned("OwnedVessels")
	local buyRemote = Remotes.get("Buy")

	local order = 0
	local function row(category: string, entry)
		order += 1
		local available = entry.Available or (entry.Magical and ownedVessels[entry.Id])
		local frame = make("Frame", {
			Size = UDim2.new(1, -8, 0, if available then 70 else 40),
			BackgroundColor3 = ROW_BG,
			BackgroundTransparency = if available then 0 else 0.5,
			LayoutOrder = order,
		}, shopRows)
		corner(frame, 8)

		text({
			Text = entry.Name,
			Size = UDim2.new(1, -160, 0, 26),
			Position = UDim2.fromOffset(12, if available then 6 else 7),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 20,
			TextStrokeTransparency = 1,
			TextColor3 = if available then Palette.UI.Text else MUTED,
		}, frame)

		if not available then
			text({
				Text = "Coming later",
				Size = UDim2.new(0, 140, 1, 0),
				Position = UDim2.new(1, -152, 0, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextSize = 15,
				Font = Palette.Font.Body,
				TextStrokeTransparency = 1,
				TextColor3 = MUTED,
			}, frame)
			return
		end

		local stats = if category == "Tool"
			then string.format(
				"Reach %d  ·  Lifts %s  ·  %s",
				entry.Reach,
				CLASS_NAMES[entry.Lift],
				DEPTH_NAMES[entry.Depth]
			)
			else string.format("Holds %d items", entry.Capacity)
		text({
			Text = stats .. "\n" .. (entry.Note or ""),
			Size = UDim2.new(1, -160, 0, 34),
			Position = UDim2.fromOffset(12, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 14,
			TextWrapped = true,
			Font = Palette.Font.Body,
			TextStrokeTransparency = 1,
			TextColor3 = MUTED,
		}, frame)

		local label, color, action
		if coins >= entry.Price then
			label, color = "Buy · " .. formatNumber(entry.Price), BUY
			action = function()
				return buyRemote:InvokeServer(category, entry.Id)
			end
		else
			label, color = formatNumber(entry.Price) .. " coins", DISABLED
		end

		local b = button(label, color, frame)
		b.Size = UDim2.fromOffset(136, 40)
		b.Position = UDim2.new(1, -148, 0.5, -20)
		b.TextSize = 17
		if action then
			b.Activated:Connect(function()
				local ok, reason = action()
				if not ok and reason then
					HUD.notify(reason)
				end
				refreshShop()
			end)
		else
			b.AutoButtonColor = false
			b.TextColor3 = Palette.UI.DisabledText
		end
	end

	-- Rebirth
	order += 1
	sectionHeader("REBIRTH", order)
	do
		order += 1
		local rebirths = player:GetAttribute("Rebirths") or 0
		local cost = Rebirth.cost(rebirths)
		local pending = (player:GetAttribute("PendingPick") or "") ~= ""
		local frame = make("Frame", {
			Size = UDim2.new(1, -8, 0, 70),
			BackgroundColor3 = ROW_BG,
			LayoutOrder = order,
		}, shopRows)
		corner(frame, 8)
		text({
			Text = "Rebirth #" .. (rebirths + 1),
			Size = UDim2.new(1, -160, 0, 26),
			Position = UDim2.fromOffset(12, 6),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 20,
			TextStrokeTransparency = 1,
		}, frame)
		text({
			Text = string.format(
				"Coins earn x%.1f, then x%.1f\nResets coins, tools and shop vessels",
				Rebirth.multiplier(rebirths),
				Rebirth.multiplier(rebirths + 1)
			),
			Size = UDim2.new(1, -160, 0, 34),
			Position = UDim2.fromOffset(12, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 14,
			TextWrapped = true,
			Font = Palette.Font.Body,
			TextStrokeTransparency = 1,
			TextColor3 = MUTED,
		}, frame)
		local affordable = coins >= cost and not pending
		local b = button(
			if pending
				then "Pick reward"
				elseif affordable then "Rebirth · " .. formatNumber(cost)
				else formatNumber(cost) .. " coins",
			if affordable then BUY else DISABLED,
			frame
		)
		b.Size = UDim2.fromOffset(136, 40)
		b.Position = UDim2.new(1, -148, 0.5, -20)
		b.TextSize = 15
		if affordable then
			b.Activated:Connect(function()
				local ok, reason = Remotes.get("Rebirth"):InvokeServer()
				if not ok and reason then
					HUD.notify(reason)
				end
				refreshShop()
			end)
		else
			b.AutoButtonColor = false
			b.TextColor3 = Palette.UI.DisabledText
		end
	end

	-- True rebirth: redeem the 5 colored coins.
	order += 1
	sectionHeader("TRUE REBIRTH", order)
	do
		order += 1
		local have = player:GetAttribute("ColoredCoinCount") or 0
		local frame = make("Frame", {
			Size = UDim2.new(1, -8, 0, 70),
			BackgroundColor3 = ROW_BG,
			LayoutOrder = order,
		}, shopRows)
		corner(frame, 8)
		make("UIStroke", { Color = Palette.Reset.TrueRebirth, Thickness = 2 }, frame)
		text({
			Text = string.format("Redeem colored coins (%d/5)", have),
			Size = UDim2.new(1, -160, 0, 26),
			Position = UDim2.fromOffset(12, 6),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 20,
			TextStrokeTransparency = 1,
		}, frame)
		text({
			Text = "Gives an attunement core. Resets coins, gear, rebirths, rewards and coins. Keeps unlock and exotic items.",
			Size = UDim2.new(1, -160, 0, 34),
			Position = UDim2.fromOffset(12, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			TextWrapped = true,
			Font = Palette.Font.Body,
			TextStrokeTransparency = 1,
			TextColor3 = MUTED,
		}, frame)
		local ready = have >= 5
		local b = button(
			if ready then "True rebirth" else have .. "/5 coins",
			if ready then Palette.UI.TrueRebirth else DISABLED,
			frame
		)
		b.Size = UDim2.fromOffset(136, 40)
		b.Position = UDim2.new(1, -148, 0.5, -20)
		b.TextSize = 15
		if ready then
			-- It wipes a lot, so it takes two clicks.
			local armed = false
			b.Activated:Connect(function()
				if not armed then
					armed = true
					b.Text = "Click to confirm"
					task.delay(4, function()
						if b.Parent then
							armed = false
							b.Text = "True rebirth"
						end
					end)
					return
				end
				local ok, reason = Remotes.get("TrueRebirth"):InvokeServer()
				if not ok and reason then
					HUD.notify(reason)
				end
				refreshShop()
			end)
		else
			b.AutoButtonColor = false
			b.TextColor3 = Palette.UI.DisabledText
		end
	end

	order += 1
	sectionHeader("GRABBING TOOLS", order)
	for _, tool in Gear.Tools do
		if tool.Price > 0 and not ownedTools[tool.Id] then
			row("Tool", tool)
		end
	end
	order += 1
	sectionHeader("VESSELS", order)
	for _, vessel in Gear.Vessels do
		if not vessel.Magical and not vessel.Exotic and not ownedVessels[vessel.Id] then
			row("Vessel", vessel)
		end
	end
	-- Robux: coin packs and gamepasses.
	order += 1
	sectionHeader("ROBUX", order)
	local passes = owned("Passes")
	local function robuxRow(name: string, note: string, id: number, kind: "product" | "pass", have: boolean)
		order += 1
		local frame = make("Frame", {
			Size = UDim2.new(1, -8, 0, 56),
			BackgroundColor3 = ROW_BG,
			LayoutOrder = order,
		}, shopRows)
		corner(frame, 8)
		text({
			Text = name,
			Size = UDim2.new(1, -160, 0, 24),
			Position = UDim2.fromOffset(12, 4),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 18,
			TextStrokeTransparency = 1,
		}, frame)
		text({
			Text = note,
			Size = UDim2.new(1, -160, 0, 22),
			Position = UDim2.fromOffset(12, 28),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 14,
			TextWrapped = true,
			Font = Palette.Font.Body,
			TextStrokeTransparency = 1,
			TextColor3 = MUTED,
		}, frame)
		local ready = id ~= 0 and not have
		local b = button(
			if have then "Owned" elseif id == 0 then "Not set up" else "Buy",
			if ready then Palette.UI.Robux else DISABLED,
			frame
		)
		b.Size = UDim2.fromOffset(136, 40)
		b.Position = UDim2.new(1, -148, 0.5, -20)
		b.TextSize = 16
		if not ready then
			b.AutoButtonColor = false
			b.TextColor3 = Palette.UI.DisabledText
			return
		end
		robuxPrice(kind, id, function(price)
			if b.Parent then
				b.Text = "R$ " .. formatNumber(price)
			end
		end)
		b.Activated:Connect(function()
			if kind == "product" then
				MarketplaceService:PromptProductPurchase(player, id)
			else
				MarketplaceService:PromptGamePassPurchase(player, id)
			end
		end)
	end
	for _, pack in Config.Monetization.CoinPacks do
		robuxRow(pack.Name, formatNumber(pack.Coins) .. " coins", pack.ProductId, "product", false)
	end
	for _, pass in Config.Monetization.Gamepasses do
		robuxRow(pass.Name, "Gamepass: " .. pass.Note, pass.PassId, "pass", passes[pass.Id] == true)
	end

	order += 1
	text({
		Text = "Gear you own is in your inventory (press I). Equip tools and spawn vessels from there.",
		Size = UDim2.new(1, -8, 0, 40),
		TextWrapped = true,
		TextSize = 14,
		Font = Palette.Font.Body,
		TextStrokeTransparency = 1,
		TextColor3 = MUTED,
		LayoutOrder = order,
	}, shopRows)
end

function HUD.openShop()
	refreshShop()
	shopFrame.Visible = true
end

function HUD.init()
	gui = make("ScreenGui", {
		Name = "SalvageHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		-- Children draw above their parents (code-made ScreenGuis default to Global).
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	statsLabel = text({
		Size = UDim2.fromOffset(300, 80),
		Position = UDim2.fromOffset(12, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 20,
		TextStrokeTransparency = 0.3,
	}, gui)

	zoneLabel = text({
		Size = UDim2.new(0, 400, 0, 30),
		Position = UDim2.new(0.5, -200, 0, 8),
		TextSize = 20,
		TextStrokeTransparency = 0.3,
	}, gui)

	bannerLabel = text({
		Size = UDim2.new(0.9, 0, 0, 50),
		Position = UDim2.new(0.05, 0, 0.18, 0),
		TextSize = 34,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		TextColor3 = Palette.UI.Banner,
	}, gui)

	toastList = make("Frame", {
		Size = UDim2.new(0, 360, 0, 200),
		Position = UDim2.new(0.5, -180, 1, -330),
		BackgroundTransparency = 1,
		ZIndex = 20, -- above the shop so purchase errors are visible
	}, gui)
	make("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, toastList)

	breathFrame = make("Frame", {
		Size = UDim2.new(0, 240, 0, 14),
		Position = UDim2.new(0.5, -120, 1, -110),
		BackgroundColor3 = Palette.UI.Track,
		Visible = false,
	}, gui)
	corner(breathFrame, 7)
	breathFill = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Palette.UI.Breath,
	}, breathFrame)
	corner(breathFill, 7)
	text(
		{ Text = "Breath", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, -20), TextSize = 14 },
		breathFrame
	)

	holdButtons = make("Frame", {
		Size = UDim2.fromOffset(150, 100),
		Position = UDim2.new(1, -170, 0.5, -50),
		BackgroundTransparency = 1,
		Visible = false,
	}, gui)
	make("UIListLayout", { Padding = UDim.new(0, 8) }, holdButtons)
	local drop = button("Drop", Palette.UI.Danger, holdButtons)
	drop.Name = "Drop"
	drop.Size = UDim2.new(1, 0, 0, 44)
	drop.Activated:Connect(function()
		onDrop()
	end)
	local send = button("To vessel", Palette.UI.Spawn, holdButtons)
	send.Name = "SendToVessel"
	send.Size = UDim2.new(1, 0, 0, 44)
	send.Activated:Connect(function()
		onSendToVessel()
	end)
	local pocket = button("Pocket (Q)", Palette.UI.Pocket, holdButtons)
	pocket.Name = "Pocket"
	pocket.Size = UDim2.new(1, 0, 0, 44)
	pocket.Visible = false
	pocket.Activated:Connect(function()
		onPocket()
	end)
	holdButtons.Size = UDim2.fromOffset(150, 150)

	rewardFrame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 300),
		BackgroundColor3 = BG,
		Visible = false,
		ZIndex = 15,
	}, gui)
	corner(rewardFrame, 12)
	make("UIStroke", { Color = Palette.UI.Accent, Thickness = 2 }, rewardFrame)
	text({
		Text = "Choose your rebirth reward",
		Size = UDim2.new(1, 0, 0, 44),
		TextSize = 24,
		TextStrokeTransparency = 1,
		TextColor3 = Palette.UI.Accent,
	}, rewardFrame)
	tooltip = text({
		Size = UDim2.fromOffset(260, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 16,
		TextStrokeTransparency = 0.2,
		Visible = false,
		ZIndex = 5,
	}, gui)

	debugLabel = text({
		Size = UDim2.fromOffset(300, 20),
		Position = UDim2.new(1, -310, 1, -28),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 14,
		TextColor3 = Palette.UI.Debug,
		Visible = false,
	}, gui)

	-- Shop panel.
	shopFrame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.8),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = BG,
		Visible = false,
		ZIndex = 10,
	}, gui)
	make("UISizeConstraint", { MaxSize = Vector2.new(540, 620) }, shopFrame)
	make("UIStroke", { Color = Palette.UI.Accent, Thickness = 2, Transparency = 0.3 }, shopFrame)
	corner(shopFrame, 12)
	text({
		Text = "Shopkeeper",
		Size = UDim2.new(0.5, 0, 0, 44),
		Position = UDim2.fromOffset(16, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 28,
		TextStrokeTransparency = 1,
	}, shopFrame)
	shopCoinsLabel = text({
		Size = UDim2.new(0.5, -70, 0, 44),
		Position = UDim2.new(0.5, 0, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 20,
		TextStrokeTransparency = 1,
		TextColor3 = Palette.UI.Accent,
	}, shopFrame)
	local close = button("X", Palette.UI.Danger, shopFrame)
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -48, 0, 10)
	close.Activated:Connect(function()
		shopFrame.Visible = false
	end)
	shopRows = make("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -66),
		Position = UDim2.fromOffset(12, 56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Palette.UI.Accent,
	}, shopFrame)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, shopRows)

	gui.Parent = player:WaitForChild("PlayerGui")

	for _, attribute in
		{
			"Coins",
			"Tool",
			"ActiveVessel",
			"Rebirths",
			"Multiplier",
			"Rewards",
			"Pockets",
			"PocketSlots",
			"Cores",
		}
	do
		player:GetAttributeChangedSignal(attribute):Connect(refreshStats)
	end
	player:GetAttributeChangedSignal("PendingPick"):Connect(refreshRewardPick)
	refreshRewardPick()
	for _, attribute in
		{
			"Coins",
			"Tool",
			"ActiveVessel",
			"OwnedTools",
			"OwnedVessels",
			"Rebirths",
			"PendingPick",
			"ColoredCoinCount",
			"Passes",
		}
	do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if shopFrame.Visible then
				refreshShop()
			end
		end)
	end
	refreshStats()

	player:GetAttributeChangedSignal("Breath"):Connect(function()
		local breath = player:GetAttribute("Breath") or 1
		breathFrame.Visible = breath < 0.999
		breathFill.Size = UDim2.fromScale(breath, 1)
		breathFill.BackgroundColor3 = if breath < 0.25 then Palette.UI.BreathLow else Palette.UI.Breath
	end)

	Remotes.get("Notify").OnClientEvent:Connect(HUD.notify)
	Remotes.get("OpenShop").OnClientEvent:Connect(HUD.openShop)

	-- Close the shop when walking away.
	RunService.Heartbeat:Connect(function()
		if not shopFrame.Visible then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local shopkeeper = workspace:FindFirstChild("Map") and workspace.Map.Shop:FindFirstChild("Shopkeeper")
		if root and shopkeeper and (root.Position - shopkeeper.Position).Magnitude > 26 then
			shopFrame.Visible = false
		end
	end)
end

return HUD
