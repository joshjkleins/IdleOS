extends Node
## 2026-11-02: quit with the queue running, load again: the welcome back shows first, then the step it was on resumes
## (STEP=1 sets up and quits mid step 1; STEP=2 loads the save; keep ~/.local/share/IdleOS_Demo between the runs)
var os
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _cmd(c: String, wait := 0.8) -> void:
	os._on_input_line_text_submitted(c)
	await _secs(wait)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	var r00 = Offline.report.duplicate(true)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	if OS.get_environment("STEP") == "2":
		var r0 = r00
		print(">>> R process=%s ran=%.0f secs=%s notes=%s resume=%s" % [r0.get("process"), float(r0.get("ran", 0)), r0.get("secs"), r0.get("notes"), r0.get("resume")])
		print(">>> R gains: ", r0.get("gains", []).map(func(g): return "%s +%d" % [g.item.name, g.amount]), " spent: ", r0.get("spent", []).map(func(g): return "%s -%d" % [g.item.name, g.amount]), " xp ", r0.get("xp"))
		var started_during_welcome = false
		var t = 0.0
		while t < 25.0:
			await get_tree().process_frame; t += get_process_delta_time()
			if os._hold_unlocks and os.process_running: started_during_welcome = true
		var txt = os.current_scrollback.get_parsed_text()
		var ls = Array(txt.split("\n", false)).filter(func(l): return l.strip_edges() != "")
		var r = Offline.report
		print(">>> report: process=%s ran=%.0f secs=%s notes=%s" % [r.get("process"), float(r.get("ran", 0)), r.get("secs"), r.get("notes")])
		print(">>> gains: ", r.get("gains", []).map(func(g): return "%s +%d" % [g.item.name, g.amount]), " spent: ", r.get("spent", []).map(func(g): return "%s -%d" % [g.item.name, g.amount]))
		print(">>> resume: ", r.get("resume"))
		print(">>> after load: queue running %s, index %d, process %s (%s), a step started during the welcome: %s" % [Queue.running, Queue.index, os.process_running, os.current_process_info.get("name", "-"), started_during_welcome])
		print(">>> last lines: ", " | ".join(ls.slice(max(0, ls.size() - 6))))
		get_tree().quit()
		return
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	Uploads.completed_tiers = [1]; Stats.unlock_location("Lawfirm"); Exp.refresh_all_process_unlocks()
	Inventory.add_resource(Items.LOGS, int(OS.get_environment("LOGS")) if OS.get_environment("LOGS") != "" else 500)
	await _cmd("queue -add mine -logs 4"); await _cmd("queue -add parse -footprint=logs 30")
	await _cmd("queue -run")
	var t2 = 0.0
	while Queue.index != 1 and t2 < 60.0:
		await get_tree().process_frame; t2 += get_process_delta_time()
	await _secs(2.0)
	print(">>> before quit: queue index %d, process %s" % [Queue.index, os.current_process_info.get("name", "-")])
	SaveManager.save_game()
	await _secs(2.0)
	SaveManager.save_game()
	get_tree().quit()
