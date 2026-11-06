class_name ObstacleArt
extends RefCounted
## Pictures for the squares that aren't tiles: crates (one picture per layer), rocks (whole,
## then cracked), their break-up clips (assets/board/obstacles/obstacles.json), and the items
## to rescue (assets/ui/campaign/<kind>.png).

const DIR := "res://assets/board/obstacles/"
const ITEM_DIR := "res://assets/ui/campaign/"
## Rock layers, outermost first: two layers show whole, the last one cracked.
const ROCK_LAYERS := {2: "rock.png", 1: "rock_cracked.png"}
## Break-up clips not named <kind>_break.
const BREAK_CLIPS := {"potion_bottle": "potion_break", "mark": "gold_mark_break"}

var _textures := {}
var _break_frames := {}
var _info := {}


func _init() -> void:
	if ResourceLoader.exists(DIR + "obstacles.json"):
		var json: JSON = load(DIR + "obstacles.json")
		if json.data is Dictionary:
			_info = json.data


## The picture for `cell` as it stands now, or null.
func texture(cell: Cell) -> Texture2D:
	if cell.is_item():
		return _load(ITEM_DIR + cell.blocker + ".png")
	match cell.blocker:
		"crate":
			var layers: Array = _info.get("layers", {}).get("crate", ["crate_1.png", "crate_2.png", "crate_3.png"])
			return _load(DIR + String(layers[clampi(cell.layers, 1, layers.size()) - 1]))
		"rock":
			return _load(DIR + String(ROCK_LAYERS.get(clampi(cell.layers, 1, 2))))
	return _load(DIR + cell.blocker + ".png")


## An overlay drawn on top of a tile: "ice" (by layers left), "web" or "mark".
func overlay(kind: String, layers := 1) -> Texture2D:
	match kind:
		"ice":
			return _load(DIR + "ice_%d.png" % clampi(layers, 1, 2))
		"web":
			return _load(DIR + "web.png")
		"mark":
			return _load(DIR + "gold_mark.png")
	return null


## The frame of `kind`'s idle loop (e.g. the poison toad breathing) at `time`: the sheet and
## its region, or {} if it has none.
func idle_frame(kind: String, time: float) -> Dictionary:
	var clip: Dictionary = _info.get("clips", {}).get(kind + "_idle", {})
	var sheet := _load(DIR + kind + "_idle.png")
	if clip.is_empty() or sheet == null:
		return {}
	var size := Vector2(clip.get("frame_width", 512), clip.get("frame_height", 512))
	var columns := maxi(int(sheet.get_width() / size.x), 1)
	var frame := int(time * float(clip.get("fps", 10))) % int(clip.get("frames", 1))
	return {"sheet": sheet, "region": Rect2(Vector2(frame % columns, frame / columns) * size, size)}


## The clip of `kind` breaking apart (SpriteFrames with one "break" animation), or null.
func break_frames(kind: String) -> SpriteFrames:
	if _break_frames.has(kind):
		return _break_frames[kind]
	var clip_name: String = BREAK_CLIPS.get(kind, kind + "_break")
	var clip: Dictionary = _info.get("clips", {}).get(clip_name, {})
	var sheet := _load(DIR + clip_name + ".png")
	var frames: SpriteFrames = null
	if sheet and not clip.is_empty():
		frames = SpriteFrames.new()
		frames.add_animation(&"break")
		frames.set_animation_loop(&"break", false)
		frames.set_animation_speed(&"break", float(clip.get("fps", 12)))
		var size := Vector2(clip.get("frame_width", 512), clip.get("frame_height", 512))
		var columns := maxi(int(sheet.get_width() / size.x), 1)
		for i in int(clip.get("frames", 4)):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(Vector2(i % columns, i / columns) * size, size)
			frames.add_frame(&"break", atlas)
	_break_frames[kind] = frames
	return frames


func _load(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]
