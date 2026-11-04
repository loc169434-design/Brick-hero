"""Read-only validation of issue 24 animation atlases. Run from repository root."""
import hashlib
import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SPECS = json.loads((ROOT / "docs/ideas/anim_moves_specs.json").read_text())


def check(character, wear="fresh"):
    folder = ROOT / "assets/characters" / character / "anim"
    metadata = json.loads((folder / "anim.json").read_text())
    assert metadata["frame_size"] == [512, 512]
    assert metadata["columns"] == 4
    results = []
    for clip, spec in SPECS[character].items():
        count, fps, loop, *impact = spec
        info = metadata["clips"][clip]
        assert (info["frames"], info["fps"], info.get("loop", False)) == (count, fps, loop), clip
        if impact:
            assert info["impact"] == impact[0], clip
        path = folder / f"{wear}_{clip}.png"
        with Image.open(path) as image:
            assert image.mode == "RGBA", path
            assert image.size == (2048, 512 * math.ceil(count / 4)), path
            frames = [image.crop(((i % 4) * 512, (i // 4) * 512, (i % 4 + 1) * 512, (i // 4 + 1) * 512)) for i in range(count)]
            assert all(frame.getbbox() for frame in frames), path
            assert all(frame.getchannel("A").getextrema() == (0, 255) for frame in frames), path
            hashes = [hashlib.sha256(frame.tobytes()).hexdigest() for frame in frames]
            assert len(set(hashes)) >= 3, f"Not enough distinct drawings: {path}"
            for i in range(count, 4 * math.ceil(count / 4)):
                assert not image.crop(((i % 4) * 512, (i // 4) * 512, (i % 4 + 1) * 512, (i // 4 + 1) * 512)).getbbox(), path
        if character == "orc_shield" and clip not in ("defeat", "bald"):
            assert len(info["shield"]) == count, clip
            assert all(len(point) == 2 and all(0 <= value < 512 for value in point) for point in info["shield"]), clip
        if not loop and clip not in ("throw", "defeat", "victory"):
            idle = Image.open(folder / f"{wear}_idle.png").convert("RGBA").crop((0, 0, 512, 512))
            assert frames[-1].tobytes() == idle.tobytes(), f"Recovery does not match idle: {path}"
        results.append({"file": str(path.relative_to(ROOT)), "frames": count, "fps": fps, "unique_drawings": len(set(hashes)), "frame_sha256": hashes})
    return results


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("character", choices=SPECS)
    parser.add_argument("--wear", choices=["fresh", "bruised", "battered"], default="fresh")
    args = parser.parse_args()
    print(json.dumps(check(args.character, args.wear), indent=2))
