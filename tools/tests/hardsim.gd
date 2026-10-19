extends Node
## Demo: can the Student (Hard) be beaten? Every pair of the best demo mods, L10, demo System upgrades, full intel,
## overclock, Lag Spike + Proxy Hop used when affordable and useful. Runs inside idle_os_2 so cooling works.
var os
var game
var ended := false
const MODS = ["PARENTS_CREDIT_CARD", "VM_PARSING_TOKEN", "IP_ADDRESS", "SQL_BOOSTER", "VM_COMPILING_TOKEN", "SQL_INJECTOR", "STUDENT_CACHE", "VM_PHISHING_TOKEN", "VM_CRACKING_TOKEN"]
func _ready() -> void:
	_run.call_deferred()
func _item(n: String) -> ItemData:
	return Items.get(n)
func _fight(mods: Array, oc: bool, spoof_policy: String) -> Dictionary:
	var hard = Stats.hacking_targets["School"]["hard mode targets"][0]
	for k in ["counter", "counter speed", "firewall", "integrity"]:
		var e = OS.get_environment(k.replace(" ", "_").to_upper())
		if e != "": hard[k] = float(e) if k == "counter speed" else int(e)
	HackingMods.current_mods.clear()
	for m in mods: HackingMods.add_mod(_item(m))
	Decoding.intel[Decoding.intel_key(hard)] = {"amount": Decoding.intel_cap(hard), "hacks": 10}
	Stats.system_tempature = 30.0; Stats.overheated = false; Stats.overclocked = false
	game = load("res://scenes/hacking_game.tscn").instantiate(); add_child(game)
	ended = false
	var w0 = Stats.get_wins(hard)
	game.setup(hard, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, oc)
	await game.prepare()
	game.start_hack()
	var t = 0.0; var maxheat = 30.0; var oh = 0.0; var best = 0.0
	var lag = Exploits.get_item("lag_spike"); var hop = Exploits.get_item("proxy_hop")
	while !ended and t < 900.0:
		await get_tree().process_frame
		var dt = get_process_delta_time()
		t += dt
		maxheat = max(maxheat, Stats.system_tempature)
		if Stats.overheated: oh += dt
		if !game.is_hacking: continue
		best = max(best, 1.0 - game.integ_bar.value / game.integ_bar.max_value)
		# smart player: overclock off near overheat, back on when cool
		if oc:
			if Stats.overclocked and Stats.system_tempature > 90.0: Stats.overclocked = false
			elif !Stats.overclocked and Stats.system_tempature < 60.0 and !Stats.overheated: Stats.overclocked = true
		if spoof_policy == "always" and Inventory.get_amount(Items.PACKET_SPOOF) > 0 and Stats.current_anon < Stats.max_anon:
			game.defending = true
		if game._exploit_lock <= 0.0:
			if Stats.current_anon <= Stats.max_anon * 0.5 and Exploits.can_afford(hop) and game._exploit_blocked("proxy_hop") == "":
				game.use_exploit(hop)
			elif game.counter_bar.value >= 70.0 and Exploits.can_afford(lag):
				game.use_exploit(lag)
	if OS.get_environment("LOG") != "": print(game.log_rtl.get_parsed_text())
	var won = Stats.get_wins(hard) > w0
	var r = {"won": won, "time": t, "best": best, "maxheat": maxheat, "oh": oh}
	game.queue_free()
	await get_tree().process_frame
	return r
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	Engine.max_fps = 0
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 30.0
	Signals.hacking_ended_signal.connect(func(): ended = true)
	# demo System upgrades installed (cooling, heat reduction, VM windows)
	for id in Upgrades.packages:
		if id.begins_with("system."):
			var p = Upgrades.packages[id]; p.installed = p.levels.size(); Upgrades._recompute(p)
	Upgrades.apply_effects()
	Hacking.SKILL.level = 10
	Hacking.SKILL.experience = Exp.xp_for_level(10)
	Hacking.SKILL.efficiency = 0.05 + 0.0015 * 9
	print("L%d hacking, crit %.3f, max anon %d, max mods %d, cooling %.2f" % [Hacking.SKILL.level, Hacking.SKILL.efficiency, Stats.max_anon, HackingMods.max_mods, Stats.cooling_amount])
	for it in [Items.SQL_INJECTOR, Items.PACKET_SPOOF, Items.SCHOOL_PAYLOAD]: Inventory.add_resource(it, 100000)
	Inventory.add_resource(Exploits.get_item("lag_spike"), 100); Inventory.add_resource(Exploits.get_item("proxy_hop"), 100)
	var pairs = []
	if OS.get_environment("SEL") != "":
		for p in OS.get_environment("SEL").split(";"): pairs.append(p.split(","))
		pairs.append([])
	for i in (MODS.size() if OS.get_environment("SEL") == "" else 0):
		for j in range(i + 1, MODS.size()):
			pairs.append([MODS[i], MODS[j]])
	var a = int(OS.get_environment("FROM")); var b = min(pairs.size(), int(OS.get_environment("TO")))
	var oc = OS.get_environment("OC") != "0"
	var pol = OS.get_environment("POL") if OS.get_environment("POL") != "" else "auto"
	for k in range(a, b):
		var r = await _fight(pairs[k], oc, pol)
		print(">>> %2d %-40s %s | best %3.0f%% | %4.0fs | max heat %.0f | overheated %.0fs" % [k, " + ".join(pairs[k]), "WIN " if r.won else "lose", r.best * 100, r.time, r.maxheat, r.oh])
	get_tree().quit()
