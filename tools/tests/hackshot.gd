extends Node
## 2026-11-06: the hacking screen at a location (OUT png): box title vs targets panel position
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
	var loc = OS.get_environment("LOC") if OS.get_environment("LOC") != "" else "school"
	for k in Stats.hacking_targets:
		if str(Stats.hacking_targets[k].name).to_lower() == loc:
			Stats.hacking_targets[k].unlocked = true
	os._on_input_line_text_submitted("cd hacking/" + loc)
	var t0 = Time.get_ticks_msec()
	while !os.hacking.is_in_hacking_context and Time.get_ticks_msec() - t0 < 20000:
		await get_tree().process_frame
	await _f(90)
	var hb = os.hacking.find_child("HackingBox", true, false)
	var panel = hb.get_node("PanelContainer")
	print(">>> virtual %s  box y %.0f h %.0f  panel y %.0f h %.0f (min %.0f)  title y %.0f" % [get_viewport().get_visible_rect().size, hb.global_position.y, hb.size.y, panel.global_position.y, panel.size.y, panel.get_combined_minimum_size().y, hb.rtl.global_position.y])
	# overflow check: make the cards taller than the box and see which way the panel grows
	panel.custom_minimum_size.y = hb.size.y + 200
	await _f(5)
	print(">>> forced overflow: box y %.0f  panel y %.0f  title y %.0f" % [hb.global_position.y, panel.global_position.y, hb.rtl.global_position.y])
	panel.custom_minimum_size.y = 0
	await _f(5)
	get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT"))
	get_tree().quit()
