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
## spin stars, and critical hits get a cinematic: the screen darkens, speed lines, a close-up
## of the striker's eyes, the camera leans in and time slows as the blow lands.
##
## Hero skills (BattleState.SKILLS) play the same way from their own report, with their name in
## comic lettering. Until the skill clips of docs/ideas/skills_art_request.md arrive, they borrow
## the existing moves: Phá Giáp the shield bash, Hồi Quang the potion.

## A blow landed: `strength` 0..1 of screen shake, `freeze` seconds of hit-stop.
signal impact(strength: float, freeze: float)
## The witch flicks her wand: the board should throw its lifted tile at `target` (global).
signal tile_thrown(target: Vector2)
## Run the game at `time_scale` for `seconds` of real time.
signal slow_motion(time_scale: float, seconds: float)

## The fight's strip of screen. The backdrop is painted 660 tall; its top is cut off
## (BACKDROP_SHIFT) so the board below gets the room.
const SIZE := Vector2(1080, 500)
const BACKDROP_SHIFT := Vector2(0, -80)
## Where each fighter's feet touch the ground.
const HERO_FEET := Vector2(270, 405)
const MONSTER_FEET := Vector2(810, 405)
## Fighting-game health bars across the top: the hero's half on the left, the monster's on
## the right, the countdown between them.
## The bars stop short of the middle, where the turn plaque and its swords swing.
const BAR_SIZE := Vector2(370, 30)
const BAR_RADIUS := 8
## The dark frame around each bar and shield pip.
const BAR_RIM := 4
const HERO_BAR := Vector2(20, 20)
const MONSTER_BAR := Vector2(SIZE.x - 20 - BAR_SIZE.x, 20)
const COUNTDOWN_AT := Vector2(SIZE.x / 2, 38)
const LABEL_SIZE := 24
## Name, gold and shield pips sit in a row just under the bars.
const ROW_Y := HERO_BAR.y + BAR_SIZE.y + BAR_RIM + 8
## Bars throb at or below this much health.
const LOW_HEALTH := 0.3
const COIN_SIZE := 34.0
## Damage and healing numbers rise this far.
const FLOAT_RISE := 80.0
const FLOAT_TIME := 1.1
const FLOAT_SIZE := 64
## A health bar's pale trail waits this long after a hit, then catches up over TRAIL_TIME.
const TRAIL_DELAY := 0.35
const TRAIL_TIME := 0.4
const HERO_ID := "hero_rookie"
const COMIC_DIR := "res://assets/fx/comic/"
const COMBAT_DIR := "res://assets/fx/combat/"
## Frame-by-frame versions of the combat effects: anim/<effect>.png, listed in anim/anim.json
## as {"<effect>": {"frames", "fps", "columns", "frame_size"}}. They win over the still image.
const COMBAT_ANIM := "res://assets/fx/combat/anim/anim.json"
const PROP_DIR := "res://assets/fx/props/"
const WEATHER_DIR := "res://assets/fx/weather/"
const SKY_ICON := 46.0
## How far the hour and weather icons sit either side of the countdown's centre.
const SKY_ICON_GAP := 72.0
## Where the hour, weather and status icons start in the hero's row, after its name.
const ROW_ICONS_X := 108.0
const NUMBER_FONT := "res://assets/fonts/Bangers-Regular.ttf"
## Comic lettering pops to this scale (of its 512×320 art).
const COMIC_SCALE := 0.55
const CRIT_ZOOM := 1.12
## Comic lettering for each hero skill (assets/fx/comic/<word>.png). Without the art, the
## skill's name floats up instead.
const SKILL_COMICS := {"armor_breaker": "armor_break", "second_wind": "second_wind"}
const SKILL_NAME_AT := Vector2(HERO_FEET.x + 40, 150)
## The monster's attacks, taken in turn.
const MONSTER_ATTACKS := [&"rock", &"club", &"charge"]

const BG := Color(0.13, 0.16, 0.22)
const GROUND := Color(0.17, 0.2, 0.16)
const TEXT := Color(0.92, 0.92, 0.96)
const TEXT_DIM := Color(0.6, 0.6, 0.7)
const HP_HERO := Color(0.35, 0.75, 0.4)
const HP_MONSTER := Color(0.85, 0.3, 0.3)
const BAR_BACK := Color(0, 0, 0, 0.5)
const BAR_RIM_COLOR := Color(0.17, 0.1, 0.05)
const BAR_EMPTY := Color(0.08, 0.05, 0.04, 0.92)
const BAR_TRAIL := Color(1, 0.93, 0.75)
const SHIELD := Color(0.62, 0.42, 0.85)
const GOLD := Color(0.98, 0.8, 0.25)
const WARN := Color(0.95, 0.3, 0.25)
const HIT_SPARK := Color(1, 0.85, 0.45)
const HURT_SPARK := Color(1, 0.45, 0.35)
const POISON := Color(0.55, 0.9, 0.3)
const CURSE := Color(0.75, 0.55, 1.0)
const RAGE := Color(1.0, 0.3, 0.15)
const PLAQUE := Color(0.27, 0.17, 0.1)
const PLAQUE_RIM := Color(0.86, 0.66, 0.3)
## The plaque's swords clash this often, the clash landing this far into each round.
const SWORD_CLASH := 2.0
## The rage steam: its size (the sheet's cels are 512) and where it sits over the head.
const STEAM_SCALE := 0.3
const STEAM_OFFSET := Vector2(0, -125)
const CLASH_AT := 0.35
const HUD_DIR := "res://assets/ui/hud/"
## The painted swords lean this far on their own (left one to the left), in radians.
const SWORD_LEAN := 0.1745
const SWORD_SIZE := 76.0
## clash_spark.png: 6 cels of 160 in 3 columns at 24 fps.
const SPARK_FRAMES := 6
const SPARK_COLUMNS := 3
const SPARK_FPS := 24.0
const SPARK_SIZE := 96.0
const CURSE_DIR := "res://assets/fx/curse/"
const STATUS_DIR := "res://assets/ui/status/"
const OUTLINE := Color(0.1, 0.07, 0.05)
const OUTLINE_SIZE := 8
## Floating numbers: a dark rim, then a ring of their color around a warm white core.
const FLOAT_RIM := 18
const FLOAT_RING := 9
const FLOAT_CORE := Color(1, 0.97, 0.86)

var _state: BattleState
## What the camera moves: the backdrop, the fighters and the FX between them.
var _stage: Node2D
## Props in flight and comic lettering, above the fighters.
var _fx: Node2D
## Sparks and light bursting from where blows land.
var _sparks: TileParticles
## The critical-hit cinematic: dimming, speed lines, eye close-ups. Not zoomed.
var _cinema: Node2D
var _zoom := 1.0
var _focus := SIZE / 2
var _camera_tween: Tween
var _attack_turn := 0
var _number_font: Font
## The level's goals, shown as small chips under the countdown; null outside a level.
var _goal: LevelProgress
var _goal_art := ObstacleArt.new()
var _status_icons := {}
var _rage_time := 0.0
var _steam: Sprite2D
var _sword: Texture2D
## The turn plaque's painted art (assets/ui/hud), or null to draw it plainly.
var _plaque: Texture2D
var _hud_swords: Array[Texture2D] = []
var _clash_spark: Texture2D
var _combat_anim := {}
var _backdrop: ArenaBackdrop
## Holds both fighters, so the hour's light tints them without touching their own flashes.
var _cast: Node2D
var _weather: ArenaWeather
## Hour and weather icons by name (assets/fx/weather/icon_<name>.png).
var _weather_icons := {}
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
## Reused for every rounded shape of the HUD.
var _box := StyleBoxFlat.new()
var _coin: Texture2D
## How many reports are still playing out.
var _playing := 0


func _ready() -> void:
	_stage = Node2D.new()
	add_child(_stage)
	_backdrop = ArenaBackdrop.new()
	_backdrop.position = BACKDROP_SHIFT
	_stage.add_child(_backdrop)
	_cast = Node2D.new()
	_stage.add_child(_cast)
	_hero = CharacterRig.new()
	_hero.position = HERO_FEET
	_cast.add_child(_hero)
	_monster = CharacterRig.new()
	_monster.position = MONSTER_FEET
	_cast.add_child(_monster)
	_weather = ArenaWeather.new()
	_weather.position = BACKDROP_SHIFT
	_weather.backdrop = _backdrop
	_stage.add_child(_weather)
	_fx = Node2D.new()
	_stage.add_child(_fx)
	_sparks = TileParticles.new()
	_sparks.additive = true
	_stage.add_child(_sparks)
	_cinema = Node2D.new()
	add_child(_cinema)
	_number_font = load(NUMBER_FONT) if ResourceLoader.exists(NUMBER_FONT) else ThemeDB.fallback_font
	if ResourceLoader.exists(COMBAT_ANIM):
		var json: JSON = load(COMBAT_ANIM)
		if json.data is Dictionary:
			_combat_anim = json.data.duplicate()
	# Curse effects (green poof, the broom spell) sit in their own folder.
	if ResourceLoader.exists(CURSE_DIR + "anim.json"):
		var curses: JSON = load(CURSE_DIR + "anim.json")
		if curses.data is Dictionary:
			for effect: String in curses.data:
				var info: Dictionary = curses.data[effect].duplicate()
				info["path"] = CURSE_DIR + effect + ".png"
				_combat_anim[effect] = info
	_coin = load(PROP_DIR + "coin.png") if ResourceLoader.exists(PROP_DIR + "coin.png") else null
	var sword := "res://assets/ui/items/iron_sword.png"
	_sword = load(sword) if ResourceLoader.exists(sword) else null
	_plaque = _load_or_null(HUD_DIR + "turn_plaque.png")
	for side in ["left", "right"]:
		var texture := _load_or_null(HUD_DIR + "sword_%s.png" % side)
		if texture:
			_hud_swords.append(texture)
	_clash_spark = _load_or_null(HUD_DIR + "clash_spark.png")
	_box.shadow_color = Color(0, 0, 0, 0.35)
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
	_sparks.clear()
	_set_camera(1.0, SIZE / 2)
	if _backdrop.background != state.monster.background:
		_backdrop.load_background(state.monster.background)
	_backdrop.set_sky(state.time_of_day, state.weather)
	_weather.set_sky(state.weather)
	_cast.modulate = _backdrop.fighter_light()
	_hero.setup(HERO_ID, 1)
	_monster.setup(state.monster.id, -1, state.shield_layers() if state.monster.shield_layers > 0 else -1)
	_monster.modulate = Color.WHITE
	_rage_time = 0.0
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
		Cell.BlockColor.GREEN: to_global(HERO_BAR + BAR_SIZE / 2),
		Cell.BlockColor.YELLOW: to_global(_coin_center()),
		Cell.BlockColor.PURPLE: to_global(MONSTER_FEET + Vector2(-110, -150)),
	}


func show_goal(progress: LevelProgress) -> void:
	_goal = progress
	_redraw()


func show_hint(text: String) -> void:
	_hint = text
	_overlay.queue_redraw()


func play_report(report: TurnReport) -> void:
	_playing += 1
	await _play_report(report)
	_playing -= 1


## Whether a move or a skill is still playing out above the board.
func is_playing() -> bool:
	return _playing > 0


func _play_report(report: TurnReport) -> void:
	var fight := _fight
	var big_play := report.chain >= 3 or report.link_length >= 6 or report.critical

	if report.skill:
		await _hero_skill(report)
		if fight != _fight:
			return
	elif report.damage > 0 or report.shield_damage > 0:
		await _hero_move(report)
		if fight != _fight:
			return
	elif report.heal > 0:
		_hero.react(&"drink", 1.0)
	if report.heal > 0:
		_float("+%d" % report.heal, HERO_FEET + Vector2(0, -200), HP_HERO.lightened(0.3))
		_hero.set_health(_state.hero_health())
		Sfx.play(&"heal")
	if report.gold > 0:
		_float("+%d VÀNG" % report.gold, _coin_center() + Vector2(0, 70), GOLD)
		Sfx.play(&"coin", 1.0, -4.0)
	_show_afflictions(report)
	if report.raged:
		_go_berserk()
	_drain_trails()

	match report.outcome:
		BattleState.Outcome.WON:
			_comic("ko", Vector2(SIZE.x / 2, 210), 1.25, 1.4)
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
				_monster.finish(true)
				Sfx.play(&"lose")
			return

	if big_play:
		_hero.react(&"cheer")
		_monster.react(&"scared", 1.2)
	elif report.damage > 0 and _state.monster_health() <= 0.3:
		_monster.react(&"scared", 1.2)
	elif report.damage == 0 and report.shield_damage == 0 and _state.monster.counterattacks and not report.skill and not report.booster:
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
		_show_spell(report)
	elif _state.attacks_next_move() and _state.hero_health() <= 0.3:
		_hero.react(&"scared", 0.0)
	if _state.attacks_next_move():
		Sfx.play(&"warn")
		if _state.next_attack_is_critical():
			# Rubbing its hands, eyes glowing: the critical blow is coming.
			_monster.react(&"windup", 0.0)


## What the poison, the board and the curses did to the hero this move.
func _show_afflictions(report: TurnReport) -> void:
	var over_head := _local(_hero.point("head")) + Vector2(0, -70)
	if report.cured:
		_float("GIẢI ĐỘC!", over_head, HP_HERO.lightened(0.3), 46)
		Sfx.play(&"heal", 1.3)
	if report.poison_damage > 0:
		_float("-%d" % report.poison_damage, over_head + Vector2(-60, 0), POISON)
		_hero.flash()
	if report.board_damage > 0:
		_float("-%d" % report.board_damage, over_head + Vector2(60, 0), HURT_SPARK)
		_hero.react(&"hurt", 0.6)
		Sfx.play(&"boom")
		impact.emit(0.5, 0.06)
	if report.poison_damage > 0 or report.board_damage > 0:
		_hero.set_health(_state.hero_health())
	if report.turned_toad:
		_turn_toad(true)
	elif report.toad_back:
		_turn_toad(false)
	if report.broom_broken and _hero.variant == "broom":
		_hero.react(&"broom_out", 0.42)
		_comic("crack", over_head, 0.8)
		await get_tree().create_timer(0.42).timeout
		_hero.set_variant("")
	if report.lift_fizzled:
		_monster.react(&"stomp_angry" if _monster.has_clip(&"stomp_angry") else &"hurt", 1.0)
		_float("PHÁ PHÉP!", MONSTER_FEET + Vector2(0, -260), CURSE, 52)
		Sfx.play(&"untick", 0.7)
	if report.stolen > 0:
		_float("-%d VÀNG" % report.stolen, _coin_center() + Vector2(0, 70), HURT_SPARK)
	_redraw()


## The monster snaps at low health: it roars, the screen shakes, and it goes red and fast.
func _go_berserk() -> void:
	var head := _local(_monster.point("head"))
	var roar := &"rage" if _monster.has_clip(&"rage") else _monster_clip(&"special")
	_monster.react(roar, _monster.clip_seconds(roar, 1.0))
	_monster.squash(0.2, 0.3)
	_start_steam()
	_comic("boom", head + Vector2(-60, -120), 1.0)
	_float("NỔI ĐIÊN!", MONSTER_FEET + Vector2(-20, -280), RAGE, 64)
	_flash("shockwave", head + Vector2(0, 60), 0.2, 1.8, 0.45, 0.0, true)
	Sfx.play(&"warn", 0.6)
	Sfx.play(&"boom", 0.7)
	impact.emit(0.6, 0.05)


## Hot steam rising off a raging monster's head, looping until it falls or the fight ends.
func _start_steam() -> void:
	if _steam or not _combat_anim.has("rage_steam"):
		return
	var info: Dictionary = _combat_anim["rage_steam"]
	_steam = _sprite(COMBAT_DIR + "anim/rage_steam.png", Vector2.ZERO, _fx)
	if _steam == null:
		return
	_steam.hframes = int(info.get("columns", 4))
	_steam.vframes = ceili(float(info.get("frames", 8)) / _steam.hframes)
	_steam.scale = Vector2.ONE * STEAM_SCALE
	_steam.modulate.a = 0.85
	_steam.set_meta("frames", int(info.get("frames", 8)))
	_steam.set_meta("fps", float(info.get("fps", 12)))


func _stop_steam() -> void:
	if _steam:
		_steam.queue_free()
		_steam = null


## Spells the monster's attack cast on the hero.
func _show_spell(report: TurnReport) -> void:
	if report.broomed and _hero.character_id == HERO_ID:
		_hero.set_variant("broom")
		_hero.react(&"broom_in", 0.7)
		Sfx.play(&"whoosh", 1.4)
		_float("CHỔI!", _local(_hero.point("head")) + Vector2(0, -80), CURSE, 52)
	if report.poisoned:
		_float("TRÚNG ĐỘC!", _local(_hero.point("head")) + Vector2(0, -80), POISON, 46)
	_redraw()


## The hero turns into a toad in a puff of green smoke, or back.
func _turn_toad(into: bool) -> void:
	var feet := _hero.position
	_flash("poof_green", _local(_hero.point("head")) + Vector2(0, 80), 0.6, 1.4, 0.4)
	Sfx.play(&"special")
	if into:
		_hero.setup("hero_toad", 1)
		_hero.react(&"transform_in", 1.0)
		_float("ỘP!", _local(_hero.point("head")) + Vector2(0, -60), CURSE, 56)
	else:
		_hero.react(&"transform_out", 1.0)
		await get_tree().create_timer(0.9).timeout
		_hero.setup(HERO_ID, 1)
		_hero.set_health(_state.hero_health())
	_hero.position = feet


func _process(delta: float) -> void:
	# A raging monster glows red with each heartbeat and steams.
	if _state and _state.raging and _state.outcome == BattleState.Outcome.ONGOING:
		_rage_time += delta
		var beat := pow(maxf(sin(_rage_time * 7.0), 0.0), 3.0)
		_monster.modulate = Color(1.0, 0.62 - 0.22 * beat, 0.55 - 0.25 * beat)
		if randf() < delta * 10.0:
			_sparks.flare(_local(_monster.point("head")) + Vector2(randf_range(-60, 60), randf_range(-40, 20)), RAGE, 0.6)
		if _steam:
			_steam.position = _local(_monster.point("head")) + STEAM_OFFSET
			_steam.frame = int(_rage_time * float(_steam.get_meta("fps"))) % int(_steam.get_meta("frames"))
	else:
		_stop_steam()
		if _monster.modulate != Color.WHITE:
			_monster.modulate = Color.WHITE
	# The plaque's swords never rest; the countdown pulses; low health bars throb.
	if _state:
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
	_hero.react(&"throw", 0.0)
	# The sword leaves the hand on the clip's release frame.
	await _wait(_hero.strike_time(&"throw", 0.0))
	Sfx.play(&"whoosh")
	var sword := _prop("sword_%s" % CharacterRig.WEAR_NAMES[_hero.wear])
	await _fly(sword, _local(_hero.point("hand")), _local(_monster.point("crown")), 0.32, 70.0, 3.0)
	_land_hit(report, "bonk", true)
	Sfx.play(&"whoosh", 0.8)
	await _fly(sword, sword.position, _local(_hero.point("hand")), 0.3, 90.0, -2.0)
	sword.queue_free()
	_hero.react(&"idle")


## Leaps high and slams down on the monster, flattening it.
func _move_leap(report: TurnReport) -> void:
	_hero.react(&"leap", 0.0)
	Sfx.play(&"whoosh")
	_camera(1.06, (HERO_FEET + MONSTER_FEET) / 2 + Vector2(0, -150), 0.3)
	await _hero.hop_to(Vector2(MONSTER_FEET.x - HERO_FEET.x - 120, -40), 190.0, _hero.strike_time(&"leap", 0.42))
	_hero.reach_impact()
	_monster.squash(0.45)
	_flash("dust_puff", MONSTER_FEET + Vector2(0, -10), 0.6, 1.4, 0.45)
	_land_hit(report, "wham", true)
	await _hero.hop_to(Vector2.ZERO, 160.0, 0.35)
	_hero.react(&"idle")


## Two quick slashes and a flying kick that knocks the monster back.
func _move_combo(report: TurnReport) -> void:
	_hero.react(&"attack", 0.0)
	await _hero.dash_to(Vector2(MONSTER_FEET.x - HERO_FEET.x - 190, -10), _hero.strike_time(&"attack", 0.15))
	_hero.reach_impact()
	_land_hit(report, "pow", false, false)
	await get_tree().create_timer(0.16).timeout
	_hero.react(&"attack", 0.0)
	await _wait(_hero.strike_time(&"attack", 0.0))
	_hero.reach_impact()
	_hero.squash(-0.15, 0.2)
	_land_hit(report, "bam", false, false)
	await get_tree().create_timer(0.16).timeout
	_hero.react(&"kick", 0.0)
	await _hero.dash_to(Vector2(MONSTER_FEET.x - HERO_FEET.x - 160, -30), _hero.strike_time(&"kick", 0.08))
	_hero.reach_impact()
	_monster.knockback(90.0)
	_land_hit(report, "combo")
	await _hero.home(0.3)
	_hero.react(&"idle")


## Charges in behind the shield. `comic` replaces the crack or clang.
func _move_bash(report: TurnReport, comic := "") -> void:
	_hero.react(&"bash", 0.0)
	await _hero.dash_to(Vector2(MONSTER_FEET.x - HERO_FEET.x - 210, 0), _hero.strike_time(&"bash", 0.16))
	_hero.reach_impact()
	_monster.knockback(45.0)
	if not comic:
		comic = "crack" if report.layers_broken > 0 else "clang"
	_land_hit(report, comic)
	await _hero.home(0.28)
	_hero.react(&"idle")


## A hero skill: its name over the hero as the screen darkens on the hero's eyes, then the move.
## Phá Giáp charges in behind the shield and cracks the monster's guard; Hồi Quang drinks deep in
## a burst of green light. The name stays on the hero's side, clear of the numbers over the monster.
func _hero_skill(report: TurnReport) -> void:
	var fight := _fight
	var comic: String = SKILL_COMICS.get(report.skill, "")
	if ResourceLoader.exists(COMIC_DIR + comic + ".png"):
		_comic(comic, SKILL_NAME_AT, 1.0, 1.0)
	else:
		_float(BattleState.SKILLS[report.skill] + "!", SKILL_NAME_AT, Color(1.0, 0.6, 0.15), 84)
	await _cinematic("hero_eye_glint", true, HERO_FEET if report.skill == "second_wind" else MONSTER_FEET)
	if fight != _fight:
		return
	match report.skill:
		"armor_breaker":
			await _move_bash(report)
		"second_wind":
			_hero.react(&"drink", 1.0)
			var chest := _local(_hero.point("head")) + Vector2(0, 90)
			_sparks.flare(chest, HP_HERO.lightened(0.3), 2.5)
			_flash("shockwave", chest, 0.2, 1.6, 0.5, 0.0, true)
			await _wait(0.6)
	_camera(1.0, SIZE / 2, 0.35)


## The blow connects. `final` is the hit that shows the numbers; earlier hits of a combo only
## flinch the monster. `bonk` hits the head and dazes it.
func _land_hit(report: TurnReport, comic: String, bonk := false, final := true) -> void:
	var head := _local(_monster.point("head"))
	var struck := head + Vector2(0, 40)
	_monster.react(&"hurt")
	_monster.flash()
	if bonk:
		_monster.daze()
	if not final:
		_comic(comic, head + Vector2(-110, -40), 0.8)
		_flash("slash", struck, 0.5, 0.9, 0.2, randf_range(-0.6, 0.6), true)
		_sparks.flare(struck, HIT_SPARK, 1.2)
		_punch(struck, 0.025)
		Sfx.play(&"hit", 1.2)
		impact.emit(0.25, 0.04)
		return
	_monster.set_health(_state.monster_health())
	_monster.set_shield_layers(_state.shield_layers())
	_sparks.flare(struck, SHIELD.lightened(0.4) if report.damage == 0 else HIT_SPARK, 1.4 + minf(report.damage / 20.0, 1.0))
	_punch(struck, 0.05)
	if report.critical:
		_critical_blow(head)
	else:
		_comic(comic, head + Vector2(-110, -40))
		_flash("slash", struck, 0.5, 1.0, 0.22, randf_range(-0.6, 0.6), true)
		_flash("shockwave", struck, 0.12, 0.8, 0.28, 0.0, true)
	_hero_strike_feel(report)
	if report.shield_damage > 0:
		_float("KHIÊN -%d" % report.shield_damage, MONSTER_FEET + Vector2(-170, -180), SHIELD)
	if report.damage > 0:
		# Bigger hits get bigger numbers.
		_float("-%d" % report.damage, MONSTER_FEET + Vector2(0, -200), HP_MONSTER.lightened(0.3), FLOAT_SIZE + mini(report.damage * 2, 56) + (30 if report.critical else 0))


## A critical blow: a red slash, a shockwave, the CRITICAL! banner, time slowing, and the
## monster loses its hat (or a tooth).
func _critical_blow(head: Vector2) -> void:
	_comic("critical", Vector2(SIZE.x / 2, 190), 1.0, 0.8)
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
	if report.drummed:
		# The war drum: a big beat before the blow, and the countdown speeds up.
		_monster.react(_monster_clip(&"special"), 0.0)
		await _wait(_monster.strike_time(_monster_clip(&"special"), 0.3))
		_comic("boom", _local(_monster.point("head")) + Vector2(-60, -120), 0.9)
		Sfx.play(&"warn", 0.8)
		impact.emit(0.3, 0.0)
		_float("TRỐNG THÚC!", COUNTDOWN_AT + Vector2(0, 150), GOLD, 46)
		await get_tree().create_timer(0.35).timeout
		if fight != _fight:
			return
	if report.board_spell or report.poisoned or report.leeched > 0:
		await _monster_spell(report)
		if fight == _fight:
			_camera(1.0, SIZE / 2, 0.35)
		return
	var kind: StringName = MONSTER_ATTACKS[_attack_turn % MONSTER_ATTACKS.size()]
	if _state.monster.special == "rock":
		kind = &"rock"
	_attack_turn += 1
	match kind:
		&"rock":
			_monster.react(_monster_clip(&"throw"), 0.7)
			await _wait(_monster.strike_time(_monster_clip(&"throw"), 0.0))
			Sfx.play(&"whoosh")
			var rock := _prop("rock")
			await _fly(rock, _local(_monster.point("hand")), _local(_hero.point("crown")), 0.4, 130.0, 2.0)
			rock.queue_free()
			_hero.daze()
			_hero_hit(report, "bonk", &"dizzy")
		&"club":
			_monster.react(_monster_clip(&"throw"), 0.7)
			await _wait(_monster.strike_time(_monster_clip(&"throw"), 0.0))
			Sfx.play(&"whoosh", 0.7)
			var club := _prop("club")
			await _fly(club, _local(_monster.point("hand")), _local(_hero.point("head")) + Vector2(0, 60), 0.32, 50.0, -3.0)
			club.queue_free()
			_hero.knockback(70.0, 0.5)
			_hero_hit(report, "thud", &"knocked")
		_:
			_monster.react(_monster_clip(&"charge"), 0.0)
			await _monster.dash_to(Vector2(HERO_FEET.x - MONSTER_FEET.x + 200, 0), _monster.strike_time(_monster_clip(&"charge"), 0.18))
			_monster.reach_impact()
			_hero.knockback(90.0, 0.5)
			_hero_hit(report, "bam", &"knocked")
			await _monster.home(0.3)
	if fight == _fight:
		_camera(1.0, SIZE / 2, 0.35)


## The witch's lift clip. Her drawn `lift` clip paints her at half her size (art issue #48), so
## she waves her broom spell until it's redrawn; then this becomes &"lift".
const LIFT_CLIP := &"cast_broom"
## Clips the monster plays for each spell, and the word that pops up.
const SPELL_CLIPS := {
	"toads": [&"cast_toads", "zap"], "broom": [&"cast_broom", "zap"], "potion": [&"throw_potion", "whoosh"],
	"burp": [&"burp_toads", "boom"], "web": [&"special", "whoosh"], "ice": [&"special", "zap"],
	"bomb": [&"special", "boom"], "marks": [&"special", "heh"], "lift": [LIFT_CLIP, "zap"],
}


## A monster whose attack is a spell or a special blow: its own clip, the hit on the hero, and
## for spells on the board a cue that something is coming down (the board shows it land).
func _monster_spell(report: TurnReport) -> void:
	var entry: Array = SPELL_CLIPS.get(report.board_spell, [&"special" if report.board_spell else &"attack", "bam"])
	var clip: StringName = entry[0] if _monster.has_clip(entry[0]) else _monster_clip(&"special")
	if report.lift_thrown:
		await _lift_and_throw(report, clip)
		return
	_monster.react(clip, 1.0)
	await _wait(_monster.strike_time(clip, 0.35))
	var head := _local(_hero.point("head"))
	_comic(entry[1], _local(_monster.point("head")) + Vector2(-80, -110), 0.8)
	if report.board_spell in ["toads", "burp"]:
		# Toads hop off toward the board.
		for i in _state.monster.special_power:
			_flash("toad_hop", _local(_monster.point("hand")) + Vector2(-80 - 90 * i, 60), 0.4, 0.6, 0.5)
	if report.board_spell == "broom":
		_flash("broom_spell", head + Vector2(80, 60), 0.5, 0.9, 0.4)
	if report.leeched > 0:
		_float("+%d" % report.leeched, MONSTER_FEET + Vector2(0, -230), HP_MONSTER.lightened(0.3))
		_monster.set_health(_state.monster_health())
	_hero_hit(report, "ouch", &"hurt")


## The witch's lift: the tile rises off the board and whirls while she raises her wand, and her
## flick (the clip's impact frame) is the moment it flies at the hero.
func _lift_and_throw(report: TurnReport, clip: StringName) -> void:
	tile_thrown.emit(_hero.point("head"))
	Sfx.play(&"charge", 1.2)
	var flick := _monster.strike_time(clip, 0.35)
	var held := BoardView.LIFT_RISE + BoardView.LIFT_SPIN
	await _wait(maxf(held - flick, 0.0))
	_monster.react(clip, 1.0)
	await _wait(minf(flick, held))
	_comic("zap", _local(_monster.point("head")) + Vector2(-80, -110), 0.8)
	Sfx.play(&"whoosh", 1.2)
	await _wait(BoardView.LIFT_FLIGHT)
	var head := _local(_hero.point("head"))
	if report.lift_special:
		_flash("shockwave", head + Vector2(0, 40), 0.3, 1.6, 0.4, 0.0, true)
		Sfx.play(&"boom")
	_hero.daze()
	_hero_hit(report, "boom" if report.lift_special else "bonk", &"dizzy")


## The boss drinks its potion and swells into its next form, in a cloud of green smoke.
func play_transform() -> void:
	if _monster.has_clip(&"drink_transform"):
		_monster.react(&"drink_transform", 2.0)
		Sfx.play(&"charge")
		await get_tree().create_timer(1.1).timeout
	_flash("poof_green", _local(_monster.point("head")) + Vector2(0, 80), 0.8, 1.8, 0.5)
	Sfx.play(&"boom")
	impact.emit(0.6, 0.08)
	await get_tree().create_timer(0.25).timeout


## `clip` if the monster has it, else its plain attack: the act 1 Orcs are drawn with attack
## and special clips rather than the Shield Orc's throw and charge.
func _monster_clip(clip: StringName) -> StringName:
	if _monster.has_clip(clip) or not _monster.has_clip(&"attack"):
		return clip
	return &"attack"


func _hero_hit(report: TurnReport, comic: String, pose: StringName) -> void:
	_hero.react(pose, 1.0)
	_hero.flash()
	_hero.set_health(_state.hero_health())
	var head := _local(_hero.point("head"))
	_sparks.flare(head + Vector2(0, 40), HURT_SPARK, 2.0)
	_punch(head + Vector2(0, 40), 0.05)
	if report.monster_critical:
		_comic("critical", Vector2(SIZE.x / 2, 190), 1.0, 0.8)
		_flash("shockwave", head + Vector2(0, 60), 0.2, 1.6, 0.4, 0.0, true)
		Sfx.play(&"crit")
		slow_motion.emit(0.3, 0.45)
	else:
		_comic(comic, head + Vector2(110, -40))
	_comic("ouch", head + Vector2(-30, -10), 0.6)
	_float("-%d" % report.monster_attack, HERO_FEET + Vector2(0, -200), WARN, FLOAT_SIZE + (40 if report.monster_critical else 16))
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
	# Only now fade: set_parallel() here would start the fade alongside the hold.
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(sprite, "scale", full * 1.2, 0.2)
	tween.tween_callback(sprite.queue_free)


## A one-shot effect image that grows from `from_scale` to `to_scale` and fades.
func _flash(effect: String, at: Vector2, from_scale: float, to_scale: float, seconds: float, angle := 0.0, additive := false) -> void:
	if _play_effect_clip(effect, at, (from_scale + to_scale) / 2, angle, additive):
		return
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


## Plays the frame-by-frame version of `effect` once, if there is one.
func _play_effect_clip(effect: String, at: Vector2, size: float, angle: float, additive: bool) -> bool:
	if not _combat_anim.has(effect):
		return false
	var path: String = _combat_anim[effect].get("path", COMBAT_DIR + "anim/" + effect + ".png")
	if not ResourceLoader.exists(path):
		return false
	var info: Dictionary = _combat_anim[effect]
	var sprite := _sprite(path, at, _fx)
	var frames := int(info.get("frames", 8))
	var columns := int(info.get("columns", 4))
	sprite.hframes = columns
	sprite.vframes = ceili(float(frames) / columns)
	sprite.rotation = angle
	sprite.scale = Vector2.ONE * size
	if additive:
		var blend := CanvasItemMaterial.new()
		blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = blend
	# Bound to the sprite, so the tween ends with it if the fight clears its effects early.
	var tween := sprite.create_tween()
	tween.tween_method(func(f: float) -> void: sprite.frame = mini(int(f), frames - 1), 0.0, float(frames), frames / float(info.get("fps", 24)))
	tween.tween_callback(sprite.queue_free)
	return true


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


## Waits `seconds`, or not at all when there is nothing to wait for.
func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout


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


func _load_or_null(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## A global position (from CharacterRig.point) in the stage's own coordinates.
func _local(global_point: Vector2) -> Vector2:
	return _fx.to_local(global_point)


## The camera jolts in toward `at` and springs back: a blow landing.
func _punch(at: Vector2, amount: float) -> void:
	var zoom := _zoom
	var focus := _focus
	_set_camera(zoom + amount, focus.lerp(at, 0.25))
	_camera(zoom, focus, 0.2)


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
## A little sideways scatter and tilt keeps numbers from the same move from stacking.
func _float(text: String, at: Vector2, color: Color, font_size := FLOAT_SIZE) -> void:
	at.x += randf_range(-30.0, 30.0)
	var floater := {"text": text, "at": at, "color": color, "size": font_size, "t": 0.0, "tilt": randf_range(-0.14, 0.14)}
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
	_draw_bar(HERO_BAR, _state.hero_hp, _hero_trail, _state.rules.hero_max_hp, HP_HERO)
	_draw_bar(MONSTER_BAR, _state.monster_hp, _monster_trail, _state.monster.max_hp, HP_MONSTER, true)
	_draw_text("HIỆP SĨ", Vector2(HERO_BAR.x + 4, ROW_Y + LABEL_SIZE), LABEL_SIZE, TEXT)
	var monster_name := _state.monster.display_name.to_upper()
	_draw_text(monster_name, Vector2(MONSTER_BAR.x + BAR_SIZE.x - 4 - _text_width(monster_name, LABEL_SIZE), ROW_Y + LABEL_SIZE), LABEL_SIZE, TEXT)
	_draw_shield_layers()
	_draw_gold()
	_draw_statuses(HERO_BAR.x + ROW_ICONS_X)
	_draw_sky_icons(COUNTDOWN_AT + Vector2(0, 76))
	_draw_turn_plaque(COUNTDOWN_AT)
	if _state.outcome == BattleState.Outcome.ONGOING and _state.monster.counterattacks:
		_draw_countdown(COUNTDOWN_AT + Vector2(0, 76))
	if _hint:
		var box := Rect2(30, 110, SIZE.x - 60, 96)
		_rounded(box, Color(0, 0, 0, 0.6), 18)
		_overlay.draw_multiline_string(ThemeDB.fallback_font, box.position + Vector2(20, 40), _hint, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 40, 32, 2, TEXT)
	if _goal:
		_draw_goal(Vector2(SIZE.x / 2, 236.0 if _hint else 176.0))
	for floater in _floaters:
		var t: float = floater["t"]
		var at: Vector2 = floater["at"] + Vector2(0, -FLOAT_RISE * ease(t, 0.4))
		_overlay.draw_set_transform(at, floater["tilt"], Vector2.ONE * _pop_scale(t))
		_draw_sticker(floater["text"], floater["size"], floater["color"], 1.0 - t * t * t, floater.get("font"))
		_overlay.draw_set_transform(Vector2.ZERO)


## A floating number drawn like a sticker, centered on the origin: a drop shadow, a thick
## dark rim, a ring of `color`, and a warm white core.
func _draw_sticker(text: String, font_size: int, color: Color, alpha: float, font: Font = null) -> void:
	if not font:
		font = ThemeDB.fallback_font
	var at := Vector2(-font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2, font_size * 0.35)
	_overlay.draw_string_outline(font, at + Vector2(4, 7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, FLOAT_RIM, Color(0, 0, 0, 0.35 * alpha))
	_overlay.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, FLOAT_RIM, Color(OUTLINE, alpha))
	_overlay.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, FLOAT_RING, Color(color.darkened(0.1), alpha))
	_overlay.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(FLOAT_CORE, alpha))


## Popping text: grows past full size in the first moments, then settles back to it.
static func _pop_scale(t: float) -> float:
	if t < 0.1:
		return lerpf(0.4, 1.35, t / 0.1)
	if t < 0.2:
		return lerpf(1.35, 1.0, (t - 0.1) / 0.1)
	return 1.0


## A framed, rounded bar with the numbers inside. `trail` is the health the bar showed a
## moment ago, drawn pale behind the real fill. Like a fighting game, each bar is anchored at
## its screen edge and drains toward the middle (the monster's, on the right: `from_right`).
## Low health throbs.
func _draw_bar(at: Vector2, value: int, trail: float, max_value: int, color: Color, from_right := false) -> void:
	var bar := Rect2(at, BAR_SIZE)
	_rounded(bar.grow(BAR_RIM), BAR_RIM_COLOR, BAR_RADIUS + BAR_RIM, 6)
	_rounded(bar, BAR_EMPTY, BAR_RADIUS)
	var fill := clampf(float(value) / max_value, 0.0, 1.0)
	if fill > 0.0 and fill <= LOW_HEALTH:
		color = color.lerp(Color.WHITE, 0.35 * absf(sin(Time.get_ticks_msec() / 1000.0 * 6.0)))
	_rounded(_bar_part(bar, clampf(trail / max_value, 0.0, 1.0), from_right), BAR_TRAIL, BAR_RADIUS)
	var filled := _bar_part(bar, fill, from_right)
	_rounded(filled, color, BAR_RADIUS)
	_rounded(Rect2(filled.position + Vector2(5, 4), Vector2(filled.size.x - 10, BAR_SIZE.y * 0.3)), Color(1, 1, 1, 0.32), 4)
	_draw_text_centered("%d/%d" % [value, max_value], bar.get_center() + Vector2(0, 10), 28, TEXT, _number_font)


func _text_width(text: String, font_size: int, font: Font = null) -> float:
	return (font if font else ThemeDB.fallback_font).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## `fraction` of `bar`, from its left edge or its right one.
static func _bar_part(bar: Rect2, fraction: float, from_right: bool) -> Rect2:
	var width := bar.size.x * fraction
	return Rect2(bar.position + Vector2(bar.size.x - width if from_right else 0.0, 0), Vector2(width, bar.size.y))


## One pip per layer in the row under the monster's bar, starting at its inner end; a damaged
## layer shows how much of it is left.
func _draw_shield_layers() -> void:
	var size := _state.rules.shield_layer_size
	var total := _state.monster.shield_layers
	if total == 0:
		return
	var pip := Vector2(36, 18)
	for i in total:
		var box := Rect2(Vector2(MONSTER_BAR.x + i * (pip.x + 10), ROW_Y + 6), pip)
		var left := clampi(_state.shield - i * size, 0, size)
		_rounded(box.grow(3), BAR_RIM_COLOR, 9, 3)
		_rounded(box, BAR_EMPTY, 6)
		var filled := _bar_part(box, float(left) / size, false)
		_rounded(filled, SHIELD, 6)
		_rounded(Rect2(filled.position + Vector2(3, 2), Vector2(filled.size.x - 6, pip.y * 0.3)), Color(1, 1, 1, 0.35), 3)


## The coin and how much gold the hero has, in the row under the hero's bar, at its inner end.
func _draw_gold() -> void:
	var text := str(_state.gold)
	var right := HERO_BAR.x + BAR_SIZE.x
	var text_x := right - _text_width(text, 30, _number_font)
	var coin := _coin_center()
	coin.x = text_x - 8 - COIN_SIZE / 2
	if _coin:
		_overlay.draw_texture_rect(_coin, Rect2(coin - Vector2.ONE * COIN_SIZE / 2, Vector2.ONE * COIN_SIZE), false)
	else:
		_overlay.draw_circle(coin, COIN_SIZE * 0.4, GOLD)
	_draw_text(text, Vector2(text_x, ROW_Y + 28), 30, GOLD, _number_font)


## Poison, toad and broom on the hero, as icons by their name with the moves left.
func _draw_statuses(x: float) -> void:
	var statuses: Array = []
	if _state.poison_turns > 0:
		statuses.append(["poison", _state.poison_turns])
	if _state.toad_turns > 0:
		statuses.append(["toad", _state.toad_turns])
	if _state.broom_turns > 0:
		statuses.append(["broom", _state.broom_turns])
	for status in statuses:
		var icon := _status_icon(status[0])
		var rect := Rect2(Vector2(x, ROW_Y - 4), Vector2(44, 44))
		if icon:
			_overlay.draw_texture_rect(icon, rect, false)
		_draw_text(str(status[1]), Vector2(rect.end.x - 6, rect.end.y), 26, TEXT, _number_font)
		x += 58.0


## The hour to the left of the countdown, and the weather unless it's clear to its right.
func _draw_sky_icons(center: Vector2) -> void:
	var sides := {_state.time_of_day: -1.0}
	if _state.weather != Weather.DEFAULT_SKY:
		sides[_state.weather] = 1.0
	for name: StringName in sides:
		var icon := _weather_icon(name)
		if icon:
			var at := center + Vector2(sides[name] * SKY_ICON_GAP, 0)
			_overlay.draw_texture_rect(icon, Rect2(at - Vector2.ONE * SKY_ICON / 2, Vector2.ONE * SKY_ICON), false)


func _weather_icon(name: StringName) -> Texture2D:
	if not _weather_icons.has(name):
		var path := WEATHER_DIR + "icon_%s.png" % name
		_weather_icons[name] = load(path) if ResourceLoader.exists(path) else null
	return _weather_icons[name]


func _status_icon(name: String) -> Texture2D:
	if not _status_icons.has(name):
		var path := STATUS_DIR + name + ".png"
		_status_icons[name] = load(path) if ResourceLoader.exists(path) else null
	return _status_icons[name]


## The level's goals as picture chips, centred on `center`: squares of the color to gather,
## crates to break and items to bring down with how many so far, and the moves left.
func _draw_goal(center: Vector2) -> void:
	var level := _goal.level
	var chips: Array = []
	if level.collect > 0 and level.collect_color >= 0:
		chips.append(["collect", "%d/%d" % [mini(_goal.collected, level.collect), level.collect]])
	if level.break_crates:
		chips.append(["crate", "%d/%d" % [mini(_goal.broken, level.crates), level.crates]])
	if level.break_cover:
		chips.append(["cover", "%d/%d" % [mini(_goal.uncovered, level.cover_count), level.cover_count]])
	if level.rescue > 0:
		chips.append(["rescue", "%d/%d" % [mini(_goal.rescued, level.rescue), level.rescue]])
	if level.turns > 0:
		chips.append(["turns", str(_goal.turns_left())])
	if chips.is_empty():
		return
	const ICON := 40.0
	const HEIGHT := 54.0
	const GAP := 14.0
	var widths: Array[float] = []
	var total := -GAP
	for chip in chips:
		var w := ICON + 10.0 + _text_width(chip[1], 34, _number_font) + 28.0
		widths.append(w)
		total += w + GAP
	var x := center.x - total / 2
	for i in chips.size():
		var box := Rect2(Vector2(x, center.y - HEIGHT / 2), Vector2(widths[i], HEIGHT))
		var urgent: bool = chips[i][0] == "turns" and _goal.turns_left() <= 3
		_rounded(box, Color(0.6, 0.1, 0.1, 0.8) if urgent else Color(0, 0, 0, 0.55), 27)
		var icon := Rect2(box.position + Vector2(12, (HEIGHT - ICON) / 2), Vector2(ICON, ICON))
		match chips[i][0]:
			"collect":
				var tint: Color = BoardView.BLOCK_COLORS.get(level.collect_color, GOLD)
				_box.bg_color = tint
				_box.set_corner_radius_all(9)
				_box.shadow_size = 0
				_box.draw(_overlay.get_canvas_item(), icon.grow(-4))
			"crate":
				var crate := _goal_art.texture(Cell.obstacle(level.obstacle, 1))
				if crate:
					_overlay.draw_texture_rect(crate, icon, false)
			"cover":
				var cover := _goal_art.overlay(level.cover, level.cover_layers)
				if cover:
					_overlay.draw_texture_rect(cover, icon, false)
			"rescue":
				var item := _goal_art.texture(Cell.obstacle(level.rescue_item))
				if item:
					_overlay.draw_texture_rect(item, icon, false)
			"turns":
				# An hourglass.
				var c := icon.get_center()
				var s := ICON * 0.36
				_overlay.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, -s), c + Vector2(s, -s), c, ]), TEXT)
				_overlay.draw_colored_polygon(PackedVector2Array([c, c + Vector2(s, s), c + Vector2(-s, s)]), TEXT)
		_draw_text(chips[i][1], Vector2(icon.end.x + 10, box.position.y + 41), 34, TEXT, _number_font)
		x += widths[i] + GAP


## Where the coin sits, give or take the width of the number beside it.
func _coin_center() -> Vector2:
	return Vector2(HERO_BAR.x + BAR_SIZE.x - 40 - COIN_SIZE / 2, ROW_Y + COIN_SIZE / 2)


func _rounded(rect: Rect2, color: Color, radius: int, shadow := 0) -> void:
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	_box.bg_color = color
	_box.set_corner_radius_all(radius)
	_box.shadow_size = shadow
	_box.shadow_offset = Vector2(0, shadow * 0.6)
	_box.draw(_overlay.get_canvas_item(), rect)


## Moves left until the monster attacks, between the bars like a round timer; turns red one
## move ahead, with a warning underneath.
## "Lượt N" on a wooden plaque between the health bars, a pair of crossed swords either side
## that swing apart and clash every SWORD_CLASH seconds.
func _draw_turn_plaque(center: Vector2) -> void:
	var size := Vector2(180, 58)
	var box := Rect2(center - size / 2, size)
	var t := fmod(Time.get_ticks_msec() / 1000.0, SWORD_CLASH)
	# Apart, then a fast swing in and a ring: the clash lands at CLASH_AT.
	var swing := 0.0
	if t < CLASH_AT:
		swing = ease(t / CLASH_AT, 2.4)
	else:
		swing = 1.0 - ease(clampf((t - CLASH_AT) / 0.5, 0.0, 1.0), 0.5)
	var spread := lerpf(0.0, 0.5, swing)
	for side in [-1.0, 1.0]:
		var at := center + Vector2(side * (size.x / 2 + 26), 2)
		for k in [-1.0, 1.0]:
			_draw_sword(at, k * (0.62 - spread), SWORD_SIZE if _hud_swords.size() == 2 else 72.0, k)
		_draw_clash(at + Vector2(0, -18), t - CLASH_AT)
	if _plaque:
		_overlay.draw_texture_rect(_plaque, Rect2(center - size / 2, size), false)
		_draw_text_centered("Lượt %d" % (_state.moves + 1), center + Vector2(0, 13), 36, TEXT)
		return
	_box.bg_color = PLAQUE
	_box.border_color = PLAQUE_RIM
	_box.set_border_width_all(4)
	_box.set_corner_radius_all(16)
	_box.shadow_size = 6
	_box.shadow_offset = Vector2(0, 4)
	_box.draw(_overlay.get_canvas_item(), box)
	_box.set_border_width_all(0)
	_draw_text_centered("Lượt %d" % (_state.moves + 1), center + Vector2(0, 14), 38, TEXT)


## Sparks where the blades meet, `since` seconds after they clash.
func _draw_clash(at: Vector2, since: float) -> void:
	if since < 0.0:
		return
	if _clash_spark:
		var frame := int(since * SPARK_FPS)
		if frame >= SPARK_FRAMES:
			return
		var cel := _clash_spark.get_width() / SPARK_COLUMNS
		var region := Rect2((frame % SPARK_COLUMNS) * cel, (frame / SPARK_COLUMNS) * cel, cel, cel)
		var rect := Rect2(at - Vector2.ONE * SPARK_SIZE / 2, Vector2.ONE * SPARK_SIZE)
		_overlay.draw_texture_rect_region(_clash_spark, rect, region)
	elif since < 0.18:
		var flash := 1.0 - since / 0.18
		_overlay.draw_circle(at, 18.0 * flash + 6.0, Color(1, 0.95, 0.6, 0.8 * flash))


## A sword standing upright at `at`, leaned by `angle` (0 = upright). `side` picks the painted
## left (-1) or right (+1) sword when there are any.
func _draw_sword(at: Vector2, angle: float, length: float, side := 1.0) -> void:
	if _hud_swords.size() == 2:
		var texture := _hud_swords[0 if side < 0.0 else 1]
		_overlay.draw_set_transform(at, angle - side * SWORD_LEAN, Vector2.ONE)
		_overlay.draw_texture_rect(texture, Rect2(-Vector2.ONE * length / 2, Vector2.ONE * length), false)
		_overlay.draw_set_transform(Vector2.ZERO)
		return
	if _sword == null:
		_overlay.draw_set_transform(at, angle, Vector2.ONE)
		_overlay.draw_line(Vector2(0, length * 0.4), Vector2(0, -length * 0.5), Color(0.85, 0.88, 0.92), 6.0)
		_overlay.draw_line(Vector2(-12, length * 0.2), Vector2(12, length * 0.2), GOLD, 6.0)
	else:
		_overlay.draw_set_transform(at, angle, Vector2.ONE)
		_overlay.draw_texture_rect(_sword, Rect2(Vector2(-length / 2, -length / 2), Vector2(length, length)), false)
	_overlay.draw_set_transform(Vector2.ZERO)


func _draw_countdown(center: Vector2) -> void:
	var warn := _state.attacks_next_move()
	var radius := 26.0
	if warn:
		radius += 5.0 * absf(sin(Time.get_ticks_msec() / 1000.0 * 6.0))
	_overlay.draw_circle(center + Vector2(0, 4), radius + BAR_RIM, Color(0, 0, 0, 0.35))
	_overlay.draw_circle(center, radius + BAR_RIM, BAR_RIM_COLOR)
	_overlay.draw_circle(center, radius, WARN if warn else BAR_EMPTY)
	_draw_text_centered(str(_state.countdown), center + Vector2(0, 12), 34, TEXT, _number_font)
	if warn:
		if _state.next_attack_is_critical():
			_draw_text_centered("SẮP CHÍ MẠNG %d!" % roundi(_state.monster.attack * _state.rules.monster_crit_multiplier), center + Vector2(0, radius + 44), 30, Color(1, 0.85, 0.2))
		else:
			_draw_text_centered("SẮP ĐÁNH %d!" % _state.monster.attack, center + Vector2(0, radius + 44), 30, WARN.lightened(0.3))


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
