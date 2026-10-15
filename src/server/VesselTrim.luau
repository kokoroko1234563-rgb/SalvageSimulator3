-- Paint and trim for the vessels. VesselService builds each vessel as a bare tray (the
-- floor "Base", four "Wall" parts and an invisible "Cargo" box); this repaints it in bright
-- colours and adds a rim cap, stripes, corner bumpers and, on the bigger boats, a pennant.
-- Everything added is welded on and never collides, so the vessel handles as it did.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local ModelParts = require(script.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder

local Smooth = Palette.Material.Smooth
local Wood = Palette.Material.Wood

local V = Palette.VesselTrim

local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar

local VesselTrim = {}

-- Hull is the body, Trim the rim and bumpers, Accent the stripe. Flag adds a pennant;
-- Spots adds round markings on the sides; Parts repaints the builder's own parts by name.
local specs = {
	Wheelbarrow = { Hull = V.Sunny, Trim = V.Red, Accent = V.White },
	BeachWagon = {
		Hull = V.Coral,
		Trim = V.Gold,
		Accent = V.White,
		Flag = V.Aqua,
		Parts = { Handle = V.Gold },
	},
	FloatingClamshell = { Hull = V.Pearl, Trim = V.Gold, Accent = V.White, Bumper = V.White },
	CaptainsLongboat = {
		Hull = V.Teal,
		Trim = V.Oak,
		Accent = V.White,
		Flag = V.Red,
		TrimMaterial = Wood,
		Parts = { Bow = V.Oak },
	},
	SeaTurtle = {
		Hull = V.Lime,
		Trim = V.Gold,
		Accent = V.LimeDark,
		Spots = true,
		Parts = { Head = V.LimeLight, Flipper = V.LimeLight },
	},
	QuadBike = { Hull = V.Teal, Trim = V.Gold, Accent = V.White },
	LeviathanRowboat = {
		Hull = V.Royal,
		Trim = V.Gold,
		Accent = V.Aqua,
		Flag = V.Gold,
		Parts = { Prow = V.Gold, Oar = V.Oak },
	},
}

local function isHull(name: string): boolean
	return name == "Base" or string.match(name, "^Wall%d") ~= nil
end

-- Whether a vessel has paint and trim.
function VesselTrim.has(kind: string): boolean
	return specs[kind] ~= nil
end

function VesselTrim.apply(model: Model, kind: string)
	local spec = specs[kind]
	local base = model.PrimaryPart
	local cargo = model:FindFirstChild("Cargo")
	if not spec or not base or not cargo then
		return
	end

	-- The tray's inside size, and the walls' height above the floor's centre.
	local width, depth = cargo.Size.X, cargo.Size.Z
	local height = cargo.Size.Y - 0.5
	local halfX, halfZ = width / 2 + 0.15, depth / 2 + 0.15

	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			if isHull(child.Name) then
				child.Color = if child.Name == "Base" then shade(spec.Hull, -0.18) else spec.Hull
			elseif child.Name == "Leg" then
				child.Color = spec.Trim
			elseif spec.Parts and spec.Parts[child.Name] then
				child.Color = spec.Parts[child.Name]
			end
		end
	end

	local trimMaterial = spec.TrimMaterial or Smooth
	local rimY = height + 0.07
	piece(
		base,
		"RimFront",
		Block,
		Vector3.new(width + 0.9, 0.14, 0.5),
		CFrame.new(0, rimY, -halfZ),
		spec.Trim,
		trimMaterial
	)
	piece(
		base,
		"RimBack",
		Block,
		Vector3.new(width + 0.9, 0.14, 0.5),
		CFrame.new(0, rimY, halfZ),
		spec.Trim,
		trimMaterial
	)
	piece(
		base,
		"RimLeft",
		Block,
		Vector3.new(0.5, 0.14, depth + 0.9),
		CFrame.new(-halfX, rimY, 0),
		spec.Trim,
		trimMaterial
	)
	piece(
		base,
		"RimRight",
		Block,
		Vector3.new(0.5, 0.14, depth + 0.9),
		CFrame.new(halfX, rimY, 0),
		spec.Trim,
		trimMaterial
	)

	-- A band of the accent colour round the outside, at mid-height.
	local bandY, bandHeight = height * 0.5, math.max(0.25, height * 0.28)
	for _, side in { -1, 1 } do
		piece(
			base,
			"StripeSide",
			Block,
			Vector3.new(0.06, bandHeight, depth + 0.3),
			CFrame.new(side * (width / 2 + 0.33), bandY, 0),
			spec.Accent
		)
		piece(
			base,
			"StripeEnd",
			Block,
			Vector3.new(width + 0.3, bandHeight, 0.06),
			CFrame.new(0, bandY, side * (depth / 2 + 0.33)),
			spec.Accent
		)
	end

	-- Round bumpers on the four top corners.
	for _, x in { -halfX, halfX } do
		for _, z in { -halfZ, halfZ } do
			piece(
				base,
				"Bumper",
				Ball,
				Vector3.new(0.55, 0.55, 0.55),
				CFrame.new(x, rimY + 0.1, z),
				spec.Bumper or shade(spec.Trim, 0.2)
			)
		end
	end

	if spec.Spots then
		for _, side in { -1, 1 } do
			for _, z in { -depth * 0.28, 0, depth * 0.28 } do
				piece(
					base,
					"Scute",
					Cylinder,
					Vector3.new(0.06, 0.95, 0.95),
					CFrame.new(side * (width / 2 + 0.33), bandY, z),
					spec.Accent
				)
			end
		end
	end

	if spec.Flag then
		-- A pennant on a white pole, at the back corner.
		local top = rimY + 3.2
		bar(
			base,
			"Pole",
			Vector3.new(halfX, rimY, halfZ),
			Vector3.new(halfX, top, halfZ),
			0.1,
			V.White,
			Smooth
		)
		piece(
			base,
			"Pennant",
			Block,
			Vector3.new(0.05, 0.65, 1.2),
			CFrame.new(halfX, top - 0.4, halfZ - 0.65),
			spec.Flag
		)
	end
end

return VesselTrim
