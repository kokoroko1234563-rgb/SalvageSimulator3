"""python3 try.py zone5 [crossing numbers]: build the crossings, print lengths (and maps)."""
import sys, importlib

z = importlib.import_module(sys.argv[1])
w = z.warren()
for i, sp in enumerate(z.SPECS):
    if len(sys.argv) > 2 and str(i + 1) not in sys.argv[2:]:
        continue
    try:
        r = w.build(sp)
        print(sp['name'], 'cart', len(r['cart']), 'foot', len(r['foot']), 'rubble', len(r['rubble']))
        if len(sys.argv) > 2:
            w.show(r)
    except Exception as ex:
        print(sp['name'], 'ERR', ex)
