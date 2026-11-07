# Clears faint stray pixels (alpha < 64, not touching a solid pixel) from rig layers.
import sys, glob
from PIL import Image
import numpy as np
from scipy import ndimage
D = sys.argv[1]
for f in sorted(glob.glob(D + '/parts/*.png') + glob.glob(D + '/gear/*/*.png') + glob.glob(D + '/head/*.png')):
    img = np.array(Image.open(f).convert('RGBA'))
    a = img[..., 3]
    stray = (a > 0) & (a < 64) & ~ndimage.binary_dilation(a >= 200)
    if stray.any():
        img[stray] = 0
        Image.fromarray(img).save(f)
