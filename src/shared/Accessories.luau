-- The rules behind the exotic accessories' powers (Gear.Accessories), kept free of the engine so
-- the server, the client and the tests all use the same ones. Reads only a player's attributes
-- and plain numbers.

local Gear = require(script.Parent.Gear)

local Accessories = {}

Accessories.WalkAttribute = "WaterWalkUntil" -- server time the Tidewalker Boots' walk ends (a player attribute)

local function worn(player)
	return Gear.getAccessory(player:GetAttribute("Accessory"))
end
Accessories.worn = worn

-- Deckhand's Satchel -----------------------------------------------------------------------

-- What something sold from the pockets is worth to this player.
function Accessories.pocketValue(player, value: number): number
	local accessory = worn(player)
	local bonus = if accessory and accessory.PocketSellBonus then accessory.PocketSellBonus else 0
	return math.floor(value * (1 + bonus) + 0.5)
end

-- Tide Crown -------------------------------------------------------------------------------

export type Window = {
	Zone: number,
	AlwaysOpen: boolean, -- uncovered the whole time
	NeverOpen: boolean, -- never uncovered
	Open: boolean, -- uncovered now
	OpensIn: number?, -- seconds until it uncovers (0 when it already is)
	ClosesIn: number?, -- seconds until it is covered again (nil when it never closes)
}

-- When each zone uncovers and closes again, looking ahead one cycle from `now`. A zone is
-- uncovered while the waterline (Z, bigger = further out) is past the zone's near edge, so
-- `edges` is { { Zone, Z } } and `waterlineAt(time)` is the sea's waterline then.
function Accessories.timeline(
	waterlineAt: (number) -> number,
	now: number,
	cycleLength: number,
	edges: { { Zone: number, Z: number } }
): { Window }
	local steps = 600
	local horizon = cycleLength * 2 -- long enough to see a zone close after it opens
	local dt = horizon / steps
	local windows = {}
	for _, edge in edges do
		local function open(t: number): boolean
			return waterlineAt(t) >= edge.Z
		end
		-- Bisects between a time the state is `from` and one it isn't, to the crossing.
		local function crossing(a: number, b: number): number
			local state = open(a)
			for _ = 1, 14 do
				local mid = (a + b) / 2
				if open(mid) == state then
					a = mid
				else
					b = mid
				end
			end
			return (a + b) / 2
		end
		local isOpen = open(now)
		local opens: number? = if isOpen then 0 else nil
		local closes: number? = nil
		local always, never = true, true
		local last = now
		local lastOpen = isOpen
		if isOpen then
			never = false
		else
			always = false
		end
		for i = 1, steps do
			local t = now + i * dt
			local o = open(t)
			if o then
				never = false
			else
				always = false
			end
			if o ~= lastOpen then
				local at = crossing(last, t) - now
				if o and not opens then
					opens = at
				elseif not o and not closes and (opens or isOpen) then
					closes = at
				end
			end
			last, lastOpen = t, o
			if opens and closes then
				break
			end
		end
		table.insert(windows, {
			Zone = edge.Zone,
			AlwaysOpen = always,
			NeverOpen = never,
			Open = isOpen,
			OpensIn = opens,
			ClosesIn = closes,
		})
	end
	return windows
end

-- Cooldowns ----------------------------------------------------------------------------------

-- Whether an ability used at `lastUse` is ready again at `now`.
function Accessories.ready(lastUse: number?, now: number, cooldown: number): boolean
	return lastUse == nil or now - lastUse >= cooldown
end

-- Foghorn ------------------------------------------------------------------------------------

-- Where the Foghorn's blast moves free items to: each Unclaimed item within `range` studs of
-- `origin` moves `pull` studs toward it (never past it). `items` are anything with a Position
-- and a State attribute. Returns { { Item, Position } }.
function Accessories.foghornPull(origin: Vector3, items, range: number, pull: number)
	local moves = {}
	for _, item in items do
		if item:GetAttribute("State") ~= "Unclaimed" then
			continue
		end
		local offset = origin - item.Position
		local distance = offset.Magnitude
		if distance > range or distance < 0.01 then
			continue
		end
		table.insert(moves, { Item = item, Position = item.Position + offset.Unit * math.min(pull, distance) })
	end
	return moves
end

-- Tidewalker Boots ---------------------------------------------------------------------------

-- Whether the player is walking on water at server time `now`.
function Accessories.isWaterWalking(player, now: number): boolean
	local until_ = player:GetAttribute(Accessories.WalkAttribute)
	return type(until_) == "number" and now < until_
end

-- Whether deep water drowns the player right now (the Boots' walk keeps them on the surface).
function Accessories.canDrown(player, now: number): boolean
	return not Accessories.isWaterWalking(player, now)
end

-- Prism Lens ---------------------------------------------------------------------------------

-- Whether the Prism Lens shines this item through walls: Rare and VeryRare ones (every biome
-- very-rare is VeryRare) and unlock items, free (Unclaimed) and within `radius` studs.
function Accessories.prismReveals(item, distance: number, radius: number): boolean
	if radius <= 0 or distance > radius or item:GetAttribute("State") ~= "Unclaimed" then
		return false
	end
	local rarity = item:GetAttribute("Rarity")
	return rarity == "Rare" or rarity == "VeryRare" or rarity == "Unlock" or item:GetAttribute("Unlock") ~= nil
end

-- Ember Lantern ------------------------------------------------------------------------------

-- The grip a player keeps on ice: nil when they don't slide at all.
function Accessories.iceGrip(player, grip: number): number?
	local accessory = worn(player)
	if accessory and accessory.NoSlide then
		return nil
	end
	return grip
end

-- Lantern of Clear Sight ---------------------------------------------------------------------

-- How much of the Fog hazard's fog closes in on a player (1 = all of it), and how far they see
-- through it, as a multiple of its Sight.
function Accessories.fogShare(player): number
	local accessory = worn(player)
	return if accessory and accessory.ClearSight then 1 / accessory.ClearSight else 1
end

function Accessories.fogSightScale(player): number
	local accessory = worn(player)
	return if accessory and accessory.ClearSight then accessory.ClearSight else 1
end

-- Glow Pearl ---------------------------------------------------------------------------------

-- The most the Gloom can black the world out for this player (1 = fully; the Glow Pearl keeps a
-- pool of light, so it never closes all the way).
function Accessories.gloomBlind(player): number
	local accessory = worn(player)
	local light = accessory and accessory.GloomLight
	return if light then light.Blind else 1
end

return Accessories
