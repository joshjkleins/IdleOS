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
	var seq = []
	for i in 40:
		var c = Alert.chance(stu)
		var ok = Alert.roll_cache(stu)
		seq.append("%d%s" % [int(round(c * 100)), "+" if ok else "-"])
	print(">>> 40 rolls (chance before, + drop / - none): ", " ".join(seq))
	print(">>> student stacks %d chance %.0f%% skill %s goal '%s'" % [Alert.stacks(stu), Alert.chance(stu) * 100, Alert.skill_of(stu), Alert.goal_text(stu)])
	# XP: two targets on the same skill, overflow from the first to the second
	var adm = school[1]; var vp = school[2]
	Alert.data[Stats.target_key(adm)] = {"stacks": 2, "skill": "Cracking", "xp": 0.0}
	Alert.data[Stats.target_key(vp)] = {"stacks": 1, "skill": "Cracking", "xp": 0.0}
	var step = Alert.step_xp("Cracking", 1)
	print(">>> cracking step at T1: %d units, %d xp  ·  goal '%s'" % [Alert.step_units("Cracking", 1), step, Alert.goal_text(adm)])
	Exp.add_xp(Cracking, null, int(step * 2.5))
	print(">>> after 2.5 steps of cracking xp: admin stacks %d, vp stacks %d (%.0f%% through), mining xp leaves them: " % [Alert.stacks(adm), Alert.stacks(vp), Alert.step_progress(vp) * 100], Alert.data.has(Stats.target_key(adm)))
	Exp.add_xp(Mining, null, 100000)
	print(">>> after mining xp: vp still %d stacks" % Alert.stacks(vp))
	for sk in Alert.SKILLS:
		var row = []
		for t in range(1, 7):
			row.append(Alert.step_units(sk, t))
		print(">>> step units %-9s %s" % [sk, row])
	# save / load
	var saved = Alert.save_data().duplicate(true)
	Alert.data.clear(); Alert.load_data(JSON.parse_string(JSON.stringify(saved)))
	print(">>> save/load same: ", JSON.stringify(Alert.save_data()) == JSON.stringify(saved))
	print(Alert.list_text())
	# real hacks against a 90%-alert-chance target: the log
	Alert.data[Stats.target_key(stu)] = {"stacks": 9, "skill": "Parsing", "xp": 0.0}
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
	while Time.get_ticks_msec() - t0 < 90000 and Alert.stacks(stu) < 10:
		await get_tree().process_frame
	await _f(120)
	if !g.is_empty():
		var lines = Array(g[0].log_rtl.get_parsed_text().split("\n", false)).filter(func(l): return "ALRT" in l or "breached" in l)
		print(">>> hack log:\n   " + "\n   ".join(lines.slice(0, 8)))
	print(">>> student stacks after hacks: %d" % Alert.stacks(stu))
	await _shot("alert_hack")
	get_tree().quit()
