extends Node
## 2026-11-14: screenshot of 'apt <CMD>' in the main terminal (OUT png); CMD env = apt argument (default system)
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	for e in Tutorial.steps():
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	var arg = OS.get_environment("CMD") if OS.get_environment("CMD") != "" else "system"
	os._on_input_line_text_submitted("clear")
	await _f(5)
	os._on_input_line_text_submitted("apt " + arg)
	await _f(60)
	get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT"))
	get_tree().quit()
