class_name BoardRules
extends Resource
## Every tunable number for the board. Charms will later hand out modified copies.

@export var columns := 7
@export var rows := 8
## Squares a link needs before it clears.
@export var min_link := 3
## Same-colored squares in a straight row or column that clear by themselves after a fall.
## 4, not 3: with 3, two moves in three set off chains and the board plays itself (docs/core_plan.md, section 6).
@export var min_line := 4

@export_group("Specials left by long links")
@export var lightning_link := 5
@export var bomb_link := 6
## The star (Cell.Special.RAINBOW): wild, so it joins a link or line of any color.
@export var star_link := 7

@export_group("Critical tiles")
## Chance that a new red square dropping in is a critical tile.
@export_range(0.0, 1.0) var crit_tile_chance := 0.08
## No new critical tile drops while this many are already on the board.
@export var max_crit_tiles := 1
