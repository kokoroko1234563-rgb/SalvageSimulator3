-- The sky-beam item (the Beacon Pearl): the rarest unlock item. Clients draw the beam of
-- light over it (SkyBeamController); the server tells everyone when it appears, who has
-- it, and when it's banked or lost, so carrying it home becomes a server-wide event.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Beach = require(Shared.Beach)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)

local ItemService = require(script.Parent.ItemService)

local SkyBeamService = {}

local notifyAll: (string) -> () = function(_text: string) end

local function track(item: BasePart)
	if not item:GetAttribute("ItemId") or not Items.get(item:GetAttribute("ItemId")).SkyBeam then
		return
	end
	local name = Items.get(item:GetAttribute("ItemId")).Name
	notifyAll(
		string.format(
			"A beam of light shines over zone %d. The %s has washed up!",
			Beach.zoneAt(item.Position.Z) or 0,
			name
		)
	)
	local lastOwner = 0
	item:GetAttributeChangedSignal("Owner"):Connect(function()
		local owner = item:GetAttribute("Owner") or 0
		if owner ~= 0 and owner ~= lastOwner then
			local player = Players:GetPlayerByUserId(owner)
			if player then
				notifyAll(player.DisplayName .. " has the " .. name .. "! Follow the beam.")
			end
		end
		lastOwner = owner
	end)
end

function SkyBeamService.init()
	local notifyRemote = Remotes.get("Notify")
	notifyAll = function(text: string)
		notifyRemote:FireAllClients(text)
	end
	ItemService.onCreated(track)
	ItemService.onDestroyed(function(item)
		local def = Items.get(item:GetAttribute("ItemId") or "")
		if def and def.SkyBeam then
			local bankedBy = item:GetAttribute("BankedBy")
			notifyAll(
				if bankedBy
					then bankedBy .. " banked the " .. def.Name .. "!"
					else "The " .. def.Name .. " was lost."
			)
		end
	end)
end

return SkyBeamService
