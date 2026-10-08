extends CharacterBody3D

# Player controller for 3D open world
# WASD movement + Space to jump + mouse look + scroll to zoom

const SPEED := 10.0
const JUMP_VELOCITY := 9.0
const GRAVITY := 20.0
const MOUSE_SENSITIVITY := 0.003

# Camera zoom range
const ZOOM_MIN_DISTANCE := 4.0
const ZOOM_MAX_DISTANCE := 25.0
const ZOOM_SPEED := 3.0         # How fast scroll changes distance
const ZOOM_MIN_HEIGHT := 3.0
const ZOOM_MAX_HEIGHT := 12.0

var camera: Camera3D
var camera_height := 6.0
var camera_distance := 15.0
var target_camera_distance := 15.0
var target_camera_height := 6.0
var camera_angle_x := 0.0       # Vertical rotation
var camera_angle_z := 0.0      # Horizontal rotation

func _ready():
	# Find the camera in the scene
	camera = get_parent().get_node_or_null("Camera")

	# Setup player collision shape
	var col_shape = $CollisionShape
	if col_shape:
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.8, 1.8, 0.8)
		col_shape.shape = shape

	# Setup player visual mesh
	var mesh = $MeshInstance3D
	if mesh:
		var box = BoxMesh.new()
		box.size = Vector3(0.8, 1.8, 0.8)
		mesh.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.2, 0.4)
		mat.emission = Color(0.3, 0.3, 0.6)
		mesh.material_override = mat

	# Capture mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Right-click to re-capture mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Mouse wheel zoom (scroll up = zoom in, scroll down = zoom out)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_camera_distance -= ZOOM_SPEED
			target_camera_height -= ZOOM_SPEED * 0.4
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_camera_distance += ZOOM_SPEED
			target_camera_height += ZOOM_SPEED * 0.4

	# Clamp zoom range
	target_camera_distance = clamp(target_camera_distance, ZOOM_MIN_DISTANCE, ZOOM_MAX_DISTANCE)
	target_camera_height = clamp(target_camera_height, ZOOM_MIN_HEIGHT, ZOOM_MAX_HEIGHT)

	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_angle_z -= event.relative.x * MOUSE_SENSITIVITY
		camera_angle_x -= event.relative.y * MOUSE_SENSITIVITY
		camera_angle_x = clamp(camera_angle_x, -1.2, 1.2)

	# ESC toggles mouse capture
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get movement direction relative to camera
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_backward")

	if input_dir != Vector2.ZERO:
		var camera_forward := Vector3(0, 0, 1).rotated(Vector3.UP, camera_angle_z)
		var camera_right := Vector3(1, 0, 0).rotated(Vector3.UP, camera_angle_z)

		var move_dir := Vector3.ZERO
		move_dir += camera_forward * input_dir.y
		move_dir += camera_right * input_dir.x
		move_dir.y = 0
		move_dir = move_dir.normalized()

		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)

	move_and_slide()

	# Fall reset - if player falls too far, respawn
	if global_position.y < -20:
		global_position = Vector3(0, 5, 0)
		velocity = Vector3.ZERO

func _process(delta):
	# Smoothly interpolate camera zoom
	camera_distance = lerp(camera_distance, target_camera_distance, delta * 8.0)
	camera_height = lerp(camera_height, target_camera_height, delta * 8.0)

	# Update camera position to follow player
	if camera:
		var cam_offset := Vector3.ZERO
		cam_offset.z = camera_distance
		cam_offset.y = camera_height

		# Apply vertical rotation
		cam_offset = cam_offset.rotated(Vector3.RIGHT, camera_angle_x)
		# Apply horizontal rotation
		cam_offset = cam_offset.rotated(Vector3.UP, camera_angle_z)

		var target_pos := global_position + cam_offset
		camera.global_position = camera.global_position.lerp(target_pos, 0.1)
		camera.look_at(global_position + Vector3(0, 1.5, 0), Vector3.UP)
