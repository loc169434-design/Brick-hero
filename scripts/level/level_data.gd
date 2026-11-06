class_name LevelData
extends Resource
## One level of the hundred (docs/campaign_100.md): who is fought, what has to be done to win,
## and what is on the board at the start. Each lives in data/levels/level_###.tres.
##
## Every goal set here must be met to win; an unset goal (0, -1, false) doesn't count. With
## `turns`, running out of moves before the goals are met loses the level.

## 1–100, also its place on the map.
@export var number := 1
## Monster ids fought one after another (data/monsters/<id>.tres); the hero's health carries
## over. A monster with a next_phase changes into it instead of falling.
@export var monsters: PackedStringArray = []
## Whether every monster has to fall.
@export var kill := true
## Moves allowed; 0 for no limit.
@export var turns := 0
## Gather this many squares of `collect_color` (Cell.BlockColor).
@export var collect := 0
@export var collect_color := -1
## Obstacles dealt onto the board (`obstacle`: "crate", "mud", "poison_toad", "time_bomb"),
## how many, how thick, and between which rows.
@export var obstacle := "crate"
@export var crates := 0
@export var crate_layers := 1
@export var crate_rows := Vector2i(3, 7)
## Whether every one of those obstacles has to be broken.
@export var break_crates := false
## An overlay laid on tiles at the start ("ice", "web", "mark"), how many, how thick (ice).
@export var cover := ""
@export var cover_count := 0
@export var cover_layers := 1
## Whether every one of those overlays has to be cleared.
@export var break_cover := false
## Items dealt onto the top row, to bring down to the bottom.
@export var rescue := 0
@export var rescue_item := "orc_flag"
## The hero starts with this much health instead of full; 0 for full.
@export var hero_hp := 0
## A bonus level: always won when the moves run out; stars by the gold picked up.
@export var bonus := false
@export var gold_target := 0
@export var gold_multiplier := 1.0
## A fixed board for a puzzle level; -1 for a random one.
@export var board_seed := -1
## Marks on the map.
@export var hard := false
@export var boss := false
@export var petal := false
## The story chapter read after winning this level the first time; 0 for none.
@export var chapter := 0
