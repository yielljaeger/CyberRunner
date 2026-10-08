extends SceneTree

func _init() -> void:
	print("--- TESTING AUDIO LOADING & PROPERTIES ---")
	var music_path = "res://assets/audio/cyberpunk_music.ogg"
	var music = AudioStreamOggVorbis.load_from_file(music_path)
	print("Loaded Music: ", music, " valid? ", music != null)
	if music:
		music.loop = true
		print("Music length: ", music.get_length(), " loop property: ", music.loop)

	quit(0)
