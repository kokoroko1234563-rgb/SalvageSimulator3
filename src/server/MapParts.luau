-- Helpers for building the map out of parts in code. Everything the map is made of comes from
-- here and the modules next to it (Buildings, BeachDressing): no Toolbox models and no assets
-- from outside the repo, so nothing in the world can carry scripts or content we haven't read.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local MapParts = {}

local BOARD_THICKNESS = 0.4

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

-- A real sign: a painted board with text on both faces. `cf` is the centre of the board, and
-- `width` and `height` are its size in studs. If `ground` is given, a post runs from the
-- ground up to the board, so it stands on the beach.
function MapParts.sign(
	parent: Instance,
	text: string,
	cf: CFrame,
	width: number,
	height: number,
	ground: number?
)
	local board = MapParts.part({
		Name = "Sign",
		Size = Vector3.new(width, height, BOARD_THICKNESS),
		CFrame = cf,
		Color = Palette.World.Boardwalk,
		Material = Palette.Material.WoodPlanks,
	})
	board.Parent = parent

	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.fromScale(0.92, 0.84)
		textLabel.Position = UDim2.fromScale(0.04, 0.08)
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Palette.Font.Title
		textLabel.TextScaled = true
		textLabel.TextColor3 = Palette.World.SignText
		textLabel.Text = text
		textLabel.Parent = gui
		gui.Parent = board
	end

	if ground then
		local top = cf.Position.Y - height / 2
		local postHeight = top - ground
		if postHeight > 0 then
			MapParts.part({
				Name = "SignPost",
				Size = Vector3.new(0.6, postHeight, 0.6),
				CFrame = CFrame.new(cf.Position.X, ground + postHeight / 2, cf.Position.Z),
				Color = Palette.World.Post,
				Material = Palette.Material.Wood,
			}).Parent =
				parent
		end
	end
	return board
end

return MapParts
