class_name SpecialArt
extends RefCounted
## The specials' own art, in assets/tiles/specials/: a still per special and a looping sheet,
## both listed in specials.json. The bomb's sheet is only its burning fuse, laid over the
## still bomb in the same 128 px frame; the lightning's and the star's sheets include the
## special itself and replace the still. Missing art returns null, for the drawn fallback.

const DIR := "res://assets/tiles/specials/"
const MANIFEST := "specials.json"
const SHEET_COLUMNS := 8
const STILLS := {
	Cell.Special.BOMB: "bomb.png",
	Cell.Special.LIGHTNING: "lightning.png",
	Cell.Special.RAINBOW: "star.png",
}
const SHEETS := {
	Cell.Special.BOMB: "bomb_fuse.png",
	Cell.Special.LIGHTNING: "lightning_idle.png",
	Cell.Special.RAINBOW: "star_idle.png",
}

var _manifest := {}
## file -> Texture2D or null
var _textures := {}


func _init() -> void:
	var path := DIR + MANIFEST
	if ResourceLoader.exists(path):
		var json: JSON = load(path)
		if json.data is Dictionary:
			_manifest = json.data


func still(kind: int) -> Texture2D:
	return _texture(STILLS.get(kind, ""))


## The looping sheet for `kind`, or null.
func sheet(kind: int) -> Texture2D:
	return _texture(SHEETS.get(kind, "")) if not _entry(kind).is_empty() else null


## True when the sheet only adds to the still (the bomb's fuse) instead of replacing it.
func sheet_overlays_still(kind: int) -> bool:
	return _entry(kind).has("overlay_on")


## The part of sheet(kind) showing `t` seconds into its loop.
func frame_region(kind: int, t: float) -> Rect2:
	var entry := _entry(kind)
	var frames: int = entry["frames"]
	var i := posmod(floori(t * float(entry["fps"])), frames)
	var size := Vector2(entry["frame_width"], entry["frame_height"])
	return Rect2(Vector2(i % SHEET_COLUMNS, floori(float(i) / SHEET_COLUMNS)) * size, size)


func _entry(kind: int) -> Dictionary:
	return _manifest.get(SHEETS.get(kind, ""), {})


func _texture(file: String) -> Texture2D:
	if file.is_empty():
		return null
	if not _textures.has(file):
		var path := DIR + file
		_textures[file] = load(path) if ResourceLoader.exists(path) else null
	return _textures[file]
