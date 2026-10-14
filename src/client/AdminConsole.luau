-- Admin console. Only built for players the server marks as admins (IsAdmin attribute);
-- every command is still checked again on the server.
-- Open with F2 (or the "Admin" button), type a command, press Enter. Up/Down for history.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local AdminConsole = {}

local FONT = Enum.Font.Code
local BG = Color3.fromRGB(18, 24, 30)
local ACCENT = Color3.fromRGB(255, 215, 120)
local MAX_LINES = 200

local panel: Frame
local log: ScrollingFrame
local input: TextBox
local hint: TextLabel
local remote: RemoteFunction

local history: { string } = {}
local historyIndex = 0
local lineCount = 0
local usages: { string } = {}

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

local function addLine(text: string, color: Color3?)
	lineCount += 1
	make("TextLabel", {
		Text = text,
		Font = FONT,
		TextSize = 15,
		TextColor3 = color or Color3.fromRGB(220, 230, 235),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -10, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = lineCount,
	}, log)
	local labels = {}
	for _, child in log:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	if #labels > MAX_LINES then
		table.sort(labels, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = 1, #labels - MAX_LINES do
			labels[i]:Destroy()
		end
	end
	task.defer(function()
		log.CanvasPosition = Vector2.new(0, math.huge)
	end)
end

local function run(line: string)
	line = line:match("^%s*(.-)%s*$") or ""
	if line == "" then
		return
	end
	if history[#history] ~= line then
		table.insert(history, line)
	end
	historyIndex = #history + 1
	addLine("> " .. line, ACCENT)
	if line:lower() == "clear" then
		for _, child in log:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		return
	end
	local ok, result = pcall(remote.InvokeServer, remote, line)
	if not ok then
		addLine("Error: " .. tostring(result), Color3.fromRGB(255, 120, 110))
		return
	end
	for _, out in result or {} do
		local isError = out:sub(1, 6) == "Error:" or out:sub(1, 7) == "Unknown" or out:sub(1, 6) == "Usage:"
		addLine(out, if isError then Color3.fromRGB(255, 160, 120) else nil)
	end
end

local function updateHint()
	local word = (input.Text:match("^%s*(%S*)") or ""):lower()
	if word == "" then
		hint.Text = "Type help for the command list"
		return
	end
	local matches = {}
	for _, usage in usages do
		if usage:lower():sub(1, #word) == word then
			table.insert(matches, usage)
		end
		if #matches >= 3 then
			break
		end
	end
	hint.Text = if #matches > 0 then table.concat(matches, "    ") else "No matching command"
end

local function setOpen(open: boolean)
	panel.Visible = open
	if open then
		task.defer(function()
			input:CaptureFocus()
		end)
	else
		input:ReleaseFocus()
	end
end

local function build()
	remote = Remotes.get("AdminCommand")

	local gui = make("ScreenGui", {
		Name = "AdminConsole",
		ResetOnSpawn = false,
		DisplayOrder = 50,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local toggle = make("TextButton", {
		Text = "Admin",
		Font = Enum.Font.FredokaOne,
		TextSize = 16,
		TextColor3 = BG,
		BackgroundColor3 = ACCENT,
		Size = UDim2.fromOffset(70, 30),
		Position = UDim2.new(1, -82, 0, 12),
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, toggle)

	panel = make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.new(0.95, -12, 0.45, 0),
		BackgroundColor3 = BG,
		BackgroundTransparency = 0.05,
		Visible = false,
	}, gui)
	make("UISizeConstraint", { MaxSize = Vector2.new(640, 360), MinSize = Vector2.new(280, 200) }, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	make("UIStroke", { Color = ACCENT, Thickness = 1.5, Transparency = 0.3 }, panel)

	make("TextLabel", {
		Text = "ADMIN CONSOLE   (F2 to toggle)",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -50, 0, 24),
		Position = UDim2.fromOffset(12, 4),
	}, panel)
	local close = make("TextButton", {
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(200, 80, 70),
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -32, 0, 6),
	}, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, close)

	log = make("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 30),
		Size = UDim2.new(1, -20, 1, -96),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = ACCENT,
	}, panel)
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, log)

	input = make("TextBox", {
		Text = "",
		PlaceholderText = "Type a command, e.g. help",
		PlaceholderColor3 = Color3.fromRGB(120, 135, 145),
		ClearTextOnFocus = false,
		Font = FONT,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(32, 42, 52),
		Position = UDim2.new(0, 10, 1, -62),
		Size = UDim2.new(1, -20, 0, 32),
	}, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, input)
	make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, input)

	hint = make("TextLabel", {
		Text = "Type help for the command list",
		Font = FONT,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(150, 165, 175),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 1, -26),
		Size = UDim2.new(1, -24, 0, 20),
	}, panel)

	gui.Parent = player:WaitForChild("PlayerGui")

	toggle.Activated:Connect(function()
		setOpen(not panel.Visible)
	end)
	close.Activated:Connect(function()
		setOpen(false)
	end)
	input:GetPropertyChangedSignal("Text"):Connect(updateHint)
	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local line = input.Text
			input.Text = ""
			run(line)
			input:CaptureFocus()
		end
	end)

	UserInputService.InputBegan:Connect(function(key)
		if key.KeyCode == Enum.KeyCode.F2 then
			setOpen(not panel.Visible)
			return
		end
		if not input:IsFocused() or #history == 0 then
			return
		end
		if key.KeyCode == Enum.KeyCode.Up then
			historyIndex = math.max(1, historyIndex - 1)
		elseif key.KeyCode == Enum.KeyCode.Down then
			historyIndex = math.min(#history + 1, historyIndex + 1)
		else
			return
		end
		input.Text = history[historyIndex] or ""
		input.CursorPosition = #input.Text + 1
	end)

	-- Learn the command list for the typing hint.
	task.spawn(function()
		local ok, lines = pcall(remote.InvokeServer, remote, "help")
		if ok and lines then
			for _, line in lines do
				local usage = line:match("^(.-)%s+—")
				if usage then
					table.insert(usages, usage)
				end
			end
		end
	end)

	addLine("Admin console ready. Type help.", ACCENT)
end

function AdminConsole.init()
	local built = false
	local function check()
		if not built and player:GetAttribute("IsAdmin") then
			built = true
			build()
		end
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(check)
	check()
end

return AdminConsole
