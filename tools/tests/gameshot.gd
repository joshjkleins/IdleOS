extends Node
## 2026-11-06: screenshot of the main game (OUT = png path) for resolution / scale checks
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var sc = float(OS.get_environment("UISCALE")) if OS.get_environment("UISCALE") != "" else 0.0
	if sc > 0.0:
		get_window().content_scale_factor = sc
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 90: await get_tree().process_frame
	var vp = get_viewport().get_visible_rect().size
	print(">>> window %s  virtual %s  scale %.2f" % [DisplayServer.window_get_size(), vp, get_window().content_scale_factor])
	get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT"))
	get_tree().quit()
