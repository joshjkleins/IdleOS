extends Node
## 2026-11-02: the command queue (live): steps advance when their count is done, manual processes and Hacking are
## blocked while it runs, pause, a queue where nothing can run stops itself, the side panel.
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
func _last(n: int) -> String:
	var ls = Array(os.current_scrollback.get_parsed_text().split("\n", false)).filter(func(l): return l.strip_edges() != "")
	return " | ".join(ls.slice(max(0, ls.size() - n)))
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/queue_%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	await _cmd("queue")
	print(">>> locked: ", _last(1))
	Uploads.completed_tiers = [1]; Stats.unlock_location("Lawfirm"); Exp.refresh_all_process_unlocks(); Queue.changed.emit()
	print(">>> slots ", Queue.slots())
	await _cmd("queue -add hack student"); print(">>> add hack: ", _last(1))
	await _cmd("queue -add mine -logs 3"); await _cmd("queue -add parse -footprint=logs 2"); await _cmd("queue -add crack -password")
	print(">>> 3rd add: ", _last(1))
	Inventory.add_resource(Items.LOGS, 20)
	Engine.time_scale = 8.0
	await _cmd("queue -run", 0.5)
	await _cmd("mine -archives", 0.3); print(">>> manual while running: ", _last(1))
	await _cmd("cd hacking", 0.3); print(">>> cd hacking while running: ", _last(1))
	var seen = []
	var t = 0.0
	while t < 40.0 and seen.size() < 6:
		await get_tree().process_frame; t += get_process_delta_time() / Engine.time_scale
		var cur = "%d:%s" % [Queue.index + 1, str(os.current_process_info.get("name", "-")) if os.process_running else "-"]
		if seen.is_empty() or seen[-1] != cur: seen.append(cur)
	print(">>> step sequence: ", seen)
	Engine.time_scale = 1.0
	await _shot("panel")
	await _cmd("queue -kill", 0.5); print(">>> kill: ", _last(1), " | running ", Queue.running, " | process ", os.process_running)
	await _shot("paused")
	await _cmd("queue -run 1", 1.0); print(">>> run 1: ", _last(2).replace("\n", " "), " | on step ", Queue.index + 1, " running ", os.current_process_info.get("name", "-"))
	os.system_dock.queue_section.set_collapsed(true); await _secs(1.2); await _shot("collapsed")
	os.system_dock.queue_section.set_collapsed(false)
	await _cmd("stop", 0.5); print(">>> stop while running: ", _last(1), " | running ", Queue.running)
	await _cmd("queue -rm -a"); await _cmd("queue -add crack -password")
	Inventory.remove_resource(Items.ENCRYPTED_PASSWORDS, Inventory.get_amount(Items.ENCRYPTED_PASSWORDS)) if "ENCRYPTED_PASSWORDS" in Items else null
	await _cmd("stop", 1.0)
	await _cmd("queue -run", 2.5)
	print(">>> nothing can run: ", _last(2), " | running ", Queue.running)
	print(">>> done")
	get_tree().quit()
