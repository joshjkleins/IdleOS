extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	Signals.update_hack_console_signal.connect(func(t): print("CONSOLE: ", t.strip_edges())) if Signals.has_signal("update_hack_console_signal") else null
	Inventory.add_resource(Items.SQL_INJECTOR, 1000); Inventory.add_resource(Items.PACKET_SPOOF, 1000); Inventory.add_resource(Items.SCHOOL_PAYLOAD, 100)
	var stu = Stats.hacking_targets["School"].targets[0]
	var g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
	g.setup(stu, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, -1, false)
	await g.prepare(); g.start_hack()
	for i in 5: await get_tree().process_frame
	var before = Inventory.get_amount(g.target_reward)
	g.win()
	for i in 5: await get_tree().process_frame
	g.kill_hack_safely()
	await get_tree().create_timer(2.0).timeout
	g.win()
	await get_tree().create_timer(1.5).timeout
	print(">>> kill -s: stopped=%s caches banked %d (expect 2)" % [g.stop_hacking, Inventory.get_amount(g.target_reward) - before])
	g.queue_free()
	g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
	g.setup(stu, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, -1, false)
	await g.prepare(); g.start_hack()
	before = Inventory.get_amount(g.target_reward)
	g.win()
	await get_tree().create_timer(2.0).timeout
	g.kill_hack()
	print(">>> kill: banked %d (expect 1)" % [Inventory.get_amount(g.target_reward) - before])
	get_tree().quit()
