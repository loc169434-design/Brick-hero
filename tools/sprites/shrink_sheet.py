# Shrinks a clip sheet drawn at 512 px frames to lighter frames (384 by default), keeping the
# grid: every frame is still the whole 512 canvas, stored smaller (CharacterRig scales it back).
# Resizes with premultiplied alpha, so edges don't pick up a dark fringe, and clears the
# near-invisible haze (alpha under 16) AI art leaves round a figure.
#
#   python3 tools/sprites/shrink_sheet.py <in.png> <out.png> [--cell 512] [--to 384]
#
# Then set "frame_size": [384, 384] in the clip set's anim.json.
import argparse
from PIL import Image
import numpy as np

p = argparse.ArgumentParser()
p.add_argument("src")
p.add_argument("dst")
p.add_argument("--cell", type=int, default=512)
p.add_argument("--to", type=int, default=384)
a = p.parse_args()

raw = np.array(Image.open(a.src).convert("RGBA"))
# the near-invisible haze AI art leaves round a figure (alpha under 16) goes
raw[raw[..., 3] < 16] = 0
img = raw.astype(np.float64) / 255.0
assert img.shape[0] % a.cell == 0 and img.shape[1] % a.cell == 0, "not a grid of %d px frames" % a.cell
premul = img.copy()
premul[..., :3] *= premul[..., 3:4]
size = (img.shape[1] * a.to // a.cell, img.shape[0] * a.to // a.cell)
channels = [Image.fromarray((premul[..., c] * 65535).astype(np.uint16).astype(np.int32)).resize(size, Image.LANCZOS) for c in range(4)]
small = np.stack([np.clip(np.array(ch, dtype=np.float64) / 65535.0, 0, 1) for ch in channels], -1)
alpha = small[..., 3:4]
small[..., :3] = np.where(alpha > 1e-4, small[..., :3] / np.maximum(alpha, 1e-4), 0)
Image.fromarray((np.clip(small, 0, 1) * 255 + 0.5).astype(np.uint8)).save(a.dst, optimize=True)
print("%s: %dx%d -> %dx%d" % (a.dst, img.shape[1], img.shape[0], size[0], size[1]))
