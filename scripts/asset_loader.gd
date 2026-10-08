extends RefCounted
class_name AssetLoader

static var _cached_scenes: Dictionary = {}
static var _skybox_texture: Texture2D = null

static func get_model(model_name: String) -> Node3D:
	if not _cached_scenes.has(model_name):
		var path: String = "res://assets/models/%s.glb" % model_name
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(path, state)
		if err == OK:
			var scene: Node3D = doc.generate_scene(state) as Node3D
			# Normalize Kenney grid cell offset (2.0, 0.0, 1.5) for static models
			if model_name != "character":
				for c in scene.get_children():
					if c is Node3D and not (c is AnimationPlayer):
						(c as Node3D).position = Vector3.ZERO
			_cached_scenes[model_name] = scene
		else:
			push_warning("Failed to load model: " + path)
			return null

	var template: Node3D = _cached_scenes.get(model_name)
	if template != null:
		return template.duplicate() as Node3D
	return null

static func get_skybox_texture() -> Texture2D:
	if _skybox_texture != null:
		return _skybox_texture

	var path := "res://assets/skyboxes/Skyboxes/skybox-space-nebula.png"
	var img := Image.new()
	var abs_path: String = ProjectSettings.globalize_path(path)
	var err: Error = img.load(abs_path)
	if err == OK:
		_skybox_texture = ImageTexture.create_from_image(img)
	else:
		push_warning("Failed to load skybox image: " + path)
	return _skybox_texture
