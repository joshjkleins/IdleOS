extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Engine.time_scale = 300.0
	Inventory.add_resource(Items.LOGS, 100000)
	var sp = Phishing.SPEAR
	sp.level = 10
	sp.efficiency = 0.3 + sp["efficiency rate"] * 9
	for bait in [null, Items.LOGS]:
		var sql0 = Inventory.get_amount(Items.SQL_INJECTOR) + Inventory.get_amount(Items.PACKET_SPOOF)
		var logs0 = Inventory.get_amount(Items.LOGS)
		var term = Phishing.terminal_scene.instantiate()
		add_child(term)
		term.cast_lines(sp, -1, bait)
		var t = 0.0
		while t < 3 * 3600.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			Stats.system_tempature = 30.0
			Stats.overheated = false
			sp.level = 10
			sp.efficiency = 0.3 + sp["efficiency rate"] * 9
		term.stop(); term.queue_free(); Phishing.current_lines.clear()
		await get_tree().process_frame
		var got = Inventory.get_amount(Items.SQL_INJECTOR) + Inventory.get_amount(Items.PACKET_SPOOF) - sql0
		print(">>> spear L10 eff %.3f bait=%s: %.0f items/h, logs used %.0f/h" % [sp.efficiency, bait.name if bait else "none", got / (t / 3600.0), (logs0 - Inventory.get_amount(Items.LOGS)) / (t / 3600.0)])
	get_tree().quit()
