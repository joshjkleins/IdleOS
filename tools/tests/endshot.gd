extends Node
## 2026-11-02: the ending cinematic, rendered: hack the normal President, force the win, screenshot each phase,
## answer CHOICE (lock / steal). Run with xvfb (see PROJECT_NOTES). ~70 s.
var os
var hk
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/end_%s.png" % name)
	print(">>> shot ", name)
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	Ending.dev_reset()
	Stats.unlock_location("Government")
	for t in Stats.hacking_targets["Government"].targets: Stats.unlock_target(t)
	Inventory.add_resource(Items.SQL_INJECTOR, 500); Inventory.add_resource(Items.PACKET_SPOOF, 100)
	Inventory.add_resource(Items.GOVERNMENT_PAYLOAD, 100)
	for c in ["tutorial complete", "cd hacking"]:
		os._on_input_line_text_submitted(c)
		for i in 60: await get_tree().process_frame
	hk = get_tree().root.find_children("*", "", true, false).filter(func(n): return n.has_method("handle_hack_command"))[0]
	if OS.get_environment("OUTRO") != "": # OUTRO=white|black: skip the fight + cinematic, test the outro and the notice
		Ending.choice = OS.get_environment("OUTRO"); Ending.state = Ending.OUTRO; Ending.choice_changed.emit()
		for i in 120: await get_tree().process_frame
		hk.go_to_root()
		await _secs(6.0); await _shot("o1_typing")
		var w = 0
		while !os._ending_wait_enter and w < 120:
			await _secs(0.5); w += 1
		await _shot("o2_enter")
		os._ending_wait_enter = false; os.ending_enter_pressed.emit()
		await _secs(3.0); await _shot("o3_congrats")
		print(">>> state ", Ending.state, " (4 = DONE)")
		get_tree().quit()
		return
	await hk.open_location("Government", false)
	for i in 400: await get_tree().process_frame
	hk.current_context = 1
	hk.handle_hack_command("hack president")
	for i in 300: await get_tree().process_frame
	var txt = hk.player_hacking_box.find_children("*", "RichTextLabel", true, false)
	for r in txt:
		var tt = r.get_parsed_text().strip_edges()
		if tt != "": print(">>> CON ", tt.right(400).replace("\n", " | "))
	var g = hk.enemy_hacking_box.hacking_game
	print(">>> hacking ", g.is_hacking, " target ", g.current_target.get("name"), " final ", Ending.is_final_target(g.current_target))
	g.integ_bar.value = 1
	g.win()
	await _secs(1.9); await _shot("1_glitch")
	await _secs(1.6); await _shot("2_glitch_late")
	await _secs(5.0); await _shot("3_grab")
	await _secs(6.0); await _shot("4_access")
	await _secs(7.0); await _shot("5_download")
	var cin = get_tree().root.find_children("*", "CanvasLayer", true, false).filter(func(n): return n.has_signal("finished_choice"))
	var wait = 0
	while !cin.is_empty() and !cin[0].prompt_row.visible and wait < 40:
		await _secs(0.5); wait += 1
	await _shot("6_hats")
	cin[0].input.text = OS.get_environment("CHOICE") if OS.get_environment("CHOICE") != "" else "steal"
	cin[0].input.text_submitted.emit(cin[0].input.text)
	await _secs(9.0); await _shot("7_answer")
	wait = 0
	while is_instance_valid(cin[0]) and wait < 200:
		await _secs(0.25); wait += 1
	await _secs(0.3); await _shot("8_back")
	hk.go_to_root()
	await _secs(3.0); await _shot("9_root")
	print(">>> state ", Ending.state, " choice ", Ending.choice, " paused ", get_tree().paused)
	print(">>> done")
	get_tree().quit()
