extends SceneTree
## Run manually: godot --headless --path . -s res://docs/ideas/campaign_g1_resource_smoke.gd
## Asset check only; this does not implement any campaign mechanics.
var failures: Array[String] = []
var clips := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for id in ["orc_rock", "orc_drummer", "orc_boar", "orc_chief", "orc_chief_enraged", "scarecrow_wood", "scarecrow_straw_shield"]:
		var rig := CharacterRig.new()
		root.add_child(rig)
		rig.setup(id, -1)
		var meta: JSON = load("res://assets/characters/%s/anim/anim.json" % id)
		for clip: String in meta.data.clips:
			var info: Dictionary = meta.data.clips[clip]
			for wear in 3:
				rig.wear = wear
				if not rig.has_clip(StringName(clip)):
					failures.append("%s/%s wear %d missing" % [id,clip,wear])
			if absf(rig.clip_seconds(StringName(clip)) - float(info.frames)/float(info.fps)) > 0.001:
				failures.append(id+" timing "+clip)
			rig._start_clip(StringName(clip))
			if rig._clip_sheet == null:
				failures.append(id+" texture "+clip)
			clips += 1
		rig.free()
	for ch in [1,2]:
		var meta: JSON = load("res://assets/story/chapter_%02d/chapter.json" % ch)
		for panel: String in meta.data.panels:
			if load("res://assets/story/chapter_%02d/%s" % [ch,panel]) == null:
				failures.append(panel)
	for segment in [1,2]:
		if load("res://assets/bg/campaign/segment_%02d.png" % segment) == null:
			failures.append("map %d" % segment)
	for icon in ["node_hard","node_boss","node_bonus","node_petal","golden_petal","orc_flag","rescue_cage","brass_key"]:
		if load("res://assets/ui/campaign/%s.png" % icon) == null:
			failures.append(icon)
	print("G1 resource smoke: %d clips, 3 wear fallbacks each, 12 panels, 2 maps, 8 icons; %d failures" % [clips,failures.size()])
	for failure in failures:
		printerr(failure)
	quit(0 if failures.is_empty() else 1)
