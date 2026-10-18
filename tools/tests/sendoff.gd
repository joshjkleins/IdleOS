extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/demo/%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("apt mining")
	for i in 90: await get_tree().process_frame
	await _shot("apt_mining")
	var fired = [false]
	Uploads.tier_completed.connect(func(_t): fired[0] = true)
	for g in Uploads.get_goals():
		Uploads.stage(g.item, g.amount)
		Uploads.start_upload(g.item)
	Engine.time_scale = 100.0
	while !fired[0]:
		await get_tree().process_frame
		Stats.system_tempature = 30.0
	Engine.time_scale = 1.0
	print(">>> tier completed, typing send-off")
	while os._typing or !fired[0]:
		await get_tree().process_frame
	for i in 60: await get_tree().process_frame
	await _shot("sendoff")
	print(">>> done; tier complete=", Uploads.is_tier_complete(1), " current tier=", Uploads.current_tier())
	get_tree().quit()
