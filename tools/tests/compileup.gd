extends Node
## Compiling upgrade checks. PART=1 payloads (base / max tracks / modifiers), PART=2 Mod, PART=3 Access.
var term
func _ready() -> void:
	_run.call_deferred()
func _setpkg(id: String, n: int) -> void:
	var p = Upgrades.packages[id]; p.installed = min(n, p.levels.size()); Upgrades._recompute(p)
func _all(n: int) -> void:
	for id in Upgrades.packages:
		if id.begins_with("compiling."): _setpkg(id, n)
func _start(proc: Dictionary, arg = null, mod: String = "") -> void:
	term = Compiling.terminal_scene.instantiate(); add_child(term)
	if mod != "":
		for m in Compiling.MODIFIERS:
			if m.command == mod: term.modifier = m
	term.start(proc, false, arg)
func _wait(secs: float) -> float:
	var t = 0.0
	while t < secs and term.running:
		await get_tree().process_frame
		t += get_process_delta_time()
		Stats.system_tempature = 30.0; Stats.overheated = false
	return t
func _scen(name: String, proc: Dictionary, secs: float, mod: String = "") -> void:
	var watch = [Items.SCHOOL_PAYLOAD, Items.IP_ADDRESS, Items.CREDENTIALS, Items.VM_COMPILING_TOKEN]
	var b = watch.map(func(i): return Inventory.get_amount(i))
	var xp0 = proc.experience
	var fills = [0]; var bursts = [0]
	var cb = func(_a): fills[0] += 1
	proc.signal.connect(cb)
	_start(proc, null, mod)
	var was = false
	var t = 0.0
	while t < secs and term.running:
		await get_tree().process_frame
		t += get_process_delta_time()
		if term.eff_proc and !was: bursts[0] += 1
		was = term.eff_proc
		Stats.system_tempature = 30.0; Stats.overheated = false
	var d = []
	for i in watch.size(): d.append(Inventory.get_amount(watch[i]) - b[i])
	var h = t / 3600.0
	print(">>> %-18s %3.0fm | fills/h %.0f | payloads/h %.0f | IP used/h %.0f | cred used/h %.0f | payload per input set %.2f | bursts/h %.0f | tokens/h %.1f | xp/h %.0f | %s" % [name, t / 60.0, fills[0] / h, d[0] / h, -d[1] / h, -d[2] / h, float(d[0]) / max(1, fills[0]) if fills[0] else 0.0, bursts[0] / h, d[3] / h, (proc.experience - xp0) / h, term.eff_label.text])
	proc.signal.disconnect(cb)
	if term.running: term.stop()
	term.queue_free()
	await get_tree().process_frame
func _run() -> void:
	await get_tree().process_frame
	Engine.max_fps = 0
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 10.0
	var part = OS.get_environment("PART")
	var S = float(OS.get_environment("SECS")) if OS.get_environment("SECS") != "" else 600.0
	_all(0)
	for r in Compiling.SCHOOL.requirements: Inventory.add_resource(r, 1000000)
	if part == "1":
		print("reqs: ", Compiling.SCHOOL.requirements.keys().map(func(i): return i.name), " | eff L%d %.4f" % [Compiling.SCHOOL.level, Compiling.get_efficiency(Compiling.SCHOOL)])
		await _scen("school base", Compiling.SCHOOL, S)
		_all(99)
		print("max eff %.4f recovery %.3f linker %.3f tuning %.2f" % [Compiling.get_efficiency(Compiling.SCHOOL), Upgrades.cur("compiling.recovery"), Upgrades.cur("compiling.linker"), Upgrades.cur("compiling.mod_tuning")])
		await _scen("school max", Compiling.SCHOOL, S / 2)
		await _scen("school optimize", Compiling.SCHOOL, S / 2, "optimize")
		await _scen("school survey", Compiling.SCHOOL, S / 2, "survey")
		await _scen("government max", Compiling.GOVERNMENT, S / 2) if false else null
	if part == "2":
		Compiling.MOD.unlocked = true
		HackingMods.current_mods.clear()
		Inventory.add_resource(Items.LOGS, 100000); Inventory.add_resource(Items.SQL_INJECTOR, 10000)
		var c = Compiling.check_mod("logs")
		print("check logs: ok=%s cost/hack %s cap %d (debug %d)" % [c.ok, str(Compiling.mod_fill_cost(Items.LOGS).keys().map(func(i): return "%s x%d" % [i.name, Compiling.mod_fill_cost(Items.LOGS)[i]])), Compiling.mod_cap(Items.LOGS), Compiling.mod_cap(Items.LOGS, true)])
		print("cost/hack sql injector mod: ", Compiling.mod_fill_cost(Items.SQL_INJECTOR).keys().map(func(i): return "%s x%d" % [i.name, Compiling.mod_fill_cost(Items.SQL_INJECTOR)[i]]), " | student cache: ", Compiling.mod_fill_cost(Items.STUDENT_CACHE).keys().map(func(i): return "%s x%d" % [i.name, Compiling.mod_fill_cost(Items.STUDENT_CACHE)[i]]))
		var l0 = Inventory.get_amount(Items.LOGS); var s0 = Inventory.get_amount(Items.SQL_INJECTOR)
		_start(Compiling.MOD, Items.LOGS)
		var t = await _wait(600)
		print(">>> mod logs base: %.0fs, mod %s | logs used %d sql used %d | running %s | label %s" % [t, str(HackingMods.current_mods), l0 - Inventory.get_amount(Items.LOGS), s0 - Inventory.get_amount(Items.SQL_INJECTOR), term.running, term.amount_gained_label.text])
		term.queue_free()
		print("check again at cap (no debug capstone): ", Compiling.check_mod("logs").message)
		_setpkg("compiling.debug_build", 1)
		var l1 = Inventory.get_amount(Items.LOGS)
		_start(Compiling.MOD, Items.LOGS)
		await _wait(60)
		print(">>> at cap with debug capstone, debug off: running %s | label '%s' | logs spent %d" % [term.running, term.amount_gained_label.text, l1 - Inventory.get_amount(Items.LOGS)])
		for m in Compiling.MODIFIERS:
			if m.command == "debug": term.modifier = m
		await _wait(200)
		print(">>> then debug on: %s | label '%s'" % [str(HackingMods.current_mods), term.amount_gained_label.text])
		term.queue_free()
		HackingMods.current_mods[HackingMods.MOD_TYPE.DAMAGE].duration = 2
		_all(99)
		_start(Compiling.MOD, Items.LOGS, "debug")
		t = await _wait(600)
		print(">>> mod logs top-up debug+tuning: %.0fs, mod %s | label %s" % [t, str(HackingMods.current_mods), term.amount_gained_label.text])
		term.queue_free()
		HackingMods.max_mods = 1
		print("slots full, other type: ", Compiling.check_mod("ip address").message)
	if part == "3":
		var school = Stats.hacking_targets["School"]
		var admin = school.targets[1]
		admin.unlocked = false
		Compiling.access_progress = {}
		var r = Stats.get_access_recipe(admin)
		Inventory.remove_resource(r.rare, Inventory.get_amount(r.rare))
		Inventory.remove_resource(r.payload, Inventory.get_amount(r.payload))
		Inventory.add_resource(r.payload, 20)
		print("admin: %d stages, payload total %d, stage costs: %s" % [Compiling.access_stages(admin), r.payload_amount, str(range(Compiling.access_stages(admin)).map(func(i): return Compiling.access_stage_cost(admin, i).values()))])
		print("stages for targets 2..5: ", range(1, 5).map(func(i): return Compiling.access_stages(school.targets[i])))
		var c = Compiling.check_access("administrator")
		print("check: ok=%s %s" % [c.ok, c.message])
		_start(Compiling.ACCESS, admin)
		var t = await _wait(120)
		print(">>> access 120s: done %d/%d | %s | running %s" % [Compiling.access_done(admin), Compiling.access_stages(admin), term.amount_gained_label.text, term.running])
		term.stop(); term.queue_free()
		print("modifier block: ", term.modifier_block_reason())
		_start(Compiling.ACCESS, admin)
		t = await _wait(600)
		print(">>> resumed until stuck: %.0fs done %d/%d | payload left %d | label '%s' | check: %s" % [t, Compiling.access_done(admin), Compiling.access_stages(admin), Inventory.get_amount(r.payload), term.payload_item.text, Compiling.check_access("administrator").message])
		term.queue_free()
		Inventory.add_resource(r.rare, 5)
		_start(Compiling.ACCESS, admin)
		t = await _wait(200)
		print(">>> with rares: %.0fs admin unlocked %s | rares left %d | progress %s" % [t, admin.unlocked, Inventory.get_amount(r.rare), str(Compiling.access_progress)])
		term.queue_free()
		# save / load keeps progress
		Compiling.access_progress = {"School/Vice principal": 7}
		var data = Compiling.save_data(); Compiling.access_progress = {}; Compiling.load_data(data)
		print("save/load progress: ", Compiling.access_progress)
	get_tree().quit()
