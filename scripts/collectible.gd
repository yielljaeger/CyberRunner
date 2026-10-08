extends Area3D
class_name TrackCollectible

enum CollectibleType {
	DATA_CORE, # Points / Coins
	SHIELD,    # 1-hit invulnerability bubble
	OVERDRIVE, # 6s hyper-speed & obstacle smashing
	MAGNET     # 8s data core magnetism
}

@export var item_type: CollectibleType = CollectibleType.DATA_CORE

var is_collected: bool = false
var base_y: float = 0.9
var bob_offset: float = 0.0
var rotate_speed: float = 3.5

# Shared Materials
static var core_mat: StandardMaterial3D = null
static var shield_mat: StandardMaterial3D = null
static var overdrive_mat: StandardMaterial3D = null
static var magnet_mat: StandardMaterial3D = null

func _init() -> void:
	_init_shared_materials()

static func _init_shared_materials() -> void:
	if core_mat != null:
		return

	# Data Core: Glowing Golden Cyan Diamond
	core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(0.1, 0.95, 1.0)
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.1, 0.95, 1.0)
	core_mat.emission_energy_multiplier = 3.5
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Shield: Deep Cyan Hex Energy
	shield_mat = StandardMaterial3D.new()
	shield_mat.albedo_color = Color(0.0, 0.8, 1.0)
	shield_mat.emission_enabled = true
	shield_mat.emission = Color(0.0, 0.8, 1.0)
	shield_mat.emission_energy_multiplier = 4.0
	shield_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Overdrive: Blazing Golden Fire
	overdrive_mat = StandardMaterial3D.new()
	overdrive_mat.albedo_color = Color(1.0, 0.75, 0.1)
	overdrive_mat.emission_enabled = true
	overdrive_mat.emission = Color(1.0, 0.75, 0.1)
	overdrive_mat.emission_energy_multiplier = 4.5
	overdrive_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Magnet: High-voltage Electric Purple
	magnet_mat = StandardMaterial3D.new()
	magnet_mat.albedo_color = Color(0.85, 0.2, 1.0)
	magnet_mat.emission_enabled = true
	magnet_mat.emission = Color(0.85, 0.2, 1.0)
	magnet_mat.emission_energy_multiplier = 4.0
	magnet_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

static func create(type: CollectibleType) -> Area3D:
	var script: GDScript = load("res://scripts/collectible.gd")
	var item: Area3D = script.new()
	item.set("item_type", type)
	item.call("_build_visuals")
	return item

func _build_visuals() -> void:
	add_to_group("collectible")
	collision_layer = 8 # Collectibles layer
	collision_mask = 2  # Player layer
	monitoring = true
	monitorable = true

	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.75
	col.shape = sphere
	col.position = Vector3(0, 0, 0)
	add_child(col)

	bob_offset = randf() * TAU

	match item_type:
		CollectibleType.DATA_CORE:
			_build_data_core()
		CollectibleType.SHIELD:
			_build_shield_powerup()
		CollectibleType.OVERDRIVE:
			_build_overdrive_powerup()
		CollectibleType.MAGNET:
			_build_magnet_powerup()

func _build_data_core() -> void:
	name = "DataCore"
	# 3D Rotating Diamond Prism
	var core_mesh := MeshInstance3D.new()
	var prism := BoxMesh.new()
	prism.size = Vector3(0.42, 0.42, 0.42)
	core_mesh.mesh = prism
	core_mesh.material_override = core_mat
	core_mesh.rotation_degrees = Vector3(45.0, 45.0, 0.0)
	add_child(core_mesh)

func _build_shield_powerup() -> void:
	name = "PowerUp_Shield"
	# Glowing Sphere with Outer Ring
	var sphere_mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.4
	s.height = 0.8
	sphere_mesh.mesh = s
	sphere_mesh.material_override = shield_mat
	add_child(sphere_mesh)

	var ring := MeshInstance3D.new()
	var r := TorusMesh.new()
	r.inner_radius = 0.45
	r.outer_radius = 0.58
	ring.mesh = r
	ring.material_override = shield_mat
	ring.rotation_degrees = Vector3(70.0, 0.0, 0.0)
	add_child(ring)

func _build_overdrive_powerup() -> void:
	name = "PowerUp_Overdrive"
	# Blazing Rocket Cylinder Core with Outer Spikes
	var flame_mesh := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.05
	c.bottom_radius = 0.35
	c.height = 0.75
	flame_mesh.mesh = c
	flame_mesh.material_override = overdrive_mat
	flame_mesh.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	add_child(flame_mesh)

	var core := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 0.3, 0.3)
	core.mesh = bm
	core.material_override = overdrive_mat
	core.rotation_degrees = Vector3(45.0, 45.0, 45.0)
	add_child(core)

func _build_magnet_powerup() -> void:
	name = "PowerUp_Magnet"
	# Dual-Pole Horseshoe Magnet Arch
	var arch := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.3
	tm.outer_radius = 0.5
	arch.mesh = tm
	arch.material_override = magnet_mat
	arch.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(arch)

func _process(delta: float) -> void:
	if is_collected:
		return

	# Idle Spin & Gentle Bobbing
	rotate_y(rotate_speed * delta)
	position.y = base_y + sin(Time.get_ticks_msec() * 0.004 + bob_offset) * 0.12

func attract_towards(target_pos: Vector3, delta: float) -> void:
	if is_collected:
		return
	# Smooth magnetic pull towards player
	global_position = global_position.lerp(target_pos, delta * 12.0)

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	collision_layer = 0
	collision_mask = 0

	# Spawn collection particle burst
	var burst := CPUParticles3D.new()
	burst.emitting = true
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.amount = 16
	burst.lifetime = 0.35
	burst.spread = 180.0
	burst.initial_velocity_min = 4.0
	burst.initial_velocity_max = 9.0
	burst.gravity = Vector3(0, 0, 0)
	
	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.06, 0.06, 0.06)
	var p_mat := StandardMaterial3D.new()
	match item_type:
		CollectibleType.DATA_CORE:
			p_mat.albedo_color = Color(0.1, 0.95, 1.0)
			p_mat.emission = Color(0.1, 0.95, 1.0)
		CollectibleType.SHIELD:
			p_mat.albedo_color = Color(0.0, 0.8, 1.0)
			p_mat.emission = Color(0.0, 0.8, 1.0)
		CollectibleType.OVERDRIVE:
			p_mat.albedo_color = Color(1.0, 0.8, 0.1)
			p_mat.emission = Color(1.0, 0.8, 0.1)
		CollectibleType.MAGNET:
			p_mat.albedo_color = Color(0.85, 0.2, 1.0)
			p_mat.emission = Color(0.85, 0.2, 1.0)
	p_mat.emission_enabled = true
	p_mat.emission_energy_multiplier = 3.5
	burst.mesh = p_mesh
	burst.material_override = p_mat

	get_parent().add_child(burst)
	burst.global_position = global_position
	queue_free()
