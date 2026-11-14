extends Node
## 2026-11-14: main terminal <-> Hacking transition time: full (tutorial), short, instant
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _round_trip(label: String) -> void:
	var t0 = Time.get_ticks_msec()
	os._on_input_line_text_submitted("cd hacking")
	while !os.hacking.is_in_hacking_context:
		await get_tree().process_frame
	var t1 = Time.get_ticks_msec()
	os.hacking.go_to_root()
	while !os.terminal_root.visible or os.terminal_root.modulate.a < 0.99:
		await get_tree().process_frame
	var t2 = Time.get_ticks_msec()
	print(">>> %-8s to hacking %.2fs   back %.2fs" % [label, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0])
	await _f(10)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	var keep_tut = Tutorial.completed_events.duplicate()
	var keep = Settings.get_value("hack_transition")
	Tutorial.completed_events.clear()
	await _round_trip("full")
	for e in Tutorial.steps():
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	Settings.values["hack_transition"] = "short"
	await _round_trip("short")
	Settings.values["hack_transition"] = "instant"
	await _round_trip("instant")
	Settings.values["hack_transition"] = keep
	Tutorial.completed_events = keep_tut
	get_tree().quit()
