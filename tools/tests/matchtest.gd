extends Node
## Matching upgrade checks: speed, recovery, efficiency, auto-correlate, hot cache, modifiers, tokens.
var term
var samples: Array = []

func _setpkg(id: String, levels: int) -> void:
	var p = Upgrades.packages[id]
	p.installed = min(levels, p.levels.size())
	Upgrades._recompute(p)

func _ready() -> void:
	_run.call_deferred()

func _reset_all() -> void:
	for id in Upgrades.packages:
		if id.begins_with("matching."):
			_setpkg(id, 0)

func _scenario(name: String, mod_cmd: String, n: int) -> Dictionary:
	var proc = Matching.CREDENTIAL
	var pay = Decoding.get_tier_resources(1)[6]
	Inventory.add_resource(Items.USERNAMES, 1000)
	Inventory.add_resource(Items.PASSWORDS, 1000)
	var u0 = Inventory.get_amount(Items.USERNAMES)
	var c0 = Inventory.get_amount(Items.CREDENTIALS)
	var p0 = Inventory.get_amount(pay)
	var x0 = proc.experience
	samples = []
	term = Matching.terminal_scene.instantiate()
	add_child(term)
	term.set_type(proc, true) # in_vm=true so finish doesn't poke the main terminal
	if mod_cmd != "":
		for m in Matching.MODIFIERS:
			if m.command == mod_cmd:
				term.modifier = m
	term.start()
	while samples.size() < n:
		await get_tree().process_frame
	term.running = false
	var used = u0 - Inventory.get_amount(Items.USERNAMES)
	var got = Inventory.get_amount(Items.CREDENTIALS) - c0
	var secs = 0.0
	var tok = 0.0
	var heat = 0.0
	for s in samples:
		heat += s.heat
		secs += s.secs
		tok += s.tok
	var r = {"name": name, "avg_s": snappedf(secs / n, 0.01), "inputs_used": used, "out": got,
		"payloads": Inventory.get_amount(pay) - p0, "tok_per_hr": snappedf(tok / secs * 3600.0, 0.01),
		"last_streak_bonus": snappedf(samples[-1].hot, 0.01), "heat": snappedf(heat / n, 0.01), "eff": snappedf(term._get_efficiency_total(), 0.001),
		"title": term.title_label.text, "sub": term.subtitle_label.text}
	print(">>> ", r)
	term.queue_free()
	await get_tree().process_frame
	return r

func _on_match(_a) -> void:
	if term:
		samples.append({"secs": term._match_seconds, "tok": term._token_chance(), "hot": term._hot_cache_bonus(), "heat": Stats.system_tempature - 30.0})
	Stats.system_tempature = 30.0
	Stats.overheated = false

func _run() -> void:
	Engine.time_scale = 60.0
	Matching.cred_cycle_completed.connect(_on_match)
	Matching.CREDENTIAL.level = 1
	Matching.CREDENTIAL.efficiency = 0.0
	Stats.system_tempature = 30.0
	Stats.overheated = false
	_reset_all()
	var part = OS.get_environment("PART")
	if part == "" or part == "1":
		await _scenario("baseline", "", 40)
	for id in ["matching.speed", "matching.recovery", "matching.efficiency", "matching.auto_correlate", "matching.hot_cache"]:
		_setpkg(id, 99)
	print("cur speed=%s rec=%s eff=%s auto=%s hot=%s" % [Upgrades.cur("matching.speed"), Upgrades.cur("matching.recovery"), Upgrades.cur("matching.efficiency"), Upgrades.cur("matching.auto_correlate"), Upgrades.cur("matching.hot_cache")])
	if part == "" or part == "1":
		await _scenario("all tracks max", "", 300)
	for id in ["matching.overclock","matching.rolodex","matching.prebuild","matching.correlate","matching.survey","matching.cold_storage"]:
		_setpkg(id, 1)
	if part != "3":
		await _scenario("+rolodex", "", 100)
		await _scenario("prebuild", "prebuild", 300)
	else:
		await _scenario("correlate", "correlate", 200)
		await _scenario("survey", "survey", 200)
		_setpkg("matching.cold_storage", 0)
		await _scenario("prebuild no cold", "prebuild", 20)
		await _scenario("correlate no cold", "correlate", 20)
		print("Upgrades.is_wired(Matching)=", Upgrades.is_wired("Matching"), " can_overclock=", Upgrades.can_overclock(Matching))
		print(">>> done")
		get_tree().quit()
		return
	await _scenario("correlate", "correlate", 200)
	await _scenario("survey", "survey", 200)
	print("Upgrades.is_wired(Matching)=", Upgrades.is_wired("Matching"), " can_overclock=", Upgrades.can_overclock(Matching))
	print(">>> done")
	get_tree().quit()
