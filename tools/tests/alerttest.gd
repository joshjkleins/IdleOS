extends Node
## 2026-11-02: target alert - rolls (chance drops only on a drop, 0% = nothing), XP steps + overflow, save/load,
## a real hack's log, and the School target cards (screenshot alert_cards.png)
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("tutorial complete")
	await _f(60)
	var school = Stats.hacking_targets["School"].targets
	for t in school: t.unlocked = true
	var stu = school[0]
	Alert.data.clear()
	# one run: first cache +10%, then +4% each
	Alert.begin_run()
	var seq = []
	for i in 30:
		var c = Alert.chance(stu)
		var ok = Alert.roll_cache(stu)
		seq.append("%d%s" % [int(round(c * 100)), "+" if ok else "-"])
	print(">>> one run of 30 (chance before, + drop / - none): ", " ".join(seq))
	print(">>> after the run: alert %.0f%%  · goal '%s'  · bar %.2f" % [Alert.alert_pct(stu), Alert.goal_text(stu), Alert.step_progress(stu)])
	var back = Alert.refund_run()
	print(">>> traced -> refunded %.0f%%, alert now %.0f%% (on alert: %s)" % [back, Alert.alert_pct(stu), Alert.data.has(Stats.target_key(stu))])
	# singles: +10% each
	for i in 3:
		Alert.begin_run(); Alert.roll_cache(stu); Alert.end_run()
	print(">>> 3 single hacks: alert %.0f%%" % Alert.alert_pct(stu))
	# cleanup: smooth, overflow to the next target on the same skill
	var adm = school[1]
	var sk = Alert.skill_of(stu)
	Alert.data[Stats.target_key(adm)] = {"alert": 25.0, "skill": sk}
	var step = Alert.step_xp(sk, 1)
	print(">>> T1 %s step (10%%): %d units, %d xp" % [sk, Alert.step_units(sk, 1), step])
	Exp.add_xp(get_node("/root/" + sk), null, int(step * 0.5))
	print(">>> half a step: student %.0f%% ('%s')" % [Alert.alert_pct(stu), Alert.goal_text(stu)])
	Exp.add_xp(get_node("/root/" + sk), null, int(step * 3.0))
	print(">>> +3 steps: student %.0f%%, admin %.0f%%" % [Alert.alert_pct(stu), Alert.alert_pct(adm)])
	for skn in Alert.SKILLS:
		var row = []
		for t in range(1, 7):
			row.append(Alert.step_units(skn, t))
		print(">>> step units %-9s %s" % [skn, row])
	var saved = Alert.save_data().duplicate(true)
	Alert.data.clear(); Alert.load_data(JSON.parse_string(JSON.stringify(saved)))
	print(">>> save/load same: ", JSON.stringify(Alert.save_data()) == JSON.stringify(saved))
	Alert.load_data({"targets": {Stats.target_key(stu): {"stacks": 3, "skill": "Mining", "xp": 0.0}}})
	print(">>> old stacks save (3 stacks) -> alert %.0f%%" % Alert.alert_pct(stu))
	# real hacks against a 90%-alert-chance target: the log
	Alert.data[Stats.target_key(stu)] = {"alert": 90.0, "skill": "Parsing"}
	Inventory.add_resource(Items.SQL_INJECTOR, 500); Inventory.add_resource(Items.PACKET_SPOOF, 100); Inventory.add_resource(Items.SCHOOL_PAYLOAD, 60)
	os._on_input_line_text_submitted("cd hacking")
	await _f(90)
	var hk = get_tree().root.find_children("*", "", true, false).filter(func(n): return n.has_method("handle_hack_command"))
	await hk[0].open_location("School", false)
	await _f(400)
	await _shot("alert_cards")
	hk[0].current_context = 1
	hk[0].handle_hack_command("hack student=3")
	var g = get_tree().root.find_children("*", "", true, false).filter(func(n): return "log_rtl" in n and n.log_rtl != null)
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000 and Alert.alert_pct(stu) < 100.0:
		await get_tree().process_frame
	await _f(120)
	if !g.is_empty():
		var lines = Array(g[0].log_rtl.get_parsed_text().split("\n", false)).filter(func(l): return "ALRT" in l or "breached" in l)
		print(">>> hack log:\n   " + "\n   ".join(lines.slice(0, 8)))
	print(">>> student alert after the run: %.0f%%" % Alert.alert_pct(stu))
	await _shot("alert_hack")
	get_tree().quit()
