extends Node
## 2026-11-05: shared clear - two Parsing targets (tier 1 + tier 2) and one Cracking target; one XP grant lowers both Parsing ones
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var stu = Stats.hacking_targets["School"].targets[0]
	var t1b = Stats.hacking_targets["School"].targets[1]
	var locs = Stats.hacking_targets.keys()
	var t2 = Stats.hacking_targets[locs[1]].targets[0]
	Alert.data.clear()
	Alert.data[Stats.target_key(stu)] = {"alert": 30.0, "skill": "Parsing"}
	Alert.data[Stats.target_key(t2)] = {"alert": 30.0, "skill": "Parsing"}
	Alert.data[Stats.target_key(t1b)] = {"alert": 30.0, "skill": "Cracking"}
	var need1 = Alert.step_xp("Parsing", 1)
	Alert.on_xp(Parsing, int(need1))
	print(">>> after 1 T1 step of XP: %s=%.2f  %s=%.2f  %s(cracking)=%.2f" % [stu.name, Alert.alert_pct(stu), t2.name, Alert.alert_pct(t2), t1b.name, Alert.alert_pct(t1b)])
	Alert.on_xp(Parsing, int(need1 * 2))
	print(">>> after 2 more steps: %s=%.2f (cleared=%s)  %s=%.2f" % [stu.name, Alert.alert_pct(stu), str(!Alert.data.has(Stats.target_key(stu))), t2.name, Alert.alert_pct(t2)])
	get_tree().quit()
