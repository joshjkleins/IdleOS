extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String, frames: int = 20) -> void:
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
func _wait_stop(maxt: float) -> float:
	var t = 0.0
	while os.process_running and t < maxt:
		await get_tree().process_frame
		t += get_process_delta_time()
		Stats.system_tempature = 30.0; Stats.overheated = false
	return t
func _last(n: int) -> void:
	var txt = os.find_child("*", true, false)
	for l in os.lines.slice(max(0, os.lines.size() - n)): print("   > ", str(l).substr(0, 140))
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 200: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	Inventory.add_resource(Items.LOGS, 500)
	Inventory.add_resource(Items.VM_MINING_TOKEN, 20)
	Engine.time_scale = 20.0
	await _cmd("mine -logs 50", 5)
	for i in 300: await get_tree().process_frame
	var snap = Offline.snapshot()
	print(">>> snapshot ", snap)
	Offline.session = {"saved_at": int(Time.get_unix_time_from_system()) - 600, "process": snap}
	await _cmd("kill")
	Offline.compute()
	print(">>> offline resume ", Offline.report.get("resume"), " notes ", Offline.report.get("notes"), " gains ", Offline.report.get("gains").map(func(g): return "%s %d" % [g.item.name, g.amount]))
	get_tree().quit()
	return
	for c in ["mine -logs 3", "parse -footprint=logs 2", "phish -spear 4"]:
		await _cmd(c, 5)
		var cp = os.current_process
		var lim = cp.cycle_limit if cp and "cycle_limit" in cp else -1
		var t = await _wait_stop(400.0)
		print(">>> %s: limit %d, stopped=%s after %.0fs, cycles %d" % [c, lim, str(!os.process_running), t, cp.session_cycles if is_instance_valid(cp) else -1])
		if os.process_running: await _cmd("kill")
	await _cmd("ssh mine -logs 2", 5)
	var vm = VMManager.vms[0] if !VMManager.vms.is_empty() else null
	print(">>> ssh 2: periods_left %d, status '%s'" % [vm.periods_left if vm else -9, vm.get_status_text() if vm else ""])
	var t = 0.0
	while !VMManager.vms.is_empty() and t < 200.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		Stats.system_tempature = 30.0
	print(">>> ssh 2 ended after %.0fs game (uptime %.0f each)" % [t, Mining.VM_UPTIME])
	await _cmd("ssh mine -logs", 5)
	await _cmd("vm kill -a -s", 5)
	vm = VMManager.vms[0] if !VMManager.vms.is_empty() else null
	print(">>> vm kill -s: repeat %s status '%s'" % [str(vm.repeat) if vm else "?", vm.get_status_text() if vm else ""])
	await _cmd("vm ls", 5)
	_last(4)
	t = 0.0
	while !VMManager.vms.is_empty() and t < 200.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	print(">>> after -s ended in %.0fs" % t)
	get_tree().quit()
