extends SceneTree
## Plays many fights per monster with each BattleSim strategy and prints a table of how they went:
##   godot --headless --path . -s res://tests/sim_balance.gd -- --fights=300
## Any BattleRules or BoardRules property can be tried without editing data/balance.tres:
##   ... -- --chain_step=0.5 --min_line=4
## and so can the monsters' MonsterData, prefixed with "monster.": --monster.max_hp=60
## Other options: --monster=orc_shield (one monster only), --strategy=2 (one strategy only),
## --seed=1000 (first fight's seed; fight i uses seed + i).

const MONSTERS := ["res://data/monsters/scarecrow.tres", "res://data/monsters/orc_shield.tres"]
const BALANCE := "res://data/balance.tres"


func _initialize() -> void:
	var options := _parse_args()
	var battle_rules: BattleRules = load(BALANCE).duplicate()
	var board_rules := BoardRules.new()
	for key: String in options:
		if key in ["fights", "monster", "strategy", "seed"] or key.begins_with("monster."):
			continue
		var target: Resource = battle_rules if key in battle_rules else board_rules if key in board_rules else null
		if target == null:
			print("Không có luật nào tên '%s'" % key)
			quit(1)
			return
		target.set(key, type_convert(options[key], typeof(target.get(key))))
		print("Thử %s = %s" % [key, target.get(key)])

	var fights := int(options.get("fights", "200"))
	var first_seed := int(options.get("seed", "1000"))
	var started := Time.get_ticks_msec()
	for path: String in MONSTERS:
		var monster: MonsterData = load(path).duplicate()
		if options.has("monster") and options["monster"] != monster.id:
			continue
		for key: String in options:
			if key.begins_with("monster."):
				var property := key.trim_prefix("monster.")
				monster.set(property, type_convert(options[key], typeof(monster.get(property))))
		print("\n## %s (máu %d, khiên %d lớp, đánh %d mỗi %d lượt), %d trận mỗi kiểu chơi\n" % [monster.display_name, monster.max_hp, monster.shield_layers, monster.attack, monster.countdown, fights])
		print("| Kiểu chơi | Thắng | Lượt (p10 / giữa / p90) | Máu còn | Thắng trong 3 lượt | Đòn đầu | Lượt có tự nổ | Sát thương từ tự nổ | Vòng / lượt | Dài nhất | Ô đặc biệt sinh / kích | Xáo bảng | Chiêu / trận | Có chiêu | Lượt chiêu đầu |")
		print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
		for strategy in BattleSim.Strategy.values():
			if options.has("strategy") and int(options["strategy"]) != strategy:
				continue
			var sim := BattleSim.new(board_rules, battle_rules, strategy)
			var runs: Array[Dictionary] = []
			for i in fights:
				runs.append(sim.play_fight(monster, first_seed + i))
			print(_row(BattleSim.STRATEGY_NAMES[strategy], runs))
	print("\n(%.1f giây)" % ((Time.get_ticks_msec() - started) / 1000.0))
	quit()


func _row(name: String, runs: Array[Dictionary]) -> String:
	var wins := runs.filter(func(r: Dictionary) -> bool: return r["outcome"] == BattleState.Outcome.WON)
	var moves: Array = wins.map(func(r: Dictionary) -> int: return r["moves"])
	moves.sort()
	var all_moves := _sum(runs, "moves")
	var firsts: Array = runs.map(func(r: Dictionary) -> int: return r["first_skill"]).filter(func(m: int) -> bool: return m >= 0)
	firsts.sort()
	var quick := wins.filter(func(r: Dictionary) -> bool: return r["moves"] <= 3).size()
	return "| %s | %d%% | %s | %s | %d%% | %.1f | %d%% | %d%% | %.2f | %d | %.1f / %.1f | %.2f | %.1f | %d%% | %s |" % [
		name,
		roundi(100.0 * wins.size() / runs.size()),
		"%d / %d / %d" % [_pick(moves, 0.1), _pick(moves, 0.5), _pick(moves, 0.9)] if moves else "-",
		"%d" % roundi(_sum(wins, "hero_hp") / wins.size()) if wins else "-",
		roundi(100.0 * quick / runs.size()),
		_sum(runs, "first_hit") / runs.size(),
		roundi(100.0 * _sum(runs, "auto_moves") / all_moves),
		roundi(100.0 * _sum(runs, "auto_damage") / maxf(_sum(runs, "damage"), 1.0)),
		_sum(runs, "rounds") / all_moves,
		runs.map(func(r: Dictionary) -> int: return r["max_chain"]).max(),
		_sum(runs, "specials_made") / runs.size(),
		_sum(runs, "specials_fired") / runs.size(),
		_sum(runs, "reshuffles") / runs.size(),
		_sum(runs, "skills") / runs.size(),
		roundi(100.0 * firsts.size() / runs.size()),
		str(_pick(firsts, 0.5)) if firsts else "-",
	]


static func _sum(runs: Array, key: String) -> float:
	var total := 0.0
	for r: Dictionary in runs:
		total += r[key]
	return total


static func _pick(sorted: Array, fraction: float) -> int:
	return sorted[clampi(floori(fraction * sorted.size()), 0, sorted.size() - 1)]


static func _parse_args() -> Dictionary:
	var options := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.substr(2).split("=", true, 1)
			options[parts[0]] = parts[1]
	return options
