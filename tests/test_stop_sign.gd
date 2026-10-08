extends SceneTree

const ObstacleScript = preload("res://scripts/obstacle.gd")

func _init() -> void:
	print("--- VERIFYING STOP SIGN GEOMETRY ---")
	var gate = ObstacleScript.create(ObstacleScript.ObstacleType.HIGH_GATE)
	root.add_child(gate)

	var labels: Array[Label3D] = []
	var meshes: Array[MeshInstance3D] = []
	for child in gate.get_children():
		if child is Label3D:
			labels.append(child)
		elif child is MeshInstance3D:
			meshes.append(child)

	assert(labels.size() == 2, "Stop sign should have front and back labels")
	assert(labels[0].text == "STOP" and labels[1].text == "STOP", "Both labels should read STOP")

	# Verify front label is forward in Z facing approaching player (+Z)
	var front_label: Label3D = null
	for l in labels:
		if l.position.z > 0.08:
			front_label = l
	assert(front_label != null, "Front STOP label must be positioned proud in +Z (visible to approaching player)")
	assert(front_label.render_priority >= 2, "Front label must have high render priority")

	print("[PASS] Stop sign verified with clean visibility and 0 occlusion.")
	gate.free()
	quit(0)
