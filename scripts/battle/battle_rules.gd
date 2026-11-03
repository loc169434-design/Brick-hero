class_name BattleRules
extends Resource
## Every number that turns cleared squares into a fight. Edited in data/balance.tres.

@export var hero_max_hp := 100

@export_group("Per cleared square")
## Red: damage to the monster.
@export var red_damage := 2.0
## Green: healing for the hero.
@export var green_heal := 1.0
## Yellow: gold.
@export var yellow_gold := 1.0
## Purple: shield points stripped.
@export var purple_shield := 2.0

@export_group("Multipliers")
## Round n of a chain counts 1 + chain_step × (n - 1) times: x1, x2, x3…
@export var chain_step := 1.0

@export_group("Critical hits")
## Red damage of a critical hit is multiplied by this.
@export var crit_multiplier := 2.0
## Chance of a critical hit on any move that deals red damage, on top of critical tiles.
@export_range(0.0, 1.0) var crit_chance := 0.0
## A monster's critical attack (MonsterData.crit_every) hits this many times harder.
@export var monster_crit_multiplier := 1.5

@export_group("Shield")
## Shield points per layer.
@export var shield_layer_size := 10
## Red damage dealt while any shield is left is multiplied by this.
@export_range(0.0, 1.0) var shielded_damage_factor := 0.5
## A chain reaching this round smashes one whole layer on top of the purple.
@export var layer_break_chain := 3
