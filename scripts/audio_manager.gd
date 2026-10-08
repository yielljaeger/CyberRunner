extends Node
class_name RunnerAudioManager

# Audio File Paths (CC0 / Public Domain Assets)
const SFX_PATHS := {
	"jump": "res://assets/audio/jump.ogg",
	"slide": "res://assets/audio/slide.ogg",
	"data_core": "res://assets/audio/data_core.ogg",
	"powerup": "res://assets/audio/powerup.ogg",
	"overdrive_start": "res://assets/audio/overdrive_start.ogg",
	"shield_break": "res://assets/audio/shield_break.ogg",
	"shield_deflect": "res://assets/audio/shield_deflect.ogg",
	"smash": "res://assets/audio/smash.ogg",
	"crash": "res://assets/audio/crash.ogg",
	"game_over": "res://assets/audio/game_over.ogg",
	"nitro_boost": "res://assets/audio/nitro_boost.ogg"
}

const MUSIC_PATH := "res://assets/audio/cyberpunk_music.ogg"

# Audio Streams Cache
var _streams: Dictionary = {}
var _music_stream: AudioStreamOggVorbis = null

# Dedicated Players
var music_player: AudioStreamPlayer
var slide_player: AudioStreamPlayer
var boost_player: AudioStreamPlayer

# One-Shot SFX Player Pool
var sfx_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 12
var _pool_index: int = 0

# Dynamic State
var is_sliding: bool = false
var target_boost_volume: float = -80.0
var current_boost_volume: float = -80.0
var core_streak: int = 0
var core_streak_timer: float = 0.0
var is_game_over: bool = false
var cached_tier: int = 0

func _ready() -> void:
	_load_audio_assets()
	_setup_audio_players()
	play_music()

func _load_audio_assets() -> void:
	for key in SFX_PATHS.keys():
		var path: String = SFX_PATHS[key]
		var stream = AudioStreamOggVorbis.load_from_file(path)
		if stream:
			_streams[key] = stream
		else:
			push_warning("Failed to load SFX: " + path)

	_music_stream = AudioStreamOggVorbis.load_from_file(MUSIC_PATH)
	if _music_stream:
		_music_stream.loop = true
	else:
		push_warning("Failed to load Cyberpunk Music: " + MUSIC_PATH)

func _setup_audio_players() -> void:
	# 1. Background Music Player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = -7.0
	music_player.bus = "Master"
	if _music_stream:
		music_player.stream = _music_stream
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	# 2. Slide Friction Looping Player
	slide_player = AudioStreamPlayer.new()
	slide_player.name = "SlidePlayer"
	slide_player.volume_db = -10.0
	slide_player.bus = "Master"
	if _streams.has("slide"):
		var slide_st: AudioStreamOggVorbis = _streams["slide"]
		slide_st.loop = true
		slide_player.stream = slide_st
	add_child(slide_player)

	# 3. Nitrous Thruster Boost Looping Player
	boost_player = AudioStreamPlayer.new()
	boost_player.name = "BoostPlayer"
	boost_player.volume_db = -80.0
	boost_player.bus = "Master"
	if _streams.has("nitro_boost"):
		var nitro_st: AudioStreamOggVorbis = _streams["nitro_boost"]
		nitro_st.loop = true
		boost_player.stream = nitro_st
	add_child(boost_player)
	if is_inside_tree():
		boost_player.play()

	# 4. One-Shot SFX Pool
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%02d" % i
		p.volume_db = 0.0
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)

func _process(delta: float) -> void:
	# 1. Update Core Collection Streak Timer
	if core_streak_timer > 0.0:
		core_streak_timer -= delta
		if core_streak_timer <= 0.0:
			core_streak = 0

	# 2. Smoothly Blend Nitrous Thruster Volume
	current_boost_volume = lerp(current_boost_volume, target_boost_volume, delta * 12.0)
	if boost_player:
		boost_player.volume_db = current_boost_volume

	# 3. Game Over Power-Down Pitch & Volume Drop
	if is_game_over and music_player:
		if music_player.pitch_scale > 0.4:
			music_player.pitch_scale = maxf(0.4, music_player.pitch_scale - delta * 0.7)
			music_player.volume_db = maxf(-35.0, music_player.volume_db - delta * 15.0)

# --- Music Controls ---

func play_music() -> void:
	if not is_inside_tree():
		return
	if music_player and _music_stream:
		music_player.pitch_scale = 1.0
		music_player.volume_db = -7.0
		music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func _on_music_finished() -> void:
	if not is_game_over and music_player and is_inside_tree():
		music_player.play()

# --- SFX Pool Player ---

func play_sfx(name: String, vol_offset: float = 0.0, pitch: float = 1.0) -> void:
	if not is_inside_tree():
		return
	if not _streams.has(name):
		return

	var stream = _streams[name]
	var player: AudioStreamPlayer = null

	# Find available player in pool
	for p in sfx_pool:
		if not p.playing:
			player = p
			break

	# Fallback to round-robin steal
	if player == null:
		player = sfx_pool[_pool_index]
		_pool_index = (_pool_index + 1) % POOL_SIZE

	player.stream = stream
	player.volume_db = vol_offset
	player.pitch_scale = pitch
	player.play()

# --- Gameplay Sound Event Hooks ---

func on_jump() -> void:
	play_sfx("jump", -2.0, randf_range(0.96, 1.05))

func on_slide_started() -> void:
	is_sliding = true
	if is_inside_tree() and slide_player and not slide_player.playing:
		slide_player.play()

func on_slide_ended() -> void:
	is_sliding = false
	if slide_player and slide_player.playing:
		slide_player.stop()

func on_data_core_collected() -> void:
	core_streak += 1
	core_streak_timer = 1.4
	# Ascending pitch scale for rewarding collection streaks
	var pitch: float = clampf(1.0 + float(core_streak) * 0.04, 1.0, 1.55)
	play_sfx("data_core", -3.0, pitch)

func on_powerup_collected(item_type: int) -> void:
	# Reset core streak
	core_streak_timer = 0.0
	match item_type:
		1: # Shield
			play_sfx("powerup", -1.0, 1.05)
		2: # Overdrive
			play_sfx("overdrive_start", +1.0, 1.0)
		3: # Magnet
			play_sfx("powerup", -1.0, 1.35)
		_:
			play_sfx("powerup", 0.0, 1.1)

func on_shield_absorbed() -> void:
	play_sfx("shield_deflect", 0.0, 1.0)
	play_sfx("shield_break", +1.0, 0.95)

func on_obstacle_smashed() -> void:
	play_sfx("smash", +2.0, randf_range(0.95, 1.08))

func on_nitro_intensity(factor: float) -> void:
	if is_game_over:
		target_boost_volume = -80.0
		return

	if factor > 0.05:
		target_boost_volume = lerpf(-24.0, -10.0, factor)
		if boost_player:
			boost_player.pitch_scale = lerpf(0.9, 1.25, factor)
	else:
		target_boost_volume = -80.0

func on_tier_updated(tier: int, multiplier: float) -> void:
	if tier > cached_tier:
		cached_tier = tier
		# Level Up announcement fanfare
		play_sfx("overdrive_start", +1.5, 1.25)
		play_sfx("powerup", +1.0, 1.4)

func on_player_crashed() -> void:
	is_game_over = true
	target_boost_volume = -80.0
	if slide_player:
		slide_player.stop()

	play_sfx("crash", +3.0, 0.95)
	play_sfx("game_over", +2.0, 1.0)

func stop_all() -> void:
	if music_player:
		music_player.stop()
	if slide_player:
		slide_player.stop()
	if boost_player:
		boost_player.stop()
	for p in sfx_pool:
		p.stop()
