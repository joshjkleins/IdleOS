extends Node
## 2026-11-06: 'windowed' from full screen ends up a real window (85% of the screen), and back
func _ready() -> void:
	_run.call_deferred()
func _p(tag: String) -> void:
	print(">>> %s: mode %d  size %s  screen %s  virtual %s" % [tag, DisplayServer.window_get_mode(), DisplayServer.window_get_size(), DisplayServer.screen_get_size(), get_viewport().get_visible_rect().size])
func _run() -> void:
	var keep = Settings.get_value("window_mode")
	for i in 10: await get_tree().process_frame
	_p("start")
	Settings.set_value("window_mode", "windowed")
	for i in 40: await get_tree().process_frame
	_p("windowed")
	Settings.set_value("window_mode", "full_screen")
	for i in 20: await get_tree().process_frame
	_p("full screen")
	Settings.set_value("window_mode", keep)
	get_tree().quit()
