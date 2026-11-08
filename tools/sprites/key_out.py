# Keys the background out of a sheet drawn on a flat key colour (green #00ff00 by default,
# magenta #ff00ff for green-skinned characters): every pixel of that colour goes, wherever it is
# (the gaps the outline encloses included), edges fade with the distance to the key, the key
# colour the edges picked up is taken back out (only near the edge, so the character's own
# colours stay), and specks under 20 px are dropped.
#
#   python3 tools/sprites/key_out.py <drawn_on_key.png> <out.png> [--key 00ff00] [--soft 60 140]
#
# --soft LOW HIGH: colour distance (0-441) under LOW is background, over HIGH is solid, between
# fades. Only for characters who wear none of the key colour.
import argparse
from PIL import Image
import numpy as np
from scipy import ndimage

p = argparse.ArgumentParser()
p.add_argument("src")
p.add_argument("dst")
p.add_argument("--key", default="00ff00")
p.add_argument("--soft", type=float, nargs=2, default=(60.0, 140.0))
a = p.parse_args()

img = np.array(Image.open(a.src).convert("RGBA")).astype(np.float64)
rgb = img[..., :3]
key = np.array([int(a.key[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)
dist = np.sqrt(((rgb - key) ** 2).sum(-1))
low, high = a.soft
alpha = np.clip((dist - low) / (high - low), 0, 1) * (img[..., 3] / 255.0)

# take the key's spill out near the edge: the key's strong channels (green; red and blue for
# magenta) pulled down to the strongest of its weak ones
strong = [c for c in range(3) if key[c] >= 128]
weak = [c for c in range(3) if key[c] < 128]
edge = ndimage.binary_dilation(alpha < 0.98, iterations=3)
spill = np.clip(rgb[..., strong].min(-1) - rgb[..., weak].max(-1), 0, None) * edge
for c in strong:
    rgb[..., c] -= spill

# drop specks
solid = alpha >= 0.25
lab, n = ndimage.label(solid)
if n:
    sizes = ndimage.sum(solid, lab, range(1, n + 1))
    small = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s < 20])
    alpha[small] = 0
    # and the faint pixels hanging off them
    alpha[(alpha < 0.25) & ~ndimage.binary_dilation(alpha >= 0.25, iterations=2)] = 0

out = np.dstack([rgb, alpha * 255.0])
out[alpha <= 0] = 0
Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8)).save(a.dst, optimize=True)
print("%s: %d px kept of %d" % (a.dst, int((alpha > 0).sum()), alpha.size))
