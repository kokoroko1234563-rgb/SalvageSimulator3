import os, sys, subprocess
here = os.path.dirname(os.path.abspath(__file__))
out = '/home/user/SalvageSimulator3/.claude/worktrees/agent-a98b2fc872c8f0694/src/shared/Layouts/Biomes/HermitHollows.luau'


def rd(name):
    return open(os.path.join(here, name)).read()


ncross = int(sys.argv[1]) if len(sys.argv) > 1 else 5
parts = [rd('head.luau.txt'), '\n']
data = rd('data.lua')
# keep only the first ncross crossings
start = data.index('local CROSSINGS = {')
fr = data[:start]
cr = data[start:]
items = cr.split('\n\t{\n')
head = items[0]
body = ['\n\t{\n' + it for it in items[1:]]
body = body[:ncross]
cr = head + ''.join(body)
if not cr.rstrip().endswith('}'):
    pass
cr = cr.rstrip()
# strip a trailing closing brace of the table from the last item if present
if cr.endswith('\n}'):
    cr = cr[:-2]
cr = cr.rstrip() + '\n}\n'
parts += [fr, cr]
parts.append(rd('zone4.luau.txt'))
if os.path.exists(os.path.join(here, 'slots.luau')) and '--noslots' not in sys.argv:
    parts.append(rd('slots.luau'))
parts.append('\n' + rd('zones56.luau.txt'))
parts.append('\nreturn {\n\t[4] = zone4,\n\t[5] = Tiled(zone5),\n\t[6] = Tiled(zone6),\n}\n')
open(out, 'w').write(''.join(parts))
print('written', out)
