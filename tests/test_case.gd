extends RefCounted
## Minimal assertions for the headless runner. Every test_* method runs on a fresh instance.

var failures: PackedStringArray = []


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		failures.append("expected true" + _context(message))


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("expected %s, got %s%s" % [str(expected), str(actual), _context(message)])


func _context(message: String) -> String:
	return " (%s)" % message if message else ""
