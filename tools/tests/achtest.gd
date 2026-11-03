extends Node
## 2026-11-03: achievements without the Steam plugin: conditions from save state, events, HACKERMAN, the account file
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _run() -> void:
	print(">>> steam: available=%s (%s)" % [SteamManager.available, SteamManager.init_text])
	Achievements.handle("achievements reset")
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	Achievements.check_all()
	print(">>> fresh game: ", Achievements.unlocked.keys())
	var stu = Stats.hacking_targets["School"].targets[0]
	Stats.wins[Stats.target_key(stu)] = 100
	Uploads.completed_tiers = [1, 2]
	Mining.SKILL.level = 55
	Queue.steps = ["mine -logs", "mine -logs", "mine -logs", "mine -logs", "mine -logs", "mine -logs"]
	Achievements.check_all()
	print(">>> after state: ", Achievements.unlocked.keys())
	os._on_input_line_text_submitted("sudo rm -rf")
	await _f(5)
	Alert.data[Stats.target_key(stu)] = {"alert": 96.0, "skill": "Mining"}
	Alert.begin_run(); Alert._raise(stu); Alert.end_run()
	print(">>> student alert %.0f%% maxed %s" % [Alert.alert_pct(stu), Alert.data[Stats.target_key(stu)].get("maxed")])
	Exp.add_xp(Mining, null, 10000000)
	print(">>> events: SUDO_RM %s ALERT_CLEARED %s" % [Achievements.is_unlocked("SUDO_RM"), Achievements.is_unlocked("ALERT_CLEARED")])
	for id in Achievements.ids():
		if id != "HACKERMAN" and id != "FIRST_VM":
			Achievements.unlock(id)
	print(">>> all but FIRST_VM: hackerman %s" % Achievements.is_unlocked("HACKERMAN"))
	Achievements.unlock("FIRST_VM")
	print(">>> +FIRST_VM: hackerman %s  (%d/%d)" % [Achievements.is_unlocked("HACKERMAN"), Achievements.unlocked.size(), Achievements.DEFS.size()])
	Achievements._load()
	print(">>> reloaded from file: %d" % Achievements.unlocked.size())
	var lines = Array(_strip(Achievements.list_text()).split("\n", false))
	print(">>> list head: ", " | ".join(lines.slice(0, 4)))
	Achievements.handle("achievements reset")
	print(">>> after reset: %d" % Achievements.unlocked.size())
	get_tree().quit()
