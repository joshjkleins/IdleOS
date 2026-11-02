extends Node
## 2026-11-02: tab-complete (hack at the shown location, decode -intel=<location>), '<command> <modifier>' starts,
## the side panel width with 'available to run' collapsed.
var os
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _cmd(c: String) -> void:
	os._on_input_line_text_submitted(c)
	await _secs(1.0)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	for l in Stats.hacking_targets:
		Stats.unlock_location(l)
		for t in Stats.hacking_targets[l].targets: Stats.unlock_target(t)
	Exp.refresh_all_process_unlocks()
	print(">>> tab 'decode -intel=gov' -> ", CommandRegistry.complete("decode -intel=gov").text)
	for p in Upgrades.group_packages("Mining"):
		p.installed = p.levels.size(); Upgrades._recompute(p)
	Inventory.add_resource(Items.SQL_INJECTOR, 50)
	await _cmd("mine -logs survey")
	print(">>> 'mine -logs survey': running ", os.process_running, " modifier ", os.current_process.modifier.get("command", "-") if os.current_process else "-")
	await _cmd("stop")
	await _cmd("mine -logs 5 sift")
	print(">>> 'mine -logs 5 sift': running ", os.process_running, " modifier ", os.current_process.modifier.get("command", "-") if os.current_process else "-", " cycle_limit ", os.current_process.get("cycle_limit") if os.current_process else "-")
	await _cmd("stop")
	var dock = os.system_dock
	var w0 = dock.size.x
	var av = dock.find_children("*", "", true, false).filter(func(n): return n.get_script() != null and str(n.get_script().resource_path).ends_with("available_section.gd"))
	print(">>> available sections found ", av.size())
	if !av.is_empty():
		var long_names = "mining logs  ·  parsing logs  ·  cracking encrypted passwords  ·  matching credentials  ·  compiling school payload  ·  hacking student  ·  decoding student cache"
		av[0].set_collapsed(true)
		av[0]._summary.text = long_names
		await _secs(1.0)
		print(">>> dock width expanded %d -> collapsed %d" % [w0, dock.size.x])
		av[0].set_collapsed(false)
	await _cmd("cd hacking")
	await _secs(2.0)
	var hk = get_tree().root.find_children("*", "", true, false).filter(func(n): return n.has_method("handle_hack_command"))[0]
	await hk.open_location("Government", false)
	await _secs(4.0)
	os.current_context = os.Context.HACKING
	var line = hk.player_hacking_box.input_line
	line.text = "hack vic"
	os._tab_complete()
	print(">>> hacking at Government: 'hack vic' + tab -> ", line.text)
	print(">>> done")
	get_tree().quit()
