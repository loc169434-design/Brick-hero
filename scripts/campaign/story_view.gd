class_name StoryView
extends Node2D
## A chapter of the story read like a webtoon: the hand-drawn panels of
## assets/story/chapter_NN/ stacked down the screen, scrolled with a finger. Each panel slides
## and fades in as it comes into view, with a short caption box in its corner
## (data/story/chapter_NN.json). The last panel ends with a button to go on; `finished` says
## the chapter was read (or skipped).

signal finished

const SCREEN := Vector2(1080, 1920)
const STORY_DIR := "res://assets/story/chapter_%02d/"
const CAPTIONS := "res://data/story/chapter_%02d.json"
const MARGIN := 40.0
const GUTTER := 36.0
## A panel slides up this far as it fades in.
const SLIDE := 70.0
const CAPTION_SIZE := 34
const CAPTION_WIDTH := 640.0
const INK := MapView.INK
const PAPER := Color(0.96, 0.93, 0.86)
const CAPTION_PAPER := Color(1.0, 0.96, 0.78)

var chapter := 0

## [{texture, top, height, caption}], top down.
var _panels: Array[Dictionary] = []
var _height := SCREEN.y
var _font: Font
var _camera: Camera2D
var _press_at := Vector2.ZERO
var _press_camera := 0.0
var _pressed := false
var _velocity := 0.0
var _last_drag := 0.0
var _done := false
var _end_button: Button


func _ready() -> void:
	_font = load(MapView.FONT) if ResourceLoader.exists(MapView.FONT) else ThemeDB.fallback_font
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	var skip := _button("BỎ QUA ▶▶", Vector2(SCREEN.x - 300, 36), Vector2(264, 80), 32)
	skip.pressed.connect(_finish)
	layer.add_child(skip)
	_end_button = _button("TIẾP ▶", Vector2((SCREEN.x - 360) / 2, SCREEN.y - 190), Vector2(360, 110), 48)
	_end_button.pressed.connect(_finish)
	_end_button.hide()
	layer.add_child(_end_button)


## Whether chapter `number` has panels to show.
static func has_chapter(number: int) -> bool:
	return number > 0 and FileAccess.file_exists(STORY_DIR % number + "chapter.json")


func show_chapter(number: int) -> void:
	chapter = number
	_panels.clear()
	var dir := STORY_DIR % number
	var info := _json(dir + "chapter.json")
	var captions: Array = _json(CAPTIONS % number).get("captions", [])
	var top := MARGIN + 60.0
	var panels: Array = info.get("panels", [])
	for i in panels.size():
		var path: String = dir + String(panels[i])
		var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
		if texture == null:
			continue
		var height := texture.get_height() * (SCREEN.x - MARGIN * 2) / texture.get_width()
		_panels.append({"texture": texture, "top": top, "height": height, "caption": String(captions[i]) if i < captions.size() else ""})
		top += height + GUTTER
	_height = maxf(top + 220.0, SCREEN.y)
	_camera.position = Vector2.ZERO
	_camera.make_current()
	Sfx.play(&"shuffle")
	queue_redraw()


func _finish() -> void:
	if _done:
		return
	_done = true
	Sfx.play(&"tick")
	finished.emit()


func _bottom() -> float:
	return maxf(_height - SCREEN.y, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_pressed = event.pressed
		if event.pressed:
			_press_at = event.position
			_press_camera = _camera.position.y
			_velocity = 0.0
	elif event is InputEventScreenDrag and _pressed:
		var y := clampf(_press_camera - (event.position.y - _press_at.y), 0.0, _bottom())
		_velocity = (y - _camera.position.y) / maxf(get_process_delta_time(), 0.001)
		_camera.position.y = y


func _process(delta: float) -> void:
	if not _pressed and absf(_velocity) > 1.0:
		# A flick keeps the page gliding, slowing down.
		_camera.position.y = clampf(_camera.position.y + _velocity * delta, 0.0, _bottom())
		_velocity = move_toward(_velocity, 0.0, 3200.0 * delta)
	_end_button.visible = _camera.position.y >= _bottom() - 40.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(0, _camera.position.y - 10), SCREEN + Vector2(0, 20)), PAPER)
	var view_bottom := _camera.position.y + SCREEN.y
	for panel in _panels:
		var top: float = panel["top"]
		var height: float = panel["height"]
		# 0 while the panel is below the screen, 1 once a third of the screen has room for it.
		var seen := clampf((view_bottom - top) / (SCREEN.y * 0.33), 0.0, 1.0)
		if seen <= 0.0:
			continue
		var t := ease(seen, 0.4)
		var rect := Rect2(Vector2(MARGIN, top + SLIDE * (1.0 - t)), Vector2(SCREEN.x - MARGIN * 2, height))
		draw_texture_rect(panel["texture"], rect, false, Color(1, 1, 1, t))
		if panel["caption"] and t > 0.5:
			_draw_caption(panel["caption"], rect.position + Vector2(-8, -14), (t - 0.5) * 2.0)


## A yellowed narration box, tilted a hair, in the panel's top-left corner.
func _draw_caption(text: String, at: Vector2, alpha: float) -> void:
	var lines := _font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, CAPTION_WIDTH, CAPTION_SIZE)
	var size := Vector2(minf(lines.x, CAPTION_WIDTH) + 40, lines.y + 26)
	draw_set_transform(at, -0.02, Vector2.ONE)
	draw_rect(Rect2(Vector2(6, 8), size), Color(0, 0, 0, 0.18 * alpha))
	draw_rect(Rect2(Vector2.ZERO, size), Color(CAPTION_PAPER, alpha))
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, alpha), false, 4.0)
	draw_multiline_string(_font, Vector2(20, 13 + CAPTION_SIZE * 0.9), text, HORIZONTAL_ALIGNMENT_LEFT, CAPTION_WIDTH, CAPTION_SIZE, -1, Color(INK, alpha))
	draw_set_transform(Vector2.ZERO)


func _button(text: String, at: Vector2, size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", PAPER)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(INK, 1.0 if state == "pressed" else 0.88)
		style.border_color = MapView.GOLD
		style.set_border_width_all(4)
		style.set_corner_radius_all(int(size.y / 2))
		button.add_theme_stylebox_override(state, style)
	return button


static func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
		return json.data
	return {}
