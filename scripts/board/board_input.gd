class_name BoardInput
extends Node
## Touch (or mouse): press on a square to start a link, drag through neighbors of the same color,
## drag back to undo the last square, release to play it. Tap after a fight to go on.
## Keys: R restarts, T switches tile theme (debug until encounters pick it), M mutes sound.

## How close (as a fraction of a square) a finger must come to a square's center to take it.
const PICK_REACH := 0.42

@export var view: BoardView

var _last_pos := Vector2.ZERO
var _pressed := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				view.new_game()
			KEY_T:
				view.next_tile_theme()
			KEY_M:
				Sfx.muted = not Sfx.muted
	elif event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag and _pressed:
		_on_drag(event)


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if view.is_finished():
			view.new_game()
			return
		_last_pos = view.to_local(event.position)
		if view.hammer_armed:
			# The hammer comes down where the finger lands; a tap off the board puts it away.
			var target := view.cell_at(_last_pos)
			if target.x >= 0:
				view.smash_at(target)
			else:
				view.hammer_armed = false
			return
		_pressed = true
		view.begin_link(view.cell_at(_last_pos, PICK_REACH))
	elif _pressed:
		_pressed = false
		view.end_link()


## A fast swipe can skip past squares between two drag events, so walk the gap in small steps.
func _on_drag(event: InputEventScreenDrag) -> void:
	var to := view.to_local(event.position)
	var steps := maxi(1, ceili(_last_pos.distance_to(to) / (BoardView.CELL * 0.25)))
	for i in range(1, steps + 1):
		var p := view.cell_at(_last_pos.lerp(to, float(i) / steps), PICK_REACH)
		if p.x >= 0:
			view.extend_link(p)
	_last_pos = to
