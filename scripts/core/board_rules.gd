class_name BoardRules
extends Resource
## Every tunable number for the board. Charms will later hand out modified copies.

@export var columns := 8
@export var rows := 12
## Same-color squares touching by an edge that clear together.
@export var min_cluster := 4
@export var lightning_cluster := 5
@export var bomb_cluster := 6
## Full rows cleared in one round that leave a rainbow behind.
@export var rainbow_rows := 2
@export var preview_count := 3
## Chance a piece comes in one color instead of two.
@export_range(0.0, 1.0) var single_color_chance := 0.35
