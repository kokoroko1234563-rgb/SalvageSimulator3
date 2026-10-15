-- Helpers for building models out of welded parts, shared by the item, tool and vessel
-- models. A model is built in its root's own frame (`at` is relative to the root), and each
-- part is welded on, weighs nothing, and can't collide or be picked, so a model never
-- changes how the thing it decorates moves or is grabbed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local Smooth = Palette.Material.Smooth
local Metal = Palette.Material.Metal
local M = Palette.ItemModel
local Block = Enum.PartType.Block

local ModelParts = {}

-- Turns a cylinder (which lies along X) to stand along Y or Z.
local ALONG_Y = CFrame.Angles(0, 0, math.pi / 2)
local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0)

-- A darker (negative) or lighter (positive) version of a colour.
local function shade(color: Color3, amount: number): Color3
	if amount >= 0 then
		return color:Lerp(M.White, amount)
	end
	return color:Lerp(Color3.new(0, 0, 0), -amount)
end

-- Adds one visible part to the item. `at` is in the root's own frame.
local function piece(
	root: BasePart,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	at: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.CFrame = root.CFrame * at
	p.Color = color
	p.Material = material or Smooth
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Massless = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = root
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = root
	return p
end

-- A square bar from one point to another, in the root's frame.
local function bar(
	root: BasePart,
	name: string,
	from: Vector3,
	to: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material?
)
	-- lookAt breaks (a NaN transform) when it looks straight along its up vector, so a
	-- vertical bar needs a different one.
	local direction = to - from
	local up = if math.abs(direction.Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	piece(
		root,
		name,
		Block,
		Vector3.new(thickness, thickness, direction.Magnitude),
		CFrame.lookAt((from + to) / 2, to, up),
		color,
		material
	)
end

-- A curve in the XY plane (at depth `z`), as a chain of bars. Metal unless told otherwise.
local function arc(
	root: BasePart,
	name: string,
	centre: Vector2,
	radius: number,
	fromDegrees: number,
	toDegrees: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	z: number?
)
	local steps = math.max(4, math.ceil(math.abs(toDegrees - fromDegrees) / 25))
	local previous = nil
	for step = 0, steps do
		local angle = math.rad(fromDegrees + (toDegrees - fromDegrees) * step / steps)
		local point =
			Vector3.new(centre.X + radius * math.cos(angle), centre.Y + radius * math.sin(angle), z or 0)
		if previous then
			bar(root, name, previous, point, thickness, color, material or Metal)
		end
		previous = point
	end
end

-- A part spanning from..to along the root's X axis, centred on the root.
local function along(from: number, to: number): CFrame
	return CFrame.new((from + to) / 2, 0, 0)
end

ModelParts.ALONG_Y = ALONG_Y
ModelParts.ALONG_Z = ALONG_Z
ModelParts.shade = shade
ModelParts.piece = piece
ModelParts.bar = bar
ModelParts.arc = arc
ModelParts.along = along

return ModelParts
