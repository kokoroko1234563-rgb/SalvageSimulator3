--!strict
--[[
	Server frame timing: how long the pieces of work that might make a long frame take.
	A piece of work is timed with `local started = Perf.start()` and `Perf.stop("Name", started)`;
	each name keeps its count, total and worst time, and how many runs took over a frame's share
	(Perf.SLOW seconds). The admin command `perf` prints them, the bot sweep reports them.
]]

local Perf = {}

-- A run longer than this is a hitch on its own.
Perf.SLOW = 0.016

export type Entry = { Count: number, Total: number, Max: number, Slow: number }

local entries: { [string]: Entry } = {}

function Perf.start(): number
	return os.clock()
end

-- Records the time since `started` under `name`; returns it.
function Perf.stop(name: string, started: number): number
	local took = os.clock() - started
	local entry = entries[name]
	if not entry then
		entry = { Count = 0, Total = 0, Max = 0, Slow = 0 }
		entries[name] = entry
	end
	entry.Count += 1
	entry.Total += took
	if took > entry.Max then
		entry.Max = took
	end
	if took > Perf.SLOW then
		entry.Slow += 1
	end
	return took
end

function Perf.reset()
	table.clear(entries)
end

-- A copy of everything recorded: { [name] = { Count, Total, Max, Slow } } (seconds).
function Perf.snapshot(): { [string]: Entry }
	local copy = {}
	for name, entry in entries do
		copy[name] = table.clone(entry)
	end
	return copy
end

-- The lines the `perf` command and the bot report print: worst first.
function Perf.lines(snapshot: { [string]: Entry }?): { string }
	local data = snapshot or entries
	local names = {}
	for name in data do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		if data[a].Max ~= data[b].Max then
			return data[a].Max > data[b].Max
		end
		return a < b
	end)
	if #names == 0 then
		return { "Nothing timed yet." }
	end
	local lines = {
		string.format("%-26s %8s %9s %9s %9s %6s", "what", "runs", "total ms", "mean ms", "max ms", "slow"),
	}
	for _, name in names do
		local e = data[name]
		table.insert(
			lines,
			string.format(
				"%-26s %8d %9.1f %9.3f %9.2f %6d",
				name,
				e.Count,
				1000 * e.Total,
				1000 * e.Total / math.max(e.Count, 1),
				1000 * e.Max,
				e.Slow
			)
		)
	end
	return lines
end

return Perf
