class_name MonsterData
extends Resource
## One kind of monster. Each lives in data/monsters/<id>.tres.

## Also names its art: assets/monsters/<id>_idle.png and so on.
@export var id := ""
@export var display_name := ""
@export var max_hp := 80
@export var shield_layers := 0
## Damage to the hero when the countdown runs out.
@export var attack := 10
## Drops between attacks.
@export var countdown := 4
## Which tile set the board uses during this fight (assets/tiles/<theme>/).
@export var tile_theme := "training"
