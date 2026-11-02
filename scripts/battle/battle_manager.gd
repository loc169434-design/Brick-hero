class_name BattleManager
extends Node
## Runs one fight: feeds each finished drop to the BattleState, shows the result above the
## board, makes the board's tiles react, and ends the board when the fight is decided.

@export var board: BoardView
@export var battle_view: BattleView
@export var monster: MonsterData
@export var rules: BattleRules

var state: BattleState


func _ready() -> void:
	board.drop_finished.connect(_on_drop_finished)
	board.restarted.connect(_start)
	_start()


func _start() -> void:
	state = BattleState.new(rules, monster)
	board.set_tile_theme(monster.tile_theme)
	battle_view.show_state(state)


func _on_drop_finished(result: DropResult) -> void:
	if board.game.is_over:
		state.lose()
	var report := state.apply_drop(result)
	battle_view.play_report(report)
	match state.outcome:
		BattleState.Outcome.WON:
			board.finish(true)
		BattleState.Outcome.LOST:
			board.finish(false)
		_:
			if report.damage > 0:
				board.play_reaction(&"hurt", 2)
			elif report.monster_attack > 0 and state.hero_hp * 10 < rules.hero_max_hp * 3:
				board.play_reaction(&"gloat", 1)
