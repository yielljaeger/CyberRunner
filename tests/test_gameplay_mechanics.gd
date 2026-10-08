extends SceneTree

const ObstacleScript = preload("res://scripts/obstacle.gd")
const CollectibleScript = preload("res://scripts/collectible.gd")
const TrackChunkScript = preload("res://scripts/track_chunk.gd")

func _init() -> void:
	print("--- BEGIN GAMEPLAY VERIFICATION TEST ---")
	test_obstacle_creation()
	test_collectible_creation()
	test_difficulty_tier_chunk_generation()
	print("--- ALL VERIFICATION TESTS PASSED SUCCESSFULLY! ---")
	quit(0)

func test_obstacle_creation() -> void:
	print("[TEST] Testing obstacle creation...")
	var low = ObstacleScript.create(ObstacleScript.ObstacleType.LOW_HURDLE)
	assert(low != null, "Low hurdle should be created")
	assert(low.name == "LowHurdle", "Obstacle name should match")
	assert(low.collision_layer == 4, "Collision layer should be 4 (obstacles)")
	low.free()

	var high = ObstacleScript.create(ObstacleScript.ObstacleType.HIGH_GATE)
	assert(high != null, "High gate should be created")
	assert(high.name == "HighGate", "High gate name should match")
	high.free()

	var solid = ObstacleScript.create(ObstacleScript.ObstacleType.SOLID_BARRIER)
	assert(solid != null, "Solid barrier should be created")
	assert(solid.name == "SolidBarrier", "Solid barrier name should match")
	solid.free()
	print("[PASS] Obstacles created correctly.")

func test_collectible_creation() -> void:
	print("[TEST] Testing collectible creation...")
	var core = CollectibleScript.create(CollectibleScript.CollectibleType.DATA_CORE)
	assert(core != null, "Data core should be created")
	assert(core.is_in_group("collectible"), "Data core should be in collectible group")
	assert(core.collision_layer == 8, "Collectible collision layer should be 8")
	core.free()

	var shield = CollectibleScript.create(CollectibleScript.CollectibleType.SHIELD)
	assert(shield != null, "Shield should be created")
	shield.free()

	var overdrive = CollectibleScript.create(CollectibleScript.CollectibleType.OVERDRIVE)
	assert(overdrive != null, "Overdrive should be created")
	overdrive.free()

	var magnet = CollectibleScript.create(CollectibleScript.CollectibleType.MAGNET)
	assert(magnet != null, "Magnet should be created")
	magnet.free()
	print("[PASS] Collectibles created correctly.")

func test_difficulty_tier_chunk_generation() -> void:
	print("[TEST] Testing chunk generation at different distance tiers...")
	# Chunk 0 (Peaceful start)
	var chunk0 = TrackChunkScript.new()
	chunk0.setup_chunk(0, false, 0.0)
	var chunk0_obstacles = 0
	var chunk0_collectibles = 0
	for child in chunk0.get_children():
		if child.is_in_group("collectible"):
			chunk0_collectibles += 1
		elif child is ObstacleScript:
			chunk0_obstacles += 1
	assert(chunk0_obstacles == 0, "Chunk 0 should have 0 obstacles")
	assert(chunk0_collectibles > 0, "Chunk 0 should have runway data cores")
	chunk0.free()

	# Tier 0 (e.g. at 500m)
	var chunk_t0 = TrackChunkScript.new()
	chunk_t0.setup_chunk(5, false, 500.0)
	var t0_obstacles = 0
	for child in chunk_t0.get_children():
		if child is ObstacleScript:
			t0_obstacles += 1
	assert(t0_obstacles == 1, "Tier 0 chunk should have exactly 1 obstacle (2 lanes open)")
	chunk_t0.free()

	# Tier 1 (e.g. at 12,000m)
	var chunk_t1 = TrackChunkScript.new()
	chunk_t1.setup_chunk(300, false, 12000.0)
	var t1_obstacles = 0
	for child in chunk_t1.get_children():
		if child is ObstacleScript:
			t1_obstacles += 1
	assert(t1_obstacles >= 2, "Tier 1 chunk should have at least 2 obstacles (multi-lane challenge)")
	chunk_t1.free()

	print("[PASS] Difficulty tier chunk generation behaves as expected.")
