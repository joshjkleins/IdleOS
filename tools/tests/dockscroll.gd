extends Node
## Side panel with 7 VMs + uploads + a defrag boost: scrolls instead of spilling off screen.
var os
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/%s.png" % name)
func _cmd(c: String) -> void:
	os._on_input_line_text_submitted(c)
	for i in 10: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	for id in ["system.vm_windows"]:
		var p = Upgrades.packages[id]; p.installed = p.levels.size(); Upgrades._recompute(p)
	Upgrades.apply_effects()
	Inventory.add_resource(Items.LOGS, 500); Inventory.add_resource(Items.VM_MINING_TOKEN, 20)
	Inventory.add_resource(Items.ENCRYPTED_PASSWORDS, 4); Inventory.add_resource(Items.USERNAMES, 3)
	Defragging.HEAT.unlocked = true
	Defragging.HEAT.expires_at = int(Time.get_unix_time_from_system()) + 600
	await _cmd("mine -logs")
	for i in 7: await _cmd("ssh mine -logs")
	print(">>> vms %d max %d" % [VMManager.vms.size(), VMManager.get("max_vms") if VMManager.get("max_vms") else -1])
	for i in 60: await get_tree().process_frame
	var d = os.system_dock
	print(">>> dock h %.0f scroll h %.0f content min %.0f vbar visible %s" % [d.size.y, d.scroll.size.y, d.full_view.get_combined_minimum_size().y, d.scroll.get_v_scroll_bar().visible])
	await _shot("dock_scroll_top")
	d.scroll.scroll_vertical = 10000
	for i in 5: await get_tree().process_frame
	await _shot("dock_scroll_bottom")
	get_tree().quit()
