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
## The monster's attack threw a rock onto the board (MonsterData.special "rock").
var rock_thrown := false
## The monster's attack beat the war drum: its attacks now come a move sooner.
var drummed := false
## The monster's attack poisoned the hero (BattleState.poison).
var poisoned := false
## Health the poison took this move, and whether green squares washed it out instead.
var poison_damage := 0
var cured := false
## Health the monster drank back with its bite.
var leeched := 0
## A spell the monster's attack casts on the board ("toads", "bomb", "web", "ice", "marks",
## "broom", "potion"…), for the fight to carry out; "" for none.
var board_spell := ""
## The hero turned back from a toad, or the broom spell broke, this move.
var toad_back := false
var broom_broken := false
## Health the board took this move: time bombs going off and poison toads spitting.
var board_damage := 0
## A potion bottle burst this move and turned the hero into a toad.
var turned_toad := false
## The broom spell landed on the sword this move.
var broomed := false
## The monster flew into a rage this move.
var raged := false
## The witch's lifted tile: thrown at the hero, or the spell broke because the tile was
## cleared first. Also whether the tile was one of the hero's specials (it goes off on them).
var lift_thrown := false
var lift_fizzled := false
var lift_special := false
## Gold a thief took for the marks left on the board.
var stolen := 0
## A booster used ("potion"), played by the fight like a skill.
var booster := ""
var outcome := BattleState.Outcome.ONGOING
