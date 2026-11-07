# Writes the "sword" track of a clip (CharacterRig) by comparing its sheet with the sword drawn
# in against the same sheet with the sword painted out: what differs is the sword.
#
#   python3 tools/sword_track.py <with_sword.png> <without_sword.png> <frames> [columns=4] [cell=512]
#
# Prints a JSON list, one entry per frame: [x, y, degrees, front] or null.
# - x, y: the grip, middle of the handle, in the frame's canvas pixels. The fist hides the
#   handle, so it's the middle of the widest gap along the sword between guard and pommel;
#   with no gap, a fifth of the way up from the pommel end.
# - degrees: the blade's turn from straight up, clockwise.
# - front: 1 if the sword lay over the body (much of it covered pixels that are opaque without
#   it), 0 if behind or clear of it.
# A frame where under MIN_PIXELS differ has no sword (null).
import sys, json
from PIL import Image
import numpy as np
from scipy import ndimage

MIN_PIXELS = 150


def frames(path, count, columns, cell):
    sheet = np.array(Image.open(path).convert('RGBA')).astype(int)
    for i in range(count):
        x, y = (i % columns) * cell, (i // columns) * cell
        yield sheet[y:y + cell, x:x + cell]


def key(old, new):
    diff = (np.abs(old - new)[..., :3].max(-1) > 40) & (old[..., 3] >= 128)
    diff = ndimage.binary_opening(diff, iterations=1)
    lab, n = ndimage.label(diff)
    if n == 0:
        return None
    sizes = ndimage.sum(diff, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= 25])
    if keep.sum() < MIN_PIXELS:
        return None
    ys, xs = np.nonzero(keep)
    pts = np.stack([xs, ys], 1).astype(float)
    centre = pts.mean(0)
    _, vecs = np.linalg.eigh(np.cov((pts - centre).T))
    axis = vecs[:, 1]
    t = (pts - centre) @ axis
    # the guard is the widest cross-piece; the blade is its longer side: point the axis there
    lo, hi = t.min(), t.max()
    u = (pts - centre) @ np.array([-axis[1], axis[0]])
    slots = np.round(t - lo).astype(int)
    widths = np.zeros(slots.max() + 1)
    for k in range(len(widths)):
        here = u[slots == k]
        widths[k] = here.max() - here.min() if here.size else 0
    guard_t = lo + float(np.argmax(ndimage.uniform_filter1d(widths, 5)))
    if hi - guard_t < guard_t - lo:
        axis, t, lo, hi = -axis, -t, -hi, -lo
    # the fist: the widest empty stretch along the axis, in the lower half (handle side)
    bins = np.zeros(int(hi - lo) + 1, bool)
    bins[(t - lo).astype(int)] = True
    best, run, start = (0, 0), 0, 0
    for i, filled in enumerate(bins[: len(bins) // 2 + 1]):
        if not filled:
            run += 1
            if run > best[0]:
                best = (run, i - run + 1)
        else:
            run = 0
    if best[0] >= 6:
        grip_t = lo + best[1] + best[0] / 2
    else:
        grip_t = lo + (hi - lo) / 5
    grip = centre + axis * grip_t
    degrees = float(np.degrees(np.arctan2(axis[0], -axis[1])))
    over_body = (keep & (new[..., 3] >= 200)).sum() / keep.sum()
    return [round(float(grip[0]), 1), round(float(grip[1]), 1), round(degrees, 1), 1 if over_body > 0.15 else 0]


def main():
    with_sword, without, count = sys.argv[1], sys.argv[2], int(sys.argv[3])
    columns = int(sys.argv[4]) if len(sys.argv) > 4 else 4
    cell = int(sys.argv[5]) if len(sys.argv) > 5 else 512
    track = [key(a, b) for a, b in zip(frames(with_sword, count, columns, cell), frames(without, count, columns, cell))]
    print(json.dumps(track))


if __name__ == '__main__':
    main()
