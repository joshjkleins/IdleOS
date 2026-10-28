extends Node
## Compromise check: recon view, a full School compromise (screens), what it paid / granted.
## SHOTS=1 saves screenshots, TS = time scale during the fight, FORFEIT=1 kills it at fight 2.
var os
var ended := false
func _ready() -> void:
	_run.call_deferred()
func _shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cmp_%s.png" % n)
func _gear() -> void:
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		p.installed = p.levels.filter(func(l): return int(l.tier) <= 1).size() if (id.begins_with("hacking.") or id.begins_with("system.")) else 0
		Upgrades._recompute(p)
	var ic = Upgrades.packages.get("system.idle_cooling")
	if ic: ic.installed = 0; Upgrades._recompute(ic)
	Upgrades.apply_effects()
	HackingMods.refresh_slots()
	for m in [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling, Hacking]:
		m.SKILL.level = 12; m.SKILL.experience = Exp.xp_for_level(12)
		Exp.refresh_efficiency(m)
	Hacking.SKILL.efficiency = 0.05 + 0.00255 * 11
func cmd(t: String) -> void:
	os.hacking._on_player_hacking_box_command_entered(t)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	for e in Tutorial.TUTORIAL_ORDER: if !(e in Tutorial.completed_events): Tutorial.completed_events.append(e)
	_gear()
	for t in Stats.hacking_targets["School"].targets: t.unlocked = true
	Inventory.add_resource(Items.SCHOOL_PAYLOAD, 30)
	Inventory.add_resource(Items.SQL_INJECTOR, 600)
	Inventory.add_resource(Items.PACKET_SPOOF, 120)
	var sb = Inventory.get_item_by_name("SQL Booster")
	HackingMods.current_mods[sb.hacking_mod_type] = {"duration": 10, "value": sb.hacking_mod_value, "tier": sb.tier}
	for k in 25: Decoding.add_intel_point(Stats.hacking_targets["School"].targets[2])
	Signals.hacking_ended_signal.connect(func(): ended = true)
	os._on_input_line_text_submitted("cd hacking")
	for i in 240: await get_tree().process_frame
	cmd("compromise -school") # locked: tier not done
	for i in 20: await get_tree().process_frame
	Uploads.completed_tiers.append(1)
	cmd("recon school")
	for i in 200: await get_tree().process_frame
	await _shot("recon")
	var xp0 = Hacking.SKILL.experience
	var wins0 = Stats.get_wins(Stats.hacking_targets["School"].targets[0])
	var drv0 = Drivers.owned.keys()
	if OS.get_environment("WIN") != "": Stats.max_anon = 3000
	cmd("compromise -school")
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 1.0
	var t = 0.0
	var shot_at = [8.0, 60.0, 200.0]
	while !ended and t < 1500.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if !shot_at.is_empty() and t > shot_at[0]:
			shot_at.pop_front()
			await _shot("run%d" % int(t))
		if OS.get_environment("FORFEIT") != "" and os.hacking.enemy_hacking_box.hacking_game.hack_index >= 2 and os.hacking.enemy_hacking_box.hacking_game.is_hacking:
			cmd("kill -s")
			for i in 5: await get_tree().process_frame
			cmd("kill")
			break
		var g = os.hacking.enemy_hacking_box.hacking_game
		if g.is_hacking and Stats.overheated == false and Stats.system_tempature > 90: pass
	Engine.time_scale = 1.0
	for i in 240: await get_tree().process_frame
	await _shot("end")
	var g = os.hacking.enemy_hacking_box.hacking_game
	print(">>> ended %s after %.0fs · fights reached %d · payload left %d · xp +%d · student wins %d->%d · mod duration left %s" % [ended, t, g.hack_index, Inventory.get_amount(Items.SCHOOL_PAYLOAD), Hacking.SKILL.experience - xp0, wins0, Stats.get_wins(Stats.hacking_targets["School"].targets[0]), str(HackingMods.current_mods.values().map(func(m): return m.duration))])
	print(">>> new drivers: ", Drivers.owned.keys().filter(func(k): return !(k in drv0)), "  left tier1: ", Compromise.drivers_left(1))
	print(">>> anon %d/%d  temp %.0f" % [Stats.current_anon, Stats.max_anon, Stats.system_tempature])
	var lines = os.hacking.player_hacking_box
	get_tree().quit()
