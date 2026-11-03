extends Node
## 2026-11-03: Clean Exit (cool_head id) + Ghost Protocol (payload_recycler id) driver texts and their alert effects
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for id in ["cool_head", "payload_recycler"]:
		for r in [1, 2, 3]:
			print(">>> %s r%d: %s  |  %s" % [Drivers.DEFS[id].name, r, Drivers.value_text(id, r), Drivers.short_text(id, r)])
	for e in Tutorial.steps():
		if !(e in Tutorial.completed_events): Tutorial.completed_events.append(e)
	for sk in [Mining, Compiling]:
		sk.SKILL.level = 40; sk.SKILL.experience = Exp.xp_for_level(40)
	var stu = Stats.hacking_targets["School"].targets[0]
	print(">>> tutorial done (exempt=%s)" % Alert.exempt())
	for id in ["cool_head", "payload_recycler"]:
		Drivers.grant(id); Drivers.owned[id] = Drivers.RANK_XP[2] # rank 3
		print(">>> equip %s: %s" % [id, Drivers.equip(id)])
	Alert.data.clear(); Alert.begin_run()
	var adds = []
	var ghosts = 0
	for i in 12:
		var before = Alert.alert_pct(stu)
		if Alert.roll_cache(stu):
			adds.append("%+.1f" % (Alert.alert_pct(stu) - before))
			if Alert.last_ghost: ghosts += 1
	print(">>> one run, Clean Exit r3 + Ghost r3: adds %s  ghosts %d  alert %.1f%%" % [" ".join(adds), ghosts, Alert.alert_pct(stu)])
	get_tree().quit()
