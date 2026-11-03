class_name ScreenFeel
extends Camera2D
## The camera over the whole screen. Shakes on impacts, freezes the game for a few frames on
## big hits (hit-stop) and buzzes the phone, so strikes and long chains land with weight.
## Shake follows "trauma": each impact adds some, it drains away, and the offset grows with
## its square, so small taps barely nudge the screen while big ones rock it.

## Offset in pixels at full trauma.
@export var max_offset := 30.0
## Trauma drained per second.
@export var recovery := 1.8
## Impacts at least this strong also buzz the phone.
@export var vibrate_from := 0.45
## Game speed during a hit-stop. Not zero, so nothing waiting on a timer gets stuck.
@export var freeze_scale := 0.05

var trauma := 0.0

var _noise := FastNoiseLite.new()
var _noise_t := 0.0
## Bumped by every hit-stop so only the latest one lets go of the freeze.
var _freeze_serial := 0


func _ready() -> void:
	anchor_mode = ANCHOR_MODE_FIXED_TOP_LEFT
	_noise.frequency = 0.6


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## `strength` 0..1 is added to the trauma; `freeze` seconds of hit-stop on top, if any.
func impact(strength: float, freeze := 0.0) -> void:
	trauma = minf(trauma + strength, 1.0)
	if strength >= vibrate_from:
		Input.vibrate_handheld(roundi(30 + 70 * minf(strength, 1.0)))
	if freeze > 0.0:
		_hit_stop(freeze)


func _process(delta: float) -> void:
	# Shake and its recovery run in real time, so the screen still rocks through a hit-stop.
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	if trauma <= 0.0:
		offset = Vector2.ZERO
		return
	trauma = maxf(trauma - recovery * real_delta, 0.0)
	_noise_t += real_delta * 30.0
	var amount := max_offset * trauma * trauma
	offset = Vector2(_noise.get_noise_2d(_noise_t, 0.0), _noise.get_noise_2d(0.0, _noise_t)) * amount * 2.0


## Runs the game at `time_scale` for `seconds` of real time: the slow-motion of a critical hit.
func slow_motion(time_scale: float, seconds: float) -> void:
	_freeze_serial += 1
	var serial := _freeze_serial
	Engine.time_scale = time_scale
	await get_tree().create_timer(seconds, true, false, true).timeout
	if serial == _freeze_serial:
		Engine.time_scale = 1.0


func _hit_stop(seconds: float) -> void:
	_freeze_serial += 1
	var serial := _freeze_serial
	Engine.time_scale = freeze_scale
	await get_tree().create_timer(seconds, true, false, true).timeout
	if serial == _freeze_serial:
		Engine.time_scale = 1.0
