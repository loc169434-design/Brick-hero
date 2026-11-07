# Lines bare-head nape hair under each helmet head where its back flap left a pocket.
import sys
from PIL import Image
import numpy as np
D = sys.argv[1]
bare = np.array(Image.open(D + '/head/bare.png').convert('RGBA'))
for k in ['leather_helmet', 'iron_helmet']:
    path = D + '/head/%s.png' % k
    h = Image.open(path).convert('RGBA')
    a = np.array(h)[..., 3]
    under = np.zeros_like(bare)
    x0 = None
    for y in range(200, 236):
        row = np.nonzero(a[y, 190:262] >= 128)[0]
        if y <= 226 and row.size:
            x0 = 190 + row[0] if x0 is None else max(x0, 190 + row[0]) if y > 222 else 190 + row[0]
        if x0 is None:
            continue
        under[y, x0:262] = bare[y, x0:262]
    out = Image.fromarray(under)
    out.alpha_composite(h)
    out.save(path)
    print(k, 'filled', int(((np.array(out)[...,3] >= 240) & (a < 240)).sum()))
