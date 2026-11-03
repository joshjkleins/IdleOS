extends Node
## 2026-11-02: screenshot of the launcher (OUT env = png path; CMD env = a command typed first)
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var l = load("res://scenes/launcher.tscn").instantiate()
	add_child(l)
	for i in 60: await get_tree().process_frame
	if OS.get_environment("CMD") != "":
		l._on_submit(OS.get_environment("CMD"))
		for i in 10: await get_tree().process_frame
	if OS.get_environment("SEL") != "":
		l._select(int(OS.get_environment("SEL")))
		for i in 5: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT"))
	get_tree().quit()
