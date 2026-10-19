extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	Engine.time_scale = 20.0
	for id in Upgrades.packages:
		if id.begins_with("hacking."):
			var p = Upgrades.packages[id]; p.installed = p.levels.size(); Upgrades._recompute(p)
	Upgrades.apply_effects()
	print("caps: ", ["clean_exit","evasion","recycler","siphon","dead_mans_switch","exploit_kit"].map(func(c): return Upgrades.has("hacking." + c)), " | spoof threshold %.2f | charge x%.2f | slots %d" % [Stats.healing_threshold_auto_start, 1.0 + Upgrades.cur("hacking.persistent_session"), HackingMods.max_mods])
	Inventory.add_resource(Items.SQL_INJECTOR, 1000); Inventory.add_resource(Items.PACKET_SPOOF, 1000); Inventory.add_resource(Items.SCHOOL_PAYLOAD, 100)
	var stu = Stats.hacking_targets["School"].targets[0]
	var g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
	g.setup(stu, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 5, false)
	await g.prepare()
	g.start_hack()
	for i in 20: await get_tree().process_frame
	var c0 = Inventory.get_amount(Items.STUDENT_CACHE)
	g.caches_gained = 5
	g.lose()
	print(">>> clean exit: banked 5, inventory +%d (expect 2)" % (Inventory.get_amount(Items.STUDENT_CACHE) - c0))
	g.queue_free()
	# exploit kit
	g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
	g.setup(stu, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, false)
	await g.prepare()
	g.start_hack()
	for i in 5: await get_tree().process_frame
	var item = Exploits.tier_items(1)[0]
	Inventory.add_resource(item, 100)
	var used = 0; var kept = 0
	for k in 40:
		Exploits.set_charge(Exploits.CHARGE_MAX)
		Stats.current_anon = Stats.max_anon * 0.2
		g._exploit_lock = 0.0
		var a = Inventory.get_amount(item)
		var r = g.use_exploit(item)
		if k == 0: print("    first run: ", r)
		if Inventory.get_amount(item) == a: kept += 1
		else: used += 1
	print(">>> exploit kit: %s 40 runs -> consumed %d, kept %d (expect ~20/20)" % [item.name, used, kept])
	Exploits.set_charge(0)
	Exploits.add_charge("attack")
	print(">>> persistent session: one SQL hit charge %.1f (base %.1f)" % [Exploits.charge, Exploits.CHARGE_GAIN.attack])
	get_tree().quit()
