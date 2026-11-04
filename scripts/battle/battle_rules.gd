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

@export_group("Hero gear")
## Taken off every monster attack by armor and boots; an attack still does at least 1.
@export var armor := 0
## 0..1: how much of a monster's critical bonus the helmet stops. 1 makes critical attacks
## hit like normal ones.
@export_range(0.0, 1.0) var crit_guard := 0.0

@export_group("Shield")
## Shield points per layer.
@export var shield_layer_size := 10
## Red damage dealt while any shield is left is multiplied by this.
@export_range(0.0, 1.0) var shielded_damage_factor := 0.5
## A chain reaching this round smashes one whole layer on top of the purple.
@export var layer_break_chain := 3

@export_group("Rage and hero skill")
## The hero's skill this fight: one of BattleState.SKILLS.
@export var skill := "armor_breaker"
## Rage it takes to use the skill; the bar stops filling there.
@export var rage_max := 100
## Rage per plain square cleared (specials don't count), whatever the chain round.
@export var rage_per_square := 2.0
## Extra rage for each fusion of two specials.
@export var rage_per_fusion := 12.0
## At most this much rage from one move.
@export var rage_per_move := 40
## Phá Giáp: strips this many shield points, then hits like this many red squares (so a
## better sword hits harder), halved like red while shield is left.
@export var armor_breaker_shield := 10
@export var armor_breaker_squares := 8.0
## Hồi Quang: health back.
@export var second_wind_heal := 25
