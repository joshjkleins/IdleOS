extends Node
## 2026-11-03: the 'hint' alert rule (best target at <= 70% cache chance)
var os
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _show(tag: String) -> void:
	print(">>> == ", tag, _strip(HintEngine.text(os)).replace("\n", "\n>>> "))
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	for e in Tutorial.TUTORIAL_ORDER:
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	Inventory.add_resource(Items.SCHOOL_PAYLOAD, 3); Inventory.add_resource(Items.SQL_INJECTOR, 60); Inventory.add_resource(Items.PACKET_SPOOF, 20)
	var best = HintEngine.best_target()
	Alert.data.clear()
	Alert.data[Stats.target_key(best)] = {"alert": 20.0, "skill": "Cracking"}
	_show("alert 20% (no hint expected)")
	Alert.data[Stats.target_key(best)] = {"alert": 30.0, "skill": "Cracking"}
	_show("alert 30%")
	Alert.data[Stats.target_key(best)] = {"alert": 55.0, "skill": "Parsing"}
	_show("alert 55%, parsing")
	get_tree().quit()
