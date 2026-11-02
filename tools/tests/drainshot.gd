extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().get_region(Rect2i(0, 0, 900, 60)).save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/drain_%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("tutorial complete"); await _secs(1.0)
	Stats.unlock_location("Lawfirm"); Exp.refresh_all_process_unlocks()
	os._on_input_line_text_submitted("cd mining"); await _secs(1.5)
	os._on_input_line_text_submitted("mine -logs"); await _secs(1.5)
	Flush.charge["Mining/Logs"] = Flush.FILL_SECONDS
	await _secs(1.5)
	await _shot("0_full")
	os._on_input_line_text_submitted("flush")
	await _secs(0.25); await _shot("1")
	await _secs(0.35); await _shot("2")
	await _secs(0.6); await _shot("3_end")
	get_tree().quit()
