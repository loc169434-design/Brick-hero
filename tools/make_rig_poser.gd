extends SceneTree
## Makes scenes/hero_rig_poser.tscn, a scene for posing the hero rig by hand in Godot's
## animation editor, and data/hero_rig/clips.tres, the clips HeroRig plays (the scene edits
## that file). Every bone is a Sprite2D named after its part and turning on its joint, its
## picture the part with its gear (and the head with its face) flattened into one image in
## data/hero_rig/poser/, so a click on a piece selects its bone and the rotate tool turns it
## where it hinges. New pictures need an import before they load: the first run on a fresh
## checkout asks for one (godot --headless --path . --editor --import) and a second run.
##
##   godot --headless --path . -s tools/make_rig_poser.gd                   # bare, wood sword
##   godot --headless --path . -s tools/make_rig_poser.gd -- iron_sword leather_armor leather_helmet
##   godot --headless --path . -s tools/make_rig_poser.gd -- --reset        # clips from HeroRig.CLIPS
##
## The scene is remade every run (edits to it are lost); the clips file is kept unless --reset.

const SCENE := "res://scenes/hero_rig_poser.tscn"
const PICTURES := "res://data/hero_rig/poser/"

var rig: HeroRig
var owner_node: Node
var missing := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var reset := args.has("--reset")
	var gear: Array = []
	for arg: String in args:
		if not arg.begins_with("--"):
			gear.append(arg)
	if gear.is_empty():
		gear = ["wood_sword"]
	rig = HeroRig.new()
	var outfit := Gear.outfit(gear)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PICTURES))
	if reset or not ResourceLoader.exists(HeroRig.CLIPS_FILE):
		var err := ResourceSaver.save(rig.build_code_clips(), HeroRig.CLIPS_FILE)
		print("clips written from code: ", error_string(err))

	var root := Node2D.new()
	root.name = "HeroRigPoser"
	root.set_script(load("res://scripts/battle/hero_rig_poser.gd"))
	owner_node = root
	var bones := Node2D.new()
	bones.name = "Rig"
	_add(root, bones)
	var made := {}
	for part: String in HeroRig.PARTS:
		_bone(part, bones, made, outfit)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	_add(bones, player)
	player.add_animation_library(&"", load(HeroRig.CLIPS_FILE))

	if missing:
		print("%d new pictures in %s: import them (godot --headless --path . --editor --import), then run this again" % [missing, PICTURES])
	else:
		var scene := PackedScene.new()
		scene.pack(root)
		print("poser scene: ", error_string(ResourceSaver.save(scene, SCENE)))
	root.free()
	rig.free()
	quit()


func _add(parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = owner_node


func _joint(part: String) -> Vector2:
	return rig._joints[HeroRig.PARTS[part]["joint"]]


## The part's bone as a Sprite2D at its joint's offset from its parent's, drawn where the
## layer was painted, at its place in the drawing order; its gear rides on it.
func _bone(part: String, rig_node: Node2D, made: Dictionary, outfit: Dictionary) -> Sprite2D:
	if made.has(part):
		return made[part]
	var parent_part: String = HeroRig.PARTS[part]["parent"]
	var parent: Node2D = rig_node if parent_part == "" else _bone(parent_part, rig_node, made, outfit)
	var here := _joint(part)
	var bone := Sprite2D.new()
	bone.name = part
	bone.centered = false
	bone.position = here - (HeroRig.FEET if parent_part == "" else _joint(parent_part))
	bone.offset = -here
	bone.z_as_relative = false
	bone.z_index = rig._order.find(part)
	_add(parent, bone)
	made[part] = bone
	if part == "sword":
		var sword: String = outfit.get("weapon", "")
		if sword:
			# Held as HeroRig holds it: the icon turned upright inside the bone, so the bone
			# itself rests at 0 like every other; a click on the icon picks the bone.
			var hold: Dictionary = HeroRig.SWORDS.get(sword, HeroRig.SWORD_HOLD)
			var icon := Sprite2D.new()
			icon.name = "icon"
			icon.texture = load("res://assets/ui/items/%s.png" % sword)
			icon.centered = false
			icon.offset = -hold["grip"]
			icon.rotation_degrees = hold["turn"]
			icon.scale = Vector2.ONE * HeroRig.SWORD_SIZE / 256.0 * hold["size"]
			_add(bone, icon)
			bone.set_meta("_edit_group_", true)
		return bone
	var layers: Array[String] = []
	if part == "head":
		rig.outfit = outfit
		layers.append(rig.head_texture().resource_path)
		layers.append(rig.face_texture().resource_path)
	else:
		layers.append(HeroRig.DIR + "parts/%s.png" % part)
	for slot: String in ["armor", "boots"]:
		var item: String = outfit.get(slot, "")
		var path := HeroRig.DIR + "gear/%s/%s.png" % [item, part]
		if item and part in HeroRig.GEAR_PARTS[slot] and ResourceLoader.exists(path):
			layers.append(path)
	bone.texture = _picture(part, layers)
	return bone


## The layers stacked into data/hero_rig/poser/<part>.png; null until that file is imported.
func _picture(part: String, layers: Array[String]) -> Texture2D:
	var image: Image
	for path: String in layers:
		var layer := Image.load_from_file(ProjectSettings.globalize_path(path))
		layer.convert(Image.FORMAT_RGBA8)
		if image == null:
			image = layer
		else:
			image.blend_rect(layer, Rect2i(Vector2i.ZERO, layer.get_size()), Vector2i.ZERO)
	var path := PICTURES + part + ".png"
	var file := ProjectSettings.globalize_path(path)
	var old := Image.load_from_file(file) if FileAccess.file_exists(file) else null
	if old == null or old.get_data() != image.get_data():
		image.save_png(file)
		missing += 1
		return null
	if not ResourceLoader.exists(path):
		missing += 1
		return null
	return load(path)
