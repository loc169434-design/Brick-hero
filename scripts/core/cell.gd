class_name Cell
extends RefCounted
## One occupied square on the board. Empty squares are `null`.

enum BlockColor { RED, GREEN, YELLOW, PURPLE }
enum Special { NONE, LIGHTNING, BOMB, RAINBOW }

const COLOR_COUNT := 4
const NO_COLOR := -1

var color: int
var special: Special


func _init(p_color: int = NO_COLOR, p_special: Special = Special.NONE) -> void:
	color = p_color
	special = p_special


static func rainbow() -> Cell:
	return Cell.new(NO_COLOR, Special.RAINBOW)


## Rainbow cells are wild: they join a cluster of any color.
func matches(c: int) -> bool:
	return special == Special.RAINBOW or color == c


func is_special() -> bool:
	return special != Special.NONE
