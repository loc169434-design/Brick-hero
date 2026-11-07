# Checks a clip sheet against the art contract (CharacterRig) and makes previews to look at.
#
#   python3 tools/sprites/check_sheet.py <sheet.png> --frames N [--columns 4] [--cell 512]
#       [--fps 24] [--ref assets/characters/hero_rookie/anim/fresh_idle.png] [--out DIR]
#       [--airborne]
#
# The sheet is a grid of `columns` frames of `cell` pixels, each the 512 canvas with the feet at
# (256, 500). Checks, scaled to the cell:
#   grid      the sheet is exactly the grid for N frames, no frame empty
#   feet      the first and last frames stand on the ground: lowest solid row within 6 px of
#             y 500, its middle within 40 px of x 256 (--airborne skips the last frame, for
#             clips that end in the air)
#   size      the body in frame 0 is as tall as in the reference's frame 0, within 8%
#   clean     at most 400 visible stray pixels (alpha 16-63 off the body) in any frame, at most
#             one speck (under 20 px) a frame on average. Effects are drawn by the game, so a
#             swoosh painted into a frame counts against it too; the
#             near-invisible haze (alpha 1-15) AI art leaves round a figure is only counted,
#             shrink_sheet.py clears it
#   inside    nothing cut by the frame's edge
# Writes <out>/<name>_report.json, <name>_frames.png (numbered, feet line drawn) and
# <name>.gif (the clip at its speed). Exit code 0 when every check passes.
import sys, json, argparse, os
from PIL import Image, ImageDraw
import numpy as np
from scipy import ndimage

p = argparse.ArgumentParser()
p.add_argument("sheet")
p.add_argument("--frames", type=int, required=True)
p.add_argument("--columns", type=int, default=4)
p.add_argument("--cell", type=int, default=512)
p.add_argument("--fps", type=float, default=24)
p.add_argument("--ref", default="assets/characters/hero_rookie/anim/fresh_idle.png")
p.add_argument("--ref-cell", type=int, default=512)
p.add_argument("--out", default=None)
p.add_argument("--airborne", action="store_true")
a = p.parse_args()

k = a.cell / 512.0
sheet = np.array(Image.open(a.sheet).convert("RGBA"))
name = os.path.splitext(os.path.basename(a.sheet))[0]
out = a.out or os.path.dirname(os.path.abspath(a.sheet))
os.makedirs(out, exist_ok=True)
rows = -(-a.frames // a.columns)
report = {"sheet": a.sheet, "frames": a.frames, "cell": a.cell, "checks": {}, "per_frame": []}
fails = []


def check(key, ok, detail):
    report["checks"][key] = {"pass": bool(ok), "detail": detail}
    if not ok:
        fails.append(key)


want = (a.columns * a.cell, rows * a.cell)
have = (sheet.shape[1], sheet.shape[0])
check("grid", have == want, "sheet %dx%d, grid for %d frames is %dx%d" % (have + (a.frames,) + want))


def frame(img, i, cell, columns):
    x, y = (i % columns) * cell, (i // columns) * cell
    return img[y:y + cell, x:x + cell]


def body_height(f):
    rows_ = np.nonzero((f[..., 3] >= 128).sum(1) > 0)[0]
    return (rows_[-1] - rows_[0] + 1) if rows_.size else 0


def feet(f):
    solid = f[..., 3] >= 128
    rows_ = np.nonzero(solid.sum(1) >= max(3, int(8 * k)))[0]
    if not rows_.size:
        return None
    y = rows_[-1]
    xs = np.nonzero(solid[max(0, y - int(20 * k)):y + 1].any(0))[0]
    return float(y), float((xs[0] + xs[-1]) / 2)


frames = [frame(sheet, i, a.cell, a.columns) for i in range(a.frames)] if have == want else []
empty, strays, specks, cut = [], 0, 0, []
for i, f in enumerate(frames):
    alpha = f[..., 3]
    solid = alpha >= 200
    info = {"frame": i}
    if (alpha >= 128).sum() < 200:
        empty.append(i)
    off_body = ~ndimage.binary_dilation(solid, iterations=2)
    stray = (alpha >= 16) & (alpha < 64) & off_body
    info["haze"] = int(((alpha > 0) & (alpha < 16) & off_body).sum())
    lab, n = ndimage.label(alpha >= 64)
    sizes = ndimage.sum(alpha >= 64, lab, range(1, n + 1)) if n else []
    small = sum(1 for s_ in sizes if s_ < 20 * k * k)
    edge = np.concatenate([alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1]])
    info.update({"feet": feet(f), "height": int(body_height(f)), "stray": int(stray.sum()), "specks": small, "edge": int((edge >= 128).sum())})
    strays += int(stray.sum())
    specks += small
    if info["edge"] > 0:
        cut.append(i)
    report["per_frame"].append(info)

if frames:
    check("grid", not empty and have == want, "sheet %dx%d ok; empty frames: %s" % (have + (empty,)))
    ends = [0] if a.airborne else [0, a.frames - 1]
    bad = []
    for i in ends:
        ft = report["per_frame"][i]["feet"]
        if ft is None or abs(ft[0] - 500 * k) > 6 * k or abs(ft[1] - 256 * k) > 40 * k:
            bad.append((i, ft))
    check("feet", not bad, "first/last frame feet (y, x) vs (%.0f, %.0f): %s" % (500 * k, 256 * k, bad or "ok"))
    try:
        ref = np.array(Image.open(a.ref).convert("RGBA"))
        ref_h = body_height(frame(ref, 0, a.ref_cell, ref.shape[1] // a.ref_cell)) * (a.cell / a.ref_cell)
        h = report["per_frame"][0]["height"]
        check("size", ref_h and abs(h - ref_h) / ref_h <= 0.08, "frame 0 body %d px tall, reference %.0f" % (h, ref_h))
    except FileNotFoundError:
        check("size", True, "no reference to compare")
    haze = sum(f_["haze"] for f_ in report["per_frame"])
    worst = max(f_["stray"] for f_ in report["per_frame"])
    check("clean", worst <= 400 and specks <= a.frames, "worst frame %d stray pixels, %d specks in %d frames (and %d haze pixels, cleared on shrinking)" % (worst, specks, a.frames, haze))
    check("inside", not cut, "frames touching the edge: %s" % (cut or "none"))

# previews: numbered frames over a checkerboard with the ground line, and the clip as a GIF
if frames:
    tile = 192
    board = Image.new("RGBA", (tile, tile), (225, 225, 225, 255))
    d = ImageDraw.Draw(board)
    for yy in range(0, tile, 16):
        for xx in range(0, tile, 16):
            if (xx // 16 + yy // 16) % 2:
                d.rectangle((xx, yy, xx + 15, yy + 15), fill=(200, 200, 200, 255))
    cells = []
    for i, f in enumerate(frames):
        c = board.copy()
        c.alpha_composite(Image.fromarray(f).resize((tile, tile), Image.LANCZOS))
        dc = ImageDraw.Draw(c)
        gy = 500 * tile / 512
        dc.line((0, gy, tile, gy), fill=(220, 40, 40, 255), width=1)
        dc.text((4, 4), str(i), fill=(0, 0, 0, 255))
        cells.append(c)
    grid = Image.new("RGBA", (a.columns * tile, rows * tile), (255, 255, 255, 255))
    for i, c in enumerate(cells):
        grid.paste(c, ((i % a.columns) * tile, (i // a.columns) * tile))
    grid.save(os.path.join(out, name + "_frames.png"))
    cells[0].convert("RGB").save(os.path.join(out, name + ".gif"), save_all=True,
        append_images=[c.convert("RGB") for c in cells[1:]], duration=int(1000 / a.fps), loop=0)

report["pass"] = not fails
json.dump(report, open(os.path.join(out, name + "_report.json"), "w"), indent=1)
for key, v in report["checks"].items():
    print("%-7s %s  %s" % (key, "ĐẠT" if v["pass"] else "TRƯỢT", v["detail"]))
print("=> %s" % ("ĐẠT" if not fails else "TRƯỢT: " + ", ".join(fails)))
sys.exit(0 if not fails else 1)
