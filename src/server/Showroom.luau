-- The showroom: an open-air gallery off the map for looking at the game's models, materials
-- and colours side by side. It's laid out automatically from a catalogue of sections
-- (ShowroomExhibits): each section is a run of exhibits in rows, each exhibit on its own
-- floor tile (or pedestal) with its name on a sign. To show something new, add an entry to
-- the catalogue; the room sizes itself.
--
-- Every exhibit is built at a staging point, measured, then moved into place, so builders
-- don't need to know where they'll end up or how big they are. Everything is anchored and
-- the room is far from the beach (on the shop side, Z < 0, so no tide or wave reaches it).
-- Admins get there with `tp showroom` (or `tp showroom <section>`).

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Palette = require(Shared.Palette)

local MapParts = require(script.Parent.MapParts)

local cfg = Config.Showroom

local Showroom = {}

-- Builders run here, then get moved. It's on the flat shop side (Z < 0), where the beach's
-- ground height is 0, so builders that place things with Beach.groundY stay level.
Showroom.Stage = Vector3.new(cfg.Origin.X, 0, cfg.Origin.Z - 5000)

export type Exhibit = {
	Name: string,
	Note: string?, -- a second line on the sign
	Pedestal: number?, -- studs: stand it on a pedestal this tall (small things)
	-- Builds the exhibit into `parent`, around `at` (the floor point it should stand on).
	Build: (parent: Instance, at: CFrame) -> (),
}

export type Section = {
	Name: string,
	Description: string?,
	Exhibits: { Exhibit },
}

-- Where each section starts, for teleporting (filled in by build).
Showroom.Sections = {} :: { [string]: Vector3 }

-- The box around every part under `root`: its min and max corners.
local function bounds(root: Instance): (Vector3?, Vector3?)
	local lo, hi = nil, nil
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") then
			local half = part.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local corner = part.CFrame * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
						-- A broken part (NaN) would spoil the whole box: leave it out.
						if corner == corner and corner.Magnitude < math.huge then
							lo = if lo then lo:Min(corner) else corner
							hi = if hi then hi:Max(corner) else corner
						end
					end
				end
			end
		end
	end
	return lo, hi
end

-- Anchors everything (exhibits are for looking at) and moves it all by `delta`. Prompts are
-- removed: a door in the showroom doesn't open anything.
local function settle(root: Instance, delta: Vector3)
	for _, child in root:GetDescendants() do
		if child:IsA("BasePart") then
			child.Anchored = true
			child.CFrame += delta
		elseif child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end
end

local function floorTile(parent: Instance, center: Vector3, size: Vector2, color: Color3)
	MapParts.part({
		Name = "Tile",
		Size = Vector3.new(size.X, 0.2, size.Y),
		CFrame = CFrame.new(center + Vector3.new(0, 0.1, 0)),
		Color = color,
		Material = Palette.Material.Smooth,
	}).Parent =
		parent
end

-- Builds one exhibit at the stage, measures it, and returns its folder and footprint.
local function stage(exhibit: Exhibit): (Folder, Vector3, Vector3)
	local folder = Instance.new("Folder")
	folder.Name = exhibit.Name
	local ok, err = pcall(exhibit.Build, folder, CFrame.new(Showroom.Stage))
	if not ok then
		warn("[Showroom] couldn't build", exhibit.Name, err)
		-- A red block stands in for anything that fails, so it's noticed.
		MapParts.part({
			Name = "BuildFailed",
			Size = Vector3.new(2, 2, 2),
			CFrame = CFrame.new(Showroom.Stage + Vector3.new(0, 1, 0)),
			Color = Palette.UI.Danger,
		}).Parent =
			folder
	end
	local lo, hi = bounds(folder)
	if not lo or not hi then
		lo, hi = Showroom.Stage, Showroom.Stage + Vector3.new(1, 1, 1)
	end
	return folder, lo :: Vector3, hi :: Vector3
end

local function buildSection(room: Folder, section: Section, frontZ: number): number
	local folder = Instance.new("Folder")
	folder.Name = section.Name
	folder.Parent = room
	local x0 = cfg.Origin.X - cfg.RowWidth / 2

	-- The section's title, across the aisle at its start.
	local titleZ = frontZ - 4
	MapParts.sign(
		folder,
		section.Name,
		CFrame.new(cfg.Origin.X, 9, titleZ),
		math.min(cfg.RowWidth * 0.5, 60),
		5,
		0
	)
	if section.Description then
		MapParts.sign(
			folder,
			section.Description,
			CFrame.new(cfg.Origin.X, 4.5, titleZ),
			math.min(cfg.RowWidth * 0.6, 80),
			2
		)
	end
	Showroom.Sections[section.Name:lower()] = Vector3.new(cfg.Origin.X, 4, frontZ + 4)

	-- Rows of exhibits, filling toward -Z.
	local z = titleZ - 8
	local x = x0
	local rowDepth = 0
	local tileColor = Palette.World.Sand:Lerp(Color3.new(1, 1, 1), 0.55)
	for _, exhibit in section.Exhibits do
		local built, lo, hi = stage(exhibit)
		local size = hi - lo
		local pedestal = exhibit.Pedestal or 0
		local cellW = math.max(size.X, 4) + cfg.Gap
		local cellD = math.max(size.Z, 4) + cfg.Gap + 3 -- room for the name sign in front
		if x + cellW > x0 + cfg.RowWidth and x > x0 then
			-- Next row.
			z -= rowDepth + cfg.Aisle
			x = x0
			rowDepth = 0
		end
		local center = Vector3.new(x + cellW / 2, 0, z - cellD / 2)
		local cell = Instance.new("Folder")
		cell.Name = exhibit.Name
		cell.Parent = folder
		floorTile(cell, center, Vector2.new(cellW - 1, cellD - 1), tileColor)
		if pedestal > 0 then
			MapParts.part({
				Name = "Pedestal",
				Size = Vector3.new(size.X + 1.5, pedestal, size.Z + 1.5),
				CFrame = CFrame.new(center + Vector3.new(0, pedestal / 2, -1.5)),
				Color = Palette.UI.Soft,
				Material = Palette.Material.Smooth,
			}).Parent =
				cell
		end
		-- Move the exhibit so the bottom of its box sits on the tile (or pedestal), centred.
		local target = Vector3.new(center.X, pedestal + 0.2, center.Z - 1.5)
		local bottomCenter = Vector3.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
		settle(built, target - bottomCenter)
		built.Parent = cell
		local label = if exhibit.Note then exhibit.Name .. "\n" .. exhibit.Note else exhibit.Name
		MapParts.sign(
			cell,
			label,
			CFrame.new(center.X, 1.2, center.Z + cellD / 2 - 1),
			math.clamp(cellW - 2, 4, 14),
			if exhibit.Note then 1.8 else 1.2,
			0
		)
		x += cellW
		rowDepth = math.max(rowDepth, cellD)
	end
	return z - rowDepth - cfg.SectionGap
end

-- Builds the whole room into a "Showroom" folder in `parent`.
function Showroom.build(parent: Instance, sections: { Section }): Folder
	local room = Instance.new("Folder")
	room.Name = "Showroom"
	local front = cfg.Origin.Z
	local z = front - 10
	for _, section in sections do
		z = buildSection(room, section, z)
	end
	local back = z
	local depth = front - back
	local width = cfg.RowWidth + 40
	local mid = Vector3.new(cfg.Origin.X, 0, (front + back) / 2)

	MapParts.part({
		Name = "Floor",
		Size = Vector3.new(width, 4, depth),
		CFrame = CFrame.new(mid - Vector3.new(0, 2, 0)),
		Color = Palette.UI.Soft,
		Material = Palette.Material.Smooth,
	}).Parent =
		room
	-- Low walls around it, so it reads as a room.
	for _, wall in
		{
			{ Vector3.new(width, cfg.WallHeight, 1), Vector3.new(0, 0, depth / 2) },
			{ Vector3.new(width, cfg.WallHeight, 1), Vector3.new(0, 0, -depth / 2) },
			{ Vector3.new(1, cfg.WallHeight, depth), Vector3.new(width / 2, 0, 0) },
			{ Vector3.new(1, cfg.WallHeight, depth), Vector3.new(-width / 2, 0, 0) },
		}
	do
		MapParts.part({
			Name = "Wall",
			Size = wall[1],
			CFrame = CFrame.new(mid + wall[2] + Vector3.new(0, cfg.WallHeight / 2, 0)),
			Color = Palette.UI.Background,
			Material = Palette.Material.Smooth,
		}).Parent =
			room
	end
	MapParts.sign(room, "Showroom", CFrame.new(cfg.Origin.X, 14, front - 2), 40, 7, 0)
	Showroom.Entrance = Vector3.new(cfg.Origin.X, 4, front - 6)
	room.Parent = parent
	return room
end

Showroom.Entrance = cfg.Origin + Vector3.new(0, 4, -6)

-- For tools/tests.
Showroom._bounds = bounds

return Showroom
