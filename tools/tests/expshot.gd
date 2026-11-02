extends Node
## 2026-11-01: screenshot of a hack with every Exploit owned (EXPLOITS card size vs the combat log)
var os
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	for it in Exploits.get_items():
		Inventory.add_resource(it, 3)
	Inventory.add_resource(Items.SQL_INJECTOR, 500)
	Inventory.add_resource(Items.PACKET_SPOOF, 100)
	Inventory.add_resource(Items.SCHOOL_PAYLOAD, 60)
	for c in ["tutorial complete", "cd hacking"]:
		os._on_input_line_text_submitted(c)
		for i in 90: await get_tree().process_frame
	var hk = get_tree().root.find_children("*", "", true, false).filter(func(n): return n.has_method("handle_hack_command"))
	await hk[0].open_location("School", false)
	for i in 600: await get_tree().process_frame
	hk[0].current_context = 1
	hk[0].handle_hack_command("hack student")
	for i in 500: await get_tree().process_frame
	await _shot(OS.get_environment("SHOT") if OS.get_environment("SHOT") != "" else "exp_all")
	var g = get_tree().root.find_children("*", "", true, false).filter(func(n): return "exp_split" in n and n.exp_split != null)
	if !g.is_empty():
		var h = g[0]
		print(">>> split off ", h.exp_split.split_offset, " list min ", h.exp_list.get_combined_minimum_size(), " list content ", h.exp_list.get_content_height(), " scroll ", h.exp_scroll.size, " card ", h.exp_card.panel.size, " split ", h.exp_split.size, " saved ", h._exp_split_saved)
		h.exp_split.split_offset = -3000
		h._exp_split_saved = -3000.0
		h._exp_sig = "x"; h._refresh_exploit_list()
		for i in 20: await get_tree().process_frame
		print(">>> dragged up: log rtl ", h.log_rtl.size, " scroll ", h.exp_scroll.size)
		await _shot("exp_dragged")
	print(">>> done ", Exploits.get_items().size())
	get_tree().quit()
