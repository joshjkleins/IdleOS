extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _cmd(c: String) -> void:
	os._on_input_line_text_submitted(c)
	await _secs(1.0)
func _tail(n: int) -> String:
	var t = ""
	for r in os.find_children("*", "RichTextLabel", true, false):
		if r.is_visible_in_tree(): t += r.get_parsed_text() + "\n"
	var ls = Array(t.split("\n", false)).filter(func(l): return l.strip_edges() != "")
	return " | ".join(ls.slice(max(0, ls.size() - n)))
func _try(cmd: String) -> void:
	await _cmd(cmd)
	await _secs(2.0)
	print(">>> START ", cmd, ": ", _tail(4).left(400))
	var before = {}
	for it in Inventory.inventory: before[it] = Inventory.get_amount(it)
	await _cmd("timeskip 600")
	await _secs(4.0)
	var gains = []
	for it in Inventory.inventory:
		var d = Inventory.get_amount(it) - before.get(it, 0)
		if d != 0: gains.append("%s %+d" % [it.name, d])
	print(">>> AFTER: ", _tail(12).left(900))
	print(">>> ", cmd, " | running ", os.process_running, " | report keys ", Offline.report.keys(), " | ", ", ".join(gains).left(300))
	await _cmd("stop")
	await _secs(1.0)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	await _cmd("uploads complete")
	Decoding.SKILL.level = 60
	Inventory.add_resource(Items.STUDENT_CACHE, 200)
	Inventory.add_resource(Items.LOGS, 5000)
	for l in Stats.hacking_targets: Stats.unlock_location(l)
	Exp.refresh_all_process_unlocks()
	await _cmd("cd decoding")
	Inventory.add_resource(Items.VM_DECODING_TOKEN, 40)
	for c in ["decode -deep"]:
		await _try(c)
	print(">>> done")
	get_tree().quit()
