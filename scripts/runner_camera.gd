extends Camera3D

@export var player: CharacterBody3D

const OFFSET_Y: float = 3.6
const OFFSET_Z: float = 7.0
const LOOK_AHEAD_Z: float = -14.0
const LOOK_AHEAD_Y: float = 1.3

const BASE_FOV: float = 75.0
const MAX_FOV: float = 86.0

var current_cam_x: float = 0.0
var current_cam_y: float = OFFSET_Y

func _ready() -> void:
	if player == null:
		player = get_parent().get_node_or_null("Player") as CharacterBody3D

	fov = BASE_FOV
	if player:
		current_cam_x = player.global_position.x
		current_cam_y = player.global_position.y + OFFSET_Y
		global_position = Vector3(current_cam_x, current_cam_y, player.global_position.z + OFFSET_Z)

func _process(delta: float) -> void:
	if player == null:
		return

	var p_pos: Vector3 = player.global_position

	# 1. Smooth horizontal follow (lane shift lag)
	current_cam_x = lerp(current_cam_x, p_pos.x * 0.65, delta * 9.0)

	# 2. Smooth vertical follow
	var target_y: float = p_pos.y + OFFSET_Y
	current_cam_y = lerp(current_cam_y, target_y, delta * 7.0)

	# 3. Direct Z tracking (perfect lock for zero jitter) + Nitrous Kinetic Micro-Shake
	var target_z: float = p_pos.z + OFFSET_Z

	var nitro_factor: float = 0.0
	if player.has_method("get_nitro_factor"):
		nitro_factor = float(player.call("get_nitro_factor"))
	elif "boost_amount" in player:
		nitro_factor = clampf(float(player.get("boost_amount")) / 16.0, 0.0, 1.0)

	var nitro_shake := Vector3.ZERO
	if nitro_factor > 0.05 and ("is_alive" in player and player.get("is_alive")):
		var shake_mag: float = nitro_factor * 0.018
		nitro_shake = Vector3(
			randf_range(-shake_mag, shake_mag),
			randf_range(-shake_mag, shake_mag),
			0.0
		)

	global_position = Vector3(current_cam_x, current_cam_y, target_z) + nitro_shake

	# 4. Look ahead along the track
	var look_target := Vector3(p_pos.x * 0.3, p_pos.y + LOOK_AHEAD_Y, p_pos.z + LOOK_AHEAD_Z)
	look_at(look_target, Vector3.UP)

	# 5. Dynamic FOV kick: Base speed + Nitrous Surge kick (smooth and comfortable)
	if "is_alive" in player and player.get("is_alive"):
		var f_val = player.get("forward_speed")
		var b_val = player.get("BASE_FORWARD_SPEED")
		var m_val = player.get("MAX_FORWARD_SPEED")
		var f_speed: float = float(f_val) if f_val != null else 24.0
		var base_spd: float = float(b_val) if b_val != null else 24.0
		var max_spd: float = float(m_val) if m_val != null else 66.0
		var speed_factor: float = clampf((f_speed - base_spd) / maxf(max_spd - base_spd, 1.0), 0.0, 1.0)
		var target_fov: float = lerp(BASE_FOV, MAX_FOV, speed_factor) + (nitro_factor * 4.5)
		fov = lerp(fov, target_fov, delta * 6.0)

	# 6. Subtle camera roll on lane shift
	var x_velocity: float = player.velocity.x
	var target_roll: float = -x_velocity * 0.006
	rotation.z = lerp_angle(rotation.z, target_roll, delta * 8.0)
