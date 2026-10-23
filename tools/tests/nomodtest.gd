extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 90: await get_tree().process_frame
	for e in Tutorial.TUTORIAL_ORDER: if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	os.RICHTEXT_LABEL_LINE_LIMIT = 100000
	Compiling.SKILL.level = 20; Exp.refresh_process_unlocks(Compiling)
	Phishing.SKILL.level = 20; Exp.refresh_process_unlocks(Phishing)
	for it in [Items.LOGS, Items.IP_ADDRESS, Items.PASSWORDS, Items.CREDENTIALS, Items.SCHOOL_PAYLOAD, Items.ARCHIVES]: Inventory.add_resource(it, 50)
	Inventory.add_resource(Items.BURST_BUFFER, 1)
	print("bait ok: ", [Items.LOGS, Items.IP_ADDRESS, Items.PASSWORDS, Items.CREDENTIALS, Items.ARCHIVES, Items.PARENTS_CREDIT_CARD, Items.SQL_INJECTOR, Items.STUDENT_CACHE].map(func(i): return "%s=%s x%.2f" % [i.name, Phishing.is_bait(i), Phishing.get_bait_multiplier(i) if Phishing.is_bait(i) else 0.0]))
	for cmd in ["compile -mod=logs", "phish -spear bait=passwords", "kill", "ssh phish -spear bait=ip address", "ls mods", "info compiling", "ls logs"]:
		var n0 = os.lines.size()
		os._on_input_line_text_submitted(cmd)
		for i in 60: await get_tree().process_frame
		var out = _strip("\n".join(os.lines.slice(n0)))
		print(">>> ", cmd, "\n", out.left(900) if cmd.begins_with("info") or cmd.begins_with("ls") else out.left(250))
	print("tab compile -m: ", CommandRegistry.complete("compile -m").text, " | tab phish -spear bait=cr: ", CommandRegistry.complete("phish -spear bait=cr").text)
	get_tree().quit()
