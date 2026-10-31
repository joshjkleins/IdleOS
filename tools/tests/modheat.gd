extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 200: await get_tree().process_frame
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("tutorial complete")
	for i in 10: await get_tree().process_frame
	Phishing.MOD.efficiency = 1.0
	Stats.system_tempature = 30.0
	var temps = []
	Signals.heat_added_signal.connect(func(a): temps.append(snappedf(a, 0.1)))
	os._on_input_line_text_submitted("phish -mod 1")
	Engine.time_scale = 10.0
	var t = 0.0
	while os.process_running and t < 200.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	print(">>> heat ticks ", temps, " temp now ", snappedf(Stats.system_tempature, 0.1))
	get_tree().quit()
