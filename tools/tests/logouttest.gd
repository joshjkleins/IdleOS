extends Node
## 2026-11-02: the save's queue meta follows the running step; 'logout' saves and relaunches (the relaunched run
## writes user://relaunch_ok.txt and quits)
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _run() -> void:
	if FileAccess.file_exists("user://relaunch_marker"):
		DirAccess.remove_absolute("user://relaunch_marker")
		var f = FileAccess.open("user://relaunch_ok.txt", FileAccess.WRITE)
		f.store_string("relaunched, slot %d, session %s" % [SaveManager.slot, SaveManager.session_active])
		f.close()
		get_tree().quit()
		return
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	Queue.kill(); Queue.steps = ["mine -logs 2", "parse -footprint=logs 3"]; Queue.index = 0
	Inventory.add_resource(Items.LOGS, 50)
	os._on_input_line_text_submitted("queue -run")
	await _secs(1.0)
	var txt = os.current_scrollback.get_parsed_text()
	print(">>> after queue -run: ", " | ".join(Array(txt.split("\n", false)).slice(-4)))
	var seen = []
	for k in int(OS.get_environment("N")) if OS.get_environment("N") != "" else 6:
		await _secs(2.0)
		SaveManager.save_game()
		var q = SaveManager.read_meta(SaveManager.slot).get("queue", {})
		seen.append("%d:%s (live %d, run %s, proc %s %s)" % [int(q.get("index", -1)), q.get("current", ""), Queue.index, Queue.running, os.process_running, os.current_process_info.get("name", "-")])
	print(">>> queue meta over time: ", " | ".join(seen))
	Queue.kill()
	var f = FileAccess.open("user://relaunch_marker", FileAccess.WRITE); f.store_string("1"); f.close()
	os._on_input_line_text_submitted("logout")
	await _secs(2.5)
	print(">>> restart set: ", OS.is_restart_on_exit_set(), " args ", OS.get_cmdline_args())
