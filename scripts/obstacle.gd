extends Area3D

const AssetLoader = preload("res://scripts/asset_loader.gd")

enum ObstacleType {
	LOW_HURDLE,   # Jump over (clearance: jump required) - RED with BRICK WALL inside
	HIGH_GATE,    # Slide under (clearance: slide required) - PURPLE with STOP SIGN
	SOLID_BARRIER # Dodged by lane shift (full height)
}

@export var obstacle_type: ObstacleType = ObstacleType.LOW_HURDLE
var is_active: bool = true

# Shared Materials for Obstacles
static var hazard_metal_mat: StandardMaterial3D = null
static var laser_red_mat: StandardMaterial3D = null
static var laser_purple_mat: StandardMaterial3D = null
static var brick_red_mat: StandardMaterial3D = null
static var brick_dark_mat: StandardMaterial3D = null
static var brick_mortar_mat: StandardMaterial3D = null
static var stop_sign_red_mat: StandardMaterial3D = null
static var stop_sign_white_mat: StandardMaterial3D = null
static var solid_barrier_mat: StandardMaterial3D = null

func _init() -> void:
	_init_shared_materials()

static func _init_shared_materials() -> void:
	if hazard_metal_mat != null:
		return

	hazard_metal_mat = StandardMaterial3D.new()
	hazard_metal_mat.albedo_color = Color(0.12, 0.14, 0.18)
	hazard_metal_mat.metallic = 0.85
	hazard_metal_mat.roughness = 0.35

	# Vivid Cyber Laser Red (for Jump obstacle top rail and accents)
	laser_red_mat = StandardMaterial3D.new()
	laser_red_mat.albedo_color = Color(1.0, 0.12, 0.18)
	laser_red_mat.emission_enabled = true
	laser_red_mat.emission = Color(1.0, 0.12, 0.18)
	laser_red_mat.emission_energy_multiplier = 4.5
	laser_red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Vibrant Neon Cyber Purple (for Slide obstacle gate and tripwire)
	laser_purple_mat = StandardMaterial3D.new()
	laser_purple_mat.albedo_color = Color(0.85, 0.15, 1.0)
	laser_purple_mat.emission_enabled = true
	laser_purple_mat.emission = Color(0.85, 0.15, 1.0)
	laser_purple_mat.emission_energy_multiplier = 4.5
	laser_purple_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Brick Wall Materials (Terracotta Red, Dark Burnt Red, and Mortar Grey)
	brick_red_mat = StandardMaterial3D.new()
	brick_red_mat.albedo_color = Color(0.72, 0.24, 0.16)
	brick_red_mat.roughness = 0.85

	brick_dark_mat = StandardMaterial3D.new()
	brick_dark_mat.albedo_color = Color(0.58, 0.19, 0.13)
	brick_dark_mat.roughness = 0.88

	brick_mortar_mat = StandardMaterial3D.new()
	brick_mortar_mat.albedo_color = Color(0.25, 0.23, 0.22)
	brick_mortar_mat.roughness = 0.95

	# Stop Sign Materials
	stop_sign_red_mat = StandardMaterial3D.new()
	stop_sign_red_mat.albedo_color = Color(0.86, 0.08, 0.12)
	stop_sign_red_mat.roughness = 0.4
	stop_sign_red_mat.emission_enabled = true
	stop_sign_red_mat.emission = Color(0.86, 0.08, 0.12)
	stop_sign_red_mat.emission_energy_multiplier = 0.6

	stop_sign_white_mat = StandardMaterial3D.new()
	stop_sign_white_mat.albedo_color = Color(0.96, 0.96, 0.98)
	stop_sign_white_mat.emission_enabled = true
	stop_sign_white_mat.emission = Color(0.96, 0.96, 0.98)
	stop_sign_white_mat.emission_energy_multiplier = 0.4

	# Reinforced Dark Barrier Metal with Red Trim
	solid_barrier_mat = StandardMaterial3D.new()
	solid_barrier_mat.albedo_color = Color(0.08, 0.1, 0.14)
	solid_barrier_mat.metallic = 0.9
	solid_barrier_mat.roughness = 0.3
	solid_barrier_mat.emission_enabled = true
	solid_barrier_mat.emission = Color(0.9, 0.1, 0.2)
	solid_barrier_mat.emission_energy_multiplier = 0.8

static func create(type: ObstacleType) -> Area3D:
	var script: GDScript = load("res://scripts/obstacle.gd")
	var obs: Area3D = script.new()
	obs.set("obstacle_type", type)
	obs.call("_build_obstacle")
	return obs

func _build_obstacle() -> void:
	# Configure collision layer: 4 = Obstacles, mask = 2 (Player)
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = true

	match obstacle_type:
		ObstacleType.LOW_HURDLE:
			_build_low_hurdle()
		ObstacleType.HIGH_GATE:
			_build_high_gate()
		ObstacleType.SOLID_BARRIER:
			_build_solid_barrier()

func _build_low_hurdle() -> void:
	name = "LowHurdle"
	# Collision Shape: Height 0.72m, Center Y = 0.36m
	# When runner jumps, runner feet reach Y >= 0.8m -> cleanly sails over!
	# When runner is standing (Y: 0-1.8) or sliding (Y: 0-0.75) -> collides!
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 0.72, 0.6)
	col.shape = box
	col.position = Vector3(0, 0.36, 0)
	add_child(col)

	# Left & Right Footing Pylons
	var post_w: float = 0.22
	var post_h: float = 0.75
	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var p_mesh := BoxMesh.new()
		p_mesh.size = Vector3(post_w, post_h, 0.45)
		post.mesh = p_mesh
		post.material_override = hazard_metal_mat
		post.position = Vector3(side * 1.15, post_h * 0.5, 0)
		add_child(post)

		# Red indicator caps on pylons
		var p_cap := MeshInstance3D.new()
		var pc_mesh := BoxMesh.new()
		pc_mesh.size = Vector3(post_w * 1.08, 0.08, 0.48)
		p_cap.mesh = pc_mesh
		p_cap.material_override = laser_red_mat
		p_cap.position = Vector3(side * 1.15, post_h + 0.02, 0)
		add_child(p_cap)

	# --- BRICK WALL INSIDE THE JUMP HURDLE ---
	# 1. Dark Masonry Mortar Base (covers X: -1.02 to +1.02, Y: 0.0 to 0.46)
	var mortar_base := MeshInstance3D.new()
	var mb_mesh := BoxMesh.new()
	mb_mesh.size = Vector3(2.06, 0.46, 0.28)
	mortar_base.mesh = mb_mesh
	mortar_base.material_override = brick_mortar_mat
	mortar_base.position = Vector3(0, 0.23, 0)
	add_child(mortar_base)

	# 2. Procedural Staggered Brick Blocks (4 rows of authentic running-bond bricks)
	var rows: int = 4
	var row_h: float = 0.095
	var brick_w: float = 0.34
	for r in range(rows):
		var y_pos: float = 0.06 + float(r) * (row_h + 0.018)
		var is_odd: bool = (r % 2 == 1)
		var start_x: float = -0.85 if is_odd else -1.01
		var end_x: float = 1.01

		var curr_x: float = start_x
		var b_idx: int = 0
		while curr_x < end_x:
			var w: float = brick_w
			if curr_x + w > end_x:
				w = end_x - curr_x
			if curr_x < -1.01:
				w = (curr_x + w) - (-1.01)
				curr_x = -1.01

			if w > 0.07:
				var brick := MeshInstance3D.new()
				var b_box := BoxMesh.new()
				b_box.size = Vector3(w - 0.02, row_h, 0.32)
				brick.mesh = b_box
				brick.material_override = brick_red_mat if ((r + b_idx) % 3 != 0) else brick_dark_mat
				brick.position = Vector3(curr_x + w * 0.5, y_pos, 0)
				add_child(brick)

			curr_x += brick_w + 0.015
			b_idx += 1

	# 3. Glowing Laser Red Cross-Beam on top of the brick wall (Y = 0.54m)
	var beam := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(2.3, 0.16, 0.34)
	beam.mesh = b_mesh
	beam.material_override = laser_red_mat
	beam.position = Vector3(0, 0.54, 0)
	add_child(beam)

	# 4. Red Hazard Caution Trim
	var trim := MeshInstance3D.new()
	var tm_mesh := BoxMesh.new()
	tm_mesh.size = Vector3(1.9, 0.04, 0.38)
	trim.mesh = tm_mesh
	trim.material_override = laser_red_mat
	trim.position = Vector3(0, 0.46, 0)
	add_child(trim)

func _build_high_gate() -> void:
	name = "HighGate"
	# Collision Shape: Clearance underneath is 0.88m!
	# Box from Y = 0.88m to Y = 2.4m (Height 1.52m, Center Y = 1.64m)
	# When runner slides, hitbox height is 0.72m -> slides underneath cleanly!
	# When runner stands or jumps -> collides with upper body!
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 1.52, 0.6)
	col.shape = box
	col.position = Vector3(0, 1.64, 0)
	add_child(col)

	# Left & Right Tall Support Pylons (clearing the roadway)
	var pylon_h: float = 2.5
	for side: float in [-1.0, 1.0]:
		var pylon := MeshInstance3D.new()
		var p_mesh := BoxMesh.new()
		p_mesh.size = Vector3(0.25, pylon_h, 0.4)
		pylon.mesh = p_mesh
		pylon.material_override = hazard_metal_mat
		pylon.position = Vector3(side * 1.15, pylon_h * 0.5, 0)
		add_child(pylon)

		# Purple neon strip along pylons
		var p_strip := MeshInstance3D.new()
		var ps_mesh := BoxMesh.new()
		ps_mesh.size = Vector3(0.08, pylon_h * 0.9, 0.42)
		p_strip.mesh = ps_mesh
		p_strip.material_override = laser_purple_mat
		p_strip.position = Vector3(side * 1.15, pylon_h * 0.5, 0)
		add_child(p_strip)

	# Top Crossbar at Y = 2.4
	var crossbar := MeshInstance3D.new()
	var cb_mesh := BoxMesh.new()
	cb_mesh.size = Vector3(2.4, 0.22, 0.4)
	crossbar.mesh = cb_mesh
	crossbar.material_override = hazard_metal_mat
	crossbar.position = Vector3(0, 2.4, 0)
	add_child(crossbar)

	# Top Crossbar Purple Neon Accent
	var cb_neon := MeshInstance3D.new()
	var cbn_mesh := BoxMesh.new()
	cbn_mesh.size = Vector3(2.3, 0.08, 0.44)
	cb_neon.mesh = cbn_mesh
	cb_neon.material_override = laser_purple_mat
	cb_neon.position = Vector3(0, 2.4, 0)
	add_child(cb_neon)

	# Glowing Cyber PURPLE Laser Barrier Field (Y: 1.0 to 2.3)
	var laser_field := MeshInstance3D.new()
	var lf_mesh := BoxMesh.new()
	lf_mesh.size = Vector3(2.2, 1.25, 0.08)
	laser_field.mesh = lf_mesh
	laser_field.material_override = laser_purple_mat
	laser_field.position = Vector3(0, 1.65, 0)
	add_child(laser_field)

	# Warning caution horizontal purple laser beam at bottom edge (Y = 1.0)
	var tripwire := MeshInstance3D.new()
	var tw_mesh := BoxMesh.new()
	tw_mesh.size = Vector3(2.25, 0.12, 0.2)
	tripwire.mesh = tw_mesh
	tripwire.material_override = laser_purple_mat
	tripwire.position = Vector3(0, 1.02, 0)
	add_child(tripwire)

	# --- 3D OCTAGONAL STOP SIGN IN CENTER OF PURPLE GATE ---
	_build_stop_sign(Vector3(0, 1.65, 0))

func _build_stop_sign(pos: Vector3) -> void:
	# 1. Sign Hanger / Mounting Bracket from Crossbar (Y: 2.4 down to 1.65)
	var bracket := MeshInstance3D.new()
	var bk_mesh := BoxMesh.new()
	bk_mesh.size = Vector3(0.08, 0.72, 0.12)
	bracket.mesh = bk_mesh
	bracket.material_override = hazard_metal_mat
	bracket.position = Vector3(pos.x, pos.y + 0.38, pos.z)
	add_child(bracket)

	# 2. Outer Red Octagon Plate (8-sided regular cylinder rotated forward)
	var sign_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.40
	cyl.bottom_radius = 0.40
	cyl.height = 0.04
	cyl.radial_segments = 8
	cyl.rings = 1
	sign_mesh.mesh = cyl
	sign_mesh.material_override = stop_sign_red_mat
	sign_mesh.rotation_degrees = Vector3(90.0, 22.5, 0.0)
	sign_mesh.position = pos
	add_child(sign_mesh)

	# 3. Inner White Octagon Border
	var border_mesh := MeshInstance3D.new()
	var b_cyl := CylinderMesh.new()
	b_cyl.top_radius = 0.36
	b_cyl.bottom_radius = 0.36
	b_cyl.height = 0.045
	b_cyl.radial_segments = 8
	b_cyl.rings = 1
	border_mesh.mesh = b_cyl
	border_mesh.material_override = stop_sign_white_mat
	border_mesh.rotation_degrees = Vector3(90.0, 22.5, 0.0)
	border_mesh.position = pos
	add_child(border_mesh)

	# 4. Inner Red Octagon Core
	var core_mesh := MeshInstance3D.new()
	var c_cyl := CylinderMesh.new()
	c_cyl.top_radius = 0.33
	c_cyl.bottom_radius = 0.33
	c_cyl.height = 0.05
	c_cyl.radial_segments = 8
	c_cyl.rings = 1
	core_mesh.mesh = c_cyl
	core_mesh.material_override = stop_sign_red_mat
	core_mesh.rotation_degrees = Vector3(90.0, 22.5, 0.0)
	core_mesh.position = pos
	add_child(core_mesh)

	# 5. Bold High-Contrast "STOP" Text Labels (Facing Front and Back)
	for side: float in [1.0, -1.0]:
		var label := Label3D.new()
		label.text = "STOP"
		label.font_size = 54
		label.pixel_size = 0.005
		label.modulate = Color(1.0, 1.0, 1.0)
		label.outline_size = 14
		label.outline_modulate = Color(0.12, 0.12, 0.12)
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.position = pos + Vector3(0, 0, side * 0.03)
		if side < 0:
			label.rotation_degrees = Vector3(0, 180, 0)
		add_child(label)

func _build_solid_barrier() -> void:
	name = "SolidBarrier"
	# Collision Shape: Full Height (0.0 to 2.5m)
	# Cannot be jumped, cannot be slid under. Player must change lanes!
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.5, 1.0)
	col.shape = box
	col.position = Vector3(0, 1.25, 0)
	add_child(col)

	# Solid Reinforced Barrier Core
	var barrier_mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.3, 2.4, 0.9)
	barrier_mesh.mesh = bm
	barrier_mesh.material_override = solid_barrier_mat
	barrier_mesh.position = Vector3(0, 1.2, 0)
	add_child(barrier_mesh)

	# Glowing Red Hazard Chevron Panels
	var chevrons := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(1.8, 0.35, 0.95)
	chevrons.mesh = cm
	chevrons.material_override = laser_red_mat
	chevrons.position = Vector3(0, 1.4, 0)
	add_child(chevrons)

	var bot_trim := MeshInstance3D.new()
	var btm := BoxMesh.new()
	btm.size = Vector3(2.1, 0.15, 0.95)
	bot_trim.mesh = btm
	bot_trim.material_override = laser_red_mat
	bot_trim.position = Vector3(0, 0.35, 0)
	add_child(bot_trim)

func smash() -> void:
	if not is_active:
		return
	is_active = false
	collision_layer = 0
	collision_mask = 0

	# Spawn explosive demolition sparks
	var sparks := CPUParticles3D.new()
	sparks.emitting = true
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.amount = 32
	sparks.lifetime = 0.5
	sparks.direction = Vector3(0, 0.8, -0.6)
	sparks.spread = 45.0
	sparks.initial_velocity_min = 8.0
	sparks.initial_velocity_max = 16.0
	sparks.gravity = Vector3(0, -18.0, 0)

	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.08, 0.08, 0.08)
	var p_mat := StandardMaterial3D.new()
	
	match obstacle_type:
		ObstacleType.HIGH_GATE:
			p_mat.albedo_color = Color(0.85, 0.15, 1.0)
			p_mat.emission_enabled = true
			p_mat.emission = Color(0.85, 0.15, 1.0)
			p_mat.emission_energy_multiplier = 3.5
		ObstacleType.LOW_HURDLE:
			p_mat.albedo_color = Color(0.72, 0.24, 0.16)
			p_mat.emission_enabled = true
			p_mat.emission = Color(1.0, 0.15, 0.15)
			p_mat.emission_energy_multiplier = 2.5
		_:
			p_mat.albedo_color = Color(1.0, 0.2, 0.2)
			p_mat.emission_enabled = true
			p_mat.emission = Color(1.0, 0.2, 0.2)
			p_mat.emission_energy_multiplier = 3.0

	sparks.mesh = p_mesh
	sparks.material_override = p_mat

	get_parent().add_child(sparks)
	sparks.global_position = global_position + Vector3(0, 1.0, 0)

	# Free obstacle immediately
	queue_free()
