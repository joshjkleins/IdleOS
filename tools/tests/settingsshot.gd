extends Node
## 2026-11-02: settings popup in-game ('settings'), a slider + toggle change, Esc closes and the input gets focus back
func _ready() -> void:
	_run.call_deferred()
func _f(n := 10) -> void:
	for i in n: await get_tree().process_frame
func _run() -> void:
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f(30)
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("settings")
	await _f()
	var p = get_tree().root.find_children("*", "SettingsPopup", true, false)
	print(">>> popup open: ", p.size())
	var before = Settings.get_value("music")
	var sl = p[0].find_children("*", "HSlider", true, false)
	sl[2].value = 35
	print(">>> music %s -> %s" % [before, Settings.get_value("music")])
	await _f()
	get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT"))
	Settings.set_value("music", str(before))
	var ev = InputEventKey.new(); ev.keycode = KEY_ESCAPE; ev.pressed = true
	Input.parse_input_event(ev)
	await _f()
	print(">>> after esc: popups %d, input focused %s" % [get_tree().root.find_children("*", "SettingsPopup", true, false).size(), os.input_line.has_focus()])
	get_tree().quit()
