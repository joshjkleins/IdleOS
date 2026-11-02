extends Node
## 2026-11-02: repeat compromise rewards (every School driver owned): XP to each equipped driver + caches + VM caches.
var os
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("tutorial complete")
	await _secs(1.0)
	Uploads.completed_tiers = [1]
	for t in Stats.hacking_targets["School"].targets: Stats.unlock_target(t)
	for id in Compromise.tier_drivers(1): Drivers.grant(id)
	var d1 = Compromise.tier_drivers(1)[0]
	Drivers.equipped[Drivers.DEFS[d1].skill] = [d1]
	var xp0 = int(Drivers.owned[d1])
	Inventory.add_resource(Items.SCHOOL_PAYLOAD, 40); Inventory.add_resource(Items.SQL_INJECTOR, 500); Inventory.add_resource(Items.PACKET_SPOOF, 100)
	print(">>> repeat? ", Compromise.is_repeat("School"), " prize: ", Compromise.prize_text("School"), " | rule: ", Compromise.prize_rule("School"), " | start problem: '", Compromise.start_problem("School"), "'")
	var before = {}
	for it in Compromise.repeat_items("School"): before[it] = Inventory.get_amount(it)
	os._on_input_line_text_submitted("cd hacking")
	await _secs(2.0)
	var hk = get_tree().root.find_children("*", "", true, false).filter(func(n): return n.has_method("handle_hack_command"))[0]
	hk.handle_compromise_command("-school")
	await _secs(6.0)
	var g = hk.enemy_hacking_box.hacking_game
	var t = 0
	while t < 80:
		if g.is_hacking:
			g.integ_bar.value = 0
			g.win()
		await _secs(1.0); t += 1
		if g.stop_hacking and !g.is_hacking and t > 10: break
	await _secs(4.0)
	var got = []
	for it in before: got.append("%s %+d" % [it.name, Inventory.get_amount(it) - before[it]])
	print(">>> driver %s xp %d -> %d | %s" % [d1, xp0, int(Drivers.owned[d1]), ", ".join(got)])
	print(">>> done")
	get_tree().quit()
