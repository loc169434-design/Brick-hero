class_name BoardView
extends Node2D
## Draws a LinkGame, shows the link the player is tracing, and replays each move's chain round
## by round. Tiles come from the chosen theme in assets/tiles/ (see TileArt). Squares playing an
## animation are drawn by their sprite instead of by _draw(), so a cleared tile never shows
## through its own burst. Without art, each color falls back to a square with its own symbol.

signal move_finished(result: MoveResult)
signal restarted

const CELL := 140
const LINK_WIDTH := 26.0
## The tile clips are paced for a showcase; replays run them faster to keep turns snappy.
const REPLAY_SPEED := 2.0
const FLASH_TIME := 0.22
const FALL_TIME := 0.2
const POPUP_TIME := 0.9

const BLOCK_COLORS := {
	Cell.BlockColor.RED: Color(0.9, 0.28, 0.3),
	Cell.BlockColor.GREEN: Color(0.27, 0.65, 0.35),
	Cell.BlockColor.YELLOW: Color(0.96, 0.77, 0.1),
	Cell.BlockColor.PURPLE: Color(0.56, 0.31, 0.78),
}
const STAR_LINK_COLOR := Color(1, 1, 1)
const SPECIAL_PATHS := {
	Cell.Special.LIGHTNING: "res://assets/tiles/special_lightning.png",
	Cell.Special.BOMB: "res://assets/tiles/special_bomb.png",
	Cell.Special.RAINBOW: "res://assets/tiles/special_rainbow.png",
}
const SPECIAL_NAMES := {
	Cell.Special.LIGHTNING: "SÉT",
	Cell.Special.BOMB: "BOM",
	Cell.Special.RAINBOW: "SAO",
}
const BOARD_BG := Color(0.1, 0.1, 0.15)
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
var _special_textures := {}
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
## Set once the fight is decided, until restart.
var _finished := false
var _end_title := ""
var _end_subtitle := ""
## Bumped on restart so a replay still waiting on a timer knows to stop.
var _generation := 0
var _popup_text := ""
var _popup_alpha := 0.0
var _popup_tween: Tween
var _sprite_layer: Node2D
## Drawn above the sprites: the link being traced, popups and the end screen.
var _overlay: Node2D


func _ready() -> void:
	_sprite_layer = Node2D.new()
	add_child(_sprite_layer)
	_overlay = Node2D.new()
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	for key in SPECIAL_PATHS:
		if ResourceLoader.exists(SPECIAL_PATHS[key]):
			_special_textures[key] = load(SPECIAL_PATHS[key])
	_art = TileArt.new(tile_theme)
	new_game()


func new_game() -> void:
	_generation += 1
	_clear_sprites()
	_flashing.clear()
	_falling.clear()
	path.clear()
	if _fall_tween:
		_fall_tween.kill()
	if _popup_tween:
		_popup_tween.kill()
	_popup_alpha = 0.0
	_finished = false
	game = LinkGame.new(BoardRules.new(), seed_value)
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
	var idle := _shown.keys().filter(func(p: Vector2i) -> bool: return not _shown[p].is_special() and not _sprites.has(p))
	idle.shuffle()
	for p in idle.slice(0, count):
		_play_clip(p, clip, null, true, 1.0)


## Switches between tile themes. Waits for the current replay so no clip changes art mid-play.
func set_tile_theme(theme: String) -> void:
	if _busy or theme == tile_theme:
		return
	tile_theme = theme
	_art = TileArt.new(theme)
	_clear_sprites()
	_redraw()


func next_tile_theme() -> void:
	var themes := TileArt.THEMES
	set_tile_theme(themes[(themes.find(tile_theme) + 1) % themes.size()])


func board_size() -> Vector2:
	return Vector2(game.board.columns, game.board.rows) * CELL


func can_act() -> bool:
	return not _busy and not _finished


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
	_overlay.queue_redraw()


## Adds `p` to the link, or steps back if `p` is the square before the last one.
func extend_link(p: Vector2i) -> void:
	if path.is_empty() or p == path[-1] or not can_act():
		return
	if path.size() >= 2 and p == path[-2]:
		path.pop_back()
	elif game.can_extend(path, p):
		path.append(p)
	_overlay.queue_redraw()


## Plays the link if it's long enough; a short one is just let go.
func end_link() -> void:
	if can_act() and path.size() >= game.rules.min_link:
		var before := _snapshot()
		var result := game.play(path)
		if result:
			_replay(result, before)
	path.clear()
	_overlay.queue_redraw()


# --- replay ----------------------------------------------------------------

func _replay(result: MoveResult, before: Dictionary) -> void:
	var generation := _generation
	_busy = true
	_clear_sprites()
	_shown = before
	if result.path.size() >= game.rules.lightning_link:
		_show_popup("NỐI %d!" % result.path.size())

	for step in result.steps:
		if step.chain >= 2:
			_show_popup("CHUỖI x%d" % step.chain)
		# Every square in the round bursts at once; the round waits for the longest burst.
		var burst := 0.0
		for i in step.cleared.size():
			var seconds := _play_clip(step.cleared[i], &"combo", step.cleared_cells[i], false)
			if seconds > 0.0:
				burst = maxf(burst, seconds)
			else:
				_flashing[step.cleared[i]] = true
		_redraw()
		await get_tree().create_timer(burst if burst > 0.0 else FLASH_TIME).timeout
		if generation != _generation:
			return

		_flashing.clear()
		for p in step.cleared:
			_shown.erase(p)
			_free_sprite(p)
		for s in step.spawned:
			_shown[s["at"]] = Cell.new(s["color"], s["special"])
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

	if result.reshuffled:
		_show_popup("XÁO BẢNG")
	_shown = _snapshot()
	_busy = false
	_redraw()
	move_finished.emit(result)


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
	if target == null or (cell == null and target.is_special()):
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


func _show_popup(text: String) -> void:
	_popup_text = text
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_method(_set_popup_alpha, 1.0, 0.0, POPUP_TIME).set_ease(Tween.EASE_IN)


func _set_popup_alpha(a: float) -> void:
	_popup_alpha = a
	_overlay.queue_redraw()


func _snapshot() -> Dictionary:
	var cells := {}
	for y in game.board.rows:
		for x in game.board.columns:
			var cell := game.board.get_cell(Vector2i(x, y))
			if cell:
				cells[Vector2i(x, y)] = cell
	return cells


func _redraw() -> void:
	queue_redraw()
	if _overlay:
		_overlay.queue_redraw()


# --- drawing ---------------------------------------------------------------

func _draw() -> void:
	var size := board_size()
	draw_rect(Rect2(Vector2.ZERO, size), BOARD_BG)
	for x in range(1, game.board.columns):
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, size.y), GRID_LINE, 2)
	for y in range(1, game.board.rows):
		draw_line(Vector2(0, y * CELL), Vector2(size.x, y * CELL), GRID_LINE, 2)

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
		_draw_cell(rect, _shown[p], alpha)
		if _flashing.has(p):
			draw_rect(rect.grow(-6), Color(1, 1, 1, 0.75))


## Above the tiles: the link being traced, its length and reward, popups, the end screen.
func _draw_overlay() -> void:
	var size := board_size()
	if not path.is_empty():
		_draw_link()
	if _popup_alpha > 0.0:
		_draw_centered_text(_popup_text, Vector2(size.x / 2, size.y * 0.35), 110, Color(1, 0.9, 0.3, _popup_alpha))
	if _finished and not _busy:
		_overlay.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
		_draw_centered_text(_end_title, Vector2(size.x / 2, size.y * 0.45), 110, TEXT)
		_draw_centered_text(_end_subtitle, Vector2(size.x / 2, size.y * 0.45 + 90), 44, TEXT_DIM)


func _draw_link() -> void:
	var color_index := Resolver.link_color(game.board, path)
	var color: Color = BLOCK_COLORS.get(color_index, STAR_LINK_COLOR)
	var points := PackedVector2Array()
	for p in path:
		var center := (Vector2(p) + Vector2(0.5, 0.5)) * CELL
		points.append(center)
		_overlay.draw_rect(Rect2(Vector2(p) * CELL, Vector2(CELL, CELL)).grow(-4), Color(1, 1, 1, 0.9), false, 6)
	if points.size() >= 2:
		_overlay.draw_polyline(points, Color(0, 0, 0, 0.35), LINK_WIDTH + 10, true)
		_overlay.draw_polyline(points, color.lightened(0.2), LINK_WIDTH, true)
	for point in points:
		_overlay.draw_circle(point, LINK_WIDTH * 0.75, color.lightened(0.2))

	# Length so far and what the link will leave behind, under the board.
	var count := path.size()
	var label := "%d ô" % count
	var kind := Resolver.special_for_link(game.rules, count)
	if kind != Cell.Special.NONE:
		label += "  →  %s" % SPECIAL_NAMES[kind]
	elif count < game.rules.min_link:
		label += "  (cần %d)" % game.rules.min_link
	_draw_centered_text(label, Vector2(board_size().x / 2, board_size().y + 70), 52, TEXT if count >= game.rules.min_link else TEXT_DIM)


func _draw_cell(rect: Rect2, cell: Cell, alpha := 1.0) -> void:
	var inner := rect.grow(-3)
	var center := inner.get_center()
	var r := inner.size.x / 2
	var tint := Color(1, 1, 1, alpha)

	if cell.special == Cell.Special.RAINBOW:
		if _special_textures.has(cell.special):
			draw_texture_rect(_special_textures[cell.special], inner, false, tint)
			return
		var stripe := inner.size.x / Cell.COLOR_COUNT
		for i in Cell.COLOR_COUNT:
			draw_rect(Rect2(inner.position + Vector2(i * stripe, 0), Vector2(stripe, inner.size.y)), Color(BLOCK_COLORS[i], alpha))
		draw_circle(center, r * 0.3, tint)
		return

	var texture := _art.tile(cell.color)
	if texture:
		draw_texture_rect(texture, inner, false, tint)
	else:
		_style_for(cell.color).draw(get_canvas_item(), inner.grow(-2))
		_draw_symbol(cell.color, center, r * 0.42, BLOCK_COLORS[cell.color].lightened(0.5))

	match cell.special:
		Cell.Special.LIGHTNING:
			if _special_textures.has(cell.special):
				draw_texture_rect(_special_textures[cell.special], inner, false, tint)
			else:
				draw_line(center + Vector2(-r * 0.8, 0), center + Vector2(r * 0.8, 0), Color.WHITE, r * 0.18)
				draw_line(center + Vector2(0, -r * 0.8), center + Vector2(0, r * 0.8), Color.WHITE, r * 0.18)
		Cell.Special.BOMB:
			if _special_textures.has(cell.special):
				draw_texture_rect(_special_textures[cell.special], inner, false, tint)
			else:
				draw_circle(center, r * 0.55, Color(0.1, 0.1, 0.12))
				draw_circle(center + Vector2(r * 0.35, -r * 0.45), r * 0.12, Color(1, 0.6, 0.1))


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


func _draw_centered_text(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_overlay.draw_string(font, center - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
