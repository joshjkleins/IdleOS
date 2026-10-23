extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	print("streams: ", Audiomanager._music_streams.keys(), " lengths: ", Audiomanager._music_streams.values().map(func(s): return int(s.get_length())))
	print("playing: ", Audiomanager.current_track, " | ", _strip(Audiomanager.now_playing_text()))
	var first = Audiomanager.current_track
	Audiomanager._active_music.seek(Audiomanager._active_music.stream.get_length() - 2.0)
	for i in 30: await get_tree().process_frame
	print("after end: ", Audiomanager.current_track, " (was ", first, ")")
	os._on_input_line_text_submitted("music off")
	for i in 10: await get_tree().process_frame
	print("off: enabled=%s playlist=%s track='%s' saved=%s" % [Audiomanager.music_enabled, Audiomanager.playlist_on, Audiomanager.current_track, Settings.get_value("music_player")])
	os._on_input_line_text_submitted("music on")
	for i in 10: await get_tree().process_frame
	print("on: ", Audiomanager.current_track, " playlist=", Audiomanager.playlist_on)
	os._on_input_line_text_submitted("music next")
	for i in 10: await get_tree().process_frame
	print("next: ", Audiomanager.current_track)
	get_tree().quit()
