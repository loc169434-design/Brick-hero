class_name PieceBag
extends RefCounted
## Deals pieces from a shuffled bag of shapes, so no shape is starved or repeated too often,
## and keeps the preview queue.

## Deliberately not the classic seven: smaller pieces help build color clusters.
const SHAPES := {
	&"duo": [Vector2i(0, 0), Vector2i(1, 0)],
	&"trio_line": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0)],
	&"trio_corner": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1)],
	&"square": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	&"line": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0)],
	&"tee": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)],
	&"ell": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(1, -1)],
	&"zig": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)],
}

var _rules: BoardRules
var _rng: RandomNumberGenerator
var _bag: Array[StringName] = []
var _queue: Array[Piece] = []


func _init(rules: BoardRules, rng: RandomNumberGenerator) -> void:
	_rules = rules
	_rng = rng
	_fill_queue()


func next() -> Piece:
	var piece: Piece = _queue.pop_front()
	_fill_queue()
	return piece


func preview() -> Array[Piece]:
	return _queue.duplicate()


## At most two colors per piece, so the player can still plan clusters.
func make_piece(shape_id: StringName) -> Piece:
	var first := _rng.randi_range(0, Cell.COLOR_COUNT - 1)
	var second := first
	if _rng.randf() >= _rules.single_color_chance:
		second = (first + _rng.randi_range(1, Cell.COLOR_COUNT - 1)) % Cell.COLOR_COUNT
	var offsets: Array = SHAPES[shape_id]
	var colors: Array[int] = []
	for i in offsets.size():
		colors.append(first if _rng.randf() < 0.5 else second)
	if not colors.has(first):
		colors[0] = first
	if not colors.has(second):
		colors[colors.size() - 1] = second
	return Piece.new(shape_id, offsets, colors)


func _fill_queue() -> void:
	while _queue.size() < maxi(_rules.preview_count, 1):
		_queue.append(make_piece(_draw_shape()))


func _draw_shape() -> StringName:
	if _bag.is_empty():
		_bag.assign(SHAPES.keys())
		# Array.shuffle() ignores our seeded RNG, so shuffle by hand.
		for i in range(_bag.size() - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var swap := _bag[i]
			_bag[i] = _bag[j]
			_bag[j] = swap
	return _bag.pop_back()
