extends Node
## STEP=1: start mining + parsing items, save, quit. STEP=2: (save edited to 2h ago) launch normally, print the download + resume.
var os
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 10: await get_tree().process_frame
	os.accepting_player_inputs = true
	if OS.get_environment("STEP") == "1":
		Inventory.add_resource(Items.LOGS, 5000)
		if OS.get_environment("TIER") != "":
			# School goal: everything uploaded except 10 Usernames, which are staged + uploading
			for g in Uploads.get_goals(1):
				Uploads.uploaded[g.item] = g.amount
			Uploads.uploaded[Items.USERNAMES] = Uploads.get_goal_amount(Items.USERNAMES) - 10
			Uploads.staged[Items.USERNAMES] = 10
			Uploads.active[Items.USERNAMES] = 0.0
			Phishing.set_trap(null)
			Mining.SKILL.level = 5
			Mining.SKILL.experience = Exp.xp_for_level(5)
			os._on_input_line_text_submitted("cd mining")
			os._on_input_line_text_submitted("mine -logs")
		else:
			Uploads.staged[Items.USERNAMES] = 120
			Uploads.active[Items.USERNAMES] = 0.0
			os._on_input_line_text_submitted("cd parsing")
			os._on_input_line_text_submitted("parse -footprint=logs")
		for i in 30: await get_tree().process_frame
		print(">>> running: ", os.process_running, " main_command ", os.main_command, " snapshot ", Offline.snapshot())
		SaveManager.save_game()
		get_tree().quit()
		return
	var t = 0.0
	var shots = [2.0, 15.0]
	while t < float(OS.get_environment("WAIT") if OS.get_environment("WAIT") != "" else "8"):
		await get_tree().process_frame
		t += get_process_delta_time()
		if !shots.is_empty() and t >= shots[0] and OS.get_environment("SHOT") != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/offline_%d.png" % int(shots[0] * 10))
			shots.pop_front()
	print(">>> terminal after the download:")
	for c in os.terminal_body_container.get_children():
		if c is RichTextLabel and c.get_parsed_text().contains("UPLOAD GOAL COMPLETE"):
			print("--- tier block ---\n", c.get_parsed_text().substr(c.get_parsed_text().find("═")).left(700))
	print(">>> School tier complete: %s | Lawfirm unlocked: %s | mining L%d" % [1 in Uploads.completed_tiers, Stats.hacking_targets["Lawfirm"].unlocked, Mining.SKILL.level])
	for c in os.terminal_body_container.get_children():
		if c is RichTextLabel and c.get_parsed_text().contains("RESTORING"):
			print("--- download block ---\n", c.get_parsed_text())
	print(">>> after: process_running %s | %s | logs %d | mining L%d" % [os.process_running, os.current_process_info.get("name", "-") if os.current_process_info else "-", Inventory.get_amount(Items.LOGS), Mining.SKILL.level])
	get_tree().quit()
