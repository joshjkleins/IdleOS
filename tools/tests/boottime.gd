extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	var t0 = Time.get_ticks_msec()
	for i in 600:
		await get_tree().process_frame
		if os.accepting_player_inputs: break
	print(">>> intro screen ready after %.1fs, typing done? lines %d" % [(Time.get_ticks_msec() - t0) / 1000.0, os.lines.size()])
	var t1 = Time.get_ticks_msec()
	os.install_idle_os()
	while os._booting or Tutorial.show_intro:
		await get_tree().process_frame
		if Time.get_ticks_msec() - t1 > 120000: break
	print(">>> boot (after Enter) %.1fs" % ((Time.get_ticks_msec() - t1) / 1000.0))
	get_tree().quit()
