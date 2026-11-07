extends SceneTree
## Makes scenes/hero_skeleton_sandbox.tscn: the hero's pieces laid out assembled, for rigging
## him by hand with Skeleton2D, Bone2D and an AnimationPlayer in the Godot editor.
##
##   godot --headless --path . -s tools/make_skeleton_sandbox.gd            # won't overwrite
##   godot --headless --path . -s tools/make_skeleton_sandbox.gd -- --force
##
## In the scene:
## - Skeleton2D: empty, for the bones.
## - Parts: one Sprite2D per piece (assets/characters/hero_rig/parts/, the bare head with its
##   face, the wooden sword), each sitting on its joint (position = joint, offset = -joint), so
##   it turns where it hinges and keeps its place when dragged onto a bone. z_index is absolute,
##   in the drawing order of joints.json, so reparenting under bones keeps the layering.
## - Joints: a Marker2D at every joint of joints.json, to place the bones on.
## - AnimationPlayer: empty, for the clips.
## The hero's feet are at the origin; canvas pixels are scene pixels (512 canvas).

const SCENE := "res://scenes/hero_skeleton_sandbox.tscn"

var owner_node: Node


func _initialize() -> void:
	if FileAccess.file_exists(SCENE) and not OS.get_cmdline_user_args().has("--force"):
		print("%s exists (your work?): pass --force to remake it" % SCENE)
		quit()
		return
	var rig := HeroRig.new()
	var joints: Dictionary = rig._joints
	var order: Array = rig._order

	var root := Node2D.new()
	root.name = "HeroSkeletonSandbox"
	owner_node = root
	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	_add(root, skeleton)
	var parts := Node2D.new()
	parts.name = "Parts"
	_add(root, parts)
	var markers := Node2D.new()
	markers.name = "Joints"
	markers.z_index = 100
	_add(root, markers)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	_add(root, player)

	for part: String in order:
		var joint: Vector2 = joints[HeroRig.PARTS[part]["joint"]] - HeroRig.FEET
		var canvas_joint: Vector2 = joints[HeroRig.PARTS[part]["joint"]]
		var sprite := Sprite2D.new()
		sprite.name = part
		sprite.centered = false
		sprite.position = joint
		sprite.z_as_relative = false
		sprite.z_index = order.find(part)
		_add(parts, sprite)
		if part == "sword":
			var hold: Dictionary = SwordArt.hold("wood_sword")
			sprite.texture = load("res://assets/ui/items/wood_sword.png")
			sprite.offset = -hold["grip"]
			sprite.rotation_degrees = hold["turn"]
			sprite.scale = Vector2.ONE * SwordArt.SIZE / 256.0 * hold["size"]
			continue
		if part == "head":
			sprite.texture = load(HeroRig.DIR + "head/bare.png")
			sprite.offset = -canvas_joint
			var face := Sprite2D.new()
			face.name = "face"
			face.texture = load(HeroRig.DIR + "faces/normal.png")
			face.centered = false
			face.offset = -canvas_joint
			_add(sprite, face)
			# a click on the face picks the head
			sprite.set_meta("_edit_group_", true)
			continue
		sprite.texture = load(HeroRig.DIR + "parts/%s.png" % part)
		sprite.offset = -canvas_joint

	for name: String in joints:
		var marker := Marker2D.new()
		marker.name = name
		marker.position = joints[name] - HeroRig.FEET
		marker.gizmo_extents = 6.0
		_add(markers, marker)

	var scene := PackedScene.new()
	scene.pack(root)
	print("skeleton sandbox: ", error_string(ResourceSaver.save(scene, SCENE)))
	root.free()
	rig.free()
	quit()


func _add(parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = owner_node
