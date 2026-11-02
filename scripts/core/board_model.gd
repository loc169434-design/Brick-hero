class_name BoardModel
extends RefCounted
## The grid of squares. (0, 0) is the top-left corner and y grows downward.

var columns: int
var rows: int
var _cells: Array = []


func _init(p_columns: int, p_rows: int) -> void:
	columns = p_columns
	rows = p_rows
	_cells.resize(columns * rows)


func is_inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < columns and p.y >= 0 and p.y < rows


func get_cell(p: Vector2i) -> Cell:
	return _cells[p.y * columns + p.x] if is_inside(p) else null


func set_cell(p: Vector2i, cell: Cell) -> void:
	_cells[p.y * columns + p.x] = cell


func count() -> int:
	return _cells.size() - _cells.count(null)


## Fills the bottom rows from text, for tests and debug setups.
## R G Y P are colors, * is a star, . is empty; spaces are ignored.
func fill_from_pattern(lines: Array) -> void:
	var top := rows - lines.size()
	for i in lines.size():
		var line: String = lines[i].replace(" ", "")
		for x in mini(line.length(), columns):
			set_cell(Vector2i(x, top + i), _cell_from_char(line[x]))


static func _cell_from_char(ch: String) -> Cell:
	match ch:
		"R":
			return Cell.new(Cell.BlockColor.RED)
		"G":
			return Cell.new(Cell.BlockColor.GREEN)
		"Y":
			return Cell.new(Cell.BlockColor.YELLOW)
		"P":
			return Cell.new(Cell.BlockColor.PURPLE)
		"*":
			return Cell.rainbow()
	return null
