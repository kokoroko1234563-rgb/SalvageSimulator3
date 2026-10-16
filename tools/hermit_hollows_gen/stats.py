import sys
from build import *
import specs

only = sys.argv[1:]
for sp in specs.SPECS:
    if only and sp['name'] not in only and str(specs.SPECS.index(sp) + 1) not in only:
        continue
    try:
        r = build(sp)
        print(sp['name'], 'cart', len(r['cart']), 'foot', len(r['foot']), 'rubble', len(r['rubble']))
        if only:
            show(r)
    except Exception as ex:
        print(sp['name'], 'ERR', ex)
