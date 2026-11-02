class_name BoardRules
extends Resource
## Every tunable number for the board. Charms will later hand out modified copies.

@export var columns := 7
@export var rows := 8
## Squares a link needs before it clears.
@export var min_link := 3
## Same-colored squares in a straight row or column that clear by themselves after a fall.
@export var min_line := 3

@export_group("Specials left by long links")
@export var lightning_link := 5
@export var bomb_link := 6
## The star (Cell.Special.RAINBOW): wild, so it joins a link or line of any color.
@export var star_link := 7
