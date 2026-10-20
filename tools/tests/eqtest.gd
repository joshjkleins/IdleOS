extends Node
## One School fight per equippable mod (time scaled): checks every effect runs and logs its line.
var os
var game
var ended := false
func _ready() -> void:
	_run.call_deferred()
func _fight(target: Dictionary, mods: Array) -> Dictionary:
	HackingMods.current_mods.clear()
	for m in mods: HackingMods.add_mod(m)
	Hacking.SKILL.level = 1; Stats.set_max_anon()
	Stats.healing_threshold_auto_start = 1.0 # spoof all fight (exercises the spoof mods)
	Stats.system_tempature = 30.0; Stats.overheated = false; Stats.overclocked = false
	game = load("res://scenes/hacking_game.tscn").instantiate(); add_child(game)
	ended = false
	var w0 = Stats.get_wins(target)
	game.setup(target, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, false)
	await game.prepare()
	var t = 0.0
	while !ended and t < 600.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	var log = game.log_rtl.get_parsed_text()
	var r = {"won": Stats.get_wins(target) > w0, "time": game.fight_time, "anon": Stats.current_anon, "log": log}
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
	Engine.time_scale = 30.0
	Signals.hacking_ended_signal.connect(func(): ended = true)
	for it in [Items.SQL_INJECTOR, Items.PACKET_SPOOF, Items.SCHOOL_PAYLOAD]: Inventory.add_resource(it, 100000)
	Hacking.SKILL.level = 1; Stats.set_max_anon() # 100 anonymity: spoofs and losses happen
	for id in ["hacking.firewall"]:
		var pk = Upgrades.packages[id]; pk.installed = pk.levels.size(); Upgrades._recompute(pk) # firewall breaks happen
	var tg = Stats.hacking_targets["School"].targets[int(OS.get_environment("TGT")) if OS.get_environment("TGT") != "" else 2]
	var keys = {"SQL_BOOSTER": "attack", "SHATTER_PROTOCOL": "slowed", "BURST_BUFFER": "", "FIRMWARE_BRICK": "bricked", "PAYLOAD_AMPLIFIER": "",
		"VULN_SCANNER": "CRIT", "CRITICAL_OVERFLOW": "CRIT", "PROXY_CHAIN": "Packet Spoof", "GHOST_PACKET": "Packet Spoof", "DECOY_TRAFFIC": "Decoy",
		"PACKET_SHREDDER": "firewall", "LATENCY_INJECTOR": "", "SILENT_ENTRY": "Silent Entry", "IP_ROTATOR": "", "ZERO_HOUR": "", "CASCADE": "Cascade",
		"MIRROR": "Mirror", "COLD_BOOT": ""}
	var base = await _fight(tg, [])
	print(">>> none: won %s in %.0fs, anon %d" % [base.won, base.time, base.anon])
	for k in keys:
		var r = await _fight(tg, [Items.get(k)])
		var hit = keys[k] == "" or keys[k] in r.log
		print(">>> %-18s won %-5s %4.0fs  anon %4d  %s" % [k, r.won, r.time, r.anon, "" if hit else "(no '%s' in log)" % keys[k]])
		if OS.get_environment("SHOW") == k:
			print(r.log.left(3000))
	get_tree().quit()
