extends Area3D
class_name TrackObstacle

const AssetLoader = preload("res://scripts/asset_loader.gd")

enum ObstacleType {
	LOW_HURDLE,   # Jump over (clearance: jump required)
	HIGH_GATE,    # Slide under (clearance: slide required)
	SOLID_BARRIER # Dodged by lane shift (full height)
}

@export var obstacle_type: ObstacleType = ObstacleType.LOW_HURDLE
var is_active: bool = true

# Shared Materials for Obstacles
static var hazard_metal_mat: StandardMaterial3D = null
static var plasma_orange_mat: StandardMaterial3D = null
static var laser_red_mat: StandardMaterial3D = null
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

	# Electric Amber / Orange Plasma Hurdle
	plasma_orange_mat = StandardMaterial3D.new()
	plasma_orange_mat.albedo_color = Color(1.0, 0.55, 0.1)
	plasma_orange_mat.emission_enabled = true
	plasma_orange_mat.emission = Color(1.0, 0.55, 0.1)
	plasma_orange_mat.emission_energy_multiplier = 4.0
	plasma_orange_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Vivid Cyber Laser Red
	laser_red_mat = StandardMaterial3D.new()
	laser_red_mat.albedo_color = Color(1.0, 0.15, 0.25)
	laser_red_mat.emission_enabled = true
	laser_red_mat.emission = Color(1.0, 0.15, 0.25)
	laser_red_mat.emission_energy_multiplier = 4.5
	laser_red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

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

	# Glowing Electrified Plasma Cross-Beam
	var beam := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(2.3, 0.22, 0.25)
	beam.mesh = b_mesh
	beam.material_override = plasma_orange_mat
	beam.position = Vector3(0, 0.55, 0)
	add_child(beam)

	# Warning hazard light pulse
	var light_mesh := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(1.8, 0.08, 0.28)
	light_mesh.mesh = lm
	light_mesh.material_override = plasma_orange_mat
	light_mesh.position = Vector3(0, 0.25, 0)
	add_child(light_mesh)

func _build_high_gate() -> void:
	name = "HighGate"
	# Collision Shape: Clearance underneath is 0.88m!
	# Box from Y = 0.88m to Y = 2.4m (Height 1.52m, Center Y = 1.64m)
	# When runner slides, hitbox height is 0.75m -> slides underneath cleanly!
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

	# Top Crossbar at Y = 2.4
	var crossbar := MeshInstance3D.new()
	var cb_mesh := BoxMesh.new()
	cb_mesh.size = Vector3(2.4, 0.22, 0.4)
	crossbar.mesh = cb_mesh
	crossbar.material_override = hazard_metal_mat
	crossbar.position = Vector3(0, 2.4, 0)
	add_child(crossbar)

	# Glowing Cyber Laser Barrier Field (Y: 1.0 to 2.3)
	var laser_field := MeshInstance3D.new()
	var lf_mesh := BoxMesh.new()
	lf_mesh.size = Vector3(2.2, 1.25, 0.1)
	laser_field.mesh = lf_mesh
	laser_field.material_override = laser_red_mat
	laser_field.position = Vector3(0, 1.65, 0)
	add_child(laser_field)

	# Warning caution horizontal laser beam at bottom edge (Y = 1.0)
	var tripwire := MeshInstance3D.new()
	var tw_mesh := BoxMesh.new()
	tw_mesh.size = Vector3(2.25, 0.12, 0.2)
	tripwire.mesh = tw_mesh
	tripwire.material_override = laser_red_mat
	tripwire.position = Vector3(0, 1.02, 0)
	add_child(tripwire)

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
	p_mat.albedo_color = Color(1.0, 0.4, 0.1)
	p_mat.emission_enabled = true
	p_mat.emission = Color(1.0, 0.6, 0.1)
	p_mat.emission_energy_multiplier = 3.0
	sparks.mesh = p_mesh
	sparks.material_override = p_mat
	
	get_parent().add_child(sparks)
	sparks.global_position = global_position + Vector3(0, 1.0, 0)
	
	# Free obstacle immediately
	queue_free()
