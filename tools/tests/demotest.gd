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
	print(">>> MAX_LEVEL %d | mining L%d | goals: %s" % [Exp.MAX_LEVEL, Mining.SKILL.level, Uploads.get_goals().map(func(g): return "%s %d" % [g.item.name, g.amount])])
	var pk = {}
	for id in Upgrades.packages: pk[Upgrades.packages[id].group] = pk.get(Upgrades.packages[id].group, []) + [id.split(".")[1]]
	print(">>> demo packages: ", pk, " hidden: ", Upgrades.demo_hidden)
	Exp.add_xp(Mining, Mining.LOGS, 10000000)
	print(">>> after huge xp: mining L%d (xp %d), logs L%d eff %.3f" % [Mining.SKILL.level, Mining.SKILL.experience, Mining.LOGS.level, Mining.LOGS.efficiency])
	Inventory.add_resource(Items.LOGS, 1000)
	for c in ["apt decoding", "info mining"]:
		await _cmd(c)
	Uploads.tier_completed.emit(1)
	await _wait(12.0)
	var rx = RegEx.new(); rx.compile("\\[[^\\]]*\\]")
	var keep = false
	for l in out:
		var t = rx.sub(str(l), "", true).strip_edges()
		if t.begins_with("##CMD"): keep = true
		if keep and t != "" and !t.begins_with("┌") and !t.begins_with("└") and !t.begins_with("├") and !(t.begins_with("|") or t.begins_with("_") or t.begins_with("\\") or t.begins_with("/")):
			print("| ", t.left(150))
	for l in rx.sub(os.current_scrollback.text, "", true).split("\n"): pass
	# send-off text lives in the previous scrollback block
	var blocks = os.terminal_body_container.get_children()
	for b in blocks:
		if b is RichTextLabel and "UPLOAD GOAL COMPLETE" in b.text:
			for l in rx.sub(b.text, "", true).split("\n"): print("SO| ", l.left(150))
	get_tree().quit()
