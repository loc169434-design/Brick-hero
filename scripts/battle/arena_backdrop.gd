class_name ArenaBackdrop
extends Node2D
## The scenery behind the fighters, built from the layers in assets/bg/<id>/ (issue #17):
## sky, drifting clouds, far hills, birds, mid scenery with its flags, smoke, torches and
## swaying grass, then the ground. A background without layers falls back to assets/bg/<id>.png.
##
## set_sky() paints the hour and the weather (docs/weather_plan.md, art issue #49): the sky
## layer swaps for its morning, noon, dusk or night version, the rest is tinted by the
## background's time_lighting, birds stay home at night and in the rain, red eyes blink in the
## bushes at night, and a storm's bolts strike behind the hills (strike_bolt). The rain and fog
## in front of the fighters are ArenaWeather's.
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
const WEATHER_DIR := "res://assets/fx/weather/"
## time_lighting for a background that doesn't say (the same values the art was checked with).
const DEFAULT_LIGHT := {
	&"morning": Color(1.0, 0.96, 0.86), &"noon": Color.WHITE,
	&"dusk": Color(1.0, 0.74, 0.58), &"night": Color(0.32, 0.4, 0.64),
}
## Rain darkens the scenery, and its sky most.
const WET_LIGHT := Color(0.8, 0.84, 0.9)
const WET_SKY := Color(0.7, 0.74, 0.82)
## The fighters take only part of the tint, so they stay easy to read at night.
const FIGHTER_LIGHT := 0.55
## Red eyes at night: seconds between blinks, and their size (of the 256×128 art).
const EYES_GAP := Vector2(2.5, 6.0)
const EYES_SCALE := 0.16
## A storm's bolt, by its 512×1024 art, strikes this far down the backdrop.
const BOLT_SCALE := 0.45
const BOLT_GROUND := Vector2(130, 300)

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
var hour := Weather.DEFAULT_HOUR
var sky := Weather.DEFAULT_SKY
var _info := {}
var _dir := ""
var _sky_sprite: Sprite2D
var _light := Color.WHITE
## assets/fx/weather/anim.json, and its textures by name once needed.
var _weather_anim := {}
var _weather_art := {}
var _next_eyes := 2.0


## Builds the scenery for `id`, or the plain backdrop if it has no layers.
func load_background(id: String) -> void:
	background = id
	for child in get_children():
		child.queue_free()
	_layers.clear()
	_props.clear()
	_flat = null
	_bird_texture = null
	_sky_sprite = null
	var dir := "res://assets/bg/%s/" % id
	var info := _json(dir + "layers.json")
	_info = info
	_dir = dir
	if info.is_empty() or not ResourceLoader.exists(dir + "sky.png"):
		var flat := "res://assets/bg/%s.png" % id
		_flat = load(flat) if id and ResourceLoader.exists(flat) else null
		_apply_sky()
		return

	var parallax: Dictionary = info.get("safe_parallax", {}).get("x_offsets", {})
	for key in parallax:
		_pan_offsets[key] = float(parallax[key])
	var origins: Dictionary = info.get("sprite_origins", {})
	var scales: Dictionary = info.get("sprite_scales", {})
	var frames: Dictionary = info.get("atlas_frames", {})

	# "bolt" (a storm's lightning, behind the hills) and "glow" (eyes and fireflies, in front)
	# give off their own light, so the hour's tint leaves them alone.
	_pan_offsets["bolt"] = _pan_offsets.get("far", 0.0)
	_pan_offsets["glow"] = _pan_offsets.get("mid", 0.0)
	for layer in ["sky", "bolt", "far", "mid", "ground", "glow"]:
		var holder := Node2D.new()
		add_child(holder)
		_layers[layer] = holder
		if layer == "bolt" or layer == "glow":
			continue
		var sprite := Sprite2D.new()
		sprite.texture = load(dir + layer + ".png")
		sprite.centered = false
		holder.add_child(sprite)
		match layer:
			"sky":
				_sky_sprite = sprite
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
	var effects: Dictionary = info.get("ambient_effects", {})
	for kind: String in effects:
		_add_ambient(kind, effects[kind])
	_apply_sky()
	_apply_camera()


## Paints `p_hour` (Weather.HOURS) and `p_sky` (Weather.SKIES) over the loaded background.
func set_sky(p_hour: StringName, p_sky: StringName) -> void:
	hour = p_hour
	sky = p_sky
	_apply_sky()


## The tint the fighters should take for the hour and the weather.
func fighter_light() -> Color:
	return Color.WHITE.lerp(_light, FIGHTER_LIGHT)


## A storm's bolt striking the ground at `x`, behind the hills; true if there was art for it.
func strike_bolt(x: float) -> bool:
	var info: Dictionary = _weather_anim_info("lightning_bolt")
	var texture := _weather_texture("lightning_bolt")
	if _layers.is_empty() or texture == null or info.is_empty():
		return false
	var origin: Array = info.get("origin", [256, 900])
	var sprite := _once(_layers["bolt"], texture, info, Vector2(x, randf_range(BOLT_GROUND.x, BOLT_GROUND.y)), BOLT_SCALE)
	sprite.offset = -Vector2(origin[0], origin[1])
	sprite.centered = false
	return true


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
	for prop in _props.duplicate():
		if prop["kind"] == "once":
			var once: Sprite2D = prop["node"]
			prop["t"] += delta
			var frame := int(prop["t"] * prop["fps"])
			if frame >= prop["frames"]:
				once.queue_free()
				_props.erase(prop)
			else:
				once.frame = frame
		elif prop["kind"] == "loop":
			var looped: Sprite2D = prop["node"]
			looped.frame = int(_time * prop["fps"] + prop["phase"]) % int(prop["frames"])
	if hour == &"night" and _info.get("eyes") is Array and not _info["eyes"].is_empty():
		_next_eyes -= delta
		if _next_eyes <= 0.0:
			_next_eyes = randf_range(EYES_GAP.x, EYES_GAP.y)
			_blink_eyes()
	_next_bird -= delta
	if _next_bird <= 0.0 and _bird_texture and hour != &"night" and sky == &"clear":
		_next_bird = randf_range(BIRD_GAP.x, BIRD_GAP.y)
		_add_bird()


func _draw() -> void:
	if _flat:
		draw_texture_rect(_flat, Rect2(Vector2.ZERO, SIZE), false, _light)


func _apply_sky() -> void:
	var lighting: Dictionary = _info.get("time_lighting", {})
	var values: Variant = lighting.get(String(hour))
	_light = Color(values[0], values[1], values[2]) if values is Array and values.size() >= 3 else DEFAULT_LIGHT.get(hour, Color.WHITE)
	if Weather.is_wet(sky):
		_light *= WET_LIGHT
	if _sky_sprite:
		var painted: String = _info.get("sky_times", {}).get(String(hour), "")
		var path := _dir + painted if painted else _dir + "sky.png"
		_sky_sprite.texture = load(path) if ResourceLoader.exists(path) else load(_dir + "sky.png")
	if _layers.has("sky"):
		# The sky is painted for its hour already; only rain greys it.
		_layers["sky"].modulate = WET_SKY if Weather.is_wet(sky) else Color.WHITE
		for layer in ["far", "mid", "ground"]:
			_layers[layer].modulate = _light
		for prop in _props:
			if prop["kind"] == "cloud":
				prop["node"].modulate = Color(_light if hour == &"night" else Color.WHITE, 0.9)
	queue_redraw()


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


## An ambient loop from layers.json's ambient_effects (the swamp's fireflies, bubbles and lotus
## flowers). Fireflies glow on their own; the rest sit on the ground and take its light.
func _add_ambient(kind: String, info: Dictionary) -> void:
	var path: String = _dir + String(info.get("file", kind + ".png"))
	if not ResourceLoader.exists(path):
		return
	var holder: Node2D = _layers["glow" if kind == "firefly" else "ground"]
	var texture: Texture2D = load(path)
	var columns := int(info.get("columns", 1))
	var frames := int(info.get("frames", 1))
	var origin: Array = info.get("origin", [0, 0])
	for spot: Array in info.get("positions", []):
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.hframes = columns
		sprite.vframes = ceili(float(frames) / columns)
		sprite.centered = false
		sprite.offset = -Vector2(origin[0], origin[1])
		sprite.scale = Vector2.ONE * float(info.get("scale", 1.0))
		sprite.position = Vector2(spot[0], spot[1])
		holder.add_child(sprite)
		_props.append({"node": sprite, "kind": "loop", "fps": float(info.get("fps", 8)), "frames": frames, "phase": randf() * frames})


## A pair of red eyes opening, blinking and closing at one of the background's eye spots.
func _blink_eyes() -> void:
	var texture := _weather_texture("red_eyes")
	var info := _weather_anim_info("red_eyes")
	if texture == null or info.is_empty():
		return
	var spots: Array = _info["eyes"]
	var spot: Array = spots[randi() % spots.size()]
	_once(_layers["glow"], texture, info, Vector2(spot[0], spot[1]), EYES_SCALE)


## A sprite that plays the frames of `info` once at `at` and frees itself.
func _once(holder: Node2D, texture: Texture2D, info: Dictionary, at: Vector2, size: float) -> Sprite2D:
	var columns := int(info.get("columns", 1))
	var frames := int(info.get("frames", 1))
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = columns
	sprite.vframes = ceili(float(frames) / columns)
	sprite.scale = Vector2.ONE * size
	sprite.position = at
	holder.add_child(sprite)
	_props.append({"node": sprite, "kind": "once", "t": 0.0, "fps": float(info.get("fps", 8)), "frames": frames})
	return sprite


func _weather_anim_info(name: String) -> Dictionary:
	if _weather_anim.is_empty():
		_weather_anim = _json(WEATHER_DIR + "anim.json")
	return _weather_anim.get(name, {})


func _weather_texture(name: String) -> Texture2D:
	if not _weather_art.has(name):
		var path := WEATHER_DIR + name + ".png"
		_weather_art[name] = load(path) if ResourceLoader.exists(path) else null
	return _weather_art[name]


static func _json(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var json: JSON = load(path)
	return json.data if json.data is Dictionary else {}
