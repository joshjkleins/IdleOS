extends Node
## Decoding upgrade checks. PART=1 numbers, PART=2 live Cache runs (base / max tracks / modifiers), PART=3 intel build-up (package was removed 2026-10-20).
var term
func _ready() -> void:
	_run.call_deferred()
func _setpkg(id: String, n: int) -> void:
	var p = Upgrades.packages[id]; p.installed = min(n, p.levels.size()); Upgrades._recompute(p)
func _all(n: int) -> void:
	for id in Upgrades.packages:
		if id.begins_with("decoding."): _setpkg(id, n)
func _scen(name: String, proc: Dictionary, secs: float, arg = null, mod: String = "") -> void:
	var watch = [Items.STUDENT_CACHE, Items.LOGS, Items.PARENTS_CREDIT_CARD, Items.VM_DECODING_TOKEN]
	var b = watch.map(func(i): return Inventory.get_amount(i))
	var staged0 = Uploads.get_staged(Items.LOGS)
	var xp0 = proc.experience
	var intel0 = Decoding.get_intel(Stats.hacking_targets["School"].targets[0]).duplicate()
	var cycles = [0]
	var cb = func(_a): cycles[0] += 1
	proc.signal.connect(cb)
	term = Decoding.terminal_scene.instantiate(); add_child(term)
	term.set_cache_type(proc, false, arg)
	if mod != "":
		for m in Decoding.MODIFIERS:
			if m.command == mod: term.modifier = m
	term.start_decrypting()
	await get_tree().process_frame
	print("    step time normal %.4fs (base %.2fs)" % [term.get_step_time(BaseTerminal.Mode.NORMAL), float(proc["base speed"])])
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
	var intel1 = Decoding.get_intel(Stats.hacking_targets["School"].targets[0])
	print(">>> %-20s %3.0fm | cycles/h %.0f | logs/h %.0f | rare/cache %.3f | tokens/h %.2f | staged logs %d | xp/h %.0f | heat/h %.0f | intel %s->%s" % [name, t / 60.0, cycles[0] / h, d["Logs"] / h, float(d["Parents credit card"]) / max(1, cycles[0]), d["VM decoding token"] / h, Uploads.get_staged(Items.LOGS) - staged0, (proc.experience - xp0) / h, heat / h, str(intel0), str(intel1)])
	print("    ", term.drop_rates.text.left(220) if term.drop_rates.visible else term.cache_name.text.left(160))
	proc.signal.disconnect(cb)
	if term.running: term.stop()
	term.queue_free()
	await get_tree().process_frame
func _run() -> void:
	await get_tree().process_frame
	Engine.max_fps = 0
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 60.0
	var part = OS.get_environment("PART")
	var stu = Stats.hacking_targets["School"].targets[0]
	stu.unlocked = true
	_all(0)
	if part == "1":
		print("L%d | base: cache eff %.4f deep rare %.4f skim %.3f intel %.3f salvage %.3f | max hacks %d" % [Decoding.CACHE.level, Decoding.get_efficiency(Decoding.CACHE), Decoding.get_rare_chance(Decoding.DEEP), Decoding.get_efficiency(Decoding.SKIM), Decoding.get_efficiency(Decoding.INTEL), Decoding.get_efficiency(Decoding.SALVAGE), Decoding.intel_max_hacks()])
		_all(99)
		print("max:  cache eff %.4f deep rare %.4f skim %.3f intel %.3f salvage %.3f | max hacks %d | yield x%.2f sweep %.2f tracker %.4f/dry | skim rare %.3f" % [Decoding.get_efficiency(Decoding.CACHE), Decoding.get_rare_chance(Decoding.DEEP), Decoding.get_efficiency(Decoding.SKIM), Decoding.get_efficiency(Decoding.INTEL), Decoding.get_efficiency(Decoding.SALVAGE), Decoding.intel_max_hacks(), Decoding.yield_multiplier(), Decoding.salvage_sweep_chance(), Upgrades.cur("decoding.rare_tracker"), Decoding.get_rare_chance(Decoding.SKIM, Items.STUDENT_CACHE)])
		Decoding.first_cache_decoded = true
		# tracker: count dry streaks and the chance after 10 dry Student caches
		Decoding.rare_tracker = {"Student cache": 10}
		print("tracker: family('Student cache Extraction')=%s | rare chance after 10 dry: %.4f (base %.4f) | footprint rare %.3f" % [Decoding.cache_family(Items.STUDENT_CACHE_EXTRACTION), Decoding.get_rare_chance(Decoding.CACHE, Items.STUDENT_CACHE), Decoding.get_rare_chance(Decoding.CACHE), Decoding.get_cache_rare_chance(Items.STUDENT_CACHE_FOOTPRINT, Decoding.get_rare_chance(Decoding.CACHE, Items.STUDENT_CACHE_FOOTPRINT))])
		var rares = 0; var streak_max = 0
		Decoding.rare_tracker = {}
		var logs = [0, 0, 0]
		for i in 20000:
			for d in Decoding.roll_loot(Items.STUDENT_CACHE, Decoding.CACHE):
				if d.rare and d.item == Items.PARENTS_CREDIT_CARD: rares += 1
				if d.item == Items.LOGS: logs[0] += d.amount
			streak_max = max(streak_max, int(Decoding.rare_tracker.get("Student cache", 0)))
		for i in 20000:
			for d in Decoding.roll_loot(Items.STUDENT_CACHE, Decoding.CACHE, "survey"):
				if d.item == Items.LOGS: logs[1] += d.amount
		_all(0)
		for i in 20000:
			for d in Decoding.roll_loot(Items.STUDENT_CACHE, Decoding.CACHE):
				if d.item == Items.LOGS: logs[2] += d.amount
		print("20k caches all max: rare/cache %.4f (no tracker would be %.4f), longest dry streak %d | logs/cache max %.1f survey %.1f base %.1f" % [rares / 20000.0, 0.095, streak_max, logs[0] / 20000.0, logs[1] / 20000.0, logs[2] / 20000.0])
		var ex = [0, 0]
		for i in 50000:
			if Exploits.roll_drops(Items.STUDENT_CACHE, Decoding.CACHE).size() > 0: ex[0] += 1
			if Exploits.roll_drops(Items.STUDENT_CACHE, Decoding.CACHE, Decoding.FORENSICS_EXPLOIT_MULT).size() > 0: ex[1] += 1
		print("one-time item per cache: normal %.4f forensics %.4f" % [ex[0] / 50000.0, ex[1] / 50000.0])
		# field notes
		_setpkg("decoding.field_notes", 99)
		Decoding.intel.erase(Decoding.intel_key(stu))
		Decoding.add_intel_point(stu)
		print("field notes: first find -> %s, max hacks %d | %s" % [str(Decoding.get_intel(stu)), Decoding.intel_max_hacks(), Decoding.intel_text(stu)])
		print("index target for Student cache Network: ", Decoding.target_for_cache(Items.STUDENT_CACHE_NETWORK).get("name", "none"))
	if part == "2":
		Decoding.first_cache_decoded = true
		Inventory.add_resource(Items.STUDENT_CACHE, 5000)
		var S = float(OS.get_environment("SECS")) if OS.get_environment("SECS") != "" else 300.0
		await _scen("cache base", Decoding.CACHE, S * 2)
		_all(99)
		Decoding.rare_tracker = {}
		await _scen("cache max tracks", Decoding.CACHE, S)
		Decoding.intel.erase(Decoding.intel_key(stu))
		await _scen("cache index", Decoding.CACHE, S / 2, null, "index")
		await _scen("cache forensics", Decoding.CACHE, S / 2, null, "forensics")
		await _scen("cache survey", Decoding.CACHE, S / 2, null, "survey")
	if part == "3":
		# intel build-up: 2% per stat per find, +1 hack each full round, up to 10% / 15 hacks
		Decoding.intel.erase(Decoding.intel_key(stu))
		for n in 36:
			Decoding.add_intel_point(stu)
			if n in [0, 3, 4, 8, 9, 23, 24, 34]:
				print("intel after %2d finds: %s" % [n + 1, str(Decoding.get_intel(stu))])
		print("maxed: %s | %s" % [Decoding.is_intel_maxed(stu), Decoding.intel_text(stu)])
	get_tree().quit()
