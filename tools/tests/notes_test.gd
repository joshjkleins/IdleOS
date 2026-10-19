extends Node
var os
var seen := 0
var out: Array = []
func _ready() -> void:
	_run.call_deferred()
func _poll() -> void:
	if os.lines.size() < seen: seen = 0
	while seen < os.lines.size():
		out.append(os.lines[seen]); seen += 1
func _wait(sec: float) -> void:
	var t = 0.0
	while t < sec:
		await get_tree().process_frame
		_poll()
		t += get_process_delta_time() / Engine.time_scale
func _cmd(c: String, w: float = 1.0) -> void:
	out.append("##CMD " + c)
	os._on_input_line_text_submitted(c)
	await _wait(w)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _wait(1.0)
	if Tutorial.show_intro: os._finish_boot()
	await _wait(1.0)
	os.accepting_player_inputs = true
	print(">>> goals: ", Uploads.get_goals().map(func(g): return "%s %d" % [g.item.name, g.amount]))
	print(">>> intro objective ok: ", "build a stronger system" in os.INTRO_TEXT)
	for e in Tutorial.TUTORIAL_ORDER.slice(0, Tutorial.TUTORIAL_ORDER.find(Tutorial.TutorialEvent.LIST_LOG_DETAILS)):
		Tutorial.completed_events.append(e)
	var tok0 = Inventory.get_amount(Items.VM_MINING_TOKEN)
	await _cmd("ls logs")
	print(">>> after 'ls logs': tokens %d -> %d | current: %s" % [tok0, Inventory.get_amount(Items.VM_MINING_TOKEN), Tutorial.get_current_task().left(70)])
	await _cmd("ssh mining logs", 1.5)
	print(">>> after ssh: current: ", Tutorial.get_current_task().left(70))
	Inventory.add_resource(Items.LOGS, 40)
	await _cmd("add logs"); await _cmd("cd decoding", 1.5)
	await _cmd("decode -package=logs"); await _cmd("decode -package=logs 3", 1.0)
	await _wait(1.5)
	print(">>> header: ", os.current_process.cache_name.text if os.current_process and "cache_name" in os.current_process else "-")
	Engine.time_scale = 8.0; await _wait(3.0); Engine.time_scale = 1.0
	print(">>> staged logs: ", Uploads.get_staged(Items.LOGS))
	await _cmd("upload -a"); await _cmd("cd ..", 1.2)
	await _cmd("-h", 2.0); await _cmd("info decoding", 2.0); await _cmd("cd mining", 1.5); await _cmd("mine -archives")
	await _cmd("overclock")
	# hard mode message, uploads not done then done
	var hard = Stats.hacking_targets["School"]["hard mode targets"][0]
	Stats.record_win(hard); await _wait(2.0)
	var rx = RegEx.new(); rx.compile("\\[[^\\]]*\\]")
	for l in out:
		var t = rx.sub(str(l), "", true).strip_edges()
		if t == "" or t.begins_with("│") and !("Cache" in t or "Skim" in t or "Deep" in t or "Package" in t or "Intel" in t or "Salvage" in t): continue
		if t.begins_with("┌") or t.begins_with("└") or t.begins_with("├"): continue
		print("| ", t.left(150))
	get_tree().quit()
