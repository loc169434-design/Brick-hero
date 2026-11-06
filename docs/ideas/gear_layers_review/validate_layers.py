"""Check the deliverable, including missing layers. This is an art helper, not game code."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
LAYERS = ROOT / "assets/characters/hero_rookie/anim/layers"
HERE = Path(__file__).resolve().parent


def validate():
    errors, missing, checked = [], [], []
    gear = ["wood_sword", "iron_sword", "tempered_sword", "leather_armor", "iron_armor",
            "leather_helmet", "iron_helmet", "reinforced_boots", "climbing_boots"]
    for clip, count, fps in [("idle", 8, 12), ("attack", 12, 24)]:
        required = [("body", w) for w in ["fresh", "bruised", "battered"]]
        required += [(item, "fresh") for item in gear] + [("wood_sword", "battered")]
        for item, wear in required:
            path = LAYERS / item / f"{wear}_{clip}.png"
            if not path.is_file():
                missing.append(str(path.relative_to(ROOT)))
        for path in sorted(LAYERS.glob(f"*/*_{clip}.png")):
            im = Image.open(path)
            if im.mode != "RGBA" or im.size != (2048, 512 * ((count + 3) // 4)):
                errors.append(f"Bad grid or mode: {path.relative_to(ROOT)}")
                continue
            cels = []
            for i in range(count):
                cel = im.crop((i % 4 * 512, i // 4 * 512, (i % 4 + 1) * 512, (i // 4 + 1) * 512))
                a = cel.getchannel("A")
                bbox = a.getbbox()
                if bbox and (bbox[0] == 0 or bbox[1] == 0 or bbox[2] == 512 or bbox[3] == 512):
                    errors.append(f"Alpha touches border: {path.relative_to(ROOT)}, frame {i}")
                if path.parent.name == "body":
                    footprint = a.crop((0, 465, 512, 504)).point(lambda v: 255 if v > 180 else 0).getbbox()
                    if not footprint:
                        errors.append(f"Missing feet: {path.name}, frame {i}")
                    else:
                        center = (footprint[0] + footprint[2] - 1) / 2
                        bottom = footprint[3] + 465
                        if abs(center - 256) > 1 or abs(bottom - 500) > 4:
                            errors.append(f"Feet registration: {path.name} frame {i}, x={center}, y={bottom}")
                cels.append(cel.tobytes())
            if clip == "attack" and cels[5] != cels[6]:
                errors.append(f"Impact hold differs: {path.relative_to(ROOT)}")
            checked.append(str(path.relative_to(ROOT)))
        for wear in ["fresh", "bruised", "battered"]:
            p = HERE / f"{wear}_{clip}_comparison.gif"
            if not p.is_file():
                errors.append(f"Missing preview: {p.name}")
                continue
            gif = Image.open(p)
            duration = 0
            for i in range(gif.n_frames):
                gif.seek(i)
                duration += gif.info["duration"]
            if gif.n_frames != count or abs(duration - count / fps * 1000) > 10:
                errors.append(f"Wrong GIF timing: {p.name}")
    for p in HERE.iterdir():
        if p.suffix in [".png", ".gif"] and p.stat().st_size >= 2_000_000:
            errors.append(f"Preview too large: {p.name}")
    result = {"status": "incomplete" if missing or errors else "technical_checks_passed",
              "existing_atlases_checked": len(checked), "technical_errors": errors,
              "missing_required_atlases": missing,
              "visual_seam_check": "not_approved; inspect numbered grids, especially helmet fit and cloth edges"}
    (HERE / "technical_checks.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 1 if missing or errors else 0


if __name__ == "__main__":
    raise SystemExit(validate())
