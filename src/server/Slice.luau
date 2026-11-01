--!strict
--[[
	Time slicing for heavy work that has to run in the live game (rebuilding terrain, decor and
	barriers when the tide rerolls the biomes): `local pause = Slice.new("Name")`, then call
	`pause()` in the work's loops. It gives the frame back (task.wait) once the work since the
	last pause has used more than the budget, so the work is a run of short frames and not one
	long one. The longest run between two pauses is timed (Perf) under the name.
	Call it only where waiting is fine: a thread of its own, or startup.
]]

local Perf = require(script.Parent.Perf)

local Slice = {}

-- Seconds of work between pauses: a third of a 60 fps frame.
Slice.BUDGET = 0.005

function Slice.new(name: string, budget: number?): () -> ()
	local limit = budget or Slice.BUDGET
	local runStart = os.clock()
	return function()
		if os.clock() - runStart > limit then
			Perf.stop(name, runStart)
			task.wait()
			runStart = os.clock()
		end
	end
end

return Slice
