extends Node
var os
var frames := 0
func _ready() -> void:
	_run.call_deferred()
func _grab() -> void:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.resize(800, 640)
	img.save_png(OS.get_environment("HOME") + "/tmp/gif/f%03d.png" % frames)
	frames += 1
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	var next = 0.0
	var t0 = Time.get_ticks_msec()
	var pressed = false
	var done_at = -1.0
	while true:
		await get_tree().process_frame
		var t = (Time.get_ticks_msec() - t0) / 1000.0
		if t >= next:
			await _grab(); next += 0.2
		if os.accepting_player_inputs and Tutorial.show_intro and !pressed:
			pressed = true
			await get_tree().create_timer(1.0).timeout
			os.install_idle_os()
		if !Tutorial.show_intro and done_at < 0: done_at = t
		if done_at > 0 and t > done_at + 1.5: break
	print(">>> frames ", frames)
	get_tree().quit()
