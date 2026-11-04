class_name TurnReport
extends RefCounted
## What one move did in the fight, for the battle view to show.

var damage := 0
var shield_damage := 0
var layers_broken := 0
var heal := 0
var gold := 0
## Rounds in this move's chain and squares in its link, for the fighters' reactions.
var chain := 0
var link_length := 0
## The link's color (Cell.BlockColor), or Cell.NO_COLOR for a link of stars.
var link_color := Cell.NO_COLOR
## The red damage was a critical hit: a critical tile was cleared, or luck.
var critical := false
## Damage the monster dealt to the hero this turn; 0 if it didn't attack.
var monster_attack := 0
## That attack was the monster's critical one.
var monster_critical := false
## The hero skill this report is for (see BattleState.SKILLS), or "" for a move on the board.
var skill := ""
## Rage the move filled; the bar is already updated.
var rage_gained := 0
var outcome := BattleState.Outcome.ONGOING
