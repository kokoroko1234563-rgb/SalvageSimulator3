-- Puts each player's chosen cosmetic on their character. Cosmetics are hats described by
-- a shape in Gear.Cosmetics, built here as an Accessory on the head's HatAttachment.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)
local Palette = require(Shared.Palette)

local CosmeticService = {}

local WORN = "WornCosmetic"

local function part(parent: Instance, name: string, size: Vector3, hat): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = size -- a cylinder's length is along X
	p.Color = hat.Color
	p.Material = Palette.Material[hat.Material]
	p.CanCollide = false
	p.Massless = true
	p.Parent = parent
	return p
end

-- Builds a cosmetic hat as an Accessory: its bottom sits on the head and its height (the
-- cylinder's X axis) points up.
function CosmeticService.build(cosmetic): Accessory
	local hat = cosmetic.Hat
	local accessory = Instance.new("Accessory")
	accessory.Name = WORN
	accessory:SetAttribute("CosmeticId", cosmetic.Id)
	local handle = part(accessory, "Handle", Vector3.new(hat.Height, hat.Width, hat.Width), hat)
	if hat.Brim then
		local brim = part(accessory, "Brim", Vector3.new(0.15, hat.Brim, hat.Brim), hat)
		brim.CFrame = handle.CFrame * CFrame.new(-hat.Height / 2, 0, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = brim
		weld.Parent = handle
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "HatAttachment"
	attachment.CFrame = CFrame.new(-hat.Height / 2, 0, 0) * CFrame.Angles(0, 0, math.rad(-90))
	attachment.Parent = handle
	return accessory
end

function CosmeticService.dress(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then
		return
	end
	local old = character:FindFirstChild(WORN)
	if old then
		old:Destroy()
	end
	local cosmetic = Gear.getCosmetic(player:GetAttribute("Cosmetic"))
	if cosmetic then
		humanoid:AddAccessory(CosmeticService.build(cosmetic))
	end
end

function CosmeticService.init()
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid")
			CosmeticService.dress(player)
		end)
		player:GetAttributeChangedSignal("Cosmetic"):Connect(function()
			CosmeticService.dress(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return CosmeticService
