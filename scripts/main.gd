extends Node

const AssetLoader = preload("res://scripts/asset_loader.gd")

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var dir_light: DirectionalLight3D = $DirectionalLight
@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Camera
@onready var track_spawner: Node3D = $TrackSpawner
@onready var hud: CanvasLayer = $HUD

var is_game_over: bool = false

func _ready() -> void:
	_setup_cyber_environment()
	_connect_signals()

func _setup_cyber_environment() -> void:
	# 1. Clean Starlight Directional Key Light
	if dir_light:
		dir_light.position = Vector3(12.0, 30.0, 18.0)
		dir_light.rotation_degrees = Vector3(-55.0, 40.0, 0.0)
		dir_light.light_color = Color(0.92, 0.95, 1.0)
		dir_light.light_energy = 1.2
		dir_light.shadow_enabled = true
		dir_light.directional_shadow_max_distance = 120.0

	# 2. Balanced WorldEnvironment (Clean, Crisp, Non-Blinding)
	if world_env:
		var env := Environment.new()

		# 4K Panoramic Space Nebula Skybox
		var skybox_tex: Texture2D = AssetLoader.get_skybox_texture()
		if skybox_tex:
			var sky_mat := PanoramaSkyMaterial.new()
			sky_mat.panorama = skybox_tex
			var sky := Sky.new()
			sky.sky_material = sky_mat
			env.sky = sky
			env.background_mode = Environment.BG_SKY
		else:
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.02, 0.025, 0.06)

		# Ambient Cosmic Lighting
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY if skybox_tex else Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.18, 0.2, 0.28)
		env.ambient_light_sky_contribution = 0.5
		env.ambient_light_energy = 0.9

		# Balanced Cyberpunk Glow (Accentuate neon strips while keeping tarmac crisp)
		env.glow_enabled = true
		env.glow_intensity = 0.65
		env.glow_strength = 0.92
		env.glow_bloom = 0.1
		env.glow_hdr_threshold = 1.1
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN

		# Soft Atmospheric Depth Fog
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = Color(0.04, 0.05, 0.12)
		env.fog_density = 0.005
		env.fog_depth_begin = 65.0
		env.fog_depth_end = 280.0

		# ACES Film Tonemapping for natural rich contrast
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.1

		# Clean Ambient Occlusion for grounded contact shadows
		env.ssao_enabled = true
		env.ssao_radius = 1.2
		env.ssao_intensity = 1.5

		world_env.environment = env

func _connect_signals() -> void:
	if player and hud:
		if player.has_signal("speed_updated") and hud.has_method("update_speed"):
			player.connect("speed_updated", Callable(hud, "update_speed"))
		if player.has_signal("boost_state_changed") and hud.has_method("set_boosting"):
			player.connect("boost_state_changed", Callable(hud, "set_boosting"))
		if player.has_signal("nitro_intensity_updated") and hud.has_method("set_nitro_intensity"):
			player.connect("nitro_intensity_updated", Callable(hud, "set_nitro_intensity"))
		if player.has_signal("distance_updated") and hud.has_method("update_distance"):
			player.connect("distance_updated", Callable(hud, "update_distance"))
		if player.has_signal("crashed"):
			player.connect("crashed", Callable(self, "_on_player_crashed"))

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		if event.is_action_pressed("restart") or event.is_action_pressed("jump"):
			_restart_game()

func _on_player_crashed() -> void:
	is_game_over = true
	if hud and hud.has_method("show_game_over"):
		var dist: float = float(player.get("distance_traveled"))
		hud.call("show_game_over", dist)

func _restart_game() -> void:
	get_tree().reload_current_scene()
