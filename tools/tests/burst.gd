extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 20: await get_tree().process_frame
	Engine.max_fps = 0
	Engine.time_scale = 40.0
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]; p.installed = 0; Upgrades._recompute(p)
	for r in Compiling.SCHOOL.requirements: Inventory.add_resource(r, 1000000)
	var t = Compiling.terminal_scene.instantiate(); add_child(t)
	t.start(Compiling.SCHOOL, false, null)
	var fills = [0, 0]
	Compiling.SCHOOL.signal.connect(func(_a): fills[0] += 1; if !t.eff_proc: fills[1] += 1)
	var bursts = 0; var was = false; var burst_time = 0.0; var tt = 0.0
	while tt < 3600.0:
		await get_tree().process_frame
		var dt = get_process_delta_time(); tt += dt
		if t.eff_proc: burst_time += dt
		if t.eff_proc and !was: bursts += 1
		was = t.eff_proc
		Stats.system_tempature = 30.0; Stats.overheated = false
	print(">>> 1h: fills %d (per h %.0f) | fills while not bursting %d | bursts %d (%.3f per non-burst fill) | avg burst %.2fs | eff %.4f | wait_time %.2f one_shot %s" % [fills[0], fills[0] / 1.0, fills[1], bursts, float(bursts) / max(1, fills[1]), burst_time / max(1, bursts), t._get_current_eff(), t.eff_timer.wait_time, t.eff_timer.one_shot])
	get_tree().quit()
