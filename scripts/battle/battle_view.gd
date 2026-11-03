class_name BattleView
extends Node2D
## The fight above the board: backdrop, hero and monster (CharacterRig), health bars, shield
## layers, the monster's countdown, tutorial hints and floating numbers.
## play_report() turns one move's TurnReport into a short scene: the hero strikes, the monster
## flinches or panics, the monster strikes back and gloats, and so on. Each blow plays a sound
## and asks for screen shake (impact); health bars drain behind a pale trail.
##
## Fight moves (issue #18): the link picks the hero's move (slash, sword throw, leaping slam,
## combo, shield bash), the Orc answers with a thrown rock, a thrown club or a charge, and dodges
## turns that can't hurt it. Hits pop up comic lettering (assets/fx/comic/), blows to the head
## leave bumps, and critical hits get a cinematic: the screen darkens, speed lines, a close-up
## of the striker's eyes, the camera leans in and time slows as the blow lands.

## A blow landed: `strength` 0..1 of screen shake, `freeze` seconds of hit-stop.
signal impact(strength: float, freeze: float)
## Run the game at `time_scale` for `seconds` of real time.
signal slow_motion(time_scale: float, seconds: float)

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
const COMIC_DIR := "res://assets/fx/comic/"
const COMBAT_DIR := "res://assets/fx/combat/"
const PROP_DIR := "res://assets/fx/props/"
const NUMBER_FONT := "res://assets/fonts/Bangers-Regular.ttf"
## Comic lettering pops to this scale (of its 512×320 art).
const COMIC_SCALE := 0.55
const CRIT_ZOOM := 1.12
## The monster's attacks, taken in turn.
const MONSTER_ATTACKS := [&"rock", &"club", &"charge"]

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
## What the camera moves: the backdrop, the fighters and the FX between them.
var _stage: Node2D
## Props in flight and comic lettering, above the fighters.
var _fx: Node2D
## The critical-hit cinematic: dimming, speed lines, eye close-ups. Not zoomed.
var _cinema: Node2D
var _zoom := 1.0
var _focus := SIZE / 2
var _camera_tween: Tween
var _attack_turn := 0
var _number_font: Font
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
	_stage = Node2D.new()
	add_child(_stage)
	_backdrop = ArenaBackdrop.new()
	_stage.add_child(_backdrop)
	_hero = CharacterRig.new()
	_hero.position = HERO_FEET
	_stage.add_child(_hero)
	_monster = CharacterRig.new()
	_monster.position = MONSTER_FEET
	_stage.add_child(_monster)
	_fx = Node2D.new()
	_stage.add_child(_fx)
	_cinema = Node2D.new()
	add_child(_cinema)
	_number_font = load(NUMBER_FONT) if ResourceLoader.exists(NUMBER_FONT) else ThemeDB.fallback_font
	_overlay = Node2D.new()
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)


func show_state(state: BattleState) -> void:
	_fight += 1
	_state = state
	_floaters.clear()
	_hint = ""
	_attack_turn = 0
	for child in _fx.get_children() + _cinema.get_children():
		child.queue_free()
	_set_camera(1.0, SIZE / 2)
	if _backdrop.background != state.monster.background:
		_backdrop.load_background(state.monster.background)
	_backdrop.react_crowd(&"idle", 0.0)
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
	var big_play := report.chain >= 3 or report.link_length >= 6 or report.critical

	if report.damage > 0 or report.shield_damage > 0:
		await _hero_move(report)
		if fight != _fight:
			return
	elif report.heal > 0:
		_hero.react(&"drink", 0.9)
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
			_backdrop.react_crowd(&"cheer", 2.4)
			_comic("ko", Vector2(SIZE.x / 2, 230), 1.25, 1.4)
			await get_tree().create_timer(0.35).timeout
			if fight == _fight:
				_camera(1.0, SIZE / 2, 0.4)
				_monster.finish(false)
				_hero.finish(true)
				Sfx.play(&"win")
			return
		BattleState.Outcome.LOST:
			if report.monster_attack > 0:
				await _monster_move(report, fight)
			if fight == _fight:
				_hero.finish(false)
				_backdrop.react_crowd(&"boo", 2.4)
				_monster.finish(true)
				Sfx.play(&"lose")
			return

	if big_play:
		_backdrop.react_crowd(&"cheer")
		_hero.react(&"cheer")
		_monster.react(&"scared", 1.2)
	elif report.damage > 0 and _state.monster_health() <= 0.3:
		_monster.react(&"scared", 1.2)
	elif report.damage == 0 and report.shield_damage == 0 and _state.monster.counterattacks:
		# Nothing that hurts it: green and yellow only. It sidesteps and laughs.
		_monster_dodges()

	if report.monster_attack > 0:
		await get_tree().create_timer(0.45).timeout
		if fight != _fight:
			return
		await _monster_move(report, fight)
		if fight != _fight:
			return
		_monster.react(&"cheer")
	elif _state.attacks_next_move() and _state.hero_health() <= 0.3:
		_hero.react(&"scared", 0.0)
	if _state.attacks_next_move():
		Sfx.play(&"warn")
		if _state.next_attack_is_critical():
			# Rubbing its hands, eyes glowing: the critical blow is coming.
			_monster.react(&"windup", 0.0)


func _process(_delta: float) -> void:
	# The countdown pulses while the monster is winding up.
	if _state and _state.attacks_next_move():
		_overlay.queue_redraw()


# --- the hero's moves --------------------------------------------------------

## Which move the link calls for: purple breaks shields with a bash, red gets fancier the
## longer the link (5 throws the sword, 6 leaps, 7 or a long chain is a combo).
static func pick_move(report: TurnReport) -> StringName:
	if report.link_color == Cell.BlockColor.PURPLE and report.shield_damage > 0:
		return &"bash"
	if report.link_length >= 7 or report.chain >= 3:
		return &"combo"
	if report.link_color == Cell.BlockColor.RED:
		if report.link_length == 6:
			return &"leap"
		if report.link_length == 5:
			return &"throw"
	return &"slash"


func _hero_move(report: TurnReport) -> void:
	if report.critical:
		await _cinematic("hero_eye_glint", true, MONSTER_FEET)
	match pick_move(report):
		&"throw":
			await _move_throw(report)
		&"leap":
			await _move_leap(report)
		&"combo":
			await _move_combo(report)
		&"bash":
			await _move_bash(report)
		_:
			await _hero.attack()
			_land_hit(report, "pow")
	_camera(1.0, SIZE / 2, 0.35)


## The sword spins across, bonks the monster on the head and flies back to the hero's hand.
func _move_throw(report: TurnReport) -> void:
	_hero.react(&"throw", 0.8)
	Sfx.play(&"whoosh")
	var sword := _prop("sword_%s" % CharacterRig.WEAR_NAMES[_hero.wear])
	await _fly(sword, _local(_hero.point("hand")), _local(_monster.point("crown")), 0.32, 70.0, 3.0)
	_land_hit(report, "bonk", true)
	Sfx.play(&"whoosh", 0.8)
	await _fly(sword, sword.position, _local(_hero.point("hand")), 0.3, 90.0, -2.0)
	sword.queue_free()


## Leaps high and slams down on the monster, flattening it.
func _move_leap(report: TurnReport) -> void:
	_hero.react(&"leap", 0.0)
	Sfx.play(&"whoosh")
	_camera(1.06, (HERO_FEET + MONSTER_FEET) / 2 + Vector2(0, -150), 0.3)
	await _hero.hop_to(Vector2(MONSTER_FEET.x - HERO_FEET.x - 120, -40), 190.0, 0.42)
	_monster.squash(0.45)
	_flash("dust_puff", MONSTER_FEET + Vector2(0, -10), 0.6, 1.4, 0.45)
	_land_hit(report, "wham", true)
	await _hero.hop_to(Vector2.ZERO, 160.0, 0.35)
	_hero.react(&"idle")


## Two quick slashes and a flying kick that knocks the monster back.
func _move_combo(report: TurnReport) -> void:
	_hero.react(&"attack", 0.0)
	await _hero.dash_to(Vector2(MONSTER_FEET.x - HERO_FEET.x - 190, -10), 0.15)
	_land_hit(report, "pow", false, false)
	await get_tree().create_timer(0.16).timeout
	_hero.react(&"attack", 0.0)
	_hero.squash(-0.15, 0.2)
	_land_hit(report, "bam", false, false)
	await get_tree().create_timer(0.16).timeout
	_hero.react(&"kick", 0.0)
	await _hero.dash_to(Vector2(MONSTER_FEET.x - HERO_FEET.x - 160, -30), 0.08)
	_monster.knockback(90.0)
	_land_hit(report, "combo")
	await _hero.home(0.3)
	_hero.react(&"idle")


## Charges in behind the shield.
func _move_bash(report: TurnReport) -> void:
	_hero.react(&"bash", 0.0)
	await _hero.dash_to(Vector2(MONSTER_FEET.x - HERO_FEET.x - 210, 0), 0.16)
	_monster.knockback(45.0)
	_land_hit(report, "crack" if report.layers_broken > 0 else "clang")
	await _hero.home(0.28)
	_hero.react(&"idle")


## The blow connects. `final` is the hit that shows the numbers; earlier hits of a combo only
## flinch the monster. `bonk` hits the head and leaves a bump.
func _land_hit(report: TurnReport, comic: String, bonk := false, final := true) -> void:
	var head := _local(_monster.point("head"))
	_monster.react(&"hurt")
	if bonk:
		_monster.add_bump()
	if not final:
		_comic(comic, head + Vector2(-60, -90), 0.8)
		_flash("slash", head + Vector2(0, 40), 0.5, 0.9, 0.2, randf_range(-0.6, 0.6), true)
		Sfx.play(&"hit", 1.2)
		impact.emit(0.2, 0.03)
		return
	_monster.set_health(_state.monster_health())
	_monster.set_shield_layers(_state.shield_layers())
	if report.chain >= 3 or report.link_length >= 6 or report.critical:
		_backdrop.react_crowd(&"cheer")
	if report.critical:
		_critical_blow(head)
	else:
		_comic(comic, head + Vector2(-60, -90))
		_flash("slash", head + Vector2(0, 40), 0.5, 1.0, 0.22, randf_range(-0.6, 0.6), true)
	_hero_strike_feel(report)
	if report.shield_damage > 0:
		_float("KHIÊN -%d" % report.shield_damage, MONSTER_FEET + Vector2(0, -300), SHIELD)
	if report.damage > 0:
		# Bigger hits get bigger numbers.
		_float("-%d" % report.damage, MONSTER_FEET + Vector2(0, -190), HP_MONSTER.lightened(0.3), FLOAT_SIZE + mini(report.damage * 2, 56) + (30 if report.critical else 0))


## A critical blow: a red slash, a shockwave, the CRITICAL! banner, time slowing, and the
## monster loses its hat (or a tooth).
func _critical_blow(head: Vector2) -> void:
	_comic("critical", Vector2(SIZE.x / 2, 200), 1.0, 0.8)
	_flash("slash_crit", head + Vector2(0, 40), 0.5, 1.2, 0.3, randf_range(-0.5, 0.5))
	_flash("shockwave", head + Vector2(0, 60), 0.2, 1.6, 0.4, 0.0, true)
	Sfx.play(&"crit")
	slow_motion.emit(0.3, 0.45)
	var lost := "tooth"
	if _monster.character_id == "orc_shield":
		lost = "orc_hat"
		_monster.react(&"bald", 1.4)
	elif _monster.character_id == "scarecrow":
		lost = "scarecrow_hat"
	var prop := _prop(lost)
	var from := _local(_monster.point("crown"))
	await _fly(prop, from, from + Vector2(260, -260), 0.6, 120.0, 4.0)
	var tween := create_tween()
	tween.tween_property(prop, "modulate:a", 0.0, 0.3)
	tween.tween_callback(prop.queue_free)


# --- the monster's moves -----------------------------------------------------

## Leans out of the way of a turn that can't hurt it, and laughs.
func _monster_dodges() -> void:
	_monster.react(&"dodge", 1.0)
	_monster.dash_to(Vector2(70, -10), 0.12, Tween.EASE_OUT)
	_comic("heh", _local(_monster.point("head")) + Vector2(-40, -110), 0.8)
	Sfx.play(&"taunt")
	await get_tree().create_timer(0.7).timeout
	_monster.home(0.25)


## The monster's attacks take turns: a rock to the head, a thrown club, a charge.
func _monster_move(report: TurnReport, fight: int) -> void:
	if report.monster_critical:
		await _cinematic("orc_eye_glare", false, HERO_FEET)
		if fight != _fight:
			return
	var kind: StringName = MONSTER_ATTACKS[_attack_turn % MONSTER_ATTACKS.size()]
	_attack_turn += 1
	match kind:
		&"rock":
			_monster.react(&"throw", 0.7)
			Sfx.play(&"whoosh")
			var rock := _prop("rock")
			await _fly(rock, _local(_monster.point("hand")), _local(_hero.point("crown")), 0.4, 130.0, 2.0)
			rock.queue_free()
			_hero.add_bump()
			_hero_hit(report, "bonk", &"dizzy")
		&"club":
			_monster.react(&"throw", 0.7)
			Sfx.play(&"whoosh", 0.7)
			var club := _prop("club")
			await _fly(club, _local(_monster.point("hand")), _local(_hero.point("head")) + Vector2(0, 60), 0.32, 50.0, -3.0)
			club.queue_free()
			_hero.knockback(70.0, 0.5)
			_hero_hit(report, "thud", &"knocked")
		_:
			_monster.react(&"charge", 0.0)
			await _monster.dash_to(Vector2(HERO_FEET.x - MONSTER_FEET.x + 200, 0), 0.18)
			_hero.knockback(90.0, 0.5)
			_hero_hit(report, "bam", &"knocked")
			await _monster.home(0.3)
	if fight == _fight:
		_camera(1.0, SIZE / 2, 0.35)


func _hero_hit(report: TurnReport, comic: String, pose: StringName) -> void:
	_backdrop.react_crowd(&"boo")
	_hero.react(pose, 1.0)
	_hero.set_health(_state.hero_health())
	var head := _local(_hero.point("head"))
	if report.monster_critical:
		_comic("critical", Vector2(SIZE.x / 2, 200), 1.0, 0.8)
		_flash("shockwave", head + Vector2(0, 60), 0.2, 1.6, 0.4, 0.0, true)
		Sfx.play(&"crit")
		slow_motion.emit(0.3, 0.45)
	else:
		_comic(comic, head + Vector2(60, -90))
	_comic("ouch", head + Vector2(-30, -10), 0.6)
	_float("-%d" % report.monster_attack, HERO_FEET + Vector2(0, -230), WARN, FLOAT_SIZE + (40 if report.monster_critical else 16))
	Sfx.play(&"thud")
	impact.emit(0.35 + minf(report.monster_attack / 40.0, 0.4) + (0.3 if report.monster_critical else 0.0), 0.06)
	_drain_trails()


# --- staging -----------------------------------------------------------------

## The critical-hit build-up: the screen darkens behind speed lines, a close-up of the
## striker's eyes sweeps across, and the camera leans in on `focus`.
func _cinematic(eyes: String, from_left: bool, focus: Vector2) -> void:
	Sfx.play(&"crit_charge")
	var dim := ColorRect.new()
	dim.size = SIZE
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinema.add_child(dim)
	var lines := _sprite(COMBAT_DIR + "speed_lines.png", SIZE / 2, _cinema)
	var strip := _sprite(COMBAT_DIR + eyes + ".png", Vector2(-SIZE.x / 2 if from_left else SIZE.x * 1.5, 230), _cinema)
	var tween := create_tween().set_parallel()
	tween.tween_property(dim, "color:a", 0.55, 0.12)
	if lines:
		lines.modulate.a = 0.0
		lines.scale = Vector2.ONE * 1.15
		tween.tween_property(lines, "modulate:a", 1.0, 0.12)
		tween.tween_property(lines, "scale", Vector2.ONE, 0.5)
	if strip:
		strip.scale = Vector2.ONE * 0.8
		tween.tween_property(strip, "position:x", SIZE.x / 2, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_camera(CRIT_ZOOM, focus + Vector2(0, -160), 0.3)
	await get_tree().create_timer(0.6).timeout
	var out := create_tween().set_parallel()
	if strip:
		out.tween_property(strip, "position:x", SIZE.x * 1.5 if from_left else -SIZE.x / 2, 0.14).set_ease(Tween.EASE_IN)
	out.tween_property(dim, "color:a", 0.0, 0.3)
	if lines:
		out.tween_property(lines, "modulate:a", 0.0, 0.3)
	out.chain().tween_callback(func() -> void:
		for node in [dim, lines, strip]:
			if node:
				node.queue_free())


## Comic lettering slams in at `at`, wobbles, and fades.
func _comic(word: String, at: Vector2, size := 1.0, hold := 0.45) -> void:
	var sprite := _sprite(COMIC_DIR + word + ".png", at, _fx)
	if not sprite:
		_float(word.to_upper() + "!", at, GOLD, FLOAT_SIZE)
		return
	var full := Vector2.ONE * COMIC_SCALE * size
	sprite.rotation = randf_range(-0.12, 0.12)
	sprite.scale = full * 0.2
	var tween := create_tween()
	tween.tween_property(sprite, "scale", full * 1.15, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", full, 0.08)
	tween.tween_interval(hold)
	tween.set_parallel()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_property(sprite, "scale", full * 1.2, 0.2)
	tween.chain().tween_callback(sprite.queue_free)


## A one-shot effect image that grows from `from_scale` to `to_scale` and fades.
func _flash(effect: String, at: Vector2, from_scale: float, to_scale: float, seconds: float, angle := 0.0, additive := false) -> void:
	var sprite := _sprite(COMBAT_DIR + effect + ".png", at, _fx)
	if not sprite:
		return
	if additive:
		var blend := CanvasItemMaterial.new()
		blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = blend
	sprite.rotation = angle
	sprite.scale = Vector2.ONE * from_scale
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector2.ONE * to_scale, seconds).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, seconds).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(sprite.queue_free)


## A prop from assets/fx/props/, shown at 70% (the fighters' scale), or a placeholder dot.
func _prop(prop_name: String) -> Node2D:
	var sprite := _sprite(PROP_DIR + prop_name + ".png", Vector2.ZERO, _fx)
	if sprite:
		sprite.scale = Vector2.ONE * CharacterRig.DISPLAY_SIZE / CharacterRig.CANVAS
		return sprite
	var dot := Node2D.new()
	dot.draw.connect(func() -> void: dot.draw_circle(Vector2.ZERO, 18, Color(0.6, 0.5, 0.4)))
	_fx.add_child(dot)
	return dot


## Flies `node` from `from` to `to` along an arc `height` high, turning `spins` times.
func _fly(node: Node2D, from: Vector2, to: Vector2, seconds: float, height: float, spins: float) -> void:
	node.position = from
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		node.position = from.lerp(to, t) + Vector2(0, -height * 4.0 * t * (1.0 - t))
		node.rotation = spins * TAU * t, 0.0, 1.0, seconds)
	await tween.finished


func _sprite(path: String, at: Vector2, parent: Node) -> Sprite2D:
	if not ResourceLoader.exists(path):
		return null
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.position = at
	parent.add_child(sprite)
	return sprite


## A global position (from CharacterRig.point) in the stage's own coordinates.
func _local(global_point: Vector2) -> Vector2:
	return _fx.to_local(global_point)


## Eases the camera to `zoom` around `focus` (stage coordinates).
func _camera(zoom: float, focus: Vector2, seconds: float) -> void:
	if _camera_tween:
		_camera_tween.kill()
	var zoom_from := _zoom
	var focus_from := _focus
	_camera_tween = create_tween()
	_camera_tween.tween_method(func(t: float) -> void:
		_set_camera(lerpf(zoom_from, zoom, t), focus_from.lerp(focus, t)), 0.0, 1.0, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## Zooming never shows past the edges: the focus stays put on screen while the stage grows
## around it. The backdrop's layers lean toward the focus by different amounts for depth.
func _set_camera(zoom: float, focus: Vector2) -> void:
	_zoom = zoom
	_focus = focus
	_stage.scale = Vector2.ONE * zoom
	_stage.position = focus * (1.0 - zoom)
	var lean := clampf((focus.x - SIZE.x / 2) / (SIZE.x / 2), -1.0, 1.0) * clampf((zoom - 1.0) / (CRIT_ZOOM - 1.0), 0.0, 1.0)
	_backdrop.set_camera(1.0, lean)


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
	# Plain numbers use the comic font; words keep the default one, which has Vietnamese.
	if text.lstrip("+-").is_valid_int():
		floater["font"] = _number_font
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
		_draw_text_centered(floater["text"], Vector2.ZERO, floater["size"], Color(color, 1.0 - t * t), floater.get("font"))
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
		if _state.next_attack_is_critical():
			_draw_text_centered("SẮP CHÍ MẠNG %d!" % roundi(_state.monster.attack * _state.rules.monster_crit_multiplier), center + Vector2(-90, -55), 36, Color(1, 0.85, 0.2))
		else:
			_draw_text_centered("SẮP ĐÁNH %d!" % _state.monster.attack, center + Vector2(-50, -55), 34, WARN.lightened(0.3))


## Text sits on painted backgrounds, so it gets a dark outline to stay readable.
func _draw_text(text: String, at: Vector2, font_size: int, color: Color, font: Font = null) -> void:
	if not font:
		font = ThemeDB.fallback_font
	_overlay.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE_SIZE, Color(OUTLINE, color.a))
	_overlay.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_text_centered(text: String, at: Vector2, font_size: int, color: Color, font: Font = null) -> void:
	if not font:
		font = ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_text(text, at - Vector2(width / 2, 0), font_size, color, font)
