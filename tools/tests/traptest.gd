extends Node
## 2026-11-02: several traps (Extra Trap apt) + bait by resource kind + the Quick Hook save migration.
var os
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _tail(n: int) -> String:
	var t = os.current_scrollback.get_parsed_text()
	var ls = Array(t.split("\n", false)).filter(func(l): return l.strip_edges() != "")
	return " | ".join(ls.slice(max(0, ls.size() - n)))
func _cmd(c: String, wait := 1.0) -> void:
	os._on_input_line_text_submitted(c)
	await _secs(wait)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	# migration: an old save with 5 Quick Hook installs (tiers 1-5)
	Upgrades.load_data({"format": 3, "installed": {"phishing.quick_hook": 5}})
	print(">>> migration: quick_hook %d (%.2f), extra_trap %d -> max traps %d" % [Upgrades.packages["phishing.quick_hook"].installed, Upgrades.cur("phishing.quick_hook"), Upgrades.packages["phishing.extra_trap"].installed, Phishing.max_traps()])
	for l in Stats.hacking_targets: Stats.unlock_location(l)
	Exp.refresh_all_process_unlocks()
	Phishing.traps.clear()
	var res = Decoding.get_tier_resources(1) # logs, ip, enc pw, usernames, passwords, credentials, school payload
	for it in res: Inventory.add_resource(it, 300)
	Engine.time_scale = 30.0
	await _cmd("cd phishing")
	for b in [res[0], res[4], res[5]]:
		await _cmd("phish -trap bait=" + b.name.to_lower(), 0.5)
		var w = 0
		while os.process_running and w < 100:
			await _secs(0.1); w += 1
	Engine.time_scale = 1.0
	print(">>> traps set: ", Phishing.traps.map(func(t): return t.bait_kind), " | logs left ", Inventory.get_amount(res[0]))
	await _cmd("phish -trap")
	print(">>> 4th trap: ", _tail(2).left(200))
	Phishing.traps.pop_back()
	await _cmd("phish -trap bait=school payload")
	print(">>> payload bait: ", _tail(1).left(160))
	for t in Phishing.traps: t["set_at"] = int(t.set_at) - 3000 # full
	var sql0 = Inventory.get_amount(Items.SQL_INJECTOR)
	await _cmd("trap")
	print(">>> status: ", _tail(4).left(400))
	await _cmd("trap collect")
	print(">>> collect: ", _tail(3).left(600))
	print(">>> SQL +", Inventory.get_amount(Items.SQL_INJECTOR) - sql0, " traps left ", Phishing.traps.size())
	print(">>> done")
	get_tree().quit()
