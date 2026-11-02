class_name SpecialFx
extends Node2D
## Plays the blasts of specials going off on the board: lightning beams down the row and the
## column, the bomb's blast over its 3×3, the star's burst with a spark on every square it
## takes, and a flash when two specials fuse. Sits above the tiles, in board coordinates.
##
## Art: assets/fx/specials/<name>.png atlases, 8 frames to a row, listed in specials.json.
## Lightning, bomb and fusion art is gray so it can be tinted with the special's color;
## the star's is already rainbow. Missing art just plays nothing.

const DIR := "res://assets/fx/specials/"
const MANIFEST := "specials.json"
const SHEET_COLUMNS := 8
## Tile art is drawn on a 128 px canvas; the spark's frame adds padding around it.
const TILE_ART_SIZE := 128.0

var cell_size := 140.0
var board_size := Vector2(980, 1120)

var _manifest := {}
## name -> Texture2D, loaded on first use: the big atlases are several MiB of texture each.
var _textures := {}


func _ready() -> void:
	var path := DIR + MANIFEST
	if ResourceLoader.exists(path):
		var json: JSON = load(path)
		if json.data is Dictionary:
			_manifest = json.data


func clear() -> void:
	for child in get_children():
		child.queue_free()


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
			Cell.Special.BOMB:
				_play("bomb_blast", _center(p), _tint(cell.color))
			Cell.Special.RAINBOW:
				_play("star_burst", _center(p))
				_sparks(step, p)


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
	if Cell.Special.RAINBOW in kinds:
		_play("star_burst", _center(at))
		_sparks(step, at)
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
		if column > 0.0 and column < board_size.x:
			_beam_line(Vector2(column, 0), Vector2.DOWN, board_size.y, frame.x, tint)
	_play("lightning_hub", _center(p), tint)


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
	add_child(sprite)
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
