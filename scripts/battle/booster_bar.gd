class_name BoosterBar
extends Node2D
## The boosters the hero brought (Boosters), as a row of round buttons between the board and
## the rage bar, each with how many are left. A tap asks for one with `pressed`; the
## BattleManager decides whether it goes off. The hammer stays lit while it's in hand.
## Keys 1–4 do the same.
##
## Art, if present: assets/ui/boosters/<id>.png for each button. Without it they're drawn.

signal pressed(id: String)

const ART_DIR := "res://assets/ui/boosters/"
const FIRST := Vector2(78, 6)
const GAP := 104.0
const RADIUS := 36.0
const RIM := 4.0

const RIM_COLOR := Color(0.17, 0.1, 0.05)
const FACE := Color(0.3, 0.2, 0.12)
const FACE_OFF := Color(0.12, 0.09, 0.07)
const GOLD := Color(1, 0.82, 0.3)
const TEXT := Color(0.97, 0.95, 0.9)
const OUTLINE := Color(0.1, 0.07, 0.05)

## How many of each the hero has, by Boosters id.
var counts := {}
## Which can be used right now, by id.
var usable := {}
## The hammer is in hand.
var armed := ""
var _art := {}
var _nudge := {}


func _ready() -> void:
	for id: String in Boosters.ORDER:
		var path := ART_DIR + id + ".png"
		_art[id] = load(path) if ResourceLoader.exists(path) else null


func show_counts(p_counts: Dictionary, p_usable: Dictionary) -> void:
	counts = p_counts
	usable = p_usable
	queue_redraw()


## A booster that can't be used now shakes its head.
func refuse(id: String) -> void:
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		_nudge[id] = sin(t * TAU * 3.0) * 8.0 * (1.0 - t)
		queue_redraw(), 0.0, 1.0, 0.35)


func center_of(id: String) -> Vector2:
	return FIRST + Vector2(GAP * Boosters.ORDER.find(id), 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var at := to_local(event.position)
		for id: String in Boosters.ORDER:
			if at.distance_to(center_of(id)) <= RADIUS + RIM + 6:
				get_viewport().set_input_as_handled()
				pressed.emit(id)
				return
	elif event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.keycode - KEY_1
		if index >= 0 and index < Boosters.ORDER.size():
			get_viewport().set_input_as_handled()
			pressed.emit(Boosters.ORDER[index])


func _process(_delta: float) -> void:
	if armed:
		queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)
	for id: String in Boosters.ORDER:
		var center := center_of(id) + Vector2(float(_nudge.get(id, 0.0)), 0)
		var count := int(counts.get(id, 0))
		var on: bool = count > 0 and usable.get(id, false)
		var radius := RADIUS * (1.08 if armed == id else 1.0)
		draw_circle(center + Vector2(0, 4), radius + RIM, Color(0, 0, 0, 0.35))
		draw_circle(center, radius + RIM, GOLD.lerp(Color.WHITE, pulse * 0.5) if armed == id else RIM_COLOR)
		draw_circle(center, radius, FACE if on else FACE_OFF)
		var tint := Color.WHITE if on else Color(0.45, 0.45, 0.5)
		if _art[id]:
			var size := Vector2.ONE * radius * 1.7
			draw_texture_rect(_art[id], Rect2(center - size / 2, size), false, tint)
		else:
			draw_icon(self, id, center, radius * 0.6, tint)
		# How many are left, on a badge at the lower right.
		var badge := center + Vector2(radius * 0.72, radius * 0.62)
		draw_circle(badge, 15, RIM_COLOR)
		draw_circle(badge, 12, GOLD if count > 0 else Color(0.35, 0.33, 0.3))
		var text := str(count)
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(font, badge + Vector2(-width / 2, 7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, OUTLINE)


## A plain emblem for booster `id` in a circle of `size` at `center`, until there's art.
## The forge uses it too.
static func draw_icon(canvas: CanvasItem, id: String, center: Vector2, size: float, tint := Color.WHITE) -> void:
	var dark := Color(0.12, 0.08, 0.05, tint.a)
	match id:
		"hammer":
			canvas.draw_set_transform(center, -0.6, Vector2.ONE)
			canvas.draw_rect(Rect2(Vector2(-size * 0.12, -size * 0.3), Vector2(size * 0.24, size * 1.3)), Color(0.62, 0.4, 0.2) * tint)
			canvas.draw_rect(Rect2(Vector2(-size * 0.7, -size * 0.85), Vector2(size * 1.4, size * 0.6)).grow(3), dark)
			canvas.draw_rect(Rect2(Vector2(-size * 0.7, -size * 0.85), Vector2(size * 1.4, size * 0.6)), Color(0.7, 0.72, 0.78) * tint)
			canvas.draw_set_transform(Vector2.ZERO)
		"shuffle":
			for k in 2:
				var side := 1.0 if k == 0 else -1.0
				var from := center + Vector2(-size * 0.8, -size * 0.45 * side)
				var to := center + Vector2(size * 0.6, size * 0.45 * side)
				canvas.draw_line(from, to, Color(0.55, 0.85, 1.0) * tint, size * 0.22)
				canvas.draw_colored_polygon(PackedVector2Array([to + Vector2(size * 0.35, 0), to + Vector2(-size * 0.1, -size * 0.3), to + Vector2(-size * 0.1, size * 0.3)]), Color(0.55, 0.85, 1.0) * tint)
		"potion":
			canvas.draw_rect(Rect2(center + Vector2(-size * 0.18, -size * 0.95), Vector2(size * 0.36, size * 0.45)), Color(0.85, 0.75, 0.6) * tint)
			canvas.draw_circle(center + Vector2(0, size * 0.25), size * 0.7 + 3, dark)
			canvas.draw_circle(center + Vector2(0, size * 0.25), size * 0.7, Color(0.9, 0.2, 0.3) * tint)
			canvas.draw_circle(center + Vector2(-size * 0.25, 0), size * 0.18, Color(1, 1, 1, 0.6 * tint.a))
		"opening_bombs":
			canvas.draw_circle(center + Vector2(0, size * 0.15), size * 0.75 + 3, dark)
			canvas.draw_circle(center + Vector2(0, size * 0.15), size * 0.75, Color(0.22, 0.22, 0.28) * tint)
			canvas.draw_line(center + Vector2(size * 0.35, -size * 0.45), center + Vector2(size * 0.7, -size * 0.95), Color(0.85, 0.7, 0.45) * tint, 4.0)
			canvas.draw_circle(center + Vector2(size * 0.72, -size * 0.98), size * 0.2, Color(1, 0.7, 0.2) * tint)
