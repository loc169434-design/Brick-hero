# Finds see-through spots inside the rendered hero: magenta that is enclosed by the figure,
# or a crack narrower than 5 px opening into it.
import sys, glob, json
from PIL import Image
import numpy as np
from scipy import ndimage
D = sys.argv[1]
names = ['Tân binh', 'Đồ da', 'Đồ sắt', 'Hoàng Gia', 'Hắc Thép', 'Băng']
poses = ['idle', 'idle_mid', 'windup', 'cut', 'follow', 'hurt', 'cheer']
report = {}
cells = []
for o in range(6):
    for p in range(7):
        im = np.array(Image.open(f'{D}/o{o}_p{p}.png').convert('RGB')).astype(int)
        r, g, b = im[..., 0], im[..., 1], im[..., 2]
        # magenta or mostly magenta (blended edge)
        bgish = (r > 150) & (b > 150) & (g < 110) & (np.abs(r - b) < 60)
        figure = ~bgish
        closed = ndimage.binary_closing(figure, structure=np.ones((3, 3)), iterations=1)
        filled = ndimage.binary_fill_holes(closed)
        holes = filled & bgish
        lab, n = ndimage.label(holes)
        sizes = ndimage.sum(holes, lab, range(1, n + 1)) if n else []
        spots = []
        for i, s in enumerate(sizes):
            if s >= 4:
                ys, xs = np.nonzero(lab == i + 1)
                spots.append([int(xs.mean()), int(ys.mean()), int(s)])
        report[f'{names[o]}/{poses[p]}'] = spots
        vis = Image.open(f'{D}/o{o}_p{p}.png').convert('RGB')
        v = np.array(vis)
        v[bgish] = [235, 230, 220]
        v[holes] = [0, 220, 255]
        cells.append(Image.fromarray(v.astype(np.uint8)).crop((120, 60, 520, 620)))
w, h = cells[0].size
sheet = Image.new('RGB', (w * 7, h * 6))
for i, c in enumerate(cells):
    sheet.paste(c, ((i % 7) * w, (i // 7) * h))
sheet.save(sys.argv[2])
bad = {k: v for k, v in report.items() if v}
print(json.dumps(bad, ensure_ascii=False))
print('poses with holes:', len(bad), '/', len(report), ' total px:', sum(s[2] for v in bad.values() for s in v))
