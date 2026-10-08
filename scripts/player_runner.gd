extends CharacterBody3D
class_name PlayerRunner

const AssetLoader = preload("res://scripts/asset_loader.gd")

# Signals
signal lane_changed(new_lane: int)
signal jumped()
signal slid()
signal speed_updated(new_speed: float)
signal distance_updated(meters: float)
signal crashed()

# Movement Constants
const LANE_WIDTH: float = 3.2
const BASE_FORWARD_SPEED: float = 24.0
const MAX_FORWARD_SPEED: float = 52.0
const SPEED_RAMP_RATE: float = 0.35 # Increase speed per 100 meters
const LANE_SWITCH_SPEED: float = 20.0
const JUMP_VELOCITY: float = 14.0
const GRAVITY: float = 38.0
const FAST_FALL_SPEED: float = -28.0
const SLIDE_DURATION: float = 0.55

# Lanes: -1 (Left), 0 (Center), 1 (Right)
var current_lane: int = 0
var target_x: float = 0.0
var forward_speed: float = BASE_FORWARD_SPEED
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

# Friction sparks only during active ground slide
var slide_spark_particles: CPUParticles3D

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

	# 1. Forward Speed Ramping
	distance_traveled = abs(global_position.z - start_z)
	forward_speed = clampf(BASE_FORWARD_SPEED + (distance_traveled / 100.0) * SPEED_RAMP_RATE, BASE_FORWARD_SPEED, MAX_FORWARD_SPEED)
	speed_updated.emit(forward_speed)
	distance_updated.emit(distance_traveled)

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
			anim_player.speed_scale = clampf(forward_speed / 18.0, 1.0, 2.2)
			visuals_root.position.y = lerp(visuals_root.position.y, 0.0, delta * 15.0)
			visuals_root.rotation.x = lerp_angle(visuals_root.rotation.x, 0.08, delta * 12.0)

func _trigger_crash(reason: String = "obstacle") -> void:
	if not is_alive:
		return
	is_alive = false
	if anim_player and anim_player.has_animation("die"):
		anim_player.play("die")
	if slide_spark_particles:
		slide_spark_particles.emitting = false
	crashed.emit()
