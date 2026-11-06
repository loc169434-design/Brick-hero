extends "res://tests/test_case.gd"


func _level(fields: Dictionary) -> LevelData:
	var level := LevelData.new()
	for k in fields:
		level.set(k, fields[k])
	return level


## A move whose single round cleared `colors` and broke `crates` crates and rescued `items`.
func _move(colors: Array, crates := 0, items := 0) -> MoveResult:
	var step := ClearStep.new()
	for c in colors:
		step.cleared_cells.append(Cell.new(c))
		step.cleared.append(Vector2i.ZERO)
	for i in crates:
		step.broken.append({"at": Vector2i.ZERO, "kind": "crate"})
	for i in items:
		step.rescued.append({"at": Vector2i.ZERO, "kind": "orc_flag"})
	var result := MoveResult.new()
	result.steps.append(step)
	return result


func test_a_fight_is_won_when_the_monsters_fall() -> void:
	var progress := LevelProgress.new(_level({}))
	assert_true(not progress.goals_met(false))
	assert_true(progress.goals_met(true))
	assert_eq(progress.turns_left(), -1)


func test_gathering_counts_only_the_goal_color() -> void:
	var Y := Cell.BlockColor.YELLOW
	var progress := LevelProgress.new(_level({"kill": false, "collect": 5, "collect_color": Y, "turns": 10}))
	progress.record(_move([Y, Y, Cell.BlockColor.RED]))
	assert_eq(progress.collected, 2)
	assert_true(not progress.goals_met(false))
	progress.record(_move([Y, Y, Y]))
	assert_true(progress.goals_met(false), "the monster needn't fall")
	assert_eq(progress.turns_left(), 8)


func test_crates_and_rescues_count_toward_their_goals() -> void:
	var progress := LevelProgress.new(_level({"kill": false, "crates": 3, "break_crates": true, "rescue": 2}))
	progress.record(_move([], 2, 1))
	assert_true(not progress.goals_met(true))
	progress.record(_move([], 1, 1))
	assert_true(progress.goals_met(true))


func test_running_out_of_moves() -> void:
	var progress := LevelProgress.new(_level({"turns": 2}))
	progress.record(_move([]))
	assert_true(not progress.out_of_turns())
	progress.record(_move([]))
	assert_true(progress.out_of_turns())
	assert_eq(progress.turns_left(), 0)


func test_stars_by_moves_to_spare_or_by_gold() -> void:
	var limited := LevelProgress.new(_level({"turns": 10}))
	for i in 5:
		limited.record(_move([]))
	assert_eq(limited.stars(0.1, 0), 3, "half the moves to spare")
	var bonus := LevelProgress.new(_level({"bonus": true, "turns": 5, "gold_target": 40}))
	assert_eq(bonus.stars(1.0, 20), 1)
	assert_eq(bonus.stars(1.0, 30), 2)
	assert_eq(bonus.stars(1.0, 45), 3)
	var plain := LevelProgress.new(_level({}))
	assert_eq(plain.stars(0.9, 0), 3, "health left without a move limit")


func test_a_bonus_level_is_won_when_the_moves_run_out() -> void:
	var progress := LevelProgress.new(_level({"bonus": true, "turns": 1}))
	assert_true(not progress.goals_met(false))
	progress.record(_move([]))
	assert_true(progress.goals_met(false))


func test_every_level_file_loads_and_names_real_monsters() -> void:
	var dir := "res://data/levels/"
	var found := 0
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".tres"):
			continue
		var level: LevelData = load(dir + file)
		assert_true(level != null, file)
		assert_eq(file, "level_%03d.tres" % level.number, "file name matches the number")
		assert_true(level.monsters.size() > 0, file)
		for id in level.monsters:
			var monster: MonsterData = load("res://data/monsters/%s.tres" % id)
			assert_true(monster != null, "%s: %s" % [file, id])
			if monster and monster.next_phase:
				assert_true(ResourceLoader.exists("res://data/monsters/%s.tres" % monster.next_phase), monster.next_phase)
		found += 1
	assert_true(found >= 18, "act 1 is there")


func _attack_move() -> MoveResult:
	var result := MoveResult.new()
	result.steps.append(ClearStep.new())
	return result


func test_the_rock_thrower_throws_a_rock_with_every_attack() -> void:
	var rules: BattleRules = load("res://data/balance.tres")
	var state := BattleState.new(rules, load("res://data/monsters/orc_rock.tres"))
	var thrown := 0
	for i in 9:
		if state.apply_move(_attack_move()).rock_thrown:
			thrown += 1
	assert_eq(thrown, 3, "an attack every 3 moves, each with a rock")


func test_the_war_drum_speeds_the_attacks_up_to_every_two_moves() -> void:
	var rules: BattleRules = load("res://data/balance.tres")
	var drummer: MonsterData = load("res://data/monsters/orc_drummer.tres")
	var state := BattleState.new(rules, drummer)
	assert_eq(state.attack_every(), 4)
	var gaps: Array[int] = []
	var since := 0
	for i in 16:
		since += 1
		if state.apply_move(_attack_move()).drummed:
			gaps.append(since)
			since = 0
	assert_eq(gaps.slice(0, 4), [4, 3, 2, 2], "4 moves, then 3, then never under 2")
	state.hero_hp = rules.hero_max_hp


func test_the_story_chapters_after_levels_have_panels_and_captions() -> void:
	for number in [1, 2]:
		assert_true(StoryView.has_chapter(number), "chapter %d" % number)
		var captions := StoryView._json(StoryView.CAPTIONS % number)
		var info := StoryView._json(StoryView.STORY_DIR % number + "chapter.json")
		assert_eq(captions.get("captions", []).size(), info.get("panels", []).size(), "a caption per panel")
	assert_true(not StoryView.has_chapter(0))
	var five: LevelData = load("res://data/levels/level_005.tres")
	assert_eq(five.chapter, 1)
