extends "res://tests/test_case.gd"

const SAVE_TEST := "user://test_campaign.json"


func test_the_map_lists_the_levels_in_order() -> void:
	var campaign := Campaign.from_map()
	assert_true(campaign.stops.size() >= 2)
	assert_eq(campaign.stops[0]["id"], "1")
	assert_eq(campaign.stops[1]["id"], "2")


func test_stops_open_one_at_a_time() -> void:
	var campaign := Campaign.from_map()
	assert_eq(campaign.state_of("1"), Campaign.Stop.OPEN)
	assert_eq(campaign.state_of("2"), Campaign.Stop.LOCKED)
	assert_eq(campaign.hero_index(), 0)
	assert_true(campaign.finish_fight("1", true, 12), "first clear")
	assert_eq(campaign.state_of("1"), Campaign.Stop.DONE)
	assert_eq(campaign.state_of("2"), Campaign.Stop.OPEN)
	assert_eq(campaign.hero_index(), 1)


func test_a_stop_without_a_level_yet_is_coming_soon() -> void:
	assert_true(Campaign.has_level("1"))
	assert_true(not Campaign.has_level("99"), "level 99 isn't made yet")
	assert_true(not Campaign.has_level("orc_shield"), "stops are numbered")
	var campaign := Campaign.from_map()
	assert_eq(campaign.stops[0]["level"], 1)
	assert_true(campaign.stops[5]["position"].y > campaign.stops[6]["position"].y or campaign.stops[5]["position"].y > 0, "laid out up the map")


func test_winning_keeps_the_purse_and_losing_keeps_the_old_one() -> void:
	var campaign := Campaign.from_map()
	campaign.finish_fight("1", true, 9)
	assert_eq(campaign.gold, 9)
	assert_true(not campaign.finish_fight("2", false, 30), "a loss clears nothing")
	assert_eq(campaign.gold, 9, "gold picked up in a lost fight is dropped")
	assert_true(not campaign.finish_fight("1", true, 15), "a replay is not a new clear")
	assert_eq(campaign.gold, 15, "but its gold counts")
	assert_eq(campaign.cleared, ["1"])


func test_stars_follow_the_health_left_and_keep_the_best() -> void:
	assert_eq(Campaign.stars_for(0.1), 1)
	assert_eq(Campaign.stars_for(0.4), 2)
	assert_eq(Campaign.stars_for(0.95), 3)
	var campaign := Campaign.from_map()
	assert_eq(campaign.stars_at("1"), 0)
	campaign.finish_fight("1", true, 0, 2)
	campaign.finish_fight("1", true, 0, 1)
	assert_eq(campaign.stars_at("1"), 2, "a worse replay keeps the best")
	campaign.finish_fight("1", true, 0, 3)
	assert_eq(campaign.stars_at("1"), 3)
	campaign.finish_fight("2", false, 0, 3)
	assert_eq(campaign.stars_at("2"), 0, "no stars for a loss")


func test_progress_survives_a_save_and_load() -> void:
	var campaign := Campaign.from_map()
	campaign.finish_fight("1", true, 21, 2)
	campaign.save(SAVE_TEST)
	var again := Campaign.from_map()
	again.load_progress(SAVE_TEST)
	assert_eq(again.cleared, ["1"])
	assert_eq(again.gold, 21)
	assert_eq(again.stars_at("1"), 2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_TEST))


func test_a_broken_save_starts_a_new_journey() -> void:
	var file := FileAccess.open(SAVE_TEST, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	var campaign := Campaign.from_map()
	campaign.load_progress(SAVE_TEST)
	assert_eq(campaign.cleared.size(), 0)
	assert_eq(campaign.gold, 0)
	campaign.apply_dict({"cleared": ["nowhere", "1", "1"], "gold": -5})
	assert_eq(campaign.cleared, ["1"], "unknown and repeated stops are dropped")
	assert_eq(campaign.gold, 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_TEST))
