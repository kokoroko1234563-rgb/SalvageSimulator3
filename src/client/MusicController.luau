-- Background music, chosen by where you are and the time of day (Config.Music). Each track
-- lists the places and times it fits; when you move somewhere it doesn't fit (or the day
-- turns), the music cross-fades to a track that does. When a track ends, another fitting one
-- follows after a short quiet gap. Each new track shows its title and the credit.
-- Muting (M, or the inventory setting) is saved on the profile.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Config = require(Shared.Config)
local DayCycle = require(Shared.DayCycle)
local Palette = require(Shared.Palette)
local Remotes = require(Shared.Remotes)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer
local cfg = Config.Music

local MusicController = {}

type Track = { Title: string, Artist: string?, SoundId: number, Places: { string }, Times: { string }? }

local muted = false
local current: { track: Track, sound: Sound }? = nil
local lastTitle: string? = nil
local quietUntil = 0
local toast: Frame
local toastTitle: TextLabel
local toastCredit: TextLabel

-- Where the player is, as a music place.
function MusicController.place(position: Vector3): string
	if position.Y > Config.Secrets.Origin.Y - 100 then
		return "Secret"
	elseif position.X > Config.Showroom.Origin.X - 1000 then
		return "Showroom"
	end
	local zone = Beach.zoneAt(position.Z)
	if not zone or zone <= 0 then
		return "Shop"
	elseif zone <= 2 then
		return "Shore"
	elseif zone <= 4 then
		return "Outer"
	end
	return "Sandbar"
end

local function fits(track: Track, place: string, time: string): boolean
	return table.find(track.Places, place) ~= nil
		and (track.Times == nil or table.find(track.Times, time) ~= nil)
end

-- Tracks that fit and have been uploaded (SoundId set).
function MusicController.candidates(place: string, time: string): { Track }
	local list = {}
	for _, track in cfg.Tracks do
		if track.SoundId ~= 0 and fits(track, place, time) then
			table.insert(list, track)
		end
	end
	return list
end

local function fade(sound: Sound, volume: number, destroyAfter: boolean)
	local tween = TweenService:Create(sound, TweenInfo.new(cfg.FadeTime), { Volume = volume })
	if destroyAfter then
		tween.Completed:Connect(function()
			sound:Destroy()
		end)
	end
	tween:Play()
end

local function showToast(title: string, artist: string?)
	toastTitle.Text = "♪  " .. title
	toastCredit.Text = artist or ""
	toast.Visible = true
	toast.BackgroundTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.6), { BackgroundTransparency = 0.25 }):Play()
	task.delay(6, function()
		if toastTitle.Text == "♪  " .. title then
			toast.Visible = false
		end
	end)
end

local function stop()
	if current then
		fade(current.sound, 0, true)
		current = nil
	end
end

local function play(track: Track)
	stop()
	local sound = Instance.new("Sound")
	sound.Name = "Music"
	sound.SoundId = "rbxassetid://" .. track.SoundId
	sound.Volume = 0
	sound.Parent = SoundService
	sound:Play()
	fade(sound, cfg.Volume, false)
	current = { track = track, sound = sound }
	lastTitle = track.Title
	showToast(track.Title, track.Artist)
	sound.Ended:Connect(function()
		if current and current.sound == sound then
			current = nil
			sound:Destroy()
			quietUntil = os.clock() + math.random(cfg.Gap[1], cfg.Gap[2])
		end
	end)
end

local function pick(list: { Track }): Track
	if #list > 1 then
		-- Not the one that just played.
		local others = {}
		for _, track in list do
			if track.Title ~= lastTitle then
				table.insert(others, track)
			end
		end
		list = others
	end
	return list[math.random(#list)]
end

local function update()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if muted or not root then
		stop()
		return
	end
	local place = MusicController.place(root.Position)
	local time = DayCycle.period(DayCycle.hour())
	if current then
		if not fits(current.track, place, time) then
			-- Somewhere new (or the day turned): cross-fade to something that fits.
			local list = MusicController.candidates(place, time)
			if #list > 0 then
				play(pick(list))
			else
				stop()
			end
		end
		return
	end
	if os.clock() < quietUntil then
		return
	end
	local list = MusicController.candidates(place, time)
	if #list > 0 then
		play(pick(list))
	end
end

local function setMuted(value: boolean, announce: boolean)
	if muted == value then
		return
	end
	muted = value
	if muted then
		stop()
	end
	if announce then
		HUD.notify(if muted then "Music off (M)" else "Music on (M)")
	end
end

function MusicController.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "NowPlaying"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0, 1)
	toast.Position = UDim2.new(0, 12, 1, -100)
	toast.Size = UDim2.fromOffset(300, 46)
	toast.BackgroundColor3 = Palette.UI.Background
	toast.BackgroundTransparency = 0.25
	toast.Visible = false
	toast.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	toastTitle = Instance.new("TextLabel")
	toastTitle.BackgroundTransparency = 1
	toastTitle.Position = UDim2.fromOffset(10, 4)
	toastTitle.Size = UDim2.new(1, -20, 0, 22)
	toastTitle.Font = Palette.Font.Bold
	toastTitle.TextSize = 16
	toastTitle.TextColor3 = Palette.UI.Text
	toastTitle.TextXAlignment = Enum.TextXAlignment.Left
	toastTitle.TextTruncate = Enum.TextTruncate.AtEnd
	toastTitle.Parent = toast
	local credit = Instance.new("TextLabel")
	credit.BackgroundTransparency = 1
	credit.Position = UDim2.fromOffset(10, 25)
	credit.Size = UDim2.new(1, -20, 0, 16)
	credit.Font = Palette.Font.Body
	credit.TextSize = 12
	credit.TextColor3 = Palette.UI.Muted
	credit.TextXAlignment = Enum.TextXAlignment.Left
	credit.Parent = toast
	toastCredit = credit

	-- The mute setting lives on the profile and arrives with the inventory.
	Remotes.get("InventorySync").OnClientEvent:Connect(function(snapshot)
		if snapshot and snapshot.Settings then
			setMuted(snapshot.Settings.MuteMusic == true, false)
		end
	end)
	task.spawn(function()
		local ok, snapshot = pcall(function()
			return Remotes.get("GetInventory"):InvokeServer()
		end)
		if ok and snapshot and snapshot.Settings then
			setMuted(snapshot.Settings.MuteMusic == true, false)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			setMuted(not muted, true)
			pcall(function()
				Remotes.get("InventoryAction"):InvokeServer("setting", "MuteMusic", muted)
			end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			update()
		end
	end)
end

return MusicController
