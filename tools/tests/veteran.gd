extends Node
## 2026-11-03: rename + demo veteran. PHASE=1 writes a fake demo save into the old IdleOS_Demo folder. PHASE=2 (a fresh
## launch, empty IdleOS folder): slots/settings copied, demo save scanned, launcher line, new profile claims it,
## bonus delivered once the tutorial is done.
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _run() -> void:
	if OS.get_environment("PHASE") == "1":
		var old = SaveManager.old_user_dir()
		DirAccess.make_dir_recursive_absolute(old)
		var rares = Uploads.get_tier_rares(1)
		var demo = {"version": 4, "mining": {"skill_level": 10}, "parsing": {"skill_level": 8}, "cracking": {"skill_level": 10},
			"matching": {"skill_level": 6}, "phishing": {"skill_level": 3}, "decoding": {"skill_level": 5}, "compiling": {"skill_level": 4},
			"hacking": {"skill_level": 10}, "uploads": {"uploaded": {str(rares[0].id): 3, str(rares[1].id): 2}, "completed_tiers": [1]}}
		var f = FileAccess.open(old.path_join("savegame.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(demo)); f.close()
		print(">>> wrote demo save to ", old, " rares ", rares[0].name, " / ", rares[1].name)
		get_tree().quit()
		return
	print(">>> user dir %s  ·  slots copied: %s" % [OS.get_user_data_dir(), [1, 2, 3].map(func(n): return SaveManager.slot_exists(n))])
	print(">>> settings copied: %s  achievements copied: %s" % [FileAccess.file_exists("user://settings.cfg"), FileAccess.file_exists("user://achievements.cfg")])
	print(">>> veteran found: %s  pending: %s" % [DemoVeteran.found, DemoVeteran.pending_for_new_profile()])
	var dummy = Node.new(); get_tree().root.add_child(dummy); get_tree().current_scene = dummy
	get_tree().change_scene_to_file("res://scenes/launcher.tscn")
	await _f(60)
	var l = get_tree().current_scene
	print(">>> launcher intro: ", l._log.get_parsed_text().replace("\n", " | "))
	var free = [1, 2, 3].filter(func(n): return !SaveManager.slot_exists(n))[0]
	l._boot(free, "vet_test")
	await _f(150)
	print(">>> new profile slot %d: veteran state '%s', claimed %d, mining L%d" % [free, DemoVeteran.state, DemoVeteran.claimed_slot, Mining.SKILL.level])
	var tok0 = Inventory.get_amount(Items.VM_MINING_TOKEN)
	var logs0 = Inventory.get_amount(Items.LOGS)
	for e in Tutorial.TUTORIAL_ORDER:
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	await _f(120)
	var rares = Uploads.get_tier_rares(1)
	print(">>> after tutorial: state '%s'  mining L%d parsing L%d hacking L%d  mining tokens +%d  logs +%d  %s %d  %s %d" % [DemoVeteran.state, Mining.SKILL.level, Parsing.SKILL.level, Hacking.SKILL.level,
		Inventory.get_amount(Items.VM_MINING_TOKEN) - tok0, Inventory.get_amount(Items.LOGS) - logs0, rares[0].name, Inventory.get_amount(rares[0]), rares[1].name, Inventory.get_amount(rares[1])])
	print(">>> pending for another new profile: ", DemoVeteran.pending_for_new_profile(), "  meta veteran: ", SaveManager.build_meta().get("veteran"))
	get_tree().quit()
