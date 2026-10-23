extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	var stu = Stats.hacking_targets["School"].targets[0]
	var adm = Stats.hacking_targets["School"].targets[1]
	print("kit (fresh, at step 1): '%s'" % Tutorial.ensure_hack_kit(stu, 1))
	for e in Tutorial.TUTORIAL_ORDER:
		if e == Tutorial.TutorialEvent.HACK_STUDENT: break
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	print("kit (at hack step, empty): '%s'" % Tutorial.ensure_hack_kit(stu, 2))
	Inventory.remove_resource(Items.SQL_INJECTOR, 20)
	print("kit (after a killed hack used 20 SQL): '%s'" % Tutorial.ensure_hack_kit(stu, 2))
	print("kit (admin): '%s'" % Tutorial.ensure_hack_kit(adm, 1))
	get_tree().quit()
