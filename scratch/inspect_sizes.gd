extends SceneTree

const AssetLoader = preload("res://scripts/asset_loader.gd")

func get_aabb(node: Node) -> AABB:
	var aabb := AABB()
	var first := true
	if node is VisualInstance3D:
		aabb = (node as VisualInstance3D).get_aabb()
		first = false
	for child in node.get_children():
		var child_aabb := get_aabb(child)
		if child_aabb.size != Vector3.ZERO:
			if first:
				aabb = child_aabb
				first = false
			else:
				aabb = aabb.merge(child_aabb)
	return aabb

func _init() -> void:
	for m in ["corridor_wall", "gate", "building_round", "building_tall", "pillar", "speeder"]:
		var node: Node3D = AssetLoader.get_model(m)
		if node:
			var b := get_aabb(node)
			print("Model '", m, "': AABB pos=", b.position, " size=", b.size)
			# print child names
			for c in node.get_children():
				print("   child: ", c.name, " (", c.get_class(), ") pos=", c.position if c is Node3D else "")
	quit()
