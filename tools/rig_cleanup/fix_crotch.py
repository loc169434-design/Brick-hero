# Clears the speckled crotch between the thighs on the pelvis layer and closes it with one outline.
import sys
from PIL import Image
import numpy as np
D = sys.argv[1]
load = lambda p: np.array(Image.open(D + '/parts/%s.png' % p).convert('RGBA'))
pelvis, back, front = load('pelvis'), load('back_leg_upper'), load('front_leg_upper')
ink = np.array([43, 17, 6, 255], np.uint8)
TOP = 385
n = 0
for y in range(TOP, 406):
    b = np.nonzero(back[y, 200:300, 3] >= 128)[0]
    f = np.nonzero(front[y, 200:300, 3] >= 128)[0]
    if not b.size or not f.size:
        continue
    left = 200 + b[-1] + 1
    right = 200 + f[f + 200 > left][0] if (f + 200 > left).any() else None
    if right is None or right <= left:
        continue
    for x in range(left - 1, right + 1):
        if y <= TOP + 1:
            pelvis[y, x] = ink  # the crotch seam, 2 px
        else:
            pelvis[y, x] = 0
        n += 1
Image.fromarray(pelvis).save(D + '/parts/pelvis.png')
print('crotch px', n)
