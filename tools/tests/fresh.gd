extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	print(">>> fresh: show_intro=%s loaded_version=%d notice=%s max_level=%d slots=%d goals=%s" % [Tutorial.show_intro, SaveManager.loaded_version, Tutorial.should_show_old_save_notice(), Exp.MAX_LEVEL, HackingMods.BASE_MOD_SLOTS, Uploads.get_goals().map(func(g): return "%s %d" % [g.item.name, g.amount]).slice(0, 2)])
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("add logs")
	os._on_input_line_text_submitted("tutorial -r")
	for i in 30: await get_tree().process_frame
	print(">>> add logs -> %d | tutorial %d/38 | apt mining packages: %d" % [Inventory.get_amount(Items.LOGS), Tutorial.completed_events.size(), Upgrades.group_packages("Mining").size()])
	get_tree().quit()
