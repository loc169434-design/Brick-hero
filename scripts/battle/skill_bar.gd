class_name SkillBar
extends Node2D
## The hero's rage bar and skill button, in the strip under the board where a thumb rests.
## The bar fills as squares clear; full, the button lights up and a tap (or Space) asks for the
## skill with `pressed`. The BattleManager decides whether it goes off.
## K switches the skill (to try them until the forge picks one).
##
## Art, if present: assets/ui/rage_bar_frame.png and rage_bar_fill.png for the bar,
## assets/ui/skill_<id>.png for the button. Without it both are drawn.

## The skill button was tapped.
signal pressed

const UI_DIR := "res://assets/ui/"
const BAR := Rect2(40, 92, 760, 34)
const BAR_RADIUS := 10
const BAR_RIM := 4
const BUTTON_CENTER := Vector2(935, 105)
const BUTTON_RADIUS := 82.0
## The button's ring of progress, outside its rim.
const RING_WIDTH := 10.0
const LABEL_SIZE := 26
## The bar's fill slides to a new value over this long.
const FILL_TIME := 0.45

const RAGE := Color(1.0, 0.5, 0.1)
const RAGE_HOT := Color(1.0, 0.85, 0.3)
const RIM := Color(0.17, 0.1, 0.05)
const EMPTY := Color(0.08, 0.05, 0.04, 0.92)
const TEXT := Color(0.92, 0.92, 0.96)
const TEXT_DIM := Color(0.6, 0.6, 0.7)
const OUTLINE := Color(0.1, 0.07, 0.05)

var state: BattleState

## The rage the bar shows, sliding toward state.rage.
var _shown := 0.0
var _fill_tween: Tween
## Shakes the button when it's tapped before it's charged.
var _nudge := 0.0
var _box := StyleBoxFlat.new()
var _frame: Texture2D
var _fill: Texture2D
## Skill id -> its button art, or null.
var _icons := {}


func _ready() -> void:
	_frame = _load(UI_DIR + "rage_bar_frame.png")
	_fill = _load(UI_DIR + "rage_bar_fill.png")
	_box.shadow_color = Color(0, 0, 0, 0.35)


func show_state(p_state: BattleState) -> void:
	state = p_state
	if _fill_tween:
		_fill_tween.kill()
	_shown = state.rage
	queue_redraw()


## Slides the bar to the state's rage after a move or a skill.
func refresh() -> void:
	if not state:
		return
	if _fill_tween:
		_fill_tween.kill()
	_fill_tween = create_tween()
	_fill_tween.tween_method(func(v: float) -> void: _shown = v, _shown, float(state.rage), FILL_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## The skill isn't charged: the button shakes its head.
func refuse() -> void:
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: _nudge = sin(t * TAU * 3.0) * 10.0 * (1.0 - t), 0.0, 1.0, 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if not state or state.outcome != BattleState.Outcome.ONGOING:
		return
	if event is InputEventScreenTouch and event.pressed:
		if to_local(event.position).distance_to(BUTTON_CENTER) <= BUTTON_RADIUS + RING_WIDTH:
			get_viewport().set_input_as_handled()
			pressed.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				get_viewport().set_input_as_handled()
				pressed.emit()
			KEY_K:
				get_viewport().set_input_as_handled()
				var ids := BattleState.SKILLS.keys()
				state.rules.skill = ids[(ids.find(state.rules.skill) + 1) % ids.size()]


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not state:
		return
	var fraction := clampf(_shown / state.rules.rage_max, 0.0, 1.0)
	var charged := state.skill_ready()
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)
	_draw_bar(fraction, charged, pulse)
	_draw_button(fraction, charged, pulse)


## A framed bar like the health bars above, filling with fire; full, it glows and throbs.
func _draw_bar(fraction: float, charged: bool, pulse: float) -> void:
	_text("NỘ", BAR.position + Vector2(4, -12), LABEL_SIZE, RAGE_HOT)
	var count := "%d/%d" % [roundi(_shown), state.rules.rage_max]
	_text(count, BAR.position + Vector2(BAR.size.x - _width(count, LABEL_SIZE) - 4, -12), LABEL_SIZE, TEXT)
	if _frame and _fill:
		draw_texture_rect(_frame, BAR.grow(BAR_RIM), false)
		var source := Rect2(Vector2.ZERO, Vector2(_fill.get_width() * fraction, _fill.get_height()))
		draw_texture_rect_region(_fill, Rect2(BAR.position, Vector2(BAR.size.x * fraction, BAR.size.y)), source)
		return
	_rounded(BAR.grow(BAR_RIM), RIM, BAR_RADIUS + BAR_RIM, 6)
	_rounded(BAR, EMPTY, BAR_RADIUS)
	var filled := Rect2(BAR.position, Vector2(BAR.size.x * fraction, BAR.size.y))
	_rounded(filled, RAGE.lerp(RAGE_HOT, pulse * 0.6) if charged else RAGE, BAR_RADIUS)
	_rounded(Rect2(filled.position + Vector2(5, 4), Vector2(filled.size.x - 10, BAR.size.y * 0.3)), Color(1, 1, 1, 0.3), 4)


## A round button: dim with a ring of progress around it while the bar fills, then bright,
## swelling and ringed with fire. Its name sits underneath.
func _draw_button(fraction: float, charged: bool, pulse: float) -> void:
	var center := BUTTON_CENTER + Vector2(_nudge, 0)
	var radius := BUTTON_RADIUS * (1.0 + (0.05 * pulse if charged else 0.0))
	draw_circle(center + Vector2(0, 6), radius + BAR_RIM + RING_WIDTH, Color(0, 0, 0, 0.35))
	draw_circle(center, radius + BAR_RIM + RING_WIDTH, RIM)
	if charged:
		draw_arc(center, radius + RING_WIDTH / 2, 0, TAU, 64, RAGE.lerp(RAGE_HOT, pulse), RING_WIDTH, true)
	elif fraction > 0.0:
		draw_arc(center, radius + RING_WIDTH / 2, -PI / 2, -PI / 2 + TAU * fraction, 64, RAGE, RING_WIDTH, true)
	draw_circle(center, radius, Color(0.32, 0.12, 0.05) if charged else EMPTY)
	var icon := _icon(state.rules.skill)
	var tint := Color.WHITE if charged else Color(0.45, 0.45, 0.5)
	if icon:
		var size := Vector2.ONE * radius * 1.8
		draw_texture_rect(icon, Rect2(center - size / 2, size), false, tint)
	else:
		_draw_emblem(state.rules.skill, center, radius * 0.55, RAGE_HOT if charged else TEXT_DIM)
	var label: String = BattleState.SKILLS.get(state.rules.skill, "")
	_text(label, center + Vector2(-_width(label, LABEL_SIZE) / 2, -radius - RING_WIDTH - 12), LABEL_SIZE, RAGE_HOT if charged else TEXT_DIM)


## Stands in for the button art: a cracked shield for Phá Giáp, a cross for Hồi Quang.
func _draw_emblem(skill: String, center: Vector2, size: float, color: Color) -> void:
	match skill:
		"armor_breaker":
			var shield := PackedVector2Array([center + Vector2(-size, -size * 0.8), center + Vector2(size, -size * 0.8), center + Vector2(size * 0.85, size * 0.3), center + Vector2(0, size), center + Vector2(-size * 0.85, size * 0.3)])
			draw_colored_polygon(shield, color)
			draw_polyline(PackedVector2Array([center + Vector2(0.1 * size, -size * 0.8), center + Vector2(-0.2 * size, -0.1 * size), center + Vector2(0.2 * size, 0.2 * size), center + Vector2(-0.05 * size, size * 0.9)]), RIM, 7.0)
		"second_wind":
			draw_rect(Rect2(center - Vector2(size * 0.3, size), Vector2(size * 0.6, size * 2)), color)
			draw_rect(Rect2(center - Vector2(size, size * 0.3), Vector2(size * 2, size * 0.6)), color)


func _icon(skill: String) -> Texture2D:
	if not _icons.has(skill):
		_icons[skill] = _load("%sskill_%s.png" % [UI_DIR, skill])
	return _icons[skill]


func _rounded(rect: Rect2, color: Color, radius: int, shadow := 0) -> void:
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	_box.bg_color = color
	_box.set_corner_radius_all(radius)
	_box.shadow_size = shadow
	_box.shadow_offset = Vector2(0, shadow * 0.6)
	_box.draw(get_canvas_item(), rect)


## Text sits on painted backgrounds, so it gets a dark outline to stay readable.
func _text(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(OUTLINE, color.a))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _width(text: String, font_size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


static func _load(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null
