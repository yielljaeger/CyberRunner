extends Node3D

const TrackChunkScript = preload("res://scripts/track_chunk.gd")

const CHUNK_LENGTH: float = 40.0
const INITIAL_CHUNKS: int = 8
const VIEW_DISTANCE_CHUNKS: int = 8
const DESPAWN_OFFSET: float = 60.0 # Distance behind player before despawn

var player: CharacterBody3D
var active_chunks: Array = []
var next_spawn_z: float = 0.0
var chunk_counter: int = 0

func _ready() -> void:
	if player == null:
		player = get_parent().get_node_or_null("Player") as CharacterBody3D

	next_spawn_z = 20.0
	for i in range(INITIAL_CHUNKS):
		_spawn_next_chunk()

func _process(_delta: float) -> void:
	if player == null:
		return

	var player_z: float = player.global_position.z

	# 1. Spawn chunks ahead
	while next_spawn_z > player_z - (VIEW_DISTANCE_CHUNKS * CHUNK_LENGTH):
		_spawn_next_chunk()

	# 2. Recycle / Despawn old chunks behind player
	while active_chunks.size() > 0:
		var oldest: Node3D = active_chunks[0] as Node3D
		if oldest and oldest.global_position.z > player_z + DESPAWN_OFFSET:
			active_chunks.pop_front()
			oldest.queue_free()
		else:
			break

func _spawn_next_chunk() -> void:
	var chunk: Node3D = TrackChunkScript.new()
	chunk.name = "Chunk_%d" % chunk_counter
	add_child(chunk)

	var chunk_center_z: float = next_spawn_z - (CHUNK_LENGTH * 0.5)
	chunk.position = Vector3(0, 0, chunk_center_z)

	var spawn_arch: bool = (chunk_counter > 2 and chunk_counter % 3 == 0)
	var current_dist: float = abs(player.global_position.z) if player else 0.0
	chunk.setup_chunk(chunk_counter, spawn_arch, current_dist)

	active_chunks.append(chunk)

	next_spawn_z -= CHUNK_LENGTH
	chunk_counter += 1

func reset() -> void:
	for c in active_chunks:
		if is_instance_valid(c):
			c.queue_free()
	active_chunks.clear()
	chunk_counter = 0
	next_spawn_z = 20.0
	for i in range(INITIAL_CHUNKS):
		_spawn_next_chunk()
