extends Node
## Live-game mod check: for tier T (env MODTIER), a player arriving at that tier (Hacking upgrades of earlier tiers,
## level per combat pass), fights the tier's first and last normal target with no mod vs each of the tier's mods.
const LEVEL_AT_TIER = [1, 15, 30, 45, 60, 75]
const SCALE := 24.0
func _ready() -> void:
	_run.call_deferred()
var _peak := 0.0
func fight(t: Dictionary, mod_item) -> Dictionary:
	HackingMods.current_mods.clear()
	if mod_item: HackingMods.current_mods[mod_item.hacking_mod_type] = {"duration": 99, "value": mod_item.hacking_mod_value, "tier": mod_item.tier}
	Stats.system_tempature = 30.0; Stats.overheated = false
	Inventory.inventory[Items.SQL_INJECTOR] = 5000; Inventory.inventory[Items.PACKET_SPOOF] = 300
	Inventory.inventory[t.requirements.item] = 50
	var g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
	var cache0 = Inventory.get_amount(t.loot)
	g.setup(t, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, true) # overclocked, like the combat pass assumes
	await g.prepare()
	var sql0 = Inventory.get_amount(Items.SQL_INJECTOR)
	g.start_hack()
	var t0 = Time.get_ticks_msec()
	var last_anon = Stats.current_anon
	while g.is_hacking and Stats.current_anon > 0 and (Time.get_ticks_msec() - t0) < 25000:
		last_anon = Stats.current_anon
		_peak = max(_peak, Stats.system_tempature)
		await get_tree().process_frame
	var res = {"won": Inventory.get_amount(t.loot) > cache0 or g.caches_gained > 0 or g.integ_bar.value <= 0, "time": g.fight_time, "sql": sql0 - Inventory.get_amount(Items.SQL_INJECTOR), "anon": float(last_anon) / float(Stats.max_anon)}
	if OS.get_environment("MODLOG") == "1" and mod_item == null:
		print(g.log_rtl.get_parsed_text().left(2500))
		print("SQL dmg %d fw dmg %d atk spd %.1f bw %d/%.1f max anon %d target integ %d fw %d" % [g.ATTACK_AMOUNT, g.FIREWALL_DAMAGE, g.ATTACK_SPEED, g.MAX_BANDWIDTH, g.BANDWIDTH_RECOVERY_RATE, Stats.max_anon, t.integrity, t.firewall])
	g.stop_hacking = true; g.is_hacking = false
	g.queue_free()
	await get_tree().process_frame
	return res
func _run() -> void:
	for i in 30: await get_tree().process_frame
	var T = int(OS.get_environment("MODTIER")) if OS.get_environment("MODTIER") != "" else 1
	var LAST = OS.get_environment("MODLAST") == "1" # last target with this tier's upgrades too
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		if id.begins_with("hacking.") or id.begins_with("system."):
			var n = 0
			for l in p.levels: if int(l.tier) < T or (LAST and int(l.tier) == T): n += 1
			p.installed = n; Upgrades._recompute(p)
	Upgrades.apply_effects()
	Hacking.SKILL.level = LEVEL_AT_TIER[T - 1] + (14 if LAST else 0)
	Stats.set_max_anon()
	var cool = Timer.new(); add_child(cool); cool.wait_time = Stats.cooling_frequency; cool.timeout.connect(func(): Stats.update_tempature(Stats.get_cooling_amount())); cool.start()
	Engine.time_scale = SCALE
	var loc = Stats.hacking_targets.keys()[T - 1]
	var targets = Stats.hacking_targets[loc].targets
	for t in [targets[int(OS.get_environment("MODTARGET")) if OS.get_environment("MODTARGET") != "" else 0]]:
		var line = ">>> T%d %-16s" % [T, t.name]
		for m in [null] + HackingMods.pool_items(T):
			_peak = 0.0
			var w = 0; var tt = 0.0; var sq = 0; var an = 0.0
			for rep in 2:
				var r = await fight(t, m)
				w += 1 if r.won else 0; tt += r.time; sq += r.sql; an += r.anon
			line += "\n      %-18s peak %3d°C won %d/2  %4.0fs  %3d sql  %3d%% anon left" % [("none" if m == null else m.name), _peak, w, tt / 2, sq / 2, roundi(an / 2 * 100)]
		print(line)
	get_tree().quit()
