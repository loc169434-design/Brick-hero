extends "res://tests/test_case.gd"
## The hour and sky of a fight (docs/weather_plan.md) and the art laid out for them (#49).

const ARENAS := ["training_field", "orc_camp", "swamp", "goblin_camp"]


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_the_training_field_is_always_clear_by_day() -> void:
	for i in 50:
		var sky := Weather.pick("training_field", _rng(i))
		assert_true(sky[0] in [&"morning", &"noon"], "hour %s" % sky[0])
		assert_eq(sky[1], &"clear")


func test_the_swamp_is_fought_late_and_often_wet() -> void:
	var wet := 0
	for i in 200:
		var sky := Weather.pick("swamp", _rng(i))
		assert_true(sky[0] in [&"dusk", &"night"], "hour %s" % sky[0])
		if Weather.is_wet(sky[1]):
			wet += 1
	assert_true(wet > 100, "rain or storm most of the time, got %d of 200" % wet)


func test_a_level_can_lock_its_sky() -> void:
	for i in 20:
		var sky := Weather.pick("orc_camp", _rng(i), PackedStringArray(["night"]), PackedStringArray(["storm"]))
		assert_eq(sky, [&"night", &"storm"] as Array[StringName])
	var witch: LevelData = load("res://data/levels/level_036.tres")
	assert_eq(witch.times, PackedStringArray(["dusk"]), "the Toad Witch fights at dusk")
	assert_eq(witch.weathers, PackedStringArray(["rain"]), "in the rain")


func test_unknown_names_and_regions_fall_back() -> void:
	var sky := Weather.pick("somewhere_new", _rng(1), PackedStringArray(["teatime"]), PackedStringArray(["snow"]))
	assert_eq(sky, [Weather.DEFAULT_HOUR, Weather.DEFAULT_SKY] as Array[StringName])


func test_every_arena_has_all_four_skies_and_eye_spots() -> void:
	for id: String in ARENAS:
		var json: JSON = load("res://assets/bg/%s/layers.json" % id)
		var info: Dictionary = json.data
		for hour in Weather.HOURS:
			var file: String = info["sky_times"][String(hour)]
			assert_true(ResourceLoader.exists("res://assets/bg/%s/%s" % [id, file]), "%s %s" % [id, hour])
			assert_eq(info["time_lighting"][String(hour)].size(), 4, "%s lighting %s" % [id, hour])
		assert_true(info["eyes"].size() > 0, id + " eyes")
	for name in ["rain", "rain_splash", "lightning_bolt", "fog", "red_eyes"]:
		assert_true(ResourceLoader.exists("res://assets/fx/weather/%s.png" % name), name)
	for name in Weather.HOURS + Weather.SKIES:
		if name != Weather.DEFAULT_SKY:
			assert_true(ResourceLoader.exists("res://assets/fx/weather/icon_%s.png" % name), "icon " + name)


func test_the_backdrop_paints_the_hour() -> void:
	var backdrop := ArenaBackdrop.new()
	backdrop.load_background("swamp")
	backdrop.set_sky(&"noon", &"clear")
	assert_eq(backdrop.fighter_light(), Color.WHITE, "noon leaves the fighters be")
	backdrop.set_sky(&"night", &"clear")
	var night := backdrop.fighter_light()
	assert_true(night.b > night.r and night.r < 1.0, "night is blue and darker: %s" % night)
	assert_true(night.r > 0.5, "but the fighters stay readable: %s" % night)
	backdrop.set_sky(&"dusk", &"rain")
	assert_true(backdrop.fighter_light().v < Color(1.0, 0.74, 0.58).v, "rain darkens dusk")
	backdrop.free()


func test_the_map_has_an_ambience_for_its_segments() -> void:
	var campaign := Campaign.from_map()
	var base: Dictionary = load("res://assets/bg/campaign/ambience.json").data
	var file: String = base["profiles"][str(campaign.segments)]
	var ambience: Dictionary = load("res://assets/bg/campaign/" + file).data
	assert_eq(int(ambience["segment_count"]), campaign.segments)
	var height := campaign.segments * 1920
	for kind in ["smoke", "flags", "waterfalls", "clouds"]:
		for piece: Dictionary in ambience[kind]:
			var y := float(piece["position"][1])
			assert_true(y >= 0 and y <= height, "%s inside the map at %s" % [kind, y])
	for name: String in ambience["textures"]:
		assert_true(ResourceLoader.exists("res://assets/bg/campaign/" + String(ambience["textures"][name]["file"])), name)
