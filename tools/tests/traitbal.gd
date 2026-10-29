extends Node
## Phase 5 (2026-10-27): live fights per target and build, for the target traits (Stats.TRAITS).
## TIER=1|2 (School / Lawfirm), GEAR=late|early (apt hacking + system tiers <= TIER, or < TIER), N fights each,
## ONLY=<target name part>, SETTRAITS=<trait[,trait]> replaces the tested targets' traits (to try new ones). Builds: base (no mods / drivers / exploits), wrong (raw damage), right (answers the trait).
## Each sample is a RUN of RUN hacks (anonymity carries over, like 'hack x=5'): prints hacks won per run, time and
## SQL / spoofs per win, anonymity left at the end of the run.
var os
var game
var ended := false
const LEVEL_AT_TIER = [12, 25, 40, 55, 70, 85]

func _ready() -> void:
	_run.call_deferred()

func _item(n: String) -> ItemData:
	return Inventory.get_item_by_name(n)

## build: {mods: [mod item names], drivers: [driver ids], auto: exploit item name or ""}
const BUILDS = {
	"base": {},
	"wrong": {"mods": ["SQL Booster", "Payload Amplifier"], "drivers": ["optimized_build"]},
	"fortress": {"mods": ["Handshake Exploit", "Breach Strike"], "drivers": ["credential_reuse", "cracked_wide", "session_hijack"], "auto": "Firewall Crack"},
	"heavy": {"mods": ["Hardened Shell", "Fresh Start"], "drivers": ["burner_account", "read_ahead", "social_proof"], "auto": "Proxy Hop"},
	"swarm": {"mods": ["Hardened Shell", "Reset Loop"], "drivers": ["cover_story", "countermeasure_log", "social_proof"], "auto": "Smoke Screen"},
	"siphon": {"mods": ["Burst Buffer", "SQL Booster"], "drivers": ["deep_reserves", "signal_boost", "cheap_spoof"], "auto": ""},
	"throttle": {"mods": ["Burst Buffer", "SQL Booster"], "drivers": ["deep_reserves", "steady_flow", "cheap_spoof"], "auto": ""},
	"regenerator": {"mods": ["SQL Booster", "Payload Amplifier"], "drivers": ["optimized_build", "steady_flow", "brute_force"], "auto": "Packet Flood"},
	"adaptive": {"mods": ["SQL Booster", "Payload Amplifier"], "drivers": ["optimized_build", "brute_force", "hash_collision"], "auto": "Overcharge"},
	"escalator": {"mods": ["SQL Booster", "Payload Amplifier"], "drivers": ["quick_compile", "warm_start", "read_ahead"], "auto": "Packet Flood"},
}

func _set_gear(tier: int, late: bool) -> void:
	var upto = tier if late else tier - 1
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		p.installed = p.levels.filter(func(l): return int(l.tier) <= upto).size() if (id.begins_with("hacking.") or id.begins_with("system.")) else 0
		Upgrades._recompute(p)
	var ic = Upgrades.packages.get("system.idle_cooling")
	if ic: ic.installed = 0; Upgrades._recompute(ic)
	Upgrades.apply_effects()
	HackingMods.refresh_slots()
	var lvl = int(OS.get_environment("LEVEL")) if OS.get_environment("LEVEL") != "" else LEVEL_AT_TIER[tier - 1] # LEVEL=12: skill levels
	for m in [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling, Hacking]:
		m.SKILL.level = lvl; m.SKILL.experience = Exp.xp_for_level(lvl)
		Exp.refresh_efficiency(m)
	Hacking.SKILL.efficiency = 0.05 + 0.00255 * (lvl - 1)

func _equip(build: Dictionary, tier: int) -> void:
	HackingMods.current_mods.clear()
	var slots = HackingMods.max_mods
	for n in build.get("mods", []).slice(0, slots):
		var it = _item(n)
		if it and int(it.tier) <= tier:
			HackingMods.current_mods[it.hacking_mod_type] = {"duration": 99, "value": it.hacking_mod_value, "tier": it.tier}
	Drivers.equipped = {}
	for id in build.get("drivers", []):
		Drivers.grant(id)
		Drivers.owned[id] = 30000 # rank 2
		var sk = Drivers.DEFS[id].skill
		var l: Array = Drivers.equipped.get(sk, [])
		if l.size() < Drivers.slots(sk):
			l.append(id); Drivers.equipped[sk] = l
	Exploits.auto_id = ""
	var a = build.get("auto", "")
	if a != "":
		var it = _item(a)
		if it and int(it.tier) <= tier:
			Inventory.add_resource(it, 50)
			Exploits.auto_id = str(it.exploit_id)

var wins_seen := 0
func _fight(target: Dictionary, run: int) -> Dictionary:
	Decoding.intel.erase(Decoding.intel_key(target))
	if OS.get_environment("INTEL") != "0": # INTEL=0: no intel; default: full intel (-10% on every stat) for the run
		Decoding.intel[Decoding.intel_key(target)] = {"lv": [5, 5, 5, 5, 5], "dur": 99, "hacks": 99}
	Stats.set_max_anon()
	Stats.current_anon = Stats.max_anon
	Stats.system_tempature = 30.0; Stats.overheated = false; Stats.overclocked = false
	Exploits.set_charge(0)
	game = load("res://scenes/hacking_game.tscn").instantiate(); add_child(game)
	ended = false
	var w0 = Stats.get_wins(target)
	var sql0 = Inventory.get_amount(Items.SQL_INJECTOR); var sp0 = Inventory.get_amount(Items.PACKET_SPOOF)
	game.setup(target, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, run, Upgrades.can_overclock(Hacking))
	await game.prepare()
	var t = 0.0
	var fight = 0.0
	while !ended and t < 600.0 * run:
		await get_tree().process_frame
		t += get_process_delta_time()
		if !game.is_hacking: continue
		fight += get_process_delta_time()
		if Upgrades.can_overclock(Hacking):
			if Stats.overclocked and Stats.system_tempature > 90.0: Stats.overclocked = false
			elif !Stats.overclocked and Stats.system_tempature < 60.0 and !Stats.overheated: Stats.overclocked = true
	if OS.get_environment("DBG") != "": # DBG=ATK,FW: print the first log lines with these tags
		var tags = Array(OS.get_environment("DBG").split(","))
		var lines = []
		for l in game.log_rtl.get_parsed_text().split("\n"):
			for tg in tags:
				if tg in l:
					lines.append(l)
					break
		print(">>> max anon %d · log:\n   %s" % [Stats.max_anon, "\n   ".join(lines.slice(0, int(OS.get_environment("DBGN")) if OS.get_environment("DBGN") != "" else 16))])
	var r = {"wins": Stats.get_wins(target) - w0, "time": fight, "anon": float(Stats.current_anon) / max(1.0, float(Stats.max_anon)),
		"sql": sql0 - Inventory.get_amount(Items.SQL_INJECTOR), "spoof": sp0 - Inventory.get_amount(Items.PACKET_SPOOF)}
	if !ended: game.stop_hacking = true
	game.queue_free()
	for i in 3: await get_tree().process_frame
	return r

func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	for e in Tutorial.TUTORIAL_ORDER: if !(e in Tutorial.completed_events): Tutorial.completed_events.append(e)
	Engine.max_fps = 0
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 30.0
	Signals.hacking_ended_signal.connect(func(): ended = true)
	var tier = int(OS.get_environment("TIER")) if OS.get_environment("TIER") != "" else 1
	var late = OS.get_environment("GEAR") != "early"
	var n = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 3
	var only = OS.get_environment("ONLY").to_lower()
	var run = int(OS.get_environment("RUN")) if OS.get_environment("RUN") != "" else 5
	_set_gear(tier, late)
	var li = 0
	for l in Stats.hacking_targets.values(): # only the locations a player at this tier has (max anonymity grows with them)
		li += 1
		l.unlocked = li <= tier
	Inventory.add_resource(Items.SQL_INJECTOR, 200000); Inventory.add_resource(Items.PACKET_SPOOF, 100000)
	var loc = Stats.hacking_targets.values()[tier - 1]
	Inventory.add_resource(loc["required payload"], 10000)
	Stats.set_max_anon()
	print(">>> TIER %d %s gear · hacking L%d · mod slots %d · +%d max bandwidth · max anonymity %d" % [tier, "late" if late else "early", Hacking.SKILL.level, HackingMods.max_mods, int(Upgrades.cur("hacking.max_bandwidth")), int(Stats.max_anon)])
	for target in loc.targets:
		if only.begins_with("="):
			if target.name.to_lower() != only.substr(1): continue # ONLY==name: exact
		elif only != "" and !(only in target.name.to_lower()): continue
		target.unlocked = true
		var st = OS.get_environment("SETTRAITS") # SETTRAITS=adaptive (or a,b): try traits on the tested targets
		if st != "":
			target["traits"] = Array(st.split(","))
		var traits = Stats.target_traits(target)
		var builds = ["base", "wrong"]
		for tr in traits:
			if BUILDS.has(tr): builds.append(tr)
		for b in builds:
			_equip(BUILDS[b], tier)
			var won = 0; var tt = 0.0; var an = 0.0; var sq = 0.0; var spf = 0.0
			for i in n:
				var r = await _fight(target, run)
				won += r.wins; tt += r.time; an += r.anon; sq += r.sql; spf += r.spoof
			var w = max(1, won)
			print(">>> %-20s %-12s %-11s hacks %4.1f/%d  %4ds/win  sql %3d/win  spoof %3d/win  anon end %3d%%" % [target.name, ",".join(traits) if !traits.is_empty() else "-", b, float(won) / n, run, int(tt / w), int(sq / w), int(spf / w), int(100 * an / n)])
	get_tree().quit()
