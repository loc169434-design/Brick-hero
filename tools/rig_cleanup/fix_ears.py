# Runs each helmet's cheek flap right up to the ear outline: paints over the bare head's
# leftover skin (leather) and hair strip (iron) between them.
import sys
from PIL import Image
import numpy as np
import re
D = sys.argv[1]
def kind(p):
    r, g, b = int(p[0]), int(p[1]), int(p[2])
    if max(r, g, b) < 85: return 'O'
    if r > 215 and g > 150: return 's'
    if abs(r - g) < 25 and abs(g - b) < 25: return 'g'
    return 'h'
# leather: skin crescent above the ear, rows 184-187
path = D + '/head/leather_helmet.png'
h = np.array(Image.open(path).convert('RGBA'))
fill = h[186, 214].copy()
n = 0
for y in range(184, 188):
    for x in range(219, 240):
        if kind(h[y, x]) != 'O' or (y == 186 and 228 <= x <= 232):
            h[y, x] = fill; n += 1
for x in (220, 221, 222, 237, 238):
    h[188, x] = fill; n += 1
Image.fromarray(h).save(path); print('leather painted', n, fill)
# iron: brown hair strip between the grey flap and the ear outline turns flap grey
path = D + '/head/iron_helmet.png'
h = np.array(Image.open(path).convert('RGBA'))
n = 0
for y in range(186, 217):
    grey = None
    for x in range(204, 227):
        r, g, b, a = (int(v) for v in h[y, x])
        if a < 128:
            continue
        if max(r, g, b) < 60 and grey is not None and x > 214:
            break  # the ear's outline: the ear itself starts here
        if abs(r - g) < 25 and abs(g - b) < 25 and r > 120:
            grey = h[y, x].copy()
        elif grey is not None and r >= 90 and r - b > 50 and r < 200:
            h[y, x] = grey; n += 1
Image.fromarray(h).save(path); print('iron painted', n)
