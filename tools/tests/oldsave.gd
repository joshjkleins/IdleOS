extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	print(">>> show_intro=%s booting=%s accepting=%s" % [Tutorial.show_intro, os._booting, os.accepting_player_inputs])
	print(">>> levels: mining %d (xp %d) parsing %d hacking %d | logs %d sql %d parents cc %d" % [Mining.SKILL.level, Mining.SKILL.experience, Parsing.SKILL.level, Hacking.SKILL.level, Inventory.get_amount(Items.LOGS), Inventory.get_amount(Items.SQL_INJECTOR), Inventory.get_amount(Items.PARENTS_CREDIT_CARD)])
	print(">>> tutorial %d/%d done, current: %s" % [Tutorial.completed_events.size(), Tutorial.tutorial_tasks.size(), Tutorial.get_current_task().left(80)])
	print(">>> versions: ", ["System","Mining","Parsing"].map(func(g): return g + " " + Upgrades.version_text(g)), " | unlocked locs: ", Stats.hacking_targets.keys().filter(func(k): return Stats.hacking_targets[k].unlocked))
	SaveManager.save_game()
	print(">>> resaved ok")
	get_tree().quit()
