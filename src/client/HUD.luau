-- Placeholder UI for the test build: coins and gear, zone name, notifications, tide
-- warnings, breath bar, hold buttons for the assist grab, a hover tooltip and the shop.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local HUD = {}

local FONT = Enum.Font.FredokaOne
local BG = Color3.fromRGB(25, 45, 60)

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
local shopRows: Frame

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
		TextColor3 = Color3.new(1, 1, 1),
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
		TextColor3 = Color3.new(1, 1, 1),
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
	statsLabel.Text = string.format(
		"Coins: %s\nTool: %s\nVessel: %s",
		formatNumber(player:GetAttribute("Coins") or 0),
		tool.Name,
		if vessel then vessel.Name else "Arms"
	)
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
	tooltip.TextColor3 = color or Color3.new(1, 1, 1)
	tooltip.Position = UDim2.fromOffset(screenPosition.X + 16, screenPosition.Y + 8)
end

function HUD.setHoldButtons(visible: boolean, canSendToVessel: boolean?)
	holdButtons.Visible = visible
	local send = holdButtons:FindFirstChild("SendToVessel") :: TextButton
	send.Visible = canSendToVessel == true
end

function HUD.bindHoldButtons(drop: () -> (), sendToVessel: () -> ())
	onDrop = drop
	onSendToVessel = sendToVessel
end

local function owned(attribute: string): { [string]: boolean }
	local set = {}
	for id in string.gmatch(player:GetAttribute(attribute) or "", "[^,]+") do
		set[id] = true
	end
	return set
end

local function refreshShop()
	for _, child in shopRows:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local ownedTools = owned("OwnedTools")
	local ownedVessels = owned("OwnedVessels")
	local buyRemote = Remotes.get("Buy")
	local spawnRemote = Remotes.get("SpawnVessel")

	local order = 0
	local function row(category: string, entry)
		order += 1
		local frame = make("Frame", {
			Size = UDim2.new(1, -8, 0, 48),
			BackgroundColor3 = Color3.fromRGB(40, 70, 90),
			LayoutOrder = order,
		}, shopRows)
		corner(frame, 6)
		local detail = entry.Note or ""
		if category == "Tool" then
			detail = string.format(
				"Reach %d · lifts %s · %s",
				entry.Reach,
				({ "Light", "Medium", "Heavy", "Very heavy" })[entry.Lift],
				detail
			)
		else
			detail = string.format("Holds %d · %s", entry.Capacity, detail)
		end
		text({
			Text = entry.Name,
			Size = UDim2.new(0.62, 0, 0.55, 0),
			Position = UDim2.fromOffset(10, 2),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, frame)
		text({
			Text = detail,
			Size = UDim2.new(0.62, 0, 0.4, 0),
			Position = UDim2.new(0, 10, 0.55, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(200, 220, 230),
		}, frame)

		local isOwned = if category == "Tool" then ownedTools[entry.Id] else ownedVessels[entry.Id]
		local label, color, action
		if not entry.Available then
			label, color = "Coming later", Color3.fromRGB(90, 90, 90)
		elseif isOwned and category == "Vessel" then
			label, color = "Spawn", Color3.fromRGB(60, 140, 220)
			action = function()
				return spawnRemote:InvokeServer(entry.Id)
			end
		elseif isOwned then
			label, color = "Owned", Color3.fromRGB(70, 120, 80)
		else
			label, color = formatNumber(entry.Price) .. " coins", Color3.fromRGB(230, 150, 40)
			action = function()
				return buyRemote:InvokeServer(category, entry.Id)
			end
		end
		local b = button(label, color, frame)
		b.Size = UDim2.new(0.34, 0, 0, 34)
		b.Position = UDim2.new(0.64, 0, 0.5, -17)
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
		end
	end

	for _, tool in Gear.Tools do
		if tool.Price > 0 then
			row("Tool", tool)
		end
	end
	for _, vessel in Gear.Vessels do
		row("Vessel", vessel)
	end
end

function HUD.openShop()
	refreshShop()
	shopFrame.Visible = true
end

function HUD.init()
	gui = make("ScreenGui", { Name = "SalvageHUD", ResetOnSpawn = false, IgnoreGuiInset = false })

	statsLabel = text({
		Size = UDim2.fromOffset(260, 80),
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
		TextColor3 = Color3.fromRGB(255, 240, 200),
	}, gui)

	toastList = make("Frame", {
		Size = UDim2.new(0, 360, 0, 200),
		Position = UDim2.new(0.5, -180, 1, -330),
		BackgroundTransparency = 1,
	}, gui)
	make("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, toastList)

	breathFrame = make("Frame", {
		Size = UDim2.new(0, 240, 0, 14),
		Position = UDim2.new(0.5, -120, 1, -110),
		BackgroundColor3 = Color3.fromRGB(20, 30, 40),
		Visible = false,
	}, gui)
	corner(breathFrame, 7)
	breathFill = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(120, 210, 255),
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
	local drop = button("Drop", Color3.fromRGB(200, 80, 70), holdButtons)
	drop.Name = "Drop"
	drop.Size = UDim2.new(1, 0, 0, 44)
	drop.Activated:Connect(function()
		onDrop()
	end)
	local send = button("To vessel", Color3.fromRGB(60, 140, 220), holdButtons)
	send.Name = "SendToVessel"
	send.Size = UDim2.new(1, 0, 0, 44)
	send.Activated:Connect(function()
		onSendToVessel()
	end)

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
		TextColor3 = Color3.fromRGB(255, 255, 160),
		Visible = false,
	}, gui)

	-- Shop panel.
	shopFrame = make("Frame", {
		Size = UDim2.new(0, 460, 0.7, 0),
		Position = UDim2.new(0.5, -230, 0.15, 0),
		BackgroundColor3 = BG,
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 2,
	}, gui)
	corner(shopFrame, 12)
	text({
		Text = "Shopkeeper",
		Size = UDim2.new(1, 0, 0, 40),
		TextSize = 26,
	}, shopFrame)
	local close = button("X", Color3.fromRGB(200, 80, 70), shopFrame)
	close.Size = UDim2.fromOffset(32, 32)
	close.Position = UDim2.new(1, -40, 0, 6)
	close.Activated:Connect(function()
		shopFrame.Visible = false
	end)
	shopRows = make("ScrollingFrame", {
		Size = UDim2.new(1, -16, 1, -56),
		Position = UDim2.fromOffset(8, 48),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 6,
	}, shopFrame)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, shopRows)

	gui.Parent = player:WaitForChild("PlayerGui")

	for _, attribute in { "Coins", "Tool", "ActiveVessel" } do
		player:GetAttributeChangedSignal(attribute):Connect(refreshStats)
	end
	for _, attribute in { "Coins", "OwnedTools", "OwnedVessels" } do
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
		breathFill.BackgroundColor3 = if breath < 0.25
			then Color3.fromRGB(255, 90, 80)
			else Color3.fromRGB(120, 210, 255)
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
