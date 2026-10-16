-- The review panel, for admins in the review place only (Config.Review, ReviewService).
-- Shows where you are in the layouts' terms (zone, biome, crossing, slot and room), times
-- each zone you cross from its top edge to its bottom edge (saved with the variation), steps
-- through the variations, and takes notes pinned where you stand (N, or the Note button).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)
local Review = require(Shared.Review)

local player = Players.LocalPlayer

local ReviewUI = {}

local EDGE = 6 -- studs in from a zone's edge where the stopwatch starts and stops

local remote: RemoteFunction
local infoLabel: TextLabel
local timerLabel: TextLabel
local statusLabel: TextLabel
local noteFrame: Frame
local noteText: TextBox
local tagButtons: { [string]: TextButton } = {}
local ratingButtons: { TextButton } = {}
local selectedTags: { [string]: boolean } = {}
local rating: number? = nil

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

local function button(text: string, parent: Instance, onClick: () -> ()): TextButton
	local b = make("TextButton", {
		Text = text,
		Font = Palette.Font.Bold,
		TextSize = 13,
		TextColor3 = Palette.UI.Text,
		BackgroundColor3 = Palette.UI.Tab,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 26),
	}, parent)
	make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, b)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	b.Activated:Connect(onClick)
	return b
end

local function status(text: string)
	statusLabel.Text = text
end

local function act(action: string, arg: any?)
	task.spawn(function()
		local ok, result = remote:InvokeServer(action, arg)
		status((if ok then "" else "! ") .. tostring(result or ""))
	end)
end

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position
end

-- Where you are -------------------------------------------------------------------------------

local function describe(where): string
	if not where.Zone then
		return "Off the zones"
	end
	local lines = {
		string.format(
			"Zone %d · %s%s",
			where.Zone,
			where.ZoneName or "",
			if where.Biome then " · " .. where.Biome else ""
		),
	}
	if where.Crossing then
		table.insert(
			lines,
			string.format(
				"Crossing %d/%d%s   (%s)",
				where.Crossing,
				where.Crossings or 1,
				if where.CrossingName then ": " .. where.CrossingName else "",
				where.Choice or ""
			)
		)
	end
	if where.Slot then
		table.insert(
			lines,
			string.format(
				"Slot %s · room %d/%d%s",
				where.SlotName or tostring(where.Slot),
				where.Room or 1,
				where.Rooms or 1,
				if where.RoomName then ": " .. where.RoomName else ""
			)
		)
	end
	table.insert(lines, string.format("x %d, z %d", math.floor(where.X), math.floor(where.Z)))
	return table.concat(lines, "\n")
end

-- The stopwatch: from crossing a zone's top edge (going seaward) to reaching its bottom edge.
local timing: { zone: number, started: number }? = nil
local lastZ: number? = nil

local function updateTimer(position: Vector3)
	local z = position.Z
	local tile = Beach.tileAt(z)
	if lastZ and tile then
		local z0 = Beach.tileRange(tile)
		if lastZ < z0 + EDGE and z >= z0 + EDGE then
			timing = { zone = tile, started = os.clock() }
		end
	end
	if timing then
		local z0, z1 = Beach.tileRange(timing.zone)
		local seconds = os.clock() - timing.started
		local target = Config.Zones[timing.zone] and Config.Zones[timing.zone].CrossTime
		if z < z0 then
			timing = nil -- went back up: not a crossing
			timerLabel.Text = "Stopwatch: back up past the top edge, stopped"
		elseif z >= z1 - EDGE then
			timerLabel.Text = string.format(
				"Zone %d crossed in %.1f s (target %s s), saved",
				timing.zone,
				seconds,
				tostring(target)
			)
			act("time", { Zone = timing.zone, Seconds = seconds })
			timing = nil
		else
			timerLabel.Text =
				string.format("Zone %d: %.1f s (target %s s)", timing.zone, seconds, tostring(target))
		end
	end
	lastZ = z
end

-- Notes ---------------------------------------------------------------------------------------

local function refreshNoteButtons()
	for tag, b in tagButtons do
		b.BackgroundColor3 = if selectedTags[tag] then Palette.UI.Accent else Palette.UI.Tab
		b.TextColor3 = if selectedTags[tag] then Palette.UI.Console else Palette.UI.Text
	end
	for value, b in ratingButtons do
		b.BackgroundColor3 = if rating == value then Palette.UI.Accent else Palette.UI.Tab
		b.TextColor3 = if rating == value then Palette.UI.Console else Palette.UI.Text
	end
end

local function openNote()
	selectedTags, rating = {}, nil
	noteText.Text = ""
	refreshNoteButtons()
	noteFrame.Visible = true
	task.defer(function()
		noteText:CaptureFocus()
	end)
end

local function saveNote()
	local camera = Workspace.CurrentCamera
	local tags = {}
	for tag in selectedTags do
		table.insert(tags, tag)
	end
	act("note", {
		Text = noteText.Text,
		Tags = tags,
		Rating = rating,
		Look = camera and camera.CFrame.LookVector,
	})
	noteFrame.Visible = false
end

-- Building ------------------------------------------------------------------------------------

local function build()
	remote = Remotes.get("Review")
	local gui = make("ScreenGui", {
		Name = "ReviewUI",
		ResetOnSpawn = false,
		DisplayOrder = 40,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local panel = make("Frame", {
		Position = UDim2.fromOffset(12, 60),
		Size = UDim2.fromOffset(340, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Palette.UI.Console,
		BackgroundTransparency = 0.15,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	make("UIStroke", { Color = Palette.UI.Accent, Thickness = 1.5, Transparency = 0.3 }, panel)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, panel)
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, panel)

	local function label(order: number, color: Color3, font): TextLabel
		return make("TextLabel", {
			Text = "",
			Font = font or Palette.Font.Body,
			TextSize = 14,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			LayoutOrder = order,
		}, panel)
	end
	local title = label(1, Palette.UI.Accent, Palette.Font.Bold)
	title.Text = "REVIEW   (N: note)"
	infoLabel = label(2, Palette.UI.Text)
	timerLabel = label(3, Palette.UI.Soft)
	timerLabel.Text = "Stopwatch: starts at a zone's top edge"

	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
	}, panel)
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(104, 26),
		CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	button("◀ Crossing", row, function()
		act("crossing", -1)
	end)
	button("Crossing ▶", row, function()
		act("crossing", 1)
	end)
	button("Room ▶", row, function()
		act("room")
	end)
	button("Reroll", row, function()
		act("reroll")
	end)
	button("Biome ▶", row, function()
		act("biome")
	end)
	button("Zone top", row, function()
		act("top")
	end)
	button("Note", row, openNote)

	statusLabel = label(5, Palette.UI.Hint)

	-- The note dialog.
	noteFrame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Palette.UI.Console,
		Visible = false,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, noteFrame)
	make("UIStroke", { Color = Palette.UI.Accent, Thickness = 1.5 }, noteFrame)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, noteFrame)
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, noteFrame)
	make("TextLabel", {
		Text = "NOTE (pinned where you stand)",
		Font = Palette.Font.Bold,
		TextSize = 13,
		TextColor3 = Palette.UI.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 1,
	}, noteFrame)
	noteText = make("TextBox", {
		Text = "",
		PlaceholderText = "What's wrong or right here?",
		Font = Palette.Font.Body,
		TextSize = 14,
		TextColor3 = Palette.UI.Text,
		PlaceholderColor3 = Palette.UI.Placeholder,
		BackgroundColor3 = Palette.UI.Input,
		ClearTextOnFocus = false,
		MultiLine = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 70),
		LayoutOrder = 2,
	}, noteFrame)
	make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, noteText)
	local tags = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
	}, noteFrame)
	make("UIGridLayout", { CellSize = UDim2.fromOffset(96, 24), CellPadding = UDim2.fromOffset(4, 4) }, tags)
	for _, tag in Config.Review.Tags do
		tagButtons[tag] = button(tag, tags, function()
			selectedTags[tag] = not selectedTags[tag] or nil
			refreshNoteButtons()
		end)
	end
	local ratings = make("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
	}, noteFrame)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, ratings)
	make("TextLabel", {
		Text = "Rating",
		Font = Palette.Font.Body,
		TextSize = 13,
		TextColor3 = Palette.UI.Soft,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(50, 26),
	}, ratings)
	for value = 1, 5 do
		local b = button(tostring(value), ratings, function()
			rating = if rating == value then nil else value
			refreshNoteButtons()
		end)
		b.LayoutOrder = value
		ratingButtons[value] = b
	end
	local actions = make("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
	}, noteFrame)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
	}, actions)
	button("Cancel", actions, function()
		noteFrame.Visible = false
	end)
	local save = button("Save note", actions, saveNote)
	save.BackgroundColor3 = Palette.UI.Buy

	gui.Parent = player:WaitForChild("PlayerGui")

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == Enum.KeyCode.N and not noteFrame.Visible then
			openNote()
		end
	end)

	local elapsed = 1
	RunService.Heartbeat:Connect(function(dt)
		local position = rootPosition()
		if not position then
			return
		end
		updateTimer(position)
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			infoLabel.Text = describe(Review.where(position))
		end
	end)
end

function ReviewUI.init()
	if not Review.enabled() then
		return
	end
	-- Admins only: the server marks them (IsAdmin), and checks every action again.
	local built = false
	local function check()
		if not built and player:GetAttribute("IsAdmin") == true then
			built = true
			build()
		end
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(check)
	check()
end

return ReviewUI
