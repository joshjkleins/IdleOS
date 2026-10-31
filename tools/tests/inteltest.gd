extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String) -> void:
	os._on_input_line_text_submitted(c)
	for i in 10: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 200: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	Decoding.INTEL.unlocked = true
	var school = Stats.hacking_targets["School"]
	for i in 3: school.targets[i].unlocked = true
	Decoding.INTEL.efficiency = 1.0
	await _cmd("decode -intel=school")
	print(">>> started: running ", os.process_running, " target ", os.current_process.target_arg.get("name", "?") if os.current_process else "-")
	Engine.time_scale = 30.0
	var seen = []
	var t = 0.0
	while os.process_running and t < 2000.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		Stats.system_tempature = 30.0; Stats.overheated = false
		var n = os.current_process.target_arg.get("name", "?") if os.current_process and os.current_process.target_arg is Dictionary else "?"
		if seen.is_empty() or seen[-1] != n: seen.append(n)
	print(">>> order ", seen, " done=", !os.process_running, " in ", int(t), "s; maxed: ", school.targets.slice(0, 3).map(func(x): return Decoding.is_intel_maxed(x)))
	await _cmd("decode -intel=school")
	await _cmd("decode -intel=bank")
	get_tree().quit()
