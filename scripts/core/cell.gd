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
## Not a tile but an obstacle: "crate" or "rock" (broken by clearing beside it, one layer a
## time), or an item such as "orc_flag" to bring down to the bottom row. Blockers have no
## color, can't be linked, and fall like any other square.
var blocker := ""
## Layers left on a crate or rock. Items have none: they can't be broken.
var layers := 0
## Moves left before a time bomb goes off or a potion bottle bursts.
var timer := 0
## Overlays on a tile, which keeps its color. Ice (layers): the tile still links, but clearing
## it only melts a layer. Web: the tile can't be linked until a square beside it clears or a
## blast hits it. Marked: a thief's mark on a gold tile, gone when the tile clears.
var ice := 0
var web := false
var marked := false


func _init(p_color: int = NO_COLOR, p_special: Special = Special.NONE) -> void:
	color = p_color
	special = p_special


static func rainbow() -> Cell:
	return Cell.new(NO_COLOR, Special.RAINBOW)


## A crate or rock with `p_layers` layers, or an item (no layers).
static func obstacle(kind: String, p_layers := 0) -> Cell:
	var cell := Cell.new()
	cell.blocker = kind
	cell.layers = p_layers
	return cell


func is_blocker() -> bool:
	return blocker != ""


## An item to rescue: a blocker that can't be broken, only brought down to the bottom row.
func is_item() -> bool:
	return blocker != "" and layers == 0


## Specials are wild: they join a link of any color, and any specials link with each other.
## A bomb or lightning still keeps the color of the link that made it, for what it sets off.
func matches(c: int) -> bool:
	return not is_blocker() and not web and (special != Special.NONE or color == c)


func is_special() -> bool:
	return special != Special.NONE
