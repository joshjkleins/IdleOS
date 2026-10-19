extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	print(">>> hint in tutorial text: ", ContextCommands.get_tutorial().contains("starts it over"))
	for p in Upgrades.group_packages("Mining"):
		while !Upgrades.is_at_max_level(p.id):
			p.installed += 1
	Uploads.uploaded[Items.LOGS] = Uploads.get_goal_amount(Items.LOGS)
	var n = Tutorial.reset_tutorial()
	print(">>> skipped %d: %s" % [n, Tutorial.completed_events.map(func(e): return Tutorial.TutorialEvent.keys()[e])])
	print(Tutorial.reset_message(n).split("\n")[2])
	get_tree().quit()
