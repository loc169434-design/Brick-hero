class_name BoardView
extends Node2D
## Draws a BoardGame and replays each drop's chain round by round.
## Tiles come from the chosen theme in assets/tiles/ (see TileArt). Squares playing an
## animation are drawn by their sprite instead of by _draw(), so a cleared tile never shows
## through its own burst. Without art, each color falls back to a square with its own symbol.

signal drop_finished(result: DropResult)

const CELL := 100
const PREVIEW_CELL := 46
const PANEL_GAP := 20
const PANEL_WIDTH := 200
const PREVIEW_BOX_HEIGHT := 140
## The tile clips are paced for a showcase; replays run them faster to keep turns snappy.
const REPLAY_SPEED := 2.0
const FLASH_TIME := 0.22
const DROP_TIME := 0.12
const FALL_TIME := 0.16
const POPUP_TIME := 0.9

const BLOCK_COLORS := {
	Cell.BlockColor.RED: Color(0.9, 0.28, 0.3),
	Cell.BlockColor.GREEN: Color(0.27, 0.65, 0.35),
	Cell.BlockColor.YELLOW: Color(0.96, 0.77, 0.1),
	Cell.BlockColor.PURPLE: Color(0.56, 0.31, 0.78),
}
const SPECIAL_PATHS := {
	Cell.Special.LIGHTNING: "res://assets/tiles/special_lightning.png",
	Cell.Special.BOMB: "res://assets/tiles/special_bomb.png",
	Cell.Special.RAINBOW: "res://assets/tiles/special_rainbow.png",
}
const BOARD_BG := Color(0.1, 0.1, 0.15)
const GRID_LINE := Color(1, 1, 1, 0.05)
const TEXT := Color(0.92, 0.92, 0.96)
const TEXT_DIM := Color(0.6, 0.6, 0.7)

## Negative picks a random seed each game.
@export var seed_value := -1
@export_enum("training", "orc_shield") var tile_theme := "training"

var game: BoardGame

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
## Bumped on restart so a replay still waiting on a timer knows to stop.
var _generation := 0
## The combo as of the last finished replay, so the counter doesn't jump ahead of the show.
var _combo_shown := 0
var _popup_text := ""
var _popup_alpha := 0.0
var _popup_tween: Tween
var _sprite_layer: Node2D
## Drawn above the sprites: popups and the game-over screen.
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
	if _fall_tween:
		_fall_tween.kill()
	if _popup_tween:
		_popup_tween.kill()
	_popup_alpha = 0.0
	_combo_shown = 0
	game = BoardGame.new(BoardRules.new(), seed_value)
	game.piece_changed.connect(_redraw)
	game.start()
	_shown = _snapshot()
	_busy = false
	_redraw()


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


func hold_rect() -> Rect2:
	var top := 3 * PREVIEW_BOX_HEIGHT + 120
	return Rect2(_panel_x(), top, PANEL_WIDTH, PREVIEW_BOX_HEIGHT + 40)


func can_act() -> bool:
	return not _busy and not game.is_over


func try_move(dx: int) -> void:
	if can_act():
		game.move(dx)


## Slides toward `column` (the piece's pivot column) until something blocks it.
func try_slide_to(column: int) -> void:
	if not can_act():
		return
	while game.origin.x < column and game.move(1):
		pass
	while game.origin.x > column and game.move(-1):
		pass


func try_rotate(clockwise := true) -> void:
	if can_act():
		game.rotate(clockwise)


func try_hold() -> void:
	if can_act():
		game.hold()


func try_drop() -> void:
	if not can_act():
		return
	var before := _snapshot()
	var piece := game.current
	var hover := game.origin
	var result := game.drop()
	_replay(result, before, piece, hover)


# --- replay ----------------------------------------------------------------

func _replay(result: DropResult, before: Dictionary, piece: Piece, hover: Vector2i) -> void:
	var generation := _generation
	_busy = true
	_clear_sprites()
	_shown = before

	# The piece travels from where it hovered to where it landed, then thuds.
	var rows_dropped := result.placed[0].y - (hover + piece.offsets[0]).y
	for i in result.placed.size():
		_shown[result.placed[i]] = Cell.new(piece.colors[i])
		_falling[result.placed[i]] = rows_dropped
	await _animate_falls(DROP_TIME, generation)
	if generation != _generation:
		return
	for p in result.placed:
		_play_clip(p, &"land")

	for step in result.steps:
		if step.chain >= 2:
			_show_popup("CHAIN x%d" % step.chain)
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
			carried.append(_shown[fall["from"]])
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

	_combo_shown = result.combo
	if result.combo >= 2:
		_show_popup("COMBO x%d" % result.combo)
	_shown = _snapshot()
	_busy = false
	if game.is_over:
		_play_on_every_square(&"lose")
	elif not result.cleared_anything():
		_taunt()
	_redraw()
	drop_finished.emit(result)


func _animate_falls(seconds: float, generation: int) -> void:
	if _falling.is_empty():
		return
	_fall_tween = create_tween()
	_fall_tween.tween_method(_set_fall_t, 0.0, 1.0, seconds)
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


## After a drop that cleared nothing, one tile laughs at full speed. It doesn't block input:
## the next drop cuts it short.
func _taunt() -> void:
	if not _art.has_clip(&"taunt"):
		return
	var candidates := _shown.keys().filter(func(p: Vector2i) -> bool: return not _shown[p].is_special())
	if not candidates.is_empty():
		_play_clip(candidates.pick_random(), &"taunt", null, true, 1.0)


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


func _panel_x() -> float:
	return board_size().x + PANEL_GAP


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
		_draw_cell(rect, _shown[p])
		if _flashing.has(p):
			draw_rect(rect.grow(-6), Color(1, 1, 1, 0.75))

	if not _busy and not game.is_over:
		_draw_ghost()
		_draw_piece(game.current, game.origin, Vector2.ZERO, CELL)

	_draw_panel()


func _draw_overlay() -> void:
	var size := board_size()
	if _popup_alpha > 0.0:
		_draw_centered_text(_overlay, _popup_text, Vector2(size.x / 2, size.y * 0.35), 96, Color(1, 0.9, 0.3, _popup_alpha))
	if game.is_over and not _busy:
		_overlay.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
		_draw_centered_text(_overlay, "GAME OVER", Vector2(size.x / 2, size.y * 0.45), 96, TEXT)
		_draw_centered_text(_overlay, "tap or press R to restart", Vector2(size.x / 2, size.y * 0.45 + 80), 40, TEXT_DIM)


func _draw_ghost() -> void:
	var landing := game.landing_origin()
	var cells := game.current.cells_at(landing)
	for i in cells.size():
		var rect := Rect2(Vector2(cells[i]) * CELL, Vector2(CELL, CELL)).grow(-8)
		var color: Color = BLOCK_COLORS[game.current.colors[i]]
		draw_rect(rect, Color(color, 0.18))
		draw_rect(rect, Color(color, 0.7), false, 4)


func _draw_piece(piece: Piece, origin: Vector2i, offset: Vector2, cell_size: float) -> void:
	var cells := piece.cells_at(origin)
	for i in cells.size():
		var rect := Rect2(offset + Vector2(cells[i]) * cell_size, Vector2(cell_size, cell_size))
		_draw_cell(rect, Cell.new(piece.colors[i]))


## Draws `piece` centered in `box`.
func _draw_piece_in(piece: Piece, box: Rect2) -> void:
	var b := piece.bounds()
	var size := Vector2(b.size) * PREVIEW_CELL
	var offset := box.get_center() - size / 2 - Vector2(b.position) * PREVIEW_CELL
	_draw_piece(piece, Vector2i.ZERO, offset, PREVIEW_CELL)


func _draw_panel() -> void:
	var x := _panel_x()
	var font_size := 40
	_draw_label("NEXT", Vector2(x, 40), font_size)
	var upcoming := game.bag.preview()
	for i in upcoming.size():
		var box := Rect2(x, 60 + i * PREVIEW_BOX_HEIGHT, PANEL_WIDTH, PREVIEW_BOX_HEIGHT - 10)
		draw_rect(box, BOARD_BG)
		_draw_piece_in(upcoming[i], box)

	var hold := hold_rect()
	_draw_label("HOLD", hold.position + Vector2(0, -20), font_size)
	draw_rect(hold, BOARD_BG)
	draw_rect(hold, Color(1, 1, 1, 0.15), false, 3)
	if game.held:
		_draw_piece_in(game.held, hold)

	var combo_y := hold.end.y + 80
	_draw_label("COMBO", Vector2(x, combo_y), font_size)
	_draw_label("x%d" % _combo_shown, Vector2(x, combo_y + 70), 64, TEXT if _combo_shown > 0 else TEXT_DIM)


func _draw_cell(rect: Rect2, cell: Cell) -> void:
	var inner := rect.grow(-2)
	var center := inner.get_center()
	var r := inner.size.x / 2

	if cell.special == Cell.Special.RAINBOW:
		if _special_textures.has(cell.special):
			draw_texture_rect(_special_textures[cell.special], inner, false)
			return
		var stripe := inner.size.x / Cell.COLOR_COUNT
		for i in Cell.COLOR_COUNT:
			draw_rect(Rect2(inner.position + Vector2(i * stripe, 0), Vector2(stripe, inner.size.y)), BLOCK_COLORS[i])
		draw_circle(center, r * 0.3, Color.WHITE)
		return

	var texture := _art.tile(cell.color)
	if texture:
		draw_texture_rect(texture, inner, false)
	else:
		_style_for(cell.color).draw(get_canvas_item(), inner.grow(-2))
		_draw_symbol(cell.color, center, r * 0.42, BLOCK_COLORS[cell.color].lightened(0.5))

	match cell.special:
		Cell.Special.LIGHTNING:
			if _special_textures.has(cell.special):
				draw_texture_rect(_special_textures[cell.special], inner, false)
			else:
				draw_line(center + Vector2(-r * 0.8, 0), center + Vector2(r * 0.8, 0), Color.WHITE, r * 0.18)
				draw_line(center + Vector2(0, -r * 0.8), center + Vector2(0, r * 0.8), Color.WHITE, r * 0.18)
		Cell.Special.BOMB:
			if _special_textures.has(cell.special):
				draw_texture_rect(_special_textures[cell.special], inner, false)
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
		style.set_corner_radius_all(14)
		style.border_color = BLOCK_COLORS[color].darkened(0.35)
		style.set_border_width_all(4)
		_styles[color] = style
	return _styles[color]


func _draw_label(text: String, pos: Vector2, font_size: int, color := TEXT_DIM) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_centered_text(canvas: CanvasItem, text: String, center: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, center - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
