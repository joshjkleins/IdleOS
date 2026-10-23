extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	for t in range(1, 7):
		print("T%d mods: %s | items: %s" % [t, ", ".join(HackingMods.pool_items(t).map(func(m): return m.name)), ", ".join(Exploits.tier_items(t).map(func(i): return "%s(%d)" % [i.name, int(Exploits.cost(i))]))])
	Inventory.add_resource(Items.SQL_INJECTOR, 2000); Inventory.add_resource(Items.PACKET_SPOOF, 500); Inventory.add_resource(Items.SCHOOL_PAYLOAD, 50)
	var stu = Stats.hacking_targets["School"].targets[0]
	var g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
	g.setup(stu, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, -1, false)
	await g.prepare(); g.start_hack()
	for i in 10: await get_tree().process_frame
	for it in Exploits.get_items():
		if !g.is_hacking:
			g.integ_bar.value = g.integ_bar.max_value
			g.reset(); await get_tree().create_timer(2.0).timeout
		Inventory.add_resource(it, 1)
		Exploits.set_charge(Exploits.CHARGE_MAX); g._exploit_lock = 0.0
		Stats.current_anon = Stats.max_anon * 0.5; Stats.system_tempature = 70.0
		g.integ_bar.value = g.integ_bar.max_value
		var r = g.use_exploit(it)
		print("  %-20s %s" % [it.name, r if r != "" else "ok"])
		for k in 3: await get_tree().process_frame
	g.stop_hacking = true
	get_tree().quit()
