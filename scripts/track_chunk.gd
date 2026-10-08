extends Node3D

const AssetLoader = preload("res://scripts/asset_loader.gd")
const ObstacleScript = preload("res://scripts/obstacle.gd")
const CollectibleScript = preload("res://scripts/collectible.gd")

const CHUNK_LENGTH: float = 40.0
const CHUNK_WIDTH: float = 12.0
const LANE_WIDTH: float = 3.2

# Shared Materials (Static instances for maximum performance & batching)
static var road_material: StandardMaterial3D = null
static var lane_line_material: StandardMaterial3D = null
static var curb_material: StandardMaterial3D = null
static var barrier_material: StandardMaterial3D = null
static var gantry_sign_material: StandardMaterial3D = null

# Neon Materials
static var neon_cyan_mat: StandardMaterial3D = null
static var neon_magenta_mat: StandardMaterial3D = null
static var neon_amber_mat: StandardMaterial3D = null
static var neon_purple_mat: StandardMaterial3D = null
static var neon_billboard_mat: StandardMaterial3D = null

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
	gantry_sign_material.albedo_color = Color(0.06, 0.08, 0.12)
	gantry_sign_material.emission_enabled = true
	gantry_sign_material.emission = Color(0.08, 0.3, 0.5)
	gantry_sign_material.emission_energy_multiplier = 1.0

	# 6. Vibrant Cyber Neon Cyan
	neon_cyan_mat = StandardMaterial3D.new()
	neon_cyan_mat.albedo_color = Color(0.0, 0.92, 1.0)
	neon_cyan_mat.emission_enabled = true
	neon_cyan_mat.emission = Color(0.0, 0.92, 1.0)
	neon_cyan_mat.emission_energy_multiplier = 3.2

	# 7. Vibrant Cyber Neon Magenta / Hot Pink
	neon_magenta_mat = StandardMaterial3D.new()
	neon_magenta_mat.albedo_color = Color(1.0, 0.08, 0.65)
	neon_magenta_mat.emission_enabled = true
	neon_magenta_mat.emission = Color(1.0, 0.08, 0.65)
	neon_magenta_mat.emission_energy_multiplier = 3.2

	# 8. Vibrant Cyber Neon Amber / Gold
	neon_amber_mat = StandardMaterial3D.new()
	neon_amber_mat.albedo_color = Color(1.0, 0.72, 0.15)
	neon_amber_mat.emission_enabled = true
	neon_amber_mat.emission = Color(1.0, 0.72, 0.15)
	neon_amber_mat.emission_energy_multiplier = 2.8

	# 9. Vibrant Cyber Neon Purple
	neon_purple_mat = StandardMaterial3D.new()
	neon_purple_mat.albedo_color = Color(0.72, 0.18, 1.0)
	neon_purple_mat.emission_enabled = true
	neon_purple_mat.emission = Color(0.72, 0.18, 1.0)
	neon_purple_mat.emission_energy_multiplier = 3.0

	# 10. Holographic City Billboard Screen
	neon_billboard_mat = StandardMaterial3D.new()
	neon_billboard_mat.albedo_color = Color(0.04, 0.08, 0.16)
	neon_billboard_mat.emission_enabled = true
	neon_billboard_mat.emission = Color(0.0, 0.75, 1.0)
	neon_billboard_mat.emission_energy_multiplier = 2.2

func setup_chunk(idx: int, spawn_arch: bool = false, player_dist: float = 0.0) -> void:
	chunk_index = idx
	has_arch = spawn_arch

	_build_road_surface()
	_build_clean_lane_markings()
	_build_outer_guardrails()
	_build_shoulder_neon_lights()
	_build_highway_streetlamps()
	_build_under_pillars()

	if has_arch:
		_build_overhead_gantry()

	_build_distant_skyline()
	_build_hazards_and_collectibles(player_dist)

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
	# Solid sci-fi guardrail barriers positioned strictly OUTSIDE the road (at X = -6.25 and X = +6.25)
	# Completely clear of running lanes (±3.2)
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

		# 3. Continuous Neon Light Tube along Guardrail Top (Cyan on Left, Magenta on Right)
		var neon_tube := MeshInstance3D.new()
		var tube_box := BoxMesh.new()
		tube_box.size = Vector3(0.12, 0.06, CHUNK_LENGTH)
		neon_tube.mesh = tube_box
		neon_tube.material_override = neon_cyan_mat if side < 0 else neon_magenta_mat
		neon_tube.position = Vector3(rail_x, 1.32, 0)
		add_child(neon_tube)

		# 4. Subtle Inset Neon Groove along inner wall facing highway
		var inner_groove := MeshInstance3D.new()
		var groove_box := BoxMesh.new()
		groove_box.size = Vector3(0.04, 0.06, CHUNK_LENGTH)
		inner_groove.mesh = groove_box
		inner_groove.material_override = neon_cyan_mat if side < 0 else neon_magenta_mat
		inner_groove.position = Vector3(side * (CHUNK_WIDTH * 0.5 + 0.06), 0.5, 0)
		add_child(inner_groove)

func _build_shoulder_neon_lights() -> void:
	# Recessed neon runway shoulder markers every 5 meters (at X = ±5.8, far from lanes)
	var marker_count: int = 8
	var step: float = CHUNK_LENGTH / float(marker_count)
	var sides: Array[float] = [-1.0, 1.0]

	for side: float in sides:
		var shoulder_x: float = side * (CHUNK_WIDTH * 0.5 - 0.2)
		for i: int in range(marker_count):
			var z_pos: float = -CHUNK_LENGTH * 0.5 + (float(i) + 0.5) * step
			var marker := MeshInstance3D.new()
			var m_box := BoxMesh.new()
			m_box.size = Vector3(0.16, 0.03, 0.6)
			marker.mesh = m_box
			# Alternate cyan and amber runway markers
			marker.material_override = neon_cyan_mat if (i % 2 == 0) else neon_amber_mat
			marker.position = Vector3(shoulder_x, 0.04, z_pos)
			add_child(marker)

func _build_highway_streetlamps() -> void:
	# Sleek cantilevered cyber streetlamps spaced at highway perimeter (X = ±6.6)
	# Spawns 1 lamp per chunk, alternating left and right
	var side: float = -1.0 if (chunk_index % 2 == 0) else 1.0
	var lamp_x: float = side * (CHUNK_WIDTH * 0.5 + 0.6) # X = ±6.6
	var lamp_h: float = 5.2

	var lamp_root := Node3D.new()
	lamp_root.position = Vector3(lamp_x, 0, 0)
	add_child(lamp_root)

	# Vertical mast
	var mast := MeshInstance3D.new()
	var mast_box := BoxMesh.new()
	mast_box.size = Vector3(0.2, lamp_h, 0.2)
	mast.mesh = mast_box
	mast.material_override = barrier_material
	mast.position = Vector3(0, lamp_h * 0.5, 0)
	lamp_root.add_child(mast)

	# Horizontal overhang arm towards road (stops at X = ±5.4, well clear of running lanes)
	var arm_len: float = 1.2
	var arm := MeshInstance3D.new()
	var arm_box := BoxMesh.new()
	arm_box.size = Vector3(arm_len, 0.15, 0.2)
	arm.mesh = arm_box
	arm.material_override = barrier_material
	arm.position = Vector3(-side * arm_len * 0.5, lamp_h, 0)
	lamp_root.add_child(arm)

	# Downward neon luminaire light strip
	var lum := MeshInstance3D.new()
	var lum_box := BoxMesh.new()
	lum_box.size = Vector3(arm_len * 0.8, 0.06, 0.16)
	lum.mesh = lum_box
	lum.material_override = neon_cyan_mat if side < 0 else neon_amber_mat
	lum.position = Vector3(-side * arm_len * 0.5, lamp_h - 0.08, 0)
	lamp_root.add_child(lum)

func _build_under_pillars() -> void:
	# Maglev structural pillar supporting highway from below into the void
	var pillar_model: Node3D = AssetLoader.get_model("pillar")
	if pillar_model:
		pillar_model.scale = Vector3(2.5, 3.5, 2.5)
		pillar_model.position = Vector3(0, -6.5, 0)
		add_child(pillar_model)

func _build_overhead_gantry() -> void:
	# Overhead Cyber Highway Gantry with pillars positioned strictly OUTSIDE the road at X = +-6.8
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

	# Continuous Neon Underglow Light Bar across bottom of crossbeam
	var under_neon := MeshInstance3D.new()
	var under_box := BoxMesh.new()
	under_box.size = Vector3(CHUNK_WIDTH + 0.8, 0.08, 0.16)
	under_neon.mesh = under_box
	under_neon.material_override = neon_cyan_mat
	under_neon.position = Vector3(0, gantry_h - 0.32, 0)
	gantry_root.add_child(under_neon)

	# Digital Information Sign on the beam
	var sign_mesh := MeshInstance3D.new()
	var sign_box := BoxMesh.new()
	sign_box.size = Vector3(gantry_w * 0.65, 0.45, 0.12)
	sign_mesh.mesh = sign_box
	sign_mesh.material_override = gantry_sign_material
	sign_mesh.position = Vector3(0, gantry_h, 0.35)
	gantry_root.add_child(sign_mesh)

	# Neon Trim Border on the digital sign
	var sign_neon_top := MeshInstance3D.new()
	var sn_box := BoxMesh.new()
	sn_box.size = Vector3(gantry_w * 0.65, 0.05, 0.14)
	sign_neon_top.mesh = sn_box
	sign_neon_top.material_override = neon_magenta_mat
	sign_neon_top.position = Vector3(0, gantry_h + 0.24, 0.35)
	gantry_root.add_child(sign_neon_top)

	var sign_neon_bot := MeshInstance3D.new()
	sign_neon_bot.mesh = sn_box
	sign_neon_bot.material_override = neon_magenta_mat
	sign_neon_bot.position = Vector3(0, gantry_h - 0.24, 0.35)
	gantry_root.add_child(sign_neon_bot)

func _build_distant_skyline() -> void:
	# Layered Cyberpunk Metropolis Skyline (Distant towers, neon light spines, beacon spires, hover traffic)
	# All elements placed strictly 28m - 60m away from highway center
	var sides: Array[float] = [-1.0, 1.0]

	for side: float in sides:
		# Layer 1: Skyscraper with Neon Architecture
		if (chunk_index + int(side)) % 2 == 0:
			var b_name: String = "building_tall" if (chunk_index % 3 == 0) else "building_round"
			var tower: Node3D = AssetLoader.get_model(b_name)
			if tower:
				var tower_x: float = side * (32.0 + float((chunk_index * 7) % 6))
				var tower_y: float = -12.0
				var tower_z: float = -CHUNK_LENGTH * 0.4
				tower.scale = Vector3(4.5, 6.5, 4.5)
				tower.position = Vector3(tower_x, tower_y, tower_z)
				add_child(tower)

				# Vertical Neon Light Spine running up the skyscraper facade
				var spine := MeshInstance3D.new()
				var spine_box := BoxMesh.new()
				spine_box.size = Vector3(0.5, 36.0, 0.5)
				spine.mesh = spine_box
				spine.material_override = neon_cyan_mat if (chunk_index % 2 == 0) else neon_magenta_mat
				# Place along building face facing highway
				spine.position = Vector3(tower_x - side * 2.5, tower_y + 18.0, tower_z)
				add_child(spine)

				# Rooftop Beacon Antenna Spire
				var spire_mast := MeshInstance3D.new()
				var sm_box := BoxMesh.new()
				sm_box.size = Vector3(0.3, 10.0, 0.3)
				spire_mast.mesh = sm_box
				spire_mast.material_override = barrier_material
				spire_mast.position = Vector3(tower_x, tower_y + 38.0, tower_z)
				add_child(spire_mast)

				# Glowing Neon Beacon Light on antenna tip
				var beacon := MeshInstance3D.new()
				var b_box := BoxMesh.new()
				b_box.size = Vector3(0.9, 0.9, 0.9)
				beacon.mesh = b_box
				beacon.material_override = neon_amber_mat if (chunk_index % 2 == 0) else neon_magenta_mat
				beacon.position = Vector3(tower_x, tower_y + 43.0, tower_z)
				add_child(beacon)

				# Floating Holographic Billboard on building front
				if (chunk_index % 3 == 0):
					var ad_board := MeshInstance3D.new()
					var ad_box := BoxMesh.new()
					ad_box.size = Vector3(10.0, 5.0, 0.3)
					ad_board.mesh = ad_box
					ad_board.material_override = neon_billboard_mat
					ad_board.position = Vector3(tower_x - side * 3.0, tower_y + 16.0, tower_z + 2.0)
					add_child(ad_board)

					# Billboard neon frame trim
					var ad_frame := MeshInstance3D.new()
					var af_box := BoxMesh.new()
					af_box.size = Vector3(10.4, 5.4, 0.2)
					ad_frame.mesh = af_box
					ad_frame.material_override = neon_purple_mat
					ad_frame.position = Vector3(tower_x - side * 3.0, tower_y + 16.0, tower_z + 1.8)
					add_child(ad_frame)

		# Layer 2: Flying Sky Corridor Hover Speeders
		if (chunk_index + 1) % 3 == 0:
			var speeder: Node3D = AssetLoader.get_model("speeder")
			if speeder:
				var sp_x: float = side * (20.0 + float((chunk_index * 5) % 10))
				var sp_y: float = 8.0 + sin(float(chunk_index) * 1.5) * 3.0
				var sp_z: float = -CHUNK_LENGTH * 0.5
				speeder.scale = Vector3(2.2, 2.2, 2.2)
				speeder.position = Vector3(sp_x, sp_y, sp_z)
				if side < 0:
					speeder.rotation.y = PI
				add_child(speeder)

				# Neon Headlight Glow on Speeder
				var headlight := MeshInstance3D.new()
				var hl_box := BoxMesh.new()
				hl_box.size = Vector3(0.8, 0.15, 0.15)
				headlight.mesh = hl_box
				headlight.material_override = neon_cyan_mat
				var hl_z: float = sp_z - (1.2 if side >= 0 else -1.2)
				headlight.position = Vector3(sp_x, sp_y + 0.2, hl_z)
				add_child(headlight)

				# Neon Engine Exhaust Glow on Speeder
				var exhaust := MeshInstance3D.new()
				var ex_box := BoxMesh.new()
				ex_box.size = Vector3(0.6, 0.15, 0.2)
				exhaust.mesh = ex_box
				exhaust.material_override = neon_amber_mat
				var ex_z: float = sp_z + (1.2 if side >= 0 else -1.2)
				exhaust.position = Vector3(sp_x, sp_y + 0.2, ex_z)
				add_child(exhaust)

func _build_hazards_and_collectibles(player_dist: float) -> void:
	var lane_coords: Array[float] = [-LANE_WIDTH, 0.0, LANE_WIDTH]

	# Chunks 0 and 1 are a peaceful runway start (no obstacles)
	if chunk_index <= 1:
		for i in range(4):
			var core = CollectibleScript.create(CollectibleScript.CollectibleType.DATA_CORE)
			core.position = Vector3(0.0, 0.9, -15.0 + float(i) * 7.5)
			add_child(core)
		return

	# Difficulty calculation (every 10,000m increases the tier)
	var tier: int = int(player_dist / 10000.0)

	# Decide hazard rows for this chunk
	# Tier 0 (0-10k): 1 hazard row (at Z = -10.0)
	# Tier 1 (10k-20k): 1 guaranteed row at Z = -10.0, 60% chance of 2nd row at Z = 10.0
	# Tier 2+ (20k+): 2 guaranteed rows at Z = -10.0 and Z = 10.0
	var hazard_z_list: Array[float] = [-10.0]
	if tier >= 2:
		hazard_z_list.append(10.0)
	elif tier >= 1 and randf() < 0.6:
		hazard_z_list.append(10.0)

	for hz_z: float in hazard_z_list:
		_spawn_hazard_row(hz_z, tier, lane_coords)

	# Spawn Data Cores & Power-Ups along open routes
	_spawn_collectibles_row(tier, lane_coords)

func _spawn_hazard_row(z_pos: float, tier: int, lane_coords: Array[float]) -> void:
	# Golden Rule: Never block all 3 lanes with impassable obstacles!
	var safe_lane_idx: int = randi() % 3
	var other_lanes: Array[int] = []
	for i in range(3):
		if i != safe_lane_idx:
			other_lanes.append(i)

	if tier == 0:
		# Tier 0 (0 - 10k): 1 obstacle, 2 completely open lanes
		var obs_lane: int = other_lanes[randi() % other_lanes.size()]
		var obs_type = ObstacleScript.ObstacleType.LOW_HURDLE
		var roll: float = randf()
		if roll < 0.38:
			obs_type = ObstacleScript.ObstacleType.LOW_HURDLE # Jump
		elif roll < 0.72:
			obs_type = ObstacleScript.ObstacleType.HIGH_GATE # Slide
		else:
			obs_type = ObstacleScript.ObstacleType.SOLID_BARRIER # Switch lane

		var obs = ObstacleScript.create(obs_type)
		obs.position = Vector3(lane_coords[obs_lane], 0.0, z_pos)
		add_child(obs)

		# If low hurdle, spawn jump arc of data cores over it to guide player!
		if obs_type == ObstacleScript.ObstacleType.LOW_HURDLE and randf() < 0.65:
			for k in range(3):
				var core = CollectibleScript.create(CollectibleScript.CollectibleType.DATA_CORE)
				var arc_y: float = 1.1 if (k != 1) else 1.85
				core.position = Vector3(lane_coords[obs_lane], arc_y, z_pos - 3.0 + float(k) * 3.0)
				add_child(core)

	else:
		# Tier 1+ (10k+): Multi-lane hazard combinations!
		for lane_idx: int in other_lanes:
			var roll: float = randf()
			var obs_type = ObstacleScript.ObstacleType.LOW_HURDLE
			if roll < 0.35:
				obs_type = ObstacleScript.ObstacleType.LOW_HURDLE
			elif roll < 0.70:
				obs_type = ObstacleScript.ObstacleType.HIGH_GATE
			else:
				obs_type = ObstacleScript.ObstacleType.SOLID_BARRIER

			var obs = ObstacleScript.create(obs_type)
			obs.position = Vector3(lane_coords[lane_idx], 0.0, z_pos)
			add_child(obs)

func _spawn_collectibles_row(tier: int, lane_coords: Array[float]) -> void:
	var c_lane: int = randi() % 3
	var lane_x: float = lane_coords[c_lane]

	# 1. Power-Up Spawn Chance (25% per chunk)
	if randf() < 0.25:
		var p_roll: float = randf()
		var p_type = CollectibleScript.CollectibleType.SHIELD
		if p_roll < 0.40:
			p_type = CollectibleScript.CollectibleType.SHIELD
		elif p_roll < 0.72:
			p_type = CollectibleScript.CollectibleType.MAGNET
		else:
			p_type = CollectibleScript.CollectibleType.OVERDRIVE

		var powerup = CollectibleScript.create(p_type)
		powerup.position = Vector3(lane_x, 1.0, 0.0)
		add_child(powerup)

	# 2. Data Core string (3 crystals in line)
	elif randf() < 0.50:
		for i in range(3):
			var core = CollectibleScript.create(CollectibleScript.CollectibleType.DATA_CORE)
			core.position = Vector3(lane_x, 0.9, -6.0 + float(i) * 5.0)
			add_child(core)
