extends SceneTree

const ObstacleScript = preload("res://scripts/obstacle.gd")

func _init() -> void:
	print("--- VERIFYING STOP SIGN GEOMETRY AND LAYER PRIORITIES ---")
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

	# Find front and back labels
	var front_label: Label3D = null
	var back_label: Label3D = null
	for l in labels:
		if l.position.z > 0.08:
			front_label = l
		else:
			back_label = l

	assert(front_label != null, "Front STOP label must be positioned proud in +Z (visible to approaching player)")
	assert(front_label.render_priority >= 10, "Front label must have high render priority (10+)")
	assert(front_label.sorting_offset >= 2.0, "Front label must have positive sorting offset")

	# Verify cylinder meshes have zero yaw tilt (all vertices in X-Y plane with constant Z)
	var octagons_found := 0
	for m in meshes:
		if m.mesh is CylinderMesh and m.mesh.radial_segments == 8:
			octagons_found += 1
			var cyl: CylinderMesh = m.mesh
			var h_half = cyl.height * 0.5
			var r = cyl.top_radius
			var z_ref: float = -999.0
			for i in range(8):
				var a = deg_to_rad(float(i) * 45.0)
				var local_pt = Vector3(cos(a) * r, h_half, sin(a) * r)
				var world_pt = m.transform * local_pt
				if z_ref < -900.0:
					z_ref = world_pt.z
				else:
					assert(abs(world_pt.z - z_ref) < 0.001, "All octagon vertices must have identical Z (zero yaw tilt)!")
			assert(front_label.position.z > z_ref, "Front label must be strictly in front of the octagon surface")

	assert(octagons_found == 3, "Must have 3 octagonal layers (base, border, core)")
	print("[PASS] STOP sign verified: perfectly planar octagon, high render priority (10), zero clipping!")
	gate.free()
	quit(0)
