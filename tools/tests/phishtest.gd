extends Node
## Phishing checks: spear (+bait), mod pool, whaling, smish (intel), trap (set / partial / full / save), tokens.
var term
var events := 0

func _ready() -> void:
	_run.call_deferred()

func _cool() -> void:
	Stats.system_tempature = 30.0
	Stats.overheated = false

func _amounts(items: Array) -> Array:
	return items.map(func(i): return Inventory.get_amount(i))

func _scenario(name: String, proc: Dictionary, seconds: float, bait: ItemData = null, target: Dictionary = {}) -> void:
	var watch = [Items.SQL_INJECTOR, Items.PACKET_SPOOF, Items.VM_PHISHING_TOKEN, Items.LOGS, Items.SQL_BOOSTER]
	var before = _amounts(watch)
	var ex_before = 0
	for e in Exploits.get_items():
		ex_before += Inventory.get_amount(e)
	var xp0 = proc.experience
	events = 0
	term = Phishing.terminal_scene.instantiate()
	add_child(term)
	term.cast_lines(proc, -1, bait, target)
	var t = 0.0
	while t < seconds and term.running:
		await get_tree().process_frame
		t += get_process_delta_time()
		_cool()
	var after = _amounts(watch)
	var ex_after = 0
	for e in Exploits.get_items():
		ex_after += Inventory.get_amount(e)
	var d = {}
	for i in watch.size():
		d[watch[i].name] = after[i] - before[i]
	var hrs = t / 3600.0
	print(">>> %s (%.0f game-min): %s | exploits +%d | events %d | xp +%d | tokens/hr %.2f | label: %s" % [name, t / 60.0, d, ex_after - ex_before, events, proc.experience - xp0, d[Items.VM_PHISHING_TOKEN.name] / hrs, term.slots_label.text.get_slice("\n", 0)])
	if term.running:
		term.stop()
	term.queue_free()
	Phishing.current_lines.clear()
	await get_tree().process_frame

func _run() -> void:
	Engine.time_scale = 300.0
	for s in [Phishing.spear_cycle_completed, Phishing.whale_cycle_completed]:
		s.connect(func(_a): events += 1)
	Inventory.add_resource(Items.LOGS, 100000)
	var part = OS.get_environment("PART")
	print("eff: spear %.3f whale %.3f smish %.3f trap %.3f mod %.4f | mod pool %s" % [Phishing.SPEAR.efficiency, Phishing.WHALING.efficiency, Phishing.SMISH.efficiency, Phishing.TRAP.efficiency, Phishing.MOD.efficiency, Phishing.mod_pool().map(func(e): return e.item.name)])
	if part == "" or part == "1":
		await _scenario("spear", Phishing.SPEAR, 2 * 3600)
		await _scenario("spear bait=logs", Phishing.SPEAR, 3600, Items.LOGS)
		var old = Phishing.MOD.efficiency
		Phishing.MOD.efficiency = 1.0
		await _scenario("mod (eff forced 100%)", Phishing.MOD, 600)
		Phishing.MOD.efficiency = old
	if part == "" or part == "2":
		await _scenario("whaling", Phishing.WHALING, 2 * 3600)
		await _scenario("whaling bait", Phishing.WHALING, 3600, Items.LOGS)
	if part == "" or part == "3":
		var student = Decoding.find_target("student")
		Decoding.intel.clear()
		await _scenario("smish target=student", Phishing.SMISH, 1800, null, student)
		print("    student intel: ", Decoding.intel_text(student), "  others: ", Decoding.intel.size() - 1)
		Decoding.intel.clear()
		await _scenario("smish random bait", Phishing.SMISH, 1800, Items.LOGS)
		print("    targets with intel: ", Decoding.intel.size())
		# trap: set through the terminal, then fake the clock
		Phishing.trap = {}
		await _scenario("trap set (bait)", Phishing.TRAP, 600, Items.LOGS)
		print("    has_trap=%s progress=%.3f status: %s" % [Phishing.has_trap(), Phishing.trap_progress(), Phishing.trap_status_text()])
		var saved = Phishing.save_data()
		Phishing.trap = {}
		Phishing.load_data(saved)
		print("    after save/load: has_trap=%s baited=%s mult=%s" % [Phishing.has_trap(), Phishing.trap.get("baited"), Phishing.trap.get("bait_mult")])
		Phishing.trap.set_at -= int(Phishing.trap_seconds_total() * 0.5)
		print("    half: ", Phishing.trap_status_text())
		print("    collect: ", Phishing.trap_command_text(" collect"))
		var full = {"sql": 0, "rare": 0}
		for i in 200:
			Phishing.set_trap(null)
			Phishing.trap.set_at -= int(Phishing.trap_seconds_total()) + 5
			for g in Phishing.collect_trap():
				if g.item == Items.SQL_INJECTOR: full.sql += g.amount
				elif g.item != Items.PACKET_SPOOF and g.item != Items.VM_PHISHING_TOKEN: full.rare += 1
		print("    200 full traps (no bait): avg SQL %.1f, rare drops %d (eff %.3f -> expect ~%.0f exploit + ~%.0f mod)" % [full.sql / 200.0, full.rare, Phishing.TRAP.efficiency, 200 * Phishing.TRAP.efficiency, 200 * Phishing.TRAP.efficiency / 5])
		print("    no trap: ", Phishing.trap_command_text(" collect"))
	print(">>> done")
	get_tree().quit()
