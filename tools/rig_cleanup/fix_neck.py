# Keeps the neck whole when the head or the cape moves.
# - The scarf wrapped round the front of the neck was on the cape layer, which swings on its own
#   bone: a fluttering cape tore it open under the chin. It moves to the torso (as it looked at
#   rest, under whatever the torso already drew there); only the cape's flowing part swings.
# - A stump of neck is painted on the torso under the chin, where the head hides it at rest,
#   for a head tipped back. Skin coloured from the bare head's neck, outlined where it meets
#   nothing.
import sys, glob
from PIL import Image
import numpy as np
from scipy import ndimage

D = sys.argv[1]
INK = np.array([43, 17, 6], np.uint8)
yy, xx = np.mgrid[0:512, 0:512]
heads = np.zeros((512, 512), bool)
for f in glob.glob(D + '/head/*.png'):
    heads |= np.array(Image.open(f).convert('RGBA'))[..., 3] >= 200
bare = np.array(Image.open(D + '/head/bare.png').convert('RGBA'))
box = bare[236:250, 250:276].reshape(-1, 4)
skin = box[(box[:, 3] > 200) & (box[:, 0] > 230) & (box[:, 1] > 160)][:, :3]
colour = np.median(skin, axis=0).astype(np.uint8)
path = D + '/parts/torso.png'
torso = np.array(Image.open(path).convert('RGBA'))
cape_img = np.array(Image.open(D + '/parts/cape.png').convert('RGBA'))
wrap = (cape_img[..., 3] > 0) & (xx >= 252) & (yy <= 266)
under = wrap & (torso[..., 3] < 255)
merged = Image.fromarray(np.where(wrap[..., None], cape_img, 0).astype(np.uint8))
merged.alpha_composite(Image.fromarray(torso))
torso = np.array(merged)
cape_img[wrap] = 0
Image.fromarray(cape_img).save(D + '/parts/cape.png')
print('scarf moved from cape to torso', int(wrap.sum()))
cape = cape_img[..., 3] >= 128
stump = ((xx - 268) ** 2 + (yy - 246) ** 2 <= 24 ** 2) & (yy >= 230) & heads & (torso[..., 3] < 128) & ~cape
torso[stump, :3] = colour
torso[stump, 3] = 255
edge = stump & ndimage.binary_dilation(torso[..., 3] < 128, iterations=2)
torso[edge, :3] = INK
Image.fromarray(torso).save(path)
print('neck stump', int(stump.sum()), 'skin', colour)
