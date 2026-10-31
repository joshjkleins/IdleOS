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
	Upgrades.apply_effects()
	Inventory.add_resource(Items.LOGS, 500); Inventory.add_resource(Items.VM_MINING_TOKEN, 20); Inventory.add_resource(Items.VM_PARSING_TOKEN, 20)
	await _cmd("cd mining")
	await _cmd("mine -logs")
	await _cmd("overclock")
	await _cmd("ssh mine -logs")
	await _cmd("ssh parse -footprint=logs")
	var vms = VMManager.vms
	print(">>> main mode %d  overclocked %s" % [os.current_process.get_mode(), Stats.overclocked])
	for vm in vms: print(">>> no sync: vm %s mode %d status '%s'" % [vm.minor_process.name, vm.terminal.get_mode(), vm.get_status_text()])
	Defragging.HEAT.expires_at = int(Time.get_unix_time_from_system()) + 600
	for vm in vms: print(">>> sync: vm %s mode %d heat %.3f (normal %.3f) status '%s'" % [vm.minor_process.name, vm.terminal.get_mode(), vm.terminal.get_heat(vm.terminal.get_mode()), vm.terminal.get_heat(0), vm.get_status_text()])
	get_tree().quit()
