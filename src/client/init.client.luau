-- Salvage Simulator 3 client entry point (Milestones 1 and 2).

local AdminConsole = require(script.AdminConsole)
local HUD = require(script.HUD)
local TideController = require(script.TideController)
local WaveController = require(script.WaveController)
local GrabController = require(script.GrabController)
local SecretController = require(script.SecretController)

HUD.init()
TideController.init()
WaveController.init()
GrabController.init()
SecretController.init()
AdminConsole.init()
