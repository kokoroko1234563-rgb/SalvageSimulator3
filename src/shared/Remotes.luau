-- One place that names every remote. The server creates them on startup; clients wait.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local FUNCTIONS = {
	"GrabRequest", -- (part) -> ok, reason
	"Buy", -- (category, id) -> ok, reason
	"SpawnVessel", -- (id) -> ok, reason
}

local EVENTS = {
	"Release", -- client -> server (part, reason?)
	"SendToVessel", -- client -> server (part)
	"Notify", -- server -> client (text, kind?)
	"OpenShop", -- server -> client ()
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

function Remotes.get(name: string): any
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	return folder:WaitForChild(name)
end

return Remotes
