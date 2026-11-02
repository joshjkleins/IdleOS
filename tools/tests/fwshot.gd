extends Node
## 2026-11-02: Firmware + final-state UI. Grants Mining + Cracking Firmware, maxes Mining (99 + apt), installs it,
## screenshots the info text / header shader / uploads panel, checks the compromise prize, VM cost and 'defrag -all'.
var os
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/fw_%s.png" % name)
	print(">>> shot ", name)
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _cmd(c: String) -> void:
	os._on_input_line_text_submitted(c)
	await _secs(1.2)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	Mining.SKILL.level = 99
	for p in Upgrades.group_packages("Mining"):
		p.installed = p.levels.size(); Upgrades._recompute(p)
	Firmware.owned.clear(); Firmware.installed.clear()
	Firmware.grant("mining"); Firmware.grant("cracking")
	print(">>> prize: ", Compromise.prize_text("Government"), " | left ", Compromise.drivers_left(6).size(), "/", Compromise.tier_drivers(6).size())
	await _cmd("cd cracking")
	await _secs(1.0); await _shot("1_cracking_info")
	await _cmd("cd ..")
	await _cmd("cd mining")
	await _secs(1.0); await _shot("2_mining_info")
	await _cmd("firmware -install")
	print(">>> mining active ", Firmware.active(Mining), " maxed ", Firmware.maxed("Mining"), " vm cost ", VMManager.token_cost(Mining, Mining.minor_processes[0]))
	await _secs(1.5); await _shot("3_installed")
	await _cmd("cd ..")
	await _secs(1.5); await _shot("4_root_header")
	Uploads.completed_tiers = [1, 2, 3]
	await _secs(1.0); await _shot("5_uploads_3")
	Uploads.completed_tiers = [1, 2, 3, 4, 5, 6]
	await _secs(1.0); await _shot("6_uploads_all")
	await _cmd("firmware")
	Firmware.grant("defragging"); Firmware.installed.append("defragging"); Firmware.changed.emit()
	Defragging.SKILL["cooldown"] = 0
	await _cmd("cd defragging")
	await _cmd("defrag -all")
	print(">>> defrag -all running: ", os.process_running, " ", os.current_process_info.get("name", ""))
	var cracked = Compromise.roll_driver(6)
	print(">>> rolled ", cracked, " owned ", Firmware.owned)
	print(">>> done")
	get_tree().quit()
