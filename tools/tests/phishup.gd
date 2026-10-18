extends Node
## Phishing upgrade checks. PART=1 tracks, PART=2 capstones/modifiers.
var term
func _ready() -> void:
	_run.call_deferred()
func _setpkg(id: String, n: int) -> void:
	var p = Upgrades.packages[id]; p.installed = min(n, p.levels.size()); Upgrades._recompute(p)
func _scen(name: String, proc: Dictionary, secs: float, bait: ItemData = null, mod: String = "") -> void:
	var watch = [Items.SQL_INJECTOR, Items.PACKET_SPOOF, Items.VM_PHISHING_TOKEN, Items.LOGS, Items.SQL_BOOSTER]
	var b = watch.map(func(i): return Inventory.get_amount(i))
	var xp0 = proc.experience
	var catches = [0]
	var cb = func(_a): catches[0] += 1
	proc.signal.connect(cb)
	term = Phishing.terminal_scene.instantiate(); add_child(term)
	term.cast_lines(proc, -1, bait)
	if mod != "":
		for m in Phishing.MODIFIERS:
			if m.command == mod: term.modifier = m
	await get_tree().process_frame
	var lbl = term.slots_label.text.replace("\n", " / ")
	var t = 0.0
	var heat = 0.0
	while t < secs and term.running:
		await get_tree().process_frame
		t += get_process_delta_time()
		heat += Stats.system_tempature - 30.0
		Stats.system_tempature = 30.0; Stats.overheated = false
	var d = {}
	for i in watch.size(): d[watch[i].name] = Inventory.get_amount(watch[i]) - b[i]
	var h = t / 3600.0
	print(">>> %-22s %4.0fm | catches/h %.0f | SQL+spoof/h %.0f | tokens/h %.1f | mods %d | logs/h %.0f | heat/h %.0f | xp/h %.0f" % [name, t / 60.0, catches[0] / h, (d["SQL Injector"] + d["Packet Spoof"]) / h, d["VM phishing token"] / h, d["SQL Booster"], -d["Logs"] / h, heat / h, (proc.experience - xp0) / h])
	print("    ", lbl.left(160))
	proc.signal.disconnect(cb)
	if term.running: term.stop()
	term.queue_free(); Phishing.current_lines.clear()
	await get_tree().process_frame
func _run() -> void:
	await get_tree().process_frame
	Engine.max_fps = 0
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 60.0
	Inventory.add_resource(Items.LOGS, 1000000)
	var part = OS.get_environment("PART")
	for id in Upgrades.packages:
		if id.begins_with("phishing."): _setpkg(id, 0)
	if part == "0":
		await _scen("spear base", Phishing.SPEAR, 1800)
		await _scen("whale base", Phishing.WHALING, 1800)
		await _scen("spear bait base", Phishing.SPEAR, 900, Items.LOGS)
	if part == "1":
		for id in ["phishing.speed","phishing.efficiency","phishing.lines","phishing.bait_power","phishing.bait_recycling","phishing.quick_hook"]:
			_setpkg(id, 99)
		print("cur: speed %.2f eff %.3f lines %d bait_power %.2f recycle %.2f hook %.2f | spear eff %.3f trap eff %.3f" % [Upgrades.cur("phishing.speed"), Upgrades.cur("phishing.efficiency"), Upgrades.cur("phishing.lines"), Upgrades.cur("phishing.bait_power"), Upgrades.cur("phishing.bait_recycling"), Upgrades.cur("phishing.quick_hook"), Phishing.get_efficiency(Phishing.SPEAR), Phishing.get_efficiency(Phishing.TRAP)])
		await _scen("spear max tracks", Phishing.SPEAR, 600)
		await _scen("whale max tracks", Phishing.WHALING, 600)
		await _scen("spear bait max", Phishing.SPEAR, 300, Items.LOGS)
		Phishing.trap = {}
		await _scen("trap setup max speed", Phishing.TRAP, 300)
		print("    trap set: ", Phishing.has_trap())
	elif part == "3":
		await _scen("spear base (tokens)", Phishing.SPEAR, 6 * 3600)
		_setpkg("phishing.tackle_box", 1)
		await _scen("spear tackle box", Phishing.SPEAR, 6 * 3600)
	else:
		await _scen("spear chum", Phishing.SPEAR, 1800, null, "chum")
		await _scen("spear lure", Phishing.SPEAR, 1800, null, "lure")
		await _scen("spear survey", Phishing.SPEAR, 1800, null, "survey")
		_setpkg("phishing.deep_water", 1)
		await _scen("spear chum cooled", Phishing.SPEAR, 900, null, "chum")
		term = Phishing.terminal_scene.instantiate(); add_child(term)
		Phishing.trap = {}
		term.cast_lines(Phishing.TRAP)
		print("    trap modifier block: '", term.modifier_block_reason(), "'")
		term.stop()
	print(">>> done")
	get_tree().quit()
