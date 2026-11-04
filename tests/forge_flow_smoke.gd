extends SceneTree
## Real scene/timers/resources, with no save writes. Run separately from the synchronous suite:
## godot --headless --path . -s res://tests/forge_flow_smoke.gd

var failures: Array[String] = []
var hits: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		print("FAIL forge: " + message)


func wait_until(predicate: Callable, timeout := 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return predicate.call()


func fixture() -> ForgeView:
	var view := ForgeView.new()
	root.add_child(view)
	var campaign := Campaign.from_map()
	campaign.gold = 100
	campaign.cleared.assign(["scarecrow", "orc_shield"])
	view.show_campaign(campaign)
	view._smith.clip_impact.connect(func(clip: StringName) -> void: hits.append(String(clip)))
	return view


func run() -> void:
	Sfx.muted = true
	var view := fixture()
	var bought: Array[String] = []
	view.bought.connect(func(id: String) -> void: bought.append(id))
	view._on_piece_tapped("weapon")
	check(view.campaign.gold == 55, "one purchase spends 45 gold")
	check(bought == ["iron_sword"], "one purchase/save signal")
	check(await wait_until(func() -> bool: return view._waiting_strike), "metal reaches anvil")
	for strike in range(1, 4):
		var clip := &"hammer_final" if strike == 3 else &"hammer"
		var previous_hits := hits.size()
		view._strike()
		for tap in 10:
			view._strike()
		check(view._strikes == strike, "rapid taps do not restart strike %d" % strike)
		check(not view._waiting_strike, "prompt and auto-strike stop during swing")
		check(view._smith.mood == clip, "correct clip for strike %d" % strike)
		check(view.to_local(view._smith.point("hammer")).distance_to(ForgeView.ANVIL_TOP) < 0.01, "head meets anvil")
		await create_timer(0.33).timeout
		check(view._smith.mood == clip, "wind-up survives the old 0.32-second cutoff")
		check(hits.size() == previous_hits, "no impact before its frame")
		check(await wait_until(func() -> bool: return hits.size() > previous_hits), "contact event arrives")
		check(hits.size() == previous_hits + 1 and hits[-1] == String(clip), "one correct impact event")
		check(view._strike_landed, "view receives the actual contact frame")
		check(view._smith._clip_frame() == (12 if strike == 3 else 9), "contact is displayed")
		check(view._smith._body.scale == Vector2.ONE, "drawn cel has no extra squash")
		var sparks := view._sparks.size()
		view._land_strike()
		check(view._sparks.size() == sparks, "contact effects are not replayed")
		if strike < 3:
			check(await wait_until(func() -> bool: return view._waiting_strike), "full recovery enables next strike")
		else:
			check(view._smith.mood == &"hammer_final", "cheer does not replace final contact")
			check(await wait_until(func() -> bool: return view._smith.mood == &"cheer"), "cheer starts after final recovery")
	check(await wait_until(func() -> bool: return view._forging.is_empty()), "item lands in equipment board")
	check(view._landed == "weapon" and view._smith.mood == &"grin", "landing triggers proud grin")
	check(view._glint == 0.0, "drawn tooth glint replaces procedural one")
	check(view._smith.position.distance_to(ForgeView.SMITH_FEET) < 0.01, "smith steps home")
	check(await wait_until(func() -> bool: return view._smith.mood == &"idle"), "grin finishes at idle")
	check(hits == ["hammer", "hammer", "hammer_final"], "exactly three contacts in order")
	view.free()

	# Missing final art still uses a complete ordinary swing, and patience resumes after it.
	view = fixture()
	view._smith._anim["clips"].erase("hammer_final")
	view._forging = "iron_sword"
	view._forge_slot = "weapon"
	view._strikes = 2
	view._waiting_strike = true
	view._strike()
	check(view._smith.mood == &"hammer", "missing final clip falls back to ordinary hammer")
	check(await wait_until(func() -> bool: return view._smith.mood == &"cheer"), "fallback ordinary swing finishes")
	view.free()

	# A still-art fallback must finish too, even though it emits no clip_impact signal.
	view = fixture()
	view._smith._anim["clips"].erase("hammer")
	view._forging = "iron_sword"
	view._forge_slot = "weapon"
	view._waiting_strike = true
	view._strike()
	check(await wait_until(func() -> bool: return view._strike_landed), "still-art fallback lands")
	check(await wait_until(func() -> bool: return view._waiting_strike), "still-art fallback recovers")
	view._strike_timer = 0.01
	check(await wait_until(func() -> bool: return view._strikes == 2), "patience can start the next strike")
	view.free()
	print("Forge animation flow: %s (%d failures)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	quit(0 if failures.is_empty() else 1)
