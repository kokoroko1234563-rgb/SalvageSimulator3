--[[
	Loads the game's modules outside Roblox, with Lune (https://lune-org.github.io).
	Lune's roblox library uses Roblox's real API database, so creating an instance with a
	property or Enum item that doesn't exist, or setting a property to the wrong type (nil
	where a Color3 is needed), errors here just as it would in Studio.

	The instance tree mirrors default.project.json, and modules are required through it, so
	`script.Parent.X` and `game:GetService("ReplicatedStorage").Shared` work unchanged.

	Lune doesn't run the engine: events (Touched, Triggered, ...) and engine-only functions
	(GetServerTimeNow, Raycast, ...) are stand-ins here. Tests build things; they don't play.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Harness = {}

local realOf = setmetatable({}, { __mode = "k" }) -- proxy -> real instance
local proxyOf = setmetatable({}, { __mode = "v" }) -- real instance -> proxy

local function fakeSignal()
	return {
		Connect = function()
			return { Disconnect = function() end }
		end,
		Once = function()
			return { Disconnect = function() end }
		end,
		Wait = function() end,
	}
end

-- Engine-only members, by class, that Lune doesn't have.
local stubs = {
	Model = {
		-- Lune has no world, so a model's position is only read back, never moved.
		PivotTo = function() end,
		GetPivot = function()
			return roblox.CFrame.new()
		end,
		GetBoundingBox = function()
			return roblox.CFrame.new(), roblox.Vector3.zero
		end,
	},
	Workspace = {
		GetServerTimeNow = function()
			return os.clock()
		end,
		Raycast = function()
			return nil
		end,
		GetPartBoundsInRadius = function()
			return {}
		end,
		Gravity = 196.2,
	},
	CollectionService = {
		AddTag = function(_, instance, tag)
			Harness.unwrap(instance):AddTag(tag)
		end,
		HasTag = function(_, instance, tag)
			return Harness.unwrap(instance):HasTag(tag)
		end,
		GetTagged = function()
			return {}
		end,
	},
	HttpService = {
		GenerateGUID = function()
			return string.format("%08x-test", math.random(0, 0x7fffffff))
		end,
	},
	Players = {
		-- Builds an avatar-shaped model (the engine's real one loads the default character).
		CreateHumanoidModelFromDescriptionAsync = function()
			local model = roblox.Instance.new("Model")
			for _, name in { "HumanoidRootPart", "Head", "Torso" } do
				local part = roblox.Instance.new("Part")
				part.Name = name
				part.Parent = model
			end
			roblox.Instance.new("Humanoid").Parent = model
			return Harness.wrap(model)
		end,
		GetPlayers = function()
			return {}
		end,
		GetPlayerByUserId = function()
			return nil
		end,
		GetPlayerFromCharacter = function()
			return nil
		end,
	},
	RunService = {
		IsStudio = function()
			return true
		end,
		IsServer = function()
			return true
		end,
	},
	Terrain = {
		WriteVoxels = function() end,
		SetMaterialColor = function() end,
	},
	PhysicsService = {
		RegisterCollisionGroup = function() end,
		CollisionGroupSetCollidable = function() end,
	},
	BasePart = {
		SetNetworkOwner = function() end,
		ApplyImpulse = function() end,
	},
}

-- Tests can swap a stand-in for one test (restore it after).
Harness.stubs = stubs

function Harness.unwrap(value)
	return realOf[value] or value
end

local function unwrapAll(...)
	local args = table.pack(...)
	for i = 1, args.n do
		args[i] = Harness.unwrap(args[i])
	end
	return table.unpack(args, 1, args.n)
end

local function stubFor(real, key)
	local ok, isPart = pcall(function()
		return real:IsA("BasePart")
	end)
	local classStubs = stubs[real.ClassName] or (ok and isPart and stubs.BasePart) or nil
	return classStubs and classStubs[key]
end

-- Wraps an instance so missing engine members get stand-ins, and proxies passed back into
-- Lune are unwrapped.
function Harness.wrap(real)
	if real == nil or realOf[real] then
		return real
	end
	if typeof(real) ~= "Instance" then
		return real
	end
	if proxyOf[real] then
		return proxyOf[real]
	end
	local proxy = setmetatable({}, {
		__index = function(_, key)
			-- Stand-ins win: some engine services' methods exist in Lune only as generic
			-- Instance methods with different arguments (CollectionService.AddTag).
			local stub = stubFor(real, key)
			if stub ~= nil then
				return stub
			end
			local ok, value = pcall(function()
				return real[key]
			end)
			if not ok then
				-- Events aren't supported by Lune: anything else that's missing is a real error.
				local message = tostring(value)
				if
					type(key) == "string"
					and string.match(message, "is not a valid member")
					and Harness.isEvent(real, key)
				then
					return fakeSignal()
				end
				error(value, 2)
			end
			if type(value) == "function" then
				return function(_, ...)
					local result = value(real, unwrapAll(...))
					-- Lists of instances (GetChildren, GetDescendants) come back wrapped too.
					if type(result) == "table" and not realOf[result] and typeof(result[1]) == "Instance" then
						local list = table.create(#result)
						for i, item in result do
							list[i] = Harness.wrap(item)
						end
						return list
					end
					return Harness.wrap(result)
				end
			end
			return Harness.wrap(value)
		end,
		__newindex = function(_, key, value)
			real[key] = Harness.unwrap(value)
		end,
		__tostring = function()
			return tostring(real)
		end,
		__eq = function(a, b)
			return Harness.unwrap(a) == Harness.unwrap(b)
		end,
	})
	realOf[proxy] = real
	proxyOf[real] = proxy
	return proxy
end

-- Event names the game uses (Lune has no events); anything else missing is a typo.
local EVENTS = {
	Triggered = true,
	Touched = true,
	Activated = true,
	Changed = true,
	Heartbeat = true,
	Stepped = true,
	RenderStepped = true,
	Died = true,
	CharacterAdded = true,
	CharacterRemoving = true,
	PlayerAdded = true,
	PlayerRemoving = true,
	DescendantAdded = true,
	InputBegan = true,
	InputChanged = true,
	InputEnded = true,
	FocusLost = true,
	OnServerEvent = true,
	OnClientEvent = true,
	Completed = true,
	Destroying = true,
}
function Harness.isEvent(_real, key)
	return EVENTS[key] == true
end

-- A minimal Random (Lune has none).
local Random = {}
Random.__index = Random
function Random.new(seed)
	return setmetatable({ seed = seed }, Random)
end
function Random:NextNumber(min, max)
	min, max = min or 0, max or 1
	return min + math.random() * (max - min)
end
function Random:NextInteger(min, max)
	return math.random(min, max)
end

local function plainNew()
	return {
		new = function()
			return {}
		end,
	}
end

function Harness.new(root: string)
	local game = roblox.Instance.new("DataModel")
	local modulePaths = {} -- ModuleScript full name -> file path
	local cache = {}

	local mount
	function mount(parent, name, className, folder)
		local container = roblox.Instance.new(className)
		container.Name = name
		container.Parent = parent
		for _, file in fs.readDir(folder) do
			local path = folder .. "/" .. file
			local stem = string.match(file, "^(.-)%.luau$")
			if stem and not string.match(stem, "^init") then
				local module = roblox.Instance.new("ModuleScript")
				module.Name = stem
				module.Parent = container
				modulePaths[module:GetFullName()] = path
			elseif fs.isDir(path) then
				-- A folder with an init.luau is a module with children (as Rojo builds it).
				local hasInit = fs.isFile(path .. "/init.luau")
				local child = mount(container, file, if hasInit then "ModuleScript" else "Folder", path)
				if hasInit then
					modulePaths[child:GetFullName()] = path .. "/init.luau"
				end
			end
		end
		return container
	end

	mount(game:GetService("ReplicatedStorage"), "Shared", "Folder", root .. "/src/shared")
	mount(game:GetService("ServerScriptService"), "Server", "Script", root .. "/src/server")
	local starterPlayer = game:GetService("StarterPlayer")
	local scripts = roblox.Instance.new("StarterPlayerScripts")
	scripts.Parent = starterPlayer
	mount(scripts, "Client", "LocalScript", root .. "/src/client")

	local base = {}
	local function requireModule(module)
		local real = Harness.unwrap(module)
		local name = real:GetFullName()
		if cache[name] ~= nil then
			return cache[name]
		end
		local path = modulePaths[name]
		assert(path, "no module at " .. name)
		-- Lune copies the environment's own keys (it ignores __index), so pass a flat copy.
		local env = table.clone(base)
		env.script = Harness.wrap(real)
		local chunk = luau.load(fs.readFile(path), { debugName = path, environment = env })
		local result = chunk()
		cache[name] = result
		return result
	end

	local gameProxy = Harness.wrap(game)
	for key, value in roblox do
		base[key] = value
	end
	base.Instance = {
		new = function(className, parent)
			local instance = Harness.wrap(roblox.Instance.new(className))
			if parent then
				instance.Parent = parent
			end
			return instance
		end,
	}
	base.game = gameProxy
	base.workspace = gameProxy:GetService("Workspace")
	base.require = requireModule
	base.typeof = function(value)
		return typeof(Harness.unwrap(value))
	end
	base.Random = Random
	base.RaycastParams = plainNew()
	base.OverlapParams = plainNew()
	base.TweenInfo = plainNew()
	base.task = {
		spawn = task.spawn,
		defer = task.defer,
		delay = function() end, -- timers never fire in tests
		wait = function()
			return 0
		end,
	}
	base.warn = function(...)
		print("[warn]", ...)
	end
	local builtins = {
		print = print,
		pairs = pairs,
		ipairs = ipairs,
		math = math,
		string = string,
		table = table,
		os = os,
		type = type,
		tostring = tostring,
		tonumber = tonumber,
		pcall = pcall,
		xpcall = xpcall,
		error = error,
		assert = assert,
		select = select,
		setmetatable = setmetatable,
		getmetatable = getmetatable,
		next = next,
		rawget = rawget,
		rawset = rawset,
		rawequal = rawequal,
		utf8 = utf8,
		bit32 = bit32,
		buffer = buffer,
		coroutine = coroutine,
	}
	for name, value in builtins do
		base[name] = value
	end

	return {
		game = gameProxy,
		require = function(path: string)
			-- "Shared/Config", "Server/VesselService", "Client/SecretController"
			local where, name = string.match(path, "^(%w+)/(%w+)$")
			local roots = {
				Shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared"),
				Server = game:GetService("ServerScriptService"):FindFirstChild("Server"),
				Client = scripts:FindFirstChild("Client"),
			}
			local module = roots[where]:FindFirstChild(name)
			assert(module, "no module " .. path)
			return requireModule(module)
		end,
		modules = function()
			local list = {}
			for name in modulePaths do
				table.insert(list, name)
			end
			table.sort(list)
			return list
		end,
		wrap = Harness.wrap,
		roblox = roblox,
	}
end

return Harness
