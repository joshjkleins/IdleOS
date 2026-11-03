extends Node
## 2026-11-03: Student at 11% alert (Parsing) -> a real 'parse -footprint=logs 20' in the main terminal: alert + XP
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("tutorial complete")
	await _f(30)
	var stu = Stats.hacking_targets["School"].targets[0]
	Alert.data.clear()
	Alert.data[Stats.target_key(stu)] = {"alert": 11.0, "skill": "Parsing"}
	Inventory.add_resource(Items.LOGS, 200)
	var xp0 = Parsing.SKILL.experience
	var seen = []
	Exp.gained_xp_signal.connect(func(a): seen.append(a))
	print(">>> start: alert %.2f%%  goal '%s'  step xp %d (units %d, xp/unit %.1f)" % [Alert.alert_pct(stu), Alert.goal_text(stu), Alert.step_xp("Parsing", 1), Alert.step_units("Parsing", 1), Alert._xp_per_unit("Parsing", 1)])
	os._on_input_line_text_submitted("parse -footprint=logs 20")
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 150000 and (os.process_running or Time.get_ticks_msec() - t0 < 3000):
		await get_tree().process_frame
	await _f(30)
	print(">>> after: alert %.2f%%  parsing xp gained %d  (xp events %d: %s)" % [Alert.alert_pct(stu), Parsing.SKILL.experience - xp0, seen.size(), seen.slice(0, 25)])
	get_tree().quit()
