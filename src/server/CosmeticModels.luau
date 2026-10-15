-- The catalog of small cosmetic models that make the beach and the sea feel lived in: buckets and
-- flip-flops, crabs and starfish, kelp, amphorae and treasure chests. Each one belongs to a theme
-- (one of the five zones or one of the fourteen biomes) and has several variants, so there are
-- about two hundred distinct models.
--
-- They're cosmetic only. They're small (nothing here is taller than a few studs), they never
-- collide or get queried, and they're not the active map: no hazards, no obstacles, nothing that
-- blocks the view. Cosmetics.luau decides where each one is placed.
--
-- Every model is built from parts around its origin, which is where it stands on the ground,
-- facing -Z. Colours come from Palette.Cosmetic, by name.

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Palette)

local MapParts = require(script.Parent.MapParts)

local CosmeticModels = {}

local C = Palette.Cosmetic
local M = Palette.Material
local add = MapParts.scenery

export type Entry = {
	Id: string,
	Kind: string,
	Theme: string,
	Name: string,
	Height: number, -- the most a model of this kind stands up, in studs
	Underwater: boolean, -- only placed where it's always under water
	Variant: { [string]: any },
	Build: (Instance, CFrame, Random) -> (),
}

-- The most any cosmetic model may stand up. The tests hold every kind to it.
CosmeticModels.MAX_HEIGHT = 12

CosmeticModels.List = {} :: { Entry }

-- Building blocks -------------------------------------------------------------------------

local function blk(
	parent: Instance,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	return add(parent, {
		Name = "Block",
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material or M.Smooth,
		Transparency = transparency or 0,
	})
end

local function ballAt(
	parent: Instance,
	cf: CFrame,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	return add(parent, {
		Name = "Ball",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		CFrame = cf,
		Color = color,
		Material = material or M.Smooth,
		Transparency = transparency or 0,
	})
end

-- A cylinder whose length runs along the local Y axis of `cf`. Rotate `cf` to lay it down.
local function rod(
	parent: Instance,
	cf: CFrame,
	length: number,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
)
	return add(parent, {
		Name = "Rod",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(length, diameter, diameter),
		CFrame = cf * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Material = material or M.Smooth,
		Transparency = transparency or 0,
	})
end

local function at(cf: CFrame, x: number, y: number, z: number): CFrame
	return cf * CFrame.new(x, y, z)
end

-- Registers a kind of model and one entry per variant.
local function kind(
	id: string,
	displayName: string,
	theme: string,
	height: number,
	variants: { { [string]: any } },
	build: (Instance, CFrame, { [string]: any }, Random) -> (),
	underwater: boolean?
)
	for index, variant in variants do
		table.insert(CosmeticModels.List, {
			Id = id .. index,
			Kind = id,
			Theme = theme,
			Name = string.format("%s %d", displayName, index),
			Height = height,
			Underwater = underwater or false,
			Variant = variant,
			Build = function(parent: Instance, cf: CFrame, rng: Random)
				build(parent, cf, variant, rng)
			end,
		})
	end
end

local SHOPSIDE = "Shopside Shore"
local SUNNY = "Sunny Stretch"
local BANKS = "Middle Banks"
local OUTER = "Outer Shore"
local FAR = "The Far Sandbar"

-- Shopside Shore: a day out at the beach ----------------------------------------------------

kind("BucketSpade", "Bucket and spade", SHOPSIDE, 2.5, {
	{ Bucket = "Red", Spade = "Yellow" },
	{ Bucket = "Blue", Spade = "White" },
	{ Bucket = "Green", Spade = "Orange" },
	{ Bucket = "Pink", Spade = "Teal" },
	{ Bucket = "Orange", Spade = "Blue" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 0.8, 0), 1.6, 1.5, C[v.Bucket])
	rod(p, at(cf, 0, 1.65, 0), 0.12, 1.7, C.White)
	blk(p, at(cf, 0, 1.9, 0), Vector3.new(1.5, 0.08, 0.08), C.Grey, M.Metal)
	blk(p, at(cf, 1.8, 0.9, 0.4) * CFrame.Angles(0, 0, math.rad(-20)), Vector3.new(0.18, 2, 0.18), C[v.Spade])
	blk(p, at(cf, 2.25, 0.05, 0.4), Vector3.new(0.8, 0.1, 1), C[v.Spade])
end)

kind("MiniCastle", "Mini sandcastle", SHOPSIDE, 6.5, {
	{ Towers = 2, Scale = 1, Flag = "Red" },
	{ Towers = 3, Scale = 1.2, Flag = "Blue" },
	{ Towers = 4, Scale = 1.5, Flag = "Yellow" },
	{ Towers = 1, Scale = 0.8, Flag = "Pink" },
	{ Towers = 4, Scale = 1.8, Flag = "Green" },
}, function(p, cf, v)
	local s = v.Scale
	blk(p, at(cf, 0, 1.2 * s, 0), Vector3.new(3 * s, 2.4 * s, 3 * s), C.Sand, M.Sand)
	local corners = { { -1.5, -1.5 }, { 1.5, 1.5 }, { -1.5, 1.5 }, { 1.5, -1.5 } }
	for i = 1, v.Towers do
		local corner = corners[i]
		rod(p, at(cf, corner[1] * s, 1.6 * s, corner[2] * s), 3.2 * s, 1 * s, C.Sand, M.Sand)
	end
	local top = at(cf, corners[1][1] * s, 3.2 * s, corners[1][2] * s)
	rod(p, at(top, 0, 0.8, 0), 1.6, 0.1, C.White, M.Wood)
	blk(p, at(top, 0.4, 1.3, 0), Vector3.new(0.8, 0.5, 0.05), C[v.Flag])
end)

kind("FlipFlops", "Flip-flops", SHOPSIDE, 0.4, {
	{ Sole = "Pink", Strap = "White" },
	{ Sole = "Blue", Strap = "Yellow" },
	{ Sole = "Green", Strap = "White" },
	{ Sole = "Orange", Strap = "Navy" },
	{ Sole = "Purple", Strap = "Pink" },
}, function(p, cf, v)
	for _, side in { -0.7, 0.7 } do
		local shoe = at(cf, side, 0.1, 0) * CFrame.Angles(0, side * 0.2, 0)
		blk(p, shoe, Vector3.new(0.8, 0.15, 2.1), C[v.Sole])
		blk(p, at(shoe, 0, 0.12, -0.45), Vector3.new(0.6, 0.12, 0.14), C[v.Strap])
	end
end)

kind("Sunglasses", "Sunglasses", SHOPSIDE, 0.5, {
	{ Frame = "Ink", Lens = "Aqua" },
	{ Frame = "Red", Lens = "Yellow" },
	{ Frame = "White", Lens = "Pink" },
	{ Frame = "Navy", Lens = "Mint" },
}, function(p, cf, v)
	for _, side in { -0.55, 0.55 } do
		rod(p, at(cf, side, 0.1, 0), 0.06, 1.05, C[v.Frame])
		rod(p, at(cf, side, 0.14, 0), 0.08, 0.9, C[v.Lens], M.Glass, 0.25)
		blk(p, at(cf, side * 1.75, 0.1, 0.65), Vector3.new(0.1, 0.08, 1.2), C[v.Frame])
	end
	blk(p, at(cf, 0, 0.12, 0), Vector3.new(0.3, 0.08, 0.1), C[v.Frame])
end)

kind("SwimRing", "Swim ring", SHOPSIDE, 1, {
	{ Main = "Red", Accent = "White" },
	{ Main = "Blue", Accent = "Yellow" },
	{ Main = "Pink", Accent = "White" },
	{ Main = "Teal", Accent = "Orange" },
	{ Main = "Yellow", Accent = "Blue" },
}, function(p, cf, v)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		ballAt(
			p,
			at(cf, math.cos(a) * 1.5, 0.4, math.sin(a) * 1.5),
			0.85,
			C[if i % 2 == 0 then v.Main else v.Accent]
		)
	end
end)

kind("Cooler", "Cooler box", SHOPSIDE, 2.2, {
	{ Body = "Blue" },
	{ Body = "Red" },
	{ Body = "Green" },
	{ Body = "Yellow" },
	{ Body = "Teal" },
}, function(p, cf, v)
	blk(p, at(cf, 0, 0.8, 0), Vector3.new(3, 1.6, 1.9), C[v.Body])
	blk(p, at(cf, 0, 1.75, 0), Vector3.new(3.1, 0.3, 2), C.White)
	blk(p, at(cf, 0, 2.05, 0), Vector3.new(1.2, 0.1, 0.12), C.Grey, M.Metal)
	blk(p, at(cf, 0, 1.2, 0.97), Vector3.new(0.5, 0.35, 0.05), C.Silver, M.Metal)
end)

kind("Kite", "Kite", SHOPSIDE, 10.5, {
	{ Main = "Red", Accent = "Yellow" },
	{ Main = "Blue", Accent = "White" },
	{ Main = "Pink", Accent = "Teal" },
	{ Main = "Orange", Accent = "Purple" },
}, function(p, cf, v)
	blk(
		p,
		at(cf, 0, 9, 0) * CFrame.Angles(math.rad(-25), 0, math.rad(45)),
		Vector3.new(2.4, 0.08, 2.4),
		C[v.Main],
		M.Fabric
	)
	blk(
		p,
		at(cf, 0, 9, 0.05) * CFrame.Angles(math.rad(-25), 0, math.rad(45)),
		Vector3.new(0.12, 0.1, 2.6),
		C[v.Accent]
	)
	for i = 1, 5 do
		blk(
			p,
			at(cf, math.sin(i) * 0.3, 8 - i * 0.7, 0.4 * i),
			Vector3.new(0.35, 0.2, 0.05),
			C[if i % 2 == 0 then v.Accent else v.Main]
		)
	end
	rod(p, at(cf, 0, 4.5, 0), 9, 0.05, C.White)
end)

kind("Bunting", "Bunting", SHOPSIDE, 3.2, {
	{ Colors = { "Red", "White", "Blue" } },
	{ Colors = { "Yellow", "Pink", "Teal" } },
	{ Colors = { "Orange", "Green", "Purple" } },
	{ Colors = { "Pink", "White", "Mint" } },
}, function(p, cf, v)
	for _, x in { -4, 4 } do
		rod(p, at(cf, x, 1.6, 0), 3.2, 0.2, C.White, M.Wood)
	end
	blk(p, at(cf, 0, 2.95, 0), Vector3.new(8, 0.04, 0.04), C.White)
	for i = 0, 7 do
		local x = -3.5 + i
		local sag = 0.4 * (1 - (x / 4) ^ 2)
		blk(
			p,
			at(cf, x, 2.6 - sag, 0) * CFrame.Angles(0, 0, math.rad(45)),
			Vector3.new(0.7, 0.7, 0.05),
			C[v.Colors[i % #v.Colors + 1]],
			M.Fabric
		)
	end
end)

kind("Sunscreen", "Sunscreen bottle", SHOPSIDE, 1.7, {
	{ Body = "Red" },
	{ Body = "Yellow" },
	{ Body = "Blue" },
	{ Body = "Orange" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 0.7, 0), 1.4, 0.7, C[v.Body])
	rod(p, at(cf, 0, 1.55, 0), 0.3, 0.4, C.White)
	blk(p, at(cf, 0, 0.7, -0.36), Vector3.new(0.5, 0.5, 0.05), C.White)
end)

-- Sunny Stretch: surf, palms and tiki torches ------------------------------------------------

kind("Surfboard", "Surfboard", SUNNY, 6.5, {
	{ Main = "White", Accent = "Red" },
	{ Main = "Yellow", Accent = "Blue" },
	{ Main = "Teal", Accent = "White" },
	{ Main = "Pink", Accent = "Purple" },
	{ Main = "Orange", Accent = "Navy" },
	{ Main = "Mint", Accent = "Coral" },
}, function(p, cf, v)
	local board = at(cf, 0, 3.2, 0) * CFrame.Angles(math.rad(8), 0, 0)
	blk(p, board, Vector3.new(1.5, 6.4, 0.25), C[v.Main])
	blk(p, at(board, 0, 0, -0.01), Vector3.new(0.35, 6.2, 0.28), C[v.Accent])
end)

kind("SaplingPalm", "Palm sapling", SUNNY, 6, {
	{ Height = 3, Leaf = "Moss" },
	{ Height = 3.8, Leaf = "Green" },
	{ Height = 4.6, Leaf = "Lime" },
	{ Height = 5.4, Leaf = "Olive" },
}, function(p, cf, v)
	rod(p, at(cf, 0, v.Height / 2, 0), v.Height, 0.5, C.Brown, M.Wood)
	for i = 1, 6 do
		blk(
			p,
			at(cf, 0, v.Height, 0)
				* CFrame.Angles(0, i / 6 * math.pi * 2, 0)
				* CFrame.Angles(math.rad(-25), 0, 0)
				* CFrame.new(0, 0, -1.2),
			Vector3.new(0.5, 0.1, 2.4),
			C[v.Leaf]
		)
	end
end)

kind("TikiTorch", "Tiki torch", SUNNY, 5, {
	{ Bowl = "Rust" },
	{ Bowl = "Brown" },
	{ Bowl = "Gold" },
	{ Bowl = "Terracotta" },
	{ Bowl = "Navy" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 2, 0), 4, 0.35, C.Brown, M.Wood)
	rod(p, at(cf, 0, 4.2, 0), 0.7, 0.9, C[v.Bowl])
	ballAt(p, at(cf, 0, 4.9, 0), 0.7, C.Orange, M.Neon)
end)

kind("Hammock", "Hammock", SUNNY, 3.2, {
	{ Main = "Red", Accent = "White" },
	{ Main = "Blue", Accent = "White" },
	{ Main = "Green", Accent = "Yellow" },
	{ Main = "Yellow", Accent = "Teal" },
}, function(p, cf, v)
	for _, x in { -3.2, 3.2 } do
		rod(p, at(cf, x, 1.5, 0), 3, 0.25, C.Brown, M.Wood)
	end
	for i = 0, 4 do
		local x = -2.4 + i * 1.2
		local sag = 0.8 * (1 - (x / 2.4) ^ 2)
		blk(
			p,
			at(cf, x, 2.7 - sag, 0),
			Vector3.new(1.3, 0.12, 1.2),
			C[if i == 2 then v.Accent else v.Main],
			M.Fabric
		)
	end
end)

kind("VolleyNet", "Volleyball net", SUNNY, 3.6, {
	{ Net = "White", Ball = "Yellow" },
	{ Net = "Cream", Ball = "White" },
	{ Net = "Aqua", Ball = "Orange" },
}, function(p, cf, v)
	for _, x in { -3, 3 } do
		rod(p, at(cf, x, 1.8, 0), 3.6, 0.25, C.Grey, M.Metal)
	end
	blk(p, at(cf, 0, 2.9, 0), Vector3.new(6, 1.2, 0.05), C[v.Net], M.Fabric, 0.35)
	blk(p, at(cf, 0, 3.5, 0), Vector3.new(6, 0.1, 0.1), C.White)
	ballAt(p, at(cf, 1.2, 0.45, 2), 0.9, C[v.Ball])
end)

kind("CoconutPile", "Coconuts", SUNNY, 2, {
	{ Count = 3 },
	{ Count = 4 },
	{ Count = 6 },
	{ Count = 10 },
}, function(p, cf, v)
	local placed = 0
	for row = 0, 3 do
		for k = 0, 3 - row do
			if placed < v.Count then
				placed += 1
				ballAt(p, at(cf, (k - (3 - row) / 2) * 0.85, 0.4 + row * 0.7, 0), 0.8, C.Brown, M.Wood)
			end
		end
	end
end)

kind("LawnChair", "Folding chair", SUNNY, 2.4, {
	{ Main = "Blue", Accent = "White" },
	{ Main = "Red", Accent = "White" },
	{ Main = "Green", Accent = "Cream" },
	{ Main = "Yellow", Accent = "Aqua" },
}, function(p, cf, v)
	blk(p, at(cf, 0, 0.9, 0), Vector3.new(1.6, 0.12, 1.4), C[v.Main], M.Fabric)
	blk(
		p,
		at(cf, 0, 1.6, 0.75) * CFrame.Angles(math.rad(-15), 0, 0),
		Vector3.new(1.6, 1.4, 0.12),
		C[v.Accent],
		M.Fabric
	)
	for _, x in { -0.7, 0.7 } do
		for _, z in { -0.6, 0.6 } do
			rod(p, at(cf, x, 0.45, z), 0.9, 0.1, C.Silver, M.Metal)
		end
	end
end)

kind("DrinkCup", "Beach drink", SUNNY, 2.2, {
	{ Drink = "Orange" },
	{ Drink = "Pink" },
	{ Drink = "Aqua" },
	{ Drink = "Lime" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 0.5, 0), 1, 0.7, C[v.Drink], M.Glass, 0.2)
	rod(p, at(cf, 0.15, 1.2, 0), 1.2, 0.07, C.White)
	rod(p, at(cf, -0.1, 1.45, 0), 0.5, 0.05, C.Brown)
	rod(p, at(cf, -0.1, 1.75, 0), 0.06, 0.7, C.Red, M.Fabric)
	ballAt(p, at(cf, 0.35, 1, 0), 0.3, C.Yellow)
end)

-- Middle Banks: fishing gear and crabs -----------------------------------------------------

kind("Crab", "Crab", BANKS, 1.2, {
	{ Main = "Red" },
	{ Main = "Orange" },
	{ Main = "Rust" },
	{ Main = "Teal" },
	{ Main = "Purple" },
	{ Main = "Sand" },
}, function(p, cf, v)
	ballAt(p, at(cf, 0, 0.55, 0), 1.2, C[v.Main])
	for _, side in { -1, 1 } do
		rod(p, at(cf, side * 0.2, 1.1, -0.45), 0.3, 0.07, C[v.Main])
		ballAt(p, at(cf, side * 0.2, 1.3, -0.45), 0.2, C.Ink)
		blk(p, at(cf, side * 0.75, 0.55, -0.7), Vector3.new(0.12, 0.12, 0.7), C[v.Main])
		ballAt(p, at(cf, side * 0.85, 0.55, -1.15), 0.5, C[v.Main])
		for k = 0, 2 do
			blk(
				p,
				at(cf, side * 0.85, 0.2, -0.1 + k * 0.3) * CFrame.Angles(0, 0, side * math.rad(25)),
				Vector3.new(0.8, 0.06, 0.06),
				C[v.Main]
			)
		end
	end
end)

kind("LobsterPot", "Lobster pot", BANKS, 1.8, {
	{ Frame = "Brown" },
	{ Frame = "Rust" },
	{ Frame = "Olive" },
	{ Frame = "DarkGrey" },
}, function(p, cf, v)
	blk(p, at(cf, 0, 0.1, 0), Vector3.new(2.6, 0.2, 1.8), C[v.Frame], M.Wood)
	blk(p, at(cf, 0, 1.6, 0), Vector3.new(2.6, 0.2, 1.8), C[v.Frame], M.Wood)
	for _, x in { -1.2, 1.2 } do
		for _, z in { -0.8, 0.8 } do
			rod(p, at(cf, x, 0.85, z), 1.5, 0.12, C[v.Frame], M.Wood)
		end
	end
	for _, z in { -0.9, 0.9 } do
		blk(p, at(cf, 0, 0.85, z), Vector3.new(2.5, 1.4, 0.04), C.Cream, M.Fabric, 0.55)
	end
end)

kind("Anchor", "Old anchor", BANKS, 1.2, {
	{ Color = "Rust", Scale = 1 },
	{ Color = "Grey", Scale = 1 },
	{ Color = "Ink", Scale = 1.3 },
	{ Color = "Verdigris", Scale = 0.8 },
}, function(p, cf, v)
	local s = v.Scale
	blk(p, at(cf, 0, 0.3 * s, 0), Vector3.new(0.35 * s, 0.35 * s, 3.6 * s), C[v.Color], M.Metal)
	blk(p, at(cf, 0, 0.3 * s, -1.4 * s), Vector3.new(1.4 * s, 0.3 * s, 0.3 * s), C[v.Color], M.Metal)
	for _, side in { -1, 1 } do
		blk(
			p,
			at(cf, side * 0.5 * s, 0.3 * s, 1.5 * s) * CFrame.Angles(0, side * math.rad(35), 0),
			Vector3.new(1.6 * s, 0.3 * s, 0.3 * s),
			C[v.Color],
			M.Metal
		)
	end
	rod(
		p,
		at(cf, 0, 0.5 * s, -1.9 * s) * CFrame.Angles(math.pi / 2, 0, 0),
		0.15 * s,
		0.9 * s,
		C[v.Color],
		M.Metal
	)
end)

kind("Bollard", "Mooring post", BANKS, 2.4, {
	{ Color = "Ink", Height = 1.4 },
	{ Color = "Rust", Height = 1.6 },
	{ Color = "Grey", Height = 1.9 },
	{ Color = "Navy", Height = 1.2 },
}, function(p, cf, v)
	rod(p, at(cf, 0, v.Height / 2, 0), v.Height, 1, C[v.Color], M.Metal)
	ballAt(p, at(cf, 0, v.Height + 0.1, 0), 1.2, C[v.Color], M.Metal)
	rod(p, at(cf, 0, 0.5, 0), 0.15, 1.7, C.Cream, M.Fabric)
end)

kind("LifeRing", "Life ring", BANKS, 1, {
	{ Main = "Red", Accent = "White" },
	{ Main = "Orange", Accent = "White" },
	{ Main = "Blue", Accent = "Yellow" },
	{ Main = "Green", Accent = "White" },
}, function(p, cf, v)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		ballAt(
			p,
			at(cf, math.cos(a) * 1.3, 0.4, math.sin(a) * 1.3),
			0.8,
			C[if i % 3 == 0 then v.Accent else v.Main]
		)
	end
end)

kind("NetPile", "Net pile", BANKS, 1.6, {
	{ Net = "Olive", Float = "Orange" },
	{ Net = "Cream", Float = "Red" },
	{ Net = "Teal", Float = "Yellow" },
	{ Net = "Brown", Float = "White" },
}, function(p, cf, v)
	for i = 0, 5 do
		rod(
			p,
			at(cf, math.sin(i) * 0.3, 0.1 + i * 0.18, math.cos(i) * 0.3),
			0.16,
			3.2 - i * 0.35,
			C[v.Net],
			M.Fabric,
			0.2
		)
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		ballAt(p, at(cf, math.cos(a) * 1.4, 0.3, math.sin(a) * 1.4), 0.5, C[v.Float])
	end
end)

kind("Oars", "Crossed oars", BANKS, 0.5, {
	{ Blade = "White" },
	{ Blade = "Red" },
	{ Blade = "Yellow" },
	{ Blade = "Blue" },
}, function(p, cf, v)
	for _, side in { -1, 1 } do
		local oar = at(cf, 0, 0.2, 0) * CFrame.Angles(0, side * math.rad(20), 0)
		blk(p, oar, Vector3.new(0.25, 0.1, 5), C.Brown, M.Wood)
		blk(p, at(oar, 0, 0, -2.5), Vector3.new(0.8, 0.08, 1.2), C[v.Blade], M.Wood)
	end
end)

-- Outer Shore: reef life -----------------------------------------------------------------------

kind("Starfish", "Starfish", OUTER, 0.5, {
	{ Main = "Orange" },
	{ Main = "Red" },
	{ Main = "Pink" },
	{ Main = "Purple" },
	{ Main = "Yellow" },
	{ Main = "Coral" },
}, function(p, cf, v)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		blk(
			p,
			at(cf, 0, 0.12, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.8),
			Vector3.new(0.45, 0.2, 1.6),
			C[v.Main]
		)
	end
	ballAt(p, at(cf, 0, 0.2, 0), 0.6, C[v.Main])
end)

kind("Urchin", "Sea urchin", OUTER, 2, {
	{ Main = "Ink" },
	{ Main = "Purple" },
	{ Main = "Magenta" },
	{ Main = "Navy" },
	{ Main = "Rust" },
}, function(p, cf, v)
	local center = at(cf, 0, 0.6, 0)
	ballAt(p, center, 1.2, C[v.Main])
	for i = 0, 13 do
		local azimuth = i * 2.4
		local polar = math.rad(20 + (i % 5) * 28)
		rod(
			p,
			center * CFrame.Angles(0, azimuth, 0) * CFrame.Angles(polar, 0, 0) * CFrame.new(0, 0.85, 0),
			0.7,
			0.07,
			C[v.Main]
		)
	end
end)

kind("SeaFan", "Sea fan", OUTER, 2.7, {
	{ Main = "Purple" },
	{ Main = "Coral" },
	{ Main = "Yellow" },
	{ Main = "Orange" },
	{ Main = "Aqua" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 0.4, 0), 0.8, 0.15, C[v.Main])
	blk(p, at(cf, 0, 1.7, 0), Vector3.new(1.6, 1.8, 0.06), C[v.Main], M.Smooth, 0.15)
	for _, side in { -1, 1 } do
		blk(
			p,
			at(cf, side * 0.5, 1.7, 0) * CFrame.Angles(0, 0, side * math.rad(-25)),
			Vector3.new(0.9, 1.6, 0.06),
			C[v.Main],
			M.Smooth,
			0.15
		)
	end
end)

kind("BrainCoral", "Brain coral", OUTER, 2.4, {
	{ Main = "Peach" },
	{ Main = "Yellow" },
	{ Main = "Lime" },
	{ Main = "Pink" },
}, function(p, cf, v)
	ballAt(p, at(cf, 0, 1, 0), 2.4, C[v.Main])
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		ballAt(p, at(cf, math.cos(a) * 1.2, 0.5, math.sin(a) * 1.2), 1.1, C[v.Main])
	end
end)

kind("Kelp", "Kelp", OUTER, 9, {
	{ Height = 5, Color = "Moss" },
	{ Height = 6, Color = "Olive" },
	{ Height = 7, Color = "Green" },
	{ Height = 8, Color = "Verdigris" },
	{ Height = 9, Color = "Lime" },
}, function(p, cf, v, rng)
	local h = v.Height
	local segment = h / 5
	local lean = CFrame.new()
	for i = 0, 4 do
		lean = lean * CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.08, 0.08))
		blk(p, cf * lean * CFrame.new(0, segment * (i + 0.5), 0), Vector3.new(0.5, segment, 0.14), C[v.Color])
	end
end, true)

kind("BarnacleRock", "Barnacle rock", OUTER, 4.2, {
	{ Size = 2.4, Color = "Stone" },
	{ Size = 3, Color = "Grey" },
	{ Size = 3.6, Color = "DarkGrey" },
	{ Size = 4.2, Color = "Brown" },
}, function(p, cf, v, rng)
	local radius = v.Size / 2
	ballAt(p, at(cf, 0, radius * 0.7, 0), v.Size, C[v.Color], M.Rock)
	for _ = 1, 14 do
		local a = rng:NextNumber() * math.pi * 2
		local tilt = rng:NextNumber(0.1, 1.1)
		ballAt(
			p,
			at(
				cf,
				math.cos(a) * math.sin(tilt) * radius,
				radius * 0.7 + math.cos(tilt) * radius,
				math.sin(a) * math.sin(tilt) * radius
			),
			0.25,
			C.White
		)
	end
end)

kind("Clam", "Giant clam", OUTER, 1.4, {
	{ Main = "Cream" },
	{ Main = "Pink" },
	{ Main = "Peach" },
	{ Main = "Lavender" },
}, function(p, cf, v)
	blk(p, at(cf, 0, 0.2, 0), Vector3.new(1.8, 0.3, 1.4), C[v.Main])
	blk(p, at(cf, 0, 0.75, 0.6) * CFrame.Angles(math.rad(-35), 0, 0), Vector3.new(1.8, 0.3, 1.4), C[v.Main])
	ballAt(p, at(cf, 0, 0.5, 0), 0.4, C.White, M.Glass)
end)

-- The Far Sandbar: ruins -----------------------------------------------------------------------

kind("ColumnDrums", "Fallen column drums", FAR, 2.6, {
	{ Stone = "Stone" },
	{ Stone = "Bone" },
	{ Stone = "Grey" },
	{ Stone = "Cream" },
}, function(p, cf, v)
	for i = 0, 2 do
		local drum = at(cf, i * 1.9 - 1.9, 1.1, math.sin(i * 2) * 0.5)
			* CFrame.Angles(0, i * 0.2, math.pi / 2)
		rod(p, drum, 1.7, 2.2 + (i % 2) * 0.3, C[v.Stone], M.Rock)
	end
	blk(p, at(cf, 0, 0.1, 0), Vector3.new(6.5, 0.2, 3), C[v.Stone], M.Rock)
end)

kind("Amphora", "Amphora", FAR, 3, {
	{ Main = "Terracotta" },
	{ Main = "Blue" },
	{ Main = "Ink" },
	{ Main = "Cream" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 0.15, 0), 0.3, 0.9, C[v.Main])
	ballAt(p, at(cf, 0, 1, 0), 1.8, C[v.Main])
	rod(p, at(cf, 0, 2.2, 0), 0.9, 0.55, C[v.Main])
	rod(p, at(cf, 0, 2.7, 0), 0.12, 0.85, C[v.Main])
	for _, side in { -1, 1 } do
		blk(
			p,
			at(cf, side * 0.55, 2, 0) * CFrame.Angles(0, 0, side * math.rad(-20)),
			Vector3.new(0.15, 0.8, 0.15),
			C[v.Main]
		)
	end
end)

kind("GlyphSlab", "Glyph stone", FAR, 3.3, {
	{ Glow = "Aqua" },
	{ Glow = "Gold" },
	{ Glow = "Mint" },
	{ Glow = "Pink" },
}, function(p, cf, v)
	local slab = at(cf, 0, 1.6, 0) * CFrame.Angles(math.rad(-4), 0, 0)
	blk(p, slab, Vector3.new(2, 3.2, 0.45), C.Stone, M.Rock)
	blk(p, at(slab, 0, 0, -0.2), Vector3.new(1.5, 2.6, 0.1), C.DarkGrey, M.Rock)
	for i = 0, 3 do
		blk(
			p,
			at(slab, ((i % 2) - 0.5) * 0.6, 0.9 - math.floor(i / 2) * 0.9, -0.27),
			Vector3.new(0.25, 0.25, 0.05),
			C[v.Glow],
			M.Neon
		)
	end
end)

kind("RibBones", "Giant ribs", FAR, 3.2, {
	{ Scale = 1, Bone = "Bone" },
	{ Scale = 1.3, Bone = "Cream" },
	{ Scale = 1.6, Bone = "Stone" },
}, function(p, cf, v)
	local s = v.Scale
	rod(p, at(cf, 0, 0.3 * s, 0) * CFrame.Angles(math.pi / 2, 0, 0), 5 * s, 0.35 * s, C[v.Bone])
	for i = 0, 4 do
		local z = (i - 2) * 0.9 * s
		for k = 0, 4 do
			local a = math.rad(k * 36)
			blk(
				p,
				at(cf, math.sin(a) * 1.6 * s, 0.3 * s + math.cos(a) * 1.3 * s, z) * CFrame.Angles(0, 0, -a),
				Vector3.new(0.18 * s, 0.9 * s, 0.18 * s),
				C[v.Bone]
			)
		end
	end
end)

kind("RuinLantern", "Ruin lantern", FAR, 4.4, {
	{ Glow = "Aqua" },
	{ Glow = "Gold" },
	{ Glow = "Pink" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 1.6, 0), 3.2, 0.5, C.Stone, M.Rock)
	blk(p, at(cf, 0, 3.3, 0), Vector3.new(1.1, 0.2, 1.1), C.Stone, M.Rock)
	blk(p, at(cf, 0, 3.95, 0), Vector3.new(0.8, 1.1, 0.8), C[v.Glow], M.Neon, 0.3)
	blk(p, at(cf, 0, 4.6, 0), Vector3.new(1, 0.15, 1), C.DarkGrey, M.Metal)
end)

-- Biome themes ---------------------------------------------------------------------------------

kind("MessageBottle", "Message in a bottle", "Driftwood Cove", 0.6, {
	{ Glass = "Green" },
	{ Glass = "Aqua" },
	{ Glass = "Orange" },
}, function(p, cf, v)
	local bottle = at(cf, 0, 0.3, 0) * CFrame.Angles(0, 0.4, math.pi / 2)
	rod(p, bottle, 1.6, 0.55, C[v.Glass], M.Glass, 0.3)
	rod(p, at(bottle, 0.9, 0, 0), 0.5, 0.25, C[v.Glass], M.Glass, 0.3)
	rod(p, at(bottle, 1.2, 0, 0), 0.15, 0.3, C.Brown, M.Wood)
	rod(p, bottle, 0.9, 0.2, C.Cream, M.Fabric)
end)

kind("Anemone", "Sea anemone", "Tidepool Rocks", 1.3, {
	{ Main = "Magenta" },
	{ Main = "Green" },
	{ Main = "Orange" },
	{ Main = "Teal" },
}, function(p, cf, v)
	ballAt(p, at(cf, 0, 0.3, 0), 1.2, C.Stone, M.Rock)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local tentacle = at(cf, 0, 0.5, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(25), 0, 0)
		rod(p, at(tentacle, 0, 0.5, 0), 0.9, 0.1, C[v.Main])
		ballAt(p, at(tentacle, 0, 1, 0), 0.16, C.White)
	end
end)

kind("SeagrassTuft", "Seagrass tuft", "Seagrass Shallows", 3, {
	{ Color = "Moss" },
	{ Color = "Green" },
	{ Color = "Olive" },
}, function(p, cf, v, rng)
	for _ = 1, 9 do
		local h = rng:NextNumber(1.5, 2.8)
		blk(
			p,
			at(cf, rng:NextNumber(-0.5, 0.5), h / 2, rng:NextNumber(-0.5, 0.5))
				* CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2)),
			Vector3.new(0.2, h, 0.04),
			C[v.Color]
		)
	end
end)

kind("CoralFinger", "Finger coral", "Coral Garden", 2.8, {
	{ Main = "Coral" },
	{ Main = "Pink" },
	{ Main = "Yellow" },
	{ Main = "Purple" },
}, function(p, cf, v, rng)
	for i = 0, 3 do
		local h = rng:NextNumber(1.5, 2.5)
		local x = (i - 1.5) * 0.5
		rod(p, at(cf, x, h / 2, 0), h, 0.45, C[v.Main])
		ballAt(p, at(cf, x, h, 0), 0.5, C[v.Main])
	end
end)

kind("TreasureChest", "Treasure chest", "Shipwreck Shallows", 2.1, {
	{ Wood = "Brown", Trim = "Gold" },
	{ Wood = "Rust", Trim = "Gold" },
	{ Wood = "Navy", Trim = "Silver" },
	{ Wood = "Olive", Trim = "Gold" },
}, function(p, cf, v)
	blk(p, at(cf, 0, 0.6, 0), Vector3.new(2.6, 1.2, 1.8), C[v.Wood], M.Wood)
	blk(p, at(cf, 0, 1.4, 0), Vector3.new(2.6, 0.4, 1.8), C[v.Wood], M.Wood)
	blk(p, at(cf, 0, 1.75, 0), Vector3.new(2.6, 0.25, 1.4), C[v.Wood], M.Wood)
	for _, x in { -0.9, 0.9 } do
		blk(p, at(cf, x, 1, 0), Vector3.new(0.2, 1.75, 1.9), C[v.Trim], M.Metal)
	end
	ballAt(p, at(cf, 0, 1.2, -0.95), 0.3, C[v.Trim], M.Metal)
end)

kind("GlowOrb", "Glow orb plant", "Jellyfish Lagoon", 2.2, {
	{ Glow = "Aqua" },
	{ Glow = "Pink" },
	{ Glow = "Mint" },
	{ Glow = "Purple" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 0.8, 0), 1.6, 0.15, C.Moss)
	ballAt(p, at(cf, 0, 1.8, 0), 0.9, C[v.Glow], M.Neon, 0.2)
	for _, side in { -1, 1 } do
		blk(
			p,
			at(cf, side * 0.3, 0.5, 0) * CFrame.Angles(0, 0, side * math.rad(-35)),
			Vector3.new(0.5, 0.1, 0.25),
			C.Moss
		)
	end
end)

kind("LanternBuoy", "Lantern buoy", "Fog Bank", 2.8, {
	{ Body = "Red" },
	{ Body = "Yellow" },
	{ Body = "White" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 0.7, 0), 1.4, 0.9, C[v.Body])
	rod(p, at(cf, 0, 1.6, 0), 0.4, 0.4, C.DarkGrey, M.Metal)
	ballAt(p, at(cf, 0, 2.1, 0), 0.6, C.Yellow, M.Neon, 0.2)
end)

kind("WindChime", "Wind chime", "Whirlwind Dunes", 3.4, {
	{ Chime = "Silver" },
	{ Chime = "Gold" },
	{ Chime = "Aqua" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 1.6, 0), 3.2, 0.2, C.Brown, M.Wood)
	blk(p, at(cf, 0.6, 3.2, 0), Vector3.new(1.4, 0.1, 0.1), C.Brown, M.Wood)
	for i = 0, 4 do
		local length = 0.8 + (i % 3) * 0.3
		rod(p, at(cf, 0.2 + i * 0.25, 3.1 - length / 2, 0), length, 0.12, C[v.Chime], M.Metal)
	end
end)

kind("SpiralShell", "Spiral shell", "Hermit Hollows", 2, {
	{ Main = "Cream" },
	{ Main = "Pink" },
	{ Main = "Peach" },
	{ Main = "Brown" },
}, function(p, cf, v)
	for i = 0, 4 do
		local d = 1.6 - i * 0.28
		rod(p, at(cf, i * 0.08, 0.15 + i * 0.3, 0), 0.3, d, C[v.Main])
	end
	ballAt(p, at(cf, -0.2, 0.3, -0.6), 0.5, C.Ink)
end)

kind("Cairn", "Stone cairn", "Spearstone Reef", 3, {
	{ Stone = "Stone" },
	{ Stone = "Grey" },
	{ Stone = "DarkGrey" },
}, function(p, cf, v)
	local y = 0
	for i = 0, 4 do
		local d = 1.8 - i * 0.28
		ballAt(p, at(cf, i % 2 * 0.1, y + d / 2, 0), d, C[v.Stone], M.Rock)
		y += d * 0.75
	end
end)

kind("SeaGlass", "Sea glass", "Sea-Glass Shore", 1, {
	{ Colors = { "Green", "Aqua", "White" } },
	{ Colors = { "Pink", "Lavender", "White" } },
	{ Colors = { "Blue", "Aqua", "Mint" } },
	{ Colors = { "Yellow", "Orange", "White" } },
}, function(p, cf, v, rng)
	for i = 1, 7 do
		local s = rng:NextNumber(0.4, 0.9)
		blk(
			p,
			at(cf, rng:NextNumber(-1, 1), s * 0.4, rng:NextNumber(-1, 1))
				* CFrame.Angles(rng:NextNumber(), rng:NextNumber(), rng:NextNumber()),
			Vector3.new(s, s * 0.6, s * 0.8),
			C[v.Colors[i % #v.Colors + 1]],
			M.Glass,
			0.25
		)
	end
end)

kind("Icicles", "Ice spikes", "Stranded Iceberg", 3, {
	{ Ice = "White" },
	{ Ice = "Aqua" },
	{ Ice = "Blue" },
	{ Ice = "Lavender" },
}, function(p, cf, v, rng)
	for i = 0, 5 do
		local x, z = rng:NextNumber(-0.8, 0.8), rng:NextNumber(-0.8, 0.8)
		local h = rng:NextNumber(1.5, 3)
		for level = 0, 2 do
			rod(p, at(cf, x, level * h / 3 + h / 6, z), h / 3, 0.6 - level * 0.2, C[v.Ice], M.Glass, 0.1)
		end
	end
end)

kind("Obsidian", "Obsidian shards", "Black Sand Vents", 2.6, {
	{ Count = 3 },
	{ Count = 4 },
	{ Count = 5 },
}, function(p, cf, v, rng)
	for _ = 1, v.Count do
		local h = rng:NextNumber(1, 2.4)
		blk(
			p,
			at(cf, rng:NextNumber(-0.7, 0.7), h / 2, rng:NextNumber(-0.7, 0.7))
				* CFrame.Angles(
					rng:NextNumber(-0.2, 0.2),
					rng:NextNumber() * math.pi,
					rng:NextNumber(-0.2, 0.2)
				),
			Vector3.new(0.6, h, 0.5),
			C.Ink,
			M.Glass,
			0.05
		)
	end
	blk(p, at(cf, 0, 0.05, 0), Vector3.new(0.3, 0.08, 0.3), C.Orange, M.Neon)
end)

kind("ToyCastle", "Toy castle", "Sandcastle Flats", 3, {
	{ Flag = "Red" },
	{ Flag = "Yellow" },
	{ Flag = "Blue" },
}, function(p, cf, v)
	rod(p, at(cf, 0, 0.6, 0), 1.2, 1.4, C.Sand, M.Sand)
	for _, x in { -0.55, 0.55 } do
		rod(p, at(cf, x, 1.5, 0), 0.6, 0.5, C.Sand, M.Sand)
	end
	rod(p, at(cf, 0, 1.8, 0), 1.2, 0.06, C.White, M.Wood)
	blk(p, at(cf, 0.3, 2.2, 0), Vector3.new(0.6, 0.4, 0.04), C[v.Flag], M.Fabric)
end)

-- The themes, in the order the design lists them.
CosmeticModels.ZoneThemes = { SHOPSIDE, SUNNY, BANKS, OUTER, FAR }

-- Models grouped by theme.
function CosmeticModels.byTheme(theme: string): { Entry }
	local found = {}
	for _, entry in CosmeticModels.List do
		if entry.Theme == theme then
			table.insert(found, entry)
		end
	end
	return found
end

return CosmeticModels
