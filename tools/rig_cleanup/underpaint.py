# Paints the parts of the torso and pelvis (and their armour) that the arms, shield, head and
# thighs hide at rest, so moving those away shows cloth, not a hole. The fill only lies under
# what covers it at rest, inside the layer's own outline (convex hull), so the rest pose is
# unchanged; colours are inpainted from the layer, and the new edge gets the art's outline.
import sys, glob
from PIL import Image
import numpy as np
import cv2
from scipy import ndimage
D = sys.argv[1]
INK = np.array([43, 17, 6], np.uint8)
def rgba(path):
    return np.array(Image.open(path).convert('RGBA'))
def alpha(names):
    a = np.zeros((512, 512), bool)
    for n in names:
        for f in glob.glob(D + '/' + n):
            a |= rgba(f)[..., 3] >= 128
    return a
# Only what is drawn over the layer (joints.json order) may hide it: the sword's upper arm and
# the back thigh are drawn behind the torso and pelvis.
ARMS = ['parts/sword_arm_lower.png', 'parts/sword_hand.png',
        'parts/shield_arm_upper.png', 'parts/shield_arm_lower.png', 'parts/shield_hand.png',
        'parts/shield.png', 'gear/*/shield_arm_upper.png']
COVERS = {
    'torso': ARMS + ['head/*.png'],
    'pelvis': ARMS + ['parts/torso.png', 'gear/*/torso.png', 'parts/front_leg_upper.png'],
}
def hull(mask):
    pts = np.argwhere(mask)[:, ::-1].astype(np.int32)
    out = np.zeros(mask.shape, np.uint8)
    cv2.fillConvexPoly(out, cv2.convexHull(pts), 1)
    return out.astype(bool)
for part, covers in COVERS.items():
    cover = alpha(covers)
    for f in [D + '/parts/%s.png' % part] + sorted(glob.glob(D + '/gear/*/%s.png' % part)):
        img = rgba(f)
        solid = img[..., 3] >= 200
        if not solid.any():
            continue
        # the layer's own hull, pulled in 3 px so the fill never pokes past its silhouette
        region = ndimage.binary_erosion(hull(solid), iterations=3) & cover & ~solid
        if not region.any():
            continue
        rgb = np.ascontiguousarray(img[..., :3][..., ::-1])
        filled = cv2.inpaint(rgb, region.astype(np.uint8), 6, cv2.INPAINT_TELEA)[..., ::-1]
        img[region, :3] = filled[region]
        img[region, 3] = 255
        # outline the new edge: filled pixels within 2 px of what stays empty
        empty = img[..., 3] < 128
        edge = region & ndimage.binary_dilation(empty, iterations=2)
        img[edge, :3] = INK
        Image.fromarray(img).save(f)
        print(f.replace(D + '/', ''), 'filled', int(region.sum()), 'outlined', int(edge.sum()))
