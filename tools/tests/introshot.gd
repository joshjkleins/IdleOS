extends Node
## Captures the intro: typing, then after Enter the install sequence. SHOTS env: comma list of seconds.
var os
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/intro2/%s.png" % name)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	var t0 = Time.get_ticks_msec()
	var marks = [1.5, 4.0]
	for m in marks:
		while (Time.get_ticks_msec() - t0) / 1000.0 < m:
			await get_tree().process_frame
		await _shot("type_%02d" % int(m))
	# wait until intro text is done (accepting input), then press enter
	while !os.accepting_player_inputs:
		await get_tree().process_frame
	var typed_s = (Time.get_ticks_msec() - t0) / 1000.0
	for i in 20: await get_tree().process_frame
	await _shot("typed")
	var ev = InputEventKey.new(); ev.keycode = KEY_ENTER; ev.pressed = true
	Input.parse_input_event(ev)
	var t1 = Time.get_ticks_msec()
	for m in [0.8, 2.2, 3.2, 4.2, 5.0]:
		while (Time.get_ticks_msec() - t1) / 1000.0 < m and !(os.accepting_player_inputs and !Tutorial.show_intro):
			await get_tree().process_frame
		await _shot("boot_%02d" % int(m))
	while !(os.accepting_player_inputs and !Tutorial.show_intro):
		await get_tree().process_frame
	var boot_s = (Time.get_ticks_msec() - t1) / 1000.0
	for i in 60: await get_tree().process_frame
	await _shot("done")
	print(">>> typed in %.1fs, boot %.1fs" % [typed_s, boot_s])
	get_tree().quit()
