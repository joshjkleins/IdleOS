extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 90: await get_tree().process_frame
	os._on_input_line_text_submitted("-h")
	for i in 60: await get_tree().process_frame
	await _shot("tut_step2")
	os._on_input_line_text_submitted("cd hacking")
	for i in 300: await get_tree().process_frame
	await _shot("tut_hacking_step3")
	os.hacking.player_hacking_box._on_input_line_text_submitted("view school")
	for i in 200: await get_tree().process_frame
	await _shot("tut_hacking_step4")
	print(">>> done")
	get_tree().quit()
