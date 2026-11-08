"""Lay out generated opaque drawings on the required magenta grid.

This never writes transparent assets. key_out.py alone creates the final alpha.
Original generator outputs are retained in generated/. Fixed per-clip scaling
preserves motion; connected-component bounds prevent the source generator's
uneven cell spacing from cutting off a mace. No per-frame size normalization.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent
KEY = np.array([255, 0, 255], dtype=np.uint8)
CLIPS = {'idle': (8, 12), 'attack': (12, 24), 'hurt': (8, 24),
         'special': (12, 24), 'defeat': (12, 12), 'victory': (8, 12), 'rage': (10, 12)}
ref = np.asarray(Image.open(ROOT / 'ref/orc_chief_frame0.png').convert('RGBA'))
ref_y = np.where(ref[..., 3] >= 128)[0]
TARGET_HEIGHT = int(ref_y.max() - ref_y.min() + 1)
layout = {}
canonical = None
for clip, (count, fps) in CLIPS.items():
    image = np.asarray(Image.open(ROOT / f'generated/orc_chief_{clip}.png').convert('RGB')).copy()
    hh, ww = image.shape[:2]
    rows = (count + 3) // 4
    distance = np.linalg.norm(image.astype(float) - KEY, axis=2)
    labels, _ = ndimage.label(distance > 140)
    sizes = np.bincount(labels.ravel())
    objects = [(label, box) for label, box in enumerate(ndimage.find_objects(labels), 1)
               if box is not None and sizes[label] > 3000]
    objects.sort(key=lambda item: (int(((item[1][0].start + item[1][0].stop) / 2) / (hh / rows)), item[1][1].start))
    assert len(objects) == count, (clip, len(objects), count)
    first_y, first_x = objects[0][1]
    sx = min(400 / (first_x.stop - first_x.start),
             492 / max(box[1].stop - box[1].start for _, box in objects))
    sy = TARGET_HEIGHT / (first_y.stop - first_y.start)
    mask0 = labels == objects[0][0]
    xs = np.where(mask0[first_y.stop - 20:first_y.stop].any(0))[0]
    anchor = float((xs[0] + xs[-1]) / 2)
    sheet = Image.new('RGB', (2048, rows * 512), tuple(KEY))
    info = {'frames': count, 'fps': fps, 'scale_x': sx, 'scale_y': sy,
            'reference_height': TARGET_HEIGHT, 'placement': []}
    for i, (label, box) in enumerate(objects):
        yy, xx = box
        # Retain the antialiased outline, with a magenta moat between drawings.
        # This edits only the opaque source background; no alpha is computed.
        y0, y1 = max(0, yy.start - 3), min(hh, yy.stop + 3)
        x0, x1 = max(0, xx.start - 3), min(ww, xx.stop + 3)
        rgb = image[y0:y1, x0:x1].copy()
        near = ndimage.binary_dilation(labels[y0:y1, x0:x1] == label, iterations=3)
        rgb[~near] = KEY
        rgb[np.linalg.norm(rgb.astype(float) - KEY, axis=2) <= 60] = KEY
        drawing = Image.fromarray(rgb).resize((round((x1-x0)*sx), round((y1-y0)*sy)), Image.Resampling.LANCZOS)
        x = round(256 + (x0 - (i % 4) * (ww/4) - anchor) * sx)
        y = round(500 - (yy.stop - 1 - y0) * sy)
        # Preserve the pose and body scale; move a wide swing only enough to fit.
        x = max(5, min(x, 507 - drawing.width))
        assert drawing.width <= 502 and drawing.height + y <= 512 and y >= 5, (clip, i, drawing.size, x, y)
        cell = Image.new('RGB', (512, 512), tuple(KEY))
        cell.paste(drawing, (x, y))
        if clip == 'idle' and i == 0:
            canonical = cell.copy()
        if i == 0 or (i == count - 1 and clip != 'defeat'):
            cell = canonical.copy()
        sheet.paste(cell, ((i % 4) * 512, (i // 4) * 512))
        info['placement'].append({'frame': i, 'source_bbox': [xx.start, yy.start, xx.stop, yy.stop],
                                   'drawing_xy': [x, y], 'shared_ready': i == 0 or (i == count-1 and clip != 'defeat')})
    sheet.save(ROOT / f'raw/orc_chief_{clip}_key.png', optimize=True)
    layout[clip] = info
(ROOT / 'orc_chief/layout.json').write_text(json.dumps(layout, indent=2) + '\n')
print('7 opaque magenta sheets assembled; final alpha must be made with tools/sprites/key_out.py')
