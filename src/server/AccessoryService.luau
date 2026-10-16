-- Visible effects of worn accessories that everyone should see: the glowing ones (Glow Pearl,
-- Lantern of Clear Sight, Ember Lantern) light up their wearer. Stat effects live in Stats;
-- the client-only ones (seeing through haze, wave warnings, the Prism Lens) in GearEffects.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)

local AccessoryService = {}

local LIGHT = "AccessoryLight"

function AccessoryService.apply(player: Player)
	local character = player.Character
	if not character then
		return
	end
	for _, old in character:GetDescendants() do
		if old.Name == LIGHT then
			old:Destroy()
		end
	end
	-- On the head (a headlamp, a lantern held up), or the root if there's no head yet.
	local holder = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	local worn = Gear.getAccessory(player:GetAttribute("Accessory"))
	if holder and worn and worn.Light then
		local light = Instance.new("PointLight")
		light.Name = LIGHT
		light.Color = worn.Light.Color
		light.Range = worn.Light.Range
		light.Brightness = worn.Light.Brightness
		light.Shadows = false
		light.Parent = holder
	end
end

-- The avatar's body loads after the character spawns and can replace its parts: whatever
-- was put on the old ones is left behind. Put it on again when the head or root changes.
local function rebuildOnNewParts(character: Model, rebuild: () -> ())
	local pending = false
	character.ChildAdded:Connect(function(child)
		if (child.Name == "Head" or child.Name == "HumanoidRootPart") and not pending then
			pending = true
			task.defer(function()
				pending = false
				rebuild()
			end)
		end
	end)
end

function AccessoryService.init()
	local function onPlayer(player: Player)
		player:GetAttributeChangedSignal("Accessory"):Connect(function()
			AccessoryService.apply(player)
		end)
		local function onCharacter(character: Model)
			rebuildOnNewParts(character, function()
				AccessoryService.apply(player)
			end)
			character:WaitForChild("HumanoidRootPart", 10)
			AccessoryService.apply(player)
		end
		player.CharacterAdded:Connect(onCharacter)
		player.CharacterAppearanceLoaded:Connect(function()
			AccessoryService.apply(player)
		end)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return AccessoryService
