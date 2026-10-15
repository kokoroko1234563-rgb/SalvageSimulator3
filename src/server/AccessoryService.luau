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
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local old = root:FindFirstChild(LIGHT)
	if old then
		old:Destroy()
	end
	local worn = Gear.getAccessory(player:GetAttribute("Accessory"))
	if worn and worn.Light then
		local light = Instance.new("PointLight")
		light.Name = LIGHT
		light.Color = worn.Light.Color
		light.Range = worn.Light.Range
		light.Brightness = worn.Light.Brightness
		light.Shadows = false
		light.Parent = root
	end
end

function AccessoryService.init()
	local function onPlayer(player: Player)
		player:GetAttributeChangedSignal("Accessory"):Connect(function()
			AccessoryService.apply(player)
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			AccessoryService.apply(player)
		end)
		AccessoryService.apply(player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return AccessoryService
