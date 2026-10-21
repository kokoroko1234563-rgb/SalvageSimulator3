-- Every kind of thing that can sit in a player's inventory, and the rules for it:
-- category, rarity (the card's colour), whether it can be traded, and which reset removes
-- it (the card's border). Built from the shop gear and the unlock items, so a new tool,
-- vessel or unlock item shows up here automatically.
--
-- Resets:
--   "Rebirth"      lost on a normal rebirth (and so also on a true rebirth): shop gear
--   "TrueRebirth"  kept through normal rebirths, lost on a true rebirth: magical rewards
--   "Never"        kept through everything: unlock items, secret rewards, cosmetics
--
-- Exotic items (from exotic secrets) can only be used once the player is attuned to that
-- item type (an attunement core, see InventoryService).

local Config = require(script.Parent.Config)
local Gear = require(script.Parent.Gear)
local Items = require(script.Parent.Items)

local Catalog = {}

export type Entry = {
	Id: string,
	Name: string,
	Category: "Tool" | "Vessel" | "Accessory" | "Cosmetic" | "Unlock",
	Rarity: string,
	Tradeable: boolean,
	Resets: "Rebirth" | "TrueRebirth" | "Never",
	ShopItem: boolean,
	Exotic: boolean,
	Description: string,
	Order: number,
}

Catalog.Categories = { "Tool", "Vessel", "Accessory", "Cosmetic", "Unlock" }

Catalog.ResetText = {
	Rebirth = "Lost on rebirth",
	TrueRebirth = "Lost on true rebirth",
	Never = "Never lost",
}

local entries: { [string]: Entry } = {}
local order = 0

local function add(entry)
	order += 1
	entry.Order = order
	entries[entry.Id] = entry
end

for _, tool in Gear.Tools do
	if tool.Id ~= "BareHands" then -- everyone always has their hands
		add({
			Id = tool.Id,
			Name = tool.Name,
			Category = "Tool",
			Rarity = tool.Rarity,
			Tradeable = tool.Exotic == true,
			Resets = if tool.Exotic then "Never" elseif tool.Magical then "TrueRebirth" else "Rebirth",
			ShopItem = not tool.Exotic and not tool.Magical,
			Exotic = tool.Exotic == true,
			-- (The shop tools' notes already say which zone they work.)
			Description = string.format(
				"%s. Reach %d.%s",
				tool.Note,
				tool.Reach,
				if string.find(tool.Note, "Works up to", 1, true)
					then ""
					else string.format(
						" Works up to zone %d (%s).",
						tool.Tier,
						Config.Zones[tool.Tier].Name
					)
			),
		})
	end
end

for _, vessel in Gear.Vessels do
	add({
		Id = vessel.Id,
		Name = vessel.Name,
		Category = "Vessel",
		Rarity = vessel.Rarity,
		Tradeable = vessel.Exotic == true,
		Resets = if vessel.Exotic then "Never" elseif vessel.Magical then "TrueRebirth" else "Rebirth",
		ShopItem = not vessel.Magical and not vessel.Exotic,
		Exotic = vessel.Exotic == true,
		Description = string.format("%s. Holds %d.", vessel.Note, vessel.Capacity),
	})
end

for _, accessory in Gear.Accessories do
	add({
		Id = accessory.Id,
		Name = accessory.Name,
		Category = "Accessory",
		Rarity = accessory.Rarity,
		Tradeable = true,
		Resets = "Never",
		ShopItem = false,
		Exotic = accessory.Exotic == true,
		Description = accessory.Note .. ".",
	})
end

for _, cosmetic in Gear.Cosmetics do
	add({
		Id = cosmetic.Id,
		Name = cosmetic.Name,
		Category = "Cosmetic",
		Rarity = cosmetic.Rarity,
		Tradeable = cosmetic.Tradeable == true,
		Resets = "Never",
		ShopItem = false,
		Exotic = false,
		Description = cosmetic.Note .. ".",
	})
end

for _, item in Items.Catalog do
	if item.Unlock then
		add({
			Id = item.Id,
			Name = item.Name,
			Category = "Unlock",
			Rarity = "Unlock",
			Tradeable = true,
			Resets = "Never",
			ShopItem = false,
			Exotic = false,
			Description = (item.UnlockNote or "Opens a secret") .. ". Used up when you go in, win or lose.",
		})
	end
end

function Catalog.get(id: string?): Entry?
	return entries[id or ""]
end

function Catalog.all(): { [string]: Entry }
	return entries
end

-- Whether a reset of kind `reset` ("Rebirth" or "TrueRebirth") removes this entry.
function Catalog.lostOn(entry: Entry, reset: string): boolean
	if entry.Resets == "Never" then
		return false
	end
	if reset == "TrueRebirth" then
		return true
	end
	return entry.Resets == "Rebirth"
end

return Catalog
