extends Node
## Hacking upgrade fights. SCEN=A (L10, School, no upgrades), B (L45, 4 locations, tiers 1-4 vs none),
## C (L99, all locations, all max + capstones vs none). N fights per target.
var game
var ended := false
func _ready() -> void:
	_run.call_deferred()
func _up_to_tier(t: int) -> void:
	for id in Upgrades.packages:
		if id.begins_with("hacking."):
			var p = Upgrades.packages[id]
			p.installed = p.levels.filter(func(l): return int(l.tier) <= t).size()
			Upgrades._recompute(p)
	Upgrades.apply_effects()
func _setup(level: int, locs: int) -> void:
	Hacking.SKILL.level = level
	Hacking.SKILL.experience = Exp.xp_for_level(level)
	var i = 0
	for loc in Stats.hacking_targets:
		Stats.hacking_targets[loc].unlocked = i < locs
		for list in ["targets", "hard mode targets"]:
			for t in Stats.hacking_targets[loc].get(list, []): t.unlocked = true
		i += 1
	Stats.set_max_anon()
	print("    Hacking L%d, %d locations -> max anon %d" % [Hacking.SKILL.level, locs, Stats.max_anon])
func _find(loc: String, name: String, hard := false) -> Dictionary:
	for t in Stats.hacking_targets[loc]["hard mode targets" if hard else "targets"]:
		if t.name == name: return t
	return {}
func _fights(label: String, target: Dictionary, n: int) -> void:
	var wins = 0; var tsum = 0.0; var sql0 = Inventory.get_amount(Items.SQL_INJECTOR); var sp0 = Inventory.get_amount(Items.PACKET_SPOOF)
	var anon_end = 0.0
	for k in n:
		HackingMods.current_mods.clear()
		game = load("res://scenes/hacking_game.tscn").instantiate(); add_child(game)
		ended = false
		var w0 = Stats.get_wins(target)
		game.setup(target, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, false)
		await game.prepare()
		game.start_hack()
		var t = 0.0
		while !ended and t < 600.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			Stats.system_tempature = 30.0; Stats.overheated = false
		if OS.get_environment("LOG") != "" and k == 0:
			print(game.log_rtl.get_parsed_text().right(int(OS.get_environment("LOGN")) if OS.get_environment("LOGN") != "" else 1400))
		if Stats.get_wins(target) > w0:
			wins += 1; tsum += game.fight_time; anon_end += Stats.current_anon / float(Stats.max_anon)
		game.queue_free()
		await get_tree().process_frame
	print(">>> %-34s max anon %4d | heal %3d (%2.0f%%) | wins %d/%d | avg fight %.0fs | anon left %.0f%% | SQL/fight %.0f | spoofs/fight %.1f" % [label, Stats.max_anon, int(ceil(Stats.max_anon * (0.05 + Upgrades.cur("hacking.healing")))), (0.05 + Upgrades.cur("hacking.healing")) * 100, wins, n, tsum / max(1, wins), anon_end / max(1, wins) * 100, float(sql0 - Inventory.get_amount(Items.SQL_INJECTOR)) / n, float(sp0 - Inventory.get_amount(Items.PACKET_SPOOF)) / n])
func _run() -> void:
	for i in 30: await get_tree().process_frame # let Exp.DEV_MAX_ALL apply first (it sets every level to 99)
	Engine.max_fps = 0
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 30.0
	Signals.hacking_ended_signal.connect(func(): ended = true)
	var n = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 3
	for it in [Items.SQL_INJECTOR, Items.PACKET_SPOOF]: Inventory.add_resource(it, 100000)
	for loc in Stats.hacking_targets:
		var p = Stats.hacking_targets[loc].get("required payload")
		if p: Inventory.add_resource(p, 10000)
	var sc = OS.get_environment("SCEN")
	if sc == "A":
		_setup(10, 1); _up_to_tier(0)
		await _fights("L10 none: Student", _find("School", "Student"), n)
		await _fights("L10 none: Superintendent", _find("School", "Superintendent"), n)
		await _fights("L10 none: Student (Hard)", _find("School", "Student (Hard)", true), n)
		_up_to_tier(1)
		await _fights("L10 tier1: Student (Hard)", _find("School", "Student (Hard)", true), n)
	if sc == "B":
		_setup(45, 4)
		for t in [0, 4]:
			_up_to_tier(t)
			await _fights("L45 tiers<=%d: Teller" % t, _find("Bank", "Teller"), n)
			await _fights("L45 tiers<=%d: Chief Financial Officer" % t, _find("Bank", "Chief Financial Officer"), n)
	if sc == "C":
		_setup(99, 6)
		for t in ([6] if OS.get_environment("LOG") != "" else [0, 6]):
			_up_to_tier(t)
			await _fights("L99 tiers<=%d: Analyst" % t, _find("Government", "Analyst"), n)
			await _fights("L99 tiers<=%d: President" % t, _find("Government", "President"), n)
	get_tree().quit()
