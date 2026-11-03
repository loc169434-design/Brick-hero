class_name BattleView
extends Node2D
## The fight above the board: backdrop, hero and monster (CharacterRig), health bars, shield
## layers, the monster's countdown, tutorial hints and floating numbers.
## play_report() turns one move's TurnReport into a short scene: the hero strikes, the monster
## flinches or panics, the monster strikes back and gloats, and so on. Each blow plays a sound
## and asks for screen shake (impact); health bars drain behind a pale trail.

## A blow landed: `strength` 0..1 of screen shake, `freeze` seconds of hit-stop.
signal impact(strength: float, freeze: float)

const SIZE := Vector2(1080, 660)
## Where each fighter's feet touch the ground.
const HERO_FEET := Vector2(270, 470)
const MONSTER_FEET := Vector2(810, 470)
const BAR_SIZE := Vector2(400, 26)
const FLOAT_TIME := 1.1
const FLOAT_SIZE := 64
## A health bar's pale trail waits this long after a hit, then catches up over TRAIL_TIME.
const TRAIL_DELAY := 0.35
const TRAIL_TIME := 0.4
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
var _backdrop: ArenaBackdrop
var _hero: CharacterRig
var _monster: CharacterRig
## Drawn above the fighters.
var _overlay: Node2D
var _hint := ""
## { "text", "at", "color", "size", "t" }
var _floaters: Array[Dictionary] = []
## Bumped per fight so a scene still playing from the last fight stops.
var _fight := 0
## Health the bars' trails still show, lagging behind the real values after a hit.
var _hero_trail := 0.0
var _monster_trail := 0.0
var _trail_tween: Tween


func _ready() -> void:
	_backdrop = ArenaBackdrop.new()
	add_child(_backdrop)
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
	if _backdrop.background != state.monster.background:
		_backdrop.load_background(state.monster.background)
	_hero.setup(HERO_ID, 1)
	_monster.setup(state.monster.id, -1, state.shield_layers() if state.monster.shield_layers > 0 else -1)
	if _trail_tween:
		_trail_tween.kill()
	_hero_trail = state.hero_hp
	_monster_trail = state.monster_hp
	_redraw()


## Where light from cleared tiles flies, by Cell.BlockColor, in global coordinates: red
## charges the hero's sword, green the health bar, yellow the gold counter, purple the
## monster's shield.
func orb_targets() -> Dictionary:
	return {
		Cell.BlockColor.RED: to_global(HERO_FEET + Vector2(90, -190)),
		Cell.BlockColor.GREEN: to_global(Vector2(40 + BAR_SIZE.x / 2, SIZE.y - 110 + BAR_SIZE.y / 2)),
		Cell.BlockColor.YELLOW: to_global(Vector2(110, 145)),
		Cell.BlockColor.PURPLE: to_global(MONSTER_FEET + Vector2(-110, -150)),
	}


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
		_hero_strike_feel(report)
		if report.shield_damage > 0:
			_float("KHIÊN -%d" % report.shield_damage, MONSTER_FEET + Vector2(0, -300), SHIELD)
		if report.damage > 0:
			# Bigger hits get bigger numbers.
			_float("-%d" % report.damage, MONSTER_FEET + Vector2(0, -190), HP_MONSTER.lightened(0.3), FLOAT_SIZE + mini(report.damage * 2, 56))
	if report.heal > 0:
		_float("+%d" % report.heal, HERO_FEET + Vector2(0, -230), HP_HERO.lightened(0.3))
		_hero.set_health(_state.hero_health())
		Sfx.play(&"heal")
	if report.gold > 0:
		_float("+%d VÀNG" % report.gold, Vector2(190, 310), GOLD)
		Sfx.play(&"coin", 1.0, -4.0)
	_drain_trails()

	match report.outcome:
		BattleState.Outcome.WON:
			await get_tree().create_timer(0.35).timeout
			if fight == _fight:
				_monster.finish(false)
				_hero.finish(true)
				Sfx.play(&"win")
			return
		BattleState.Outcome.LOST:
			if report.monster_attack > 0:
				await _monster_strikes(report, fight)
			if fight == _fight:
				_hero.finish(false)
				_monster.finish(true)
				Sfx.play(&"lose")
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
	if _state.attacks_next_move():
		Sfx.play(&"warn")


func _process(_delta: float) -> void:
	# The countdown pulses while the monster is winding up.
	if _state and _state.attacks_next_move():
		_overlay.queue_redraw()


func _monster_strikes(report: TurnReport, fight: int) -> void:
	await _monster.attack()
	if fight != _fight:
		return
	_hero.react(&"hurt")
	_hero.set_health(_state.hero_health())
	_float("-%d" % report.monster_attack, HERO_FEET + Vector2(0, -230), WARN, FLOAT_SIZE + 16)
	Sfx.play(&"thud")
	impact.emit(0.35 + minf(report.monster_attack / 40.0, 0.4), 0.06)
	_drain_trails()


## The hero's blow landing: heavier for bigger hits, a freeze-frame when a shield layer breaks,
## and the longest one on the killing blow.
func _hero_strike_feel(report: TurnReport) -> void:
	var strength := 0.25 + minf(report.damage / 40.0, 0.5)
	var freeze := 0.04
	if report.damage > 0:
		# Bigger hits sound lower and heavier.
		Sfx.play(&"hit", clampf(1.2 - report.damage / 60.0, 0.8, 1.2))
	if report.shield_damage > 0:
		Sfx.play(&"clang")
	if report.layers_broken > 0:
		Sfx.play(&"shatter")
		strength += 0.2
		freeze = 0.08
	if report.outcome == BattleState.Outcome.WON:
		strength = 1.0
		freeze = 0.18
	impact.emit(minf(strength, 1.0), freeze)


## Redraws the bars now, then lets their trails catch up after a beat.
func _drain_trails() -> void:
	_redraw()
	if _trail_tween:
		_trail_tween.kill()
	_trail_tween = create_tween().set_parallel()
	_trail_tween.tween_method(_set_hero_trail, _hero_trail, float(_state.hero_hp), TRAIL_TIME).set_delay(TRAIL_DELAY)
	_trail_tween.tween_method(_set_monster_trail, _monster_trail, float(_state.monster_hp), TRAIL_TIME).set_delay(TRAIL_DELAY)


func _set_hero_trail(value: float) -> void:
	_hero_trail = value
	_overlay.queue_redraw()


func _set_monster_trail(value: float) -> void:
	_monster_trail = value
	_overlay.queue_redraw()


## Rises from where it pops up, popping in oversized and settling before it fades.
## A little sideways scatter keeps numbers from the same move from stacking.
func _float(text: String, at: Vector2, color: Color, font_size := FLOAT_SIZE) -> void:
	at.x += randf_range(-30.0, 30.0)
	var floater := {"text": text, "at": at, "color": color, "size": font_size, "t": 0.0}
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

## Only shows when the encounter has no background art at all.
func _draw() -> void:
	if not _state or not _state.monster.background:
		draw_rect(Rect2(Vector2.ZERO, SIZE), BG)
		draw_rect(Rect2(0, HERO_FEET.y, SIZE.x, SIZE.y - HERO_FEET.y), GROUND)


## Above the fighters: bars, shield, countdown, gold, hint, floating numbers.
func _draw_overlay() -> void:
	if not _state:
		return
	var bar_y := SIZE.y - 110
	_draw_bar(Vector2(40, bar_y), _state.hero_hp, _hero_trail, _state.rules.hero_max_hp, HP_HERO, "HIỆP SĨ")
	var monster_bar := Vector2(SIZE.x - 40 - BAR_SIZE.x, bar_y)
	_draw_bar(monster_bar, _state.monster_hp, _monster_trail, _state.monster.max_hp, HP_MONSTER, _state.monster.display_name.to_upper())
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
		var at: Vector2 = floater["at"] + Vector2(0, -90 * t)
		_overlay.draw_set_transform(at, 0.0, Vector2.ONE * _pop_scale(t))
		_draw_text_centered(floater["text"], Vector2.ZERO, floater["size"], Color(color, 1.0 - t * t))
		_overlay.draw_set_transform(Vector2.ZERO)


## Popping text: grows past full size in the first moments, then settles back to it.
static func _pop_scale(t: float) -> float:
	if t < 0.1:
		return lerpf(0.4, 1.35, t / 0.1)
	if t < 0.2:
		return lerpf(1.35, 1.0, (t - 0.1) / 0.1)
	return 1.0


## `trail` is the health the bar showed a moment ago, drawn pale behind the real fill.
func _draw_bar(at: Vector2, value: int, trail: float, max_value: int, color: Color, label: String) -> void:
	_overlay.draw_rect(Rect2(at, BAR_SIZE), BAR_BACK)
	var trail_fill := clampf(trail / max_value, 0.0, 1.0)
	_overlay.draw_rect(Rect2(at, Vector2(BAR_SIZE.x * trail_fill, BAR_SIZE.y)), Color(1, 0.95, 0.85, 0.85))
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
	var radius := 40.0
	if warn:
		radius += 7.0 * absf(sin(Time.get_ticks_msec() / 1000.0 * 6.0))
	_overlay.draw_circle(center, radius, WARN if warn else Color(0, 0, 0, 0.5))
	_overlay.draw_arc(center, radius, 0, TAU, 32, TEXT, 3)
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
