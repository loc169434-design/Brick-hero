extends SceneTree

func _initialize() -> void:
	var specification: JSON = load("res://docs/ideas/world_life_resources.json")
	var count := 0
	for entry: Dictionary in specification.data["textures"]:
		var texture: Texture2D = load("res://" + str(entry["file"]))
		assert(texture != null, str(entry["file"]))
		assert(texture.get_size() == Vector2(entry["size"][0], entry["size"][1]), str(entry["file"]))
		count += 1
	for path: String in specification.data.get("metadata", []):
		var metadata: JSON = load("res://" + path)
		assert(metadata != null and metadata.data is Dictionary, path)
	print("Issue49 resource smoke: %d textures, correct dimensions, metadata loaded; 0 failures" % count)
	quit()
