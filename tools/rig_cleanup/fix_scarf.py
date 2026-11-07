# Outlines the scarf's top edge behind the neck, which the hair used to hide.
import sys
from PIL import Image
import numpy as np
D = sys.argv[1]
X0, X1, Y0, Y1 = 200, 266, 208, 238
parts = {p: np.array(Image.open(D + '/parts/%s.png' % p).convert('RGBA')) for p in ['cape', 'torso']}
union = np.maximum(parts['cape'][..., 3], parts['torso'][..., 3])
ink = parts['cape'][..., :3][(parts['cape'][..., 3] > 240) & (parts['cape'][..., :3].sum(-1) < 160)]
color = np.median(ink, axis=0).astype(np.uint8)
print('outline colour', color)
for p, img in parts.items():
    a = img[..., 3]
    red = (img[..., 0] > 140) & (img[..., 1] < 110) & (a >= 128)
    edit = img.copy()
    n = 0
    for y in range(Y0, Y1):
        for x in range(X0, X1):
            if not red[y, x]:
                continue
            # top edge: open sky within 2 px above (or 2 px up-left) in both layers
            if any(union[y - d, x] < 64 or union[y - d, x - d] < 64 for d in (1, 2, 3)):
                edit[y, x, :3] = color
                edit[y, x, 3] = 255
                n += 1
    Image.fromarray(edit).save(D + '/parts/%s.png' % p)
    print(p, 'outlined', n)
