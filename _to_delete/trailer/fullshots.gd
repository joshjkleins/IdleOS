extends Node
## Full-game store screenshots (cdd build, flags off). STAGE=1 builds a Hospital-tier save; SHOT picks a scene.
var os
const OUT = "/mnt/idle-os-prototype/_to_delete/screens/store/"
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + OUT + name + ".png")
	print(">>> shot ", name)
func _wait(sec: float) -> void:
	var t = 0.0
	while t < sec:
		await get_tree().process_frame
		t += get_process_delta_time() / Engine.time_scale
func _cmd(c: String, w: float = 0.6) -> void:
	os._on_input_line_text_submitted(c)
	await _wait(w)
## navigate quietly: cd, let its info print, then clear so the process panel has the screen
func _goto(skill: String) -> void:
	await _cmd("cd " + skill, 1.5)
	await os._wait_for_output() # keep its info table above the process (fills the screen)
func _stage() -> void:
	var lv = {Mining: 44, Parsing: 41, Cracking: 38, Matching: 36, Phishing: 33, Hacking: 35, Decoding: 31, Compiling: 34}
	for s in lv:
		s.SKILL["level"] = lv[s]
		s.SKILL["experience"] = Exp.xp_for_level(lv[s]) + int((Exp.xp_for_level(lv[s] + 1) - Exp.xp_for_level(lv[s])) * 0.6)
		for p in s.minor_processes:
			if !p.has("level") or int(p.get("unlock level", 1)) > lv[s]: continue
			var pl = max(1, lv[s] - int(p.get("unlock level", 1)) + 1)
			p["level"] = pl
			p["experience"] = Exp.xp_for_level(pl) + 5
			p["unlocked"] = true
			if p.has("efficiency"): p["efficiency"] = float(p["efficiency"]) + float(p.get("efficiency rate", 0.0)) * (pl - 1)
	Stats.unlock_location("Lawfirm"); Stats.unlock_location("Hospital")
	for t in Stats.hacking_targets["School"].targets: Stats.unlock_target(t)
	Stats.unlock_target(Stats.hacking_targets["School"]["hard mode targets"][0])
	Stats.unlock_target(Stats.hacking_targets["Lawfirm"].targets[1])
	Uploads.completed_tiers = [1, 2]
	var res = Decoding.get_tier_resources(3)
	var amounts = [940, 310, 255, 204, 83, 61, 42]
	for i in res.size(): Inventory.add_resource(res[i], amounts[i])
	var up = {}
	for i in res.size(): up[res[i]] = [118, 64, 71, 52, 33, 21, 12][i]
	Uploads.uploaded = up
	Uploads.stage(res[5], 9); Uploads.start_upload(res[5])
	Uploads.stage(res[0], 40); Uploads.start_upload(res[0])
	var cache = Stats.hacking_targets["Hospital"].targets[0].loot
	for pair in [[Items.SQL_INJECTOR, 412], [Items.PACKET_SPOOF, 57], [cache, 23], [Items.VM_MINING_TOKEN, 9], [Items.VM_PARSING_TOKEN, 7], [Items.VM_CRACKING_TOKEN, 6], [Items.VM_MATCHING_TOKEN, 4], [Items.LOGS, 300], [Items.ARCHIVES, 260]]:
		Inventory.add_resource(pair[0], pair[1])
	for e in Tutorial.TUTORIAL_ORDER:
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	Tutorial.show_intro = false
	# upgrades: tiers 1-2 done for the wired skills, a few Tier 3 installs
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		if !Upgrades.is_wired(p.group): continue
		var n = 0
		for l in p.levels:
			if int(l.tier) <= 2 or (int(l.tier) == 3 and int(l.slot) <= 3): n += 1
		p.installed = n; Upgrades._recompute(p)
	Upgrades.apply_effects()
	HackingMods.refresh_slots()
	Stats.system_tempature = 61.0
	SaveManager.save_game()
	print(">>> staged: mining L%d, versions %s" % [Mining.SKILL.level, Upgrades.version_text("Mining")])
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _wait(0.5)
	if Tutorial.show_intro: os._finish_boot()
	await _wait(0.5)
	if OS.get_environment("SHOT") != "intro":
		os.accepting_player_inputs = true
	else:
		os.accepting_player_inputs = false
	if OS.get_environment("STAGE") == "1":
		_stage(); get_tree().quit(); return
	await os._wait_for_output()
	os._clear_terminal()
	match OS.get_environment("SHOT"):
		"mining":
			await _cmd("ssh parsing footprint=archives"); await _cmd("ssh cracking badge"); await _cmd("ssh matching credential")
			await _goto("mining"); await _cmd("mine -metadata")
			Engine.time_scale = 2.0; await _wait(9.0); Engine.time_scale = 1.0
			await _shot("01_mining_vms")
		"cracking":
			await _cmd("ssh mining metadata"); await _cmd("ssh matching badge")
			await _goto("cracking"); await _cmd("crack -badge"); await _wait(9.0)
			await _shot("02_cracking")
		"matching":
			await _cmd("ssh cracking badge")
			await _goto("matching"); await _cmd("match -badge"); await _wait(14.0)
			await _shot("03_matching")
		"phishing":
			await _goto("phishing"); await _cmd("phish -whale bait=archives"); Engine.time_scale = 4.0; await _wait(16.0); Engine.time_scale = 1.0
			await _shot("04_phishing_whale")
		"spear":
			await _goto("phishing"); await _cmd("phish -spear bait=logs"); Engine.time_scale = 3.0; await _wait(14.0); Engine.time_scale = 1.0
			await _shot("04b_phishing_spear")
		"apt":
			await _cmd("apt", 2.5)
			await _shot("05_apt")
		"decoding":
			await _cmd("ssh mining metadata"); await _cmd("ssh parsing footprint=archives")
			await _goto("decoding"); await _cmd("decode -cache"); await _wait(16.0)
			await _shot("06_decoding")
		"compiling":
			await _goto("compiling"); await _cmd("compile -hospital"); await _wait(6.0)
			await _shot("07_compiling")
		"parsing":
			await _goto("parsing"); await _cmd("parse -footprint=metadata"); await _wait(6.0)
			await _shot("08_parsing")
		"hack":
			await _cmd("cd hacking", 4.0)
			os.hacking._on_player_hacking_box_command_entered("view school"); await _wait(2.5)
			Inventory.add_resource(Items.SCHOOL_PAYLOAD, 30)
			os.hacking._on_player_hacking_box_command_entered("hack student=20"); await _wait(30.0)
			await _shot("09_hacking")
			await _wait(9.0)
			await _shot("09b_hacking")
		"intro":
			Tutorial.show_intro = true
			os._clear_terminal()
			os.header.visible = false; os.input_line_container.visible = false; os.system_dock.modulate.a = 0.0
			os.header.prepare_intro()
			os.intro_to_game()
			while !os.accepting_player_inputs: await get_tree().process_frame
			await _wait(0.5)
			await _shot("10_intro")
			os.install_idle_os()
			await _wait(3.6)
			await _shot("11_boot")
	get_tree().quit()
