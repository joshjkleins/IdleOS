extends Node
## 2026-11-14: the system panel shows the main process's modifier (OUT = png prefix)
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _shot(name: String) -> void:
	var img = get_viewport().get_texture().get_image()
	var w = img.get_width()
	img.get_region(Rect2i(w - 420, 100, 420, 150)).save_png(OS.get_environment("OUT") + name + ".png")
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	for e in Tutorial.steps():
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	for id in ["mining.sift", "mining.overclock"]: Upgrades.packages[id].installed = 1
	if os.process_running: os.kill_main_process()
	await _f(10)
	os._on_input_line_text_submitted("mine -logs sift")
	await _f(40)
	var st = get_tree().root.find_child("SystemTemp", true, false)
	print(">>> sift: running %s  modifier %s" % [os.process_running, os.current_process.modifier.get("command", "") if os.current_process else "-"])
	await _shot("_sift")
	os.current_process.modifier = Mining.MODIFIERS[1] # prospect: the longest name
	Stats.overclocked = true
	await _f(30)
	await _shot("_sift_oc")
	get_tree().quit()
