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
## Each clearing drop in a row after the first adds this much: x1, x1.25, x1.5…
@export var combo_bonus := 0.25

@export_group("Shield")
## Shield points per layer.
@export var shield_layer_size := 10
## Red damage dealt while any shield is left is multiplied by this.
@export_range(0.0, 1.0) var shielded_damage_factor := 0.5
## A chain reaching this round smashes one whole layer on top of the purple.
@export var layer_break_chain := 3
