extends CharacterBody3D
class_name PlayerRunner

const AssetLoader = preload("res://scripts/asset_loader.gd")

# Signals
signal lane_changed(new_lane: int)
signal jumped()
signal slid()
signal speed_updated(new_speed: float)
signal boost_state_changed(is_boosting: bool)
signal nitro_intensity_updated(factor: float)
signal distance_updated(meters: float)
signal crashed()

# Movement Constants
const LANE_WIDTH: float = 3.2
const BASE_FORWARD_SPEED: float = 24.0
const MAX_BASE_FORWARD_SPEED: float = 50.0
const MAX_FORWARD_SPEED: float = 66.0 # Max possible velocity with ramp + boost
const BOOST_EXTRA_SPEED: float = 16.0 # Extra speed when W is held (24 -> 40+ m/s, ~145 km/h)
const BOOST_ACCEL_RATE: float = 24.0 # Responsive acceleration into boost
const BOOST_DECEL_RATE: float = 14.0 # Smooth deceleration when W is released
const SPEED_RAMP_RATE: float = 0.35 # Increase base speed per 100 meters
const LANE_SWITCH_SPEED: float = 20.0
const JUMP_VELOCITY: float = 14.0
const GRAVITY: float = 38.0
const FAST_FALL_SPEED: float = -28.0
const SLIDE_DURATION: float = 0.55

# Lanes: -1 (Left), 0 (Center), 1 (Right)
var current_lane: int = 0
var target_x: float = 0.0
var forward_speed: float = BASE_FORWARD_SPEED
var boost_amount: float = 0.0
var is_boosting: bool = false
var distance_traveled: float = 0.0
var start_z: float = 0.0

# States
var is_sliding: bool = false
var slide_timer: float = 0.0
var is_alive: bool = true

# Node references
var visuals_root: Node3D
var collision_shape: CollisionShape3D
var box_shape: BoxShape3D
var anim_player: AnimationPlayer
var character_model: Node3D

# Particles & Nitrous Thrusters
var slide_spark_particles: CPUParticles3D
var boost_trail_particles: CPUParticles3D
var nitro_left_root: Node3D
var nitro_right_root: Node3D
var nitro_ground_light: OmniLight3D

func _ready() -> void:
	start_z = global_position.z
	_setup_collision()
	_setup_visuals()

func _setup_collision() -> void:
	collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)

	box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.0, 1.8, 1.0)
	collision_shape.shape = box_shape
	collision_shape.position = Vector3(0, 0.9, 0)

func _setup_visuals() -> void:
	visuals_root = Node3D.new()
	visuals_root.name = "Visuals"
	add_child(visuals_root)

	# Clean 3D Humanoid Runner Model
	character_model = AssetLoader.get_model("character")
	if character_model:
		character_model.name = "CharacterModel"
		character_model.scale = Vector3(1.3, 1.3, 1.3)
		# Face forward along -Z (model faces +Z natively)
		character_model.rotation.y = PI
		visuals_root.add_child(character_model)

		anim_player = character_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim_player:
			if anim_player.has_animation("sprint"):
				anim_player.play("sprint")

	# Ground friction sparks (active only during slide)
	slide_spark_particles = _create_spark_particles()
	visuals_root.add_child(slide_spark_particles)

	# Aerodynamic boost speed particles (active when holding W)
	boost_trail_particles = _create_boost_particles()
	visuals_root.add_child(boost_trail_particles)

	# Twin Nitrous Plasma Burners & Ground Glow
	_setup_nitrous_thrusters()

func _setup_nitrous_thrusters() -> void:
	# Material: Outer Electric Cyan Nitrous Flame
	var outer_mat := StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.0, 0.85, 1.0)
	outer_mat.emission_enabled = true
	outer_mat.emission = Color(0.0, 0.85, 1.0)
	outer_mat.emission_energy_multiplier = 4.2
	outer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Material: Inner Superheated White Core
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(0.9, 0.98, 1.0)
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.9, 0.98, 1.0)
	core_mat.emission_energy_multiplier = 6.0
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var flame_len: float = 0.65
	var flame_mesh := BoxMesh.new()
	flame_mesh.size = Vector3(0.09, 0.09, flame_len)

	var core_len: float = 0.4
	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.04, 0.04, core_len)

	# Left Thruster Nozzle Root (Positioned at runner hip/backpack)
	nitro_left_root = Node3D.new()
	nitro_left_root.position = Vector3(-0.2, 0.72, 0.35)
	nitro_left_root.scale = Vector3.ZERO
	visuals_root.add_child(nitro_left_root)

	var left_outer := MeshInstance3D.new()
	left_outer.mesh = flame_mesh
	left_outer.material_override = outer_mat
	left_outer.position = Vector3(0, 0, flame_len * 0.5)
	nitro_left_root.add_child(left_outer)

	var left_core := MeshInstance3D.new()
	left_core.mesh = core_mesh
	left_core.material_override = core_mat
	left_core.position = Vector3(0, 0, core_len * 0.5)
	nitro_left_root.add_child(left_core)

	# Right Thruster Nozzle Root
	nitro_right_root = Node3D.new()
	nitro_right_root.position = Vector3(0.2, 0.72, 0.35)
	nitro_right_root.scale = Vector3.ZERO
	visuals_root.add_child(nitro_right_root)

	var right_outer := MeshInstance3D.new()
	right_outer.mesh = flame_mesh
	right_outer.material_override = outer_mat
	right_outer.position = Vector3(0, 0, flame_len * 0.5)
	nitro_right_root.add_child(right_outer)

	var right_core := MeshInstance3D.new()
	right_core.mesh = core_mesh
	right_core.material_override = core_mat
	right_core.position = Vector3(0, 0, core_len * 0.5)
	nitro_right_root.add_child(right_core)

	# Nitrous Dynamic Ground Glow Light
	nitro_ground_light = OmniLight3D.new()
	nitro_ground_light.position = Vector3(0, 0.5, 0.7)
	nitro_ground_light.light_color = Color(0.0, 0.85, 1.0)
	nitro_ground_light.light_energy = 0.0
	nitro_ground_light.omni_range = 6.5
	nitro_ground_light.omni_attenuation = 1.3
	visuals_root.add_child(nitro_ground_light)

func _create_spark_particles() -> CPUParticles3D:
	var parts := CPUParticles3D.new()
	parts.position = Vector3(0, 0.05, 0)
	parts.emitting = false
	parts.amount = 16
	parts.lifetime = 0.25
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	parts.emission_box_extents = Vector3(0.25, 0.02, 0.25)
	parts.gravity = Vector3(0, 9.8, 12.0)
	parts.direction = Vector3(0, 0.4, 1.0)
	parts.spread = 25.0
	parts.initial_velocity_min = 4.0
	parts.initial_velocity_max = 10.0
	parts.scale_amount_min = 0.03
	parts.scale_amount_max = 0.06

	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.03, 0.03, 0.03)
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(1.0, 0.8, 0.3)
	p_mat.emission_enabled = true
	p_mat.emission = Color(1.0, 0.7, 0.1)
	p_mat.emission_energy_multiplier = 1.5
	parts.mesh = p_mesh
	parts.material_override = p_mat
	return parts

func _create_boost_particles() -> CPUParticles3D:
	var parts := CPUParticles3D.new()
	parts.position = Vector3(0, 0.72, 0.42)
	parts.emitting = false
	parts.amount = 40
	parts.lifetime = 0.18
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	parts.emission_box_extents = Vector3(0.25, 0.15, 0.08)
	parts.gravity = Vector3(0, 0, 0)
	parts.direction = Vector3(0, 0.05, 1.0)
	parts.spread = 10.0
	parts.initial_velocity_min = 16.0
	parts.initial_velocity_max = 24.0
	parts.scale_amount_min = 0.04
	parts.scale_amount_max = 0.09

	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.03, 0.03, 0.28)
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.15, 0.95, 1.0)
	p_mat.emission_enabled = true
	p_mat.emission = Color(0.15, 0.95, 1.0)
	p_mat.emission_energy_multiplier = 3.8
	parts.mesh = p_mesh
	parts.material_override = p_mat
	return parts

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive:
		return

	if event.is_action_pressed("move_left"):
		_shift_lane(-1)
	elif event.is_action_pressed("move_right"):
		_shift_lane(1)

	if event.is_action_pressed("jump"):
		_handle_jump()

	if event.is_action_pressed("slide"):
		_handle_slide()

func _shift_lane(direction: int) -> void:
	var next_lane: int = clampi(current_lane + direction, -1, 1)
	if next_lane != current_lane:
		current_lane = next_lane
		target_x = float(current_lane) * LANE_WIDTH
		lane_changed.emit(current_lane)

func _handle_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		if is_sliding:
			_end_slide()
		if anim_player and anim_player.has_animation("jump"):
			anim_player.play("jump")
		jumped.emit()

func _handle_slide() -> void:
	if not is_on_floor():
		velocity.y = FAST_FALL_SPEED
	else:
		_start_slide()

func _start_slide() -> void:
	if is_sliding:
		slide_timer = SLIDE_DURATION
		return

	is_sliding = true
	slide_timer = SLIDE_DURATION
	# Keep bottom of collision shape at 0.0 (height 0.8, center y = 0.4)
	box_shape.size = Vector3(1.0, 0.8, 1.2)
	collision_shape.position = Vector3(0, 0.4, 0)
	if slide_spark_particles:
		slide_spark_particles.emitting = true
	if anim_player and anim_player.has_animation("crouch"):
		anim_player.play("crouch")
	slid.emit()

func _end_slide() -> void:
	is_sliding = false
	slide_timer = 0.0
	# Standing height 1.8, center y = 0.9 -> bottom is at 0.0
	box_shape.size = Vector3(1.0, 1.8, 1.0)
	collision_shape.position = Vector3(0, 0.9, 0)
	if slide_spark_particles:
		slide_spark_particles.emitting = false

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# 1. Forward Speed Ramping and W Key Speed Boost
	distance_traveled = abs(global_position.z - start_z)
	var base_speed: float = clampf(BASE_FORWARD_SPEED + (distance_traveled / 100.0) * SPEED_RAMP_RATE, BASE_FORWARD_SPEED, MAX_BASE_FORWARD_SPEED)

	# When player presses/holds W, accelerate forward speed
	var wants_boost: bool = (Input.is_action_pressed("boost") or Input.is_key_pressed(KEY_W)) and not is_sliding
	if wants_boost:
		boost_amount = move_toward(boost_amount, BOOST_EXTRA_SPEED, delta * BOOST_ACCEL_RATE)
	else:
		boost_amount = move_toward(boost_amount, 0.0, delta * BOOST_DECEL_RATE)

	var active_boost: bool = (boost_amount > 1.0)
	if active_boost != is_boosting:
		is_boosting = active_boost
		boost_state_changed.emit(is_boosting)

	forward_speed = base_speed + boost_amount
	speed_updated.emit(forward_speed)
	distance_updated.emit(distance_traveled)

	var nitro_factor: float = clampf(boost_amount / BOOST_EXTRA_SPEED, 0.0, 1.0)
	nitro_intensity_updated.emit(nitro_factor)
	_update_nitrous_thrusters(delta, nitro_factor)

	if boost_trail_particles:
		boost_trail_particles.emitting = is_boosting and is_alive

	velocity.z = -forward_speed

	# 2. Gravity and Airborne State
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0:
		velocity.y = 0.0

	# 3. Smooth Lane Interpolation (X Axis)
	var x_diff: float = target_x - global_position.x
	velocity.x = x_diff * LANE_SWITCH_SPEED

	# 4. Slide Timer
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			_end_slide()

	# 5. Move Character
	move_and_slide()

	# 6. Fall-off fail-safe
	if global_position.y < -15.0:
		_trigger_crash("fell_into_void")

	# 7. Procedural Animations and Skeleton Blend
	_update_character_animation(delta)

func _update_nitrous_thrusters(delta: float, factor: float) -> void:
	var is_active: bool = factor > 0.04 and is_alive and not is_sliding

	if is_active:
		# Rapid combustion flicker for high-power nitrous plasma
		var flicker: float = randf_range(0.88, 1.14)
		var flame_scale := Vector3(factor * flicker, factor * flicker, factor * flicker * 1.35)
		if nitro_left_root: nitro_left_root.scale = flame_scale
		if nitro_right_root: nitro_right_root.scale = flame_scale
		if nitro_ground_light:
			nitro_ground_light.light_energy = lerp(nitro_ground_light.light_energy, factor * 2.8, delta * 24.0)
	else:
		if nitro_left_root: nitro_left_root.scale = Vector3.ZERO
		if nitro_right_root: nitro_right_root.scale = Vector3.ZERO
		if nitro_ground_light:
			nitro_ground_light.light_energy = lerp(nitro_ground_light.light_energy, 0.0, delta * 16.0)

func get_nitro_factor() -> float:
	return clampf(boost_amount / BOOST_EXTRA_SPEED, 0.0, 1.0)

func _update_character_animation(delta: float) -> void:
	if visuals_root == null:
		return

	# Lean / Bank into turns
	var target_roll: float = -velocity.x * 0.025
	visuals_root.rotation.z = lerp_angle(visuals_root.rotation.z, target_roll, delta * 12.0)

	# Skeletal Animation State Machine
	if anim_player:
		if is_sliding:
			if anim_player.current_animation != "crouch":
				anim_player.play("crouch")
			anim_player.speed_scale = 1.0
			# Keep feet firmly on floor at y = 0.0 with NO clipping into floor!
			visuals_root.position.y = lerp(visuals_root.position.y, 0.0, delta * 18.0)
			visuals_root.rotation.x = lerp_angle(visuals_root.rotation.x, 0.0, delta * 18.0)
		elif not is_on_floor():
			if velocity.y > 0.0:
				if anim_player.current_animation != "jump":
					anim_player.play("jump")
			else:
				if anim_player.current_animation != "fall" and anim_player.has_animation("fall"):
					anim_player.play("fall")
			anim_player.speed_scale = 1.0
			visuals_root.position.y = lerp(visuals_root.position.y, 0.0, delta * 12.0)
			visuals_root.rotation.x = lerp_angle(visuals_root.rotation.x, -0.15, delta * 10.0)
		else:
			# Running on track
			if anim_player.current_animation != "sprint":
				anim_player.play("sprint")
			# Sprint animation cadence scales smoothly with boosted forward speed
			anim_player.speed_scale = clampf(forward_speed / 16.0, 1.0, 2.6)
			visuals_root.position.y = lerp(visuals_root.position.y, 0.0, delta * 15.0)
			# Aerodynamic forward lean when boosting
			var target_pitch: float = 0.16 if is_boosting else 0.08
			visuals_root.rotation.x = lerp_angle(visuals_root.rotation.x, target_pitch, delta * 12.0)

func _trigger_crash(reason: String = "obstacle") -> void:
	if not is_alive:
		return
	is_alive = false
	is_boosting = false
	if nitro_left_root: nitro_left_root.scale = Vector3.ZERO
	if nitro_right_root: nitro_right_root.scale = Vector3.ZERO
	if nitro_ground_light: nitro_ground_light.light_energy = 0.0
	nitro_intensity_updated.emit(0.0)
	if boost_trail_particles:
		boost_trail_particles.emitting = false
	if anim_player and anim_player.has_animation("die"):
		anim_player.play("die")
	if slide_spark_particles:
		slide_spark_particles.emitting = false
	crashed.emit()
