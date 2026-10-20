extends Node
## Live fights vs combat_sim: CASES="tier,slot,scenario,intel;..." (scenario S1..S5 as combat_tune.py).
## Sets hacking + System upgrades to <upg> tiers, hacking level / locations as combat_sim.player, overclock policy
## on <60 C / off >90 C. Prints win%, avg time, avg anonymity left (wins only).
var os
var game
var ended := false
const LEVEL_AT_TIER = [1, 15, 30, 45, 60, 75]
const MODV = {"dmg": [0, [10, 20, 35, 55, 80, 120]], "fw_dmg": [3, [10, 20, 35, 55, 80, 120]], "atk_spd": [6, [.15, .2, .25, .3, .35, .4]],
	"band_rate": [5, [2, 3, 4, 5, 6, 7]], "crit": [1, [.03, .06, .09, .12, .15, .18]], "dr": [7, [7, 17, 32, 52, 77, 112]], "fw_red": [2, [15, 30, 53, 83, 120, 180]]}
func _ready() -> void:
	_run.call_deferred()
const EXTRA = {"S3": ["hacking.damage", "hacking.firewall"],
	"S4": ["hacking.damage", "hacking.firewall", "hacking.bandwidth_recovery", "hacking.max_bandwidth", "hacking.healing", "hacking.mod_slots"]}
const MOD_ORDER = ["dmg", "fw_dmg", "atk_spd", "band_rate", "crit", "dr", "fw_red"]
func _set_upg(full: int, extra: Array) -> void:
	for id in Upgrades.packages:
		if !(id.begins_with("hacking.") or id.begins_with("system.")): continue
		var p = Upgrades.packages[id]
		var t = full + 1 if id in extra else full
		p.installed = p.levels.filter(func(l): return int(l.tier) <= t).size(); Upgrades._recompute(p)
	# Idle Cooling never applies during a real hack (this test runs the fight outside the hacking screen)
	var ic = Upgrades.packages["system.idle_cooling"]; ic.installed = 0; Upgrades._recompute(ic)
	Upgrades.apply_effects()
func _fight(target: Dictionary, intel: float, mods: Dictionary, tier: int) -> Dictionary:
	HackingMods.current_mods.clear()
	for k in mods: HackingMods.current_mods[k] = {"duration": 99, "value": mods[k], "tier": tier}
	Decoding.intel.erase(Decoding.intel_key(target))
	if intel > 0: Decoding.intel[Decoding.intel_key(target)] = {"amount": int(Decoding.intel_cap(target) * intel), "hacks": 99}
	var lvl = LEVEL_AT_TIER[tier - 1]
	Hacking.SKILL.level = lvl; Hacking.SKILL.experience = Exp.xp_for_level(lvl); Hacking.SKILL.efficiency = 0.05 + 0.00255 * (lvl - 1)
	Stats.set_max_anon()
	Stats.system_tempature = 30.0; Stats.overheated = false; Stats.overclocked = false
	game = load("res://scenes/hacking_game.tscn").instantiate(); add_child(game)
	ended = false
	var w0 = Stats.get_wins(target)
	game.setup(target, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, true)
	await game.prepare()
	var t = 0.0
	var last_anon = 0.0
	while !ended and t < 900.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if !game.is_hacking: continue
		last_anon = float(Stats.current_anon) / max(1.0, float(Stats.max_anon))
		if Stats.overclocked and Stats.system_tempature > 90.0: Stats.overclocked = false
		elif !Stats.overclocked and Stats.system_tempature < 60.0 and !Stats.overheated: Stats.overclocked = true
	var r = {"won": Stats.get_wins(target) > w0, "time": game.fight_time, "anon": last_anon, "log": game.log_rtl.get_parsed_text()}
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
	var locs = Stats.hacking_targets.keys()
	for c in OS.get_environment("CASES").split(";"):
		var f = c.split(",")
		var tier = int(f[0]); var slot = int(f[1]); var sc = f[2]
		for i in locs.size(): Stats.hacking_targets[locs[i]].unlocked = i < tier
		_set_upg(tier if sc == "S5" else tier - 1, EXTRA.get(sc, []))
		var nm = {"S1": 0, "S2": 1, "S3": 2}.get(sc, 99)
		nm = min(nm, HackingMods.max_mods)
		var mods = {}
		for k in MOD_ORDER.slice(0, nm): mods[int(MODV[k][0])] = MODV[k][1][tier - 1]
		var target = Stats.hacking_targets[locs[tier - 1]].targets[slot - 1]
		for it in [Items.SQL_INJECTOR, Items.PACKET_SPOOF, target.requirements.item]: Inventory.add_resource(it, 100000)
		var n = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 8
		var wins = 0; var tt = 0.0; var aa = 0.0
		for k in n:
			var r = await _fight(target, float(f[3]), mods, tier)
			if OS.get_environment("SHOW") != "": print(r.log.left(5000))
			if r.won: wins += 1; tt += r.time; aa += r.anon
		print(">>> %s  %-22s win %3d%%  %4ds  anon %3d%%" % [c, target.name, wins * 100 / n, int(tt / max(1, wins)), int(aa / max(1, wins) * 100)])
	get_tree().quit()
