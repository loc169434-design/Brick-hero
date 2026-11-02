class_name MonsterData
extends Resource
## One kind of monster. Each lives in data/monsters/<id>.tres.

## Also names its art folder: assets/characters/<id>/.
@export var id := ""
@export var display_name := ""
@export var max_hp := 80
@export var shield_layers := 0
## False for training dummies: no countdown, never hits back.
@export var counterattacks := true
## Damage to the hero when the countdown runs out.
@export var attack := 10
## Moves between attacks.
@export var countdown := 4
## Which tile set the board uses during this fight (assets/tiles/<theme>/).
@export var tile_theme := "training"
## Battle backdrop: assets/bg/<background>.png.
@export var background := ""
## Shown one per move, in order, above the fight. For the tutorial.
@export var hints: PackedStringArray = []
