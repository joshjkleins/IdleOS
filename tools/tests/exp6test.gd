extends Node
## 2026-11-01: Redaction / Root Access / System Purge (tier 6 Exploit rework) in a real fight vs the Clerk
func _ready() -> void:
	_run.call_deferred()
func _fight(id: String, pre: Callable = Callable(), mid: Callable = Callable()) -> void:
	var g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
	var clerk = Stats.hacking_targets["Government"].targets[0]
	Inventory.add_resource(Items.SQL_INJECTOR, 300); Inventory.add_resource(Items.PACKET_SPOOF, 50)
	Inventory.add_resource(Items.GOVERNMENT_PAYLOAD, 10)
	var it = Exploits.get_item(id); Inventory.add_resource(it, 2)
	Stats.max_anon = 100000; Stats.current_anon = Stats.max_anon
	g.setup(clerk, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, 1, false)
	await g.prepare()
	g.start_hack()
	Stats.max_anon = 100000; Stats.current_anon = Stats.max_anon
	for i in 30: await get_tree().process_frame
	if pre.is_valid(): await pre.call(g)
	Exploits.set_charge(Exploits.CHARGE_MAX)
	var before_i = g.integ_bar.value; var before_f = g.firewall_bar.value
	g.set("_t_fw", 0)
	print(">>> %s cost %d  use -> '%s'  integ %d -> %d  fw %d -> %d  atk x%.2f  ctr rate %.2f" % [id, Exploits.cost(it), g.use_exploit(it), before_i, g.integ_bar.value, before_f, g.firewall_bar.value, g._attack_speed_mult(), g._counter_rate()])
	var t = 0.0
	var hit_done = false
	while (t < 3.0 or g.root_left > 0.0 or g.purge_left > 0.0) and g.is_hacking and t < 60.0:
		await get_tree().process_frame; t += get_process_delta_time()
		if mid.is_valid() and !hit_done and t > 1.0: hit_done = true; mid.call(g)
	var lines = g.log_rtl.get_parsed_text().split("\n")
	for l in lines:
		if "Root Access" in l or "Purge" in l or "Redaction" in l or "REDACT" in l: print(">>>   ", l.strip_edges().substr(0, 170))
	print(">>>   fw at end %d (base %d)" % [g.firewall_bar.value, g.fw_base])
	print(">>>   when done: integ %d, purge_left %.1f root_left %.1f chips ok" % [g.integ_bar.value, g.purge_left, g.root_left])
	g.queue_free()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	Engine.time_scale = 2.0
	await _fight("redaction")
	await _fight("system_purge")
	# Root Access: 2 x 100 manual integrity hits inside the window -> 200 stored -> 400 payout
	var hit = func(g): g.integ_bar.value -= 100; g.integ_bar.value -= 100; print(">>>   (manual -200, bank now %d)" % g.root_bank)
	await _fight("root_access", Callable(), hit) # firewall up: 125 of the 400 absorbed, firewall untouched
	await _fight("root_access", func(g): g._break_firewall(false), hit) # firewall down: all 400
	print(">>> done")
	get_tree().quit()
