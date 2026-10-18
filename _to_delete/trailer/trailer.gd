extends Node
## Trailer clips. CLIP env picks the scene; DUR = seconds of footage. Run with --write-movie <file>.avi --fixed-fps 30.
var os
var t := 0.0
func _ready() -> void:
	_run.call_deferred()
func _process(delta: float) -> void:
	t += delta / max(0.0001, Engine.time_scale)
	Stats.system_tempature = min(Stats.system_tempature, 66.0)
func _wait(sec: float) -> void:
	var s = t
	while t - s < sec:
		await get_tree().process_frame
func _cmd(c: String, w: float = 0.4) -> void:
	os._on_input_line_text_submitted(c)
	await _wait(w)
func _goto(skill: String) -> void:
	await _cmd("cd " + skill, 0.8)
	await os._wait_for_output()
func _run() -> void:
	AudioServer.set_bus_mute(0, true) # music is added in the edit
	var clip = OS.get_environment("CLIP")
	var dur = float(OS.get_environment("DUR"))
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	if clip != "intro":
		await _wait(0.2)
		if Tutorial.show_intro: os._finish_boot()
		os.accepting_player_inputs = true
		await os._wait_for_output()
		os._clear_terminal()
	var start = t
	match clip:
		"intro":
			while !os.accepting_player_inputs: await get_tree().process_frame
			await _wait(0.7)
			os.install_idle_os()
		"mining":
			await _cmd("ssh parsing footprint=archives", 0.6); await _cmd("ssh cracking badge", 0.6); await _cmd("ssh matching credential", 0.6)
			await _goto("mining"); await _cmd("mine -metadata")
			Engine.time_scale = 2.0
		"cracking":
			await _cmd("ssh mining metadata", 0.3)
			await _goto("cracking"); await _cmd("crack -badge")
			Engine.time_scale = 1.5
		"matching":
			await _cmd("ssh cracking badge", 0.3)
			await _goto("matching"); await _cmd("match -badge")
			Engine.time_scale = 2.0
		"phishing":
			await _goto("phishing"); await _cmd("phish -spear bait=logs")
			Engine.time_scale = 3.0
		"hack":
			Inventory.add_resource(Items.SCHOOL_PAYLOAD, 30)
			await _cmd("cd hacking", 3.2)
			os.hacking._on_player_hacking_box_command_entered("view school"); await _wait(1.5)
			os.hacking._on_player_hacking_box_command_entered("hack student=20")
			Engine.time_scale = 2.5
		"apt":
			for item in [Items.LOGS, Items.ARCHIVES, Items.SQL_INJECTOR]: Inventory.add_resource(item, 5000)
			for r in Decoding.get_tier_resources(3): Inventory.add_resource(r, 5000)
			await _cmd("apt phishing", 1.2)
			await _cmd("apt install phishing", 1.0)
			await _cmd("y")
		"breach":
			Inventory.add_resource(Items.SCHOOL_PAYLOAD, 30)
			await _cmd("cd hacking", 3.2)
			os.hacking._on_player_hacking_box_command_entered("view school"); await _wait(1.0)
			os.hacking._on_player_hacking_box_command_entered("hack student=20")
			Engine.time_scale = 3.0
			await _wait(1.0)
			var game = os.hacking.enemy_hacking_box.hacking_game
			while game.integ_bar.value > game.integ_bar.max_value * 0.35:
				await get_tree().process_frame
			Engine.time_scale = 1.0
			while game.integ_bar.value > 0.5:
				await get_tree().process_frame
			print(">>> breach at %.2f" % (t - start))
			start = t - (dur - 3.0) # keep 3 s after the breach
		"swarm":
			Stats.MAX_ALL_VMS = 7
			for item in Decoding.get_tier_resources(3):
				Uploads.stage(item, 120); Uploads.start_upload(item)
			for tok in [Items.VM_COMPILING_TOKEN, Items.VM_DECODING_TOKEN, Items.VM_PHISHING_TOKEN, Items.VM_MINING_TOKEN, Items.VM_MATCHING_TOKEN]:
				Inventory.add_resource(tok, 5)
			Inventory.add_resource(Items.SCHOOL_PAYLOAD, 40)
			await _goto("mining"); await _cmd("mine -metadata")
			await os._wait_for_output(); os._clear_terminal()
			for c in ["ssh parsing footprint=archives", "ssh cracking badge", "ssh mining logs", "ssh matching badge", "ssh phishing spear"]:
				await _cmd(c, 0.25)
			await os._wait_for_output(); os._clear_terminal()
			# lay the windows out over the terminal area for the shot (by their real widths)
			var spots = [Vector2(10, 150), Vector2(552, 150), Vector2(1000, 150), Vector2(10, 600), Vector2(905, 600)]
			for i in min(spots.size(), VMManager.vms.size()):
				VMManager.vms[i].position = spots[i]
			Engine.time_scale = 2.5
		"typing":
			Stats.MAX_ALL_VMS = 7
			for item in Decoding.get_tier_resources(3):
				Uploads.stage(item, 120); Uploads.start_upload(item)
			await _cmd("ssh mining metadata", 0.2); await _cmd("ssh parsing footprint=archives", 0.2)
			await _goto("mining"); await _cmd("mine -logs", 0.2)
			await os._wait_for_output(); os._clear_terminal()
			await _wait(1.6)
			var txt = "ssh cracking badge"
			for i in txt.length():
				os.input_line.text = txt.substr(0, i + 1)
				os.input_line.caret_column = i + 1
				await _wait(0.07)
			await _wait(0.35)
			os.input_line.text = ""
			os._on_input_line_text_submitted(txt)
			print(">>> enter at %.2f" % (t - start))
			Engine.time_scale = 1.5
		"install":
			for r in Decoding.get_tier_resources(3): Inventory.add_resource(r, 5000)
			await _cmd("apt mining", 1.0)
			await os._wait_for_output(); os._clear_terminal()
			await _wait(0.4)
			var txt = "apt install mining.efficiency"
			for i in txt.length():
				os.input_line.text = txt.substr(0, i + 1); os.input_line.caret_column = i + 1
				await _wait(0.05)
			await _wait(0.25)
			os.input_line.text = ""
			os._on_input_line_text_submitted(txt)
			await _wait(1.0)
			os.input_line.text = "y"; await _wait(0.3); os.input_line.text = ""
			os._on_input_line_text_submitted("y")
			print(">>> y at %.2f" % (t - start))
		"cook":
			Stats.MAX_ALL_VMS = 7
			for tok in [Items.VM_DECODING_TOKEN, Items.VM_PHISHING_TOKEN, Items.VM_MINING_TOKEN, Items.VM_MATCHING_TOKEN, Items.VM_PARSING_TOKEN]:
				Inventory.add_resource(tok, 5)
			for item in Decoding.get_tier_resources(3):
				Uploads.stage(item, 150); Uploads.start_upload(item)
			await _goto("cracking"); await _cmd("crack -badge")
			await os._wait_for_output(); os._clear_terminal()
			for c in ["ssh mining metadata", "ssh parsing footprint=archives", "ssh decoding cache", "ssh matching badge"]:
				await _cmd(c, 0.25)
			await os._wait_for_output(); os._clear_terminal()
			var spots = [Vector2(740, 150), Vector2(10, 590), Vector2(10, 150), Vector2(560, 590)]
			for i in min(spots.size(), VMManager.vms.size()):
				VMManager.vms[i].position = spots[i]
			Engine.time_scale = 2.5
	while t - start < dur:
		await get_tree().process_frame
	get_tree().quit()
