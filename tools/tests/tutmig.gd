extends Node
func _ready() -> void:
	_run.call_deferred()
func _case(name: String, done: Array) -> void:
	Tutorial.completed_events.clear(); Tutorial.kit_given = false
	for e in done: Tutorial.completed_events.append(e)
	Tutorial._migrate_to_hack_first()
	await get_tree().process_frame
	var cur = Tutorial.current_step()
	print(">>> %-34s complete=%s  now at: %s  kit_given=%s" % [name, Tutorial.is_tutorial_complete(), Tutorial.step_title(cur) if cur != -1 else "-", Tutorial.kit_given])
func _run() -> void:
	for i in 30: await get_tree().process_frame
	var T = Tutorial.TutorialEvent
	await _case("old tutorial finished", Tutorial.OLD_ORDER_V2.filter(func(e): return Tutorial.tutorial_tasks.has(e)))
	var old = Tutorial.OLD_ORDER_V2
	await _case("old: up to match credentials", old.slice(0, old.find(T.MATCH_3_CREDENTIALS) + 1))
	await _case("old: just -h and cd mining", [T.RUN_HELP_COMMAND, T.NAVIGATE_MINING])
	await _case("old: up to hack student", old.slice(0, old.find(T.HACK_STUDENT) + 1))
	print("sql after kit: ", Inventory.get_amount(Items.SQL_INJECTOR))
	get_tree().quit()
