class_name Piece
extends RefCounted
## A piece in the player's hand: a few squares around a pivot at (0, 0), each with its own color.

var shape_id: StringName
var offsets: Array[Vector2i] = []
var colors: Array[int] = []


func _init(p_shape_id: StringName, p_offsets: Array, p_colors: Array) -> void:
	shape_id = p_shape_id
	offsets.assign(p_offsets)
	colors.assign(p_colors)


func size() -> int:
	return offsets.size()


func cells_at(origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for o in offsets:
		result.append(origin + o)
	return result


## Colors stay with their squares, so turning a two-color piece changes where each color lands.
func rotated(clockwise := true) -> Piece:
	var turned: Array[Vector2i] = []
	for o in offsets:
		turned.append(Vector2i(-o.y, o.x) if clockwise else Vector2i(o.y, -o.x))
	return Piece.new(shape_id, turned, colors)


func bounds() -> Rect2i:
	var lo := offsets[0]
	var hi := offsets[0]
	for o in offsets:
		lo = lo.min(o)
		hi = hi.max(o)
	return Rect2i(lo, hi - lo + Vector2i.ONE)
