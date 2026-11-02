class_name BoardInput
extends Node
## Turns touches and keys into board commands.
## Touch: drag sideways to slide the piece, tap to turn it, swipe down to drop, tap HOLD to hold.
## Keys: Left/Right move, Up or X turns, Z turns back, Space or Down drops, C holds, R restarts.

const TAP_DISTANCE := 24.0
const DROP_SWIPE := 140.0

@export var view: BoardView

var _pressed := false
var _start := Vector2.ZERO
var _start_column := 0
var _slid := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_on_key(event)
	elif event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag and _pressed:
		_on_drag(event)


func _on_key(event: InputEventKey) -> void:
	if not event.pressed:
		return
	var repeatable := event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT
	if event.echo and not repeatable:
		return
	match event.keycode:
		KEY_LEFT:
			view.try_move(-1)
		KEY_RIGHT:
			view.try_move(1)
		KEY_UP, KEY_X:
			view.try_rotate(true)
		KEY_Z:
			view.try_rotate(false)
		KEY_SPACE, KEY_DOWN:
			view.try_drop()
		KEY_C:
			view.try_hold()
		KEY_R:
			view.new_game()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_pressed = true
		_slid = false
		_start = event.position
		_start_column = view.game.origin.x
		return
	if not _pressed:
		return
	_pressed = false
	var delta := event.position - _start
	if delta.y > DROP_SWIPE and delta.y > absf(delta.x):
		view.try_drop()
	elif not _slid and delta.length() < TAP_DISTANCE:
		_on_tap(event.position)


func _on_drag(event: InputEventScreenDrag) -> void:
	var dx := event.position.x - _start.x
	if absf(dx) > TAP_DISTANCE:
		_slid = true
	view.try_slide_to(_start_column + roundi(dx / BoardView.CELL))


func _on_tap(screen_pos: Vector2) -> void:
	if view.game.is_over:
		view.new_game()
	elif view.hold_rect().has_point(view.to_local(screen_pos)):
		view.try_hold()
	else:
		view.try_rotate(true)
