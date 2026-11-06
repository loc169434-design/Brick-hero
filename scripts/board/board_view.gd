class_name BoardView
extends Node2D
## Draws a LinkGame, shows the link the player is tracing, and replays each move's chain round
## by round. Tiles come from the chosen theme in assets/tiles/ (see TileArt). Squares playing an
## animation are drawn by their sprite instead of by _draw(), so a cleared tile never shows
## through its own burst. Without art, each color falls back to a square with its own symbol.
##
## The board is never still (issue #17): it sits on a bright panel, idle tiles breathe and a
## sheen sweeps across them, linked tiles lift, glow and tremble with scared faces, joined only
## where their frames meet, and cleared tiles shatter into light that flies up to the fight
## (orb_targets). Tiles cast shadows so they read as raised blocks.

signal move_finished(result: MoveResult)
signal restarted
## Something hit hard enough to feel: `strength` 0..1 of screen shake, `freeze` seconds of hit-stop.
signal impact(strength: float, freeze: float)

const CELL := 140
## The tile clips are paced for a showcase; replays run them faster to keep turns snappy.
const REPLAY_SPEED := 2.0
const FLASH_TIME := 0.22
const FALL_TIME := 0.2
const POPUP_TIME := 0.9
const POPUP_SIZE := 110
## How long the newest square of a link stays puffed up after it's taken.
const LINK_POP_TIME := 0.15
## While a link would set specials off, the squares it would blow up besides its own get a
## pulsing rim of this color, and the squares that would stay are dimmed.
const BLAST_RIM := Color(1.0, 0.55, 0.1)
const BLAST_DIM := Color(0.05, 0.03, 0.1, 0.4)
## Semitones above the first note for each square of a link: a major pentatonic run, so any
## length sounds like a tune rising instead of a siren.
const LINK_NOTES := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]

const BLOCK_COLORS := {
	Cell.BlockColor.RED: Color(0.9, 0.28, 0.3),
	Cell.BlockColor.GREEN: Color(0.27, 0.65, 0.35),
	Cell.BlockColor.YELLOW: Color(0.96, 0.77, 0.1),
	Cell.BlockColor.PURPLE: Color(0.56, 0.31, 0.78),
}
const STAR_LINK_COLOR := Color(1, 1, 1)
const GLOW_PATH := "res://assets/fx/particles/glow.png"
const SPARK_PATH := "res://assets/fx/particles/spark.png"
## Where the bomb's fuse burns, on its 128 px art (fuse_tip in assets/tiles/specials/specials.json).
const BOMB_FUSE := Vector2(88, 28)
## How big a bare special is drawn, against its square.
const SPECIAL_SCALE := 0.94
## How far the star sways either way, in radians. Its art is lit from the top left, so it
## doesn't spin all the way round.
const STAR_SWAY := 0.12
const STAR_GOLD := Color(0.85, 0.55, 0.1)
const FUSE_FIRE := Color(1.0, 0.6, 0.15)
const SPECIAL_NAMES := {
	Cell.Special.LIGHTNING: "SÉT",
	Cell.Special.BOMB: "BOM",
	Cell.Special.RAINBOW: "SAO",
}
const BOARD_BG := Color(0.1, 0.1, 0.15)
## Where the board's surface art sits, relative to the board, which is placed at (50, 530):
## the backdrop fills the screen below the fight (from y 500), the panel frames the 7×8 grid.
const BACKDROP_AT := Vector2(-50, -30)
const PANEL_AT := Vector2(-30, -30)
const SURFACE_DIR := "res://assets/ui/"
const SHINE_PATH := "res://assets/tiles/shine.png"
const GLOW_OUTLINE_PATH := "res://assets/tiles/glow_outline.png"
## Sparks around a critical tile: 8 frames of 192 px in a row, the 128 px tile in the middle.
const CRIT_SPARK_PATH := "res://assets/tiles/crit_spark.png"
const CRIT_SPARK_FRAMES := 8
const CRIT_SPARK_FPS := 14.0
## A link through a critical tile glows this color.
const CRIT_LINK_COLOR := Color(1.0, 0.45, 0.1)
## A critical tile's frame: gold, to stand out on its red face.
const CRIT_FRAME_COLOR := Color(1.0, 0.86, 0.25)
## The glow outline frames a 128 px tile on a 192 px canvas.
const GLOW_OUTLINE_RATIO := 192.0 / 128.0
## Idle tiles: how far they bob (pixels) and how fast; neighbors are a little out of step.
const BREATH_LIFT := 2.5
const BREATH_SPEED := 2.2
## A sheen sweeps diagonally across the board once every this many seconds.
const SHINE_PERIOD := 4.5
const SHINE_TIME := 0.5
## Linked tiles lift this far and grow this much, and tremble this many pixels side to side.
const LINK_LIFT := 8.0
const LINK_GROW := 6.0
const LINK_TREMBLE := 1.8
## How long a tile let go from the link looks relieved.
const RELIEF_TIME := 0.7
## How long a crate or rock shakes after losing a layer.
const KNOCK_TIME := 0.3
## A break-up clip is drawn this many squares wide, so splinters fly past the square.
const BREAK_SCALE := 1.6
## Dust thrown off when a crate or rock breaks.
const BLOCKER_DUST := {"crate": Color(0.66, 0.45, 0.24), "rock": Color(0.6, 0.6, 0.62)}
## Tiles cast their shadow this far down and right, so they read as raised blocks.
const SHADOW_DROP := Vector2(3, 8)
const SHADOW := Color(0.22, 0.12, 0.04, 0.42)
## The joint between two linked tiles: from this far out of one tile's center to the same
## distance short of the next, so it covers the frames where they meet and not their faces.
const JOINT_REACH := 0.3
const JOINT_WIDTH := 22.0
## The screen is this tall; the board's backdrop stretches to its bottom.
const SCREEN_HEIGHT := 1920.0
## A round of clears sends at most this many orbs to the fight.
const MAX_ORBS := 14
const GRID_LINE := Color(1, 1, 1, 0.05)
const TEXT := Color(0.92, 0.92, 0.96)
const TEXT_DIM := Color(0.6, 0.6, 0.7)

## Negative picks a random seed each game.
@export var seed_value := -1
@export_enum("training", "orc_shield") var tile_theme := "training"

var game: LinkGame
## The link being traced, in order.
var path: Array[Vector2i] = []

var _art: TileArt
var _special_art := SpecialArt.new()
var _obstacles := ObstacleArt.new()
## Crates and rocks that just lost a layer shake until this time, by square.
var _knocked := {}
## Placeholder tile style per color, used only when there's no tile art.
var _styles := {}
## What's on screen. Lags behind the model while a chain is being replayed.
var _shown := {}
var _flashing := {}
## Squares mid-fall: landing position -> rows they still have to fall at _fall_t = 0.
var _falling := {}
var _fall_t := 1.0
var _fall_tween: Tween
## Squares currently drawn by an animation: position -> AnimatedSprite2D.
var _sprites := {}
var _busy := false
## Set while something off the board is playing out (a hero skill), so no link starts meanwhile.
var locked := false
## Set once the fight is decided, until restart.
var _finished := false
var _end_title := ""
var _end_subtitle := ""
## Bumped on restart so a replay still waiting on a timer knows to stop.
var _generation := 0
var _popup_text := ""
var _popup_size := POPUP_SIZE
var _popup_alpha := 0.0
var _popup_scale := 1.0
var _popup_tween: Tween
## 1 just after a square joins the link, easing to 0.
var _link_pop := 0.0
var _link_pop_tween: Tween
var _sprite_layer: Node2D
## Blasts of specials going off, above the tiles.
var _special_fx: SpecialFx
## Drawn above the sprites: the link being traced, popups and the end screen.
var _overlay: Node2D
## Tile shards (normal blend) and sparks, glows and orbs (added light).
var _shards: TileParticles
var _lights: TileParticles
## Backdrop, panel and slot art for the current theme; missing pieces are skipped.
var _surface := {}
var _shine: Texture2D
var _glow_outline: Texture2D
var _crit_spark: Texture2D
var _glow: Texture2D
var _spark: Texture2D
## The transform _draw() is drawing with while it draws a special, for the sparks on top.
var _xform := Transform2D.IDENTITY
var _shadow_box := StyleBoxFlat.new()
## Square -> time until which a tile let go from the link looks relieved.
var _relief := {}
## Squares the link being traced would set its specials off on, besides its own, for the
## path it was worked out for: a star's targets and a fusion's reach show before letting go.
var _blast := {}
var _blast_path: Array[Vector2i] = []
var _time := 0.0
## Where light from each tile color flies when cleared, in global coordinates, by
## Cell.BlockColor. Colors without a target just burst in place.
var orb_targets := {}


func _ready() -> void:
	_sprite_layer = Node2D.new()
	add_child(_sprite_layer)
	_shards = TileParticles.new()
	add_child(_shards)
	_special_fx = SpecialFx.new()
	_special_fx.cell_size = CELL
	add_child(_special_fx)
	_lights = TileParticles.new()
	_lights.additive = true
	add_child(_lights)
	_overlay = Node2D.new()
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	_art = TileArt.new(tile_theme)
	_shine = load(SHINE_PATH) if ResourceLoader.exists(SHINE_PATH) else null
	_glow_outline = load(GLOW_OUTLINE_PATH) if ResourceLoader.exists(GLOW_OUTLINE_PATH) else null
	_crit_spark = load(CRIT_SPARK_PATH) if ResourceLoader.exists(CRIT_SPARK_PATH) else null
	_glow = load(GLOW_PATH) if ResourceLoader.exists(GLOW_PATH) else null
	_spark = load(SPARK_PATH) if ResourceLoader.exists(SPARK_PATH) else null
	_shadow_box.set_corner_radius_all(22)
	_load_surface()
	new_game()


## An obstacle thrown onto the board lands on a random tile with a thud. Waits for the board to
## be still and the finger off it, so it never lands mid-link.
func drop_obstacle(kind: String, layers: int) -> void:
	var generation := _generation
	while _busy or not path.is_empty():
		await get_tree().process_frame
		if generation != _generation or _finished:
			return
	if _finished:
		return
	var placed := game.place(kind, 1, layers)
	if placed.is_empty():
		return
	var p: Vector2i = placed[0]
	_shown = _snapshot()
	_falling[p] = 3
	_fall_t = 0.0
	_knocked[p] = _time + KNOCK_TIME + 0.25
	await _animate_falls(0.25, generation)
	_shards.shatter((Vector2(p) + Vector2(0.5, 0.5)) * CELL, BLOCKER_DUST.get(kind, BLOCKER_DUST["crate"]), 12)
	Sfx.play(&"thud", 0.8)
	impact.emit(0.35, 0.04)


## Sets the board up for a level after a restart, without starting over: a fixed deal when
## `seed` is 0 or more, then `setup` gets the LinkGame to put obstacles on.
func prepare(seed := -1, setup := Callable()) -> void:
	if seed >= 0:
		game = LinkGame.new(BoardRules.new(), seed)
	if setup.is_valid():
		setup.call(game)
	_shown = _snapshot()
	_redraw()


func new_game() -> void:
	_generation += 1
	_clear_sprites()
	_special_fx.clear()
	_shards.clear()
	_lights.clear()
	_flashing.clear()
	_falling.clear()
	_relief.clear()
	path.clear()
	if _fall_tween:
		_fall_tween.kill()
	if _popup_tween:
		_popup_tween.kill()
	_popup_alpha = 0.0
	_finished = false
	game = LinkGame.new(BoardRules.new(), seed_value)
	_special_fx.board_size = board_size()
	_shown = _snapshot()
	_busy = false
	_redraw()
	restarted.emit()


## Stops play and has every tile react to the result. Safe to call more than once.
func finish(won: bool, subtitle := "chạm để chơi lại") -> void:
	if _finished:
		return
	_finished = true
	path.clear()
	_end_title = "CHIẾN THẮNG" if won else "THẤT BẠI"
	_end_subtitle = subtitle
	_clear_sprites()
	_play_on_every_square(&"win" if won else &"lose")
	_redraw()


func is_finished() -> bool:
	return _finished


## Up to `count` idle tiles play `clip` at normal speed without holding up play.
## Does nothing if the theme has no such clip (Training tiles don't taunt, for one).
func play_reaction(clip: StringName, count: int) -> void:
	if _busy or _finished or not _art.has_clip(clip):
		return
	var idle := _shown.keys().filter(func(p: Vector2i) -> bool: return not _shown[p].is_special() and not _shown[p].is_blocker() and not _sprites.has(p))
	idle.shuffle()
	for p in idle.slice(0, count):
		_play_clip(p, clip, null, true, 1.0)


## Switches between tile themes. Waits for the current replay so no clip changes art mid-play.
func set_tile_theme(theme: String) -> void:
	if _busy or theme == tile_theme:
		return
	tile_theme = theme
	_art = TileArt.new(theme)
	_load_surface()
	_clear_sprites()
	_redraw()


func next_tile_theme() -> void:
	var themes := TileArt.THEMES
	set_tile_theme(themes[(themes.find(tile_theme) + 1) % themes.size()])


func _load_surface() -> void:
	_surface.clear()
	for part in ["backdrop", "panel", "slot"]:
		var art_path := "%sboard_%s_%s.png" % [SURFACE_DIR, part, tile_theme]
		if ResourceLoader.exists(art_path):
			_surface[part] = load(art_path)


func board_size() -> Vector2:
	return Vector2(game.board.columns, game.board.rows) * CELL


func can_act() -> bool:
	return not _busy and not _finished and not locked


## The square under `local_pos`, if it's within `reach` (a fraction of a square) of its center.
## Cutting a corner between squares then picks nothing rather than a diagonal neighbor.
func cell_at(local_pos: Vector2, reach := 0.5) -> Vector2i:
	var p := Vector2i((local_pos / CELL).floor())
	var center := (Vector2(p) + Vector2(0.5, 0.5)) * CELL
	if not game.board.is_inside(p) or local_pos.distance_to(center) > CELL * reach:
		return Vector2i(-1, -1)
	return p


func begin_link(p: Vector2i) -> void:
	path.clear()
	if can_act() and game.can_extend(path, p):
		path.append(p)
		_on_link_grew()
	_overlay.queue_redraw()


## Adds `p` to the link, or steps back if `p` is the square before the last one.
func extend_link(p: Vector2i) -> void:
	if path.is_empty() or p == path[-1] or not can_act():
		return
	if path.size() >= 2 and p == path[-2]:
		_let_go([path.pop_back()])
		Sfx.play(&"untick", _link_pitch(path.size()), 0.0, true)
	elif game.can_extend(path, p):
		path.append(p)
		_on_link_grew()
	_overlay.queue_redraw()


## Each new square plays the next note up and puffs up; reaching a special adds a chime.
func _on_link_grew() -> void:
	var count := path.size()
	Sfx.play(&"tick", _link_pitch(count), 0.0, true)
	if count in [game.rules.lightning_link, game.rules.bomb_link, game.rules.star_link]:
		Sfx.play(&"charge", 1.0, -2.0)
	_link_pop = 1.0
	if _link_pop_tween:
		_link_pop_tween.kill()
	_link_pop_tween = create_tween()
	_link_pop_tween.tween_method(_set_link_pop, 1.0, 0.0, LINK_POP_TIME).set_ease(Tween.EASE_OUT)


func _link_pitch(count: int) -> float:
	var note: int = LINK_NOTES[clampi(count - 1, 0, LINK_NOTES.size() - 1)]
	return pow(2.0, note / 12.0)


func _set_link_pop(t: float) -> void:
	_link_pop = t
	_overlay.queue_redraw()


## Plays the link if it's long enough; a short one is just let go.
func end_link() -> void:
	var played := false
	if can_act() and path.size() >= game.rules.min_link:
		var before := _snapshot()
		var result := game.play(path)
		if result:
			played = true
			_replay(result, before)
	if not played:
		_let_go(path)
	path.clear()
	_overlay.queue_redraw()


# --- replay ----------------------------------------------------------------

func _replay(result: MoveResult, before: Dictionary) -> void:
	var generation := _generation
	_busy = true
	_relief.clear()
	_clear_sprites()
	_shown = before
	if result.path.size() >= game.rules.lightning_link:
		_show_popup("NỐI %d!" % result.path.size())

	for step in result.steps:
		if step.chain >= 2:
			# Each round further down the chain shouts a little louder.
			_show_popup("CHUỖI x%d" % step.chain, mini(POPUP_SIZE + 16 * (step.chain - 2), 170))
		# Every square in the round bursts at once; the round waits for the longest burst.
		var burst := 0.0
		for h in step.hit:
			if _shown.has(h["at"]):
				_shown[h["at"]].layers = h["layers"]
				_knocked[h["at"]] = _time + KNOCK_TIME
		if not step.hit.is_empty() or not step.broken.is_empty():
			Sfx.play(&"thud", 1.2)
		for r in step.rescued:
			_rescue_item(r["at"], r["kind"])
		for i in step.cleared.size():
			var cleared_cell: Cell = step.cleared_cells[i]
			if cleared_cell.is_blocker():
				var broke := 0.0 if cleared_cell.is_item() else _play_break(step.cleared[i], cleared_cell.blocker)
				burst = maxf(burst, broke)
				continue
			# Specials have no tile to burst: they flash, and their blast does the rest.
			var seconds := 0.0 if cleared_cell.is_special() else _play_clip(step.cleared[i], &"combo", cleared_cell, false)
			if seconds > 0.0:
				burst = maxf(burst, seconds)
			else:
				_flashing[step.cleared[i]] = true
		_redraw()
		_burst_into_light(step)
		_feel_step(step, result.path.size())
		_special_fx.play_step(step)
		await get_tree().create_timer(burst if burst > 0.0 else FLASH_TIME).timeout
		if generation != _generation:
			return

		_flashing.clear()
		for p in step.cleared:
			_shown.erase(p)
			_free_sprite(p)
		for s in step.spawned:
			_shown[s["at"]] = Cell.new(s["color"], s["special"])
		if not step.spawned.is_empty():
			Sfx.play(&"special")
		# Lift every falling square first: a square's landing spot can be another's start.
		var carried: Array[Cell] = []
		for fall in step.falls:
			carried.append(fall["cell"] if fall.has("cell") else _shown.get(fall["from"]))
			_free_sprite(fall["from"])
		for fall in step.falls:
			_shown.erase(fall["from"])
		for i in step.falls.size():
			var to: Vector2i = step.falls[i]["to"]
			_shown[to] = carried[i]
			_falling[to] = to.y - step.falls[i]["from"].y
		await _animate_falls(FALL_TIME, generation)
		if generation != _generation:
			return
		for fall in step.falls:
			_play_clip(fall["to"], &"land")
		if not step.falls.is_empty():
			Sfx.play(&"land", 1.0, -6.0)

	if result.reshuffled:
		_show_popup("XÁO BẢNG")
		Sfx.play(&"shuffle")
	_shown = _snapshot()
	_busy = false
	_redraw()
	move_finished.emit(result)


## Every cleared square shatters and flares in its color; some send an orb up to the fight.
func _burst_into_light(step: ClearStep) -> void:
	var orbs := 0
	for i in step.cleared.size():
		var cell: Cell = step.cleared_cells[i]
		if cell.is_blocker():
			continue
		var center := (Vector2(step.cleared[i]) + Vector2(0.5, 0.5)) * CELL
		var color: Color = BLOCK_COLORS.get(cell.color, STAR_LINK_COLOR)
		if cell.is_special():
			_shards.shatter(center, color, 12)
			_lights.flare(center, color, 2.2)
		else:
			_shards.shatter(center, color, 5)
			_lights.flare(center, color, 1.0)
		if orb_targets.has(cell.color) and orbs < MAX_ORBS:
			_lights.orb(center, to_local(orb_targets[cell.color]), color.lightened(0.15), orbs * 0.03)
			orbs += 1


## Sound and shake for one round going off: stronger for longer links, later rounds of a
## chain, and most of all for specials and fusions, which also freeze the frame for a moment.
func _feel_step(step: ClearStep, link_length: int) -> void:
	Sfx.play(&"pop", pow(2.0, (step.chain - 1) * 2 / 12.0))
	var strength := 0.15 + 0.04 * (link_length - game.rules.min_link)
	if step.chain >= 2:
		strength = 0.15 + 0.08 * step.chain
	var freeze := 0.0
	if not step.triggered.is_empty():
		Sfx.play(&"boom")
		strength += 0.3 + 0.1 * step.triggered.size()
		freeze = 0.07
	if not step.fusions.is_empty():
		strength += 0.35
		freeze = 0.12
	impact.emit(minf(strength, 1.0), freeze)


func _animate_falls(seconds: float, generation: int) -> void:
	if _falling.is_empty():
		return
	_fall_tween = create_tween()
	_fall_tween.tween_method(_set_fall_t, 0.0, 1.0, seconds).set_ease(Tween.EASE_IN)
	await _fall_tween.finished
	if generation == _generation:
		_falling.clear()


func _set_fall_t(t: float) -> void:
	_fall_t = t
	_redraw()


## Plays `clip` on the square at `p`, replacing whatever it was playing. Plain squares only
## (unless `cell` is given for a square that's going away), so specials keep their markings.
## Returns the clip's length in seconds, or 0 if the theme has no art for it.
func _play_clip(p: Vector2i, clip: StringName, cell: Cell = null, free_when_done := true, speed := REPLAY_SPEED) -> float:
	var target: Cell = cell if cell else _shown.get(p)
	if target == null or target.is_blocker() or (cell == null and target.is_special()):
		return 0.0
	if not _art.ensure_clip(target.color, clip):
		return 0.0
	_free_sprite(p)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = _art.frames(target.color)
	sprite.position = (Vector2(p) + Vector2(0.5, 0.5)) * CELL
	sprite.scale = Vector2.ONE * CELL / TileArt.TILE_SIZE
	sprite.speed_scale = speed
	_sprite_layer.add_child(sprite)
	sprite.play(clip)
	_sprites[p] = sprite
	if free_when_done:
		sprite.animation_finished.connect(_on_clip_finished.bind(p, sprite))
	_redraw()
	return _art.clip_seconds(target.color, clip) / speed


## A crate or rock at `p` breaks apart. Returns how long that takes.
func _play_break(p: Vector2i, kind: String) -> float:
	var frames := _obstacles.break_frames(kind)
	if frames == null:
		_flashing[p] = true
		return 0.0
	_free_sprite(p)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = (Vector2(p) + Vector2(0.5, 0.5)) * CELL
	sprite.scale = Vector2.ONE * CELL * BREAK_SCALE / 512.0
	sprite.speed_scale = REPLAY_SPEED
	_sprite_layer.add_child(sprite)
	sprite.play(&"break")
	_sprites[p] = sprite
	_shards.shatter(sprite.position, BLOCKER_DUST.get(kind, BLOCKER_DUST["crate"]), 10)
	return frames.get_frame_count(&"break") / frames.get_animation_speed(&"break") / REPLAY_SPEED


## An item reached the bottom row: it floats up, glowing, and fades away.
func _rescue_item(p: Vector2i, kind: String) -> void:
	var texture := _obstacles.texture(Cell.obstacle(kind))
	Sfx.play(&"coin", 1.3)
	_lights.flare((Vector2(p) + Vector2(0.5, 0.5)) * CELL, Color(1, 0.85, 0.4), 2.0)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = (Vector2(p) + Vector2(0.5, 0.5)) * CELL
	sprite.scale = Vector2.ONE * CELL * 0.9 / texture.get_width()
	_sprite_layer.add_child(sprite)
	var tween := sprite.create_tween().set_parallel()
	tween.tween_property(sprite, "position:y", sprite.position.y - CELL * 1.6, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", sprite.scale * 1.4, 0.7)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tween.chain().tween_callback(sprite.queue_free)


func _on_clip_finished(p: Vector2i, sprite: AnimatedSprite2D) -> void:
	if _sprites.get(p) == sprite:
		_free_sprite(p)
		_redraw()


func _free_sprite(p: Vector2i) -> void:
	if _sprites.has(p):
		_sprites[p].queue_free()
		_sprites.erase(p)


func _clear_sprites() -> void:
	for p in _sprites.keys():
		_free_sprite(p)


## Holds on the last frame until restart.
func _play_on_every_square(clip: StringName) -> void:
	for p: Vector2i in _shown:
		_play_clip(p, clip, null, false, 1.0)


## Slams in oversized, settles with a little overshoot, holds, then fades.
func _show_popup(text: String, font_size := POPUP_SIZE) -> void:
	_popup_text = text
	_popup_size = font_size
	_popup_alpha = 1.0
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween().set_parallel()
	_popup_tween.tween_method(_set_popup_scale, 1.8, 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_method(_set_popup_alpha, 1.0, 0.0, POPUP_TIME * 0.5).set_delay(POPUP_TIME * 0.5).set_ease(Tween.EASE_IN)


func _set_popup_alpha(a: float) -> void:
	_popup_alpha = a
	_overlay.queue_redraw()


func _set_popup_scale(s: float) -> void:
	_popup_scale = s
	_overlay.queue_redraw()


func _snapshot() -> Dictionary:
	var cells := {}
	for y in game.board.rows:
		for x in game.board.columns:
			var cell := game.board.get_cell(Vector2i(x, y))
			if cell and cell.is_blocker():
				# A copy, so a crate keeps its layers on screen until the replay knocks one off.
				var copy := Cell.obstacle(cell.blocker, cell.layers)
				cells[Vector2i(x, y)] = copy
			elif cell:
				cells[Vector2i(x, y)] = cell
	return cells


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	_overlay.queue_redraw()


func _redraw() -> void:
	queue_redraw()
	if _overlay:
		_overlay.queue_redraw()


# --- drawing ---------------------------------------------------------------

func _draw() -> void:
	_draw_surface()
	## Square -> [rect, alpha] for every square drawn here rather than by a sprite.
	var placed := {}
	for p: Vector2i in _shown:
		if _sprites.has(p):
			continue
		var lift := 0.0
		if _falling.has(p):
			lift = _falling[p] * CELL * (1.0 - _fall_t)
		var rect := Rect2(Vector2(p.x * CELL, p.y * CELL - lift), Vector2(CELL, CELL))
		# New squares slide in from above the board; fade them in as they cross the top edge.
		var alpha := clampf(rect.end.y / CELL, 0.0, 1.0)
		if alpha <= 0.0:
			continue
		if path.has(p):
			rect = rect.grow(LINK_GROW)
			rect.position.y -= LINK_LIFT * (1.0 + _link_pop * (1.0 if p == path[-1] else 0.0))
			# Caught in the link, the Orcs tremble.
			rect.position.x += LINK_TREMBLE * sin(_time * 47.0 + p.x * 3.1 + p.y * 1.7)
		elif _knocked.get(p, 0.0) > _time:
			# A crate or rock that just lost a layer shudders.
			rect.position.x += 7.0 * sin(_time * 60.0) * (_knocked[p] - _time) / KNOCK_TIME
		elif not _falling.has(p) and not _flashing.has(p) and not _finished and not (_shown[p].is_blocker() and not _shown[p].is_item()):
			# Breathing: each tile bobs a little out of step with its neighbors.
			var breath := sin(_time * BREATH_SPEED + p.x * 0.7 + p.y * 0.45)
			rect.position.y -= BREATH_LIFT * breath
			rect = rect.grow(breath * 1.2)
		placed[p] = [rect, alpha]
	# Every shadow goes down before any tile, so tiles stand over their neighbors' shadows.
	for p: Vector2i in _sprites:
		if _shown.has(p) and _sprites[p].animation != &"combo":
			_draw_shadow(Rect2(Vector2(p) * CELL, Vector2(CELL, CELL)), _shown[p], 1.0, false)
	for p: Vector2i in placed:
		_draw_shadow(placed[p][0], _shown[p], placed[p][1], path.has(p))
	for p: Vector2i in placed:
		var rect: Rect2 = placed[p][0]
		_draw_cell(rect, _shown[p], placed[p][1], p.x * 1.7 + p.y * 2.3, _pose_for(p))
		if _flashing.has(p):
			if _shown[p].is_special():
				_draw_glow(rect.get_center(), CELL * 1.6, Color(1, 1, 1, 0.9))
			else:
				draw_rect(rect.grow(-6), Color(1, 1, 1, 0.75))
		elif not _falling.has(p) and not _shown[p].is_special() and not _shown[p].is_blocker():
			_draw_shine(rect.grow(-3), p)


## The face an Orc tile pulls (an expression in the tile theme): scared while it's in the
## link, screaming at its end, relieved for a moment after being let go. "" for its own face.
func _pose_for(p: Vector2i) -> String:
	if path.has(p):
		return "scream" if path.size() > 1 and p == path[-1] else "fear"
	if _relief.get(p, 0.0) > _time:
		return "relief"
	return ""


## Tiles cast a soft rounded shadow down and to the right, so the board reads as raised blocks;
## a lifted tile's shadow falls further off. Specials cast a round one on the slot under them.
func _draw_shadow(rect: Rect2, cell: Cell, alpha: float, lifted: bool) -> void:
	if cell.is_special():
		draw_set_transform(rect.get_center() + Vector2(0, rect.size.y * 0.34), 0.0, Vector2(1.0, 0.32))
		_draw_glow(Vector2.ZERO, rect.size.x * 0.9, Color(0, 0, 0, alpha * (0.4 if lifted else 0.6)))
		draw_set_transform(Vector2.ZERO)
		return
	var drop := SHADOW_DROP * (2.0 if lifted else 1.0)
	_shadow_box.bg_color = Color(SHADOW, SHADOW.a * alpha * (0.75 if lifted else 1.0))
	_shadow_box.draw(get_canvas_item(), Rect2(rect.position + drop, rect.size).grow(-6))


func _let_go(squares: Array) -> void:
	for p in squares:
		_relief[p] = _time + RELIEF_TIME


## Critical tiles, drawn over every tile so neighbors don't hide the glow: a pulsing orange
## glow and frame, with sparks crackling around them.
func _draw_crit_tiles() -> void:
	var pulse := 0.75 + 0.25 * sin(_time * 7.0)
	for p: Vector2i in _shown:
		if not _shown[p].critical or _sprites.has(p) or _falling.has(p):
			continue
		var rect := Rect2(Vector2(p) * CELL, Vector2(CELL, CELL))
		if path.has(p):
			rect = rect.grow(LINK_GROW)
			rect.position.y -= LINK_LIFT
		if _glow_outline:
			var glow := rect.size * GLOW_OUTLINE_RATIO
			for i in 2:
				_overlay.draw_texture_rect(_glow_outline, Rect2(rect.get_center() - glow / 2, glow), false, Color(CRIT_FRAME_COLOR, pulse))
		_overlay.draw_rect(rect.grow(-4), Color(CRIT_FRAME_COLOR, pulse), false, 8)
		if _crit_spark:
			var frame := int(_time * CRIT_SPARK_FPS) % CRIT_SPARK_FRAMES
			var cell_px := _crit_spark.get_width() / CRIT_SPARK_FRAMES
			var size := rect.size * cell_px / TileArt.TILE_SIZE * 1.3
			_overlay.draw_texture_rect_region(_crit_spark, Rect2(rect.get_center() - size / 2, size), Rect2(frame * cell_px, 0, cell_px, _crit_spark.get_height()))


func _link_has_critical() -> bool:
	for p in path:
		var cell := game.board.get_cell(p)
		if cell and cell.critical:
			return true
	return false


## The bright panel the tiles sit in, or a dark grid without the art.
func _draw_surface() -> void:
	var size := board_size()
	if _surface.has("backdrop"):
		# Stretched to reach the bottom of the screen wherever the board sits.
		var height := SCREEN_HEIGHT - global_position.y - BACKDROP_AT.y
		draw_texture_rect(_surface["backdrop"], Rect2(BACKDROP_AT, Vector2(_surface["backdrop"].get_width(), height)), false)
	if _surface.has("panel"):
		draw_texture(_surface["panel"], PANEL_AT)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), BOARD_BG)
	if _surface.has("slot"):
		for y in game.board.rows:
			for x in game.board.columns:
				draw_texture_rect(_surface["slot"], Rect2(Vector2(x, y) * CELL, Vector2(CELL, CELL)), false)
	else:
		for x in range(1, game.board.columns):
			draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, size.y), GRID_LINE, 2)
		for y in range(1, game.board.rows):
			draw_line(Vector2(0, y * CELL), Vector2(size.x, y * CELL), GRID_LINE, 2)


## A glossy streak crossing the tile, part of a diagonal wave over the whole board. The
## streak is clipped to the tile by drawing only the part of the texture still over it.
func _draw_shine(rect: Rect2, p: Vector2i) -> void:
	if not _shine:
		return
	var k := (fmod(_time, SHINE_PERIOD) - (p.x + p.y) * 0.06) / SHINE_TIME
	if k <= 0.0 or k >= 1.0:
		return
	var shift := lerpf(-1.0, 1.0, k) * rect.size.x
	var dest := Rect2(rect.position + Vector2(shift, 0), rect.size).intersection(rect)
	if dest.size.x <= 0.0:
		return
	var texture_scale := _shine.get_width() / rect.size.x
	var source := Rect2((dest.position - rect.position - Vector2(shift, 0)) * texture_scale, dest.size * texture_scale)
	draw_texture_rect_region(_shine, dest, source, Color(1, 1, 1, 0.55 * sin(k * PI)))


## Above the tiles: the link being traced, its length and reward, popups, the end screen.
func _draw_overlay() -> void:
	var size := board_size()
	if not _finished:
		_draw_crit_tiles()
	if not path.is_empty():
		_draw_blast()
		_draw_link()
	if _popup_alpha > 0.0:
		# Scaled around the middle of the letters rather than their baseline.
		var lift := _popup_size * 0.35
		_overlay.draw_set_transform(Vector2(size.x / 2, size.y * 0.35 - lift), 0.0, Vector2.ONE * _popup_scale)
		_draw_centered_text(_popup_text, Vector2(0, lift), _popup_size, Color(1, 0.9, 0.3, _popup_alpha), 14)
		_overlay.draw_set_transform(Vector2.ZERO)
	if _finished and not _busy:
		_overlay.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
		_draw_centered_text(_end_title, Vector2(size.x / 2, size.y * 0.45), 110, TEXT)
		_draw_centered_text(_end_subtitle, Vector2(size.x / 2, size.y * 0.45 + 90), 44, TEXT_DIM)


## Shows what the traced link would blow up besides its own squares: the rest dims.
func _draw_blast() -> void:
	if path != _blast_path:
		_blast_path = path.duplicate()
		_blast.clear()
		if path.size() >= game.rules.min_link and path.any(func(p: Vector2i) -> bool: return game.board.get_cell(p).is_special()):
			for p in Resolver.link_step(game.board, game.rules, path).cleared:
				if not path.has(p):
					_blast[p] = true
	if _blast.is_empty():
		return
	for p: Vector2i in _shown:
		if not _blast.has(p) and not path.has(p):
			_overlay.draw_rect(Rect2(Vector2(p) * CELL, Vector2(CELL, CELL)), BLAST_DIM)
	var pulse := 0.5 + 0.5 * sin(_time * 8.0)
	for p: Vector2i in _blast:
		var rect := Rect2(Vector2(p) * CELL, Vector2(CELL, CELL)).grow(-7)
		_overlay.draw_rect(rect, Color(BLAST_RIM, 0.6 + 0.4 * pulse), false, 6.0)


## A short glossy bar with a dark rim and rounded ends bridging two tiles' frames. The newest
## one swells as the link reaches its square.
func _draw_joint(from: Vector2, to: Vector2, color: Color, newest: bool) -> void:
	var width := JOINT_WIDTH * (1.0 + (0.5 * _link_pop if newest else 0.0))
	var rim := Color(0.16, 0.09, 0.04)
	for layer in [[width + 10, rim], [width, color.lightened(0.15)]]:
		_overlay.draw_line(from, to, layer[1], layer[0])
		_overlay.draw_circle(from, layer[0] / 2, layer[1])
		_overlay.draw_circle(to, layer[0] / 2, layer[1])
	var across := (to - from).normalized().orthogonal() * width * 0.18
	var gloss := Color(1, 1, 1, 0.55)
	# The gloss sits on the upper side, whichever way the joint runs.
	if across.y > 0:
		across = -across
	_overlay.draw_line(from + across, to + across, gloss, width * 0.25)


func _draw_link() -> void:
	var color_index := Resolver.link_color(game.board, path)
	var color: Color = BLOCK_COLORS.get(color_index, STAR_LINK_COLOR)
	var critical := _link_has_critical()
	if critical:
		color = CRIT_LINK_COLOR
	var points := PackedVector2Array()
	for p in path:
		var center := (Vector2(p) + Vector2(0.5, 0.5)) * CELL - Vector2(0, LINK_LIFT)
		points.append(center)
		var puff := _link_pop * 10.0 if p == path[-1] else 0.0
		if _glow_outline:
			var glow := (CELL + LINK_GROW * 2 + puff) * GLOW_OUTLINE_RATIO
			var pulse := 0.8 + 0.2 * sin(_time * 10.0)
			_overlay.draw_texture_rect(_glow_outline, Rect2(center - Vector2(glow, glow) / 2, Vector2(glow, glow)), false, Color(color.lightened(0.35), pulse))
		else:
			_overlay.draw_rect(Rect2(Vector2(p) * CELL, Vector2(CELL, CELL)).grow(-4 + puff), Color(1, 1, 1, 0.9), false, 6)
	# Linked tiles are joined only where they meet, so their faces stay in view.
	for i in range(1, points.size()):
		var direction := (points[i] - points[i - 1]).normalized()
		_draw_joint(points[i - 1] + direction * CELL * JOINT_REACH, points[i] - direction * CELL * JOINT_REACH, color, i == points.size() - 1)

	# Length so far and what the link will leave behind, under the board.
	var count := path.size()
	var label := "%d ô" % count
	var kind := Resolver.special_for_link(game.rules, count)
	if kind != Cell.Special.NONE:
		label += "  →  %s" % SPECIAL_NAMES[kind]
	elif count < game.rules.min_link:
		label += "  (cần %d)" % game.rules.min_link
	if critical and count >= game.rules.min_link:
		label += "  ·  CHÍ MẠNG!"
	_draw_centered_text(label, Vector2(board_size().x / 2, board_size().y + 75), 52, TEXT if count >= game.rules.min_link else TEXT_DIM, 12)


## `phase` puts neighboring specials out of step with each other.
## `pose` is the Orc face to show instead of the plain tile (see _pose_for), if the theme has it.
func _draw_cell(rect: Rect2, cell: Cell, alpha := 1.0, phase := 0.0, pose := "") -> void:
	if cell.is_special():
		_draw_special(rect, cell, alpha, _time + phase)
		return
	if cell.is_blocker():
		var picture := _obstacles.texture(cell)
		if picture:
			draw_texture_rect(picture, rect.grow(-4 if cell.is_item() else 2), false, Color(1, 1, 1, alpha))
		else:
			draw_rect(rect.grow(-6), Color(0.45, 0.3, 0.16, alpha))
		return
	var inner := rect.grow(-3)
	var texture: Texture2D = _art.expression(cell.color, pose) if pose else null
	if not texture:
		texture = _art.tile(cell.color)
	if texture:
		draw_texture_rect(texture, inner, false, Color(1, 1, 1, alpha))
	else:
		_style_for(cell.color).draw(get_canvas_item(), inner.grow(-2))
		_draw_symbol(cell.color, inner.get_center(), inner.size.x * 0.21, BLOCK_COLORS[cell.color].lightened(0.5))


## Specials are drawn bare, with nothing behind them, and never sit still: the bomb shivers
## while its fuse burns, the lightning pulses and the star sways. Their art loops on its own
## (see SpecialArt); without it they're drawn by hand. They're wild, so they show no color.
func _draw_special(rect: Rect2, cell: Cell, alpha: float, t: float) -> void:
	var center := rect.get_center()
	var size := rect.size.x * SPECIAL_SCALE
	match cell.special:
		Cell.Special.BOMB:
			_draw_bomb(center, size, alpha, t)
		Cell.Special.LIGHTNING:
			_draw_lightning(center, size, alpha, t)
		Cell.Special.RAINBOW:
			_draw_star(center, size, alpha, t)


## `kind`'s art, `size` across, centered on the current transform's origin: the still under
## its sheet's frame at `t`, or the sheet alone when it includes the special. False when
## there's no art, for the caller to draw its own.
func _draw_special_art(kind: int, size: float, alpha: float, t: float) -> bool:
	var rect := Rect2(-Vector2(size, size) / 2, Vector2(size, size))
	var still := _special_art.still(kind)
	var sheet := _special_art.sheet(kind)
	if still and (sheet == null or _special_art.sheet_overlays_still(kind)):
		draw_texture_rect(still, rect, false, Color(1, 1, 1, alpha))
	if sheet:
		draw_texture_rect_region(sheet, rect, _special_art.frame_region(kind, t), Color(1, 1, 1, alpha))
	return still != null or sheet != null


## Shivers on a quick beat while its fuse burns.
func _draw_bomb(center: Vector2, size: float, alpha: float, t: float) -> void:
	var beat := sin(t * 14.0)
	_xform = Transform2D(0.06 * sin(t * 7.0), Vector2(1.0 + 0.03 * beat, 1.0 - 0.03 * beat), 0.0, center)
	draw_set_transform_matrix(_xform)
	if not _draw_special_art(Cell.Special.BOMB, size, alpha, t):
		draw_circle(Vector2(-size * 0.05, size * 0.08), size * 0.33, Color(0.12, 0.12, 0.14, alpha))
	if not _special_art.sheet(Cell.Special.BOMB):
		_draw_fuse_fire(size, alpha, t)
	_xform = Transform2D.IDENTITY
	draw_set_transform_matrix(_xform)


## Without fuse art: a flickering flame, sparks spraying off it and wisps of smoke curling up.
func _draw_fuse_fire(size: float, alpha: float, t: float) -> void:
	var tip := (BOMB_FUSE / TileArt.TILE_SIZE - Vector2(0.5, 0.5)) * size
	# Smoke rises and drifts behind the flame.
	for k in 3:
		var age := fmod(t * 0.9 + k / 3.0, 1.0)
		var at := tip + Vector2(sin(age * 5.0 + k) * size * 0.06, -age * size * 0.4)
		_draw_glow(at, size * (0.14 + 0.22 * age), Color(0.35, 0.33, 0.32, alpha * 0.45 * (1.0 - age)))
	# The flame: an orange halo, a yellow body and a white-hot core, all flickering.
	var flicker := 0.8 + 0.2 * sin(t * 37.0) * sin(t * 13.0)
	_draw_glow(tip, size * 0.62 * flicker, Color(FUSE_FIRE, alpha * 0.85))
	_draw_glow(tip + Vector2(0, -size * 0.03), size * 0.34 * flicker, Color(1, 0.85, 0.3, alpha))
	_draw_glow(tip, size * 0.16 * flicker, Color(1, 1, 0.9, alpha))
	# Sparks spray up and out from the fuse and arc down as they burn out.
	for k in 9:
		var age := fmod(t * 2.6 + k / 9.0, 1.0)
		var direction := Vector2.from_angle(-PI / 2 + (k - 4.0) * 0.33)
		var at := tip + direction * age * size * 0.42 + Vector2(0, age * age * size * 0.3)
		var spark := Color(1, 0.95, 0.6).lerp(FUSE_FIRE, age)
		_draw_spark(at, size * 0.2 * (1.0 - age * 0.7), t * 9.0 + k, Color(spark, alpha * (1.0 - age)))


## Pulses. Its art crackles on its own; without it, sparks crackle at the tips of its arrows.
func _draw_lightning(center: Vector2, size: float, alpha: float, t: float) -> void:
	var grow := 1.0 + 0.06 * sin(t * 7.0)
	draw_set_transform(center, 0.0, Vector2(grow, grow))
	if not _draw_special_art(Cell.Special.LIGHTNING, size, alpha, t):
		draw_line(Vector2(-size / 2, 0), Vector2(size / 2, 0), Color(1, 1, 1, alpha), size * 0.1)
		draw_line(Vector2(0, -size / 2), Vector2(0, size / 2), Color(1, 1, 1, alpha), size * 0.1)
	draw_set_transform(Vector2.ZERO)
	if _special_art.sheet(Cell.Special.LIGHTNING):
		return
	_draw_glow(center, size * 0.45, Color(1, 1, 0.85, alpha * (0.4 + 0.3 * sin(t * 13.0))))
	for k in 4:
		var crackle := sin(t * 23.0 + k * 1.9) * sin(t * 9.0 + k)
		if crackle > 0.2:
			var at := center + Vector2.from_angle(k * PI / 2) * size * 0.44
			_draw_spark(at, size * 0.32 * crackle, t * 5.0 + k, Color(1, 1, 0.75, alpha * crackle))


## Breathes and sways; its art twinkles on its own. Without art: a white four-pointed star
## with a gold rim that slowly turns, breathes and twinkles.
func _draw_star(center: Vector2, size: float, alpha: float, t: float) -> void:
	var breath := 1.0 + 0.04 * sin(t * 5.0)
	draw_set_transform(center, STAR_SWAY * sin(t * 1.6), Vector2(breath, breath))
	var drawn := _draw_special_art(Cell.Special.RAINBOW, size, alpha, t)
	draw_set_transform(Vector2.ZERO)
	if drawn:
		return
	var outer := size * (0.42 + 0.03 * sin(t * 5.0))
	var inner := outer * 0.34
	var turn := t * 1.2
	var points := PackedVector2Array()
	for i in 8:
		points.append(center + Vector2.from_angle(turn + i * PI / 4 - PI / 2) * (outer if i % 2 == 0 else inner))
	_draw_glow(center, size * 0.8, Color(1, 1, 0.9, alpha * 0.8))
	draw_colored_polygon(points, Color(1, 0.98, 0.9, alpha))
	points.append(points[0])
	draw_polyline(points, Color(STAR_GOLD, alpha), 5.0, true)
	draw_circle(center, inner * 0.55, Color(1, 0.9, 0.5, alpha))
	var tip := int(t * 2.0) % 4
	var twinkle := sin(fmod(t * 2.0, 1.0) * PI)
	_draw_spark(center + Vector2.from_angle(turn + tip * PI / 2 - PI / 2) * outer, size * 0.35 * twinkle, 0.0, Color(1, 1, 1, alpha * twinkle))


func _draw_glow(at: Vector2, size: float, color: Color) -> void:
	if _glow:
		draw_texture_rect(_glow, Rect2(at - Vector2(size, size) / 2, Vector2(size, size)), false, color)
	else:
		draw_circle(at, size * 0.3, Color(color, color.a * 0.5))


func _draw_spark(at: Vector2, size: float, angle: float, color: Color) -> void:
	if size <= 0.5:
		return
	if not _spark:
		draw_circle(at, size * 0.25, color)
		return
	# On top of the caller's transform: sparks around a bomb wobble with it.
	draw_set_transform_matrix(_xform * Transform2D(angle, at))
	draw_texture_rect(_spark, Rect2(-Vector2(size, size) / 2, Vector2(size, size)), false, color)
	draw_set_transform_matrix(_xform)


## One shape per color: circle, triangle, square, diamond.
func _draw_symbol(color: int, c: Vector2, s: float, tint: Color) -> void:
	match color:
		Cell.BlockColor.RED:
			draw_circle(c, s, tint)
		Cell.BlockColor.GREEN:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, s * 0.8), c + Vector2(-s, s * 0.8)]), tint)
		Cell.BlockColor.YELLOW:
			draw_rect(Rect2(c - Vector2(s, s) * 0.8, Vector2(s, s) * 1.6), tint)
		Cell.BlockColor.PURPLE:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), tint)


func _style_for(color: int) -> StyleBoxFlat:
	if not _styles.has(color):
		var style := StyleBoxFlat.new()
		style.bg_color = BLOCK_COLORS[color]
		style.set_corner_radius_all(18)
		style.border_color = BLOCK_COLORS[color].darkened(0.35)
		style.set_border_width_all(4)
		_styles[color] = style
	return _styles[color]


func _draw_centered_text(text: String, center: Vector2, font_size: int, color: Color, outline := 0) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := center - Vector2(width / 2, 0)
	if outline > 0:
		_overlay.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(0, 0, 0, color.a * 0.8))
	_overlay.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
