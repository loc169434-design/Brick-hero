# Re-cuts the sword arm from the hero as he stands, so it moves in one piece.
#
# The delivered art had the sleeve, cuff and upper-arm skin painted on the torso, a crude disc
# for an elbow on the upper arm and a forearm sliced straight down: raised, the arm left its
# sleeve on the body and broke at the elbow. Here the arm's regions (sleeve, cuff, upper-arm
# skin) are cut from the assembled hero, right of where the arm meets the body:
#   sword_arm_upper  sleeve + cuff + skin down to the elbow, now drawn over the torso, with an
#                    elbow painted on where the forearm hides it;
#   sword_arm_lower  the bracer as drawn, what the fist hides repainted in its colours;
#   torso            the body without the arm, but with its shoulder painted on under the
#                    sleeve, so a raised arm shows a shoulder, not a tear beside the neck.
# Armour painted over the sleeve moves from gear/<armour>/torso.png onto the shoulder piece,
# gear/<armour>/sword_arm_upper.png. joints.json gets the elbow where the bracer meets the arm.
# Run it after underpaint.py: the torso stays empty where the arm was below the shoulder, so a
# raised arm leaves the body's outlined edge, not a painted stub.
import sys, glob, json
from PIL import Image
import numpy as np
from scipy import ndimage

D = sys.argv[1]
INK = np.array([43, 17, 6], np.uint8)
ELBOW = (309, 314)                           # x, y: the bend, where the bracer meets the arm


def load(path):
    return np.array(Image.open(D + '/' + path).convert('RGBA'))


def save(path, img):
    Image.fromarray(img).save(D + '/' + path)


meta = json.load(open(D + '/joints.json'))
joints = {k: tuple(v) for k, v in meta['joints'].items()}
order = [p for p in meta['order'] if p != 'sword']
layers = {p: load('head/bare.png' if p == 'head' else 'parts/%s.png' % p) for p in order}

# The hero as he stands (bare).
ref = np.zeros((512, 512, 4), np.float64)
for p in order:
    src = layers[p].astype(np.float64)
    a = src[..., 3:4] / 255
    ref[..., :3] = src[..., :3] * a + ref[..., :3] * (1 - a)
    ref[..., 3:4] = a * 255 + ref[..., 3:4] * (1 - a)
ref = ref.round().astype(np.uint8)
solid = ref[..., 3] >= 128
ink = solid & (ref[..., :3].max(-1) < 75)

old_lower = layers['sword_arm_lower'][..., 3] >= 128
hand = layers['sword_hand'][..., 3] >= 200
# The arm is everything right of where it meets the body (the shared outline), from the
# shoulder down to the elbow; the forearm and fist keep what they cover.
yy, xx = np.mgrid[0:512, 0:512]
boundary = np.where(yy < 300, 297, 299)
arm_zone = (yy >= 250) & (yy <= 343) & (xx >= boundary) & (xx <= 336) & ~((yy < 258) & (xx < 300))
# where the body may not reach: the arm and, under the fist, anything underpaint.py spread there
clear_zone = arm_zone | ((yy >= 250) & (yy <= 343) & (xx > 336) & (xx <= 360))
# the old upper arm also held the scarf's end and its outline by the shoulder: the body's
scarf = (layers['sword_arm_upper'][..., 3] >= 128) & ~arm_zone
upper_mask = arm_zone & solid & ~old_lower & ~hand
lower_mask = old_lower


def hull(mask):
    import cv2
    pts = np.argwhere(mask)[:, ::-1].astype(np.int32)
    out = np.zeros(mask.shape, np.uint8)
    cv2.fillConvexPoly(out, cv2.convexHull(pts), 1)
    return out.astype(bool)


def disc(centre, radius):
    return (xx - centre[0]) ** 2 + (yy - centre[1]) ** 2 <= radius ** 2


def fill_from(img, area, source):
    # paints `area` with the colour of the nearest `source` pixel
    _, (iy, ix) = ndimage.distance_transform_edt(~source, return_indices=True)
    img[area, :3] = img[iy[area], ix[area], :3]
    img[area, 3] = 255


def outline(img, area, px=2):
    # inks the pixels of `area` within px of nothing
    edge = area & ndimage.binary_dilation(img[..., 3] < 128, iterations=px)
    img[edge, :3] = INK


# The shoulder under the sleeve: the body's, painted on (the sleeve hides it at rest).
SHOULDER = upper_mask & (yy < 298) & (xx <= 314)


def without_arm(img, zone=None):
    # clears the arm (`zone`) from a body layer, paints its shoulder under the sleeve, and
    # outlines the edge left where the arm was
    zone = clear_zone if zone is None else zone
    had = img[..., 3] >= 128
    img[zone] = 0
    body = (img[..., 3] >= 128) & ~ink
    near = ndimage.binary_dilation(img[..., 3] >= 128, iterations=6)
    shoulder = SHOULDER & near
    if shoulder.any():
        fill_from(img, shoulder, body)
    open_ = img[..., 3] < 128
    rim = (img[..., 3] >= 128) & ndimage.binary_dilation(open_ & zone, iterations=2)
    img[rim, :3] = INK
    return int((had & zone).sum())


# The torso without the arm, also under the forearm.
torso = layers['torso'].copy()
taken = without_arm(torso)
torso[scarf] = ref[scarf]

# The upper arm, now over the torso. Where the forearm or fist hides it (the elbow) it's
# painted on in its own colours, so bending shows arm, not a gap.
upper = np.zeros((512, 512, 4), np.uint8)
upper[upper_mask] = ref[upper_mask]
upper[upper_mask, 3] = 255
hidden = lower_mask | hand
shape = hull(upper_mask | disc(ELBOW, 12))
# rounded, so a bent elbow shows a curve, not the hull's corner
round_ = (np.mgrid[-6:7, -6:7] ** 2).sum(0) <= 36
shape = ndimage.binary_erosion(ndimage.binary_opening(shape, structure=round_), iterations=1)
caps = shape & hidden & ~upper_mask
fill_from(upper, caps, upper_mask & ~ink & (xx >= 302))
outline(upper, caps)

# The forearm, in front: as drawn, but what the fist hides repainted from the bracer.
lower = layers['sword_arm_lower'].copy()
lower[old_lower & hand] = 0
seen = old_lower & ~hand
wcap = disc(joints['wrist_sword'], 11) & hand & ~seen
fill_from(lower, wcap, seen & ~ink)
outline(lower, wcap)

save('parts/torso.png', torso)
save('parts/sword_arm_upper.png', upper)
save('parts/sword_arm_lower.png', lower)
print('upper', int(upper_mask.sum()), '+hidden', int(caps.sum()), '| lower +cap', int(wcap.sum()), '| torso gave up', taken)

# Armour painted over the sleeve rides the shoulder piece now; what it painted under the
# forearm goes.
for f in sorted(glob.glob(D + '/gear/*/torso.png')):
    item = f.split('/')[-2]
    armour = np.array(Image.open(f).convert('RGBA'))
    move = upper_mask & (armour[..., 3] > 0)
    pad_path = D + '/gear/%s/sword_arm_upper.png' % item
    pad = np.array(Image.open(pad_path).convert('RGBA'))
    under = np.zeros_like(armour)
    under[move] = armour[move]
    merged = Image.fromarray(under)
    merged.alpha_composite(Image.fromarray(pad))
    merged.save(pad_path)
    # armour reaching past the bare body (a flank below the elbow) stays where it shows
    without_arm(armour, clear_zone & (upper_mask | lower_mask | hand | (xx > 336)))
    Image.fromarray(armour).save(f)
    print(item, 'moved', int(move.sum()))

meta['joints']['elbow_sword'] = list(ELBOW)
# the upper arm (and its armour) now lies over the body, under the head
meta['order'].remove('sword_arm_upper')
meta['order'].insert(meta['order'].index('torso') + 1, 'sword_arm_upper')
open(D + '/joints.json', 'w').write(json.dumps(meta, indent=2) + '\n')
