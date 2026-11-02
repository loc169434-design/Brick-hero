class_name BattleView
extends Node2D
## The fight above the board: backdrop, hero and monster (CharacterRig), health bars, shield
## layers, the monster's countdown, tutorial hints and floating numbers.
## play_report() turns one move's TurnReport into a short scene: the hero strikes, the monster
## flinches or panics, the monster strikes back and gloats, and so on.

const SIZE := Vector2(1080, 660)
## Where each fighter's feet touch the ground.
const HERO_FEET := Vector2(270, 470)
const MONSTER_FEET := Vector2(810, 470)
const BAR_SIZE := Vector2(400, 26)
const FLOAT_TIME := 1.1
const HERO_ID := "hero_rookie"

const BG := Color(0.13, 0.16, 0.22)
const GROUND := Color(0.17, 0.2, 0.16)
const TEXT := Color(0.92, 0.92, 0.96)
const TEXT_DIM := Color(0.6, 0.6, 0.7)
const HP_HERO := Color(0.35, 0.75, 0.4)
const HP_MONSTER := Color(0.85, 0.3, 0.3)
const BAR_BACK := Color(0, 0, 0, 0.5)
const SHIELD := Color(0.62, 0.42, 0.85)
const GOLD := Color(0.98, 0.8, 0.25)
const WARN := Color(0.95, 0.3, 0.25)
const OUTLINE := Color(0.1, 0.07, 0.05)
const OUTLINE_SIZE := 8

var _state: BattleState
var _background: Texture2D
var _hero: CharacterRig
var _monster: CharacterRig
## Drawn above the fighters.
var _overlay: Node2D
var _hint := ""
## { "text", "at", "color", "t" }
var _floaters: Array[Dictionary] = []
## Bumped per fight so a scene still playing from the last fight stops.
var _fight := 0


func _ready() -> void:
	_hero = CharacterRig.new()
	_hero.position = HERO_FEET
	add_child(_hero)
	_monster = CharacterRig.new()
	_monster.position = MONSTER_FEET
	add_child(_monster)
	_overlay = Node2D.new()
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)


func show_state(state: BattleState) -> void:
	_fight += 1
	_state = state
	_floaters.clear()
	_hint = ""
	var bg_path := "res://assets/bg/%s.png" % state.monster.background
	_background = load(bg_path) if state.monster.background and ResourceLoader.exists(bg_path) else null
	_hero.setup(HERO_ID, 1)
	_monster.setup(state.monster.id, -1, state.shield_layers() if state.monster.shield_layers > 0 else -1)
	_redraw()


func show_hint(text: String) -> void:
	_hint = text
	_overlay.queue_redraw()


func play_report(report: TurnReport) -> void:
	var fight := _fight
	var big_play := report.chain >= 3 or report.link_length >= 6

	if report.damage > 0 or report.shield_damage > 0:
		await _hero.attack()
		if fight != _fight:
			return
		_monster.react(&"hurt")
		_monster.set_health(_state.monster_health())
		_monster.set_shield_layers(_state.shield_layers())
		if report.shield_damage > 0:
			_float("KHIÊN -%d" % report.shield_damage, MONSTER_FEET + Vector2(0, -260), SHIELD)
		if report.damage > 0:
			_float("-%d" % report.damage, MONSTER_FEET + Vector2(0, -190), HP_MONSTER.lightened(0.3))
	if report.heal > 0:
		_float("+%d" % report.heal, HERO_FEET + Vector2(0, -230), HP_HERO.lightened(0.3))
		_hero.set_health(_state.hero_health())
	if report.gold > 0:
		_float("+%d VÀNG" % report.gold, Vector2(190, 230), GOLD)
	_redraw()

	match report.outcome:
		BattleState.Outcome.WON:
			await get_tree().create_timer(0.35).timeout
			if fight == _fight:
				_monster.finish(false)
				_hero.finish(true)
			return
		BattleState.Outcome.LOST:
			if report.monster_attack > 0:
				await _monster_strikes(report, fight)
			if fight == _fight:
				_hero.finish(false)
				_monster.finish(true)
			return

	if big_play:
		_hero.react(&"cheer")
		_monster.react(&"scared", 1.2)
	elif report.damage > 0 and _state.monster_health() <= 0.3:
		_monster.react(&"scared", 1.2)
	elif report.damage == 0 and report.shield_damage == 0 and _state.monster.counterattacks:
		# Nothing that hurts it: green and yellow only.
		_monster.react(&"cheer")

	if report.monster_attack > 0:
		await get_tree().create_timer(0.45).timeout
		if fight != _fight:
			return
		await _monster_strikes(report, fight)
		if fight != _fight:
			return
		_monster.react(&"cheer")
	elif _state.attacks_next_move() and _state.hero_health() <= 0.3:
		_hero.react(&"scared", 0.0)


func _monster_strikes(report: TurnReport, fight: int) -> void:
	await _monster.attack()
	if fight != _fight:
		return
	_hero.react(&"hurt")
	_hero.set_health(_state.hero_health())
	_float("-%d" % report.monster_attack, HERO_FEET + Vector2(0, -230), WARN)
	_redraw()


func _float(text: String, at: Vector2, color: Color) -> void:
	var floater := {"text": text, "at": at, "color": color, "t": 0.0}
	_floaters.append(floater)
	var tween := create_tween()
	tween.tween_method(_set_floater_t.bind(floater), 0.0, 1.0, FLOAT_TIME)
	tween.tween_callback(func() -> void: _floaters.erase(floater))


func _set_floater_t(t: float, floater: Dictionary) -> void:
	floater["t"] = t
	_overlay.queue_redraw()


func _redraw() -> void:
	queue_redraw()
	_overlay.queue_redraw()


# --- drawing ---------------------------------------------------------------

func _draw() -> void:
	if _background:
		draw_texture_rect(_background, Rect2(Vector2.ZERO, SIZE), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, SIZE), BG)
		draw_rect(Rect2(0, HERO_FEET.y, SIZE.x, SIZE.y - HERO_FEET.y), GROUND)


## Above the fighters: bars, shield, countdown, gold, hint, floating numbers.
func _draw_overlay() -> void:
	if not _state:
		return
	var bar_y := SIZE.y - 110
	_draw_bar(Vector2(40, bar_y), _state.hero_hp, _state.rules.hero_max_hp, HP_HERO, "HIỆP SĨ")
	var monster_bar := Vector2(SIZE.x - 40 - BAR_SIZE.x, bar_y)
	_draw_bar(monster_bar, _state.monster_hp, _state.monster.max_hp, HP_MONSTER, _state.monster.display_name.to_upper())
	_draw_shield_layers(monster_bar + Vector2(0, BAR_SIZE.y + 50))
	if _state.outcome == BattleState.Outcome.ONGOING and _state.monster.counterattacks:
		_draw_countdown(MONSTER_FEET + Vector2(170, -360))
	_draw_text("VÀNG %d" % _state.gold, Vector2(40, 160), 40, GOLD)
	if _hint:
		var box := Rect2(30, 20, SIZE.x - 60, 96)
		_overlay.draw_rect(box, Color(0, 0, 0, 0.55))
		_overlay.draw_multiline_string(ThemeDB.fallback_font, box.position + Vector2(20, 40), _hint, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 40, 32, 2, TEXT)
	for floater in _floaters:
		var t: float = floater["t"]
		var color: Color = floater["color"]
		_draw_text_centered(floater["text"], floater["at"] + Vector2(0, -90 * t), 64, Color(color, 1.0 - t * t))


func _draw_bar(at: Vector2, value: int, max_value: int, color: Color, label: String) -> void:
	_overlay.draw_rect(Rect2(at, BAR_SIZE), BAR_BACK)
	var fill := clampf(float(value) / max_value, 0.0, 1.0)
	_overlay.draw_rect(Rect2(at, Vector2(BAR_SIZE.x * fill, BAR_SIZE.y)), color)
	_draw_text("%s  %d/%d" % [label, value, max_value], at + Vector2(0, -10), 32, TEXT)


## One box per layer; a damaged layer shows how much of it is left.
func _draw_shield_layers(at: Vector2) -> void:
	var size := _state.rules.shield_layer_size
	var total := _state.monster.shield_layers
	if total == 0:
		return
	_draw_text("KHIÊN", at + Vector2(0, -8), 28, TEXT_DIM)
	for i in total:
		var box := Rect2(at + Vector2(130 + i * 56, -34), Vector2(46, 34))
		var left := clampi(_state.shield - i * size, 0, size)
		_overlay.draw_rect(box, BAR_BACK)
		_overlay.draw_rect(Rect2(box.position, Vector2(box.size.x * left / size, box.size.y)), SHIELD)
		_overlay.draw_rect(box, SHIELD.lightened(0.3), false, 2)


## Moves left until the monster attacks; turns red one move ahead.
func _draw_countdown(center: Vector2) -> void:
	var warn := _state.attacks_next_move()
	_overlay.draw_circle(center, 40, WARN if warn else Color(0, 0, 0, 0.5))
	_overlay.draw_arc(center, 40, 0, TAU, 32, TEXT, 3)
	_draw_text_centered(str(_state.countdown), center + Vector2(0, 16), 48, TEXT)
	if warn:
		_draw_text_centered("SẮP ĐÁNH %d!" % _state.monster.attack, center + Vector2(-50, -55), 34, WARN.lightened(0.3))


## Text sits on painted backgrounds, so it gets a dark outline to stay readable.
func _draw_text(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	_overlay.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE_SIZE, Color(OUTLINE, color.a))
	_overlay.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_text_centered(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_text(text, at - Vector2(width / 2, 0), font_size, color)
