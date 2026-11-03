class_name ArenaBackdrop
extends Node2D
## The scenery behind the fighters, built from the layers in assets/bg/<id>/ (issue #17):
## sky, drifting clouds, far hills, birds, mid scenery with its flags, smoke, torches and
## swaying grass, then the ground. A background without layers falls back to assets/bg/<id>.png.
##
## set_camera() zooms and pans the layers by different amounts, so the scene gains depth when
## the fight leans in on a big blow. At zoom 1 every layer sits exactly where it was painted.

const SIZE := Vector2(1080, 660)
const CENTER := SIZE / 2
const CLOUD_SPEED := Vector2(14, 22)
## Seconds between birds crossing the sky.
const BIRD_GAP := Vector2(6, 14)
const BIRD_SPEED := 120.0
const FRAME_FPS := 8.0
## How far each layer slides at full pan, from layers.json when it says.
const DEFAULT_PAN := {"sky": 0, "far": -12, "mid": 12, "ground": 20}

var background := ""
var zoom := 1.0
## -1..1: which way the camera leans.
var pan := 0.0

var _layers := {}
var _pan_offsets := DEFAULT_PAN.duplicate()
## Each moving piece: {"node", "layer", "base", "kind", ...}.
var _props: Array[Dictionary] = []
var _flat: Texture2D
var _time := 0.0
var _next_bird := 3.0
var _bird_texture: Texture2D
var _bird_scale := 0.65
var _bird_lane := Vector2(80, 200)


## Builds the scenery for `id`, or the plain backdrop if it has no layers.
func load_background(id: String) -> void:
	background = id
	for child in get_children():
		child.queue_free()
	_layers.clear()
	_props.clear()
	_flat = null
	_bird_texture = null
	var dir := "res://assets/bg/%s/" % id
	var info := _json(dir + "layers.json")
	if info.is_empty() or not ResourceLoader.exists(dir + "sky.png"):
		var flat := "res://assets/bg/%s.png" % id
		_flat = load(flat) if id and ResourceLoader.exists(flat) else null
		queue_redraw()
		return

	var parallax: Dictionary = info.get("safe_parallax", {}).get("x_offsets", {})
	for key in parallax:
		_pan_offsets[key] = float(parallax[key])
	var origins: Dictionary = info.get("sprite_origins", {})
	var scales: Dictionary = info.get("sprite_scales", {})
	var frames: Dictionary = info.get("atlas_frames", {})

	for layer in ["sky", "far", "mid", "ground"]:
		var holder := Node2D.new()
		add_child(holder)
		_layers[layer] = holder
		var sprite := Sprite2D.new()
		sprite.texture = load(dir + layer + ".png")
		sprite.centered = false
		holder.add_child(sprite)
		match layer:
			"sky":
				for i in 3:
					_add_cloud(holder, dir + "cloud_%d.png" % (i + 1), i)
			"mid":
				# Animated scenery belongs to the mid layer so it moves with what it stands on.
				for kind in ["flag", "smoke", "torch"]:
					var spots: Variant = info.get(kind)
					if spots == null or not ResourceLoader.exists(dir + kind + ".png"):
						continue
					if spots is Array and not spots.is_empty() and not spots[0] is Array:
						spots = [spots]
					for spot in spots:
						_add_strip(holder, dir + kind + ".png", kind, Vector2(spot[0], spot[1]), frames.get(kind, 6), origins.get(kind), scales.get(kind, 1.0))
				if ResourceLoader.exists(dir + "grass.png"):
					for spot in info.get("grass", []):
						_add_grass(holder, dir + "grass.png", Vector2(spot[0], spot[1]), origins.get("grass"), scales.get("grass", 1.0))
	if ResourceLoader.exists(dir + "bird.png"):
		_bird_texture = load(dir + "bird.png")
		_bird_scale = scales.get("bird", 0.65)
		var lane: Array = info.get("bird_lane_y", [80, 200])
		_bird_lane = Vector2(lane[0], lane[1])
	_apply_camera()


## `zoom` 1..1.15 and `pan` -1..1. Call every frame while the camera moves.
func set_camera(p_zoom: float, p_pan: float) -> void:
	zoom = p_zoom
	pan = p_pan
	_apply_camera()


func has_layers() -> bool:
	return not _layers.is_empty()


func _process(delta: float) -> void:
	if _layers.is_empty():
		return
	_time += delta
	for prop in _props:
		var node: Node2D = prop["node"]
		match prop["kind"]:
			"cloud":
				node.position.x += prop["speed"] * delta
				if node.position.x > SIZE.x + 40:
					node.position.x = -prop["width"] - 40
			"strip":
				var sprite: Sprite2D = node
				sprite.frame = int(_time * FRAME_FPS + prop["phase"]) % sprite.hframes
			"grass":
				node.rotation = 0.06 * sin(_time * 1.7 + prop["phase"])
			"bird":
				node.position.x += prop["speed"] * delta
				node.position.y = prop["y"] + 10 * sin(_time * 3.0 + prop["phase"])
				var bird: Sprite2D = node
				bird.frame = int(_time * 10.0) % bird.hframes
	for prop in _props.duplicate():
		if prop["kind"] == "bird" and absf(prop["node"].position.x - CENTER.x) > SIZE.x:
			prop["node"].queue_free()
			_props.erase(prop)
	_next_bird -= delta
	if _next_bird <= 0.0 and _bird_texture:
		_next_bird = randf_range(BIRD_GAP.x, BIRD_GAP.y)
		_add_bird()


func _draw() -> void:
	if _flat:
		draw_texture_rect(_flat, Rect2(Vector2.ZERO, SIZE), false)


func _apply_camera() -> void:
	for layer in _layers:
		var holder: Node2D = _layers[layer]
		holder.scale = Vector2.ONE * zoom
		holder.position = CENTER - CENTER * zoom + Vector2(_pan_offsets.get(layer, 0.0) * pan, 0)


func _add_cloud(holder: Node2D, path: String, index: int) -> void:
	if not ResourceLoader.exists(path):
		return
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.position = Vector2(randf_range(0, SIZE.x), 30 + index * 55 + randf_range(-10, 10))
	sprite.modulate.a = 0.9
	holder.add_child(sprite)
	_props.append({"node": sprite, "kind": "cloud", "speed": randf_range(CLOUD_SPEED.x, CLOUD_SPEED.y), "width": sprite.texture.get_width()})


## A looping strip of frames in one row, placed by its origin (the foot of the flagpole, the
## mouth of the chimney...).
func _add_strip(holder: Node2D, path: String, kind: String, at: Vector2, frame_count: int, origin: Variant, size: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.hframes = frame_count
	sprite.centered = false
	sprite.scale = Vector2.ONE * size
	var pivot := Vector2(origin[0], origin[1]) if origin is Array else Vector2(sprite.texture.get_width() / frame_count / 2.0, sprite.texture.get_height())
	sprite.offset = -pivot
	sprite.position = at
	holder.add_child(sprite)
	_props.append({"node": sprite, "kind": "strip", "phase": randf() * frame_count, "name": kind})


func _add_grass(holder: Node2D, path: String, at: Vector2, origin: Variant, size: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.scale = Vector2.ONE * size
	var pivot := Vector2(origin[0], origin[1]) if origin is Array else Vector2(sprite.texture.get_width() / 2.0, sprite.texture.get_height())
	sprite.offset = -pivot
	sprite.position = at
	holder.add_child(sprite)
	_props.append({"node": sprite, "kind": "grass", "phase": randf() * TAU})


func _add_bird() -> void:
	var holder: Node2D = _layers["far"]
	var sprite := Sprite2D.new()
	sprite.texture = _bird_texture
	sprite.hframes = 4
	var direction := 1.0 if randf() < 0.5 else -1.0
	sprite.scale = Vector2(_bird_scale * direction, _bird_scale)
	var y := randf_range(_bird_lane.x, _bird_lane.y)
	sprite.position = Vector2(-60.0 if direction > 0 else SIZE.x + 60.0, y)
	holder.add_child(sprite)
	_props.append({"node": sprite, "kind": "bird", "speed": BIRD_SPEED * direction, "y": y, "phase": randf() * TAU})


static func _json(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var json: JSON = load(path)
	return json.data if json.data is Dictionary else {}
