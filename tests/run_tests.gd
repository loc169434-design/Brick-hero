extends SceneTree
## Runs every test_* method in SUITES and exits non-zero on failure:
##   godot --headless --path . -s res://tests/run_tests.gd
## A GDScript runtime error aborts a test without failing it, so also check the
## output for "SCRIPT ERROR".

const SUITES := [
	"res://tests/test_resolver.gd",
	"res://tests/test_obstacles.gd",
	"res://tests/test_levels.gd",
	"res://tests/test_link_game.gd",
	"res://tests/test_tile_art.gd",
	"res://tests/test_battle_state.gd",
	"res://tests/test_feel.gd",
	"res://tests/test_battle_sim.gd",
	"res://tests/test_character_clips.gd",
	"res://tests/test_campaign.gd",
	"res://tests/test_gear.gd",
]


func _initialize() -> void:
	var passed := 0
	var failed := 0
	for path: String in SUITES:
		var script: GDScript = load(path)
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var suite: RefCounted = script.new()
			suite.call(method_name)
			if suite.failures.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s :: %s" % [path.get_file(), method_name])
				for failure in suite.failures:
					print("    " + failure)
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
