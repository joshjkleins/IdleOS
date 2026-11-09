extends Node
## 2026-11-09: Escape opens settings in the main terminal, Escape again closes it; not in Hacking
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _esc() -> void:
	var e = InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	Input.parse_input_event(e)
	var u = InputEventKey.new()
	u.keycode = KEY_ESCAPE
	u.pressed = false
	Input.parse_input_event(u)
	await _f(5)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	await _esc()
	print(">>> after esc: open %s" % is_instance_valid(os._settings_popup))
	await _esc()
	print(">>> after esc again: open %s" % is_instance_valid(os._settings_popup))
	os._on_input_line_text_submitted("settings")
	await _f(5)
	print(">>> 'settings' cmd: open %s" % is_instance_valid(os._settings_popup))
	await _esc()
	print(">>> esc closes it: open %s" % is_instance_valid(os._settings_popup))
	for e in Tutorial.steps():
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	os._on_input_line_text_submitted("cd hacking")
	var t0 = Time.get_ticks_msec()
	while !os.hacking.is_in_hacking_context and Time.get_ticks_msec() - t0 < 20000:
		await get_tree().process_frame
	await _f(30)
	await _esc()
	print(">>> in hacking, esc: open %s" % is_instance_valid(os._settings_popup))
	get_tree().quit()
