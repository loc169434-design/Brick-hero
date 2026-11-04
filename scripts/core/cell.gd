class_name Cell
extends RefCounted
## One occupied square on the board. Empty squares are `null`.

enum BlockColor { RED, GREEN, YELLOW, PURPLE }
enum Special { NONE, LIGHTNING, BOMB, RAINBOW }

const COLOR_COUNT := 4
const NO_COLOR := -1

var color: int
var special: Special
## A critical tile (red only): a move that clears it lands a critical hit. Shown with sparks.
var critical := false


func _init(p_color: int = NO_COLOR, p_special: Special = Special.NONE) -> void:
	color = p_color
	special = p_special


static func rainbow() -> Cell:
	return Cell.new(NO_COLOR, Special.RAINBOW)


## Specials are wild: they join a link of any color, and any specials link with each other.
## A bomb or lightning still keeps the color of the link that made it, for what it sets off.
func matches(c: int) -> bool:
	return special != Special.NONE or color == c


func is_special() -> bool:
	return special != Special.NONE
