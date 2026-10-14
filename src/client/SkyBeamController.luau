-- Draws the beam of light over the sky-beam item for this player. It follows the item
-- wherever it goes (in the surf, in someone's hands, in a vessel) until it's banked.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Palette = require(Shared.Palette)

local SkyBeamController = {}

local beams: { [BasePart]: Part } = {}

local function addBeam(item: Instance)
	if not item:IsA("BasePart") or beams[item] then
		return
	end
	local beam = Instance.new("Part")
	beam.Name = "SkyBeam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam.Material = Palette.Material.Neon
	beam.Color = Palette.Rarity.Unlock
	beam.Transparency = 0.45
	beam.Size = Vector3.new(2.5, Config.SkyBeam.Height, 2.5)
	beam.Parent = Workspace
	beams[item] = beam
end

local function removeBeam(item: Instance)
	local beam = beams[item :: BasePart]
	if beam then
		beam:Destroy()
		beams[item :: BasePart] = nil
	end
end

function SkyBeamController.init()
	for _, item in CollectionService:GetTagged("SkyBeam") do
		addBeam(item)
	end
	CollectionService:GetInstanceAddedSignal("SkyBeam"):Connect(addBeam)
	CollectionService:GetInstanceRemovedSignal("SkyBeam"):Connect(removeBeam)
	RunService.RenderStepped:Connect(function()
		for item, beam in beams do
			if item.Parent then
				beam.CFrame = CFrame.new(item.Position + Vector3.new(0, Config.SkyBeam.Height / 2, 0))
			else
				removeBeam(item)
			end
		end
	end)
end

return SkyBeamController
