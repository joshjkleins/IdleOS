extends Node
## Student (Hard) tuning. STATS="counter,counter_speed,firewall,integrity". CASES="mods|policy|intel|n;..."
## mods = item constants joined by '+' (or 'none'), policy = early (re-spoof below 80%) / auto, intel = 1/0.
var os
var game
var ended := false
func _ready() -> void:
	_run.call_deferred()
func _fight(mods: Array, policy: String, intel: bool) -> Dictionary:
	var hard = Stats.hacking_targets["School"]["hard mode targets"][0]
	HackingMods.current_mods.clear()
	for m in mods: HackingMods.add_mod(Items.get(m))
	Decoding.intel.erase(Decoding.intel_key(hard))
	if intel:
		Decoding.intel[Decoding.intel_key(hard)] = {"amount": Decoding.intel_cap(hard), "hacks": 10}
	Stats.system_tempature = 30.0; Stats.overheated = false; Stats.overclocked = false
	game = load("res://scenes/hacking_game.tscn").instantiate(); add_child(game)
	ended = false
	var w0 = Stats.get_wins(hard)
	game.setup(hard, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, true)
	await game.prepare()
	game.start_hack()
	var t = 0.0; var best = 0.0
	var lag = Exploits.get_item("lag_spike"); var hop = Exploits.get_item("proxy_hop")
	while !ended and t < 900.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if !game.is_hacking: continue
		best = max(best, 1.0 - game.integ_bar.value / game.integ_bar.max_value)
		if Stats.overclocked and Stats.system_tempature > 90.0: Stats.overclocked = false
		elif !Stats.overclocked and Stats.system_tempature < 60.0 and !Stats.overheated: Stats.overclocked = true
		if policy == "early" and !game.defending and Stats.current_anon < Stats.max_anon * 0.8:
			game.manual_defense()
		if game._exploit_lock <= 0.0:
			if Stats.current_anon <= Stats.max_anon * 0.5 and Exploits.can_afford(hop) and game._exploit_blocked("proxy_hop") == "":
				game.use_exploit(hop)
			elif game.counter_bar.value >= 70.0 and Exploits.can_afford(lag):
				game.use_exploit(lag)
	var r = {"won": Stats.get_wins(hard) > w0, "time": t, "best": best}
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
	for id in Upgrades.packages:
		if id.begins_with("system."):
			var p = Upgrades.packages[id]; p.installed = p.levels.size(); Upgrades._recompute(p)
	Upgrades.apply_effects()
	Hacking.SKILL.level = 10
	Hacking.SKILL.experience = Exp.xp_for_level(10)
	Hacking.SKILL.efficiency = 0.05 + 0.0015 * 9
	for it in [Items.SQL_INJECTOR, Items.PACKET_SPOOF, Items.SCHOOL_PAYLOAD]: Inventory.add_resource(it, 100000)
	Inventory.add_resource(Exploits.get_item("lag_spike"), 100); Inventory.add_resource(Exploits.get_item("proxy_hop"), 100)
	if OS.get_environment("HEAL") != "":
		var ps: ItemData = Items.PACKET_SPOOF
		ps.heal = int(OS.get_environment("HEAL"))
	var st = OS.get_environment("STATS").split(",")
	var hard = Stats.hacking_targets["School"]["hard mode targets"][0]
	hard["counter"] = int(st[0]); hard["counter speed"] = float(st[1]); hard["firewall"] = int(st[2]); hard["integrity"] = int(st[3])
	var out = []
	for c in OS.get_environment("CASES").split(";"):
		var f = c.split("|")
		var mods = [] if f[0] == "none" else Array(f[0].split("+"))
		var wins = 0; var times = []; var bests = []
		for k in int(f[3]):
			var r = await _fight(mods, f[1], f[2] == "1")
			if r.won: wins += 1; times.append(int(r.time))
			bests.append(int(r.best * 100))
		out.append("%s: %d/%s %s %s" % [c, wins, f[3], ("win s " + str(times)) if wins else "", "best% " + str(bests)])
	print(">>> STATS %s\n    %s" % [OS.get_environment("STATS"), "\n    ".join(out)])
	get_tree().quit()
