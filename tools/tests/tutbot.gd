extends Node
## Plays the hack-first tutorial with the commands from Tutorial.STEP_COMMANDS and checks each step completes.
var os
const SCALE := 8.0
var t0 := 0
func _ready() -> void:
	_run.call_deferred()
func gt() -> float:
	return (Time.get_ticks_msec() - t0) / 1000.0 * SCALE
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func send(cmd: String) -> void:
	var g = 0
	while os.current_context == os.Context.HACKING and (os.hacking.current_context == os.hacking.HackingContext.HACKING or !os.hacking.can_accept_inputs) and g < 3000:
		g += 1
		await get_tree().process_frame
	if os.current_context == os.Context.HACKING:
		os.hacking.player_hacking_box._on_input_line_text_submitted(cmd)
	else:
		os._on_input_line_text_submitted(cmd)
	for i in 6: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 90: await get_tree().process_frame
	os.RICHTEXT_LABEL_LINE_LIMIT = 100000
	Engine.time_scale = SCALE
	t0 = Time.get_ticks_msec()
	var peak = 0.0
	var guard = 0
	while Tutorial.current_step() != -1 and guard < 40:
		guard += 1
		var e = Tutorial.current_step()
		var title = Tutorial.step_title(e)
		var cmds = str(Tutorial.STEP_COMMANDS.get(e, "")).split("(")[0].split("->")
		var start = gt()
		for c in cmds:
			c = c.strip_edges()
			if c == "": continue
			if c == "kill" and !os.process_running: continue
			# a person reads the step first: give a finishing process (decode, compile) a moment to end on its own
			var w = 0
			while c != "kill" and os.process_running and w < 300 and !c.begins_with("ssh") and !c.begins_with("cd") and !c.begins_with("ls") and !c.begins_with("mod") and !c.begins_with("upload") and c != "y":
				w += 1
				await get_tree().process_frame
			if c == "cd hacking":
				while !os.accepting_player_inputs: await get_tree().process_frame
			await send(c)
			# navigation into/out of hacking takes a moment
			for k in 40: await get_tree().process_frame
		while Tutorial.current_step() == e and gt() - start < 600:
			peak = max(peak, Stats.system_tempature)
			await get_tree().process_frame
		var ok = Tutorial.current_step() != e
		print(">>> %5.0fs  %-28s %s  (%.0fs)  inv: ip %d cred %d sql %d payload %d spoof %d caches %d mods %d  temp %.0f" % [gt(), title, "OK" if ok else "STUCK", gt() - start, Inventory.get_amount(Items.IP_ADDRESS), Inventory.get_amount(Items.CREDENTIALS),
			Inventory.get_amount(Items.SQL_INJECTOR), Inventory.get_amount(Items.SCHOOL_PAYLOAD), Inventory.get_amount(Items.PACKET_SPOOF),
			Inventory.get_amount(Items.STUDENT_CACHE), HackingMods.current_mods.size(), Stats.system_tempature])
		if !ok:
			print("---- last terminal lines ----\n", _strip("\n".join(os.lines.slice(-30)) + "\nlogs %d running %s ctx %s" % [Inventory.get_amount(Items.LOGS), os.process_running, os.current_context]))
			break
	print(">>> tutorial complete: %s  peak temp %.0f  game-time %.0fs" % [Tutorial.is_tutorial_complete(), peak, gt()])
	get_tree().quit()
