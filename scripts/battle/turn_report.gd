class_name TurnReport
extends RefCounted
## What one drop did in the fight, for the battle view to show.

var damage := 0
var shield_damage := 0
var layers_broken := 0
var heal := 0
var gold := 0
## Damage the monster dealt to the hero this turn; 0 if it didn't attack.
var monster_attack := 0
var outcome := BattleState.Outcome.ONGOING
