extends Node3D

# Chunk-based procedural terrain for 3D open world
# Generates ground tiles around the player as they move

const CHUNK_SIZE := 30.0        # Units per chunk side
const RENDER_DIST := 3          # Chunks radius around player
const GRID := 12                # Sub-divisions per chunk (12x12 tiles)
const TILE_SIZE := CHUNK_SIZE / float(GRID)

var player: CharacterBody3D
var chunks: Dictionary = {}     # key: String(chunk_x,chunk_z) -> Node3D

# Simple seeded hash for deterministic terrain
func _hash(x: int, z: int) -> float:
	var n := float(x * 374761393 + z * 668265263)
	n = fmod(n, 4294967296.0)
	var result := sin(n) * 43758.5453123
	# fract() equivalent in GDScript
	result = result - floor(result)
	if result < 0:
		result += 1.0
	return result

func _interpolate_noise(x: float, z: float) -> float:
	var ix := floori(x)
	var iz := floori(z)
	var fx := x - float(ix)
	var fz := z - float(iz)
	# Smoothstep
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)

	var n00: float = _hash(ix, iz)
	var n10: float = _hash(ix + 1, iz)
	var n01: float = _hash(ix, iz + 1)
	var n11: float = _hash(ix + 1, iz + 1)

	var nx0: float = lerp(n00, n10, fx)
	var nx1: float = lerp(n01, n11, fx)
	return lerp(nx0, nx1, fz)

func terrain_height(x: float, z: float) -> float:
	# Multi-octave noise for natural-looking terrain
	var height := 0.0
	height += _interpolate_noise(x * 0.05, z * 0.05) * 6.0
	height += _interpolate_noise(x * 0.1, z * 0.1) * 3.0
	height += _interpolate_noise(x * 0.2, z * 0.2) * 1.5
	return maxf(height - 5.0, 0.0)  # Clamp minimum to 0

func height_color(h: float) -> Color:
	if h < 1.0:
		return Color(0.12, 0.56, 1.0)   # Water (blue)
	elif h < 2.5:
		return Color(0.13, 0.78, 0.36)  # Grass (green)
	elif h < 4.5:
		return Color(0.52, 0.8, 0.09)   # Hills (lime)
	elif h < 6.5:
		return Color(0.64, 0.64, 0.64)  # Rock (gray)
	else:
		return Color(1.0, 1.0, 1.0)     # Snow (white)

func _chunk_key(cx: int, cz: int) -> String:
	return str(cx) + "," + str(cz)

func create_chunk(cx: int, cz: int) -> Node3D:
	var chunk := Node3D.new()
	chunk.name = "Chunk_" + _chunk_key(cx, cz)

	# Each chunk is a StaticBody3D so collisions actually work
	var static_body := StaticBody3D.new()
	static_body.name = "Collisions"
	chunk.add_child(static_body)

	var chunk_offset_x := float(cx) * CHUNK_SIZE
	var chunk_offset_z := float(cz) * CHUNK_SIZE

	for tx in range(GRID):
		for tz in range(GRID):
			var world_x := chunk_offset_x + float(tx) * TILE_SIZE
			var world_z := chunk_offset_z + float(tz) * TILE_SIZE
			var h := terrain_height(world_x, world_z)
			var tile_h := maxf(h, 0.5)

			# Create collision shape under StaticBody3D (this is the key fix!)
			var col := CollisionShape3D.new()
			col.position = Vector3(
				world_x + TILE_SIZE / 2.0,
				tile_h / 2.0,
				world_z + TILE_SIZE / 2.0
			)
			var col_shape := BoxShape3D.new()
			col_shape.size = Vector3(TILE_SIZE - 0.1, tile_h, TILE_SIZE - 0.1)
			col.shape = col_shape
			static_body.add_child(col)

			# Create tile mesh (visual only, separate from physics)
			var tile := MeshInstance3D.new()
			tile.position = Vector3(
				world_x + TILE_SIZE / 2.0,
				h,
				world_z + TILE_SIZE / 2.0
			)

			var box := BoxMesh.new()
			box.size = Vector3(TILE_SIZE - 0.1, tile_h, TILE_SIZE - 0.1)
			tile.mesh = box

			var mat := StandardMaterial3D.new()
			mat.albedo_color = height_color(h)
			mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			tile.material_override = mat

			chunk.add_child(tile)

	add_child(chunk)
	return chunk

func update_terrain():
	if player == null:
		return

	var px := player.global_position.x
	var pz := player.global_position.z

	var current_cx := floori(px / CHUNK_SIZE)
	var current_cz := floori(pz / CHUNK_SIZE)

	# Determine which chunks should exist
	var needed: Dictionary = {}
	for dx in range(-RENDER_DIST, RENDER_DIST + 1):
		for dz in range(-RENDER_DIST, RENDER_DIST + 1):
			var cx := current_cx + dx
			var cz := current_cz + dz
			var key := _chunk_key(cx, cz)
			needed[key] = true

	# Remove chunks that are too far away
	var keys_to_remove: Array[String] = []
	for key in chunks:
		if not needed.has(key):
			keys_to_remove.append(key as String)

	for key in keys_to_remove:
		var chunk_node = chunks[key]
		if chunk_node:
			chunk_node.queue_free()
		chunks.erase(key)

	# Add new chunks
	for key in needed:
		if not chunks.has(key):
			var parts: PackedStringArray = key.split(",")
			var cx := int(parts[0])
			var cz := int(parts[1])
			chunks[key] = create_chunk(cx, cz)

func _ready():
	# Find the player node
	player = get_parent().get_node_or_null("Player") as CharacterBody3D
	if player:
		update_terrain()

var last_update_pos := Vector2i(0, 0)

func _process(_delta):
	if player == null:
		return

	var current_cx := floori(player.global_position.x / CHUNK_SIZE)
	var current_cz := floori(player.global_position.z / CHUNK_SIZE)
	var current_pos := Vector2i(current_cx, current_cz)

	# Only update when player crosses a chunk boundary
	if current_pos != last_update_pos:
		last_update_pos = current_pos
		update_terrain()
