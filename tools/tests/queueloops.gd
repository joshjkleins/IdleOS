extends Node
## 2026-11-09: 'queue -run <loops> [start=<n>]' - parsing, a 2-loop online run, and offline stopping after its loops
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
	if !(1 in Uploads.completed_tiers): Uploads.completed_tiers.append(1)
	if os.process_running: os.kill_main_process()
	await _f(10)
	Queue.handle("queue -rm -a")
	Queue.handle("queue -add mine -logs 1")
	Queue.handle("queue -add mine -logs 1")
	for c in ["queue -run start=5", "queue -run abc", "queue -run 0"]:
		print(">>> '%s' -> %s" % [c, ContextCommands.strip_bbcode(Queue.handle(c))])
	print(">>> 'queue -run 2 start=1' -> %s" % ContextCommands.strip_bbcode(Queue.handle("queue -run 2 start=1")))
	print(">>> status: %s" % ContextCommands.strip_bbcode(Queue.status_text(false)).strip_edges().split("\n")[0])
	Queue.handle("queue -kill")
	await _f(10)
	# online: 2 loops from step 0 = 4 step runs, then stop
	print(">>> 'run queue 2' -> %s" % ContextCommands.strip_bbcode(Queue.handle("queue -run 2")) if false else "")
	os._on_input_line_text_submitted("run queue 2")
	var runs = 0
	var last = -1
	var t0 = Time.get_ticks_msec()
	while Queue.running and Time.get_ticks_msec() - t0 < 120000:
		if os.process_running and Queue.index != last:
			runs += 1
			last = Queue.index
		await get_tree().process_frame
	print(">>> online: running %s after %.0fs, step starts seen %d, loops_total now %d" % [Queue.running, (Time.get_ticks_msec() - t0) / 1000.0, runs, Queue.loops_total])
	# offline: 2 loops of 1-log steps over 1 h away stops early
	var logs0 = Inventory.get_amount(Items.LOGS)
	Queue.index = 0
	Queue.running = true
	Queue.loops_left = 2
	Queue.loops_total = 2
	Offline.report = {"gains": [], "lost": {}, "drivers": [], "uploaded": [], "staged": [], "notes": [], "trap": -1.0, "ran": 0.0, "resume": {}, "process": ""}
	Offline._run_queue(Offline.snap_from_command(Queue.steps[0]), 3600.0)
	print(">>> offline: running %s  logs +%d  notes %s" % [Queue.running, Inventory.get_amount(Items.LOGS) - logs0, Offline.report.notes])
	Queue.handle("queue -rm -a")
	get_tree().quit()
