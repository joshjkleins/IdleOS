extends Node
var ended := false
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	Signals.hacking_ended_signal.connect(func(): ended = true) if Signals.has_signal("hacking_ended_signal") else null
	Engine.time_scale = 8.0
	var stu = Stats.hacking_targets["School"].targets[0]
	var cool = Timer.new(); add_child(cool); cool.wait_time = Stats.cooling_frequency; cool.timeout.connect(func(): Stats.update_tempature(Stats.get_cooling_amount())); cool.start()
	for trial in 8:
		Stats.system_tempature = 30.0; Stats.overheated = false
		Inventory.inventory.clear()
		Inventory.add_resource(Items.SQL_INJECTOR, 35); Inventory.add_resource(Items.PACKET_SPOOF, 3); Inventory.add_resource(Items.SCHOOL_PAYLOAD, 3)
		var results = []
		for run in [1, 2]:
			var g = load("res://scenes/hacking_game.tscn").instantiate(); add_child(g)
			var cache0 = Inventory.get_amount(Items.STUDENT_CACHE)
			var sql0 = Inventory.get_amount(Items.SQL_INJECTOR)
			g.setup(stu, {"offensive": Items.SQL_INJECTOR, "defensive": Items.PACKET_SPOOF}, run, false)
			await g.prepare()
			var t0 = Time.get_ticks_msec()
			var peak = 0.0
			g.start_hack()
			while !g.stop_hacking and Stats.current_anon > 0 and Time.get_ticks_msec() - t0 < 60000:
				if g.is_hacking == false and g.stop_hacking == false: pass
				peak = max(peak, Stats.system_tempature)
				await get_tree().process_frame
			await get_tree().create_timer(1.0).timeout
			results.append("run of %d: caches +%d, SQL used %d, game-time %.0fs, anon end %d, peak temp %.0f" % [run, Inventory.get_amount(Items.STUDENT_CACHE) - cache0, sql0 - Inventory.get_amount(Items.SQL_INJECTOR), (Time.get_ticks_msec() - t0) / 1000.0 * Engine.time_scale, Stats.current_anon, peak])
			if Inventory.get_amount(Items.STUDENT_CACHE) - cache0 < run:
				print("---- LOST RUN LOG ----\n", g.log_rtl.get_parsed_text().right(3000))
			g.queue_free()
		print(">>> trial %d: %s | SQL left %d, spoofs left %d" % [trial, " ; ".join(results), Inventory.get_amount(Items.SQL_INJECTOR), Inventory.get_amount(Items.PACKET_SPOOF)])
	get_tree().quit()
