extends Node
## Offline vs live: each scenario runs live for SECS game seconds (heat held at 30, no overclock), then the same
## process is snapshotted and Offline.compute() works out 1 h away. Prints both per hour for the top items.
var os
func _ready() -> void:
	_run.call_deferred()
func _inv() -> Dictionary:
	return Inventory.inventory.duplicate()
func _diff(a: Dictionary, b: Dictionary) -> Dictionary:
	var d = {}
	for k in b:
		var n = int(b[k]) - int(a.get(k, 0))
		if n != 0: d[k] = n
	for k in a:
		if !b.has(k) and int(a[k]) != 0: d[k] = -int(a[k])
	return d
func _fmt(d: Dictionary, h: float) -> String:
	var ks = d.keys(); ks.sort_custom(func(x, y): return abs(d[x]) > abs(d[y]))
	return ", ".join(ks.slice(0, 4).map(func(k): return "%s %+.0f" % [k.name, d[k] / h]))
func _cmd(c: String) -> void:
	os._on_input_line_text_submitted(c)
	for i in 3: await get_tree().process_frame
func _scen(label: String, skill: String, command: String, secs: float, setup: Callable = func(): pass) -> void:
	await _cmd("kill")
	await _cmd("cd ..")
	await _cmd("cd " + skill)
	setup.call()
	Stats.system_tempature = 30.0; Stats.overheated = false; Stats.overclocked = false
	await _cmd(command)
	if !os.process_running:
		print(">>> %-22s did not start ('%s')" % [label, command]); return
	for i in 10: await get_tree().process_frame
	var a = _inv(); var u0 = Uploads.staged.duplicate()
	var t = 0.0
	while t < secs and os.process_running:
		await get_tree().process_frame
		t += get_process_delta_time()
		Stats.system_tempature = 30.0; Stats.overheated = false
	var live = _diff(a, _inv())
	var snap = Offline.snapshot()
	var hot = Offline._runs_hot(Offline._job(Offline._skill(snap.get("skill", "")), Offline._find_process(Offline._skill(snap.get("skill", "")), snap.get("process", "")), snap)) if !snap.is_empty() else false
	await _cmd("kill")
	for i in 5: await get_tree().process_frame
	var b = _inv(); var u1 = Uploads.staged.duplicate()
	Offline.session = {"saved_at": int(Time.get_unix_time_from_system()) - 3600, "process": snap}
	Offline.compute()
	var off = _diff(b, _inv())
	var r = Offline.report
	print(">>> %-22s live %4.0fs: %s" % [label, t, _fmt(live, t / 3600.0)])
	print("    %-22s offline 1h: %s%s | ran %.0fs%s" % ["", _fmt(off, 1.0), ("  staged +" + str(int(Uploads.get_staged(Items.LOGS)) - int(u1.get(Items.LOGS, 0)))) if command.contains("package") else "", r.get("ran", 0.0), "  RAN HOT (-10%)" if r.get("overheat", false) else ""])
	Offline.report = {}
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	os.accepting_player_inputs = true
	Offline.report = {}
	Engine.max_fps = 0
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 10.0
	var S = float(OS.get_environment("SECS")) if OS.get_environment("SECS") != "" else 600.0
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]; p.installed = 0; Upgrades._recompute(p)
	if OS.get_environment("MAX") != "":
		for id in Upgrades.packages:
			if !id.begins_with("system.") and !id.begins_with("hacking."):
				var p = Upgrades.packages[id]; p.installed = p.levels.size(); Upgrades._recompute(p)
	Upgrades.apply_effects()
	for it in [Items.LOGS, Items.ENCRYPTED_PASSWORDS, Items.USERNAMES, Items.PASSWORDS, Items.IP_ADDRESS, Items.CREDENTIALS]: Inventory.add_resource(it, 200000)
	Inventory.add_resource(Items.STUDENT_CACHE, 20000)
	Decoding.first_cache_decoded = true
	var only = OS.get_environment("ONLY")
	var sc = [
		["mining logs", "mining", "mine -logs"],
		["parsing footprint", "parsing", "parse -footprint=logs"],
		["cracking password", "cracking", Cracking.minor_processes[0].command],
		["matching credentials", "matching", Matching.minor_processes[0].command],
		["phishing spear", "phishing", "phish -spear"],
		["phishing spear bait", "phishing", "phish -spear bait=logs"],
		["phishing whaling", "phishing", Phishing.WHALING.command],
		["decoding cache", "decoding", "decode -cache=student cache"],
		["decoding package", "decoding", "decode -package=logs 1000"],
		["compiling school", "compiling", "compile -school"],
	]
	for s in sc:
		if only == "" or s[0].begins_with(only):
			await _scen(s[0], s[1], s[2], S)
	get_tree().quit()
