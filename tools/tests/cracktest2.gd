extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String, frames: int = 10) -> void:
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 200: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	Inventory.add_resource(Items.ENCRYPTED_PASSWORDS, 50)
	Upgrades.packages["cracking.dictionary"].installed = 0; Upgrades._recompute(Upgrades.packages["cracking.dictionary"])
	Engine.time_scale = 10.0
	# overheated for the first 3 s of a crack, then cooled
	Stats.overheated = true; Stats.system_tempature = 99.0
	await _cmd("crack -password 1", 2)
	var cp = os.current_process
	var t = 0.0
	var cooled = false
	while os.process_running and t < 300.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > 3.0 and !cooled:
			cooled = true; Stats.overheated = false; Stats.system_tempature = 30.0
			print(">>> cooled at %.1fs, bar %.0f%%" % [t, cp.progress_bar.value])
		if cooled: Stats.system_tempature = 30.0
	print(">>> crack done in %.1fs (normal step %.1fs x4, overheat step %.1fs)" % [t, Cracking.PASSWORD["base speed"], Cracking.PASSWORD["overheat speed"]])
	# matching head start
	var ac = Upgrades.packages["matching.auto_correlate"]; ac.installed = 3; Upgrades._recompute(ac)
	for r in Matching.minor_processes[0].requirements: Inventory.add_resource(r, 20)
	await _cmd("match -cred 1", 3)
	print(">>> matching bar at start %.1f (auto_correlate %.2f)" % [os.current_process.main_bar.value, Upgrades.cur("matching.auto_correlate")])
	t = 0.0
	while os.process_running and t < 300.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	print(">>> match done in %.1fs" % t)
	get_tree().quit()
