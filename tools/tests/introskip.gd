extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _key(code: int) -> void:
	var ev = InputEventKey.new(); ev.keycode = code; ev.pressed = true
	Input.parse_input_event(ev)
func _state() -> String:
	var hidden = []
	for c in os.system_dock.full_view.get_children():
		if c is CanvasItem and c.modulate.a < 0.99: hidden.append("%s=%.2f" % [c.name, c.modulate.a])
	return "dock a=%.2f hidden sections=%s input_visible=%s header=%s show_intro=%s accepting=%s" % [os.system_dock.modulate.a, hidden, os.input_line_container.visible, os.header.visible, Tutorial.show_intro, os.accepting_player_inputs]
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	if OS.get_environment("MODE") == "existing":
		for i in 30: await get_tree().process_frame
		print(">>> existing save: ", _state())
		get_tree().quit(); return
	var t0 = Time.get_ticks_msec()
	for i in 30: await get_tree().process_frame
	_key(KEY_SPACE) # skip typing
	while !os.accepting_player_inputs: await get_tree().process_frame
	print(">>> typing skipped after %.2fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	_key(KEY_ENTER)
	var t1 = Time.get_ticks_msec()
	for i in 30: await get_tree().process_frame
	_key(KEY_A) # skip boot
	while Tutorial.show_intro: await get_tree().process_frame
	print(">>> boot skipped after %.2fs" % ((Time.get_ticks_msec() - t1) / 1000.0))
	for i in 60: await get_tree().process_frame
	print(">>> end: ", _state(), " input text='", os.input_line.text, "'")
	get_tree().quit()
