extends SceneTree

const AudioManagerScript = preload("res://scripts/audio_manager.gd")

func _init() -> void:
	print("--- TESTING AUDIO MANAGER SYSTEM ---")
	var audio_mgr = AudioManagerScript.new()
	audio_mgr._ready()

	assert(audio_mgr.music_player != null, "Music player must exist")
	print("[PASS] Background music initialized.")

	# Test SFX pool
	audio_mgr.on_jump()
	audio_mgr.on_data_core_collected()
	audio_mgr.on_data_core_collected()
	assert(audio_mgr.core_streak == 2, "Core streak should be 2")
	print("[PASS] Core streak combo counter works: ", audio_mgr.core_streak)

	# Test Powerups
	audio_mgr.on_powerup_collected(1) # Shield
	audio_mgr.on_powerup_collected(2) # Overdrive
	audio_mgr.on_powerup_collected(3) # Magnet
	print("[PASS] Powerup sounds triggered.")

	# Test Slide loop
	audio_mgr.on_slide_started()
	assert(audio_mgr.is_sliding, "Slide state should be active")
	audio_mgr.on_slide_ended()
	assert(not audio_mgr.is_sliding, "Slide state should be ended")
	print("[PASS] Slide audio state toggling works.")

	# Test Boost audio
	audio_mgr.on_nitro_intensity(1.0)
	assert(audio_mgr.target_boost_volume > -30.0, "Boost target volume should increase")
	audio_mgr.on_nitro_intensity(0.0)
	assert(audio_mgr.target_boost_volume == -80.0, "Boost target volume should silence on 0 intensity")
	print("[PASS] Nitrous boost audio intensity modulation works.")

	# Test Obstacle Smash and Shield Absorb
	audio_mgr.on_shield_absorbed()
	audio_mgr.on_obstacle_smashed()
	print("[PASS] Smash and Shield sounds triggered.")

	# Test Tier Up Fanfare
	audio_mgr.on_tier_updated(1, 2.0)
	print("[PASS] Tier Up Fanfare triggered.")

	# Test Game Over
	audio_mgr.on_player_crashed()
	assert(audio_mgr.is_game_over, "Game over state should be true")
	print("[PASS] Game over audio state and power-down triggered.")

	audio_mgr.free()
	print("--- ALL AUDIO MANAGER TESTS PASSED SUCCESSFULLY! ---")
	quit(0)
