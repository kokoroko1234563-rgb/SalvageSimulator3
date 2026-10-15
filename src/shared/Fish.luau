-- The fish that live in the sea. They're purely cosmetic: each species is a small model built from
-- parts, and the client swims schools of them around the seabed (see FishController). Nothing
-- about them collides, is queried, or can be grabbed.
--
-- A fish faces -Z, like every Roblox model, so `CFrame.lookAt` points it where it's swimming.

local Palette = require(script.Parent.Palette)

local Fish = {}

local C = Palette.Cosmetic

export type Species = {
	Id: string,
	Name: string,
	Shape: string, -- slim, tall, puffer, ray, turtle, seahorse or jelly
	Length: number,
	Height: number,
	Body: string, -- a Palette.Cosmetic colour name
	Fin: string,
	Stripe: string?, -- stripes across the body, for the clownfish
}

Fish.Species = {
	{
		Id = "Sardine",
		Name = "Sardine",
		Shape = "slim",
		Length = 2.4,
		Height = 0.7,
		Body = "Silver",
		Fin = "Grey",
	},
	{
		Id = "Clownfish",
		Name = "Clownfish",
		Shape = "slim",
		Length = 2,
		Height = 0.9,
		Body = "Orange",
		Fin = "Orange",
		Stripe = "White",
	},
	{
		Id = "Angelfish",
		Name = "Angelfish",
		Shape = "tall",
		Length = 3,
		Height = 3,
		Body = "Yellow",
		Fin = "Orange",
	},
	{
		Id = "Pufferfish",
		Name = "Pufferfish",
		Shape = "puffer",
		Length = 2.2,
		Height = 2.2,
		Body = "Cream",
		Fin = "Peach",
	},
	{ Id = "Ray", Name = "Ray", Shape = "ray", Length = 6, Height = 0.4, Body = "Grey", Fin = "DarkGrey" },
	{ Id = "Tuna", Name = "Tuna", Shape = "slim", Length = 5, Height = 1.6, Body = "Navy", Fin = "Blue" },
	{
		Id = "BlueTang",
		Name = "Blue Tang",
		Shape = "tall",
		Length = 2.6,
		Height = 2.4,
		Body = "Blue",
		Fin = "Yellow",
	},
	{
		Id = "Seahorse",
		Name = "Seahorse",
		Shape = "seahorse",
		Length = 1.5,
		Height = 2.6,
		Body = "Gold",
		Fin = "Orange",
	},
	{
		Id = "Turtle",
		Name = "Sea Turtle",
		Shape = "turtle",
		Length = 4,
		Height = 1.2,
		Body = "Moss",
		Fin = "Olive",
	},
	{
		Id = "MoonJelly",
		Name = "Moon Jelly",
		Shape = "jelly",
		Length = 2.2,
		Height = 2.2,
		Body = "Lavender",
		Fin = "Pink",
	},
} :: { Species }

function Fish.get(id: string): Species?
	for _, species in Fish.Species do
		if species.Id == id then
			return species
		end
	end
	return nil
end

local function piece(
	model: Model,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material or Palette.Material.Smooth
	part.Transparency = transparency or 0
	part.CFrame = offset
	part.Parent = model
	return part
end

local function wedge(model: Model, name: string, size: Vector3, offset: CFrame, color: Color3)
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Color = color
	part.Material = Palette.Material.Smooth
	part.CFrame = offset
	part.Parent = model
	return part
end

local BLOCK = Enum.PartType.Block
local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder

local function eyes(model: Model, spec: Species, z: number, spread: number)
	local size = math.max(spec.Height * 0.18, 0.12)
	for _, side in { -1, 1 } do
		piece(
			model,
			"Eye",
			BALL,
			Vector3.new(size, size, size),
			CFrame.new(side * spread, spec.Height * 0.1, z),
			C.Ink
		)
	end
end

local shapes: { [string]: (Model, Species, Color3, Color3) -> BasePart } = {}

-- A streamlined fish: body, head, tail and a dorsal fin.
shapes.slim = function(model, spec, body, fin)
	local width = spec.Height * 0.7
	local main =
		piece(model, "Body", BLOCK, Vector3.new(width, spec.Height, spec.Length * 0.7), CFrame.new(), body)
	piece(
		model,
		"Head",
		BALL,
		Vector3.new(spec.Height, spec.Height, spec.Height),
		CFrame.new(0, 0, -spec.Length * 0.35),
		body
	)
	wedge(
		model,
		"Tail",
		Vector3.new(0.15, spec.Height * 1.3, spec.Length * 0.3),
		CFrame.new(0, 0, spec.Length * 0.45),
		fin
	)
	wedge(
		model,
		"Dorsal",
		Vector3.new(0.12, spec.Height * 0.5, spec.Length * 0.3),
		CFrame.new(0, spec.Height * 0.7, 0),
		fin
	)
	eyes(model, spec, -spec.Length * 0.42, width * 0.45)
	if spec.Stripe then
		for _, z in { -0.15, 0.15 } do
			piece(
				model,
				"Stripe",
				BLOCK,
				Vector3.new(width * 1.06, spec.Height * 1.02, spec.Length * 0.06),
				CFrame.new(0, 0, z * spec.Length),
				C[spec.Stripe :: string]
			)
		end
	end
	return main
end

-- A tall, flat fish with long fins, like an angelfish or a tang.
shapes.tall = function(model, spec, body, fin)
	local main =
		piece(model, "Body", BLOCK, Vector3.new(0.35, spec.Height, spec.Length * 0.55), CFrame.new(), body)
	wedge(
		model,
		"TopFin",
		Vector3.new(0.1, spec.Height * 0.6, spec.Length * 0.35),
		CFrame.new(0, spec.Height * 0.75, spec.Length * 0.05),
		fin
	)
	wedge(
		model,
		"BottomFin",
		Vector3.new(0.1, spec.Height * 0.5, spec.Length * 0.3),
		CFrame.new(0, -spec.Height * 0.7, spec.Length * 0.05) * CFrame.Angles(math.pi, 0, 0),
		fin
	)
	wedge(
		model,
		"Tail",
		Vector3.new(0.12, spec.Height * 0.8, spec.Length * 0.3),
		CFrame.new(0, 0, spec.Length * 0.42),
		fin
	)
	eyes(model, spec, -spec.Length * 0.22, 0.2)
	return main
end

-- A round pufferfish.
shapes.puffer = function(model, spec, body, fin)
	local main =
		piece(model, "Body", BALL, Vector3.new(spec.Length, spec.Length, spec.Length), CFrame.new(), body)
	wedge(
		model,
		"Tail",
		Vector3.new(0.12, spec.Height * 0.5, spec.Length * 0.3),
		CFrame.new(0, 0, spec.Length * 0.55),
		fin
	)
	eyes(model, spec, -spec.Length * 0.38, spec.Length * 0.28)
	return main
end

-- A flat diamond-shaped ray with a thin tail.
shapes.ray = function(model, spec, body, fin)
	local main = piece(
		model,
		"Body",
		BLOCK,
		Vector3.new(spec.Length * 0.7, spec.Height * 0.6, spec.Length * 0.7),
		CFrame.Angles(0, math.rad(45), 0),
		body
	)
	piece(
		model,
		"Tail",
		BLOCK,
		Vector3.new(0.15, 0.15, spec.Length * 0.9),
		CFrame.new(0, 0, spec.Length * 0.7),
		fin
	)
	eyes(model, spec, -spec.Length * 0.3, spec.Length * 0.12)
	return main
end

-- A sea turtle: a shell, a head and four flippers.
shapes.turtle = function(model, spec, body, fin)
	local shell = spec.Length * 0.8
	local main = piece(model, "Body", BALL, Vector3.new(shell, shell, shell), CFrame.new(), body)
	piece(
		model,
		"Head",
		BALL,
		Vector3.new(spec.Length * 0.3, spec.Length * 0.3, spec.Length * 0.3),
		CFrame.new(0, 0, -spec.Length * 0.5),
		fin
	)
	for _, side in { -1, 1 } do
		for _, z in { -0.2, 0.25 } do
			piece(
				model,
				"Flipper",
				BLOCK,
				Vector3.new(spec.Length * 0.5, 0.12, spec.Length * 0.22),
				CFrame.new(side * spec.Length * 0.45, -spec.Length * 0.1, z * spec.Length)
					* CFrame.Angles(0, 0, side * math.rad(15)),
				fin
			)
		end
	end
	return main
end

-- A seahorse: upright, with a snout and a curled tail.
shapes.seahorse = function(model, spec, body, fin)
	local main = piece(model, "Body", BLOCK, Vector3.new(0.35, spec.Height, 0.35), CFrame.new(), body)
	piece(model, "Snout", BLOCK, Vector3.new(0.2, 0.2, 0.6), CFrame.new(0, spec.Height * 0.4, -0.45), body)
	piece(model, "Head", BALL, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, spec.Height * 0.45, -0.1), body)
	for i = 1, 3 do
		local d = 0.3 - i * 0.05
		piece(
			model,
			"Tail",
			BALL,
			Vector3.new(d, d, d),
			CFrame.new(0, -spec.Height * 0.5 - i * 0.12, i * 0.2),
			body
		)
	end
	wedge(model, "Dorsal", Vector3.new(0.1, spec.Height * 0.3, 0.4), CFrame.new(0, 0, 0.35), fin)
	return main
end

-- A moon jelly: a glowing dome with trailing tentacles.
shapes.jelly = function(model, spec, body, fin)
	local main = piece(
		model,
		"Body",
		BALL,
		Vector3.new(spec.Length, spec.Length, spec.Length),
		CFrame.new(),
		body,
		Palette.Material.Neon,
		0.4
	)
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		piece(
			model,
			"Tentacle",
			CYLINDER,
			Vector3.new(spec.Height * 0.9, 0.12, 0.12),
			CFrame.new(
				math.cos(angle) * spec.Length * 0.25,
				-spec.Height * 0.9,
				math.sin(angle) * spec.Length * 0.25
			) * CFrame.Angles(0, 0, math.pi / 2),
			fin,
			Palette.Material.Neon,
			0.45
		)
	end
	return main
end

-- Builds one fish of a species. Its pivot is its middle; it faces -Z.
function Fish.build(spec: Species): Model
	local model = Instance.new("Model")
	model.Name = spec.Id
	local builder = shapes[spec.Shape]
	assert(builder, "no fish shape " .. spec.Shape)
	local main = builder(model, spec, C[spec.Body], C[spec.Fin])
	model.PrimaryPart = main
	return model
end

return Fish
