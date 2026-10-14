-- Salvage Simulator 3, Milestone 1 client entry point.

local HUD = require(script.HUD)
local TideController = require(script.TideController)
local WaveController = require(script.WaveController)
local GrabController = require(script.GrabController)

HUD.init()
TideController.init()
WaveController.init()
GrabController.init()
