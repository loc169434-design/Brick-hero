class_name TileArt
extends RefCounted
## One tile theme's art: static PNGs for the board, NEXT and HOLD, plus animation clips
## built on demand from the atlases listed in assets/tiles/animation_pack.json.
## Clips load one at a time because each atlas is about 3.4 MiB of texture; loading a
## family's ready-made SpriteFrames would pull in every clip at once.

const MANIFEST := "res://assets/tiles/animation_pack.json"
## Indexed by Cell.BlockColor.
const COLOR_NAMES := ["red", "green", "yellow", "purple"]
## Tile art is drawn on a 128 px canvas; animation frames add padding around it for FX.
const TILE_SIZE := 128.0
const THEMES := ["training", "orc_shield"]

var family: String

## "red/combo" -> manifest atlas entry
var _atlases := {}
var _frames := {}
var _tiles := {}
## "red/fear" -> Texture2D or null
var _expressions := {}


func _init(p_family: String) -> void:
	family = p_family
	if not ResourceLoader.exists(MANIFEST):
		return
	var manifest: JSON = load(MANIFEST)
	for entry: Dictionary in manifest.data.get("atlases", []):
		if entry["family"] == family:
			_atlases["%s/%s" % [entry["color"], entry["animation"]]] = entry


func has_clip(clip: StringName) -> bool:
	return _atlases.has("red/%s" % clip)


## The theme's tile, else the shared fallback in assets/tiles/, else null (placeholder art).
func tile(color: int) -> Texture2D:
	if color < 0 or color >= COLOR_NAMES.size():
		return null
	if not _tiles.has(color):
		_tiles[color] = null
		for path in ["res://assets/tiles/%s/tile_%s.png" % [family, COLOR_NAMES[color]],
				"res://assets/tiles/tile_%s.png" % COLOR_NAMES[color]]:
			if ResourceLoader.exists(path):
				_tiles[color] = load(path)
				break
	return _tiles[color]


## A still face the theme's tile pulls (assets/tiles/<theme>/expressions/<color>_<pose>.png:
## fear, scream, relief...), or null if the theme has none.
func expression(color: int, pose: String) -> Texture2D:
	if color < 0 or color >= COLOR_NAMES.size():
		return null
	var key := "%s/%s" % [COLOR_NAMES[color], pose]
	if not _expressions.has(key):
		var path := "res://assets/tiles/%s/expressions/%s_%s.png" % [family, COLOR_NAMES[color], pose]
		_expressions[key] = load(path) if ResourceLoader.exists(path) else null
	return _expressions[key]


## One SpriteFrames per color, shared by every sprite of that color; clips are added by ensure_clip.
func frames(color: int) -> SpriteFrames:
	if not _frames.has(color):
		_frames[color] = SpriteFrames.new()
	return _frames[color]


## Loads `clip` for `color` if the theme has it. Returns false when there is no such clip.
func ensure_clip(color: int, clip: StringName) -> bool:
	if color < 0 or color >= COLOR_NAMES.size():
		return false
	var sprite_frames := frames(color)
	if sprite_frames.has_animation(clip):
		return true
	var entry: Dictionary = _atlases.get("%s/%s" % [COLOR_NAMES[color], clip], {})
	var path := "res://%s" % entry.get("file", "")
	if entry.is_empty() or not ResourceLoader.exists(path):
		return false
	var atlas: Texture2D = load(path)
	var cell: int = entry["cell"]
	var columns: int = entry["columns"]
	sprite_frames.add_animation(clip)
	sprite_frames.set_animation_speed(clip, entry["fps"])
	sprite_frames.set_animation_loop(clip, entry["loop"])
	for i in int(entry["frames"]):
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(i % columns * cell, floori(float(i) / columns) * cell, cell, cell)
		sprite_frames.add_frame(clip, frame)
	return true


## Length of `clip` at normal speed, or 0 if it isn't loaded.
func clip_seconds(color: int, clip: StringName) -> float:
	var sprite_frames := frames(color)
	if not sprite_frames.has_animation(clip):
		return 0.0
	return sprite_frames.get_frame_count(clip) / sprite_frames.get_animation_speed(clip)
