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
## Every this many attacks is a critical one (BattleRules.monster_crit_multiplier), announced a
## move ahead. 0: never.
@export var crit_every := 0
## Which tile set the board uses during this fight (assets/tiles/<theme>/).
@export var tile_theme := "training"
## Battle backdrop: assets/bg/<background>.png.
@export var background := ""
## Shown one per move, in order, above the fight. For the tutorial.
@export var hints: PackedStringArray = []
## A boss's next form: when this one's health runs out it turns into that monster
## (data/monsters/<next_phase>.tres) instead of falling.
@export var next_phase := ""
## What its attacks do besides the damage: "rock" also throws a rock onto the board (an
## obstacle of two layers), "drum" beats the war drum so every later attack comes a move
## sooner (down to every 2 moves), even from the monster after it. "" for none.
@export var special := ""
