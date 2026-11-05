extends Node
## 2026-11-05: release check - fresh user dir, new profile from the launcher, dev commands off
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var dummy = Node.new()
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	get_tree().create_timer(60.0).timeout.connect(func(): print(">>> timed out"); get_tree().quit())
	print(">>> user dir %s  version %s  slot1 exists %s" % [OS.get_user_data_dir(), ProjectSettings.get_setting("application/config/version"), SaveManager.slot_exists(1)])
	print(">>> flags: items %s  ach %s  drivers %s  ending %s  maxall %s  alltiers %s  alltargets %s  intro %s" % [load("res://scripts/idle_os_2.gd").DEV_ITEM_COMMANDS, Achievements.DEV, Drivers.DEV_GIVE, Ending.DEV, Exp.DEV_MAX_ALL, Upgrades.DEV_UNLOCK_ALL_TIERS, Stats.DEV_UNLOCK_ALL_TARGETS, Tutorial.DEV_ALWAYS_SHOW_INTRO])
	print(">>> steam_appid.txt in project: %s" % FileAccess.file_exists("res://steam_appid.txt"))
	get_tree().change_scene_to_file("res://scenes/launcher.tscn")
	for i in 10: await get_tree().process_frame
	var l = get_tree().current_scene
	while l._booting: await get_tree().process_frame
	l._boot(1, "tester")
	for i in 240: await get_tree().process_frame
	var os = get_tree().current_scene
	print(">>> scene %s  slot %d  session %s  tutorial done %s  logs %d" % [os.name, SaveManager.slot, SaveManager.session_active, Tutorial.is_tutorial_complete(), Inventory.get_amount(Items.LOGS)])
	if "accepting_player_inputs" in os:
		os.accepting_player_inputs = true
		for cmd in ["add logs", "timeskip 5", "tutorial complete", "driver give all", "achievement unlock HACKERMAN"]:
			os._on_input_line_text_submitted(cmd)
			await get_tree().process_frame
		print(">>> after dev cmds: logs %d  tutorial done %s  drivers owned %d  HACKERMAN %s" % [Inventory.get_amount(Items.LOGS), Tutorial.is_tutorial_complete(), Drivers.owned.size() if "owned" in Drivers else -1, Achievements.is_unlocked("HACKERMAN") if Achievements.has_method("is_unlocked") else "?"])
	get_tree().quit()
