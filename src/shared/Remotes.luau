-- One place that names every remote. The server creates them on startup; clients wait.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local FUNCTIONS = {
	"GrabRequest", -- (part) -> ok, reason
	"Buy", -- (category, id) -> ok, reason
	"SpawnVessel", -- (id) -> ok, reason
	"AdminCommand", -- (commandLine) -> { output lines } (admins only)
	"Rebirth", -- () -> ok, reason
	"TrueRebirth", -- () -> ok, reason
	"Trade", -- (action, ...) -> ok, reason (see TradeService)
	"TraderBuy", -- (encounterId) -> ok, reason
	"AuctionBid", -- (lotId, amount) -> ok, reason
	"AuctionState", -- () -> current lot, your bid, recent winners
	"ChooseReward", -- (rewardId) -> ok, reason
	"GetInventory", -- () -> snapshot (see InventoryService)
	"InventoryAction", -- (action, arg, value?) -> ok, reason
	"Review", -- (action, arg?) -> ok, text (admins in the review place, see ReviewService)
}

local EVENTS = {
	"Release", -- client -> server (part, reason?)
	"SendToVessel", -- client -> server (part)
	"Notify", -- server -> client (text, kind?)
	"OpenShop", -- server -> client ()
	"SecretEvent", -- server -> client ("start", info) | ("end")
	"SecretReady", -- client -> server () course built, ready to teleport
	"ClaimChest", -- client -> server ()
	"Pocket", -- client -> server ("store", part) | ("drop", slot?)
	"InventorySync", -- server -> client (snapshot) whenever the inventory changes
	"TradeSync", -- server -> client (trade state) whenever a trade or invite changes
	"TraderOpen", -- server -> client (offer) when a player talks to a special trader
	"HazardHarm", -- client -> server (hazard part) this client's character was hit by a Harm or swallowed by a Sink
}

local Remotes = {}

function Remotes.init()
	assert(RunService:IsServer(), "Remotes.init is server-only")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) or Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in FUNCTIONS do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		end
	end
	for _, name in EVENTS do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
end

-- Server: answers a RemoteFunction with `handler`, which returns (ok, reason). If the
-- handler errors, the error goes to Output and the player gets a message instead of the
-- button silently doing nothing.
function Remotes.handle(name: string, handler: (Player, ...any) -> (boolean, string?))
	Remotes.get(name).OnServerInvoke = function(player: Player, ...)
		local called, ok, reason = pcall(handler, player, ...)
		if not called then
			warn(string.format("[Remotes] %s from %s errored: %s", name, player.Name, tostring(ok)))
			return false, "Something went wrong (server error, see Output)"
		end
		return ok, reason
	end
end

function Remotes.get(name: string): any
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	return folder:WaitForChild(name)
end

return Remotes
