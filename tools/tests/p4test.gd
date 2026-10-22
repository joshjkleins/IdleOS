extends Node
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _run() -> void:
	for i in 30: await get_tree().process_frame
	# apt: finish mining tier 1, tier 2 locked
	for p in Upgrades.group_packages("Mining"):
		var n = 0
		for l in p.levels:
			if int(l.tier) == 1: n += 1
		p.installed = n; Upgrades._recompute(p)
	Upgrades.apply_effects()
	print("tier2 unlocked? ", Upgrades.tier_unlocked(2), " working ", Upgrades.working_tier("Mining"))
	var root = _strip(ContextCommands.get_root_upgrades_text())
	for l in root.split("\n"):
		if l.to_lower().contains("mining"): print("ROOT| ", l)
	print(_strip(ContextCommands.get_skill_upgrades_text("Mining")))
	# exploits / force
	var ph = Exploits.get_item("proxy_hop"); Inventory.add_resource(ph, 2)
	print("find_forced: ", Exploits.find_forced("proxy hop -force"), " / ", Exploits.find_forced("Proxy-Hop -force"), " / ", Exploits.find_forced("heal -force"))
	for t in ["prox", "proxy hop -", "cd ~"]:
		var r = CommandRegistry.complete(t, true); print("[hack] '%s' -> '%s' %s" % [t, r.text, r.options])
	for t in ["ssh decoding intel=v", "ssh decoding intel=vice p", "decode -intel=v"]:
		var r = CommandRegistry.complete(t); print("'%s' -> '%s' %s" % [t, r.text, r.options])
	print(_strip(Exploits.list_text(false)).substr(0, 400))
	# mods table
	HackingMods.current_mods[HackingMods.MOD_TYPE.BW_PCT_REGEN] = {"duration": 3, "value": 0.2, "tier": 1}
	HackingMods.current_mods[HackingMods.MOD_TYPE.COUNTER_SLOW_PCT] = {"duration": 3, "value": 0.2, "tier": 1}
	print(_strip(ContextCommands.get_mod_command()))
	# defrag
	print("defrag reqs ok: ", Defragging.minor_processes.map(func(p): return Defragging.has_requirements(p)))
	print(_strip(ContextCommands.get_help_text_defragging(Defragging)).right(700))
	print("rare chance cache %.2f deep %.2f eff mult %.3f" % [Decoding.get_rare_chance(Decoding.CACHE), Decoding.get_rare_chance(Decoding.DEEP), Decoding.efficiency_basic_mult(Decoding.CACHE)])
	# hacking: intel drain + breach crit + sql booster display
	HackingMods.current_mods.clear()
	HackingMods.current_mods[HackingMods.MOD_TYPE.SQL_BOOST] = {"duration": 3, "value": 0.25, "tier": 1}
	Inventory.add_resource(Items.SQL_INJECTOR, 1000); Inventory.add_resource(Items.PACKET_SPOOF, 1000); Inventory.add_resource(Items.SCHOOL_PAYLOAD, 100)
	var stu = Stats.hacking_targets["School"].targets[0]
	for k in 15: Decoding.add_intel_point(stu)
	var g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
	g.setup(stu, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, false)
	await g.prepare()
	print("intel pcts ", g.active_intel.get("pcts"), " integ %d/%d fw %d/%d" % [g.integ_bar.value, g.integ_bar.max_value, g.firewall_bar.value, g.firewall_bar.max_value])
	print("SQL card: ", _strip(g.sql_card.stats.text), " | base speed ", g.ATTACK_SPEED)
	print("ctr mods: ", _strip(g.ctr_card.mods.text))
	g.start_hack()
	for i in 5: await get_tree().process_frame
	g._break_firewall(false)
	print("breach_crit after break: ", g.breach_crit)
	g.attack()
	print("breach_crit after attack: ", g.breach_crit)
	await get_tree().process_frame
	g.stop_hacking = true
	get_tree().quit()
