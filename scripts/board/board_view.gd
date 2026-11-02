class_name BoardView
extends Node2D
## Draws a BoardGame and replays each drop's chain round by round.
## Placeholder art is a colored square with a symbol per color, so colors read without
## color vision. PNGs dropped into assets/tiles/ (names in docs/core_plan.md) replace it.

signal drop_finished(result: DropResult)

const CELL := 100
const PREVIEW_CELL := 36
const PANEL_GAP := 20
const PANEL_WIDTH := 200
const PREVIEW_BOX_HEIGHT := 140
const FLASH_TIME := 0.22
const FALL_TIME := 0.16
const POPUP_TIME := 0.9

const BLOCK_COLORS := {
	Cell.BlockColor.RED: Color(0.9, 0.28, 0.3),
	Cell.BlockColor.GREEN: Color(0.27, 0.65, 0.35),
	Cell.BlockColor.YELLOW: Color(0.96, 0.77, 0.1),
	Cell.BlockColor.PURPLE: Color(0.56, 0.31, 0.78),
}
const TILE_PATHS := {
	Cell.BlockColor.RED: "res://assets/tiles/tile_red.png",
	Cell.BlockColor.GREEN: "res://assets/tiles/tile_green.png",
	Cell.BlockColor.YELLOW: "res://assets/tiles/tile_yellow.png",
	Cell.BlockColor.PURPLE: "res://assets/tiles/tile_purple.png",
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

var game: BoardGame

## What's on screen. Lags behind the model while a chain is being replayed.
var _shown := {}
var _flashing := {}
## Squares mid-fall: landing position -> rows they still have to fall at _fall_t = 0.
var _falling := {}
var _fall_t := 1.0
var _busy := false
var _popup_text := ""
var _popup_alpha := 0.0
var _popup_tween: Tween
var _textures := {}
var _styles := {}


func _ready() -> void:
	_load_textures()
	new_game()


func new_game() -> void:
	game = BoardGame.new(BoardRules.new(), seed_value)
	game.piece_changed.connect(queue_redraw)
	game.start()
	_shown = _snapshot()
	_busy = false
	queue_redraw()


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
	var result := game.drop()
	_replay(result, before, piece)


func _replay(result: DropResult, before: Dictionary, piece: Piece) -> void:
	_busy = true
	_shown = before
	for i in result.placed.size():
		_shown[result.placed[i]] = Cell.new(piece.colors[i])
	queue_redraw()

	for step in result.steps:
		if step.chain >= 2:
			_show_popup("CHAIN x%d" % step.chain)
		for p in step.cleared:
			_flashing[p] = true
		queue_redraw()
		await get_tree().create_timer(FLASH_TIME).timeout

		_flashing.clear()
		for p in step.cleared:
			_shown.erase(p)
		for s in step.spawned:
			_shown[s["at"]] = Cell.new(s["color"], s["special"])
		# Lift every falling square first: a square's landing spot can be another's start.
		var carried: Array[Cell] = []
		for fall in step.falls:
			carried.append(_shown[fall["from"]])
		for fall in step.falls:
			_shown.erase(fall["from"])
		for i in step.falls.size():
			var to: Vector2i = step.falls[i]["to"]
			_shown[to] = carried[i]
			_falling[to] = to.y - step.falls[i]["from"].y
		if not step.falls.is_empty():
			var tween := create_tween()
			tween.tween_method(_set_fall_t, 0.0, 1.0, FALL_TIME)
			await tween.finished
		_falling.clear()

	if result.combo >= 2:
		_show_popup("COMBO x%d" % result.combo)
	_shown = _snapshot()
	_busy = false
	queue_redraw()
	drop_finished.emit(result)


func _set_fall_t(t: float) -> void:
	_fall_t = t
	queue_redraw()


func _show_popup(text: String) -> void:
	_popup_text = text
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_method(_set_popup_alpha, 1.0, 0.0, POPUP_TIME).set_ease(Tween.EASE_IN)


func _set_popup_alpha(a: float) -> void:
	_popup_alpha = a
	queue_redraw()


func _snapshot() -> Dictionary:
	var cells := {}
	for y in game.board.rows:
		for x in game.board.columns:
			var cell := game.board.get_cell(Vector2i(x, y))
			if cell:
				cells[Vector2i(x, y)] = cell
	return cells


func _load_textures() -> void:
	for key in TILE_PATHS:
		if ResourceLoader.exists(TILE_PATHS[key]):
			_textures["c%d" % key] = load(TILE_PATHS[key])
	for key in SPECIAL_PATHS:
		if ResourceLoader.exists(SPECIAL_PATHS[key]):
			_textures["s%d" % key] = load(SPECIAL_PATHS[key])


func _panel_x() -> float:
	return board_size().x + PANEL_GAP


# --- drawing ---------------------------------------------------------------

func _draw() -> void:
	var size := board_size()
	draw_rect(Rect2(Vector2.ZERO, size), BOARD_BG)
	for x in range(1, game.board.columns):
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, size.y), GRID_LINE, 2)
	for y in range(1, game.board.rows):
		draw_line(Vector2(0, y * CELL), Vector2(size.x, y * CELL), GRID_LINE, 2)

	for p: Vector2i in _shown:
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

	if _popup_alpha > 0.0:
		_draw_centered_text(_popup_text, Vector2(size.x / 2, size.y * 0.35), 96, Color(1, 0.9, 0.3, _popup_alpha))

	if game.is_over:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
		_draw_centered_text("GAME OVER", Vector2(size.x / 2, size.y * 0.45), 96, TEXT)
		_draw_centered_text("tap or press R to restart", Vector2(size.x / 2, size.y * 0.45 + 80), 40, TEXT_DIM)


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
	_draw_label("x%d" % game.combo, Vector2(x, combo_y + 70), 64, TEXT if game.combo > 0 else TEXT_DIM)


func _draw_cell(rect: Rect2, cell: Cell) -> void:
	var inner := rect.grow(-4)
	var center := inner.get_center()
	var r := inner.size.x / 2

	if cell.special == Cell.Special.RAINBOW:
		if _textures.has("s%d" % cell.special):
			draw_texture_rect(_textures["s%d" % cell.special], inner, false)
			return
		var stripe := inner.size.x / Cell.COLOR_COUNT
		for i in Cell.COLOR_COUNT:
			draw_rect(Rect2(inner.position + Vector2(i * stripe, 0), Vector2(stripe, inner.size.y)), BLOCK_COLORS[i])
		draw_circle(center, r * 0.3, Color.WHITE)
		return

	var base: Color = BLOCK_COLORS[cell.color]
	if _textures.has("c%d" % cell.color):
		draw_texture_rect(_textures["c%d" % cell.color], inner, false)
	else:
		_style_for(cell.color).draw(get_canvas_item(), inner)
		_draw_symbol(cell.color, center, r * 0.42, base.lightened(0.5))

	match cell.special:
		Cell.Special.LIGHTNING:
			if _textures.has("s%d" % cell.special):
				draw_texture_rect(_textures["s%d" % cell.special], inner, false)
			else:
				draw_line(center + Vector2(-r * 0.8, 0), center + Vector2(r * 0.8, 0), Color.WHITE, r * 0.18)
				draw_line(center + Vector2(0, -r * 0.8), center + Vector2(0, r * 0.8), Color.WHITE, r * 0.18)
		Cell.Special.BOMB:
			if _textures.has("s%d" % cell.special):
				draw_texture_rect(_textures["s%d" % cell.special], inner, false)
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


func _draw_centered_text(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, center - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
