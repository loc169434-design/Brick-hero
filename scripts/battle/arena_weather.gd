class_name ArenaWeather
extends Node2D
## The weather in front of the arena (docs/weather_plan.md, art issue #49): slanting rain with
## drops splashing on the floor, fog rolling across, and in a storm a bolt now and then, the
## screen flashing white and thunder after it. The bolt itself strikes far behind, on the
## backdrop (ArenaBackdrop.strike_bolt). Sits over the fighters and under the HUD, in the
## backdrop's coordinates. Art: assets/fx/weather/, laid out by its anim.json.

const DIR := "res://assets/fx/weather/"
const SIZE := Vector2(1080, 660)
## How strongly the rain shows, by Weather sky.
const RAIN_ALPHA := {&"rain": 0.5, &"storm": 0.85}
## Seconds between drops splashing on the floor.
const SPLASH_GAP := {&"rain": 0.16, &"storm": 0.07}
const SPLASH_SCALE := Vector2(0.1, 0.18)
## Where drops splash: the arena floor.
const FLOOR := Rect2(30, 410, 1020, 150)
## Seconds between a storm's bolts; the first comes sooner.
const BOLT_GAP := Vector2(6.0, 11.0)
const FIRST_BOLT := 2.5
const FLASH_TIME := 0.45
const THUNDER_DELAY := 0.25
## Fog drifts this many pixels a second.
const FOG_SPEED := 22.0
const FOG_ALPHA := 0.75

var sky := Weather.DEFAULT_SKY
## Where the bolts strike; may be null.
var backdrop: ArenaBackdrop
var _anim := {}
var _art := {}
var _time := 0.0
var _next_splash := 0.0
var _next_bolt := FIRST_BOLT
var _flash := 0.0
## Seconds until the thunder of the last bolt; -1 for none coming.
var _thunder := -1.0
## {"at", "t", "scale"}
var _splashes: Array[Dictionary] = []


func _ready() -> void:
	if ResourceLoader.exists(DIR + "anim.json"):
		var json: JSON = load(DIR + "anim.json")
		if json.data is Dictionary:
			_anim = json.data


func set_sky(p_sky: StringName) -> void:
	sky = p_sky
	_splashes.clear()
	_flash = 0.0
	_thunder = -1.0
	_next_bolt = FIRST_BOLT
	visible = sky != Weather.DEFAULT_SKY
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	if _thunder >= 0.0:
		_thunder -= delta
		if _thunder < 0.0:
			Sfx.play(&"thunder", randf_range(0.85, 1.1))
	if Weather.is_wet(sky):
		_next_splash -= delta
		while _next_splash <= 0.0:
			_next_splash += SPLASH_GAP[sky] * randf_range(0.5, 1.5)
			var at := Vector2(randf_range(FLOOR.position.x, FLOOR.end.x), randf_range(FLOOR.position.y, FLOOR.end.y))
			# Further back is higher up the floor, and smaller.
			var depth := (at.y - FLOOR.position.y) / FLOOR.size.y
			_splashes.append({"at": at, "t": 0.0, "scale": lerpf(SPLASH_SCALE.x, SPLASH_SCALE.y, depth)})
		var splash := _info("rain_splash")
		var length := float(splash.get("frames", 6)) / float(splash.get("fps", 16))
		for drop in _splashes:
			drop["t"] += delta
		_splashes = _splashes.filter(func(drop: Dictionary) -> bool: return drop["t"] < length)
	if sky == &"storm":
		_next_bolt -= delta
		if _next_bolt <= 0.0:
			_next_bolt = randf_range(BOLT_GAP.x, BOLT_GAP.y)
			_strike()
	queue_redraw()


func _strike() -> void:
	if backdrop:
		backdrop.strike_bolt(randf_range(120, SIZE.x - 120))
	_flash = 1.0
	_thunder = THUNDER_DELAY


func _draw() -> void:
	if sky == &"fog":
		# Two copies side by side, sliding, so the drift never ends.
		var shift := fposmod(_time * FOG_SPEED, SIZE.x)
		for k in 2:
			_draw_frame("fog", Rect2(Vector2(shift - SIZE.x * k, 0), SIZE), Color(1, 1, 1, FOG_ALPHA))
	if Weather.is_wet(sky):
		_draw_frame("rain", Rect2(Vector2.ZERO, SIZE), Color(1, 1, 1, RAIN_ALPHA[sky]))
		var splash := _info("rain_splash")
		var origin: Array = splash.get("origin", [256, 420])
		var cell := _cell("rain_splash")
		for drop in _splashes:
			var size := cell * float(drop["scale"])
			var at: Vector2 = drop["at"] - Vector2(origin[0], origin[1]) * float(drop["scale"])
			_draw_frame("rain_splash", Rect2(at, size), Color(1, 1, 1, 0.85), drop["t"])
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.92, 0.95, 1.0, 0.65 * _flash * _flash))


## One frame of `name` into `rect`; `t` seconds into a clip that plays once, or the looping
## frame for now when -1.
func _draw_frame(name: String, rect: Rect2, tint: Color, t := -1.0) -> void:
	var texture := _texture(name)
	var info := _info(name)
	if texture == null or info.is_empty():
		return
	var frames := int(info.get("frames", 1))
	var columns := int(info.get("columns", 1))
	var at := t if t >= 0.0 else _time
	var frame := int(at * float(info.get("fps", 8)))
	frame = frame % frames if t < 0.0 else mini(frame, frames - 1)
	var cell := _cell(name)
	draw_texture_rect_region(texture, rect, Rect2(Vector2(frame % columns, frame / columns) * cell, cell), tint)


func _info(name: String) -> Dictionary:
	return _anim.get(name, {})


func _cell(name: String) -> Vector2:
	var size: Array = _info(name).get("frame_size", [SIZE.x, SIZE.y])
	return Vector2(size[0], size[1])


func _texture(name: String) -> Texture2D:
	if not _art.has(name):
		var path := DIR + name + ".png"
		_art[name] = load(path) if ResourceLoader.exists(path) else null
	return _art[name]
