extends Node3D

const AssetLoader = preload("res://scripts/asset_loader.gd")

const CHUNK_LENGTH: float = 40.0
const CHUNK_WIDTH: float = 12.0
const LANE_WIDTH: float = 3.2

# Clean, Grounded Materials
static var road_material: StandardMaterial3D = null
static var lane_line_material: StandardMaterial3D = null
static var curb_material: StandardMaterial3D = null
static var barrier_material: StandardMaterial3D = null
static var gantry_sign_material: StandardMaterial3D = null

var chunk_index: int = 0
var has_arch: bool = false

func _init() -> void:
	_init_shared_materials()

static func _init_shared_materials() -> void:
	if road_material != null:
		return

	# 1. Dark Clean Highway Tarmac (Matte, non-glare, high readability)
	road_material = StandardMaterial3D.new()
	road_material.albedo_color = Color(0.1, 0.11, 0.14)
	road_material.metallic = 0.25
	road_material.roughness = 0.72

	# 2. Crisp Painted Highway Lane Dashes (Clean off-white, non-blinding)
	lane_line_material = StandardMaterial3D.new()
	lane_line_material.albedo_color = Color(0.8, 0.84, 0.9)
	lane_line_material.roughness = 0.5
	lane_line_material.emission_enabled = true
	lane_line_material.emission = Color(0.15, 0.2, 0.3)
	lane_line_material.emission_energy_multiplier = 0.25

	# 3. Dark Gunmetal Curbs / Shoulder Edge Strips
	curb_material = StandardMaterial3D.new()
	curb_material.albedo_color = Color(0.18, 0.2, 0.24)
	curb_material.metallic = 0.7
	curb_material.roughness = 0.45

	# 4. Sci-Fi Barrier Material (Sleek dark structural steel)
	barrier_material = StandardMaterial3D.new()
	barrier_material.albedo_color = Color(0.14, 0.16, 0.2)
	barrier_material.metallic = 0.88
	barrier_material.roughness = 0.3

	# 5. Overhead Highway Sign (Clean matte dark tech display)
	gantry_sign_material = StandardMaterial3D.new()
	gantry_sign_material.albedo_color = Color(0.08, 0.12, 0.18)
	gantry_sign_material.emission_enabled = true
	gantry_sign_material.emission = Color(0.1, 0.35, 0.55)
	gantry_sign_material.emission_energy_multiplier = 0.6

func setup_chunk(idx: int, spawn_arch: bool = false) -> void:
	chunk_index = idx
	has_arch = spawn_arch

	_build_road_surface()
	_build_clean_lane_markings()
	_build_outer_guardrails()
	_build_under_pillars()

	if has_arch:
		_build_overhead_gantry()

	_build_distant_skyline()

func _build_road_surface() -> void:
	# Physics floor collision (covers exactly X: -6.0 to +6.0)
	var static_body := StaticBody3D.new()
	static_body.name = "RoadBody"
	add_child(static_body)

	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(CHUNK_WIDTH, 1.0, CHUNK_LENGTH)
	col_shape.shape = box
	col_shape.position = Vector3(0, -0.5, 0)
	static_body.add_child(col_shape)

	# Main road slab
	var road_mesh := MeshInstance3D.new()
	var road_box := BoxMesh.new()
	road_box.size = Vector3(CHUNK_WIDTH, 1.0, CHUNK_LENGTH)
	road_mesh.mesh = road_box
	road_mesh.material_override = road_material
	road_mesh.position = Vector3(0, -0.5, 0)
	add_child(road_mesh)

	# Outer curb strips at the road shoulders (at X = -5.8 and X = +5.8)
	var sides: Array[float] = [-1.0, 1.0]
	for side: float in sides:
		var curb := MeshInstance3D.new()
		var curb_box := BoxMesh.new()
		curb_box.size = Vector3(0.25, 0.04, CHUNK_LENGTH)
		curb.mesh = curb_box
		curb.material_override = curb_material
		curb.position = Vector3(side * (CHUNK_WIDTH * 0.5 - 0.2), 0.02, 0)
		add_child(curb)

func _build_clean_lane_markings() -> void:
	# 3 Distinct Lanes: Left (-3.2), Center (0.0), Right (+3.2)
	# Divided by clean, painted dashed lines at X = -1.6 and X = +1.6
	var divider_x_coords: Array[float] = [-1.6, 1.6]
	var dash_count: int = 7
	var dash_length: float = 3.0
	var step: float = CHUNK_LENGTH / float(dash_count)

	for x: float in divider_x_coords:
		for i: int in range(dash_count):
			var z_pos: float = -CHUNK_LENGTH * 0.5 + (float(i) + 0.5) * step
			var dash := MeshInstance3D.new()
			var dash_box := BoxMesh.new()
			dash_box.size = Vector3(0.12, 0.02, dash_length)
			dash.mesh = dash_box
			dash.material_override = lane_line_material
			dash.position = Vector3(x, 0.015, z_pos)
			add_child(dash)

func _build_outer_guardrails() -> void:
	# Solid sci-fi guardrail barriers positioned strictly OUTSIDE the road (at X = -6.2 and X = +6.2)
	# Completely clear of Lane 1 (at X = 3.2) and Lane -1 (at X = -3.2)
	var sides: Array[float] = [-1.0, 1.0]

	for side: float in sides:
		var rail_x: float = side * (CHUNK_WIDTH * 0.5 + 0.25) # X = +-6.25

		# 1. Continuous Solid Barrier Base
		var barrier_base := MeshInstance3D.new()
		var base_box := BoxMesh.new()
		base_box.size = Vector3(0.4, 1.2, CHUNK_LENGTH)
		barrier_base.mesh = base_box
		barrier_base.material_override = barrier_material
		barrier_base.position = Vector3(rail_x, 0.6, 0)
		add_child(barrier_base)

		# 2. Sleek Top Cap Rail
		var rail_cap := MeshInstance3D.new()
		var cap_box := BoxMesh.new()
		cap_box.size = Vector3(0.5, 0.1, CHUNK_LENGTH)
		rail_cap.mesh = cap_box
		rail_cap.material_override = curb_material
		rail_cap.position = Vector3(rail_x, 1.25, 0)
		add_child(rail_cap)

func _build_under_pillars() -> void:
	# Maglev structural pillar supporting highway from below into the void
	var pillar_model: Node3D = AssetLoader.get_model("pillar")
	if pillar_model:
		pillar_model.scale = Vector3(2.5, 3.5, 2.5)
		pillar_model.position = Vector3(0, -6.5, 0)
		add_child(pillar_model)

func _build_overhead_gantry() -> void:
	# Overhead Cyber Highway Gantry with pillars positioned strictly OUTSIDE the road at X = +-6.6
	# Zero obstruction in ANY lane
	var gantry_root := Node3D.new()
	gantry_root.name = "OverheadGantry"
	add_child(gantry_root)

	var gantry_h: float = 6.8
	var gantry_w: float = CHUNK_WIDTH + 1.6 # 13.6 units span

	# Left Support Pillar
	var left_post := MeshInstance3D.new()
	var post_box := BoxMesh.new()
	post_box.size = Vector3(0.6, gantry_h, 0.6)
	left_post.mesh = post_box
	left_post.material_override = barrier_material
	left_post.position = Vector3(-gantry_w * 0.5, gantry_h * 0.5, 0)
	gantry_root.add_child(left_post)

	# Right Support Pillar
	var right_post := MeshInstance3D.new()
	right_post.mesh = post_box
	right_post.material_override = barrier_material
	right_post.position = Vector3(gantry_w * 0.5, gantry_h * 0.5, 0)
	gantry_root.add_child(right_post)

	# Overhead Crossbeam
	var crossbeam := MeshInstance3D.new()
	var beam_box := BoxMesh.new()
	beam_box.size = Vector3(gantry_w, 0.6, 0.6)
	crossbeam.mesh = beam_box
	crossbeam.material_override = barrier_material
	crossbeam.position = Vector3(0, gantry_h, 0)
	gantry_root.add_child(crossbeam)

	# Digital Information Sign on the beam
	var sign_mesh := MeshInstance3D.new()
	var sign_box := BoxMesh.new()
	sign_box.size = Vector3(gantry_w * 0.7, 0.35, 0.12)
	sign_mesh.mesh = sign_box
	sign_mesh.material_override = gantry_sign_material
	sign_mesh.position = Vector3(0, gantry_h, 0.35)
	gantry_root.add_child(sign_mesh)

func _build_distant_skyline() -> void:
	# Distant skyscrapers and speeders located far away on the city horizon (32+ meters out)
	# 100% impossible to ever enter or touch the highway lanes
	var sides: Array[float] = [-1.0, 1.0]

	for side: float in sides:
		# Place skyscrapers far away on the horizon
		if (chunk_index + int(side)) % 2 == 0:
			var b_name: String = "building_tall" if (chunk_index % 3 == 0) else "building_round"
			var tower: Node3D = AssetLoader.get_model(b_name)
			if tower:
				# Position 32 to 38 meters away from highway center
				var tower_x: float = side * (32.0 + float((chunk_index * 7) % 8))
				var tower_y: float = -12.0 # Grounded down on the horizon
				var tower_z: float = -CHUNK_LENGTH * 0.4
				tower.scale = Vector3(4.0, 6.0, 4.0)
				tower.position = Vector3(tower_x, tower_y, tower_z)
				add_child(tower)

		# Floating hover speeder in the far distance
		if (chunk_index + 1) % 4 == 0:
			var speeder: Node3D = AssetLoader.get_model("speeder")
			if speeder:
				var sp_x: float = side * 18.0 # 18m away
				var sp_y: float = 6.0 + sin(float(chunk_index)) * 2.0
				var sp_z: float = -CHUNK_LENGTH * 0.5
				speeder.scale = Vector3(2.0, 2.0, 2.0)
				speeder.position = Vector3(sp_x, sp_y, sp_z)
				if side < 0:
					speeder.rotation.y = PI
				add_child(speeder)
