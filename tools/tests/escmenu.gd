extends Node
## 2026-11-09: Escape on the profile screen opens settings, Escape again closes it
func _ready() -> void:
	_run.call_deferred()
func _esc() -> void:
	var e = InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	Input.parse_input_event(e)
	var u = InputEventKey.new()
	u.keycode = KEY_ESCAPE
	Input.parse_input_event(u)
	for i in 5: await get_tree().process_frame
func _run() -> void:
	var l = load("res://scenes/launcher.tscn").instantiate()
	add_child(l)
	for i in 10: await get_tree().process_frame
	while l._booting: await get_tree().process_frame
	for i in 10: await get_tree().process_frame
	print(">>> focus on input: %s" % l._input_line.has_focus())
	await _esc()
	print(">>> esc: modal %s" % (l._modal != null and l._modal is SettingsPopup))
	await _esc()
	print(">>> esc again: modal %s" % (l._modal != null))
	l._open_new(2)
	for i in 5: await get_tree().process_frame
	await _esc()
	print(">>> esc on the new-profile box closes it, no settings: modal %s" % (l._modal != null))
	get_tree().quit()
