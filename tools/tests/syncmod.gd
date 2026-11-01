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
	for id in ["mining.overclock", "system.vm_windows"]:
		var p = Upgrades.packages[id]; p.installed = p.levels.size(); Upgrades._recompute(p)
	for id in Upgrades.packages: 
		if id.begins_with("mining."): var p = Upgrades.packages[id]; p.installed = p.levels.size(); Upgrades._recompute(p)
	Upgrades.apply_effects()
	Inventory.add_resource(Items.LOGS, 500); Inventory.add_resource(Items.VM_MINING_TOKEN, 20)
	await _cmd("cd mining")
	await _cmd("mine -logs")
	await _cmd("sift")
	await _cmd("ssh mine -logs")
	var vm = VMManager.vms[0]
	var t = vm.terminal
	print(">>> main mod '%s'" % os.current_process.modifier.get("command",""))
	print(">>> no sync: vm mod '%s' heat %.3f" % [t.modifier.get("command",""), t.get_heat(0)])
	Defragging.HEAT.expires_at = int(Time.get_unix_time_from_system()) + 600
	print(">>> sync: vm mod '%s' has sift %s heat %.3f step %.3f | main heat %.3f step %.3f" % [t.modifier.get("command",""), t.has_modifier("sift"), t.get_heat(0), t.get_step_time(0), os.current_process.get_heat(0), os.current_process.get_step_time(0)])
	await _cmd("sift -kill")
	print(">>> after kill: vm mod '%s'" % t.modifier.get("command",""))
	get_tree().quit()
