extends Node
## Screens of 'flow' and 'info compiling school' as posted in the terminal.
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
	for i in 30: await get_tree().process_frame
	os.accepting_player_inputs = true
	Offline.report = {}
	Inventory.add_resource(Items.LOGS, 1234)
	Inventory.add_resource(Items.USERNAMES, 3)
	for c in ["clear", "flow"]:
		os._on_input_line_text_submitted(c)
		for i in 90: await get_tree().process_frame
	await _shot("flow_loop")
	for c in ["clear", "info compiling school"]:
		os._on_input_line_text_submitted(c)
		for i in 240: await get_tree().process_frame
	await _shot("flow_recipe")
	for c in ["clear", "info compiling lawfirm"]:
		os._on_input_line_text_submitted(c)
		for i in 240: await get_tree().process_frame
	await _shot("flow_recipe2")
	print(">>> done")
	get_tree().quit()
