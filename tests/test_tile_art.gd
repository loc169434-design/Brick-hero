extends "res://tests/test_case.gd"

const R := Cell.BlockColor.RED
const P := Cell.BlockColor.PURPLE


func test_each_theme_has_a_tile_per_color() -> void:
	for theme in TileArt.THEMES:
		var art := TileArt.new(theme)
		for color in Cell.COLOR_COUNT:
			assert_true(art.tile(color) != null, "%s color %d" % [theme, color])


func test_rainbow_has_no_tile_or_clip() -> void:
	var art := TileArt.new("orc_shield")
	assert_eq(art.tile(Cell.NO_COLOR), null)
	assert_true(not art.ensure_clip(Cell.NO_COLOR, &"combo"))


func test_clips_load_on_demand_with_all_frames() -> void:
	var art := TileArt.new("training")
	assert_true(not art.frames(R).has_animation(&"combo"), "nothing loaded up front")
	assert_true(art.ensure_clip(R, &"combo"))
	assert_eq(art.frames(R).get_frame_count(&"combo"), 24)
	assert_true(absf(art.clip_seconds(R, &"combo") - 1.2) < 0.01)
	assert_true(not art.frames(P).has_animation(&"combo"), "other colors stay unloaded")


func test_only_orc_tiles_taunt() -> void:
	assert_true(TileArt.new("orc_shield").has_clip(&"taunt"))
	assert_true(not TileArt.new("training").has_clip(&"taunt"))
	assert_true(not TileArt.new("training").ensure_clip(R, &"taunt"))


func test_each_special_has_art_and_a_looping_sheet() -> void:
	var art := SpecialArt.new()
	for kind in [Cell.Special.BOMB, Cell.Special.LIGHTNING, Cell.Special.RAINBOW]:
		assert_true(art.still(kind) != null, "still %d" % kind)
		assert_true(art.sheet(kind) != null, "sheet %d" % kind)
	assert_true(art.sheet_overlays_still(Cell.Special.BOMB), "the fuse goes over the bomb")
	assert_true(not art.sheet_overlays_still(Cell.Special.LIGHTNING), "lightning's sheet replaces its still")


func test_special_sheet_frames_walk_the_atlas_and_loop() -> void:
	var art := SpecialArt.new()
	var kind := Cell.Special.RAINBOW
	assert_eq(art.frame_region(kind, 0.0), Rect2(0, 0, 128, 128))
	# 12 frames at 12 fps, 8 to a row: frame 9 is the second on the second row.
	assert_eq(art.frame_region(kind, 9.5 / 12.0), Rect2(128, 128, 128, 128))
	assert_eq(art.frame_region(kind, 1.0), art.frame_region(kind, 0.0), "loops after a second")
	assert_eq(art.frame_region(kind, -0.5 / 12.0), Rect2(384, 128, 128, 128), "an early phase wraps to frame 11")
