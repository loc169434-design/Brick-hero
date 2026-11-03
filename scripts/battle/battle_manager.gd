class_name BattleManager
extends Node
## Runs the fights in order: feeds each finished move to the BattleState, shows the result
## above the board, makes the board's tiles react, and ends the board when a fight is decided.
## Winning moves on to the next encounter; losing retries the same one.

## Below this much health after a hit, the monster's tiles sweat out a close call (near_miss).
const NEAR_MISS_HEALTH := 0.15
## Below this much health, the hero is close enough to losing for the tiles to gloat.
const GLOAT_HEALTH := 0.3

@export var board: BoardView
@export var battle_view: BattleView
## Shakes the screen when the board or the fight reports an impact. Optional.
@export var feel: ScreenFeel
## Fought in order: the training scarecrow, then the Shield Orc, and so on.
@export var encounters: Array[MonsterData] = []
@export var rules: BattleRules

var state: BattleState
var encounter_index := 0
var _advance_on_restart := false


func _ready() -> void:
	board.move_finished.connect(_on_move_finished)
	board.restarted.connect(_start)
	if feel:
		board.impact.connect(feel.impact)
		battle_view.impact.connect(feel.impact)
		battle_view.slow_motion.connect(feel.slow_motion)
	board.orb_targets = battle_view.orb_targets()
	_start()


func monster() -> MonsterData:
	return encounters[encounter_index]


## How the monster's faces on the board answer a move that left the fight going, as
## [clip, how many tiles], or [&"", 0] for none. Themes without the clip just skip it.
static func board_reaction(report: TurnReport, state: BattleState) -> Array:
	if report.monster_attack > 0 and state.hero_health() < GLOAT_HEALTH:
		return [&"gloat", 1]
	if report.damage > 0:
		if state.monster_health() <= NEAR_MISS_HEALTH:
			return [&"near_miss", 2]
		return [&"hurt", 2]
	if report.shield_damage == 0 and state.monster.counterattacks:
		# Only green and yellow: nothing that hurts it, so it laughs.
		return [&"taunt", 2]
	return [&"", 0]


func _start() -> void:
	if _advance_on_restart:
		encounter_index = (encounter_index + 1) % encounters.size()
		_advance_on_restart = false
	state = BattleState.new(rules, monster())
	state.rng.randomize()
	board.set_tile_theme(monster().tile_theme)
	battle_view.show_state(state)
	_show_hint()


func _on_move_finished(result: MoveResult) -> void:
	var report := state.apply_move(result)
	battle_view.play_report(report)
	_show_hint()
	match state.outcome:
		BattleState.Outcome.WON:
			_advance_on_restart = true
			var last := encounter_index == encounters.size() - 1
			board.finish(true, "chạm để chơi lại từ đầu" if last else "chạm để gặp đối thủ tiếp theo")
		BattleState.Outcome.LOST:
			board.finish(false, "chạm để đánh lại")
		_:
			var reaction := board_reaction(report, state)
			if reaction[1] > 0:
				board.play_reaction(reaction[0], reaction[1])


func _show_hint() -> void:
	var hints := monster().hints
	var ongoing := state.outcome == BattleState.Outcome.ONGOING
	battle_view.show_hint(hints[state.moves] if ongoing and state.moves < hints.size() else "")
