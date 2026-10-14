-- Helpers for building the map out of parts in code. Everything the map is made of comes from
-- here and the modules next to it (Buildings, BeachDressing): no Toolbox models and no assets
-- from outside the repo, so nothing in the world can carry scripts or content we haven't read.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local MapParts = {}

-- An anchored part with smooth faces and the sand material unless told otherwise.
function MapParts.part(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Palette.Material.Sand
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

-- A floating sign above a part.
function MapParts.label(parent: BasePart, text: string, offset: Vector3, size: Vector2?)
	local gui = Instance.new("BillboardGui")
	local pixels = size or Vector2.new(240, 50)
	gui.Size = UDim2.fromOffset(pixels.X, pixels.Y)
	gui.StudsOffset = offset
	gui.AlwaysOnTop = false
	gui.MaxDistance = 250
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Palette.Font.Title
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.4
	textLabel.Text = text
	textLabel.Parent = gui
	gui.Parent = parent
end

return MapParts
