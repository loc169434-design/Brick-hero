# Clears the tunic-hem sliver left outside the front thigh's outline.
import sys
from PIL import Image
import numpy as np
p = sys.argv[1] + '/parts/front_leg_upper.png'
b = np.array(Image.open(p).convert('RGBA'))
b[378:385, 264:269] = 0
Image.fromarray(b).save(p)
