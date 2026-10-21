extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	os.accepting_player_inputs = true
	os.input_line.grab_focus()
	os.input_line.text = "cd mi"
	var ev = InputEventKey.new(); ev.keycode = KEY_TAB; ev.pressed = true
	Input.parse_input_event(ev)
	for i in 5: await get_tree().process_frame
	print("after tab: '%s' caret %d focus %s" % [os.input_line.text, os.input_line.caret_column, os.input_line.has_focus()])
	os.input_line.text = "mine -"
	Input.parse_input_event(ev)
	for i in 5: await get_tree().process_frame
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true; rt.text = os.current_scrollback.text
	print("listed: ", rt.get_parsed_text())
	get_tree().quit()
