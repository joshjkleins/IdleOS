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
	for e in [Tutorial.TutorialEvent.RUN_HELP_COMMAND, Tutorial.TutorialEvent.NAVIGATE_HACKING, Tutorial.TutorialEvent.VIEW_SCHOOL, Tutorial.TutorialEvent.HACK_STUDENT, Tutorial.TutorialEvent.RETURN_TO_ROOT, Tutorial.TutorialEvent.DECODE_1_STUDENT_CACHE, Tutorial.TutorialEvent.LIST_ITEMS, Tutorial.TutorialEvent.NAVIGATE_PARSING]:
		Tutorial.completed_events.append(e)
	Tutorial.complete_event(Tutorial.TutorialEvent.OBTAIN_3_IP_ADDRESSES)
	for i in 30: await get_tree().process_frame
	var w = os.tutorial_window
	var before = w.position
	var down = InputEventMouseButton.new(); down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true
	Input.warp_mouse(w.global_position + Vector2(20, 8))
	w._dragging = true; w._drag_offset = Vector2(20, 8)
	var mv = InputEventMouseMotion.new()
	# simulate: move the window 300 px left / 400 down by setting the mouse target through the handler
	w.global_position = before + Vector2(-300, 400); Tutorial.window_moved = true; Tutorial.window_pos = w.position; w._clamp_to_host()
	w._dragging = false
	w._dock()
	print(">>> moved from %s to %s (moved=%s); after _dock stays: %s" % [before, w.position, Tutorial.window_moved, w.position])
	await _shot("tut_drag")
	var d = Tutorial.save_data()
	print(">>> saved window_pos ", d.window_pos)
	var dbl = InputEventMouseButton.new(); dbl.button_index = MOUSE_BUTTON_LEFT; dbl.pressed = true; dbl.double_click = true
	w._on_title_input(dbl)
	print(">>> after double-click: %s (moved=%s)" % [w.position, Tutorial.window_moved])
	get_tree().quit()
