"""Shared crop/registration/atlas/review helpers. Never paint or recolor artwork."""
from pathlib import Path
import hashlib
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def bounds(mask):
    y, x = np.where(mask)
    assert len(x), 'empty drawing'
    return [int(x.min()), int(y.min()), int(x.max()) + 1, int(y.max()) + 1]


def components(image, threshold=32):
    labels, _ = ndimage.label(np.asarray(image)[:, :, 3] > threshold, np.ones((3, 3)))
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    return labels, sizes


def cells(entry, columns, rows, count):
    source = Image.open(entry['path']).convert('RGBA')
    alpha = np.asarray(source)[:, :, 3]
    assert int(alpha.min()) == 0, 'source needs true transparent background'
    def cuts(projection, n):
        result = [0]
        step = len(projection) / n
        for i in range(1, n):
            l, r = round((i - .3) * step), round((i + .3) * step)
            region = projection[l:r]
            minimum = region.min()
            candidates = np.flatnonzero(region == minimum)
            target = i * step - l
            result.append(int(l + candidates[np.argmin(abs(candidates - target))]))
        return result + [len(projection)]
    xs = cuts((alpha > 32).sum(axis=0), columns)
    ys = cuts((alpha > 32).sum(axis=1), rows)
    boxes = [[xs[x], ys[y], xs[x+1], ys[y+1]] for y in range(rows) for x in range(columns)][:count]
    entry.update({'sha256': hashlib.sha256(Path(entry['path']).read_bytes()).hexdigest(),
                  'grid': [columns, rows], 'crop_boxes': boxes})
    return [source.crop(b) for b in boxes]


def actor_frames(raw, reference):
    """One uniform sheet scale; register full drawn cels by feet, not moving props."""
    ref = Image.open(reference).convert('RGBA')
    ref_box = bounds(np.asarray(ref)[:, :, 3] > 32)
    bodies = []
    boxes = []
    feet = []
    for im in raw:
        labels, sizes = components(im)
        body = labels == sizes.argmax()
        box = bounds(body)
        boxes.append(box)
        ys, xs = np.where(body & (np.indices(body.shape)[0] >= box[3] - 5))
        feet.append((float(np.median(xs)), box[3]))
        bodies.append(body)
    neutral = boxes[0]
    scale = (ref_box[3] - ref_box[1]) / (neutral[3] - neutral[1])
    for im, (fx, fy) in zip(raw, feet):
        l, t, r, b = bounds(np.asarray(im)[:, :, 3] > 32)
        scale = min(scale, 484 / (fy - t), 242 / max(fx-l, r-fx))
    result = []
    registration = []
    for im, (fx, fy) in zip(raw, feet):
        # Crop a whole rectangle containing all its alpha before positioning.
        l, t, r, b = bounds(np.asarray(im)[:, :, 3] > 32)
        l, t, r, b = max(0, l-2), max(0, t-2), min(im.width, r+2), min(im.height, b+2)
        drawn = im.crop((l, t, r, b))
        drawn = drawn.resize((round(drawn.width*scale), round(drawn.height*scale)), Image.Resampling.LANCZOS)
        at = (round(256-(fx-l)*scale), round(500-(fy-t)*scale))
        canvas = Image.new('RGBA', (512,512))
        canvas.alpha_composite(drawn, at)
        result.append(canvas)
        registration.append({'whole_crop':[l,t,r,b], 'feet_in_source':[fx,fy], 'scale':scale, 'offset':list(at)})
    return result, registration


def fx_frames(raw, size=(512,512), fill=.8):
    # The same scale for the whole clip avoids per-frame pulsing from packing.
    boxes = [bounds(np.asarray(im)[:,:,3] > 32) for im in raw]
    maximum = max(max((b[2]-b[0])/size[0], (b[3]-b[1])/size[1]) for b in boxes)
    scale = fill/maximum
    result=[]
    for im, b in zip(raw, boxes):
        im=im.crop(b)
        im=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',size)
        canvas.alpha_composite(im,((size[0]-im.width)//2,(size[1]-im.height)//2))
        result.append(canvas)
    return result


def atlas(frames, columns=4):
    w,h=frames[0].size
    result=Image.new('RGBA',(w*columns,h*math.ceil(len(frames)/columns)))
    for i,im in enumerate(frames):result.alpha_composite(im,(i%columns*w,i//columns*h))
    return result


def save_png(path, image):
    path.parent.mkdir(parents=True,exist_ok=True)
    image.save(path,optimize=True)


def jpg(path, image):
    path.parent.mkdir(parents=True,exist_ok=True)
    image.convert('RGB').save(path,quality=87,optimize=True)
    assert path.stat().st_size<2_000_000, str(path)


def gif(path, frames, fps):
    path.parent.mkdir(parents=True,exist_ok=True)
    palette=frames[0].convert('RGB').quantize(colors=144)
    converted=[im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
    timing=[round((i+1)*100/fps)*10-round(i*100/fps)*10 for i in range(len(frames))]
    converted[0].save(path,save_all=True,append_images=converted[1:],duration=timing,loop=0,optimize=True,disposal=2)
    assert path.stat().st_size<2_000_000, str(path)


def preview_frames(frames, label, size=(320,350)):
    result=[]
    for f,im in enumerate(frames):
        canvas=Image.new('RGBA',size,'#27343a')
        display=im.copy();display.thumbnail((size[0],size[1]-32),Image.Resampling.LANCZOS)
        canvas.alpha_composite(display,((size[0]-display.width)//2,32+(size[1]-32-display.height)//2))
        ImageDraw.Draw(canvas).text((8,7),label+' '+str(f),font=ImageFont.truetype(FONT,15),fill='#f6e8bf')
        result.append(canvas)
    return result
