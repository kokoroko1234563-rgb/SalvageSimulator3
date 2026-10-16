-- Models for the grabbing tools, held in the player's right hand. Each is built around the
-- hand's grip point, with the business end pointing forward (-Z) and up as +Y. Bare Hands
-- have none. The model is an Accessory attached by the hand's "RightGripAttachment", the way
-- cosmetics attach to the head, so it follows the hand and never collides with anything.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Gear)
local Palette = require(Shared.Palette)

local ModelParts = require(script.Parent.ModelParts)

local Ball = Enum.PartType.Ball
local Block = Enum.PartType.Block
local Cylinder = Enum.PartType.Cylinder

local Glass = Palette.Material.Glass
local Wood = Palette.Material.Wood
local Metal = Palette.Material.Metal
local Neon = Palette.Material.Neon
local Smooth = Palette.Material.Smooth
local Fabric = Palette.Material.Fabric

local T = Palette.ToolModel

local ALONG_Z = ModelParts.ALONG_Z
local shade = ModelParts.shade
local piece = ModelParts.piece
local bar = ModelParts.bar
local arc = ModelParts.arc

local ToolModels = {}

local WORN = "HeldTool"

local builders = {}

local function point(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

-- A cylinder lying along Z, from z1 to z2 (the grips and ferrules on a pole).
local function sleeve(
	handle: BasePart,
	name: string,
	z1: number,
	z2: number,
	width: number,
	color: Color3,
	material
)
	piece(
		handle,
		name,
		Cylinder,
		Vector3.new(math.abs(z2 - z1), width, width),
		CFrame.new(0, 0, (z1 + z2) / 2) * ALONG_Z,
		color,
		material
	)
end

-- A pole from the hand out to `tip`, with a coloured rubber grip where it's held.
local function pole(handle: BasePart, tip: number, thickness: number, color: Color3, material)
	bar(handle, "Pole", point(0, 0, 0.9), point(0, 0, tip), thickness, color, material)
	sleeve(handle, "Grip", 0.75, 0.05, thickness * 1.7, T.Red, Smooth)
end

builders.Lantern = function(handle)
	-- A storm lantern hanging from the hand by its bail: iron cap and base, glowing glass.
	local tool = Gear.getTool("Lantern")
	bar(handle, "Bail", point(-0.25, 0, -0.1), point(0.25, 0, -0.1), 0.08, T.LanternIron, Metal)
	piece(
		handle,
		"Cap",
		Cylinder,
		Vector3.new(0.25, 0.7, 0.7),
		CFrame.new(0, -0.35, -0.1) * CFrame.Angles(0, 0, math.pi / 2),
		T.LanternIron,
		Metal
	)
	local glass = piece(
		handle,
		"Glass",
		Cylinder,
		Vector3.new(0.8, 0.55, 0.55),
		CFrame.new(0, -0.9, -0.1) * CFrame.Angles(0, 0, math.pi / 2),
		T.LanternGlass,
		Neon
	)
	piece(
		handle,
		"Base",
		Cylinder,
		Vector3.new(0.2, 0.75, 0.75),
		CFrame.new(0, -1.4, -0.1) * CFrame.Angles(0, 0, math.pi / 2),
		T.LanternIron,
		Metal
	)
	local light = Instance.new("PointLight")
	light.Color = tool.Light.Color
	light.Range = tool.Light.Range
	light.Brightness = tool.Light.Brightness
	light.Shadows = false
	light.Parent = glass
end

builders.BeachRake = function(handle)
	pole(handle, -2.1, 0.14, T.Pole, Wood)
	bar(handle, "Head", point(-0.75, 0, -2.15), point(0.75, 0, -2.15), 0.14, T.Steel, Metal)
	for index = 0, 6 do
		local x = -0.6 + index * 0.2
		bar(handle, "Tooth", point(x, 0, -2.15), point(x, -0.55, -2.2), 0.07, T.Steel, Metal)
	end
end

builders.FishingNet = function(handle)
	pole(handle, -2.0, 0.14, T.PoleDark, Wood)
	arc(handle, "Hoop", Vector2.new(0, 0), 0.68, 0, 360, 0.1, T.Brass, Metal, -2.4)
	-- The bag of the net: a pale, see-through ball hanging from the hoop.
	piece(handle, "Net", Ball, Vector3.new(1.3, 1.3, 1.3), CFrame.new(0, -0.2, -2.6), T.White, Fabric, 0.55)
	piece(handle, "Float", Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0.68, -2.4), T.Orange, Smooth)
end

builders.GrabberClaw = function(handle)
	bar(handle, "Shaft", point(0, 0, 0.6), point(0, 0, -1.6), 0.16, T.Steel, Metal)
	-- A pistol grip with a trigger, and three curved jaws round the tip.
	piece(handle, "Grip", Block, Vector3.new(0.22, 0.6, 0.24), CFrame.new(0, -0.32, 0.25), T.Red, Smooth)
	piece(handle, "Trigger", Block, Vector3.new(0.12, 0.2, 0.08), CFrame.new(0, -0.1, -0.1), T.Yellow, Smooth)
	for jaw = 0, 2 do
		local angle = jaw * math.pi * 2 / 3
		local dx, dy = math.cos(angle), math.sin(angle)
		local previous = point(0, 0, -1.6)
		for _, step in { point(0.38, 0, -1.9), point(0.62, 0, -2.3), point(0.36, 0, -2.7) } do
			local target = point(step.X * dx, step.X * dy, step.Z)
			bar(handle, "Jaw", previous, target, 0.12, T.Yellow, Metal)
			previous = target
		end
		piece(handle, "Tip", Ball, Vector3.new(0.16, 0.16, 0.16), CFrame.new(previous), T.Red, Smooth)
	end
end

builders.BoatHook = function(handle)
	-- A nautical pole, painted in white and blue stripes, with a brass hook.
	local length = 4.0
	local stripes = 10
	for index = 0, stripes - 1 do
		local z1 = 1.0 - length * index / stripes
		local z2 = 1.0 - length * (index + 1) / stripes
		bar(
			handle,
			"Stripe",
			point(0, 0, z1),
			point(0, 0, z2),
			0.17,
			if index % 2 == 0 then T.White else T.Blue,
			Smooth
		)
	end
	sleeve(handle, "Ferrule", -2.85, -3.25, 0.24, T.Brass, Metal)
	arc(handle, "Hook", Vector2.new(0, -0.38), 0.38, 90, -160, 0.11, T.Brass, Metal, -3.25)
	piece(
		handle,
		"Point",
		Ball,
		Vector3.new(0.16, 0.16, 0.16),
		CFrame.new(-0.12, -0.4, -3.25),
		T.Brass,
		Metal
	)
	sleeve(handle, "Grip", 0.55, -0.15, 0.28, T.Red, Smooth)
end

builders.HandWinch = function(handle)
	-- An orange frame round a steel drum wound with rope, a crank, and a hook on the line.
	piece(handle, "Frame", Block, Vector3.new(0.7, 0.55, 0.9), CFrame.new(0, 0, -0.45), T.Orange, Smooth)
	piece(handle, "Drum", Cylinder, Vector3.new(0.85, 0.5, 0.5), CFrame.new(0, 0.08, -0.45), T.Steel, Metal)
	piece(handle, "Rope", Cylinder, Vector3.new(0.5, 0.58, 0.58), CFrame.new(0, 0.08, -0.45), T.Rope, Fabric)
	bar(handle, "CrankArm", point(0.46, 0.08, -0.45), point(0.46, 0.58, -0.45), 0.1, T.Steel, Metal)
	piece(
		handle,
		"CrankKnob",
		Ball,
		Vector3.new(0.22, 0.22, 0.22),
		CFrame.new(0.46, 0.6, -0.45),
		T.Red,
		Smooth
	)
	piece(handle, "Handle", Block, Vector3.new(0.2, 0.55, 0.22), CFrame.new(0, -0.45, 0.1), T.PoleDark, Wood)
	bar(handle, "Line", point(0, 0.08, -0.9), point(0, -0.2, -2.4), 0.06, T.Rope, Fabric)
	arc(handle, "Hook", Vector2.new(0, -0.45), 0.25, 90, -180, 0.08, T.Steel, Metal, -2.4)
end

builders.ElectricWinch = function(handle)
	-- A yellow power unit with a motor, a status light, a cable and a hook.
	piece(handle, "Body", Block, Vector3.new(0.8, 0.62, 1.1), CFrame.new(0, 0, -0.5), T.Yellow, Smooth)
	sleeve(handle, "Motor", 0.7, 0.05, 0.5, T.Steel, Metal)
	piece(handle, "Drum", Cylinder, Vector3.new(0.9, 0.46, 0.46), CFrame.new(0, 0.1, -0.85), T.Steel, Metal)
	piece(handle, "Light", Ball, Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 0.36, -0.2), T.Green, Neon)
	piece(handle, "Handle", Block, Vector3.new(0.2, 0.5, 0.22), CFrame.new(0, -0.5, -0.1), T.Red, Smooth)
	bar(handle, "Cable", point(0, 0.1, -1.1), point(0, -0.15, -2.6), 0.07, T.Steel, Metal)
	arc(handle, "Hook", Vector2.new(0, -0.43), 0.28, 90, -180, 0.09, T.Steel, Metal, -2.6)
end

builders.AnchorHook = function(handle)
	-- A teal pole with a small anchor standing on the end, glowing at the eye.
	pole(handle, -1.95, 0.15, T.Teal, Metal)
	local z = -2.05
	bar(handle, "Shank", point(0, -0.72, z), point(0, 0.75, z), 0.15, T.Teal, Metal)
	bar(handle, "Stock", point(-0.48, 0.55, z), point(0.48, 0.55, z), 0.14, T.Brass, Metal)
	piece(handle, "Eye", Ball, Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, 0.86, z), T.Teal, Neon)
	for _, side in { -1, 1 } do
		local previous = point(0, -0.66, z)
		for _, step in { point(0.24, -0.82, z), point(0.46, -0.62, z), point(0.54, -0.32, z) } do
			local target = point(step.X * side, step.Y, z)
			bar(handle, "Arm", previous, target, 0.15, T.Teal, Metal)
			previous = target
		end
		piece(handle, "Blade", Ball, Vector3.new(0.22, 0.22, 0.22), CFrame.new(previous), T.Brass, Metal)
	end
end

builders.TideMagnet = function(handle)
	-- A horseshoe magnet on a pole: one red leg, one blue, steel tips, and a watery glow.
	bar(handle, "Pole", point(0, 0, 0.8), point(0, 0, -0.95), 0.14, T.Pole, Wood)
	sleeve(handle, "Grip", 0.7, 0.0, 0.26, T.Teal, Smooth)
	local centre = Vector2.new(0, 0.1)
	arc(handle, "Red", centre, 0.55, 180, 270, 0.24, T.Red, Smooth, -1.2)
	arc(handle, "Blue", centre, 0.55, 270, 360, 0.24, T.Blue, Smooth, -1.2)
	bar(handle, "RedLeg", point(-0.55, 0.1, -1.2), point(-0.55, 0.62, -1.2), 0.24, T.Red, Smooth)
	bar(handle, "BlueLeg", point(0.55, 0.1, -1.2), point(0.55, 0.62, -1.2), 0.24, T.Blue, Smooth)
	for _, side in { -1, 1 } do
		piece(
			handle,
			"Tip",
			Block,
			Vector3.new(0.3, 0.2, 0.3),
			CFrame.new(0.55 * side, 0.68, -1.2),
			T.Steel,
			Metal
		)
		piece(
			handle,
			"Spark",
			Ball,
			Vector3.new(0.18, 0.18, 0.18),
			CFrame.new(0.55 * side, 0.9, -1.2),
			if side < 0 then T.Pink else T.Teal,
			Neon
		)
	end
end

builders.BubbleWand = function(handle)
	-- A pink wand with a violet ring holding a soap film, and bubbles drifting off it.
	bar(handle, "Wand", point(0, 0, 0.7), point(0, 0, -1.6), 0.12, T.Pink, Smooth)
	sleeve(handle, "Grip", 0.6, 0.0, 0.22, T.Violet, Smooth)
	arc(handle, "Ring", Vector2.new(0, 0), 0.55, 0, 360, 0.1, T.Violet, Smooth, -2.15)
	piece(
		handle,
		"Film",
		Cylinder,
		Vector3.new(0.02, 1.08, 1.08),
		CFrame.new(0, 0, -2.15) * ALONG_Z,
		T.Film,
		Glass,
		0.75
	)
	for _, bubble in
		{
			{ point(0.75, 0.45, -2.9), 0.4 },
			{ point(-0.55, 0.85, -3.2), 0.28 },
			{ point(0.2, -0.05, -3.5), 0.22 },
			{ point(-0.9, 0.2, -2.6), 0.18 },
		}
	do
		piece(
			handle,
			"Bubble",
			Ball,
			Vector3.new(bubble[2], bubble[2], bubble[2]),
			CFrame.new(bubble[1]),
			T.Film,
			Glass,
			0.6
		)
	end
end

builders.GustGloves = function(handle)
	-- A leather gauntlet with fingers, and rings of wind spinning off the knuckles.
	piece(handle, "Cuff", Block, Vector3.new(0.7, 0.6, 0.7), CFrame.new(0, 0, 0.1), T.PoleDark, Fabric)
	piece(handle, "Palm", Block, Vector3.new(0.62, 0.5, 0.6), CFrame.new(0, 0, -0.55), T.Pole, Fabric)
	for index = 0, 3 do
		local x = -0.24 + index * 0.16
		bar(handle, "Finger", point(x, 0, -0.85), point(x, 0.05, -1.45), 0.13, T.Pole, Fabric)
		piece(
			handle,
			"Fingertip",
			Ball,
			Vector3.new(0.15, 0.15, 0.15),
			CFrame.new(x, 0.05, -1.47),
			T.Sky,
			Smooth
		)
	end
	for ring = 0, 2 do
		local z = -1.7 - ring * 0.55
		arc(handle, "Whirl", Vector2.new(0, 0.1), 0.45 + ring * 0.22, 0, 360, 0.07, T.Sky, Smooth, z)
		piece(
			handle,
			"Puff",
			Ball,
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(0.45 + ring * 0.22, 0.1, z),
			T.White,
			Smooth
		)
	end
end

builders.CrabClaw = function(handle)
	-- A big red pincer on a short handle, with a crab's eyes on stalks.
	bar(handle, "Handle", point(0, 0, 0.8), point(0, 0, -0.7), 0.2, T.Orange, Smooth)
	piece(handle, "Body", Block, Vector3.new(0.7, 0.55, 0.6), CFrame.new(0, 0, -0.75), T.Red, Smooth)
	for _, side in { -1, 1 } do
		bar(
			handle,
			"Stalk",
			point(0.2 * side, 0.25, -0.7),
			point(0.2 * side, 0.65, -0.7),
			0.06,
			T.Red,
			Smooth
		)
		piece(
			handle,
			"Eye",
			Ball,
			Vector3.new(0.22, 0.22, 0.22),
			CFrame.new(0.2 * side, 0.72, -0.7),
			T.White,
			Smooth
		)
		piece(
			handle,
			"Pupil",
			Ball,
			Vector3.new(0.1, 0.1, 0.1),
			CFrame.new(0.2 * side, 0.74, -0.8),
			T.PoleDark,
			Smooth
		)
	end
	local upper = { point(0, 0.12, -0.9), point(0, 0.62, -1.3), point(0, 0.55, -1.95), point(0, 0.12, -2.3) }
	local lower =
		{ point(0, -0.12, -0.9), point(0, -0.5, -1.25), point(0, -0.4, -1.75), point(0, -0.08, -2.1) }
	for _, jaw in { upper, lower } do
		for index = 1, #jaw - 1 do
			bar(handle, "Jaw", jaw[index], jaw[index + 1], 0.3, T.Red, Smooth)
		end
		piece(handle, "Point", Ball, Vector3.new(0.26, 0.26, 0.26), CFrame.new(jaw[#jaw]), T.White, Smooth)
	end
end

builders.ObsidianGrabber = function(handle)
	-- Black volcanic glass on a dark shaft, with a glowing lava collar and three spikes.
	pole(handle, -1.8, 0.2, T.Obsidian, Metal)
	sleeve(handle, "Collar", -1.55, -1.85, 0.4, T.Lava, Neon)
	for index = 0, 2 do
		local angle = index * math.pi * 2 / 3 + math.pi / 2
		local tip = point(math.cos(angle) * 0.6, math.sin(angle) * 0.6, -2.7)
		bar(handle, "Spike", point(0, 0, -1.8), tip, 0.2, T.Obsidian, Metal)
		piece(handle, "Ember", Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(tip), T.Lava, Neon)
	end
	bar(handle, "Core", point(0, 0, -1.8), point(0, 0, -2.9), 0.24, T.Obsidian, Metal)
	piece(handle, "Heart", Ball, Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 0, -3.0), T.Lava, Neon)
end

builders.FreezeWand = function(handle)
	-- An icy wand topped with a glittering snowflake and a few icicles.
	bar(handle, "Wand", point(0, 0, 0.7), point(0, 0, -1.8), 0.13, T.Ice, Glass)
	sleeve(handle, "Grip", 0.6, 0.0, 0.22, T.Sky, Smooth)
	local z = -2.1
	for index = 0, 2 do
		local angle = index * math.pi / 3
		local dx, dy = math.cos(angle) * 0.55, math.sin(angle) * 0.55
		bar(handle, "Ray", point(-dx, -dy, z), point(dx, dy, z), 0.1, T.Ice, Neon)
		for _, side in { -1, 1 } do
			local mid = point(dx * 0.62 * side, dy * 0.62 * side, z)
			local across = point(-dy * 0.3, dx * 0.3, 0)
			bar(handle, "Twig", mid - across, mid + across, 0.06, T.Frost, Neon)
		end
	end
	piece(handle, "Heart", Ball, Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 0, z), T.Frost, Neon)
	for _, x in { -0.3, 0, 0.3 } do
		piece(
			handle,
			"Icicle",
			Block,
			Vector3.new(0.08, 0.34, 0.08),
			CFrame.new(x, -0.72, z),
			T.Ice,
			Glass,
			0.2
		)
	end
end

-- Whether a tool has a model. Bare Hands don't.
function ToolModels.has(id: string): boolean
	return builders[id] ~= nil
end

ToolModels._builders = builders

-- A tool's model as an Accessory: an invisible Handle at the grip point, with the model
-- welded to it, joined to the hand by the shared "RightGripAttachment".
function ToolModels.build(id: string): Accessory?
	local builder = builders[id]
	if not builder then
		return nil
	end
	local accessory = Instance.new("Accessory")
	accessory.Name = WORN
	accessory:SetAttribute("ToolId", id)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 0.2)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.Parent = accessory
	local attachment = Instance.new("Attachment")
	attachment.Name = "RightGripAttachment"
	attachment.Parent = handle
	builder(handle)
	return accessory
end

function ToolModels.dress(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then
		return
	end
	local old = character:FindFirstChild(WORN)
	if old then
		old:Destroy()
	end
	local accessory = ToolModels.build(Gear.getTool(player:GetAttribute("Tool")).Id)
	if accessory then
		humanoid:AddAccessory(accessory)
	end
end

function ToolModels.init()
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid")
			ToolModels.dress(player)
		end)
		player:GetAttributeChangedSignal("Tool"):Connect(function()
			ToolModels.dress(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return ToolModels
