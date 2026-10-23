extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	Inventory.add_resource(Items.SQL_INJECTOR, 9)
	Inventory.add_resource(Items.SCHOOL_PAYLOAD, 1)
	Defragging.activate_cooldown()
	Inventory.add_resource(Items.LOGS, 300)
	Uploads.uploaded[Items.LOGS] = 1000 if "uploaded" in Uploads else 0
	for i in 40: await get_tree().process_frame
	await _shot("hint_panel")
	print(">>> done")
	get_tree().quit()
