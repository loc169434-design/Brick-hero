class_name SpecialFx
extends Node2D
## Plays the blasts of specials going off on the board: lightning beams down the row and the
## column, the bomb's blast over its 3×3, the star's burst with a spark on every square it
## takes, and a flash when two specials fuse. Sits above the tiles, in board coordinates.
##
## Art: assets/fx/specials/<name>.png atlases, 8 frames to a row, listed in specials.json.
## Lightning, bomb and fusion art is gray so it can be tinted with the special's color;
## the star's is already rainbow. Missing art just plays nothing.
##
## Over the art, drawn in added light: the board flashes, shockwave rings spread from each
## blast, a white-hot core runs down every lightning beam and rays spin out of the star.

const DIR := "res://assets/fx/specials/"
const MANIFEST := "specials.json"
const SHEET_COLUMNS := 8
## Tile art is drawn on a 128 px canvas; the spark's frame adds padding around it.
const TILE_ART_SIZE := 128.0
## Two lightnings fire their cross, then their diagonals this much later, so all eight read.
const DIAGONAL_DELAY := 0.1

var cell_size := 140.0
var board_size := Vector2(980, 1120)

var _manifest := {}
## name -> Texture2D, loaded on first use: the big atlases are several MiB of texture each.
var _textures := {}
## The atlas animations playing.
var _sheets: Node2D
## Drawn in added light above the sheets.
var _light: Node2D
## {"kind", "at", "t", "life", "color", ...} for each light shape still showing.
var _shapes: Array[Dictionary] = []
## Bumped by clear(), so beams still waiting on a timer know the board moved on.
var _generation := 0


func _ready() -> void:
	var path := DIR + MANIFEST
	if ResourceLoader.exists(path):
		var json: JSON = load(path)
		if json.data is Dictionary:
			_manifest = json.data
	_sheets = Node2D.new()
	add_child(_sheets)
	_light = Node2D.new()
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light.material = blend
	_light.draw.connect(_draw_light)
	add_child(_light)


func clear() -> void:
	_generation += 1
	for child in _sheets.get_children():
		child.queue_free()
	_shapes.clear()
	_light.queue_redraw()


func _process(delta: float) -> void:
	if _shapes.is_empty():
		return
	for shape in _shapes:
		shape["t"] += delta
	_shapes = _shapes.filter(func(s: Dictionary) -> bool: return s["t"] < s["life"])
	_light.queue_redraw()


func _shape(kind: String, at: Vector2, life: float, color: Color, extra := {}) -> void:
	var shape := {"kind": kind, "at": at, "t": 0.0, "life": life, "color": color}
	shape.merge(extra)
	_shapes.append(shape)


## The board lights up for a moment, and a ring spreads from `at` with a white flash behind it.
func _boom(at: Vector2, tint: Color, radius: float) -> void:
	_shape("board", Vector2.ZERO, 0.16, Color(1, 1, 1, 0.22))
	_shape("flash", at, 0.22, Color(1, 1, 0.92), {"radius": radius * 0.55})
	_shape("ring", at, 0.42, tint, {"radius": radius, "width": 34.0})
	_shape("ring", at, 0.3, Color.WHITE, {"radius": radius * 0.7, "width": 18.0})


func _draw_light() -> void:
	for shape in _shapes:
		var k: float = shape["t"] / shape["life"]
		var out := 1.0 - pow(1.0 - k, 3.0)
		var color: Color = shape["color"]
		var at: Vector2 = shape["at"]
		match shape["kind"]:
			"board":
				_light.draw_rect(Rect2(Vector2.ZERO, board_size), Color(color, color.a * (1.0 - k)))
			"flash":
				_light.draw_circle(at, shape["radius"] * (0.6 + 0.6 * out), Color(color, 0.85 * (1.0 - k) * (1.0 - k)))
			"ring":
				var width: float = shape["width"] * (1.0 - k)
				if width > 0.5:
					_light.draw_arc(at, shape["radius"] * (0.15 + 0.85 * out), 0, TAU, 64, Color(color, 1.0 - k), width, true)
			"beam":
				# A white-hot core inside a wider glow in the beam's color, both thinning away.
				var to: Vector2 = shape["to"]
				_light.draw_line(at, to, Color(color, 0.6 * (1.0 - k)), 70.0 * (1.0 - out * 0.7))
				_light.draw_line(at, to, Color(1, 1, 1, 1.0 - k), 22.0 * (1.0 - k))
			"rays":
				var spin: float = shape["spin"] + k * 1.4
				for i in 12:
					var direction := Vector2.from_angle(spin + i * TAU / 12)
					var reach: float = shape["radius"] * out
					var ray_color := Color(BoardView.BLOCK_COLORS[i % Cell.COLOR_COUNT].lightened(0.4), 1.0 - k)
					_light.draw_line(at + direction * reach * 0.25, at + direction * reach, ray_color, 16.0 * (1.0 - k))


## Everything `step` set off. Squares that fused play the fusion instead of their own blast.
func play_step(step: ClearStep) -> void:
	var fused := {}
	for fusion in step.fusions:
		fused[fusion["at"]] = true
		fused[fusion["with"]] = true
		_play_fusion(step, fusion)
	for p in step.triggered:
		if fused.has(p):
			continue
		var cell := _cell_at(step, p)
		if cell == null:
			continue
		match cell.special:
			Cell.Special.LIGHTNING:
				_beams(p, 0, _tint(cell.color))
				_boom(_center(p), _tint(cell.color), cell_size * 1.2)
			Cell.Special.BOMB:
				_play("bomb_blast", _center(p), _tint(cell.color), 0.0, Vector2.ONE * 1.15)
				_boom(_center(p), _tint(cell.color), cell_size * 2.2)
			Cell.Special.RAINBOW:
				_play("star_burst", _center(p))
				_sparks(step, p)
				_boom(_center(p), Color(1, 0.95, 0.7), cell_size * 2.0)
				_shape("rays", _center(p), 0.5, Color.WHITE, {"radius": cell_size * 4.0, "spin": randf() * TAU})


func _play_fusion(step: ClearStep, fusion: Dictionary) -> void:
	var at: Vector2i = fusion["at"]
	var with: Vector2i = fusion["with"]
	var kinds: Array = fusion["kinds"]
	var color := Cell.NO_COLOR
	for p in [at, with]:
		var cell := _cell_at(step, p)
		if cell and cell.color != Cell.NO_COLOR:
			color = cell.color
	var tint := _tint(color)
	_play("fusion_flash", (_center(at) + _center(with)) / 2.0, tint, 0.0, Vector2.ONE * 1.4)
	_boom(_center(at), tint, cell_size * 3.2)
	if Cell.Special.RAINBOW in kinds:
		_play("star_burst", _center(at))
		_sparks(step, at)
		_shape("rays", _center(at), 0.6, Color.WHITE, {"radius": cell_size * 6.0, "spin": randf() * TAU})
	elif kinds == [Cell.Special.LIGHTNING, Cell.Special.LIGHTNING]:
		# Two lightnings: eight ways, the cross first and the diagonals a beat later.
		_beams(at, 0, tint)
		get_tree().create_timer(DIAGONAL_DELAY).timeout.connect(_diagonal_beams.bind(at, tint, _generation))
	elif Cell.Special.LIGHTNING in kinds:
		# Lightning with a bomb: a cross three squares wide.
		_beams(at, 1, tint)
	else:
		# Two bombs: a 5×5 blast.
		_play("bomb_blast", _center(at), tint, 0.0, Vector2.ONE * 5.0 / 3.0)


## Beams along the rows and columns within `half_width` of `p`, crossing at a flash on `p`.
func _beams(p: Vector2i, half_width: int, tint: Color) -> void:
	var frame := _frame_size("lightning_beam.png")
	if frame == Vector2.ZERO:
		return
	for offset in range(-half_width, half_width + 1):
		var row := (p.y + offset + 0.5) * cell_size
		var column := (p.x + offset + 0.5) * cell_size
		if row > 0.0 and row < board_size.y:
			_beam_line(Vector2(0, row), Vector2.RIGHT, board_size.x, frame.x, tint)
			_shape("beam", Vector2(0, row), 0.3, tint, {"to": Vector2(board_size.x, row)})
		if column > 0.0 and column < board_size.x:
			_beam_line(Vector2(column, 0), Vector2.DOWN, board_size.y, frame.x, tint)
			_shape("beam", Vector2(column, 0), 0.3, tint, {"to": Vector2(column, board_size.y)})
	_play("lightning_hub", _center(p), tint)


## Beams along both diagonals through `p`, from board edge to board edge.
func _diagonal_beams(p: Vector2i, tint: Color, generation: int) -> void:
	if generation != _generation:
		return
	var frame := _frame_size("lightning_beam.png")
	if frame == Vector2.ZERO:
		return
	var center := _center(p)
	for direction: Vector2 in [Vector2(1, 1).normalized(), Vector2(1, -1).normalized()]:
		var start := center - direction * _reach(center, -direction)
		var end := center + direction * _reach(center, direction)
		_beam_line(start, direction, start.distance_to(end), frame.x, tint)
		_shape("beam", start, 0.3, tint, {"to": end})
	_play("lightning_hub", center, tint, PI / 4)


## How far from `at` along `direction` until the board's edge.
func _reach(at: Vector2, direction: Vector2) -> float:
	var reach := INF
	if direction.x != 0.0:
		reach = minf(reach, ((board_size.x if direction.x > 0.0 else 0.0) - at.x) / direction.x)
	if direction.y != 0.0:
		reach = minf(reach, ((board_size.y if direction.y > 0.0 else 0.0) - at.y) / direction.y)
	return reach


## The beam art is one seamless stretch; repeat it, squeezed a little, to span exactly `length`.
func _beam_line(start: Vector2, direction: Vector2, length: float, segment: float, tint: Color) -> void:
	var count := ceili(length / segment)
	var stretch := length / count
	for i in count:
		var at := start + direction * stretch * (i + 0.5)
		_play("lightning_beam", at, tint, direction.angle(), Vector2(stretch / segment, 1.0))


## A spark on every square the star took, besides the star itself.
func _sparks(step: ClearStep, star: Vector2i) -> void:
	for p in step.cleared:
		if p != star:
			_play("star_spark", _center(p), Color.WHITE, 0.0, Vector2.ONE * cell_size / TILE_ART_SIZE)


func _play(sheet: String, at: Vector2, tint := Color.WHITE, angle := 0.0, size := Vector2.ONE) -> void:
	var file := sheet + ".png"
	var entry: Dictionary = _manifest.get(file, {})
	var texture := _texture(file)
	if entry.is_empty() or texture == null:
		return
	var frames: int = entry["frames"]
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = SHEET_COLUMNS
	sprite.vframes = ceili(float(frames) / SHEET_COLUMNS)
	sprite.position = at
	sprite.rotation = angle
	sprite.scale = size
	sprite.modulate = tint
	_sheets.add_child(sprite)
	var tween := sprite.create_tween()
	tween.tween_method(func(f: float) -> void: sprite.frame = mini(int(f), frames - 1), 0.0, float(frames), frames / float(entry["fps"]))
	tween.tween_callback(sprite.queue_free)


func _frame_size(file: String) -> Vector2:
	var entry: Dictionary = _manifest.get(file, {})
	if entry.is_empty():
		return Vector2.ZERO
	return Vector2(entry["frame_width"], entry["frame_height"])


func _texture(file: String) -> Texture2D:
	if not _textures.has(file):
		var path := DIR + file
		_textures[file] = load(path) if ResourceLoader.exists(path) else null
	return _textures[file]


func _center(p: Vector2i) -> Vector2:
	return (Vector2(p) + Vector2(0.5, 0.5)) * cell_size


## The gray art times the special's color, lifted so the bright core stays bright.
func _tint(color: int) -> Color:
	if not BoardView.BLOCK_COLORS.has(color):
		return Color.WHITE
	return BoardView.BLOCK_COLORS[color].lightened(0.35)


static func _cell_at(step: ClearStep, p: Vector2i) -> Cell:
	var i := step.cleared.find(p)
	return step.cleared_cells[i] if i >= 0 else null
