class_name BattleView
extends Node2D
## The fight above the board: hero and monster, health bars, shield layers, the monster's
## countdown and floating numbers. Placeholder shapes stand in until art lands at
## assets/characters/hero_idle.png and assets/monsters/<id>_idle.png (docs/core_plan.md, section 5).
## Each fighter is its own child node so it can lunge and fade without redrawing the rest.

const SIZE := Vector2(1000, 600)
## Where each fighter's feet touch the ground.
const HERO_FEET := Vector2(230, 430)
const MONSTER_FEET := Vector2(770, 430)
const ART_SIZE := 360.0
const BAR_SIZE := Vector2(380, 26)
const FLOAT_TIME := 1.1

const BG := Color(0.13, 0.16, 0.22)
const GROUND := Color(0.17, 0.2, 0.16)
const TEXT := Color(0.92, 0.92, 0.96)
const TEXT_DIM := Color(0.6, 0.6, 0.7)
const HP_HERO := Color(0.35, 0.75, 0.4)
const HP_MONSTER := Color(0.85, 0.3, 0.3)
const BAR_BACK := Color(0, 0, 0, 0.45)
const SHIELD := Color(0.62, 0.42, 0.85)
const GOLD := Color(0.98, 0.8, 0.25)
const WARN := Color(0.95, 0.3, 0.25)

var _state: BattleState
var _hero_art: Texture2D
var _monster_art: Texture2D
var _hero: Node2D
var _monster: Node2D
## Drawn above the fighters.
var _overlay: Node2D
var _monster_flash := 0.0
var _hero_flash := 0.0
## { "text", "at", "color", "t" }
var _floaters: Array[Dictionary] = []


func _ready() -> void:
	_hero = _add_layer(HERO_FEET, _draw_hero)
	_monster = _add_layer(MONSTER_FEET, _draw_monster)
	_overlay = _add_layer(Vector2.ZERO, _draw_floaters)


func show_state(state: BattleState) -> void:
	_state = state
	_floaters.clear()
	_hero_art = _load_if_exists("res://assets/characters/hero_idle.png")
	_monster_art = _load_if_exists("res://assets/monsters/%s_idle.png" % state.monster.id)
	for fighter: Node2D in [_hero, _monster]:
		fighter.modulate = Color.WHITE
	_hero.position = HERO_FEET
	_monster.position = MONSTER_FEET
	_redraw()


func play_report(report: TurnReport) -> void:
	var above_monster := MONSTER_FEET + Vector2(0, -300)
	var above_hero := HERO_FEET + Vector2(0, -300)
	if report.shield_damage > 0:
		_float("SHIELD -%d" % report.shield_damage, above_monster + Vector2(0, -50), SHIELD)
	if report.damage > 0:
		_float("-%d" % report.damage, above_monster, HP_MONSTER.lightened(0.3))
		create_tween().tween_method(_set_monster_flash, 1.0, 0.0, 0.35)
	if report.heal > 0:
		_float("+%d" % report.heal, above_hero, HP_HERO.lightened(0.3))
	if report.gold > 0:
		_float("+%d GOLD" % report.gold, Vector2(150, 110), GOLD)
	if report.monster_attack > 0:
		var tween := create_tween()
		tween.tween_property(_monster, "position:x", MONSTER_FEET.x - 260, 0.15).set_ease(Tween.EASE_IN)
		tween.tween_callback(_on_monster_strike.bind(report.monster_attack))
		tween.tween_property(_monster, "position:x", MONSTER_FEET.x, 0.25).set_ease(Tween.EASE_OUT)
	match report.outcome:
		BattleState.Outcome.WON:
			_fall(_monster)
		BattleState.Outcome.LOST:
			_fall(_hero)
	_redraw()


func _on_monster_strike(amount: int) -> void:
	_float("-%d" % amount, HERO_FEET + Vector2(0, -300), WARN)
	create_tween().tween_method(_set_hero_flash, 1.0, 0.0, 0.35)


## The loser sinks and fades out.
func _fall(fighter: Node2D) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(fighter, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.tween_property(fighter, "position:y", fighter.position.y + 40, 0.8).set_delay(0.3)


func _float(text: String, at: Vector2, color: Color) -> void:
	var floater := {"text": text, "at": at, "color": color, "t": 0.0}
	_floaters.append(floater)
	var tween := create_tween()
	tween.tween_method(_set_floater_t.bind(floater), 0.0, 1.0, FLOAT_TIME)
	tween.tween_callback(func() -> void: _floaters.erase(floater))


func _set_floater_t(t: float, floater: Dictionary) -> void:
	floater["t"] = t
	_overlay.queue_redraw()


func _set_monster_flash(v: float) -> void:
	_monster_flash = v
	_monster.queue_redraw()


func _set_hero_flash(v: float) -> void:
	_hero_flash = v
	_hero.queue_redraw()


func _add_layer(at: Vector2, drawer: Callable) -> Node2D:
	var layer := Node2D.new()
	layer.position = at
	add_child(layer)
	layer.draw.connect(drawer)
	return layer


func _redraw() -> void:
	queue_redraw()
	for layer: Node2D in [_hero, _monster, _overlay]:
		layer.queue_redraw()


func _load_if_exists(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


# --- drawing ---------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), BG)
	draw_rect(Rect2(0, HERO_FEET.y, SIZE.x, SIZE.y - HERO_FEET.y), GROUND)
	if not _state:
		return

	var bar_y := HERO_FEET.y + 50
	_draw_bar(Vector2(40, bar_y), _state.hero_hp, _state.rules.hero_max_hp, HP_HERO, "HERO")
	var monster_bar := Vector2(SIZE.x - 40 - BAR_SIZE.x, bar_y)
	_draw_bar(monster_bar, _state.monster_hp, _state.monster.max_hp, HP_MONSTER, _state.monster.display_name.to_upper())
	_draw_shield_layers(monster_bar + Vector2(0, BAR_SIZE.y + 50))
	_draw_text(self, "GOLD %d" % _state.gold, Vector2(30, 60), 40, GOLD)


## Hero layer: origin at the hero's feet.
func _draw_hero() -> void:
	if not _state:
		return
	if _hero_art:
		_draw_art(_hero, _hero_art, Color(1, 0.3, 0.3, _hero_flash * 0.5))
		return
	var body := Rect2(Vector2(-45, -150), Vector2(90, 150))
	_hero.draw_rect(body, Color(0.25, 0.4, 0.75))
	_hero.draw_circle(Vector2(0, -190), 42, Color(0.95, 0.8, 0.65))
	_hero.draw_line(Vector2(55, -90), Vector2(130, -230), Color(0.85, 0.87, 0.9), 12)
	_hero.draw_circle(Vector2(-55, -85), 38, Color(0.55, 0.35, 0.2))
	if _hero_flash > 0.0:
		_hero.draw_rect(body.grow(30), Color(1, 0.3, 0.3, _hero_flash * 0.5))


## Monster layer: origin at the monster's feet. It faces left, toward the hero.
func _draw_monster() -> void:
	if not _state:
		return
	if _monster_art:
		_draw_art(_monster, _monster_art, Color(1, 1, 1, _monster_flash * 0.6))
	else:
		var body := Rect2(Vector2(-80, -170), Vector2(160, 170))
		_monster.draw_rect(body, Color(0.4, 0.6, 0.3))
		var head := Vector2(0, -235)
		_monster.draw_circle(head, 65, Color(0.48, 0.68, 0.35))
		_monster.draw_colored_polygon(PackedVector2Array([head + Vector2(-35, 25), head + Vector2(-25, 55), head + Vector2(-15, 25)]), Color.WHITE)
		_monster.draw_colored_polygon(PackedVector2Array([head + Vector2(15, 25), head + Vector2(25, 55), head + Vector2(35, 25)]), Color.WHITE)
		if _monster_flash > 0.0:
			_monster.draw_rect(body.merge(Rect2(head - Vector2(65, 65), Vector2(130, 130))), Color(1, 1, 1, _monster_flash * 0.6))
	if _state.shield > 0:
		var plate := Rect2(Vector2(-150, -190), Vector2(70, 160))
		_monster.draw_rect(plate, Color(0.45, 0.3, 0.18))
		_monster.draw_rect(plate, SHIELD, false, 6)


## Art stands on the layer's origin; `flash` is drawn over it as a tinted copy.
func _draw_art(layer: Node2D, texture: Texture2D, flash: Color) -> void:
	var rect := Rect2(Vector2(-ART_SIZE / 2, -ART_SIZE), Vector2(ART_SIZE, ART_SIZE))
	layer.draw_texture_rect(texture, rect, false)
	if flash.a > 0.0:
		layer.draw_texture_rect(texture, rect, false, flash)


## Overlay layer: the countdown and floating numbers, above both fighters.
func _draw_floaters() -> void:
	if _state and _state.outcome == BattleState.Outcome.ONGOING:
		_draw_countdown(MONSTER_FEET + Vector2(150, -320))
	for floater in _floaters:
		var t: float = floater["t"]
		var color: Color = floater["color"]
		_draw_text_centered(_overlay, floater["text"], floater["at"] + Vector2(0, -90 * t), 64, Color(color, 1.0 - t * t))


func _draw_bar(at: Vector2, value: int, max_value: int, color: Color, label: String) -> void:
	draw_rect(Rect2(at, BAR_SIZE), BAR_BACK)
	var fill := clampf(float(value) / max_value, 0.0, 1.0)
	draw_rect(Rect2(at, Vector2(BAR_SIZE.x * fill, BAR_SIZE.y)), color)
	_draw_text(self, "%s  %d/%d" % [label, value, max_value], at + Vector2(0, -10), 32, TEXT)


## One box per layer; a damaged layer shows how much of it is left.
func _draw_shield_layers(at: Vector2) -> void:
	var size := _state.rules.shield_layer_size
	var total := _state.monster.shield_layers
	if total == 0:
		return
	_draw_text(self, "SHIELD", at + Vector2(0, -8), 28, TEXT_DIM)
	for i in total:
		var box := Rect2(at + Vector2(130 + i * 56, -34), Vector2(46, 34))
		var left := clampi(_state.shield - i * size, 0, size)
		draw_rect(box, BAR_BACK)
		draw_rect(Rect2(box.position, Vector2(box.size.x * left / size, box.size.y)), SHIELD)
		draw_rect(box, SHIELD.lightened(0.3), false, 2)


## Drops left until the monster attacks; turns red one drop ahead.
func _draw_countdown(center: Vector2) -> void:
	var warn := _state.attacks_next_drop()
	_overlay.draw_circle(center, 40, WARN if warn else Color(0, 0, 0, 0.5))
	_overlay.draw_arc(center, 40, 0, TAU, 32, TEXT, 3)
	_draw_text_centered(_overlay, str(_state.countdown), center + Vector2(0, 16), 48, TEXT)
	if warn:
		_draw_text_centered(_overlay, "ATTACK %d!" % _state.monster.attack, center + Vector2(-30, -55), 34, WARN.lightened(0.3))


func _draw_text(canvas: CanvasItem, text: String, at: Vector2, font_size: int, color: Color) -> void:
	canvas.draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_text_centered(canvas: CanvasItem, text: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, at - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
