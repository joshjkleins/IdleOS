extends Node
## 2026-11-14: player music folder - scan, a bad file, built-ins off, playlist picks the player's tracks
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var src = FileAccess.get_file_as_bytes("res://audio/sfx/vm_shutdown.mp3")
	if src.is_empty(): # imported resource: read the original via the globalized path
		src = FileAccess.get_file_as_bytes(ProjectSettings.globalize_path("res://audio/sfx/vm_shutdown.mp3"))
	DirAccess.make_dir_recursive_absolute("user://music")
	var f = FileAccess.open("user://music/My_Cool-Song.mp3", FileAccess.WRITE); f.store_buffer(src); f.close()
	f = FileAccess.open("user://music/broken.ogg", FileAccess.WRITE); f.store_string("not audio"); f.close()
	f = FileAccess.open("user://music/notes.txt", FileAccess.WRITE); f.store_string("ignored"); f.close()
	print(">>> folder %s  scan: %d tracks" % [Audiomanager.user_music_path(), Audiomanager.scan_user_music()])
	print(">>> playlist (built-ins on): %s" % [Audiomanager.playlist_tracks()])
	Settings.set_value("music_builtin", "off")
	print(">>> playlist (built-ins off): %s" % [Audiomanager.playlist_tracks()])
	Audiomanager.music_enabled = true
	Audiomanager.playlist_on = true
	Audiomanager._queue = ["user:broken.ogg", "user:My_Cool-Song.mp3"]
	Audiomanager._play_next_in_playlist(0.1)
	print(">>> now: %s  |  %s" % [Audiomanager.current_track, ContextCommands.strip_bbcode(Audiomanager.now_playing_text())])
	print(">>> %s" % ContextCommands.strip_bbcode(Audiomanager.playlist_text()))
	DirAccess.remove_absolute("user://music/My_Cool-Song.mp3")
	DirAccess.remove_absolute("user://music/broken.ogg")
	DirAccess.remove_absolute("user://music/notes.txt")
	print(">>> after emptying the folder: %d tracks, playlist %s (built-ins still off)" % [Audiomanager.scan_user_music(), Audiomanager.playlist_tracks()])
	Settings.set_value("music_builtin", "on")
	get_tree().quit()
