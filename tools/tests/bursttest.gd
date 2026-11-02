extends Node
## 2026-11-02: burst bars (fill while the main process runs, offline too) and 'burst' (5 min of the main process now).
var os
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _cmd(c: String, wait := 1.0) -> void:
	os._on_input_line_text_submitted(c)
	await _secs(wait)
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/burst_%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	for l in ["School", "Lawfirm"]: Stats.unlock_location(l)
	Exp.refresh_all_process_unlocks()
	Burst.charge.clear()
	await _cmd("cd mining")
	await _cmd("mine -logs", 4.0)
	print(">>> after ~4s of Logs: logs %.1fs, archives %.1fs" % [Burst.charge.get("Mining/Logs", 0.0), Burst.charge.get("Mining/Archives", 0.0)])
	await _cmd("burst")
	print(">>> burst with nothing full: ", os.current_scrollback.get_parsed_text().strip_edges().right(220).replace("\n", " | "))
	Burst.charge["Mining/Archives"] = Burst.FILL_SECONDS # another process's bar is full
	Burst.charge["Mining/Logs"] = Burst.FILL_SECONDS * 0.6
	await _secs(1.5)
	await _shot("header")
	var logs0 = Inventory.get_amount(Items.LOGS)
	await _cmd("burst")
	print(">>> burst: ", os.current_scrollback.get_parsed_text().strip_edges().right(260).replace("\n", " | "))
	print(">>> logs +%d, archives charge now %.0f, process still running %s" % [Inventory.get_amount(Items.LOGS) - logs0, Burst.charge.get("Mining/Archives", 0.0), os.process_running])
	var c0 = float(Burst.charge.get("Mining/Logs", 0.0))
	await _cmd("timeskip 10", 4.0)
	print(">>> timeskip 10 min: logs charge %.0f -> %.0f" % [c0, Burst.charge.get("Mining/Logs", 0.0)])
	print(">>> done")
	get_tree().quit()
