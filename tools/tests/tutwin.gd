extends Node
## Tutorial window: first page, a completed step (banner + next page), prev/next, fold, close/reopen.
var os
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/%s.png" % name)
func _cmd(c: String, frames: int = 60) -> void:
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	var w = os.tutorial_window
	print("visible=", w.visible, " page=", w.page, " pos=", w.position, " size=", w.size)
	await _shot("tut_1")
	await _cmd("-h", 90)
	print("after -h page=", w.page, " banner=", w._banner.visible)
	await _shot("tut_2")
	await _cmd("cd mining")
	await _cmd("mine -logs", 300)
	print("progress page=", w.page, " text=", w._body.get_parsed_text().substr(0, 80))
	await _shot("tut_3")
	w.show_page(w.page + 2)
	for i in 10: await get_tree().process_frame
	await _shot("tut_upcoming")
	w.set_folded(true)
	for i in 10: await get_tree().process_frame
	await _shot("tut_folded")
	w.close()
	await _cmd("tutorial")
	print("reopen visible=", w.visible)
	print(">>> done")
	get_tree().quit()
